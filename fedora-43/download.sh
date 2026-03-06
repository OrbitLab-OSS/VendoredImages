#!/bin/bash

set -eou pipefail

wget https://download.fedoraproject.org/pub/fedora/linux/releases/43/Cloud/x86_64/images/Fedora-Cloud-Base-GCE-43-1.6.x86_64.tar.gz \
    -O fedora-43-cloud-base.tar.gz

tar -xzvf fedora-43-cloud-base.tar.gz
qemu-img convert -O qcow2 disk.raw fedora-43-generic-amd64.qcow2
