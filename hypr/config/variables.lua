-- GLOBAL VARIABLES & CONSTANTS
-- Shared by every other module via require("config.variables").

local home = os.getenv("HOME")

return {
    -- APPLICATION VARIABLES
    mainMod          = "SUPER",
    terminal         = "ghostty",
    terminalClass    = "com.mitchellh.ghostty",
    fileManager      = "thunar",
    browser          = "zen-browser",
    launcher         = "wofi --show drun --matching --insensitive",
    volumeBrightness = "~/.config/scripts/media/volume-brightness.sh",

    -- DIRECTORY PATHS
    configDir     = "~/.config/hypr",
    scriptsDir    = "~/.config/scripts",
    wallpaperDir  = home .. "/Pictures/Wallpapers",
    screenshotDir = home .. "/Pictures/Screenshots",

    -- THEME VARIABLES
    cursorTheme = "Bibata-Modern-Ice",
    cursorSize  = 24,
    fontFamily  = "SF Pro",
    fontMono    = "Liga SFMono Nerd Font",

    -- LAYOUT CONSTANTS
    gapsIn      = 5,
    gapsOut     = 10,
    borderSize  = 3,
    rounding    = 10,
    masterRatio = 0.6,

    -- ANIMATION TIMING
    animSpeed     = 3,
    animSpeedFast = 2,
    animSpeedSlow = 5,

    -- OPACITY VALUES
    opacityActive   = 1.0,
    opacityInactive = 0.8,
    opacityFloat    = 0.90,
    opacitySpecial  = 0.6,
}
