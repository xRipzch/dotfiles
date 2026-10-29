-- APPEARANCE CONFIGURATION
local v = require("config.variables")

-- Border colours are regenerated from the wallpaper by wallust (config/border.lua);
-- the fallback is the last palette used, in case the file has not been generated yet.
local FALLBACK_BORDER = {
    active = { colors = { "rgb(8B7265)", "rgb(567BAF)", "rgb(EB8E89)", "rgb(BCBBA5)", "rgb(667D72)" } },
    inactive = "rgba(050605ee)",
}
local loaded, border = pcall(require, "config.border")
if not loaded then
    border = FALLBACK_BORDER
end

hl.config({
    general = {
        border_size = v.borderSize,
        gaps_in = v.gapsIn,
        gaps_out = v.gapsOut,
        resize_on_border = true,
        no_focus_fallback = true,
        allow_tearing = true,
        layout = "master",

        col = {
            active_border = border.active,
            inactive_border = border.inactive,
        },

        snap = {
            enabled = true,
        },
    },

    cursor = {
        hide_on_key_press = true,
        inactive_timeout = 4,
        warp_on_toggle_special = 1,
    },

    decoration = {
        rounding = v.rounding,
        active_opacity = v.opacityActive,
        inactive_opacity = v.opacityInactive,
        dim_special = v.opacitySpecial,

        shadow = {
            enabled = false,
            range = 0,
            render_power = 3,
            color = "rgba(1a1a1aee)",
        },

        blur = {
            enabled = true,
            size = 6,
            noise = 0.03,
            passes = 2,
            vibrancy = 0,
            xray = true,
            special = false,
            popups = true,
            input_methods = true,
            input_methods_ignorealpha = 0.8,
        },
    },

    misc = {
        force_default_wallpaper = 0,
        font_family = v.fontFamily,
        vrr = 0,
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
        animate_manual_resizes = false,
        animate_mouse_windowdragging = false,
        enable_swallow = false,
        swallow_regex = "(kitty|ghostty|Ghostty)",
        allow_session_lock_restore = true,
        initial_workspace_tracking = false,
        focus_on_activate = true,
    },
})
