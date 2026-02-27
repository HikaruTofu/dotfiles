#!/bin/bash

VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2 * 100}')
MUTED=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -i MUTED)

VOL_TEXT=${VOL%%.*}%
[ -n "$MUTED" ] && VOL_TEXT="[MUTED]"

OPTIONS="Volume Up (+5%)\nVolume Down (-5%)\nToggle Mute"

SELECTED=$(echo -e "$OPTIONS" | fuzzel --dmenu -p "Volume ($VOL_TEXT):" --lines 3 --width 30)

[ -z "$SELECTED" ] && exit 0

case "$SELECTED" in
    "Volume Up (+5%)")
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
        exec "$0"
        ;;
    "Volume Down (-5%)")
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        exec "$0"
        ;;
    "Toggle Mute")
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        exec "$0"
        ;;
esac
