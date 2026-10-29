-- LAYOUT CONFIGURATION
local v = require("config.variables")

hl.config({
    dwindle = {
        preserve_split = true,
        smart_split = false,
        smart_resizing = false,
    },

    master = {
        new_status = "master",
        mfact = v.masterRatio,
    },
})
