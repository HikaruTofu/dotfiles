#!/bin/bash

# Ensure output directory exists
SAVE_DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$SAVE_DIR"

# Check if an argument was passed to bypass the menu
if [ -n "$1" ]; then
    SELECTED="$1"
else
    OPTIONS="Capture Screen\nCapture Region\nCapture Active Window"
    SELECTED=$(echo -e "$OPTIONS" | fuzzel --dmenu -p "Screenshot:" --lines 3 --width 25 --no-run-if-empty)
fi

[ -z "$SELECTED" ] && exit 0

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

case "$SELECTED" in
    "Capture Screen"|"--screen")
        sleep 0.5
        grim "$SAVE_DIR/screenshot-$TIMESTAMP.png"
        notify-send -r 1 -i "$SAVE_DIR/screenshot-$TIMESTAMP.png" "Screenshot Saved" "Saved to $SAVE_DIR"
        wl-copy < "$SAVE_DIR/screenshot-$TIMESTAMP.png"
        ;;
    "Capture Region"|"--region")
        REGION=$(slurp -d -w 1 -b "#1a1a1a33" -c "#00ffcc")
        [ -z "$REGION" ] && exit 1
        grim -g "$REGION" "$SAVE_DIR/screenshot-$TIMESTAMP.png"
        notify-send -r 1 -i "$SAVE_DIR/screenshot-$TIMESTAMP.png" "Screenshot Saved" "Region saved and copied to clipboard"
        wl-copy < "$SAVE_DIR/screenshot-$TIMESTAMP.png"
        ;;
    "Capture Active Window"|"--window")
        sleep 0.5
        # Niri IPC logic for active window bounds (x,y wxh)
        WINDOW_INFO=$(niri msg -j focused-window | jq -r 'if . then "\(.x),\(.y) \(.width)x\(.height)" else "" end')
        if [ -n "$WINDOW_INFO" ]; then
            grim -g "$WINDOW_INFO" "$SAVE_DIR/screenshot-$TIMESTAMP.png"
            notify-send -r 1 -i "$SAVE_DIR/screenshot-$TIMESTAMP.png" "Screenshot Saved" "Active window saved and copied to clipboard"
            wl-copy < "$SAVE_DIR/screenshot-$TIMESTAMP.png"
        else
            notify-send -r 1 "Screenshot Failed" "No active window found"
        fi
        ;;
esac
