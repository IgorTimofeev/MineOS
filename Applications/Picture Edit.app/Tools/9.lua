
local image = require("Image")
local GUI = require("GUI")
local text = require("Text")

------------------------------------------------------

local workspace, window, menu = select(1, ...), select(2, ...), select(3, ...)
local tool = {}
local locale = select(4, ...)

tool.shortcut = "Bra"
tool.keyCode = 33
tool.about = locale.tool9

local layout = GUI.layout(1, 1, 1, 8, 1, 1)
local container, char, step = layout:addChild(GUI.container(1, 1, 8, 8)), " ", false
for y = 1, 8, 2 do
	for x = 1, 8, 4 do
		local button = container:addChild(GUI.button(x, y, 4, 2, step and 0xFFFFFF or 0xD2D2D2, 0x0, step and 0x0 or 0x1E1E1E, 0x0, " "))
		button.switchMode = true
		button.onTouch = function()
			local data = {}
			for i = 1, #container.children do
				data[i] = container.children[i].pressed and 1 or 0
			end

			char = text.brailleChar(table.unpack(data))
		end

		step = not step
	end

	step = not step
end

local backgroundSwitch = window.newSwitch(locale.drawBack, false)

tool.onSelection = function()
	window.currentToolLayout:addChild(layout)
	window.currentToolLayout:addChild(backgroundSwitch)
end

tool.eventHandler = function(workspace, object, e1, e2, e3, e4)
	if e1 == "touch" or e1 == "drag" then
		local x, y = e3 - window.image.x + 1, e4 - window.image.y + 1
		local background, foreground, alpha, symbol = image.get(window.image.data, x, y)
		
		image.set(window.image.data, x, y,
			backgroundSwitch.switch.state and window.secondaryColorSelector.color or background,
			window.primaryColorSelector.color,
			backgroundSwitch.switch.state and 0 or alpha,
			char
		)

		workspace:draw()
	end
end

------------------------------------------------------

return tool
