
local GUI = require("GUI")
local buffer = require("doubleBuffering")
local image = require("image")
local tool = {}

------------------------------------------------------

tool.shortcut = "Se"
tool.keyCode = 50
tool.about = "Selection tool allows you select preferred zone on image and perform some operations on it. For example, to crop, to fill, to clear and to outline in via selected primary color"

local xOld, yOld, selector
tool.eventHandler = function(mainContainer, object, eventData)
	if eventData[1] == "touch" then
		xOld, yOld = eventData[3], eventData[4]
		selector = mainContainer:addChild(GUI.object(eventData[3], eventData[4], 1, 1))
		selector.eventHandler = tool.eventHandler
		selector.draw = function()
			local step = true
			for x = selector.x + 1, selector.x + selector.width - 2 do
				buffer.text(x, selector.y, step and 0xFFFFFF or 0x0, "━")
				buffer.text(x, selector.y + selector.height - 1, step and 0xFFFFFF or 0x0, "━")
				step = not step
			end

			step = true
			for y = selector.y + 1, selector.y + selector.height - 2 do
				buffer.text(selector.x, y, step and 0xFFFFFF or 0x0, "┃")
				buffer.text(selector.x + selector.width - 1, y, step and 0xFFFFFF or 0x0, "┃")
				step = not step
			end

			buffer.text(selector.x, selector.y, 0x0, "┏")
			buffer.text(selector.x + selector.width - 1, selector.y, 0x0, "┓")
			buffer.text(selector.x + selector.width - 1, selector.y + selector.height - 1, 0x0, "┛")
			buffer.text(selector.x, selector.y + selector.height - 1, 0x0, "┗")
		end

		mainContainer:drawOnScreen()
	elseif eventData[1] == "drag" and selector then
		local x, y, width, height
		if eventData[3] - xOld >= 0 then
			x, width = xOld, eventData[3] - xOld + 1
		else
			x, width = eventData[3], xOld - eventData[3] + 1
		end

		if eventData[4] - yOld >= 0 then
			y, height = yOld, eventData[4] - yOld + 1
		else
			y, height = eventData[4], yOld - eventData[4] + 1
		end

		selector.localX, selector.localY, selector.width, selector.height = x, y, width, height
		
		mainContainer:drawOnScreen()
	elseif eventData[1] == "drop" and selector then
		local menu = GUI.contextMenu(eventData[3], eventData[4])
		
		menu:addItem("Fill").onTouch = function()
			for j = selector.y, selector.y + selector.height - 1 do
				for i = selector.x, selector.x + selector.width - 1 do
					image.set(mainContainer.image.data, i - mainContainer.image.x + 1, j - mainContainer.image.y + 1, mainContainer.primaryColorSelector.color, 0x0, 0, " ")
				end
			end
		end

		menu:addItem("Clear").onTouch = function()
			for j = selector.y, selector.y + selector.height - 1 do
				for i = selector.x, selector.x + selector.width - 1 do
					image.set(mainContainer.image.data, i - mainContainer.image.x + 1, j - mainContainer.image.y + 1, 0x0, 0x0, 1, " ")
				end
			end
		end

		menu:addItem("Outline").onTouch = function()
			local x1, y1 = selector.x - mainContainer.image.x + 1, selector.y - mainContainer.image.y + 1
			local x2, y2 = x1 + selector.width - 1, y1 + selector.height - 1
			
			for x = x1, x2 do
				image.set(mainContainer.image.data, x, y1, mainContainer.primaryColorSelector.color, 0x0, 0, " ")
				image.set(mainContainer.image.data, x, y2, mainContainer.primaryColorSelector.color, 0x0, 0, " ")
			end

			for y = y1 + 1, y2 - 1 do
				image.set(mainContainer.image.data, x1, y, mainContainer.primaryColorSelector.color, 0x0, 0, " ")
				image.set(mainContainer.image.data, x2, y, mainContainer.primaryColorSelector.color, 0x0, 0, " ")
			end
		end

		menu:addSeparator()

		menu:addItem("Crop").onTouch = function()
			mainContainer.image.data = image.crop(mainContainer.image.data, selector.x - mainContainer.image.x + 1, selector.y - mainContainer.image.y + 1, selector.width, selector.height)
			mainContainer.image.reposition()
		end

		menu:show()

		selector:delete()
		xOld, yOld, selector = nil, nil, nil
		mainContainer:drawOnScreen()
	end
end


------------------------------------------------------

return tool