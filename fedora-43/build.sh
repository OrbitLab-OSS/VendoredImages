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

cleanup
mv "$CHROOT/fedora-43-generic-amd64.qcow2" "fedora-43-amd64-${version}.qcow2"
