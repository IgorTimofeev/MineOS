
local component = require("component")
local robot = require("robot")
local currentToolSlot = 1
local counter = 0
local inventorySize = robot.inventorySize()


robot.select(1)
local success
while true do
	success = robot.swing()
	if success then
		robot.place()
	end
	counter = counter + 1
	if counter > 50 then
		local durability = robot.durability() or 500000000
		counter = 0
		print("Текущая экспа: " .. robot.level())
		print("Текущий слот: " .. currentToolSlot)
		print("Текущая прочность: " .. durability)
		print(" ")
		if durability < 0.1 then
			currentToolSlot = currentToolSlot + 1
			if currentToolSlot > inventorySize then currentToolSlot = inventorySize end
			robot.select(currentToolSlot)
			component.inventory_controller.equip()
			robot.select(1)
		end
	end
end











