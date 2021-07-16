
local image = require("Image")

------------------------------------------------------

local workspace, window, menu = select(1, ...), select(2, ...), select(3, ...)
local tool = {}
local locale = select(4, ...)

tool.shortcut = "Mov"
tool.keyCode = 47
tool.about = locale.tool2

local xOld, yOld
tool.eventHandler = function(workspace, object, e1, e2, e3, e4)
	if e1 == "touch" then
		xOld, yOld = e3, e4
	elseif e1 == "drag" and xOld and yOld then
		window.image.setPosition(
			window.image.localX + (e3 - xOld),
			window.image.localY + (e4 - yOld)
		)
		xOld, yOld = e3, e4
		
		workspace:draw()
	elseif e1 == "drop" then
		xOld, yOld = nil, nil
	end
end

------------------------------------------------------

return tool
