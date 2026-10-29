#!/usr/bin/env bash
# Super+Q handler: sends Spotify to its special workspace instead of killing it,
# so playback keeps running. Every other window is closed as usual.
#
# The windowrule in rules/general.conf does not match on Hyprland 0.56, so Spotify
# usually sits on a normal workspace; it has to be moved to the special workspace
# explicitly (toggling an empty special workspace just dims the screen).

set -euo pipefail

readonly HIDE_CLASS="spotify"
readonly SPECIAL_WORKSPACE="special:spotify"

active_class="$(hyprctl activewindow -j | jq -r '.class // empty')"
active_workspace="$(hyprctl activewindow -j | jq -r '.workspace.name // empty')"

if [[ "${active_class,,}" != "$HIDE_CLASS" ]]; then
    hyprctl dispatch 'hl.dsp.window.close()'
elif [[ "$active_workspace" == "$SPECIAL_WORKSPACE" ]]; then
    hyprctl dispatch "hl.dsp.workspace.toggle_special(\"${SPECIAL_WORKSPACE#special:}\")"
else
    hyprctl dispatch "hl.dsp.window.move({ workspace = \"$SPECIAL_WORKSPACE\", follow = false })"
fi
