local robot = require("robot")
local component = require("component")
local robotAPI = require("robotAPI")
local inventory = component.inventory_controller

local args = { ... }
if #args < 2 then print(" "); print("Использование: laser <длина> <ширина>"); print(" "); return end

local width = tonumber(args[2])
local length = tonumber(args[1])

for w = 1, width/2 do
	for h = 1, length do
		robot.useDown()
		if h < length then robotAPI.move("forward") end
	end

	robot.turnRight()
	robotAPI.move("forward")
	robot.turnRight()

	for h = 1, length do
		robot.useDown()
		if h < length then robotAPI.move("forward") end
	end

	robot.turnLeft()
	robotAPI.move("forward")
	robot.turnLeft()
end

