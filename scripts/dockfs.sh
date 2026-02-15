#!/bin/bash

set -eou pipefail

COMMAND="$1"

getAddress() {
  local ADDRESS="$(ip addr show eth0 | grep "inet\b" | grep "brd" | awk '{print $2}')"
  echo "$ADDRESS"
}

createConfig() {
    local MANIFEST="$1"
    local VIP="$2"
    local VRID="$3"
    local AUTH_SECRET="$4"
    local ADDRESS="$(getAddress)"
    local CIDR="$(ipcalc -n $ADDRESS | awk '/Network/ {print $2}')"
    cat >/etc/default/dockfs <<EOL
MANIFEST=$MANIFEST
VIP=$VIP
CIDR=$CIDR
VRID=$VRID
AUTH_SECRET=$AUTH_SECRET
EOL
}

initializeDockFS() {
    source /etc/default/dockfs
    local DRIVE_ID=$(ls /dev/disk/by-id | grep scsi1)
    local DRIVE_UUID=$(blkid "/dev/disk/by-id/$DRIVE_ID" | cut -d" " -f2 | cut -d"=" -f2 | sed 's/"//g')
    if [ -z "$DRIVE_UUID" ] ; then
      mkfs.ext4 "/dev/disk/by-id/$DRIVE_ID"
      local DRIVE_UUID=$(blkid "/dev/disk/by-id/$DRIVE_ID" | cut -d" " -f2 | cut -d"=" -f2 | sed 's/"//g')
    fi
    mkdir -p /mnt/data
    chmod 0777 /mnt/data
    mkdir -p /exports/data
    if ! mountpoint /exports/data; then
      mount --bind /mnt/data /exports/data
    fi
    local RELOAD_DAEMON=""
    if [ $(cat /etc/fstab | grep "UUID=$DRIVE_UUID  /mnt/data" | wc -l) -lt 1 ]; then
      echo "UUID=$DRIVE_UUID  /mnt/data  ext4  defaults,noatime  0  0" >> /etc/fstab
      local RELOAD_DAEMON="true"
    fi
    if [ $(cat /etc/fstab | grep '/mnt/data /exports/data' | wc -l) -lt 1 ]; then
      echo "/mnt/data /exports/data none bind" >> /etc/fstab
      local RELOAD_DAEMON="true"
    fi
    if [ $(cat /etc/exports | grep "/exports/data $CIDR(rw,sync" | wc -l) -lt 1 ]; then
      echo "/exports/data $CIDR(rw,sync,no_subtree_check,fsid=0,crossmnt)" >> /etc/exports
      local RELOAD_DAEMON="true"
    fi
    [ -z "$RELOAD_DAEMON" ] || systemctl daemon-reload 
    mount -a
    exportfs -r
}

configureKeepalived() {
    source /etc/default/dockfs
    cat >/etc/keepalived/keepalived.conf <<EOL
global_defs {
    router_id DOCKFS
    enable_script_security
    script_user root
}
vrrp_script dockfs_ready {
    script "/usr/bin/dockfs 'check-health'"
    interval 2
    fall 2
    rise 2
}
vrrp_instance DOCKFS_VIP {
    state BACKUP
    interface eth0
    virtual_router_id $VRID
    priority 100
    advert_int 1

    nopreempt

    authentication {
        auth_type PASS
        auth_pass $AUTH_SECRET
    }

    virtual_ipaddress {
        $VIP
    }

    track_script {
        dockfs_ready
    }

    notify_master "/usr/bin/dockfs 'promoted'"
    notify_fault  "/usr/bin/dockfs 'failover'"
    notify_stop  "/usr/bin/dockfs 'failover'"
}
EOL
    systemctl restart keepalived
}

checkHealth() {
    mountpoint -q /mnt/data || exit 1
    [ "$(df --output=source,fstype /mnt/data/)" = "$(df --output=source,fstype /exports/data/)" ] || exit 1
    [ $(exportfs -v | grep "/exports/data" | wc -l) -ge 1 ] || exit 1
    systemctl is-active --quiet nfs-server || exit 1
}

case "$COMMAND" in
    create)
        MANIFEST="$2"
        VIP="$3"
        VRID="$4"
        AUTH_SECRET="$5"
        createConfig "$MANIFEST" "$VIP" "$VRID" "$AUTH_SECRET"
        initializeDockFS
        configureKeepalived
        ;;
    create-passive)
        MANIFEST="$2"
        VIP="$3"
        VRID="$4"
        AUTH_SECRET="$5"
        createConfig "$MANIFEST" "$VIP" "$VRID" "$AUTH_SECRET"
        configureKeepalived
        ;;
    promote)
        initializeDockFS
        ;;
    promoted)
        source /etc/default/dockfs
        ADDRESS="$(getAddress)"
        curl -X POST http://orbital-relay.orbitlab.internal/relay \
            --header "x-orbitlab-event-name: dockfs.reconcile" \
            --header 'x-orbitlab-event-version: v1' \
            --data "{\"manifest\":\"$MANIFEST\", \"address\": \"$ADDRESS\"}"
        ;;
    failover)
        source /etc/default/dockfs
        ADDRESS="$(getAddress)"
        curl -X POST http://orbital-relay.orbitlab.internal/relay \
            --header "x-orbitlab-event-name: dockfs.failover" \
            --header 'x-orbitlab-event-version: v1' \
            --data "{\"manifest\":\"$MANIFEST\", \"address\": \"$ADDRESS\"}"
        ;;
    check-health)
        checkHealth
        ;;
    *)
        echo "Unknown command: $COMMAND" || exit 1
        ;;
esac
