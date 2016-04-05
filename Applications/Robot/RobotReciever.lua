

local event = require("event")
local robot = require("robot")
local component = require("component")
local serialization = require("serialization")
local modem = component.modem
local inventoryController = component.inventory_controller
local port = 1337
local moveSleepDelay = 0.05

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
		print("Ошибка try:", functionName, reason)
		sendMessage(errorMessage, functionName, reason)
	end
	os.sleep(moveSleepDelay)
end

local function sendInventory()
	local inventory = {}
	local inventorySize = robot.inventorySize()
	
	for slot = 1, inventorySize do
		table.insert(inventory, inventoryController.getStackInInternalSlot(slot))
	end

	sendMessage("inventoryInfo", serialization.serialize(inventory))
	print("Отправляю информацию об инвентаре")
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
					try(e[7], "successfullyRotatedTo", "cantRotateWTF")
				elseif e[7] == "swing" then
					try(e[7], "successfullySwingedTo", "cantSwingTo")
				elseif e[7] == "use" then
					robot.use()
				elseif e[7] == "drop" then
					robot.drop(e[8] or 1)
				elseif e[7] == "giveMeInfoAboutInventory" then
					sendInventory()
				end
			end
		end
	end
end









