#!/bin/bash

set -e

MESON_SOURCE_ROOT=$1
MESON_BUILD_ROOT=$2

rootfs=$MESON_BUILD_ROOT/testsuite/rootfs
rootfs_pristine=$MESON_SOURCE_ROOT/testsuite/rootfs-pristine

rm -rf "$rootfs"
mkdir -p "${rootfs%/*}"

cp -r "$rootfs_pristine" "$rootfs"

find "$rootfs" -type d -exec chmod +w {} +
find "$rootfs" -type f -name .gitignore -delete

# XXX: port as much of this as possible to meson proper.
make -C "$MESON_SOURCE_ROOT/testsuite/module-playground"

"$MESON_SOURCE_ROOT/testsuite/populate-modules.sh" \
  "$MESON_SOURCE_ROOT/testsuite/module-playground" \
  "$rootfs"

touch \
  "$MESON_BUILD_ROOT/testsuite/stamp-rootfs" \
  "$MESON_BUILD_ROOT/stamp-rootfs"
