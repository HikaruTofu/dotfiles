#!/bin/bash

OPTIONS="Logout"
OPTIONS="$OPTIONS\nReboot"
OPTIONS="$OPTIONS\nShutdown"

SELECTION=$(echo -e "$OPTIONS" | fuzzel --dmenu -p "Power Menu:" --lines 3 --width 20)

case $SELECTION in
    *"Logout")
        jiri msg action quit
        ;;
    *"Reboot")
        pgrep -x mpvpaper > /dev/null && pkill mpvpaper
        systemctl reboot
        ;;
    *"Shutdown")
        pgrep -x mpvpaper > /dev/null && pkill mpvpaper
        systemctl poweroff
        ;;
esac
