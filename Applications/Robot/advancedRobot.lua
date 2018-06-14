
local computer = require("computer")
local event = require("event")
local sides = require("sides")

local AR = {}

--------------------------------------------------------------------------------

AR.proxies = {}
AR.requiredProxies = {
	"robot",
	"generator",
	"inventory_controller",
	"modem",
	"geolyzer",
	"redstone",
	"experience",
	"chunkloader"
}

AR.fuels = {
	"minecraft:coal",
	"minecraft:coal_block",
	"minecraft:lava_bucket",
	"minecraft:coal_block",
}

AR.droppables = {
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

AR.tools = {
	"minecraft:diamond_pickaxe",
	"minecraft:iron_pickaxe",
}

AR.toolReplaceDurability = 0.05
AR.zeroPositionReturnEnergy = 0.1
AR.emptySlotsCountDropping = 4

AR.positionX = 0
AR.positionY = 0
AR.positionZ = 0
AR.rotation = 0

--------------------------------------------------------------------------------

function AR.updateProxies()
	local name
	for i = 1, #AR.requiredProxies do
		name = AR.requiredProxies[i]
		
		AR.proxies[name] = component.list(name)()
		if AR.proxies[name] then
			AR.proxies[name] = component.proxy(AR.proxies[name])
		end
	end
end

function AR.moveToZeroPosition()
	AR.moveToRequiredPosition(0, AR.positionY, 0)
	AR.turnToRequiredRotation(0)
	AR.tryToDropDroppables()
	AR.moveToRequiredPosition(0, 0, 0)
end

function AR.move(direction)
	while true do
		local swingSuccess, swingReason = AR.proxies.robot.swing(direction)
		if swingSuccess or swingReason == "air" then
			local moveSuccess, moveReason = AR.proxies.robot.move(direction)
			if moveSuccess then
				break
			end
		else
			if swingReason == "block" then
				AR.moveToZeroPosition()
				error("Unbreakable block detected, going to base")
			end
		end
	end

	if direction == sides.front or direction == sides.back then
		local directionOffset = direction == sides.front and 1 or -1

		if AR.rotation == 0 then
			AR.positionX = AR.positionX + directionOffset
		elseif AR.rotation == 1 then
			AR.positionZ = AR.positionZ + directionOffset
		elseif AR.rotation == 2 then
			AR.positionX = AR.positionX - directionOffset
		elseif AR.rotation == 3 then
			AR.positionZ = AR.positionZ - directionOffset
		end
	elseif direction == sides.up or direction == sides.down then
		local directionOffset = direction == sides.up and 1 or -1
		AR.positionY = AR.positionY + directionOffset
	end
end

function AR.turn(clockwise)
	AR.proxies.robot.turn(clockwise)
	AR.rotation = AR.rotation + (clockwise and 1 or -1)
	if AR.rotation > 3 then
		AR.rotation = 0
	elseif AR.rotation < 0 then
		AR.rotation = 3
	end
end

function AR.turnToRequiredRotation(requiredRotation)
	local difference = AR.rotation - requiredRotation
	
	if difference ~= 0 then
		local fastestWay
		if difference > 0 then
			if difference > 2 then fastestWay = true else fastestWay = false end
		else
			if -difference > 2 then fastestWay = false else fastestWay = true end
		end

		while AR.rotation ~= requiredRotation do
			AR.turn(fastestWay)
		end
	end
end

function AR.moveToRequiredPosition(xTarget, yTarget, zTarget)
	local xDistance = xTarget - AR.positionX
	local yDistance = yTarget - AR.positionY
	local zDistance = zTarget - AR.positionZ

	if yDistance ~= 0 then
		local direction = yDistance > 0 and sides.up or sides.down
		for i = 1, math.abs(yDistance) do AR.move(direction) end
	end

	if xDistance ~= 0 then
		AR.turnToRequiredRotation(xDistance > 0 and 0 or 2)
		for i = 1, math.abs(xDistance) do AR.move(sides.front) end
	end

	if zDistance ~= 0 then
		AR.turnToRequiredRotation(zDistance > 0 and 1 or 3)
		for i = 1, math.abs(zDistance) do AR.move(sides.front) end
	end
end

function AR.getEmptySlotsCount()
	local count = 0
	for slot = 1, AR.inventorySize() do
		if AR.count(slot) == 0 then
			count = count + 1
		end
	end

	return count
end

function AR.tryToDropDroppables(side)
	if AR.getEmptySlotsCount() < AR.emptySlotsCountDropping then 
		print("Trying to drop all shitty resources to free some slots for mining")
		for slot = 1, AR.inventorySize() do
			local stack = AR.getStackInInternalSlot(slot)
			if stack then
				for i = 1, #AR.droppables do
					if stack.name == AR.droppables[i] then
						AR.select(slot)
						AR.drop(side or sides.down)
					end
				end
			end
		end

		AR.select(1)
	end
end

function AR.dropAll(side, exceptArray)
	exceptArray = exceptArray or AR.tools
	print("Dropping all mined resources...")

	for slot = 1, AR.inventorySize() do
		local stack = AR.getStackInInternalSlot(slot)
		if stack then
			local droppableItem = true
			
			for exceptItem = 1, #exceptArray do
				if stack.name == exceptArray[exceptItem] then
					droppableItem = false
					break
				end
			end
			
			if droppableItem then
				AR.select(slot)
				AR.drop(side)
			end
		end
	end

	AR.select(1)
end

function AR.checkToolStatus()
	if AR.durability() < AR.toolReplaceDurability then
		print("Equipped tool durability lesser then " .. AR.toolReplaceDurability)
		local success = false
		
		for slot = 1, AR.inventorySize() do
			local stack = AR.getStackInInternalSlot(slot)
			if stack then
				for tool = 1, #AR.tools do
					if stack.name == AR.tools[tool] and stack.damage / stack.maxDamage < AR.toolReplaceDurability then
						local oldSlot = AR.select()
						AR.select(slot)
						AR.equip()
						AR.select(oldSlot)
						success = true
						break
					end
				end
			end
		end

		if not success then
			AR.moveToZeroPosition()
			error("No one useable tool are found in inventory, going back to base")
		else
			print("Successfullty switched tool to another from inventory")
		end
	end
end

function AR.checkEnergyStatus()
	if computer.energy() / computer.maxEnergy() < AR.zeroPositionReturnEnergy then
		print("Low energy level detected")
		-- Запоминаем старую позицию, шобы суда вернуться
		local oldPosition = AR.getRobotPosition()
		-- Пиздуем на базу за зарядкой
		AR.moveToZeroPosition()
		-- Заряжаемся, пока энергия не достигнет более-менее максимума
		while computer.energy() / computer.maxEnergy() < 0.99 do
			print("Charging up: " .. math.floor(computer.energy() / computer.maxEnergy() * 100) .. "%")
			os.sleep(1)
		end
		-- Пиздуем обратно
		AR.moveToRequiredPosition(oldPosition.x, oldPosition.y, oldPosition.z)
		AR.turnToRequiredRotation(oldPosition.rotation)
	end
end

function AR.getSlotWithFuel()
	for slot = 1, AR.inventorySize() do
		local stack = AR.getStackInInternalSlot(slot)
		if stack then
			for fuel = 1, #AR.fuels do
				if stack.name == AR.fuels[fuel] then
					return slot
				end
			end
		end
	end
end

function AR.checkGeneratorStatus()
	if AR.proxies.generator then
		if AR.proxies.generator.count() == 0 then
			print("Generator is empty, trying to find some fuel in inventory")
			local slot = AR.getSlotWithFuel()
			if slot then
				print("Found slot with fuel: " .. slot)
				local oldSlot = AR.select()
				AR.select(slot)
				AR.proxies.generator.insert()
				AR.select(oldSlot)
				return
			else
				print("Slot with fuel not found")
			end
		end
	end
end

--------------------------------------------------------------------------------

-- Swing
function AR.swingForward()
	return AR.proxies.robot.swing(sides.front)
end

function AR.swingUp()
	return AR.proxies.robot.swing(sides.up)
end

function AR.swingDown()
	return AR.proxies.robot.swing(sides.down)
end
--Use
function AR.useForward()
	return AR.proxies.robot.use(sides.front)
end

function AR.useUp()
	return AR.proxies.robot.use(sides.up)
end

function AR.useDown()
	return AR.proxies.robot.use(sides.down)
end
-- Move
function AR.moveForward()
	return AR.move(sides.front)
end

function AR.moveBackward()
	return AR.move(sides.back)
end

function AR.moveUp()
	return AR.move(sides.up)
end

function AR.moveDown()
	return AR.move(sides.down)
end
-- Turn
function AR.turnLeft()
	return AR.turn(false)
end

function AR.turnRight()
	return AR.turn(true)
end

function AR.turnAround()
	AR.turn(true)
	AR.turn(true)
end

AR.select = AR.proxies.robot.select
AR.drop = AR.proxies.robot.drop
AR.durability = AR.proxies.robot.durability
AR.inventorySize = AR.proxies.robot.inventorySize
AR.count = AR.proxies.robot.count

--------------------------------------------------------------------------------

local function callProxyMethod(proxyName, methodName, ...)
	if AR.proxies[proxyName] then
		return AR.proxies[proxyName][methodName](...)
	else
		return false, proxyName .. " component is not available"
	end
end

function AR.equip(...)
	return callProxyMethod("inventory_controller", "equip", ...)
end

function AR.getStackInInternalSlot(...)
	return callProxyMethod("inventory_controller", "getStackInInternalSlot", ...)
end

--------------------------------------------------------------------------------

AR.updateProxies()

--------------------------------------------------------------------------------

return AR