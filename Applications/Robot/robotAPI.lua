
local computer = require("computer")
local event = require("event")
local sides = require("sides")
local component = require("component")

local robotComponent = component.robot
local inventoryController = component.inventory_controller

local robotAPI = {}

-------------------------------------------------- Some variables that user can change for himself --------------------------------------------------

robotAPI.fuels = {
	"minecraft:coal",
	"minecraft:lava_bucket",
	"minecraft:coal_block",
}

robotAPI.shittyResources = {
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

robotAPI.tools = {
	"minecraft:diamond_pickaxe",
	"minecraft:iron_pickaxe",
}

robotAPI.replaceToolOnDurabilityLesserThen = 0.05
robotAPI.returnToHomeOnEneryLowerThen = 0.1
robotAPI.dropShittyResourcesOnCountOfEmptySlotsLesserThen = 4

-------------------------------------------------- API-related stuff --------------------------------------------------

robotAPI.robotPosition = {x = 0, y = 0, z = 0, rotation = 0}

function robotAPI.getRobotPosition()
	return {
		x = robotAPI.robotPosition.x,
		y = robotAPI.robotPosition.y,
		z = robotAPI.robotPosition.z,
		rotation =robotAPI.robotPosition.rotation
	}
end

-------------------------------------------------- Move-related functions --------------------------------------------------

function robotAPI.returnToStartPoint()
	robotAPI.moveToRequiredPoint(0, robotAPI.robotPosition.y, 0)
	robotAPI.turnToRequiredRotation(0)
	robotAPI.tryToDropShittyResources()
	robotAPI.moveToRequiredPoint(0, 0, 0)
end

function robotAPI.move(direction)
	while true do
		local swingSuccess, swingReason = robotComponent.swing(direction)
		if swingSuccess or swingReason == "air" then
			local moveSuccess, moveReason = robotComponent.move(direction)
			if moveSuccess then
				break
			end
		else
			if swingReason == "block" then
				robotAPI.returnToStartPoint()
				error("Unbreakable block detected, going to base")
			end
		end
	end

	if direction == sides.front or direction == sides.back then
		local directionOffset = direction == sides.front and 1 or -1

		if robotAPI.robotPosition.rotation == 0 then
			robotAPI.robotPosition.x = robotAPI.robotPosition.x + directionOffset
		elseif robotAPI.robotPosition.rotation == 1 then
			robotAPI.robotPosition.z = robotAPI.robotPosition.z + directionOffset
		elseif robotAPI.robotPosition.rotation == 2 then
			robotAPI.robotPosition.x = robotAPI.robotPosition.x - directionOffset
		elseif robotAPI.robotPosition.rotation == 3 then
			robotAPI.robotPosition.z = robotAPI.robotPosition.z - directionOffset
		end
	elseif direction == sides.up or direction == sides.down then
		local directionOffset = direction == sides.up and 1 or -1
		robotAPI.robotPosition.y = robotAPI.robotPosition.y + directionOffset
	end
end

function robotAPI.turn(clockwise)
	robotComponent.turn(clockwise)
	robotAPI.robotPosition.rotation = robotAPI.robotPosition.rotation + (clockwise and 1 or -1)
	if robotAPI.robotPosition.rotation > 3 then
		robotAPI.robotPosition.rotation = 0
	elseif robotAPI.robotPosition.rotation < 0 then
		robotAPI.robotPosition.rotation = 3
	end
end

function robotAPI.turnToRequiredRotation(requiredRotation)
	local difference = robotAPI.robotPosition.rotation - requiredRotation
	
	if difference ~= 0 then
		local fastestWay
		if difference > 0 then
			if difference > 2 then fastestWay = true else fastestWay = false end
		else
			if -difference > 2 then fastestWay = false else fastestWay = true end
		end

		while robotAPI.robotPosition.rotation ~= requiredRotation do
			robotAPI.turn(fastestWay)
		end
	end
end

function robotAPI.moveToRequiredPoint(xTarget, yTarget, zTarget)
	local xDistance = xTarget - robotAPI.robotPosition.x
	local yDistance = yTarget - robotAPI.robotPosition.y
	local zDistance = zTarget - robotAPI.robotPosition.z

	if yDistance ~= 0 then
		local direction = yDistance > 0 and sides.up or sides.down
		for i = 1, math.abs(yDistance) do robotAPI.move(direction) end
	end

	if xDistance ~= 0 then
		robotAPI.turnToRequiredRotation(xDistance > 0 and 0 or 2)
		for i = 1, math.abs(xDistance) do robotAPI.move(sides.front) end
	end

	if zDistance ~= 0 then
		robotAPI.turnToRequiredRotation(zDistance > 0 and 1 or 3)
		for i = 1, math.abs(zDistance) do robotAPI.move(sides.front) end
	end
end

-------------------------------------------------- Inventory-related functions --------------------------------------------------

function robotAPI.getEmptySlotsCount()
	local count = 0
	for slot = 1, robotComponent.inventorySize() do
		count = count + (robotComponent.count(slot) == 0 and 1 or 0)
	end
	return count
end

function robotAPI.tryToDropShittyResources(side)
	if robotAPI.getEmptySlotsCount() < robotAPI.dropShittyResourcesOnCountOfEmptySlotsLesserThen then 
		print("Trying to drop all shitty resources to free some slots for mining")
		for slot = 1, robotComponent.inventorySize() do
			local stack = inventoryController.getStackInInternalSlot(slot)
			if stack then
				for i = 1, #robotAPI.shittyResources do
					if stack.name == robotAPI.shittyResources[i] then
						robotComponent.select(slot)
						robotComponent.drop(side or sides.down)
					end
				end
			end
		end

		robotComponent.select(1)
	end
end

function robotAPI.dropAllResources(side, exceptArray)
	side = side or sides.front
	exceptArray = exceptArray or robotAPI.tools
	print("Dropping all mined resources...")

	for slot = 1, robotComponent.inventorySize() do
		local stack = inventoryController.getStackInInternalSlot(slot)
		if stack then
			local thisIsAShittyItem = true
			
			for exceptItem = 1, #exceptArray do
				if stack.name == exceptArray[exceptItem] then
					thisIsAShittyItem = false
					break
				end
			end
			
			if thisIsAShittyItem then
				robotComponent.select(slot)
				robotComponent.drop(side)
			end
		end
	end
	robotComponent.select(1)
end

function robotAPI.checkToolStatus()
	if robotComponent.durability() < robotAPI.replaceToolOnDurabilityLesserThen then
		print("Equipped tool durability lesser then " .. robotAPI.replaceToolOnDurabilityLesserThen)
		local success = false
		
		for slot = 1, robotComponent.inventorySize() do
			local stack = inventoryController.getStackInInternalSlot(slot)
			if stack then
				for tool = 1, #robotAPI.tools do
					if stack.name == robotAPI.tools[tool] and stack.damage / stack.maxDamage < robotAPI.replaceToolOnDurabilityLesserThen then
						local oldSlot = robotComponent.select()
						robotComponent.select(slot)
						inventoryController.equip()
						robotComponent.select(oldSlot)
						success = true
						break
					end
				end
			end
		end

		if not success then
			robotAPI.returnToStartPoint()
			error("No one useable tool are found in inventory, going back to base")
		else
			print("Successfullty switched tool to another from inventory")
		end
	end
end

-------------------------------------------------- Energy-related functions --------------------------------------------------

function robotAPI.checkEnergyStatus()
	if computer.energy() / computer.maxEnergy() < robotAPI.returnToHomeOnEneryLowerThen then
		print("Low energy level detected")
		-- Запоминаем старую позицию, шобы суда вернуться
		local oldPosition = robotAPI.getRobotPosition()
		-- Пиздуем на базу за зарядкой
		robotAPI.returnToStartPoint()
		-- Заряжаемся, пока энергия не достигнет более-менее максимума
		while computer.energy() / computer.maxEnergy() < 0.99 do
			print("Charging up: " .. math.floor(computer.energy() / computer.maxEnergy() * 100) .. "%")
			os.sleep(1)
		end
		-- Пиздуем обратно
		robotAPI.moveToRequiredPoint(oldPosition.x, oldPosition.y, oldPosition.z)
		robotAPI.turnToRequiredRotation(oldPosition.rotation)
	end
end

function robotAPI.getSlotWithFuel()
	for slot = 1, robotComponent.inventorySize() do
		local stack = inventoryController.getStackInInternalSlot(slot)
		if stack then
			for fuel = 1, #robotAPI.fuels do
				if stack.name == robotAPI.fuels[fuel] then
					return slot
				end
			end
		end
	end
end

function robotAPI.checkGeneratorStatus()
	if component.isAvailable("generator") then
		if component.generator.count() == 0 then
			print("Generator is empty, trying to find some fuel in inventory")
			local slot = robotAPI.getSlotWithFuel()
			if slot then
				print("Found slot with fuel: " .. slot)
				local oldSlot = robotComponent.select()
				robotComponent.select(slot)
				component.generator.insert()
				robotComponent.select(oldSlot)
				return
			else
				print("Slot with fuel not found")
			end
		end
	end
end

-------------------------------------------------- Shortcut functions --------------------------------------------------

-- Swing
function robotAPI.swingForward()
	return robotComponent.swing(sides.front)
end

function robotAPI.swingUp()
	return robotComponent.swing(sides.up)
end

function robotAPI.swingDown()
	return robotComponent.swing(sides.down)
end

--Use
function robotAPI.useForward()
	return robotComponent.use(sides.front)
end

function robotAPI.useUp()
	return robotComponent.use(sides.up)
end

function robotAPI.useDown()
	return robotComponent.use(sides.down)
end

-- Move
function robotAPI.moveForward()
	robotAPI.move(sides.front)
end

function robotAPI.moveBack()
	robotAPI.move(sides.back)
end

function robotAPI.moveUp()
	robotAPI.move(sides.up)
end

function robotAPI.moveDown()
	robotAPI.move(sides.down)
end

-- Turn
function robotAPI.turnLeft()
	robotAPI.turn(false)
end

function robotAPI.turnRight()
	robotAPI.turn(true)
end

function robotAPI.turnAround()
	robotAPI.turn(true)
	robotAPI.turn(true)
end

-------------------------------------------------- End of shit --------------------------------------------------

return robotAPI








