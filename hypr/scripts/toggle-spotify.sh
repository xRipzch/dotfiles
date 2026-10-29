#!/usr/bin/env bash
# Super+M handler: launches Sonora straight onto its special workspace if it is not
# running, otherwise toggles that workspace. A Sonora window sitting on a normal
# workspace is moved over first.
#
# The windowrule in rules/general.conf does not match on Hyprland 0.56, so the
# target workspace rides along on the exec dispatcher instead.

set -euo pipefail

readonly WM_CLASS="sonora"
readonly SPECIAL_NAME="sonora"
readonly SPECIAL_WORKSPACE="special:${SPECIAL_NAME}"
readonly LAUNCH_TIMEOUT_TICKS=100
readonly LAUNCH_POLL_SECONDS=0.1

app_workspace() {
    hyprctl clients -j | jq -r --arg c "$WM_CLASS" \
        '[.[] | select(.class | ascii_downcase == $c)][0].workspace.name // empty'
}

wait_for_window() {
    local tick
    for ((tick = 0; tick < LAUNCH_TIMEOUT_TICKS; tick++)); do
        [[ -n "$(app_workspace)" ]] && return 0
        sleep "$LAUNCH_POLL_SECONDS"
    done
    echo "toggle-spotify: Sonora window did not appear" >&2
    return 1
}

if [[ -z "$(app_workspace)" ]]; then
    hyprctl dispatch "hl.dsp.exec_cmd(\"sonora\", { workspace = \"${SPECIAL_WORKSPACE} silent\" })"
    wait_for_window
fi

# Sonora forks on launch, so the exec rule above can miss its window
if [[ "$(app_workspace)" != "$SPECIAL_WORKSPACE" ]]; then
    hyprctl dispatch "hl.dsp.window.move({ window = \"class:^(${WM_CLASS})$\", workspace = \"${SPECIAL_WORKSPACE}\", follow = false })"
fi

hyprctl dispatch "hl.dsp.workspace.toggle_special(\"$SPECIAL_NAME\")"
