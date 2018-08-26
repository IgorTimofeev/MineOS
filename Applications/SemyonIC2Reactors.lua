
local computer = require("computer")
local component = require("component")
local GUI = require("GUI")
local buffer = require("doubleBuffering")
local fs = require("filesystem")
local scale = require("scale")
local bigLetters = require("bigLetters")

--------------------------------------------------------------------------------

scale.set(1)
buffer.flush()

local databasePath, database = "/reactors.cfg", {}
if fs.exists(databasePath) then
	database = table.fromFile(databasePath)
end

local palette = { 0x00FF00,0x00B600,0x33DB00,0x99FF00,0xCCFF00,0xFFDB00,0xFFB600,0xFF9200,0xFF6D00,0xFF4900,0xFF2400,0xFF0000 }

--------------------------------------------------------------------------------

local redstones = {}
for address in component.list("redstone") do
	table.insert(redstones, component.proxy(address))
end

local mainContainer = GUI.fullScreenContainer()

mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x1E1E1E))

local statLayout = mainContainer:addChild(GUI.layout(1, 1, 56, mainContainer.height, 1, 1))
statLayout.localX = mainContainer.width - statLayout.width - 3

local totalEnergy = 0
local totalEnergyObject = statLayout:addChild(GUI.object(1, 1, statLayout.width, 6))

totalEnergyObject.draw = function()
	local text = tostring(totalEnergy) .. " eu"
	bigLetters.drawText(math.floor(totalEnergyObject.x + totalEnergyObject.width / 2 - bigLetters.getTextSize(text) / 2), totalEnergyObject.y, 0xFFFFFF, text)
end

local masterEnable = statLayout:addChild(GUI.button(1, 1, statLayout.width, 3, 0x2D2D2D, 0x969696, 0x33B640, 0xFFFFFF, "MASTER ENABLE"))
local masterDisable = statLayout:addChild(GUI.button(1, 1, statLayout.width, 3, 0x2D2D2D, 0x969696, 0x660000, 0xFFFFFF, "MASTER DISABLE"))
masterEnable.animated, masterDisable.animated = false, false

local delaySlider = statLayout:addChild(GUI.slider(1, 1, statLayout.width, 0x33B640, 0x0, 0xFFFFFF, 0xAAAAAA, 0, 10000, 1000, false, "UPDATE DELAY: ", " MSEC"))
delaySlider.roundValues = true

local contorollersContainer = mainContainer:addChild(GUI.container(1, 1, mainContainer.width, mainContainer.height))

local function setButtonState(button, state)
	button.pressed = state
	button.text = button.pressed and "ENABLED" or "DISABLED"
end

local function newController(x, y, reactorProxy)
	local object = GUI.window(x, y, 40, 6)

	object.reactorProxy = reactorProxy
	object:addChild(GUI.panel(1, 1, object.width, object.height, 0x2D2D2D))

	object.button = object:addChild(GUI.button(1, 1, 16, 3, 0x660000, 0xFFFFFF, 0x33B640, 0xFFFFFF, "DISABLED"))
	object.button.localX = object.width - object.button.width + 1
	object.button.switchMode = true
	object.button.animated = false

	local comboBox = object:addChild(GUI.comboBox(object.button.localX, object.button.localY + object.button.height, object.button.width, object.button.height, 0x3C3C3C, 0x787878, 0x4B4B4B, 0x5A5A5A))
	comboBox.dropDownMenu.itemHeight = 1
	comboBox:addItem("Not assigned")
	for i = 1, #redstones do
		comboBox:addItem("I/O " .. redstones[i].address)
		if database[reactorProxy.address] == redstones[i].address then
			comboBox.selectedItem = i + 1
		end
	end

	object:addChild(GUI.label(1, 2, object.width - object.button.width, 1, 0x969696, "REACTOR " .. reactorProxy.address:sub(1, 5))):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
	object.temperatureBar = object:addChild(GUI.progressBar(2, 3, object.width - object.button.width - 2, 0x3366CC, 0x1E1E1E, 0x969696, 80, true, false))
	object.temperatureLabel = object:addChild(GUI.label(2, 4, object.temperatureBar.width, 1, 0x5A5A5A, "")):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
	object.energyLabel = object:addChild(GUI.label(2, 5, object.temperatureBar.width, 1, 0x5A5A5A, "")):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)

	local function getRedstoneProxy()
		return component.proxy(redstones[comboBox.selectedItem - 1].address)
	end

	local function updateButton()
		object.button.disabled = comboBox.selectedItem == 1
	end

	object.button.onTouch = function()
		setButtonState(object.button, object.button.pressed)
		mainContainer:drawOnScreen()

		getRedstoneProxy().setOutput(1, object.button.pressed and 15 or 0)
	end

	comboBox.onItemSelected = function()
		updateButton()
		mainContainer:drawOnScreen()

		database[reactorProxy.address] = comboBox.selectedItem > 1 and redstones[comboBox.selectedItem - 1].address or nil
		table.toFile(databasePath, database)
	end

	updateButton()

	if comboBox.selectedItem > 1 and getRedstoneProxy().getOutput(1) > 0 then
		setButtonState(object.button, true)
	end

	return object
end

local x, y, xStart, yStart = 3, 2, 3, 2
for address in component.list("reactor_chamber") do
	local proxy = component.proxy(address)

	local object = contorollersContainer:addChild(newController(x, y, proxy))

	y = y + object.height + 1
	if y >= contorollersContainer.height - object.height then
		x, y = x + object.width + 2, yStart
	end
end

local function update()
	totalEnergy = 0
	
	for i = 1, #contorollersContainer.children do
		local object = contorollersContainer.children[i]
		
		local heat = object.reactorProxy.getHeat()
		local value = heat / object.reactorProxy.getMaxHeat()
		object.temperatureBar.value = value * 100
		object.temperatureBar.colors.active = palette[math.floor(value * #palette)] or palette[1]
		object.temperatureLabel.text = "TEMP: " .. math.floor(heat) .. " °C"
		object.energyLabel.text = "ENRG: " .. math.floor(object.reactorProxy.getReactorEUOutput()) .. " eU/t"
		
		totalEnergy = totalEnergy + math.floor(object.reactorProxy.getReactorEUOutput())
	end
end

local uptime = computer.uptime()
contorollersContainer.eventHandler = function(mainContainer, object, e1)
	if not e1 and computer.uptime() - uptime > delaySlider.value / 1000 then
		update()
		mainContainer:drawOnScreen()
		uptime = computer.uptime()
	end
end

local function masterState(state)
	for i = 1, #contorollersContainer.children do
		local object = contorollersContainer.children[i]
		if not object.disabled then
			setButtonState(object.button, state)
		end
	end

	mainContainer:drawOnScreen()

	for i = 1, #redstones do
		redstones[i].setOutput(1, state and 15 or 0)
	end

	update()
	mainContainer:drawOnScreen()
end

masterDisable.onTouch = function()
	masterState(false)
end

masterEnable.onTouch = function()
	masterState(true)
end

--------------------------------------------------------------------------------

update()
mainContainer:drawOnScreen(true)
mainContainer:startEventHandling(0)
