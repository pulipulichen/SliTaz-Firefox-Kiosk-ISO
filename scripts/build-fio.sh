#!/usr/bin/env bash
# Build fio with libaio using musl inside Alpine, then ship a portable static binary.
# The Ubuntu glibc libaio-dev package cannot be safely linked against musl.
set -Eeuo pipefail
[[ $# == 2 ]] || { echo 'Usage: build-fio.sh ROOTFS WORKDIR' >&2; exit 2; }
root=$1
work=$2
src="$work/fio-source"
FIO_COMMIT='5a649e2dddc4d8ad163b0cf57f7cea00a2e94a33' # upstream fio-3.35
for command in docker git file chroot; do
    command -v "$command" >/dev/null || { echo "Missing fio builder tool: $command" >&2; exit 1; }
done
mkdir -p "$src"
git -C "$src" init -q
git -C "$src" fetch --quiet --depth=1 https://github.com/axboe/fio.git "$FIO_COMMIT"
git -C "$src" checkout -q --detach FETCH_HEAD
[[ $(git -C "$src" rev-parse HEAD) = "$FIO_COMMIT" ]] || {
    echo 'fio source commit does not match pinned SHA' >&2
    exit 1
}
# Alpine supplies libaio headers and static libraries compiled against musl.
# Confirm at configure and at runtime that fio's libaio engine really exists.
docker run --rm --platform linux/amd64 \
    --mount "type=bind,src=$src,dst=/src" --workdir /src \
    alpine:3.20 sh -euc '
        apk add --no-cache build-base linux-headers libaio-dev file
        ./configure --build-static --disable-native \
            --disable-numa --disable-rdma --disable-rados --disable-rbd \
            --disable-http --disable-gfapi --disable-libzbc \
            --disable-xnvme --disable-libblkio --disable-tcmalloc --disable-libnfs \
            > fio-configure.log
        cat fio-configure.log
        grep -Eq "Linux AIO support[[:space:]]+yes" fio-configure.log || {
            echo "Linux AIO engine was not detected; refusing to ship fio" >&2
            exit 1
        }
        make -j2 fio
        file fio
        file fio | grep -q "statically linked" || exit 1
        ./fio --enghelp=libaio >/dev/null
        ./fio --name=libaio-smoke --filename=/tmp/fio-libaio-smoke \
            --rw=randwrite --ioengine=libaio --bs=4k --direct=1 \
            --iodepth=2 --size=4M --runtime=1 --time_based \
            --output=/tmp/fio-libaio-smoke.log
        rm -f /tmp/fio-libaio-smoke /tmp/fio-libaio-smoke.log
    '
install -Dm755 "$src/fio" "$root/usr/local/bin/fio"
chroot "$root" /usr/local/bin/fio --version | grep -F 'fio-3.35'
chroot "$root" /usr/local/bin/fio --enghelp=libaio >/dev/null
echo "Installed and verified static fio-3.35 with libaio engine in $root"
