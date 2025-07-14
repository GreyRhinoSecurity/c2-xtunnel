# GreyRhinoSec Xray Stealth C2 Proxy Client

## Features
- Stealth WebSocket+TLS proxy tunnel (HTTPS-camouflaged)
- Systemd autostart
- Watchdog/failover healthcheck (cron)
- Desktop launcher

## Install
```
sudo dpkg -i greyrhinosec-xray-c2-client_1.0.0_amd64.deb
sudo systemctl enable --now xray-client
```
## Usage
Set your browser/CLI to use SOCKS5 proxy 127.0.0.1:10808
