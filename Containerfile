FROM quay.io/fedora/fedora-kinoite:44

RUN <<EOF
set -xeuo pipefail

dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

dnf install -y vim fastfetch

dnf install -y kernel-devel

dnf install -y --allowerasing --setopt=tsflags=noscripts akmod-nvidia xorg-x11-drv-nvidia-cuda

akmods --force --kernels $(rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}' kernel-devel)

dnf clean all
EOF

RUN mkdir -p /usr/lib/bootc/kargs.d && echo 'kargs = ["rd.driver.blacklist=nouveau", "modprobe.blacklist=nouveau", "nvidia-drm.modeset=1"]' > /usr/lib/bootc/kargs.d/01-nvidia.toml

RUN bootc container lint
