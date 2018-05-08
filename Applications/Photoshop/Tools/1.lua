
local GUI = require("GUI")
local buffer = require("doubleBuffering")
local image = require("image")
local tool = {}

------------------------------------------------------

tool.shortcut = "Se"
tool.keyCode = 50
tool.about = "Selection tool allows you to select preferred area on image and to perform some operations on it. Green dots mean start and end points (for example, it needs to line rasterization)"

local selector, touchX, touchY, dragX, dragY = GUI.object(1, 1, 1, 1)

local fillButton = GUI.roundedButton(1, 1, 36, 1, 0xE1E1E1, 0x2D2D2D, 0x2D2D2D, 0xE1E1E1, "Fill")
local outlineButton = GUI.roundedButton(1, 1, 36, 1, 0xE1E1E1, 0x2D2D2D, 0x2D2D2D, 0xE1E1E1, "Outline")
local rasterizeLineButton = GUI.roundedButton(1, 1, 36, 1, 0xE1E1E1, 0x2D2D2D, 0x2D2D2D, 0xE1E1E1, "Rasterize line")
local rasterizeEllipseButton = GUI.roundedButton(1, 1, 36, 1, 0xE1E1E1, 0x2D2D2D, 0x2D2D2D, 0xE1E1E1, "Rasterize ellipse")
local clearButton = GUI.roundedButton(1, 1, 36, 1, 0x696969, 0xE1E1E1, 0x2D2D2D, 0xE1E1E1, "Clear")
local cropButton = GUI.roundedButton(1, 1, 36, 1, 0x696969, 0xE1E1E1, 0x2D2D2D, 0xE1E1E1, "Crop")

local function repositionSelector(mainContainer)
	if dragX - touchX >= 0 then
		selector.localX, selector.width = touchX, dragX - touchX + 1
	else
		selector.localX, selector.width = dragX, touchX - dragX + 1
	end

	if dragY - touchY >= 0 then
		selector.localY, selector.height = touchY, dragY - touchY + 1
	else
		selector.localY, selector.height = dragY, touchY - dragY + 1
	end
	
	mainContainer:drawOnScreen()
end

local function fitSelector(mainContainer)
	touchX, touchY, dragX, dragY = mainContainer.image.localX, mainContainer.image.localY, mainContainer.image.localX + mainContainer.image.width - 1, mainContainer.image.localY + mainContainer.image.height - 1
	repositionSelector(mainContainer)
end

tool.onSelection = function(mainContainer)
	mainContainer.currentToolLayout:addChild(fillButton).onTouch = function()
		for j = selector.y, selector.y + selector.height - 1 do
			for i = selector.x, selector.x + selector.width - 1 do
				image.set(mainContainer.image.data, i - mainContainer.image.x + 1, j - mainContainer.image.y + 1, mainContainer.primaryColorSelector.color, 0x0, 0, " ")
			end
		end

		mainContainer:drawOnScreen()
	end
	
	mainContainer.currentToolLayout:addChild(outlineButton).onTouch = function()
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

		mainContainer:drawOnScreen()
	end
	
	mainContainer.currentToolLayout:addChild(rasterizeLineButton).onTouch = function()
		buffer.rasterizeLine(
			touchX - mainContainer.image.x + 1,
			touchY - mainContainer.image.y + 1,
			dragX - mainContainer.image.x + 1,
			dragY - mainContainer.image.y + 1,
			function(x, y)
				image.set(mainContainer.image.data, x, y, mainContainer.primaryColorSelector.color, 0x0, 0, " ")
			end
		)

		mainContainer:drawOnScreen()
	end

	mainContainer.currentToolLayout:addChild(rasterizeEllipseButton).onTouch = function()
		local minX, minY, maxX, maxY = math.min(touchX, dragX), math.min(touchY, dragY), math.max(touchX, dragX), math.max(touchY, dragY)
		local centerX, centerY = math.ceil(minX + (maxX - minX) / 2), math.ceil(minY + (maxY - minY) / 2)
				
		buffer.rasterizeEllipse(
			centerX - mainContainer.image.x + 1,
			centerY - mainContainer.image.y + 1,
			maxX - centerX,
			maxY - centerY,
			function(x, y)
				image.set(mainContainer.image.data, x, y, mainContainer.primaryColorSelector.color, 0x0, 0, " ")
			end
		)

		mainContainer:drawOnScreen()
	end

	mainContainer.currentToolLayout:addChild(clearButton).onTouch = function()
		for j = selector.y, selector.y + selector.height - 1 do
			for i = selector.x, selector.x + selector.width - 1 do
				image.set(mainContainer.image.data, i - mainContainer.image.x + 1, j - mainContainer.image.y + 1, 0x0, 0x0, 1, " ")
			end
		end

		mainContainer:drawOnScreen()
	end
	
	mainContainer.currentToolLayout:addChild(cropButton).onTouch = function()
		mainContainer.image.data = image.crop(mainContainer.image.data, selector.x - mainContainer.image.x + 1, selector.y - mainContainer.image.y + 1, selector.width, selector.height)
		mainContainer.image.reposition()
		fitSelector(mainContainer)
	end

	mainContainer.currentToolOverlay:addChild(selector)
	fitSelector(mainContainer)
end

tool.eventHandler = function(mainContainer, object, e1, e2, e3, e4)
	if e1 == "touch" then
		touchX, touchY, dragX, dragY = e3, e4, e3, e4
		repositionSelector(mainContainer)
	elseif e1 == "drag" then
		dragX, dragY = e3, e4
		repositionSelector(mainContainer)
	end
end

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
	buffer.text(selector.x + selector.width - 1, selector.y + selector.height - 1, 0x0, "┛")

	buffer.text(selector.x + selector.width - 1, selector.y, 0x0, "┓")
	buffer.text(selector.x, selector.y + selector.height - 1, 0x0, "┗")

	buffer.text(touchX, touchY, 0x66FF80, "⬤")
	buffer.text(dragX, dragY, 0x66FF80, "⬤")
end

------------------------------------------------------

return tool