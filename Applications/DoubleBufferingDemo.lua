
local buffer = require("doubleBuffering")
local event = require("event")
local image = require("image")

local currentBackground = 0x990000
local transparency = 25
local xWindow, yWindow = 5, 5

buffer.start()

--Заполним весь наш экран цветом фона 0x262626, цветом текста 0xFFFFFF и символом " "
buffer.square(1, 1, buffer.screen.width, buffer.screen.height, currentBackground, 0xFFFFFF, " ")

--Нарисуем изображение из буфера. По сути, сейчас отобразился серый экран.
buffer.draw()

--Создаем переменные с координатами начала и размерами нашего окна
local width, height = 82, 25

local cykaPicture = image.load("System/OS/Icons/Steve.pic")
local cykaPicture2 = image.load("System/OS/Icons/Love.pic")

local function drawWindow(x, y)

	--Тени
	local shadowTransparency = 60
	buffer.square(x + width, y + 1, 2, height, 0x000000, 0xFFFFFF, " ", shadowTransparency)
	buffer.square(x + 2, y + height, width - 2, 1, 0x000000, 0xFFFFFF, " ", shadowTransparency)

	--Создаем прозрачную часть окна, где отображается "Избранное"
	buffer.square(x, y, 20, height, 0xFFFFFF, 0xFFFFFF, " ", transparency)

	--Создаем непрозрачную часть окна для отображения всяких файлов и т.п.
	buffer.square(x + 20, y, width - 20, height, 0xFFFFFF, 0xFFFFFF, " ")

	--Создаем три более темных полоски вверху окна, имитируя объем
	buffer.square(x, y, width, 1, 0xDDDDDD, 0xFFFFFF, " ")
	buffer.square(x, y + 1, width, 1, 0xCCCCCC, 0xFFFFFF, " ")
	buffer.square(x, y + 2, width, 1, 0xBBBBBB, 0xFFFFFF, " ")

	--Рисуем заголовок нашего окошка
	buffer.text(x + 30, y, 0x000000, "Тестовое окно")

	--Создаем три кнопки в левом верхнем углу для закрытия, разворачивания и сворачивания окна
	buffer.set(x + 1, y, 0xDDDDDD, 0xFF4940, "⬤")
	buffer.set(x + 3, y, 0xDDDDDD, 0xFFB640, "⬤")
	buffer.set(x + 5, y, 0xDDDDDD, 0x00B640, "⬤")

	--Рисуем элементы "Избранного" чисто для демонстрации
	buffer.text(x + 1, y + 3, 0x000000, "Избранное")
	for i = 1, 6 do buffer.text(x + 2, y + 3 + i, 0x555555, "Вариант " .. i) end

	--Рисуем "Файлы" в виде желтых квадратиков. Нам без разницы, а выглядит красиво
	for j = 1, 3 do
	  for i = 1, 5 do
	    local xPos, yPos = x + 22 + i*12 - 12, y + 4 + j*7 - 7
	    buffer.square(xPos, yPos, 8, 4, 0xFFFF80, 0xFFFFFF, " ")
	    buffer.text(xPos, yPos + 5, 0x262626, "Файл " .. i .. "x" .. j)
	  end
	end

	--Ну, и наконец рисуем голубой скроллбар справа
	buffer.square(x + width - 1, y + 3, 1, height - 3, 0xBBBBBB, 0xFFFFFF, " ")
	buffer.square(x + width - 1, y + 3, 1, 4, 0x3366CC, 0xFFFFFF, " ")

	--Изображения!
	-- buffer.image(x + 23, y + 6, cykaPicture)
	-- buffer.image(x + 33, y + 12, cykaPicture2)

	xPos, yPos = x, y + height + 2
	buffer.square(xPos, yPos, width, 8, 0xFFFFFF, 0xFFFFFF, " ", transparency)
	yPos = yPos + 1
	xPos = xPos + 2
	buffer.text(xPos + 2, yPos, 0x262626, "Кликай на экран левой кнопкой, чтобы изменить позицию окошка"); yPos = yPos + 1
	buffer.text(xPos + 2, yPos, 0x262626, "Или правой кнопкой, чтобы нарисовать еще одно такое же окошко"); yPos = yPos + 1
	buffer.text(xPos + 2, yPos, 0x262626, "А еще крути колесико, чтобы изменять прозрачность"); yPos = yPos + 2
	buffer.text(xPos + 2, yPos, 0x262626, "Можешь жать пробел, чтобы сменить фон на рандомный"); yPos = yPos + 1
	buffer.text(xPos + 2, yPos, 0x262626, "Или жми энтер, чтобы выйти отсудова на хер"); yPos = yPos + 1
end

drawWindow(xWindow, yWindow)
buffer.draw()

while true do
	local e = {event.pull()}
	if e[1] == "touch" or e[1] == "drag" then
		if e[5] == 0 then
			buffer.square(1, 1, buffer.screen.width, buffer.screen.height, currentBackground, 0xFFFFFF, " ")
			xWindow, yWindow = e[3], e[4]
			drawWindow(xWindow, yWindow)
			buffer.draw()
		else
			xWindow, yWindow = e[3], e[4]
			drawWindow(xWindow, yWindow)
			buffer.draw()
		end
	elseif e[1] == "key_down" then
		if e[4] == 57 then
			currentBackground = math.random(0x000000, 0xFFFFFF)
			buffer.square(1, 1, buffer.screen.width, buffer.screen.height, currentBackground, 0xFFFFFF, " ")
			drawWindow(xWindow, yWindow)
			buffer.draw()
		elseif e[4] == 28 then
			buffer.square(1, 1, buffer.screen.width, buffer.screen.height, 0x262626, 0xFFFFFF, " ")
			buffer.draw()
			return
		end
	elseif e[1] == "scroll" then
		if e[5] == 1 then
			if transparency > 5 then
				transparency = transparency - 5
				buffer.square(1, 1, buffer.screen.width, buffer.screen.height, currentBackground, 0xFFFFFF, " ")
				drawWindow(xWindow, yWindow)
				buffer.draw()
			end
		else
			if transparency < 100 then
				transparency = transparency + 5
				buffer.square(1, 1, buffer.screen.width, buffer.screen.height, currentBackground, 0xFFFFFF, " ")
				drawWindow(xWindow, yWindow)
				buffer.draw()
			end
		end
	end
end






