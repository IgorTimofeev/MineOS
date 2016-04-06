
local component = require("component")
local buffer = require("doubleBuffering")
local unicode = require("unicode")
local serialization = require("serialization")
local context = require("context")
local event = require("event")
local keyboard = require("keyboard")
local ecs = require("ECSAPI")
local modem = component.modem

--------------------------------------------------------------------------------------------------------------------------------------

buffer.start()
local xStart = math.floor(buffer.screen.width / 2)
local yStart = math.floor(buffer.screen.height / 2 + 2)
local port = 1337

local topBarElements = { "Карта", "Скрипт", "Инвентарь", "Редстоун", "Геоанализатор", "Бак" }
local currentTopBarElement = 1

local drawInventoryFrom = 1
local currentInventoryType = "internal"

local map = {
	robot = {
		x = 0, y = 0, z = 0,
		rotation = 1,
		status = "Ожидание",
		energy = 1,
		maxEnergy = 1,
		redstone = {
			[0] = 0,
			[1] = 0,
			[2] = 0,
			[3] = 0,
			[4] = 0,
			[5] = 0,
		}
	},
	currentLayer = 0,
	{ type = "empty", x = 0, y = 0, z = 0 },
}

local robotPicture = {
	"▲", "►", "▼", "◄"
}
local robotFront = image.load("Robot.pic")
local robotSide = image.load("RobotSide.pic")
local robotTop = image.load("RobotTop.pic")
local chest = image.load("Chest.pic")

local colors = {
	white = 0xFFFFFF,
	lightGray = 0xCCCCCC,
	gray = 0x333333,
	black = 0x000000,
	robot = 0xFF3333,
	entity = 0xFFCC33,
	homePoint = 0x6699FF,
	passable = 0xFF3333,
	keyPoint = 0xFF3333,
	keyPointText = 0xFFFFFF,
}

modem.open(port)

--------------------------------------------------------------------------------------------------------------------------------------

--OBJECTS, CYKA
local obj = {}
local function newObj(class, name, ...)
	obj[class] = obj[class] or {}
	obj[class][name] = {...}
end

local function isNumberInRange(n, min, max)
	if n > min and n <= max then return true end
end

local function sendMessage(...)
	modem.broadcast(port, "ECSRobotControl", ...)
end

local function drawMultiColorProgressBar(x, y, width, currentValue, maxValue, fat)
	local percent = currentValue / maxValue
	local valueWidth = math.ceil(percent * width)
	local color = 0x33CC33
	if isNumberInRange(percent, 0.5, 0.7) then
		color = 0xFFFF33
	elseif isNumberInRange(percent, 0.3, 0.5) then
		color = 0xFFCC33
	elseif isNumberInRange(percent, 0.1, 0.3) then
		color = 0xFF3333
	elseif isNumberInRange(percent, -10, 0.1) then
		color = 0x663300
	end

	buffer.text(x, y, 0x000000, string.rep(fat and "▄" or "━", width))
	buffer.text(x, y, color, string.rep(fat and "▄" or "━", valueWidth))
end

local function drawRobotStatus()
	local width, height = 10, 7
	local x, y = buffer.screen.width - width, buffer.screen.height - height

	buffer.square(x, y, width, height, colors.lightGray)
	buffer.text(x, y, colors.gray, map.robot.status or "N/A")
	y = y + 2
	buffer.image(x, y, robotFront)
	y = y + robotFront.height
	drawMultiColorProgressBar(x - 1, y, 10, map.robot.energy, map.robot.maxEnergy, true)
end

local function drawTopBar()
	obj.TopBar = {}
	buffer.square(1, 1, buffer.screen.width, 3, colors.gray)
	local x = 1
	for i = 1, #topBarElements do
		local textLength = unicode.len(topBarElements[i]) + 4
		if i == currentTopBarElement then
			buffer.square(x, 1, textLength, 3, colors.lightGray)
			buffer.text(x + 2, 2, colors.gray, topBarElements[i])
		else
			buffer.text(x + 2, 2, colors.lightGray, topBarElements[i])
		end

		newObj("TopBar", i, x, 1, x + textLength - 1, 3)
		x = x + textLength
	end
end

local function drawMap()
	buffer.setDrawLimit(1, 4, buffer.screen.width, buffer.screen.height - 3)

	--Рисуем карту под роботом
	for i = 1, #map do
		if map[i].y < map.currentLayer then
			buffer.set(xStart + map[i].x, yStart - map[i].z, colors.lightGray, colors.gray, "░")
		end
	end

	--Рисуем текущий слой
	for i = 1, #map do
		--Если слой совпадает с текущим Y
		if map[i].y == map.currentLayer then
			--Если координаты в границах экрана
			if map[i].type == "empty" then
				buffer.set(xStart + map[i].x, yStart - map[i].z, colors.gray, 0x000000, " ")
			elseif map[i].type == "solid" then
				buffer.set(xStart + map[i].x, yStart - map[i].z, colors.lightGray, colors.gray, "▒")
			elseif map[i].type == "passable" then
				buffer.set(xStart + map[i].x, yStart - map[i].z, colors.lightGray, colors.passable, "▒")
			elseif map[i].type == "entity" then
				buffer.set(xStart + map[i].x, yStart - map[i].z, colors.lightGray, colors.gray, "☺")
			end
		end
	end

	--Рисуем точку дома
	if map.currentLayer == 0 then buffer.set(xStart, yStart, colors.homePoint, colors.gray, "⌂") end

	--Рисуем ключевые точки
	if map.keyPoints and #map.keyPoints > 0 then
		for i = 1, #map.keyPoints do
			buffer.set(xStart + map.keyPoints[i].x, yStart + map.keyPoints[i].z, colors.keyPoint, colors.keyPointText, "*")
		end
	end

	--Рисуем робота
	buffer.text(xStart + map.robot.x, yStart - map.robot.z, colors.robot, robotPicture[map.robot.rotation])

	buffer.resetDrawLimit()

	drawRobotStatus()
end

local function requestInfoAboutInventory()
	sendMessage("giveMeInfoAboutInventory", currentInventoryType)
end

local function requestInfoAboutRobot()
	sendMessage("giveMeInfoAboutRobot")
end

local function highlight(x, y, width, height, color)
	buffer.square(x, y + 1, width, height - 2, color)
	buffer.text(x, y, color, string.rep("▄", width))
	buffer.text(x, y + height - 1, color, string.rep("▀", width))
end

local function drawCloud(x, y, width, height, text)
	local cloudColor = 0xFFFFFF
	local textColor = colors.gray

	buffer.square(x, y + 1, width, height - 2, cloudColor, textColor, " ")
	buffer.square(x + 1, y, width - 2, height, cloudColor, textColor, " ")

	buffer.text(x, y, cloudColor, "▄")
	buffer.text(x + width - 1, y, cloudColor, "▄")
	buffer.text(x, y + height - 1, cloudColor, "▀")
	buffer.text(x + width - 1, y + height - 1, cloudColor, "▀")

	local lines = {
		"▄",
		"██▄",
		"████▄",
		"████▀",
		"██▀",
		"▀",
	}
	local xLine, yLine = x + width, math.floor(y + height / 2 - #lines / 2)
	for i = 1, #lines do buffer.text(xLine, yLine, cloudColor, lines[i]); yLine = yLine + 1 end

	y = math.floor(y + height / 2)
	x = math.floor(x + width / 2 - unicode.len(text) / 2)
	buffer.text(x, y, textColor, text)
end

local function drawInventory()

	obj.InventorySlots = {}

	local x, y = 3, 5
	local inventoryWidth, inventoryHeight = 42, 19
	local xPos, yPos = x, y
	local counter = 1

	if map.robotInventory then
		if not map.robotInventory.noInventory then

			-- highlight(x - 1, y - 1, inventoryWidth + 2, inventoryHeight + 2, 0xFFFFFF)
			--Рисуем скроллбар
			buffer.scrollBar(x + inventoryWidth - 2, y, 2, inventoryHeight, map.robotInventory.inventorySize, drawInventoryFrom, colors.gray, 0xFF3333)
			--Рисуем слотики
			for i = drawInventoryFrom, map.robotInventory.inventorySize do
				--Выделение слота
				if i == map.robotInventory.currentSlot then
					highlight(xPos - 1, yPos - 1, 10, 6, 0xFF3333)
				end
				--Квадратик
				buffer.square(xPos, yPos, 8, 4, colors.gray, colors.lightGray, " ")
				--Записываем обжект, чо уж там
				newObj("InventorySlots", i, xPos, yPos, xPos + 7, yPos + 3)
				--Если такой слот ваще есть, то рисуем инфу о нем, а иначе рисуем пустой слот
				if map.robotInventory[i] then
					--Имя шмотки
					local name = unicode.sub(map.robotInventory[i].label, 1, 16)
					local firstPart = unicode.sub(name, 1, 8)
					local secondPart = unicode.sub(name, 9, 16) or ""
					buffer.text(xPos, yPos, colors.lightGray, firstPart)
					buffer.text(xPos, yPos + 1, colors.lightGray, secondPart)
					--Колво шмотки
					local stringSize = tostring(map.robotInventory[i].size)
					buffer.text(xPos + math.floor(4 - unicode.len(stringSize) / 2), yPos + 2, 0xFFFFFF, stringSize)
					--Процент износа
					if map.robotInventory[i].maxDamage ~= 0 then
						drawMultiColorProgressBar(xPos + 1, yPos + 3, 6, map.robotInventory[i].damage, map.robotInventory[i].maxDamage)
					end
				else
					buffer.text(xPos + 1, yPos + 1, colors.lightGray, "Пусто")
				end

				xPos = xPos + 10
				counter = counter + 1
				if i % 4 == 0 then xPos = x; yPos = yPos + 5 end
				if counter > 16 then break end
			end
		else
			drawCloud(x, y, inventoryWidth, inventoryHeight + 1, "Где инвентарь, сука? Кто ответственный?")
		end
	else
		drawCloud(x, y, inventoryWidth, inventoryHeight + 1, "Запрашиваю у робота массив инвентаря")
	end

	--Рисуем выбор типа инвентаря
	local width = 17
	local height = 13
	x = buffer.screen.width - width - 7
	y = math.floor(4 + (buffer.screen.height - 4) / 2 - height / 2 )

	--Коорды все нужные
	local inventoryPositions = {
		top = { x = x + 10, y = y }, 
		front = { x = x, y = y + 5 },
		bottom = { x = x + 10, y = y + 10 },
		internal = { x = x + 10, y = y + 5}
	}
	--Подсветочка
	highlight(inventoryPositions[currentInventoryType].x - 1, inventoryPositions[currentInventoryType].y - 1, 10, 6, 0xFF3333)
	--Верхний сундук
	buffer.image(inventoryPositions.top.x, inventoryPositions.top.y, chest)
	--Средний сундук и роботСайд
	buffer.image(inventoryPositions.front.x, inventoryPositions.front.y, chest)
	buffer.image(inventoryPositions.internal.x, inventoryPositions.internal.y, robotSide)
	--Нижний
	buffer.image(inventoryPositions.bottom.x, inventoryPositions.bottom.y, chest)
	--Обжекты
	obj.InventoryTypeSelectors = {}
	for key in pairs(inventoryPositions) do newObj("InventoryTypeSelectors", key, inventoryPositions[key].x, inventoryPositions[key].y, inventoryPositions[key].x + 9, inventoryPositions[key].y + 5) end
end

local function drawScript()

end

local function getSizeOfRedstoneWire(size, side)
	local percent = (map.robot.redstone[side]) / 15
	return math.floor(size * percent)
end

local function sendRedstoneRequest()
	sendMessage("giveMeInfoAboutRedstone")
end

local function drawRedstone()
	local x, y = 6, 5
	local width, side

	obj.Redstone = {}

	--Левая гориз черта
	side = 5
	width = getSizeOfRedstoneWire(16, side)
	newObj("Redstone", side, x, y + 9, x + 15, y + 10)
	buffer.text(x, y + 9, 0x000000, string.rep("▄", 16))
	buffer.text(x, y + 10, 0x000000, string.rep("▀", 16))
	buffer.text(x + 16 - width, y + 9, 0xFF3333, string.rep("▄", width))
	buffer.text(x + 16 - width, y + 10, 0xFF3333, string.rep("▀", width))

	--Правая гориз черта
	side = 4
	newObj("Redstone", side, x + 24, y + 9, x + 39, y + 10)
	width = getSizeOfRedstoneWire(16, side)
	buffer.text(x + 24, y + 9, 0x000000, string.rep("▄", 16))
	buffer.text(x + 24, y + 10, 0x000000, string.rep("▀", 16))
	buffer.text(x + 24, y + 9, 0xFF3333, string.rep("▄", width))
	buffer.text(x + 24, y + 10, 0xFF3333, string.rep("▀", width))

	--Верхняя верт черта
	side = 3
	newObj("Redstone", side, x + 19, y, x + 20, y + 7)
	width = getSizeOfRedstoneWire(8, side)
	buffer.square(x + 19, y, 2, 8, 0x000000)
	buffer.square(x + 19, y + 8 - width, 2, width, 0xFF3333)

	--Нижняя верт черта
	side = 2
	newObj("Redstone", side, x + 19, y + 12, x + 20, y + 19)
	buffer.square(x + 19, y + 12, 2, 8, 0x000000)
	buffer.square(x + 19, y + 12, 2, getSizeOfRedstoneWire(8, side), 0xFF3333)

	buffer.image(x + 16, y + 8, robotTop)

	x = x + 41

	--Верхняя верт черта
	side = 1
	newObj("Redstone", side, x + 19, y, x + 20, y + 7)
	width = getSizeOfRedstoneWire(8, side)
	buffer.square(x + 19, y, 2, 8, 0x000000)
	buffer.square(x + 19, y + 8 - width, 2, width, 0xFF3333)

	--Нижняя верт черта
	side = 0
	newObj("Redstone", side, x + 19, y + 12, x + 20, y + 19)
	buffer.square(x + 19, y + 12, 2, 8, 0x000000)
	buffer.square(x + 19, y + 12, 2, getSizeOfRedstoneWire(8, side), 0xFF3333)

	buffer.image(x + 16, y + 8, robotFront)

end

local function drawMain()
	--Очищаем главную зону
	buffer.square(1, 4, buffer.screen.width, buffer.screen.height - 3, colors.lightGray)

	if topBarElements[currentTopBarElement] == "Карта" then
		drawMap()
	elseif topBarElements[currentTopBarElement] == "Инвентарь" then
		drawInventory()
	elseif topBarElements[currentTopBarElement] == "Редстоун" then
		drawRedstone()
	end
end

local function drawAll()
	drawTopBar()
	drawMain()
	buffer.draw()
end

local function getTargetCoords(direction)
	if direction == "forward" then
		if map.robot.rotation == 1 then
			return map.robot.x, map.robot.y, map.robot.z + 1, xStart, yStart + 1
		elseif map.robot.rotation == 2 then
			return map.robot.x + 1, map.robot.y, map.robot.z, xStart - 1, yStart
		elseif map.robot.rotation == 3 then
			return map.robot.x, map.robot.y, map.robot.z - 1, xStart, yStart - 1
		elseif map.robot.rotation == 4 then
			return map.robot.x - 1, map.robot.y, map.robot.z, xStart + 1, yStart
		end
	elseif direction == "back" then
		if map.robot.rotation == 1 then
			return map.robot.x, map.robot.y, map.robot.z - 1, xStart, yStart - 1
		elseif map.robot.rotation == 2 then
			return map.robot.x - 1, map.robot.y, map.robot.z, xStart + 1, yStart
		elseif map.robot.rotation == 3 then
			return map.robot.x, map.robot.y, map.robot.z + 1, xStart, yStart + 1
		elseif map.robot.rotation == 4 then
			return map.robot.x + 1, map.robot.y, map.robot.z, xStart - 1, yStart
		end
	elseif direction == "up" then
		return map.robot.x, map.robot.y + 1, map.robot.z, xStart, yStart
	elseif direction == "down" then
		return map.robot.x, map.robot.y - 1, map.robot.z, xStart, yStart
	end
end

local function getOptimalKeyPoint()
	local optimalID
	local optimalDistance = math.huge
	for i = 1, #map.keyPoints do
		local distance = math.sqrt(map.keyPoints.x ^ 2 + map.keyPoints.y ^ 2 + map.keyPoints.x ^ z)
		if distance < optimalDistance then
			optimalID = i
			optimalDistance = distance
		end
	end
	return optimalID
end

local function clicked(x, y, object)
	if x >= object[1] and y >= object[2] and x <= object[3] and y <= object[4] then
		return true
	end
end

--------------------------------------------------------------------------------------------------------------------------------------

drawAll()
requestInfoAboutRobot()

while true do
	local e = { event.pull() }
	if e[1] == "touch" then
		--СОздание ключевых точек
		if e[4] >= 4 and topBarElements[currentTopBarElement] == "Карта" then
		 	map.keyPoints = map.keyPoints or {}
		 	table.insert(map.keyPoints, { x = e[3] - xStart, y = map.currentLayer, z = e[4] - yStart })
		 	drawAll()
		 end

		--Выбор верхнего тулбара
	 	for key in pairs(obj.TopBar) do
	 		if clicked(e[3], e[4], obj.TopBar[key]) then
	 			currentTopBarElement = key

	 			requestInfoAboutRobot()
	 			
	 			if topBarElements[currentTopBarElement] == "Инвентарь" then
	 				map.robotInventory = nil
	 				currentInventoryType = "internal";
	 				drawInventoryFrom = 1
	 				requestInfoAboutInventory()
	 			elseif topBarElements[currentTopBarElement] == "Редстоун" then
	 				sendRedstoneRequest()
	 			end 

	 			drawAll()
	 			break
	 		end
	 	end

	 	--Редстоун
	 	if topBarElements[currentTopBarElement] == "Редстоун" then
	 		if obj.Redstone then
		 		for key in pairs(obj.Redstone) do
		 			if clicked(e[3], e[4], obj.Redstone[key]) then
		 				local newValue
		 				--Если низ или жопка
		 				if key == 0 or key == 2 then
		 					newValue = (e[4] - obj.Redstone[key][2] + 1) * 2
		 					if e[4] == obj.Redstone[key][2] then newValue = 0 end
		 				--Ебало или верх
		 				elseif key == 1 or key == 3 then
		 					newValue = (obj.Redstone[key][4] - e[4] + 1) * 2
		 					if e[4] == obj.Redstone[key][4] then newValue = 0 end
		 				--Если лево
		 				elseif key == 5 then
		 					newValue = (obj.Redstone[key][3] - e[3])
		 					if e[3] == obj.Redstone[key][3] then newValue = 0 end
		 				elseif key == 4 then
		 					newValue = (e[3] - obj.Redstone[key][1])
		 					if e[3] == obj.Redstone[key][1] then newValue = 0 end

		 				end

		 				if newValue > 15 then newValue = 15 elseif newValue < 0 then newValue = 0 end
		 				-- ecs.error(newValue)
		 				sendMessage("changeRedstoneOutput", key, newValue)

		 				break
		 			end
		 		end
		 	end
		 end

	 	--Выбор слотов
	 	if topBarElements[currentTopBarElement] == "Инвентарь" then
	 		--Тип инвентаря
	 		if obj.InventoryTypeSelectors then
		 		for key in pairs(obj.InventoryTypeSelectors) do
			 		if clicked(e[3], e[4], obj.InventoryTypeSelectors[key]) then
			 			map.robotInventory = nil
			 			currentInventoryType = key
			 			drawInventoryFrom = 1
			 			requestInfoAboutInventory()
			 			drawAll()
			 		end
			 	end
			end

		 	--Слотики
		 	if obj.InventorySlots then
			 	for key in pairs(obj.InventorySlots) do
			 		if clicked(e[3], e[4], obj.InventorySlots[key]) then
			 			if e[5] ~= 1 then
			 				if currentInventoryType == "internal" then
			 					sendMessage("selectSlot", key)
			 				end
			 			else
			 				if currentInventoryType == "internal" then
				 				if map.robotInventory[key] then
					 				local action = context.menu(e[3], e[4], {"Экипировать"}, {"Выбросить"}, "-", {"Инфо", true})
					 				if action == "Экипировать" then
					 					sendMessage("equip", key)
					 				elseif action == "Выбросить" then
					 					sendMessage("drop", nil, key)
					 				end
					 			end
				 			else
				 				local action = context.menu(e[3], e[4], {"Соснуть", map.robotInventory[key] == nil}, {"Положить суда", map.robotInventory[key] ~= nil}, "-", {"Инфо", true})
				 				if action == "Соснуть" then
				 					sendMessage("suckFromSlot", currentInventoryType, key)
				 				end
				 			end
			 			end
			 			
			 			break
			 		end
			 	end
		 	end
		 end
	elseif e[1] == "key_down" then
		if topBarElements[currentTopBarElement] == "Карта" then
			--W
			if e[4] == 17 then
				sendMessage("forward")
			--S
			elseif e[4] == 31 then
				sendMessage("back")
			--SHIFT
			elseif e[4] == 42 then
				sendMessage("down")
			--SPACE
			elseif e[4] == 57 then
				sendMessage("up")
			--A
			elseif e[4] == 30 then
				sendMessage("turnLeft")
			--D
			elseif e[4] == 32 then
				sendMessage("turnRight")
			--E
			elseif e[4] == 18 then
				if keyboard.isControlDown() then sendMessage("use") else sendMessage("swing") end
			--Q
			elseif e[4] == 16 then
				sendMessage("place", 1)
			--C
			elseif e[4] == 46 then
				local color = require("palette").draw("auto", "auto")
				sendMessage("changeColor", color or 0xFFFFFF)
			elseif e[4] == 28 then
				-- if map.keyPoints and #map.keyPoints > 0 then
				-- 	sendMessage("executeKeyPoints", serialization.serialize(map.keyPoints))
				-- end
			end
		end
	elseif e[1] == "modem_message" then
		if e[4] == port then
			if e[6] == "ECSRobotAnswer" then
				if e[7] == "cantMoveTo" then
					local x, y, z = getTargetCoords(e[8])
					table.insert(map, { type = e[9], x = x, y = y, z = z })
					drawAll()
				elseif e[7] == "successfullyMovedTo" then
					local x, y, z; x, y, z, xStart, yStart = getTargetCoords(e[8])
					if e[8] == "up" then
						map.currentLayer = map.currentLayer + 1
					elseif e[8] == "down" then
						map.currentLayer = map.currentLayer - 1
					end
					map.robot.x = x; map.robot.y = y; map.robot.z = z
					table.insert(map, { type = "empty", x = x, y = y, z = z })
					drawAll()
				elseif e[7] == "successfullyRotatedTo" then
					local adder = -1; if e[8] == "turnRight" then adder = 1 end
					map.robot.rotation = map.robot.rotation + adder
					if map.robot.rotation < 1 then 
						map.robot.rotation = 4
					elseif map.robot.rotation > 4 then
						map.robot.rotation = 1
					end
					drawAll()
				elseif e[7] == "successfullySwingedTo" then
					if e[8] == "swing" then e[8] = "forward" elseif e[8] == "swingUp" then e[8] = "up" elseif e[8] == "swingDown" then e[8] = "down" end
					local x, y, z = getTargetCoords(e[8])
					table.insert(map, { type = "empty", x = x, y = y, z = z })
					drawAll()
				elseif e[7] == "inventoryInfo" then
					map.robotInventory = serialization.unserialize(e[8])
					drawAll()
				elseif e[7] == "selectedSlot" then
					map.robotInventory.currentSlot = e[8]
					if topBarElements[currentTopBarElement] == "Инвентарь" then drawAll() end
				elseif e[7] == "infoAboutRobot" then
					map.robot.energy = e[8]
					map.robot.maxEnergy = e[9]
					map.robot.status = e[10]
					if topBarElements[currentTopBarElement] == "Карта" then drawRobotStatus(); buffer.draw() end
				elseif e[7] == "infoAboutRedstone" then
					map.robot.redstone = serialization.unserialize(e[8])
					if topBarElements[currentTopBarElement] == "Редстоун" then drawAll() end
				end
			end
		end
	elseif e[1] == "scroll" then
		if topBarElements[currentTopBarElement] == "Инвентарь" then
			if e[5] == 1 then
				if drawInventoryFrom > 4 then drawInventoryFrom = drawInventoryFrom - 4; drawAll() end
			else
				if drawInventoryFrom < (map.robotInventory.inventorySize - 3) then drawInventoryFrom = drawInventoryFrom + 4; drawAll() end
			end
		end
	end
end



