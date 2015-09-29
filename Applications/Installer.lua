
------------------------------------------- Библиотеки -------------------------------------------

local shell = require("shell")
local component = require("component")
local unicode = require("unicode")
local gpu = component.gpu

------------------------------------------- Переменные -------------------------------------------

--Массив с программами, которые необходимо загрузить. Первый элемент - ссылка на файл, второй - путь для сохранения файла.
local applications = {
	{ "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/lib/colorlib.lua", "lib/colorlib.lua" },
	{ "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/lib/ECSAPI.lua", "lib/ECSAPI.lua" },
	{ "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/lib/context.lua", "lib/context.lua" },
	{ "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/lib/palette.lua", "lib/palette.lua" },
	{ "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/lib/image.lua", "lib/image.lua" },
	{ "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/Applications/Photoshop/Photoshop.lua", "Photoshop.lua" },
}

--Получаем размеры монитора
local xSize, ySize = gpu.getResolution()

------------------------------------------- Функции -------------------------------------------

--Отрисовка квадрата указанного цвета
local function square(x, y, width, height, background)
	gpu.setBackground(background)
	gpu.fill(x, y, width, height, " ")
end

--Запомнить область пикселей и возвратить ее в виде массива
local function rememberOldPixels(x, y, x2, y2)
	local newPNGMassiv = { ["backgrounds"] = {} }
	newPNGMassiv.x, newPNGMassiv.y = x, y
	--Перебираем весь массив стандартного PNG-вида по высоте
	local xCounter, yCounter = 1, 1
	for j = y, y2 do
		xCounter = 1
		for i = x, x2 do
			if (i > xSize or i < 0) or (j > ySize or j < 0) then
				error("Can't remember pixel, because it's located behind the screen: x("..i.."), y("..j..") out of xSize("..xSize.."), ySize("..ySize..")\n")
			end
			local symbol, fore, back = gpu.get(i, j)
			newPNGMassiv["backgrounds"][back] = newPNGMassiv["backgrounds"][back] or {}
			newPNGMassiv["backgrounds"][back][fore] = newPNGMassiv["backgrounds"][back][fore] or {}
			table.insert(newPNGMassiv["backgrounds"][back][fore], {xCounter, yCounter, symbol} )

			xCounter = xCounter + 1
			back, fore, symbol = nil, nil, nil
		end
		yCounter = yCounter + 1
	end
	return newPNGMassiv
end

--Нарисовать запомненные ранее пиксели из массива
local function drawOldPixels(massivSudaPihay)
	--Перебираем массив с фонами
	for back, backValue in pairs(massivSudaPihay["backgrounds"]) do
		gpu.setBackground(back)
		for fore, foreValue in pairs(massivSudaPihay["backgrounds"][back]) do
			gpu.setForeground(fore)
			for pixel = 1, #massivSudaPihay["backgrounds"][back][fore] do
				if massivSudaPihay["backgrounds"][back][fore][pixel][3] ~= transparentSymbol then
					gpu.set(massivSudaPihay.x + massivSudaPihay["backgrounds"][back][fore][pixel][1] - 1, massivSudaPihay.y + massivSudaPihay["backgrounds"][back][fore][pixel][2] - 1, massivSudaPihay["backgrounds"][back][fore][pixel][3])
				end
			end
		end
	end
end

--Ограничение длины строки
local function stringLimit(mode, text, size, noDots)
	if unicode.len(text) <= size then return text end
	local length = unicode.len(text)
	if mode == "start" then
		if noDots then
			return unicode.sub(text, length - size + 1, -1)
		else
			return "…" .. unicode.sub(text, length - size + 2, -1)
		end
	else
		if noDots then
			return unicode.sub(text, 1, size)
		else
			return unicode.sub(text, 1, size - 1) .. "…"
		end
	end
end

--Шкала прогресса
local function progressBar(x, y, width, height, background, foreground, percent)
	local activeWidth = math.ceil(width * percent / 100)
	square(x, y, width, height, background)
	square(x, y, activeWidth, height, foreground)
end

--Окно загрузки
local function downloadWindow()
	--Задаем стартовые координаты
	local width, height = 60, 7
	local progressBarWidth = math.floor(width * 3 / 4)
	local x, y = math.floor(xSize / 2 - width / 2), math.floor(ySize / 2 - height / 2) + 1
	--Запоминаем старые пиксели
	local oldPixels = rememberOldPixels(x, y, x + width - 1, y + height - 1)
	--Рисуем верхний тулбар
	square(x, y, width, 1, 0xcccccc)
	local text = "Загрузка"
	local xPos, yPos = math.floor(xSize / 2 - unicode.len(text) / 2), y
	gpu.setForeground( 0x000000 )
	gpu.set(xPos, yPos, text)
	--Рисуем само окно
	square(x, y + 1, width, height - 1, 0xeeeeee)
	--Загружаем файлы и рисуем шкалу прогресса
	xPos, yPos = math.floor(xSize / 2 - progressBarWidth / 2), math.floor(ySize / 2)
	local percent = 0
	progressBar(xPos, yPos, progressBarWidth, 1, 0xcccccc, 0x3366CC, percent)
	for i = 1, #applications do
		progressBar(xPos, yPos, progressBarWidth, 1, 0xcccccc, 0x3366CC, percent)
		square(xPos, yPos + 1, progressBarWidth, 1, 0xeeeeee)
		gpu.setForeground(0x262626)
		gpu.set(xPos, yPos + 1, stringLimit("end", "Устанавливаю " .. applications[i][2], progressBarWidth))
		shell.execute("wget " .. applications[i][1] .. " " .. applications[i][2] .. " -fQ")
		percent = math.floor(100 * i / #applications)
	end
	progressBar(xPos, yPos, progressBarWidth, 1, 0xcccccc, 0x3366CC, percent)
	os.sleep(0.3)
	--Выпиливаем нарисованное окно
	drawOldPixels(oldPixels)
end

------------------------------------------- Программа -------------------------------------------

downloadWindow()








