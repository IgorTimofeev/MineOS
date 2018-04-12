
local image = require("image")
local GUI = require("GUI")
local tool = {}

------------------------------------------------------

tool.shortcut = "Br"
tool.keyCode = 33
tool.about = "Braille font tool allows you to draw pixels with Braille symbols on your image. Select preferred semi-pixels on menu, configure transparency affecting and \"Let's go fellas!\""

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

local transparencySwitch = GUI.switchAndLabel(1, 1, 1, 6, 0x66DB80, 0x2D2D2D, 0xE1E1E1, 0x878787, "Transparency:", false)

tool.onSelection = function(mainContainer)
	mainContainer.currentToolLayout:addChild(layout)
	mainContainer.currentToolLayout:addChild(transparencySwitch)
end

tool.eventHandler = function(mainContainer, object, eventData)
	if eventData[1] == "touch" or eventData[1] == "drag" then
		local x, y = eventData[3] - mainContainer.image.x + 1, eventData[4] - mainContainer.image.y + 1
		local background, foreground, alpha, symbol = image.get(mainContainer.image.data, x, y)
		
		image.set(mainContainer.image.data, x, y,
			transparencySwitch.switch.state and background or mainContainer.secondaryColorSelector.color,
			mainContainer.primaryColorSelector.color,
			transparencySwitch.switch.state and 1 or 0,
			char
		)

		mainContainer:drawOnScreen()
	end
end


------------------------------------------------------

return tool