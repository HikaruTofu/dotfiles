#!/bin/bash

CONFIG_FILE="$HOME/.config/niri/options.conf"
mkdir -p "$(dirname "$CONFIG_FILE")"

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    CURRENT="${SCHEME:-tonal-spot}"
else
    CURRENT="tonal-spot"
fi

TAGS="${TAGS:-}"
RATING="${RATING:-any}"
RES="${RES:-Any}"
ENGINE="${ENGINE:-awww}"
WALLPAPER="${WALLPAPER:-}"

SCHEMES=(
    "content"
    "expressive"
    "fidelity"
    "fruit-salad"
    "monochrome"
    "neutral"
    "rainbow"
    "tonal-spot"
    "vibrant"
)

OPTIONS=""
for scheme in "${SCHEMES[@]}"; do
    if [ "$scheme" = "$CURRENT" ]; then
        OPTIONS+="* $scheme"$'\n'
    else
        OPTIONS+="$scheme"$'\n'
    fi
done

OPTIONS="${OPTIONS%$'\n'}"

SELECTED=$(echo -e "$OPTIONS" | fuzzel --dmenu -p "Color Scheme:" --lines 9 --width 20)

if [ -n "$SELECTED" ]; then
    SELECTED="${SELECTED#\* }"
    SELECTED="${SELECTED#  }"

    cat > "$CONFIG_FILE" <<EOF
SCHEME="$SELECTED"
TAGS="$TAGS"
RATING="$RATING"
RES="$RES"
ENGINE="$ENGINE"
WALLPAPER="$WALLPAPER"
EOF

    if [ -f "$HOME/.cache/current_wallpaper" ]; then
        CURRENT_WALL=$(cat "$HOME/.cache/current_wallpaper")
        if [ -f "$CURRENT_WALL" ]; then
            (
                if [[ "$CURRENT_WALL" == *.mp4 ]]; then
                    FRAME_PATH="/tmp/video_frame.jpg"
                    ffmpeg -y -i "$CURRENT_WALL" -ss 00:00:02 -vframes 1 "$FRAME_PATH" >/dev/null 2>&1
                    matugen image "$FRAME_PATH" -m dark -t "scheme-$SELECTED" >/dev/null 2>&1
                else
                    matugen image "$CURRENT_WALL" -m dark -t "scheme-$SELECTED" >/dev/null 2>&1
                fi

                pgrep -x waybar >/dev/null && pkill -SIGUSR2 waybar
                pgrep -x mako >/dev/null && makoctl reload
                gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' >/dev/null 2>&1
                sleep 0.1
                gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' >/dev/null 2>&1

                notify-send "Scheme Applied" "$SELECTED" -i preferences-color
            ) >/dev/null 2>&1 &
            disown
        fi
    else
        notify-send "Scheme Changed" "$SELECTED" -i preferences-color
    fi
fi
