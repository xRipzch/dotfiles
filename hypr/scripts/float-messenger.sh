#!/usr/bin/env bash
# Launches the Messenger webapp and floats/resizes/centers its window.

set -euo pipefail

readonly WM_CLASS="WebApp-Messenger4386"
readonly WIDTH=1400
readonly HEIGHT=820
readonly POLL_INTERVAL=0.1
readonly TIMEOUT_SECONDS=10

XAPP_FORCE_GTKWINDOW_ICON="messenger-indicator" firefox \
	--class "$WM_CLASS" --name "$WM_CLASS" \
	--profile /home/ravn/.local/share/ice/firefox/Messenger4386 \
	--no-remote "https://www.messenger.com" &

elapsed=0
address=""
while (($(echo "$elapsed < $TIMEOUT_SECONDS" | bc -l))); do
	address=$(hyprctl clients -j | jq -r --arg class "$WM_CLASS" \
		'[.[] | select(.class == $class)] | last | .address // empty')
	[[ -n "$address" ]] && break
	sleep "$POLL_INTERVAL"
	elapsed=$(echo "$elapsed + $POLL_INTERVAL" | bc -l)
done

if [[ -z "$address" ]]; then
	exit 0
fi

hyprctl dispatch setfloating "address:$address"
hyprctl dispatch resizewindowpixel "exact $WIDTH $HEIGHT,address:$address"
hyprctl dispatch centerwindow "address:$address"
