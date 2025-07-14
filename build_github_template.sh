#!/bin/bash
set -e

# Vars
PKGNAME="greyrhinosec-xray-c2"
WORKDIR="$HOME/${PKGNAME}_template"
DEBVER="1.0"
UUID="841829c6-45c9-4cf8-b287-fbea627026f8"    # replace as needed

# Clean up any old
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"/{DEBIAN,usr/local/etc/xray,usr/local/bin,etc/cron.d,etc/systemd/system,usr/share/pixmaps,usr/share/applications,doc}

# --- CONTROL FILE ---
cat > "$WORKDIR/DEBIAN/control" <<EOF
Package: $PKGNAME
Version: $DEBVER
Section: net
Priority: optional
Architecture: amd64
Maintainer: You <admin@greyrhinosec.com>
Description: GreyRhinoSec Stealth C2 Proxy - WebSocket+TLS tunneling with watchdog failover, systemd service, and automatic healthcheck.
EOF

# --- POSTINST ---
cat > "$WORKDIR/DEBIAN/postinst" <<'EOF'
#!/bin/bash
set -e
systemctl daemon-reload
systemctl enable xray-client
systemctl restart xray-client
EOF
chmod 755 "$WORKDIR/DEBIAN/postinst"

# --- XRAY CONFIG ---
cat > "$WORKDIR/usr/local/etc/xray/client.json" <<EOF
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
          "id": "$UUID",
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

# --- SYSTEMD SERVICE ---
cat > "$WORKDIR/etc/systemd/system/xray-client.service" <<'EOF'
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

# --- WATCHDOG SCRIPT ---
cat > "$WORKDIR/usr/local/bin/xray-client-failover.sh" <<'EOF'
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
chmod 755 "$WORKDIR/usr/local/bin/xray-client-failover.sh"

# --- CRON WATCHDOG ---
cat > "$WORKDIR/etc/cron.d/xray-failover" <<EOF
*/5 * * * * root /usr/local/bin/xray-client-failover.sh
EOF

# --- ICON (generic SVG rhino if PNG not available) ---
cat > "$WORKDIR/usr/share/pixmaps/greyrhinosec.png" <<'EOF'
iVBORw0KGgoAAAANSUhEUgAAAJYAAACWCAMAAADkWcjtAAAABlBMVEUAAAD///+l2Z/dAAAAAnRSTlMAAHaTzTgAAAB4SURBVHja7cExAQAAAMKg9U9tCF8gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgP4FvgABRUQcEQAAAABJRU5ErkJggg==
EOF
# (This is just a placeholder. Replace with a real PNG for production!)

# --- DESKTOP ENTRY ---
cat > "$WORKDIR/usr/share/applications/greyrhinosec-c2.desktop" <<EOF
[Desktop Entry]
Name=GreyRhinoSec C2 Proxy
Comment=Stealth WebSocket+TLS Tunnel with Watchdog
Exec=systemctl status xray-client
Icon=greyrhinosec.png
Terminal=true
Type=Application
Categories=Network;Security;
EOF

# --- README ---
cat > "$WORKDIR/README.md" <<EOF
# GreyRhinoSec Xray Stealth C2 Proxy

## Features
- Stealth VMess WebSocket+TLS proxy tunnel
- Systemd autostart
- Watchdog/failover healthcheck (cron)
- Desktop launcher and icon

## Install
\`\`\`
sudo dpkg -i xray-stealth-client_1.0_amd64.deb
\`\`\`

## Usage
- Set your browser/CLI to use SOCKS5 proxy 127.0.0.1:10808
- All traffic will tunnel via your Linode C2.

## Branding
- Custom icon: /usr/share/pixmaps/greyrhinosec.png
- Menu: GreyRhinoSec C2 Proxy

## Authors
- You (elliot@greyrhinosec.com)
EOF

# --- LICENSE (MIT) ---
cat > "$WORKDIR/LICENSE" <<EOF
MIT License

Copyright (c) 2025 GreyRhinoSec

Permission is hereby granted, free of charge, to any person obtaining a copy...
(etc)
EOF

# --- Zip it all up for GitHub ---
cd "$WORKDIR/.."
zip -r "${PKGNAME}_github_template.zip" "${PKGNAME}_template"

echo
echo "DONE! Your GitHub zip is at: $WORKDIR/../${PKGNAME}_github_template.zip"
