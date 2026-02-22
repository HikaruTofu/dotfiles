#!/bin/bash

CONFIG_FILE="$HOME/.config/niri/options.conf"

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

ENGINE="${ENGINE:-awww}"
WALLPAPER="${WALLPAPER:-}"

# Always ensure awww daemon is available for fast static switching
pgrep -x awww-daemon > /dev/null || { nohup awww-daemon > /dev/null 2>&1 & sleep 0.2; }

if [ -n "$WALLPAPER" ] && [ -f "$WALLPAPER" ]; then
    if [ "$ENGINE" == "mpvpaper" ]; then
        # Launch video wallpaper
        pgrep -x awww > /dev/null && pkill awww
        nohup mpvpaper -vs -o "loop=inf no-audio hwdec=auto profile=fast" "*" "$WALLPAPER" > /dev/null 2>&1 &
    else
        # Launch static wallpaper
        pgrep -x mpvpaper > /dev/null && pkill mpvpaper
        awww img "$WALLPAPER" \
            --transition-type grow \
            --transition-pos 0.5,0.5 \
            --transition-step 90 \
            --transition-fps 60
    fi
fi
