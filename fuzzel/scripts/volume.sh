#!/bin/bash
NOTIF_ID=9993

case $1 in
    up)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ -l 1.0
        ;;
    down)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        ;;
    mute)
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        ;;
esac

VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}')
MUTE=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep "MUTED")

if [ -n "$MUTE" ]; then
    ICON="audio-volume-muted"
    TEXT="Muted"
else
    if [ "$VOL" -lt 33 ]; then ICON="audio-volume-low";
    elif [ "$VOL" -lt 66 ]; then ICON="audio-volume-medium";
    else ICON="audio-volume-high"; fi
    TEXT="${VOL}%"
fi

notify-send -a "Volume" -r "$NOTIF_ID" -h int:value:"$VOL" -i "$ICON" "Volume" "$TEXT" -t 2000
