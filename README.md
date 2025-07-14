# 🦏 GreyRhinoSec Xray Stealth C2 Proxy

![Linux](https://img.shields.io/badge/Platform-Kali%20%7C%20Ubuntu-informational?logo=linux)
![Debian package](https://img.shields.io/badge/Install-.deb-blue?logo=debian)
![License: MIT](https://img.shields.io/badge/License-MIT-green)
![Status](https://img.shields.io/badge/Status-Operational-brightgreen)

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
- **Branding ready:** icon, launcher, docs, and banners

---

## Quick Install

```sh
wget https://github.com/GreyRhinoSecurity/c2-xtunnel/releases/latest/download/greyrhinosec-xray-c2-client.deb
sudo dpkg -i greyrhinosec-xray-c2-client.deb
sudo systemctl enable --now xray-client
