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
builder="$work/builder"
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
    printf '%s\n' 'https://mirror.slitaz.org/x86_64/cooking/packages/' > "$target/var/lib/tazpkg/mirror"
    chroot "$target" /usr/bin/tazpkg recharge
    for package in "$@"; do
        chroot "$target" /usr/bin/tazpkg get-install "$package" --forced
        # Some old tazpkg releases return success after a failed download.
        [[ -d "$target/var/lib/tazpkg/installed/$package" ]] || {
            echo "Package installation failed: $package" >&2; exit 1;
        }
    done
}
# Never delete a root still containing mounts from an interrupted build.
for target in "$root" "$builder"; do
    if findmnt -rn -o TARGET | grep -Fq "$target/"; then
        echo "Stale mounts below $target: unmount them before rebuilding." >&2; exit 1
    fi
done
rm -rf "$root" "$builder" "$cdtree"
mkdir -p "$root" "$cdtree"
xorriso -osirrox on -indev "$iso" -extract / "$cdtree"
(cd "$root"; xz --format=lzma -dc "$cdtree/boot/rootfs.gz" | cpio -idm --no-absolute-filenames)
bind_root "$root"
install_packages "$root" ibus libnotify opencc wqy-microhei \
    libboost-filesystem libboost-regex libboost-system
# Keep the existing UTF-8 locale; Unicode rendering/input does not require a
# Chinese desktop translation package from the old 32-bit-era locale set.
cleanup
mounts=()
cp -a "$root" "$builder"
bind_root "$builder"
# MARISA is built with our CMake recipe; the cooking mirror's automake archive is missing.
install_packages "$builder" gcc make cmake3 \
    glibc-dev libboost-dev libboost-filesystem-dev libboost-regex-dev \
    libboost-system-dev opencc-dev ibus-dev libnotify-dev gtk+-dev gtk+3-dev
cp -a "$work/downloads/sources" "$builder/sources"
# Build pkg-config from its hash-locked source; the SliTaz mirror's binary archive is stale.
chroot "$builder" /bin/sh -c 'cd /sources/pkg-config && ./configure --with-internal-glib --prefix=/usr --disable-host-tool && make -j2 && make install'
install -m755 scripts/build-rime.sh "$builder/build-rime.sh"
install -Dm644 scripts/marisa-cmake/CMakeLists.txt "$builder/marisa-cmake/CMakeLists.txt"
chroot "$builder" /bin/sh /build-rime.sh
cp -a "$builder/opt/rime" "$root/opt/"
mkdir -p "$root/usr/share/ibus/component"
cp "$builder/usr/share/ibus/component/rime.xml" "$root/usr/share/ibus/component/"
cleanup
mounts=()
data="$root/opt/rime/share/rime-data"
mkdir -p "$data" "$root/usr/share/doc/kiosk/upstream"
for name in prelude bopomofo terra-pinyin stroke; do
    cp "$work/downloads/sources/$name/"*.yaml "$data/"
done
# Retain upstream copyright/license files in the image.
for src in "$work/downloads/sources/"*; do
    mkdir -p "$root/usr/share/doc/kiosk/upstream/${src##*/}"
    find "$src" -maxdepth 1 -type f \( -iname '*license*' -o -iname '*copying*' -o -iname '*readme*' \) \
        -exec cp '{}' "$root/usr/share/doc/kiosk/upstream/${src##*/}/" \;
done
rm -rf "$root/opt/rime/include" "$root/opt/rime/lib/cmake" "$root/opt/rime/lib/pkgconfig"
find "$root/opt/rime" -name '*.a' -delete
install -Dm644 config/kiosk.conf "$root/etc/kiosk.conf"
install -Dm755 scripts/kiosk-session "$root/usr/local/bin/kiosk-session"
install -Dm755 scripts/kiosk-network "$root/usr/local/sbin/kiosk-network"
install -Dm644 scripts/kiosk-ibus.py "$root/usr/local/lib/kiosk-ibus.py"
install -Dm644 config/default.custom.yaml "$root/etc/skel/.config/ibus/rime/default.custom.yaml"
install -Dm644 config/user.js "$root/etc/skel/.mozilla/firefox/kiosk/user.js"
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
menuentry "SliTaz Firefox (DHCP / RIME)" {
  linux /boot/bzImage rw root=/dev/null autologin lang=en_US.UTF-8 kmap=us tz=Asia/Taipei
  initrd /boot/rootfs.gz
}
EOF
# Fail the build if required drivers, input modules or runtime libraries are missing.
python3 scripts/verify-rootfs.py "$root"
chroot "$root" /bin/sh -c 'LD_LIBRARY_PATH=/opt/rime/lib ldd /opt/rime/libexec/ibus-rime/ibus-engine-rime' > "$dist/runtime-libraries.txt"
if grep -q 'not found' "$dist/runtime-libraries.txt"; then cat "$dist/runtime-libraries.txt"; exit 1; fi
chroot "$root" /bin/sh -c 'python -c "import ibus"; fc-cache -f'
cp config/sources.lock.json "$dist/sources.lock.json"
cp "$root/var/lib/tazpkg/installed.info" "$dist/packages.tsv"
cp -a "$work/downloads/"*.tar.gz "$dist/"
# rootfs is an initramfs in legacy LZMA format, despite its .gz suffix.
(cd "$root"; find . -print0 | LC_ALL=C sort -z | cpio --null -o -H newc --owner=0:0 | xz --format=lzma -6 -T1) > "$cdtree/boot/rootfs.gz"
(cd "$cdtree"; find . -type f ! -name md5sum ! -name boot.cat -print0 | sort -z | xargs -0 md5sum > md5sum)
output="$dist/slitaz-firefox-kiosk-x86_64.iso"
rm -f "$output"
# Replay the upstream hybrid BIOS/UEFI boot equipment rather than inventing it.
xorriso -indev "$iso" -outdev "$output" -map "$cdtree" / -boot_image any replay
(cd "$dist"; sha256sum *.iso *.tar.gz sources.lock.json packages.tsv runtime-libraries.txt > SHA256SUMS)
echo "ISO built: $output"
