
local image = require("image")
local buffer = require("doubleBuffering")
local tool = {}

---------------------------------------------------------------------------------------------------------

tool.shortcut = "M"
tool.keyCode = 47
tool.lastTouch = {x = 0, y = 0}
tool.offset = {x = 0, y = 0}

tool.onSelected = function(mainContainer)
	
end

tool.onDeselected = function(mainContainer)
	
end

tool.onEvent = function(mainContainer, eventData)
	if eventData[1] == "touch" then
		tool.lastTouch.x, tool.lastTouch.y = eventData[3], eventData[4]
	elseif eventData[1] == "drag" then
		local offset = eventData[3] - tool.lastTouch.x, eventData[3] - tool.lastTouch.y

		mainContainer:draw()
		buffer.draw()
	end
end

---------------------------------------------------------------------------------------------------------

return tool