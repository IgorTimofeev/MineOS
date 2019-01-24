
local system = require("System")

local workspace, icon, menu = select(1, ...), select(2, ...), select(3, ...)
local localization = system.getSystemLocalization()
local userSettings = system.getUserSettings()

menu:addItem(localization.setAsWallpaper).onTouch = function()
	userSettings.interfaceWallpaperEnabled = true
	userSettings.interfaceWallpaperPath = icon.path

	system.updateWallpaper()
	workspace:draw()

	system.saveUserSettings()
end

menu:addItem(localization.uploadToPastebin, not component.isAvailable("internet")).onTouch = function()
	system.uploadToPastebin(icon.path)
end
