#!/bin/bash
set -e

#### --- CLIENT PACKAGE --- ####

CLIENT="$HOME/greyrhinosec-xray-c2-client"
rm -rf "$CLIENT"
mkdir -p "$CLIENT"/{DEBIAN,usr/local/etc/xray,usr/local/bin,etc/cron.d,etc/systemd/system,usr/share/applications}

cat > "$CLIENT/DEBIAN/control" <<EOF
Package: greyrhinosec-xray-c2-client
Version: 1.0.0
Section: net
Priority: optional
Architecture: amd64
Maintainer: You <admin@greyrhinosec.com>
Description: GreyRhinoSec Stealth Xray C2 Proxy Client (.deb). Systemd, watchdog, full branding.
EOF

cat > "$CLIENT/DEBIAN/postinst" <<'EOF'
#!/bin/bash
set -e
systemctl daemon-reload
systemctl enable xray-client
systemctl restart xray-client
EOF
chmod 755 "$CLIENT/DEBIAN/postinst"

cat > "$CLIENT/usr/local/etc/xray/client.json" <<EOF
{
  "inbounds": [{
    "port": 10808,
    "listen": "127.0.0.1",
    "protocol": "socks",
    "settings": { "auth": "noauth" }
  }],
  "outbounds": [{
    "protocol": "vmess",
    "settings": {
      "vnext": [{
        "address": "greyrhinosec.com",
        "port": 443,
        "users": [{
          "id": "841829c6-45c9-4cf8-b287-fbea627026f8",
          "alterId": 0
        }]
      }]
    },
    "streamSettings": {
      "network": "ws",
      "security": "tls",
      "tlsSettings": {
        "serverName": "greyrhinosec.com"
      },
      "wsSettings": {
        "path": "/cdn-b4e/"
      }
    }
  }]
}
EOF

cat > "$CLIENT/etc/systemd/system/xray-client.service" <<'EOF'
[Unit]
Description=GreyRhinoSec Stealth Xray C2 Proxy
After=network.target
[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/xray -c /usr/local/etc/xray/client.json
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF

cat > "$CLIENT/usr/local/bin/xray-client-failover.sh" <<'EOF'
#!/bin/bash
SOCKS="127.0.0.1:10808"
PRIMARY_IP="172.235.53.246"
ACTIVE_CFG="/usr/local/etc/xray/client.json"
PRIMARY_CFG="/usr/local/etc/xray/client-primary.json"
FAILOVER_CFG="/usr/local/etc/xray/client-failover.json"
SERVICE="xray-client"
CURIP=$(curl --socks5 $SOCKS -s --max-time 10 https://ifconfig.me || echo fail)
DIFF=$(diff "$ACTIVE_CFG" "$PRIMARY_CFG" >/dev/null && echo "primary" || echo "failover")
if [[ "$CURIP" == "$PRIMARY_IP" ]]; then
    [[ "$DIFF" == "failover" ]] && cp "$PRIMARY_CFG" "$ACTIVE_CFG" && systemctl restart $SERVICE && logger -t xray-failover "Tunnel recovered, switched back to PRIMARY"
    logger -t xray-failover "Tunnel OK (PRIMARY, $CURIP)"
else
    logger -t xray-failover "TUNNEL DOWN ($CURIP), restarting service"
    systemctl restart $SERVICE
fi
EOF
chmod 755 "$CLIENT/usr/local/bin/xray-client-failover.sh"

cat > "$CLIENT/etc/cron.d/xray-failover" <<EOF
*/5 * * * * root /usr/local/bin/xray-client-failover.sh
EOF

cat > "$CLIENT/usr/share/applications/greyrhinosec-c2.desktop" <<EOF
[Desktop Entry]
Name=GreyRhinoSec C2 Proxy
Comment=Stealth WebSocket+TLS Tunnel with Watchdog
Exec=systemctl status xray-client
Terminal=true
Type=Application
Categories=Network;Security;
EOF

cat > "$CLIENT/README.md" <<EOF
# GreyRhinoSec Xray Stealth C2 Proxy Client

## Features
- Stealth WebSocket+TLS proxy tunnel (HTTPS-camouflaged)
- Systemd autostart
- Watchdog/failover healthcheck (cron)
- Desktop launcher

## Install
\`\`\`
sudo dpkg -i greyrhinosec-xray-c2-client_1.0.0_amd64.deb
sudo systemctl enable --now xray-client
\`\`\`
## Usage
Set your browser/CLI to use SOCKS5 proxy 127.0.0.1:10808
EOF

cat > "$CLIENT/LICENSE" <<EOF
MIT License
Copyright (c) 2025 GreyRhinoSec
...
EOF

(cd "$CLIENT/.."; zip -r greyrhinosec-xray-c2-client.zip "$(basename "$CLIENT")")

#### --- SERVER PACKAGE --- ####

SERVER="$HOME/greyrhinosec-xray-c2-server"
rm -rf "$SERVER"
mkdir -p "$SERVER"/{DEBIAN,usr/local/etc/xray,usr/local/bin,etc/systemd/system,etc/nginx/sites-available}

cat > "$SERVER/DEBIAN/control" <<EOF
Package: greyrhinosec-xray-c2-server
Version: 1.0.0
Section: net
Priority: optional
Architecture: amd64
Maintainer: You <admin@greyrhinosec.com>
Description: GreyRhinoSec Stealth Xray C2 Server (.deb). Systemd, hardened configs, nginx reverse proxy, HTTPS camouflage.
EOF

cat > "$SERVER/DEBIAN/postinst" <<'EOF'
#!/bin/bash
set -e
systemctl daemon-reload
systemctl enable xray
systemctl enable nginx
systemctl restart xray
systemctl restart nginx
EOF
chmod 755 "$SERVER/DEBIAN/postinst"

cat > "$SERVER/usr/local/etc/xray/config.json" <<EOF
{
  "inbounds": [{
    "port": 10000,
    "protocol": "vmess",
    "settings": {
      "clients": [{
        "id": "841829c6-45c9-4cf8-b287-fbea627026f8",
        "alterId": 0
      }]
    },
    "streamSettings": {
      "network": "ws",
      "wsSettings": {
        "path": "/cdn-b4e/"
      }
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {
      "domainStrategy": "UseIPv4"
    }
  }]
}
EOF

cat > "$SERVER/etc/systemd/system/xray.service" <<'EOF'
[Unit]
Description=GreyRhinoSec Xray C2 Server
After=network.target
[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/xray -c /usr/local/etc/xray/config.json
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF

cat > "$SERVER/etc/nginx/sites-available/default" <<EOF
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
EOF

cat > "$SERVER/README.md" <<EOF
# GreyRhinoSec Xray Stealth C2 Proxy Server

## Features
- Hardened Xray-core (VMess + WebSocket + TLS)
- Nginx reverse proxy for HTTPS camouflage
- Systemd auto-start
- Easy config, easy uninstall

## Install
\`\`\`
sudo dpkg -i greyrhinosec-xray-c2-server_1.0.0_amd64.deb
sudo systemctl enable --now xray
sudo systemctl enable --now nginx
\`\`\`

## Usage
- Edit configs as needed (\`/usr/local/etc/xray/config.json\`, \`/etc/nginx/sites-available/default\`)
- Restart services after change

## Security Tips
- Use strong UUIDs
- Restrict firewall (allow 22, 443 only)
- Monitor logs: tail -f /var/log/nginx/error.log
EOF

cat > "$SERVER/LICENSE" <<EOF
MIT License
Copyright (c) 2025 GreyRhinoSec
...
EOF

(cd "$SERVER/.."; zip -r greyrhinosec-xray-c2-server.zip "$(basename "$SERVER")")

echo
echo "Client zip: $CLIENT/../greyrhinosec-xray-c2-client.zip"
echo "Server zip: $SERVER/../greyrhinosec-xray-c2-server.zip"
