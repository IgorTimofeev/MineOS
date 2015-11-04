local robot = require("robot")
local component = require("component")
local robotAPI = require("robotAPI")
local inventory = component.inventory_controller

local args = { ... }
if #args < 2 then print(" "); print("Использование: laser <ширина> <высота>"); print(" "); return end

local width = tonumber(args[1])
local height = tonumber(args[2])

for w = 1, width/2 do
	for h = 1, height do
		robot.use()
		if h < height then robotAPI.move("up") end
	end

	robot.turnRight()
	robotAPI.move("forward")
	robot.turnLeft()

	for h = 1, height do
		robot.use()
		if h < height then robotAPI.move("down") end
	end

	robot.turnRight()
	robotAPI.move("forward")
	robot.turnLeft()
end

