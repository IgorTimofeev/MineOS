local term = require("term")
local event = require("event")
local computer = require("computer")
local component = require("component")
local unicode = require("unicode")
local fs = require("filesystem")
local gpu = component.gpu
local serialization = require("serialization")
local xSize, ySize = gpu.getResolution()
local width = 63
local height = 25
local xPosCells
local tempXPosCells
local xPosTitle
local tempXPosTitle
local yPosTitle = 8
local yPosCells = 10
local cellsXPos = {}
local title
local words = {}
local word1 = {}
local word2 = {'_','_','_','_','_','_','_','_','_'}
local score = 0
local point = 0
local heard = 5
local sameLetter = false
local noWords = false
local nicknames
local records
local name
local count
local heardPlus
local tempRandom
local record = 0
local play = true
local colors = {
	background = 0x7A8B8B,
	button = 0x00688B,
	textButton = 0xE0FFFF,
	input = 0xBBFFFF,
	cell = 0x2F4F4F,
	text = 0x000000,
	heard = 0xFF0000,
	correctLetter = 0x7CFC00,
	incorrectLetter = 0xB22222,
	defBg = 0x000000,
	defText = 0xFFFFFF
}
--Наша клавиатура где (x,y,символ, надпись на клавиатуре)
local keyboard = {
	{8, 16,"й"," Й "},
	{12, 16, "ц", " Ц "},
	{16, 16, "у", " У "},
	{20, 16 , "к", " К "},
	{24, 16, "е", " Е "},
	{28, 16, "н", " Н "},
	{32, 16, "г", " Г "},
	{36, 16, "ш", " Ш "},
	{40, 16, "щ", " Щ "},
	{44, 16, "з", " З "},
	{48, 16, "х", " Х "},
	{52, 16, "ъ", " Ъ "},
	{10, 18, "ф", " Ф "},
	{14, 18, "ы", " Ы "},
	{18, 18, "в", " В "},
	{22, 18, "а", " А "},
	{26, 18, "п", " П "},
	{30, 18, "р", " Р "},
	{34, 18, "о", " О "},
	{38, 18, "л", " Л "},
	{42, 18, "д", " Д "},
	{46, 18, "ж", " Ж "},
	{50, 18, "э", " Э "},
	{14, 20, "я", " Я "},
	{18, 20, "ч", " Ч "},
	{22, 20, "с", " С "},
	{26, 20, "м", " М "},
	{30, 20, "и", " И "},
	{34, 20, "т", " Т "},
	{38, 20, "ь", " Ь "},
	{42, 20, "б", " Б "},
	{46, 20, "ю", " Ю "}
}

local selectKey

gpu.setResolution(width, height)

local pathToWords = "words.txt"
local function loadWords() --Загружаем слова
	local bool = true
	gpu.setBackground(colors.background)
	if fs.exists(pathToWords) then
		local array = {}
		local file = io.open(pathToWords, "r")
		local str = file:read("*a")
		array = serialization.unserialize(str)
		file:close()
		words = array
	else
		if component.isAvailable("internet") then
		os.execute("pastebin get rc7qrrHA words.txt")
		term.clear()
		gpu.set(18, 12, "Загружен файл со словами!")
		os.sleep(5)
		term.clear()
		loadWords()
		else
			term.clear()
			gpu.set(4,12, "Вставьте Интернет карту или скачайте words.txt вручную.")
			gpu.set(10,13,"По ссылке http://pastebin.com/rc7qrrHA")
			gpu.setBackground(colors.button)
			gpu.setForeground(colors.textButton)
			gpu.set(4,24,"[<<Назад]")
			gpu.setBackground(colors.background)
			gpu.setForeground(colors.text)
			while bool do
				local e = {event.pull("touch")}
				if e[4] == 24 then
					if e[3]>3 and e[3]<14 then
						play = false
						noWords = true
						bool = false	
					end
				end
			end
		end
	end
end
--Берем рандомное слово
local function getRandomWord()
	local randomN = math.modf(math.random(1,#words))
	if tempRandom ~= randomN then --Проверка чтоб небыло 2 подряд
	title = words[randomN].title
	word1 = words[randomN].word
	else
		getRandomWord()
	end
	tempRandom = randomN
end

local pathToRecords = "recordsGtW.txt" --путь к файлу с рекордами
local function saveRecord() --Сохраняем рекорды
	local file = io.open(pathToRecords, "w")
	local array = {["nicknames"] = nicknames, ["records"] = records}
	file:write(serialization.serialize(array))
	file:close()
end
local function saveScore() --сохраняем наши заработанные очки
	for i = 1, #nicknames do
		if name == nicknames[i] then
			if score >= record then
				records[i] = score
			end
		end
	end
	saveRecord()
end
local function loadRecord()  --Загружаем рекорды
	if fs.exists(pathToRecords) then
		local array = {}
		local file = io.open(pathToRecords, "r")
		local str = file:read("*a")
		array = serialization.unserialize(str)
		file:close()
		nicknames = array.nicknames
		records = array.records
	else --или создаем новые дефолтные пустые таблицы
		fs.makeDirectory(fs.path(pathToRecords))
			nicknames = {}
			records = {}
			saveRecord()
	end
end
local function checkName(name)  --Проверка на наличие имени в базе
	for i =1, #nicknames do
		if name == nicknames[i] then
			record = records[i]
			return false
		end
	end
	return true
end
local function addPlayer()  --Создаем учетку пользователю если его нет в базе
	if checkName(name) then
		table.insert(nicknames, name)
		table.insert(records, record)
		saveRecord()
	end
end
local function getXPosTitle() --Получаем х позицию вопроса
	tempXPosTitle = unicode.len(title)
	tempXPosTitle = width - tempXPosTitle
	xPosTitle = math.modf(tempXPosTitle/2)
	tempXPosTitle = xPosTitle
end

local function getXPosCells() --Получаем х позицию ячеек
	tempXPosCells = #word1
	tempXPosCells = tempXPosCells*5 - 1
	tempXPosCells = width - tempXPosCells
	xPosCells = tempXPosCells/2
	tempXPosCells = xPosCells
end

getXPosCells()

local function paintMenu() --Отрисовываем меню
	gpu.setResolution(width, height)
	gpu.setBackground(colors.background)
	term.clear()
	gpu.setForeground(colors.text)
	
	gpu.set(27, 3, "Угадай-Ка")
	gpu.setForeground(colors.textButton)
	gpu.setBackground(colors.button)
	gpu.set(25, 15, "[Начать игру]")
	gpu.set(25, 17, "[Топ Лидеров]")
	gpu.set(27, 19,"[Правила]")
	gpu.set(28, 21, "[Выход]")
	gpu.setForeground(colors.text)
end

local function paintScene() --Отрисовываем игровой экран
	getXPosCells()
	getXPosTitle()
	gpu.setBackground(colors.background)
	term.clear()
	gpu.set(xPosTitle, yPosTitle, title)
	for i=1, #word1 do
		table.insert(cellsXPos, tempXPosCells)
		gpu.setBackground(colors.cell)
		gpu.setForeground(colors.text)
		gpu.set(tempXPosCells, yPosCells, "   ")
		tempXPosCells = tempXPosCells + 5
		gpu.setBackground(colors.background)
	end

	for i=1, #keyboard do
		gpu.setBackground(colors.button)
		gpu.set(keyboard[i][1], keyboard[i][2], keyboard[i][4])
		gpu.setBackground(colors.background)
	end
	local tempN = unicode.len(name)
	tempN = width - (tempN + 17)
	gpu.set(tempN,2,name.." :Текущий игрок")
	gpu.set(2,2,"Ваш рекорд: "..record)
	gpu.set(49,3, " :Ваши жизни")
	gpu.setForeground(colors.heard)
	gpu.set(44,3, "❤x"..heard)
	gpu.setForeground(colors.text)
	gpu.set(2,3,"Текущий счет: "..score)

end

local function paintRules() --Отрисовываем правила
	local bool = true
	gpu.setBackground(colors.background)
	term.clear()
	gpu.setForeground(colors.text)
	gpu.set(25,7,"Правила игры!")
	gpu.set(4,11,"        Доброго времени суток, уважаемый игрок!")
	gpu.set(4,12,"   Правила <<Угадай-Ки>> очень просты, перед вами будет")
	gpu.set(4,13,"n-количество   ячеек    за   которыми   буквы.   Сверху")
	gpu.set(4,14,"подсказка. Чтоб  выбрать букву  нажмите  ее на экранной")
	gpu.set(4,15,"клавиатуре.  Если  угадаете она  появится  в поле и  на")
	gpu.set(4,16,"ЭК станет зеленной, неугадаете красной. Есть 4  режима.")
	gpu.set(4,17,"Если не угадали букву минус жизнь. Каждое угаданное слово")
	gpu.set(4,18,"дает свое количество очков в зависимости от режима игры.")
	gpu.set(4,19,"Каждая  угаданая  подряд буква умножает очки на  кол-во")
	gpu.set(4,20,"угаданых букв подряд. Удачи в игре!!")
	gpu.setBackground(colors.button)
	gpu.setForeground(colors.textButton)
	gpu.set(4,24,"[<<Назад]")
	gpu.setBackground(colors.background)
	gpu.setForeground(colors.text)
	while bool do
		local e = {event.pull("touch")}
		if e[4] == 24 then
			if e[3]>3 and e[3]<14 then
				bool = false	
				guessTW()
			end
		end
	end
end

local function clearLine(a) --Просто отчиистка линии для сокращения кода
	term.setCursor(1,a)
	term.clearLine()
end

local function guessTheWord() --Наш алгоритм для сранения букв и работа с нимм
	local goodLetter = false
	local haveSpace = false
	local key = selectKey
	local letter = key[3]
	local tempScore
	local bool = true

	for i = 1, #word1 do
		if word1[i] == letter then
			if word1[i] ~= word2[i] then
				point = point + 1
				tempScore = point*count
				score = score + tempScore
				gpu.set(16,3, tostring(score))
				if record>=score then
					gpu.set(14,2, tostring(record))
				else
					record = score
					gpu.set(14,2, tostring(record))
				end
				goodLetter = true
				gpu.set(25,12,"Верная буква!")
			elseif word1[i] == word2[i] then
				sameLetter = true
			end
			word2[i] = letter
			gpu.setBackground(colors.cell)
			gpu.setForeground(colors.textButton)
			gpu.set(cellsXPos[i],10, key[4])
			gpu.setForeground(colors.text)
			gpu.setBackground(colors.correctLetter)
			gpu.set(key[1],key[2],key[4])
			gpu.setBackground(colors.background)
			gpu.setForeground(colors.text)
			clearLine(12)
			gpu.set(25,12,"Верная буква!")
		end
		if word2[i] == "_" then
			haveSpace = true
		end
	end

	if goodLetter then
		if not haveSpace then
			heard = heard + heardPlus
			gpu.setForeground(colors.heard)
			gpu.set(47,3,"   ")
			gpu.set(47,3, tostring(heard))
			gpu.setForeground(colors.text)
			clearLine(12)
			if heardPlus == 0 then
				gpu.set(18, 12,"Слово отгадано, продолжим?")
			elseif heardPlus == 2 then
				gpu.set(7, 12,"Слово отгадано, вы получили две жизни, продолжим?")
			else
				gpu.set(6, 12,"Слово отгадано, вы получили одну жизнь, продолжим?")
			end
			gpu.setForeground(colors.textButton)
			gpu.setBackground(colors.button)
			gpu.set(35,14,"[Далее >>]")
			gpu.set(18,14,"[Выход]")
			gpu.setForeground(colors.text)
			while bool do
				local e = {event.pull("touch")}
				if e[4] == 14 then
					if e[3]>17 and e[3]<26 then
						play = false
						bool = false
						heardScore = heard * count * point
						score = score + heardScore
						saveScore()
						score = 0
						guessTW()
						
					elseif e[3]>34 and e[3]<44 then
						bool = false
						saveScore()
						game()
						
					end
				end
			end
		end
	elseif sameLetter then
		clearLine(12)
		gpu.set(21,12,"Эта буква уже введена")
		sameLetter = false
	else
		point = 0
		clearLine(12)
		gpu.set(24,12,"Неверная буква!")
		gpu.setBackground(colors.incorrectLetter)
		gpu.set(key[1],key[2],key[4])
		gpu.setBackground(colors.background)
		heard = heard - 1
		if heard ~= 0 then
			gpu.setForeground(colors.heard)
			gpu.set(47,3,"   ")
			gpu.set(47,3, tostring(heard))
			gpu.setForeground(colors.text)
		else
			term.clear()
			gpu.set(15,11,"Игра окончена!!! Ваш счет: "..tostring(score))
			score = 0
			os.sleep(8)
			play = false
			guessTW()
		end
	end
end


local function sortTop() --Сортируем Топ игроков
	for i=1, #records do
	  for j=1, #records-1 do
	    if records[j] < records[j+1] then
	      local r = records[j+1]
	      local n = nicknames[j+1]
	      records[j+1] = records[j]
	      nicknames[j+1] = nicknames[j]
	      records[j] = r
	      nicknames[j] = n
	    end
	  end
	end
	saveRecord()
end
function printRecords()  --Выводим рекорды на экран
	local bool = true
	sortTop()
	gpu.setBackground(colors.background)
	term.clear()
	local xPosName = 15
	local xPosRecord = 40
	local yPos = 2
	loadRecord()
		gpu.setForeground(colors.text)
		gpu.set(25,2,"Toп Лидеров")
		gpu.setForeground(colors.textButton)
	if #nicknames <= 15 then
	for i = 1, #nicknames do
		yPos= yPos+1
		gpu.set(xPosName, yPos, nicknames[i] )
		gpu.set(xPosRecord, yPos, tostring(records[i]))
	end
	else
		for i = 1, 15 do
		yPos= yPos+1
		gpu.set(xPosName, yPos, nicknames[i] )
		gpu.set(xPosRecord, yPos, tostring(records[i]))
		end
	end
	gpu.setBackground(colors.button)
	gpu.set(4,24,"[<<Назад]")
	gpu.setBackground(colors.background)
	while bool do
		local e = {event.pull("touch")}
		if e[4] == 24 then
			if e[3]>3 and e[3]<14 then
				bool = false	
				guessTW()
			end
		end
	end
end

function game() --Наша игра
	cellsXPos = {}
	word2 = {'_','_','_','_','_','_','_','_','_'}
	term.clear()
	getRandomWord()
	paintScene()
	while play do
		local e = {event.pull("touch")}
		for i=1, #keyboard do
			if e[4] == keyboard[i][2] then
				if e[3] > keyboard[i][1]-1 and e[3] < keyboard[i][1]+3 then
					selectKey = keyboard[i]
					guessTheWord()
				end
			end
		end
	end
end

local function selectComplexity() --Выбор уровня сложности
	local bool = true
	gpu.setBackground(colors.background)
	term.clear()
	gpu.setBackground(colors.button)
	gpu.setForeground(colors.textButton)
	gpu.set(27,10,"[Хардкор]")
	gpu.set(27,13,"[Сложная]")
	gpu.set(27,16,"[Средняя]")
	gpu.set(28,19,"[Легко]")
	gpu.set(4,24,"[<<Назад]")
	gpu.setBackground(colors.background)
	gpu.setForeground(colors.text)
	gpu.set(22,8,"Выберите сложность:")
	gpu.set(9,11,"Всего 10 жизней на игру и за букву 100 очков!")
	gpu.set(5,14,"2 жизни в начале и за букву 50 очков, за слово жизнь!")
	gpu.set(6,17,"5 жизней в начале и за букву 10 очков, за слово жизнь!")
	gpu.set(6,20,"10 жизней в начале и за букву 2 очка, за слово 2 жизни!")

	while bool do
		local e = {event.pull("touch")}
		if e[4] == 10 then
			if e[3]>26 and e[3]<36 then
				bool = false
				heard = 10
				heardPlus = 0
				count = 100
				game()
			end
		elseif e[4] == 13 then
			if e[3]>26 and e[3]<36 then
				bool = false
				heard = 2
				heardPlus = 1
				count = 50
				game()
			end
		elseif e[4] == 16 then
			if e[3]>26 and e[3]<36 then
				bool = false
				heard = 5
				heardPlus = 1
				count = 10
				game()
			end
		elseif e[4] == 19 then
			if e[3]>27 and e[3]<35 then
				bool = false
				heard = 10
				heardPlus = 2
				count = 2
				game()
			end
		elseif e[4] == 24 then
			if e[3]>3 and e[3]<14 then
				bool = false

				guessTW()
			end
		end
	end
end


function guessTW() -- Запуск нашей игры
	record = 0
	loadRecord()
	loadWords()
	paintMenu()
	while true do
		local e = {event.pull("touch")}
		if e[4] == 15 then
			if e[3]>24 and e[3]<33 then
				if not noWords then
					name = e[6]
					addPlayer(name)
					for i = 1, #nicknames do
						if name == nicknames[i] then
							record = records[i]
						end
					end
					play = true
					point = 0
					selectComplexity()
				end
			end
		elseif e[4] == 17 then
			if e[3]>24 and e[3]<37 then
				sortTop()
				printRecords()
			end
		elseif e[4] == 19 then
			if e[3]>26 and e[3]<36 then
				paintRules()
			end
		elseif e[4] == 21 then
			if e[3]>27 and e[3]<35 then
				gpu.setForeground(colors.defText)
				gpu.setBackground(colors.defBg)
				gpu.setResolution(xSize,ySize)
				term.clear()
				quit = true
				break
			end
		end
		if quit then break end
	end
end

guessTW()