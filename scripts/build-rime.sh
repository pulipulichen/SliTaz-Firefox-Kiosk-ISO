#!/bin/sh
# Runs ONLY inside the disposable SliTaz build root.
set -eu
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
export LD_LIBRARY_PATH=/opt/rime/lib
export PKG_CONFIG_PATH=/opt/rime/lib/pkgconfig
export CMAKE_BUILD_PARALLEL_LEVEL=${JOBS:-2}
cd /sources
mkdir -p /opt/rime
cmake_build() {
    src=$1; shift
    cmake -S "$src" -B "$src/build" -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/opt/rime -DCMAKE_INSTALL_LIBDIR=lib \
        -DCMAKE_PREFIX_PATH=/opt/rime -DCMAKE_INSTALL_RPATH=/opt/rime/lib \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5 "$@"
    cmake --build "$src/build" --parallel "$CMAKE_BUILD_PARALLEL_LEVEL"
    cmake --install "$src/build"
}
cmake_build yaml-cpp -DYAML_CPP_BUILD_TESTS=OFF -DYAML_CPP_BUILD_TOOLS=OFF -DYAML_BUILD_SHARED_LIBS=ON
cmake_build leveldb -DLEVELDB_BUILD_TESTS=OFF -DLEVELDB_BUILD_BENCHMARKS=OFF -DBUILD_SHARED_LIBS=ON
# The upstream MARISA 0.2.6 tarball contains Autotools files but no
# CMakeLists.txt; use our minimal recipe to avoid unavailable automake packages.
cmake -S /marisa-cmake -B /sources/marisa/build \
    -DMARISA_SOURCE_DIR=/sources/marisa \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/opt/rime -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_INSTALL_RPATH=/opt/rime/lib
cmake --build /sources/marisa/build --parallel "$CMAKE_BUILD_PARALLEL_LEVEL"
cmake --install /sources/marisa/build
cmake_build librime -DBUILD_TEST=OFF -DBUILD_DATA=OFF -DENABLE_LOGGING=OFF
cmake_build ibus-rime -DRIME_DATA_DIR=/opt/rime/share/rime-data
# XML component discovery stays at the system IBus location.
mkdir -p /usr/share/ibus/component
cp /opt/rime/share/ibus/component/rime.xml /usr/share/ibus/component/
