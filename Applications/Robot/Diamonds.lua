local robot = require("robot")
local component = require("component")
local robotAPI = require("robotAPI")
local inventory = component.inventory_controller

local args = { ... }
if #args < 3 then print(" "); print("Использование: diamonds <длина> <высота> <ширина>"); print(" "); return end

local length = args[1]
local height = args[2]
local width = args[3]

local moves = {
	
}

local function swingForLength()
	for i = 1, length do
		robotAPI.move("forward")
		robot.swingDown()
		robot.swingUp()
	end
end

local function swingForUp()
	for i = 1, 3 do
		robotAPI.move("up")
	end
end

local function swingForDown()
	for i = 1, 3 do
		robotAPI.move("down")
	end
end

--Перебираем все ширины
for i = 1, width do
	--Перебираем все высоты для конкретной ширины
	for i = 1, height do
		swingForLength()
		robot.turnAround()
		swingForUp()
		swingForLength()
		robot.turnAround()
		swingForUp()
		--Выбрасываем говно
		robotAPI.dropShmot()
	end

	--Возвращаемся по высоте на конкретной ширине
	for i = 1, (height * 2) do
		swingForDown()
	end

	--Двигаемся к следующей ширине
	robot.turnRight()

	for i = 1, 3 do
		robotAPI.move("forward")
	end

	robot.turnLeft()
end

--Возвращаемся домой из последней ширины
robot.turnLeft()

for i = 1, width do
	for j = 1, 3 do
		robotAPI.move("forward")
	end
end

robot.turnRight()


