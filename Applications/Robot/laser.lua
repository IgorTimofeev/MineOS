local robot = require("robot")
local component = require("component")
local robotAPI = require("robotAPI")
local inventory = component.inventory_controller

local args = { ... }
if #args < 2 then print(" "); print("Использование: laser <ширина> <высота>"); print(" "); return end

local width = args[1]
local height = args[2]

for w = 1, width/2 do
	for h = 1, height do
		robot.use()
		robotAPI.move("up")
	end

	robot.turnRight()
	robotAPI.move("forward")
	robot.turnLeft()

	for h = 1, height do
		robotAPI.move("down")
		robot.use()
	end

	robot.turnRight()
	robotAPI.move("forward")
	robot.turnLeft()
end

robot.turnLeft()

for w = 1, width do
	robotAPI.move("forward")
end

robot.turnRight()

