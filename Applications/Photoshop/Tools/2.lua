
local image = require("image")
local tool = {}

------------------------------------------------------

tool.shortcut = "Mv"
tool.keyCode = 47
tool.about = "Move tool allows you to move image as you wish. But be careful: large images will take a time to shift and redraw. Hello, shitty GPUs!"

local xOld, yOld
tool.eventHandler = function(mainContainer, object, eventData)
	if eventData[1] == "touch" then
		xOld, yOld = eventData[3], eventData[4]
	elseif eventData[1] == "drag" and xOld and yOld then
		mainContainer.image.localX = mainContainer.image.localX + (eventData[3] - xOld)
		mainContainer.image.localY = mainContainer.image.localY + (eventData[4] - yOld)
		xOld, yOld = eventData[3], eventData[4]
		
		mainContainer:drawOnScreen()
	elseif eventData[1] == "drop" then
		xOld, yOld = nil, nil
	end
end


------------------------------------------------------

return tool