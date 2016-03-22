
------------------------------------------------ Копирайт --------------------------------------------------------------

local copyright = [[
	
	Photoshop v4.0 (buffered)

	Автор: IT
		Контакты: https://vk.com/id7799889
	Соавтор: Pornogion
		Контакты: https://vk.com/id88323331
	
]]

------------------------------------------------ Библиотеки --------------------------------------------------------------

local libraries = {
	ecs = "ECSAPI",
	fs = "filesystem",
	unicode = "unicode",
	context = "context",
	image = "image",
	component = "component",
	keyboard = "keyboard",
	buffer = "doubleBuffering",
	colorlib = "colorlib",
	palette = "palette",
	event = "event",
}

local components = {
	gpu = "gpu",
}

for library in pairs(libraries) do if not _G[library] then _G[library] = require(libraries[library]) end end
for comp in pairs(components) do if not _G[comp] then _G[comp] = _G.component[components[comp]] end end
libraries, components = nil, nil

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
sizes.yEndOfDrawingArea = sizes.ySize
sizes.widthOfDrawingArea = sizes.xEndOfDrawingArea - sizes.xStartOfDrawingArea + 1
sizes.heightOfDrawingArea = sizes.yEndOfDrawingArea - sizes.yStartOfDrawingArea + 1
sizes.heightOfLeftBar = sizes.ySize - 1
sizes.sizeOfPixelData = 4
--Для изображения
local function reCalculateImageSizes(x, y)
	sizes.xStartOfImage = x or 9
	sizes.yStartOfImage = y or 6
	sizes.xEndOfImage = sizes.xStartOfImage + masterPixels.width - 1
	sizes.yEndOfImage = sizes.yStartOfImage + masterPixels.height - 1
end
reCalculateImageSizes()

--Инструменты
sizes.heightOfInstrument = 3
sizes.yStartOfInstruments = 2 + sizes.heightOfTopBar
local instruments = {
	-- {"⮜", "Move"},
	-- {"✄", "Crop"},
	{"B", "Brush"},
	{"E", "Eraser"},
	{"F", "Fill"},
	{"T", "Text"},
}
local currentInstrument = 1
local currentBackground = 0x6649ff
local currentForeground = 0x3ff80
local currentAlpha = 0x00
local currentSymbol = " "
local currentBrushSize = 1
local savePath

--Верхний тулбар
local topToolbar = {{"PS", ecs.colors.blue}, {"Файл"}, {"Изображение"}, {"Редактировать"}, {"О программе"}}

------------------------------------------------ Функции отрисовки --------------------------------------------------------------

--Объекты для тача
local obj = {}
local function newObj(class, name, ...)
	obj[class] = obj[class] or {}
	obj[class][name] = {...}
end

local function drawTransparentZone(x, y)
	y = y - 1

	local stro4ka1 = ""
	local stro4ka2 = ""
	if masterPixels.width % 2 == 0 then
		stro4ka1 = string.rep("█ ", masterPixels.width / 2)
		stro4ka2 = stro4ka1
	else
		stro4ka1 = string.rep("█ ", masterPixels.width / 2)
		stro4ka2 = stro4ka1 .. "█"
	end

	for i = 1, masterPixels.height do
		if i % 2 == 0 then
			buffer.square(x, y + i, masterPixels.width, 1, colors.transparencyWhite, colors.transparencyGray, " ")
			buffer.text(x + 1, y + i, colors.transparencyGray, stro4ka1)
		else
			buffer.square(x, y + i, masterPixels.width, 1, colors.transparencyWhite, colors.transparencyGray)
			buffer.text(x, y + i, colors.transparencyGray, stro4ka2)
		end
	end
end

local function drawBackground()
	buffer.square(sizes.xStartOfDrawingArea, sizes.yStartOfDrawingArea, sizes.widthOfDrawingArea, sizes.heightOfDrawingArea, colors.drawingArea, 0xFFFFFF, " ")
end

local function drawInstruments()
	local yPos = sizes.yStartOfInstruments
	for i = 1, #instruments do
		if currentInstrument == i then
			buffer.square(1, yPos, sizes.widthOfLeftBar, sizes.heightOfInstrument, colors.toolbarButton, 0xFFFFFF, " ")
		else
			buffer.square(1, yPos, sizes.widthOfLeftBar, sizes.heightOfInstrument, colors.toolbar, 0xFFFFFF, " ")
		end
		buffer.text(3, yPos + 1, colors.toolbarButtonText, instruments[i][1])

		newObj("Instruments", i, 1, yPos, sizes.widthOfLeftBar, yPos + sizes.heightOfInstrument - 1)

		yPos = yPos + sizes.heightOfInstrument
	end
end

local function drawColors()
	local xPos, yPos = 2, sizes.ySize - 4
	buffer.square(xPos, yPos, 3, 2, currentBackground, 0xFFFFFF, " ")
	buffer.square(xPos + 3, yPos + 1, 1, 2, currentForeground, 0xFFFFFF, " ")
	buffer.square(xPos + 1, yPos + 2, 2, 1, currentForeground, 0xFFFFFF, " ")
	buffer.text(xPos + 1, yPos + 3, 0xaaaaaa, "←→")

	newObj("Colors", 1, xPos, yPos, xPos + 2, yPos + 1)
	newObj("Colors", 2, xPos + 3, yPos + 1, xPos + 3, yPos + 2)
	newObj("Colors", 3, xPos + 1, yPos + 2, xPos + 3, yPos + 2)
	newObj("Colors", 4, xPos + 1, yPos + 3, xPos + 2, yPos + 3)
end

local function drawLeftBar()
	buffer.square(1, 2, sizes.widthOfLeftBar, sizes.heightOfLeftBar, colors.toolbar, 0xFFFFFF, " ")
	drawInstruments()
	drawColors()
end

local function drawTopMenu()
	buffer.square(1, 1, sizes.xSize, 1, colors.topMenu, 0xFFFFFF, " ")
	local xPos = 3

	for i = 1, #topToolbar do
		buffer.text(xPos, 1, topToolbar[i][2] or colors.topMenuText, topToolbar[i][1])
		if i > 1 then
			newObj("TopMenu", topToolbar[i][1], xPos, 1, xPos + unicode.len(topToolbar[i][1]) - 1, 1)
		end
		xPos = xPos + unicode.len(topToolbar[i][1]) + 2
	end
end

local function drawTopBar()
	local topBarInputs = { {"Размер кисти", currentBrushSize}, {"Прозрачность", math.floor(currentAlpha)}}

	buffer.square(1, 2, sizes.xSize, sizes.heightOfTopBar, colors.toolbar, 0xFFFFFF, " ")
	local xPos, yPos = 3, 3
	local limit = 8

	for i = 1, #topBarInputs do
		buffer.text(xPos, yPos, 0xeeeeee, topBarInputs[i][1])
		
		xPos = xPos + unicode.len(topBarInputs[i][1]) + 1
		ecs.inputText(xPos, yPos, limit, tostring(topBarInputs[i][2]), 0xffffff, 0x262626, true)

		newObj("TopBarInputs", i, xPos, yPos, xPos + limit - 1, yPos, limit)

		if i == 2 then xPos = xPos + 3 end

		xPos = xPos + limit + 2
	end

end

local function createEmptyMasterPixels()
	--Создаем пустой мастерпиксельс
	for j = 1, masterPixels.height * masterPixels.width do
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
	local ostatok = iterator % masterPixels.width
	--Если остаток равен 0, то х равен ширине изображения, а если нет, то х равен остатку
	local x = (ostatok == 0) and masterPixels.width or ostatok
	--А теперь как два пальца получаем координату по Y
	local y = math.ceil(iterator / masterPixels.width)
	--Очищаем остаток из оперативки
	ostatok = nil
	--Возвращаем координаты
	return x, y
end

--Формула конвертации абсолютных координат пикселя изображения в итератор для массива
local function convertCoordsToIterator(x, y)
	--Конвертируем координаты в итератор
	return (masterPixels.width * (y - 1) + x) * sizes.sizeOfPixelData - sizes.sizeOfPixelData + 1
end

local function console(text)
	buffer.square(sizes.xStartOfDrawingArea, sizes.ySize, sizes.widthOfDrawingArea, 1, colors.console, 0xFFFFFF, " ")
	local _, total, used = ecs.getInfoAboutRAM()
	buffer.text(sizes.xEndOfDrawingArea - 15, sizes.ySize, colors.consoleText, used.."/"..total.." KB RAM")
	buffer.text(sizes.xStartOfDrawingArea + 1, sizes.ySize, colors.consoleText, text)
	_, total, used = nil, nil, nil
end

local function drawPixel(x, y, xPixel, yPixel, iterator)
	--Получаем данные о пикселе
	local background, foreground, alpha, symbol = masterPixels[iterator], masterPixels[iterator + 1], masterPixels[iterator + 2], masterPixels[iterator + 3]
	--Если пиксель не прозрачный
	if alpha == 0x00 then
		buffer.set(x, y, background, foreground, symbol)
	--Если пиксель прозрачнее непрозрачного
	elseif alpha > 0x00 then
		local blendColor
		if xPixel % 2 == 0 then
			if yPixel % 2 == 0 then
				blendColor = colors.transparencyGray
			else
				blendColor = colors.transparencyWhite
			end
		else
			if yPixel % 2 == 0 then
				blendColor = colors.transparencyWhite
			else
				blendColor = colors.transparencyGray
			end
		end

		buffer.set(x, y, colorlib.alphaBlend(blendColor, background, alpha), foreground, symbol)
	end
	background, foreground, alpha, symbol = nil, nil, nil, nil
end

local function drawImage()
	--Стартовые нужности
	local xPixel, yPixel = 1, 1
	local xPos, yPos = sizes.xStartOfImage, sizes.yStartOfImage

	buffer.setDrawLimit(sizes.xStartOfDrawingArea, sizes.yStartOfDrawingArea, sizes.widthOfDrawingArea, sizes.heightOfDrawingArea)

	drawTransparentZone(xPos, yPos)

	--Перебираем массив мастерпиксельса
	for i = 1, #masterPixels, 4 do
		--Рисуем пиксель
		if masterPixels[i + 2] ~= 0xFF or masterPixels[i + 3] ~= " " then drawPixel(xPos, yPos, xPixel, yPixel, i) end
		--Всякие расчеты координат
		xPixel = xPixel + 1
		xPos = xPos + 1
		if xPixel > masterPixels.width then xPixel = 1; xPos = sizes.xStartOfImage; yPixel = yPixel + 1; yPos = yPos + 1 end
	end

	buffer.resetDrawLimit()
end

local function drawBackgroundAndImage()
	drawBackground()
	drawImage()
end

local function drawAll()
	drawBackground()
	drawLeftBar()
	drawTopBar()
	drawTopMenu()
	drawBackgroundAndImage()

	buffer.draw()
end

------------------------------------------------ Функции расчета --------------------------------------------------------------

local function move(direction)
	local howMuchUpDown = 2
	local howMuchLeftRight = 4
	if direction == "up" then
		reCalculateImageSizes(sizes.xStartOfImage, sizes.yStartOfImage - howMuchUpDown)
	elseif direction == "down" then
		reCalculateImageSizes(sizes.xStartOfImage, sizes.yStartOfImage + howMuchUpDown)
	elseif direction == "left" then
		reCalculateImageSizes(sizes.xStartOfImage - howMuchLeftRight, sizes.yStartOfImage)
	elseif direction == "right" then
		reCalculateImageSizes(sizes.xStartOfImage + howMuchLeftRight, sizes.yStartOfImage)
	end
	drawBackgroundAndImage()
	buffer.debugWait = true
	buffer.draw()
	buffer.debugWait = false
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
		if x + i > masterPixels.width then break end
		iterator = convertCoordsToIterator(x + i, y)
		setPixel(iterator, masterPixels[iterator], currentBackground, masterPixels[iterator + 2], unicode.sub(text, i, i))
	end
end

local function tryToFitImageOnCenterOfScreen()
	reCalculateImageSizes()

	local x, y = sizes.xStartOfImage, sizes.yStartOfImage
	if masterPixels.width < sizes.widthOfDrawingArea then
		x = math.floor(sizes.xStartOfDrawingArea + sizes.widthOfDrawingArea / 2 - masterPixels.width / 2) - 1
	end

	if masterPixels.height < sizes.heightOfDrawingArea then
		y = math.floor(sizes.yStartOfDrawingArea + sizes.heightOfDrawingArea / 2 - masterPixels.height / 2)
	end

	reCalculateImageSizes(x, y)
end

local function new()
	local data = ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x262626, "Новый документ"}, {"EmptyLine"}, {"Input", 0x262626, 0x880000, "Ширина"}, {"Input", 0x262626, 0x880000, "Высота"}, {"EmptyLine"}, {"Button", {0xbbbbbb, 0xffffff, "OK"}})

	data[1] = tonumber(data[1]) or 51
	data[2] = tonumber(data[2]) or 19

	masterPixels = {}
	masterPixels.width, masterPixels.height = data[1], data[2]
	createEmptyMasterPixels()
	tryToFitImageOnCenterOfScreen()
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
			if x >= 1 and x <= masterPixels.width and y >= 1 and y <= masterPixels.height then
				
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

local function cropOrExpand(text)
	local data = ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true,
		{"EmptyLine"},
		{"CenterText", 0x262626, text},
		{"EmptyLine"},
		{"Input", 0x262626, 0x880000, "Количество пикселей"},
		{"Selector", 0x262626, 0x880000, "Снизу", "Сверху", "Слева", "Справа"},
		{"EmptyLine"},
		{"Button", {0xaaaaaa, 0xffffff, "OK"}, {0x888888, 0xffffff, "Отмена"}}
	)

	if data[3] == "OK" then
		local countOfPixels = tonumber(data[1])
		if countOfPixels then
			local direction = ""
			if data[2] == "Снизу" then
				direction = "fromBottom"
			elseif data[2] == "Сверху" then
				direction = "fromTop"
			elseif data[2] == "Слева" then
				direction = "fromLeft"
			else
				direction = "fromRight"
			end

			return direction, countOfPixels
		else
			ecs.error("Введено некорректное количество пикселей")
		end 
	end
end

local function crop()
	local direction, countOfPixels = cropOrExpand("Обрезать")
	if direction then
		masterPixels = image.crop(masterPixels, direction, countOfPixels)
		drawAll()
	end
end

local function expand()
	local direction, countOfPixels = cropOrExpand("Обрезать")
	if direction then
		masterPixels = image.expand(masterPixels, direction, countOfPixels)
		drawAll()
	end
end

local function loadImageFromFile(path)
	if fs.exists(path) then
		masterPixels = image.load(path)
		savePath = path
		tryToFitImageOnCenterOfScreen()
	else
		ecs.error("Файл \"" .. path .. "\" не существует")
	end
end

------------------------------------------------ Старт программы --------------------------------------------------------------

local args = {...}

--Рисуем весь интерфейс
buffer.start()
drawAll()

if args[1] == "o" or args[1] == "open" or args[1] == "-o" or args[1] == "load" then
	loadImageFromFile(args[2])
else
	new()
end

drawAll()

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
						buffer.draw()
					
					--Если обычная кисть, просто кисть, вообще всем кистям кисть
					else
						brush(x, y, currentBackground, currentForeground, currentAlpha, currentSymbol)
						--Пишем что-то в консоли
						console("Кисть: клик на точку "..e[3].."x"..e[4]..", координаты в изображении: "..x.."x"..y..", индекс массива изображения: "..iterator)
						buffer.draw()
					end
				--Ластик
				elseif currentInstrument == 2 then
					brush(x, y, currentBackground, currentForeground, 0xFF, currentSymbol)
					console("Ластик: клик на точку "..e[3].."x"..e[4]..", координаты в изображении: "..x.."x"..y..", индекс массива изображения: "..iterator)
					buffer.draw()
				--Текст
				elseif currentInstrument == 4 then
					local limit = masterPixels.width - x + 1
					local text = inputText(e[3], e[4], limit)
					saveTextToPixels(x, y, text)
					drawImage()
					buffer.draw()

				--Заливка
				elseif currentInstrument == 3 then

					fill(x, y, masterPixels[iterator], currentBackground)
					drawImage()
					buffer.draw()

				end

				iterator, x, y = nil, nil, nil

			end

			--Цвета
			for key in pairs(obj["Colors"]) do
				if ecs.clickedAtArea(e[3], e[4], obj["Colors"][key][1], obj["Colors"][key][2], obj["Colors"][key][3], obj["Colors"][key][4]) then
					if key == 1 then
						currentBackground = palette.draw("auto", "auto", currentBackground) or currentBackground
						drawColors()
						buffer.draw()
					elseif key == 2 or key == 3 then
						currentForeground = palette.draw("auto", "auto", currentForeground) or currentForeground
						drawColors()
						buffer.draw()
					elseif key == 4 then
						buffer.text(obj["Colors"][key][1], obj["Colors"][key][2], 0xFF0000, "←→")
						os.sleep(0.2)
						swapColors()
						buffer.draw()
					end
					break
				end	
			end

			--Инструменты
			for key in pairs(obj["Instruments"]) do
				if ecs.clickedAtArea(e[3], e[4], obj["Instruments"][key][1], obj["Instruments"][key][2], obj["Instruments"][key][3], obj["Instruments"][key][4]) then
					currentInstrument = key
					drawInstruments()
					buffer.draw()
					break
				end
			end

			--Верхний меню-бар
			for key in pairs(obj["TopMenu"]) do
				if ecs.clickedAtArea(e[3], e[4], obj["TopMenu"][key][1], obj["TopMenu"][key][2], obj["TopMenu"][key][3], obj["TopMenu"][key][4]) then
					buffer.square(obj["TopMenu"][key][1] - 1, obj["TopMenu"][key][2], unicode.len(key) + 2, 1, ecs.colors.blue, 0xFFFFFF, " ")
					buffer.text(obj["TopMenu"][key][1], obj["TopMenu"][key][2], 0xffffff, key)
					buffer.draw()

					local action
					
					if key == "Файл" then
						action = context.menu(obj["TopMenu"][key][1] - 1, obj["TopMenu"][key][2] + 1, {"Новый"}, {"Открыть"}, "-", {"Сохранить", (savePath == nil)}, {"Сохранить как"}, "-", {"Выход"})
					elseif key == "Изображение" then
						action = context.menu(obj["TopMenu"][key][1] - 1, obj["TopMenu"][key][2] + 1, {"Обрезать"}, {"Расширить"}, "-", {"Повернуть на 90 градусов"}, {"Повернуть на 180 градусов"}, "-", {"Отразить по горизонтали"}, {"Отразить по вертикали"})
					elseif key == "Редактировать" then
						action = context.menu(obj["TopMenu"][key][1] - 1, obj["TopMenu"][key][2] + 1, {"Цветовой тон/насыщенность"}, {"Цветовой баланс"}, {"Фотофильтр"}, "-", {"Инвертировать цвета"}, {"Черно-белый фильтр"})
					elseif key == "О программе" then
						ecs.universalWindow("auto", "auto", 36, 0xeeeeee, true, {"EmptyLine"}, {"CenterText", 0x880000, "Photoshop v4.0 (buffered)"}, {"EmptyLine"}, {"CenterText", 0x262626, "Авторы:"}, {"CenterText", 0x555555, "Тимофеев Игорь"}, {"CenterText", 0x656565, "vk.com/id7799889"}, {"CenterText", 0x656565, "Трифонов Глеб"}, {"CenterText", 0x656565, "vk.com/id88323331"}, {"EmptyLine"}, {"CenterText", 0x262626, "Тестеры:"}, {"CenterText", 0x656565, "Шестаков Тимофей"}, {"CenterText", 0x656565, "vk.com/id113499693"}, {"CenterText", 0x656565, "Вечтомов Роман"}, {"CenterText", 0x656565, "vk.com/id83715030"}, {"CenterText", 0x656565, "Омелаенко Максим"},  {"CenterText", 0x656565, "vk.com/paladincvm"}, {"EmptyLine"},{"Button", {0xbbbbbb, 0xffffff, "OK"}})
					end

					if action == "Выход" then
						ecs.prepareToExit()
						return
					elseif action == "Цветовой тон/насыщенность" then
						local data = ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true,
							{"EmptyLine"},
							{"CenterText", 0x262626, "Цветовой тон/насыщенность"},
							{"EmptyLine"},
							{"Slider", 0x262626, 0x880000, 0, 100, 50, "Тон: ", ""},
							{"Slider", 0x262626, ecs.colors.red, 0, 100, 50, "Насыщенность: ", ""},
							{"Slider", 0x262626, 0x000000, 0, 100, 50, "Яркость: ", ""},
							{"EmptyLine"}, 
							{"Button", {0xaaaaaa, 0xffffff, "OK"}, {0x888888, 0xffffff, "Отмена"}}
						)
						if data[4] == "OK" then
							masterPixels = image.hueSaturationBrightness(masterPixels, data[1] - 50, data[2] - 50, data[3] - 50)
							drawAll()
						end
					elseif action == "Цветовой баланс" then
						local data = ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true,
							{"EmptyLine"},
							{"CenterText", 0x262626, "Цветовой баланс"},
							{"EmptyLine"},
							{"Slider", 0x262626, 0x880000, 0, 100, 50, "R: ", ""},
							{"Slider", 0x262626, ecs.colors.green, 0, 100, 50, "G: ", ""},
							{"Slider", 0x262626, ecs.colors.blue, 0, 100, 50, "B: ", ""},
							{"EmptyLine"}, 
							{"Button", {0xaaaaaa, 0xffffff, "OK"}, {0x888888, 0xffffff, "Отмена"}}
						)
						if data[4] == "OK" then
							masterPixels = image.colorBalance(masterPixels, data[1] - 50, data[2] - 50, data[3] - 50)
							drawAll()
						end
					elseif action == "Фотофильтр" then
						local data = ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true,
							{"EmptyLine"},
							{"CenterText", 0x262626, "Фотофильтр"},
							{"EmptyLine"},
							{"Color", "Цвет фильтра", 0x333333},
							{"Slider", 0x262626, 0x880000, 0, 255, 100, "Прозрачность: ", ""},
							{"EmptyLine"}, 
							{"Button", {0xaaaaaa, 0xffffff, "OK"}, {0x888888, 0xffffff, "Отмена"}}
						)
						if data[3] == "OK" then
							masterPixels = image.photoFilter(masterPixels, data[1], data[2])
							drawAll()
						end
					elseif action == "Обрезать" then
						crop()
					elseif action == "Расширить" then
						expand()
					elseif action == "Отразить по вертикали" then
						masterPixels = image.flipVertical(masterPixels)
						drawAll()
					elseif action == "Отразить по горизонтали" then
						masterPixels = image.flipHorizontal(masterPixels)
						drawAll()
					elseif action == "Инвертировать цвета" then
						masterPixels = image.invert(masterPixels)
						drawAll()
					elseif action == "Черно-белый фильтр" then
						masterPixels = image.blackAndWhite(masterPixels)
						drawAll()
					elseif action == "Повернуть на 90 градусов" then
						masterPixels = image.rotate(masterPixels, 90)
						drawAll()
					elseif action == "Повернуть на 180 градусов" then
						masterPixels = image.rotate(masterPixels, 180)
						drawAll()
					elseif action == "Новый" then
						new()
						drawAll()
					elseif action == "Сохранить как" then
						local data = ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x262626, "Сохранить как"}, {"EmptyLine"}, {"Input", 0x262626, 0x880000, "Путь"}, {"Selector", 0x262626, 0x880000, "OCIF4", "OCIF1", "RAW"}, {"CenterText", 0x262626, "Рекомендуется использовать"}, {"CenterText", 0x262626, "метод кодирования OCIF4"}, {"EmptyLine"}, {"Button", {0xaaaaaa, 0xffffff, "OK"}, {0x888888, 0xffffff, "Отмена"}})
						if data[3] == "OK" then
							data[1] = data[1] or "Untitled"
							data[2] = data[2] or "OCIF4"
							
							if data[2] == "RAW" then
								data[2] = 0
							elseif data[2] == "OCIF1" then
								data[2] = 1
							elseif data[2] == "OCIF4" then
								data[2] = 4
							else
								data[2] = 4
							end

							local filename = data[1] .. ".pic"
							local encodingMethod = data[2]

							image.save(filename, masterPixels, encodingMethod)
							savePath = fileName
						end
					elseif action == "Сохранить" then
						image.save(savePath, masterPixels)

					elseif action == "Открыть" then
						local data = ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x262626, "Открыть"}, {"EmptyLine"}, {"Input", 0x262626, 0x880000, "Путь"}, {"EmptyLine"}, {"Button", {0xaaaaaa, 0xffffff, "OK"}, {0x888888, 0xffffff, "Отмена"}})
						if data[2] == "OK" then
							local fileFormat = ecs.getFileFormat(data[1])
						
							if not data[1] then
								ecs.error("Некорректное имя файла!")
							elseif not fs.exists(data[1]) then
								ecs.error("Файл\""..data[1].."\" не существует!")
							elseif fileFormat ~= ".pic" and fileFormat ~= ".rawpic" and fileFormat ~= ".png" then 
								ecs.error("Формат файла \""..fileFormat.."\" не поддерживается!")
							else
								loadImageFromFile(data[1])
								drawAll()
							end
						end
					end

					drawTopMenu()
					buffer.draw()
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
					buffer.draw()

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
				buffer.draw()
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
			buffer.draw()
		--B
		elseif e[4] == 48 then
			currentInstrument = 1
			drawInstruments()
			buffer.draw()
		--E
		elseif e[4] == 18 then
			currentInstrument = 2
			drawInstruments()
			buffer.draw()
		--T
		elseif e[4] == 20 then
			currentInstrument = 4
			drawInstruments()
			buffer.draw()
		--G
		elseif e[4] == 34 then
			currentInstrument = 3
			drawInstruments()
			buffer.draw()
		--D
		elseif e[4] == 32 then
			currentBackground = 0x000000
			currentForeground = 0xFFFFFF
			currentAlpha = 0x00
			drawColors()
			buffer.draw()
		end
	elseif e[1] == "scroll" then
		if e[5] == 1 then
			move("up")
		else
			move("down")
		end
	end
end

------------------------------------------------ Выход из программы --------------------------------------------------------------

