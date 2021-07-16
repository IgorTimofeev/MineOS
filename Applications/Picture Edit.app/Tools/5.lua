
local image = require("Image")
local GUI = require("GUI")
local keyboard = require("Keyboard")

------------------------------------------------------

local workspace, window, menu = select(1, ...), select(2, ...), select(3, ...)
local tool = {}
local locale = select(4, ...)

tool.shortcut = "Brs"
tool.keyCode = 48
tool.about = locale.tool5

local backgroundSwitch = window.newSwitch(locale.drawBack, true)
local foregroundSwitch = window.newSwitch(locale.drawFor, true)
local alphaSwitch = window.newSwitch(locale.drawAlpha, true)
local symbolSwitch = window.newSwitch(locale.drawSym, true)

local symbolInput = window.newInput("", locale.symToDraw)
symbolInput.onInputFinished = function()
	symbolInput.text = unicode.sub(symbolInput.text, 1, 1)
end

local alphaSlider = window.newSlider(0, 255, 0, false, locale.alphaVal, "")
local radiusSlider = window.newSlider(1, 8, 1, false, locale.radius, " px")
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
