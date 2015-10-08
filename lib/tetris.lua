
-------------------------------------------- Библиотеки -------------------------------------------------------------

local component = require("component")
local colorlib = require("colorlib")
local gpu = component.gpu

local tetris = {}

-------------------------------------------- Переменные -------------------------------------------------------------

tetris.screen = {
	main = {
		{{false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}},
		{{false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}},
		{{false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}},
		{{false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}},
		{{false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}},
		{{false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}},
		{{false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}},
		{{false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}},
		{{false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}},
		{{false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}},
		{{false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}},
		{{false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}},
		{{false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}},
		{{false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}},
		{{false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}},
		{{false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}},
		{{false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}},
		{{false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}},
		{{false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}},
		{{false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}},
	},
	mini = {
		{{false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}},
		{{false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}},
		{{false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}},
		{{false, 0xF}, {false, 0xF}, {false, 0xF}, {false, 0xF}},
	},
	score = 0,
	highScore = 0,
	speed = 1,
	level = 1,
}

tetris.colors = {
	tetrisColor = 0xFF5555,
	screen = 0xCCDBBF,
	pixel = {},
	button = 0xFFFF00,
}

local sizes = {}
sizes.xScreenOffset = 4
sizes.yScreenOffset = 3

--⬛⬜

-------------------------------------------- Функции -------------------------------------------------------------

--Пересчитать размеры корпуса экрана в зависимости от указанного размера массива
function tetris.recalculateSizes()
	sizes.widthOfScreen = #tetris.screen.main[1] * 2 + (function() if tetris.showInfoPanel then return 10 else return 0 end end)()
	sizes.heightOfScreen = #tetris.screen.main
end

--Сгенерировать новый пустой массив указанного экрана. Экран будет как бы выключенным
function tetris.generateScreenArray(width, height, whichScreen)
	tetris.screen[whichScreen or "main"] = {}
	for j = 1, height do
		tetris.screen[whichScreen or "main"][j] = {}
		for i = 1, width do
			tetris.screen[whichScreen or "main"][j][i] = {false, 0xF}
		end
	end
end

--Рассчитать более темный вариант указанного цвета
local function calculateBrightness(color1, brightness)
	local color
	if brightness < 0 then color = 0x000000 else color = 0xFFFFFF end
	brightness = math.abs(brightness) 
	return colorlib.alphaBlend(color1, color, brightness)
end

--Перерассчитать все цвета
local function recalculateColors()
	--Всякие тени, света для корпуса
	tetris.colors.light1 = calculateBrightness(tetris.colors.tetrisColor, 0xCC)
	tetris.colors.light2 = calculateBrightness(tetris.colors.tetrisColor, 0xAA)
	tetris.colors.light3 = calculateBrightness(tetris.colors.tetrisColor, 0x55)
	tetris.colors.shadow1 = calculateBrightness(tetris.colors.tetrisColor, -(0xCC))
	tetris.colors.shadow2 = calculateBrightness(tetris.colors.tetrisColor, -(0xAA))
	tetris.colors.shadow3 = calculateBrightness(tetris.colors.tetrisColor, -(0x77))
	
	--Для кнопочек
	if tetris.colors.button > 0x777777 then
		tetris.colors.buttonText = calculateBrightness(tetris.colors.button, -(0x77))
	else
		tetris.colors.buttonText = calculateBrightness(tetris.colors.button, 0x77)
	end

	--Просчитываем массив интенсивности цветов пикселя
	tetris.colors.pixel = {}

	for i = 0, 15 do
		tetris.colors.pixel[i] = colorlib.alphaBlend(tetris.colors.screen, 0x000000, (0xFF - i * 16))
	end

	-- ecs.square(2, 2, 10, 5, tetris.colors.pixel[0x0])

	-- ecs.waitForTouchOrClick()

	-- local str = ""
	-- for i = 0, #tetris.colors.pixel do
	-- 	str = str .. ecs.HEXtoString(tetris.colors.pixel[i], 6, true) .. " "
	-- end

	-- ecs.error(str)
end

--Нарисовать пиксели указанного экрана (main или mini)
function tetris.drawPixels(x, y, whichScreen)
	--Задаем стартовое значение
	whichScreen = whichScreen or "main"
	--Задаем стартовые координаты
	local xPos, yPos = x, y
	--Перебираем массив указанного экрана
	for j = 1, #tetris.screen[whichScreen] do
		xPos = x
		for i = 1, #tetris.screen[whichScreen][j] do
			
			if gpu.getForeground() ~= tetris.colors.pixel[tetris.screen[whichScreen][j][i][2]] then
				gpu.setForeground(tetris.colors.pixel[tetris.screen[whichScreen][j][i][2]])
			end

			if tetris.screen[whichScreen][j][i][1] == true then
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

--Нарисовать инфопанель
function tetris.drawInfoPanel()
	--Если показывать инфопанель = труе, то показать, хули
	if tetris.showInfoPanel then
		local xPos, yPos = tetris.xScreen + sizes.widthOfScreen - 9, tetris.yScreen + 1

		--Ставим максимально интенсивный цвет из возможных
		gpu.setForeground(tetris.colors.pixel[0xF])

		gpu.set(xPos + 1, yPos, "Score:"); yPos = yPos + 1
		gpu.set(xPos + 3, yPos, tostring(tetris.screen.score)); yPos = yPos + 2

		gpu.set(xPos, yPos, "HiScore:"); yPos = yPos + 1
		gpu.set(xPos + 3, yPos, tostring(tetris.screen.highScore)); yPos = yPos + 2

		gpu.set(xPos + 2, yPos, "Next:"); yPos = yPos + 1

		--Рисуем мини-экран
		tetris.drawPixels(xPos, yPos, "mini"); yPos = yPos + 5

		--Ставим максимально интенсивный цвет из возможных
		gpu.setForeground(tetris.colors.pixel[0xF])

		gpu.set(xPos + 1, yPos, "Speed:"); yPos = yPos + 1
		gpu.set(xPos + 3, yPos, tostring(tetris.screen.speed)); yPos = yPos + 2

		gpu.set(xPos + 1, yPos, "Level:"); yPos = yPos + 1
		gpu.set(xPos + 3, yPos, tostring(tetris.screen.level)); yPos = yPos + 2
	end
end

function tetris.getPixel(x, y, whichScreen)
	return tetris.screen[whichScreen or "main"][y][x]
end

--Нарисовать пиксель по указанным координатам (экрана!) указанной яркости на указанном экране
function tetris.setPixel(x, y, state, intensivity, whichScreen)
	intensivity = intensivity or 0xF
	whichScreen = whichScreen or "main"
	tetris.screen[whichScreen][y][x][1] = state
	tetris.screen[whichScreen][y][x][2] = intensivity

	if gpu.getForeground() ~= tetris.colors.pixel[tetris.screen[whichScreen][y][x][2]] then
		gpu.setForeground(tetris.colors.pixel[tetris.screen[whichScreen][y][x][2]])
	end

	if tetris.screen[whichScreen][y][x][1] == true then
		gpu.set(tetris.xScreen + x * 2 - 2, tetris.yScreen + y - 1, "⬛")
	else
		gpu.set(tetris.xScreen + x * 2 - 2, tetris.yScreen + y - 1, "⬜")
	end
end

function tetris.changeColors(caseColor, buttonsColor, screenColor)
	tetris.colors.tetrisColor = caseColor or tetris.colors.tetrisColor
	tetris.colors.button = buttonsColor or tetris.colors.button
	tetris.colors.screen = screenColor or tetris.colors.screen
end

function tetris.drawScreen()
	--Рисуем квадрат экрана
	ecs.square(tetris.xScreen, tetris.yScreen, sizes.widthOfScreen, sizes.heightOfScreen, tetris.colors.screen)
	--Рисуем большой экран
	tetris.drawPixels(tetris.xScreen, tetris.yScreen, "main")
	--Рисуем инфопанель
	tetris.drawInfoPanel()
end

function tetris.drawButtons()
	local xPos, yPos = tetris.x + math.floor(sizes.caseWidth / 2 - 17), tetris.y + (sizes.heightOfScreen + sizes.yScreenOffset * 2 + 6) + 6

	ecs.drawButton(xPos, yPos, 6, 3, "⮜", tetris.colors.button, tetris.colors.buttonText)
	xPos = xPos + 12
	ecs.drawButton(xPos, yPos, 6, 3, "⮞", tetris.colors.button, tetris.colors.buttonText)
	xPos = xPos - 6
	yPos = yPos - 3
	ecs.drawButton(xPos, yPos, 6, 3, "⮝", tetris.colors.button, tetris.colors.buttonText)
	yPos = yPos + 3 * 2
	ecs.drawButton(xPos, yPos, 6, 3, "⮟", tetris.colors.button, tetris.colors.buttonText)

	--Жирная кнопа
	xPos = xPos + 17
	yPos = yPos - 4
	ecs.square(xPos + 2, yPos, 6, 5, tetris.colors.button)
	ecs.square(xPos, yPos + 1, 10, 3, tetris.colors.button)


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
	ecs.square(tetris.x + 1, yPos, sizes.caseWidth - 2, 1, tetris.colors.light2)
	yPos = yPos + 1
	--Рисуем всю штучку под экраном
	ecs.square(tetris.x, yPos, sizes.caseWidth, sizes.heightOfScreen + sizes.yScreenOffset * 2 - 1, tetris.colors.tetrisColor)
	ecs.square(tetris.x + sizes.xScreenOffset - 1, yPos + 1, sizes.widthOfScreen + 2, sizes.heightOfScreen + 2, tetris.colors.shadow1)
	yPos = yPos + sizes.heightOfScreen + sizes.yScreenOffset * 2 - 1
	--Рисуем кольцевую штучку
	ecs.square(tetris.x, yPos, sizes.caseWidth, 1, tetris.colors.light2); yPos = yPos + 1
	ecs.square(tetris.x, yPos, sizes.caseWidth, 1, tetris.colors.light1); yPos = yPos + 1
	ecs.square(tetris.x, yPos, sizes.caseWidth, 2, tetris.colors.tetrisColor); yPos = yPos + 2
	ecs.square(tetris.x, yPos, sizes.caseWidth, 1, tetris.colors.shadow1); yPos = yPos + 1
	ecs.square(tetris.x, yPos, sizes.caseWidth, 1, tetris.colors.shadow2); yPos = yPos + 1
	--Рисуем под кнопочками
	ecs.square(tetris.x, yPos, sizes.caseWidth, sizes.heightOfBottomThing, tetris.colors.tetrisColor)
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

-- ecs.prepareToExit()

-- tetris.draw(2, 3, 10, 20, true)

-- gpu.setBackground(tetris.colors.screen)

-- local intensivity = 0x0
-- local xPos, yPos = 1, 1
-- for i = 1, 16 do
-- 	if xPos > 10 then xPos = 1; yPos = yPos + 1 end
-- 	tetris.setPixel(xPos, yPos, true, intensivity)
-- 	tetris.setPixel(xPos, yPos + 3, false, intensivity)
-- 	xPos = xPos + 1
-- 	intensivity = intensivity + 0x1
-- end

return tetris















