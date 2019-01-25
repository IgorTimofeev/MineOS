
local image = require("Image")
local GUI = require("GUI")
local keyboard = require("Keyboard")

------------------------------------------------------

local workspace, window, menu = select(1, ...), select(2, ...), select(3, ...)
local tool = {}

tool.shortcut = "Brs"
tool.keyCode = 48
tool.about = "Classic brush tool to perform drawing with specified radius and transparency. You can configure of what data will be drawn. Also you can specify preferred symbol to draw with, otherwise whitespace will be used."

local backgroundSwitch = window.newSwitch("Draw background:", true)
local foregroundSwitch = window.newSwitch("Draw foreground:", true)
local alphaSwitch = window.newSwitch("Draw alpha:", true)
local symbolSwitch = window.newSwitch("Draw symbol:", true)

local symbolInput = window.newInput("", "Symbol to draw with")
symbolInput.onInputFinished = function()
	symbolInput.text = unicode.sub(symbolInput.text, 1, 1)
end

local alphaSlider = window.newSlider(0, 255, 0, false, "Alpha value: ", "")
local radiusSlider = window.newSlider(1, 8, 1, false, "Radius: ", " px")
radiusSlider.height = 2

tool.onSelection = function()
	window.currentToolLayout:addChild(backgroundSwitch)
	window.currentToolLayout:addChild(foregroundSwitch)
	window.currentToolLayout:addChild(alphaSwitch)
	window.currentToolLayout:addChild(symbolSwitch)
	window.currentToolLayout:addChild(symbolInput)
	window.currentToolLayout:addChild(alphaSlider)
	window.currentToolLayout:addChild(radiusSlider)
end

tool.eventHandler = function(workspace, object, e1, e2, e3, e4)
	if e1 == "touch" or e1 == "drag" then
		local x, y = e3 - window.image.x + 1, e4 - window.image.y + 1
		local meow = math.floor(radiusSlider.value)

		for j = y - meow + 1, y + meow - 1 do
			for i = x - meow + 1, x + meow - 1 do
				if i >= 1 and i <= window.image.width and j >= 1 and j <= window.image.height then
					local background, foreground, alpha, symbol = image.get(window.image.data, i, j)
					image.set(window.image.data, i, j,
						backgroundSwitch.switch.state and window.primaryColorSelector.color or background,
						foregroundSwitch.switch.state and window.secondaryColorSelector.color or foreground,
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