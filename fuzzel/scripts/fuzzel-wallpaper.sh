#!/bin/bash

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
CONFIG_DIR="$HOME/.config/fireflyshell"
CONFIG_FILE="$CONFIG_DIR/options.conf"

mkdir -p "$CONFIG_DIR"

# Load config options
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

SCHEME="${SCHEME:-tonal-spot}"
TAGS="${TAGS:-}"
RATING="${RATING:-any}"
RES="${RES:-Any}"
ENGINE="${ENGINE:-awww}"
WALLPAPER="${WALLPAPER:-}"

# Save function to easily write config
save_config() {
    cat > "$CONFIG_FILE" <<EOF
SCHEME="$SCHEME"
TAGS="$TAGS"
RATING="$RATING"
RES="$RES"
ENGINE="$ENGINE"
WALLPAPER="$WALLPAPER"
EOF
}

SOURCE_OPTS="Local\nOnline\nVideo"
SOURCE_SELECTED=$(echo -e "$SOURCE_OPTS" | fuzzel --dmenu -p "Source:" --lines 3 --width 20)

if [ -z "$SOURCE_SELECTED" ]; then
    exit 0
fi

if [ "$SOURCE_SELECTED" == "Local" ]; then
    mapfile -t FILES < <(find "$WALLPAPER_DIR" -type f \( \
        -iname "*.jpg" -o \
        -iname "*.png" -o \
        -iname "*.jpeg" -o \
        -iname "*.webp" \))

    DISPLAY_LIST=""
    for file in "${FILES[@]}"; do
        DISPLAY_LIST+="${file#"$WALLPAPER_DIR/"}"$'\n'
    done

    SELECTED=$(echo "$DISPLAY_LIST" | fuzzel --dmenu -p "Select Wallpaper:" --lines 15 --width 40)

    if [ -n "$SELECTED" ]; then
        FULL_PATH="$WALLPAPER_DIR/$SELECTED"
        echo "$FULL_PATH" > "$HOME/.cache/current_wallpaper"

        pgrep -x mpvpaper > /dev/null && pkill mpvpaper

        awww img "$FULL_PATH" \
            --transition-type grow \
            --transition-pos 0.5,0.5 \
            --transition-step 90 \
            --transition-fps 60

        ENGINE="awww"
        WALLPAPER="$FULL_PATH"
        save_config

        SELECTED_INFO="$SELECTED"
    else
        exit 0
    fi

elif [ "$SOURCE_SELECTED" == "Online" ]; then
    while true; do
        LOOP_OPTS="Apply\nTags: ${TAGS:-(none)}\nRating: $RATING\nMin Res: $RES"
        LOOP_SELECTED=$(echo -e "$LOOP_OPTS" | fuzzel --dmenu -p "Select Options:" --lines 4 --width 40)

        if [ -z "$LOOP_SELECTED" ]; then
            exit 0
        fi

        if [[ "$LOOP_SELECTED" == "Back" ]]; then
            exec "$0"
        elif [[ "$LOOP_SELECTED" == Apply* ]]; then
            break
        elif [[ "$LOOP_SELECTED" == Tags:* ]]; then
            if [ -n "$TAGS" ]; then
                CURRENT_TAG_LIST=$(echo "$TAGS" | tr ' ' '\n')
                TAG_OPTS="$CURRENT_TAG_LIST"
                NEW_TAGS=$(echo -e "$TAG_OPTS" | fuzzel --dmenu -p "Add Tags:" --lines 6 --width 40)
            fi

            if [ -n "$NEW_TAGS" ] && [ "$NEW_TAGS" != "(done)" ]; then
                if [ "$NEW_TAGS" == "(clear)" ] || [ "$NEW_TAGS" == "(none)" ]; then
                    TAGS=""
                else
                    FORMATTED_TAG=$(echo "$NEW_TAGS" | tr ' ' '_')

                    if echo " $TAGS " | grep -q " $FORMATTED_TAG "; then
                        TAGS=$(echo " $TAGS " | sed "s/ $FORMATTED_TAG / /g" | xargs)
                    else
                        if [ -z "$TAGS" ]; then
                            TAGS="$FORMATTED_TAG"
                        else
                            TAGS="$TAGS $FORMATTED_TAG"
                        fi
                    fi
                fi
                save_config
            fi
        elif [[ "$LOOP_SELECTED" == Rating:* ]]; then
            RATING_OPTS="safe\nquestionable\nexplicit\nany"
            NEW_RATING=$(echo -e "$RATING_OPTS" | fuzzel --dmenu -p "Select Rating:" --lines 4 --width 20)
            if [ -n "$NEW_RATING" ]; then
                RATING="$NEW_RATING"
                save_config
            fi
        elif [[ "$LOOP_SELECTED" == Min\ Res:* ]]; then
            RES_OPTS="Any\n1920x1080\n2560x1440\n3840x2160"
            NEW_RES=$(echo -e "$RES_OPTS" | fuzzel --dmenu -p "Select Min Res:" --lines 4 --width 20)
            if [ -n "$NEW_RES" ]; then
                RES="$NEW_RES"
                save_config
            fi
        fi
    done

    QUERY_TAGS="order:random"
    if [ "$RATING" != "any" ]; then
        QUERY_TAGS="$QUERY_TAGS rating:$RATING"
    fi
    if [ "$RES" != "Any" ]; then
        WIDTH="${RES%%x*}"
        HEIGHT="${RES##*x}"
        QUERY_TAGS="$QUERY_TAGS width:$WIDTH.. height:$HEIGHT.."
    fi

    if [ -n "$TAGS" ]; then
        read -r -a TAG_ARRAY <<< "$TAGS"
        RANDOM_INDEX=$((RANDOM % ${#TAG_ARRAY[@]}))
        SELECTED_RANDOM_TAG="${TAG_ARRAY[$RANDOM_INDEX]}"

        QUERY_TAGS="$QUERY_TAGS $SELECTED_RANDOM_TAG"
        SELECTED_INFO="Wallpaper (Tag: $SELECTED_RANDOM_TAG)"
    else
        SELECTED_INFO="Wallpaper (Random)"
    fi

    ENCODED_TAGS=$(echo "$QUERY_TAGS" | jq -sRr @uri)
    API="https://konachan.net/post.json?limit=1&tags=$ENCODED_TAGS"

    notify-send "Fetching Wallpaper..." "Querying Konachan API"

    RESPONSE=$(curl -s -L "$API")
    URL=$(echo "$RESPONSE" | jq -r '.[0].file_url')

    if [ "$URL" = "null" ] || [ -z "$URL" ]; then
        notify-send "Wallpaper Error" "Could not find image matching those tags." -u critical
        exit 1
    fi

    DL_DIR="$HOME/Pictures/Wallpapers/Konachan"
    mkdir -p "$DL_DIR"

    FILENAME=$(basename "$URL")
    FULL_PATH="$DL_DIR/$FILENAME"

    if [ -s "$FULL_PATH" ]; then
        notify-send "Using Existing..." "Wallpaper already downloaded: $FILENAME"
    else
        notify-send "Downloading..." "Downloading $FILENAME"
        curl -s -L "$URL" -o "$FULL_PATH"

        if [ ! -s "$FULL_PATH" ]; then
            notify-send "Wallpaper Error" "Failed to download image." -u critical
            exit 1
        fi
    fi

    echo "$FULL_PATH" > "$HOME/.cache/current_wallpaper"

    pgrep -x mpvpaper > /dev/null && pkill mpvpaper

    awww img "$FULL_PATH" \
        --transition-type grow \
        --transition-pos 0.5,0.5 \
        --transition-step 90 \
        --transition-fps 60

    ENGINE="awww"
    WALLPAPER="$FULL_PATH"
    save_config
elif [ "$SOURCE_SELECTED" == "Video" ]; then
    mapfile -t FILES < <(find "$WALLPAPER_DIR" -type f -iname "*.mp4")

    DISPLAY_LIST=""
    for file in "${FILES[@]}"; do
        DISPLAY_LIST+="${file#"$WALLPAPER_DIR/"}"$'\n'
    done

    SELECTED=$(echo "$DISPLAY_LIST" | fuzzel --dmenu -p "Select Video:" --lines 15 --width 40)

    if [ -n "$SELECTED" ]; then
        FULL_PATH="$WALLPAPER_DIR/$SELECTED"
        echo "$FULL_PATH" > "$HOME/.cache/current_wallpaper"

        FRAME_PATH="/tmp/video_frame.jpg"
        notify-send "Processing Video..." "Extracting frame for colors"
        ffmpeg -y -i "$FULL_PATH" -ss 00:00:02 -vframes 1 "$FRAME_PATH" 2>/dev/null

        awww clear 2>/dev/null
        pgrep -x mpvpaper > /dev/null && pkill mpvpaper
        
        nohup mpvpaper -vs -o "loop=inf no-audio hwdec=auto profile=fast" "*" "$FULL_PATH" > /dev/null 2>&1 &

        ENGINE="mpvpaper"
        WALLPAPER="$FULL_PATH"
        save_config
        
        export FULL_PATH="$FRAME_PATH"
        SELECTED_INFO="$SELECTED"
    else
        exit 0
    fi
fi

if [ -n "$FULL_PATH" ]; then
    matugen image "$FULL_PATH" -m dark -t "scheme-$SCHEME"

    pgrep -x waybar > /dev/null && pkill -SIGUSR2 waybar
    pgrep -x mako > /dev/null && makoctl reload

    notify-send "Wallpaper & Colors Updated" "$SELECTED_INFO (scheme: $SCHEME)" -i wallpaper
fi
