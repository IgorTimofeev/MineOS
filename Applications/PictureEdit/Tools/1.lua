
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

local function repositionSelector(application)
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
	
	application:draw()
end

local function fitSelector(application)
	touchX, touchY, dragX, dragY = application.image.localX, application.image.localY, application.image.localX + application.image.width - 1, application.image.localY + application.image.height - 1
	repositionSelector(application)
end

tool.onSelection = function(application)
	application.currentToolLayout:addChild(fillButton).onTouch = function()
		for j = selector.y, selector.y + selector.height - 1 do
			for i = selector.x, selector.x + selector.width - 1 do
				image.set(application.image.data, i - application.image.x + 1, j - application.image.y + 1, application.primaryColorSelector.color, 0x0, 0, " ")
			end
		end

		application:draw()
	end
	
	application.currentToolLayout:addChild(outlineButton).onTouch = function()
		local x1, y1 = selector.x - application.image.x + 1, selector.y - application.image.y + 1
		local x2, y2 = x1 + selector.width - 1, y1 + selector.height - 1
		
		for x = x1, x2 do
			image.set(application.image.data, x, y1, application.primaryColorSelector.color, 0x0, 0, " ")
			image.set(application.image.data, x, y2, application.primaryColorSelector.color, 0x0, 0, " ")
		end

		for y = y1 + 1, y2 - 1 do
			image.set(application.image.data, x1, y, application.primaryColorSelector.color, 0x0, 0, " ")
			image.set(application.image.data, x2, y, application.primaryColorSelector.color, 0x0, 0, " ")
		end

		application:draw()
	end
	
	application.currentToolLayout:addChild(rasterizeLineButton).onTouch = function()
		buffer.rasterizeLine(
			touchX - application.image.x + 1,
			touchY - application.image.y + 1,
			dragX - application.image.x + 1,
			dragY - application.image.y + 1,
			function(x, y)
				image.set(application.image.data, x, y, application.primaryColorSelector.color, 0x0, 0, " ")
			end
		)

		application:draw()
	end

	application.currentToolLayout:addChild(rasterizeEllipseButton).onTouch = function()
		local minX, minY, maxX, maxY = math.min(touchX, dragX), math.min(touchY, dragY), math.max(touchX, dragX), math.max(touchY, dragY)
		local centerX, centerY = math.ceil(minX + (maxX - minX) / 2), math.ceil(minY + (maxY - minY) / 2)
				
		buffer.rasterizeEllipse(
			centerX - application.image.x + 1,
			centerY - application.image.y + 1,
			maxX - centerX,
			maxY - centerY,
			function(x, y)
				image.set(application.image.data, x, y, application.primaryColorSelector.color, 0x0, 0, " ")
			end
		)

		application:draw()
	end

	application.currentToolLayout:addChild(clearButton).onTouch = function()
		for j = selector.y, selector.y + selector.height - 1 do
			for i = selector.x, selector.x + selector.width - 1 do
				image.set(application.image.data, i - application.image.x + 1, j - application.image.y + 1, 0x0, 0x0, 1, " ")
			end
		end

		application:draw()
	end
	
	application.currentToolLayout:addChild(cropButton).onTouch = function()
		application.image.data = image.crop(application.image.data, selector.x - application.image.x + 1, selector.y - application.image.y + 1, selector.width, selector.height)
		application.image.reposition()
		fitSelector(application)
	end

	application.currentToolOverlay:addChild(selector)
	fitSelector(application)
end

tool.eventHandler = function(application, object, e1, e2, e3, e4)
	if e1 == "touch" then
		touchX, touchY, dragX, dragY = e3, e4, e3, e4
		repositionSelector(application)
	elseif e1 == "drag" then
		dragX, dragY = e3, e4
		repositionSelector(application)
	end
end

selector.eventHandler = tool.eventHandler
selector.draw = function()
	local step = true
	for x = selector.x + 1, selector.x + selector.width - 2 do
		buffer.drawText(x, selector.y, step and 0xFFFFFF or 0x0, "━")
		buffer.drawText(x, selector.y + selector.height - 1, step and 0xFFFFFF or 0x0, "━")
		step = not step
	end

	step = true
	for y = selector.y + 1, selector.y + selector.height - 2 do
		buffer.drawText(selector.x, y, step and 0xFFFFFF or 0x0, "┃")
		buffer.drawText(selector.x + selector.width - 1, y, step and 0xFFFFFF or 0x0, "┃")
		step = not step
	end

	buffer.drawText(selector.x, selector.y, 0x0, "┏")
	buffer.drawText(selector.x + selector.width - 1, selector.y + selector.height - 1, 0x0, "┛")

	buffer.drawText(selector.x + selector.width - 1, selector.y, 0x0, "┓")
	buffer.drawText(selector.x, selector.y + selector.height - 1, 0x0, "┗")

	buffer.drawText(touchX, touchY, 0x66FF80, "⬤")
	buffer.drawText(dragX, dragY, 0x66FF80, "⬤")
end

------------------------------------------------------

return tool