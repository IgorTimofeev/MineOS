local robot = require("robot")
local component = require("component")
local inventory = component.inventory_controller

local robotAPI = {}

---------------------------------------------------------------------------------------------------------------------------------------

local countOfTries = 20
local sleepDelay = 0.06

local itemsToDrop = {
	"minecraft:cobblestone",
	"minecraft:dirt",
	"minecraft:gravel",
	"minecraft:sand",
}

local directions = {
	up = { move = robot.up, swing = robot.swingUp},
	down = { move = robot.down, swing = robot.swingDown},
	forward = { move = robot.forward, swing = robot.swing},
}

function robotAPI.move(direction)
	local tries = 0
	while tries <= countOfTries do
		directions[direction].swing()
		local success, reason = directions[direction].move()
		os.sleep(sleepDelay)
		if success then
			return
		else
			print("Не могу двигаться " .. direction .. ": " .. reason)
		end
		tries = tries + 1
	end
	error("Количество попыток перемещения " .. direction .. " исчерпано, программа завершена")
end

function robotAPI.dropShmot()
	for slot = 1, robot.inventorySize() do
		local item = inventory.getStackInInternalSlot(slot)
		if item then
			for i = 1, #itemsToDrop do
				if item.name == itemsToDrop[i] then
					robot.select(slot)
					robot.drop()
				end
			end
		end
	end
	robot.select(1)
end

--------------------------------------------------------------------------------------------------------------------------------------------

return robotAPI



