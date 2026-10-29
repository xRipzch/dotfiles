-- INPUT CONFIGURATION

hl.config({
    input = {
        kb_layout = "dk",
        kb_options = "caps:escape", -- Map Caps Lock to Escape (Vim-friendly)
        follow_mouse = 1,
        sensitivity = 0,

        touchpad = {
            natural_scroll = true,
            scroll_factor = 0.69,
        },
    },

    gestures = {
        workspace_swipe_distance = 300,
        workspace_swipe_min_speed_to_force = 25,
        workspace_swipe_cancel_ratio = 0.25,
        workspace_swipe_direction_lock_threshold = 15,
    },

    binds = {
        scroll_event_delay = 0,
        hide_special_on_workspace_change = true,
    },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

hl.device({
    name = "epic-mouse-v1",
    sensitivity = 0,
    natural_scroll = true,
})
