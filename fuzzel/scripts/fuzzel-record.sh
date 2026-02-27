#!/bin/bash

# Ensure output directory exists
SAVE_DIR="${XDG_VIDEOS_DIR:-$HOME/Videos}/Recordings"
mkdir -p "$SAVE_DIR"
CONFIG_FILE="$HOME/.config/niri/options.conf"

# Read existing global config from Niri options
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Defaults if not configured globally
REC_FPS="${REC_FPS:-60}"
REC_AUDIO="${REC_AUDIO:-No Audio}"
REC_QUALITY="${REC_QUALITY:-high}"

# Ensure these variables exist in the global options file 
save_config() {
    # Replace existing lines or append if missing
    for var in REC_FPS REC_AUDIO REC_QUALITY; do
        if grep -q "^${var}=" "$CONFIG_FILE"; then
            sed -i "s/^${var}=.*/${var}=\"${!var}\"/" "$CONFIG_FILE"
        else
            echo "${var}=\"${!var}\"" >> "$CONFIG_FILE"
        fi
    done
}

# Check if an argument was passed to bypass the menu
if [ -n "$1" ]; then
    SELECTED="$1"
else
    # Build inline menu
    if pidof gpu-screen-recorder > /dev/null; then
        OPTIONS="Stop Recording (Running)\nFPS [$REC_FPS]\nAudio [$REC_AUDIO]\nQuality [$REC_QUALITY]"
    else
        OPTIONS="Record Screen\nRecord Region\nRecord Active Window\nFPS [$REC_FPS]\nAudio [$REC_AUDIO]\nQuality [$REC_QUALITY]"
    fi

    SELECTED=$(echo -e "$OPTIONS" | fuzzel --dmenu -p "Record:" --lines 6 --width 35 --no-run-if-empty)
fi

[ -z "$SELECTED" ] && exit 0

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

case "$SELECTED" in
    "Stop Recording (Running)"|"--stop"|"Record Screen"|"--screen"|"Record Region"|"--region"|"Record Active Window"|"--window")
        # If any recording is already running, intercept and kill it instead
        if pidof gpu-screen-recorder > /dev/null; then
            killall -INT gpu-screen-recorder
            notify-send -r 1 "Recording Stopped" "Video saved to $SAVE_DIR"
            exit 0
        fi
        
        # If it wasn't running but we are asked to stop, exit silently
        if [[ "$SELECTED" == "Stop Recording (Running)" ]] || [[ "$SELECTED" == "--stop" ]]; then
            exit 0
        fi
        
        # Otherwise, proceed to start the recording
        AUDIO_ARG=""
        if [ "$REC_AUDIO" == "Default Output" ] && command -v pactl > /dev/null; then
            AUDIO_ARG="-a $(pactl get-default-sink).monitor"
        elif [ "$REC_AUDIO" == "Default Input" ] && command -v pactl > /dev/null; then
            AUDIO_ARG="-a $(pactl get-default-source)"
        fi
        
        case "$SELECTED" in
            "Record Screen"|"--screen")
                TARGET="screen"
                ;;
            "Record Region"|"--region")
                TARGET=$(slurp -d -w 1 -b "#1a1a1a33" -c "#00ffcc" -f "%wx%h+%x+%y")
                [ -z "$TARGET" ] && exit 1
                ;;
            "Record Active Window"|"--window")
                sleep 0.5
                TARGET=$(niri msg -j focused-window | jq -r 'if . then "\(.width)x\(.height)+\(.x)+\(.y)" else "" end')
                if [ -z "$TARGET" ]; then
                    notify-send -r 1 "Recording Failed" "No active window found"
                    exit 1
                fi
                ;;
        esac
        
        notify-send -r 1 "Recording Started" "Saving to $SAVE_DIR/record-$TIMESTAMP.mp4"
        gpu-screen-recorder -w "$TARGET" -f "$REC_FPS" -q "$REC_QUALITY" $AUDIO_ARG -o "$SAVE_DIR/record-$TIMESTAMP.mp4" &
        ;;
    FPS\ *)
        NEW_FPS=$(echo -e "30\n60\n120" | fuzzel --dmenu -p "Select FPS:" --lines 3 --width 20 --no-run-if-empty)
        if [ -n "$NEW_FPS" ]; then
            REC_FPS="$NEW_FPS"
            save_config
        fi
        exec "$0"
        ;;
    Audio\ *)
        NEW_AUDIO=$(echo -e "No Audio\nDefault Output\nDefault Input" | fuzzel --dmenu -p "Select Audio:" --lines 3 --width 20 --no-run-if-empty)
        if [ -n "$NEW_AUDIO" ]; then
            REC_AUDIO="$NEW_AUDIO"
            save_config
        fi
        exec "$0"
        ;;
    Quality\ *)
        NEW_QUAL=$(echo -e "very_high\nhigh\nmedium\nlow" | fuzzel --dmenu -p "Select Quality:" --lines 4 --width 20 --no-run-if-empty)
        if [ -n "$NEW_QUAL" ]; then
            REC_QUALITY="$NEW_QUAL"
            save_config
        fi
        exec "$0"
        ;;
esac
