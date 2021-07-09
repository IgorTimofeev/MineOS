
local GUI = require("GUI")
local screen = require("Screen")
local fs = require("Filesystem")
local color = require("Color")
local image = require("Image")
local system = require("System")
local paths = require("Paths")
local system = require("System")
local text = require("Text")

--------------------------------------------------------------------------------

local stack = {}
local port = 451
local maxInputs = 18
local scrollSpeed = 2
local from = 3
local maxActiveInputs = 4
local elementWidth = 40
local syncDelay = 4
local historyLimit = 30
local modem
local currentEffects = "{}"

local localization = system.getCurrentScriptLocalization()

local config = {
	favourites = {},	
}

local configPath = paths.user.applicationData .. "Nanomachines/Config.cfg"
if fs.exists(configPath) then
	config = filesystem.readTable(configPath)
end

local function saveConfig()
	filesystem.writeTable(configPath, config)
end

--------------------------------------------------------------------------------

local workspace, window = system.addWindow(GUI.filledWindow(1, 1, 80, 22, 0xF0F0F0))
local inputsPanel = window:addChild(GUI.panel(1, 1, 19, window.height, 0x2D2D2D))
window.backgroundPanel.localX = inputsPanel.width + 1
window.backgroundPanel.width = window.width - inputsPanel.width

local inputsContainer = window:addChild(GUI.container(1, 4, inputsPanel.width, inputsPanel.height - 3))

local layout = window:addChild(GUI.layout(window.backgroundPanel.localX, 1, window.backgroundPanel.width, window.height, 1, 1))
layout:setMargin(1, 1, 0, from)
layout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)

local textBox = window:addChild(GUI.textBox(window.backgroundPanel.localX, 1, window.backgroundPanel.width, 5, 0xFFFFFF, 0xB4B4B4, {}, 1, 1))
textBox.eventHandler = nil
textBox.localY = window.height - textBox.height + 1

local textBoxButton = window:addChild(GUI.adaptiveButton(1, 1, 2, 0, 0xFFFFFF, 0xD2D2D2, 0xFFFFFF, 0x2D2D2D, " "))
textBoxButton.localX = math.floor(textBox.localX + textBox.width / 2 - textBoxButton.width / 2)

local syncContainer = window:addChild(GUI.container(1, 1, window.width, window.height))
local syncPanel = syncContainer:addChild(GUI.panel(1, 1, syncContainer.width, syncContainer.height, 0xF0F0F0))
local syncLayout = syncContainer:addChild(GUI.layout(1, 1, syncContainer.width, syncContainer.height, 1, 1))

syncLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.syncWelcome))
local syncTextBox = syncLayout:addChild(GUI.textBox(1, 1, 44, 1, nil, 0xA5A5A5, {}, 1, 0, 0, true, true))
syncTextBox.eventHandler = nil

textBoxButton.onTouch = function()
	textBox.hidden = not textBox.hidden
	textBoxButton.localY = textBox.hidden and window.height or textBox.localY - 1
	textBoxButton.text = textBox.hidden and "▲" or "▼"
end

local function addMessage(prefix, ...)
	local message = {...}
	for i = 1, #message do
		message[i] = tostring(message[i])
	end
	
	message = text.wrap(prefix .. table.concat(message, ", "), textBox.width - 2)

	for i = 1, #message do
		table.insert(textBox.lines, message[i])
	end

	for i = 1, #textBox.lines - historyLimit do
		table.remove(textBox.lines, 1)
	end

	textBox:scrollToEnd()
end

local function broadcast(...)
	addMessage(localization.sent .. ": ", ...)
	workspace:draw()

	modem.broadcast(port, "nanomachines", ...)
end

local function broadcastPut(...)
	table.insert(stack, {...})
end

local function broadcastNext()
	if #stack > 0 then
		broadcast(table.unpack(stack[1]))
		table.remove(stack, 1)
	end
end

local function getActiveSwitchCount()
	local count = 0
	for i = 1, maxInputs do
		if inputsContainer.children[i].state then
			count = count + 1
		end
	end

	return count
end

local function checkSwitches()
	local count = getActiveSwitchCount()

	for i = 1, maxInputs do
		inputsContainer.children[i].colors.active = count > 2 and 0xFF4940 or 0x66DB80
		inputsContainer.children[i].disabled = not inputsContainer.children[i].state and count > 3
	end
end

local spacing, width = 3, 6
local startX = math.floor(inputsContainer.width / 2 - width / 2 - spacing)
local x, y = startX, 1
for i = 1, maxInputs do
	local input = inputsContainer:addChild(GUI.switch(x, y, width, 0x66DB80, 0x1E1E1E, 0xE1E1E1, false))
	input.onStateChanged = function()
		checkSwitches()
		workspace:draw()

		broadcastPut("setInput", i, input.state)
		broadcastPut("getActiveEffects")
		broadcastNext()
	end

	x = x + width + spacing
	if x > inputsContainer.width - 1 then
		x, y = startX, y + 2
	end
end

for i = 1, maxInputs do
	local child = inputsContainer.children[i]
	inputsContainer:addChild(GUI.text(math.floor(child.localX + width / 2 - 1), child.localY + 1, 0x4B4B4B, tostring(i)))
end

layout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.favourites))

local favouritesLayout = layout:addChild(GUI.layout(1, 1, elementWidth, 3, 1, 1))
favouritesLayout:setDirection(1, 1, GUI.DIRECTION_HORIZONTAL)
favouritesLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_TOP)

local favouritesComboBox = favouritesLayout:addChild(GUI.comboBox(1, 1, favouritesLayout.width - 12, 3, 0xE1E1E1, 0x696969, 0xD2D2D2, 0xA5A5A5))
local favouritesAddButton = favouritesLayout:addChild(GUI.button(1, 1, 5, 3, 0xE1E1E1, 0x787878, 0x2D2D2D, 0xE1E1E1, "+"))
local favouritesRemoveButton = favouritesLayout:addChild(GUI.button(1, 1, 5, 3, 0xE1E1E1, 0x787878, 0x2D2D2D, 0xE1E1E1, "-"))

layout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.activeEffects))

local effectsLayout = layout:addChild(GUI.layout(1, 1, elementWidth, 1, 1, 1))
effectsLayout:setSpacing(1, 1, 0)
effectsLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_TOP)

layout:addChild(GUI.button(1, 1, elementWidth, 3, 0xE1E1E1, 0x787878, 0x2D2D2D, 0xE1E1E1, localization.saveConfiguration)).onTouch = function()
	broadcastPut("saveConfiguration")
	broadcastNext()
end

layout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.instructionTitle))

local infoTextBox = layout:addChild(GUI.textBox(1, 1, elementWidth, 1, nil, 0xA5A5A5, {localization.instructionData}, 1, 0, 0, true, true))
infoTextBox.eventHandler = nil

local function parseEffects()
	local variants = {}
	
	for node in currentEffects:sub(2, -2):gmatch("[^%,]+") do
		local type, name = node:match("([^%.]+)%.(.+)")

		table.insert(variants, {
			type = type or "effect",
			name = name or node
		})
	end

	table.sort(variants, function(a, b) return a.type < b.type end)

	return variants
end

local function updateEffects(variants)
	effectsLayout:removeChildren()

	local function effectDraw(object)
		screen.drawRectangle(object.x, object.y, object.width, object.height, object.backgroundColor, object.textColor, " ")
		screen.drawText(object.x + 1, object.y + 1, object.textColor, object.text)
	end

	local step = false
	local function add(text)
		local object = effectsLayout:addChild(GUI.object(1, 1, elementWidth, 3))
		object.draw = effectDraw
		object.backgroundColor = step and 0xD2D2D2 or 0xE1E1E1
		object.textColor = 0x787878
		object.text = text

		step = not step
	end

	if #variants > 0 then
		local width = 14
		for i = 1, #variants do
			add(variants[i].type .. string.rep(" ", width - unicode.len(variants[i].type)) .. variants[i].name)
		end
	else
		add(localization.nothingFound)
	end

	effectsLayout.height = #effectsLayout.children * 3
end

local function runtimeEventHandler(workspace, object, e1, e2, e3, e4, e5, e6, e7, e8, ...)
	if e1 == "modem_message" and e6 == "nanomachines" then
		if e7 == "input" then
			local child = inputsContainer.children[e8]
			if not child then
				GUI.alert(localization.notSynced)
			end
		elseif e7 == "effects" then
			currentEffects = e8
			updateEffects(parseEffects())
		elseif e7 == "saved" and e8 == false then
			GUI.alert(localization.saveFailed)
		end

		addMessage(localization.received .. ": ", e7, e8, ...)
		workspace:draw()

		broadcastNext()
	elseif e1 == "scroll" then
		local cell = layout.cells[1][1]
		local to = -math.floor(cell.childrenHeight / 2)

		cell.verticalMargin = cell.verticalMargin + (e5 > 0 and scrollSpeed or -scrollSpeed)
		if cell.verticalMargin > from then
			cell.verticalMargin = from
		elseif cell.verticalMargin < to then
			cell.verticalMargin = to
		end

		workspace:draw()
	end
end

local syncResult, syncDeadline, syncStarted

local function syncUpdate()
	syncDeadline = computer.uptime() + syncDelay
end

local function setLines(text)
	syncTextBox.lines = {text}
	syncTextBox:update()
end

local function syncReset()
	setLines(localization.syncInfo)
	syncStarted = false
	syncResult = {}
	syncUpdate()
end

favouritesAddButton.onTouch = function()
	local text, variants = "", parseEffects()
	for i = 1, #variants do
		text = text .. variants[i].name .. (i < #variants and ", " or "")
	end

	for i = 1, favouritesComboBox:count() do
		local item = favouritesComboBox:getItem(i)
		if item.text == text then
			return
		end
	end

	local inputs = {}
	for i = 1, maxInputs do
		inputs[i] = inputsContainer.children[i].state
	end

	favouritesComboBox:addItem(text)
	table.insert(config.favourites, {
		effects = currentEffects,
		inputs = inputs,
		text = text,
	})

	favouritesComboBox.selectedItem = favouritesComboBox:count()

	saveConfig()
end

favouritesRemoveButton.onTouch = function()
	if favouritesComboBox:count() > 0 then
		table.remove(config.favourites, favouritesComboBox.selectedItem)
		favouritesComboBox:removeItem(favouritesComboBox.selectedItem)
		saveConfig()
	end
end

favouritesComboBox.onItemSelected = function()
	-- Оффаем текущие эффекты
	for i = 1, maxInputs do
		local child = inputsContainer.children[i]
		if child.state then
			child:setState(false)
			broadcastPut("setInput", i, false)
		end
	end

	-- Парисим эффекты конфига
	currentEffects = config.favourites[favouritesComboBox.selectedItem].effects
	updateEffects(parseEffects())

	-- Врубаем новые эффекты
	for i = 1, maxInputs do
		if config.favourites[favouritesComboBox.selectedItem].inputs[i] then
			inputsContainer.children[i]:setState(true)
			broadcastPut("setInput", i, true)
		end
	end

	checkSwitches()
	workspace:draw()
	broadcastNext()
end

for i = 1, #config.favourites do
	favouritesComboBox:addItem(config.favourites[i].text)
end

--------------------------------------------------------------------------------

-- syncContainer.hidden = true

window.actionButtons:moveToFront()

if component.isAvailable("modem") then
	modem = component.get("modem")
	
	if modem.isWireless() then
		modem.open(port)
		textBoxButton.onTouch()
		updateEffects(parseEffects())
		syncReset()

		layout.eventHandler = function(workspace, object, e1, e2, e3, e4, e5, e6, e7, e8, e9)
			if not e1 then
				if computer.uptime() >= syncDeadline then
					syncReset()
					setLines(localization.syncInfo)
					workspace:draw()
				end

				if not syncStarted then
					broadcast("setResponsePort", port)
				end
			elseif e1 == "modem_message" and e6 == "nanomachines" then
				if e7 == "port" and not syncStarted then
					syncStarted = true

					for i = 1, maxInputs do
						broadcastPut("getInput", i)
					end
					broadcastPut("getActiveEffects")
				elseif e7 == "input" then
					syncResult[e8] = e9
				elseif e7 == "effects" then
					currentEffects = e8
					updateEffects(parseEffects())

					syncContainer.hidden = true
					for i = 1, #syncResult do
						inputsContainer.children[i]:setState(syncResult[i])
					end
					checkSwitches()
					workspace:draw()

					layout.eventHandler = runtimeEventHandler
					return
				end

				setLines(string.format(localization.syncProgress .. localization.syncContacts, #syncResult, maxInputs))
				workspace:draw()

				syncUpdate()
				broadcastNext()
			end
		end
	else
		setLines(localization.notWireless)
	end
else
	setLines(localization.noModem)
end
		
workspace:draw()