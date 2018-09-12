
local GUI = require("GUI")
local component = require("component")
local buffer = require("doubleBuffering")
local MineOSInterface = require("MineOSInterface")
local MineOSPaths = require("MineOSPaths")
local MineOSCore = require("MineOSCore")
local scale = require("scale")

local module = {}

local mainContainer, window, localization = table.unpack({...})

--------------------------------------------------------------------------------

module.name = localization.screen
module.margin = 0
module.onTouch = function()
	-- Screen proxy
	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.screenPreferredMonitor))
	
	local monitorComboBox = window.contentLayout:addChild(GUI.comboBox(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0xD2D2D2, 0xA5A5A5))
	for address in component.list("screen") do
		monitorComboBox:addItem(address).onTouch = function()
			buffer.clear(0x0)
			buffer.drawChanges()

			buffer.bindScreen(address, false)
			MineOSInterface.changeResolution()
			MineOSInterface.changeWallpaper()
			MineOSInterface.updateFileListAndDraw()
			MineOSCore.saveProperties()
		end
	end

	-- Resolution
	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.screenResolution))
	local resolutionComboBox = window.contentLayout:addChild(GUI.comboBox(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0xD2D2D2, 0xA5A5A5))

	local function setResolution(width, height)
		MineOSCore.properties.resolution = {width, height}
		MineOSInterface.changeResolution()
		MineOSInterface.changeWallpaper()
		MineOSInterface.updateFileListAndDraw()
		
		MineOSCore.saveProperties()
	end

	local step = 1 / 6
	for i = 1, step, -step do
		local width, height = scale.getResolution(i)
		resolutionComboBox:addItem(width .. "x" .. height).onTouch = function()
			setResolution(width, height)
		end
	end

	local layout = window.contentLayout:addChild(GUI.layout(1, 1, 36, 3, 1, 1))
	layout:setDirection(1, 1, GUI.DIRECTION_HORIZONTAL)
	
	local widthInput = layout:addChild(GUI.input(1, 1, 16, 3, 0xE1E1E1, 0x696969, 0xA5A5A5, 0xE1E1E1, 0x2D2D2D, "", localization.screenWidth))
	layout:addChild(GUI.text(1, 1, 0x2D2D2D, "x"))
	local heightInput = layout:addChild(GUI.input(1, 1, 17, 3, 0xE1E1E1, 0x696969, 0xA5A5A5, 0xE1E1E1, 0x2D2D2D, "", localization.screenHeight))

	local switch = window.contentLayout:addChild(GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xA5A5A5, localization.screenAutoScale .. ":", MineOSCore.properties.screenAutoScale)).switch

	window.contentLayout:addChild(GUI.textBox(1, 1, 36, 1, nil, 0xA5A5A5, {localization.screenScaleInfo}, 1, 0, 0, true, true))

	local function updateSwitch()
		widthInput.text, heightInput.text = tostring(buffer.getWidth()), tostring(buffer.getHeight())
		resolutionComboBox.hidden = not switch.state
		layout.hidden = switch.state
		MineOSInterface.mainContainer:drawOnScreen()
	end

	switch.onStateChanged = function()
		updateSwitch()

		MineOSCore.properties.screenAutoScale = switch.state
		MineOSCore.saveProperties()
	end

	widthInput.onInputFinished = function()
		local width, height = tonumber(widthInput.text), tonumber(heightInput.text)
		if width and height then
			setResolution(width, height)
		end
	end
	heightInput.onInputFinished = widthInput.onInputFinished

	updateSwitch()
end

--------------------------------------------------------------------------------

return module

