#!/usr/bin/env bash
set -euo pipefail

sudo apt install iperf            
sudo apt install traceroute       
sudo apt install mtr             
sudo apt install musescore        
sudo apt install net-tools        
sudo apt install iftop            
sudo apt install inxi
sudo apt install wireshark        
sudo apt install dmidecode       
sudo apt install openssh-server
sudo apt install openssh-client

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



sudo apt update && sudo apt upgrade

sudo apt install -y \
build-essential clang clangd lldb llvm cmake ninja-build gdb valgrind cppcheck \
git openssh-client rsync curl wget \
iproute2 net-tools ethtool tcpdump traceroute mtr nmap dnsutils \
man-db manpages manpages-dev cppman lynx w3m \
vim-nox nano tmux tree htop btop
sudo apt install figlet toilet boxes cmatrix lolcat \
python3 python3-pip

