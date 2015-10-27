local component = require("component")
local colorlib = require("colorlib")
local unicode = require("unicode")
local gpu = component.gpu

local buffer = {}
local countOfGPUOperations = 0
local debug = false
local sizeOfPixelData = 3

------------------------------------------------------------------------------------------------------

--Формула конвертации индекса массива изображения в абсолютные координаты пикселя изображения
local function convertIndexToCoords(index)
	--Приводим индекс к корректному виду (1 = 1, 4 = 2, 7 = 3, 10 = 4, 13 = 5, ...)
	index = (index + sizeOfPixelData - 1) / sizeOfPixelData
	--Получаем остаток от деления индекса на ширину изображения
	local ostatok = index % buffer.screen.width
	--Если остаток равен 0, то х равен ширине изображения, а если нет, то х равен остатку
	local x = (ostatok == 0) and buffer.screen.width or ostatok
	--А теперь как два пальца получаем координату по Y
	local y = math.ceil(index / buffer.screen.width)
	--Очищаем остаток из оперативки
	ostatok = nil
	--Возвращаем координаты
	return x, y
end

--Формула конвертации абсолютных координат пикселя изображения в индекс для массива изображения
local function convertCoordsToIndex(x, y)
	return (buffer.screen.width * (y - 1) + x) * sizeOfPixelData - sizeOfPixelData + 1
end

local function printDebug(line, text)
	if debug then 
		ecs.colorTextWithBack(1, line, 0xFFFFFF, 0x262626, text)
	end
end

function buffer.createArray()
	buffer.screen.current = {}
	buffer.screen.new = {}

	for y = 1, buffer.screen.height do
		for x = 1, buffer.screen.width do
			table.insert(buffer.screen.current, -1)
			table.insert(buffer.screen.current, -1)
			table.insert(buffer.screen.current, " ")

			table.insert(buffer.screen.new, -1)
			table.insert(buffer.screen.new, -1)
			table.insert(buffer.screen.new, " ")
		end
	end
end

function buffer.start()

	countOfGPUOperations = 0

	buffer.screen = {
		current = {},
		new = {},
	}

	buffer.screen.width, buffer.screen.height = gpu.getResolution()

	if debug then
		local old = ecs.getInfoAboutRAM()
		buffer.createArray()
		local new = ecs.getInfoAboutRAM()
		printDebug(49, "Схавалось " .. old - new .. " КБ оперативки")
	end
end

function buffer.get(x, y)
	local index = convertCoordsToIndex(x, y)
	if x >= 1 and y >= 1 and x <= buffer.screen.width and y <= buffer.screen.height then
		return buffer.screen.current[index], buffer.screen.current[index + 1], buffer.screen.current[index + 2]
	else
		error("Невозможно получить указанные значения, так как указанные координаты лежат за пределами экрана.\n")
	end
end

function buffer.set(x, y, background, foreground, symbol)
	local index = convertCoordsToIndex(x, y)
	if x >= 1 and y >= 1 and x <= buffer.screen.width and y <= buffer.screen.height then
		buffer.screen.new[index] = background
		buffer.screen.new[index + 1] = foreground
		buffer.screen.new[index + 2] = symbol
	end
end

--Нарисовать квадрат
function buffer.square(x, y, width, height, background, foreground, symbol, transparency)
	local index
	if transparency then transparency = transparency * 2.55 end
	for j = y, (y + height - 1) do
		for i = x, (x + width - 1) do
			if i >= 1 and j >= 1 and i <= buffer.screen.width and j <= buffer.screen.height then
				index = convertCoordsToIndex(i, j)
				if transparency then
					buffer.screen.new[index] = colorlib.alphaBlend(buffer.screen.new[index], background, transparency)
					buffer.screen.new[index + 1] = colorlib.alphaBlend(buffer.screen.new[index + 1], background, transparency)
				else
					buffer.screen.new[index] = background
					buffer.screen.new[index + 1] = foreground
					buffer.screen.new[index + 2] = symbol
				end
			end
		end
	end
end

--Заливка области изображения (рекурсивная, говно-метод)
function buffer.fill(x, y, background, foreground, symbol)
	
	local startBackground, startForeground, startSymbol

	local function doFill(xStart, yStart)
		local index = convertCoordsToIndex(xStart, yStart)

		if
			buffer.screen.new[index] ~= startBackground or
			-- buffer.screen.new[index + 1] ~= startForeground or
			-- buffer.screen.new[index + 2] ~= startSymbol or
			buffer.screen.new[index] == background
			-- buffer.screen.new[index + 1] == foreground or
			-- buffer.screen.new[index + 2] == symbol
		then
			return
		end

		--Заливаем в память
		buffer.screen.new[index] = background
		buffer.screen.new[index + 1] = foreground
		buffer.screen.new[index + 2] = symbol

		doFill(xStart + 1, yStart)
		doFill(xStart - 1, yStart)
		doFill(xStart, yStart + 1)
		doFill(xStart, yStart - 1)

		iterator = nil
	end

	local startIndex = convertCoordsToIndex(x, y)
	startBackground = buffer.screen.new[startIndex]
	startForeground = buffer.screen.new[startIndex + 1]
	startSymbol = buffer.screen.new[startIndex + 2]

	doFill(x, y)
end

--Нарисовать окружность, алгоритм спизжен с вики
function buffer.circle(xCenter, yCenter, radius, background, foreground, symbol)
	--Подфункция вставки точек
	local function insertPoints(x, y)
		buffer.set(xCenter + x * 2, yCenter + y, background, foreground, symbol)
		buffer.set(xCenter + x * 2, yCenter - y, background, foreground, symbol)
		buffer.set(xCenter - x * 2, yCenter + y, background, foreground, symbol)
		buffer.set(xCenter - x * 2, yCenter - y, background, foreground, symbol)

		buffer.set(xCenter + x * 2 + 1, yCenter + y, background, foreground, symbol)
		buffer.set(xCenter + x * 2 + 1, yCenter - y, background, foreground, symbol)
		buffer.set(xCenter - x * 2 + 1, yCenter + y, background, foreground, symbol)
		buffer.set(xCenter - x * 2 + 1, yCenter - y, background, foreground, symbol)
	end

	local x = 0
	local y = radius
	local delta = 3 - 2 * radius;
	while (x < y) do
		insertPoints(x, y);
		insertPoints(y, x);
		if (delta < 0) then
			delta = delta + (4 * x + 6)
		else 
			delta = delta + (4 * (x - y) + 10)
			y = y - 1
		end
		x = x + 1
	end

	if x == y then insertPoints(x, y) end
end

--Скопировать область изображения и вернуть ее в виде массива
function buffer.copy(x, y, width, height)
	local copyArray = {
		["width"] = width,
		["height"] = height,
	}

	if x < 1 or y < 1 or x + width - 1 > buffer.screen.width or y + height - 1 > buffer.screen.height then
		errror("Область копирования выходит за пределы экрана.")
	end

	local index
	for j = y, (y + height - 1) do
		for i = x, (x + width - 1) do
			index = convertCoordsToIndex(i, j)
			table.insert(copyArray, buffer.screen.new[index])
			table.insert(copyArray, buffer.screen.new[index + 1])
			table.insert(copyArray, buffer.screen.new[index + 2])
		end
	end

	return copyArray
end

--Вставить скопированную ранее область изображения
function buffer.paste(x, y, copyArray)
	local index, arrayIndex
	if not copyArray or #copyArray == 0 then error("Массив области экрана пуст.") end

	for j = y, (y + copyArray.height - 1) do
		for i = x, (x + copyArray.width - 1) do
			if i >= 1 and j >= 1 and i <= buffer.screen.width and j <= buffer.screen.height then
				--Рассчитываем индекс массива основного изображения
				index = convertCoordsToIndex(i, j)
				--Копипаст формулы, аккуратнее!
				--Рассчитываем индекс массива вставочного изображения
				arrayIndex = (copyArray.width * ((j - y + 1) - 1) + (i - x + 1)) * sizeOfPixelData - sizeOfPixelData + 1
				--Вставляем данные
				buffer.screen.new[index] = copyArray[arrayIndex]
				buffer.screen.new[index + 1] = copyArray[arrayIndex + 1]
				buffer.screen.new[index + 2] = copyArray[arrayIndex + 2]
			end
		end
	end
end

--Нарисовать линию, алгоритм спизжен с вики
function buffer.line(x1, y1, x2, y2, background, foreground, symbol)
	local deltaX = math.abs(x2 - x1)
	local deltaY = math.abs(y2 - y1)
	local signX = (x1 < x2) and 1 or -1
	local signY = (y1 < y2) and 1 or -1

	local errorCyka = deltaX - deltaY
	local errorCyka2

	buffer.set(x2, y2, background, foreground, symbol)

	while(x1 ~= x2 or y1 ~= y2) do
		buffer.set(x1, y1, background, foreground, symbol)

		errorCyka2 = errorCyka * 2

		if (errorCyka2 > -deltaY) then
			errorCyka = errorCyka - deltaY
			x1 = x1 + signX
		end

		if (errorCyka2 < deltaX) then
			errorCyka = errorCyka + deltaX
			y1 = y1 + signY
		end
	end
end

function buffer.text(x, y, color, text)
	local index
	local sText = unicode.len(text)
	for i = 1, sText do
		index = convertCoordsToIndex(x + i - 1, y)
		buffer.screen.new[index + 1] = color
		buffer.screen.new[index + 2] = unicode.sub(text, i, i)
	end
end

function buffer.calculateDifference(x, y)
	local index = convertCoordsToIndex(x, y)
	local backgroundIsChanged, foregroundIsChanged, symbolIsChanged = false, false, false
	
	--Если цвет фона на новом экране отличается от цвета фона на текущем, то
	if buffer.screen.new[index] ~= buffer.screen.current[index] then
		--Присваиваем цвету фона на текущем экране значение цвета фона на новом экране
		buffer.screen.current[index] = buffer.screen.new[index]
		
		--Говорим системе, что что фон изменился
		backgroundIsChanged = true
	end

	index = index + 1
	
	--Аналогично для цвета текста
	if buffer.screen.new[index] ~= buffer.screen.current[index] then
		buffer.screen.current[index] = buffer.screen.new[index]
		foregroundIsChanged = true
	end

	index = index + 1

	--И для символа
	if buffer.screen.new[index] ~= buffer.screen.current[index] then
		buffer.screen.current[index] = buffer.screen.new[index]
		symbolIsChanged = true
	end

	return backgroundIsChanged, foregroundIsChanged, symbolIsChanged
end

function buffer.draw()
	local currentBackground, currentForeground = -math.huge, -math.huge
	local index
	local massiv
	
	for y = 1, buffer.screen.height do
		local x = 1
		while x <= buffer.screen.width do

			index = convertCoordsToIndex(x, y)

			local backgroundIsChanged, foregroundIsChanged, symbolIsChanged = buffer.calculateDifference(x, y)

			if currentBackground ~= buffer.screen.current[index] then
				gpu.setBackground(buffer.screen.current[index])
				currentBackground = buffer.screen.current[index]
				countOfGPUOperations = countOfGPUOperations + 1
			end

			index = index + 1

			if currentForeground ~= buffer.screen.current[index] then
				gpu.setForeground(buffer.screen.current[index])
				currentForeground = buffer.screen.current[index]
				countOfGPUOperations = countOfGPUOperations + 1
			end

			index = index - 1

			--Если были найдены какие-то отличия нового экрана от старого, то корректируем эти отличия через gpu.set()
			if backgroundIsChanged or foregroundIsChanged or symbolIsChanged then

				massiv = { buffer.screen.current[index + 2] }

				--Отрисовка линиями. Не трожь, сука!
				local iIndex
				for i = (x + 1), buffer.screen.width do
					iIndex = convertCoordsToIndex(i, y)
					if	
						buffer.screen.current[index] == buffer.screen.new[iIndex] and
						(
						buffer.screen.new[iIndex + 2] == " "
						or
						buffer.screen.current[index + 1] == buffer.screen.new[iIndex + 1]
						)
					then
					 	buffer.calculateDifference(i, y)
					 	table.insert(massiv, buffer.screen.current[iIndex + 2])
					else
						break
					end
				end

				--os.sleep(0.2)
				gpu.set(x, y, table.concat(massiv))
				
				x = x + #massiv - 1

				countOfGPUOperations = countOfGPUOperations + 1
			end

			x = x + 1
		end
	end

	printDebug(50, "Количество GPU-операций: " .. countOfGPUOperations)
end

------------------------------------------------------------------------------------------------------

buffer.start()

------------------------------------------------------------------------------------------------------

return buffer














