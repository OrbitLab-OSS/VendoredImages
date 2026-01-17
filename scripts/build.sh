#!/bin/bash

set -eou pipefail

if [ "${CHROOT:-'unset'}" == "unset" ]; then
    echo "CHROOT was not provided."
    exit 1
fi
version="${VERSION:-dev}"

if [ -z "$(which qemu-img)" ]; then
    sudo apt-get install -y qemu-utils
fi

if [ -z "$(which guestfish)" ]; then
    sudo apt-get install -y guestfish
fi

set -o xtrace

sudo guestfish --rw -i -x --network -a "$CHROOT/scripts/debian-13-generic-amd64.qcow2" <<_EOF_
command "apt-get update"
command "apt-get install -y qemu-guest-agent"
command "systemctl enable qemu-guest-agent"
command "truncate -s 0 /etc/machine-id"
command "rm -f /var/lib/dbus/machine-id"
command "cloud-init clean --logs"
command "apt-get clean"
command "rm -rf /var/log/*"
command "rm -rf /var/lib/apt/lists/*"
_EOF_
mv "$CHROOT/scripts/debian-13-generic-amd64.qcow2" "orbitlab-debian-13-amd64-${version}.qcow2"
sha256sum "orbitlab-debian-13-amd64-${version}.qcow2" > "orbitlab-debian-13-amd64-${version}.qcow2.sha256"
