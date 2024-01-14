local GUI = require("GUI")
local system = require("System")
local fs = require("Filesystem")
local paths = require("Paths")

local module = {}

local workspace, window, localization = table.unpack({...})
local userSettings = system.getUserSettings()

--------------------------------------------------------------------------------

local wallpaperConfigurationControlsBegin, wallpaperConfigurationControlsEnd = nil, nil

local function updateWallpaperConfigurationControls(layout)
	-- Remove previously added controls from layout
	if wallpaperConfigurationControlsBegin ~= nil then
		layout:removeChildren(wallpaperConfigurationControlsBegin, wallpaperConfigurationControlsEnd)
		wallpaperConfigurationControlsBegin, wallpaperConfigurationControlsEnd = nil, nil
	end

	-- Add new controls if needed
	if system.wallpaper and system.wallpaper.configure then
		wallpaperConfigurationControlsBegin = #layout.children + 1
		system.wallpaper.configure(layout)
		wallpaperCOnfigurationControlsEnd = #layout.children
	end
end

--------------------------------------------------------------------------------

module.name = localization.wallpaper
module.margin = 0

module.onTouch = function()
	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.wallpaperWallpaper))

	local comboBox = window.contentLayout:addChild(GUI.comboBox(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0xD2D2D2, 0xA5A5A5))
	for _, filename in pairs(fs.list(paths.system.wallpapers)) do
		local path = paths.system.wallpapers .. filename
		
		if fs.isDirectory(path) and fs.extension(path) == ".wlp" then
			local item = comboBox:addItem(fs.hideExtension(filename))

			item.onTouch = function() 
				userSettings.interfaceWallpaperPath = path
				system.updateWallpaper()
				workspace:draw()
				
				system.saveUserSettings()
				updateWallpaperConfigurationControls(window.contentLayout)
			end

			if userSettings.interfaceWallpaperPath == path then
				comboBox.selectedItem = comboBox:count()
			end
		end
	end

	updateWallpaperConfigurationControls(window.contentLayout)
end

--------------------------------------------------------------------------------

return module