#!/bin/bash

set -eou pipefail

# Prep
rm -f fedora-43-amd64-*.qcow2
cp "$CHROOT/fedora-43/fedora-43-generic-amd64.qcow2" "$CHROOT/fedora-43-generic-amd64.qcow2"

# Run setup commands
source "$CHROOT/common.sh"
mountQcow2 "$CHROOT/fedora-43-generic-amd64.qcow2"

# Update, upgrade, and install qemu-guest-agent
sudo chroot "$CHROOT/mnt" dnf upgrade -y --refresh
sudo chroot "$CHROOT/mnt" dnf install -y qemu-guest-agent
sudo chroot "$CHROOT/mnt" dnf clean all
sudo rm -rf "$CHROOT/mnt/var/cache/dnf"
sudo rm -rf "$CHROOT/mnt/var/cache/yum"
sudo rm -rf "$CHROOT/mnt/var/lib/dnf/history*"

prep
cleanup
qemu-img convert -O qcow2 -c "$CHROOT/fedora-43-generic-amd64.qcow2" "fedora-43-amd64-${version}.qcow2"
