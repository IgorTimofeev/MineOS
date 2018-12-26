
require("advancedLua")
local fs = require("filesystem")
local buffer = require("doubleBuffering")
local GUI = require("GUI")
local unicode = require("unicode")
local image = require("image")
local keyboard = require("keyboard")
local MineOSInterface = require("MineOSInterface")

---------------------------------------------------------------------------------------------------------

local application, window = MineOSInterface.addWindow(GUI.filledWindow(1, 1, 32, 19, 0x2D2D2D))

local layout = window:addChild(GUI.layout(1, 2, 1, 1, 1, 1))
layout:setDirection(1, 1, GUI.DIRECTION_HORIZONTAL)

local newButton = layout:addChild(GUI.button(1, 1, 3, 1, 0x444444, 0xE1E1E1, 0xE1E1E1, 0x444444, "N"))
local saveButton = layout:addChild(GUI.button(1, 1, 3, 1, 0x444444, 0xE1E1E1, 0xE1E1E1, 0x444444, "S"))
local openButton = layout:addChild(GUI.button(1, 1, 3, 1, 0x444444, 0xE1E1E1, 0xE1E1E1, 0x444444, "O"))
local colorSelector1 = layout:addChild(GUI.colorSelector(1, 1, 3, 1, 0xFF4940, "B"))
local colorSelector2 = layout:addChild(GUI.colorSelector(1, 1, 3, 1, 0x9924FF, "F"))
local keepSwitch = layout:addChild(GUI.switchAndLabel(1, 1, 16, 5, 0x66DB80, 0x1E1E1E, 0xE1E1E1, 0x888888, "Replace: ", true)).switch

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
					buffer.drawRectangle(object.x + x * 2 - 2, object.y + y - 1, 2, 1, object.pixels[y][x] == 1 and object.foreground or object.background, 0x0, " ")
				else
					buffer.drawRectangle(object.x + x * 2 - 2, object.y + y - 1, 2, 1, 0xFFFFFF, object.shaded and (step and 0xC3C3C3 or 0xB4B4B4) or (step and 0xE1E1E1 or 0xD2D2D2), "▒")
				end
				step = not step
			end
			step = not step
		end
	end

	object.eventHandler = function(application, object, e1, e2, e3, e4, e5)
		if e1 == "touch" or e1 == "drag" then
			local x, y = math.ceil((e3 - object.x + 1) / 2), e4 - object.y + 1
			
			if (object.background ~= colorSelector1.color and keepSwitch.state) or object.background == colorSelector1.color then
				object.background = colorSelector1.color
			end

			if (object.foreground ~= colorSelector2.color and keepSwitch.state) or object.foreground == colorSelector2.color then
				object.foreground = colorSelector2.color
			end

			-- CTRL or CMD or ALT
			if keyboard.isKeyDown(29) or keyboard.isKeyDown(219) or keyboard.isKeyDown(56) then
				object.pixels[y][x] = nil	
			else
				object.pixels[y][x] = e5 == 0 and 1 or 0
			end

			application:draw()
		end
	end

	return object
end


local drawingArea = window:addChild(GUI.container(1, 4, 1, 1))
local overrideDraw = drawingArea.draw
drawingArea.draw = function(...)
	GUI.drawShadow(drawingArea.x, drawingArea.y, drawingArea.width, drawingArea.height, GUI.CONTEXT_MENU_SHADOW_TRANSPARENCY, true)
	overrideDraw(...)
end

local function getBrailleChar(a, b, c, d, e, f, g, h)
	return unicode.char(10240 + 128*h + 64*g + 32*f + 16*d + 8*b + 4*e + 2*c + a)
end

local function newNoGUI(width, height)
	drawingArea.width, drawingArea.height = width * 4, height * 4
	
	window.width = math.max(50, drawingArea.width)
	window.height = drawingArea.height + 4

	drawingArea.localX = math.floor(window.width / 2 - drawingArea.width / 2)

	window.backgroundPanel.width = window.width
	window.backgroundPanel.height = window.height

	layout.width = window.backgroundPanel.width
	

	drawingArea:removeChildren()

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
	local container = MineOSInterface.addBackgroundContainer(application, "Create")

	local widthTextBox = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0x666666, 0xEEEEEE, 0x262626, "8", "Width", true))
	widthTextBox.validator = function(text)
		return tonumber(text)
	end

	local heightTextBox = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0x666666, 0xEEEEEE, 0x262626, "4", "Height", true))
	heightTextBox.validator = function(text)
		return tonumber(text)
	end

	container.panel.eventHandler = function(application, object, e1)
		if e1 == "touch" then
			container:remove()

			newNoGUI(tonumber(widthTextBox.text), tonumber(heightTextBox.text))

			application:draw()
		end
	end

	application:draw()
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

newButton.onTouch = function()
	new()
end

saveButton.onTouch = function()
	local filesystemDialog = GUI.addFilesystemDialog(application, true, 50, math.floor(application.height * 0.8), "OK", "Cancel", "Path", "/")
	
	filesystemDialog:setMode(GUI.IO_MODE_SAVE, GUI.IO_MODE_FILE)
	filesystemDialog:addExtensionFilter(".pic")
	filesystemDialog:addExtensionFilter(".braiile")
	
	filesystemDialog.onSubmit = function(path)
		if fs.extension(path) == ".pic" then
			local picture = {drawingArea.width / 4, drawingArea.height / 4, {}, {}, {}, {}}

			local x, y = 1, 1
			for childIndex = 1, #drawingArea.children do
				local background, foreground = drawingArea.children[childIndex].background, drawingArea.children[childIndex].foreground
				
				local brailleArray, transparencyCyka, backgroundCyka, foregroundCyka = fillBrailleArray(drawingArea.children[childIndex].pixels)
				if transparencyCyka then
					if backgroundCyka and foregroundCyka then
						GUI.alert("Пиксель " .. x .. "x" .. y .. " имеет два цвета и прозрачность. Убирай любой из цветов и наслаждайся")
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
		else
			local pizda = {
				width = drawingArea.width / 4,
				height = drawingArea.height / 4,
			}

			for i = 1, #drawingArea.children do
				table.insert(pizda, {
					background = drawingArea.children[i].background,
					foreground = drawingArea.children[i].foreground,
					pixels = drawingArea.children[i].pixels,
				})
			end

			table.toFile(path, pizda, true)
		end
	end

	filesystemDialog:show()
end

openButton.onTouch = function()
	local filesystemDialog = GUI.addFilesystemDialog(application, true, 50, math.floor(application.height * 0.8), "OK", "Cancel", "Path", "/")
	
	filesystemDialog:setMode(GUI.IO_MODE_OPEN, GUI.IO_MODE_FILE)
	filesystemDialog:addExtensionFilter(".braiile")

	filesystemDialog.onSubmit = function(path)
		local pizda = table.fromFile(path)
		drawingArea:removeChildren()

		newNoGUI(pizda.width, pizda.height)

		for i = 1, #drawingArea.children do
			drawingArea.children[i].background = pizda[i].background
			drawingArea.children[i].foreground = pizda[i].foreground
			drawingArea.children[i].pixels = pizda[i].pixels
		end

		application:draw()
	end

	filesystemDialog:show()
end

window.actionButtons.minimize:remove()
window.actionButtons.maximize:remove()


---------------------------------------------------------------------------------------------------------

newNoGUI(8, 4)
application:draw()



