-- WINDOW RULES (general, floating, dialogs, media, opacity)
local v = require("config.variables")

local TERMINAL_CLASS = "^(" .. v.terminalClass .. ")$"
local BROWSERS = "(firefox|google-chrome|zen)"
local PIP_TITLE = ".*(Picture-in-Picture|Picture in Picture).*"
local OPACITY_FLOAT = string.format("%.2f %.2f", v.opacityFloat, v.opacityFloat)

local function rule(name, match, effects)
    effects.name = name
    effects.match = match
    return hl.window_rule(effects)
end

-- GENERAL
-- Ignore maximize requests from apps
rule("suppress-maximize-events", { class = ".*" }, { suppress_event = "maximize" })
-- Fix some dragging issues with XWayland
rule("fix-xwayland-drags", {
    class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false,
}, { no_focus = true })
-- No blur for empty class/title
rule("no-blur-empty", { class = "^$", title = "^$" }, { no_blur = true })

-- Dedicated special workspace for Spotify (opened via SUPER + M)
rule("spotify-special", { class = "^(spotify)$" }, { workspace = "special:spotify silent" })

-- FLOATING
rule("float-portal-gtk", { class = "^(xdg-desktop-portal-gtk)$" }, { float = true })

for _, title in ipairs({ "top", "btm", "htop" }) do
    rule("float-term-" .. title, { class = TERMINAL_CLASS, title = "^(" .. title .. ")$" }, { float = true })
end
rule("float-term-btop", { class = TERMINAL_CLASS, title = "^(btop)$" }, { float = true, size = { 1200, 780 } })

rule("float-thunar-rename", { class = "^([Tt]hunar)$", title = "^(Rename.*)$" }, { float = true })

local FLOAT_CLASSES = {
    "org.gnome.FileRoller", "qt5ct", "qt6ct", "nwg-look", "nwg-displays",
    "org.pulseaudio.pavucontrol", "blueman-manager", "nm-connection-editor",
    "org.Waytrogen.Waytrogen", "waytrogen", "com.github.unrud.VideoDownloader",
    "com.interversehq.qView",
}
for _, class in ipairs(FLOAT_CLASSES) do
    rule("float-" .. class, { class = "^(" .. class .. ")$" }, { float = true })
end

rule("messenger", { class = "^(WebApp-Messenger4386)$" }, { float = true, size = { 1400, 820 }, center = true })
rule("discord", { class = "^(discord)$" }, { float = true, size = { 1000, 820 }, center = true })

-- DIALOGS
local DIALOG_TITLES = {
    "^(Open File)(.*)$", "^(Select a File)(.*)$", "^(Choose wallpaper)(.*)$",
    "^(Open Folder)(.*)$", "^(Save As)(.*)$", "^(Library)(.*)$", "^(File Upload)(.*)$",
    "^(File Operation Progress)$", "^(Confirm to replace files)$",
}
for index, title in ipairs(DIALOG_TITLES) do
    rule("float-dialog-" .. index, { title = title }, { float = true })
end
-- The old rule matched $browser ("zen-browser"), which is never a window class.
rule("float-browser-accounts", { class = "^(zen|zen-browser)$", title = ".*accounts.*" }, { float = true })

-- File dialogs with specific sizes
for index, title in ipairs({ "^(Save As)$", "^(Choose Files)$", "^(Open File)$", "^(Open Folder)$" }) do
    rule("size-browser-dialog-" .. index, { class = "^(firefox|google-chrome|zen)$", title = title }, {
        size = { 800, 600 },
    })
end

-- qView image viewer
rule("qview", { class = "^(com.interversehq.qView)$" }, {
    -- fullscreen_state = "1 3" was commented out in the old config and maximizes the window, so it stays off.
    size = { 800, 450 }, content = "photo", no_blur = true, opaque = true,
})

-- PICTURE-IN-PICTURE
rule("pip", { class = BROWSERS, title = PIP_TITLE }, {
    float = true,
    pin = true,
    size = { 480, 270 },
    no_blur = true,
    move = { "monitor_w * 0.745", "monitor_h * 0.0425" },
    animation = "slide",
    opaque = true,
})

-- OPACITY
local OPACITY_CLASSES = { "hyprswitch", "Dunst", "thunar", "code", "cursor", "kiro-url-handler" }
for _, class in ipairs(OPACITY_CLASSES) do
    rule("opacity-" .. class, { class = "^(" .. class .. ")$" }, { opacity = OPACITY_FLOAT })
end
rule("opacity-nvim", { title = "^(nvim.*)$" }, { opacity = OPACITY_FLOAT })
rule("opacity-zsh", { title = "^(zsh*)$" }, { opacity = OPACITY_FLOAT })
rule("opacity-monkeytype", {
    class = "(zen)",
    title = "^(Monkeytype \\| A minimalistic, customizable typing test — Zen Browser)$",
}, { opacity = "0.75 0.75" })
