#!/usr/bin/env bash

# Bluetooth manager via Fuzzel
# Requires: bluetoothctl (from bluez-utils)

if ! command -v bluetoothctl >/dev/null 2>&1; then
    notify-send -r 1 -t 5000 -u critical "Bluetooth" "bluetoothctl not found. Install bluez-utils."
    exit 1
fi

BT_POWER=$(echo "show" | bluetoothctl 2>/dev/null | grep -oP 'Powered: \K\w+')

if [[ "$BT_POWER" != "yes" ]]; then
    ACTION=$(echo "Power On" | fuzzel --dmenu -p "Bluetooth is Off: " --lines 1 --width 20)
    if [ "$ACTION" == "Power On" ]; then
        rfkill unblock bluetooth
        sleep 0.5
        bluetoothctl power on >/dev/null 2>&1
        notify-send -r 1 -t 2000 "Bluetooth" "Powered on"
    fi
    exit 0
fi

# Fetch known/discovered devices instantly
DEVICES=$(echo "devices" | bluetoothctl 2>/dev/null | grep "^Device ")

DISPLAY_LIST="Power Off\nScan for Devices\n"

if [[ -z "$DEVICES" ]]; then
    DISPLAY_LIST+="[No devices found]"
else
    while IFS= read -r line; do
        MAC=$(echo "$line" | awk '{print $2}')
        NAME=$(echo "$line" | cut -d' ' -f3-)
        
        INFO=$(echo "info $MAC" | bluetoothctl 2>/dev/null)
        CONNECTED=$(echo "$INFO" | grep -oP 'Connected: \K\w+')
        PAIRED=$(echo "$INFO" | grep -oP 'Paired: \K\w+')
        
        if [[ "$CONNECTED" == "yes" ]]; then
            DISPLAY_LIST+="* $NAME ($MAC)\n"
        elif [[ "$PAIRED" == "yes" ]]; then
            DISPLAY_LIST+="+ $NAME ($MAC)\n"
        else
            DISPLAY_LIST+="  $NAME ($MAC)\n"
        fi
    done <<< "$DEVICES"
    DISPLAY_LIST="${DISPLAY_LIST%\\n}"
fi

SELECTED=$(echo -e "$DISPLAY_LIST" | fuzzel --dmenu -p "Bluetooth: " --lines 10 --width 40)

[[ -z "$SELECTED" || "$SELECTED" == "[No devices found]" ]] && exit 0

if [[ "$SELECTED" == "Scan for Devices" ]]; then
    notify-send -r 1 -t 5000 "Bluetooth" "Scanning for devices (5s)..."
    bluetoothctl --timeout 5 scan on >/dev/null 2>&1
    exec "$0"
fi

if [[ "$SELECTED" == "Power Off" ]]; then
    bluetoothctl power off >/dev/null 2>&1
    notify-send -r 1 -t 2000 "Bluetooth" "Powered off"
    exit 0
fi

# Extract MAC
SEL_MAC=$(echo "$SELECTED" | grep -oP '\(([0-9A-F:]+)\)' | tr -d '()')
SEL_NAME=$(echo "$SELECTED" | sed 's/ *(\([0-9A-F:]*\))$//' | sed 's/^[*+ ] //')

# Check if already connected
SEL_CONNECTED=$(echo "info $SEL_MAC" | bluetoothctl 2>/dev/null | grep -oP 'Connected: \K\w+')

if [[ "$SEL_CONNECTED" == "yes" ]]; then
    ACTION=$(echo -e "Disconnect\nForget" | fuzzel --dmenu -p "$SEL_NAME: " --lines 2 --width 20)
    case "$ACTION" in
        "Disconnect")
            bluetoothctl disconnect "$SEL_MAC" >/dev/null 2>&1
            notify-send -r 1 -t 3000 "Bluetooth" "Disconnected from $SEL_NAME"
            ;;
        "Forget")
            bluetoothctl remove "$SEL_MAC" >/dev/null 2>&1
            notify-send -r 1 -t 3000 "Bluetooth" "Removed $SEL_NAME"
            ;;
    esac
else
    notify-send -r 1 -t 3000 "Bluetooth" "Connecting to $SEL_NAME..."
    bluetoothctl pair "$SEL_MAC" >/dev/null 2>&1
    bluetoothctl trust "$SEL_MAC" >/dev/null 2>&1

    if bluetoothctl connect "$SEL_MAC" >/dev/null 2>&1; then
        notify-send -r 1 -t 3000 "Bluetooth" "Connected to $SEL_NAME"
    else
        notify-send -r 1 -t 5000 -u critical "Bluetooth" "Failed to connect to $SEL_NAME"
    fi
fi
