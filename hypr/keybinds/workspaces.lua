-- WORKSPACE KEYBINDINGS
local v = require("config.variables")
local mod = v.mainMod
local dsp = hl.dsp

local WORKSPACE_COUNT = 10

for i = 1, WORKSPACE_COUNT do
    local key = i % WORKSPACE_COUNT -- workspace 10 sits on key 0
    hl.bind(mod .. " + " .. key, dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. key, dsp.window.move({ workspace = i }))
end

hl.bind(mod .. " + S", dsp.workspace.toggle_special("magic"))
hl.bind(mod .. " + CTRL + S", dsp.window.move({ workspace = "special:magic" }))
hl.bind(mod .. " + ALT + S", dsp.window.move({ workspace = "special:magic", follow = false }))

-- WORKSPACE SCROLLING
hl.bind(mod .. " + comma", dsp.focus({ workspace = "-1" }))
hl.bind(mod .. " + period", dsp.focus({ workspace = "+1" }))
hl.bind(mod .. " + mouse_down", dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up", dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + SHIFT + comma", dsp.window.move({ workspace = "r-1" }))
hl.bind(mod .. " + SHIFT + period", dsp.window.move({ workspace = "r+1" }))
hl.bind(mod .. " + SHIFT + mouse_down", dsp.window.move({ workspace = "r-1" }))
hl.bind(mod .. " + SHIFT + mouse_up", dsp.window.move({ workspace = "r+1" }))

-- WINDOW SWITCHING (NOTE: Requires `hyprswitch`)
hl.bind("SUPER + tab", dsp.exec_cmd(
    "hyprswitch gui --mod-key super --key tab --close mod-key-release --reverse-key=key=grave"
        .. " --sort-recent --max-switch-offset 0 && hyprswitch dispatch"
))
