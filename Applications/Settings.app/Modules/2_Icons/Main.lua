
local GUI = require("GUI")
local paths = require("Paths")
local system = require("System")
local filesystem = require("Filesystem")

local module = {}

local workspace, window, localization, theme = table.unpack({...})
local userSettings = system.getUserSettings()

--------------------------------------------------------------------------------

module.name = localization.appearance
module.margin = 6

module.onTouch = function()
	-- Theme
	window.contentLayout:addChild(system.applyThemeToTitleText(GUI.text(1, 1, 0x0, localization.appearanceTheme)))

	local themeComboBox = window.contentLayout:addChild(system.applyThemeToComboBox(GUI.comboBox(1, 1, 36, 3, 0x0, 0x0, 0x0, 0x0)))

	local list = filesystem.list(paths.system.themes)
	for i = 1, #list do
		if filesystem.extension(list[i]) == ".thm" then
			local name = filesystem.hideExtension(list[i])
			
			themeComboBox:addItem(name).onTouch = function()
				userSettings.theme = name
				theme = system.getTheme(paths.system.themes)

				system.updateSystemTheme()
				system.updateWorkspace()
				system.updateDesktop()
				workspace:draw()

				system.saveUserSettings()
			end

			if name == userSettings.theme then
				themeComboBox.selectedItem = themeComboBox:count()
			end
		end
	end

	local transparencySwitch = window.contentLayout:addChild(system.applyThemeToSwitchAndLabel(GUI.switchAndLabel(1, 1, 36, 6, 0x0, 0x0, 0x0, 0x0, localization.appearanceTransparencyEnabled .. ":", userSettings.interfaceTransparencyEnabled))).switch
	local blurSwitch = window.contentLayout:addChild(system.applyThemeToSwitchAndLabel(GUI.switchAndLabel(1, 1, 36, 6, 0x0, 0x0, 0x0, 0x0, localization.appearanceBlurEnabled .. ":", userSettings.interfaceBlurEnabled))).switch

	-- Files
	window.contentLayout:addChild(system.applyThemeToTitleText(GUI.text(1, 1, 0x0, localization.appearanceFiles)))
	local showExtensionSwitch = window.contentLayout:addChild(system.applyThemeToSwitchAndLabel(GUI.switchAndLabel(1, 1, 36, 6, 0x0, 0x0, 0x0, 0x0, localization.appearanceExtensions .. ":", userSettings.filesShowExtension))).switch
	local showHiddenFilesSwitch = window.contentLayout:addChild(system.applyThemeToSwitchAndLabel(GUI.switchAndLabel(1, 1, 36, 6, 0x0, 0x0, 0x0, 0x0, localization.appearanceHidden .. ":", userSettings.filesShowHidden))).switch
	local showApplicationIconsSwitch = window.contentLayout:addChild(system.applyThemeToSwitchAndLabel(GUI.switchAndLabel(1, 1, 36, 6, 0x0, 0x0, 0x0, 0x0, localization.appearanceApplications .. ":", userSettings.filesShowApplicationIcon))).switch

	-- Icon sizes
	window.contentLayout:addChild(system.applyThemeToTitleText(GUI.text(1, 1, 0x0, localization.appearanceSize)))

	local iconWidthSlider = window.contentLayout:addChild(system.applyThemeToSlider(GUI.slider(1, 1, 36, 0x0, 0x0, 0x0, 0x0, 8, 16, userSettings.iconWidth, false, localization.appearanceHorizontal .. ": ", "")))
	local iconHeightSlider = window.contentLayout:addChild(system.applyThemeToSlider(GUI.slider(1, 1, 36, 0x0, 0x0, 0x0, 0x0, 6, 16, userSettings.iconHeight, false, localization.appearanceVertical .. ": ", "")))
	iconHeightSlider.height = 2

	window.contentLayout:addChild(system.applyThemeToTitleText(GUI.text(1, 1, 0x0, localization.appearanceSpace)))

	local iconHorizontalSpaceBetweenSlider = window.contentLayout:addChild(system.applyThemeToSlider(GUI.slider(1, 1, 36, 0x0, 0x0, 0x0, 0x0, 0, 5, userSettings.iconHorizontalSpace, false, localization.appearanceHorizontal .. ": ", "")))
	local iconVerticalSpaceBetweenSlider = window.contentLayout:addChild(system.applyThemeToSlider(GUI.slider(1, 1, 36, 0x0, 0x0, 0x0, 0x0, 0, 5, userSettings.iconVerticalSpace, false, localization.appearanceVertical .. ": ", "")))
	iconVerticalSpaceBetweenSlider.height = 2

	iconHorizontalSpaceBetweenSlider.roundValues, iconVerticalSpaceBetweenSlider.roundValues = true, true
	iconWidthSlider.roundValues, iconHeightSlider.roundValues = true, true

	local function setIconProperties(width, height, horizontalSpace, verticalSpace)
		userSettings.iconWidth, userSettings.iconHeight, userSettings.iconHorizontalSpace, userSettings.iconVerticalSpace = width, height, horizontalSpace, verticalSpace
		system.saveUserSettings()
		
		system.calculateIconProperties()
		system.updateIconProperties()
	end

	iconWidthSlider.onValueChanged = function()
		setIconProperties(math.floor(iconWidthSlider.value), math.floor(iconHeightSlider.value), userSettings.iconHorizontalSpace, userSettings.iconVerticalSpace)
	end
	iconHeightSlider.onValueChanged = iconWidthSlider.onValueChanged

	iconHorizontalSpaceBetweenSlider.onValueChanged = function()
		setIconProperties(userSettings.iconWidth, userSettings.iconHeight, math.floor(iconHorizontalSpaceBetweenSlider.value), math.floor(iconVerticalSpaceBetweenSlider.value))
	end
	iconVerticalSpaceBetweenSlider.onValueChanged = iconHorizontalSpaceBetweenSlider.onValueChanged

	showExtensionSwitch.onStateChanged = function()
		userSettings.filesShowExtension = showExtensionSwitch.state
		userSettings.filesShowHidden = showHiddenFilesSwitch.state
		userSettings.filesShowApplicationIcon = showApplicationIconsSwitch.state
		userSettings.interfaceTransparencyEnabled = transparencySwitch.state
		userSettings.interfaceBlurEnabled = blurSwitch.state
		
		system.saveUserSettings()

		computer.pushSignal("system", "updateFileList")
	end

	showHiddenFilesSwitch.onStateChanged, showApplicationIconsSwitch.onStateChanged, transparencySwitch.onStateChanged, blurSwitch.onStateChanged = showExtensionSwitch.onStateChanged, showExtensionSwitch.onStateChanged, showExtensionSwitch.onStateChanged, showExtensionSwitch.onStateChanged

end

--------------------------------------------------------------------------------

return module

