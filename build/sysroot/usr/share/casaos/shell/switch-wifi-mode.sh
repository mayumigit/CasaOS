#!/bin/bash
set -e

INTERFACE=$(iw dev | awk '$1=="Interface"{print $2}')
MODE="$1"
SSID="$2"
PASSWORD="$3"

log() {
  logger -t switch-wifi-mode.sh -s "$@"
  echo -e "\033[36m[WiFi]\033[0m $@"
}

log "切り替え開始: ${MODE} モード"

if [ "$MODE" == "client" ]; then
    log "▶ Switching to client mode..."

    /usr/share/casaos/shell/setup-wifi-client.sh "$SSID" "$PASSWORD"
    if [ $? -ne 0 ]; then
        log "❌ Client setup failed — fallback to AP mode"
        /usr/share/casaos/shell/setup-ap.sh || {
            log "❌ AP fallback also failed"
            exit 1
        }
        exit 0
    fi
    log "clientモード設定完了"
    for i in {1..5}; do
        if ping -c 1 -I "$INTERFACE" 8.8.8.8 > /dev/null 2>&1; then
            log "✅ Connected to internet via Wi-Fi!"
            exit 0
        fi
        log "⏳ Waiting for connection..."
        sleep 1
    done

    log "fallbackでAPモードへ切り替え"
    log "❌ Wi-Fi connected but no internet. Switching to AP mode..."
    /usr/share/casaos/shell/setup-ap.sh
    exit 0

elif [ "$MODE" == "ap" ]; then
    log "▶ Switching to AP mode..."

    /usr/share/casaos/shell/setup-ap.sh
    log "APモード設定完了"
    exit 0

else
    log "❌ Unknown mode: ${MODE}"
    exit 1
fi

