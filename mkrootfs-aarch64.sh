#!/usr/bin/env bash
set -euo pipefail

IMG="test.img"
MOUNT="/mnt/moss"

if [ -f "$IMG" ]; then
    echo "initrd file $IMG already exists.  Skipping."
    exit 0
fi

dd if=/dev/zero of="$IMG" bs=1M count=128
mkfs.vfat -F 32 "$IMG"

if ! mountpoint -q "$MOUNT"; then
    mount -o loop "$IMG" "$MOUNT"
fi

if [ ! -d /tmp/bash ]; then
    git clone https://github.com/bminor/bash.git /tmp/bash
fi


pushd /tmp/bash
if [ ! -f "/tmp/bash/bash" ]; then
    ./configure --without-bash-malloc --enable-static-link --host=aarch64-linux-gnu CC=aarch64-linux-gnu-gcc
    make
fi

if [ ! -f "$MOUNT/bin/bash" ]; then
    sudo mkdir -p "$MOUNT/bin"
    sudo cp bash "$MOUNT/bin"
fi
popd

# busybox -- I couldn't get this to build.  I ended up restoring to a third-party static binary which isn't ideal but it get's things running.
pushd "/tmp"
if [ ! -f "$MOUNT/bin/busybox-aarch64-linux-gnu" ]; then
    wget https://github.com/shutingrz/busybox-static-binaries-fat/raw/refs/heads/main/busybox-aarch64-linux-gnu
    chmod +x busybox-aarch64-linux-gnu
    sudo cp busybox-aarch64-linux-gnu "$MOUNT/bin"
fi
popd

sudo mkdir -p "$MOUNT/dev"

if mountpoint -q "$MOUNT"; then
    umount "$MOUNT"
fi
