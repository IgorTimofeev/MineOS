local GUI = require("GUI")
local system = require("System")
local filesystem = require("Filesystem")
local paths = require("Paths")

--------------------------------------------------------------------------------

local workspace, window, localization = table.unpack({...})
local userSettings = system.getUserSettings()
local configureFrom, configureTo

local function configure()
	-- Remove previously added controls from layout
	if configureFrom then
		window.contentLayout:removeChildren(configureFrom, configureTo)
		configureFrom, configureTo = nil, nil
	end

	-- Add new controls if needed
	local wallpaper = system.getWallpaper()
	if wallpaper.configure then
		configureFrom = #window.contentLayout.children + 1
		wallpaper.configure(window.contentLayout)
		configureTo = #window.contentLayout.children
	end
end

--------------------------------------------------------------------------------

return {
	name = localization.wallpaper,
	margin = 0,
	onTouch = function()
		window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.wallpaperWallpaper))

		local comboBox = window.contentLayout:addChild(GUI.comboBox(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0xD2D2D2, 0xA5A5A5))
		local files = filesystem.list(paths.system.wallpapers)

		for i = 1, #files do
			local file = files[i]
			local path = paths.system.wallpapers .. file
			
			if filesystem.isDirectory(path) and filesystem.extension(path) == ".wlp" then
				comboBox:addItem(filesystem.hideExtension(file))

				if userSettings.interfaceWallpaperPath == path then
					comboBox.selectedItem = i
				end
			end
		end

		comboBox.onItemSelected = function(index)
			userSettings.interfaceWallpaperPath = paths.system.wallpapers .. files[index]
			system.updateWallpaper()
			configure(window.contentLayout)

			workspace:draw()
			system.saveUserSettings()
		end

		configure()
	end
}