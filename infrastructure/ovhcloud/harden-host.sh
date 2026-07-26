#!/usr/bin/env bash
set -Eeuo pipefail

host_role="${1:?Host role is required}"
admin_public_cidr="${2:?Administrator CIDR is required}"
mgmt_private_ip="${3:?Management private IP is required}"

case "${host_role}" in
  mgmt|app|db|cache|obs)
    ;;
  *)
    echo "Invalid role: ${host_role}" >&2
    exit 1
    ;;
esac

export DEBIAN_FRONTEND=noninteractive

apt-get update

apt-get install -y \
  apparmor \
  apparmor-utils \
  auditd \
  audispd-plugins \
  ca-certificates \
  chrony \
  curl \
  debsums \
  fail2ban \
  git \
  gnupg \
  htop \
  jq \
  libpam-pwquality \
  logrotate \
  lsof \
  needrestart \
  net-tools \
  nftables \
  openssl \
  rsync \
  sysstat \
  ufw \
  unattended-upgrades \
  unzip \
  vim \
  xfsprogs

apt-get dist-upgrade -y

systemctl enable --now \
  apparmor \
  auditd \
  chrony \
  fail2ban \
  fstrim.timer \
  sysstat

install -d \
  -m 0750 \
  -o root \
  -g adm \
  /var/log/cetech

cat > /etc/ssh/sshd_config.d/10-cetech-hardening.conf <<EOF
Protocol 2

PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
PubkeyAuthentication yes
AuthenticationMethods publickey

PermitEmptyPasswords no
UsePAM yes

X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding no
PermitTunnel no
GatewayPorts no

ClientAliveInterval 300
ClientAliveCountMax 2
LoginGraceTime 30
MaxAuthTries 3
MaxSessions 5
MaxStartups 10:30:30

IgnoreRhosts yes
HostbasedAuthentication no

LogLevel VERBOSE
AllowUsers cetechops root

Match User root Address ${mgmt_private_ip}
    PermitRootLogin prohibit-password
    AllowTcpForwarding no
    X11Forwarding no
EOF

sshd -t

cat > /etc/sysctl.d/99-cetech-security.conf <<'EOF'
# Source routing and redirect protections.
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Log suspicious packets.
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Loose mode - recommended for multi-homed servers.
net.ipv4.conf.all.rp_filter = 2
net.ipv4.conf.default.rp_filter = 2

# Basic TCP protections.
net.ipv4.tcp_syncookies = 1

# Restrict kernel information exposure.
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
kernel.yama.ptrace_scope = 1

# Protect symlink and hardlink operations.
fs.protected_fifos = 2
fs.protected_regular = 2
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
EOF

sysctl --system

cat > /etc/security/limits.d/99-cetech.conf <<'EOF'
* soft nofile 65535
* hard nofile 65535
root soft nofile 65535
root hard nofile 65535
EOF

install -d \
  -m 0755 \
  /etc/systemd/journald.conf.d
  
cat > /etc/systemd/journald.conf.d/99-cetech.conf <<'EOF'
[Journal]
Storage=persistent
Compress=yes
SystemMaxUse=2G
RuntimeMaxUse=512M
MaxRetentionSec=14day
ForwardToSyslog=no
EOF

systemctl restart systemd-journald

cat > /etc/fail2ban/jail.d/cetech-sshd.local <<'EOF'
[sshd]
enabled = true
mode = aggressive
backend = systemd
maxretry = 4
findtime = 10m
bantime = 1h
bantime.increment = true
bantime.factor = 2
bantime.maxtime = 1w
EOF

systemctl restart fail2ban

cat > /etc/apt/apt.conf.d/52cetech-unattended-upgrades <<'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
};

Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";

Unattended-Upgrade::Automatic-Reboot "false";
EOF

cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

cat > /etc/audit/rules.d/cetech.rules <<'EOF'
-w /etc/passwd -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/sudoers -p wa -k privilege
-w /etc/sudoers.d/ -p wa -k privilege
-w /etc/ssh/sshd_config -p wa -k ssh
-w /etc/ssh/sshd_config.d/ -p wa -k ssh
-w /etc/docker/ -p wa -k docker
-w /etc/systemd/system/ -p wa -k systemd
EOF

augenrules --load

ufw --force reset
ufw default deny incoming
ufw default allow outgoing

ufw allow \
  from "${admin_public_cidr}" \
  to any \
  port 22 \
  proto tcp \
  comment 'CETECH administrator SSH'

ufw allow \
  from "${mgmt_private_ip}" \
  to any \
  port 22 \
  proto tcp \
  comment 'CETECH management SSH'

case "${host_role}" in
  mgmt)
    ufw allow \
      from "${admin_public_cidr}" \
      to any \
      port 3000 \
      proto tcp \
      comment 'Temporary Dokploy setup'

    ufw allow \
      from "${admin_public_cidr}" \
      to any \
      port 80 \
      proto tcp \
      comment 'Temporary panel HTTP'

    ufw allow \
      from "${admin_public_cidr}" \
      to any \
      port 443 \
      proto tcp \
      comment 'Temporary panel HTTPS'
    ;;

  app)
    ufw allow \
      from 10.40.0.0/16 \
      to any \
      port 80 \
      proto tcp \
      comment 'Private LB HTTP'

    ufw allow \
      from 10.40.0.0/16 \
      to any \
      port 443 \
      proto tcp \
      comment 'Private LB HTTPS'
    ;;

  db)
    ufw allow \
      from 10.40.20.11 \
      to any \
      port 3306 \
      proto tcp \
      comment 'app-a MariaDB'

    ufw allow \
      from 10.40.20.12 \
      to any \
      port 3306 \
      proto tcp \
      comment 'app-b MariaDB'
    ;;

  cache)
    for source in 10.40.20.11 10.40.20.12; do
      ufw allow \
        from "${source}" \
        to any \
        port 6379:6381 \
        proto tcp \
        comment 'Application Valkey'
    done
    ;;

  obs)
    for port in 3100 4317 4318 9093; do
      ufw allow \
        from 10.40.0.0/16 \
        to any \
        port "${port}" \
        proto tcp \
        comment 'Private observability ingestion'
    done

    for port in 3000 9090; do
      ufw allow \
        from "${mgmt_private_ip}" \
        to any \
        port "${port}" \
        proto tcp \
        comment 'Management observability access'
    done
    ;;
esac

ufw --force enable

systemctl restart ssh

echo "${host_role}" \
  > /etc/cetech-host-role

chmod 0644 /etc/cetech-host-role

touch /var/log/cetech/hardening-complete
date -u --iso-8601=seconds \
  > /var/log/cetech/hardening-complete
