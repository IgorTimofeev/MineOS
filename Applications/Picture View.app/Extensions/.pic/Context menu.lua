
local filesystem = require("Filesystem")
local GUI = require("GUI")
local paths = require("Paths")
local system = require("System")

local workspace, icon, menu = select(1, ...), select(2, ...), select(3, ...)
local localization = system.getSystemLocalization()

menu:addItem("💻", localization.setAsWallpaper).onTouch = function()
	local userSettings = system.getUserSettings()

	local staticPictureWallpaperPath = paths.system.wallpapers .. "Static picture.wlp"
	if userSettings.interfaceWallpaperPath ~= staticPictureWallpaperPath then
		userSettings.interfaceWallpaperPath = staticPictureWallpaperPath
		system.updateWallpaper()
	end
	
	system.wallpaper.setPicture(icon.path)

	workspace:draw()
	system.saveUserSettings()
end

system.addUploadToPastebinMenuItem(menu, icon.path)