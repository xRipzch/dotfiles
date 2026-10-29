-- APPLICATION KEYBINDINGS
local v = require("config.variables")
local mod = v.mainMod
local exec = hl.dsp.exec_cmd

hl.bind(mod .. " + SHIFT + RETURN", exec(v.terminal))
hl.bind(mod .. " + RETURN", exec(v.terminal, { float = true, size = "800 450", center = true }))
hl.bind(mod .. " + E", exec(v.terminal .. " -e yazi"))
hl.bind(mod .. " + W", exec(v.browser))
hl.bind(mod .. " + M", exec("~/.config/hypr/scripts/toggle-spotify.sh"))
hl.bind(mod .. " + D", exec("~/.config/hypr/scripts/float-discord.sh"))
hl.bind(mod .. " + C", exec("/home/ravn/.local/bin/zed"))
hl.bind(mod .. " + O", exec("obsidian"))
hl.bind(mod .. " + SPACE", exec("pgrep wofi || " .. v.launcher))
hl.bind(mod .. " + SHIFT + A", exec("~/.config/scripts/utils/util-launcher.sh"))
hl.bind(mod .. " + N", exec("swaync-client -t"))
hl.bind(mod .. " + Escape", exec("pgrep wlogout || wlogout -b 2"))
-- Goes through logind so hypridle's lock_cmd owns the hyprlock instance
hl.bind(mod .. " + L", exec("loginctl lock-session"))
hl.bind(mod .. " + SHIFT + P", exec("hyprpicker -a"))
hl.bind(mod .. " + SHIFT + W", exec("waytrogen"))
hl.bind(mod .. " + ALT + W", exec("pgrep -x eww >/dev/null && eww -c ~/.config/eww/bar kill || ~/.config/eww/bar/launch"))
hl.bind(mod .. " + B", exec("eww -c ~/.config/eww/bar open --toggle panel"))
hl.bind(mod .. " + ALT + B", exec("bongocat -c ~/.config/bongocat/bongo.conf --toggle"))
hl.bind(mod .. " + ALT + N", exec("~/.config/scripts/restart-swaync.sh"))
