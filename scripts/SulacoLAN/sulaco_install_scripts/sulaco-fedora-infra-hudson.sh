#!/usr/bin/env bash
set -euo pipefail

# Sulaco FIP-1: Fedora Headless Infra (Hudson)
# - Headless: no desktop environment
# - Toolchains: GCC + Clang/LLDB + CMake + GDB + Valgrind + cppcheck
# - Infra: cockpit, firewalld/nftables, samba/nfs, mdadm/lvm, nvme tools
# - Net tools: tcpdump, nmap, bind-utils, wireshark-cli
# Based on Hudson RPM inventory. :contentReference[oaicite:5]{index=5}

LOG="${LOG:-/var/log/sulaco-fip1-hudson.log}"
exec > >(tee -a "$LOG") 2>&1

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: Run as root (sudo)."
  exit 1
fi

echo "=== Sulaco FIP-1 (Fedora Headless Infra) provisioning start ==="
date

# Prefer dnf5 if present, else fall back to dnf.
DNF="dnf"
if command -v dnf5 >/dev/null 2>&1; then
  DNF="dnf5"
fi

echo "Using package manager: $DNF"

$DNF -y update

# ---------- Core utilities ----------
$DNF -y install \
  sudo curl wget2 rsync jq \
  unzip zip xz bzip2 gzip tar \
  tree less \
  nano vim-enhanced tmux \
  htop btop

# ---------- Dev toolchain ----------
$DNF -y install \
  gcc gcc-c++ cpp \
  make cmake \
  gdb gdb-headless \
  clang clang-tools-extra lldb llvm-libs \
  valgrind valgrind-docs \
  cppcheck \
  ctags

# ---------- Docs ----------
$DNF -y install \
  man-db man-pages pinfo

# ---------- Networking / troubleshooting ----------
$DNF -y install \
  iproute net-tools iputils ipcalc \
  ethtool \
  tcpdump traceroute mtr \
  nmap nmap-ncat \
  bind-utils \
  whois \
  wireshark-cli

# ---------- Firewall / SELinux / diagnostics ----------
$DNF -y install \
  firewalld nftables \
  policycoreutils policycoreutils-python-utils \
  setroubleshoot-server \
  logrotate mcelog \
  smartmontools

# ---------- Storage / NAS ----------
$DNF -y install \
  mdadm lvm2 \
  btrfs-progs xfsprogs exfatprogs ntfs-3g \
  parted nvme-cli \
  nfs-utils \
  cifs-utils samba-common samba-common-libs

# ---------- Cockpit control plane ----------
$DNF -y install \
  cockpit cockpit-storaged cockpit-networkmanager cockpit-selinux

systemctl enable --now firewalld || true
systemctl enable --now cockpit.socket || true

echo "=== Sulaco FIP-1 (Hudson) provisioning complete ==="
date
echo "Log: $LOG"

