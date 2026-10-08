set -ex

PKG_RM=(
    "@kde-apps"
    "@kde-pim"
    "@libreoffice"
    "@desktop-accessibility"
    "@guest-desktop-agents"
    "@printing"
    "*abrt*"
    "libreoffice*"
    "plymouth*"
    "sssd*"
    "tuned*"
    dracut-config-rescue
    firefox
    firefox-langpacks
    gssproxy
    kaddressbook
    kdebugsettings
    kmailtransport
    plasma-discover-notifier
    plasma-workspace-wallpapers
    elisa-player
    nfs-utils
    thunderbird
)
PKG_NVIDIA=(
    akmod-nvidia
    xorg-x11-drv-nvidia
    xorg-x11-drv-nvidia-cuda
)
PKG_APPS=(
    brave-origin
    fontforge
    ghostty
    obs-studio
    koko
    mpv
    pinta
    qbittorrent
    xournal
    vlc
    drawy
    calibre
    dnfdragora
)
PKG_TOOLS=(
    aria2
    btop
    htop
    jq
    distrobox
    podman
    podman-compose
    podman-docker
    rclone
    umu-launcher
    zsh
    zsh-autosuggestions
    zsh-syntax-highlighting
    virt-manager
    power-profiles-daemon
    systemd-boot-unsigned
)
PKG_DEVEL=(
    ccache
    clang
    clangd
    zed
    git-lfs
)
PKG_CODEC=(
    ffmpeg
    libavcodec-freeworld
)
PKG_VN=(
    fcitx5-lotus
    papirus-icon-theme
    jetbrains-mono-fonts
    fira-code-fonts
)
PKG_ADD=(
    ${PKG_CODEC[*]}
    ${PKG_APPS[*]}
    ${PKG_TOOLS[*]}
    ${PKG_DEVEL[*]}
    ${PKG_VN[*]}
)

systemctl disable systemd-networkd-wait-online.service
systemctl disable NetworkManager-wait-online.service
echo -e "\ninstallonly_limit=2\ninstall_weak_deps=0" | tee -a /etc/dnf/dnf.conf
echo -e "\nblacklist nouveau\nalias nouveau off" > /etc/modprobe.d/nouveau.conf
sed -i 's/=enforcing/=permissive/g' /etc/selinux/config
find /boot -name "*0-rescue*" -delete

# cleanup
PKG_RM+=(intel-gpu-firmware) # TODO: remove in F35; conflicts with linux-firmware
dnf remove --assumeyes ${PKG_RM[*]}
dnf autoremove --assumeyes

# install repo
FEDORA_VER=$(rpm -E %fedora)
KERNEL_OLD=$(rpm -q kernel)

dnf install --assumeyes --nogpgcheck \
    --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release
dnf install --assumeyes --nogpgcheck \
    https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$FEDORA_VER.noarch.rpm \
    https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$FEDORA_VER.noarch.rpm
dnf config-manager addrepo --from-repofile="https://brave-browser-rpm-release.s3.brave.com/brave-browser-stable.repo"
dnf config-manager addrepo --from-repofile="https://pkg.cloudflareclient.com/cloudflare-warp-ascii.repo"
dnf config-manager addrepo --from-repofile="https://pkg.cloudflare.com/cloudflared.repo"
dnf config-manager addrepo --from-repofile="https://fcitx5-lotus.pages.dev/rpm/fedora/fcitx5-lotus-$FEDORA_VER.repo"

dnf update --assumeyes --refresh
dnf remove --assumeyes "*${KERNEL_OLD}*"

# install pkgs

dnf install --assumeyes ${PKG_NVIDIA[*]}
until rpm -qa "kmod-nvidia-*"; do
    echo "Waiting driver build to finish..."
    sleep 5
done

dnf install --assumeyes --allowerasing ${PKG_CODEC[*]}
# dnf install --assumeyes ${PKG_ADD[*]}

cd /boot
dracut --verbose --reproducible --no-hostonly --no-hostonly-cmdline --add " dmsquash-live livenet pollcdrom " initrd
cp vmlinuz-* linux
chmod 777 initrd linux
cd -
