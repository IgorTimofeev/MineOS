
require("advancedLua")
local component = require("component")
local fs = require("filesystem")
local color = require("color")
local image = require("image")
local buffer = require("doubleBuffering")
local GUI = require("GUI")

--------------------------------------------------------------------------------------------------------------

local palette = {}
local pathToFavouritesConfig, favourites = fs.path(getCurrentScript()) .. ".palette.cfg"

local function saveFavourites()
	table.toFile(pathToFavouritesConfig, favourites)
end

--------------------------------------------------------------------------------------------------------------

local function changeInputsValueToCurrentColor(window)
	window.inputs[1].input.text = tostring(window.color.rgb.red)
	window.inputs[2].input.text = tostring(window.color.rgb.green)
	window.inputs[3].input.text = tostring(window.color.rgb.blue)
	window.inputs[4].input.text = tostring(math.floor(window.color.hsb.hue))
	window.inputs[5].input.text = tostring(math.floor(window.color.hsb.saturation))
	window.inputs[6].input.text = tostring(math.floor(window.color.hsb.brightness))
	window.inputs[7].input.text = string.format("%06X", window.color.hex)
	window.colorPanel.colors.background = window.color.hex
end

local function switchColorFromHex(window, hex)
	window.color.hex = hex
	window.color.rgb.red, window.color.rgb.green, window.color.rgb.blue = color.HEXToRGB(hex)
	window.color.hsb.hue, window.color.hsb.saturation, window.color.hsb.brightness = color.RGBToHSB(window.color.rgb.red, window.color.rgb.green, window.color.rgb.blue)
	changeInputsValueToCurrentColor(window)
end

local function switchColorFromHsb(window, hue, saturation, brightness)
	window.color.hsb.hue, window.color.hsb.saturation, window.color.hsb.brightness = hue, saturation, brightness
	window.color.rgb.red, window.color.rgb.green, window.color.rgb.blue = color.HSBToRGB(hue, saturation, brightness)
	window.color.hex = color.RGBToHEX(window.color.rgb.red, window.color.rgb.green, window.color.rgb.blue)
	changeInputsValueToCurrentColor(window)
end

local function switchColorFromRgb(window, red, green, blue)
	window.color.rgb.red, window.color.rgb.green, window.color.rgb.blue = red, green, blue
	window.color.hsb.hue, window.color.hsb.saturation, window.color.hsb.brightness = color.RGBToHSB(red, green, blue)
	window.color.hex = color.RGBToHEX(red, green, blue)
	changeInputsValueToCurrentColor(window)
end

--------------------------------------------------------------------------------------------------------------

local function refreshBigRainbow(window)
	local saturationStep, brightnessStep, saturation, brightness = 100 / image.getWidth(window.bigRainbow.image), 100 / (image.getHeight(window.bigRainbow.image)), 0, 100
	for j = 1, image.getHeight(window.bigRainbow.image) do
		for i = 1, image.getWidth(window.bigRainbow.image) do
			image.set(window.bigRainbow.image, i, j, color.optimize(color.HSBToHEX(window.color.hsb.hue, saturation, brightness)), 0x0, 0x0, " ")
			saturation = saturation + saturationStep
		end
		saturation, brightness = 0, brightness - brightnessStep
	end
end

local function refreshMiniRainbow(window)
	local hueStep, hue = 360 / (image.getHeight(window.miniRainbow.image)), 0
	for j = 1, image.getHeight(window.miniRainbow.image) do
		for i = 1, image.getWidth(window.miniRainbow.image) do
			image.set(window.miniRainbow.image, i, j, color.optimize(color.HSBToHEX(hue, 100, 100)), 0x0, 0x0, " ")
		end
		hue = hue + hueStep
	end
end

--------------------------------------------------------------------------------------------------------------

local function createCrestsCoordinates(window)
	window.bigCrest.localX = math.floor((window.bigRainbow.width - 1) * window.color.hsb.saturation / 100) - 1
	window.bigCrest.localY = math.floor((window.bigRainbow.height - 1) - (window.bigRainbow.height - 1) * window.color.hsb.brightness / 100)
	window.miniCrest.localY = math.floor(window.color.hsb.hue / 360 * window.miniRainbow.height)
end

local function drawBigCrestPixel(window, x, y, symbol)
	if window.bigRainbow:isClicked(x, y) then
		local background, foreground = buffer.get(x, y)
		if background >= 0x888888 then
			foreground = 0x000000
		else
			foreground = 0xFFFFFF
		end
		buffer.set(x, y, background, foreground, symbol)
	end
end

--------------------------------------------------------------------------------------------------------------

function palette.window(x, y, startColor)
	local window = GUI.window(x, y, 71, 25)
	
	window.color = {hsb = {}, rgb = {}}
	window:addChild(GUI.panel(1, 1, window.width, window.height, 0xEEEEEE))
	
	window.bigRainbow = window:addChild(GUI.image(1, 1, image.create(50, 25)))
	window.bigCrest = window:addChild(GUI.object(1, 1, 5, 3))
	window.bigCrest.draw = function(object)
		drawBigCrestPixel(window, object.x, object.y + 1, "─")
		drawBigCrestPixel(window, object.x + 1, object.y + 1, "─")
		drawBigCrestPixel(window, object.x + 3, object.y + 1, "─")
		drawBigCrestPixel(window, object.x + 4, object.y + 1, "─")
		drawBigCrestPixel(window, object.x + 2, object.y, "│")
		drawBigCrestPixel(window, object.x + 2, object.y + 2, "│")
	end
	window.bigRainbow.eventHandler = function(mainContainer, object, eventData)
		if eventData[1] == "touch" or eventData[1] == "drag" and window.bigRainbow:isClicked(eventData[3], eventData[4]) then
			window.bigCrest.localX, window.bigCrest.localY = eventData[3] - window.x - 1, eventData[4] - window.y
			switchColorFromHex(window, select(3, component.gpu.get(eventData[3], eventData[4])))
			mainContainer:draw()
			buffer.draw()
		end
	end
	window.bigCrest.eventHandler = window.bigRainbow.eventHandler
	
	window.miniRainbow = window:addChild(GUI.image(53, 1, image.create(3, 25)))
	window.miniCrest = window:addChild(GUI.object(52, 1, 5, 1))
	window.miniCrest.draw = function(object)
		buffer.text(object.x, object.y, 0x0, ">")
		buffer.text(object.x + 4, object.y, 0x0, "<")
	end
	window.miniRainbow.eventHandler = function(mainContainer, object, eventData)
		if eventData[1] == "touch" or eventData[1] == "drag" then
			window.miniCrest.localY = eventData[4] - window.y + 1
			switchColorFromHsb(window, (eventData[4] - window.miniRainbow.y) * 360 / window.miniRainbow.height, window.color.hsb.saturation, window.color.hsb.brightness)
			refreshBigRainbow(window)
			mainContainer:draw()
			buffer.draw()
		end
	end
	
	window.colorPanel = window:addChild(GUI.panel(58, 2, 12, 3, 0x0))
	window.OKButton = window:addChild(GUI.roundedButton(58, 6, 12, 1, 0x444444, 0xFFFFFF, 0x88FF88, 0xFFFFFF, "OK"))
	window.cancelButton = window:addChild(GUI.roundedButton(58, 8, 12, 1, 0xFFFFFF, 0x444444, 0x88FF88, 0xFFFFFF, "Cancel"))

	local function onAnyInputFinished()
		refreshBigRainbow(window)
		createCrestsCoordinates(window)
		window:getFirstParent():draw()
		buffer.draw()
	end

	local function onHexInputFinished()
		switchColorFromHex(window, tonumber("0x" .. window.inputs[7].input.text))
		onAnyInputFinished()
	end

	local function onRgbInputFinished()
		switchColorFromRgb(window, tonumber(window.inputs[1].input.text), tonumber(window.inputs[2].input.text), tonumber(window.inputs[3].input.text))
		onAnyInputFinished()
	end

	local function onHsbInputFinished()
		switchColorFromHsb(window, tonumber(window.inputs[4].input.text), tonumber(window.inputs[5].input.text), tonumber(window.inputs[6].input.text))
		onAnyInputFinished()
	end

	local function rgbValidaror(text)
		local num = tonumber(text) if num and num >= 0 and num <= 255 then return true end
	end

	local function hValidator(text)
		local num = tonumber(text) if num and num >= 0 and num <= 359 then return true end
	end

	local function sbValidator(text)
		local num = tonumber(text) if num and num >= 0 and num <= 100 then return true end
	end

	local function hexValidator(text)
		if string.match(text, "^[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]$") then
			return true
		end
	end

	window.inputs = {
		{ shortcut = "R:", validator = rgbValidaror, onInputFinished = onRgbInputFinished },
		{ shortcut = "G:", validator = rgbValidaror, onInputFinished = onRgbInputFinished },
		{ shortcut = "B:", validator = rgbValidaror, onInputFinished = onRgbInputFinished },
		{ shortcut = "H:", validator = hValidator,   onInputFinished = onHsbInputFinished },
		{ shortcut = "S:", validator = sbValidator,  onInputFinished = onHsbInputFinished },
		{ shortcut = "L:", validator = sbValidator,  onInputFinished = onHsbInputFinished },
		{ shortcut = "0x", validator = hexValidator, onInputFinished = onHexInputFinished }
	}

	local y = 10
	for i = 1, #window.inputs do
		window:addChild(GUI.label(58, y, 2, 1, 0x000000, window.inputs[i].shortcut))
		
		window.inputs[i].input = window:addChild(GUI.input(61, y, 9, 1, 0xFFFFFF, 0x444444, 0x444444, 0xFFFFFF, 0x000000, "", "", true))
		window.inputs[i].input.validator = window.inputs[i].validator
		window.inputs[i].input.onInputFinished = window.inputs[i].onInputFinished
		
		y = y + 2
	end
	
	if fs.exists(pathToFavouritesConfig) then
		favourites = table.fromFile(pathToFavouritesConfig)
	else
		favourites = {}
		for i = 1, 6 do favourites[i] = math.random(0x000000, 0xFFFFFF) end
		saveFavourites()
	end

	palette.favouritesContainer = window:addChild(GUI.container(58, 24, 12, 1))
	for i = 1, #favourites do
		local button = palette.favouritesContainer:addChild(GUI.button(i * 2 - 1, 1, 2, 1, favourites[i], 0x0, 0x0, 0x0, " "))
		button.onTouch = function(mainContainer, object, eventData)
			switchColorFromHex(window, button.colors.default.background)
			refreshBigRainbow(window)
			createCrestsCoordinates(window)
			mainContainer:draw()
			buffer.draw()
		end
	end
	
	window:addChild(GUI.button(58, 25, 12, 1, 0xFFFFFF, 0x444444, 0x88FF88, 0xFFFFFF, "+")).onTouch = function(mainContainer, object, eventData)
		local favouriteExists = false
		for i = 1, #favourites do
			if favourites[i] == window.color.hex then
				favouriteExists = true
				break
			end
		end
		
		if not favouriteExists then
			table.insert(favourites, 1, window.color.hex)
			table.remove(favourites, #favourites)
			for i = 1, #favourites do
				palette.favouritesContainer.children[i].colors.default.background = favourites[i]
				palette.favouritesContainer.children[i].colors.pressed.background = 0x0
			end
			saveFavourites()
			mainContainer:draw()
			buffer.draw()
		end
	end

	switchColorFromHex(window, startColor)
	createCrestsCoordinates(window)
	refreshBigRainbow(window)
	refreshMiniRainbow(window)

	return window
end

function palette.show(x, y, startColor)
	local mainContainer = GUI.container(1, 1, buffer.width, buffer.height)

	local selectedColor
	local window = mainContainer:addChild(palette.window(x, y, startColor))
	window.eventHandler = nil
	window.OKButton.onTouch = function(mainContainer, object, eventData)
		mainContainer:stopEventHandling()
		selectedColor = window.color.hex
	end
	window.cancelButton.onTouch = function(mainContainer, object, eventData)
		mainContainer:stopEventHandling()
	end

	mainContainer:draw()
	buffer.draw()
	mainContainer:startEventHandling()

	return selectedColor
end

--------------------------------------------------------------------------------------------------------------

-- buffer.start()
-- buffer.draw(true)
-- GUI.error(tostring(palette.show(5, 5, 0xFF00FF)))

--------------------------------------------------------------------------------------------------------------

return palette
