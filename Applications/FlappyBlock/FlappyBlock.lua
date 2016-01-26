--Floppy Block v.0.2
--Автор: newbie

local term = require("term")
local event = require("event")
local computer = require("computer")
local component = require("component")
local fs = require("filesystem")
local gpu = component.gpu
local serialization = require("serialization")
local xSize, ySize = gpu.getResolution()
local width = 30
local height = 22
local startXPosPlayer = 8
local tempPosPlayer = 10
local nicknames
local records
local name
local count = 0
local tCount = 0
local colors = {
	player = 0xffea00,
	bg = 0x71c5cf,
	floor = 0xddd894,
	walls = 0x74bf2e,
	text = 0xefb607,
	button = 0x000000
}
local quit = false
local game = true
local fin = false
local function start()
	term.clear()
	gpu.setForeground(colors.player)
	gpu.set(6, 10, "Кликни чтоб начать")
	gpu.set(5, 11, "Жми кнопки чтоб жить")
	gpu.setForeground(colors.text)
	local e = {event.pull("touch")}
	name = e[6]
	computer.addUser(name)--Эту строку лучше коментить если игру ставите на личный комп
end
local function paintWall()
	local function up() --cлушалка
	if tempPosPlayer <= 2 then --проверка на удар сверху
		fin = true
		game = false
		event.ignore("key_down", up)
	end
	gpu.set(startXPosPlayer, tempPosPlayer, "  ")
	tempPosPlayer = tempPosPlayer - 1
	gpu.setBackground(colors.player)
	gpu.set(startXPosPlayer, tempPosPlayer, "  ")
	gpu.setBackground(colors.bg)
	os.sleep(0.1)
	end
	tempPosPlayer = 10
	while game do
		gpu.set(2, 3, tostring(tCount))
		--Делает нам на случайной высоте отвертие в 5 блоков
		local randomY = math.modf(math.random(2,15))
		for i = 1, 29 do
			local a = 29 - i
			gpu.setBackground(colors.walls)	
			for i=2, randomY do
				gpu.set(a, i, "  ")
			end
			for i = randomY + 5, 21 do
				gpu.set(a, i, "  ")	
			end
			local function checkWall()
				rand = randomY + 5
				if startXPosPlayer + 1 == a then  --лобовое столкновение сверху
					if randomY>= tempPosPlayer -1 then
						tempPosPlayer = 21
					end	
				elseif startXPosPlayer == a then  --удар в верхний угол задним пикселем
					if randomY>= tempPosPlayer - 1 then
						tempPosPlayer = 21
					end 
				elseif startXPosPlayer == a+1 then  --совпадение второго пикселя с задним вверху
					if randomY>= tempPosPlayer-1 then
						tempPosPlayer = 21
					end
				elseif startXPosPlayer == a+2 then  --совпадение второго пикселя с задним вверху
					if randomY>= tempPosPlayer-1 then
						tempPosPlayer = 21
					end
				end
				if startXPosPlayer + 1 == a then  --лобовое столкновение снизу
					if tempPosPlayer+1 >= rand then
						tempPosPlayer = 21
					end
				elseif startXPosPlayer  == a then --удар в нижний угол задним пикселем
					if tempPosPlayer+1 >= rand then
						tempPosPlayer = 21
					end 
				elseif startXPosPlayer == a+1 then  --совпадение второго пикселя с задним сверху
					if tempPosPlayer +1 >= rand then
						tempPosPlayer = 21
					end
				elseif startXPosPlayer == a+2 then  --совпадение второго пикселя с задним сверху
					if tempPosPlayer +1 >= rand then
						tempPosPlayer = 21
					end
				end
			end
				checkWall()
				if tempPosPlayer>=21 then --проверка на удар снизу
					fin = true
					game = false
					event.ignore("key_down", up)
					break
				end
				--отрисовка, перерисовка игрока
				gpu.setBackground(colors.bg)
				gpu.set(startXPosPlayer, tempPosPlayer, "  ")
				tempPosPlayer = tempPosPlayer + 1
				gpu.setBackground(colors.player)
				gpu.set(startXPosPlayer, tempPosPlayer, "  ")
				gpu.setBackground(colors.bg)
				os.sleep(0.2)
				event.listen("key_down", up)
				if startXPosPlayer == a then
					tCount = tCount + 1
					gpu.set(2, 3, tostring(tCount))
				end
			gpu.setBackground(colors.bg)
			for i=2, randomY do
				gpu.set(a, i, "   ")
			end
			for i = randomY + 5, 21 do
				gpu.set(a, i, "   ")
			end
			if fin then
				break
			end
		end
	end
end
local pathToRecords = "records.txt" --путь к файлу с рекордами
local function saveRecord() --Сохраняем рекорды
	local file = io.open(pathToRecords, "w")
	local array = {["nicknames"] = nicknames, ["records"] = records}
	file:write(serialization.serialize(array))
	file:close()
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
			count = records[i]
			return false
		end
	end
	return true
end
local function addPlayer()  --Создаем учетку пользователю если его нет в базе
	if checkName(name) then
		table.insert(nicknames, name)
		table.insert(records, count)
		saveRecord()
	end
end
local function gameOver() --Игра окончена
	gpu.setBackground(colors.bg)
	term.clear()
	gpu.setForeground(colors.player)
	gpu.set(10,11,"GAME OVER!")
	gpu.set(8,14,"You count:   "..tostring(tCount))
	gpu.setForeground(colors.text)
	count = 0 
	tCount = 0 
	game = true 
	fin = false
	computer.removeUser(name) --опять же коментим эту строку если комп не публичный
end
local function saveCount() --сохраняем наши заработанные очки
	for i = 1, #nicknames do
		if name == nicknames[i] then
			count = records[i]
			if tCount > count then
				records[i] = tCount
			end
		end
	end
	saveRecord()
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
function paintScene() --Рисуем сцену
	term.clear()
	gpu.setBackground(colors.floor)
	gpu.set(0,1,"                               ")
	gpu.set(0,22,"                               ")
	gpu.setBackground(colors.bg)
end
local function printRecords()  --Выводим рекорды на экран
	term.clear()
	local xPosName = 5
	local xPosRecord = 20
	local yPos = 1
	loadRecord()
		gpu.setForeground(colors.player)
		gpu.set(11,1,"Top - 15")
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
	gpu.setForeground(colors.text)
	os.sleep(10)
	floppyBlock()
end
function main()
start()
addPlayer()
paintScene()
paintWall()
saveCount()
gameOver()
os.sleep(3)
floppyBlock()
end
function floppyBlock()
	term.clear()
	event.shouldInterrupt = function() return false end --Alt+ Ctrl + C не пашет, так же на ваше усмотрение
	gpu.setResolution(width, height)
	gpu.setForeground(colors.player)
	loadRecord()
	gpu.set(9,5,"Flappy Block")
	gpu.setBackground(colors.button)
	gpu.set(12,15," Play ")
	gpu.set(11,17," Top-15 ")
	gpu.set(12,20," Quit ")
	gpu.setBackground(colors.bg)
	while true do
		local e = {event.pull("touch")}
		if e[4] == 15 then
			if e[3]>12 then
				if e[3]<18 then main() end	
			end
		elseif e[4] == 17 then
			if e[3]>11 then
				if e[3]<19 then
					sortTop()
					printRecords()
				end
			end
		elseif e[4] == 20 then
			if e[3]>12 then
				if e[3]<18 then
					if e[6] == "newbie" then --В эту строку заносим ник того кто может закрыть игру, если ненужно,
						--коментим ее
						gpu.setForeground(colors.text)
						gpu.setResolution(xSize,ySize)
						term.clear()
						quit = true
						break
					end --и тут
				end
			end
		end
	if quit then break end
		return 0
	end
end
floppyBlock()