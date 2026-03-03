#1/bin/bash

cleanup() {
    if mountpoint "$CHROOT/mnt/proc"; then
        sudo umount "$CHROOT/mnt/proc"
    fi
    if mountpoint "$CHROOT/mnt/sys"; then
        sudo umount "$CHROOT/mnt/sys"
    fi
    if mountpoint "$CHROOT/mnt/dev/pts"; then
        sudo umount "$CHROOT/mnt/dev/pts"
    fi
    if mountpoint "$CHROOT/mnt/dev"; then
        sudo umount "$CHROOT/mnt/dev"
    fi
    if mountpoint "$CHROOT/mnt/run"; then
        sudo umount "$CHROOT/mnt/run"
    fi
    if mountpoint "$CHROOT/mnt"; then
        sudo umount -l "$CHROOT/mnt"
    fi
    sudo qemu-nbd --disconnect /dev/nbd0
}

mountQcow2() {
    local image="$1"

    mkdir -p "$CHROOT/mnt"

    sudo modprobe nbd max_part=8
    sudo qemu-nbd --connect=/dev/nbd0 "$image"
    sleep 1  # Gives the system a beat to ensure the nbd mounts exist

    if [[  "$image" == *"debian-13"*  ]]; then
        sudo mount /dev/nbd0p1 "$CHROOT/mnt"
    elif [[ "$image" == *"fedora-43"* ]]; then
        sudo mount -o subvol=root /dev/nbd0p4 "$CHROOT/mnt"
        sudo mount /dev/nbd0p3 "$CHROOT/mnt/boot"
    else
        echo "Unknown image: $image" && exit 1
    fi

    sudo mount --bind /dev "$CHROOT/mnt/dev"
    sudo mount --bind /dev/pts "$CHROOT/mnt/dev/pts"
    sudo mount --bind /proc "$CHROOT/mnt/proc"
    sudo mount --bind /sys "$CHROOT/mnt/sys"
    sudo mount --bind /run "$CHROOT/mnt/run"

    set -o xtrace
}

if [ "${CHROOT:-'unset'}" == "unset" ]; then
    echo "CHROOT was not provided."
    exit 1
fi
version="$(date -u +"%Y%m%d")"

if [ -z "$(which qemu-nbd)" ]; then
    sudo apt-get install -y qemu-utils
fi

trap "cleanup" EXIT INT TERM