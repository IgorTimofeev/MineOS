local component = require("component")
local term = require("term")
local unicode = require("unicode")
local event = require("event")
local fs = require("filesystem")
local ecs = require("ECSAPI")
local gpu = component.gpu

------------------------------------------------------------------------------------------------------------------------

local arg = {...}

local crossword = {}
local keyWords = {}
local keyWordsColors = {}

local temporaryWordTrace = {}
local globalWordTrace = {}

------------------------------------------------------------------------------------------------------------------------

local function readFile(path)
	--ЧИТАЕМ И ЗАПОЛНЯЕМ МАССИВ
	local lines = {}
	local f = io.open(path, "r")
	while true do
		local line = f:read("*l")
		if line then
			table.insert(lines, unicode.upper(line))
		else
			break
		end
	end
	f:close()

	return lines
end


local function getCrosswordFromFile(pathToCrossword)

	--ЧИТАЕМ ФАЙЛ КРОССВОРДА
	local readedCrossword = readFile(pathToCrossword)

	--ЕСЛИ ПЕРВАЯ ФРАЗА В ФАЙЛЕ НЕ РАВНА НУЖНОЙ, ТО КИНУТЬ ОШИБКУ, А ТО МАЛО ЛИ
	if readedCrossword[1] ~= "--КРОССВОРД" then ecs.error("Ошибка чтения файла кроссворда: скорее всего, он хуево составлен. Давай заново.") end

	--ПАРСИМ КРОССВОРД НА БУКОВКИ
	local keyWordsStarted = false
	for i = 2, #readedCrossword do
		--ЕСЛИ НАЙДЕНА ФРАЗА НУЖНАЯ, ТО ВКЛЮЧИТЬ РЕЖИМ ЧТЕНИЯ КЛЮЧЕВЫХ СЛОВ
		if readedCrossword[i] == "--КЛЮЧЕВЫЕ СЛОВА" then
			keyWordsStarted = true
		end
		--ВЫБОР МЕЖДУ РЕЖИМАМИ КРОССВОРДА И КЛЮЧЕВЫХ СЛОВ
		if not keyWordsStarted then
			local position = #crossword + 1
			crossword[position] = {}
			for j = 1, unicode.len( readedCrossword[i] ) do
				crossword[position][j] = { unicode.sub(readedCrossword[i], j, j) }
			end
		else
			local yPos = i + 1
			if readedCrossword[yPos] then
				local position = #keyWords + 1
				keyWords[position] = {}
				for j = 1, unicode.len( readedCrossword[yPos] ) do
					table.insert( keyWords[position], unicode.sub(readedCrossword[yPos], j, j) )
				end
			else
				break
			end
		end
	end


end

local function drawCrossword(x, y, background, foreground, xSpaceBetween, ySpaceBetween)

	--ЗАДАНИЕ СТАРТОВЫХ АРГУМЕНТОВ, А ТО МАЛО ЛИ ЧЁ
	x = x or 1
	y = y or 1

	background = background or 0xffffff
	foreground = foreground or 0x000000

	local barsColor = 0xaaaaaa
	local barsTextColor = 0xffffff

	xSpaceBetween = 3
	ySpaceBetween = 1

	--КОРРЕКЦИЯ КООРДИНАТ
	local xPos = x
	local yPos = y

	--РИСУЕМ РЯДЫ
	ecs.square(xPos, yPos, xSpaceBetween + #crossword[1] + xSpaceBetween * #crossword[1] - 1, 1, barsColor)
	ecs.square(xPos, yPos, 2, ySpaceBetween + #crossword + ySpaceBetween * #crossword, barsColor)

	xPos = x + xSpaceBetween + 1
	yPos = yPos + ySpaceBetween + 1

	--РИСУЕМ САМ КРОССВОРД

	for i = 1, #crossword do

		for j = 1, #crossword[i] do
			local cvet1 = background
			local cvet2 = foreground
			if crossword[i][j][2] then
				cvet1 = crossword[i][j][2]
				cvet2 = 0xffffff - cvet1
			end

			gpu.setBackground(cvet1)
			gpu.setForeground(cvet2)

			gpu.set(xPos, yPos, crossword[i][j][1])

			--РИСУЕМ ТЕКСТ НА ПОЛОСОЧКАХ С НОМЕРАМИ
			gpu.setForeground(barsTextColor)
			gpu.setBackground(barsColor)

			gpu.set(xPos, y, tostring(j))
			gpu.set(x, yPos, tostring(i))

			xPos = xPos + xSpaceBetween + 1
			--event.pull("key_down")
		end
		xPos = x + xSpaceBetween + 1
		yPos = yPos + ySpaceBetween + 1
	end

	--СЛОВЕЧКИ РИСУЕМ

	gpu.setBackground(background)
	gpu.setForeground(foreground)

	--ЛИНИЮ РИСУЕМ
	xPos = x + xSpaceBetween
	gpu.set(1, yPos, string.rep("-", 100))
	yPos = yPos + ySpaceBetween + 1

	for i = 1, #keyWords do

		local color1, color2 = background, foreground
		if keyWordsColors[i] then color1 = keyWordsColors[i]; color2 = 0xffffff - color1 end

		local slovo = ""
		for j = 1, #keyWords[i] do
			slovo = slovo .. keyWords[i][j]
		end

		gpu.setBackground(color1)
		gpu.setForeground(color2)

		gpu.set(xPos, yPos, slovo)
		--ecs.error("Слово = "..slovo)

		yPos = yPos + 1
	end
end

local function findWord(x, y, wordCyka, uspeh )	

	if #wordCyka <= 1 then return uspeh end

	local word = {}
	for i = 1, #wordCyka do
		word[i] = wordCyka[i]
	end

	uspeh = false

	table.remove(word, 1)

	--ecs.error("#wordCyka="..#wordCyka..", #word="..#word)

	--ecs.error("Рассматриваю х="..x..", y="..y..", word[1]="..word[1]..", xOtkuda="..xOtkuda..", yOtkuda="..yOtkuda)

	local function cyka(xMod, yMod)
		--ecs.error(word[1] .." ".. crossword[y + yMod][x + xMod][1])
		if word[1] == crossword[y + yMod][x + xMod][1] and not uspeh then
			--ecs.error("Смотрю на ("..x..","..y..","..crossword[y][x][1].."), ищу вокруг букву \""..word[1].."\", #свет="..#temporaryWordTrace)

			uspeh = true
			table.insert(temporaryWordTrace, {xMod, yMod})

			uspeh = findWord( x + xMod, y + yMod, word, uspeh )
		end
	end

	if crossword[y - 1] then cyka(0, -1) end
	if crossword[y][x + 1] then cyka(1, 0) end
	if crossword[y + 1] then cyka(0, 1) end
	if crossword[y][x - 1] then cyka(-1, 0) end

	--УБИРАЕМ ЭЛЕМЕНТИК ИЗ ПОДСВЕТКИ
	if not uspeh then temporaryWordTrace[#temporaryWordTrace] = nil end

	--ecs.error("Успех в конце = "..tostring(uspeh))
	return uspeh
end

local function trace(massivSuda)
	local nomerSlova, x, y, track = massivSuda[1], massivSuda[2], massivSuda[3], massivSuda[4]

	local color = math.random(0x000000, 0xffffff)
	--ecs.error("x="..x..", y="..y)

	keyWordsColors[nomerSlova] = color

	crossword[y][x][2] = color

	for i = 1, #track do
		x = x + track[i][1]
		y = y + track[i][2]

		crossword[y][x][2] = color
	end
end

local function reshitCrossword()
	for ySimvol = 1, #crossword do
		for xSimvol = 1, #crossword[ySimvol] do

			local yKeyWord = 1
			while yKeyWord <= #keyWords do

				--ЕСЛИ ПЕРВАЯ БУКВА КЛЮЧЕВОГО СЛОВА РАВНА СИМВОЛУ РАССМАТРИВАЕМОМУ
				if keyWords[yKeyWord][1] == crossword[ySimvol][xSimvol][1] then

					--ДУБЛИРОВАНИЕ МАССИВА, ПОТОМУШТО ТАК НУЖНО!!! ВОТ
					-- local cyka = {}
					-- for i = 1, #keyWords do
					-- 	cyka[i] = {}
					-- 	for j = 1, #keyWords[i] do
					-- 		cyka[i][j] = keyWords[i][j]
					-- 	end
					-- end

					--table.remove(cyka[yKeyWord], 1)

					--ecs.error("#cyka[yKeyWord] = "..#cyka[yKeyWord]..", #keyWords[yKeyWord] = "..#keyWords[yKeyWord])

					--yKeyWord = 3

					temporaryWordTrace = {}
					--ecs.error("Начинаю поиск слова №"..yKeyWord.." на x = "..xSimvol..", y = "..ySimvol)
					if findWord(xSimvol, ySimvol, keyWords[yKeyWord], true ) then
						

						--ecs.error("УСПЕХ! НАШЛО СЛОВО НОМЕР " .. yKeyWord .. ", его размер="..#keyWords[yKeyWord]..", #свет="..#temporaryWordTrace)

						table.insert(globalWordTrace, {yKeyWord, xSimvol, ySimvol, temporaryWordTrace})

						trace(globalWordTrace[#globalWordTrace])

						--drawCrossword(2, 2, 0xeeeeee, 0x333333, 3, 1)

						yKeyWord = yKeyWord + 1

						--event.pull("key_down")
					end

				end

				yKeyWord = yKeyWord + 1
			end
		end
	end
end


------------------------------------------------------------------------------------------------------------------------

ecs.clearScreen(0x262626)

local vvod = ecs.universalWindow("auto", "auto", 40, 0xeeeeee, true, {"EmptyLine"}, {"CenterText", 0x262626, "Путь к файлу кроссворда"}, {"Input", 0x262626, ecs.colors.green, "Crossword.app/Resources/CrosswordFile.txt"}, {"EmptyLine"}, {"Button", {ecs.colors.green, 0xffffff, "OK"}})
local pathToCrossword = vvod[1]
local mode = vvod[2]

ecs.clearScreen(0xeeeeee)
getCrosswordFromFile(pathToCrossword)
drawCrossword(2, 2, 0xeeeeee, 0x333333, 3, 1)
reshitCrossword()

event.pull("key_down")
drawCrossword(2, 2, 0xeeeeee, 0x333333, 3, 1)

os.sleep(1)
event.pull("key_down")
