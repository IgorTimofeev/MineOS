


-------------------------------------------- Библиотеки -------------------------------------------------------------

local component = require("component")
local colorlib = require("colorlib")
local gpu = component.gpu

local tetris = {}

-------------------------------------------- Переменные -------------------------------------------------------------

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

local colors = {
	tetrisColor = 0xFF5555,
	screen = 0xCCDBBF,
	pixel = 0x000000,
	button = 0xFFFF00,
}

local function calculateBrightness(color1, brightness)
	local color
	if brightness < 0 then color = 0x000000 else color = 0xFFFFFF end
	brightness = math.abs(brightness) 
	return colorlib.alphaBlend(color1, color, brightness)
end

local function recalculateColors()
	--Всякие тени, света для корпуса
	colors.light1 = calculateBrightness(colors.tetrisColor, 0xCC)
	colors.light2 = calculateBrightness(colors.tetrisColor, 0xAA)
	colors.light3 = calculateBrightness(colors.tetrisColor, 0x55)
	colors.shadow1 = calculateBrightness(colors.tetrisColor, -(0xCC))
	colors.shadow2 = calculateBrightness(colors.tetrisColor, -(0xAA))
	colors.shadow3 = calculateBrightness(colors.tetrisColor, -(0x77))
	--Для кнопочек
	if colors.button > 0x777777 then
		colors.buttonText = calculateBrightness(colors.button, -(0x77))
	else
		colors.buttonText = calculateBrightness(colors.button, 0x77)
	end
end

local sizes = {}
sizes.xScreenOffset = 4
sizes.yScreenOffset = 3

-------------------------------------------- Функции -------------------------------------------------------------

function tetris.recalculateSizes()
	sizes.widthOfScreen = #tetris.screen.main[1] * 2 + (function() if tetris.showInfoPanel then return 10 else return 0 end end)()
	sizes.heightOfScreen = #tetris.screen.main
end

function tetris.generateScreenArray(width, height)
	tetris.screen.main = {}
	for j = 1, height do
		tetris.screen.main[j] = {}
		for i = 1, width do
			tetris.screen.main[j][i] = 0
		end
	end
end

function tetris.drawOnlyMainScreen()
	local xPos, yPos = tetris.xScreen, tetris.yScreen
	for j = 1, #tetris.screen.main do
		xPos = tetris.xScreen
		for i = 1, #tetris.screen.main[j] do
			if tetris.screen.main[j][i] == 1 then
				gpu.set(xPos, yPos, "⬛")
			else
				gpu.set(xPos, yPos, "⬜")
			end

			xPos = xPos + 2
		end
		yPos = yPos + 1
	end
	xPos, yPos = nil, nil
end

function tetris.drawOnlyMiniScreen(x, y)
	local xPos, yPos = x, y
	for j = 1, #tetris.screen.mini do
		xPos = x	
		for i = 1, #tetris.screen.mini[j] do
			if tetris.screen.mini[j][i] == 1 then
				gpu.set(xPos, yPos, "⬛")
			else
				gpu.set(xPos, yPos, "⬜")
			end

			xPos = xPos + 2
		end
		yPos = yPos + 1
	end
	xPos, yPos = nil, nil
end

function tetris.getPixel(x, y, whichScreen)
	return tetris.screen[whichScreen or "main"][y][x]
end

function tetris.setPixel(x, y, state, whichScreen)
	tetris.screen[whichScreen or "main"][y][x] = state
end

function tetris.changeColors(caseColor, buttonsColor, screenColor, pixelsColor)
	colors.tetrisColor = caseColor or colors.tetrisColor
	colors.button = buttonsColor or colors.button
	colors.screen = screenColor or colors.screen
	colors.pixel = pixelsColor or colors.pixel
end

function tetris.drawScreen()
	local xPos, yPos = tetris.xScreen, tetris.yScreen
	--Рисуем квадрат экрана
	ecs.square(xPos, yPos, sizes.widthOfScreen, sizes.heightOfScreen, colors.screen)
	--Делаем цвет пикселей
	gpu.setForeground(colors.pixel)
	tetris.drawOnlyMainScreen()
	
	--Если показывать инфопанель = труе, то показать, хули
	if tetris.showInfoPanel then
		xPos, yPos = xPos + sizes.widthOfScreen - 9, yPos + 1

		gpu.set(xPos + 1, yPos, "Score:"); yPos = yPos + 1
		gpu.set(xPos + 2, yPos, tostring(tetris.screen.score)); yPos = yPos + 2

		gpu.set(xPos, yPos, "HiScore:"); yPos = yPos + 1
		gpu.set(xPos + 1, yPos, tostring(tetris.screen.highScore)); yPos = yPos + 2

		gpu.set(xPos + 2, yPos, "Next:"); yPos = yPos + 1

		tetris.drawOnlyMiniScreen(xPos, yPos); yPos = yPos + 5

		gpu.set(xPos + 1, yPos, "Speed:"); yPos = yPos + 1
		gpu.set(xPos + 3, yPos, tostring(tetris.screen.speed)); yPos = yPos + 2

		gpu.set(xPos + 1, yPos, "Level:"); yPos = yPos + 1
		gpu.set(xPos + 3, yPos, tostring(tetris.screen.level)); yPos = yPos + 2
	end
end

function tetris.drawButtons()
	local xPos, yPos = tetris.x + math.floor(sizes.caseWidth / 2 - 17), tetris.y + (sizes.heightOfScreen + sizes.yScreenOffset * 2 + 6) + 6

	ecs.drawButton(xPos, yPos, 6, 3, "⮜", colors.button, colors.buttonText)
	xPos = xPos + 12
	ecs.drawButton(xPos, yPos, 6, 3, "⮞", colors.button, colors.buttonText)
	xPos = xPos - 6
	yPos = yPos - 3
	ecs.drawButton(xPos, yPos, 6, 3, "⮝", colors.button, colors.buttonText)
	yPos = yPos + 3 * 2
	ecs.drawButton(xPos, yPos, 6, 3, "⮟", colors.button, colors.buttonText)

	xPos = xPos + 17
	yPos = yPos - 4
	ecs.square(xPos + 2, yPos, 6, 5, colors.button)
	ecs.square(xPos, yPos + 1, 10, 3, colors.button)
end

function tetris.drawCase()
	--Делаем перерасчет размеров экрана
	tetris.recalculateSizes()
	--Рассчитываем размер корпуса
	sizes.xSize, sizes.ySize = gpu.getResolution()
	sizes.caseWidth = sizes.widthOfScreen + sizes.xScreenOffset * 2
	sizes.heightOfBottomThing = sizes.ySize - (sizes.heightOfScreen + sizes.yScreenOffset * 2 + 6) - tetris.y + 1
	local yPos = tetris.y
	--Рисуем верхнюю штучку
	ecs.square(tetris.x + 1, yPos, sizes.caseWidth - 2, 1, colors.light2)
	yPos = yPos + 1
	--Рисуем всю штучку под экраном
	ecs.square(tetris.x, yPos, sizes.caseWidth, sizes.heightOfScreen + sizes.yScreenOffset * 2 - 1, colors.tetrisColor)
	ecs.square(tetris.x + sizes.xScreenOffset - 1, yPos + 1, sizes.widthOfScreen + 2, sizes.heightOfScreen + 2, colors.shadow1)
	yPos = yPos + sizes.heightOfScreen + sizes.yScreenOffset * 2 - 1
	--Рисуем кольцевую штучку
	ecs.square(tetris.x, yPos, sizes.caseWidth, 1, colors.light2); yPos = yPos + 1
	ecs.square(tetris.x, yPos, sizes.caseWidth, 1, colors.light1); yPos = yPos + 1
	ecs.square(tetris.x, yPos, sizes.caseWidth, 2, colors.tetrisColor); yPos = yPos + 2
	ecs.square(tetris.x, yPos, sizes.caseWidth, 1, colors.shadow1); yPos = yPos + 1
	ecs.square(tetris.x, yPos, sizes.caseWidth, 1, colors.shadow2); yPos = yPos + 1
	--Рисуем под кнопочками
	ecs.square(tetris.x, yPos, sizes.caseWidth, sizes.heightOfBottomThing, colors.tetrisColor)
end

function tetris.draw(x, y, screenResolutionWidth, screenResolutionHeight, showInfoPanel)
	--Задаем переменную показа инфопанели
	tetris.showInfoPanel = showInfoPanel
	--Просчитываем цвета
	recalculateColors()
	--Создаем массив основного экрана нужной ширины и высоты
	tetris.generateScreenArray(screenResolutionWidth, screenResolutionHeight)
	--Рисуем корпус устройства
	tetris.x, tetris.y = x, y
	tetris.drawCase()
	--Рисуем экран тетриса
	tetris.xScreen, tetris.yScreen = tetris.x + sizes.xScreenOffset, tetris.y + sizes.yScreenOffset
	tetris.drawScreen()
	--Кнопочки рисуем
	tetris.drawButtons()
end

-------------------------------------------- Программа -------------------------------------------------------------

--ecs.prepareToExit()

tetris.changeColors(0x008800, 0xFFFF00)
tetris.draw(10, 5, 27, 20, false)
tetris.changeColors(0xFF5555, 0xFFFF00)
tetris.draw(80, 5, 10, 20, true)

ecs.waitForTouchOrClick()
















