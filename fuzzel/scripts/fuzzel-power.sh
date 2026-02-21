#!/bin/bash

SELECTION="$(printf "1 - Lock\n2 - Logout\n3 - Reboot\n4 - Shutdown" | fuzzel --dmenu -l 4 -p "Power Menu: " --width 20)"

case $SELECTION in
	*"Lock")
	hyprlock
		;;
	*"Logout")
		niri msg action quit
		;;
	*"Reboot")
		systemctl reboot
		;;
	*"Shutdown")
		systemctl poweroff
		;;
esac
