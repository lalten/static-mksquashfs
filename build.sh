#!/bin/sh

set -eux

# Install dependencies
if [ "$(uname)" = "Linux" ]; then
    apk add alpine-sdk zlib-dev zlib-static zstd-dev zstd-static
    export EXTRA_LDFLAGS=-static
    njobs="$(nproc)"
    appimage_arch="$(apk --print-arch)"

else
    # No static builds for MacOS...
    brew install squashfs
    export EXTRA_CFLAGS=-std=gnu89
    njobs="$(sysctl -n hw.logicalcpu)"
    appimage_arch="$(/usr/bin/arch)"

fi

# Build static squashfs-tools
squashfs_version="4.6.1"
wget -O squashfs-tools.tar.gz "https://github.com/plougher/squashfs-tools/archive/refs/tags/${squashfs_version}.tar.gz"
tar xf squashfs-tools.tar.gz
rm squashfs-tools.tar.gz
cd squashfs-tools-*/squashfs-tools
sed -i -e 's|#ZSTD_SUPPORT = 1|ZSTD_SUPPORT = 1|g' Makefile
make -j"${njobs}"
file mksquashfs unsquashfs
strip mksquashfs unsquashfs
./mksquashfs -version
cd -

# Use the same architecture names as https://github.com/AppImage/AppImageKit/releases/
echo "$appimage_arch" | grep -q armv && appimage_arch=armhf # replace "armv7l" with "armhf"
[ "$appimage_arch" = "x86" ] && appimage_arch=i686

mkdir -p out
cp squashfs-tools-*/squashfs-tools/mksquashfs "out/mksquashfs-${squashfs_version}-$(uname)-${appimage_arch}"
cp squashfs-tools-*/squashfs-tools/unsquashfs "out/unsquashfs-${squashfs_version}-$(uname)-${appimage_arch}"
