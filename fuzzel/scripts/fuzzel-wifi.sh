#!/usr/bin/env bash

# WiFi manager using nmcli + Fuzzel

if ! command -v nmcli >/dev/null 2>&1; then
    notify-send -r 1 -t 5000 -u critical "WiFi" "nmcli not found. Install NetworkManager."
    exit 1
fi

WIFI_STATE=$(nmcli radio wifi)

if [[ "$WIFI_STATE" != "enabled" ]]; then
    ACTION=$(echo "Enable WiFi" | fuzzel --dmenu -p "WiFi is Off: " --lines 1 --width 20)
    if [ "$ACTION" == "Enable WiFi" ]; then
        nmcli radio wifi on
        notify-send -r 1 -t 2000 "WiFi" "Enabled"
    fi
    exit 0
fi

# Get list of available networks instantly (uses cached data)
CONNECTED=$(nmcli -t -f SSID,SIGNAL,SECURITY,IN-USE dev wifi list 2>/dev/null | \
    awk -F: '$4 == "*" && $1 != "" {printf "* %s  (%s%% %s)\n", $1, $2, $3}')

OTHER=$(nmcli -t -f SSID,SIGNAL,SECURITY,IN-USE dev wifi list 2>/dev/null | \
    awk -F: '$4 != "*" && $1 != "" {printf "  %s  (%s%% %s)\n", $1, $2, $3}' | sort -t'(' -k2 -rn | uniq)

if [[ -n "$CONNECTED" && -n "$OTHER" ]]; then
    DISPLAY_LIST="Disable WiFi\nRescan Networks\n$CONNECTED\n$OTHER"
elif [[ -n "$CONNECTED" ]]; then
    DISPLAY_LIST="Disable WiFi\nRescan Networks\n$CONNECTED"
elif [[ -n "$OTHER" ]]; then
    DISPLAY_LIST="Disable WiFi\nRescan Networks\n$OTHER"
else
    DISPLAY_LIST="Disable WiFi\nRescan Networks\n[No networks found]"
fi

SELECTED=$(echo -e "$DISPLAY_LIST" | fuzzel --dmenu -p "WiFi: " --lines 10 --width 40)

[[ -z "$SELECTED" || "$SELECTED" == "[No networks found]" ]] && exit 0

if [[ "$SELECTED" == "Rescan Networks" ]]; then
    notify-send -r 1 -t 2000 "WiFi" "Scanning for networks..."
    nmcli dev wifi rescan
    exec "$0"
fi

if [[ "$SELECTED" == "Disable WiFi" ]]; then
    nmcli radio wifi off
    notify-send -r 1 -t 2000 "WiFi" "Disabled"
    exit 0
fi

# Extract SSID
SSID=$(echo "$SELECTED" | sed 's/^[* ] *//' | sed 's/  *(.*//')

# Check if already connected to this network
if [[ "$SELECTED" == \** ]]; then
    ACTION=$(echo -e "Disconnect\nForget" | fuzzel --dmenu -p "$SSID: " --lines 2 --width 20)
    case "$ACTION" in
        "Disconnect")
            nmcli con down "$SSID" 2>/dev/null
            notify-send -r 1 -t 3000 "WiFi" "Disconnected from $SSID"
            ;;
        "Forget")
            nmcli con delete "$SSID" 2>/dev/null
            notify-send -r 1 -t 3000 "WiFi" "Forgot $SSID"
            ;;
    esac
    exit 0
fi

# Check if we have a saved connection
if nmcli -t -f NAME con show 2>/dev/null | grep -qx "$SSID"; then
    notify-send -r 1 -t 2000 "WiFi" "Connecting to $SSID..."
    if nmcli con up "$SSID" 2>/dev/null; then
        notify-send -r 1 -t 3000 "WiFi" "Connected to $SSID"
    else
        notify-send -r 1 -t 5000 -u critical "WiFi" "Failed to connect to $SSID"
    fi
else
    # Need password
    SECURITY=$(nmcli -t -f SSID,SECURITY dev wifi list 2>/dev/null | grep "^${SSID}:" | head -1 | cut -d: -f2)

    if [[ -z "$SECURITY" || "$SECURITY" == "--" ]]; then
        nmcli dev wifi connect "$SSID" 2>/dev/null
    else
        PASSWORD=$(echo "" | fuzzel --dmenu -p "Password for $SSID: " --password --lines 0 --width 40)
        [[ -z "$PASSWORD" ]] && exit 0

        notify-send -r 1 -t 2000 "WiFi" "Connecting to $SSID..."
        if nmcli dev wifi connect "$SSID" password "$PASSWORD" 2>/dev/null; then
            notify-send -r 1 -t 3000 "WiFi" "Connected to $SSID"
        else
            notify-send -r 1 -t 5000 -u critical "WiFi" "Failed to connect to $SSID"
        fi
    fi
fi
