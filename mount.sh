sudo mkdir -p mnt_og mnt_1 root
sudo mount -t erofs -o loop squashfs.img mnt_og
if [ ! -f overlay1.img ]; then
    truncate -s 20G overlay1.img
    mkfs.ext4 overlay1.img
fi
sudo mount -o loop overlay1.img mnt_1
sudo mkdir -p mnt_1/root mnt_1/swap
sudo mount -t overlay overlay -o lowerdir=mnt_og,upperdir=mnt_1/root,workdir=mnt_1/swap root