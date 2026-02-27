#!/bin/bash

BRIGHT=$(brightnessctl i | grep -oP '\(\K[0-9]+(?=%\))')

OPTIONS="Brightness Up (+10%)\nBrightness Down (-10%)"

SELECTED=$(echo -e "$OPTIONS" | fuzzel --dmenu -p "Brightness ($BRIGHT%):" --lines 2 --width 35)

[ -z "$SELECTED" ] && exit 0

case "$SELECTED" in
    "Brightness Up (+10%)")
        brightnessctl s 10%+
        exec "$0"
        ;;
    "Brightness Down (-10%)")
        brightnessctl s 10%-
        exec "$0"
        ;;
esac
