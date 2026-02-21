#!/bin/bash

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
CONFIG_FILE="$HOME/.config/matugen/settings.conf"

# Load scheme dari config
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    SCHEME="${SCHEME:-tonal-spot}"
else
    SCHEME="tonal-spot"
fi

# Ambil full path, tapi tampilkan hanya nama file
mapfile -t FILES < <(find "$WALLPAPER_DIR" -type f \( \
    -iname "*.jpg" -o \
    -iname "*.png" -o \
    -iname "*.jpeg" -o \
    -iname "*.webp" \))

DISPLAY_LIST=""
for file in "${FILES[@]}"; do
    DISPLAY_LIST+="$(basename "$file")"$'\n'
done

SELECTED=$(echo "$DISPLAY_LIST" | fuzzel --dmenu -p "Select Wallpaper:" --lines 15 --width 40)

if [ -n "$SELECTED" ]; then
    FULL_PATH="$WALLPAPER_DIR/$SELECTED"

    echo "$FULL_PATH" > "$HOME/.cache/current_wallpaper"

    awww img "$FULL_PATH" \
        --transition-type grow \
        --transition-pos 0.5,0.5 \
        --transition-step 90 \
        --transition-fps 60

    # Generate dengan scheme type argument
    matugen image "$FULL_PATH" -m dark -t "scheme-$SCHEME"

    pgrep -x waybar > /dev/null && pkill -SIGUSR2 waybar
    pgrep -x mako > /dev/null && makoctl reload

    notify-send "Wallpaper & Colors Updated" "$SELECTED (scheme: $SCHEME)" -i wallpaper
fi
