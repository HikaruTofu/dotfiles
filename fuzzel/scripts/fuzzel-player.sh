#!/bin/bash

PLAYER_STAT=$(playerctl status 2>/dev/null || echo "Stopped")

OPTIONS="Play / Pause\nNext Track\nPrevious Track"

SELECTED=$(echo -e "$OPTIONS" | fuzzel --dmenu -p "Media Player [$PLAYER_STAT]:" --lines 3 --width 30)

[ -z "$SELECTED" ] && exit 0

case "$SELECTED" in
    "Play / Pause") playerctl play-pause ;;
    "Next Track") playerctl next ;;
    "Previous Track") playerctl previous ;;
esac
