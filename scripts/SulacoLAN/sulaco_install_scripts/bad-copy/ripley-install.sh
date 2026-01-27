#!/usr/bin/env bash
set -euo pipefail

# Ripley WSL: Sulaco bundle install (recorded from apt history)
# Source: /var/log/apt/history.log* tail :contentReference[oaicite:3]{index=3}

sudo apt-get update

sudo apt-get install -y \
  build-essential clang clangd lldb llvm cmake ninja-build gdb valgrind cppcheck \
  git openssh-client rsync curl wget \
  iproute2 net-tools ethtool tcpdump traceroute mtr nmap dnsutils \
  man-db manpages manpages-dev cppman lynx w3m \
  vim-nox nano tmux tree htop btop \
  figlet toilet boxes cmatrix lolcat \
  python3 python3-pip
sudo apt-get install -y \
  chromium libreoffice wireshark musescore \
  nodejs npm \
  mesa-utils xorg-dev

