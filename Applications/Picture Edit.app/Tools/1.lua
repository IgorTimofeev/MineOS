
local GUI = require("GUI")
local screen = require("Screen")
local image = require("Image")

------------------------------------------------------

local workspace, window, menu = select(1, ...), select(2, ...), select(3, ...)
local tool = {}
local locale = select(4, ...)

tool.shortcut = "Slc"
tool.keyCode = 50
tool.about = locale.tool1

local selector, touchX, touchY, dragX, dragY = GUI.object(1, 1, 1, 1)

local fillButton = window.newButton1(locale.fill)
local outlineButton = window.newButton1(locale.outline)
local rasterizeLineButton = window.newButton1(locale.rasterizeLine)
local rasterizeEllipseButton = window.newButton1(locale.rasterizeEllipse)
local rasterizePolygonButton = window.newButton1(locale.rasterizePolygon)
local clearButton = window.newButton2(locale.clear)
local cropButton = window.newButton2(locale.crop)

local function repositionSelector()
	if dragX - touchX >= 0 then
		selector.localX, selector.width = touchX - window.currentToolOverlay.x + 1, dragX - touchX + 1
	else
		selector.localX, selector.width = dragX - window.currentToolOverlay.x + 1, touchX - dragX + 1
	end

	if dragY - touchY >= 0 then
		selector.localY, selector.height = touchY - window.currentToolOverlay.y + 1, dragY - touchY + 1
	else
		selector.localY, selector.height = dragY - window.currentToolOverlay.y + 1, touchY - dragY + 1
	end
	
	workspace:draw()
end

local function fitSelector()
	touchX, touchY, dragX, dragY = window.image.x, window.image.y, window.image.x + window.image.width - 1, window.image.y + window.image.height - 1
	repositionSelector()
end

tool.onSelection = function()
	window.currentToolLayout:addChild(fillButton).onTouch = function()
		for j = selector.y, selector.y + selector.height - 1 do
			for i = selector.x, selector.x + selector.width - 1 do
				image.set(window.image.data, i - window.image.x + 1, j - window.image.y + 1, window.primaryColorSelector.color, 0x0, 0, " ")
			end
		end

		workspace:draw()
	end
	
	window.currentToolLayout:addChild(outlineButton).onTouch = function()
		local x1, y1 = selector.x - window.image.x + 1, selector.y - window.image.y + 1
		local x2, y2 = x1 + selector.width - 1, y1 + selector.height - 1
		
		for x = x1, x2 do
			image.set(window.image.data, x, y1, window.primaryColorSelector.color, 0x0, 0, " ")
			image.set(window.image.data, x, y2, window.primaryColorSelector.color, 0x0, 0, " ")
		end

		for y = y1 + 1, y2 - 1 do
			image.set(window.image.data, x1, y, window.primaryColorSelector.color, 0x0, 0, " ")
			image.set(window.image.data, x2, y, window.primaryColorSelector.color, 0x0, 0, " ")
		end

		workspace:draw()
	end
	
	window.currentToolLayout:addChild(rasterizeLineButton).onTouch = function()
		screen.rasterizeLine(
			touchX - window.image.x + 1,
			touchY - window.image.y + 1,
			dragX - window.image.x + 1,
			dragY - window.image.y + 1,
			function(x, y)
				image.set(window.image.data, x, y, window.primaryColorSelector.color, 0x0, 0, " ")
			end
		)

		workspace:draw()
	end

	window.currentToolLayout:addChild(rasterizeEllipseButton).onTouch = function()
		local minX, minY, maxX, maxY = math.min(touchX, dragX), math.min(touchY, dragY), math.max(touchX, dragX), math.max(touchY, dragY)
		local centerX, centerY = math.ceil(minX + (maxX - minX) / 2), math.ceil(minY + (maxY - minY) / 2)
				
		screen.rasterizeEllipse(
			centerX - window.image.x + 1,
			centerY - window.image.y + 1,
			maxX - centerX,
			maxY - centerY,
			function(x, y)
				image.set(window.image.data, x, y, window.primaryColorSelector.color, 0x0, 0, " ")
			end
		)

		workspace:draw()
	end
	
	window.currentToolLayout:addChild(rasterizePolygonButton).onTouch = function()
		local container = GUI.addBackgroundContainer(workspace, true, true, locale.polygonEdges)
		container.panel.eventHandler = nil

		local edgesSelector = container.layout:addChild(GUI.comboBox(1, 1, 30, 3, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
		for i = 3, 10 do
			edgesSelector:addItem(i)
		end

		container.layout:addChild(GUI.button(1, 1, 30, 3, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, locale.ok)).onTouch = function()
			screen.rasterizePolygon(
				touchX - window.image.x + 1,
				touchY - window.image.y + 1,
				dragX - window.image.x + 1,
				dragY - window.image.y + 1,
				edgesSelector.selectedItem + 2,
				function(x, y)
					if x <= window.image.data[1] and y <= window.image.data[2] and x > 0 and y > 0 then
						image.set(window.image.data, x, y, window.primaryColorSelector.color, 0x0, 0, " ")
					end
				end
			)
			
			container:remove()
		end

		container.layout:addChild(GUI.button(1, 1, 30, 3, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, locale.cancel)).onTouch = function()
			container:remove()
		end

		workspace:draw()
	end

	window.currentToolLayout:addChild(clearButton).onTouch = function()
		for j = selector.y, selector.y + selector.height - 1 do
			for i = selector.x, selector.x + selector.width - 1 do
				image.set(window.image.data, i - window.image.x + 1, j - window.image.y + 1, 0x0, 0x0, 1, " ")
			end
		end

		workspace:draw()
	end
	
	window.currentToolLayout:addChild(cropButton).onTouch = function()
		window.image.data = image.crop(window.image.data, selector.x - window.image.x + 1, selector.y - window.image.y + 1, selector.width, selector.height)
		window.image.reposition()
		fitSelector()
	end

	window.currentToolOverlay:addChild(selector)
	fitSelector()
end

tool.eventHandler = function(workspace, object, e1, e2, e3, e4)
	if e1 == "touch" then
		touchX, touchY, dragX, dragY = e3, e4, e3, e4
		repositionSelector()
	elseif e1 == "drag" then
		dragX, dragY = e3, e4
		repositionSelector()
	end
end

selector.eventHandler = tool.eventHandler

selector.draw = function()
	local step = true
	for x = selector.x + 1, selector.x + selector.width - 2 do
		screen.drawText(x, selector.y, step and 0xFFFFFF or 0x0, "━")
		screen.drawText(x, selector.y + selector.height - 1, step and 0xFFFFFF or 0x0, "━")
		step = not step
	end

	step = true
	for y = selector.y + 1, selector.y + selector.height - 2 do
		screen.drawText(selector.x, y, step and 0xFFFFFF or 0x0, "┃")
		screen.drawText(selector.x + selector.width - 1, y, step and 0xFFFFFF or 0x0, "┃")
		step = not step
	end

	screen.drawText(selector.x, selector.y, 0x0, "┏")
	screen.drawText(selector.x + selector.width - 1, selector.y + selector.height - 1, 0x0, "┛")

	screen.drawText(selector.x + selector.width - 1, selector.y, 0x0, "┓")
	screen.drawText(selector.x, selector.y + selector.height - 1, 0x0, "┗")

	screen.drawText(selector.x, selector.y, 0x66FF80, "⬤")
	screen.drawText(selector.x + selector.width - 1, selector.y + selector.height - 1, 0x66FF80, "⬤")
end

------------------------------------------------------

return tool
