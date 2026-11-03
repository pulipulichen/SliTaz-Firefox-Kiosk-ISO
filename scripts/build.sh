#!/usr/bin/env bash
set -Eeuo pipefail
repo=$(cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo"
[[ $EUID = 0 ]] || { echo 'Run with sudo on a disposable Ubuntu 24.04 builder.' >&2; exit 1; }
[[ $(uname -m) = x86_64 ]] || { echo 'An x86_64 builder is required.' >&2; exit 1; }
for cmd in xorriso cpio xz python3 chroot mount sha256sum; do command -v "$cmd" >/dev/null; done
work="$repo/work"
dist="$repo/dist"
mkdir -p "$work" "$dist"
python3 scripts/fetch-sources.py "$work/downloads"
iso="$work/downloads/base.iso"
root="$work/rootfs"
cdtree="$work/cd"
mounts=()
cleanup() {
    for ((i=${#mounts[@]}-1; i>=0; i--)); do umount "${mounts[$i]}" || true; done
}
trap cleanup EXIT
bind_root() {
    local target=$1
    mkdir -p "$target"/{dev,proc,sys}
    for fs in dev proc sys; do
        mount --bind "/$fs" "$target/$fs"
        mounts+=("$target/$fs")
    done
    cp -L /etc/resolv.conf "$target/etc/resolv.conf"
}
install_packages() {
    local target=$1; shift
    local package install_log package_file candidate mirror package_path dependency
    local idx=0
    local -a pending=("$@")
    local -A processed=()
    local mirrors=(
        'https://distro.ibiblio.org/slitaz/x86_64/cooking/packages'
        'https://ftp.icm.edu.pl/packages/linux-slitaz/x86_64/cooking/packages'
        'https://mirror.clarkson.edu/slitaz/x86_64/cooking/packages'
    )
    printf '%s\n' 'https://distro.ibiblio.org/slitaz/x86_64/cooking/packages/' > "$target/var/lib/tazpkg/mirror"
    chroot "$target" /usr/bin/tazpkg recharge || echo 'WARNING: tazpkg recharge failed; using bundled package metadata.' >&2

    # tazpkg may mark a parent package installed even when its dependencies
    # could not be downloaded. Recover and validate those dependencies too.
    while (( idx < ${#pending[@]} )); do
        package=${pending[$idx]}
        idx=$((idx + 1))
        [[ -n $package ]] || continue
        [[ -z ${processed[$package]+x} ]] || continue
        processed[$package]=1
        (( idx <= 200 )) || { echo 'Too many package dependencies; aborting.' >&2; return 1; }
        install_log="$work/tazpkg-$package.log"
        : > "$install_log"

        if [[ ! -d "$target/var/lib/tazpkg/installed/$package" ]]; then
            chroot "$target" /usr/bin/tazpkg get-install "$package" --forced 2>&1 | tee "$install_log" || true
            if [[ ! -d "$target/var/lib/tazpkg/installed/$package" ]]; then
                package_file=''
                while IFS= read -r candidate; do
                    if [[ "$candidate" == "$package"-*.tazpkg ]]; then
                        package_file=$candidate
                        break
                    fi
                done < <(sed -n 's/.*Checksum error for "\([^"]*\.tazpkg\)".*/\1/p' "$install_log")

                [[ -n $package_file ]] || {
                    echo "No package archive name found for $package" >&2
                    tail -n 40 "$install_log" >&2
                    return 1
                }
                mkdir -p "$target/tmp"
                for mirror in "${mirrors[@]}"; do
                    package_path="$target/tmp/$package_file"
                    echo "Trying $package_file from $mirror" >&2
                    if curl --fail --location --silent --show-error --retry 2 "$mirror/$package_file" --output "$package_path"; then
                        chroot "$target" /usr/bin/tazpkg install "/tmp/$package_file" --forced 2>&1 | tee -a "$install_log" || true
                        rm -f "$package_path"
                        if [[ -d "$target/var/lib/tazpkg/installed/$package" ]]; then
                            break
                        fi
                    fi
                    rm -f "$package_path"
                done
            fi
        fi

        [[ -d "$target/var/lib/tazpkg/installed/$package" ]] || {
            echo "Package installation failed: $package" >&2
            tail -n 40 "$install_log" >&2
            return 1
        }

        while IFS= read -r dependency; do
            [[ -n $dependency ]] && pending+=("$dependency")
        done < <(sed -n 's/.*Missing package "\([^"]*\)".*/\1/p' "$install_log")
    done

    for package in "${pending[@]}"; do
        [[ -d "$target/var/lib/tazpkg/installed/$package" ]] || {
            echo "Unresolved package dependency: $package" >&2
            return 1
        }
    done
    printf 'Verified %d explicitly requested and discovered packages.\n' "${#processed[@]}"
}
# Never delete a root still containing mounts from an interrupted build.
if findmnt -rn -o TARGET | grep -Fq "$root/"; then
    echo "Stale mounts below $root: unmount them before rebuilding." >&2
    exit 1
fi
rm -rf "$root" "$cdtree"
mkdir -p "$root" "$cdtree"
xorriso -osirrox on -indev "$iso" -extract / "$cdtree"
(cd "$root"; xz --format=lzma -dc "$cdtree/boot/rootfs.gz" | cpio -idm --no-absolute-filenames)
bind_root "$root"
# SCIM's existing ZhuYin tables avoid the entire RIME source-build toolchain.
install_packages "$root" scim scim-tables-base scim-tables-zh wqy-microhei pcmanfm lxpanel lxterminal wmctrl
# Building fio on Ubuntu against musl avoids introducing GCC into the Live ISO.
bash scripts/build-fio.sh "$root" "$work"
# Cooking retires old module archives. Refresh the boot kernel and all of
# its installed split packages together, including the VirtIO PCI provider.
index="$root/var/lib/tazpkg/files-list.lzma"
owners=$(xz --format=lzma -dc "$index" |
    awk -F: '/\/virtio_pci\.ko(\.(xz|gz|zst))?$/ && $1 ~ /^linux-lts(-[a-z0-9-]+)?$/ {print $1}' | sort -u)
[[ -n $owners ]] || { echo 'No linux-lts provider for virtio_pci in the mirror index' >&2; exit 1; }
packages=(linux-lts linux-lts-net linux-lts-virt)
for receipt in "$root"/var/lib/tazpkg/installed/linux-lts-*/receipt; do
    [[ -f $receipt ]] || continue
    package=${receipt%/receipt}
    packages+=("${package##*/}")
done
mapfile -t kernel_packages < <(printf '%s\n' "${packages[@]}" "$owners" | sort -u)
for package in "${kernel_packages[@]}"; do
    echo "Installing matching kernel component: $package"
    chroot "$root" /usr/bin/tazpkg get-install "$package" --forced
done
receipt="$root/var/lib/tazpkg/installed/linux-lts"
version=$(chroot "$root" /bin/sh -c '. /var/lib/tazpkg/installed/linux-lts/receipt; echo "$VERSION"')
release="$version-slitaz"
kernel_image=$(awk '/^\/?boot\/(vmlinuz|bzImage)(-|$)/ {print; exit}' "$receipt/files.list")
[[ -n $kernel_image && -s $root/${kernel_image#/} && -d $root/lib/modules/$release ]] || {
    cat "$receipt/files.list" >&2
    echo "Missing boot kernel or modules for $release" >&2
    exit 1
}
install -m644 "$root/${kernel_image#/}" "$cdtree/boot/bzImage"
depmod -b "$root" "$release"
for driver in virtio_pci virtio_net; do
    modprobe -d "$root" -S "$release" --show-depends "$driver"
done
cleanup
mounts=()
install -Dm644 config/kiosk.conf "$root/etc/kiosk.conf"
install -Dm755 scripts/kiosk-session "$root/usr/local/bin/kiosk-session"
install -Dm755 scripts/kiosk-network "$root/usr/local/sbin/kiosk-network"
# Store Firefox and SCIM settings both in /etc/skel and a runtime source for
# the existing SliTaz tux user, whose home may predate /etc/skel changes.
install -Dm644 config/user.js "$root/etc/skel/.mozilla/firefox/kiosk/user.js"
install -Dm644 config/user.js "$root/usr/local/share/kiosk/firefox/user.js"
install -Dm644 config/scim-global "$root/etc/skel/.scim/global"
install -Dm644 config/scim-config "$root/etc/skel/.scim/config"
install -Dm644 config/scim-global "$root/usr/local/share/kiosk/scim/global"
install -Dm644 config/scim-config "$root/usr/local/share/kiosk/scim/config"
# Firefox supports /etc/firefox/policies and also app/distribution/policies.json.
install -Dm644 config/firefox-policies.json "$root/etc/firefox/policies/policies.json"
while IFS= read -r -d '' app_ini; do
    browser_dir=${app_ini%/application.ini}
    case "$browser_dir" in
        *firefox*) install -Dm644 config/firefox-policies.json "$browser_dir/distribution/policies.json" ;;
    esac
done < <(find "$root/usr/lib" "$root/opt" -name application.ini -print0 2>/dev/null)
install -Dm755 scripts/fio-database-benchmark "$root/usr/local/bin/fio-database-benchmark"
install -Dm755 scripts/fio-database-benchmark "$root/usr/local/share/kiosk/desktop/Database-IO-10min.sh"
install -Dm755 config/Database-IO-10min.desktop "$root/usr/local/share/kiosk/desktop/Database-IO-10min.desktop"
install -Dm755 scripts/fio-database-benchmark "$root/etc/skel/Desktop/Database-IO-10min.sh"
install -Dm755 config/Database-IO-10min.desktop "$root/etc/skel/Desktop/Database-IO-10min.desktop"
mkdir -p "$root/usr/share/xsessions"
cat > "$root/usr/share/xsessions/kiosk.desktop" <<'EOF'
[Desktop Entry]
Name=Firefox Kiosk
Type=Application
Exec=/usr/local/bin/kiosk-session
EOF
printf '#!/bin/sh\nexec /usr/local/bin/kiosk-session\n' > "$root/etc/skel/.xinitrc"
chmod +x "$root/etc/skel/.xinitrc"
sed -i 's/^autologin-session=.*/autologin-session=x11\/kiosk/;s/^default-session=.*/default-session=kiosk/' "$root/etc/lxtaz/dm.conf"
cat >> "$root/etc/init.d/local.sh" <<'EOF'
/usr/local/sbin/kiosk-network > /var/log/kiosk-network.log 2>&1 &
EOF
# Replace the language picker with a timed boot straight into the browser.
cat > "$cdtree/boot/grub/grub.cfg" <<'EOF'
set default=0
set timeout=2
search --no-floppy --file --set=root /boot/bzImage
if [ "$grub_platform" = pc ]; then
  set gfxpayload=1024x768x16,800x600x16,auto
fi
menuentry "SliTaz Firefox Desktop (DHCP / SCIM ZhuYin)" {
  linux /boot/bzImage rw root=/dev/null autologin lang=en_US.UTF-8 kmap=us tz=Asia/Taipei
  initrd /boot/rootfs.gz
}
EOF
# Fail before publishing an ISO with missing input tables, drivers, or CJK fonts.
python3 scripts/verify-rootfs.py "$root"
table_engine=$(find "$root/usr/lib" -type f -name 'table.so' -path '*/scim-*/IMEngine/*' -print -quit)
[[ -n $table_engine ]] || { echo 'SCIM table IMEngine library not found' >&2; exit 1; }
module_path="/${table_engine#"$root/"}"
chroot "$root" /bin/sh -c 'ldd /usr/bin/scim' > "$dist/runtime-libraries.txt"
chroot "$root" /bin/sh -c 'ldd "$1"' sh "$module_path" >> "$dist/runtime-libraries.txt"
if grep -q 'not found' "$dist/runtime-libraries.txt"; then cat "$dist/runtime-libraries.txt"; exit 1; fi
chroot "$root" /bin/sh -c 'fc-cache -f'
cp config/sources.lock.json "$dist/sources.lock.json"
cp "$root/var/lib/tazpkg/installed.info" "$dist/packages.tsv"
# rootfs is an initramfs in legacy LZMA format, despite its .gz suffix.
(cd "$root"; find . -print0 | LC_ALL=C sort -z | cpio --null -o -H newc --owner=0:0 | xz --format=lzma -6 -T1) > "$cdtree/boot/rootfs.gz"
(cd "$cdtree"; find . -type f ! -name md5sum ! -name boot.cat -print0 | sort -z | xargs -0 md5sum > md5sum)
output="$dist/slitaz-firefox-kiosk-x86_64.iso"
rm -f "$output"
# Replay the upstream hybrid BIOS/UEFI boot equipment rather than inventing it.
maps=()
for path in boot/bzImage boot/rootfs.gz boot/grub/grub.cfg md5sum; do
    maps+=(-map "$cdtree/$path" "/$path")
done
xorriso -indev "$iso" -outdev "$output" "${maps[@]}" -boot_image any replay
boot_report=$(xorriso -indev "$output" -report_el_torito plain)
printf '%s\n' "$boot_report"
for platform in BIOS UEFI; do
    grep -Eq "El Torito boot img .* $platform +y " <<< "$boot_report"
done
(cd "$dist"; sha256sum *.iso sources.lock.json packages.tsv runtime-libraries.txt > SHA256SUMS)
echo "ISO built: $output"
