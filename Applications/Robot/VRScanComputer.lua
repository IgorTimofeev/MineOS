
local component = require("component")
local GUI = require("GUI")
local filesystem = require("filesystem")
local MineOSPaths = require("MineOSPaths")

local glasses = component.glasses
local modem = component.modem

--------------------------------------------------------------------------------

local port = 512

config = {
	offsetX = 0,
	offsetY = 0,
	offsetZ = 0,
}

local configPath = MineOSPaths.applicationData .. "VRScan.cfg"
if filesystem.exists(configPath) then
	config = table.fromFile(configPath)
end

--------------------------------------------------------------------------------

local function broadcast(...)
	modem.broadcast(port, "VRScan", ...)
end

local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0xF0F0F0))

local layout = mainContainer:addChild(GUI.layout(1, 1, mainContainer.width, mainContainer.height, 1, 1))

local offsetXInput = layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x787878, 0xB4B4B4, 0xE1E1E1, 0x2D2D2D, tostring(config.offsetX), "Robot offset by X"))

local offsetYInput = layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x787878, 0xB4B4B4, 0xE1E1E1, 0x2D2D2D, tostring(config.offsetY), "Robot offset by Y"))

local offsetZInput = layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x787878, 0xB4B4B4, 0xE1E1E1, 0x2D2D2D, tostring(config.offsetZ), "Robot offset by Z"))

local widthSlider = layout:addChild(GUI.slider(1, 1, 36, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xB4B4B4, 1, 10, 3, false, "Width: ", ""))
widthSlider.height = 2
widthSlider.roundValues = true

local heightSlider = layout:addChild(GUI.slider(1, 1, 36, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xB4B4B4, 1, 10, 3, false, "Height: ", ""))
heightSlider.height = 2
heightSlider.roundValues = true

local lengthSlider = layout:addChild(GUI.slider(1, 1, 36, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xB4B4B4, 1, 10, 3, false, "Length: ", ""))
lengthSlider.height = 2
heightSlider.roundValues = true

local radiusSlider = layout:addChild(GUI.slider(1, 1, 36, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xB4B4B4, 1, 10, 3, false, "Radius: ", ""))
radiusSlider.height = 2
radiusSlider.roundValues = true

local minDensitySlider = layout:addChild(GUI.slider(1, 1, 36, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xB4B4B4, 0, 10, 0.5, false, "Min density: ", ""))
minDensitySlider.height = 2

local maxDensitySlider = layout:addChild(GUI.slider(1, 1, 36, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xB4B4B4, 0, 10, 0.5, false, "Max density: ", ""))
maxDensitySlider.height = 2

layout:addChild(GUI.button(1, 1, 36, 3, 0xC3C3C3, 0xFFFFFF, 0x969696, 0xFFFFFF, "Scan")).onTouch = function()
	config.offsetX, config.offsetY, config.offsetZ = tonumber(offsetXInput.text), tonumber(offsetYInput.text), tonumber(offsetZInput.text)
	table.toFile(configPath, config)
	
	broadcast(
		"scan",
		config.offsetX,
		config.offsetY,
		config.offsetZ,
		math.floor(widthSlider.value),
		math.floor(heightSlider.value),
		math.floor(lengthSlider.value),
		math.floor(radiusSlider.value),
		minDensitySlider.value,
		maxDensitySlider.value
	)
end

layout.eventHandler = function(mainContainer, layout, e1, e2, e3, e4, e5, e6, e7, e8, e9, e10, e11, e12)
	if e1 == "modem_message" and e6 == "VRScan" then
		if e7 == "result" then
			local robotX, robotY, robotZ, result = e[8], e[9], e[10], serialization.unserialize(e[11])
			GUI.alert("Got result from " .. robotX .. "x" .. robotY .. robotZ .. " with size " .. #result)
		end
	end
end

--------------------------------------------------------------------------------

modem.open(port)
mainContainer:drawOnScreen(true)
mainContainer:startEventHandling()