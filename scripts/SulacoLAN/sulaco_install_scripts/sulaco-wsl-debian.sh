#!/usr/bin/env bash
set -e

sudo apt update

sudo apt install -y \
build-essential clang clangd lldb llvm cmake ninja-build gdb valgrind cppcheck \
git openssh-client rsync curl wget \
iproute2 net-tools ethtool tcpdump traceroute mtr nmap dnsutils \
man-db manpages manpages-dev cppman lynx w3m \
vim-nox nano tmux tree htop btop figlet toilet boxes cmatrix lolcat \
python3 python3-pip
# neofetch ???? doesnt want to install

