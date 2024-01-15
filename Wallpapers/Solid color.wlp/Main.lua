-- The simplest solid color wallpaper

local system = require("System")
local fs = require("Filesystem")
local screen = require("Screen")
local GUI = require("GUI")

local wallpaper = {}

--------------------------------------------------------------------------------

local configPath = fs.path(system.getCurrentScript()) .. "/" .. "Config.cfg"

local function saveConfig()
    fs.writeTable(configPath, wallpaper.config)
end

if fs.exists(configPath) then
    wallpaper.config = fs.readTable(configPath)
else
    wallpaper.config = {
        color = 0x161616
    }
end

--------------------------------------------------------------------------------

wallpaper.draw = function(object)
    screen.drawRectangle(object.x, object.y, object.width, object.height, wallpaper.config.color, 0, ' ')
end

wallpaper.configure = function(layout)
    layout:addChild(GUI.colorSelector(1, 1, 36, 3, wallpaper.config.color, "Color")).onColorSelected = function(_, object)
        wallpaper.config.color = object.color
        saveConfig()
    end
end

--------------------------------------------------------------------------------

return wallpaper