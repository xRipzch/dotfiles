-- AUTOSTART APPLICATIONS
local v = require("config.variables")

local CURSOR_REFRESH_DELAY_MS = 1000

-- awww-daemon has crashed intermittently on this dual-GPU (amdgpu card1+card2) setup;
-- auto-restart it on crash instead of leaving the background black until next login.
-- Only start a daemon when none answers: waytrogen -r may already have started one, and a
-- second awww-daemon aborts (and dumps core) on the taken socket every second forever.
-- The loop ends when the Hyprland session's Wayland socket disappears.
local AWWW_SUPERVISOR =
    [[sh -c 'while [ -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ]; do awww query >/dev/null 2>&1 || awww-daemon; sleep 1; done']]

local startup = {
    "~/.config/eww/bar/launch",
    "hypridle",
    "/usr/lib/hyprpolkitagent/hyprpolkitagent",
    "udiskie",
    "swaync",
    "easyeffects --gapplication-service",
    "gnome-keyring-daemon --start --components=secrets",
    AWWW_SUPERVISOR,
    "sleep 2 && waytrogen -r",
    "hyprswitch init --show-title --size-factor 5 --workspaces-per-row 4 --custom-css "
        .. v.configDir .. "/config/hyprswitch.css",
}

hl.on("hyprland.start", function()
    for _, cmd in ipairs(startup) do
        hl.exec_cmd(cmd)
    end

    -- Forces a fresh cursor-plane render, clearing a stale default-arrow artifact left over
    -- from before the themed cursor is applied at boot (dual-GPU hardware cursor plane bug).
    hl.timer(function()
        hl.config({ cursor = { no_hardware_cursors = true } })
        hl.config({ cursor = { no_hardware_cursors = false } })
    end, { timeout = CURSOR_REFRESH_DELAY_MS, type = "oneshot" })
end)
