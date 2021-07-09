
----------------------------------------- Libraries -----------------------------------------

local filesystem = require("Filesystem")
local color = require("Color")
local image = require("Image")
local screen = require("Screen")
local GUI = require("GUI")
local paths = require("Paths")
local system = require("System")
local event = require("Event")

----------------------------------------- cyka -----------------------------------------

if not component.isAvailable("printer3d") then
	GUI.alert("This program requires at least one 3D-printer")
	return
end

local args, options = system.parseArguments(...)

local startImagePath = args[1] == "open" and args[2] or paths.system.icons .. "Folder.pic"
local configPath = paths.user.applicationData .. "PrintImage/Config.cfg"
local panelWidth = 34
local application
local mainImage
local printers
local currentPrinter = 1
local shapeResolutionLimit = 4
local timeDelay = 0.05

----------------------------------------- Config -----------------------------------------

local function save()
	filesystem.writeTable(configPath, config)
end

local function load()
	if filesystem.exists(configPath) then
		config = filesystem.readTable(configPath)
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
			if xPrinterPixel == image.getWidth(mainImage) then xModifyer2 = -config.frame.width end
			if yPrinterPixel == 1 then yModifyer2 = -config.frame.width end
			if yPrinterPixel == image.getHeight(mainImage) * 2 then yModifyer1 = config.frame.width end
			printers[currentPrinter].addShape(xPrinter + xModifyer1, yPrinter + yModifyer1, 15, xPrinter + pixelSize + xModifyer2, yPrinter + pixelSize + yModifyer2, 16, config.mainMaterial, false, color)
		else
			printers[currentPrinter].addShape(xPrinter, 15, yPrinter, xPrinter + pixelSize, 16, yPrinter + pixelSize, config.mainMaterial, false, color)
		end
	end
end

local function beginPrint()
	screen.clear(0x0000000, 50)

	local xShape, yShape = 1, 1
	local xShapeCount, yShapeCount = math.ceil(image.getWidth(mainImage) / shapeResolutionLimit), math.ceil(image.getHeight(mainImage) * 2 / shapeResolutionLimit)
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

					if xImage <= image.getWidth(mainImage) and yImage <= image.getHeight(mainImage) then
						local background, foreground, alpha, symbol = image.get(mainImage, xImage, yImage)
						if alpha < 0xFF then
							if symbol == " " then foreground = background end
							addShapePixel(i, jReplacer, background, xImage, yImage * 2 - 1)
							addShapePixel(i, jReplacer - 1, foreground, xImage, yImage * 2)
						end

						GUI.progressBar(math.floor(screen.getWidth() / 2 - 25), math.floor(screen.getHeight() / 2), 50, 0x3366CC, 0xFFFFFF, 0xFFFFFF, math.ceil(counter * 100 / (xShapeCount * yShapeCount)), true, true, "Progress: ", "%"):draw()
						screen.update()
					-- else
					-- 	error("Printing out of mainImage range")
					end
				end

				jReplacer = jReplacer - 2
			end

			if config.frame.enabled and not config.floorMode then
				local xFrame, yFrame = shapeResolutionLimit * (image.getWidth(mainImage) % shapeResolutionLimit), shapeResolutionLimit * ((image.getHeight(mainImage) * 2) % shapeResolutionLimit)
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
		event.sleep(timeDelay)
	end

	screen.clear()
	workspace:draw()
end

----------------------------------------- Window-zaluped parasha -----------------------------------------

local function getStatus()
	local xBlocks, yBlocks = math.ceil(image.getWidth(mainImage) / shapeResolutionLimit), math.ceil(image.getHeight(mainImage) * 2 / shapeResolutionLimit)
	workspace.shadeContainer.statusTextBox.lines = {
		"Image size: " .. image.getWidth(mainImage) .. "x" .. image.getHeight(mainImage) .. " px",
		"Count of printers: " .. #printers,
		"Print result: " .. xBlocks .. "x" .. yBlocks .. " blocks",
		"Total count: " .. xBlocks * yBlocks .. " blocks"
	}
end

local function verticalLine(x, y, height, transparency)
	for i = y, y + height - 1 do
		local background = screen.get(x, i)
		screen.set(x, i, background, color.blend(background, 0xFFFFFF, transparency), "│")
	end
end

local function horizontalLine(x, y, width, transparency)
	for i = x, x + width - 1 do
		local background, foreground, symbol = screen.get(i, y)
		screen.set(i, y, background, color.blend(background, 0xFFFFFF, transparency), symbol == "│" and "┼" or "─")
	end
end

local function drawMainImageObject(object)
	if mainImage then
		local xImage = image.getWidth(mainImage) < screen.getWidth() and math.floor(screen.getWidth() / 2 - image.getWidth(mainImage) / 2) or 1
		local yImage = image.getHeight(mainImage) < screen.getHeight() and math.floor(screen.getHeight() / 2 - image.getHeight(mainImage) / 2) or 1
		screen.drawImage(xImage, yImage, mainImage)
		GUI.drawShadow(xImage, yImage, image.getWidth(mainImage), image.getHeight(mainImage), 50, true)
		if config.showGrid then
			for x = xImage, xImage + image.getWidth(mainImage) - 1, shapeResolutionLimit do verticalLine(x, yImage, image.getHeight(mainImage), 0.627) end
			for y = yImage, yImage + image.getHeight(mainImage) - 1, shapeResolutionLimit / 2 do horizontalLine(xImage, y, image.getWidth(mainImage), 0.627) end
			screen.drawText(1, 1, 0xBBBBBB, "хуй")
		end
	end
end

local function createWindow()
	workspace = GUI.workspace()
	workspace:addChild(GUI.panel(1, 1, workspace.width, workspace.height, 0xEEEEEE))
	workspace:addChild(GUI.object(1, 1, workspace.width, workspace.height)).draw = drawMainImageObject
	local textBoxesWidth = math.floor(panelWidth * 0.55)
	
	workspace.shadeContainer = workspace:addChild(GUI.container(workspace.width - panelWidth + 1, 1, panelWidth, workspace.height))
	workspace.shadeContainer:addChild(GUI.panel(1, 1, workspace.shadeContainer.width, workspace.shadeContainer.height, 0x0000000, 0.4))
	
	local y = 2
	workspace.shadeContainer:addChild(GUI.label(1, y, workspace.shadeContainer.width, 1, 0xFFFFFF, "Main properties")):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
	
	y = y + 2
	workspace.shadeContainer:addChild(GUI.label(3, y, workspace.shadeContainer.width, 1, 0xCCCCCC, "Image path:"))
	local filesystemChooser = workspace.shadeContainer:addChild(GUI.filesystemChooser(workspace.shadeContainer.width - textBoxesWidth - 1, y, textBoxesWidth, 1, 0xEEEEEE, 0x262626, 0x444444, 0x999999, startImagePath, "Open", "Cancel", "Image path", "/"))
	filesystemChooser:addExtensionFilter(".pic")
	filesystemChooser.onSubmit = function(path)
		mainImage = image.load(path)
		getStatus()
		workspace:draw()
	end

	y = y + 2
	workspace.shadeContainer:addChild(GUI.label(3, y, workspace.shadeContainer.width, 1, 0xCCCCCC, "Material:"))
	local mainMaterialTextBox = workspace.shadeContainer:addChild(GUI.input(workspace.shadeContainer.width - textBoxesWidth - 1, y, textBoxesWidth, 1, 0xEEEEEE, 0x555555, 0x555555, 0xEEEEEE, 0x262626, config.mainMaterial, nil, false))
	mainMaterialTextBox.onInputFinished = function()
		config.mainMaterial = mainMaterialTextBox.text
		save()
	end

	y = y + 2
	workspace.shadeContainer:addChild(GUI.label(3, y, workspace.shadeContainer.width, 1, 0xCCCCCC, "Print name:"))
	local printNameTextBox = workspace.shadeContainer:addChild(GUI.input(workspace.shadeContainer.width - textBoxesWidth - 1, y, textBoxesWidth, 1, 0xEEEEEE, 0x555555, 0x555555, 0xEEEEEE, 0x262626, config.printName, nil, false))
	printNameTextBox.onInputFinished = function()
		config.printName = printNameTextBox.text
		save()
	end

	y = y + 2
	workspace.shadeContainer:addChild(GUI.label(3, y, workspace.shadeContainer.width, 1, 0xCCCCCC, "Floor mode:"))
	local floorSwitch = workspace.shadeContainer:addChild(GUI.switch(workspace.shadeContainer.width - 9, y, 8, 0xFFDB40, 0xAAAAAA, 0xFFFFFF, config.floorMode))
	floorSwitch.onStateChanged = function()
		config.floorMode = floorSwitch.state
		save()
	end

	y = y + 2
	workspace.shadeContainer:addChild(GUI.label(3, y, workspace.shadeContainer.width, 1, 0xCCCCCC, "Show grid:"))
	local gridSwitch = workspace.shadeContainer:addChild(GUI.switch(workspace.shadeContainer.width - 9, y, 8, 0xFFDB40, 0xAAAAAA, 0xFFFFFF, config.showGrid))
	gridSwitch.onStateChanged = function()
		config.showGrid = gridSwitch.state
		save()
		workspace:draw()
	end
	
	y = y + 4
	workspace.shadeContainer:addChild(GUI.label(1, y, workspace.shadeContainer.width, 1, 0xFFFFFF, "Frame properties")):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
	y = y + 2
	workspace.shadeContainer:addChild(GUI.label(3, y, workspace.shadeContainer.width, 1, 0xCCCCCC, "Enabled:"))
	local frameSwitch = workspace.shadeContainer:addChild(GUI.switch(workspace.shadeContainer.width - 9, y, 8, 0xFFDB40, 0xAAAAAA, 0xFFFFFF, config.frame.enabled))
	frameSwitch.onStateChanged = function()
		config.frame.enabled = frameSwitch.state
		save()
	end
	y = y + 2
	workspace.shadeContainer:addChild(GUI.label(3, y, workspace.shadeContainer.width, 1, 0xCCCCCC, "Material:"))
	local frameMaterialTextBox = workspace.shadeContainer:addChild(GUI.input(workspace.shadeContainer.width - textBoxesWidth - 1, y, textBoxesWidth, 1, 0xEEEEEE, 0x555555, 0x555555, 0xEEEEEE, 0x262626, config.frame.material, nil, false))
	frameMaterialTextBox.onInputFinished = function()
		config.frame.material = frameMaterialTextBox.text
		save()
	end

	y = y + 2
	local frameWidthSlider = workspace.shadeContainer:addChild(GUI.slider(3, y, workspace.shadeContainer.width - 4, 0xFFDB80, 0x000000, 0xFFDB40, 0xCCCCCC, 1, shapeResolutionLimit - 1, config.frame.width, false, "Width: " , " voxel(s)"))
	frameWidthSlider.onValueChanged = function()
		config.frame.width = frameWidthSlider.value
		save()
	end
	frameWidthSlider.roundValues = true

	y = y + 5
	workspace.shadeContainer:addChild(GUI.label(1, y, workspace.shadeContainer.width, 1, 0xFFFFFF, "Light emission")):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
	y = y + 2
	workspace.shadeContainer:addChild(GUI.label(3, y, workspace.shadeContainer.width, 1, 0xCCCCCC, "Enabled:"))
	local lightSwitch = workspace.shadeContainer:addChild(GUI.switch(workspace.shadeContainer.width - 9, y, 8, 0xFFDB40, 0xAAAAAA, 0xFFFFFF, config.lightEmission.enabled))
	lightSwitch.onStateChanged = function()
		config.lightEmission.enabled = true
		save()
	end

	y = y + 2
 	local lightSlider = workspace.shadeContainer:addChild(GUI.slider(3, y, workspace.shadeContainer.width - 4, 0xFFDB80, 0x000000, 0xFFDB40, 0xCCCCCC, 1, 8, 8, false, "Radius: " , " block(s)"))
	lightSlider.roundValues = true
	lightSlider.onValueChanged = function()
		config.lightEmission.value = lightSlider.value
		save()
	end

	y = y + 5
	workspace.shadeContainer:addChild(GUI.label(1, y, workspace.shadeContainer.width, 1, 0xFFFFFF, "Summary information:")):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
	y = y + 2
	workspace.shadeContainer.statusTextBox = workspace.shadeContainer:addChild(GUI.textBox(3, y, workspace.shadeContainer.width - 4, 5, nil, 0xCCCCCC, {}, 1)):setAlignment(GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_TOP)

	workspace.shadeContainer:addChild(GUI.button(1, workspace.shadeContainer.height - 5, workspace.shadeContainer.width, 3, 0x363636, 0xFFFFFF, 0xFFFFFF, 0x262626, "Exit")).onTouch = function()
		workspace:stop()
	end

	workspace.shadeContainer:addChild(GUI.button(1, workspace.shadeContainer.height - 2, workspace.shadeContainer.width, 3, 0x262626, 0xFFFFFF, 0xFFFFFF, 0x262626, "Start print")).onTouch = function()
		beginPrint()
	end

	workspace.eventHandler = function(workspace, object, e1, e2, e3)
		if (e1 == "component_added" or e1 == "component_removed") and e3 == "printer3d" then
			getPrinters()
			getStatus()
			workspace:draw()
		end
	end
end

----------------------------------------- Shitty meatball rolls -----------------------------------------

screen.flush()
load()
getPrinters()
createWindow()
mainImage = image.load(startImagePath)
getStatus()

workspace:draw()
workspace:start()
