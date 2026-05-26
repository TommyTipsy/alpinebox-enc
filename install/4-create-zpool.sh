#!/bin/sh
set -e
source config
echo "ALPINEBOX: Creating zpool on $INSTALL_ZPOOL_DEV"

zgenhostid -f

zpool create \
    -f \
    -o ashift=12 \
    -o autotrim=on \
    -O mountpoint=none \
    -O acltype=posixacl \
    -O compression=on \
    -o autoexpand=on \
    -O dnodesize=auto \
    -O normalization=formD \
    -O relatime=on \
    -O atime=off \
    -O xattr=sa \
    -R $INSTALL_ROOT \
    $INSTALL_ZPOOL $INSTALL_ZPOOL_DEV

if 
[ "$INSTALL_ENCRYPT" = "1" ]; then
    echo
    echo "ALPINEBOX: Set a passphrase for ZFS native encryption."
    echo "ALPINEBOX: You will be prompted for this at every boot in ZFSBootMenu."
    echo "ALPINEBOX: If you forget it, your data is unrecoverable."
    echo

    while :; do
        stty -echo
        printf "Passphrase: "; IFS= read -r PASS1; echo
        printf "Confirm:    "; IFS= read -r PASS2; echo
        stty echo
        if 
[ -z "$PASS1" ]; then
            echo "Passphrase cannot be empty, try again."
            continue
        fi
        if 
[ "$PASS1" != "$PASS2" ]; then
            echo "Passphrases do not match, try again."
            continue
        fi
        break
    done

    ( umask 077 && printf '%s' "$PASS1" > /tmp/rpool.key )
    unset PASS1 PASS2

    zfs create \
        -o mountpoint=/ \
        -o canmount=noauto \
        -o encryption=aes-256-gcm \
        -o keyformat=passphrase \
        -o keylocation=file:///tmp/rpool.key \
        $INSTALL_ZPOOL/ROOT
else
    zfs create -o mountpoint=/ -o canmount=noauto $INSTALL_ZPOOL/ROOT
fi

zpool set bootfs=$INSTALL_ZPOOL/ROOT $INSTALL_ZPOOL

zfs mount $INSTALL_ZPOOL/ROOT

zfs set org.zfsbootmenu:commandline="$APPEND" $INSTALL_ZPOOL/ROOT

echo "ALPINEBOX: Done, $INSTALL_ZPOOL mounted under $INSTALL_ROOT"
