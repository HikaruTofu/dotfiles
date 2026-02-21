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
        systemctl reboot
        ;;
    *"Shutdown")
        systemctl poweroff
        ;;
esac
