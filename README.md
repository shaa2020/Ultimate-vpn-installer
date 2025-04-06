# Ultimate VPN Installer

**A powerful, production-grade script to deploy a full-featured multi-protocol VPN server in minutes.**

This installer supports:

- **OpenVPN** – Easy-to-use and battle-tested
- **WireGuard** – Fast, modern, and lightweight
- **Xray-core** – VMess protocol with full stream customization
- **Hysteria2** – UDP-based high-performance tunneling
- **SSH Tunnel** – For secure shell access
- **BBR + Optimizations** – Boost speed and reliability

## Features

- One-command installation
- Supports Debian/Ubuntu-based VPS
- Automatically configures firewall and sysctl
- Secure key generation and UUID setup
- Optional TLS (via Hysteria2 self-signed cert)
- Ready for commercial or personal use

## Requirements

- A fresh VPS (Debian/Ubuntu preferred)
- Root access
- 512MB+ RAM
- Open ports for VPN protocols

## Installation

SSH into your VPS and run:

```bash
wget https://raw.githubusercontent.com/shaa2020/ultimate-vpn-installer/main/install.sh
chmod +x install.sh
./install.sh
