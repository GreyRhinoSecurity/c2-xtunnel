# GreyRhinoSec Xray Stealth C2 Proxy

## Features
- Stealth VMess WebSocket+TLS proxy tunnel
- Systemd autostart
- Watchdog/failover healthcheck (cron)
- Desktop launcher and icon

## Install
```
sudo dpkg -i xray-stealth-client_1.0_amd64.deb
```

## Usage
- Set your browser/CLI to use SOCKS5 proxy 127.0.0.1:10808
- All traffic will tunnel via your Linode C2.

## Branding
- Custom icon: /usr/share/pixmaps/greyrhinosec.png
- Menu: GreyRhinoSec C2 Proxy

## Authors
- You (elliot@greyrhinosec.com)
