#!/bin/bash
set -e

WIKI="$HOME/greyrhinosec-c2-wiki"
rm -rf "$WIKI"
mkdir -p "$WIKI"

# Home.md
cat > "$WIKI/Home.md" <<EOF
# 🦏 GreyRhinoSec Xray C2 XTunnel Wiki

Welcome! This wiki is your one-stop for stealth C2 tunneling with GreyRhinoSec.

**Quick Links:**  
- [Client Install](./Client-Install)
- [Server Setup](./Server-Setup)
- [Failover & Healthcheck](./Failover)
- [Branding & Customization](./Branding)
- [Advanced Ops](./Advanced-Ops)
- [FAQ](./FAQ)
- [Uninstall](./Uninstall)

## Overview
- Stealth VMess WebSocket+TLS, Nginx reverse proxy
- .deb install (client/server)
- Systemd, watchdog, failover, custom branding
- Modular: easy deploy, easy remove
EOF

# Client-Install.md
cat > "$WIKI/Client-Install.md" <<EOF
# Client Install & Usage

## Install
\`\`\`sh
sudo dpkg -i xray-stealth-client_1.0_amd64.deb
sudo systemctl enable --now xray-client
\`\`\`

## Usage
- Set browser/CLI to SOCKS5 proxy \`127.0.0.1:10808\`
- \`curl --socks5 127.0.0.1:10808 https://ifconfig.me\`
- Healthcheck/failover runs automatically (see [Failover](./Failover))
EOF

# Server-Setup.md
cat > "$WIKI/Server-Setup.md" <<EOF
# Server Setup (Linode, VPS)

## Requirements
- Ubuntu/Kali server with root access
- Registered domain pointing to server

## Install Nginx, Certbot, Xray-core
\`\`\`sh
sudo apt update && sudo apt install nginx certbot python3-certbot-nginx -y
bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)
\`\`\`

## Nginx Reverse Proxy
\`\`\`nginx
server {
    listen 443 ssl;
    server_name greyrhinosec.com;
    ssl_certificate /etc/letsencrypt/live/greyrhinosec.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/greyrhinosec.com/privkey.pem;
    location /cdn-b4e/ {
        proxy_pass http://127.0.0.1:10000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }
}
\`\`\`
Restart nginx and xray after changes.
EOF

# Failover.md
cat > "$WIKI/Failover.md" <<EOF
# Failover, Watchdog, and Healthcheck

- Watchdog script in cron checks tunnel health.
- If primary fails, restarts service and/or fails over to backup config.
- Logs: \`sudo journalctl -t xray-failover -f\`

**Customizing failover logic:**  
Edit \`/usr/local/bin/xray-client-failover.sh\` and \`/usr/local/etc/xray/client-failover.json\`
EOF

# Branding.md
cat > "$WIKI/Branding.md" <<EOF
# Branding & Customization

- **Icon:** \`/usr/share/pixmaps/greyrhinosec.png\`
- **Launcher:** \`/usr/share/applications/greyrhinosec-c2.desktop\`
- ASCII art: edit CLI banners in watchdog and scripts
- Package metadata: edit DEBIAN/control before build

You can fully brand the .deb, launcher, and documentation!
EOF

# FAQ.md
cat > "$WIKI/FAQ.md" <<EOF
# FAQ / Troubleshooting

**Q: Tunnel won't connect?**  
- Check client/server config match (domain, UUID, path).
- Check \`sudo systemctl status xray-client\` and logs.

**Q: Browser traffic not tunneled?**  
- Ensure SOCKS5 is set in browser, or use proxychains.

**Q: All traffic through tunnel?**  
- See [Advanced-Ops](./Advanced-Ops) for TUN mode or redsocks.
EOF

# Uninstall.md
cat > "$WIKI/Uninstall.md" <<EOF
# Uninstall & Cleanup

\`\`\`sh
sudo systemctl stop xray-client
sudo systemctl disable xray-client
sudo dpkg -r greyrhinosec-xray-c2
\`\`\`

Remove configs and branding files as needed.
EOF

# Advanced-Ops.md
cat > "$WIKI/Advanced-Ops.md" <<EOF
# Advanced Operations

## Multi-hop / Chained Tunnels
- Chain multiple Xray servers for added stealth.

## CI/CD / Mass Deploy
- Host .deb on private server; install with one line:
\`\`\`
wget https://yourdomain.com/xray-stealth-client_1.0_amd64.deb && sudo dpkg -i xray-stealth-client_1.0_amd64.deb
\`\`\`

## Full-system tunneling
- Use tun2socks, redsocks, or Xray TUN mode for all traffic.

## Monitoring & Alerts
- Integrate watchdog with Slack/email for live ops.

EOF

# Zip all
cd "$WIKI/.."
zip -r greyrhinosec-c2-wiki.zip "$(basename $WIKI)"

echo "DONE! Wiki zip at $WIKI/../greyrhinosec-c2-wiki.zip"
