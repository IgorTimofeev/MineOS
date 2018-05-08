
local GUI = require("GUI")
local image = require("image")
local tool = {}

------------------------------------------------------

tool.shortcut = "Er"
tool.keyCode = 18
tool.about = "Eraser tool will cleanup pixels just like brush tool. You can configure of what data is need to be erased"

local backgroundSwitch = GUI.switchAndLabel(1, 1, width, 6, 0x66DB80, 0x2D2D2D, 0xE1E1E1, 0x878787, "Erase background:", true)
local foregroundSwitch = GUI.switchAndLabel(1, 1, width, 6, 0x66DB80, 0x2D2D2D, 0xE1E1E1, 0x878787, "Erase foreground:", true)
local alphaSwitch = GUI.switchAndLabel(1, 1, width, 6, 0x66DB80, 0x2D2D2D, 0xE1E1E1, 0x878787, "Erase alpha:", true)
local symbolSwitch = GUI.switchAndLabel(1, 1, width, 6, 0x66DB80, 0x2D2D2D, 0xE1E1E1, 0x878787, "Erase symbol:", true)
local radiusSlider = GUI.slider(1, 1, 1, 0x66DB80, 0x2D2D2D, 0xE1E1E1, 0x878787, 1, 8, 1, false, "Radius: ", " px")
radiusSlider.height = 2
radiusSlider.roundValues = true

tool.onSelection = function(mainContainer)
	mainContainer.currentToolLayout:addChild(backgroundSwitch)
	mainContainer.currentToolLayout:addChild(foregroundSwitch)
	mainContainer.currentToolLayout:addChild(alphaSwitch)
	mainContainer.currentToolLayout:addChild(symbolSwitch)
	mainContainer.currentToolLayout:addChild(radiusSlider)
end

tool.eventHandler = function(mainContainer, object, e1, e2, e3, e4)
	if e1 == "touch" or e1 == "drag" then
		local x, y = e3 - mainContainer.image.x + 1, e4 - mainContainer.image.y + 1
		local meow = math.floor(radiusSlider.value)

		for j = y - meow + 1, y + meow - 1 do
			for i = x - meow + 1, x + meow - 1 do
				if i >= 1 and i <= mainContainer.image.width and j >= 1 and j <= mainContainer.image.height then
					local background, foreground, alpha, symbol = image.get(mainContainer.image.data, i, j)
					image.set(mainContainer.image.data, i, j,
						backgroundSwitch.switch.state and 0x0 or background,
						foregroundSwitch.switch.state and 0x0 or foreground,
						alphaSwitch.switch.state and 1 or alpha,
						symbolSwitch.switch.state and " " or symbol
					)
				end
			end
		end

		mainContainer:drawOnScreen()
	end
end

------------------------------------------------------

return tool