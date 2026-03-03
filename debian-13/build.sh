#!/bin/bash

set -eou pipefail

# Prep
rm -f debian-13-amd64-*.qcow2
cp "$CHROOT/debian-13/debian-13-generic-amd64.qcow2" "$CHROOT/debian-13-generic-amd64.qcow2"

# Run setup commands
source "$CHROOT/common.sh"
mountQcow2 "$CHROOT/debian-13-generic-amd64.qcow2"

# Update, upgrade, and install qemu-guest-agent
sudo chroot "$CHROOT/mnt" apt update
sudo chroot "$CHROOT/mnt" apt upgrade -y
sudo chroot "$CHROOT/mnt" apt install -y qemu-guest-agent

cleanup
mv "$CHROOT/debian-13-generic-amd64.qcow2" "debian-13-amd64-${version}.qcow2"
