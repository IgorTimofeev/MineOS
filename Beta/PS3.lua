
------------------------------------------------ Копирайт --------------------------------------------------------------

local copyright = [[
	
	Photoshop v3.0 (закрытая бета)

	Автор: IT
		Контакты: https://vk.com/id7799889
	Соавтор: Pornogion
		Контакты: https://vk.com/id88323331
	
]]

------------------------------------------------ Библиотеки --------------------------------------------------------------

--Не требующиеся для ОС
--local ecs = require("ECSAPI")
--local fs = require("filesystem")
--local unicode = require("unicode")

--Обязательные
local colorlib = require("colorlib")
local palette = require("palette")
local event = require("event")
local gpu = component.gpu

------------------------------------------------ Переменные --------------------------------------------------------------

--Базовая цветовая схема программы
local colors = {
	toolbar = 0x535353,
	toolbarInfo = 0x3d3d3d,
	toolbarButton = 0x3d3d3d,
	toolbarButtonText = 0xeeeeee,
	drawingArea = 0x262626,
	console = 0x3d3d3d,
	consoleText = 0x999999,
	transparencyWhite = 0xffffff,
	transparencyGray = 0xcccccc,
	transparencyVariable = 0xffffff,
}

--Различные константы и размеры тулбаров и кликабельных зон
local sizes = {
	widthOfLeftBar = 6,
	widthOfRightBar = 20,
}
sizes.xSize, sizes.ySize = gpu.getResolution()
sizes.xStartOfDrawingArea = sizes.widthOfLeftBar + 1
sizes.xEndOfDrawingArea = sizes.xSize - sizes.widthOfRightBar
sizes.yStartOfDrawingArea = 2
sizes.yEndOfDrawingArea = sizes.ySize
sizes.widthOfDrawingArea = sizes.xEndOfDrawingArea - sizes.xStartOfDrawingArea + 1
sizes.heightOfDrawingArea = sizes.yEndOfDrawingArea - sizes.yStartOfDrawingArea + 1
sizes.heightOfLeftBar = sizes.ySize - 1

--Для правого тулбара
sizes.heightOfRightBar = sizes.heightOfLeftBar
sizes.xStartOfRightBar = sizes.xSize - sizes.widthOfRightBar + 1
sizes.yStartOfRightBar = 2

--Для изображения
sizes.widthOfImage = 8
sizes.heightOfImage = 4
sizes.xStartOfImage = 9
sizes.yStartOfImage = 3

--Инструменты
sizes.heightOfInstrument = 3
sizes.yStartOfInstruments = 2
local instruments = {
	{"⮜", "Move"},
	{"✄", "Crop"},
	{"✎", "Brush"},
	{"❎", "Eraser"},
	{"Ⓣ", "Text"},
}
local currentInstrument = 1

--Верхний тулбар
local topToolbar = {{"PS", 0xaaaaff}, {"Файл"}, {"Изображение"}, {"Инструменты"}, {"Фильтры"}}

------------------------------------------------ Функции отрисовки --------------------------------------------------------------

local function drawTransparentPixel(xPos, yPos, i, j)
	if j % 2 == 0 then
		if i % 2 == 0 then
			colors.transparencyVariable = colors.transparencyWhite
		else
			colors.transparencyVariable = colors.transparencyGray
		end
	else
		if i % 2 == 0 then
			colors.transparencyVariable = colors.transparencyGray
		else
			colors.transparencyVariable = colors.transparencyWhite
		end
	end

	gpu.setBackground(colors.transparencyVariable)
	gpu.set(xPos, yPos, " ")
end

local function drawBackground()
	ecs.square(sizes.xStartOfDrawingArea, sizes.yStartOfDrawingArea, sizes.widthOfDrawingArea, sizes.heightOfDrawingArea, colors.drawingArea)
end

local function drawTransparency()
	local xPos, yPos = sizes.xStartOfImage, sizes.yStartOfImage

	for j = 1, sizes.heightOfImage do
		for i = 1, sizes.widthOfImage, 1 do
			--Если пиксель в зоне рисования, то рисуем этот пиксель
			if xPos >= sizes.xStartOfDrawingArea and xPos <= sizes.xEndOfDrawingArea and yPos >= sizes.yStartOfDrawingArea and yPos <= sizes.yEndOfDrawingArea then
				--Рисуем пиксель прозрачности
				drawTransparentPixel(xPos, yPos, i, j)
			end
			xPos = xPos + 1
		end
		xPos = sizes.xStartOfImage
		yPos = yPos + 1
	end
end

local function drawInstruments()
	local yPos = sizes.yStartOfInstruments
	for i = 1, #instruments do
		if currentInstrument == i then
			ecs.square(1, yPos, sizes.widthOfLeftBar, sizes.heightOfInstrument, colors.toolbarButton)
		else
			ecs.square(1, yPos, sizes.widthOfLeftBar, sizes.heightOfInstrument, colors.toolbar)
		end
		ecs.colorText(3, yPos + 1, colors.toolbarButtonText, instruments[i][1])
		yPos = yPos + sizes.heightOfInstrument
	end
end

local function drawLeftBar()
	ecs.square(1, 2, sizes.widthOfLeftBar, sizes.heightOfLeftBar, colors.toolbar)
	drawInstruments()
end

local function drawRightBar()
	local yPos = sizes.yStartOfRightBar
	ecs.square(sizes.xStartOfRightBar, yPos, sizes.widthOfRightBar, sizes.heightOfRightBar, colors.toolbar)
	
	ecs.square(sizes.xStartOfRightBar, yPos, sizes.widthOfRightBar, 1, colors.toolbarInfo)
	ecs.colorText(sizes.xStartOfRightBar + 1, yPos, 0xffffff, "Параметры кисти")

	yPos = yPos + 10
	ecs.square(sizes.xStartOfRightBar, yPos, sizes.widthOfRightBar, 1, colors.toolbarInfo)
	ecs.colorText(sizes.xStartOfRightBar + 1, yPos, 0xffffff, "Слои")
end

local function drawTopBar()
	ecs.square(1, 1, sizes.xSize, 1, colors.toolbar)
	local xPos = 3
	local spaceBetween = 2

	for i = 1, #topToolbar do
		ecs.colorText(xPos, 1, topToolbar[i][2] or 0xffffff, topToolbar[i][1])
		xPos = xPos + unicode.len(topToolbar[i][1]) + spaceBetween
	end

end

local function drawImage()
	drawBackground()
	drawTransparency()
end

local function drawAll()
	ecs.prepareToExit()
	drawBackground()
	drawLeftBar()
	drawRightBar()
	drawTopBar()
	drawImage()
end

------------------------------------------------ Функции расчета --------------------------------------------------------------

local function move(direction)
	if direction == "up" then
		sizes.yStartOfImage = sizes.yStartOfImage - 2
	elseif direction == "down" then
		sizes.yStartOfImage = sizes.yStartOfImage + 2
	elseif direction == "left" then
		sizes.xStartOfImage = sizes.xStartOfImage - 2
	elseif direction == "right" then
		sizes.xStartOfImage = sizes.xStartOfImage + 2
	end

	drawImage()
end

------------------------------------------------ Старт программы --------------------------------------------------------------

drawAll()

while true do
	local e = {event.pull()}
	if e[1] == "key_down" then
		if e[4] == 200 then
			move("up")
		elseif e[4] == 208 then
			move("down")
		elseif e[4] == 203 then
			move("left")
		elseif e[4] == 205 then
			move("right")
		end
	end
end

------------------------------------------------ Выход из программы --------------------------------------------------------------




