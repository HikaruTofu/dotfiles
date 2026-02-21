#!/bin/bash

CONFIG_FILE="$HOME/.config/fireflyshell/options.conf"
mkdir -p "$(dirname "$CONFIG_FILE")"

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    CURRENT="${SCHEME:-tonal-spot}"
else
    CURRENT="tonal-spot"
fi

# Fallback values for other config
TAGS="${TAGS:-}"
RATING="${RATING:-any}"
RES="${RES:-Any}"

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
        OPTIONS+="  $scheme"$'\n'
    fi
done

OPTIONS="${OPTIONS%$'\n'}"

SELECTED=$(echo -e "$OPTIONS" | fuzzel --dmenu -p "Color Scheme:" --lines 9 --width 30)

if [ -n "$SELECTED" ]; then
    SELECTED="${SELECTED#\* }"
    SELECTED="${SELECTED#  }"

    cat > "$CONFIG_FILE" <<EOF
SCHEME="$SELECTED"
TAGS="$TAGS"
RATING="$RATING"
RES="$RES"
EOF

    if [ -f "$HOME/.cache/current_wallpaper" ]; then
        CURRENT_WALL=$(cat "$HOME/.cache/current_wallpaper")
        if [ -f "$CURRENT_WALL" ]; then
            # Regenerate dengan scheme baru pakai -t argument
            matugen image "$CURRENT_WALL" -m dark -t "scheme-$SELECTED"

            pgrep -x waybar > /dev/null && pkill -SIGUSR2 waybar
            pgrep -x mako > /dev/null && makoctl reload

            notify-send "Scheme Applied" "$SELECTED" -i preferences-color
        fi
    else
        notify-send "Scheme Changed" "$SELECTED" -i preferences-color
    fi
fi
