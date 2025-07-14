# 🦏 GreyRhinoSec Xray Stealth C2 Proxy

![Platform](https://img.shields.io/badge/Platform-Kali%20%7C%20Ubuntu-informational?logo=linux)
![Debian package](https://img.shields.io/badge/Install-.deb-blue?logo=debian)
![License: MIT](https://img.shields.io/badge/License-MIT-green)
![Status](https://img.shields.io/badge/Status-Operational-brightgreen)

---

## About

**GreyRhinoSec Xray C2 XTunnel** is a stealth SOCKS5 proxy tunneling solution for red teams, operators, and security researchers.
It leverages Xray-core’s VMess over WebSocket+TLS (HTTPS lookalike), with Nginx reverse proxy for maximum camouflage.  
Includes watchdog/failover healthcheck, systemd auto-start, desktop launcher, and full custom branding.

---

## Features

- Stealth WebSocket+TLS (HTTPS-camouflaged) proxy tunnel
- Systemd autostart for 24/7 ops
- Watchdog/failover healthcheck (cron, logs, auto-recovery)
- Desktop launcher and custom icon
- Easy `.deb` package install for instant deploy
- **Branding ready:** icon, launcher, docs, banners

---

## Prerequisites

- Debian, Ubuntu, Kali, or other modern Debian-based Linux
- systemd, curl, cron (usually pre-installed)
- [Xray-core binary](https://github.com/XTLS/Xray-core/releases) in `/usr/local/bin/xray`
- (Server only) nginx and certbot for SSL proxy

### Install missing dependencies
```sh
sudo apt update
sudo apt install curl cron
# (server only)
sudo apt install nginx certbot python3-certbot-nginx
bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)
