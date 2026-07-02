#!/bin/bash
set -euo pipefail

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
CURRENT=$(awww query 2>/dev/null | grep -oP '(?<=image: ).*' | head -n1 | tr -d '\n\r')

NEXT=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) ! -path "$CURRENT" | shuf -n1)

if [[ -z "$NEXT" ]]; then
    exit 0
fi

awww img "$NEXT" --transition-type simple --transition-duration 2

echo "$NEXT" > "$HOME/.config/waytrogen/wallpaper.txt"

exec "$HOME/.config/scripts/theme/theme-sync.sh"
