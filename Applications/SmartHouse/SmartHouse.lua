
local sides = require("sides")
local component = require("component")
local advancedLua = require("advancedLua")
local image = require("image")
local buffer = require("doubleBuffering")
local keyboard = require("keyboard")
local GUI = require("GUI")
local ecs = require("ECSAPI")
local MineOSCore = require("MineOSCore")
local computer = require("computer")
local fs = require("filesystem")

-----------------------------------------------------------------------------------------------------------------------------------

local window

local paths = {}
paths.resources = MineOSCore.getCurrentApplicationResourcesDirectory()
-- paths.resources = "/SmartHouse/"
paths.modules = paths.resources .. "Modules/"

local colors = {
	-- background = image.load("/MineOS/Pictures/Ciri.pic"),
	background = 0x1b1b1b,
	connectionLines = 0xFFFFFF,
	devicesBackgroundTransparency = 40,
	devicesBackground = 0x0,
	devicesButtonBackground = 0xFFFFFF,
	devicesButtonText = 0x262626,
	devicesInfoText = 0xDDDDDD,
	groupsTransparency = nil,
}

local signals = {}
local groups = {}
local modules = {}
local offset = {x = 0, y = 0}

-----------------------------------------------------------------------------------------------------------------------------------

local function loadModule(modulePath)
	local success, module = pcall(loadfile(modulePath .. "/Main.lua"))
	if success then
		module.modulePath = modulePath
		module.icon = image.load(module.modulePath .. "/Icon.pic")
		modules[fs.name(module.modulePath)] = module
	else
		error("Module loading failed: " .. module)
	end
end

local function loadModules()
	modules = {}
	for file in fs.list(paths.modules) do
		local modulePath = paths.modules .. file
		if fs.isDirectory(modulePath) then
			loadModule(modulePath)
		end
	end
end

local function highlightDiviceAsSignal(deviceContainer, color)
	buffer.square(deviceContainer.x - 1, deviceContainer.y, deviceContainer.width + 2, deviceContainer.height, color)
	buffer.text(deviceContainer.x - 1, deviceContainer.y - 1, color, string.rep("▄", deviceContainer.width + 2))
	buffer.text(deviceContainer.x - 1, deviceContainer.y + deviceContainer.height, color, string.rep("▀", deviceContainer.width + 2))
end

local function createNewGroup(name, color)
	table.insert(groups, {
		color = color,
		name = name,
		devices = {}
	})
end

local function removeDeviceFromGroup(address)
	for groupIndex = 1, #groups do
		local deviceIndex = 1
		while deviceIndex <= #groups[groupIndex].devices do
			if groups[groupIndex].devices[deviceIndex].componentProxy.address == address then
				table.remove(groups[groupIndex].devices, deviceIndex)
				deviceIndex = deviceIndex - 1
				if #groups[groupIndex].devices == 0 then
					groups[groupIndex] = nil
					return
				end
			end
			deviceIndex = deviceIndex + 1
		end
	end
end

local function addDeviceToGroup(deviceContainer, name, color)
	local groupIndex
	
	for i = 1, #groups do
		if groups[i].name == name then groupIndex = i; break end
	end

	if not groupIndex then
		createNewGroup(name, color)
		groupIndex = #groups
	end

	table.insert(groups[groupIndex].devices, deviceContainer)
	groups[groupIndex].color = color
end

local function containerPushSignal(container, ...)
	for signalIndex = 1, #signals do
		if signals[signalIndex].fromDevice == container then
			for toDeviceIndex = 1, #signals[signalIndex].toDevices do
				if signals[signalIndex].toDevices[toDeviceIndex].module.onSignalReceived then
					signals[signalIndex].toDevices[toDeviceIndex].module.onSignalReceived(signals[signalIndex].toDevices[toDeviceIndex], ...)
				end
			end
		end
	end
end

local function changeChildrenState(container, state)
	for i = 3, #container.children do
		container.children[i].isHidden = state
	end
end

local function createDevice(x, y, componentName, componentProxy, name)
	if not modules[componentName] then error("No such module: " .. componentName) end
	local container = window:addContainer(x, y, 16, 9)

	container.name = name
	container.module = modules[componentName]
	container.componentProxy = componentProxy
	container.componentName = componentName
	container.detailsIsHidden = true

	x, y = 1, 1
	container.deviceImage = container:addImage(x, y, container.module.icon); y = y + 8
	local stateButton = container:addButton(1, y, container.width, 1, colors.devicesButtonBackground, colors.devicesButtonText, colors.devicesButtonText, colors.devicesButtonBackground, "*")
	stateButton.onTouch = function()
		container.detailsIsHidden = not container.detailsIsHidden
		changeChildrenState(container, container.detailsIsHidden)
		if container.detailsIsHidden then
			stateButton.localPosition.y = container.backgroundPanel.localPosition.y
		else
			stateButton.localPosition.y = container.backgroundPanel.localPosition.y + container.backgroundPanel.height
		end
	end

	container.backgroundPanel = container:addPanel(1, y, container.width, 1, colors.devicesBackground, colors.devicesBackgroundTransparency)


	container:addLabel(2, y, container.width - 2, 1, 0xFFFFFF, container.name):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top); y = y + 1
	container:addLabel(2, y, container.width - 2, 1, 0x999999, container.componentProxy.address):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top); y = y + 2
	
	container.module.start(container)
	container.module.update(container, {})

	y = container.children[#container.children].localPosition.y + (container.children[#container.children].height or 0) + 1
	container.backgroundPanel.height = container.backgroundPanel.height + (y - container.backgroundPanel.y - 1)

	container.deviceImage.onTouch = function(eventData)
		if eventData[5] == 0 then
			window.deviceToDrag = container
			container:moveToFront()
			if keyboard.isShiftDown() then
				local x, y = container.x + 8, container.y + 4
				signals.fromDevice = container
				signals.toPoint = {x = x, y = y}
			end
		else
			local action = GUI.contextMenu(eventData[3], eventData[4], {"Add to group"}, {"Remove from group"}):show()
			if action == "Add to group" then
				local data = ecs.universalWindow("auto", "auto", 36, 0x262626, true,
					{"EmptyLine"},
					{"CenterText", ecs.colors.orange, "Add to group"},
					{"EmptyLine"},
					{"Input", 0xFFFFFF, ecs.colors.orange, "Group #1"},
					{"Color", "Group color", 0xAAAAAA},
					{"EmptyLine"},
					{"Button", {ecs.colors.orange, 0xffffff, "OK"}, {0x999999, 0xffffff, "Cancel"}}
				)

				if data[3] == "OK" then
					addDeviceToGroup(container, data[1], data[2])
				end
			elseif action == "Remove from group" then
				removeDeviceFromGroup(container.componentProxy.address)
			end
		end
	end

	local oldDraw = container.draw
	container.draw = function()
		if container.highlightColor then
			highlightDiviceAsSignal(container, container.highlightColor)
		end
		oldDraw(container)
	end
	container.sendSignal = containerPushSignal

	changeChildrenState(container, container.detailsIsHidden)
	return container
end

local function drawConnectionLine(x1, y1, x2, y2, thin, color, cutAfterPixels)
	local symbol = ""
	if x1 < x2 then
		if y1 < y2 then
			symbol = thin and "┐" or "█"
		else
			symbol = thin and "┘" or "▀"
		end
	else
		if y1 < y2 then
			symbol = thin and "┌" or "█"
		else
			symbol = thin and "└" or "▀"
		end
	end

	local x, y, counter, xIncrement, yIncrement = x1, y1, 1, (x1 <= x2 and 1 or -1), (y1 <= y2 and 1 or -1)

	while true do
		local bg = buffer.get(x, y)
		buffer.set(x, y, bg, color, thin and "─" or "▀")
		x = x + xIncrement

		if counter < cutAfterPixels then 
			counter = counter + 1
		else
			x = x + xIncrement
		end

		if x1 <= x2 then
			if x >= x2 - 1 then break end
		else
			if x < x2 + 1 then break end
		end
	end

	buffer.text(x, y, color, symbol)
	y = y + yIncrement

	while true do
		local bg = buffer.get(x, y)
		buffer.set(x, y, bg, color, thin and "│" or "█")
		y = y + yIncrement
	
		if counter < cutAfterPixels then 
			counter = counter + 1
		else
			y = y + yIncrement
		end

		if y1 <= y2 then
			if y >= y2 then break end
		else
			if y < y2 then break end
		end
	end
end

local function moveDevice(container, x, y)
	container.localPosition.x, container.localPosition.y = container.localPosition.x + x, container.localPosition.y + y
end

local function moveDevices(x, y)
	for i = 1, #window.children do
		moveDevice(window.children[i], x, y)
	end
end

local function getGroupGeometry(devices)
	local geometry = {}

	for deviceIndex = 1, #devices do
		geometry.x = math.min(geometry.x or devices[deviceIndex].localPosition.x, devices[deviceIndex].localPosition.x)
		geometry.y = math.min(geometry.y or devices[deviceIndex].localPosition.y, devices[deviceIndex].localPosition.y)

		geometry.xMax = math.max(geometry.xMax or devices[deviceIndex].localPosition.x, devices[deviceIndex].localPosition.x)
		geometry.yMax = math.max(geometry.yMax or devices[deviceIndex].localPosition.y, devices[deviceIndex].localPosition.y)
	end

	local xOffset, yOffset = 2, 2
	geometry.width, geometry.height = geometry.xMax - geometry.x + 16 + xOffset * 2, geometry.yMax - geometry.y + 9 + yOffset * 2
	geometry.x, geometry.y = geometry.x - xOffset, geometry.y - yOffset - 1

	return geometry
end

local function drawGroups()
	for groupIndex = 1, #groups do
		local groupGeometry = getGroupGeometry(groups[groupIndex].devices)
		buffer.square(groupGeometry.x, groupGeometry.y, groupGeometry.width, groupGeometry.height, groups[groupIndex].color)
		GUI.label(groupGeometry.x, groupGeometry.y + 1, groupGeometry.width, 1, 0x000000, groups[groupIndex].name):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top):draw()
	end
end

local function drawSignals()
	local colorPrimary = 0xFF4940
	local step = 16

	if signals.fromDevice then
		drawConnectionLine(
			signals.fromDevice.x + 8,
			signals.fromDevice.y + 4,
			signals.toPoint.x,
			signals.toPoint.y,
			false, colorPrimary, step
		)
		signals.fromDevice.highlightColor = colorPrimary
	end

	for signalIndex = 1, #signals do
		--Подсветка подключенных устройств
		for toDeviceIndex = 1, #signals[signalIndex].toDevices do
			signals[signalIndex].toDevices[toDeviceIndex].highlightColor = colorPrimary
			drawConnectionLine(
				signals[signalIndex].fromDevice.x + 8,
				signals[signalIndex].fromDevice.y + 4,
				signals[signalIndex].toDevices[toDeviceIndex].x + 8,
				signals[signalIndex].toDevices[toDeviceIndex].y + 4,
				false, colorPrimary, step
			)
		end
		-- Подсветка стартового устройства
		signals[signalIndex].fromDevice.highlightColor = colorPrimary
	end
end

local function createWindow()
	window = GUI.fullScreenWindow()

	-- Создаем главное и неебически важное устройство домашнего писюка
	local homePC = createDevice(math.floor(window.width / 2 - 8), math.floor(window.height / 2 - 4), "homePC", component.proxy(computer.address()), "Сервак")
	homePC.module.icon = image.load(homePC.module.modulePath .. "Server.pic")
	homePC.deviceImage.image = homePC.module.icon

	-- Перед отрисовкой окна чистим буфер фоном и перехуячиваем позиции объектов групп
	window.onDrawStarted = function()
		buffer.clear(colors.background)
		drawGroups()

		local xPC, yPC = homePC.x + 8, homePC.y + 4
		for i = 1, #window.children do
			drawConnectionLine(xPC, yPC, window.children[i].x + 8, window.children[i].y + 4, true, colors.connectionLines, math.huge)
		end	

		drawSignals()
	end

	window.onAnyEvent = function(eventData)
		if eventData[1] == "key_down" then
			if eventData[4] == 19 then
				colors.background = math.random(0x0, 0xFFFFFF)
			elseif eventData[4] == 200 then
				moveDevices(0, -2)
			elseif eventData[4] == 208 then
				moveDevices(0, 2)
			elseif eventData[4] == 203 then
				moveDevices(-4, 0)
			elseif eventData[4] == 205 then
				moveDevices(4, 0)
			end
		elseif eventData[1] == "touch" then
			window.dragOffset = {x = eventData[3], y = eventData[4]}
		elseif eventData[1] == "drag" then
			if keyboard.isShiftDown() then
				if signals.fromDevice then
					signals.toPoint.x, signals.toPoint.y = eventData[3], eventData[4]
				end
			else
				if eventData[5] == 0 and window.deviceToDrag then
					window.deviceToDrag.localPosition.x, window.deviceToDrag.localPosition.y = window.deviceToDrag.localPosition.x + (eventData[3] - window.dragOffset.x), window.deviceToDrag.y + (eventData[4] - window.dragOffset.y)
				end
			end
			window.dragOffset = {x = eventData[3], y = eventData[4]}
		elseif eventData[1] == "drop" then
			if keyboard.isShiftDown() and signals.fromDevice then
				--Создаем новый сигнал, если такового еще не существовало
				local signalIndex
				for i = 1, #signals do
					if signals[i].fromDevice == signals.fromDevice then signalIndex = i; break end
				end
				if not signalIndex then
					table.insert(signals, {fromDevice = signals.fromDevice, toDevices = {}})
					signalIndex = #signals
				end

				--Ищем контейнер, на который дропнулось
				local container
				for i = 1, #window.children do
					if window.children[i]:isClicked(eventData[3], eventData[4]) then
						container = window.children[i]
						break
					end
				end

				-- Если контейнер найден, то
				if container then
					--Чекаем, принимает ли модуль этого контейнера сигналы, и если принимает, то
					if container.module.allowSignalConnections then
						--Проверяем, нет ли часом этого устройства в УЖЕ подключенных
						local deviceExists = false
						for i = 1, #signals[signalIndex].toDevices do
							if signals[signalIndex].toDevices[i] == container then deviceExists = true end
						end

						--И если нет, а также если это устройство не является устройством, от которого ВЕЛОСЬ подключение, то
						if not deviceExists and container ~= signals[signalIndex].fromDevice then
							table.insert(signals[signalIndex].toDevices, container)
						end
					else
						GUI.error("This device doesn't support virtual signal receiving", {title = {text = "Warning", color = 0xFF5555}})
						if #signals[signalIndex].toDevices <= 0 then
							signals[signalIndex].fromDevice.highlightColor = nil
							signals[signalIndex] = nil
						end
					end
				else
					-- А если мы дропнули на пустую точку, то оффаем выделение
					if #signals[signalIndex].toDevices <= 0 then
						signals[signalIndex].fromDevice.highlightColor = nil
						signals[signalIndex] = nil
					end
				end

			end


			-- Удаляем временные сигнальные переменные
			signals.fromDevice, signals.toPoint = nil, nil
			-- Сбрасываем также общее смещение драга
			window.dragOffset = nil
			window.deviceToDrag = nil
		end

		for i = 1, #window.children do
			if not window.children[i].detailsIsHidden or window.children[i].module.updateWhenModuleDetailsIsHidden then
				window.children[i].module.update(window.children[i], eventData)
			end
		end

		window:draw()
		buffer.draw()
	end
end

local function refreshComponents()
	local devices = {}
	for componentAddress, componentName in pairs(component.list()) do
		if modules[componentName] then
			table.insert(devices, {componentAddress = componentAddress, componentName = componentName})
		end
	end
	local x, y = math.floor(buffer.screen.width / 2 - #devices * 18 / 2 + 1), 2
	for i = 1, #devices do 
		createDevice(x, y, devices[i].componentName, component.proxy(devices[i].componentAddress), devices[i].componentName)
		x = x + 18
	end
end

-----------------------------------------------------------------------------------------------------------------------------------

buffer.start()

loadModules()
createWindow()
refreshComponents()
window:draw()
buffer.draw()
window:handleEvents(1)




















