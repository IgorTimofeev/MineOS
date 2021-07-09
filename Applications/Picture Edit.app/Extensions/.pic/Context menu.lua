
local filesystem = require("Filesystem")
local GUI = require("GUI")
local paths = require("Paths")
local system = require("System")

local workspace, icon, menu = select(1, ...), select(2, ...), select(3, ...)
local localization = system.getSystemLocalization()

menu:addItem(localization.setAsWallpaper).onTouch = function()
	local userSettings = system.getUserSettings()

	userSettings.interfaceWallpaperPath = icon.path
	userSettings.interfaceWallpaperEnabled = true
	system.updateWallpaper()
	workspace:draw()

	system.saveUserSettings()
end

system.addUploadToPastebinMenuItem(menu, icon.path)
