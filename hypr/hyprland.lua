-- HYPRLAND MAIN CONFIGURATION (Lua)
-- Replaces hyprland.conf; the old .conf tree is kept as rollback and ignored while this exists.

-- CORE CONFIGURATION MODULES
require("config.variables")
require("config.environment")
require("config.appearance")
require("config.animations")
require("config.layouts")
require("config.input")
require("config.autostart")

-- KEYBINDING MODULES
require("keybinds.applications")
require("keybinds.windows")
require("keybinds.workspaces")
require("keybinds.media")

-- SYSTEM-SPECIFIC MODULES
require("monitors")

-- RULES
require("rules.windows")
require("rules.layers")
