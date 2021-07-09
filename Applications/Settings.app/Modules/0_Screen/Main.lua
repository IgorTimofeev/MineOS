
local GUI = require("GUI")
local screen = require("Screen")
local paths = require("Paths")
local system = require("System")

local module = {}

local workspace, window, localization = table.unpack({...})
local userSettings = system.getUserSettings()

--------------------------------------------------------------------------------

module.name = localization.screen
module.margin = 0
module.onTouch = function()
	-- Screen proxy
	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.screenPreferredMonitor))
	
	local monitorComboBox = window.contentLayout:addChild(GUI.comboBox(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0xD2D2D2, 0xA5A5A5))
	for address in component.list("screen") do
		monitorComboBox:addItem(address).onTouch = function()
			screen.clear(0x0)
			screen.update()

			screen.bind(address, false)
			
			system.updateResolution()
			system.updateWallpaper()
			workspace:draw()

			system.saveUserSettings()
		end
	end

	-- Resolution
	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.screenResolution))
	local resolutionComboBox = window.contentLayout:addChild(GUI.comboBox(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0xD2D2D2, 0xA5A5A5))

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
	
	local widthInput = layout:addChild(GUI.input(1, 1, 16, 3, 0xE1E1E1, 0x696969, 0xA5A5A5, 0xE1E1E1, 0x2D2D2D, "", localization.screenWidth))
	layout:addChild(GUI.text(1, 1, 0x2D2D2D, "x"))
	local heightInput = layout:addChild(GUI.input(1, 1, 17, 3, 0xE1E1E1, 0x696969, 0xA5A5A5, 0xE1E1E1, 0x2D2D2D, "", localization.screenHeight))

	local maxWidth, maxHeight = screen.getGPUProxy().maxResolution()
	local limit = maxWidth * maxHeight
	local lowerLimit = 30
	local cykaTextBox = window.contentLayout:addChild(GUI.textBox(1, 1, 36, 1, nil, 0x880000, {string.format(localization.screenInvalidResolution, lowerLimit, limit)}, 1, 0, 0, true, true))

	local switch = window.contentLayout:addChild(GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xA5A5A5, localization.screenAutoScale .. ":", userSettings.interfaceScreenAutoScale)).switch

	window.contentLayout:addChild(GUI.textBox(1, 1, 36, 1, nil, 0xA5A5A5, {localization.screenScaleInfo}, 1, 0, 0, true, true))

	local function updateSwitch()
		widthInput.text = tostring(userSettings.interfaceScreenWidth and userSettings.interfaceScreenWidth or screen.getWidth())
		heightInput.text = tostring(userSettings.interfaceScreenHeight and userSettings.interfaceScreenHeight or screen.getHeight())
		resolutionComboBox.hidden = not switch.state
		layout.hidden = switch.state
	end

	local function updateCykaTextBox()
		local width, height = tonumber(widthInput.text), tonumber(heightInput.text)
		cykaTextBox.hidden = width and height and width * height <= limit and width > lowerLimit and height > lowerLimit
		return width, height
	end

	switch.onStateChanged = function()
		updateSwitch()
		updateCykaTextBox()
		workspace:draw()

		userSettings.interfaceScreenAutoScale = switch.state
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
