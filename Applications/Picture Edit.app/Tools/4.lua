
local image = require("image")
local GUI = require("GUI")
local tool = {}

------------------------------------------------------

tool.shortcut = "Pi"
tool.keyCode = 56
tool.about = "Picker tool allows to select interested data from image as primary or secondary color. You can configure of what colors to pick."

local pickBackgroundSwitch = GUI.switchAndLabel(1, 1, width, 6, 0x66DB80, 0x2D2D2D, 0xE1E1E1, 0x878787, "Pick background:", true)
local pickForegroundSwitch = GUI.switchAndLabel(1, 1, width, 6, 0x66DB80, 0x2D2D2D, 0xE1E1E1, 0x878787, "Pick foreground:", true)

tool.onSelection = function(workspace)
	workspace.currentToolLayout:addChild(pickBackgroundSwitch)
	workspace.currentToolLayout:addChild(pickForegroundSwitch)
end

tool.eventHandler = function(workspace, object, e1, e2, e3, e4)
	if e1 == "touch" or e1 == "drag" then
		local x, y = e3 - workspace.image.x + 1, e4 - workspace.image.y + 1
		
		local background, foreground = image.get(workspace.image.data, x, y)

		if pickBackgroundSwitch.switch.state then
			workspace.secondaryColorSelector.color = background
		end

		if pickForegroundSwitch.switch.state then
			workspace.primaryColorSelector.color = foreground
		end

		workspace:draw()
	end
end

------------------------------------------------------

return tool