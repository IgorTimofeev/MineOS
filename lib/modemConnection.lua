
local event = require("event")
local computer = require("computer")
local component = require("component")
local serialization = require("serialization")
local unicode = require("unicode")
local ecs, image
local modem = component.modem
local gpu = component.gpu
local wirelessConnection = {}

----------------------------------------------------------------------------------------------------------------------------------

local infoMessages = {
	userTriesToConnectNoGUI = "Пользователь %s желает установить с вами соединение. Разрешить?",
	noModem = "Этой библиотеке требуется сетевая карта для работы",
}

wirelessConnection.port = 322
wirelessConnection.sendingDataDelay = 1.0
wirelessConnection.receiveMessagesFromRobots = true

----------------------------------------------------------------------------------------------------------------------------------

local xSize, ySize = gpu.getResolution()
local computerIcon
if not component.isAvailable("robot") then
	image = require("image")
	ecs = require("ECSAPI")
	computerIcon = image.load("MineOS/System/OS/Icons/Script.pic")
end

----------------------------------------------------------------------------------------------------------------------------------

local obj = {}
local function newObj(class, name, ...)
	obj[class] = obj[class] or {}
	obj[class][name] = {...}
end

local function askForConnection(userData)
	local data = ecs.universalWindow("auto", "auto", 36, 0x262626, true,
		{"EmptyLine"},
		{"CenterText", ecs.colors.orange, "WirelessConnection"},
		{"EmptyLine"},
		{"CenterText", 0xffffff, "Пользователь " .. ecs.stringLimit("end", userData.address, 6) .. " желает" },
		{"CenterText", 0xffffff, "установить с вами беспроводное соединение." },
		{"EmptyLine"},
		{"CenterText", 0xffffff, "Разрешить подключение?" },
		{"EmptyLine"},
		{"Button", {ecs.colors.orange, 0x262626, "Да"}, {0x999999, 0xffffff, "Нет"}}
	)
end

local function modemMessageHandler(_, localAddress, remoteAddress, port, distance, ...)
	local messages = {...}
	if #messages > 0 then
		if port == wirelessConnection.port then
			if messages[1] == "requestingPermissionToConnect" then
				askForConnection(messages[2])
			elseif messages[1] == "iAmHereAddMePlease" then
				if not wirelessConnection.availableUsers[remoteAddress] then
					local userData = serialization.unserialize(messages[2])
					if not userData.isRobot or (userData.isRobot and wirelessConnection.receiveMessagesFromRobots) then
						wirelessConnection.availableUsers[userData.address] = userData
						modem.send(remoteAddress, wirelessConnection.port, "iAmHereAddMePlease", wirelessConnection.dataToSend)
						computer.pushSignal("userlistChanged")
					end
				end
			elseif messages[1] == "iAmDisconnecting" then
				if wirelessConnection.availableUsers[remoteAddress] then
					wirelessConnection.availableUsers[remoteAddress] = nil
					computer.pushSignal("userlistChanged")
				end
			end
		end
	end
end

local function createSendingArray()
	wirelessConnection.dataToSend = {}
	wirelessConnection.dataToSend.address = wirelessConnection.localAddress
	wirelessConnection.dataToSend.name = component.filesystem.getLabel()
	if component.isAvailable("robot") then
		wirelessConnection.dataToSend.isRobot = true
		if component.isAvailable("inventory_controller") then
			wirelessConnection.dataToSend.inventoryController = true
		end
		if component.isAvailable("tank_controller") then
			wirelessConnection.dataToSend.tankController = true
		end
		if component.isAvailable("crafting") then
			wirelessConnection.dataToSend.crafting = true
		end
		if component.isAvailable("redstone") then
			wirelessConnection.dataToSend.redstone = true
		end
	end
	wirelessConnection.dataToSend = serialization.serialize(wirelessConnection.dataToSend)
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
			circle(xCircle, yCircle, radius, 0xAAAAAA)
		else
			circle(xCircle, yCircle, radius, 0xDDDDDD)
		end
	end
end

local function drawIconAndAddress(x, y, background, foreground, text)
	image.draw(x + 3, y, computerIcon)
	ecs.colorTextWithBack(x, y + 5, foreground, background, ecs.stringLimit("end", text, 14))
	return x, y, x + 13, y + 5
end

local function drawHorizontalIcons()
	local height = 8
	local y = math.floor(ySize / 2 - height / 2)
	local background = 0x66A8FF
	ecs.square(1, y, xSize, height, background)

	local iconWidth = 14
	local spaceBetween = 2
	local totalWidth = ecs.getArraySize(wirelessConnection.availableUsers) * (iconWidth + spaceBetween) - spaceBetween
	local x = math.floor(xSize / 2 - totalWidth / 2) + 1

	obj.Users = {}

	local counter = 0
	local limit = math.floor(xSize / (iconWidth + spaceBetween))
	y = y + 1
	for address in pairs(wirelessConnection.availableUsers) do
		if counter < limit then
			newObj("Users", address, drawIconAndAddress(x, y, background, 0xFFFFFF, address))
		end
		x = x + iconWidth + spaceBetween
		counter = counter + 1
	end
end

local function drawSelectedIcon(x, y, background, foreground, text)
	local selectionWidth = 16
	local oldPixels = ecs.rememberOldPixels(x - 1, y, x + selectionWidth - 2, y + 13)
	ecs.square(x - 1, y, selectionWidth, 8, background)
	drawIconAndAddress(x, y + 1, background, foreground, text)
	obj.CykaKnopkaInfo = { ecs.drawButton(x - 1, y + 8, selectionWidth, 3, "Информация", 0xff6699, 0xFFFFFF) }
	obj.CykaKnopkaConnect = { ecs.drawButton(x - 1, y + 11, selectionWidth, 3, "Подключиться", 0xff3333, 0xFFFFFF) }
	return oldPixels
end

local function connectionGUI()
	ecs.square(1, 1, xSize, ySize, 0xEEEEEE)
	
	local xCircle, yCircle = math.floor(xSize / 2), ySize - 3
	local minumumRadius, maximumRadius = 7, xCircle * 0.8
	local step = 4
	local currentRadius = minumumRadius

	drawIconAndAddress(xCircle - 6, ySize - 6, 0xEEEEEE, 0x262626, wirelessConnection.localAddress)

	while true do
		if ecs.getArraySize(wirelessConnection.availableUsers) > 0 then
			currentRadius = 0
			drawCircles(xCircle, yCircle, minumumRadius, maximumRadius, step, currentRadius)
			
			drawHorizontalIcons()

			local oldPixels, needToUpdate
			while true do
				if not oldPixels and needToUpdate then
					if ecs.getArraySize(wirelessConnection.availableUsers) <= 0 then
						ecs.square(1, 1, xSize, ySize, 0xEEEEEE)
						drawIconAndAddress(xCircle - 6, ySize - 6, 0xEEEEEE, 0x262626, wirelessConnection.localAddress)
						currentRadius = minumumRadius
						break
					else
						drawHorizontalIcons()
						needToUpdate = false
					end
				end

				local e = { event.pull() }
				if e[1] == "touch" then
					if oldPixels then ecs.drawOldPixels(oldPixels); oldPixels = nil end
					for address in pairs(obj.Users) do
						if ecs.clickedAtArea(e[3], e[4], obj.Users[address][1], obj.Users[address][2], obj.Users[address][3], obj.Users[address][4]) then
							oldPixels = drawSelectedIcon(obj.Users[address][1], obj.Users[address][2] - 1, 0xCCCCFF, 0x262626, address)
							break
						end
					end
				elseif e[1] == "userlistChanged" then
					needToUpdate = true
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

function wirelessConnection.stopReceivingData()
	event.ignore("modem_message", modemMessageHandler)
end

function wirelessConnection.startReceivingData()
	wirelessConnection.stopReceivingData()
	event.listen("modem_message", modemMessageHandler)
end

function wirelessConnection.disconnect()
	modem.broadcast(wirelessConnection.port, "iAmDisconnecting")
end

function wirelessConnection.sendPersonalData()
	wirelessConnection.disconnect()
	modem.broadcast(wirelessConnection.port, "iAmHereAddMePlease", wirelessConnection.dataToSend)
end

function wirelessConnection.changePort(newPort)
	modem.close(wirelessConnection.port)
	modem.open(newPort)
	wirelessConnection.port = newPort
	wirelessConnection.remoteAddress = nil
	wirelessConnection.localAddress = component.getPrimary("modem").address
	wirelessConnection.availableUsers = {}
	createSendingArray()
end

function wirelessConnection.connect()
	wirelessConnection.sendPersonalData()
	connectionGUI()
end

function wirelessConnection.init()
	if component.isAvailable("modem") then
		wirelessConnection.changePort(wirelessConnection.port)
		wirelessConnection.startReceivingData()
	else
		ecs.error(infoMessages.noModem)
		return
	end
end

----------------------------------------------------------------------------------------------------------------------------------

wirelessConnection.init()
wirelessConnection.sendPersonalData()
-- wirelessConnection.connect()

----------------------------------------------------------------------------------------------------------------------------------

return wirelessConnection

