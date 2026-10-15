
local GUI = require("GUI")
local screen = require("Screen")
local paths = require("Paths")
local system = require("System")

local module = {}

local workspace, window, localization, theme = table.unpack({...})
local userSettings = system.getUserSettings()

--------------------------------------------------------------------------------

module.name = localization.screen
module.margin = 4
module.onTouch = function()

	-- Screen proxy
	window.contentLayout:addChild(system.applyThemeToTitleText(GUI.text(1, 1, 0x0, localization.screenPreferredMonitor)))

	local screenComboBox = window.contentLayout:addChild(system.applyThemeToComboBox(GUI.comboBox(1, 1, 36, 3, 0x0, 0x0, 0x0, 0x0)))

	screenComboBox.onItemSelected = function(index)
		userSettings.interfaceScreenAddress = screenComboBox:getItem(index).text

		screen.clear(0x0)
		screen.update()

		system.updateScreen()
		system.updateResolution()
		system.updateWallpaper()
		workspace:draw()

		system.saveUserSettings()
	end

	do
		local screenAddress = screen.getScreenAddress()

		-- Filling screen screenComboBox with available addresses & selecting current one
		local index = 1

		for address in component.list("screen") do
			screenComboBox:addItem(address)

			if address == screenAddress then
				screenComboBox.selectedItem = index
			end

			index = index + 1
		end

		-- Precise mode
		local preciseSwitch = window.contentLayout:addChild(system.applyThemeToSwitchAndLabel(GUI.switchAndLabel(1, 1, 36, 6, 0x0, 0x0, 0x0, 0x0, localization.screenPreciseMode .. ":", component.invoke(screenAddress, "isPrecise")))).switch

		preciseSwitch.onStateChanged = function()
			component.invoke(screen.getScreenAddress(), "setPrecise", preciseSwitch.state)
		end
	end

	-- Resolution
	window.contentLayout:addChild(
		system.applyThemeToTitleText(
			GUI.text(1, 1, 0x2D2D2D, localization.screenResolution)
		)
	)

	local resolutionComboBox = window.contentLayout:addChild(system.applyThemeToComboBox(GUI.comboBox(1, 1, 36, 3, 0x0, 0x0, 0x0, 0x0)))

	local function setResolution(width, height)
		userSettings.interfaceScreenWidth = width
		userSettings.interfaceScreenHeight = height

		system.updateResolution()
		system.updateWallpaper()
		workspace:draw()
		
		system.saveUserSettings()
	end

	local step = 1 / 6
	for i = 1, step, -step do
		local width, height = screen.getScaledResolution(i)
		resolutionComboBox:addItem(width .. "x" .. height).onTouch = function()
			setResolution(width, height)
		end
	end

	local layout = window.contentLayout:addChild(GUI.layout(1, 1, 36, 3, 1, 1))
	layout:setDirection(1, 1, GUI.DIRECTION_HORIZONTAL)
	
	local widthInput = layout:addChild(system.applyThemeToInput(GUI.input(1, 1, 16, 3, 0x0, 0x0, 0x0, 0x0, 0x0, "", localization.screenWidth)))
	layout:addChild(system.applyThemeToDescriptionText(GUI.text(1, 1, 0x2D2D2D, "x")))
	local heightInput = layout:addChild(system.applyThemeToInput(GUI.input(1, 1, 17, 3, 0x0, 0x0, 0x0, 0x0, 0x0, "", localization.screenHeight)))

	local maxWidth, maxHeight = screen.getMaxResolution()
	local limit = maxWidth * maxHeight
	local lowerLimit = 5
	local cykaTextBox = window.contentLayout:addChild(system.applyThemeToDescriptionTextBox(GUI.textBox(1, 1, 36, 1, nil, 0x0, {string.format(localization.screenInvalidResolution, lowerLimit, limit)}, 1, 0, 0, true, true)))

	local autoscalingSwtich = window.contentLayout:addChild(system.applyThemeToSwitchAndLabel(GUI.switchAndLabel(1, 1, 36, 6, 0x0, 0x0, 0x0, 0x0, localization.screenAutoScale .. ":", userSettings.interfaceScreenAutoScale))).switch

	window.contentLayout:addChild(system.applyThemeToDescriptionTextBox(GUI.textBox(1, 1, 36, 1, nil, 0x0, {localization.screenScaleInfo}, 1, 0, 0, true, true)))

	local function updateSwitch()
		widthInput.text = tostring(userSettings.interfaceScreenWidth and userSettings.interfaceScreenWidth or screen.getWidth())
		heightInput.text = tostring(userSettings.interfaceScreenHeight and userSettings.interfaceScreenHeight or screen.getHeight())
		resolutionComboBox.hidden = not autoscalingSwtich.state
		layout.hidden = autoscalingSwtich.state
	end

	local function updateCykaTextBox()
		local width, height = tonumber(widthInput.text), tonumber(heightInput.text)
		
		cykaTextBox.hidden =
			width
			and height
			and width * height <= limit
			and width >= lowerLimit
			and height >= lowerLimit
		
		return width, height
	end

	-- Color depth
	window.contentLayout:addChild(
		system.applyThemeToTitleText(
			GUI.text(1, 1, 0x0, localization.screenColorDepth)
		)
	)

	local colorDepthComboBox = window.contentLayout:addChild(
		system.applyThemeToComboBox(
			GUI.comboBox(1, 1, 36, 3, 0x0, 0x0, 0x0, 0x0)
		)
	)

	local availableColorDepthValues = {1, 4, 8}
	if screen.getMaxColorDepth() >= 16 then
		table.insert(availableColorDepthValues, 16)
	end

	local function showColorDepthAlert(onSettingConfirmed)
		local container = system.applyThemeToBackgroundContainer(
			GUI.addBackgroundContainer(workspace, true, true, localization.screenColorDepthAlertTitle)
		)

		local layout = container.layout:addChild(GUI.layout(1, 1, 40, 6, 1, 2))

		layout:addChild(
			system.applyThemeToTextBox(
				GUI.textBox(1, 1, 36, 1, nil, 0x0, {localization.screenColorDepthAlertMessage}, 1, 0, 0, true, true)
			)
		):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)

		-- Ok / cancel
		layout:setDirection(1, 2, GUI.DIRECTION_HORIZONTAL)
		layout:setSpacing(1, 2, 3)

		layout:setPosition(
			1, 
			2, 
			layout:addChild(
				system.applyThemeToPrimaryButton(
					GUI.button(1, 1, 16, 3, 0x0, 0x0, 0x0, 0x0, localization.ok)
				)
			)
		).onTouch = function()
			onSettingConfirmed()
			container:remove()
		end

		layout:setPosition(
			1, 
			2, 
			layout:addChild(
				system.applyThemeToPrimaryButton(
					GUI.button(1, 1, 16, 3, 0x0, 0x0, 0x0, 0x0, localization.cancel)
				)
			)
		).onTouch = function()
			container:remove()
		end
	end
	
	local function setColorDepth(depth)
		local function confirmSetting()
			userSettings.interfaceColorDepth = depth

			system.updateResolution()
			system.updateResolution()
			system.updateWallpaper()
			workspace:draw()
		
			system.saveUserSettings()		
		end

		if depth == 1 then
			showColorDepthAlert(confirmSetting)
		else
			confirmSetting()
		end
	end

	local selectedColorDepth = userSettings.interfaceColorDepth or screen.getColorDepth()
	for i = 1, #availableColorDepthValues do
		local depth = availableColorDepthValues[i]

		colorDepthComboBox:addItem(depth .. "bit").onTouch = function()
			setColorDepth(depth)
		end

		if selectedColorDepth == depth then
			colorDepthComboBox.selectedItem = i
		end
	end

	autoscalingSwtich.onStateChanged = function()
		updateSwitch()
		updateCykaTextBox()
		workspace:draw()

		userSettings.interfaceScreenAutoScale = autoscalingSwtich.state
		system.saveUserSettings()
	end

	widthInput.onInputFinished = function()
		local width, height = updateCykaTextBox()
		
		if cykaTextBox.hidden then
			setResolution(width, height)
		else
			workspace:draw()
		end
	end

	heightInput.onInputFinished = widthInput.onInputFinished

	updateSwitch()
	updateCykaTextBox()
end

--------------------------------------------------------------------------------

return module
