
local component = require("component")
local color = require("color")
local image = require("image")
local buffer = require("doubleBuffering")
local GUI = require("GUI")
local MineOSCore = require("MineOSCore")

--------------------------------------------------------------------------------------------------------------------

if not component.isAvailable("geolyzer") then
	GUI.alert("This program requires a geolyzer to work!"); return
end

if not component.isAvailable("hologram") then
	GUI.alert("This program requires a hologram projector to work!"); return
end

component.gpu.setResolution(component.gpu.maxResolution())
buffer.flush()
local bufferWidth, bufferHeight = buffer.getResolution()

local resourcesDirectory = MineOSCore.getCurrentScriptDirectory() 
local earthImage = image.load(resourcesDirectory .. "Earth.pic")

local onScreenDataXOffset, onScreenDataYOffset = math.floor(bufferWidth / 2), bufferHeight
local onProjectorDataYOffset = 0
local scanResult = {horizontalRange = 0, verticalRange = 0}
local application = GUI.application()

--------------------------------------------------------------------------------------------------------------------

local function getOpenGLValidColorChannels(cykaColor)
	local r, g, b = color.integerToRGB(cykaColor)
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
	local x, y = math.floor(bufferWidth / 2 - width / 2), math.floor(bufferHeight / 2)
	GUI.progressBar(x, y, width, 0x00B6FF, 0xFFFFFF, 0xEEEEEE, value, true, true, text, "%"):draw()
	buffer.drawChanges()
end

local function updateData(onScreen, onProjector, onGlasses)
	local glassesAvailable = component.isAvailable("glasses")

	if onScreen then buffer.clear(0xEEEEEE) end
	if onProjector then component.hologram.clear() end
	if onGlasses and glassesAvailable then component.glasses.removeAll() end

	local min, max = tonumber(application.minimumHardnessTextBox.text), tonumber(application.maximumHardnessTextBox.text)
	if min and max then
		local horizontalRange, verticalRange = math.floor(application.horizontalScanRangeSlider.value), math.floor(application.verticalScanRangeSlider.value)

		for x = -horizontalRange, horizontalRange do
			for z = -horizontalRange, horizontalRange do
				for y = 32 - verticalRange, 32 + verticalRange do
					if scanResult[x] and scanResult[x][z] and scanResult[x][z][y] and scanResult[x][z][y] >= min and scanResult[x][z][y] <= max then
						if onScreen then
							buffer.semiPixelSet(onScreenDataXOffset + x, onScreenDataYOffset + 32 - y, 0x454545)
						end
						if onProjector and application.projectorUpdateSwitch.state then
							component.hologram.set(horizontalRange + x, math.floor(application.projectorYOffsetSlider.value) + y - 32, horizontalRange + z, 1)
						end
						if onGlasses and application.glassesUpdateSwitch.state and glassesAvailable then
							glassesCreateCube(x, y - 32, z, application.glassesOreColorButton.colors.default.background, "Hardness: " .. string.format("%.2f", scanResult[x][z][y]))
							os.sleep(0)
						end
					end
				end
			end
		end
	end
end

local oldDraw = application.draw
application.draw = function()
	updateData(true, false, false)
	oldDraw(application)
end

local panelWidth = 30
local panelX = bufferWidth - panelWidth + 1
local buttonX, objectY = panelX + 2, 2
local buttonWidth = panelWidth - 4
application:addChild(GUI.panel(panelX, 1, panelWidth, bufferHeight, 0x444444))

application.planetImage = application:addChild(GUI.image(buttonX, objectY, earthImage))
objectY = objectY + application.planetImage.image[2] + 1

application:addChild(GUI.label(buttonX, objectY, buttonWidth, 1, 0xFFFFFF, "GeoScan v2.0")):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
objectY = objectY + 2

application.horizontalScanRangeSlider = application:addChild(GUI.slider(buttonX, objectY, buttonWidth, 0xFFDB80, 0x000000, 0xFFDB40, 0xBBBBBB, 4, 24, 16, false, "Horizontal scan range: "))
application.horizontalScanRangeSlider.roundValues = true
objectY = objectY + 3
application.verticalScanRangeSlider = application:addChild(GUI.slider(buttonX, objectY, buttonWidth, 0xFFDB80, 0x000000, 0xFFDB40, 0xBBBBBB, 4, 32, 16, false, "Vertical show range: "))
application.verticalScanRangeSlider.roundValues = true
objectY = objectY + 4

application:addChild(GUI.label(buttonX, objectY, buttonWidth, 1, 0xFFFFFF, "Rendering properties")):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
objectY = objectY + 2

application.minimumHardnessTextBox = application:addChild(GUI.input(buttonX, objectY, 12, 3, 0x262626, 0xBBBBBB, 0xBBBBBB, 0x262626, 0xFFFFFF, tostring(2.7), nil, true))
application.maximumHardnessTextBox = application:addChild(GUI.input(buttonX + 14, objectY, 12, 3, 0x262626, 0xBBBBBB, 0xBBBBBB, 0x262626, 0xFFFFFF, tostring(10), nil, true))
objectY = objectY + 3
application:addChild(GUI.label(buttonX, objectY, buttonWidth, 1, 0xBBBBBB, "Hardness min  Hardness max")):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
objectY = objectY + 2


application.projectorScaleSlider = application:addChild(GUI.slider(buttonX, objectY, buttonWidth, 0xFFDB80, 0x000000, 0xFFDB40, 0xBBBBBB, 0.33, 3, component.hologram.getScale(), false, "Projection scale: "))
application.projectorScaleSlider.onValueChanged = function()
	component.hologram.setScale(application.projectorScaleSlider.value)
end
objectY = objectY + 3
application.projectorYOffsetSlider = application:addChild(GUI.slider(buttonX, objectY, buttonWidth, 0xFFDB80, 0x000000, 0xFFDB40, 0xBBBBBB, 0, 64, 4, false, "Projection Y offset: "))
application.projectorYOffsetSlider.roundValues = true
objectY = objectY + 3

local function setButtonColorFromPalette(button)
	local selectedColor = GUI.palette(math.floor(application.width / 2 - 35), math.floor(application.height / 2 - 12), button.colors.default.background):show()
	if selectedColor then button.colors.default.background = selectedColor end
	application:draw()
end

local function updateProjectorColors()
	component.hologram.setPaletteColor(1, application.color1Button.colors.default.background)
end

local color1, color2, color3 = component.hologram.getPaletteColor(1), component.hologram.getPaletteColor(2), component.hologram.getPaletteColor(3)
application.color1Button = application:addChild(GUI.button(buttonX, objectY, buttonWidth, 1, color1, 0xBBBBBB, 0xEEEEEE, 0x262626, "Projector color")); objectY = objectY + 1
application.color1Button.onTouch = function()
	setButtonColorFromPalette(application.color1Button)
	updateProjectorColors()
end
application.glassesOreColorButton = application:addChild(GUI.button(buttonX, objectY, buttonWidth, 1, 0x0044FF, 0xBBBBBB, 0xEEEEEE, 0x262626, "Glasses ore color"))
application.glassesOreColorButton.onTouch = function()
	setButtonColorFromPalette(application.glassesOreColorButton)
end
objectY = objectY + 2

application:addChild(GUI.label(buttonX, objectY, buttonWidth, 1, 0xBBBBBB, "Projector update:"))
application.projectorUpdateSwitch = application:addChild(GUI.switch(bufferWidth - 8, objectY, 7, 0xFFDB40, 0xAAAAAA, 0xFFFFFF, true))
objectY = objectY + 2
application:addChild(GUI.label(buttonX, objectY, buttonWidth, 1, 0xBBBBBB, "Glasses update:"))
application.glassesUpdateSwitch = application:addChild(GUI.switch(bufferWidth - 8, objectY, 7, 0xFFDB40, 0xAAAAAA, 0xFFFFFF, true))
objectY = objectY + 2

application:addChild(GUI.button(bufferWidth, 1, 1, 1, nil, 0xEEEEEE, nil, 0xFF2222, "X")).onTouch = function()
	application:stop()
	createDick(math.random(-48, 48), math.random(1, 32), math.random(-48, 48), 100, true)
end

application:addChild(GUI.button(panelX, bufferHeight - 5, panelWidth, 3, 0x353535, 0xEEEEEE, 0xAAAAAA, 0x262626, "Update")).onTouch = function()
	updateData(false, true, true)
end
application.scanButton = application:addChild(GUI.button(panelX, bufferHeight - 2, panelWidth, 3, 0x262626, 0xEEEEEE, 0xAAAAAA, 0x262626, "Scan"))
application.scanButton.onTouch = function()
	scanResult = {}
	local horizontalRange, verticalRange = math.floor(application.horizontalScanRangeSlider.value), math.floor(application.verticalScanRangeSlider.value)
	local total, current = (horizontalRange * 2 + 1) ^ 2, 0

	buffer.clear(0x0, 0.48)
	for x = -horizontalRange, horizontalRange do
		scanResult[x] = {}
		for z = -horizontalRange, horizontalRange do
			scanResult[x][z] = component.geolyzer.scan(x, z)
			current = current + 1
			progressReport(math.ceil(current / total * 100), "Scan progress: ")
			buffer.drawChanges()
		end
	end

	application:draw()
	updateData(false, true, true)
end

--------------------------------------------------------------------------------------------------------------------

buffer.clear(0x0)
application:draw()
application:start()

