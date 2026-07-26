#!/usr/bin/env bash
set -Eeuo pipefail

export DEBIAN_FRONTEND=noninteractive

for package in \
  docker.io \
  docker-doc \
  docker-compose \
  docker-compose-v2 \
  podman-docker \
  containerd \
  runc
do
  apt-get remove -y "${package}" 2>/dev/null || true
done

install -m 0755 -d /etc/apt/keyrings

curl -fsSL \
  https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc

chmod a+r /etc/apt/keyrings/docker.asc

cat > /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

apt-get update

docker_version='5:29.6.1-1~ubuntu.24.04~noble'

apt-get install -y \
  "docker-ce=${docker_version}" \
  "docker-ce-cli=${docker_version}" \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

install -d \
  -m 0755 \
  /etc/docker

cat > /etc/docker/daemon.json <<'EOF'
{
  "live-restore": true,
  "log-driver": "local",
  "log-opts": {
    "max-size": "20m"
  },
  "default-address-pools": [
    {
      "base": "172.30.0.0/16",
      "size": 24
    },
    {
      "base": "172.31.0.0/16",
      "size": 24
    }
  ]
}
EOF

systemctl daemon-reload
systemctl enable docker.service
systemctl enable containerd.service
systemctl restart containerd
systemctl restart docker

apt-mark hold \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

docker version
docker compose version
docker info

if ss -lntp | grep -qE ':(2375|2376)\b'; then
  echo "Docker remote TCP API is exposed." >&2
  exit 1
fi

docker run --rm hello-world

docker image rm hello-world:latest || true


