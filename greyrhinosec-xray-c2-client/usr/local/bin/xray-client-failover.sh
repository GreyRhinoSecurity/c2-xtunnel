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
