-- WINDOW MANAGEMENT KEYBINDINGS
local v = require("config.variables")
local mod = v.mainMod
local dsp = hl.dsp

local RESIZE_STEP = 20

hl.bind(mod .. " + Q", dsp.exec_cmd("~/.config/hypr/scripts/close-or-hide.sh"))
hl.bind(mod .. " + SHIFT + Q", dsp.window.close())
hl.bind(mod .. " + SHIFT + F", dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + F", dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(mod .. " + ALT + F", dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(mod .. " + bracketleft", dsp.layout("mfact -0.05"))
hl.bind(mod .. " + bracketright", dsp.layout("mfact +0.05"))

-- FREE DRAG / RESIZE (hold mod+key, move mouse; release to drop)
hl.bind(mod .. " + X", dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + Z", dsp.window.resize(), { mouse = true })

-- WINDOW FOCUS
-- SUPER + l is the lock bind - use SUPER + right to focus right
local FOCUS_KEYS = {
    h = "left", k = "up", j = "down",
    left = "left", right = "right", up = "up", down = "down",
}
for key, direction in pairs(FOCUS_KEYS) do
    hl.bind(mod .. " + " .. key, dsp.focus({ direction = direction }))
end

-- WINDOW MOVEMENT
local MOVE_KEYS = {
    h = "left", l = "right", k = "up", j = "down",
    left = "left", right = "right", up = "up", down = "down",
}
for key, direction in pairs(MOVE_KEYS) do
    hl.bind(mod .. " + SHIFT + " .. key, dsp.window.move({ direction = direction }))
end

-- SIZE ADJUSTMENT
hl.bind(mod .. " + R", dsp.submap("resize"))
hl.define_submap("resize", function()
    local RESIZE_KEYS = {
        l = { x = RESIZE_STEP, y = 0 },
        h = { x = -RESIZE_STEP, y = 0 },
        k = { x = 0, y = -RESIZE_STEP },
        j = { x = 0, y = RESIZE_STEP },
    }
    for key, delta in pairs(RESIZE_KEYS) do
        hl.bind(key, dsp.window.resize({ x = delta.x, y = delta.y, relative = true }), { repeating = true })
    end

    hl.bind("escape", dsp.submap("reset"))
end)
