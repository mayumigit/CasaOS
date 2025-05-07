#!/bin/bash
set -a
. /etc/casaos/env
set +a

INTERFACE=$(iw dev | awk '$1=="Interface"{print $2}')
WPA_CONF_PATH="/etc/wpa_supplicant/wpa_supplicant-${INTERFACE}.conf"
WPA_TEMPLATE="/etc/casaos/wifi/templates/wpa_supplicant.conf.template"
NETWORK_TEMPLATE="/etc/casaos/wifi/network/10-wifi.network.template"
NETWORK_TARGET="/etc/systemd/network/10-wifi.network"
RESOLV_SOURCE="/etc/casaos/wifi/resolv/resolv-client.conf"
RESOLV_TARGET="/etc/resolv.conf"
AP_NETWORK_FILE="/etc/systemd/network/10-ap.network"
CLIENT_NETWORK_FILE="/etc/systemd/network/10-wifi.network"

SSID="$1"
PASSWORD="$2"

# CleanUp
[ -f "$AP_NETWORK_FILE" ] && rm -f "$AP_NETWORK_FILE"
[ -f "$CLIENT_NETWORK_FILE" ] && rm -f "$CLIENT_NETWORK_FILE"
[ -f "$RESOLV_FILE" ] && rm -f "$RESOLV_FILE"

# 書き込み
cp "$WPA_TEMPLATE" "$WPA_CONF_PATH"
sed -i "s|SSID_PLACEHOLDER|$SSID|g" "$WPA_CONF_PATH"
sed -i "s|PASSWORD_PLACEHOLDER|$PASSWORD|g" "$WPA_CONF_PATH"

# Network
cp "$NETWORK_TEMPLATE" "$NETWORK_TARGET"
sed -i "s|{{INTERFACE_NAME}}|$INTERFACE|g" "$NETWORK_TARGET"

# Resolv
cp "$RESOLV_SOURCE" "$RESOLV_TARGET"

# Service Restart
systemctl stop hostapd dnsmasq || exit 1
systemctl disable hostapd dnsmasq || exit 1

systemctl enable wpa_supplicant@$INTERFACE || exit 1
systemctl restart wpa_supplicant@$INTERFACE || exit 1
systemctl restart systemd-networkd || exit 1
