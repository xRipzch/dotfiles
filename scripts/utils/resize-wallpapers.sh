#!/bin/bash
# Resize all wallpapers down to screen resolution in-place
# No point storing 8K images for a 1920x1200 screen

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
MAX_RES="1920x1200"

shopt -s nullglob
files=("$WALLPAPER_DIR"/*.{jpg,jpeg,png,webp})

total=${#files[@]}
count=0

for f in "${files[@]}"; do
    count=$((count + 1))
    filename=$(basename "$f")

    # Get current dimensions
    dims=$(magick identify -format "%wx%h" "$f" 2>/dev/null)
    w=${dims%x*}
    h=${dims#*x}

    if [[ "$w" -le 1920 && "$h" -le 1200 ]]; then
        echo "[$count/$total] skip  $filename ($dims)"
        continue
    fi

    echo -n "[$count/$total] resize $filename ($dims → max $MAX_RES) ... "
    magick "$f" -resize "${MAX_RES}>" -quality 92 "$f" && echo "done" || echo "FAILED"
done

echo ""
echo "Done. Run 'du -sh $WALLPAPER_DIR' to see space saved."
