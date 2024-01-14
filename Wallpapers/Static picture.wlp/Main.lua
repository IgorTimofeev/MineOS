local system = require("System")
local fs = require("Filesystem")
local screen = require("Screen")
local GUI = require("GUI")
local image = require("Image")

local wallpaper = {}

--------------------------------------------------------------------------------

local configPath = fs.path(system.getCurrentScript()) .. "/" .. "Config.cfg"

local function loadPicture()
    wallpaper.image, wallpaper.reason = image.load(wallpaper.config.path)
end

local function saveConfig()
    fs.writeTable(configPath, wallpaper.config)
end

if fs.exists(configPath) then
    wallpaper.config = fs.readTable(configPath)
else
    wallpaper.config = {
        path = fs.path(system.getCurrentScript()) .. "Pictures/Girl.pic"
    }

    saveConfig()
end

loadPicture()

--------------------------------------------------------------------------------

wallpaper.draw = function(object)
    if wallpaper.image then
        screen.drawImage(object.x, object.y, wallpaper.image)
    else
        screen.drawRectangle(object.x, object.y, object.width, object.height, 0x161616, 0x000000, " ")

        local text = wallpaper.reason
        screen.drawText(math.floor(object.x + object.width / 2 - #text / 2), math.floor(object.y + object.height / 2), 0x646464, text)
    end
end

wallpaper.configure = function(layout)
    local wallpaperChooser = layout:addChild(GUI.filesystemChooser(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0xD2D2D2, 0xA5A5A5, wallpaper.config.path, "Open", "Cancel", "Wallpaper path", "/"))
	wallpaperChooser:setMode(GUI.IO_MODE_OPEN, GUI.IO_MODE_FILE)
	wallpaperChooser:addExtensionFilter(".pic")
	wallpaperChooser.onSubmit = function(path)
        wallpaper.config.path = path
        loadPicture()
		saveConfig()
	end 
end

wallpaper.setPicture = function(path)
    wallpaper.config.path = path
    saveConfig()
    loadPicture()
end

--------------------------------------------------------------------------------

return wallpaper