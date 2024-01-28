local system = require("System")
local filesystem = require("Filesystem")
local screen = require("Screen")
local GUI = require("GUI")

--------------------------------------------------------------------------------

local configPath = filesystem.path(system.getCurrentScript()) .. "Config.cfg"

local config = {
    color = 0x161616
}

if filesystem.exists(configPath) then
    for key, value in pairs(filesystem.readTable(configPath)) do
        config[key] = value
    end
end

local function saveConfig()
    filesystem.writeTable(configPath, config)
end

--------------------------------------------------------------------------------

return {
    draw = function(object)
        screen.drawRectangle(object.x, object.y, object.width, object.height, config.color, 0, ' ')
    end,

    configure = function(layout)
        layout:addChild(GUI.colorSelector(1, 1, 36, 3, config.color, "Color")).onColorSelected = function(_, object)
            config.color = object.color
            saveConfig()
        end
    end
}