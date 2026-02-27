#!/usr/bin/env bash

SCRIPT_DIR="$HOME/.config/fuzzel/scripts"

while true; do
    OPTIONS="WiFi\nBluetooth\nVolume\nBrightness\nMedia Player\nScreenshot\nRecord Screen\nWallpaper\nColor Scheme\nClipboard\nPower Profile\nPower Menu"
    
    # We pass the options in, but use --no-run-if-empty so closing with Esc breaks the loop.
    # Note: Fuzzel doesn't have a built-in "wrap around" flag like rofi, but users can type 
    # to filter or just use arrows.
    CHOSEN=$(echo -e "$OPTIONS" | fuzzel --dmenu -p "Main Menu: " --lines 12 --width 25 --no-run-if-empty)

    # If the user pressed Escape/closed Fuzzel, $CHOSEN is empty, break the loop
    [ -z "$CHOSEN" ] && exit 0

    case "$CHOSEN" in
        "WiFi") bash "$SCRIPT_DIR/fuzzel-wifi.sh" ;;
        "Bluetooth") bash "$SCRIPT_DIR/fuzzel-bluetooth.sh" ;;
        "Wallpaper") bash "$SCRIPT_DIR/fuzzel-wallpaper.sh" & break ;;
        "Color Scheme") bash "$SCRIPT_DIR/fuzzel-scheme.sh" & break ;;
        "Power Profile") bash "$SCRIPT_DIR/fuzzel-powerprofile.sh" & break ;;
        "Clipboard") bash "$SCRIPT_DIR/fuzzel-clipboard.sh" & break ;;
        "Power Menu") bash "$SCRIPT_DIR/fuzzel-power.sh" & break ;;
        "Media Player") bash "$SCRIPT_DIR/fuzzel-player.sh" ;;
        "Volume") bash "$SCRIPT_DIR/fuzzel-volume.sh" ;;
        "Brightness") bash "$SCRIPT_DIR/fuzzel-brightness.sh" ;;
        "Screenshot") bash "$SCRIPT_DIR/fuzzel-screenshot.sh" & break ;;
        "Record Screen") bash "$SCRIPT_DIR/fuzzel-record.sh" & break ;;
    esac
done
