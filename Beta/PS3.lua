
------------------------------------------------ Копирайт --------------------------------------------------------------

local copyright = [[
	
	Photoshop v3.0 (закрытая бета)

	Автор: IT
		Контакты: https://vk.com/id7799889
	Соавтор: Pornogion
		Контакты: https://vk.com/id88323331
	
]]

------------------------------------------------ Библиотеки --------------------------------------------------------------

--Не требующиеся для MineOS
--local ecs = require("ECSAPI")
--local fs = require("filesystem")
--local unicode = require("unicode")
--local context = require("context")

--Обязательные
local colorlib = require("colorlib")
local palette = require("palette")
local event = require("event")
local image = require("image")
local gpu = component.gpu

------------------------------------------------ Переменные --------------------------------------------------------------

--Массив главного изображения
local masterPixels = {
	width = 0,
	height = 0,
}

--Базовая цветовая схема программы
local colors = {
	toolbar = 0x535353,
	toolbarInfo = 0x3d3d3d,
	toolbarButton = 0x3d3d3d,
	toolbarButtonText = 0xeeeeee,
	drawingArea = 0x262626,
	console = 0x3d3d3d,
	consoleText = 0x999999,
	transparencyWhite = 0xffffff,
	transparencyGray = 0xcccccc,
	transparencyVariable = 0xffffff,
	oldBackground = 0x0,
	oldForeground = 0x0,
	topMenu = 0xeeeeee,
	topMenuText = 0x262626,
}

--Различные константы и размеры тулбаров и кликабельных зон
local sizes = {
	widthOfLeftBar = 6,
}
sizes.heightOfTopBar = 3
sizes.xSize, sizes.ySize = gpu.getResolution()
sizes.xStartOfDrawingArea = sizes.widthOfLeftBar + 1
sizes.xEndOfDrawingArea = sizes.xSize
sizes.yStartOfDrawingArea = 2 + sizes.heightOfTopBar
sizes.yEndOfDrawingArea = sizes.ySize - 1
sizes.widthOfDrawingArea = sizes.xEndOfDrawingArea - sizes.xStartOfDrawingArea + 1
sizes.heightOfDrawingArea = sizes.yEndOfDrawingArea - sizes.yStartOfDrawingArea + 1
sizes.heightOfLeftBar = sizes.ySize - 1

--Для изображения
local function reCalculateImageSizes()
	sizes.widthOfImage = masterPixels.width
	sizes.heightOfImage = masterPixels.height
	sizes.sizeOfPixelData = 4
	sizes.xStartOfImage = 9
	sizes.yStartOfImage = 6
	sizes.xEndOfImage = sizes.xStartOfImage + sizes.widthOfImage - 1
	sizes.yEndOfImage = sizes.yStartOfImage + sizes.heightOfImage - 1
end
reCalculateImageSizes()

--Инструменты
sizes.heightOfInstrument = 3
sizes.yStartOfInstruments = 2 + sizes.heightOfTopBar
local instruments = {
	-- {"⮜", "Move"},
	-- {"✄", "Crop"},
	{"✎", "Brush"},
	{"❎", "Eraser"},
	{"⃟", "Fill"},
	{"Ⓣ", "Text"},
}
local currentInstrument = 1
local currentBackground = 0x6649ff
local currentForeground = 0x3ff80
local currentAlpha = 0x00
local currentSymbol = " "
local currentBrushSize = 1
local savePath

--Верхний тулбар
local topToolbar = {{"PS", ecs.colors.blue}, {"Файл"}, {"Изображение"}, {"Инструменты"}, {"О программе"}}

------------------------------------------------ Функции отрисовки --------------------------------------------------------------

--Объекты для тача
local obj = {}
local function newObj(class, name, ...)
	obj[class] = obj[class] or {}
	obj[class][name] = {...}
end

local function drawTransparentPixel(xPos, yPos, i, j)
	if j % 2 == 0 then
		if i % 2 == 0 then
			colors.transparencyVariable = colors.transparencyWhite
		else
			colors.transparencyVariable = colors.transparencyGray
		end
	else
		if i % 2 == 0 then
			colors.transparencyVariable = colors.transparencyGray
		else
			colors.transparencyVariable = colors.transparencyWhite
		end
	end
	gpu.setBackground(colors.transparencyVariable)
	gpu.set(xPos, yPos, " ")
end

local function drawBackground()
	ecs.square(sizes.xStartOfDrawingArea, sizes.yStartOfDrawingArea, sizes.widthOfDrawingArea, sizes.heightOfDrawingArea, colors.drawingArea)
end

local function drawInstruments()
	local yPos = sizes.yStartOfInstruments
	for i = 1, #instruments do
		if currentInstrument == i then
			ecs.square(1, yPos, sizes.widthOfLeftBar, sizes.heightOfInstrument, colors.toolbarButton)
		else
			ecs.square(1, yPos, sizes.widthOfLeftBar, sizes.heightOfInstrument, colors.toolbar)
		end
		ecs.colorText(3, yPos + 1, colors.toolbarButtonText, instruments[i][1])

		newObj("Instruments", i, 1, yPos, sizes.widthOfLeftBar, yPos + sizes.heightOfInstrument - 1)

		yPos = yPos + sizes.heightOfInstrument
	end
end

local function drawColors()
	local xPos, yPos = 2, sizes.ySize - 4
	ecs.square(xPos, yPos, 3, 2, currentBackground)
	ecs.square(xPos + 3, yPos + 1, 1, 2, currentForeground)
	ecs.square(xPos + 1, yPos + 2, 2, 1, currentForeground)
	ecs.colorTextWithBack(xPos + 1, yPos + 3, 0xaaaaaa, colors.toolbar, "←→")

	newObj("Colors", 1, xPos, yPos, xPos + 2, yPos + 1)
	newObj("Colors", 2, xPos + 3, yPos + 1, xPos + 3, yPos + 2)
	newObj("Colors", 3, xPos + 1, yPos + 2, xPos + 3, yPos + 2)
	newObj("Colors", 4, xPos + 1, yPos + 3, xPos + 2, yPos + 3)
end

local function drawLeftBar()
	ecs.square(1, 2, sizes.widthOfLeftBar, sizes.heightOfLeftBar, colors.toolbar)
	drawInstruments()
	drawColors()
end

local function drawTopMenu()
	ecs.square(1, 1, sizes.xSize, 1, colors.topMenu)
	local xPos = 3

	for i = 1, #topToolbar do
		ecs.colorText(xPos, 1, topToolbar[i][2] or colors.topMenuText, topToolbar[i][1])

		if i > 1 then
			newObj("TopMenu", topToolbar[i][1], xPos, 1, xPos + unicode.len(topToolbar[i][1]) - 1, 1)
		end

		xPos = xPos + unicode.len(topToolbar[i][1]) + 2
	end
end

local function drawTopBar()

	local topBarInputs = { {"Размер кисти", currentBrushSize}, {"Прозрачность", math.floor(currentAlpha)}}

	ecs.square(1, 2, sizes.xSize, sizes.heightOfTopBar, colors.toolbar)
	local xPos, yPos = 3, 3
	local limit = 8

	--ecs.error("сукак")

	for i = 1, #topBarInputs do
		ecs.colorTextWithBack(xPos, yPos, 0xeeeeee, colors.toolbar, topBarInputs[i][1])
		
		xPos = xPos + unicode.len(topBarInputs[i][1]) + 1
		ecs.inputText(xPos, yPos, limit, tostring(topBarInputs[i][2]), 0xffffff, 0x262626, true)

		newObj("TopBarInputs", i, xPos, yPos, xPos + limit - 1, yPos, limit)

		if i == 2 then xPos = xPos + 3 end

		xPos = xPos + limit + 2
	end

end

local function createEmptyMasterPixels()
	--Очищаем мастерпиксельс и задаем ширину с высотой
	masterPixels = {}
	masterPixels.width = sizes.widthOfImage
	masterPixels.height = sizes.heightOfImage
	--Создаем пустой мастерпиксельс
	for j = 1, sizes.heightOfImage * sizes.widthOfImage do
		table.insert(masterPixels, 0x000000)
		table.insert(masterPixels, 0x000000)
		table.insert(masterPixels, 0xFF)
		table.insert(masterPixels, " ")
	end
end

--Формула конвертации итератора массива в абсолютные координаты пикселя изображения
local function convertIteratorToCoords(iterator)
	--Приводим итератор к корректному виду (1 = 1, 5 = 2, 9 = 3, 13 = 4, 17 = 5, ...)
	iterator = (iterator + sizes.sizeOfPixelData - 1) / sizes.sizeOfPixelData
	--Получаем остаток от деления итератора на ширину изображения
	local ostatok = iterator % sizes.widthOfImage
	--Если остаток равен 0, то х равен ширине изображения, а если нет, то х равен остатку
	local x = (ostatok == 0) and sizes.widthOfImage or ostatok
	--А теперь как два пальца получаем координату по Y
	local y = math.ceil(iterator / sizes.widthOfImage)
	--Очищаем остаток из оперативки
	ostatok = nil
	--Возвращаем координаты
	return x, y
end

--Формула конвертации абсолютных координат пикселя изображения в итератор для массива
local function convertCoordsToIterator(x, y)
	--Конвертируем координаты в итератор
	return (sizes.widthOfImage * (y - 1) + x) * sizes.sizeOfPixelData - sizes.sizeOfPixelData + 1
end

local function console(text)
	ecs.square(sizes.xStartOfDrawingArea, sizes.ySize, sizes.widthOfDrawingArea, 1, colors.console)
	local _, total, used = ecs.getInfoAboutRAM()
	ecs.colorText(sizes.xEndOfDrawingArea - 15, sizes.ySize, colors.consoleText, used.."/"..total.." KB RAM")
	gpu.set(sizes.xStartOfDrawingArea + 1, sizes.ySize, text)
	_, total, used = nil, nil, nil
end

local function drawPixel(x, y, i, j, iterator)
	--Получаем данные о пикселе
	local background, foreground, alpha, symbol = masterPixels[iterator], masterPixels[iterator + 1], masterPixels[iterator + 2], masterPixels[iterator + 3]
	--Если пиксель не прозрачный
	if alpha == 0x00 then
		gpu.setBackground(background)
		gpu.setForeground(foreground)
		gpu.set(x, y, symbol)
	--Если пиксель прозрачнее непрозрачного
	elseif alpha > 0x00 then
		--Рисуем прозрачный пиксель
		drawTransparentPixel(x, y, i, j)
		--Ебать я красавчик! Даже без гпу.гет() сделал!
		gpu.setBackground(colorlib.alphaBlend(colors.transparencyVariable, background, alpha))
		gpu.setForeground(foreground)
		gpu.set(x, y, symbol)
	end
	background, foreground, alpha, symbol = nil, nil, nil, nil
end

local function drawImage()
	--Стартовые нужности
	local xPixel, yPixel = 1, 1
	local xPos, yPos = sizes.xStartOfImage, sizes.yStartOfImage
	--Перебираем массив мастерпиксельса
	for i = 1, #masterPixels, 4 do
		--Если пиксель входит в разрешенную зону рисования
		if xPos >= sizes.xStartOfDrawingArea and xPos <= sizes.xEndOfDrawingArea and yPos >= sizes.yStartOfDrawingArea and yPos <= sizes.yEndOfDrawingArea then
			--Рисуем пиксель
			drawPixel(xPos, yPos, xPixel, yPixel, i)
		end
		--Всякие расчеты координат
		xPixel = xPixel + 1
		xPos = xPos + 1
		if xPixel > sizes.widthOfImage then xPixel = 1; xPos = sizes.xStartOfImage; yPixel = yPixel + 1; yPos = yPos + 1 end
	end
end

local function drawBackgroundAndImage()
	drawBackground()
	drawImage()
end

local function drawAll()
	--Очищаем экран
	ecs.prepareToExit()
	--И консольку!
	console("Весь интерфейс перерисован!")
	--Рисуем тулбары
	drawBackground()
	drawLeftBar()
	drawTopBar()
	drawTopMenu()
	--Рисуем картинку
	drawBackgroundAndImage()
end

------------------------------------------------ Функции расчета --------------------------------------------------------------

local function move(direction)
	if direction == "up" then
		sizes.yStartOfImage = sizes.yStartOfImage - 2
	elseif direction == "down" then
		sizes.yStartOfImage = sizes.yStartOfImage + 2
	elseif direction == "left" then
		sizes.xStartOfImage = sizes.xStartOfImage - 2
	elseif direction == "right" then
		sizes.xStartOfImage = sizes.xStartOfImage + 2
	end
	drawBackgroundAndImage()
end

local function setPixel(iterator, background, foreground, alpha, symbol)
	masterPixels[iterator] = background
	masterPixels[iterator + 1] = foreground
	masterPixels[iterator + 2] = alpha
	masterPixels[iterator + 3] = symbol
end

local function swapColors()
	local tempColor = currentForeground
	currentForeground = currentBackground
	currentBackground = tempColor
	tempColor = nil
	drawColors()
	console("Цвета поменяны местами.")
end

local function inputText(x, y, limit)
	local oldPixels = ecs.rememberOldPixels(x,y-1,x+limit-1,y+1)

	local text = ""
	local inputPos = 1

	local function drawThisShit()
		for i=1,inputPos do
			ecs.invertedText(x + i - 1, y + 1, "─")
			ecs.adaptiveText(x + i - 1, y - 1, " ", currentBackground)
		end
		ecs.invertedText(x + inputPos - 1, y + 1, "▲")--"▲","▼"
		ecs.invertedText(x + inputPos - 1, y - 1, "▼")
		ecs.adaptiveText(x, y, ecs.stringLimit("start", text, limit, false), currentBackground)
	end

	drawThisShit()

	while true do
		local e = {event.pull()}
		if e[1] == "key_down" then
			if e[4] == 14 then
				if unicode.len(text) >= 1 then
					text = unicode.sub(text, 1, -2)
					if unicode.len(text) < (limit - 1) then
						inputPos = inputPos - 1
					end
					ecs.drawOldPixels(oldPixels)
					drawThisShit()
				end
			elseif e[4] == 28 then
				break
			else
				local symbol = ecs.convertCodeToSymbol(e[3])
				if symbol ~= nil then
					text = text .. symbol
					if unicode.len(text) < limit then
						inputPos = inputPos + 1
					end
					drawThisShit()
				end
			end
		elseif e[1] == "clipboard" then
			if e[3] then
				text = text .. e[3]
				if unicode.len(text) < limit then
					inputPos = inputPos + unicode.len(e[3])
				end
				drawThisShit()
			end
		end
	end

	ecs.drawOldPixels(oldPixels)
	if text == "" then text = " " end
	return text
end

local function saveTextToPixels(x, y, text)
	local sText = unicode.len(text)
	local iterator
	x = x - 1
	for i = 1, sText do
		if x + i > sizes.widthOfImage then break end
		iterator = convertCoordsToIterator(x + i, y)
		setPixel(iterator, masterPixels[iterator], currentBackground, masterPixels[iterator + 2], unicode.sub(text, i, i))
	end
end

local function flipVertical(massiv)
	local newMassiv = {}
	newMassiv.width, newMassiv.height = massiv.width, massiv.height

	local iterator = #masterPixels
	while iterator >= 1 do
		table.insert(newMassiv, masterPixels[iterator - 3])
		table.insert(newMassiv, masterPixels[iterator - 2])
		table.insert(newMassiv, masterPixels[iterator - 1])
		table.insert(newMassiv, masterPixels[iterator])

		masterPixels[iterator], masterPixels[iterator - 1], masterPixels[iterator - 2], masterPixels[iterator - 3] = nil, nil, nil, nil

		iterator = iterator - 4
	end

	return newMassiv
end

local function flipHorizontal( picture )
	local blockSize = picture.width * 4

	local buffer = nil
	local startBlock = nil
	local endPixel = nil

	for j=1, picture.height, 1 do
		startBlock = picture.width * 4 * (j-1)
		
		for pixel=4, blockSize/2, 4 do
			endPixel = blockSize-(pixel-4)

			--Foreground
			buffer = picture[pixel-3+startBlock]
			picture[pixel-3+startBlock] = picture[endPixel-3+startBlock]
			picture[endPixel-3+startBlock] = buffer

			--Background
			buffer = picture[pixel-2+startBlock]
			picture[pixel-2+startBlock] = picture[endPixel-2+startBlock]
			picture[endPixel-2+startBlock] = buffer

			--Alpha
			buffer = picture[pixel-1+startBlock]
			picture[pixel-1+startBlock] = picture[endPixel-1+startBlock]
			picture[endPixel-1+startBlock] = buffer

			--Char
			buffer = picture[pixel-0+startBlock]
			picture[pixel-0+startBlock] = picture[endPixel-0+startBlock]
			picture[endPixel-0+startBlock] = buffer
		end
	end
end

local function doFlip(horizontal)
	if horizontal then
		flipHorizontal(masterPixels)
	else
		masterPixels = flipVertical(masterPixels)
	end
	drawImage()
end

local function invertColors()
	for i = 1, #masterPixels, 4 do
		masterPixels[i] = 0xFFFFFF - masterPixels[i]
		masterPixels[i + 1] = 0xFFFFFF - masterPixels[i + 1]
	end
	drawImage()
end

local function blackAndWhite()
	for i = 1, #masterPixels, 4 do
		local hh, ss, bb = colorlib.HEXtoHSB(masterPixels[i]); ss = 0
		masterPixels[i] = colorlib.HSBtoHEX(hh, ss, bb)
		
		hh, ss, bb = colorlib.HEXtoHSB(masterPixels[i + 1]); ss = 0
		masterPixels[i + 1] = colorlib.HSBtoHEX(hh, ss, bb)
	end
	drawImage()
end

local function new()
	local data = ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, false, {"EmptyLine"}, {"CenterText", 0x262626, "Новый документ"}, {"EmptyLine"}, {"Input", 0x262626, 0x880000, "Ширина"}, {"Input", 0x262626, 0x880000, "Высота"}, {"EmptyLine"}, {"Button", {0xbbbbbb, 0xffffff, "Ok!"}})

	data[1] = tonumber(data[1]) or 51
	data[2] = tonumber(data[2]) or 19

	sizes.widthOfImage, sizes.heightOfImage = data[1], data[2]
	sizes.xStartOfImage = 9
	sizes.yStartOfImage = 6
	sizes.xEndOfImage = sizes.xStartOfImage + sizes.widthOfImage - 1
	sizes.yEndOfImage = sizes.yStartOfImage + sizes.heightOfImage - 1

	createEmptyMasterPixels()
	drawAll()
end

--Обычная рекурсивная заливка
local function fill(x, y, startColor, fillColor)
	local function doFill(xStart, yStart)
		local iterator = convertCoordsToIterator(xStart, yStart)

		--Завершаем функцию, если цвет в массиве не такой, какой мы заливаем
		if masterPixels[iterator] ~= startColor or masterPixels[iterator] == fillColor then return end

		--Заливаем в память
		masterPixels[iterator] = fillColor
		masterPixels[iterator + 2] = currentAlpha

		doFill(xStart + 1, yStart)
		doFill(xStart - 1, yStart)
		doFill(xStart, yStart + 1)
		doFill(xStart, yStart - 1)

		iterator = nil
	end
	doFill(x, y)
end

--Кисть
local function brush(x, y, background, foreground, alpha, symbol)
	--Смещение влево и вправо относительно указанного центра кисти
	local position = math.floor(currentBrushSize / 2)
	local newIterator
	--Сдвигаем х и у на смещение
	x, y = x - position, y - position
	--Считаем ширину/высоту кисти
	local brushSize = position * 2 + 1
	--Перебираем кисть по ширине и высоте
	for cyka = 1, brushSize do
		for pidor = 1, brushSize do
			--Если этот кусочек входит в границы рисовабельной зоны, то
			if x >= 1 and x <= sizes.widthOfImage and y >= 1 and y <= sizes.heightOfImage then
				
				--Считаем новый итератор для кусочка кисти
				newIterator = convertCoordsToIterator(x, y)

				--Если указанная прозрачность не максимальна
				if alpha < 0xFF then
					--Если пиксель в массиве ни хуя не прозрачный, то оставляем его таким же, разве что цвет меняем на сблендированный
					if masterPixels[newIterator + 2] == 0x00 then
						local gettedBackground = colorlib.alphaBlend(masterPixels[newIterator], background, alpha)
						setPixel(newIterator, gettedBackground, foreground, 0x00, symbol)
					--А если прозрачный
					else
						--Если его прозоачность максимальная
						if masterPixels[newIterator + 2] == 0xFF then
							setPixel(newIterator, background, foreground, alpha, symbol)
						--Если не максимальная
						else
							local newAlpha = masterPixels[newIterator + 2] - (0xFF - alpha)
							if newAlpha < 0x00 then newAlpha = 0x00 end
							setPixel(newIterator, background, foreground, newAlpha, symbol)
						end
					end
				--Если указанная прозрачность максимальна, т.е. равна 0xFF
				else
					setPixel(newIterator, 0x000000, 0x000000, 0xFF, " ")
				end
				--Рисуем пиксель из мастерпиксельса
				drawPixel(x + sizes.xStartOfImage - 1, y + sizes.yStartOfImage - 1, x, y, newIterator)
			end

			x = x + 1
		end
		x = x - brushSize
		y = y + 1
	end
end

------------------------------------------------ Старт программы --------------------------------------------------------------

--Создаем пустой мастерпиксельс
--createEmptyMasterPixels()

--Рисуем весь интерфейс
drawAll()
new()

while true do
	local e = {event.pull()}
	if e[1] == "touch" or e[1] == "drag" then
		--Левый клик
		if e[5] == 0 then
			--Если кликнули на рисовабельную зонку
			if ecs.clickedAtArea(e[3], e[4], sizes.xStartOfImage, sizes.yStartOfImage, sizes.xEndOfImage, sizes.yEndOfImage) then
				
				local x, y = e[3] - sizes.xStartOfImage + 1, e[4] - sizes.yStartOfImage + 1
				local iterator = convertCoordsToIterator(x, y)

				--Кисть
				if currentInstrument == 1 then
					
					--Если нажата клавиша альт
					if keyboard.isKeyDown(56) then
						local _, _, gettedBackground = gpu.get(e[3], e[4])
						currentBackground = gettedBackground
						drawColors()
					
					--Если обычная кисть, просто кисть, вообще всем кистям кисть
					else
					
						brush(x, y, currentBackground, currentForeground, currentAlpha, currentSymbol)

						--Пишем что-то в консоли
						console("Кисть: клик на точку "..e[3].."x"..e[4]..", координаты в изображении: "..x.."x"..y..", индекс массива изображения: "..iterator)
					end
				--Ластик
				elseif currentInstrument == 2 then

					brush(x, y, currentBackground, currentForeground, 0xFF, currentSymbol)

					console("Ластик: клик на точку "..e[3].."x"..e[4]..", координаты в изображении: "..x.."x"..y..", индекс массива изображения: "..iterator)

				--Текст
				elseif currentInstrument == 4 then
					local limit = sizes.widthOfImage - x + 1
					local text = inputText(e[3], e[4], limit)
					saveTextToPixels(x, y, text)
					drawImage()

				--Заливка
				elseif currentInstrument == 3 then

					fill(x, y, masterPixels[iterator], currentBackground)

					drawImage()

				end

				iterator, x, y = nil, nil, nil

			end

			--Цвета
			for key in pairs(obj["Colors"]) do
				if ecs.clickedAtArea(e[3], e[4], obj["Colors"][key][1], obj["Colors"][key][2], obj["Colors"][key][3], obj["Colors"][key][4]) then
					if key == 1 then
						currentBackground = palette.draw("auto", "auto", currentBackground) or currentBackground
						drawColors()
					elseif key == 2 or key == 3 then
						currentForeground = palette.draw("auto", "auto", currentForeground) or currentForeground
						drawColors()
					elseif key == 4 then
						ecs.colorTextWithBack(obj["Colors"][key][1], obj["Colors"][key][2], 0xFF0000, colors.toolbar, "←→")
						os.sleep(0.2)
						swapColors()
					end
					break
				end	
			end

			--Инструменты
			for key in pairs(obj["Instruments"]) do
				if ecs.clickedAtArea(e[3], e[4], obj["Instruments"][key][1], obj["Instruments"][key][2], obj["Instruments"][key][3], obj["Instruments"][key][4]) then
					currentInstrument = key
					drawInstruments()
					break
				end
			end

			--Верхний меню-бар
			for key in pairs(obj["TopMenu"]) do
				if ecs.clickedAtArea(e[3], e[4], obj["TopMenu"][key][1], obj["TopMenu"][key][2], obj["TopMenu"][key][3], obj["TopMenu"][key][4]) then
					ecs.square(obj["TopMenu"][key][1] - 1, obj["TopMenu"][key][2], unicode.len(key) + 2, 1, ecs.colors.blue)
					ecs.colorText(obj["TopMenu"][key][1], obj["TopMenu"][key][2], 0xffffff, key)
					local action
					
					if key == "Файл" then
						action = context.menu(obj["TopMenu"][key][1] - 1, obj["TopMenu"][key][2] + 1, {"Новый"}, {"Открыть"}, "-", {"Сохранить", (savePath == nil)}, {"Сохранить как"}, "-", {"Выход"})
					elseif key == "Изображение" then
						action = context.menu(obj["TopMenu"][key][1] - 1, obj["TopMenu"][key][2] + 1, {"Отразить по горизонтали"}, {"Отразить по вертикали"}, "-", {"Инвертировать цвета"}, {"Черно-белый фильтр"})
					elseif key == "Инструменты" then
						action = context.menu(obj["TopMenu"][key][1] - 1, obj["TopMenu"][key][2] + 1, {"Кисть"}, {"Ластик"}, {"Заливка"}, {"Текст"})
					elseif key == "О программе" then
						ecs.universalWindow("auto", "auto", 36, 0xeeeeee, true, {"EmptyLine"}, {"CenterText", 0x880000, "Photoshop v3.0 (public beta)"}, {"EmptyLine"}, {"CenterText", 0x262626, "Авторы:"}, {"CenterText", 0x555555, "Тимофеев Игорь"}, {"CenterText", 0x656565, "vk.com/id7799889"}, {"CenterText", 0x656565, "Трифонов Глеб"}, {"CenterText", 0x656565, "vk.com/id88323331"}, {"EmptyLine"}, {"CenterText", 0x262626, "Тестеры:"}, {"CenterText", 0x656565, "Шестаков Тимофей"}, {"CenterText", 0x656565, "vk.com/id113499693"}, {"CenterText", 0x656565, "Вечтомов Роман"}, {"CenterText", 0x656565, "vk.com/id83715030"}, {"CenterText", 0x656565, "Омелаенко Максим"},  {"CenterText", 0x656565, "vk.com/paladincvm"}, {"EmptyLine"},{"Button", {0xbbbbbb, 0xffffff, "OK"}})
					end

					if action == "Выход" then
						ecs.prepareToExit()
						return
					elseif action == "Отразить по горизонтали" then
						doFlip(true)
					elseif action == "Отразить по вертикали" then
						doFlip(false)
					elseif action == "Инвертировать цвета" then
						invertColors()
					elseif action == "Черно-белый фильтр" then
						blackAndWhite()
					elseif action == "Ластик" then
						currentInstrument = 2
						drawInstruments()
					elseif action == "Кисть" then
						currentInstrument = 1
						drawInstruments()
					elseif action == "Текст" then
						currentInstrument = 4
						drawInstruments()
					elseif action == "Заливка" then
						currentInstrument = 3
						drawInstruments()
					elseif action == "Новый" then
						new()

					elseif action == "Сохранить как" then
						local data = ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x262626, "Сохранить как"}, {"EmptyLine"}, {"Input", 0x262626, 0x880000, "Путь"}, {"Selector", 0x262626, 0x880000, ".PIC", ".RAWPIC"}, {"EmptyLine"}, {"Button", {0xbbbbbb, 0xffffff, "OK"}})
						data[1] = data[1] or "Untitled"
						data[2] = unicode.lower(data[2] or "PIC")
						local fileName = data[1]..data[2]
						image.save(fileName, masterPixels)
						savePath = fileName

					elseif action == "Сохранить" then
						image.save(savePath, masterPixels)

					elseif action == "Открыть" then
						local data = ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x262626, "Открыть"}, {"EmptyLine"}, {"Input", 0x262626, 0x880000, "Путь"}, {"EmptyLine"}, {"Button", {0xbbbbbb, 0xffffff, "OK"}})
						local fileFormat = ecs.getFileFormat(data[1])
					
						if not data[1] then
							ecs.error("Некорректное имя файла!")
						elseif not fs.exists(data[1]) then
							ecs.error("Файл\""..data[1].."\" не существует!")
						elseif fileFormat ~= ".pic" and fileFormat ~= ".rawpic" then 
							ecs.error("Формат файла \""..fileFormat.."\" не поддерживается!")
						else
							masterPixels = image.load(data[1])
							reCalculateImageSizes()
							drawImage()
						end
					end

					drawTopMenu()
					break
				end
			end

			--Топбар
			for key in pairs(obj["TopBarInputs"]) do
				if ecs.clickedAtArea(e[3], e[4], obj["TopBarInputs"][key][1], obj["TopBarInputs"][key][2], obj["TopBarInputs"][key][3], obj["TopBarInputs"][key][4]) then
					local input = ecs.inputText(obj["TopBarInputs"][key][1], obj["TopBarInputs"][key][2], obj["TopBarInputs"][key][5], "", 0xffffff, 0x262626)
					input = tonumber(input)

					if input then
						if key == 1 then
							if input > 0 and input < 10 then currentBrushSize = input end
						elseif key == 2 then
							if input > 0 and input <= 255 then currentAlpha = input end
						end
					end

					drawTopBar()

					break
				end
			end
		else
			--Если кликнули на рисовабельную зонку
			if ecs.clickedAtArea(e[3], e[4], sizes.xStartOfImage, sizes.yStartOfImage, sizes.xEndOfImage, sizes.yEndOfImage) then
				
				local x, y, width, height = e[3], e[4], 30, 12

				--А это чтоб за края экрана не лезло
				if y + height >= sizes.ySize then y = sizes.ySize - height end
				if x + width + 1 >= sizes.xSize then x = sizes.xSize - width - 1 end

				currentBrushSize, currentAlpha = table.unpack(ecs.universalWindow(x, y, width, 0xeeeeee, true, {"EmptyLine"}, {"CenterText", 0x880000, "Параметры кисти"}, {"Slider", 0x262626, 0x880000, 1, 10, currentBrushSize, "Размер: ", " px"}, {"Slider", 0x262626, 0x880000, 0, 255, currentAlpha, "Прозрачность: ", ""}, {"EmptyLine"}, {"Button", {0xbbbbbb, 0xffffff, "OK"}}))
				drawTopBar()
			end
		end

	elseif e[1] == "key_down" then
		--Стрелки
		if e[4] == 200 then
			move("up")
		elseif e[4] == 208 then
			move("down")
		elseif e[4] == 203 then
			move("left")
		elseif e[4] == 205 then
			move("right")
		--Пробел
		elseif e[4] == 57 then
			drawAll()
		--X
		elseif e[4] == 45 then
			swapColors()
		--B
		elseif e[4] == 48 then
			currentInstrument = 1
			drawInstruments()
		--E
		elseif e[4] == 18 then
			currentInstrument = 2
			drawInstruments()
		--T
		elseif e[4] == 20 then
			currentInstrument = 4
			drawInstruments()

		--G
		elseif e[4] == 34 then
			currentInstrument = 3
			drawInstruments()
		--D
		elseif e[4] == 32 then
			currentBackground = 0x000000
			currentForeground = 0xFFFFFF
			currentAlpha = 0x00
			drawColors()
		end
	elseif e[1] == "scroll" then

	end
end

------------------------------------------------ Выход из программы --------------------------------------------------------------




