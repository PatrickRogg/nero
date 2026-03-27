#!/usr/bin/env bash
set -euo pipefail

if [[ -f /etc/os-release ]]; then
  . /etc/os-release
else
  printf 'Cannot detect operating system.\n' >&2
  exit 1
fi

if [[ "${ID:-}" != "ubuntu" || "${VERSION_ID:-}" != "24.04" ]]; then
  printf 'This script is intended for Ubuntu 24.04. Detected %s %s.\n' "${ID:-unknown}" "${VERSION_ID:-unknown}" >&2
  exit 1
fi

if [[ "${EUID}" -ne 0 ]]; then
  printf 'Please run this script as root: sudo bash scripts/bootstrap-ubuntu-24.sh\n' >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get upgrade -y
apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  git \
  gnupg \
  lsb-release \
  nano \
  openssl \
  rsync \
  software-properties-common \
  tar \
  ufw

install -m 0755 -d /etc/apt/keyrings

if [[ ! -f /etc/apt/keyrings/docker.asc ]]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
fi

arch="$(dpkg --print-architecture)"
codename="$(. /etc/os-release && printf '%s' "$VERSION_CODENAME")"

cat > /etc/apt/sources.list.d/docker.list <<EOF
deb [arch=${arch} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${codename} stable
EOF

apt-get update
apt-get install -y --no-install-recommends \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

systemctl enable docker
systemctl start docker

ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

printf '\nUbuntu 24.04 bootstrap complete.\n'
printf 'Installed: Docker Engine, Docker Compose plugin, git, curl, rsync, nano, ufw.\n'
printf 'Firewall: OpenSSH, 80/tcp, and 443/tcp allowed.\n'
printf 'Next: cp .env.example .env && bash scripts/install.sh\n'
