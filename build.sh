#!/bin/bash
set -ex

ISO=Fedora-KDE-Desktop-Live-44-1.7.x86_64.iso
ISO_OUT=AAAAAA.iso
ROOTFS=LiveOS/squashfs.img
IMG_ARGS='-Efragments -C 1048576 -z lzma,level=6 --exclude-regex=^image$ --exclude-regex=^.kconfig$ --exclude-regex=^run/.*$ --exclude-regex=^tmp/.*$ --exclude-regex=^.buildenv$ --exclude-regex=^var/cache/kiwi$'

if [ ! -d iso ]; then
    mkdir iso
    cd iso
    7z x -x!"[BOOT]" ../$ISO
    mv $ROOTFS ..
    cd ..
fi
if [ ! -d root ]; then
    mkdir root
    # sudo fsck.erofs --extract=root squashfs.img
    . mount.sh
fi

sudo cp -f chroot.sh root
sudo systemd-nspawn -D root --resolv-conf bind-host -- /usr/bin/bash /chroot.sh

sudo mv root/boot/initrd root/boot/linux iso/boot/x86_64/loader/
sudo chown 1000:1000 iso/boot/x86_64/loader/initrd iso/boot/x86_64/loader/linux
sudo mkfs.erofs iso/$ROOTFS root $IMG_ARGS
cp -f grub.cfg iso/boot/grub2/grub.cfg
xorriso -indev $ISO -outdev $ISO_OUT -update_r iso / -boot_image any replay
