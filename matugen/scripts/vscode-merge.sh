#!/bin/bash

# Define paths
SETTINGS_FILE="$HOME/.config/Antigravity/User/settings.json"
COLORS_FILE="$HOME/.config/matugen/vscode-colors.json"

# Ensure the settings file exists
if [ ! -f "$SETTINGS_FILE" ]; then
    echo "{}" > "$SETTINGS_FILE"
fi

# Merge Matugen colors into user settings using jq
if [ -f "$COLORS_FILE" ]; then
    jq -s '.[0] * .[1]' "$SETTINGS_FILE" "$COLORS_FILE" > "${SETTINGS_FILE}.tmp"
    if [ $? -eq 0 ]; then
        mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
    else
        echo "Error merging VSCode colors with jq"
        rm -f "${SETTINGS_FILE}.tmp"
    fi
fi
