-- HYPRLAND MONITOR CONFIGURATION
-- Matched by EDID description instead of connector name (eDP-1/eDP-2), since the
-- connector name flips depending on whether the panel is driven by the AMD iGPU
-- or the NVIDIA dGPU (envycontrol / GPU mode switch).
hl.monitor({
    output = "desc:BOE NE153WUM-NY1",
    mode = "1920x1200@165",
    position = "0x0",
    scale = 1,
})
