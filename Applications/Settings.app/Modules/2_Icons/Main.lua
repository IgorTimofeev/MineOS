
local GUI = require("GUI")
local paths = require("Paths")
local system = require("System")

local module = {}

local workspace, window, localization = table.unpack({...})

--------------------------------------------------------------------------------

module.name = localization.appearance
module.margin = 12
module.onTouch = function()
	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.appearanceFiles))

	local showExtensionSwitch = window.contentLayout:addChild(GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xA5A5A5, localization.appearanceExtensions .. ":", system.properties.filesShowExtension)).switch
	local showHiddenFilesSwitch = window.contentLayout:addChild(GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xA5A5A5, localization.appearanceHidden .. ":", system.properties.filesShowHidden)).switch
	local showApplicationIconsSwitch = window.contentLayout:addChild(GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xA5A5A5, localization.appearanceApplications .. ":", system.properties.filesShowApplicationIcon)).switch
	local transparencySwitch = window.contentLayout:addChild(GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xA5A5A5, localization.appearanceTransparencyEnabled .. ":", system.properties.interfaceTransparencyEnabled)).switch
	
	window.contentLayout:addChild(GUI.textBox(1, 1, 36, 1, nil, 0xA5A5A5, {localization.appearanceTransparencyInfo}, 1, 0, 0, true, true))

	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.appearanceColorScheme))

	local backgroundColorSelector = window.contentLayout:addChild(GUI.colorSelector(1, 1, 36, 3, system.properties.interfaceColorDesktopBackground, localization.appearanceDesktopBackground))
	local menuColorSelector = window.contentLayout:addChild(GUI.colorSelector(1, 1, 36, 3, system.properties.interfaceColorMenu, localization.appearanceMenu))
	local dockColorSelector = window.contentLayout:addChild(GUI.colorSelector(1, 1, 36, 3, system.properties.interfaceColorDock, localization.appearanceDock))

	backgroundColorSelector.onColorSelected = function()
		system.properties.interfaceColorDesktopBackground = backgroundColorSelector.color
		system.properties.interfaceColorMenu = menuColorSelector.color
		system.properties.interfaceColorDock = dockColorSelector.color
		system.properties.interfaceTransparencyEnabled = transparencySwitch.state

		system.updateColorScheme()
		workspace:draw()
		system.saveProperties()
	end
	menuColorSelector.onColorSelected = backgroundColorSelector.onColorSelected
	dockColorSelector.onColorSelected = backgroundColorSelector.onColorSelected
	transparencySwitch.onStateChanged = backgroundColorSelector.onColorSelected

	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.appearanceSize))

	local iconWidthSlider = window.contentLayout:addChild(GUI.slider(1, 1, 36, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xA5A5A5, 8, 16, system.properties.iconWidth, false, localization.appearanceHorizontal .. ": ", ""))
	local iconHeightSlider = window.contentLayout:addChild(GUI.slider(1, 1, 36, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xA5A5A5, 6, 16, system.properties.iconHeight, false, localization.appearanceVertical .. ": ", ""))
	iconHeightSlider.height = 2

	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.appearanceSpace))

	local iconHorizontalSpaceBetweenSlider = window.contentLayout:addChild(GUI.slider(1, 1, 36, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xA5A5A5, 0, 5, system.properties.iconHorizontalSpace, false, localization.appearanceHorizontal .. ": ", ""))
	local iconVerticalSpaceBetweenSlider = window.contentLayout:addChild(GUI.slider(1, 1, 36, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xA5A5A5, 0, 5, system.properties.iconVerticalSpace, false, localization.appearanceVertical .. ": ", ""))
	iconVerticalSpaceBetweenSlider.height = 2

	iconHorizontalSpaceBetweenSlider.roundValues, iconVerticalSpaceBetweenSlider.roundValues = true, true
	iconWidthSlider.roundValues, iconHeightSlider.roundValues = true, true

	local function setIconProperties(width, height, horizontalSpace, verticalSpace)
		system.properties.iconWidth, system.properties.iconHeight, system.properties.iconHorizontalSpace, system.properties.iconVerticalSpace = width, height, horizontalSpace, verticalSpace
		system.saveProperties()
		
		system.calculateIconProperties()
		system.updateIconProperties()
	end

	iconWidthSlider.onValueChanged = function()
		setIconProperties(math.floor(iconWidthSlider.value), math.floor(iconHeightSlider.value), system.properties.iconHorizontalSpace, system.properties.iconVerticalSpace)
	end
	iconHeightSlider.onValueChanged = iconWidthSlider.onValueChanged

	iconHorizontalSpaceBetweenSlider.onValueChanged = function()
		setIconProperties(system.properties.iconWidth, system.properties.iconHeight, math.floor(iconHorizontalSpaceBetweenSlider.value), math.floor(iconVerticalSpaceBetweenSlider.value))
	end
	iconVerticalSpaceBetweenSlider.onValueChanged = iconHorizontalSpaceBetweenSlider.onValueChanged

	showExtensionSwitch.onStateChanged = function()
		system.properties.filesShowExtension = showExtensionSwitch.state
		system.properties.filesShowHidden = showHiddenFilesSwitch.state
		system.properties.filesShowApplicationIcon = showApplicationIconsSwitch.state
		system.saveProperties()

		computer.pushSignal("system", "updateFileList")
	end
	showHiddenFilesSwitch.onStateChanged, showApplicationIconsSwitch.onStateChanged = showExtensionSwitch.onStateChanged, showExtensionSwitch.onStateChanged

end

--------------------------------------------------------------------------------

return module

