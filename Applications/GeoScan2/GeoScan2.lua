
local component = require("component")
local color = require("color")
local image = require("image")
local buffer = require("doubleBuffering")
local GUI = require("GUI")
local MineOSCore = require("MineOSCore")

--------------------------------------------------------------------------------------------------------------------

if not component.isAvailable("geolyzer") then
	GUI.error("This program requires a geolyzer to work!"); return
end

if not component.isAvailable("hologram") then
	GUI.error("This program requires a hologram projector to work!"); return
end

component.gpu.setResolution(component.gpu.maxResolution())
buffer.start()

local resourcesDirectory = MineOSCore.getCurrentApplicationResourcesDirectory() 
local earthImage = image.load(resourcesDirectory .. "Earth.pic")

local onScreenDataXOffset, onScreenDataYOffset = math.floor(buffer.width / 2), buffer.height
local onProjectorDataYOffset = 0
local scanResult = {horizontalRange = 0, verticalRange = 0}
local mainContainer = GUI.fullScreenContainer()

--------------------------------------------------------------------------------------------------------------------

local function getOpenGLValidColorChannels(cykaColor)
	local r, g, b = color.HEXToRGB(cykaColor)
	return r / 255, g / 255, b / 255
end

local function createCube(x, y, z, cykaColor, isVisThrObj)
	local cube = component.glasses.addCube3D()
	cube.set3DPos(x, y, z)
	cube.setVisibleThroughObjects(isVisThrObj)
	cube.setColor(getOpenGLValidColorChannels(cykaColor))
	cube.setAlpha(0.23)
	return cube
end

local function glassesCreateCube(x, y, z, cykaColor, text)
	local cube = createCube(x, y, z, cykaColor, true)
	cube.setVisibleThroughObjects(true)

	local floatingText = component.glasses.addFloatingText()
	floatingText.set3DPos(x + 0.5, y + 0.5, z + 0.5)
	floatingText.setColor(1, 1, 1)
	floatingText.setAlpha(0.6)
	floatingText.setText(text)
	floatingText.setScale(0.015)
end

local function createDick(x, y, z, chance, isVisThrObj)
	if component.isAvailable("glasses") and math.random(1, 100) <= chance then
		createCube(x, y, z, 0xFFFFFF, isVisThrObj)
		createCube(x + 1, y, z, 0xFFFFFF, isVisThrObj)
		createCube(x + 2, y, z, 0xFFFFFF, isVisThrObj)
		createCube(x + 1, y + 1, z, 0xFFFFFF, isVisThrObj)
		createCube(x + 1, y + 2, z, 0xFFFFFF, isVisThrObj)
		createCube(x + 1, y + 3, z, 0xFFFFFF, isVisThrObj)
		createCube(x + 1, y + 5, z, 0xFF8888, isVisThrObj)
	end
end

local function progressReport(value, text)
	local width = 40
	local x, y = math.floor(buffer.width / 2 - width / 2), math.floor(buffer.height / 2)
	GUI.progressBar(x, y, width, 0x00B6FF, 0xFFFFFF, 0xEEEEEE, value, true, true, text, "%"):draw()
	buffer.draw()
end

local function updateData(onScreen, onProjector, onGlasses)
	local glassesAvailable = component.isAvailable("glasses")

	if onScreen then buffer.clear(0xEEEEEE) end
	if onProjector then component.hologram.clear() end
	if onGlasses and glassesAvailable then component.glasses.removeAll() end

	local min, max = tonumber(mainContainer.minimumHardnessTextBox.text), tonumber(mainContainer.maximumHardnessTextBox.text)
	local horizontalRange, verticalRange = math.floor(mainContainer.horizontalScanRangeSlider.value), math.floor(mainContainer.verticalScanRangeSlider.value)

	for x = -horizontalRange, horizontalRange do
		for z = -horizontalRange, horizontalRange do
			for y = 32 - verticalRange, 32 + verticalRange do
				if scanResult[x] and scanResult[x][z] and scanResult[x][z][y] and scanResult[x][z][y] >= min and scanResult[x][z][y] <= max then
					if onScreen then
						buffer.semiPixelSet(onScreenDataXOffset + x, onScreenDataYOffset + 32 - y, 0x454545)
					end
					if onProjector and mainContainer.projectorUpdateSwitch.state then
						component.hologram.set(horizontalRange + x, math.floor(mainContainer.projectorYOffsetSlider.value) + y - 32, horizontalRange + z, 1)
					end
					if onGlasses and mainContainer.glassesUpdateSwitch.state and glassesAvailable then
						glassesCreateCube(x, y - 32, z, mainContainer.glassesOreColorButton.colors.default.background, "Hardness: " .. string.format("%.2f", scanResult[x][z][y]))
						os.sleep(0)
					end
				end
			end
		end
	end
end

local oldDraw = mainContainer.draw
mainContainer.draw = function()
	updateData(true, false, false)
	oldDraw(mainContainer)
end

local panelWidth = 30
local panelX = buffer.width - panelWidth + 1
local buttonX, objectY = panelX + 2, 2
local buttonWidth = panelWidth - 4
mainContainer:addChild(GUI.panel(panelX, 1, panelWidth, buffer.height, 0x444444))

mainContainer.planetImage = mainContainer:addChild(GUI.image(buttonX, objectY, earthImage))
objectY = objectY + mainContainer.planetImage.image[2] + 1

mainContainer:addChild(GUI.label(buttonX, objectY, buttonWidth, 1, 0xFFFFFF, "GeoScan v2.0")):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
objectY = objectY + 2

mainContainer.horizontalScanRangeSlider = mainContainer:addChild(GUI.slider(buttonX, objectY, buttonWidth, 0xFFDB80, 0x000000, 0xFFDB40, 0xBBBBBB, 4, 24, 16, false, "Horizontal scan range: "))
mainContainer.horizontalScanRangeSlider.roundValues = true
objectY = objectY + 3
mainContainer.verticalScanRangeSlider = mainContainer:addChild(GUI.slider(buttonX, objectY, buttonWidth, 0xFFDB80, 0x000000, 0xFFDB40, 0xBBBBBB, 4, 32, 16, false, "Vertical show range: "))
mainContainer.verticalScanRangeSlider.roundValues = true
objectY = objectY + 4

mainContainer:addChild(GUI.label(buttonX, objectY, buttonWidth, 1, 0xFFFFFF, "Rendering properties")):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
objectY = objectY + 2

mainContainer.minimumHardnessTextBox = mainContainer:addChild(GUI.inputField(buttonX, objectY, 12, 3, 0x262626, 0xBBBBBB, 0xBBBBBB, 0x262626, 0xFFFFFF, tostring(2.7), nil, true))
mainContainer.minimumHardnessTextBox.validator = function(text) if tonumber(text) then return true end end
mainContainer.maximumHardnessTextBox = mainContainer:addChild(GUI.inputField(buttonX + 14, objectY, 12, 3, 0x262626, 0xBBBBBB, 0xBBBBBB, 0x262626, 0xFFFFFF, tostring(10), nil, true))
mainContainer.maximumHardnessTextBox.validator = function(text) if tonumber(text) then return true end end
objectY = objectY + 3
mainContainer:addChild(GUI.label(buttonX, objectY, buttonWidth, 1, 0xBBBBBB, "Hardness min  Hardness max")):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
objectY = objectY + 2


mainContainer.projectorScaleSlider = mainContainer:addChild(GUI.slider(buttonX, objectY, buttonWidth, 0xFFDB80, 0x000000, 0xFFDB40, 0xBBBBBB, 0.33, 3, component.hologram.getScale(), false, "Projection scale: "))
mainContainer.projectorScaleSlider.onValueChanged = function()
	component.hologram.setScale(mainContainer.projectorScaleSlider.value)
end
objectY = objectY + 3
mainContainer.projectorYOffsetSlider = mainContainer:addChild(GUI.slider(buttonX, objectY, buttonWidth, 0xFFDB80, 0x000000, 0xFFDB40, 0xBBBBBB, 0, 64, 4, false, "Projection Y offset: "))
mainContainer.projectorYOffsetSlider.roundValues = true
objectY = objectY + 3

local function setButtonColorFromPalette(button)
	local selectedColor = require("palette").show("auto", "auto", button.colors.default.background)
	if selectedColor then button.colors.default.background = selectedColor end
	mainContainer:draw(); buffer.draw() 
end

local function updateProjectorColors()
	component.hologram.setPaletteColor(1, mainContainer.color1Button.colors.default.background)
end

local color1, color2, color3 = component.hologram.getPaletteColor(1), component.hologram.getPaletteColor(2), component.hologram.getPaletteColor(3)
mainContainer.color1Button = mainContainer:addChild(GUI.button(buttonX, objectY, buttonWidth, 1, color1, 0xBBBBBB, 0xEEEEEE, 0x262626, "Projector color")); objectY = objectY + 1
mainContainer.color1Button.onTouch = function()
	setButtonColorFromPalette(mainContainer.color1Button)
	updateProjectorColors()
end
mainContainer.glassesOreColorButton = mainContainer:addChild(GUI.button(buttonX, objectY, buttonWidth, 1, 0x0044FF, 0xBBBBBB, 0xEEEEEE, 0x262626, "Glasses ore color"))
mainContainer.glassesOreColorButton.onTouch = function()
	setButtonColorFromPalette(mainContainer.glassesOreColorButton)
end
objectY = objectY + 2

mainContainer:addChild(GUI.label(buttonX, objectY, buttonWidth, 1, 0xBBBBBB, "Projector update:"))
mainContainer.projectorUpdateSwitch = mainContainer:addChild(GUI.switch(buffer.width - 8, objectY, 7, 0xFFDB40, 0xAAAAAA, 0xFFFFFF, true))
objectY = objectY + 2
mainContainer:addChild(GUI.label(buttonX, objectY, buttonWidth, 1, 0xBBBBBB, "Glasses update:"))
mainContainer.glassesUpdateSwitch = mainContainer:addChild(GUI.switch(buffer.width - 8, objectY, 7, 0xFFDB40, 0xAAAAAA, 0xFFFFFF, true))
objectY = objectY + 2

mainContainer:addChild(GUI.button(buffer.width, 1, 1, 1, nil, 0xEEEEEE, nil, 0xFF2222, "X")).onTouch = function()
	mainContainer:stopEventHandling()
	createDick(math.random(-48, 48), math.random(1, 32), math.random(-48, 48), 100, true)
end

mainContainer:addChild(GUI.button(panelX, buffer.height - 5, panelWidth, 3, 0x353535, 0xEEEEEE, 0xAAAAAA, 0x262626, "Update")).onTouch = function()
	updateData(false, true, true)
end
mainContainer.scanButton = mainContainer:addChild(GUI.button(panelX, buffer.height - 2, panelWidth, 3, 0x262626, 0xEEEEEE, 0xAAAAAA, 0x262626, "Scan"))
mainContainer.scanButton.onTouch = function()
	scanResult = {}
	local horizontalRange, verticalRange = math.floor(mainContainer.horizontalScanRangeSlider.value), math.floor(mainContainer.verticalScanRangeSlider.value)
	local total, current = (horizontalRange * 2 + 1) ^ 2, 0

	buffer.clear(0x0, 0.48)
	for x = -horizontalRange, horizontalRange do
		scanResult[x] = {}
		for z = -horizontalRange, horizontalRange do
			scanResult[x][z] = component.geolyzer.scan(x, z)
			current = current + 1
			progressReport(math.ceil(current / total * 100), "Scan progress: ")
			buffer.draw()
		end
	end

	mainContainer:draw()
	buffer.draw()
	updateData(false, true, true)
end

--------------------------------------------------------------------------------------------------------------------

buffer.clear(0x0)
mainContainer:draw()
buffer.draw()
mainContainer:startEventHandling()

