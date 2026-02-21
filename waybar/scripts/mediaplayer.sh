#!/usr/bin/env bash
# Waybar custom media module using playerctl
# Only outputs when there's actual track info

artist=$(playerctl metadata artist 2>/dev/null)
title=$(playerctl metadata title 2>/dev/null)
status=$(playerctl status 2>/dev/null)

if [[ -z "$title" && -z "$artist" ]]; then
    echo ""
    exit 0
fi

if [[ -n "$artist" && -n "$title" ]]; then
    text="$artist - $title"
elif [[ -n "$title" ]]; then
    text="$title"
elif [[ -n "$artist" ]]; then
    text="$artist"
fi

# Escape markup characters
text="${text//&/&amp;}"
text="${text//</&lt;}"
text="${text//>/&gt;}"

if [[ "$status" == "Paused" ]]; then
    echo "  $text"
else
    echo "  $text"
fi
