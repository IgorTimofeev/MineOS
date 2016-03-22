
-- Адаптивная загрузка необходимых библиотек и компонентов
local libraries = {
	["component"] = "component",
	["unicode"] = "unicode",
	["image"] = "image",
	["colorlib"] = "colorlib",
}

local components = {
	["gpu"] = "gpu",
}

for library in pairs(libraries) do if not _G[library] then _G[library] = require(libraries[library]) end end
for comp in pairs(components) do if not _G[comp] then _G[comp] = _G.component[components[comp]] end end
libraries, components = nil, nil

local buffer = {}
local debug = false
local sizeOfPixelData = 3

------------------------------------------------- Вспомогательные методы -----------------------------------------------------------------

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
		ecs.square(1, line, buffer.screen.width, 1, 0x262626)
		ecs.colorText(2, line, 0xFFFFFF, text)
	end
end

-- Установить ограниченную зону рисования. Все пиксели, не попадающие в эту зону, будут игнорироваться.
function buffer.setDrawLimit(x, y, width, height)
	buffer.drawLimit = { x1 = x, y1 = y, x2 = x + width - 1, y2 = y + height - 1 }
end

-- Удалить ограничение зоны рисования, по умолчанию она будет от 1х1 до координат размера экрана.
function buffer.resetDrawLimit()
	buffer.drawLimit = {x1 = 1, y1 = 1, x2 = buffer.screen.width, y2 = buffer.screen.height}
end

-- Создать массив буфера с базовыми переменными и базовыми цветами. Т.е. черный фон, белый текст.
function buffer.start()	
	buffer.screen = {}
	buffer.screen.current = {}
	buffer.screen.new = {}
	buffer.screen.width, buffer.screen.height = gpu.getResolution()

	buffer.resetDrawLimit()

	for y = 1, buffer.screen.height do
		for x = 1, buffer.screen.width do
			table.insert(buffer.screen.current, 0x010101)
			table.insert(buffer.screen.current, 0xFEFEFE)
			table.insert(buffer.screen.current, " ")

			table.insert(buffer.screen.new, 0x010101)
			table.insert(buffer.screen.new, 0xFEFEFE)
			table.insert(buffer.screen.new, " ")
		end
	end
end

------------------------------------------------- Методы отрисовки -----------------------------------------------------------------

-- Получить информацию о пикселе из буфера
function buffer.get(x, y)
	local index = convertCoordsToIndex(x, y)
	if x >= buffer.drawLimit.x1 and y >= buffer.drawLimit.y1 and x <= buffer.drawLimit.x2 and y <= buffer.drawLimit.y2 then
		return buffer.screen.current[index], buffer.screen.current[index + 1], buffer.screen.current[index + 2]
	else
		error("Невозможно получить указанные значения, так как указанные координаты лежат за пределами экрана.\n")
	end
end

-- Установить пиксель в буфере
function buffer.set(x, y, background, foreground, symbol)
	local index = convertCoordsToIndex(x, y)
	if x >= buffer.drawLimit.x1 and y >= buffer.drawLimit.y1 and x <= buffer.drawLimit.x2 and y <= buffer.drawLimit.y2 then
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
			if i >= buffer.drawLimit.x1 and j >= buffer.drawLimit.y1 and i <= buffer.drawLimit.x2 and j <= buffer.drawLimit.y2 then
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

--Очистка экрана, по сути более короткая запись buffer.square
function buffer.clear(color)
	buffer.square(1, 1, buffer.screen.width, buffer.screen.height, color or 0x262626, 0xFFFFFF, " ")
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
		if xStart >= buffer.drawLimit.x1 and yStart >= buffer.drawLimit.y1 and xStart <= buffer.drawLimit.x2 and yStart <= buffer.drawLimit.y2 then
			buffer.screen.new[index] = background
			buffer.screen.new[index + 1] = foreground
			buffer.screen.new[index + 2] = symbol
		end

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
			if i >= buffer.drawLimit.x1 and j >= buffer.drawLimit.y1 and i <= buffer.drawLimit.x2 and j <= buffer.drawLimit.y2 then
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

-- Отрисовка текста, подстраивающегося под текущий фон
function buffer.text(x, y, color, text, transparency)
	local index
	if transparency then transparency = transparency * 2.55 end
	local sText = unicode.len(text)
	for i = 1, sText do
		if (x + i - 1) >= buffer.drawLimit.x1 and y >= buffer.drawLimit.y1 and (x + i - 1) <= buffer.drawLimit.x2 and y <= buffer.drawLimit.y2 then
			index = convertCoordsToIndex(x + i - 1, y)
			buffer.screen.new[index + 1] = not transparency and color or colorlib.alphaBlend(buffer.screen.new[index], color, transparency)
			buffer.screen.new[index + 2] = unicode.sub(text, i, i)
		end
	end
end

-- Отрисовка изображения
function buffer.image(x, y, picture)
	if not image then image = require("image") end
	local index, imageIndex
	for j = y, (y + picture.height - 1) do
		for i = x, (x + picture.width - 1) do
			if i >= buffer.drawLimit.x1 and j >= buffer.drawLimit.y1 and i <= buffer.drawLimit.x2 and j <= buffer.drawLimit.y2 then
				index = convertCoordsToIndex(i, j)
				--Копипаст формулы!
				imageIndex = (picture.width * ((j - y + 1) - 1) + (i - x + 1)) * 4 - 4 + 1

				if picture[imageIndex + 2] ~= 0x00 then
					buffer.screen.new[index] = colorlib.alphaBlend(buffer.screen.new[index], picture[imageIndex], picture[imageIndex + 2])
				else
					buffer.screen.new[index] = picture[imageIndex]
				end
				buffer.screen.new[index + 1] = picture[imageIndex + 1]
				buffer.screen.new[index + 2] = picture[imageIndex + 3]
			end
		end
	end
end

-- Кнопка фиксированных размеров
function buffer.button(x, y, width, height, background, foreground, text)
	local textPosX = math.floor(x + width / 2 - unicode.len(text) / 2)
	local textPosY = math.floor(y + height / 2)
	buffer.square(x, y, width, height, background, 0xFFFFFF, " ")
	buffer.text(textPosX, textPosY, foreground, text)

	return x, y, (x + width - 1), (y + height - 1)
end

-- Кнопка, подстраивающаяся под длину текста
function buffer.adaptiveButton(x, y, xOffset, yOffset, background, foreground, text)
	local width = xOffset * 2 + unicode.len(text)
	local height = yOffset * 2 + 1

	buffer.square(x, y, width, height, background, 0xFFFFFF, " ")
	buffer.text(x + xOffset, y + yOffset, foreground, text)

	return x, y, (x + width - 1), (y + height - 1)
end

-- Вертикальный скролл-бар
function buffer.scrollBar(x, y, width, height, countOfAllElements, currentElement, backColor, frontColor)
	local sizeOfScrollBar = math.ceil(1 / countOfAllElements * height)
	local displayBarFrom = math.floor(y + height * ((currentElement - 1) / countOfAllElements))

	buffer.square(x, y, width, height, backColor, 0xFFFFFF, " ")
	buffer.square(x, displayBarFrom, width, sizeOfScrollBar, frontColor, 0xFFFFFF, " ")

	sizeOfScrollBar, displayBarFrom = nil, nil
end

-- Отрисовка любого изображения в виде трехмерного массива. Неоптимизированно, зато просто.
function buffer.customImage(x, y, pixels)
	x = x - 1
	y = y - 1

	for i=1, #pixels do
		for j=1, #pixels[1] do
			if pixels[i][j][3] ~= "#" then
				buffer.set(x + j, y + i, pixels[i][j][1], pixels[i][j][2], pixels[i][j][3])
			end
		end
	end

	return (x + 1), (y + 1), (x + #pixels[1]), (y + #pixels)
end

--Нарисовать топ-меню, горизонтальная полоска такая с текстами
function buffer.menu(x, y, width, color, selectedObject, ...)
	local objects = { ... }
	local objectsToReturn = {}
	local xPos = x + 2
	local spaceBetween = 2
	buffer.square(x, y, width, 1, color, 0xFFFFFF, " ")
	for i = 1, #objects do
		if i == selectedObject then
			buffer.square(xPos - 1, y, unicode.len(objects[i][1]) + spaceBetween, 1, 0x3366CC, 0xFFFFFF, " ")
			buffer.text(xPos, y, 0xFFFFFF, objects[i][1])
		else
			buffer.text(xPos, y, objects[i][2], objects[i][1])
		end
		objectsToReturn[objects[i][1]] = { xPos, y, xPos + unicode.len(objects[i][1]) - 1, y, i }
		xPos = xPos + unicode.len(objects[i][1]) + spaceBetween
	end
	return objectsToReturn
end

-- Прамоугольная рамочка
function buffer.frame(x, y, width, height, color)
	local stringUp = "┌" .. string.rep("─", width - 2) .. "┐"
	local stringDown = "└" .. string.rep("─", width - 2) .. "┘"

	buffer.text(x, y, color, stringUp)
	buffer.text(x, y + height - 1, color, stringDown)

	local yPos = 1
	for i = 1, (height - 2) do
		buffer.text(x, y + yPos, color, "│")
		buffer.text(x + width - 1, y + yPos, color, "│")
		yPos = yPos + 1
	end
end

-- Кнопка в виде текста в рамке
function buffer.framedButton(x, y, width, height, backColor, buttonColor, text)
	buffer.square(x, y, width, height, backColor, buttonColor, " ")
	buffer.frame(x, y, width, height, buttonColor)
	
	x = x + math.floor(width / 2 - unicode.len(text) / 2)
	y = y + math.floor(width / 2 - 1)

	buffer.text(x, y, buttonColor, text)
end

------------------------------------------- Просчет изменений и отрисовка ------------------------------------------------------------------------

--Функция рассчитывает изменения и применяет их, возвращая то, что было изменено
function buffer.calculateDifference(index)
	local somethingIsChanged = false
	
	--Если цвет фона на новом экране отличается от цвета фона на текущем, то
	if buffer.screen.new[index] ~= buffer.screen.current[index] then
		--Присваиваем цвету фона на текущем экране значение цвета фона на новом экране
		buffer.screen.current[index] = buffer.screen.new[index]
		--Говорим системе, что что-то изменилось
		somethingIsChanged = true
	end

	index = index + 1
	
	--Аналогично для цвета текста
	if buffer.screen.new[index] ~= buffer.screen.current[index] then
		buffer.screen.current[index] = buffer.screen.new[index]
		somethingIsChanged = true
	end

	index = index + 1

	--И для символа
	if buffer.screen.new[index] ~= buffer.screen.current[index] then
		buffer.screen.current[index] = buffer.screen.new[index]
		somethingIsChanged = true
	end

	return somethingIsChanged
end

--Функция группировки изменений и их отрисовки на экран
function buffer.draw(force)
	--Необходимые переменные, дабы не создавать их в цикле и не генерировать конструкторы
	local somethingIsChanged, index, indexPlus1, indexPlus2, massiv, x, y
	--Массив третьего буфера, содержащий в себе измененные пиксели
	-- buffer.screen.changes = {}
	
	--Перебираем содержимое нашего буфера по X и Y
	for y = 1, buffer.screen.height do
		x = 1
		while x <= buffer.screen.width do
			--Получаем индекс массива из координат, уменьшая нагрузку на CPU
			index = convertCoordsToIndex(x, y)
			indexPlus1 = index + 1
			indexPlus2 = index + 2
			--Получаем изменения и применяем их
			somethingIsChanged = buffer.calculateDifference(index)

			--Если хоть что-то изменилось, то начинаем работу
			if somethingIsChanged or force then

				gpu.setBackground(buffer.screen.current[index]])
				gpu.setForeground(buffer.screen.current[indexPlus1])
				gpu.set(x, y, buffer.screen.current[indexPlus2])

				--Оптимизация by Krutoy, создаем массив, в который заносим чарсы. Работает быстрее, чем конкатенейт строк
				-- massiv = { buffer.screen.current[indexPlus2] }
				-- --Загоняем в наш чарс-массив одинаковые пиксели справа, если таковые имеются
				-- local iIndex
				-- local i = x + 1
				-- while i <= buffer.screen.width do
				-- 	iIndex = convertCoordsToIndex(i, y)
				-- 	if	
				-- 		buffer.screen.current[index] == buffer.screen.new[iIndex] and
				-- 		(
				-- 		buffer.screen.new[iIndex + 2] == " "
				-- 		or
				-- 		buffer.screen.current[indexPlus1] == buffer.screen.new[iIndex + 1]
				-- 		)
				-- 	then
				-- 	 	buffer.calculateDifference(iIndex)
				-- 	 	table.insert(massiv, buffer.screen.current[iIndex + 2])
				-- 	else
				-- 		break
				-- 	end

				-- 	i = i + 1
				-- end

				-- --Заполняем третий буфер полученными данными
				-- buffer.screen.changes[buffer.screen.current[indexPlus1]] = buffer.screen.changes[buffer.screen.current[indexPlus1]] or {}
				-- buffer.screen.changes[buffer.screen.current[indexPlus1]][buffer.screen.current[index]] = buffer.screen.changes[buffer.screen.current[indexPlus1]][buffer.screen.current[index]] or {}
				
				-- table.insert(buffer.screen.changes[buffer.screen.current[indexPlus1]][buffer.screen.current[index]], index)
				-- table.insert(buffer.screen.changes[buffer.screen.current[indexPlus1]][buffer.screen.current[index]], table.concat(massiv))
			
				--Смещаемся по иксу вправо
				x = x + #massiv - 1
			end

			x = x + 1
		end
	end

	--Сбрасываем переменные на невозможное значение цвета, чтобы не багнуло
	-- index, indexPlus1 = -math.huge, -math.huge

	--Перебираем все цвета текста и фона, выполняя гпу-операции
	-- for foreground in pairs(buffer.screen.changes) do
	-- 	if indexPlus1 ~= foreground then gpu.setForeground(foreground); indexPlus1 = foreground end
	-- 	for background in pairs(buffer.screen.changes[foreground]) do
	-- 		if index ~= background then gpu.setBackground(background); index = background end
			
	-- 		for i = 1, #buffer.screen.changes[foreground][background], 2 do
	-- 			--Конвертируем указанный индекс в координаты
	-- 			x, y = convertIndexToCoords(buffer.screen.changes[foreground][background][i])
	-- 			--Выставляем ту самую собранную строку из одинаковых цветов
	-- 			gpu.set(x, y, buffer.screen.changes[foreground][background][i + 1])
	-- 		end
	-- 	end
	-- end

	--Очищаем память, ибо незачем нам хранить третий буфер
	-- buffer.screen.changes = {}
	-- buffer.screen.changes = nil
end

------------------------------------------------------------------------------------------------------

buffer.start()

------------------------------------------------------------------------------------------------------

return buffer













