
local args = {...}
local computer = require("computer")
local MineOSCore = require("MineOSCore")

local icon, menu = args[1], args[2]
menu:addItem(MineOSCore.localization.setAsWallpaper).onTouch = function()
	MineOSCore.OSSettings.wallpaperEnabled = true
	MineOSCore.OSSettings.wallpaper = icon.path
	MineOSCore.saveOSSettings()
	computer.pushSignal("MineOSCore", "updateWallpaper")
end
