#!/bin/bash

NOTIF_ID=9994

case $1 in
    up)
        brightnessctl set +5%
        ;;
    down)
        brightnessctl set 5%-
        ;;
esac

MAX=$(brightnessctl max)
CURRENT=$(brightnessctl get)
PERC=$(( CURRENT * 100 / MAX ))

ICON="display-brightness-symbolic"

notify-send -a "Brightness" -r "$NOTIF_ID" -h int:value:"$PERC" -i "$ICON" "Brightness" "${PERC}%" -t 2000
