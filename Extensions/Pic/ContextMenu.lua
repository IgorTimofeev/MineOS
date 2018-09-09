local computer = require("computer")
local MineOSCore = require("MineOSCore")

local icon, menu = select(1, ...), select(2, ...)
menu:addItem(MineOSCore.localization.setAsWallpaper).onTouch = function()
	MineOSCore.properties.wallpaperEnabled = true
	MineOSCore.properties.wallpaper = icon.path
	MineOSCore.saveProperties()
	computer.pushSignal("MineOSCore", "updateWallpaper")
end
