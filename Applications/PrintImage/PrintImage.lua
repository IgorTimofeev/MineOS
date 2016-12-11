
----------------------------------------- Libraries -----------------------------------------

-- package.loaded.windows = nil

local libraries = {
	component = "component",
	computer = "computer",
	unicode = "unicode",
	fs = "filesystem",
	advancedLua = "advancedLua",
	colorlib = "colorlib",
	image = "image",
	doubleBuffering = "doubleBuffering",
	GUI = "GUI",
	windows = "windows",
}

for library in pairs(libraries) do if not _G[library] then _G[library] = require(libraries[library]) end end; libraries = nil

----------------------------------------- cyka -----------------------------------------

if not component.isAvailable("printer3d") then GUI.error("This program requires at least one 3D-printer", {title = {color = 0xFFDB40, text = "Error"}}); return end
local args, options = require("shell").parse(...)
local startImagePath = args[1] == "open" and args[2] or "/MineOS/System/OS/Icons/Steve.pic"
local configPath = "/MineOS/System/PrintImage/Config.cfg"
local panelWidth = 34
local window
local mainImage
local printers
local currentPrinter = 1
local shapeResolutionLimit = 4
local timeDelay = 0.05

----------------------------------------- Config -----------------------------------------

local function save()
	table.toFile(configPath, config)
end

local function load()
	if fs.exists(configPath) then
		config = table.fromFile(configPath)
	else
		config = {
			mainMaterial = "quartz_block_side",
			printName = "My picture",
			showGrid = true,
			floorMode = false,
			frame = {enabled = true, width = 3, material = "planks_spruce"},
			lightEmission = {enabled = false, level = 8}
		}
		save()
	end
end

----------------------------------------- Printer-related cyka -----------------------------------------

local function getPrinters()
	printers = {}
	for address in pairs(component.list("printer3d")) do table.insert(printers, component.proxy(address)) end
end

local function addShapePixel(x, y, color, xPrinterPixel, yPrinterPixel)
	local pixelSize = math.floor(16 / shapeResolutionLimit)
	local xPrinter = x * pixelSize - pixelSize
	local yPrinter = y * pixelSize - pixelSize
	
	if config.floorMode then
		printers[currentPrinter].addShape(xPrinter, 0, yPrinter, xPrinter + pixelSize, 16, yPrinter + pixelSize, config.mainMaterial, false, color)
	else
		if config.frame.enabled then
			local xModifyer1, xModifyer2, yModifyer1, yModifyer2 = 0, 0, 0, 0
			if xPrinterPixel == 1 then xModifyer1 = config.frame.width end
			if xPrinterPixel == mainImage.width then xModifyer2 = -config.frame.width end
			if yPrinterPixel == 1 then yModifyer2 = -config.frame.width end
			if yPrinterPixel == mainImage.height * 2 then yModifyer1 = config.frame.width end
			printers[currentPrinter].addShape(xPrinter + xModifyer1, yPrinter + yModifyer1, 15, xPrinter + pixelSize + xModifyer2, yPrinter + pixelSize + yModifyer2, 16, config.mainMaterial, false, color)
		else
			printers[currentPrinter].addShape(xPrinter, 15, yPrinter, xPrinter + pixelSize, 16, yPrinter + pixelSize, config.mainMaterial, false, color)
		end
	end
end

local function beginPrint()
	buffer.clear(0x0000000, 50)

	local xShape, yShape = 1, 1
	local xShapeCount, yShapeCount = math.ceil(mainImage.width / shapeResolutionLimit), math.ceil(mainImage.height * 2 / shapeResolutionLimit)
	local counter = 0
	while true do
		if printers[currentPrinter].status() == "idle" then
			printers[currentPrinter].reset()
			printers[currentPrinter].setLabel(config.printName)
			printers[currentPrinter].setTooltip("Part " .. xShape .. "x" .. yShape .. " of " .. xShapeCount .. "x" .. yShapeCount)
			if config.lightEmission.enabled then printers[currentPrinter].setLightLevel(config.lightEmission.level) end

			local jReplacer = shapeResolutionLimit
			for j = 1, shapeResolutionLimit / 2 do
				for i = 1, shapeResolutionLimit do
					local xImage = xShape * shapeResolutionLimit - shapeResolutionLimit + i
					local yImage = yShape * (shapeResolutionLimit / 2) - (shapeResolutionLimit / 2) + j

					if xImage <= mainImage.width and yImage <= mainImage.height then
						local background, foreground, alpha, symbol = image.get(mainImage, xImage, yImage)
						if alpha < 0xFF then
							if symbol == " " then foreground = background end
							addShapePixel(i, jReplacer, background, xImage, yImage * 2 - 1)
							addShapePixel(i, jReplacer - 1, foreground, xImage, yImage * 2)
						end

						GUI.progressBar(math.floor(buffer.screen.width / 2 - 25), math.floor(buffer.screen.height / 2), 50, 0x3366CC, 0xFFFFFF, 0xFFFFFF, math.ceil(counter * 100 / (xShapeCount * yShapeCount)), true, true, "Progress: ", "%"):draw()
						buffer.draw()
					-- else
					-- 	error("Printing out of mainImage range")
					end
				end

				jReplacer = jReplacer - 2
			end

			if config.frame.enabled and not config.floorMode then
				local xFrame, yFrame = shapeResolutionLimit * (mainImage.width % shapeResolutionLimit), shapeResolutionLimit * ((mainImage.height * 2) % shapeResolutionLimit)
				xFrame = xShape == xShapeCount and (xFrame == 0 and 16 or xFrame) or 16
				yFrame = yShape == yShapeCount and (yFrame == 0 and 0 or yFrame) or 0

				if xShape == 1 then printers[currentPrinter].addShape(0, yFrame, 14, config.frame.width, 16, 16, config.frame.material) end
				if xShape == xShapeCount then printers[currentPrinter].addShape(xFrame - config.frame.width, yFrame, 14, xFrame, 16, 16, config.frame.material) end

				if yShape == 1 then printers[currentPrinter].addShape(0, 16 - config.frame.width, 14, xFrame, 16, 16, config.frame.material) end
				if yShape == yShapeCount then printers[currentPrinter].addShape(0, yFrame, 14, xFrame, yFrame + config.frame.width, 16, config.frame.material) end
			end

			printers[currentPrinter].commit()

			counter = counter + 1
			xShape = xShape + 1
			if xShape > xShapeCount then xShape = 1; yShape = yShape + 1 end
			if yShape > yShapeCount then break end
		end

		currentPrinter = currentPrinter + 1
		if currentPrinter > #printers then currentPrinter = 1 end
		os.sleep(timeDelay)
	end

	buffer.clear()
	window:draw()
	buffer.draw(true)
end

----------------------------------------- Window-zaluped parasha -----------------------------------------

local function getStatus()
	local xBlocks, yBlocks = math.ceil(mainImage.width / shapeResolutionLimit), math.ceil(mainImage.height * 2 / shapeResolutionLimit)
	window.shadeContainer.statusTextBox.lines = {
		"Image size: " .. mainImage.width .. "x" .. mainImage.height .. " px",
		"Count of printers: " .. #printers,
		"Print result: " .. xBlocks .. "x" .. yBlocks .. " blocks",
		"Total count: " .. xBlocks * yBlocks .. " blocks"
	}
end

local function verticalLine(x, y, height, transparency)
	for i = y, y + height - 1 do
		local background = buffer.get(x, i)
		buffer.set(x, i, background, colorlib.alphaBlend(background, 0xFFFFFF, transparency), "│")
	end
end

local function horizontalLine(x, y, width, transparency)
	for i = x, x + width - 1 do
		local background, foreground, symbol = buffer.get(i, y)
		buffer.set(i, y, background, colorlib.alphaBlend(background, 0xFFFFFF, transparency), symbol == "│" and "┼" or "─")
	end
end

local function drawMainImageObject(object)
	if mainImage then
		local xImage = mainImage.width < buffer.screen.width and math.floor(buffer.screen.width / 2 - mainImage.width / 2) or 1
		local yImage = mainImage.height < buffer.screen.height and math.floor(buffer.screen.height / 2 - mainImage.height / 2) or 1
		buffer.image(xImage, yImage, mainImage)
		GUI.windowShadow(xImage, yImage, mainImage.width, mainImage.height, 50, true)
		if config.showGrid then
			for x = xImage, xImage + mainImage.width - 1, shapeResolutionLimit do verticalLine(x, yImage, mainImage.height, 0xA0) end
			for y = yImage, yImage + mainImage.height - 1, shapeResolutionLimit / 2 do horizontalLine(xImage, y, mainImage.width, 0xA0) end
			buffer.text(1, 1, 0xBBBBBB, "хуй")
		end
	end
end

local function createWindow()
	window = windows.fullScreen()
	window:addPanel(1, 1, window.width, window.height, 0xEEEEEE)
	window:addObject(1, 1, window.width, window.height).draw = drawMainImageObject
	local textBoxesWidth = math.floor(panelWidth * 0.55)
	
	window.shadeContainer = window:addContainer(window.width - panelWidth + 1, 1, panelWidth, window.height)
	window.shadeContainer:addPanel(1, 1, window.shadeContainer.width, window.shadeContainer.height, 0x0000000, 40)
	
	local y = 2
	window.shadeContainer:addLabel(1, y, window.shadeContainer.width, 1, 0xFFFFFF, "Main properties"):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	
	y = y + 2
	window.shadeContainer:addLabel(3, y, window.shadeContainer.width, 1, 0xCCCCCC, "Image path:")
	window.shadeContainer:addInputTextBox(window.shadeContainer.width - textBoxesWidth - 1, y, textBoxesWidth, 1, 0xEEEEEE, 0x555555, 0xEEEEEE, 0x262626, startImagePath, nil, nil, true).validator = function(text)
		if text and fs.exists(text) then
			if unicode.sub(text, -4, -1) == ".pic" then
				mainImage = image.load(text)
				getStatus()
				return true
			else
				GUI.error("File \"" .. text .. "\" is not in .pic format", {title = {color = 0xFFDB40, text = "Error while loading image"}})
			end
		else
			GUI.error("File \"" .. text .. "\" doesn't exists", {title = {color = 0xFFDB40, text = "Error while loading image"}})
		end
	end
	
	y = y + 2
	window.shadeContainer:addLabel(3, y, window.shadeContainer.width, 1, 0xCCCCCC, "Material:")
	local mainMaterialTextBox = window.shadeContainer:addInputTextBox(window.shadeContainer.width - textBoxesWidth - 1, y, textBoxesWidth, 1, 0xEEEEEE, 0x555555, 0xEEEEEE, 0x262626, config.mainMaterial, nil, nil, false)
	mainMaterialTextBox.onInputFinished = function()
		config.mainMaterial = mainMaterialTextBox.text
		save()
	end

	y = y + 2
	window.shadeContainer:addLabel(3, y, window.shadeContainer.width, 1, 0xCCCCCC, "Print name:")
	local printNameTextBox = window.shadeContainer:addInputTextBox(window.shadeContainer.width - textBoxesWidth - 1, y, textBoxesWidth, 1, 0xEEEEEE, 0x555555, 0xEEEEEE, 0x262626, config.printName, nil, nil, false)
	printNameTextBox.onInputFinished = function()
		config.printName = printNameTextBox.text
		save()
	end

	y = y + 2
	window.shadeContainer:addLabel(3, y, window.shadeContainer.width, 1, 0xCCCCCC, "Floor mode:")
	local floorSwitch = window.shadeContainer:addSwitch(window.shadeContainer.width - 9, y, 8, 0xFFDB40, 0xAAAAAA, 0xFFFFFF, config.floorMode)
	floorSwitch.onStateChanged = function()
		config.floorMode = floorSwitch.state
		save()
	end

	y = y + 2
	window.shadeContainer:addLabel(3, y, window.shadeContainer.width, 1, 0xCCCCCC, "Show grid:")
	local gridSwitch = window.shadeContainer:addSwitch(window.shadeContainer.width - 9, y, 8, 0xFFDB40, 0xAAAAAA, 0xFFFFFF, config.showGrid)
	gridSwitch.onStateChanged = function()
		config.showGrid = gridSwitch.state
		save()
		window:draw()
		buffer.draw()
	end
	
	y = y + 4
	window.shadeContainer:addLabel(1, y, window.shadeContainer.width, 1, 0xFFFFFF, "Frame properties"):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	y = y + 2
	window.shadeContainer:addLabel(3, y, window.shadeContainer.width, 1, 0xCCCCCC, "Enabled:")
	local frameSwitch = window.shadeContainer:addSwitch(window.shadeContainer.width - 9, y, 8, 0xFFDB40, 0xAAAAAA, 0xFFFFFF, config.frame.enabled)
	frameSwitch.onStateChanged = function()
		config.frame.enabled = frameSwitch.state
		save()
	end
	y = y + 2
	window.shadeContainer:addLabel(3, y, window.shadeContainer.width, 1, 0xCCCCCC, "Material:")
	local frameMaterialTextBox = window.shadeContainer:addInputTextBox(window.shadeContainer.width - textBoxesWidth - 1, y, textBoxesWidth, 1, 0xEEEEEE, 0x555555, 0xEEEEEE, 0x262626, config.frame.material, nil, nil, false)
	frameMaterialTextBox.onInputFinished = function()
		config.frame.material = frameMaterialTextBox.text
		save()
	end

	y = y + 2
	local frameWidthSlider = window.shadeContainer:addHorizontalSlider(3, y, window.shadeContainer.width - 4, 0xFFDB80, 0x000000, 0xFFDB40, 0xCCCCCC, 1, shapeResolutionLimit - 1, config.frame.width, false, "Width: " , " voxel(s)")
	frameWidthSlider.onValueChanged = function(value)
		config.frame.width = frameWidthSlider.value
		save()
	end
	frameWidthSlider.roundValues = true

	y = y + 5
	window.shadeContainer:addLabel(1, y, window.shadeContainer.width, 1, 0xFFFFFF, "Light emission"):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	y = y + 2
	window.shadeContainer:addLabel(3, y, window.shadeContainer.width, 1, 0xCCCCCC, "Enabled:")
	local lightSwitch = window.shadeContainer:addSwitch(window.shadeContainer.width - 9, y, 8, 0xFFDB40, 0xAAAAAA, 0xFFFFFF, config.lightEmission.enabled)
	lightSwitch.onStateChanged = function()
		config.lightEmission.enabled = true
		save()
	end

	y = y + 2
 	local lightSlider = window.shadeContainer:addHorizontalSlider(3, y, window.shadeContainer.width - 4, 0xFFDB80, 0x000000, 0xFFDB40, 0xCCCCCC, 1, 8, 8, false, "Radius: " , " block(s)")
	lightSlider.roundValues = true
	lightSlider.onValueChanged = function()
		config.lightEmission.value = lightSlider.value
		save()
	end

	y = y + 5
	window.shadeContainer:addLabel(1, y, window.shadeContainer.width, 1, 0xFFFFFF, "Summary information:"):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	y = y + 2
	window.shadeContainer.statusTextBox = window.shadeContainer:addTextBox(3, y, window.shadeContainer.width - 4, 5, nil, 0xCCCCCC, {}, 1):setAlignment(GUI.alignment.horizontal.left, GUI.alignment.vertical.top)

	window.shadeContainer:addButton(1, window.shadeContainer.height - 5, window.shadeContainer.width, 3, 0x363636, 0xFFFFFF, 0xFFFFFF, 0x262626, "Exit").onTouch = function()
		window:close()
	end

	window.shadeContainer:addButton(1, window.shadeContainer.height - 2, window.shadeContainer.width, 3, 0x262626, 0xFFFFFF, 0xFFFFFF, 0x262626, "Start print").onTouch = function()
		beginPrint()
	end

	window.onAnyEvent = function(eventData)
		if (eventData[1] == "component_added" or eventData[1] == "component_removed") and eventData[3] == "printer3d" then
			getPrinters()
			getStatus()
			window:draw()
			buffer.draw()
		end
	end
end

----------------------------------------- Shitty meatball rolls -----------------------------------------

buffer.start()
load()
getPrinters()
createWindow()
mainImage = image.load(startImagePath)
getStatus()
window:draw()
buffer.draw()

window:handleEvents()










