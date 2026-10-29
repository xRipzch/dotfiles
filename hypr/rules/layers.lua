-- LAYER RULES

local function layer(namespace, effects)
    effects.match = { namespace = namespace }
    return hl.layer_rule(effects)
end

layer("^wofi$", { blur = true, xray = true })
-- The eww bar surface spans the full width with transparent gaps between the pills; without
-- ignore_alpha the compositor blurs those gaps too, leaving a faint band behind the bar.
local EWW_BLUR_ALPHA_FLOOR = 0.3
layer("^eww$", { blur = true, xray = true, ignore_alpha = EWW_BLUR_ALPHA_FLOOR })
layer("^swaync-notification-window$", { blur = true, xray = true })
layer("^swaync-control-center$", { blur = true, xray = true, animation = "slide right" })
layer("^logout_dialog$", { blur = true })

-- Disabled in the old config (comments claimed the types were removed; they exist in Lua as
-- dim_around / ignore_alpha / blur_popups / no_anim). Enable deliberately if wanted:
-- layer("^wofi$", { dim_around = true, ignore_alpha = 0.9 })
-- layer("^swaync-control-center$", { ignore_alpha = 0.45 })
-- layer("^swaync-notification-window$", { ignore_alpha = 0.45 })
-- layer("^hyprswitch$", { no_anim = true })
