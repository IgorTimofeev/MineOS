

local event = require("event")
local tetris = require("tetris")

------------------------------------------------------------------------------------------------------------------------------------

local width = 10
local height = 20

local snake = {
	{2, 3},
	{3, 3},
	{4, 3},
}

local direction = 3

local speed = 0.2

local xFood, yFood


------------------------------------------------------------------------------------------------------------------------------------

local function checkCoords(x, y)
	if x < 1 then x = width elseif x > width then x = 1 end
	if y < 1 then y = height elseif y > height then y = 1 end
	return x, y
end

local function displaySnake()
	tetris.generateScreenArray(width, height)
	tetris.screen.main[snake[1][2]][snake[1][1]][1] = true
	tetris.screen.main[snake[1][2]][snake[1][1]][2] = 0x7
	for i = 2, #snake do
		tetris.screen.main[snake[i][2]][snake[i][1]][1] = true
	end
	tetris.screen.main[yFood][xFood][1] = true
	tetris.screen.main[yFood][xFood][2] = 0xB
	tetris.drawPixels(tetris.xScreen, tetris.yScreen, "main")
end

local function createFood()
	while true do
		local x, y = math.random(1, width), math.random(1, height)
		local success = true
		
		for i = 1, #snake do
			if snake[i][1] == x and snake[i][2] == y then
				success = false
				break
			end
		end
		
		if success then
			xFood, yFood = x, y
			break
		end
	end
end

local function checkFood()
	if snake[1][1] == xFood and snake[1][2] == yFood then return true else return false end
end

local function checkSnakeHitForItself()
	for i = 2, #snake do
		if snake[1][1] == snake[i][1] and snake[1][2] == snake[i][2] then return false end
	end
	return true
end

local function moveSnake()
	if direction == 1 then
		table.insert(snake, 1, { checkCoords(snake[1][1], snake[1][2] - 1) })
	elseif direction == 2 then
		table.insert(snake, 1, { checkCoords(snake[1][1] + 1, snake[1][2]) })
	elseif direction == 3 then
		table.insert(snake, 1, { checkCoords(snake[1][1], snake[1][2] + 1) })
	else
		table.insert(snake, 1, { checkCoords(snake[1][1] - 1, snake[1][2]) })
	end

	if checkFood() then tetris.screen.score = tetris.screen.score + 300; createFood() else table.remove(snake, #snake) end
	
	tetris.screen.score = math.max(0, tetris.screen.score - 5)

	tetris.drawInfoPanel()

	displaySnake()

	return checkSnakeHitForItself()
end

------------------------------------------------------------------------------------------------------------------------------------

--ecs.prepareToExit()
tetris.screen.score = 0
tetris.draw(32, 3, width, height, true)
createFood()
gpu.setBackground(tetris.colors.screen)
displaySnake()

while true do
	local eventData = { event.pull(speed) }
	if #eventData > 0 then
		if eventData[1] == "key_down" then
			if eventData[4] == 200 and (direction ~= 1 and direction ~= 3) then
				direction = 1
				if not moveSnake() then ecs.error("Игра закончена со счетом "..tetris.screen.score.."!"); break end
			elseif eventData[4] == 208 and (direction ~= 1 and direction ~= 3) then
				direction = 3
				if not moveSnake() then ecs.error("Игра закончена со счетом "..tetris.screen.score.."!"); break end
			elseif eventData[4] == 203 and (direction ~= 2 and direction ~= 4) then
				direction = 4
				if not moveSnake() then ecs.error("Игра закончена со счетом "..tetris.screen.score.."!"); break end
			elseif eventData[4] == 205 and (direction ~= 2 and direction ~= 4) then
				direction = 2
				if not moveSnake() then ecs.error("Игра закончена со счетом "..tetris.screen.score.."!"); break end
			end
		end
	else
		if not moveSnake() then ecs.error("Игра закончена со счетом "..tetris.screen.score.."!"); break end	
	end
end

--ecs.prepareToExit()




