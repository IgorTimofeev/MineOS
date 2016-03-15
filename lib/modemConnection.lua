
local event = require("event")
local computer = require("computer")
local component = require("component")
local term = require("term")
local serialization = require("serialization")
local unicode = require("unicode")
local ecs, image
local modem = component.modem
local gpu = component.gpu
local modemConnection = {}

----------------------------------------------------------------------------------------------------------------------------------

modemConnection.port = 322
modemConnection.waitForConnectionAcceptingDelay = 10
modemConnection.receiveMessagesFromRobots = true
modemConnection.receiveMessagesFromTablets = true
modemConnection.receiveMessagesFromComputers = true

local infoMessages = {
	userTriesToConnectNoGUI = "Пользователь %s желает установить с вами соединение. Разрешить? Y/N",
	noModem = "Этой библиотеке требуется сетевая карта для работы",
}

----------------------------------------------------------------------------------------------------------------------------------

local xSize, ySize = gpu.getResolution()
local computerIcon, robotIcon, tabletIcon
if not component.isAvailable("robot") then
	image = require("image")
	ecs = require("ECSAPI")
	computerIcon = image.load("MineOS/System/OS/Icons/Computer.pic")
	robotIcon = image.load("MineOS/System/OS/Icons/Robot.pic")
	tabletIcon = image.load("MineOS/System/OS/Icons/Tablet.pic")
end

----------------------------------------------------------------------------------------------------------------------------------

local obj = {}
local function newObj(class, name, ...)
	obj[class] = obj[class] or {}
	obj[class][name] = {...}
end

local function sendAcceptingMessage(address)
	modem.send(address, modemConnection.port, "connectionAccepted", modemConnection.dataToSend)
end

local function sendDecliningMessage(address)
	modem.send(address, modemConnection.port, "connectionDeclined", modemConnection.dataToSend)
end

local function tryToConnect(address)
	modem.send(address, modemConnection.port, "iWantToConnect", modemConnection.dataToSend)
end

local function acceptingOrDecliningDialog(address, accepted)
	local text1, text2
	-- if accepted == true then
	-- 	text1 = "Установлено соединение с пользователем"
	-- 	text2 = "\"" .. ecs.stringLimit("end", address, 18) .. "\""
	-- else
	if accepted == false then
		text1 = "Пользователь \"" .. ecs.stringLimit("end", address, 12) .. "\" отказался"
		text2 = "установить с вами соединение."
	elseif accepted == nil then
		text1 = "Пользователь \"" .. ecs.stringLimit("end", address, 12) .. "\" не ответил"
		text2 = "на ваш запрос"
	end

	ecs.universalWindow("auto", "auto", 36, 0x262626, true,
		{"EmptyLine"},
		{"CenterText", ecs.colors.orange, "WirelessConnection"},
		{"EmptyLine"},
		{"CenterText", 0xffffff, text1 },
		{"CenterText", 0xffffff, text2 },
		{"EmptyLine"},
		{"Button", {ecs.colors.orange, 0x262626, "OK"}}
	)
end

local function askForAcceptConnection(address)
	if not component.isAvailable("robot") then
		local data = ecs.universalWindow("auto", "auto", 36, 0x262626, true,
			{"EmptyLine"},
			{"CenterText", ecs.colors.orange, "WirelessConnection"},
			{"EmptyLine"},
			{"CenterText", 0xffffff, "Пользователь \"" .. ecs.stringLimit("end", address, 12) .. "\" желает" },
			{"CenterText", 0xffffff, "установить с вами беспроводное соединение." },
			{"EmptyLine"},
			{"CenterText", 0xffffff, "Разрешить подключение?" },
			{"EmptyLine"},
			{"Button", {ecs.colors.orange, 0x262626, "Да"}, {0x999999, 0xffffff, "Нет"}}
		)

		if data[1] == "Да" then
			modemConnection.remoteAddress = address
			sendAcceptingMessage(address)
			computer.pushSignal("connectionEstabilishedExitFromGUI")
		else
			sendDecliningMessage(address)
		end
	else
		term.clear()
		term.setCursor(1, 1)
		print("Пользователь \"" .. string.sub(address, 1, 12) .. "\" желает установить с вами беспроводное соединение. Разрешить подключение? Y/N")
		local answer = term.read()
		if string.sub(string.lower(answer), 1, 1) == "y" then
			modemConnection.remoteAddress = address
			sendAcceptingMessage(address)
			print(" ")
			print("Соединение установлено.")
			print(" ")
			-- computer.pushSignal("key_down", component.getPrimary("keyboard").address, 13, 28, "ECS")
		else
			sendDecliningMessage(address)
			term.clear()
			term.setCursor(1, 1)
		end
	end
end

local function infoAboutClient(userData)

	local arguments = {
		"auto", "auto", 36, 0x262626, true, {"EmptyLine"}, {"CenterText", ecs.colors.orange, "Информация о пользователе"}, {"EmptyLine"},
	}

	if userData.isRobot then
		table.insert(arguments, {"CenterText", 0xffffff, "Тип: робот"})
	elseif userData.isTablet then
		table.insert(arguments, {"CenterText", 0xffffff, "Тип: планшет"})
	elseif not userData.isTablet and not userData.isRobot then
		table.insert(arguments, {"CenterText", 0xffffff, "Тип: компьютер"})
	end

	table.insert(arguments, {"CenterText", 0xffffff, "Имя: " .. userData.name})
	table.insert(arguments, {"CenterText", 0xffffff, "Адрес: " .. ecs.stringLimit("end", userData.address, 12)})
	table.insert(arguments, {"CenterText", 0xffffff, "Память: " .. userData.ram .. " KB"})

	if userData.isTablet or userData.isRobot and userData.hasUpgrades then
		table.insert(arguments, {"EmptyLine"})
		table.insert(arguments, {"CenterText", ecs.colors.orange, "Улучшения"})
		table.insert(arguments, {"EmptyLine"})
		if userData.inventoryController then
			table.insert(arguments, {"CenterText", 0xffffff, "Контроллер инвентаря"})
		end
		if userData.tankController then
			table.insert(arguments, {"CenterText", 0xffffff, "Контроллер бака"})
		end
		if userData.crafting then
			table.insert(arguments, {"CenterText", 0xffffff, "Крафтинг"})
		end
		if userData.redstone then
			table.insert(arguments, {"CenterText", 0xffffff, "Редстоун-плата"})
		end
		if userData.navigation then
			table.insert(arguments, {"CenterText", 0xffffff, "Навигация"})
		end
		if userData.piston then
			table.insert(arguments, {"CenterText", 0xffffff, "Поршень"})
		end
		if userData.geolyzer then
			table.insert(arguments, {"CenterText", 0xffffff, "Геоанализатор"})
		end
	end

	table.insert(arguments, {"EmptyLine"})
	table.insert(arguments, {"Button", {ecs.colors.orange, 0x262626, "OK"}})
	

	ecs.universalWindow(table.unpack(arguments))
end

local function modemMessageHandler(_, localAddress, remoteAddress, port, distance, ...)
	local messages = {...}
	if #messages > 0 then
		if port == modemConnection.port then
			if messages[1] == "iWantToConnect" and not modemConnection.remoteAddress then
				askForAcceptConnection(remoteAddress)
			elseif messages[1] == "iAmHereAddMePlease" and not modemConnection.remoteAddress then
				if not modemConnection.availableUsers[remoteAddress] then
					local userData = serialization.unserialize(messages[2])
					if 
						(not userData.isRobot and not userData.isTablet and modemConnection.receiveMessagesFromComputers)
						or
						(userData.isRobot and modemConnection.receiveMessagesFromRobots)
						or
						(userData.isTablet and modemConnection.receiveMessagesFromTablets)
					then
						modemConnection.availableUsers[userData.address] = userData
						modem.send(remoteAddress, modemConnection.port, "iAmHereAddMePlease", modemConnection.dataToSend)
						computer.pushSignal("userlistChanged")
					end
				end
			elseif messages[1] == "iAmDisconnecting" then
				if modemConnection.availableUsers[remoteAddress] then
					modemConnection.availableUsers[remoteAddress] = nil
					computer.pushSignal("userlistChanged")
				end
			end
		end
	end
end

local function createSendingArray()
	modemConnection.dataToSend = {}
	modemConnection.dataToSend.address = modemConnection.localAddress
	modemConnection.dataToSend.name = component.filesystem.getLabel()
	modemConnection.dataToSend.ram = math.floor(computer.totalMemory() / 1024)

	if component.isAvailable("robot") then
		modemConnection.dataToSend.isRobot = true
		if component.isAvailable("inventory_controller") then
			modemConnection.dataToSend.inventoryController = true; modemConnection.dataToSend.hasUpgrades = true
		end
	
		if component.isAvailable("tank_controller") then
			modemConnection.dataToSend.tankController = true; modemConnection.dataToSend.hasUpgrades = true
		end
	
		if component.isAvailable("crafting") then
			modemConnection.dataToSend.crafting = true; modemConnection.dataToSend.hasUpgrades = true
		end
	
		if component.isAvailable("redstone") then
			modemConnection.dataToSend.redstone = true; modemConnection.dataToSend.hasUpgrades = true
		end
	end
	
	if component.isAvailable("tablet") then
		modemConnection.dataToSend.isTablet = true
		if component.isAvailable("navigation") then
			modemConnection.dataToSend.navigation = true; modemConnection.dataToSend.hasUpgrades = true
		end
	
		if component.isAvailable("piston") then
			modemConnection.dataToSend.piston = true; modemConnection.dataToSend.hasUpgrades = true
		end
	end
	
	if component.isAvailable("geolyzer") then
		modemConnection.dataToSend.geolyzer = true; modemConnection.dataToSend.hasUpgrades = true
	end
	
	modemConnection.dataToSend = serialization.serialize(modemConnection.dataToSend)
end

--Нарисовать окружность, алгоритм спизжен с вики
local function circle(xCenter, yCenter, radius, color)
	gpu.setBackground(color)
	local function insertPoints(x, y)
		gpu.set(xCenter + x * 2, yCenter + y, "  ")
		gpu.set(xCenter + x * 2, yCenter - y, "  ")
		gpu.set(xCenter - x * 2, yCenter + y, "  ")
		gpu.set(xCenter - x * 2, yCenter - y, "  ")

		gpu.set(xCenter + x * 2 + 1, yCenter + y, " ")
		gpu.set(xCenter + x * 2 + 1, yCenter - y, " ")
		gpu.set(xCenter - x * 2 + 1, yCenter + y, " ")
		gpu.set(xCenter - x * 2 + 1, yCenter - y, " ")
	end

	local x = 0
	local y = radius
	local delta = 3 - 2 * radius;
	while (x < y) do
		insertPoints(x, y);
		insertPoints(y, x);
		if (delta < 0) then
			delta = delta + (4 * x + 6)
		else 
			delta = delta + (4 * (x - y) + 10)
			y = y - 1
		end
		x = x + 1
	end

	if x == y then insertPoints(x, y) end
end

local function drawCircles(xCircle, yCircle, minumumRadius, maximumRadius, step, currentRadius)
	for radius = minumumRadius, maximumRadius, step do
		if radius == currentRadius then
			circle(xCircle, yCircle, radius, 0x888888)
		else
			circle(xCircle, yCircle, radius, 0xDDDDDD)
		end
	end
end

local function drawIconAndAddress(x, y, background, foreground, userData)
	if userData.isRobot then
		image.draw(x + 3, y, robotIcon)
	elseif userData.isTablet then
		image.draw(x + 3, y, tabletIcon)
	else
		image.draw(x + 3, y, computerIcon)
	end

	ecs.colorTextWithBack(x, y + 5, foreground, background, ecs.stringLimit("end", userData.address, 14))
	
	return x, y, x + 13, y + 5
end

local function drawHorizontalIcons()
	local height = 8
	local y = math.floor(ySize / 2 - height / 2)
	local background = 0x66A8FF
	ecs.square(1, y, xSize, height, background)

	local iconWidth = 14
	local spaceBetween = 2
	local totalWidth = ecs.getArraySize(modemConnection.availableUsers) * (iconWidth + spaceBetween) - spaceBetween
	local x = math.floor(xSize / 2 - totalWidth / 2) + 1

	obj.Users = {}

	local counter = 0
	local limit = math.floor(xSize / (iconWidth + spaceBetween))
	y = y + 1
	for address in pairs(modemConnection.availableUsers) do
		if counter < limit then
			newObj("Users", address, drawIconAndAddress(x, y, background, 0xFFFFFF, modemConnection.availableUsers[address]))
		end
		x = x + iconWidth + spaceBetween
		counter = counter + 1
	end
end

local function drawSelectedIcon(x, y, background, foreground, userData)
	local selectionWidth = 16
	local skokaOtnat = (selectionWidth - 14) / 2
	local oldPixels = ecs.rememberOldPixels(x - skokaOtnat, y, x + selectionWidth - 2, y + 13)
	ecs.square(x - skokaOtnat, y, selectionWidth, 8, background)
	drawIconAndAddress(x, y + 1, background, foreground, userData)
	obj.CykaKnopkaInfo = { ecs.drawButton(x - skokaOtnat, y + 8, selectionWidth, 3, "Информация", 0xff6699, 0xFFFFFF) }
	obj.CykaKnopkaConnect = { ecs.drawButton(x - skokaOtnat, y + 11, selectionWidth, 3, "Подключиться", 0xff3333, 0xFFFFFF) }
	obj.CykaKnopkaConnect.address = userData.address
	return oldPixels
end

local function connectionGUI()
	ecs.square(1, 1, xSize, ySize, 0xEEEEEE)
	
	local xCircle, yCircle = math.floor(xSize / 2), ySize - 3
	local minumumRadius, maximumRadius = 7, xCircle * 0.8
	local step = 4
	local currentRadius = minumumRadius
	local unserializedDataToSend = serialization.unserialize(modemConnection.dataToSend)

	drawIconAndAddress(xCircle - 6, ySize - 6, 0xEEEEEE, 0x262626, unserializedDataToSend)

	while true do
		if ecs.getArraySize(modemConnection.availableUsers) > 0 then
			currentRadius = 0
			drawCircles(xCircle, yCircle, minumumRadius, maximumRadius, step, currentRadius)
			
			drawHorizontalIcons()

			local oldPixels, needToUpdate
			while true do
				if not oldPixels and needToUpdate then
					if ecs.getArraySize(modemConnection.availableUsers) <= 0 then
						ecs.square(1, 1, xSize, ySize, 0xEEEEEE)
						drawIconAndAddress(xCircle - 6, ySize - 6, 0xEEEEEE, 0x262626, unserializedDataToSend)
						currentRadius = minumumRadius
						break
					else
						drawHorizontalIcons()
						needToUpdate = false
					end
				end

				local e = { event.pull() }
				if e[1] == "touch" then
					
					if obj.CykaKnopkaInfo and obj.CykaKnopkaConnect then
						if ecs.clickedAtArea(e[3], e[4], obj.CykaKnopkaInfo[1], obj.CykaKnopkaInfo[2], obj.CykaKnopkaInfo[3], obj.CykaKnopkaInfo[4]) then
							ecs.drawButton(obj.CykaKnopkaInfo[1], obj.CykaKnopkaInfo[2], 16, 3, "Информация", 0x262626, 0xFFFFFF)
							os.sleep(0.2)
							if oldPixels then ecs.drawOldPixels(oldPixels); oldPixels = nil end
							infoAboutClient(modemConnection.availableUsers[obj.CykaKnopkaConnect.address])

						elseif ecs.clickedAtArea(e[3], e[4], obj.CykaKnopkaConnect[1], obj.CykaKnopkaConnect[2], obj.CykaKnopkaConnect[3], obj.CykaKnopkaConnect[4]) then
							ecs.drawButton(obj.CykaKnopkaConnect[1], obj.CykaKnopkaConnect[2], 16, 3, "Подключиться", 0x262626, 0xFFFFFF)
							os.sleep(0.2)
							if oldPixels then ecs.drawOldPixels(oldPixels); oldPixels = nil end

							local oldInfoPixels = ecs.info("auto", "auto", "", "Ожидание ответа от пользователя...")							
							tryToConnect(obj.CykaKnopkaConnect.address)

							local function filter(name, _, remoteAddress)
								if name == "modem_message" and remoteAddress == obj.CykaKnopkaConnect.address then
									return true
								end
							end

							local e2 = { event.pullFiltered(modemConnection.waitForConnectionAcceptingDelay, filter) }
							ecs.drawOldPixels(oldInfoPixels)
						
							if e2[6] == "connectionAccepted" then
								modemConnection.remoteAddress = e2[3]
								-- acceptingOrDecliningDialog(obj.CykaKnopkaConnect.address, true)
								computer.pushSignal("connectionEstabilishedExitFromGUI")
							elseif e2[6] == "connectionDeclined" then
								acceptingOrDecliningDialog(obj.CykaKnopkaConnect.address, false)
							else
								acceptingOrDecliningDialog(obj.CykaKnopkaConnect.address, nil)
							end
						end

						obj.CykaKnopkaInfo, obj.CykaKnopkaConnect = nil, nil
					end

					if oldPixels then ecs.drawOldPixels(oldPixels); oldPixels = nil end

					for address in pairs(obj.Users) do
						if ecs.clickedAtArea(e[3], e[4], obj.Users[address][1], obj.Users[address][2], obj.Users[address][3], obj.Users[address][4]) then
							oldPixels = drawSelectedIcon(obj.Users[address][1], obj.Users[address][2] - 1, 0xCCCCFF, 0x262626, modemConnection.availableUsers[address])
							break
						end
					end
				elseif e[1] == "userlistChanged" then
					needToUpdate = true
				elseif e[1] == "connectionEstabilishedExitFromGUI" then
					ecs.prepareToExit()
					modemConnection.disconnect()
					return
				end
			end
		else
			drawCircles(xCircle, yCircle, minumumRadius, maximumRadius, step, currentRadius)
			currentRadius = currentRadius + step
			if currentRadius > (maximumRadius + step) then currentRadius = minumumRadius end
			os.sleep(0)
		end
	end
end

----------------------------------------------------------------------------------------------------------------------------------

function modemConnection.stopReceivingData()
	event.ignore("modem_message", modemMessageHandler)
end

function modemConnection.startReceivingData()
	modemConnection.stopReceivingData()
	modemConnection.remoteAddress = nil
	event.listen("modem_message", modemMessageHandler)
end

function modemConnection.disconnect()
	modem.broadcast(modemConnection.port, "iAmDisconnecting")
end

function modemConnection.sendPersonalData()
	modem.broadcast(modemConnection.port, "iAmHereAddMePlease", modemConnection.dataToSend)
end

function modemConnection.changePort(newPort)
	modem.close(modemConnection.port)
	modem.open(newPort)
	modemConnection.port = newPort
	modemConnection.remoteAddress = nil
	modemConnection.availableUsers = {}
	modemConnection.localAddress = component.getPrimary("modem").address
	createSendingArray()
end

function modemConnection.search()
	modemConnection.availableUsers = {}
	modemConnection.remoteAddress = nil
	modemConnection.disconnect()
	modemConnection.sendPersonalData()
	connectionGUI()
end

function modemConnection.init()
	if component.isAvailable("modem") then
		modemConnection.changePort(modemConnection.port)
	else
		ecs.error(infoMessages.noModem)
		return
	end
end

----------------------------------------------------------------------------------------------------------------------------------

modemConnection.init()

----------------------------------------------------------------------------------------------------------------------------------

return modemConnection

