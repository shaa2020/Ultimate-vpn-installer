#!/bin/bash

# Ultimate VPN Installer - By Hasibo
# Supports: OpenVPN, WireGuard, Xray (VMess, VLESS, Trojan, Reality), SSH Tunnel, Hysteria2

# Basic checks
if [[ $EUID -ne 0 ]]; then
   echo "Please run this script as root."
   exit 1
fi

# Variables
WG_PORT=51820
OVPN_PORT=1194
XRAY_PORT=443
HY_PORT=5678
SSH_PORT=22

# Install dependencies
apt update && apt upgrade -y
apt install -y curl wget git nano lsb-release unzip qrencode socat net-tools gnupg

# Enable IPv4 forwarding
echo "Enabling IP forwarding..."
sysctl -w net.ipv4.ip_forward=1
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
sysctl -p

# Install BBR (TCP Optimization)
echo "Installing BBR..."
modprobe tcp_bbr
echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p

# Install OpenVPN
echo "Installing OpenVPN..."
wget https://git.io/vpn -O openvpn-install.sh
chmod +x openvpn-install.sh
AUTO_INSTALL=y ./openvpn-install.sh

# Install WireGuard
echo "Installing WireGuard..."
apt install -y wireguard
umask 077
wg genkey | tee /etc/wireguard/server_private.key | wg pubkey > /etc/wireguard/server_public.key

SERVER_PRIV_KEY=$(cat /etc/wireguard/server_private.key)
SERVER_PUB_KEY=$(cat /etc/wireguard/server_public.key)
WG_CONF="/etc/wireguard/wg0.conf"
SERVER_IP=$(curl -s ifconfig.me)

cat > $WG_CONF <<EOF
[Interface]
Address = 10.66.66.1/24
ListenPort = $WG_PORT
PrivateKey = $SERVER_PRIV_KEY

[Peer]
PublicKey = PLACEHOLDER
AllowedIPs = 10.66.66.2/32
EOF

systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

# Install Xray Core
echo "Installing Xray..."
bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)
mkdir -p /etc/xray
UUID=$(cat /proc/sys/kernel/random/uuid)

cat > /etc/xray/config.json <<EOF
{
  "inbounds": [{
    "port": $XRAY_PORT,
    "protocol": "vmess",
    "settings": {
      "clients": [{"id": "$UUID"}]
    },
    "streamSettings": {
      "network": "tcp"
    }
  }],
  "outbounds": [{"protocol": "freedom"}]
}
EOF

systemctl enable xray
systemctl start xray

# Install Hysteria2
echo "Installing Hysteria2..."
curl -L -o hysteria.tar.gz https://github.com/apernet/hysteria/releases/latest/download/hysteria-linux-amd64.tar.gz
mkdir -p /usr/local/bin/hysteria2
tar -xvzf hysteria.tar.gz -C /usr/local/bin/hysteria2 --strip-components=1
chmod +x /usr/local/bin/hysteria2/hysteria

cat > /etc/hysteria2.yaml <<EOF
listen: :$HY_PORT
tls:
  cert: /etc/ssl/certs/self.crt
  key: /etc/ssl/private/self.key
auth:
  password: yourpassword
EOF

nohup /usr/local/bin/hysteria2/hysteria server -c /etc/hysteria2.yaml &

# Firewall setup
echo "Configuring firewall..."
ufw allow $WG_PORT/udp
ufw allow $OVPN_PORT/udp
ufw allow $XRAY_PORT/tcp
ufw allow $HY_PORT/udp
ufw allow $SSH_PORT
ufw --force enable

# Summary
echo -e "

===== INSTALLATION COMPLETE ====="
echo "VPN Server IP: $SERVER_IP"
echo "OpenVPN: TCP/UDP $OVPN_PORT"
echo "WireGuard: UDP $WG_PORT"
echo "Xray (VMess): TCP $XRAY_PORT"
echo "Hysteria2: UDP $HY_PORT"
echo "UUID: $UUID"
echo "WG Server Public Key: $SERVER_PUB_KEY"
echo "=================================
"
