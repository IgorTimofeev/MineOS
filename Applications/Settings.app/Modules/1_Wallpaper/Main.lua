
local GUI = require("GUI")
local system = require("System")

local module = {}

local workspace, window, localization = table.unpack({...})

--------------------------------------------------------------------------------

module.name = localization.wallpaper
module.margin = 5
module.onTouch = function()
	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.wallpaperWallpaper))

	local wallpaperChooser = window.contentLayout:addChild(GUI.filesystemChooser(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0xD2D2D2, 0xA5A5A5, system.properties.interfaceWallpaperPath, localization.open, localization.cancel, localization.wallpaperPath, "/"))
	wallpaperChooser:setMode(GUI.IO_MODE_OPEN, GUI.IO_MODE_FILE)
	wallpaperChooser:addExtensionFilter(".pic")
	wallpaperChooser.onSubmit = function(path)
		system.properties.interfaceWallpaperPath = path
		system.updateWallpaper()
		workspace:draw()

		system.saveProperties()
	end

	local comboBox = window.contentLayout:addChild(GUI.comboBox(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0xD2D2D2, 0xA5A5A5))
	comboBox.selectedItem = system.properties.interfaceWallpaperMode or 1
	comboBox:addItem(localization.wallpaperStretch)
	comboBox:addItem(localization.wallpaperCenter)

	local wallpaperSwitch = window.contentLayout:addChild(GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xA5A5A5, localization.wallpaperEnabled .. ":", system.properties.interfaceWallpaperEnabled)).switch
	wallpaperSwitch.onStateChanged = function()
		system.properties.interfaceWallpaperEnabled = wallpaperSwitch.state
		system.updateWallpaper()
		workspace:draw()

		system.saveProperties()
	end

	window.contentLayout:addChild(GUI.textBox(1, 1, 36, 1, nil, 0xA5A5A5, {localization.wallpaperInfo}, 1, 0, 0, true, true))

	local wallpaperSlider = window.contentLayout:addChild(GUI.slider(1, 1, 36, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xA5A5A5, 0, 100, system.properties.interfaceWallpaperBrightness * 100, false, localization.wallpaperBrightness .. ": ", "%"))
	wallpaperSlider.height = 2
	wallpaperSlider.roundValues = true
	wallpaperSlider.onValueChanged = function()
		system.properties.interfaceWallpaperBrightness = wallpaperSlider.value / 100
		system.updateWallpaper()
		workspace:draw()

		system.saveProperties()
	end
	
	comboBox.onItemSelected = function()
		system.properties.interfaceWallpaperMode = comboBox.selectedItem
		system.updateWallpaper()
		workspace:draw()

		system.saveProperties()
	end

	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.wallpaperScreensaver))

	local screensaverChooser = window.contentLayout:addChild(GUI.filesystemChooser(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0xD2D2D2, 0xA5A5A5, system.properties.interfaceScreensaverPath, localization.open, localization.cancel, localization.wallpaperScreensaverPath, "/"))
	screensaverChooser:setMode(GUI.IO_MODE_OPEN, GUI.IO_MODE_FILE)
	screensaverChooser:addExtensionFilter(".lua")

	local screensaverSwitch = window.contentLayout:addChild(GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xA5A5A5, localization.wallpaperScreensaverEnabled .. ":", system.properties.interfaceScreensaverEnabled)).switch

	local screensaverSlider = window.contentLayout:addChild(GUI.slider(1, 1, 36, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xA5A5A5, 1, 100, system.properties.interfaceScreensaverDelay, false, localization.wallpaperScreensaverDelay .. ": ", " s"))
	
	local function save()
		system.properties.interfaceScreensaverEnabled = screensaverSwitch.state
		system.properties.interfaceScreensaverPath = screensaverChooser.path
		system.properties.interfaceScreensaverDelay = screensaverSlider.value

		system.saveProperties()
	end

	screensaverChooser.onSubmit, screensaverSwitch.onStateChanged, screensaverSlider.onValueChanged = save, save, save
end

--------------------------------------------------------------------------------

return module

