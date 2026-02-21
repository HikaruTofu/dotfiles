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

# Save function to easily write config
save_config() {
    cat > "$CONFIG_FILE" <<EOF
SCHEME="$SCHEME"
TAGS="$TAGS"
RATING="$RATING"
RES="$RES"
EOF
}

SOURCE_OPTS="Local\nOnline"
SOURCE_SELECTED=$(echo -e "$SOURCE_OPTS" | fuzzel --dmenu -p "Source:" --lines 2 --width 20)

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
        
        SELECTED_INFO="$SELECTED"
    else
        exit 0
    fi

elif [ "$SOURCE_SELECTED" == "Online" ]; then
    while true; do
        LOOP_OPTS="Apply\nTags: ${TAGS:-(none)}\nRating: $RATING\nMin Res: $RES\nBack"
        LOOP_SELECTED=$(echo -e "$LOOP_OPTS" | fuzzel --dmenu -p "Konachan:" --lines 5 --width 40)

        if [ -z "$LOOP_SELECTED" ]; then
            exit 0
        fi

        if [[ "$LOOP_SELECTED" == "Back" ]]; then
            exec "$0"
        elif [[ "$LOOP_SELECTED" == Apply* ]]; then
            break
        elif [[ "$LOOP_SELECTED" == Tags:* ]]; then
            NEW_TAGS=$(echo -e "${TAGS}\n(clear)" | fuzzel --dmenu -p "Enter Tags:" --lines 2 --width 40)
            if [ -n "$NEW_TAGS" ]; then
                if [ "$NEW_TAGS" == "(clear)" ] || [ "$NEW_TAGS" == "(none)" ]; then
                    TAGS=""
                else
                    TAGS="$NEW_TAGS"
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

    # Build query tags
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
        QUERY_TAGS="$QUERY_TAGS $TAGS"
    fi
    
    # URL encode tags
    ENCODED_TAGS=$(echo "$QUERY_TAGS" | sed 's/ /+/g')
    API="https://konachan.net/post.json?limit=1&tags=$ENCODED_TAGS"

    notify-send "Fetching Wallpaper..." "Querying Konachan API"

    # Fetch from API
    RESPONSE=$(curl -s -L "$API")
    URL=$(echo "$RESPONSE" | jq -r '.[0].file_url')

    # Verify URL
    if [ "$URL" = "null" ] || [ -z "$URL" ]; then
        notify-send "Konahchan Error" "Could not find image matching those tags." -u critical
        exit 1
    fi

    # Set up Download Directory
    DL_DIR="$HOME/Pictures/Wallpapers/Konachan"
    mkdir -p "$DL_DIR"

    # Download it
    FILENAME=$(basename "$URL")
    FULL_PATH="$DL_DIR/$FILENAME"

    # Jika file sudah ada, skip download
    if [ -s "$FULL_PATH" ]; then
        notify-send "Using Existing..." "Wallpaper already downloaded: $FILENAME"
    else
        notify-send "Downloading..." "Downloading $FILENAME"
        curl -s -L "$URL" -o "$FULL_PATH"

        if [ ! -s "$FULL_PATH" ]; then
            notify-send "Konahchan Error" "Failed to download image." -u critical
            exit 1
        fi
    fi

    echo "$FULL_PATH" > "$HOME/.cache/current_wallpaper"

    # Apply via awww
    awww img "$FULL_PATH" \
        --transition-type grow \
        --transition-pos 0.5,0.5 \
        --transition-step 90 \
        --transition-fps 60
    
    SELECTED_INFO="Konachan Online (Tags: $TAGS)"
fi

# Apply Matugen and notify
if [ -n "$FULL_PATH" ]; then
    # Generate dengan scheme type argument
    matugen image "$FULL_PATH" -m dark -t "scheme-$SCHEME"

    pgrep -x waybar > /dev/null && pkill -SIGUSR2 waybar
    pgrep -x mako > /dev/null && makoctl reload

    notify-send "Wallpaper & Colors Updated" "$SELECTED_INFO (scheme: $SCHEME)" -i wallpaper
fi

