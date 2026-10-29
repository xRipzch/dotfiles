-- MEDIA & SYSTEM KEYBINDINGS
local v = require("config.variables")
local mod = v.mainMod
local exec = hl.dsp.exec_cmd

local VOLUME_BRIGHTNESS_KEYS = {
    XF86AudioRaiseVolume = "volume_up",
    XF86AudioLowerVolume = "volume_down",
    XF86AudioMute = "volume_mute",
    XF86AudioMicMute = "mic_mute",
    XF86MonBrightnessUp = "brightness_up",
    XF86MonBrightnessDown = "brightness_down",
}
for key, action in pairs(VOLUME_BRIGHTNESS_KEYS) do
    hl.bind(key, exec(v.volumeBrightness .. " " .. action), { locked = true, repeating = true })
end

local TRANSPORT_KEYS = {
    XF86AudioPlay = "play_pause",
    XF86AudioPause = "play_pause",
    XF86AudioNext = "next_track",
    XF86AudioPrev = "prev_track",
}
for key, action in pairs(TRANSPORT_KEYS) do
    hl.bind(key, exec(v.volumeBrightness .. " " .. action), { locked = true })
end

-- SCREENSHOTS
local SCREENSHOT = "~/.config/scripts/utils/screenshot.sh -r "
hl.bind("ALT + SHIFT + F", exec(SCREENSHOT .. "fullscreen"))
hl.bind("ALT + SHIFT + W", exec(SCREENSHOT .. "workspace"))
hl.bind("ALT + SHIFT + S", exec(SCREENSHOT .. "selection"))
hl.bind(mod .. " + SHIFT + S", exec(SCREENSHOT .. "selection"))

-- LAPTOP LID SWITCH HANDLING
-- Note: Remember to modify /etc/systemd/logind.conf before using
hl.bind("switch:on:Lid Switch", function()
    hl.monitor({ output = "eDP-1", disabled = true })
    hl.dispatch(hl.dsp.exec_cmd("hyprctl reload")) -- Lid closed
end, { locked = true })
hl.bind("switch:off:Lid Switch", function()
    hl.monitor({ output = "eDP-1", disabled = false })
    hl.dispatch(hl.dsp.exec_cmd("hyprctl reload")) -- Lid opened
end, { locked = true })
