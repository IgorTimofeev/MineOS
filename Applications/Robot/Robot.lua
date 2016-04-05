

local component = require("component")
local buffer = require("doubleBuffering")
local unicode = require("unicode")
local serialization = require("serialization")
local context = require("context")
local event = require("event")
local keyboard = require("keyboard")
local modem = component.modem

--------------------------------------------------------------------------------------------------------------------------------------

buffer.start()
local xStart = math.floor(buffer.screen.width / 2)
local yStart = math.floor(buffer.screen.height / 2 + 2)
local port = 1337

local topBarElements = { "Карта", "Инвентарь", "Редстоун", "Геоанализатор", "Бак" }
local currentTopBarElement = 2

local map = {
	robotPosition = {
		x = 0, y = 0, z = 0,
		rotation = 1,
	},
	currentLayer = 0,
	{ type = "empty", x = 0, y = 0, z = 0 },
}

local robotPicture = {
	"▲", "►", "▼", "◄"
}

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

local function sendMessage(...)
	modem.broadcast(port, "ECSRobotControl", ...)
end

local function drawTopBar()
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
		x = x + textLength
	end
end

local function drawMap()	
	--Рисуем карту
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
				buffer.text(xStart + map[i].x, yStart - map[i].z, colors.entity, "☺")
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
	buffer.text(xStart + map.robotPosition.x, yStart - map.robotPosition.z, colors.robot, robotPicture[map.robotPosition.rotation])
end

local function requestInventoryInfo()
	sendMessage("giveMeInfoAboutInventory")
end

local function drawInventory()
	-- sendMessage("giveMeInfoAboutInventory")
	local x, y = 3, 5
	local xPos, yPos = x, y
	if map.robotInventory and #map.robotInventory > 0 then
		for i = 1, #map.robotInventory do
			--Квадратик
			buffer.square(xPos, yPos, 8, 4, colors.gray)
			--Имя шмотки
			local name = unicode.sub(map.robotInventory[i].label, 1, 16)
			local firstPart = unicode.sub(name, 1, 8)
			local secondPart = unicode.sub(name, 9, 16) or ""
			buffer.text(xPos, yPos, colors.lightGray, firstPart)
			buffer.text(xPos, yPos + 1, colors.lightGray, secondPart)
			--Колво шмотки
			buffer.text(xPos, yPos + 2, 0xFFFFFF, tostring(map.robotInventory[i].size))
			--Процент износа
			if map.robotInventory[i].maxDamage ~= 0 then
				local percentOfNotDamage = 1 - (map.robotInventory[i].damage / map.robotInventory[i].maxDamage)
				local widthOfNotDamage = math.floor(percentOfNotDamage * 6)
				buffer.text(xPos + 1, yPos + 3, 0x000000, "━━━━━━")
				buffer.text(xPos + 1, yPos + 3, 0x33CC33, string.rep("━", widthOfNotDamage))
			end

			xPos = xPos + 10
			if i % 4 == 0 then xPos = x; yPos = yPos + 5 end
		end
	end
end

local function drawMain()
	--Очищаем главную зону
	buffer.square(1, 4, buffer.screen.width, buffer.screen.height - 3, colors.lightGray)

	if topBarElements[currentTopBarElement] == "Карта" then
		drawMap()
	elseif topBarElements[currentTopBarElement] == "Карта" then
		drawInventory()
	end
end

local function drawAll()
	drawTopBar()
	drawMain()
	buffer.draw()
end

local function getTargetCoords(direction)
	if direction == "forward" then
		if map.robotPosition.rotation == 1 then
			return map.robotPosition.x, map.robotPosition.y, map.robotPosition.z + 1, xStart, yStart + 1
		elseif map.robotPosition.rotation == 2 then
			return map.robotPosition.x + 1, map.robotPosition.y, map.robotPosition.z, xStart - 1, yStart
		elseif map.robotPosition.rotation == 3 then
			return map.robotPosition.x, map.robotPosition.y, map.robotPosition.z - 1, xStart, yStart - 1
		elseif map.robotPosition.rotation == 4 then
			return map.robotPosition.x - 1, map.robotPosition.y, map.robotPosition.z, xStart + 1, yStart
		end
	elseif direction == "back" then
		if map.robotPosition.rotation == 1 then
			return map.robotPosition.x, map.robotPosition.y, map.robotPosition.z - 1, xStart, yStart - 1
		elseif map.robotPosition.rotation == 2 then
			return map.robotPosition.x - 1, map.robotPosition.y, map.robotPosition.z, xStart + 1, yStart
		elseif map.robotPosition.rotation == 3 then
			return map.robotPosition.x, map.robotPosition.y, map.robotPosition.z + 1, xStart, yStart + 1
		elseif map.robotPosition.rotation == 4 then
			return map.robotPosition.x + 1, map.robotPosition.y, map.robotPosition.z, xStart - 1, yStart
		end
	elseif direction == "up" then
		return map.robotPosition.x, map.robotPosition.y + 1, map.robotPosition.z, xStart, yStart
	elseif direction == "down" then
		return map.robotPosition.x, map.robotPosition.y - 1, map.robotPosition.z, xStart, yStart
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

--------------------------------------------------------------------------------------------------------------------------------------

drawAll()

while true do
	local e = { event.pull() }
	if e[1] == "touch" then
	 	map.keyPoints = map.keyPoints or {}
	 	table.insert(map.keyPoints, { x = e[3] - xStart, y = map.currentLayer, z = e[4] - yStart })
	 	drawAll()
	elseif e[1] == "key_down" then
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
			sendMessage("drop")
		elseif e[4] == 28 then
			-- if map.keyPoints and #map.keyPoints > 0 then
			-- 	sendMessage("executeKeyPoints", serialization.serialize(map.keyPoints))
			-- end
			requestInventoryInfo()
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
					map.robotPosition.x = x; map.robotPosition.y = y; map.robotPosition.z = z
					table.insert(map, { type = "empty", x = x, y = y, z = z })
					drawAll()
				elseif e[7] == "successfullyRotatedTo" then
					local adder = -1; if e[8] == "turnRight" then adder = 1 end
					map.robotPosition.rotation = map.robotPosition.rotation + adder
					if map.robotPosition.rotation < 1 then 
						map.robotPosition.rotation = 4
					elseif map.robotPosition.rotation > 4 then
						map.robotPosition.rotation = 1
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
					print("ПРИШЛО СУКА СУКА СУКА")
					print(e[8])
				end
			end
		end 
	end
end



