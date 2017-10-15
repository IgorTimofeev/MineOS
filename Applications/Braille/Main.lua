
require("advancedLua")
local fs = require("filesystem")
local buffer = require("doubleBuffering")
local GUI = require("GUI")
local unicode = require("unicode")
local image = require("image")
local keyboard = require("keyboard")
local MineOSInterface = require("MineOSInterface")

---------------------------------------------------------------------------------------------------------

local mainContainer, window = MineOSInterface.addWindow(GUI.window(nil, nil, 32, 19))
local panel = window:addChild(GUI.panel(1, 1, 1, 3, 0x2D2D2D, 0.2))

local layout = window:addChild(GUI.layout(1, 2, 1, 1, 1, 1))
layout:setCellDirection(1, 1, GUI.directions.horizontal)

local actionButtons = window:addChild(GUI.actionButtons(2, 1))
local newButton = layout:addChild(GUI.button(1, 1, 3, 1, 0x444444, 0xE1E1E1, 0xE1E1E1, 0x444444, "N"))
local saveButton = layout:addChild(GUI.button(1, 1, 3, 1, 0x444444, 0xE1E1E1, 0xE1E1E1, 0x444444, "S"))
local colorSelector1 = layout:addChild(GUI.colorSelector(1, 1, 3, 1, 0xFF4940, "B"))
local colorSelector2 = layout:addChild(GUI.colorSelector(1, 1, 3, 1, 0x9924FF, "F"))

local function newCell(x, y, shaded)
	local object = GUI.object(x, y, 4, 4)
	object.shaded = shaded
	object.pixels = {}
	object.background = 0xFF0000
	object.foreground = 0x0000FF
	for y = 1, 4 do
		object.pixels[y] = {}
	end

	object.draw = function(object)
		local step = false
		for y = 1, 4 do
			for x = 1, 2 do
				if object.pixels[y][x] then
					buffer.square(object.x + x * 2 - 2, object.y + y - 1, 2, 1, object.pixels[y][x] == 1 and object.foreground or object.background, 0x0, " ")
				else
					buffer.square(object.x + x * 2 - 2, object.y + y - 1, 2, 1, 0xFFFFFF, object.shaded and (step and 0xC3C3C3 or 0xB4B4B4) or (step and 0xE1E1E1 or 0xD2D2D2), "▒")
				end
				step = not step
			end
			step = not step
		end
	end

	object.eventHandler = function(mainContainer, object, eventData)
		if eventData[1] == "touch" or eventData[1] == "drag" then
			local x, y = math.ceil((eventData[3] - object.x + 1) / 2), eventData[4] - object.y + 1
			
			object.background = colorSelector1.color
			object.foreground = colorSelector2.color

			-- CTRL or CMD or ALT
			if keyboard.isKeyDown(29) or keyboard.isKeyDown(219) or keyboard.isKeyDown(56) then
				object.pixels[y][x] = nil	
			else
				object.pixels[y][x] = eventData[5] == 0 and 1 or 0
			end

			mainContainer:draw()
			buffer.draw()
		end
	end

	return object
end


local drawingArea = window:addChild(GUI.container(1, 4, 1, 1))

local function getBrailleChar(a, b, c, d, e, f, g, h)
	return unicode.char(10240 + 128*h + 64*g + 32*f + 16*d + 8*b + 4*e + 2*c + a)
end

local function newNoGUI(width, height)
	drawingArea.width, drawingArea.height = width * 4, height * 4
	
	window.width = drawingArea.width
	window.height = drawingArea.height + 3

	panel.width = window.width
	layout.width = panel.width
	

	drawingArea:deleteChildren()

	local x, y, step = 1, 1, false
	for j = 1, height do
		for i = 1, width do
			drawingArea:addChild(newCell(x, y, step))
			x, step = x + 4, not step
		end
		x, y, step = 1, y + 4, not step
	end	
end

local function new()
	local container = MineOSInterface.addUniversalContainer(mainContainer, "Create")

	local widthTextBox = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0x666666, 0xEEEEEE, 0x262626, "8", "Width", true))
	widthTextBox.validator = function(text)
		return tonumber(text)
	end

	local heightTextBox = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0x666666, 0xEEEEEE, 0x262626, "4", "Height", true))
	heightTextBox.validator = function(text)
		return tonumber(text)
	end

	container.panel.eventHandler = function(mainContainer, object, eventData)
		if eventData[1] == "touch" then
			container:delete()

			newNoGUI(tonumber(widthTextBox.text), tonumber(heightTextBox.text))

			mainContainer:draw()
			buffer.draw()
		end
	end

	mainContainer:draw()
	buffer.draw()
end

local function fillBrailleArray(source, inverted)
	local brailleArray, transparencyCyka, backgroundCyka, foregroundCyka = {}

	for j = 1, 4 do
		for i = 1, 2 do
			if not source[j][i] then
				transparencyCyka = true
				table.insert(brailleArray, 0)
			elseif source[j][i] == 1 then
				foregroundCyka = true
				table.insert(brailleArray, inverted and 0 or 1)
			else
				backgroundCyka = true
				table.insert(brailleArray, inverted and 1 or 0)
			end
		end
	end

	return brailleArray, transparencyCyka, backgroundCyka, foregroundCyka
end

local function saveAs()
	local filesystemDialog = GUI.addFilesystemDialogToContainer(mainContainer, "OK", "Cancel", "Path", "/")
	filesystemDialog:setMode(GUI.filesystemModes.save, GUI.filesystemModes.file)
	filesystemDialog:addExtensionFilter(".pic")
	filesystemDialog.onSubmit = function(path)
		local picture = {drawingArea.width / 4, drawingArea.height / 4}

		local x, y = 1, 1
		for childIndex = 1, #drawingArea.children do
			local background, foreground = drawingArea.children[childIndex].background, drawingArea.children[childIndex].foreground
			
			local brailleArray, transparencyCyka, backgroundCyka, foregroundCyka = fillBrailleArray(drawingArea.children[childIndex].pixels)
			if transparencyCyka then
				if backgroundCyka and foregroundCyka then
					GUI.error("Пиксель " .. x .. "x" .. y .. " имеет два цвета и прозрачность. Убирай любой из цветов и наслаждайся")
					return
				else
					background = 0x0
					if backgroundCyka then
						foreground = drawingArea.children[childIndex].background
						brailleArray = fillBrailleArray(drawingArea.children[childIndex].pixels, true)
					end
				end
			end

			image.set(
				picture, x, y, background, foreground,
				transparencyCyka and 1 or 0,
				string.brailleChar(table.unpack(brailleArray))
			)

			x = x + 1
			if x > picture[1] then
				x, y = 1, y + 1
			end
		end

		image.save(path, picture)
	end
	filesystemDialog:show()
end

newButton.onTouch = function()
	new()
end
saveButton.onTouch = function()
	saveAs()
end
actionButtons.close.onTouch = function()
	window:close()
end
actionButtons.minimize:delete()
actionButtons.maximize:delete()


---------------------------------------------------------------------------------------------------------

newNoGUI(8, 4)

mainContainer:draw()
buffer.draw(true)



