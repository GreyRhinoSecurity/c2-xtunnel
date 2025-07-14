# GreyRhinoSec Xray Stealth C2 Proxy Server

## Features
- Hardened Xray-core (VMess + WebSocket + TLS)
- Nginx reverse proxy for HTTPS camouflage
- Systemd auto-start
- Easy config, easy uninstall

## Install
```
sudo dpkg -i greyrhinosec-xray-c2-server_1.0.0_amd64.deb
sudo systemctl enable --now xray
sudo systemctl enable --now nginx
```

## Usage
- Edit configs as needed (`/usr/local/etc/xray/config.json`, `/etc/nginx/sites-available/default`)
- Restart services after change

## Security Tips
- Use strong UUIDs
- Restrict firewall (allow 22, 443 only)
- Monitor logs: tail -f /var/log/nginx/error.log
