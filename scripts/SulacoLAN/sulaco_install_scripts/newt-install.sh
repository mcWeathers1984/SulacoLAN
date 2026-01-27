#!/usr/bin/env bash
set -e

sudo apt update

sudo apt install -y \
build-essential clang clangd clang-tools-19 lldb llvm-19 gdb valgrind cppcheck cmake meson ninja-build \
git rsync curl wget lynx tmux tree htop btop figlet toilet boxes lolcat \
iproute2 net-tools ethtool tcpdump nmap traceroute mtr nftables iptables-persistent dnsmasq isc-dhcp-server chrony \
openssh-server ufw netfilter-persistent \
vim-nox nano ncdu p7zip-full unzip zip \
python3 python3-dev python3-venv python3-pip python-is-python3 \
python3-gpiozero python3-libgpiod python3-spidev python3-rpi-lgpio \
raspi-config raspi-firmware raspberrypi-sys-mods raspberrypi-net-mods rpi-update \
vlc ffmpeg chromium firefox \
mesa-utils vulkan-tools xorg xserver-xorg lightdm openbox pcmanfm lxterminal mousepad \
pipewire pipewire-pulse bluez bluetooth wireless-tools wpasupplicant \
isc-dhcp-server dnsmasq

