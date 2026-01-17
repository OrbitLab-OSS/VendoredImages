#!/bin/bash

set -eou pipefail

if [ "${CHROOT:-'unset'}" == "unset" ]; then
    echo "CHROOT was not provided."
    exit 1
fi
version="${VERSION:-dev}"

if [ -z "$(which qemu-nbd)" ]; then
    sudo apt-get install -y qemu-utils
fi

rm -f *.qcow2
rm -f *.qcow2.sha256

set -o xtrace

sudo modprobe nbd max_part=8
sudo qemu-nbd --connect=/dev/nbd0 "$CHROOT/scripts/debian-13-generic-amd64.qcow2"
mkdir -p "$CHROOT/mnt"
sleep 1  # Gives the system a beat to ensure the nbd mounts exist
sudo mount /dev/nbd0p1 "$CHROOT/mnt"
sudo mount --bind /dev "$CHROOT/mnt/dev"
sudo mount --bind /proc "$CHROOT/mnt/proc"
sudo mount --bind /sys "$CHROOT/mnt/sys"
sudo mount --bind /run "$CHROOT/mnt/run"

sudo chroot "$CHROOT/mnt" apt-get update
sudo chroot "$CHROOT/mnt" apt-get install -y qemu-guest-agent

sudo umount "$CHROOT/mnt/dev"
sudo umount "$CHROOT/mnt/proc"
sudo umount "$CHROOT/mnt/sys"
sudo umount "$CHROOT/mnt/run"
sudo umount -l "$CHROOT/mnt"
sudo qemu-nbd --disconnect /dev/nbd0

mv "$CHROOT/scripts/debian-13-generic-amd64.qcow2" "orbitlab-debian-13-amd64-${version}.qcow2"
sha256sum "orbitlab-debian-13-amd64-${version}.qcow2" > "orbitlab-debian-13-amd64-${version}.qcow2.sha256"
