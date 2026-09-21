#!/usr/bin/env bash
# Focuses the Discord window, or launches Discord floating/resized/centered.
#
# Hyprland 0.56 no longer applies hyprlang "windowrule" lines - they parse without
# error but never match, so the float/size/center rules have to ride along on the
# exec dispatcher instead. See rules/floating.conf.

set -euo pipefail

readonly WM_CLASS="discord"
readonly WIDTH=1400
readonly HEIGHT=900

address=$(hyprctl clients -j | jq -r --arg class "$WM_CLASS" \
	'[.[] | select(.class == $class)] | last | .address // empty')

# Discord keeps running in the tray with no window, so match on the window, not
# the process - a stale process check would focus nothing and launch nothing.
if [[ -n "$address" ]]; then
	hyprctl dispatch focuswindow "address:$address"
	exit 0
fi

hyprctl dispatch exec "[float; size $WIDTH $HEIGHT; center] discord"
