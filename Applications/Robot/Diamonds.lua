
_G.robotAPI, package.loaded.robotAPI = nil, nil

local robotAPI = require("robotAPI")
local sides = require("sides")
local component = require("component")
local inventoryController = component.inventory_controller
local robotComponent = component.robot

-----------------------------------------------------------------

local args = {...}
if not (args[1] and args[2] and args[3]) then
	print("Usage: diamonds <length> <height> <width> <torch cyka>")
	return
end

local length, height, width, torchFrequency = tonumber(args[1]), tonumber(args[2]), tonumber(args[3]), tonumber(args[4] or 7)
local torchCount, torchSlot

-----------------------------------------------------------------

local function getItemSlotAndCount(item)
	for slot = 1, robotComponent.inventorySize() do
		local stack = inventoryController.getStackInInternalSlot(slot)
		if stack and stack.name == item then
			return slot, stack.size
		end
	end
end


local function doLength()
	for l = 1, length do
		robotAPI.moveForward()
		robotAPI.swingUp()
		robotAPI.swingDown()
		if l % torchFrequency == 0 and torchSlot and torchCount > 0 and robotAPI.robotPosition.y == 0 then
			robotComponent.select(torchSlot)
			robotComponent.place(sides.down)
			torchCount = torchCount - 1
		end
	end

	robotAPI.tryToDropShittyResources()
	robotAPI.checkGeneratorStatus()
	robotAPI.checkEnergyStatus()
	robotAPI.checkToolStatus()
end

local function doHeight()
	for h = 1, height do
		doLength()
		for i = 1, 3 do robotAPI.moveUp() end
		robotAPI.turnAround()
		doLength()
		robotAPI.turnAround()
		if h < height then for i = 1, 3 do robotAPI.moveUp() end end
	end
end

local function doWidth()
	for w = 1, width do
		doHeight()
		for i = 1, height * 3 * 2 - 3 do robotAPI.moveDown() end

		if w < width then
			robotAPI.turnRight()
			for i = 1, 3 do robotAPI.moveForward() end
			robotAPI.turnLeft()
		end
	end
end

-----------------------------------------------------------------

-- Ставим стартовый сундук
local chestSlot = getItemSlotAndCount("minecraft:chest")
if chestSlot then
	robotAPI.turnAround()
	robotComponent.select(chestSlot)
	robotComponent.place(sides.front)
	robotAPI.turnAround()
end

-- Получаем слот факела
torchSlot, torchCount = getItemSlotAndCount("minecraft:torch")

-- Ебошим
doWidth()

-- Пиздуем назад
robotAPI.returnToStartPoint()

-- Скидываем говно в сундук, если он ваще был
if chestSlot then
	robotAPI.turnAround()
	robotAPI.dropAllResources(sides.front)
	robotAPI.turnAround()
end







