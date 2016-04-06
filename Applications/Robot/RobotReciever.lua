

local event = require("event")
local robot = require("robot")
local computer = require("computer")
local component = require("component")
local serialization = require("serialization")
local modem = component.modem
local inventoryController = component.inventory_controller
local port = 1337
local moveSleepDelay = 0.05
local sides = {front = 3, bottom = 0, top = 1}

modem.open(port)

------------------------------------------------------------------------------------------

local function sendMessage(...)
	modem.broadcast(port, "ECSRobotAnswer", ...)
end

local function try(functionName, successMessage, errorMessage)
	local success, reason = robot[functionName]()
	if success then
		sendMessage(successMessage, functionName)
	else
		print("Ошибка try: " .. tostring(functionName) .. " " .. tostring(reason))
		sendMessage(errorMessage, functionName, reason)
	end
	-- os.sleep(moveSleepDelay)
end

local function sendInventoryInfo(type)
	local inventory = {}
	local inventorySize
	
	if type == "internal" then
		inventorySize = robot.inventorySize()
	elseif type == "front" or type == "bottom" or type == "top" then
		inventorySize = inventoryController.getInventorySize(sides[type])
	end

	if inventorySize then
		inventory.inventorySize = inventorySize
		inventory.type = type

		if type == "internal" then
			inventory.currentSlot = robot.select()
			for slot = 1, inventorySize do
				-- if robot.count(i) > 0 then
					inventory[slot] = inventoryController.getStackInInternalSlot(slot)
				-- end
			end
		elseif type == "front" or type == "bottom" or type == "top" then
			for slot = 1, inventorySize do
				inventory[slot] = inventoryController.getStackInSlot(sides[type], slot)
			end
		end
	else
		inventory.noInventory = true
	end

	sendMessage("inventoryInfo", serialization.serialize(inventory))
end

local function sendInfoAboutRobot()
	sendMessage("infoAboutRobot", computer.energy(), computer.maxEnergy(), "Статус")
end

local function sendInfoAboutRedstone()
	local redstoneInfo = {}
	for i = 0, 5 do
		redstoneInfo[i] = component.redstone.getOutput(i)
	end
	sendMessage("infoAboutRedstone", serialization.serialize(redstoneInfo))
end

------------------------------------------------------------------------------------------

while true do
	local e = { event.pull() }
	if e[1] == "modem_message" then
		if e[4] == port then
			if e[6] == "ECSRobotControl" then
				if e[7] == "forward" or e[7] == "back" or e[7] == "up" or e[7] == "down" then
					try(e[7], "successfullyMovedTo", "cantMoveTo")
				elseif e[7] == "turnLeft" or e[7] == "turnRight" then
					try(e[7], "successfullyRotatedTo", "")
				elseif e[7] == "swing" then
					try(e[7], "successfullySwingedTo", "cantSwingTo")
				elseif e[7] == "use" then
					robot.use()
				elseif e[7] == "place" then
					try(e[7], "successfullyPlacedTo", "cantPlaceTo")
				elseif e[7] == "changeColor" then
					component.robot.setLightColor(e[8])
				elseif e[7] == "drop" then
					local oldSlot
					if e[9] then robot.select(e[9]); oldSlot = robot.select() end
					robot.drop(e[8])
					sendInventoryInfo("internal")
					if oldSlot then robot.select(oldSlot) end
				elseif e[7] == "giveMeInfoAboutInventory" then
					sendInventoryInfo(e[8])
				elseif e[7] == "selectSlot" then
					robot.select(e[8])
					sendMessage("selectedSlot", e[8])
				elseif e[7] == "equip" then
					local success = inventoryController.equip(e[8])
					if success then sendInventoryInfo("internal") end
				elseif e[7] == "giveMeInfoAboutRobot" then
					sendInfoAboutRobot()
				elseif e[7] == "giveMeInfoAboutRedstone" then
					sendInfoAboutRedstone()
				elseif e[7] == "suckFromSlot" then
					local success = inventoryController.suckFromSlot(sides[e[8]], e[9])
					if success then sendInventoryInfo(e[8]) end
				elseif e[7] == "changeRedstoneOutput" then
					component.redstone.setOutput(e[8], e[9])
					sendInfoAboutRedstone()
				end
			end
		end
	end
end









