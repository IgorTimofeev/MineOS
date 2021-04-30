local GUI = require("GUI")
local screen = require("Screen")
local fs = require("Filesystem")
local bigLetters = require("BigLetters")
local paths = require("Paths")

--------------------------------------------------------------------------------

local configPath = paths.user.applicationData .. "/YobaReactors.cfg"
local config = fs.exists(configPath) and fs.readTable(configPath) or { delay = 5000, links = {} }
local palette = { 0x00FF00,0x00B600,0x33DB00,0x99FF00,0xCCFF00,0xFFDB00,0xFFB600,0xFF9200,0xFF6D00,0xFF4900,0xFF2400,0xFF0000 }

local sides = {
	[0] = "Bottom",
	[1] = "Top",
	[2] = "Back",
	[3] = "Front",
	[4] = "Right",
	[5] = "Left"
}

local ios = {}
for address in component.list("redstone") do
	table.insert(ios, component.proxy(address))
end

--------------------------------------------------------------------------------

screen.setResolution(screen.getScaledResolution(1))

local workspace = GUI.workspace()

workspace:addChild(GUI.panel(1, 1, workspace.width, workspace.height, 0x1E1E1E))

local statLayout = workspace:addChild(GUI.layout(1, 1, 56, workspace.height, 1, 1))
statLayout.localX = workspace.width - statLayout.width - 3

local totalEnergy = 0
local totalEnergyObject = statLayout:addChild(GUI.object(1, 1, statLayout.width, 6))

totalEnergyObject.draw = function()
	local text = tostring(totalEnergy) .. " eu"
	bigLetters.drawText(math.floor(totalEnergyObject.x + totalEnergyObject.width / 2 - bigLetters.getTextSize(text) / 2), totalEnergyObject.y, 0xFFFFFF, text)
end

local masterEnable = statLayout:addChild(GUI.button(1, 1, statLayout.width, 3, 0x2D2D2D, 0x969696, 0x33B640, 0xFFFFFF, "MASTER ENABLE"))
local masterDisable = statLayout:addChild(GUI.button(1, 1, statLayout.width, 3, 0x2D2D2D, 0x969696, 0x660000, 0xFFFFFF, "MASTER DISABLE"))
masterEnable.animated, masterDisable.animated = false, false

local delaySlider = statLayout:addChild(GUI.slider(1, 1, statLayout.width, 0x33B640, 0x0, 0xFFFFFF, 0xAAAAAA, 0, 10000, config.delay, false, "UPDATE DELAY: ", " MSEC"))
delaySlider.roundValues = true
delaySlider.onValueChanged = function()
	config.delay = delaySlider.value
	fs.writeTable(configPath, config)
end

local contorollersContainer = workspace:addChild(GUI.container(1, 1, workspace.width, workspace.height))

local function setButtonState(button, state)
	button.pressed = state
	button.text = button.pressed and "ENABLED" or "DISABLED"
end

local function newController(x, y, reactorProxy)
	local object = GUI.window(x, y, 38, 5)

	object.reactorProxy = reactorProxy
	object:addChild(GUI.panel(1, 1, object.width, object.height, 0x2D2D2D))

	object.button = object:addChild(GUI.button(1, 1, 16, 3, 0x660000, 0xFFFFFF, 0x33B640, 0xFFFFFF, "DISABLED"))
	object.button.localX = object.width - object.button.width + 1
	object.button.switchMode = true
	object.button.animated = false

	-- I/O comboBox
	object.ioComboBox = object:addChild(GUI.comboBox(object.button.localX, object.button.localY + object.button.height, object.button.width, 1, 0x4B4B4B, 0x787878, 0x5A5A5A, 0x696969))
	object.ioComboBox.dropDownMenu.itemHeight = 1
	object.ioComboBox:addItem("Not assigned")

	for i = 1, #ios do
		object.ioComboBox:addItem("I/O " .. ios[i].address)

		if config.links[reactorProxy.address] and config.links[reactorProxy.address].address == ios[i].address then
			object.ioComboBox.selectedItem = i + 1
		end
	end

	-- Side comboBox
	object.sideComboBox = object:addChild(GUI.comboBox(object.button.localX, object.button.localY + object.button.height + 1, object.button.width, 1, 0x3C3C3C, 0x787878, 0x5A5A5A, 0x696969))
	object.sideComboBox.dropDownMenu.itemHeight = 1

	for i = 0, 5 do
		object.sideComboBox:addItem(sides[i])

		if config.links[reactorProxy.address] and config.links[reactorProxy.address].side == i then
			object.sideComboBox.selectedItem = i
		end
	end

	object:addChild(GUI.label(1, 2, object.width - object.button.width, 1, 0x969696, "REACTOR " .. reactorProxy.address:sub(1, 5))):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
	object.temperatureBar = object:addChild(GUI.progressBar(2, 3, object.width - object.button.width - 2, 0x3366CC, 0x1E1E1E, 0x969696, 80, true, false))
	object.statusLabel = object:addChild(GUI.label(2, 4, object.temperatureBar.width, 1, 0x5A5A5A, "")):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)

	local function getRedstoneProxy()
		return component.proxy(ios[object.ioComboBox.selectedItem - 1].address)
	end

	local function updateButton()
		object.button.disabled = object.ioComboBox.selectedItem == 1
	end

	object.button.onTouch = function()
		setButtonState(object.button, object.button.pressed)
		workspace:draw()

		getRedstoneProxy().setOutput(object.sideComboBox.selectedItem, object.button.pressed and 15 or 0)
	end

	local function saveIOSide()
		updateButton()
		workspace:draw()

		config.links[reactorProxy.address] = config.links[reactorProxy.address] or {}
		config.links[reactorProxy.address].address = object.ioComboBox.selectedItem > 1 and ios[object.ioComboBox.selectedItem - 1].address or nil
		config.links[reactorProxy.address].side = object.sideComboBox.selectedItem

		fs.writeTable(configPath, config)
	end

	object.ioComboBox.onItemSelected = saveIOSide
	object.sideComboBox.onItemSelected = saveIOSide

	updateButton()

	if object.ioComboBox.selectedItem > 1 and getRedstoneProxy().getOutput(object.sideComboBox.selectedItem) > 0 then
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
		object.statusLabel.text = math.floor(heat) .. " °C, " .. math.floor(object.reactorProxy.getReactorEUOutput()) .. " eU/t"
		
		totalEnergy = totalEnergy + math.floor(object.reactorProxy.getReactorEUOutput())
	end
end

local uptime = computer.uptime()
contorollersContainer.eventHandler = function(workspace, object, e1)
	if not e1 and computer.uptime() - uptime > delaySlider.value / 1000 then
		update()
		workspace:draw()
		uptime = computer.uptime()
	end
end

local function masterState(state)
	for i = 1, #contorollersContainer.children do
		local object = contorollersContainer.children[i]

		if not object.disabled and object.ioComboBox.selectedItem > 1 then
			setButtonState(object.button, state)

			ios[object.ioComboBox.selectedItem - 1].setOutput(object.sideComboBox.selectedItem, state and 15 or 0)
		end
	end

	update()
	workspace:draw()
end

masterDisable.onTouch = function()
	masterState(false)
end

masterEnable.onTouch = function()
	masterState(true)
end

--------------------------------------------------------------------------------

update()
workspace:draw(true)
workspace:start(0)