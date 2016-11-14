
local computer = require("computer")
local component = require("component")
local robot = require("robot")
local event = require("event")
local sides = require("sides")
local geo = component.geolyzer
local inventoryController = inventoryController

-------------------------------------------------------------------------------------------------------------------

local fuels = {
	"minecraft:coal",
	"minecraft:lava_bucket",
	"minecraft:coal_block",
}

local shittyResources = {
	"minecraft:cobblestone",
	"minecraft:grass",
	"minecraft:dirt",
	"minecraft:gravel",
	"minecraft:sand",
	"minecraft:sandstone",
	"minecraft:torch",
	"minecraft:planks",
	"minecraft:fence",
	"minecraft:chest",
	"minecraft:monster_egg",
	"minecraft:stonebrick",
}

local oreSearchRadius = 5
local searchPassesCount = 5
local minimumOreHardness = 2.5
local maximumOreHardness = 8
local replaceToolDurabilityTrigger = 0.05
local replaceToolRegex = "(minecraft:).+(_pickaxe)"
local rechargeTrigger = 0.1
local dropShittyResourcesOnEmptySlots = 5

-------------------------------------------------------------------------------------------------------------------

local program = {}
local robotPosition = {x = 0, y = 0, z = 0, rotation = 0}
local energyStatusCheckEnabled = true
local toolStatusCheckEnabled = true
local generatorIsAvailable = component.isAvailable("generator")

function program.scan(radius, passes, minHardness, maxHardness)
	local ores = {}

	-- Заносим все руды в массивыч руд
	for pass = 1, passes do
		print("Scan pass " .. pass .. " started...")
		for x = -radius, radius do
			for z = -radius, radius do
				local stack = geo.scan(x, z, true)
				for y = 1, #stack do
					if stack[y] >= minHardness and stack[y] <= maxHardness then
						-- Заполняем координатную сетку, если массивов еще не существует
						ores[x] = ores[x] or {}
						ores[x][y] = ores[x][y] or {}

						-- Если мы уже сканировали этот блок, то получаем среднюю плотность из двух значений
						-- Если нет, то банально ставим полученное значение
						if ores[x][y][z] then
							ores[x][y][z] = (ores[x][y][z] + stack[y]) / 2
						else
							ores[x][y][z] = stack[y]
						end

						-- print("x=" .. x .. ", y=" .. y .. ", z=" .. z .. ", hardness=" .. stack[y])
					end
				end
			end
		end
	end

	-- Переебошиваем массив руд для более удобной работы с ним в линейном формате
	-- Не забываем подчищать говнище за собой, а то роботы не резиновые
	local newOres = {}
	for x in pairs(ores) do
		for y in pairs(ores[x]) do
			for z in pairs(ores[x][y]) do
				table.insert(newOres, {x = robotPosition.x + x, y = robotPosition.y + y - 33, z = robotPosition.z + z})
				ores[x][y][z] = nil
			end
			ores[x][y] = nil
		end
		ores[x]= nil
	end

	return newOres
end

local function getHardness(x, z)
	local stack = geo.scan(x, z)
	for i = 1, #stack do
		print("i=" .. i .. ", val=" .. stack[i])
		event.pull("key_down")
	end
end

function program.move(direction)
	while true do
		local swingSuccess, swingReason = component.robot.swing(direction)
		if swingSuccess or swingReason == "air" then
			local moveSuccess, moveReason = component.robot.move(direction)
			if moveSuccess then
				break
			end
		else
			if swingReason == "block" then
				print("Unbreakable block detected, going to base")
				program.returnToBase()
				os.exit()
			end
		end
	end

	if direction == sides.front or direction == sides.back then
		local directionOffset = direction == sides.front and 1 or -1

		if robotPosition.rotation == 0 then
			robotPosition.x = robotPosition.x + directionOffset
		elseif robotPosition.rotation == 1 then
			robotPosition.z = robotPosition.z + directionOffset
		elseif robotPosition.rotation == 2 then
			robotPosition.x = robotPosition.x - directionOffset
		elseif robotPosition.rotation == 3 then
			robotPosition.z = robotPosition.z - directionOffset
		end
	elseif direction == sides.up or direction == sides.down then
		local directionOffset = direction == sides.up and 1 or -1
		robotPosition.y = robotPosition.y + directionOffset
	end
end


function program.returnToBase()
	program.gotoPoint(0, robotPosition.y, 0)
	program.turnToRequiredRotation(0)
	program.gotoPoint(0, -2, 0)
	program.tryToDropShittyResources()
	program.gotoPoint(0, 0, 0)
	program.dropAllResoucesIntoBaseChest()
end

function program.getSlotWithFuel()
	for slot = 1, component.robot.inventorySize() do
		local stack = inventoryController.getStackInInternalSlot(slot)
		if stack then
			for fuel = 1, #fuels do
				if stack.name == fuels[fuel] then
					return slot
				end
			end
		end
	end
end

function program.tryToRechargeByGenerator()
	if generatorIsAvailable then
		if component.generator.count() == 0 then
			print("Generator is empty, trying to find some fuel in inventory")
			local slot = program.getSlotWithFuel()
			if slot then
				print("Found slot with fuel: " .. slot)
				local oldSlot = robot.select(slot)
				component.generator.insert()
				robot.select(oldSlot)
				return
			else
				print("Slot with fuel not found")
			end
		end
	end
end

function program.checkEnergyStatus()
	if computer.energy() / computer.maxEnergy() < rechargeTrigger then
		print("Low energy level detected")
		energyStatusCheckEnabled = false
		-- Запоминаем старую позицию, шобы суда вернуться
		local oldPosition = {x = robotPosition.x, y = robotPosition.y, z = robotPosition.z, rotation = robotPosition.rotation}
		-- Пиздуем на базу за зарядкой
		program.returnToBase()
		-- Заряжаемся, пока энергия не достигнет более-менее максимума
		while computer.energy() / computer.maxEnergy() < 0.99 do
			print("Charging up: " .. math.floor(computer.energy() / computer.maxEnergy() * 100) .. "%")
			os.sleep(1)
		end
		-- Пиздуем обратно
		program.gotoPoint(oldPosition.x, oldPosition.y, oldPosition.z)
		program.turnToRequiredRotation(oldPosition.rotation)
		energyStatusCheckEnabled = true
	end
end

function program.turn(clockwise)
	component.robot.turn(clockwise)
	robotPosition.rotation = robotPosition.rotation + (clockwise and 1 or -1)
	if robotPosition.rotation > 3 then
		robotPosition.rotation = 0
	elseif robotPosition.rotation < 0 then
		robotPosition.rotation = 3
	end
end

function program.turnToRequiredRotation(requiredRotation)
	local difference = robotPosition.rotation - requiredRotation
	
	if difference ~= 0 then
		local fastestWay
		if difference > 0 then
			if difference > 2 then fastestWay = true else fastestWay = false end
		else
			if -difference > 2 then fastestWay = false else fastestWay = true end
		end

		while robotPosition.rotation ~= requiredRotation do
			program.turn(fastestWay)
		end
	end
end

function program.gotoPoint(xTarget, yTarget, zTarget)
	local xDistance = xTarget - robotPosition.x
	local yDistance = yTarget - robotPosition.y
	local zDistance = zTarget - robotPosition.z

	if yDistance ~= 0 then
		local direction = yDistance > 0 and sides.up or sides.down
		for i = 1, math.abs(yDistance) do program.move(direction) end
	end

	if xDistance ~= 0 then
		program.turnToRequiredRotation(xDistance > 0 and 0 or 2)
		for i = 1, math.abs(xDistance) do program.move(sides.front) end
	end

	if zDistance ~= 0 then
		program.turnToRequiredRotation(zDistance > 0 and 1 or 3)
		for i = 1, math.abs(zDistance) do program.move(sides.front) end
	end

	-- Если количество пустых слотов меньше, чем лимит пустых слотов,
	-- то выбрасываем весь дерьмовый шмот, указанный в массиве дерьмового шмота
	program.tryToDropShittyResources()

	-- Если включена проверка энергосостояния, то делаем ее и возвращаемся на базу
	-- для подзарядки, если требуется
	if energyStatusCheckEnabled then program.checkEnergyStatus() end

	-- Проверяем также состояние инструментов
	if toolStatusCheckEnabled then program.checkToolStatus() end

	-- А еще заправляем генератор
	program.tryToRechargeByGenerator()
end

function program.findNearestOre(ores)
	local nearest
	for i = 1, #ores do
		local distance = math.sqrt((ores[i].x - robotPosition.x) ^ 2 + (ores[i].y - robotPosition.y) ^ 2 + (ores[i].z - robotPosition.z) ^ 2)
		if not nearest or distance < nearest.distance then
			nearest = {x = ores[i].x, y = ores[i].y, z = ores[i].z, distance = distance, oreIndex = i}
		end
	end
	return nearest
end

function program.scanAndDig(radius, passes, minHardness, maxHardness, bedrockLocation)
	local ores = program.scan(radius, passes, minHardness, maxHardness)
	print("Scanning finished, count of resources to mine: " .. #ores)
	while #ores > 0 do
		local nearest = program.findNearestOre(ores)
		if nearest.y >= bedrockLocation and nearest.y < 0 then
			-- print("Found next nearest ore: (" .. nearest.x .. "; " .. nearest.y .. "; " .. nearest.z .. ")")
			program.gotoPoint(nearest.x, nearest.y, nearest.z)
		end
		table.remove(ores, nearest.oreIndex)
	end
end

function program.getBedrockLocation()
	while true do
		local success, reason = component.robot.swing(sides.down)
		if success or reason == "air" then
			program.move(sides.down)
		else
			if reason == "block" then
				print("Bedrock location is: " .. robotPosition.y)
				return robotPosition.y
			end
		end
	end
end

function program.getEmptySlotsCount()
	local count = 0
	for slot = 1, robot.inventorySize() do
		count = count + (robot.count(slot) == 0 and 1 or 0)
	end
	return count
end

function program.tryToDropShittyResources()
	if program.getEmptySlotsCount() < dropShittyResourcesOnEmptySlots then 
		print("Trying to drop all shitty resources to free some slots for mining")
		for slot = 1, robot.inventorySize() do
			local stack = inventoryController.getStackInInternalSlot(slot)
			if stack then
				for i = 1, #shittyResources do
					if stack.name == shittyResources[i] then
						robot.select(slot)
						robot.drop()
					end
				end
			end
		end

		if program.getEmptySlotsCount() < dropShittyResourcesOnEmptySlots - 2 then
			local oldPosition = {x = robotPosition.x, y = robotPosition.y, z = robotPosition.z, rotation = robotPosition.rotation}
			program.returnToBase()
			program.gotoPoint(oldPosition.x, oldPosition.y, oldPosition.z)
			program.turnToRequiredRotation(oldPosition.rotation)
		end

		robot.select(1)
	end
end

function program.dropAllResoucesIntoBaseChest()
	print("Dropping all mined resources to chest on base")
	for slot = 1, robot.inventorySize() do
		local stack = inventoryController.getStackInInternalSlot(slot)
		if stack then
			if not string.match(stack.name, replaceToolRegex) then
				robot.select(slot)
				robot.drop()
			end
		end
	end
	robot.select(1)
end

function program.checkToolStatus()
	if robot.durability() < replaceToolDurabilityTrigger then
		print("Equipped tool durability lesser then " .. replaceToolDurabilityTrigger)
		local success = false
		
		for slot = 1, robot.inventorySize() do
			local stack = inventoryController.getStackInInternalSlot(slot)
			if stack then
				if string.match(stack.name, replaceToolRegex) and stack.damage / stack.maxDamage < replaceToolDurabilityTrigger then
					local oldSlot = robot.select(slot)
					inventoryController.equip()
					robot.select(oldSlot)
					success = true
					break
				end
			end
		end

		if not success and toolStatusCheckEnabled then
			toolStatusCheckEnabled = false
			returnToBase()
			print("No one useable tool are found in inventory, going back to base")
			os.exit()
		else
			print("Successfullty switched tool to another from inventory")
		end
	end
end

-------------------------------------------------------------------------------------------------------------------

-- getHardness(1, 0)
-- program.checkToolStatus()
-- program.move(sides.front)

-- Выбираем сразу первый слотик по умолчанию
robot.select(1)
-- Определяем позицию говна
print("Going deeper to determine bedrock location...")
local bedrockLocation = program.getBedrockLocation() + 4
-- Ебошим стартовую точку после определения позиции говна, и если она слишком высоко, то робот начнет как раз от нее же
local startPoint = bedrockLocation + 32
if startPoint > 0 then startPoint = 0 end

-- Пиздуем на старт и вкалываем до посинения
program.gotoPoint(0, startPoint, 0)
program.scanAndDig(oreSearchRadius, searchPassesCount, minimumOreHardness, maximumOreHardness, bedrockLocation)

-- В конце возвращаемся на начало и ожидаем, че уж там
program.returnToBase()












