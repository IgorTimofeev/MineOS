
----------------------------------------- Libraries -----------------------------------------

package.loaded.windows = nil

local libraries = {
	component = "component",
	computer = "computer",
	unicode = "unicode",
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
local window
local mainImage
local startImagePath = args[1] == "open" and args[2] or "/MineOS/System/OS/Icons/Steve.pic"
local printers
local currentPrinter = 1
local shapeResolutionLimit = 4
-- local shapeResolutionLimit = math.floor(math.sqrt(printers[currentPrinter].getMaxShapeCount()))

local showGrid = true
local floorMode = false
local emitLight = false
local frameEnabled = true

local frameWidthSlider

----------------------------------------- pidor -----------------------------------------

local function getPrinters()
	printers = {}
	for address in pairs(component.list("printer3d")) do table.insert(printers, component.proxy(address)) end
end

local function addShapePixel(x, y, color, xPrinterPixel, yPrinterPixel)
	local pixelSize = math.floor(16 / shapeResolutionLimit)
	local xPrinter = x * pixelSize - pixelSize
	local yPrinter = y * pixelSize - pixelSize
	
	if floorMode then
		printers[currentPrinter].addShape(xPrinter, 0, yPrinter, xPrinter + pixelSize, 16, yPrinter + pixelSize, window.shadeContainer.mainMaterial.text, false, color)
	else
		if frameEnabled then
			local xModifyer1, xModifyer2, yModifyer1, yModifyer2 = 0, 0, 0, 0
			if xPrinterPixel == 1 then xModifyer1 = frameWidthSlider.value end
			if xPrinterPixel == mainImage.width then xModifyer2 = -frameWidthSlider.value end
			if yPrinterPixel == 1 then yModifyer2 = -frameWidthSlider.value end
			if yPrinterPixel == mainImage.height * 2 then yModifyer1 = frameWidthSlider.value end
			printers[currentPrinter].addShape(xPrinter + xModifyer1, yPrinter + yModifyer1, 15, xPrinter + pixelSize + xModifyer2, yPrinter + pixelSize + yModifyer2, 16, window.shadeContainer.mainMaterial.text, false, color)
		else
			printers[currentPrinter].addShape(xPrinter, 15, yPrinter, xPrinter + pixelSize, 16, yPrinter + pixelSize, window.shadeContainer.mainMaterial.text, false, color)
		end
	end
end

local function beginPrint()
	buffer.clear(0x0000000, 50)

	local material = window.shadeContainer.frameMaterial.text
	local xShape, yShape = 1, 1
	local xShapeCount, yShapeCount = math.ceil(mainImage.width / shapeResolutionLimit), math.ceil(mainImage.height * 2 / shapeResolutionLimit)
	local counter = 0
	while true do
		if printers[currentPrinter].status() == "idle" then
			printers[currentPrinter].reset()
			printers[currentPrinter].setLabel(fs.name(window.shadeContainer.imagePath.text))
			printers[currentPrinter].setTooltip("Part " .. xShape .. "x" .. yShape .. " of " .. xShapeCount .. "x" .. yShapeCount)
			if emitLight then printers[currentPrinter].setLightLevel(window.shadeContainer.lightSlider.value) end

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

			if frameEnabled and not floorMode then
				local xFrame, yFrame = shapeResolutionLimit * (mainImage.width % shapeResolutionLimit), shapeResolutionLimit * ((mainImage.height * 2) % shapeResolutionLimit)
				xFrame = xShape == xShapeCount and (xFrame == 0 and 16 or xFrame) or 16
				yFrame = yShape == yShapeCount and (yFrame == 0 and 0 or yFrame) or 0

				if xShape == 1 then printers[currentPrinter].addShape(0, yFrame, 14, frameWidthSlider.value, 16, 16, material) end
				if xShape == xShapeCount then printers[currentPrinter].addShape(xFrame - frameWidthSlider.value, yFrame, 14, xFrame, 16, 16, material) end

				if yShape == 1 then printers[currentPrinter].addShape(0, 16 - frameWidthSlider.value, 14, xFrame, 16, 16, material) end
				if yShape == yShapeCount then printers[currentPrinter].addShape(0, yFrame, 14, xFrame, yFrame + frameWidthSlider.value, 16, material) end
			end

			printers[currentPrinter].commit()

			counter = counter + 1
			xShape = xShape + 1
			if xShape > xShapeCount then xShape = 1; yShape = yShape + 1 end
			if yShape > yShapeCount then break end
		end

		currentPrinter = currentPrinter + 1
		if currentPrinter > #printers then currentPrinter = 1 end
		os.sleep(0.1)
	end

	buffer.clear()
	window:draw()
	buffer.draw(true)
end

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
		if showGrid then
			for x = xImage, xImage + mainImage.width - 1, shapeResolutionLimit do verticalLine(x, yImage, mainImage.height, 0xA0) end
			for y = yImage, yImage + mainImage.height - 1, shapeResolutionLimit / 2 do horizontalLine(xImage, y, mainImage.width, 0xA0) end
			buffer.text(1, 1, 0xBBBBBB, "хуй")
		end
	end
end

local function createWindow()
	window = windows.fullScreen()
	window:addPanel("backgroundPanel", 1, 1, window.width, window.height, 0xEEEEEE)
	window:addObject("mainImageObject", 1, 1, window.width, window.height).draw = drawMainImageObject
	local panelWidth = 34
	local textBoxesWidth = math.floor(panelWidth * 0.55)
	
	local shadeContainer = window:addContainer("shadeContainer", window.width - panelWidth + 1, 1, panelWidth, window.height)
	shadeContainer:addPanel("shadePanel", 1, 1, shadeContainer.width, shadeContainer.height, 0x0000000, 40)
	
	local y = 2
	shadeContainer:addLabel("label", 1, y, shadeContainer.width, 1, 0xFFFFFF, "Main properties"):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	
	y = y + 2
	shadeContainer:addLabel("imagePathLabel", 3, y, shadeContainer.width, 1, 0xCCCCCC, "Image path:")
	shadeContainer:addInputTextBox("imagePath", shadeContainer.width - textBoxesWidth - 1, y, textBoxesWidth, 1, 0xEEEEEE, 0x555555, 0xEEEEEE, 0x262626, startImagePath, nil, nil, true).validator = function(text)
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
	shadeContainer:addLabel("mainMaterialLabel", 3, y, shadeContainer.width, 1, 0xCCCCCC, "Material:")
	shadeContainer:addInputTextBox("mainMaterial", shadeContainer.width - textBoxesWidth - 1, y, textBoxesWidth, 1, 0xEEEEEE, 0x555555, 0xEEEEEE, 0x262626, "quartz_block_side", nil, nil, true).validator = function(text)

	end

	y = y + 2
	shadeContainer:addLabel("label", 3, y, shadeContainer.width, 1, 0xCCCCCC, "Floor mode:")
	local floorSwitch = shadeContainer:addSwitch("floorSwitch", shadeContainer.width - 9, y, 8, 0xFFDB40, 0xAAAAAA, 0xFFFFFF, floorMode)
	floorSwitch.onStateChanged = function()
		floorMode = floorSwitch.state
	end

	y = y + 2
	shadeContainer:addLabel("label", 3, y, shadeContainer.width, 1, 0xCCCCCC, "Show grid:")
	local gridSwitch = shadeContainer:addSwitch("gridSwitch", shadeContainer.width - 9, y, 8, 0xFFDB40, 0xAAAAAA, 0xFFFFFF, showGrid)
	gridSwitch.onStateChanged = function()
		showGrid = gridSwitch.state
		window:draw()
	end
	
	y = y + 4
	shadeContainer:addLabel("label", 1, y, shadeContainer.width, 1, 0xFFFFFF, "Frame properties"):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	y = y + 2
	shadeContainer:addLabel("label", 3, y, shadeContainer.width, 1, 0xCCCCCC, "Enabled:")
	local frameSwitch = shadeContainer:addSwitch("frameSwitch", shadeContainer.width - 9, y, 8, 0xFFDB40, 0xAAAAAA, 0xFFFFFF, frameEnabled)
	frameSwitch.onStateChanged = function()
		frameEnabled = frameSwitch.state
	end
	y = y + 2
	shadeContainer:addLabel("frameMaterialLabel", 3, y, shadeContainer.width, 1, 0xCCCCCC, "Material:")
	shadeContainer:addInputTextBox("frameMaterial", shadeContainer.width - textBoxesWidth - 1, y, textBoxesWidth, 1, 0xEEEEEE, 0x555555, 0xEEEEEE, 0x262626, "planks_spruce", nil, nil, true)
	y = y + 2
	frameWidthSlider = shadeContainer:addHorizontalSlider("frameWidthSlider", 3, y, shadeContainer.width - 4, 0xFFDB80, 0x000000, 0xFFDB40, 0xCCCCCC, 1, shapeResolutionLimit - 1, 1, false, "Width: " , " voxel(s)")
	frameWidthSlider.roundValues = true

	y = y + 5
	shadeContainer:addLabel("label", 1, y, shadeContainer.width, 1, 0xFFFFFF, "Light emission"):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	y = y + 2
	shadeContainer:addLabel("label", 3, y, shadeContainer.width, 1, 0xCCCCCC, "Enabled:")
	local lightSwitch = shadeContainer:addSwitch("lightSwitch", shadeContainer.width - 9, y, 8, 0xFFDB40, 0xAAAAAA, 0xFFFFFF, emitLight)
	lightSwitch.onStateChanged = function()
		emitLight = lightSwitch.state
	end

	y = y + 2
 	local lightSlider = shadeContainer:addHorizontalSlider("lightSlider", 3, y, shadeContainer.width - 4, 0xFFDB80, 0x000000, 0xFFDB40, 0xCCCCCC, 1, 8, 8, false, "Radius: " , " block(s)")
	lightSlider.roundValues = true

	y = y + 5
	shadeContainer:addLabel("label", 1, y, shadeContainer.width, 1, 0xFFFFFF, "Summary information:"):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	y = y + 2
	shadeContainer:addTextBox("statusTextBox", 3, y, shadeContainer.width - 4, 5, nil, 0xCCCCCC, {}, 1):setAlignment(GUI.alignment.horizontal.left, GUI.alignment.vertical.top)

	shadeContainer:addButton("printButton", 1, shadeContainer.height - 5, shadeContainer.width, 3, 0x363636, 0xFFFFFF, 0xFFFFFF, 0x262626, "Exit").onTouch = function()
		window:close()
	end

	shadeContainer:addButton("printButton", 1, shadeContainer.height - 2, shadeContainer.width, 3, 0x262626, 0xFFFFFF, 0xFFFFFF, 0x262626, "Start print").onTouch = function()
		beginPrint()
	end
end

----------------------------------------- Program -----------------------------------------

buffer.start()
getPrinters()
createWindow()
mainImage = image.load(startImagePath)
getStatus()
window:draw()

window:handleEvents()




