FROM quay.io/fedora/fedora-bootc:44

ENV DRACUT_NO_XATTR=1

RUN <<EOF
set -xeuo pipefail

# RPM fusion
dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
# for copr to work:
dnf install -y dnf5-plugins
EOF

#Cachyos kernel
RUN dnf remove -y --setopt=protect_running_kernel=false kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra
RUN <<EOF
dnf copr enable -y bieszczaders/kernel-cachyos
dnf install -y --setopt=tsflags=noscripts kernel-cachyos kernel-cachyos-devel-matched
EOF


#Cachyos addons
RUN <<EOF
dnf copr enable -y bieszczaders/kernel-cachyos-addons
dnf swap -y zram-generator-defaults cachyos-settings
dnf install -y scx-scheds scx-tools ananicy-cpp
systemctl enable ananicy-cpp
EOF

#add iommu support via dracut conf
RUN mkdir -p /etc/dracut.conf.d && echo 'add_drivers+=" vfio vfio_iommu_type1 vfio_pci vfio_virqfd "' > /etc/dracut.conf.d/vfio.conf

#dracut
RUN <<EOF
mkdir -p /var/roothome
KVER=$(rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}\n' kernel-cachyos-core) && echo "Kernel version: $KVER" && depmod -a "$KVER" && dracut --no-hostonly --reproducible --add ostree -f "/usr/lib/modules/$KVER/initramfs.img" "$KVER"
EOF

#nvidia
RUN dnf install -y kernel-devel
RUN dnf install -y --allowerasing --setopt=tsflags=noscripts akmod-nvidia xorg-x11-drv-nvidia-cuda
RUN mkdir -p /usr/lib/bootc/kargs.d && echo 'kargs = ["rd.driver.blacklist=nouveau", "modprobe.blacklist=nouveau", "nvidia-drm.modeset=1"]' > /usr/lib/bootc/kargs.d/01-nvidia.toml
RUN KVER=$(rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}' kernel-cachyos-core) && akmods --force --kernels $KVER

# Brave origin
RUN <<EOF
# mkdir -p /var/opt
# dnf install -y dnf-plugins-core
dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
dnf install -y brave-origin
# mkdir -p /usr/lib/opt && mv /var/opt/brave.com /usr/lib/opt/brave.com
# mkdir -p /usr/lib/tmpfiles.d && echo 'L+ /var/opt/brave.com - - - - /usr/lib/opt/brave.com' > /usr/lib/tmpfiles.d/brave-opt.conf
EOF

# for wifi:
RUN dnf install -y NetworkManager-wifi wpa_supplicant iwlwifi-mvm-firmware

#mullvad
RUN dnf config-manager addrepo --from-repofile=https://repository.mullvad.net/rpm/stable/mullvad.repo && dnf install -y mullvad-vpn


RUN dnf install -y vim fastfetch tailscale fish distrobox btop flatpak @virtualization langpacks-en

RUN dnf install -y niri noctalia foot jetbrains-mono-fonts krusader unrar nmtui flameshot

RUN systemctl enable tailscaled.service libvirtd.service



#nix
#RUN curl -fsSL https://install.determinate.systems/nix | sh -s -- install linux --no-start-daemon --no-confirm
#RUN mkdir -p /nix/var/nix/profiles/per-user/root/channels
#RUN rm -rf /etc/tmpfiles.d/*

RUN dnf clean all

RUN bootc container lint
