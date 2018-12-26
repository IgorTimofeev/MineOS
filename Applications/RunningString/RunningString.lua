local MineOSInterface = require("MineOSInterface")
local GUI = require("GUI")
local buffer = require("doubleBuffering")
local scale = require("scale")
local unicode = require("unicode")
local event = require("event")

---------------------------------------------------------------------------------------------------------

local container = MineOSInterface.addBackgroundContainer(MineOSInterface.application, "Running string setup")

local textInput = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xFFFFFF, 0x696969, 0xB4B4B4, 0xFFFFFF, 0x2D2D2D, "Working on cool things, don't distract me", "Type text here", true))
local backgroundColorSelector = container.layout:addChild(GUI.colorSelector(1, 1, 36, 3, 0x0, "Background color"))
local textColorSelector = container.layout:addChild(GUI.colorSelector(1, 1, 36, 3, 0xFFFFFF, "Text color"))
local scaleSlider = container.layout:addChild(GUI.slider(1, 1, 36, 0x66DB80, 0x2D2D2D, 0xE1E1E1, 0x878787, 1, 1000, 100, false, "Scale: ", ""))
local delaySlider = container.layout:addChild(GUI.slider(1, 1, 36, 0x66DB80, 0x2D2D2D, 0xE1E1E1, 0x878787, 0, 500, 50, false, "Delay: ", " ms"))
local spacingSlider = container.layout:addChild(GUI.slider(1, 1, 36, 0x66DB80, 0x2D2D2D, 0xE1E1E1, 0x878787, 1, 50, 10, false, "Spacing: ", " char(s)"))
scaleSlider.roundValues, delaySlider.roundValues, spacingSlider.roundValues = true, true, true
spacingSlider.height = 2

container.layout:addChild(GUI.button(1, 1, 36, 3, 0x444444, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, "OK")).onTouch = function()
	local text = textInput.text .. string.rep(" ", math.round(spacingSlider.value))
	local gpu = buffer.getGPUProxy()
	
	scale.set(scaleSlider.value / 1000)
	local width, height = gpu.getResolution()
	local y = math.round(height / 2)
	
	gpu.setBackground(backgroundColorSelector.color)
	gpu.setForeground(textColorSelector.color)
	gpu.fill(1, 1, width, height, " ")

	while true do
		local eventData = {event.pull(delaySlider.value / 1000)}
		if eventData[1] == "touch" or eventData[1] == "key_down" then
			break
		end

		text = unicode.sub(text, 2, -1) .. unicode.sub(text, 1, 1)
		gpu.set(1, y, text)
	end

	buffer.setResolution(buffer.getResolution())
	MineOSInterface.application:draw()
end











