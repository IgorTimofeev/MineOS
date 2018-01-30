
-- package.loaded.color = nil
-- package.loaded.GUI = nil

require("advancedLua")
local computer = require("computer")
local component = require("component")
local fs = require("filesystem")
local buffer = require("doubleBuffering")
local GUI = require("GUI")
local unicode = require("unicode")
local image = require("image")
local keyboard = require("keyboard")
local color = require("color")

local resourcesPath = fs.path(getCurrentScript()) .. "/Resources/"
local toolsPath = resourcesPath .. "/Tools/"

---------------------------------------------------------------------------------------------------------

-- /MineOS/Desktop/PS4.app/Main.lua
local mainContainer = GUI.fullScreenContainer()
mainContainer.backgroundPanel = mainContainer:addChild(GUI.panel(1, 2, mainContainer.width, mainContainer.height - 1, 0x262626))

---------------------------------------------------------------------------------------------------------

mainContainer.drawingZone = mainContainer:addChild(GUI.object(8, 3, 1, 1))
mainContainer.drawingZone.layers = {current = 1}

local function mergeLayersAtPixel(x, y)
	local background, foreground, alpha, symbol = image.get(mainContainer.drawingZone.layers[1], x, y)

	for layer = 2, #mainContainer.drawingZone.layers do
		local backgroundNext, foregroundNext, alphaNext, symbolNext = image.get(mainContainer.drawingZone.layers[layer], x, y)
		if backgroundNext then
			if background then
				background, alpha = color.blendRGBA(background, backgroundNext, alpha / 255, alphaNext / 255)
				alpha = alpha * 255
			else
				background, alpha = backgroundNext, alphaNext / 255
			end
			
			foreground = foregroundNext
			symbol = symbolNext
		end
	end

	return background or 0x0, foreground or 0x0, alpha or 255, symbol or " "
end

mainContainer.drawingZone.draw = function(object)
	local step = false
	for y = 1, object.height do
		for x = 1, object.width do
			local background, foreground, alpha, symbol = mergeLayersAtPixel(x, y)
			buffer.set(
				object.x + x - 1,
				object.y + y - 1,
				color.blend(step and 0xFFFFFF or 0xDDDDDD, background, alpha / 255),
				foreground,
				symbol
			)

			step = not step
		end
	end
end

mainContainer.drawingZone.eventHandler = function(mainContainer, object, eventData)
	mainContainer.leftToolbar.toolsContainer.children[mainContainer.leftToolbar.toolsContainer.current].module.onEvent(mainContainer, eventData)
end

---------------------------------------------------------------------------------------------------------

mainContainer.menu = mainContainer:addChild(GUI.menu(1, 1, mainContainer.width, 0xDDDDDD, 0x666666, 0x3366CC, 0xFFFFFF))
mainContainer.menu:addItem("PS", 0x0)
mainContainer.menu:addItem("File", 0x444444).onTouch = function()

end
mainContainer.menu:addItem("Edit", 0x444444).onTouch = function()

end

---------------------------------------------------------------------------------------------------------

local layersToolbarWidth = math.floor(mainContainer.width * 0.2)
mainContainer.layersToolbar = mainContainer:addChild(GUI.container(mainContainer.width - layersToolbarWidth + 1, 2, layersToolbarWidth, mainContainer.height - 1))
mainContainer.layersToolbar.layersObject = mainContainer.layersToolbar:addChild(GUI.object(1, 1, mainContainer.layersToolbar.width, mainContainer.layersToolbar.height))
mainContainer.layersToolbar.layersObject.offset = 0

mainContainer.layersToolbar.layersObject.draw = function(object)
	buffer.square(object.x, object.y, object.width, object.height, 0x444444, 0x555555, " ")
	
	local y = object.y + object.offset
	buffer.text(object.x, y, 0x262626, string.rep("─", object.width))
	buffer.text(object.x + 5, y, 0x262626, "┬")
	y = y + 1
	for i = #mainContainer.drawingZone.layers, 1, -1 do
		if i == mainContainer.drawingZone.layers.current then
			buffer.square(object.x, y, object.width, 3, 0x555555, 0xAAAAAA, " ")
		end

		-- Миниатюра
		buffer.square(object.x + 7, y, 6, 3, 0xFFFFFF)

		-- Текст
		buffer.text(object.x + 14, y + 1, 0xAAAAAA, mainContainer.drawingZone.layers[i].text)

		-- Кнопочка оффанья
		if mainContainer.drawingZone.layers[i].hidden then
			buffer.set(object.x + 2, y + 1, 0x3C3C3C, 0xAAAAAA, " ")
		else
			buffer.set(object.x + 2, y + 1, 0x3C3C3C, 0xAAAAAA, "*")
		end

		-- Рамки
		for i = 1, 3 do
			buffer.text(object.x + 5, y + i - 1, 0x262626, "│")
		end
		buffer.text(object.x, y + 3, 0x262626, string.rep("─", object.width))
		buffer.text(object.x + 5, y + 3, 0x262626, i > 1 and "┼" or "┴")


		y = y + 4
	end
end

mainContainer.layersToolbar.layersObject.eventHandler = function(mainContainer, object, eventData)
	if eventData[1] == "touch" then
		local index = math.ceil((eventData[4] - object.y - object.offset + 1) / 4)
		
		mainContainer.drawingZone.layers.current = #mainContainer.drawingZone.layers - index + 1

		mainContainer:draw()
		buffer.draw()
	elseif eventData[1] == "scroll" then
		object.offset = object.offset + eventData[5]
		if object.offset > 0 then
			object.offset = 0
		end
		
		mainContainer:draw()
		buffer.draw()
	end
end

local function newLayer(text)
	local atIndex = #mainContainer.drawingZone.layers > 0 and mainContainer.drawingZone.layers.current + 1 or 1

	table.insert(
		mainContainer.drawingZone.layers,
		atIndex,
		{
			text = text,
			hidden = false,
			[1] = mainContainer.drawingZone.width,
			[2] = mainContainer.drawingZone.height
		}
	)
end

---------------------------------------------------------------------------------------------------------

mainContainer.leftToolbar = mainContainer:addChild(GUI.container(1, 2, 5, mainContainer.height - 1))
mainContainer.leftToolbar:addChild(GUI.panel(1, 1, mainContainer.leftToolbar.width, mainContainer.leftToolbar.height, 0x444444))
mainContainer.leftToolbar.toolsContainer = mainContainer.leftToolbar:addChild(GUI.container(1, 1, mainContainer.leftToolbar.width, mainContainer.leftToolbar.height))

local function toolDraw(object)
	local background, foreground = object.state and 0x3C3C3C or 0x555555, object.state and 0xAAAAAA or 0xAAAAAA
	buffer.square(object.x, object.y, object.width, object.height, background, foreground, " ")
	buffer.set(math.floor(object.x + object.width / 2), math.floor(object.y + object.height / 2), background, foreground, object.module.shortcut)

	return object
end

local function selectTool(index)
	mainContainer.leftToolbar.toolsContainer.current = index
	for i = 1, #mainContainer.leftToolbar.toolsContainer.children do
		mainContainer.leftToolbar.toolsContainer.children[i].state = i == index
	end
end

local function toolEventHandler(mainContainer, object, eventData)
	if eventData[1] == "touch" then
		selectTool(object:indexOf())

		mainContainer:draw()
		buffer.draw()
	end
end

local function newTool(y, path)
	local object = GUI.object(1, y, mainContainer.leftToolbar.width, 3)
	
	local success, reason = dofile(path)
	if success then
		object.module = success
	else
		error("Failed to load module: " .. tostring(reason))
	end
	object.draw = toolDraw
	object.eventHandler = toolEventHandler

	return object
end

local y = 1
local toolsList = fs.sortedList(toolsPath, "name", false)
for i = 1, #toolsList do
	y = y + mainContainer.leftToolbar.toolsContainer:addChild(newTool(y, toolsPath .. toolsList[i])).height
end

---------------------------------------------------------------------------------------------------------

local function colorSelectorDraw(object)
	buffer.square(object.x, object.y, object.width, object.height, object.color, 0x0, " ")
end

local function colorSelectorEventHandler(mainContainer, object, eventData)
	if eventData[1] == "touch" then
		object.color = require("palette").show(math.floor(mainContainer.width / 2 - 35), math.floor(mainContainer.height / 2 - 12), object.color) or object.color
		mainContainer:draw()
		buffer.draw()
	end
end

local function newColorSelector(x, y, width, height, color)
	local object = GUI.object(x, y, width, height)

	object.color = color
	object.draw = colorSelectorDraw
	object.eventHandler = colorSelectorEventHandler

	return object
end

local colorSelectorsY = mainContainer.leftToolbar.height - 4
mainContainer.leftToolbar.secondColorSelector = mainContainer.leftToolbar:addChild(newColorSelector(2, colorSelectorsY + 1, 4, 2, 0xFF0000))
mainContainer.leftToolbar.firstColorSelector = mainContainer.leftToolbar:addChild(newColorSelector(1, colorSelectorsY, 4, 2, 0x0000FF))

---------------------------------------------------------------------------------------------------------

local function new(width, height, background, foreground, alpha, symbol)
	mainContainer.drawingZone.width, mainContainer.drawingZone.height = width, height
	newLayer("Layer 1")
end

---------------------------------------------------------------------------------------------------------

mainContainer.eventHandler = function(mainContainer, object, eventData)
	if eventData[1] == "key_down" then
		for i = 1, #mainContainer.leftToolbar.toolsContainer.children do
			if mainContainer.leftToolbar.toolsContainer.children[i].module.keyCode == eventData[4] then
				selectTool(i)
				mainContainer:draw()
				buffer.draw()

				break
			end
		end

		-- N
		if eventData[4] == 49 then
			newLayer("Layer " .. #mainContainer.drawingZone.layers + 1)
			mainContainer:draw()
			buffer.draw()
		elseif eventData[4] == 45 then
			mainContainer.leftToolbar.firstColorSelector.color, mainContainer.leftToolbar.secondColorSelector.color = mainContainer.leftToolbar.secondColorSelector.color, mainContainer.leftToolbar.firstColorSelector.color
			mainContainer:draw()
			buffer.draw()
		end
	end
end

---------------------------------------------------------------------------------------------------------

buffer.flush()
buffer.draw(true)

selectTool(2)
new(51, 19, 0x0, 0xFFFFFF, 0x0, "A")
mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()















