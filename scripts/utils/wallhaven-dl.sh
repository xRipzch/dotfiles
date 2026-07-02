#!/bin/bash
# Download wallpapers from a wallhaven collection (pages 1-18)
# Usage: wallhaven-dl.sh <api_key>

set -euo pipefail

API_KEY="${1:-}"
USER="lewdpatriot"
COLLECTION_ID="935888"
PAGES=18
DEST="$HOME/Pictures/Wallpapers"
API="https://wallhaven.cc/api/v1/collections/$USER/$COLLECTION_ID"

if [[ -z "$API_KEY" ]]; then
    echo "Usage: $0 <api_key>"
    echo "Get your key at: https://wallhaven.cc/settings/account"
    exit 1
fi

mkdir -p "$DEST"

total_downloaded=0
total_skipped=0

for page in $(seq 1 $PAGES); do
    echo ""
    echo "── Page $page / $PAGES ──────────────────────────"

    response=$(curl -sf "$API?apikey=$API_KEY&page=$page") || {
        echo "  ERROR: Failed to fetch page $page — check your API key or connection"
        exit 1
    }

    urls=$(echo "$response" | jq -r '.data[].path')

    if [[ -z "$urls" ]]; then
        echo "  No wallpapers found on page $page, stopping."
        break
    fi

    while IFS= read -r url; do
        filename=$(basename "$url")
        dest_file="$DEST/$filename"

        if [[ -f "$dest_file" ]]; then
            echo "  skip  $filename"
            total_skipped=$((total_skipped + 1))
            continue
        fi

        echo -n "  dl    $filename ... "
        if curl -sf -o "$dest_file" "$url"; then
            echo "done"
            total_downloaded=$((total_downloaded + 1))
        else
            echo "FAILED"
            rm -f "$dest_file"
        fi

        # Be polite to the API
        sleep 0.3
    done <<< "$urls"
done

echo ""
echo "Done. Downloaded: $total_downloaded  |  Skipped (already had): $total_skipped"
echo "Wallpapers saved to: $DEST"
