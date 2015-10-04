


-------------------------------------------- Библиотеки -------------------------------------------------------------

local component = require("component")
local gpu = component.gpu

local tetris = {}

-------------------------------------------- Переменные -------------------------------------------------------------

local colors = {
	tetrisColor = 0x6649FF,
	screen = 0xccdbbf,
	activePixel = 0x000000,
}

local sizes = {}
sizes.xSize, sizes.ySize = gpu.getResolution()
sizes.xScreenOffset = 4
sizes.yScreenOffset = 2
sizes.width = 30 + sizes.xScreenOffset * 2
sizes.height = 20 + sizes.yScreenOffset * 2 + 10
sizes.widthOfScreen = 30
sizes.heightOfScreen = 20

--Символы высокого разрешения
local highResolutionTopPixel = "▀"
local highResolutionMidPixel = "█"
local highResolutionBotPixel = "▄"

-------------------------------------------- Функции -------------------------------------------------------------

--Функция отрисовки квадрата высокого разрешения
local function highResolutionSquare(x, y, width, height, color)

	gpu.setForeground(color)
	--Считаем количество сдвоенных пикселей
	local countOfMidPixels = math.floor(height / 2)
	--Если количество пикселей по высоте больше 1, то залить верний ряд
	if height > 1 then
		gpu.fill(x, y, width, 1, highResolutionTopPixel)
	end
	--Залить средний ряд
	gpu.fill(x, y, width, countOfMidPixels, highResolutionMidPixel)
	--Если высота нечетная, то залить нижний ряд
	if height % 2 ~= 0 then
		gpu.fill(x, y + countOfMidPixels, width, 1, highResolutionTopPixel)
	end
	--Очищаем память
	highResolutionTopPixel, highResolutionMidPixel, highResolutionBotPixel, countOfMidPixels = nil, nil, nil, nil
end

tetris.screen = {
	main = {
		{0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
		{0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
		{0, 0, 0, 1, 1, 1, 0, 0, 0, 0},
		{0, 0, 1, 0, 0, 0, 1, 0, 0, 0},
		{0, 0, 1, 0, 0, 0, 1, 0, 0, 0},
		{0, 0, 1, 1, 1, 1, 1, 0, 0, 0},
		{0, 0, 1, 0, 0, 0, 1, 0, 0, 0},
		{0, 0, 1, 0, 0, 0, 1, 0, 0, 0},
		{0, 0, 1, 0, 0, 0, 1, 0, 0, 0},
		{0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
		{0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
		{0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
		{0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
		{0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
		{0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
		{0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
		{0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
		{0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
		{0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
		{0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
	},
	mini = {
		{0, 0, 0, 0},
		{0, 0, 0, 0},
		{0, 0, 0, 0},
		{0, 0, 0, 0},
	},
	score = 538,
	highScore = 1000,
	speed = 1,
	level = 1,
}


function tetris.drawAnyScreen(which, x, y)
	gpu.setForeground(colors.activePixel)
	local xPos, yPos = x, y
	for j = 1, #tetris.screen[which] do
		xPos = x
		
		for i = 1, #tetris.screen[which][j] do
			if tetris.screen[which][j][i] == 1 then
				gpu.set(xPos, yPos, "⬛")
			else
				gpu.set(xPos, yPos, "⬜")
			end

			xPos = xPos + 2
		end

		yPos = yPos + 1
	end
end

function tetris.drawScreen(x, y)
	local xPos, yPos = x, y
	ecs.square(xPos, yPos, sizes.widthOfScreen, sizes.heightOfScreen, colors.screen)
	tetris.drawAnyScreen("main", xPos, yPos)
	
	xPos, yPos = xPos + 21, yPos + 1

	gpu.set(xPos + 1, yPos, "Score:"); yPos = yPos + 1
	gpu.set(xPos, yPos, tostring(tetris.screen.score)); yPos = yPos + 2

	gpu.set(xPos + 2, yPos, "Next:"); yPos = yPos + 1

	tetris.drawAnyScreen("mini", xPos, yPos); yPos = yPos + 5

	gpu.set(xPos + 1, yPos, "Speed:"); yPos = yPos + 1
	gpu.set(xPos + 3, yPos, tostring(tetris.screen.speed)); yPos = yPos + 2

	gpu.set(xPos + 1, yPos, "Level:"); yPos = yPos + 1
	gpu.set(xPos + 3, yPos, tostring(tetris.screen.level)); yPos = yPos + 2
end

function tetris.drawDevice(x, y)
	--Рисуем подкладочку под экран
	ecs.square(x, y, sizes.width, sizes.height, colors.tetrisColor)
	
end

function tetris.draw(x, y)
	--Девайс
	tetris.drawDevice(x, y)
	--Рисуем экран
	tetris.drawScreen(x + sizes.xScreenOffset, y + sizes.yScreenOffset)
end

-------------------------------------------- Программа -------------------------------------------------------------

ecs.prepareToExit()
tetris.draw(2, 2)
















