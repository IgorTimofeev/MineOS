
local GUI = require("GUI")
local image = require("image")
local tool = {}

------------------------------------------------------

tool.shortcut = "Er"
tool.keyCode = 18
tool.about = "Eraser tool will erase all your pixels just like brush tool. But it's eraser!!1"

local radiusSlider = GUI.slider(1, 1, 1, 0x66DB80, 0x2D2D2D, 0xE1E1E1, 0x878787, 1, 8, 1, false, "Radius: ", " px")
radiusSlider.height = 2
radiusSlider.roundValues = true

tool.onSelection = function(mainContainer)
	mainContainer.currentToolLayout:addChild(radiusSlider)
end

tool.eventHandler = function(mainContainer, object, eventData)
	if eventData[1] == "touch" or eventData[1] == "drag" then
		local x, y = eventData[3] - mainContainer.image.x + 1, eventData[4] - mainContainer.image.y + 1
		local meow = math.floor(radiusSlider.value)

		for j = y - meow + 1, y + meow - 1 do
			for i = x - meow + 1, x + meow - 1 do
				if i >= 1 and i <= mainContainer.image.width and j >= 1 and j <= mainContainer.image.height then
					image.set(mainContainer.image.data, i, j, 0x0, 0x0, 1, " ")
				end
			end
		end

		mainContainer:drawOnScreen()
	end
end

------------------------------------------------------

return tool