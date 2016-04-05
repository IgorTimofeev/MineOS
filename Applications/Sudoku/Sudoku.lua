
---------------------------------------------------- Библиотеки ----------------------------------------------------------------

local serialization = require("serialization")
local event = require("event")
local ecs = require("ECSAPI")
local fs = require("filesystem")
local buffer = require("doubleBuffering")
local unicode = require("unicode")
local component = require("component")

---------------------------------------------------- Константы ----------------------------------------------------------------

buffer.start()

local tablica = {}

-------------------------------------------------------------------------------------------------------------------------------

local function drawGrid(x, y)
	local gridWidth = 74
	local gridHeight = 39
	
	buffer.clear(0xFFFFFF)

	local lines = {
		"       ┃       ┃       ",
		"       ┃       ┃       ",
		"       ┃       ┃       ",
		"━━━━━━━╋━━━━━━━╋━━━━━━━",
		"       ┃       ┃       ",
		"       ┃       ┃       ",
		"       ┃       ┃       ",
		"━━━━━━━╋━━━━━━━╋━━━━━━━",
		"       ┃       ┃       ",
		"       ┃       ┃       ",
		"       ┃       ┃       ",
	}

	--Тонкие
	local xPos, yPos = x, y
	for a = 1, 3 do
		for j = 1, 3 do
			for i = 1, #lines do
				buffer.text(xPos, yPos, 0x000000, lines[i])
				yPos = yPos + 1
			end
			yPos = yPos + 1
		end
		yPos = y
		xPos = xPos + unicode.len(lines[1]) + 2
	end

	--Толстые
	--Горизонтальные
	buffer.square(x, y + (#lines + 1) - 1, (unicode.len(lines[1]) + 2) * 3, 1, 0x000000)
	buffer.square(x, y + (#lines + 1) * 2 - 1, (unicode.len(lines[1]) + 2) * 3, 1, 0x000000)
	--Вертикальные
	buffer.square(x + (unicode.len(lines[1]) + 1) - 1, y, 2, (#lines + 1) * 3, 0x000000)
	buffer.square(x + (unicode.len(lines[1]) * 2 + 3 ) - 1, y, 2, (#lines + 1) * 3, 0x000000)

	--Значения
	yPos = y
	for j = 1, #tablica do
		xPos = x + 1
		
		for i = 1, #tablica[j] do
			if i == 4 or i == 7 then xPos = xPos + 1 end
			
			if tablica[j][i].value then
				buffer.set(xPos + 2, yPos + 1, 0xFFFFFF, 0x000000, tostring(tablica[j][i].value))
			elseif tablica[j][i].possibleValues and #tablica[j][i].possibleValues > 0 then
				local xPossible, yPossible = xPos, yPos
				for a = 1, #tablica[j][i].possibleValues do
					local background, foreground = 0xFFFFFF, 0xAAAAAA
					if #tablica[j][i].possibleValues == 1 then background = 0x88FF88; foreground = 0x000000 end
					buffer.set(xPossible, yPossible, background, foreground, tablica[j][i].possibleValues[a])
					xPossible = xPossible + 2
					if a % 3 == 0 then xPossible = xPos; yPossible = yPossible + 1 end
				end
			end
			
			xPos = xPos + 8
		end
		
		yPos = yPos + 4
	end

	buffer.draw()
end

local function checkCellValue(xCell, yCell, requestedValue)
	if tablica[yCell][xCell].value and tablica[yCell][xCell].value == requestedValue then
		return false
	end
	return true
end

local function checkCellForRules(xCell, yCell, requestedValue)
	--Чекаем горизонтально, включая эту же ячейку
	for i = (xCell + 1), 9 do if not checkCellValue(i, yCell, requestedValue) then return false end end
	for i = 1, (xCell - 1) do if not checkCellValue(i, yCell, requestedValue) then return false end end
	
	--Вертикально
	for i = (yCell + 1), 9 do if not checkCellValue(xCell, i, requestedValue) then return false end end
	for i = 1, (yCell - 1) do if not checkCellValue(xCell, i, requestedValue) then return false end end
	
	--И вокруг
	local xFrom, yFrom = 1, 1
	if xCell >= 4 and xCell <= 6 then xFrom = 4 elseif xCell >= 7 and xCell <= 9 then xFrom = 7 end
	if yCell >= 4 and yCell <= 6 then yFrom = 4 elseif yCell >= 7 and yCell <= 9 then yFrom = 7 end
	for j = yFrom, (yFrom + 2) do
		for i = xFrom, (xFrom + 2) do
			if not checkCellValue(i, j, requestedValue) then return false end
		end
	end

	return true
end

local function clearTablica()
	tablica = {}
	for i = 1, 9 do table.insert(tablica, { {},{},{}, {},{},{}, {},{},{} }) end
end

local function generateSudoku(startCountOfNumbers)
	clearTablica()

	for i = 1, startCountOfNumbers do
		while true do
			local randomNumber = math.random(1, 9)
			local randomX = math.random(1, 9)
			local randomY = math.random(1, 9)

			if not tablica[randomY][randomX].value and checkCellForRules(randomX, randomY, randomNumber) then
				tablica[randomY][randomX].value = randomNumber
				break
			end
		end
	end
end

local function getpossibleValuesForCell(xCell, yCell)
	--Получаем невозможные числа
	local impossibleValues = {}
	--Горизонтально
	for i = 1, (xCell - 1) do if tablica[yCell][i].value then impossibleValues[tablica[yCell][i].value] = true end end
	for i = (xCell + 1), 9 do if tablica[yCell][i].value then impossibleValues[tablica[yCell][i].value] = true end end
	--Вертикально
	for i = 1, (yCell - 1) do if tablica[i][xCell].value then impossibleValues[tablica[i][xCell].value] = true end end
	for i = (yCell + 1), 9 do if tablica[i][xCell].value then impossibleValues[tablica[i][xCell].value] = true end end
	--Квадратно
	local xFrom, yFrom = 1, 1
	if xCell >= 4 and xCell <= 6 then xFrom = 4 elseif xCell >= 7 and xCell <= 9 then xFrom = 7 end
	if yCell >= 4 and yCell <= 6 then yFrom = 4 elseif yCell >= 7 and yCell <= 9 then yFrom = 7 end
	for j = yFrom, (yFrom + 2) do
		for i = xFrom, (xFrom + 2) do
			if tablica[j][i].value then impossibleValues[tablica[j][i].value] = true end
		end
	end

	--А теперь берем возможные числа из невозможных
	local possibleValues = {}

	for i = 1, 9 do
		if not impossibleValues[i] then table.insert(possibleValues, i) end
	end
	
	return possibleValues
end

local function getpossibleValues()
	local countOfPossibleValues = 0
	for j = 1, 9 do
		for i = 1, 9 do
			if not tablica[j][i].value then
				local possibleValues = getpossibleValuesForCell(i, j)
				tablica[j][i].possibleValues = possibleValues

				countOfPossibleValues = countOfPossibleValues + #possibleValues
			end
		end
	end
	return countOfPossibleValues
end

local function loadSudokuFromFile(path)
	clearTablica()
	local file = io.open(path, "r")

	local counter = 1
	for line in file:lines() do
		if unicode.len(line) > 9 then error("Неверный файл Судоку: длина линии больше 9 символов") end
		for i = 1, 9 do
			local symbol = unicode.sub(line, i, i)
			if symbol ~= " " and not tonumber(symbol) then error("Неверный файл Судоку: символ не может быть представлен как число") end
			tablica[counter][i].value = tonumber(symbol)
		end

		counter = counter + 1
	end

	file:close()
end

local function convertSinglePossibleValuesToValues()
	for j = 1, 9 do
		for i = 1, 9 do
			if tablica[j][i].possibleValues and #tablica[j][i].possibleValues == 1 then
				tablica[j][i].value = tablica[j][i].possibleValues[1]
				tablica[j][i].possibleValues = nil
			end
		end
	end
end

local function solveEasySudoku()
	while true do
		ecs.wait()
		
		local countOfPossibleValues = getpossibleValues()
		if countOfPossibleValues <= 0 then
			drawGrid(1, 1)
			ecs.wait()
			ecs.error("Все решено!")
			buffer.clear(0x262626)
			ecs.prepareToExit() 
			break
		end

		drawGrid(1, 1)
		convertSinglePossibleValuesToValues()
	end
end

loadSudokuFromFile("testSudokuFile.txt")
drawGrid(1, 1)
solveEasySudoku()











