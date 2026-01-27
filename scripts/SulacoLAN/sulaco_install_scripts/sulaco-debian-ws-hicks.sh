#!/usr/bin/env bash
set -euo pipefail

# Sulaco DWP-1: Debian Workstation (Hicks)
# - XFCE desktop
# - C/C++ toolchain + LLVM/Clang
# - Vim (vim-nox), docs (manpages-dev, cppman, lynx/w3m)
# - Networking tools
# - Optional: Docker CE (matches your Hicks inventory) :contentReference[oaicite:2]{index=2}

LOG="${LOG:-/var/log/sulaco-dwp1-hicks.log}"
exec > >(tee -a "$LOG") 2>&1

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: Run as root (sudo)."
  exit 1
fi

echo "=== Sulaco DWP-1 (Debian Workstation) provisioning start ==="
date

# ---------- Config toggles ----------
INSTALL_XFCE="${INSTALL_XFCE:-1}"
INSTALL_DOCKER_CE="${INSTALL_DOCKER_CE:-1}"   # Docker CE + buildx + compose plugin

# ---------- Helpers ----------
apt_install() {
  local pkgs=("$@")
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${pkgs[@]}"
}

has_cmd() { command -v "$1" >/dev/null 2>&1; }

echo "[1/8] Update base OS..."
apt-get update -y
apt-get upgrade -y

echo "[2/8] Install core utilities..."
apt_install \
  sudo ca-certificates gnupg lsb-release apt-transport-https \
  curl wget rsync jq \
  unzip zip xz-utils bzip2 gzip tar \
  tree less

echo "[3/8] Install editors + shell productivity..."
apt_install \
  vim vim-nox nano tmux \
  htop btop

echo "[4/8] Install development toolchain (C/C++ + LLVM) + analysis..."
apt_install \
  build-essential make cmake ninja-build pkg-config \
  gdb valgrind cppcheck \
  clang llvm lldb clangd

echo "[5/8] Install docs / offline reference..."
apt_install \
  man-db manpages manpages-dev \
  cppman \
  lynx w3m

echo "[6/8] Install networking / troubleshooting tools..."
apt_install \
  iproute2 net-tools ethtool \
  tcpdump traceroute mtr nmap \
  dnsutils \
  nfs-kernel-server nfs-common
  # for the host ^, for the clients ^

echo "[7/8] Optional: XFCE desktop (Hicks canonical UI layer)..."
if [[ "$INSTALL_XFCE" == "1" ]]; then
  # Mirrors the Hicks "task-xfce-desktop" style footprint. :contentReference[oaicite:3]{index=3}
  apt_install \
    task-xfce-desktop lightdm lightdm-gtk-greeter
fi

echo "[8/8] Optional: Docker CE (Debian repo install)..."
if [[ "$INSTALL_DOCKER_CE" == "1" ]]; then
  if ! has_cmd docker; then
    echo "Installing Docker CE repo + packages..."
    install -m 0755 -d /etc/apt/keyrings

    curl -fsSL https://download.docker.com/linux/debian/gpg \
      | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    chmod a+r /etc/apt/keyrings/docker.gpg

    CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"
    ARCH="$(dpkg --print-architecture)"

    cat >/etc/apt/sources.list.d/docker.list <<EOF
deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian ${CODENAME} stable
EOF

    apt-get update -y

    apt_install docker-ce docker-ce-cli containerd.io \
      docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras

    systemctl enable --now docker || true
  else
    echo "Docker already present; skipping."
  fi
fi

echo "=== Sulaco DWP-1 (Hicks) provisioning complete ==="
date
echo "Log: $LOG"

