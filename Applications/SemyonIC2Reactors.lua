
local computer = require("computer")
local component = require("component")
local GUI = require("GUI")
local buffer = require("doubleBuffering")
local fs = require("filesystem")
local scale = require("scale")
local bigLetters = require("bigLetters")

--------------------------------------------------------------------------------

local redstones = {}
for address in component.list("redstone") do
	table.insert(redstones, component.proxy(address))
end

local databasePath = "/reactors.cfg"
local database = {}
if fs.exists(databasePath) then
	database = table.fromFile(databasePath)
end

local palette = {0x00FF00,0x00B600,0x33DB00,0x99FF00,0xCCFF00,0xFFDB00,0xFFB600,0xFF9200,0xFF6D00,0xFF4900,0xFF2400,0xFF0000}

--------------------------------------------------------------------------------

scale.set(1)
buffer.flush()
local mainContainer = GUI.fullScreenContainer()

mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x1E1E1E))

local statLayout = mainContainer:addChild(GUI.layout(1, 1, 30, mainContainer.height, 1, 1))
statLayout.localX = mainContainer.width - statLayout.width + 1

local totalEnergy = "732"
local totalEnergyObject = statLayout:addChild(GUI.object(1, 1, statLayout.width, 5))
totalEnergyObject.draw = function()
	local text = tostring(totalEnergy)
	bigLetters.drawText(math.floor(totalEnergyObject.x + totalEnergyObject.width / 2 - bigLetters.getTextSize(text) / 2), totalEnergyObject.y, 0xFFFFFF, text)
end

local totalEnable = statLayout:addChild(GUI.button(1, 1, statLayout.width, 3, 0x2D2D2D, 0x969696, 0x008800, 0xFFFFFF, "MASTER ENABLE"))
local totalDisable = statLayout:addChild(GUI.button(1, 1, statLayout.width, 3, 0x2D2D2D, 0x969696, 0x880000, 0xFFFFFF, "MASTER DISABLE"))

local function newController(x, y, proxy)
	local contoroller = GUI.window(x, y, 40, 6)
	
	contoroller:addChild(GUI.panel(1, 1, contoroller.width, contoroller.height, 0x2D2D2D))

	local button = contoroller:addChild(GUI.button(1, 1, 16, 3, 0x880000, 0xFFFFFF, 0x008800, 0xFFFFFF, "PASV"))
	button.localX = contoroller.width - button.width + 1
	button.switchMode = true
	button.animated = false

	local comboBox = contoroller:addChild(GUI.comboBox(button.localX, button.localY + button.height, button.width, button.height, 0x3C3C3C, 0x787878, 0x4B4B4B, 0x5A5A5A))
	comboBox.dropDownMenu.itemHeight = 1
	comboBox:addItem("Not assigned")
	for i = 1, #redstones do
		comboBox:addItem("I/O " .. redstones[i].address)
		if database[proxy.address] == redstones[i].address then
			comboBox.selectedItem = i + 1
		end
	end

	contoroller:addChild(GUI.label(1, 2, contoroller.width - button.width, 1, 0x969696, "RCTR " .. proxy.address:sub(1, 5))):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)

	local temperatureBar = contoroller:addChild(GUI.progressBar(2, 3, contoroller.width - button.width - 2, 0x3366CC, 0x1E1E1E, 0x969696, 80, true, false))
	local temperatureLabel = contoroller:addChild(GUI.label(2, 4, temperatureBar.width, 1, 0x5A5A5A, "")):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
	local energyLabel = contoroller:addChild(GUI.label(2, 5, temperatureBar.width, 1, 0x5A5A5A, "")):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)

	local function getRedstoneProxy()
		return component.proxy(redstones[comboBox.selectedItem - 1].address)
	end

	local function update()
		local heat = proxy.getHeat()
		local value = heat / proxy.getMaxHeat()
		temperatureBar.value = value * 100
		temperatureBar.colors.active = palette[math.floor(value * #palette)] or palette[1]
		temperatureLabel.text = "TEMP: " .. math.floor(heat) .. " °C"
		energyLabel.text = "ENRG: " .. math.floor(proxy.getReactorEUOutput()) .. " eU/t"
	end

	local function updateButton()
		button.disabled = comboBox.selectedItem == 1
	end

	button.onTouch = function()
		button.text = button.pressed and "ACTV" or "PASV"
		mainContainer:drawOnScreen()

		getRedstoneProxy().setOutput(1, button.pressed and 15 or 0)
	end

	comboBox.onItemSelected = function()
		updateButton()
		mainContainer:drawOnScreen()

		database[proxy.address] = comboBox.selectedItem > 1 and redstones[comboBox.selectedItem - 1].address or nil
		table.toFile(databasePath, database)
	end

	local overrideEventHandler = contoroller.eventHandler
	local uptime = computer.uptime()
	contoroller.eventHandler = function(mainContainer, object, e1, ...)
		if e1 then
			overrideEventHandler(mainContainer, object, e1, ...)
		elseif computer.uptime() - uptime > 2 then
			update()
			mainContainer:drawOnScreen()

			uptime = computer.uptime()
		end
	end

	update()
	updateButton()

	if comboBox.selectedItem > 1 and getRedstoneProxy().getOutput(1) > 0 then
		button.text, button.pressed = "ACTV", true
	end

	return contoroller
end

local x, y, xStart, yStart = 3, 2, 3, 2
for address in component.list("reactor_chamber") do
	local proxy = component.proxy(address)

	local contoroller = mainContainer:addChild(newController(x, y, proxy))

	y = y + contoroller.height + 1
	if y > mainContainer.height - 4 then
		x, y = x + contoroller.width + 2, yStart
	end
end

--------------------------------------------------------------------------------

mainContainer:drawOnScreen(true)
mainContainer:startEventHandling(0)

