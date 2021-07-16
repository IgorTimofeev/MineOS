
local image = require("Image")
local GUI = require("GUI")

------------------------------------------------------

local workspace, window, menu = select(1, ...), select(2, ...), select(3, ...)
local tool = {}
local locale = select(4, ...)

tool.shortcut = "Pck"
tool.keyCode = 56
tool.about = locale.tool4

local pickBackgroundSwitch = window.newSwitch(locale.pickBack, true)
local pickForegroundSwitch = window.newSwitch(locale.pickFor, true)

tool.onSelection = function()
	window.currentToolLayout:addChild(pickBackgroundSwitch)
	window.currentToolLayout:addChild(pickForegroundSwitch)
end

tool.eventHandler = function(workspace, object, e1, e2, e3, e4)
	if e1 == "touch" or e1 == "drag" then
		local x, y = e3 - window.image.x + 1, e4 - window.image.y + 1
		
		local background, foreground = image.get(window.image.data, x, y)

		if pickBackgroundSwitch.switch.state then
			window.secondaryColorSelector.color = background
		end

		if pickForegroundSwitch.switch.state then
			window.primaryColorSelector.color = foreground
		end

		workspace:draw()
	end
end

------------------------------------------------------

return tool
