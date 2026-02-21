#!/bin/bash

HISTORY=$(cliphist list)

MENU="-       Clear History\n$HISTORY"

SELECTED=$(echo -e "$MENU" | fuzzel --dmenu -p "Clipboard: " --width 60)

if [ "$SELECTED" == "-       Clear History" ]; then
    CONFIRM=$(echo -e "No\nYes" | fuzzel --dmenu -p "Delete ALL History? " --lines 2 --width 30)
    if [ "$CONFIRM" == "Yes" ]; then
        cliphist wipe
        notify-send "Clipboard" "History Cleared"
    fi
else
    if [ -n "$SELECTED" ]; then
        echo "$SELECTED" | cliphist decode | wl-copy
    fi
fi
