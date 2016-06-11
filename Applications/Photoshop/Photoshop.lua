
------------------------------------------------ Информешйн, епта --------------------------------------------------------------

local copyright = [[
	
	Photoshop v6.2 для OpenComputers

	Автор: ECS
		Контактый адрес: https://vk.com/id7799889
	Соавтор: Pornogion
		Контактый адрес: https://vk.com/id88323331

	Что нового в версии 6.2:
		- Добавлен суб-инструмент "Многоугольник"
		- Улучшен инструмент "Выделение", теперь можно выделять области с шириной или высотой, равными 1

	Что нового в версии 6.1:
		- Добавлен суб-инструмент "Эллипс"

	Что нового в версии 6.0:
		- Добавлен иструмент "Фигура", включающий в себя линию, прямоугольник и рамку
		- Добавлен фильтр размытия по Гауссу
		- Переработана концепция работы с выделениями

	Что нового в версии 5.1:
		- Цветовая гамма программы изменена на более детальную
		- Добавлена информационная мини-панель к инструменту "выделение"
		- Добавлена информация о размере изображения, отображаемая под самим изображением
		- Ускорен алгоритм рисования кистью и ластиком

	Что нового в версии 5.0:
		- Добавлен инструмент "выделение" и несколько функций для работы с ним
		- Добавлено меню "Горячие клавиши", подсказывающее, как можно удобнее работать с программой

	Что нового в версии 4.0:
		- Программа переведена на библиотеку тройного буфера, скорость работы увеличена в десятки раз
		- Добавлены функции обрезки, расширения, поворота и отражения картинки
		- Добавлены функции тона/насыщенности, цветового баланса и наложения фотофильтра

]]

copyright = nil

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

local selection

for library in pairs(libraries) do if not _G[library] then _G[library] = require(libraries[library]) end end
for comp in pairs(components) do if not _G[comp] then _G[comp] = _G.component[components[comp]] end end
libraries, components = nil, nil

------------------------------------------------ Переменные --------------------------------------------------------------

--Инициализируем библиотеку двойного буфера
buffer.start()

--Получаем аргументы программы
local args = {...}

--Массив главного изображения
local masterPixels = {
	width = 0,
	height = 0,
}

--Базовая цветовая схема программы
local colors = {
	leftToolbar = 0x3c3c3c,
	leftToolbarButton = 0x2d2d2d,
	leftToolbarButtonText = 0xeeeeee,
	topToolbar = 0x4b4b4b,
	drawingArea = 0x1e1e1e,
	console = 0x2d2d2d,
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
sizes.xStartOfDrawingArea = sizes.widthOfLeftBar + 1
sizes.xEndOfDrawingArea = buffer.screen.width
sizes.yStartOfDrawingArea = sizes.heightOfTopBar + 2
sizes.yEndOfDrawingArea = buffer.screen.height - 1
sizes.widthOfDrawingArea = sizes.xEndOfDrawingArea - sizes.xStartOfDrawingArea + 1
sizes.heightOfDrawingArea = sizes.yEndOfDrawingArea - sizes.yStartOfDrawingArea + 1
sizes.heightOfLeftBar = buffer.screen.height - 1
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
local instruments = {
	"M",
	"B",
	"E",
	"F",
	"T",
	"S",
}
sizes.heightOfInstrument = 3
sizes.yStartOfInstruments = sizes.heightOfTopBar + 2
local currentInstrument = 2
local currentBackground = 0x000000
local currentForeground = 0xFFFFFF
local currentAlpha = 0x00
local currentSymbol = " "
local currentBrushSize = 1
local savePath
local currentShape
local currentPolygonCountOfEdges

--Верхний тулбар
local topToolbar = {{"PS", ecs.colors.blue}, {"Файл"}, {"Изображение"}, {"Редактировать"}, {"Горячие клавиши"}, {"О программе"}}

------------------------------------------------ Функции отрисовки --------------------------------------------------------------

--Объекты для тача
local obj = {}
local function newObj(class, name, ...)
	obj[class] = obj[class] or {}
	obj[class][name] = {...}
end

--Функция-сваппер переменных, пока что юзается только в выделении
--А, не, наебал!
--Вон, ниже тоже юзается! Ха, удобненько
local function swap(a, b)
	return b, a
end

--Адекватное округление, ибо в луашке нет такого, ХАХ
local function round(num) 
	if num >= 0 then
		return math.floor(num + 0.5) 
	else
		return math.ceil(num - 0.5)
	end
end

--Отрисовка "прозрачной зоны", этакая сеточка чередующаяся
local function drawTransparentZone(x, y)
	y = y - 1

	local stro4ka1 = ""
	local stro4ka2 = ""
	if masterPixels.width % 2 == 0 then
		stro4ka1 = string.rep("▒ ", masterPixels.width / 2)
		stro4ka2 = stro4ka1
	else
		stro4ka1 = string.rep("▒ ", masterPixels.width / 2)
		stro4ka2 = stro4ka1 .. "▒"
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

--Банальная заливка фона
local function drawBackground()
	buffer.square(sizes.xStartOfDrawingArea, sizes.yStartOfDrawingArea, sizes.widthOfDrawingArea, sizes.heightOfDrawingArea + 1, colors.drawingArea, 0xFFFFFF, " ")
end

--Отрисовка цветов
local function drawColors()
	local xPos, yPos = 2, buffer.screen.height - 4
	buffer.square(xPos, yPos, 3, 2, currentBackground, 0xFFFFFF, " ")
	buffer.square(xPos + 3, yPos + 1, 1, 2, currentForeground, 0xFFFFFF, " ")
	buffer.square(xPos + 1, yPos + 2, 2, 1, currentForeground, 0xFFFFFF, " ")
	buffer.text(xPos + 1, yPos + 3, 0xaaaaaa, "←→")

	newObj("Colors", 1, xPos, yPos, xPos + 2, yPos + 1)
	newObj("Colors", 2, xPos + 3, yPos + 1, xPos + 3, yPos + 2)
	newObj("Colors", 3, xPos + 1, yPos + 2, xPos + 3, yPos + 2)
	newObj("Colors", 4, xPos + 1, yPos + 3, xPos + 2, yPos + 3)
end

--Отрисовка панели инструментов слева
local function drawLeftBar()
	--Рисуем подложечку
	buffer.square(1, 5, sizes.widthOfLeftBar, sizes.heightOfLeftBar, colors.leftToolbar, 0xFFFFFF, " ")
	--Рисуем инструменты
	local yPos = sizes.yStartOfInstruments
	for i = 1, #instruments do
		if currentInstrument == i then
			buffer.square(1, yPos, sizes.widthOfLeftBar, sizes.heightOfInstrument, colors.leftToolbarButton, 0xFFFFFF, " ")
		else
			buffer.square(1, yPos, sizes.widthOfLeftBar, sizes.heightOfInstrument, colors.leftToolbar, 0xFFFFFF, " ")
		end
		buffer.text(3, yPos + 1, colors.leftToolbarButtonText, instruments[i])

		newObj("Instruments", i, 1, yPos, sizes.widthOfLeftBar, yPos + sizes.heightOfInstrument - 1)

		yPos = yPos + sizes.heightOfInstrument
	end
	--И цвета
	drawColors()
end

--Отрисовка верхнего меню
local function drawTopMenu()
	buffer.square(1, 1, buffer.screen.width, 1, colors.topMenu, 0xFFFFFF, " ")
	local xPos = 3

	for i = 1, #topToolbar do
		buffer.text(xPos, 1, topToolbar[i][2] or colors.topMenuText, topToolbar[i][1])
		if i > 1 then
			newObj("TopMenu", topToolbar[i][1], xPos, 1, xPos + unicode.len(topToolbar[i][1]) - 1, 1)
		end
		xPos = xPos + unicode.len(topToolbar[i][1]) + 2
	end
end

--Отрисовка верхней панели инструментов, пока что она не шибко-то полезна
local function drawTopBar()
	local topBarInputs = { {"Размер кисти", currentBrushSize}, {"Прозрачность", math.floor(currentAlpha)}}

	buffer.square(1, 2, buffer.screen.width, sizes.heightOfTopBar, colors.topToolbar, 0xFFFFFF, " ")
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

--Функция, создающая пустой массив изображения на основе указанных ранее длины и ширины
local function createEmptyMasterPixels()
	--Создаем пустой мастерпиксельс
	for j = 1, masterPixels.height * masterPixels.width do
		table.insert(masterPixels, 0x010101)
		table.insert(masterPixels, 0x010101)
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

--Мини-консолька для отладки, сообщающая снизу, че происходит ваще
local function console(text)
	buffer.square(sizes.xStartOfDrawingArea, buffer.screen.height, sizes.widthOfDrawingArea, 1, colors.console, colors.consoleText, " ")
	
	local _, total, used = ecs.getInfoAboutRAM()
	local RAMText = used .. "/" .. total .. " KB RAM"
	buffer.text(sizes.xEndOfDrawingArea - unicode.len(RAMText), buffer.screen.height, colors.consoleText, RAMText)
	
	buffer.text(sizes.xStartOfDrawingArea + 1, buffer.screen.height, colors.consoleText, text)
end

--Функция, берущая указанный пиксель из массива изображения и рисующая его в буфере корректно,
--т.е. с учетом прозрачности и т.п.
local function drawPixel(x, y, xPixel, yPixel, iterator)
	--Получаем тукущие данные о пикселе
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

--Пиздюлинка, показывающая размер текста и тыпы
local function drawTooltip(x, y, ...)
	local texts = {...}
	--Рассчитываем ширину пиздюлинки
	local maxWidth = 0; for i = 1, #texts do maxWidth = math.max(maxWidth, unicode.len(texts[i])) end
	--Рисуем пиздюлинку
	buffer.square(x, y, maxWidth + 2, #texts, 0x000000, 0xFFFFFF, " ", 69); x = x + 1		
	for i = 1, #texts do buffer.text(x, y, 0xFFFFFF, texts[i]); y = y + 1 end
end

--Функция для отрисовки выделения соотв. инструментом
local function drawSelection()
	local color = 0x000000
	local xStart, yStart = sizes.xStartOfImage + selection.x - 1, sizes.yStartOfImage + selection.y - 1
	local xEnd, yEnd = xStart + selection.width - 1, yStart + selection.height - 1
	local currentBackground

	local function nextColor()
		if color == 0x000000 then color = 0xFFFFFF else color = 0x000000 end
	end

	--"━"
	--"┃"

	local function drawSelectionSquare(x1, y1, x2, y2, xStep, yStep, symbol)
		for y = y1, y2, yStep do
			for x = x1, x2, xStep do
				local background = buffer.get(x, y)
				buffer.set(x, y, background, color, symbol)
				nextColor()
			end
		end
	end

	local function drawCornerPoint(x, y, symbol)
		local background = buffer.get(x, y)
		buffer.set(x, y, background, color, symbol)
		nextColor()
	end

	if selection.width > 1 and selection.height > 1 then
		drawCornerPoint(xStart, yStart, "┏")
		drawSelectionSquare(xStart + 1, yStart, xEnd - 1, yStart, 1, 1, "━")
		drawCornerPoint(xEnd, yStart, "┓")
		drawSelectionSquare(xEnd, yStart + 1, xEnd, yEnd - 1, 1, 1, "┃")
		drawCornerPoint(xEnd, yEnd, "┛")
		drawSelectionSquare(xEnd - 1, yEnd, xStart + 1, yEnd, -1, 1, "━")
		drawCornerPoint(xStart, yEnd, "┗")
		drawSelectionSquare(xStart, yEnd - 1, xStart, yStart + 1, 1, -1, "┃")
	else
		if selection.width == 1 then
			drawSelectionSquare(xStart, yStart, xStart, yEnd, 1, 1, "┃")
		elseif selection.height == 1 then 
			drawSelectionSquare(xStart, yStart, xEnd, yStart, 1, 1, "━")
		end
	end

	drawTooltip(xEnd + 2, yEnd - 1, "Ш: " .. selection.width .. " px", "В: " .. selection.height .. " px")
	-- drawTooltip(xEnd + 2, yEnd - 1, "Ш: " .. selection.width .. " px", "В: " .. selection.height .. " px", "S: " .. xStart .. "x" .. yStart, "E: " .. xEnd .. "x" .. yEnd)
end

local function line(x0, y0, x1, y1, background, applyToMasterPixels)
   	local steep = false;
    
    if math.abs(x0 - x1) < math.abs(y0 - y1 ) then
        x0, y0 = swap(x0, y0)
        x1, y1 = swap(x1, y1)
        steep = true;
    end

    if (x0 > x1) then
    	x0, x1 = swap(x0, x1)
    	y0, y1 = swap(y0, y1)
    end

    local dx = x1 - x0;
    local dy = y1 - y0;
    local derror2 = math.abs(dy) * 2
    local error2 = 0;
    local y = y0;
    
    for x = x0, x1, 1 do
        if steep then
        	if applyToMasterPixels then
        		image.set(masterPixels, y, x, background, 0x000000, 0x00, " ")
        	else
            	buffer.set(y, x, background, 0x000000, " ")
            end
        else
        	if applyToMasterPixels then
        		image.set(masterPixels, x, y, background, 0x000000, 0x00, " ")
        	else
            	buffer.set(x, y, background, 0x000000, " ")
            end
        end

        error2 = error2 + derror2;

        if error2 > dx then
            y = y + (y1 > y0 and 1 or -1);
            error2 = error2 - dx * 2;
        end
    end
end

local function drawShapeCornerPoints(xStart, yStart, xEnd, yEnd)
	buffer.set(xStart, yStart, 0x99FF80, 0x000000, " ")
	buffer.set(xEnd, yEnd, 0x99FF80, 0x000000, " ")
end

local function drawLineShape()
	local xStart, yStart = sizes.xStartOfImage + selection.xStart - 1, sizes.yStartOfImage + selection.yStart - 1
	local xEnd, yEnd = sizes.xStartOfImage + selection.xEnd - 1, sizes.yStartOfImage + selection.yEnd - 1

	line(xStart, yStart, xEnd, yEnd, currentBackground)
	drawShapeCornerPoints(xStart, yStart, xEnd, yEnd)
	drawTooltip(xEnd + 2, yEnd - 3, "Ш: " .. selection.width .. " px", "В: " .. selection.height .. " px", " ", "Enter - применить")
end

--Функция для обводки выделенной зоны
local function stroke(x, y, width, height, color, applyToMasterPixels)
	if applyToMasterPixels then
		local iterator
		for i = x, x + width - 1 do
			iterator = convertCoordsToIterator(i, y)
			masterPixels[iterator] = color; masterPixels[iterator + 1] = 0x0; masterPixels[iterator + 2] = 0x0; masterPixels[iterator + 3] = " "

			iterator = convertCoordsToIterator(i, y + height - 1)
			masterPixels[iterator] = color; masterPixels[iterator + 1] = 0x0; masterPixels[iterator + 2] = 0x0; masterPixels[iterator + 3] = " "
		end

		for i = y, y + height - 1 do
			iterator = convertCoordsToIterator(x, i)
			masterPixels[iterator] = color; masterPixels[iterator + 1] = 0x0; masterPixels[iterator + 2] = 0x0; masterPixels[iterator + 3] = " "

			iterator = convertCoordsToIterator(x + width - 1, i)
			masterPixels[iterator] = color; masterPixels[iterator + 1] = 0x0; masterPixels[iterator + 2] = 0x0; masterPixels[iterator + 3] = " "
		end
	else
		buffer.square(x, y, width, 1, color, 0x000000, " ")
		buffer.square(x, y + height - 1, width, 1, color, 0x000000, " ")

		buffer.square(x, y, 1, height, color, 0x000000, " ")
		buffer.square(x + width - 1, y, 1, height, color, 0x000000, " ")
	end
end

local function ellipse(xStart, yStart, width, height, color, applyToMasterPixels)
	--helper function, draws pixel and mirrors it
	local function setpixel4(centerX, centerY, deltaX, deltaY, color)
		if applyToMasterPixels then
			image.set(masterPixels, centerX + deltaX, centerY + deltaY, color, 0x000000, 0x00, " ")
			image.set(masterPixels, centerX - deltaX, centerY + deltaY, color, 0x000000, 0x00, " ")
			image.set(masterPixels, centerX + deltaX, centerY - deltaY, color, 0x000000, 0x00, " ")
			image.set(masterPixels, centerX - deltaX, centerY - deltaY, color, 0x000000, 0x00, " ")
		else
			buffer.set(centerX + deltaX, centerY + deltaY, color, 0x000000, " ")
			buffer.set(centerX - deltaX, centerY + deltaY, color, 0x000000, " ")
			buffer.set(centerX + deltaX, centerY - deltaY, color, 0x000000, " ")
			buffer.set(centerX - deltaX, centerY - deltaY, color, 0x000000, " ")
		end
	end

	--red ellipse, 2*10px border
	local centerX = math.floor(xStart + width / 2)
	local centerY = math.floor(yStart + height / 2)
	local radiusX = math.floor(width / 2)
	local radiusY = math.floor(height / 2)
	local radiusX2 = radiusX ^ 2
	local radiusY2 = radiusY ^ 2
	
	--upper and lower halves
	local quarter = math.floor(radiusX2 / math.sqrt(radiusX2 + radiusY2))
	for x = 0, quarter do
		local y = radiusY * math.sqrt(1 - x^2 / radiusX2)
		setpixel4(centerX, centerY, x, math.floor(y), color);
	end

	--right and left halves
	quarter = math.floor(radiusY2 / math.sqrt(radiusX2 + radiusY2));
	for y = 0, quarter do
		x = radiusX * math.sqrt(1 - y^2 / radiusY2);
		setpixel4(centerX, centerY, math.floor(x), y, color);
	end
end

local function polygon(xCenter, yCenter, xStart, yStart, countOfEdges, color)
	local degreeStep = 360 / countOfEdges

	local deltaX, deltaY = xStart - xCenter, yStart - yCenter
	local radius = math.sqrt(deltaX ^ 2 + deltaY ^ 2)
	local halfRadius = radius / 2
	local startDegree = math.deg(math.asin(deltaX / radius))

	local function calculatePosition(degree)
		local radDegree = math.rad(degree)
		local deltaX2 = math.sin(radDegree) * radius
		local deltaY2 = math.cos(radDegree) * radius
		return round(xCenter + deltaX2), round(yCenter + (deltaY >= 0 and deltaY2 or -deltaY2))
	end

	local xOld, yOld, xNew, yNew = calculatePosition(startDegree)

	for degree = (startDegree + degreeStep - 1), (startDegree + 360), degreeStep do
		xNew, yNew = calculatePosition(degree)
		buffer.line(xOld, yOld, xNew, yNew, color, 0x000000, " ")
		xOld, yOld = xNew, yNew
	end
end

local function drawPolygonShape()
	local xStart, yStart = sizes.xStartOfImage + selection.xStart - 1, sizes.yStartOfImage + selection.yStart - 1
	local xEnd, yEnd = sizes.xStartOfImage + selection.xEnd - 1, sizes.yStartOfImage + selection.yEnd - 1

	local radius = math.floor(math.sqrt(selection.width ^ 2 + (selection.height*2) ^ 2))
	polygon(xStart, yStart, xEnd, yEnd, currentPolygonCountOfEdges, currentBackground)

	drawShapeCornerPoints(xStart, yStart, xEnd, yEnd)
	drawTooltip(xEnd + 2, yEnd - 3, "Радиус: " .. radius .. " px", "Грани: " .. currentPolygonCountOfEdges, " ", "Enter - применить")
end

local function drawSquareShape(type)
	local xStart, yStart = sizes.xStartOfImage + selection.x - 1, sizes.yStartOfImage + selection.y - 1
	local xEnd, yEnd = xStart + selection.width - 1, yStart + selection.height - 1
	
	if type == "filledSquare" then
		buffer.square(xStart, yStart, selection.width, selection.height, currentBackground, 0x000000, " ")
	elseif type == "frame" then
		stroke(xStart, yStart, selection.width, selection.height, currentBackground, false)
	elseif type == "ellipse" then
		ellipse(xStart, yStart, selection.width, selection.height, currentBackground, false)		
	end

	drawShapeCornerPoints(xStart, yStart, xEnd, yEnd)
	drawTooltip(xEnd + 2, yEnd - 3, "Ш: " .. selection.width .. " px", "В: " .. selection.height .. " px", " ", "Enter - применить")
end

local function drawMultiPointInstrument()
	if selection and selection.finished == true then
		if instruments[currentInstrument] == "M" then
			drawSelection()
		elseif instruments[currentInstrument] == "S" then
			if currentShape == "Линия" then
				drawLineShape()
			elseif currentShape == "Эллипс" then
				drawSquareShape("ellipse")
			elseif currentShape == "Прямоугольник" then
				drawSquareShape("filledSquare")
			elseif currentShape == "Рамка" then
				drawSquareShape("frame")
			elseif currentShape == "Многоугольник" then
				drawPolygonShape()
			end
		end
	end
end

--Отрисовка изображения
local function drawImage()
	--Стартовые нужности
	local xPixel, yPixel = 1, 1
	local xPos, yPos = sizes.xStartOfImage, sizes.yStartOfImage

	--Устанавливаем ограничение прорисовки, чтобы картинка не съебывала за дозволенную зону
	buffer.setDrawLimit(sizes.xStartOfDrawingArea, sizes.yStartOfDrawingArea, sizes.widthOfDrawingArea, sizes.heightOfDrawingArea)

	--Рисуем прозрачную зону
	drawTransparentZone(xPos, yPos)

	--Перебираем массив мастерпиксельса
	for i = 1, #masterPixels, 4 do
		--Рисуем пиксель, если у него прозрачность не абсолютная, ЛИБО имеется какой-то символ
		--Т.е. даже если прозрачность и охуела, но символ есть, то рисуем его
		if masterPixels[i + 2] ~= 0xFF or masterPixels[i + 3] ~= " " then
			drawPixel(xPos, yPos, xPixel, yPixel, i)
		end
		--Всякие расчеты координат
		xPixel = xPixel + 1
		xPos = xPos + 1
		if xPixel > masterPixels.width then xPixel = 1; xPos = sizes.xStartOfImage; yPixel = yPixel + 1; yPos = yPos + 1 end
	end

	if masterPixels.width > 0 and masterPixels.height > 0 then
		local text = "Размер: " .. masterPixels.width .. "x" .. masterPixels.height .. " px"
		xPos = math.floor(sizes.xStartOfImage + masterPixels.width / 2 - unicode.len(text) / 2)
		buffer.text(xPos, sizes.yEndOfImage + 1, 0xFFFFFF, text)
	end

	--Рисуем мультиинструмент
	drawMultiPointInstrument()
	--Убираем ограничение отрисовки
	buffer.resetDrawLimit()
end

--Просто для удобства
local function drawBackgroundAndImage()
	drawBackground()
	drawImage()
end

--Функция, рисующая ВСЕ, абсолютли, епта
local function drawAll()
	drawBackground()
	drawLeftBar()
	drawTopBar()
	drawTopMenu()
	drawBackgroundAndImage()

	buffer.draw()
end

------------------------------------------------ Вспомогательные функции для работы с изображением и прочим --------------------------------------------------------------

--Смена инструмента на указанный номер
local function changeInstrumentTo(ID)
	currentInstrument = ID
	selection = nil
	drawAll()
end

--Перемещалка картинки в указанном направлении, поддерживающая все инструменты
local function move(direction)
	if instruments[currentInstrument] == "M" and selection and selection.finished == true then
		if direction == "up" then
			selection.y = selection.y - 1
			if selection.y < 1 then selection.y = 1 end
		elseif direction == "down" then
			selection.y = selection.y + 1
			if selection.y + selection.height - 1 > masterPixels.height then selection.y = selection.y - 1 end
		elseif direction == "left" then
			selection.x = selection.x - 1
			if selection.x < 1 then selection.x = 1 end
		elseif direction == "right" then
			selection.x = selection.x + 1
			if selection.x + selection.width - 1 > masterPixels.width then selection.x = selection.x - 1 end
		end
	else
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
	end
	drawBackgroundAndImage()
	buffer.draw()
end

--Просто более удобная установка пикселя, а то все эти плюсы, минусы, бррр
local function setPixel(iterator, background, foreground, alpha, symbol)
	masterPixels[iterator] = background
	masterPixels[iterator + 1] = foreground
	masterPixels[iterator + 2] = alpha
	masterPixels[iterator + 3] = symbol
end

--Функция, меняющая цвета местами
local function swapColors()
	currentBackground, currentForeground = swap(currentBackground, currentForeground)
	drawColors()
	console("Цвета поменяны местами")
end

--Ух, сука! Функция для работы инструмента текста
--Лютая дичь, спиздил со старого фш, но, вроде, пашет нормас
--Правда, чет есть предчувствие, что костыльная и багованная она, ну да похуй
local function inputText(x, y, limit)
	local oldPixels = ecs.rememberOldPixels(x,y-1,x+limit-1,y+1)
	local text = ""
	local inputPos = 1

	local function drawThisShit()
		for i = 1, inputPos do
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
			elseif e[4] == 200 then
				text = text .. "▀"
				if unicode.len(text) < limit then
					inputPos = inputPos + 1
				end
				drawThisShit()
			elseif e[4] == 208 then
				text = text .. "▄"
				if unicode.len(text) < limit then
					inputPos = inputPos + 1
				end
				drawThisShit()
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

--Функция-применятор текста к массиву изображения
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

--Функция-центратор картинки по центру моника
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

--Функция, спрашивающая юзверя, какого размера пикчу он  хочет создать - ну, и создает ее
local function new()
	selection = nil
	local data = ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x262626, "Новый документ"}, {"EmptyLine"}, {"Input", 0x262626, 0x880000, "Ширина"}, {"Input", 0x262626, 0x880000, "Высота"}, {"EmptyLine"}, {"Button", {0xbbbbbb, 0xffffff, "OK"}})

	data[1] = tonumber(data[1]) or 51
	data[2] = tonumber(data[2]) or 19

	masterPixels = {}
	masterPixels.width, masterPixels.height = data[1], data[2]
	createEmptyMasterPixels()
	tryToFitImageOnCenterOfScreen()
	drawAll()
end

--Обычная рекурсивная заливка, алгоритм спизжен с вики
--Есть инфа, что выжирает стек, но Луа, вроде, не особо ругается, так что заебок все
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

--Кисть, КИИИИСТЬ
local function brush(x, y, background, foreground, alpha, symbol)
	--Смещение влево и вправо относительно указанного центра кисти
	--КОРОЧ, НЕ ТУПИ
	--Чтобы кисточка была по центру мыши, ну
	local position = math.floor(currentBrushSize / 2)
	x, y = x - position, y - position
	--Хуевинка для рисования
	local newIterator
	--Перебираем кисть по ширине и высоте
	for cyka = 1, currentBrushSize do
		for pidor = 1, currentBrushSize do
			--Если этот кусочек входит в границы рисовабельной зоны, то
			if x >= 1 and x <= masterPixels.width and y >= 1 and y <= masterPixels.height then
				
				--Считаем итератор для кусочка кисти
				newIterator = convertCoordsToIterator(x, y)

				--Если прозрачности кисти ВАЩЕ НЕТ, то просто рисуем как обычненько все
				if alpha == 0x00 then
					setPixel(newIterator, background, foreground, alpha, symbol)
				--Если прозрачности кисти есть какая-то, но она не абсолютная
				elseif alpha < 0xFF and alpha > 0x00 then
					--Если пиксель в массиве ни хуя не прозрачный, то оставляем его таким же, разве что цвет меняем на сблендированный
					if masterPixels[newIterator + 2] == 0x00 then
						local gettedBackground = colorlib.alphaBlend(masterPixels[newIterator], background, alpha)
						setPixel(newIterator, gettedBackground, foreground, 0x00, symbol)
					--А если прозрачный, то смешиваем прозрачности
					--Пиздануться вообще, сук
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
		x = x - currentBrushSize
		y = y + 1
	end
end

--Диалоговое окно обрезки и расширения картинки
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

--Функция-обрезчик картинки
local function crop()
	local direction, countOfPixels = cropOrExpand("Обрезать")
	if direction then
		masterPixels = image.crop(masterPixels, direction, countOfPixels)
		reCalculateImageSizes(sizes.xStartOfImage, sizes.yStartOfImage)
		drawAll()
	end
end

--Функция-расширитель картинки
local function expand()
	local direction, countOfPixels = cropOrExpand("Обрезать")
	if direction then
		masterPixels = image.expand(masterPixels, direction, countOfPixels, 0x010101, 0x010101, 0xFF, " ")
		reCalculateImageSizes(sizes.xStartOfImage, sizes.yStartOfImage)
		drawAll()
	end
end

--Функция-загрузчик картинки из файла
local function loadImageFromFile(path)
	if fs.exists(path) then
		selection = nil
		masterPixels = image.load(path)
		savePath = path
		tryToFitImageOnCenterOfScreen()
	else
		ecs.error("Файл \"" .. path .. "\" не существует")
	end
end

--Функция-заполнитель выделенной зоны какими-либо данными
local function fillSelection(background, foreground, alpha, symbol)
	for j = selection.y, selection.y + selection.height - 1 do
		for i = selection.x, selection.x + selection.width - 1 do
			local iterator = convertCoordsToIterator(i, j)
			masterPixels[iterator] = background
			masterPixels[iterator + 1] = foreground
			masterPixels[iterator + 2] = alpha
			masterPixels[iterator + 3] = symbol
		end
	end

	drawAll()
end

local function applyShapeToMasterPixels()
	if currentShape == "Линия" then
		line(selection.xStart, selection.yStart, selection.xEnd, selection.yEnd, currentBackground, true)
	elseif currentShape == "Прямоугольник" then
		fillSelection(currentBackground, 0x00000, 0x00, " ")
	elseif currentShape == "Рамка" then
		stroke(selection.x, selection.y, selection.width, selection.height, currentBackground, true)
	elseif currentShape == "Эллипс" then
		ellipse(selection.x, selection.y, selection.width, selection.height, currentBackground, true)
	end

	selection = nil
	drawBackgroundAndImage()
	buffer.draw()
end

------------------------------------------------ Старт программы --------------------------------------------------------------

--Рисуем весь интерфейс чисто для красоты
drawAll()

--Открываем файлы по аргументам программы
if args[1] == "o" or args[1] == "open" or args[1] == "-o" or args[1] == "load" then
	loadImageFromFile(args[2])
else
	new()
end

--Отрисовываем интерфейс снова, поскольку у нас либо создался новый документ, либо открылся имеющийся файл
drawAll()

--Анализируем ивенты
while true do
	local e = {event.pull()}
	if e[1] == "touch" or e[1] == "drag" or e[1] == "drop" then
		--Левый клик
		if e[5] == 0 then
			--Если кликнули на рисовабельную зонку
			if ecs.clickedAtArea(e[3], e[4], sizes.xStartOfImage, sizes.yStartOfImage, sizes.xEndOfImage, sizes.yEndOfImage) then
				
				--Получаем координаты в изображении и итератор
				local x, y = e[3] - sizes.xStartOfImage + 1, e[4] - sizes.yStartOfImage + 1
				local iterator = convertCoordsToIterator(x, y)
				
				--Все для инструментов мультиточечного рисования
				if instruments[currentInstrument] == "M" or instruments[currentInstrument] == "S" then
					if e[1] == "touch" then
						selection = {}
						selection.xStart, selection.yStart = x, y

					elseif e[1] == "drag" and selection then
						local x1, y1 = selection.xStart, selection.yStart
						local x2, y2 = x, y
						if x1 > x2 then
							x1, x2 = swap(x1, x2)
						end
						if y1 > y2 then
							y1, y2 = swap(y1, y2)
						end

						selection.x, selection.y = x1, y1
						selection.x2, selection.y2 = x2, y2
						selection.xEnd, selection.yEnd = x, y
						selection.width = selection.x2 - selection.x + 1
						selection.height = selection.y2 - selection.y + 1

						selection.finished = true
					end

					--Если выделение полностью завершено, то отдаем контроль отрисовочным функциям
					-- if instruments[currentInstrument] == "M" then
						drawBackgroundAndImage()
						buffer.draw()
					-- end
				--Кисть
				elseif instruments[currentInstrument] == "B" then
					
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
				elseif instruments[currentInstrument] == "E" then
					brush(x, y, currentBackground, currentForeground, 0xFF, currentSymbol)
					console("Ластик: клик на точку "..e[3].."x"..e[4]..", координаты в изображении: "..x.."x"..y..", индекс массива изображения: "..iterator)
					buffer.draw()
				--Текст
				elseif instruments[currentInstrument] == "T" then
					local limit = masterPixels.width - x + 1
					local text = inputText(e[3], e[4], limit)
					saveTextToPixels(x, y, text)
					drawImage()
					buffer.draw()

				--Заливка
				elseif instruments[currentInstrument] == "F" then

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
					selection = nil
					currentInstrument = key
					drawLeftBar(); buffer.draw()
					if instruments[currentInstrument] == "S" then
						local action = context.menu(obj["Instruments"][key][3] + 1, obj["Instruments"][key][2], {"Линия"}, {"Эллипс"}, {"Прямоугольник"}, {"Многоугольник"}, {"Рамка"})
						currentShape = action or "Линия"
						
						if currentShape == "Многоугольник" then
							local data = ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true,
								{"EmptyLine"},
								{"CenterText", 0x262626, "Количество граней"},
								{"EmptyLine"},
								{"Selector", 0x262626, 0x880000, "3", "4", "5", "6", "7", "8", "9", "10"},
								{"EmptyLine"}, 
								{"Button", {0xaaaaaa, 0xffffff, "OK"}}
							)
							currentPolygonCountOfEdges = tonumber(data[1])
						end
						drawAll()
					end
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
						action = context.menu(obj["TopMenu"][key][1] - 1, obj["TopMenu"][key][2] + 1, {"Цветовой тон/насыщенность"}, {"Цветовой баланс"}, {"Фотофильтр"}, "-", {"Инвертировать цвета"}, {"Черно-белый фильтр"}, "-", {"Размытие по Гауссу"})
					elseif key == "О программе" then
						ecs.universalWindow("auto", "auto", 36, 0xeeeeee, true, {"EmptyLine"}, {"CenterText", 0x880000, "Photoshop v6.2"}, {"EmptyLine"}, {"CenterText", 0x262626, "Авторы:"}, {"CenterText", 0x555555, "Тимофеев Игорь"}, {"CenterText", 0x656565, "vk.com/id7799889"}, {"CenterText", 0x656565, "Трифонов Глеб"}, {"CenterText", 0x656565, "vk.com/id88323331"}, {"EmptyLine"}, {"CenterText", 0x262626, "Тестеры:"}, {"CenterText", 0x656565, "Шестаков Тимофей"}, {"CenterText", 0x656565, "vk.com/id113499693"}, {"CenterText", 0x656565, "Вечтомов Роман"}, {"CenterText", 0x656565, "vk.com/id83715030"}, {"CenterText", 0x656565, "Омелаенко Максим"},  {"CenterText", 0x656565, "vk.com/paladincvm"}, {"EmptyLine"},{"Button", {0xbbbbbb, 0xffffff, "OK"}})
					elseif key == "Горячие клавиши" then
						ecs.universalWindow( "auto", "auto", 42, 0xeeeeee, true,
							{"EmptyLine"},
							{"CenterText", 0x880000, "Горячие клавиши"},
							{"EmptyLine"},
							{"CenterText", 0x000000, "B - кисть"},
							{"CenterText", 0x000000, "E - ластик"},
							{"CenterText", 0x000000, "T - текст"},
							{"CenterText", 0x000000, "G - заливка"},
							{"CenterText", 0x000000, "M - выделение"},
							{"EmptyLine"},
							{"WrappedText", 0x000000, "Стрелки - перемещение изображения"},
							{"WrappedText", 0x000000, "X - поменять цвета местами"},
							{"WrappedText", 0x000000, "D - установка черного и белого цвета"},
							{"WrappedText", 0x000000, "Ctrl+D - отмена выделения"},
							{"WrappedText", 0x000000, "Alt+Клик - выбор цвета (только для Кисти)"},
							{"EmptyLine"},
							{"Button", {0xbbbbbb, 0xffffff, "OK"}}
						)				
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
					elseif action == "Размытие по Гауссу" then
						local data = ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true,
							{"EmptyLine"},
							{"CenterText", 0x262626, "Размытие по Гауссу"},
							{"EmptyLine"},
							{"Slider", 0x262626, 0x880000, 1, 5, 2, "Радиус: ", ""},
							{"Slider", 0x262626, 0x880000, 1, 255, 0x88, "Сила: ", ""},
							{"EmptyLine"}, 
							{"Button", {0xaaaaaa, 0xffffff, "OK"}, {0x888888, 0xffffff, "Отмена"}}
						)
						if data[3] == "OK" then
							masterPixels = image.gaussianBlur(masterPixels, tonumber(data[1]), tonumber(data[2]))
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
						local data = ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x262626, "Сохранить как"}, {"EmptyLine"}, {"Input", 0x262626, 0x880000, "Путь"}, {"Selector", 0x262626, 0x880000, "OCIF4", "OCIF1", "OCIFString", "RAW"}, {"CenterText", 0x262626, "Рекомендуется использовать"}, {"CenterText", 0x262626, "метод кодирования OCIF4"}, {"EmptyLine"}, {"Button", {0xaaaaaa, 0xffffff, "OK"}, {0x888888, 0xffffff, "Отмена"}})
						if data[3] == "OK" then
							data[1] = data[1] or "Untitled"
							data[2] = data[2] or "OCIF4"
							
							if data[2] == "RAW" then
								data[2] = 0
							elseif data[2] == "OCIF1" then
								data[2] = 1
							elseif data[2] == "OCIF4" then
								data[2] = 4
							elseif data[2] == "OCIFString" then
								data[2] = 6
							else
								data[2] = 4
							end

							local filename = data[1] .. ".pic"
							local encodingMethod = data[2]

							image.save(filename, masterPixels, encodingMethod)
							savePath = filename
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
				
				if instruments[currentInstrument] == "M" and selection then
					local action = context.menu(e[3], e[4], {"Убрать выделение"}, {"Обрезать", true}, "-", {"Заливка"}, {"Рамка"}, "-", {"Очистить"})
					if action == "Убрать выделение" then
						selection = nil
						drawAll()
					elseif action == "Очистить" then
						fillSelection(0x0, 0x0, 0xFF, " ")
					elseif action == "Заливка" then
						fillSelection(currentBackground, 0x0, 0x0, " ")
					elseif action == "Рамка" then
						stroke(selection.x, selection.y, selection.width, selection.height, currentBackground, true)
						drawAll()
					end
				else
					local x, y, width, height = e[3], e[4], 30, 12
					--А это чтоб за края экрана не лезло
					if y + height >= buffer.screen.height then y = buffer.screen.height - height end
					if x + width + 1 >= buffer.screen.width then x = buffer.screen.width - width - 1 end

					currentBrushSize, currentAlpha = table.unpack(ecs.universalWindow(x, y, width, 0xeeeeee, true, {"EmptyLine"}, {"CenterText", 0x880000, "Параметры кисти"}, {"Slider", 0x262626, 0x880000, 1, 10, currentBrushSize, "Размер: ", " px"}, {"Slider", 0x262626, 0x880000, 0, 255, currentAlpha, "Прозрачность: ", ""}, {"EmptyLine"}, {"Button", {0xbbbbbb, 0xffffff, "OK"}}))
					drawTopBar()
					buffer.draw()
				end
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
		-- --Пробел
		-- elseif e[4] == 57 then
		-- 	drawAll()
		--ENTER
		elseif e[4] == 28 then
			if instruments[currentInstrument] == "S" and selection and selection.finished then
				applyShapeToMasterPixels()
			end
		--BACKSPACE
		elseif e[4] == 14 then
			if selection and selection.finished then
				fillSelection(0x000000, 0x000000, 0x00, " ")
				drawAll()
			end
		--X
		elseif e[4] == 45 then
			swapColors()
			buffer.draw()
		--B
		elseif e[4] == 48 then
			changeInstrumentTo(2)
		--E
		elseif e[4] == 18 then
			changeInstrumentTo(3)
		--G
		elseif e[4] == 34 then
			changeInstrumentTo(4)
		--T
		elseif e[4] == 20 then
			changeInstrumentTo(5)
		--M
		elseif e[4] == 50 then
			changeInstrumentTo(1)
		--D
		elseif e[4] == 32 then
			if keyboard.isControlDown() then
				selection = nil
				drawAll()
			else
				currentBackground = 0x000000
				currentForeground = 0xFFFFFF
				currentAlpha = 0x00
				drawColors()
				buffer.draw()
			end
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
