
local GUI = require("GUI")
local computer = require("computer")
local MineOSInterface = require("MineOSInterface")
local MineOSPaths = require("MineOSPaths")
local MineOSCore = require("MineOSCore")

local module = {}

local application, window, localization = table.unpack({...})

--------------------------------------------------------------------------------

module.name = localization.appearance
module.margin = 12
module.onTouch = function()
	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.appearanceFiles))

	local showExtensionSwitch = window.contentLayout:addChild(GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xA5A5A5, localization.appearanceExtensions .. ":", MineOSCore.properties.showExtension)).switch
	local showHiddenFilesSwitch = window.contentLayout:addChild(GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xA5A5A5, localization.appearanceHidden .. ":", MineOSCore.properties.showHiddenFiles)).switch
	local showApplicationIconsSwitch = window.contentLayout:addChild(GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xA5A5A5, localization.appearanceApplications .. ":", MineOSCore.properties.showApplicationIcons)).switch
	local transparencySwitch = window.contentLayout:addChild(GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xA5A5A5, localization.appearanceTransparencyEnabled .. ":", MineOSCore.properties.transparencyEnabled)).switch
	
	window.contentLayout:addChild(GUI.textBox(1, 1, 36, 1, nil, 0xA5A5A5, {localization.appearanceTransparencyInfo}, 1, 0, 0, true, true))

	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.appearanceColorScheme))

	local backgroundColorSelector = window.contentLayout:addChild(GUI.colorSelector(1, 1, 36, 3, MineOSCore.properties.backgroundColor, localization.appearanceDesktopBackground))
	local menuColorSelector = window.contentLayout:addChild(GUI.colorSelector(1, 1, 36, 3, MineOSCore.properties.menuColor, localization.appearanceMenu))
	local dockColorSelector = window.contentLayout:addChild(GUI.colorSelector(1, 1, 36, 3, MineOSCore.properties.dockColor, localization.appearanceDock))

	backgroundColorSelector.onColorSelected = function()
		MineOSCore.properties.backgroundColor = backgroundColorSelector.color
		MineOSCore.properties.menuColor = menuColorSelector.color
		MineOSCore.properties.dockColor = dockColorSelector.color
		MineOSInterface.application.menu.colors.default.background = MineOSCore.properties.menuColor

		MineOSInterface.application:draw()
	end
	menuColorSelector.onColorSelected = backgroundColorSelector.onColorSelected
	dockColorSelector.onColorSelected = backgroundColorSelector.onColorSelected

	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.appearanceSize))

	local iconWidthSlider = window.contentLayout:addChild(GUI.slider(1, 1, 36, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xA5A5A5, 8, 16, MineOSCore.properties.iconWidth, false, localization.appearanceHorizontal .. ": ", ""))
	local iconHeightSlider = window.contentLayout:addChild(GUI.slider(1, 1, 36, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xA5A5A5, 6, 16, MineOSCore.properties.iconHeight, false, localization.appearanceVertical .. ": ", ""))
	iconHeightSlider.height = 2

	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.appearanceSpace))

	local iconHorizontalSpaceBetweenSlider = window.contentLayout:addChild(GUI.slider(1, 1, 36, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xA5A5A5, 0, 5, MineOSCore.properties.iconHorizontalSpaceBetween, false, localization.appearanceHorizontal .. ": ", ""))
	local iconVerticalSpaceBetweenSlider = window.contentLayout:addChild(GUI.slider(1, 1, 36, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xA5A5A5, 0, 5, MineOSCore.properties.iconVerticalSpaceBetween, false, localization.appearanceVertical .. ": ", ""))
	iconVerticalSpaceBetweenSlider.height = 2

	iconHorizontalSpaceBetweenSlider.roundValues, iconVerticalSpaceBetweenSlider.roundValues = true, true
	iconWidthSlider.roundValues, iconHeightSlider.roundValues = true, true

	iconWidthSlider.onValueChanged = function()
		MineOSInterface.setIconProperties(math.floor(iconWidthSlider.value), math.floor(iconHeightSlider.value), MineOSCore.properties.iconHorizontalSpaceBetween, MineOSCore.properties.iconVerticalSpaceBetween)
	end
	iconHeightSlider.onValueChanged = iconWidthSlider.onValueChanged

	iconHorizontalSpaceBetweenSlider.onValueChanged = function()
		MineOSInterface.setIconProperties(MineOSCore.properties.iconWidth, MineOSCore.properties.iconHeight, math.floor(iconHorizontalSpaceBetweenSlider.value), math.floor(iconVerticalSpaceBetweenSlider.value))
	end
	iconVerticalSpaceBetweenSlider.onValueChanged = iconHorizontalSpaceBetweenSlider.onValueChanged

	showExtensionSwitch.onStateChanged = function()
		MineOSCore.properties.showExtension = showExtensionSwitch.state
		MineOSCore.properties.showHiddenFiles = showHiddenFilesSwitch.state
		MineOSCore.properties.showApplicationIcons = showApplicationIconsSwitch.state
		MineOSCore.saveProperties()

		computer.pushSignal("MineOSCore", "updateFileList")
	end
	showHiddenFilesSwitch.onStateChanged, showApplicationIconsSwitch.onStateChanged = showExtensionSwitch.onStateChanged, showExtensionSwitch.onStateChanged
	
	transparencySwitch.onStateChanged = function()
		MineOSCore.properties.transparencyEnabled = transparencySwitch.state

		MineOSInterface.applyTransparency()
		MineOSInterface.application:draw()
		MineOSCore.saveProperties()
	end

end

--------------------------------------------------------------------------------

return module

