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
    SCHEME="${SCHEME:-tonal-spot}"
    
    if [ "$ENGINE" == "mpvpaper" ]; then
        # Launch video wallpaper
        pgrep -x awww > /dev/null && pkill awww
        nohup mpvpaper -vs -o "loop=inf no-audio hwdec=auto profile=fast" "*" "$WALLPAPER" > /dev/null 2>&1 &
        
        # Extract a frame to restore the color scheme
        FRAME_PATH="/tmp/video_frame.jpg"
        ffmpeg -y -i "$WALLPAPER" -ss 00:00:02 -vframes 1 "$FRAME_PATH" 2>/dev/null
        matugen image "$FRAME_PATH" -m dark -t "scheme-$SCHEME"
        (gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null; \
         sleep 0.1; \
         gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null) &
    else
        # Launch static wallpaper
        pgrep -x mpvpaper > /dev/null && pkill mpvpaper
        awww img "$WALLPAPER" \
            --transition-type grow \
            --transition-pos 0.5,0.5 \
            --transition-step 90 \
            --transition-fps 60
            
        matugen image "$WALLPAPER" -m dark -t "scheme-$SCHEME"
        (gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null; \
         sleep 0.1; \
         gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null) &
    fi
fi
