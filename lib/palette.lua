
-- _G.windows, _G.GUI, package.loaded.windows, package.loaded.GUI = nil, nil, nil, nil

local libraries = {
	advancedLua = "advancedLua",
	component = "component",
	fs = "filesystem",
	colorlib = "colorlib",
	image = "image",
	buffer = "doubleBuffering",
	GUI = "GUI",
	windows = "windows",
}

for library in pairs(libraries) do if not _G[library] then _G[library] = require(libraries[library]) end end; libraries = nil

--------------------------------------------------------------------------------------------------------------

local palette = {}
local window
local currentColor, favourites
local xBigCrest, yBigCrest, yMiniCrest
local favouritesContainer, bigRainbow, miniRainbow, currentColorPanel
local pathToFavouritesConfig = "/MineOS/System/Palette/Favourites.cfg"
local inputs

--------------------------------------------------------------------------------------------------------------

local function switchColorFromHex(hex)
	currentColor = {hsb = {}, rgb = {}, hex = hex}
	currentColor.rgb.red, currentColor.rgb.green, currentColor.rgb.blue = colorlib.HEXtoRGB(hex)
	currentColor.hsb.hue, currentColor.hsb.saturation, currentColor.hsb.brightness = colorlib.RGBtoHSB(currentColor.rgb.red, currentColor.rgb.green, currentColor.rgb.blue)
end

local function switchColorFromHsb(hue, saturation, brightness)
	currentColor = {hsb = {hue = hue, saturation = saturation, brightness = brightness}, rgb = {}, hex = nil}
	currentColor.rgb.red, currentColor.rgb.green, currentColor.rgb.blue = colorlib.HSBtoRGB(hue, saturation, brightness)
	currentColor.hex = colorlib.RGBtoHEX(currentColor.rgb.red, currentColor.rgb.green, currentColor.rgb.blue)
end

local function switchColorFromRgb(red, green, blue)
	currentColor = {hsb = {}, rgb = {red = red, green = green, blue = blue}, hex = nil}
	currentColor.hsb.hue, currentColor.hsb.saturation, currentColor.hsb.brightness = colorlib.RGBtoHSB(red, green, blue)
	currentColor.hex = colorlib.RGBtoHEX(red, green, blue)
end

--------------------------------------------------------------------------------------------------------------

local function randomizeFavourites()
	favourites = {}; for i = 1, 6 do favourites[i] = math.random(0x000000, 0xFFFFFF) end
end

local function saveFavoutites()
	table.toFile(pathToFavouritesConfig, favourites)
end

local function loadFavourites()
	if fs.exists(pathToFavouritesConfig) then
		favourites = table.fromFile(pathToFavouritesConfig)
	else
		randomizeFavourites()
		saveFavoutites()
	end
end

--------------------------------------------------------------------------------------------------------------

local function changeInputsValueToCurrentColor()
	inputs[1].object.text = tostring(currentColor.rgb.red)
	inputs[2].object.text = tostring(currentColor.rgb.green)
	inputs[3].object.text = tostring(currentColor.rgb.blue)
	inputs[4].object.text = tostring(math.floor(currentColor.hsb.hue))
	inputs[5].object.text = tostring(math.floor(currentColor.hsb.saturation))
	inputs[6].object.text = tostring(math.floor(currentColor.hsb.brightness))
	inputs[7].object.text = string.format("%06X", currentColor.hex)
end

--------------------------------------------------------------------------------------------------------------

local function refreshBigRainbow(width, height)
	local picture = image.create(width, height, 0x0, 0x0, 0x0, " ")
	local saturationStep, brightnessStep, saturation, brightness = 100 / width, 100 / height, 0, 100
	for j = 1, height do
		for i = 1, width do
			image.set(picture, i, j, colorlib.HSBtoHEX(currentColor.hsb.hue, saturation, brightness), 0x0, 0x0, " ")
			saturation = saturation + saturationStep
		end
		saturation = 0; brightness = brightness - brightnessStep
	end
	return picture
end

local function refreshMiniRainbow(width, height)
	local picture = image.create(width, height, 0x0, 0x0, 0x0, " ")
	local hueStep, hue = 360 / height, 0
	for j = 1, height do
		for i = 1, width do
			image.set(picture, i, j, colorlib.HSBtoHEX(hue, 100, 100), 0x0, 0x0, " ")
		end
		hue = hue + hueStep
	end
	return picture
end

local function refreshRainbows()
	bigRainbow.image = refreshBigRainbow(50, 25)
	miniRainbow.image = refreshMiniRainbow(3, 25)
end

local function betterVisiblePixel(x, y, symbol)
	local background, foreground = buffer.get(x, y)
	if background > 0x888888 then foreground = 0x000000 else foreground = 0xFFFFFF end
	buffer.set(x, y, background, foreground, symbol)
end

local function drawBigCrest()
	local drawLimit = buffer.getDrawLimit(); buffer.setDrawLimit(window.x, window.y, bigRainbow.width + 2, bigRainbow.height)
	betterVisiblePixel(xBigCrest - 2, yBigCrest, "─")
	betterVisiblePixel(xBigCrest - 1, yBigCrest, "─")
	betterVisiblePixel(xBigCrest + 1, yBigCrest, "─")
	betterVisiblePixel(xBigCrest + 2, yBigCrest, "─")
	betterVisiblePixel(xBigCrest, yBigCrest - 1, "│")
	betterVisiblePixel(xBigCrest, yBigCrest + 1, "│")
	buffer.setDrawLimit(drawLimit)
end

local function drawMiniCrest()
	buffer.text(miniRainbow.x - 1, yMiniCrest, 0x000000, ">")
	buffer.text(miniRainbow.x + miniRainbow.width, yMiniCrest, 0x000000, "<")
end

local function drawCrests()
	drawBigCrest()
	drawMiniCrest()
end

local function drawAll()
	currentColorPanel.colors.background = currentColor.hex
	changeInputsValueToCurrentColor()
	window:draw()
	drawCrests()
	buffer.draw()
end

--------------------------------------------------------------------------------------------------------------

local function createCrestsCoordinates()
	local xBigCrestModifyer = (bigRainbow.width - 1) * currentColor.hsb.saturation / 100
	local yBigCrestModifyer = (bigRainbow.height - 1) - (bigRainbow.height - 1) * currentColor.hsb.brightness / 100
	local yMiniCrestModifyer = (miniRainbow.height - 1) - (miniRainbow.height - 1) * currentColor.hsb.hue / 360
	
	xBigCrest, yBigCrest, yMiniCrest = math.floor(window.x + xBigCrestModifyer), math.floor(window.y + yBigCrestModifyer), math.floor(window.y + yMiniCrestModifyer)
end

local function createInputs(x, y)
	local function onAnyInputFinished() refreshRainbows(); createCrestsCoordinates(); drawAll() end
	local function onHexInputFinished(object) switchColorFromHex(tonumber("0x" .. inputs[7].object.text)); onAnyInputFinished() end
	local function onRgbInputFinished(object) switchColorFromRgb(tonumber(inputs[1].object.text), tonumber(inputs[2].object.text), tonumber(inputs[3].object.text)); onAnyInputFinished() end
	local function onHsbInputFinished(object) switchColorFromHsb(tonumber(inputs[4].object.text), tonumber(inputs[5].object.text), tonumber(inputs[6].object.text)); onAnyInputFinished() end

	local function rgbValidaror(text) local num = tonumber(text) if num and num >= 0 and num <= 255 then return true end end
	local function hValidator(text) local num = tonumber(text) if num and num >= 0 and num <= 359 then return true end end
	local function sbValidator(text) local num = tonumber(text) if num and num >= 0 and num <= 100 then return true end end
	local function hexValidator(text) if string.match(text, "^[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]$") then return true end end

	inputs = {
		{ shortcut = "R:", arrayName = "red",        validator = rgbValidaror, onInputFinished = onRgbInputFinished },
		{ shortcut = "G:", arrayName = "green",      validator = rgbValidaror, onInputFinished = onRgbInputFinished },
		{ shortcut = "B:", arrayName = "blue",       validator = rgbValidaror, onInputFinished = onRgbInputFinished },
		{ shortcut = "H:", arrayName = "hue",        validator = hValidator,   onInputFinished = onHsbInputFinished },
		{ shortcut = "S:", arrayName = "saturation", validator = sbValidator,  onInputFinished = onHsbInputFinished },
		{ shortcut = "L:", arrayName = "brightness", validator = sbValidator,  onInputFinished = onHsbInputFinished },
		{ shortcut = "0x", arrayName = "red",        validator = hexValidator, onInputFinished = onHexInputFinished }
	}

	for i = 1, #inputs do
		window:addLabel("inputShortcut" .. i, x, y, 2, 1, 0x000000, inputs[i].shortcut)
		inputs[i].object = window:addInputTextBox("inputObject" .. i, x + 3, y, 9, 1, 0xFFFFFF, 0x444444, 0xFFFFFF, 0x000000, "", nil, nil, true)
		inputs[i].object.validator = inputs[i].validator
		inputs[i].object.onInputFinished = inputs[i].onInputFinished
		y = y + 2
	end

	return y
end

local function createFavourites()
	local function onFavouriteClicked(button) switchColorFromHex(button.colors.default.background); refreshRainbows(); createCrestsCoordinates(); drawAll() end
	for i = 1, #favourites do favouritesContainer:addButton("favourite" .. i, i * 2 - 1, 1, 2, 1, favourites[i], 0x0, 0x0, 0x0, " ").onTouch = onFavouriteClicked end
end

local function createWindow(x, y)
	window = windows.empty(x, y, 71, 25, 71, 25)
	
	x, y = 1, 1
	window:addPanel("backgroundPanel", x, y, window.width, window.height, 0xEEEEEE)
	
	bigRainbow = window:addImage("bigRainbow", x, y, image.create(50, 25))
	bigRainbow.onTouch = function(eventData)
		xBigCrest, yBigCrest = eventData[3], eventData[4]
		local _, _, background = component.gpu.get(eventData[3], eventData[4])
		switchColorFromHex(background)
		drawAll()
	end
	bigRainbow.onDrag = bigRainbow.onTouch

	x = x + bigRainbow.width + 2
	
	miniRainbow = window:addImage("miniRainbow", x, y, image.create(3, 25))
	miniRainbow.onTouch = function(eventData)
		yMiniCrest = eventData[4]
		switchColorFromHsb((eventData[4] - miniRainbow.y) * 360 / miniRainbow.height, currentColor.hsb.saturation, currentColor.hsb.brightness)
		refreshRainbows()
		drawAll()
	end
	miniRainbow.onDrag = miniRainbow.onTouch
	x, y = x + 5, y + 1
	
	currentColorPanel = window:addPanel("currentColorPanel", x, y, 12, 3, currentColor.hex)
	y = y + 4
	
	window:addButton("okButton", x, y, 12, 1, 0x444444, 0xFFFFFF, 0x88FF88, 0xFFFFFF, "OK").onTouch = function()
		window:returnData(currentColor.hex)
	end
	y = y + 2
	
	window:addButton("cancelButton", x, y, 12, 1, 0xFFFFFF, 0x444444, 0x88FF88, 0xFFFFFF, "Cancel").onTouch = function()
		window:close()
	end
	y = y + 2

	y = createInputs(x, y)
	
	favouritesContainer = window:addContainer("favouritesContainer", x, y, 12, 1)
	createFavourites()
	y = y + 1
	
	window:addButton("favouritesAddButton", x, y, 12, 1, 0xFFFFFF, 0x444444, 0x88FF88, 0xFFFFFF, "+").onTouch = function()
		local favouriteExists = false; for i = 1, #favourites do if favourites[i] == currentColor.hex then favouriteExists = true; break end end
		if not favouriteExists then
			table.insert(favourites, 1, currentColor.hex); table.remove(favourites, #favourites)
			for i = 1, #favourites do favouritesContainer.children[i].colors.default.background = favourites[i]; favouritesContainer.children[i].colors.pressed.background = 0x0 end
			saveFavoutites()
			drawAll()
		end
	end

	window.onDrawFinished = function()
		drawCrests()
		buffer.draw()
	end

	window.onKeyDown = function(eventData)
		if eventData[4] == 28 then
			window.okButton:press()
			drawAll()
			window:returnData(currentColor.hex)
		end
	end
end

--------------------------------------------------------------------------------------------------------------

function palette.show(x, y, startColor)
	loadFavourites()
	switchColorFromHex(startColor or 0x00B6FF)
	createWindow(x, y)
	createCrestsCoordinates()

	refreshRainbows()
	window.drawShadow = true
	drawAll()
	window.drawShadow = false

	return window:handleEvents()
end

-- Поддержим олдфагов!
palette.draw = palette.show

--------------------------------------------------------------------------------------------------------------

-- ecs.error(palette.show("auto", "auto", 0xFF5555))

--------------------------------------------------------------------------------------------------------------

return palette
