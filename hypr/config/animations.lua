-- ANIMATION CONFIGURATION
local v = require("config.variables")

hl.config({ animations = { enabled = true } })

-- Curves: name -> { x1, y1 }, { x2, y2 }
local curves = {
    linear   = { { 0, 0 },       { 1, 1 } },
    easeIn   = { { 0.42, 0.0 },  { 1, 1 } },
    easeOut  = { { 0.0, 0.0 },   { 0.58, 1 } },
    balanced = { { 0.2, 0 },     { 0.3, 1 } },
    smooth   = { { 0.25, 0.1 },  { 0.25, 1 } },
    crisp    = { { 0.3, 0 },     { 0.4, 1 } },
    flow     = { { 0.15, 0 },    { 0.35, 1 } },
}
for name, points in pairs(curves) do
    hl.curve(name, { type = "bezier", points = points })
end

local function animate(leaf, speed, bezier, style)
    hl.animation({ leaf = leaf, enabled = true, speed = speed, bezier = bezier, style = style })
end

-- Window animations
animate("windows", 4, "smooth")
animate("windowsIn", 3, "balanced", "slide")
animate("windowsOut", 2, "crisp", "slide")
animate("windowsMove", 3, "flow")

-- Fade animations
animate("fadeLayers", 2, "smooth")

-- Layer animations - overlays, notifications, menus
animate("layers", 2, "balanced")
animate("layersIn", 2, "smooth", "slide")
animate("layersOut", 1, "crisp", "slide")

-- Border animations - responsive feedback
animate("border", 4, "balanced")

-- Workspaces
animate("workspaces", 4, "flow", "slide")

-- Special workspace
animate("specialWorkspaceIn", v.animSpeedFast, "easeIn", "fade")
animate("specialWorkspaceOut", v.animSpeedFast, "easeOut", "fade")
