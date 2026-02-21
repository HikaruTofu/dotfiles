#!/bin/bash

CURRENT=$(powerprofilesctl get)

OPTIONS="Performance"
[ "$CURRENT" = "performance" ] && OPTIONS="* Performance"

if [ "$CURRENT" = "balanced" ]; then
    OPTIONS="$OPTIONS\n* Balanced"
else
    OPTIONS="$OPTIONS\nBalanced"
fi

if [ "$CURRENT" = "power-saver" ]; then
    OPTIONS="$OPTIONS\n* Power Saver"
else
    OPTIONS="$OPTIONS\nPower Saver"
fi

SELECTED=$(echo -e "$OPTIONS" | fuzzel --dmenu -p "Power Profile ($CURRENT): " --lines 3 --width 25)

case $SELECTED in
    *"Performance")
        powerprofilesctl set performance
        notify-send "Power Profile" "Switched to Performance Mode" -i weather-clear
        ;;
    *"Balanced")
        powerprofilesctl set balanced
        notify-send "Power Profile" "Switched to Balanced Mode" -i weather-few-clouds
        ;;
    *"Power Saver")
        powerprofilesctl set power-saver
        notify-send "Power Profile" "Switched to Power Saver Mode" -i weather-overcast
        ;;
esac
