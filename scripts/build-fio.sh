#!/usr/bin/env bash
# Build a portable, static fio binary on the Ubuntu Actions runner.
# SliTaz x86_64 cooking does not currently publish a fio .tazpkg.
set -Eeuo pipefail
[[ $# == 2 ]] || { echo 'Usage: build-fio.sh ROOTFS WORKDIR' >&2; exit 2; }
root=$1
work=$2
src="$work/fio-source"
FIO_COMMIT='5a649e2dddc4d8ad163b0cf57f7cea00a2e94a33' # fio-3.35
for command in musl-gcc git make file chroot; do
    command -v "$command" >/dev/null || { echo "Missing fio builder tool: $command" >&2; exit 1; }
done
mkdir -p "$src"
git -C "$src" init -q
git -C "$src" fetch --quiet --depth=1 https://github.com/axboe/fio.git "$FIO_COMMIT"
git -C "$src" checkout -q --detach FETCH_HEAD
[[ $(git -C "$src" rev-parse HEAD) = "$FIO_COMMIT" ]] || {
    echo 'fio source commit does not match the pinned SHA' >&2
    exit 1
}
(
    cd "$src"
    ./configure --cc=musl-gcc --build-static --disable-native \
        --disable-numa --disable-rdma --disable-rados --disable-rbd \
        --disable-http --disable-gfapi --disable-libzbc \
        --disable-xnvme --disable-libblkio --disable-tcmalloc --disable-libnfs
    make -j2 fio
    file fio
    file fio | grep -q 'statically linked' || {
        echo 'fio must be static to avoid SliTaz/Ubuntu libc mismatches' >&2
        exit 1
    }
)
install -Dm755 "$src/fio" "$root/usr/local/bin/fio"
chroot "$root" /usr/local/bin/fio --version | grep -F 'fio-3.35'
echo "Installed static fio-3.35 in $root"
