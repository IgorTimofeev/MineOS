
local image = require("image")
local GUI = require("GUI")
local tool = {}

------------------------------------------------------

tool.shortcut = "Br"
tool.keyCode = 33
tool.about = "Braille tool allows you to draw pixels with Braille symbols on your image. Select preferred mini-pixels via menu above, configure transparency affecting and \"Let's go fellas!\""

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

			char = string.brailleChar(table.unpack(data))
		end

		step = not step
	end

	step = not step
end

local backgroundSwitch = GUI.switchAndLabel(1, 1, 1, 6, 0x66DB80, 0x2D2D2D, 0xE1E1E1, 0x878787, "Draw background:", false)

tool.onSelection = function(mainContainer)
	mainContainer.currentToolLayout:addChild(layout)
	mainContainer.currentToolLayout:addChild(backgroundSwitch)
end

tool.eventHandler = function(mainContainer, object, e1, e2, e3, e4)
	if e1 == "touch" or e1 == "drag" then
		local x, y = e3 - mainContainer.image.x + 1, e4 - mainContainer.image.y + 1
		local background, foreground, alpha, symbol = image.get(mainContainer.image.data, x, y)
		
		image.set(mainContainer.image.data, x, y,
			backgroundSwitch.switch.state and mainContainer.secondaryColorSelector.color or background,
			mainContainer.primaryColorSelector.color,
			backgroundSwitch.switch.state and 0 or alpha,
			char
		)

		mainContainer:drawOnScreen()
	end
end

------------------------------------------------------

return tool