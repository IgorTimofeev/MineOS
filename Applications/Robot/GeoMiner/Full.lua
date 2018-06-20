local computer, component = require("computer"), require("component")

local minDensity, maxDensity, chunkCount, worldHeight, droppables, tools, mathAbs, getComponent, getEnergy, checkItemInTable =
	2,
	10,
	9,
	-100,
	{
		cobblestone = 1,
		sandstone = 1,
		stone = 1,
		dirt = 1,
		gravel = 1,
		hardened_clay = 1,
		nether_brick = 1,
		sand = 1,
		soul_sand = 1,
		netherrack = 1,
	},
	{
		diamond_pickaxe = 1,
		iron_pickaxe = 1,
	},
	math.abs,
	function(c)
		c = component.list(c)()
		return c and component.proxy(c) or nil
	end,
	function()
		return computer.energy() / computer.maxEnergy()
	end,
	function(table, name)
		return table[name] or table[name:gsub("minecraft:", "")]
	end

local robot, geolyzer, inventory_controller, generator =
	getComponent("robot"),
	getComponent("geolyzer"),
	getComponent("inventory_controller"),
	getComponent("generator")

local positionX, positionY, positionZ, rotation, inventorySize, robotSwing, robotSelect, geolyzerScan, inventory_controllerGetStackInInternalSlot = 0, 0, 0, 0, robot.inventorySize(), robot.swing, robot.select, geolyzer.scan, inventory_controller.getStackInInternalSlot

local turn, move = 
	function(clockwise)
		robot.turn(clockwise)
		rotation = rotation + (clockwise and 1 or -1)
		rotation = rotation > 3 and 0 or rotation < 0 and 3 or rotation
	end,
	function(direction)
		while true do
			local success, reason = robotSwing(direction)
			if success or reason == "air" then
				success, reason = robot.move(direction)
				if success then
					if direction == 0 or direction == 1 then
						positionY = positionY + (direction == 1 and 1 or -1)
					else
						positionX, positionZ = positionX + (rotation == 0 and 1 or rotation == 2 and -1 or 0), positionZ + (rotation == 1 and 1 or rotation == 3 and -1 or 0)
					end


					break
				end
			else
				if reason == "block" then
					while true do
						computer.beep(1500, 1)
					end
				end
			end
		end
	end

local function turnTo(requiredRotation)
	local difference = rotation - requiredRotation
	if difference ~= 0 then
		local fastestWay = difference > 2
		if difference <= 0 then
			fastestWay = -difference <= 2
		end

		while rotation ~= requiredRotation do
			turn(fastestWay)
		end
	end
end

local moveTo, drop =
	function(toX, toY, toZ)
		toX, toY, toZ = toX - positionX, toY - positionY, toZ - positionZ

		if toY ~= 0 then
			for i = 1, mathAbs(toY) do
				move(toY > 0 and 1 or 0)
			end
		end

		if toX ~= 0 then
			turnTo(toX > 0 and 0 or 2)
			for i = 1, mathAbs(toX) do
				move(3)
			end
		end

		if toZ ~= 0 then
			turnTo(toZ > 0 and 1 or 3)
			for i = 1, mathAbs(toZ) do
				move(3)
			end
		end
	end,
	function(trashOnly)
		local freeSlots = 0
		for i = 1, inventorySize do
			local stack = inventory_controllerGetStackInInternalSlot(i)
			if stack then
				local droppable = checkItemInTable(droppables, stack.name)
				if trashOnly and droppable or not trashOnly and not checkItemInTable(tools, stack.name)  then
					robotSelect(i)
					robot.drop(droppable and 0 or 3)
					freeSlots = freeSlots + 1
				end
			end
		end

		return freeSlots
	end

local function moveToBase()
	--print("Пиздую на базу")
	moveTo(0, positionY, 0)
	moveTo(0, 0, 0)

	--print("Ищу сундук")
	for i = 0, 3 do
		local size = inventory_controller.getInventorySize(3)
		if size and size > 3 then
			--print("Нашел, дропаю весь шмот")
			drop()
			return
		else
			turn(true)
		end
	end

	--print("Чет сундука нет, дропну хоть треш")
	drop(true)
end

--print("Запускаю софтину")
robotSelect(1)
move(0)

--print("Детекчу сторону")
local initial = geolyzerScan(1, 0)[33]
for i = 0, 3 do
	if initial > 0 then
		if robotSwing(3) and geolyzerScan(1, 0)[33] == 0 then
			break
		end
	else
		if robot.place(3) and geolyzerScan(1, 0)[33] > 0 then
			break
		end
	end

	turn(false)
end

local chunkX, chunkZ, chunkRotation, chunkRadius, chunkRadiusCounter, chunkWorldX, chunkWorldZ = 0, 0, 0, 1, 1
for chunk = 1, chunkCount do
	chunkWorldX, chunkWorldZ = chunkX * 8, chunkZ * 8

	--print("Пиздую к текущему чанку", chunkX, chunkZ)
	moveTo(chunkWorldX, -1, chunkWorldZ)

	while true do
		--print("Сканирую чанк", chunkX, chunkZ)
		local scanX, scanZ, scanIndex, ores, scanResult, bedrock =
			positionX,
			positionZ,
			1,
			{},
			geolyzer.scan(
				chunkWorldX - positionX,
				chunkWorldZ - positionZ,
				-1,
				8,
				8,
				1
			)

		for z = 0, 7 do
			for x = 0, 7 do 
				if scanResult[scanIndex] >= minDensity and scanResult[scanIndex] <= maxDensity then
					table.insert(ores, chunkWorldX + x)
					table.insert(ores, chunkWorldZ + z)
				elseif scanResult[scanIndex] < -0.4 then
					bedrock = true
				end

				scanIndex = scanIndex + 1
			end
		end

		if #ores > 0 then
			--print("Нашел вот стока руд", #ores)
			while #ores > 0 do
				local nearestIndex, nearestDistance, distance = 1, math.huge
				for i = 1, #ores, 2 do
					distance = math.sqrt((ores[i] - positionX) ^ 2 + (ores[i + 1] - positionZ) ^ 2)
					if distance < nearestDistance then
						nearestIndex, nearestDistance = i, distance
					end
				end

				--print("Пиздую к руде на точку", ores[nearestIndex], positionY, ores[nearestIndex + 1])
				moveTo(ores[nearestIndex], positionY, ores[nearestIndex + 1])
				robotSwing(0)

				for i = 1, 2 do
					table.remove(ores, nearestIndex)
				end
			end
		else
			--print("Ни хуя тут руд нет")
		end

		--print("Чекаем генератор")
		if generator and generator.count() == 0 then
			--print("Генератор пустой чота")
			for i = 1, inventorySize do
				robotSelect(i)
				if generator.insert() then
					--print("Генератор заправлен")
					break
				end
			end
		end

		--print("Чекаем инстурмент")
		if robot.durability() <= 0.2 then
			--print("Инструмент хуевый")
			for i = 1, inventorySize do
				local stack = inventory_controllerGetStackInInternalSlot(i)
				if stack and checkItemInTable(tools, stack.name) and stack.damage / stack.maxDamage < 0.8 then
					--print("Ща сменю его")
					robotSelect(i)
					inventory_controller.equip()
					break
				end
			end
		end

		--print("Чекаю фри слоты или энергию", freeSlots, getEnergy())
		local freeSlots = 0
		for i = 1, inventorySize do
			if robot.count(i) == 0 then
				freeSlots = freeSlots + 1
			end
		end

		if freeSlots <= 1 then
			--print("Фри слотов маловато, пытаюсь дропнуть треш")
			freeSlots = freeSlots + drop(true)
		end

		if freeSlots <= 3 or getEnergy() <= 0.2 then
			--print("Чота все ваще хуева: либо слотов мало, либо энергии не хватает... заебало")
			local oldX, oldY, oldZ, oldRotation = positionX, positionY, positionZ, rotation
			moveToBase()

			if getEnergy() <= 0.2 then
				--print("еще и зарядки мало, ща подзарядимсо")
				while getEnergy() < 0.99 do
					--print("Заряжаюсь", getEnergy())
					computer.pullSignal(1)
				end
			end

			--print("Пиздую назад")
			moveTo(oldX, oldY, oldZ)
			turnTo(oldRotation)
		end

		if bedrock or positionY <= worldHeight then
			--print("Бедрок чет нашел на Y или низковато опустился", positionY - 1)
			break
		else
			--print("Руды выкопаны. Сдвигаюсь вниз и ебошу")
			move(0)
		end
	end

	--print("Чанк полностью выкопан, рассчитываю коорды следующего")
	chunkX, chunkZ = chunkX + (chunkRotation == 0 and 1 or chunkRotation == 2 and -1 or 0), chunkZ + (chunkRotation == 1 and 1 or chunkRotation == 3 and -1 or 0)
	
	if
		(chunkRotation == 0 or chunkRotation == 2) and mathAbs(chunkX) >= chunkRadius or
		(chunkRotation == 1 or chunkRotation == 3) and mathAbs(chunkZ) >= chunkRadius
	then
		chunkRadiusCounter = chunkRadiusCounter + 1
		if chunkRadiusCounter > 5 then
			chunkRadius, chunkRadiusCounter = chunkRadius + 1, 1
			--print("Радиус увеличил", chunkRadius)
		else
			chunkRotation = chunkRotation + 1
			if chunkRotation > 3 then
				chunkRotation = 0
			end
			--print("Паварооот", chunkRotation)
		end
	end
end

moveToBase()
turnTo(0)
--print("Усе, епта")