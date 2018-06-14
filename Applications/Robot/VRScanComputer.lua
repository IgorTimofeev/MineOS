
local component = require("component")
local GUI = require("GUI")
local color = require("color")
local computer = require("computer")
local filesystem = require("filesystem")
local MineOSPaths = require("MineOSPaths")

local glasses = component.glasses
local modem = component.modem

--------------------------------------------------------------------------------

local port = 512

local config = {
	glassesX = 0,
	glassesY = 0,
	glassesZ = 0,
	robotX = 0,
	robotY = 0,
	robotZ = 0,
	width = 3,
	height = 1,
	length = 3,
	radius = 16,
	minDensity = 0.2,
	maxDensity = 10,
}

local configPath = MineOSPaths.applicationData .. "VRScan4.cfg"
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

local width = 39

local function addCoords(v1, v2, v3, t1, t2, t3)
	local subLayout = layout:addChild(GUI.layout(1, 1, width, 3, 1, 1))
	subLayout:setDirection(1, 1, GUI.DIRECTION_HORIZONTAL)
	subLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_TOP)

	local width = math.floor((width - 2) / 3)
	return
		subLayout:addChild(GUI.input(1, 1, width, 3, 0xE1E1E1, 0x787878, 0xB4B4B4, 0xE1E1E1, 0x2D2D2D, v1, t1)),
		subLayout:addChild(GUI.input(1, 1, width, 3, 0xE1E1E1, 0x787878, 0xB4B4B4, 0xE1E1E1, 0x2D2D2D, v2, t2)),
		subLayout:addChild(GUI.input(1, 1, width, 3, 0xE1E1E1, 0x787878, 0xB4B4B4, 0xE1E1E1, 0x2D2D2D, v3, t3))
end

local glassesXInput, glassesYInput, glassesZInput = addCoords(tostring(config.glassesX), tostring(config.glassesY), tostring(config.glassesZ), "Glasses X", "Glasses Y", "Glasses Z")

local robotXInput, robotYInput, robotZInput = addCoords(tostring(config.robotX), tostring(config.robotY), tostring(config.robotZ), "Robot X", "Robot Y", "Robot Z")

local widthSlider = layout:addChild(GUI.slider(1, 1, width, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xB4B4B4, 1, 10, config.width, false, "Width: ", ""))
widthSlider.height = 2
widthSlider.roundValues = true

local heightSlider = layout:addChild(GUI.slider(1, 1, width, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xB4B4B4, 1, 10, config.height, false, "Height: ", ""))
heightSlider.height = 2
heightSlider.roundValues = true

local lengthSlider = layout:addChild(GUI.slider(1, 1, width, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xB4B4B4, 1, 10, config.length, false, "Length: ", ""))
lengthSlider.height = 2
lengthSlider.roundValues = true

local radiusSlider = layout:addChild(GUI.slider(1, 1, width, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xB4B4B4, 1, 24, config.radius, false, "Radius: ", ""))
radiusSlider.height = 2
radiusSlider.roundValues = true

local minDensitySlider = layout:addChild(GUI.slider(1, 1, width, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xB4B4B4, 0, 10, config.minDensity, false, "Min density: ", ""))
minDensitySlider.height = 2

local maxDensitySlider = layout:addChild(GUI.slider(1, 1, width, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xB4B4B4, 0, 10, config.maxDensity, false, "Max density: ", ""))
maxDensitySlider.height = 2

local function saveConfig()
	config.glassesX = tonumber(glassesXInput.text)
	config.glassesY = tonumber(glassesYInput.text)
	config.glassesZ = tonumber(glassesZInput.text)
	config.robotX = tonumber(robotXInput.text)
	config.robotY = tonumber(robotYInput.text)
	config.robotZ = tonumber(robotZInput.text)
	config.width = math.floor(widthSlider.value)
	config.height = math.floor(heightSlider.value)
	config.length = math.floor(lengthSlider.value)
	config.radius = math.floor(radiusSlider.value)
	config.minDensity = minDensitySlider.value
	config.maxDensity = maxDensitySlider.value

	table.toFile(configPath, config)
end

layout:addChild(GUI.button(1, 1, width, 3, 0xC3C3C3, 0xFFFFFF, 0x969696, 0xFFFFFF, "Scan")).onTouch = function()
	saveConfig()

	broadcast("scan", table.toString({
		width = config.width,
		height = config.height,
		length = config.length,
		radius = config.radius,
		minDensity = config.minDensity,
		maxDensity = config.maxDensity
	}))

	glasses.removeAll()
end

layout.eventHandler = function(mainContainer, layout, e1, e2, e3, e4, e5, e6, e7, e8, e9, e10, e11, e12)
	if e1 == "modem_message" and e6 == "VRScan" then
		if e7 == "result" then
			local result = table.fromString(e8)

			for x in pairs(result.blocks) do
				for y in pairs(result.blocks[x]) do
					for z in pairs(result.blocks[x][y]) do
						for i = 1, #result.blocks[x][y][z] do
							local cube = glasses.addCube3D()
							cube.setVisibleThroughObjects(true)

							local maxHue = 240
							local hue = (1 - result.blocks[x][y][z][i] / config.maxDensity) * maxHue
							local r, g, b = color.HSBToRGB(hue, 1, 1)

							cube.setColor(r / 255, g / 255, b / 255)
							cube.setAlpha(0.5)
							cube.set3DPos(
								config.robotX - config.glassesX + result.x + x,
								config.robotY - config.glassesY + result.y + y,
								config.robotZ - config.glassesZ + result.z + z
							)
						end

						computer.pullSignal(0)
					end
				end
			end
		end
	end
end

--------------------------------------------------------------------------------

modem.open(port)
mainContainer:drawOnScreen(true)
mainContainer:startEventHandling()