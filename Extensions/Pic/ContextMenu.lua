
local system = require("System")

local workspace, icon, menu = select(1, ...), select(2, ...), select(3, ...)

menu:addItem(system.localization.setAsWallpaper).onTouch = function()
	system.properties.interfaceWallpaperEnabled = true
	system.properties.interfaceWallpaperPath = icon.path

	system.updateWallpaper()
	workspace:draw()

	system.saveProperties()
end
