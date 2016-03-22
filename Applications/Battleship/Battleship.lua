--Реквайрики
local g = require("component").gpu
local term = require("term")
local event = require("event")

local colors = {
	white = 0xffffff,
	orange = 0xF2B233,
	magenta = 0xE57FD8,
	lightBlue = 0x99B2F2,
	yellow = 0xDEDE6C,
	lime = 0x7FCC19,
	pink = 0xF2B2CC,
	gray = 0x4C4C4C,
	lightGray = 0x999999,
	cyan = 0x4C99B2,
	purple = 0xB266E5,
	blue = 0x3366CC,
	brown = 0x7F664C,
	green = 0x57A64E,
	red = 0xCC4C4C,
    black = 0x000000,
}


--Настройка экрана
local w, h = 46, 14
g.setResolution(w,h)

--Аргументы
args = {...}

--Очищаем экран
g.setBackground(colors.lightGray)
term.clear()

--Переменные для кораблей
local ships =  {{3, 3, 8},
		{3, 5, 6},
		{11, 5, 6},
		{3, 7, 4},
		{9, 7, 4},
		{15, 7, 4},
		{3, 9, 2},
		{7, 9, 2},
		{11, 9, 2},
		{15, 9, 2}}
local shipsE = {{0, 0, 8},
		{0, 0, 6},
		{0, 0, 6},
		{0, 0, 4},
		{0, 0, 4},
		{0, 0, 4},
		{0, 0, 2},
		{0, 0, 2},
		{0, 0, 2},
		{0, 0, 2}}

--Переменные попаданий
local shots = 0
local shotsE = {{0, 0}}
local shotsE2 = 0

--Пишем заголовок
g.setBackground(colors.gray)
g.fill(1,1,w,1," ")
term.setCursor(math.floor(w/2-6),1)
g.setForeground(colors.white)
term.write("Морской Бой")
g.setBackground(colors.black)
term.setCursor(w-3,1)
term.write("   ")

--Функция определения координаты для поля
function makePixelX(x, b)
	return b+math.floor((x-b)/2)*2
end

--Рисуем кораблики
function drawShips()
	for i=1,10 do
		g.setBackground(colors.brown)
		g.fill(ships[i][1], ships[i][2], ships[i][3], 1, " ")
	end
end

--Автоматически установить кораблики
function setShipsAuto(var)
	local s = ships
	if var ~= 25 then
		s = shipsE	
	end
	for i=1,10 do
		local x, y = 0, 0
		local yes = true
		while yes do
			x = math.random(var, var+19)
			y = math.random(3, 12)
			if x+s[i][3]-1 < var+20 then
				for j=1,10 do
					if i ~= j and (x < s[j][1]+s[j][3]+2 and x+s[i][3] > s[j][1]-2 and y > s[j][2]-2 and y < s[j][2]+2) then
						x = math.random(var, var+19)
						y = math.random(3, 12)
						break
					elseif i ~= j and (j == 10 or (i == 10 and j == 9)) then
						s[i][1] = makePixelX(x, var)
						s[i][2] = y
						yes = false
					end
				end
			end
		end
	end
	if var == 25 then
		ships = s
	else
		shipsE = s
	end
end

--Рисуем поле
function drawField()
	g.setBackground(0xffffff)
	g.fill(25,3,20,10," ")
	g.setBackground(0xDDDDDD)
	if args[1] ~= "fast" then
		for i=1,10 do
			local delta = math.fmod(i,2)
			for j=1,5 do
				g.fill(23+4*j-2*delta, i+2, 2, 1, " ")
			end
		end
	end
end

--Рисуем поле врага
function drawFieldE()
	g.setBackground(0xffffff)
	g.fill(3,3,20,10," ")
	g.setBackground(0xDDDDDD)
	if args[1] ~= "fast" then
		for i=1,10 do
			local delta = math.fmod(i,2)
			for j=1,5 do
				g.fill(1+4*j-2*delta, i+2, 2, 1, " ")
			end
		end
	end
end

--Кнопка готово после рандома
function drawButton2()
	g.setBackground(colors.pink)
	term.setCursor(13, 11)
	term.write("  Готово  ")
end

--Кнопка рандома своих кораблей
function drawButton()
	g.setBackground(colors.lime)
	term.setCursor(3, 11)
	term.write("  Авто  ")
end

--Очищаем пустое место
function clearShipsField()
	g.setBackground(colors.lightGray)
	g.fill(3,3,22,10," ")
end

--Гуишечка
drawField()
drawShips()
drawButton()
g.setBackground(colors.lightGray)
g.setForeground(colors.black)
term.setCursor(3,13)
term.write("Установите корабли")

--Цикл для установки своих корабликов вручную
local ship = 0
local prevX = 0
local shipCoords = {0,0}
local setting = true
local playing = true
local button2 = false
while setting do
	local event, _, x, y = event.pull()
	if event == "touch" then
		if x > 2 and x < 13 and y == 11 then
			setShipsAuto(25)
			drawField()
			clearShipsField()
			drawShips()
			drawButton()
			drawButton2()
			button2 = true
		elseif button2 and x > 12 and x < 24 and y == 11 then
			setting = false
			break
		elseif x > w-4 and x < w and y == 1 then
			setting = false
			playing = false
			break
		end
	elseif event == "drag" then
		if ship == 0 then
			for i=1,10 do
				if x > ships[i][1] and x < ships[i][1]+ships[i][3] and y == ships[i][2] then
					ship = i
					shipCoords[1] = ships[i][1]
					shipCoords[2] = ships[i][2]
					break
				end
			end
		else
			ships[ship][1] = ships[ship][1] + x - prevX
			ships[ship][2] = y
			if ships[ship][1] > 2 and ships[ship][1]+ships[ship][3]-1 < 45 and y > 2 and y < 13 then
				drawField()
				clearShipsField()
				drawShips()
				drawButton()
			end
		end
		prevX = x
	elseif event == "drop" then
		if ship > 0 then
			if ships[ship][1] < 25 or ships[ship][1]+ships[ship][3]-1 > 45 or y < 3 or y > 13then
				ships[ship][1] = shipCoords[1]
				ships[ship][2] = shipCoords[2]
			end
			for i=1,10 do
				if i ~= ship and (ships[ship][1] < ships[i][1]+ships[i][3]+1 and ships[ship][1]+ships[ship][3]-1 > ships[i][1]-2 and ships[ship][2] > ships[i][2]-2 and ships[ship][2] < ships[i][2]+2) then
					ships[ship][1] = shipCoords[1]
					ships[ship][2] = shipCoords[2]
					break
				end
			end
			ships[ship][1] = makePixelX(ships[ship][1], 25)
		end
		ship = 0
		drawField()
		clearShipsField()
		drawShips()
		drawButton()
		for i=1,10 do
			if ships[i][1] < 25 then
				break
			elseif i == 10 then
				setting = false
				break
			end
		end
	end
end

--Следующий цикл для игры
setShipsAuto(3)
drawFieldE()
g.setBackground(colors.lightGray)
g.setForeground(colors.black)
term.setCursor(3,13)
term.write("Противник          ")
term.setCursor(25,13)
term.write("Вы")
g.setBackground(colors.magenta)
g.fill(23, 3, 2, 10, " ")
while playing do
	local event, _, x, y = event.pull()
	if event == "touch" then
		if shots < 20 and shotsE2 < 20 and x > 2 and x < 23 and y > 2 and y < 13 then
			x = makePixelX(x, 3)
			for i=1,10 do
				if x > shipsE[i][1]-1 and x < shipsE[i][1]+shipsE[i][3] and y == shipsE[i][2] then
					shots = shots + 1
					g.setBackground(colors.red)
					break
				end
				g.setBackground(colors.blue)
			end
			g.fill(x, y, 2, 1, " ")
			local yes = true
			local xE, yE = 0, 0
			while yes do
				xE = makePixelX(math.random(25,44), 3)
				yE = math.random(3,12)
				for i=1,#shotsE do
					if xE == shotsE[i][1] and yE == shotsE[i][2] then
						break
					elseif i == #shotsE then
						yes = false
						break
					end
				end
			end
			table.insert(shotsE, {makePixelX(xE, 3), yE})
			if args[2] ~= "notime" then
				g.setBackground(colors.purple)
				g.fill(23, 3, 2, 10, " ")
				os.sleep(math.floor(math.random(2))-0.5)
				g.setBackground(colors.magenta)
				g.fill(23, 3, 2, 10, " ")
			end
			for i=1,10 do
				if xE > ships[i][1]-1 and xE < ships[i][1]+ships[i][3] and yE == ships[i][2] then
					shotsE2 = shotsE2 + 1
					g.setBackground(colors.red)
					break
				end
				g.setBackground(colors.blue)
			end
			g.fill(xE, yE, 2, 1, " ")
			if shots == 20 or shotsE2 == 20 then
				g.setBackground(colors.lightGray)
				g.fill(2, 3, 43, 12, " ")
				g.setBackground(colors.white)
				g.fill(15, 5, 16, 3, " ")
				
				if shots == 20 then
					term.setCursor(20, 6)
					term.write("Победа")
				elseif shotsE2 == 20 then
					term.setCursor(18, 6)
					term.write("Поражение")
				end
			end
		elseif x > w-4 and x < w and y == 1 then
			playing = false
			break
		end
	end
end

--При выходе
g.setForeground(colors.white)
g.setBackground(colors.black)
term.clear()
g.setResolution(g.maxResolution())