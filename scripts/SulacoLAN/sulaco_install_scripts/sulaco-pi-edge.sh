#!/usr/bin/env bash
set -e

sudo apt update

sudo apt install -y \
sudo cron anacron chrony htop btop passwdqc libpam-passwdqc \
iproute2 net-tools nftables iptables dnsmasq tcpdump traceroute mtr nmap ethtool iw wireless-tools wpasupplicant \
iptables-persistent netfilter-persistent bridge-utils \
openssh-server rsync curl wget \
man-db manpages lynx figlet toilet boxes cmatrix \
build-essential python3 python3-pip jq

