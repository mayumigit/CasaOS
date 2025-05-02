#!/bin/bash

#LOGFILE="/var/log/setup-wifi.log"
#STATE_DIR="./log"
#LAST_SUCCESS_FILE="$STATE_DIR/last_success"
#SSID_FAIL_COUNT_FILE="$STATE_DIR/ssid_fail_count"

log="logger -t setup-wifi-client.sh -s "

SSID="$1"
PASSWORD="$2"
INTERFACE=$(iw dev | awk '$1=="Interface"{print $2}')
CONFIG_DIR="/usr/share/casaos/shell"

if [ -f /etc/wpa_supplicant/wpa_supplicant-${INTERFACE}.conf ]; then
    mv /etc/wpa_supplicant/wpa_supplicant-${INTERFACE}.conf /etc/wpa_supplicant/wpa_supplicant-${INTERFACE}.conf.old
fi

cp "$CONFIG_DIR/wpa_supplicant.conf.template" /etc/wpa_supplicant/wpa_supplicant-${INTERFACE}.conf
sed -i "s|SSID_PLACEHOLDER|$SSID|g" /etc/wpa_supplicant/wpa_supplicant-${INTERFACE}.conf
sed -i "s|PASSWORD_PLACEHOLDER|$PASSWORD|g" /etc/wpa_supplicant/wpa_supplicant-${INTERFACE}.conf
echo "start wpa_supplicant"
systemctl stop hostapd dnsmasq
systemctl enable wpa_supplicant@${INTERFACE}
systemctl restart wpa_supplicant@${INTERFACE}
if [ -f /etc/systemd/network/10-ap.network ]; then
    rm /etc/systemd/network/10-ap.network
fi
cp "$CONFIG_DIR/network/10-wifi.network.template" /etc/systemd/network/10-wifi.network

echo "Updating /etc/resolv.conf for WiFi mode"
if [ -f /etc/resov.conf ]; then
    rm /etc/resolv.conf
fi
cp "$CONFIG_DIR/resolv-client.conf" /etc/resolv.conf

systemctl restart systemd-networkd
echo "try ping 8.8.8.8"
for i in {1..3}; do
    # `ping` を試してインターネット接続を確認
    ping -c 2 -I $INTERFACE 8.8.8.8 > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        ${log} "WiFi connected and Internet is reachable"
        break
    fi
    ${log} "retry..."
    sleep 1
done

ping -c 2 -I $INTERFACE 8.8.8.8 > /dev/null 2>&1
if [ $? -ne 0 ]; then
    ip addr
    ${log} "WiFi connection failed or no internet access"
    ${log} "Disable wpa_supplicant"
    systemctl disable wpa_supplicant@${INTERFACE}
    ${log} "stop wpa_supplicant"
    systemctl stop wpa_supplicant@${INTERFACE}
    if [ -f /etc/systemd/network/10-wifi.network ]; then
        rm /etc/systemd/network/10-wifi.network
    fi
    cp "$CONFIG_DIR/network/10-ap.network.template" /etc/systemd/network/10-ap.network

    if [ -f /etc/resolv.conf ]; then
        rm /etc/resolv.conf
    fi
    cp "$CONFIG_DIR/resolv-ap.conf" /etc/resolv.conf
    systemctl restart systemd-networkd
    ${log} "start hostapd"
    systemctl start hostapd
    ${log} "start dnsmasq"
    systemctl start dnsmasq
    systemctl enable hostapd dnsmasq
    exit 1
fi
#echo "$(date) $SSID" > $LAST_SUCCESS_FILE
#echo "0" > $SSID_FILE_COUNT_FILE

${log} "stop hostapd dnsmasq"
systemctl stop hostapd dnsmasq
systemctl disable hostapd dnsmasq

if [ -f /etc/systemd/network/10-wifi.network ]; then
    rm /etc/systemd/network/10-wifi.network
fi
cp "$CONFIG_DIR/network/10-wifi.network.template" /etc/systemd/network/10-wifi.network

${log} "Updating /etc/resolv.conf for WiFi mode"
if [ -f /etc/resov.conf ]; then
    rm /etc/resolv.conf
fi
cp "$CONFIG_DIR/resolv-client.conf" /etc/resolv.conf

systemctl restart systemd-networkd

${log} "Setup complete"
exit 0
