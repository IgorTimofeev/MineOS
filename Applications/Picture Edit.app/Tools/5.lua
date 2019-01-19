
local image = require("image")
local GUI = require("GUI")
local keyboard = require("keyboard")
local tool = {}

------------------------------------------------------

tool.shortcut = "Bs"
tool.keyCode = 48
tool.about = "Classic brush tool to perform drawing with specified radius and transparency. You can configure of what data will be drawn. Also you can specify preferred symbol to draw with, otherwise whitespace will be used."

local backgroundSwitch = GUI.switchAndLabel(1, 1, width, 6, 0x66DB80, 0x2D2D2D, 0xE1E1E1, 0x878787, "Draw background:", true)
local foregroundSwitch = GUI.switchAndLabel(1, 1, width, 6, 0x66DB80, 0x2D2D2D, 0xE1E1E1, 0x878787, "Draw foreground:", true)
local alphaSwitch = GUI.switchAndLabel(1, 1, width, 6, 0x66DB80, 0x2D2D2D, 0xE1E1E1, 0x878787, "Draw alpha:", true)
local symbolSwitch = GUI.switchAndLabel(1, 1, width, 6, 0x66DB80, 0x2D2D2D, 0xE1E1E1, 0x878787, "Draw symbol:", true)
local symbolInput = GUI.input(1, 1, width, 1, 0x2D2D2D, 0xC3C3C3, 0x5A5A5A, 0x2D2D2D, 0xD2D2D2, "", "Symbol to draw with")
symbolInput.onInputFinished = function()
	symbolInput.text = unicode.sub(symbolInput.text, 1, 1)
end
local alphaSlider = GUI.slider(1, 1, width, 0x66DB80, 0x2D2D2D, 0xE1E1E1, 0x878787, 0, 255, 0, false, "Alpha value: ", "")
alphaSlider.roundValues = true
local radiusSlider = GUI.slider(1, 1, width, 0x66DB80, 0x2D2D2D, 0xE1E1E1, 0x878787, 1, 8, 1, false, "Radius: ", " px")
radiusSlider.height = 2
radiusSlider.roundValues = true

tool.onSelection = function(workspace)
	workspace.currentToolLayout:addChild(backgroundSwitch)
	workspace.currentToolLayout:addChild(foregroundSwitch)
	workspace.currentToolLayout:addChild(alphaSwitch)
	workspace.currentToolLayout:addChild(symbolSwitch)
	workspace.currentToolLayout:addChild(symbolInput)
	workspace.currentToolLayout:addChild(alphaSlider)
	workspace.currentToolLayout:addChild(radiusSlider)
end

tool.eventHandler = function(workspace, object, e1, e2, e3, e4)
	if e1 == "touch" or e1 == "drag" then
		local x, y = e3 - workspace.image.x + 1, e4 - workspace.image.y + 1
		local meow = math.floor(radiusSlider.value)

		for j = y - meow + 1, y + meow - 1 do
			for i = x - meow + 1, x + meow - 1 do
				if i >= 1 and i <= workspace.image.width and j >= 1 and j <= workspace.image.height then
					local background, foreground, alpha, symbol = image.get(workspace.image.data, i, j)
					image.set(workspace.image.data, i, j,
						backgroundSwitch.switch.state and workspace.primaryColorSelector.color or background,
						foregroundSwitch.switch.state and workspace.secondaryColorSelector.color or foreground,
						alphaSwitch.switch.state and alphaSlider.value / 255 or alpha,
						symbolSwitch.switch.state and (symbolInput.text == "" and " " or symbolInput.text) or symbol
					)
				end
			end
		end

		workspace:draw()
	end
end

------------------------------------------------------

return tool