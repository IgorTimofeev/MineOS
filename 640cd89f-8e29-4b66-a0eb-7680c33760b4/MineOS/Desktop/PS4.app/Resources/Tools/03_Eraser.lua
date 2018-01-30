
local image = require("image")
local buffer = require("doubleBuffering")
local tool = {}

---------------------------------------------------------------------------------------------------------

tool.shortcut = "E"
tool.keyCode = 18

tool.onSelected = function(mainContainer)
	
end

tool.onDeselected = function(mainContainer)
	
end

tool.onEvent = function(mainContainer, eventData)
	if eventData[1] == "touch" or eventData[1] == "drag" then
		local x, y = eventData[3] - mainContainer.drawingZone.x + 1, eventData[4] - mainContainer.drawingZone.y + 1
		image.set(mainContainer.drawingZone.layers[mainContainer.drawingZone.layers.current], x, y, 0x0, 0x0, 0xFF, " ")

		mainContainer:draw()
		buffer.draw()
	end
end

---------------------------------------------------------------------------------------------------------

return tool