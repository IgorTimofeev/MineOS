
local args = {...}
local computer = require("computer")
local MineOSCore = require("MineOSCore")
local MineOSInterface = require("MineOSInterface")

local icon, menu = args[1], args[2]
menu:addItem(MineOSCore.localization.setAsWallpaper).onTouch = function()
	MineOSCore.properties.wallpaperEnabled = true
	MineOSCore.properties.wallpaper = icon.path
	MineOSCore.saveProperties()
	computer.pushSignal("MineOSCore", "updateWallpaper")
end
