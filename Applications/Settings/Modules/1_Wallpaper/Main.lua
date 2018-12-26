
local GUI = require("GUI")
local MineOSInterface = require("MineOSInterface")
local MineOSPaths = require("MineOSPaths")
local MineOSCore = require("MineOSCore")

local module = {}

local application, window, localization = table.unpack({...})

--------------------------------------------------------------------------------

module.name = localization.wallpaper
module.margin = 5
module.onTouch = function()
	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.wallpaperWallpaper))

	local wallpaperChooser = window.contentLayout:addChild(GUI.filesystemChooser(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0xD2D2D2, 0xA5A5A5, MineOSCore.properties.wallpaper, localization.open, localization.cancel, localization.wallpaperPath, "/"))
	wallpaperChooser:setMode(GUI.IO_MODE_OPEN, GUI.IO_MODE_FILE)
	wallpaperChooser:addExtensionFilter(".pic")
	wallpaperChooser.onSubmit = function(path)
		MineOSCore.properties.wallpaper = path
		MineOSInterface.changeWallpaper()
		MineOSInterface.application:draw()

		MineOSCore.saveProperties()
	end

	local comboBox = window.contentLayout:addChild(GUI.comboBox(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0xD2D2D2, 0xA5A5A5))
	comboBox.selectedItem = MineOSCore.properties.wallpaperMode or 1
	comboBox:addItem(localization.wallpaperStretch)
	comboBox:addItem(localization.wallpaperCenter)

	local wallpaperSwitch = window.contentLayout:addChild(GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xA5A5A5, localization.wallpaperEnabled .. ":", MineOSCore.properties.wallpaperEnabled)).switch
	wallpaperSwitch.onStateChanged = function()
		MineOSCore.properties.wallpaperEnabled = wallpaperSwitch.state
		MineOSInterface.changeWallpaper()
		MineOSInterface.application:draw()

		MineOSCore.saveProperties()
	end

	window.contentLayout:addChild(GUI.textBox(1, 1, 36, 1, nil, 0xA5A5A5, {localization.wallpaperInfo}, 1, 0, 0, true, true))

	local wallpaperSlider = window.contentLayout:addChild(GUI.slider(1, 1, 36, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xA5A5A5, 0, 100, MineOSCore.properties.wallpaperBrightness * 100, false, localization.wallpaperBrightness .. ": ", "%"))
	wallpaperSlider.height = 2
	wallpaperSlider.roundValues = true
	wallpaperSlider.onValueChanged = function()
		MineOSCore.properties.wallpaperBrightness = wallpaperSlider.value / 100
		MineOSInterface.changeWallpaper()
		MineOSInterface.application:draw()

		MineOSCore.saveProperties()
	end
	
	comboBox.onItemSelected = function()
		MineOSCore.properties.wallpaperMode = comboBox.selectedItem
		MineOSInterface.changeWallpaper()
		MineOSInterface.application:draw()

		MineOSCore.saveProperties()
	end

	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.wallpaperScreensaver))

	local screensaverChooser = window.contentLayout:addChild(GUI.filesystemChooser(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0xD2D2D2, 0xA5A5A5, MineOSCore.properties.screensaver, localization.open, localization.cancel, localization.wallpaperScreensaverPath, "/"))
	screensaverChooser:setMode(GUI.IO_MODE_OPEN, GUI.IO_MODE_FILE)
	screensaverChooser:addExtensionFilter(".lua")

	local screensaverSwitch = window.contentLayout:addChild(GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xA5A5A5, localization.wallpaperScreensaverEnabled .. ":", MineOSCore.properties.screensaverEnabled)).switch

	local screensaverSlider = window.contentLayout:addChild(GUI.slider(1, 1, 36, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xA5A5A5, 1, 100, MineOSCore.properties.screensaverDelay, false, localization.wallpaperScreensaverDelay .. ": ", " s"))
	
	local function save()
		MineOSCore.properties.screensaverEnabled = screensaverSwitch.state
		MineOSCore.properties.screensaver = screensaverChooser.path
		MineOSCore.properties.screensaverDelay = screensaverSlider.value

		MineOSCore.saveProperties()
	end

	screensaverChooser.onSubmit, screensaverSwitch.onStateChanged, screensaverSlider.onValueChanged = save, save, save
end

--------------------------------------------------------------------------------

return module

