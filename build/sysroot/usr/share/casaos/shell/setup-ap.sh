#!/bin/bash
set -a
. /etc/casaos/env
set +a

INTERFACE=$(iw dev | awk '$1=="Interface"{print $2}')
NETWORK_TEMPLATE="/etc/casaos/wifi/network/10-ap.network.template"
NETWORK_TARGET="/etc/systemd/network/10-ap.network"
RESOLV_SOURCE="/etc/casaos/wifi/resolv/resolv-ap.conf"
RESOLV_TARGET="/etc/resolv.conf"
AP_NETWORK_FILE="/etc/systemd/network/10-ap.network"
CLIENT_NETWORK_FILE="/etc/systemd/network/10-wifi.network"

# CleanUp
[ -f "$AP_NETWORK_FILE" ] && rm -f "$AP_NETWORK_FILE"
[ -f "$CLIENT_NETWORK_FILE" ] && rm -f "$CLIENT_NETWORK_FILE"
[ -f "$RESOLV_FILE" ] && rm -f "$RESOLV_FILE"

cp "$NETWORK_TEMPLATE" "$NETWORK_TARGET"
sed -i "s|{{INTERFACE_NAME}}|$INTERFACE|g" "$NETWORK_TARGET"
sed -i "s|{{AP_IP_ADDRESS}}|$AP_IP_ADDRESS|g" "$NETWORK_TARGET"

cp "$RESOLV_SOURCE" "$RESOLV_TARGET"
sed -i "s|{{AP_IP_ADDRESS}}|$AP_IP_ADDRESS|g" "$RESOLV_TARGET"

# Service Restart
systemctl stop wpa_supplicant@$INTERFACE || exit 1
systemctl disable wpa_supplicant@$INTERFACE || exit 1

systemctl restart systemd-networkd || exit 1

systemctl start hostapd || exit 1
sleep 1
systemctl start dnsmasq || exit 1
systemctl enable hostapd dnsmasq || exit 1
