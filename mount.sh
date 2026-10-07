sudo mkdir -p mnt_og mnt_ovrlay
sudo mount -t erofs -o loop,rw squashfs.img orig
#truncate -s 10G overlay1.img
sudo mount -o loop overlay1.img .l1
sudo mkdir -p .l1/up .l1/swap
sudo mount -t overlay overlay -o lowerdir=orig,upperdir=.l1/up,workdir=.l1/swap root