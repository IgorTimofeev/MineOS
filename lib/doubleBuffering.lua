
------------------------------------------------- Libraries -------------------------------------------------

local libraries = {
	component = "component",
	unicode = "unicode",
	colorlib = "colorlib",
	image = "image",
}

for library in pairs(libraries) do if not _G[library] then _G[library] = require(libraries[library]) end end; libraries = nil

------------------------------------------------- Constants -------------------------------------------------


local gpu = component.gpu
local buffer = {}

------------------------------------------------- Core methods -------------------------------------------------

--Формула конвертации индекса массива изображения в абсолютные координаты пикселя изображения
function buffer.getBufferCoordinatesByIndex(index)
	local integer, fractional = math.modf(index / (buffer.screen.tripleWidth))
	return math.ceil(fractional * buffer.screen.width), integer + 1
end

--Формула конвертации абсолютных координат пикселя изображения в индекс для массива изображения
function buffer.getBufferIndexByCoordinates(x, y)
	return buffer.screen.tripleWidth * (y - 1) + x * 3 - 2
end

-- Установить ограниченную зону рисования. Все пиксели, не попадающие в эту зону, будут игнорироваться.
function buffer.setDrawLimit(xOrPasteArray, y, width, height)
	if type(xOrPasteArray) == "table" then
		buffer.drawLimit.x, buffer.drawLimit.y, buffer.drawLimit.x2, buffer.drawLimit.y2, buffer.drawLimit.width, buffer.drawLimit.height = xOrPasteArray.x, xOrPasteArray.y, xOrPasteArray.x2, xOrPasteArray.y2, xOrPasteArray.width, xOrPasteArray.height
	else
		buffer.drawLimit.x, buffer.drawLimit.y, buffer.drawLimit.x2, buffer.drawLimit.y2, buffer.drawLimit.width, buffer.drawLimit.height = xOrPasteArray, y, xOrPasteArray + width - 1, y + height - 1, width, height
	end
end

-- Удалить ограничение зоны рисования, по умолчанию она будет от 1х1 до координат размера экрана.
function buffer.resetDrawLimit()
	buffer.drawLimit.x, buffer.drawLimit.y, buffer.drawLimit.x2, buffer.drawLimit.y2, buffer.drawLimit.width, buffer.drawLimit.height = 1, 1, buffer.screen.width, buffer.screen.height, buffer.screen.width, buffer.screen.height
end

-- Cкопировать ограничение зоны рисования в виде отдельного массива
function buffer.getDrawLimit()
	return { x = buffer.drawLimit.x, y = buffer.drawLimit.y, x2 = buffer.drawLimit.x2, y2 = buffer.drawLimit.y2, width = buffer.drawLimit.width, height = buffer.drawLimit.height }
end

-- Создание массивов буфера и всех необходимых параметров
function buffer.flush(width, height)
	buffer.screen = {
		current = {},
		new = {},
		width = width,
		height = height,
		tripleWidth = width * 3,
	}
	buffer.drawLimit = {}
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

-- Инициализация буфера со всеми необходимыми параметрами, вызывается автоматически
function buffer.start()	
	buffer.flush(gpu.getResolution())
end

-- Изменение разрешения экрана и пересоздание массивов буфера
function buffer.changeResolution(width, height)
	gpu.setResolution(width, height)
	buffer.flush(width, height)
end

------------------------------------------------- Методы отрисовки -----------------------------------------------------------------

function buffer.rawSet(index, background, foreground, symbol)
	buffer.screen.new[index], buffer.screen.new[index + 1], buffer.screen.new[index + 2] = background, foreground, symbol
end

function buffer.rawGet(index)
	return buffer.screen.new[index], buffer.screen.new[index + 1], buffer.screen.new[index + 2]
end

-- Получить информацию о пикселе из буфера
function buffer.get(x, y)
	local index = buffer.getBufferIndexByCoordinates(x, y)
	if x >= 1 and y >= 1 and x <= buffer.screen.width and y <= buffer.screen.height then
		return buffer.rawGet(index)
	else
		return 0x000000, 0x000000, " "
	end
end

-- Установить пиксель в буфере
function buffer.set(x, y, background, foreground, symbol)
	local index = buffer.getBufferIndexByCoordinates(x, y)
	if x >= buffer.drawLimit.x and y >= buffer.drawLimit.y and x <= buffer.drawLimit.x2 and y <= buffer.drawLimit.y2 then
		buffer.rawSet(index, background, foreground or 0x0, symbol or " ")
	end
end

--Нарисовать квадрат
function buffer.square(x, y, width, height, background, foreground, symbol, transparency) 
	if transparency then
		if transparency == 0 then
			transparency = nil
		else
			transparency = transparency * 2.55
		end
	end
	if not foreground then foreground = 0x000000 end
	if not symbol then symbol = " " end

	local index, indexStepForward, indexPlus1 = buffer.getBufferIndexByCoordinates(x, y), (buffer.screen.width - width) * 3
	for j = y, (y + height - 1) do
		for i = x, (x + width - 1) do
			if i >= buffer.drawLimit.x and j >= buffer.drawLimit.y and i <= buffer.drawLimit.x2 and j <= buffer.drawLimit.y2 then
				indexPlus1 = index + 1
				if transparency then
					buffer.screen.new[index] = colorlib.alphaBlend(buffer.screen.new[index], background, transparency)
					buffer.screen.new[indexPlus1] = colorlib.alphaBlend(buffer.screen.new[indexPlus1], background, transparency)
				else
					buffer.screen.new[index] = background
					buffer.screen.new[indexPlus1] = foreground
					buffer.screen.new[index + 2] = symbol
				end
			end
			index = index + 3
		end
		index = index + indexStepForward
	end
end
buffer.rectangle = buffer.square

--Очистка экрана, по сути более короткая запись buffer.square
function buffer.clear(color, transparency)
	buffer.square(1, 1, buffer.screen.width, buffer.screen.height, color or 0x262626, 0x000000, " ", transparency)
end

--Скопировать область изображения и вернуть ее в виде массива
function buffer.copy(x, y, width, height)
	local copyArray = {
		["width"] = width,
		["height"] = height,
	}

	if x < 1 or y < 1 or x + width - 1 > buffer.screen.width or y + height - 1 > buffer.screen.height then
		error("Область копирования выходит за пределы экрана.")
	end

	local index
	for j = y, (y + height - 1) do
		for i = x, (x + width - 1) do
			index = buffer.getBufferIndexByCoordinates(i, j)
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
			if i >= buffer.drawLimit.x and j >= buffer.drawLimit.y and i <= buffer.drawLimit.x2 and j <= buffer.drawLimit.y2 then
				--Рассчитываем индекс массива основного изображения
				index = buffer.getBufferIndexByCoordinates(i, j)
				--Копипаст формулы, аккуратнее!
				--Рассчитываем индекс массива вставочного изображения
				arrayIndex = (copyArray.width * (j - y) + (i - x + 1)) * 3 - 2
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
	if transparency then
		if transparency == 0 then
			transparency = nil
		else
			transparency = transparency * 2.55
		end
	end

	local index, sText = buffer.getBufferIndexByCoordinates(x, y), unicode.len(text)
	for i = 1, sText do
		if x >= buffer.drawLimit.x and y >= buffer.drawLimit.y and x <= buffer.drawLimit.x2 and y <= buffer.drawLimit.y2 then
			buffer.screen.new[index + 1] = not transparency and color or colorlib.alphaBlend(buffer.screen.new[index], color, transparency)
			buffer.screen.new[index + 2] = unicode.sub(text, i, i)
		end
		index = index + 3
		x = x + 1
	end
end

-- Отрисовка изображения
function buffer.image(x, y, picture)
	local xPos, xEnd, bufferIndexStepOnReachOfImageWidth = x, x + picture.width - 1, (buffer.screen.width - picture.width) * 3
	local bufferIndex = buffer.getBufferIndexByCoordinates(x, y)
	local imageIndexPlus2, imageIndexPlus3

	for imageIndex = 1, #picture, 4 do
		if xPos >= buffer.drawLimit.x and y >= buffer.drawLimit.y and xPos <= buffer.drawLimit.x2 and y <= buffer.drawLimit.y2 then
			imageIndexPlus2, imageIndexPlus3 = imageIndex + 2, imageIndex + 3
			-- Ебля с прозрачностью
			if picture[imageIndexPlus2] == 0x00 then
				buffer.screen.new[bufferIndex] = picture[imageIndex]
				buffer.screen.new[bufferIndex + 1] = picture[imageIndex + 1]
				buffer.screen.new[bufferIndex + 2] = picture[imageIndexPlus3]
			elseif picture[imageIndexPlus2] > 0x00 and picture[imageIndexPlus2] < 0xFF then
				buffer.screen.new[bufferIndex] = colorlib.alphaBlend(buffer.screen.new[bufferIndex], picture[imageIndex], picture[imageIndexPlus2])
				buffer.screen.new[bufferIndex + 1] = picture[imageIndex + 1]
				buffer.screen.new[bufferIndex + 2] = picture[imageIndexPlus3]
			elseif picture[imageIndexPlus2] == 0xFF and picture[imageIndexPlus3] ~= " " then
				buffer.screen.new[bufferIndex + 1] = picture[imageIndex + 1]
				buffer.screen.new[bufferIndex + 2] = picture[imageIndexPlus3]
			end
		end

		--Корректируем координаты и индексы
		xPos = xPos + 1
		bufferIndex = bufferIndex + 3
		if xPos > xEnd then xPos, y, bufferIndex = x, y + 1, bufferIndex + bufferIndexStepOnReachOfImageWidth end
	end
end

-- Кнопка фиксированных размеров
function buffer.button(x, y, width, height, background, foreground, text)
	local textLength = unicode.len(text)
	if textLength > width - 2 then text = unicode.sub(text, 1, width - 2) end
	
	local textPosX = math.floor(x + width / 2 - textLength / 2)
	local textPosY = math.floor(y + height / 2)
	buffer.square(x, y, width, height, background, foreground, " ")
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
	local sizeOfScrollBar = math.ceil(height / countOfAllElements)
	local displayBarFrom = math.floor(y + height * ((currentElement - 1) / countOfAllElements))

	buffer.square(x, y, width, height, backColor, 0xFFFFFF, " ")
	buffer.square(x, displayBarFrom, width, sizeOfScrollBar, frontColor, 0xFFFFFF, " ")

	sizeOfScrollBar, displayBarFrom = nil, nil
end

function buffer.horizontalScrollBar(x, y, width, countOfAllElements, currentElement, background, foreground)
	local pipeSize = math.ceil(width / countOfAllElements)
	local displayBarFrom = math.floor(x + width * ((currentElement - 1) / countOfAllElements))

	buffer.text(x, y, background, string.rep("▄", width))
	buffer.text(displayBarFrom, y, foreground, string.rep("▄", pipeSize))
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
	local stringUp, stringDown, x2 = "┌" .. string.rep("─", width - 2) .. "┐", "└" .. string.rep("─", width - 2) .. "┘", x + width - 1
	buffer.text(x, y, color, stringUp); y = y + 1
	for i = 1, (height - 2) do
		buffer.text(x, y, color, "│")
		buffer.text(x2, y, color, "│")
		y = y + 1
	end
	buffer.text(x, y, color, stringDown)
end

-- Кнопка в виде текста в рамке
function buffer.framedButton(x, y, width, height, backColor, buttonColor, text)
	buffer.square(x, y, width, height, backColor, buttonColor, " ")
	buffer.frame(x, y, width, height, buttonColor)
	
	x = math.floor(x + width / 2 - unicode.len(text) / 2)
	y = math.floor(y + height / 2)

	buffer.text(x, y, buttonColor, text)
end

------------------------------------------- Semipixel methods ------------------------------------------------------------------------

function buffer.semiPixelRawSet(index, color, yPercentTwoEqualsZero)
	local upperPixel, lowerPixel, bothPixel, indexPlus1, indexPlus2 = "▀", "▄", " ", index + 1, index + 2
	local background, foreground, symbol = buffer.screen.new[index], buffer.screen.new[indexPlus1], buffer.screen.new[indexPlus2]

	if yPercentTwoEqualsZero then
		if symbol == upperPixel then
			if color == foreground then
				buffer.screen.new[index], buffer.screen.new[indexPlus2] = color, bothPixel
			else
				buffer.screen.new[index] = color
			end
		else
			buffer.screen.new[indexPlus1], buffer.screen.new[indexPlus2] = color, lowerPixel
		end
	else
		if symbol == lowerPixel then
			if color == foreground then
				buffer.screen.new[index], buffer.screen.new[indexPlus2] = color, bothPixel
			else
				buffer.screen.new[index] = color
			end
		else
			buffer.screen.new[index], buffer.screen.new[indexPlus1], buffer.screen.new[indexPlus2] = background, color, upperPixel
		end
	end
end

function buffer.semiPixelSet(x, y, color)
	local yFixed = math.ceil(y / 2)
	if x >= buffer.drawLimit.x and yFixed >= buffer.drawLimit.y and x <= buffer.drawLimit.x2 and yFixed <= buffer.drawLimit.y2 then
		buffer.semiPixelRawSet(buffer.getBufferIndexByCoordinates(x, yFixed), color, y % 2 == 0)
	end
end

function buffer.semiPixelSquare(x, y, width, height, color)
	-- for j = y, y + height - 1 do for i = x, x + width - 1 do buffer.semiPixelSet(i, j, color) end end
	local index, indexStepForward, indexStepBackward, jPercentTwoEqualsZero, jFixed = buffer.getBufferIndexByCoordinates(x, math.ceil(y / 2)), (buffer.screen.width - width) * 3, width * 3
	for j = y, y + height - 1 do
		jPercentTwoEqualsZero = j % 2 == 0
		
		for i = x, x + width - 1 do
			jFixed = math.ceil(j / 2)
			-- if x >= buffer.drawLimit.x and jFixed >= buffer.drawLimit.y and x <= buffer.drawLimit.x2 and jFixed <= buffer.drawLimit.y2 then
				buffer.semiPixelRawSet(index, color, jPercentTwoEqualsZero)
			-- end
			index = index + 3
		end

		if jPercentTwoEqualsZero then
			index = index + indexStepForward
		else
			index = index - indexStepBackward
		end
	end
end

function buffer.semiPixelLine(x1, y1, x2, y2, color)
	local incycleValueFrom, incycleValueTo, outcycleValueFrom, outcycleValueTo, isReversed, incycleValueDelta, outcycleValueDelta = x1, x2, y1, y2, false, math.abs(x2 - x1), math.abs(y2 - y1)
	if incycleValueDelta < outcycleValueDelta then
		incycleValueFrom, incycleValueTo, outcycleValueFrom, outcycleValueTo, isReversed, incycleValueDelta, outcycleValueDelta = y1, y2, x1, x2, true, outcycleValueDelta, incycleValueDelta
	end

	if outcycleValueFrom > outcycleValueTo then
		outcycleValueFrom, outcycleValueTo = swap(outcycleValueFrom, outcycleValueTo)
		incycleValueFrom, incycleValueTo = swap(incycleValueFrom, incycleValueTo)
	end

	local outcycleValue, outcycleValueCounter, outcycleValueTriggerIncrement = outcycleValueFrom, 1, incycleValueDelta / outcycleValueDelta
	local outcycleValueTrigger = outcycleValueTriggerIncrement
	for incycleValue = incycleValueFrom, incycleValueTo, incycleValueFrom < incycleValueTo and 1 or -1 do
		if isReversed then
			buffer.semiPixelSet(outcycleValue, incycleValue, color)
		else
			buffer.semiPixelSet(incycleValue, outcycleValue, color)
		end

		outcycleValueCounter = outcycleValueCounter + 1
		if outcycleValueCounter > outcycleValueTrigger then
			outcycleValue, outcycleValueTrigger = outcycleValue + 1, outcycleValueTrigger + outcycleValueTriggerIncrement
		end
	end
end

----------------------------------------- Bezier curve -----------------------------------------

local function getPointTimedPosition(firstPoint, secondPoint, time)
	return {
		x = firstPoint.x + (secondPoint.x - firstPoint.x) * time,
		y = firstPoint.y + (secondPoint.y - firstPoint.y) * time
	}
end

local function getConnectionPoints(points, time)
	local connectionPoints = {}
	for point = 1, #points - 1 do
		table.insert(connectionPoints, getPointTimedPosition(points[point], points[point + 1], time))
	end
	return connectionPoints
end

local function getMainPointPosition(points, time)
	if #points > 1 then
		return getMainPointPosition(getConnectionPoints(points, time), time)
	else
		return points[1]
	end
end

function buffer.bezierCurve(points, color, precision)
	local linePoints = {}
	for time = 0, 1, precision or 0.01 do
		table.insert(linePoints, getMainPointPosition(points, time))
	end
	
	for point = 1, #linePoints - 1 do
		buffer.semiPixelLine(math.floor(linePoints[point].x), math.floor(linePoints[point].y), math.floor(linePoints[point + 1].x), math.floor(linePoints[point + 1].y), color)
	end
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
	local somethingIsChanged, index, indexPlus1, indexPlus2, sameCharArray
	--Массив третьего буфера, содержащий в себе измененные пиксели
	buffer.screen.changes, indexStepOnEveryLine = {}, (buffer.screen.width - buffer.drawLimit.width) * 3 

	index = buffer.getBufferIndexByCoordinates(buffer.drawLimit.x, buffer.drawLimit.y)
	for y = buffer.drawLimit.y, buffer.drawLimit.y2 do
		local x = buffer.drawLimit.x
		while x <= buffer.drawLimit.x2 do
			--Чутка оптимизируем рассчеты
			indexPlus1, indexPlus2 = index + 1, index + 2
			--Получаем изменения и применяем их
			somethingIsChanged = buffer.calculateDifference(index)
			--Если хоть что-то изменилось, то начинаем работу
			if somethingIsChanged or force then
				--Оптимизация by Krutoy, создаем массив, в который заносим чарсы. Работает быстрее, чем конкатенейт строк
				sameCharArray = { buffer.screen.current[indexPlus2] }
				--Загоняем в наш чарс-массив одинаковые пиксели справа, если таковые имеются
				local xCharCheck, indexCharCheck = x + 1, index + 3
				while xCharCheck <= buffer.drawLimit.x2 do
					indexCharCheckPlus2 = indexCharCheck + 2
					if	
						buffer.screen.current[index] == buffer.screen.new[indexCharCheck]
						and
						(
						buffer.screen.new[indexCharCheckPlus2] == " "
						or
						buffer.screen.current[indexPlus1] == buffer.screen.new[indexCharCheck + 1]
						)
					then
					 	buffer.calculateDifference(indexCharCheck)
					 	table.insert(sameCharArray, buffer.screen.current[indexCharCheckPlus2])
					else
						break
					end

					indexCharCheck = indexCharCheck + 3
					xCharCheck = xCharCheck + 1
				end

				--Заполняем третий буфер полученными данными
				buffer.screen.changes[buffer.screen.current[indexPlus1]] = buffer.screen.changes[buffer.screen.current[indexPlus1]] or {}
				buffer.screen.changes[buffer.screen.current[indexPlus1]][buffer.screen.current[index]] = buffer.screen.changes[buffer.screen.current[indexPlus1]][buffer.screen.current[index]] or {}
				
				table.insert(buffer.screen.changes[buffer.screen.current[indexPlus1]][buffer.screen.current[index]], x)
				table.insert(buffer.screen.changes[buffer.screen.current[indexPlus1]][buffer.screen.current[index]], y)
				table.insert(buffer.screen.changes[buffer.screen.current[indexPlus1]][buffer.screen.current[index]], table.concat(sameCharArray))
			
				--Смещаемся по иксу вправо
				index = index + #sameCharArray * 3 - 3
				x = x + #sameCharArray - 1
			end

			index = index + 3
			x = x + 1
		end

		index = index + indexStepOnEveryLine
	end

	--Сбрасываем переменные на невозможное значение цвета, чтобы не багнуло
	local currentBackground, currentForeground = -math.huge, -math.huge

	--Перебираем все цвета текста и фона, выполняя гпу-операции
	for foreground in pairs(buffer.screen.changes) do
		if currentForeground ~= foreground then gpu.setForeground(foreground); currentForeground = foreground end
		for background in pairs(buffer.screen.changes[foreground]) do
			if currentBackground ~= background then gpu.setBackground(background); currentBackground = background end
			for i = 1, #buffer.screen.changes[foreground][background], 3 do
				gpu.set(buffer.screen.changes[foreground][background][i], buffer.screen.changes[foreground][background][i + 1], buffer.screen.changes[foreground][background][i + 2])
			end
		end
	end

	--Очищаем память, ибо на кой хер нам хранить третий буфер
	buffer.screen.changes = nil
end

------------------------------------------------------------------------------------------------------

buffer.start()

-- buffer.clear(0xFF8888)
-- buffer.bezierCurve({
-- 	-- { x = 32, y = 2},
-- 	-- { x = 2, y = 2},
-- 	-- { x = 2, y = 98},
-- 	-- { x = 98, y = 98},
-- 	{ x = 10, y = 80 },
-- 	{ x = 2, y = 4 },
-- 	{ x = 110, y = 4 },
-- 	{ x = 130, y = 70 },
-- 	{ x = 150, y = 10 },
-- }, 0x0, 0.005)
-- buffer.draw()

-- ecs.prepareToExit()
-- buffer.clear(0xFF8888)

-- -- buffer.square(2, 2, 10, 5, 0xFFFFFF, 0x000000, " ")
-- -- buffer.square(5, 4, 10, 5, 0x000000, 0x000000, " ")
-- -- buffer.square(20, 4, 10, 5, 0xAAAAAA, 0x000000, " ")

-- buffer.semiPixelSquare(3, 3, 30, 30, 0x880088)

-- buffer.draw()

------------------------------------------------------------------------------------------------------

return buffer













