local component = require("component")
local event = require("event")
local term = require("term")
local unicode = require("unicode")
--local ecs = require("ECSAPI")
local fs = require("filesystem")
local context = require("context")
local colorlib = require("colorlib")
local palette = require("palette")
local computer = require("computer")
local seri = require("serialization")
local keyboard = require("keyboard")
local image = require("image")

local gpu = component.gpu

local arg = {...}

-------------------------------------ПЕРЕМЕННЫЕ------------------------------------------------------

local xSize,ySize = gpu.getResolution()

local drawImageFromX = 9
local drawImageFromY = 3

local imageWidth = 8
local imageHeight = 4

local transparentSymbol = "#"
local transparentBackground = 0xffffff
local transparentForeground = 0xcccccc

local background = 0x000000
local foreground = 0xffffff
local symbol = " "

local toolbarColor = 0x535353
local padColor = 0x262626
local shadowColor = 0x1d1d1d
local toolbarTextColor = 0xcccccc
local toolbarPressColor = 0x3d3d3d
local consoleColor1 = 0x3d3d3d
local consoleColor2 = 0x999999


local historyY = 2
local rightToolbarWidth = 18
local xRightToolbar = xSize - rightToolbarWidth + 1

local currentFile

local rightToolbarWidthTextLimit = rightToolbarWidth - 2

local currentLayer = 1
local layersY = historyY + math.floor(ySize / 2) - 2
local layersDisplayLimit = math.floor((ySize - layersY - 1) / 2)
local drawLayersFrom = 1
local layersIsVisibleSymbol = "●"
local layersIsNotVisibleSymbol = "◯"
local layersLimit = 20
--◯ ●

local currentInstrument = 2
local instruments={
	{"Pipette","P"},
	{"Brush","B"},
	{"Eraser","E"},
	{"Text","T"},
}
local topButtons = {
	{"Файл"},
	{"Инструменты"},
	{"Фильтры"},
}

local buttons = {"▲","▼","D","J","N","R"}

local consoleEnabled = true
local consoleWidth = xSize - 6 - rightToolbarWidth
local consoleText = "Программа запущена, консоль отладки включена"

local pixels = {}
local MasterPixels = {}

--------------------------------------ФУНКЦИИ-----------------------------------------------------

--ОТРИСОВКА ПОЛОСЫ ПРОКРУТКИ
function newScrollBar(x,y,height,countOfAllElements,displayingFrom,displayingTo,backColor,frontColor)
	local diapason = displayingTo - displayingFrom + 1
	local percent = diapason / countOfAllElements
	local sizeOfScrollBar = math.ceil(percent * height)
	local displayBarFrom = math.floor(y + height*(displayingFrom-1)/countOfAllElements)

	ecs.square(x,y,1,height,backColor)
	ecs.square(x,displayBarFrom,1,sizeOfScrollBar,frontColor)
end

--ОБЪЕКТЫ
local obj = {}
local function newObj(class,name,key,value)
	obj[class] = obj[class] or {}
	obj[class][name] = obj[class][name] or {}
	obj[class][name][key] = value
end

newObj("tools","imageZone","x1",drawImageFromX);newObj("tools","imageZone","x2",drawImageFromX+imageWidth-1);newObj("tools","imageZone","y1",drawImageFromY);newObj("tools","imageZone","y2",drawImageFromY+imageHeight-1)

local function clearScreen(color)
	gpu.setBackground(color)
	term.clear()
end

local function drawTransparency()
	gpu.setBackground(transparentBackground)
	gpu.setForeground(transparentForeground)
	gpu.fill(drawImageFromX,drawImageFromY,imageWidth,imageHeight,transparentSymbol)
end

local function createSampleLayer()
	local massiv = {}
	for j = 1,imageHeight do
		massiv[j] = {}
		for i = 1,imageWidth do
			massiv[j][i] = { transparentBackground, transparentForeground, transparentSymbol }
		end
	end
	return massiv
end

--ОБЪЕДИНИТЬ ВСЕ СЛОИ В ОДИН САМЫЙ ЖИРНЫЙ ПИЗДОСЛОЙ
local function mergeLayersToMasterPixels()

	local sPixels = #pixels
	MasterPixels = createSampleLayer()

	local layerCounter = sPixels
	while layerCounter >= 1 do

		if pixels[layerCounter][3] then
			for y=1,imageHeight do
				if pixels[layerCounter][2][y] then
					for x=1,imageWidth do
						if pixels[layerCounter][2][y][x] then
							MasterPixels[y][x] = {pixels[layerCounter][2][y][x][1],pixels[layerCounter][2][y][x][2],pixels[layerCounter][2][y][x][3]}
						end
					end
				end
			end
		end

		layerCounter = layerCounter - 1
	end

end

local function createMassiv()
	MasterPixels = {}
	pixels = {
		{"Слой 1",{},true}
	}
end

newObj("tools", "imageZone2", "x1", 7); newObj("tools", "imageZone2", "x2", xSize - rightToolbarWidth); newObj("tools", "imageZone2", "y1", 2); newObj("tools", "imageZone2", "y2", ySize - 1)

local function drawFromMassiv(clearScreenOrNot)

	if clearScreenOrNot then ecs.square(obj["tools"]["imageZone2"]["x1"], obj["tools"]["imageZone2"]["y1"], obj["tools"]["imageZone2"]["x2"] - obj["tools"]["imageZone2"]["x1"] + 1, obj["tools"]["imageZone2"]["y2"] - obj["tools"]["imageZone2"]["y1"] + 1, padColor) end

	obj["tools"]["imageZone"] = {}
	newObj("tools","imageZone","x1",drawImageFromX);newObj("tools","imageZone","x2",drawImageFromX+imageWidth-1);newObj("tools","imageZone","y1",drawImageFromY);newObj("tools","imageZone","y2",drawImageFromY+imageHeight-1)


	local x = drawImageFromX - 1
	local y = drawImageFromY - 1

	--[[local PLUSY = drawImageFromY + imageHeight
	local PLUSX = drawImageFromX + imageWidth]]

	mergeLayersToMasterPixels()

	for i=1,imageHeight do
		for j=1,imageWidth do

			local xOnScreen = drawImageFromX + j - 1
			local yOnScreen = drawImageFromY + i - 1

			if xOnScreen >= obj["tools"]["imageZone2"]["x1"] and xOnScreen <= obj["tools"]["imageZone2"]["x2"] and yOnScreen >= obj["tools"]["imageZone2"]["y1"] and yOnScreen <= obj["tools"]["imageZone2"]["y2"] then

				if MasterPixels[i][j][3] ~= transparentSymbol then

					--Оптимизация

					if MasterPixels[i][j][1] ~= gpu.getBackground() then
						gpu.setBackground(MasterPixels[i][j][1])
					end

					if MasterPixels[i][j][2] ~= gpu.getForeground() then
						gpu.setForeground(MasterPixels[i][j][2])
					end					

					gpu.set(x+j, y+i, MasterPixels[i][j][3])
				
				else

					if transparentBackground ~= gpu.getBackground() then
						gpu.setBackground(transparentBackground)
					end

					if transparentForeground ~= gpu.getForeground() then
						gpu.setForeground(transparentForeground)
					end					

					gpu.set(x+j, y+i, transparentSymbol)

				end

				--[[ТЕНЬ, БЛЯДЬ
				gpu.setBackground(shadowColor)

				if PLUSY <= obj["tools"]["imageZone2"]["y2"] then
					gpu.set(xOnScreen,PLUSY," ")
				end

				if PLUSX <= obj["tools"]["imageZone2"]["x2"]-1 then
					gpu.fill(PLUSX,yOnScreen,2,1," ")
				end]]
			end
		end
	end
end

local function changePixelInMassiv(x,y,layer,background,foreground,symbol)
	pixels[layer][2][y] = pixels[layer][2][y] or {}
	pixels[layer][2][y][x] = pixels[layer][2][y][x] or {}
	pixels[layer][2][y][x][1] = background
	pixels[layer][2][y][x][2] = foreground
	pixels[layer][2][y][x][3] = symbol
end

local function drawInstruments(xStart,yStart)
	for i=1,#instruments do
		local posY = yStart+i*4-4
		local cyka = toolbarColor

		if currentInstrument == i then cyka = toolbarPressColor end
		ecs.square(1,posY,6,3,cyka)
		gpu.setForeground(toolbarTextColor)
		gpu.set(xStart+1,posY+1,instruments[i][2])
		newObj("instruments",i,"x1",xStart);newObj("instruments",i,"x2",xStart+3);newObj("instruments",i,"y1",posY);newObj("instruments",i,"y2",posY+2)
	end
end

local function drawMemory()
	local totalMemory = computer.totalMemory() /  1024
	local freeMemory = computer.freeMemory() / 1024
	local usedMemory = totalMemory - freeMemory

	local stro4ka = math.ceil(usedMemory).."/"..math.floor(totalMemory).."KB"

	local posX = xRightToolbar - unicode.len(stro4ka) - 1

	ecs.colorTextWithBack(posX,ySize,consoleColor2,consoleColor1,stro4ka)
end

local function console(x,y)
	ecs.square(x,y,consoleWidth,1,consoleColor1)
	gpu.setForeground(consoleColor2)
	gpu.set(x+1,y,consoleText)

	drawMemory()
end

local function drawTopToolbar()
	ecs.square(1,1,xSize,1,toolbarColor)
	ecs.colorText(3,1,ecs.colors.lightBlue,"PS")

	local posX = 7
	local spaceBetween = 2
	gpu.setForeground(toolbarTextColor)
	for i=1,#topButtons do
		gpu.set(posX,1,topButtons[i][1])
		local length = unicode.len(topButtons[i][1])
		newObj("top",i,"x1",posX-1);newObj("top",i,"x2",posX+length);newObj("top",i,"y1",1);newObj("top",i,"y2",1);newObj("top",i,"name",topButtons[i][1])

		posX = posX + length + spaceBetween
	end
end

local function drawLeftToolbar()
	ecs.square(1,2,6,xSize,toolbarColor)

	--ЦВЕТА
	ecs.square(3,ySize-3,3,2,foreground)
	ecs.square(2,ySize-4,3,2,background)
	ecs.colorTextWithBack(3,ySize-1,toolbarTextColor,toolbarColor,"←→")

	drawInstruments(2,2)

	if consoleEnabled then console(7,ySize) end

	newObj("colors",1,"x1",2);newObj("colors",1,"x2",4);newObj("colors",1,"y1",ySize-4);newObj("colors",1,"y2",ySize-3)
	newObj("colors",2,"x1",3);newObj("colors",2,"x2",5);newObj("colors",2,"y1",ySize-2);newObj("colors",2,"y2",ySize-2)
	newObj("colors",3,"x1",5);newObj("colors",3,"x2",5);newObj("colors",3,"y1",ySize-3);newObj("colors",3,"y2",ySize-3)

	newObj("swapper",1,"x1",3);newObj("swapper",1,"x2",4);newObj("swapper",1,"y1",ySize-1);newObj("swapper",1,"y2",ySize-1)
end


newObj("layersZone",1,"x1",xRightToolbar);newObj("layersZone",1,"y1",layersY + 1);newObj("layersZone",1,"x2",xSize-1);newObj("layersZone",1,"y2",layersY + layersDisplayLimit*2+1)


--РИСОВАТЬ СЛОИ СПРАВА
local function drawLayers(from)

	obj["layers"] = {}

	local sLayers = #pixels
	local posY = layersY + 2

	local heigthOfGovno = layersDisplayLimit*2

	--СЕРАЯ ОЧИСТКА ВСЕГО СПРАВА
	ecs.square(xRightToolbar,posY,rightToolbarWidth-1,heigthOfGovno,toolbarColor)
	
	--ВЕРНОЕ ОТОБРАЖЕНИЕ СКРОЛЛБАРА, РАСЧЕТ, ДОКУДОВА ОНО БУДЕТ ЕБОШИТЬ
	local to = sLayers
	if sLayers > layersDisplayLimit then
		to = drawLayersFrom +  layersDisplayLimit - 1
	end
	newScrollBar(xSize,posY-1,heigthOfGovno+1,sLayers,drawLayersFrom,to,padColor,ecs.colors.lightBlue)

	--СОЗДАНИЕ ХОРОШИХ ПЕРЕМННЫХ, ЧТОБЫ В ЦИКЛЕ НЕ СОЗДАВАЛИСЬ ПЛЮСИКИ
	local dlyaCiklaO4istka = rightToolbarWidth - 4
	local dlyaCiklaText = xRightToolbar + 4
	local dlyaCiklaVision = xRightToolbar + 1
	local dlyaCiklaVisionPoloskaSprava = dlyaCiklaVision + 1
	local dlyaCiklaStartOfSelectionBlue = xRightToolbar+3

	--СОЗДАНИЕ РАЗДЕЛИТЕЛЯ НУЖНОЙ ДЛИНЫ ПО ТИПУ STRING.REP()
	local separatorLength = rightToolbarWidth-4 
	local separator = ""
	for i=1,separatorLength do
		separator = separator .. "─"
	end
	--ФУНКЦИЯ ОТРИСОВКИ РАЗДЕЛИТЕЛЯ
	local function drawLayersLine(y,type)
		gpu.setForeground(toolbarPressColor)	
		gpu.setBackground(toolbarColor)
		if type == "top" then
			gpu.set(xRightToolbar,y,"──┬"..separator)
		elseif type == "mid" then
			gpu.set(xRightToolbar,y,"──┼"..separator)
		else
			gpu.set(xRightToolbar,y,"──┴"..separator)
		end
	end

	drawLayersLine(posY-1,"top")

	--ОТРИСОВКА ВСЕХ СЛОЕВ СПРАВА
	local counter = 1
	for i=from,(from+layersDisplayLimit-1) do

		if pixels[i] then

			--СОЗДАНИЕ НАЗВАНИЯ СЛОЯ И ОТРИСОВКА СИНЕНЬКОГО ИЛИ НЕТ
			local stroka = ecs.stringLimit("end",pixels[i][1],separatorLength-2,true)
			if currentLayer == i then
				ecs.square( dlyaCiklaStartOfSelectionBlue, posY, dlyaCiklaO4istka, 1, ecs.colors.blue )
				ecs.colorText(dlyaCiklaText,posY,0xffffff,stroka)
			else
				gpu.setForeground(toolbarTextColor)	
				gpu.setBackground(toolbarColor)
				gpu.set(dlyaCiklaText,posY,stroka)
			end

			--ОТРИСОВКА ВИДИМОГО ИЛИ НЕВИДИМОГО ГЛАЗКА
			gpu.setBackground(toolbarPressColor)
			gpu.setForeground(toolbarTextColor)
			if pixels[i][3] then
				gpu.set(dlyaCiklaVision,posY,layersIsVisibleSymbol)
			else
				gpu.set(dlyaCiklaVision,posY,layersIsNotVisibleSymbol)
			end

			--ОТРИСОВКА РАЗДЕЛИТЕЛЕЙ ПО УСЛОВИЯМ
			if counter < sLayers and counter < layersDisplayLimit then
				drawLayersLine(posY + 1, "mid")
			else
				drawLayersLine(posY + 1, "bot")
			end
			gpu.set(dlyaCiklaVisionPoloskaSprava, posY, "│")

			--СОЗДАНИЕ ОБЪЕКТОВ
			newObj("layers",i,"x1",xRightToolbar+3);newObj("layers",i,"x2",xSize);newObj("layers",i,"y",posY)
			newObj("layerEyes",i,"x1",xRightToolbar+1);newObj("layerEyes",i,"x2",xRightToolbar+1);newObj("layerEyes",i,"y",posY)

			posY = posY + 2
			counter = counter + 1
		end

	end

	--РИСОВАНИЕ КНОПОЧЕК УПРАВЛЕНИЯ СЛОЯМИ
	obj["layerButtons"] = {}
	ecs.square(xRightToolbar, ySize, rightToolbarWidth, 1, toolbarPressColor + 0x111111)

	--ЭТО ШОБ КОД СОКРАТИТЬ, Я ЖЕ ТИПА ПРО
	local function drawLayerButton(xPos,name,good)
		if not good then
			ecs.colorText(xPos,ySize,0x000000,name)
		else
			ecs.colorText(xPos,ySize,toolbarTextColor,name)
			newObj("layerButtons",name,"x1",xPos);newObj("layerButtons",name,"x2",xPos);newObj("layerButtons",name,"y",ySize)
		end
	end

	local xPos = xRightToolbar + 1
	for i = 1, #buttons do

		if i == 1 then

			if currentLayer <= 1 then
				drawLayerButton(xPos,buttons[i],false)
			else
				drawLayerButton(xPos,buttons[i],true)
			end

		elseif i == 2 then

			if currentLayer >= sLayers then
				drawLayerButton(xPos,buttons[i],false)
			else
				drawLayerButton(xPos,buttons[i],true)
			end

		elseif i == 3 then

			drawLayerButton(xPos,buttons[i],true)

		elseif i == 4 then

			if sLayers > 1 and currentLayer < sLayers then
				drawLayerButton(xPos,buttons[i],true)
			else
				drawLayerButton(xPos,buttons[i],false)
			end

		elseif i == 5 then

			if sLayers >= layersLimit then
				drawLayerButton(xPos,buttons[i],false)
			else
				drawLayerButton(xPos,buttons[i],true)
			end

		elseif i == 6 then

			if sLayers <= 1 then
				drawLayerButton(xPos,buttons[i],false)
			else
				drawLayerButton(xPos,buttons[i],true)
			end

		end

		xPos = xPos + 3
	end


end

local function drawLayersBEZVOPROSOVCYKA()
	local sLayers = #pixels
	drawLayersFrom = sLayers - layersDisplayLimit + 1
	if sLayers < layersDisplayLimit then drawLayersFrom = 1 end
	drawLayers(drawLayersFrom)
end

local function drawRightToolbar()
	ecs.square(xRightToolbar,2,rightToolbarWidth,ySize-1,toolbarColor)

	ecs.square(xRightToolbar,historyY,rightToolbarWidth,1,toolbarPressColor)
	ecs.colorText(xRightToolbar+1,historyY,toolbarTextColor,"Тут будут пар-ры кисти")

	ecs.square(xRightToolbar,layersY,rightToolbarWidth,1,toolbarPressColor)
	ecs.colorText(xRightToolbar+1,layersY,toolbarTextColor,"Слои")

	drawLayers(drawLayersFrom)
end

local function scrollLayers(direction)
	if direction == 1 then
		drawLayersFrom = drawLayersFrom - 1
		if drawLayersFrom < 1 then
			drawLayersFrom = 1
		else
			drawLayers(drawLayersFrom)
		end
	else
		drawLayersFrom = drawLayersFrom + 1
		if drawLayersFrom + layersDisplayLimit -1 > #pixels then 
			drawLayersFrom = drawLayersFrom - 1

		else
			--ЭТО ШОБ НЕ СКРОЛЛИТЬ НИЖЕ КАРОЧ, А ТО ВЫЛЕЗЕТ И БУДЕТ 1 ЭЛЕМЕНТ ТОЛЬКА КАРОЧ	
			if drawLayersFrom > #pixels - layersDisplayLimit + 1 then
				drawLayersFrom = drawLayersFrom - 1
			end

			drawLayers(drawLayersFrom)
		end
	end
end

--ДОБАВИТЬ НОВЫЙ ЭЛЕМЕНТ В ИСТОРИЮ ЭТОГО КАЛОПРОИЗВОДСТВА
local function addElementToLayers(discription)
	table.insert(pixels, 1, {"Слой "..(#pixels+1), {}, true})

	--НУ ТУТ И ТАК ФСО ЯСНА, БЛЯДЬ
	currentLayer = 1
end

local function duplicateLayer(from)
	local hehe = {"Копия "..pixels[from][1], {}, true}
	for key,val in pairs(pixels[from][2]) do
		hehe[2][key] = val
	end

	table.insert(pixels, from, hehe)
	hehe = nil
end

local function moveLayer(from,direction)
	local hehe = {}
	for key,val in pairs(pixels[from]) do
		hehe[key] = val
	end

	if direction == "up" then
		pixels[from] = pixels[from - 1]
		pixels[from - 1] = hehe
		currentLayer = currentLayer - 1
	else
		pixels[from] = pixels[from + 1]
		pixels[from + 1] = hehe
		currentLayer = currentLayer + 1
	end

	hehe = nil

	drawFromMassiv()
end

local function joinLayer(from)
	local fromPlusOne = from + 1
	for j=1,imageHeight do
		if pixels[from][2][j] then
			for i = 1,imageWidth do
				if pixels[from][2][j][i] then
					pixels[fromPlusOne][2][j] = pixels[fromPlusOne][2][j] or {}
					pixels[fromPlusOne][2][j][i] = pixels[from][2][j][i]
				end
			end
		end
	end
	pixels[fromPlusOne][1] = pixels[from][1].." и "..pixels[fromPlusOne][1]
	table.remove(pixels,from)
end

local function deleteLayer(layer)
	table.remove(pixels,layer)
	if currentLayer > #pixels then currentLayer = #pixels end

	drawLayers(drawLayersFrom)
	drawFromMassiv()
end

local function swapColors()
	local tempColor = foreground
	foreground = background
	background = tempColor
	tempColor = nil
	consoleText = "Цвета переключены. Первичный цвет "..string.format("%x",background)..", вторичный "..string.format("%x",foreground)
	drawLeftToolbar()
end

--Сохранение изображения в нужном формате
local function save(path, format)
	mergeLayersToMasterPixels()
	image.save(path, MasterPixels)
	-- if format == ".png" then
	-- 	image.savePNG(path, MasterPixels)
	-- elseif format == ".jpg" then
	-- 	image.saveJPG(path, image.PNGtoJPG(MasterPixels))
	-- end
end

local function open(path)

	--Загружаем картинку и получаем все, что нужно о ней
	local loadedImage = image.load(path)
	local kartinka = loadedImage.image
	local format = loadedImage["format"]

	--Всякие вещи
	local loadedImageWidth
	local loadedImageHeight
	createMassiv()

	if format == ".png" then
		loadedImageHeight = #kartinka
		loadedImageWidth = #kartinka[1]
		pixels[1][2] = kartinka
	elseif format == ".jpg" then
		--local PNGKartinka = image.JPGtoPNG(kartinka)
		loadedImageHeight = #kartinka
		loadedImageWidth = #kartinka[1]
		pixels[1][2] = kartinka
	else
		ecs.error("Ошибка чтения формата файла!")
		return
	end

	imageWidth, imageHeight = loadedImageWidth, loadedImageHeight
end

--ОТРИСОВАТЬ ВАЩЕ ВСЕ ЧТО ТОЛЬКО МОЖНО
local function drawAll()
	clearScreen(padColor)
	drawLeftToolbar()
	drawTopToolbar()
	drawRightToolbar()
	drawFromMassiv()
end

--А ЭТО КАРОЧ ИЗ ЮНИКОДА В СИМВОЛ - ВРОДЕ РАБОТАЕТ, НО ВСЯКОЕ БЫВАЕТ
local function convertCodeToSymbol(code)
	local symbol = nil
	if code ~= 0 and code ~= 13 and code ~= 8  then
		symbol = unicode.char(code)
		if keyboard.isShiftPressed then symbol = unicode.upper(symbol) end
	end
	return symbol
end

--КРАСИВАЯ ШТУЧКА ДЛЯ ВВОДА ТЕКСТА
local function inputText(x,y,limit,textColor)

	textColor = textColor or background

	local oldPixels = ecs.rememberOldPixels(x,y-1,x+limit-1,y+1)

	local text = ""
	local inputPos = 1

	local function drawThisShit()
		for i=1,inputPos do
			ecs.invertedText(x + i - 1, y + 1, "─")
			ecs.adaptiveText(x + i - 1, y - 1, " ", background)
		end
		ecs.invertedText(x + inputPos - 1, y + 1, "▲")--"▲","▼"
		ecs.invertedText(x + inputPos - 1, y - 1, "▼")
		ecs.adaptiveText(x,y,ecs.stringLimit("start",text,limit,false),textColor)
	end

	drawThisShit()

	while true do
		local e = {event.pull()}
		if e[1] == "key_down" then
			if e[4] == 14 then
				if unicode.len(text) >= 1 then
					text = unicode.sub(text, 1, -2)
					if unicode.len(text) < (limit - 1) then
						inputPos = inputPos - 1
					end
					ecs.drawOldPixels(oldPixels)
					drawThisShit()
				end
			elseif e[4] == 28 then
				break
			else
				local symbol = convertCodeToSymbol(e[3])
				if symbol ~= nil then
					text = text .. symbol
					if unicode.len(text) < limit then
						inputPos = inputPos + 1
					end
					drawThisShit()
				end
			end
		end
	end

	ecs.drawOldPixels(oldPixels)
	return text
end

--СОХРАНЕНИЕ ТЕКСТА В МАССИВ ПИКСЕЛЕЙ, НО ЕСЛИ ЧЕТ ПРЕВЫШАЕТ ИЛИ ЕЩЕ КАКАЯ ХУЙНЯ - ТО СОСИ!
local function saveTextToPixels(x,y,text)
	local sText = unicode.len(text)
	pixels[currentLayer][2][y] = pixels[currentLayer][2][y] or {}
	for i=1,sText do
		local xPlusIMinus1 = x + i - 1
		local kuso4ek = unicode.sub(text,i,i)
		if pixels[currentLayer][2][y][xPlusIMinus1] then
			pixels[currentLayer][2][y][xPlusIMinus1][2] = background
			pixels[currentLayer][2][y][xPlusIMinus1][3] = kuso4ek
		else
			pixels[currentLayer][2][y][xPlusIMinus1] = {}
			pixels[currentLayer][2][y][xPlusIMinus1][1] = foreground
			pixels[currentLayer][2][y][xPlusIMinus1][2] = background
			pixels[currentLayer][2][y][xPlusIMinus1][3] = kuso4ek
		end
	end
end

local function newFile()
	imageWidth = 0
	imageHeight = 0

	createMassiv()
	currentLayer = 1
	drawAll()

	local data = ecs.beautifulInput("auto", "auto", 30, "Новый документ", "Ок", ecs.windowColors.background, ecs.windowColors.usualText, 0xcccccc, true, {"Ширина"}, {"Высота"})
	if data[1] == "" or data[1] == nil or data[1] == " " then data[1] = 51 end
	if data[2] == "" or data[2] == nil or data[2] == " " then data[2] = 19 end

	imageWidth = tonumber(data[1])
	imageHeight = tonumber(data[2])

	createMassiv()
	drawAll()
end

local function filter(mode)

	for y = 1, imageHeight do
		if pixels[currentLayer][2][y] then
			for x =1 ,imageWidth do
				if pixels[currentLayer][2][y][x] then
					if mode == "invert" then
						pixels[currentLayer][2][y][x] = {0xffffff - pixels[currentLayer][2][y][x][1], 0xffffff - pixels[currentLayer][2][y][x][2], pixels[currentLayer][2][y][x][3]}
					else
						local hex1 = pixels[currentLayer][2][y][x][1]
						local hex2 = pixels[currentLayer][2][y][x][2]
						local h, s, b = colorlib.HEXtoHSB(hex1); s = 0
						hex1 = colorlib.HSBtoHEX(h, s, b)

						h, s, b = colorlib.HEXtoHSB(hex2); s = 0
						hex2 = colorlib.HSBtoHEX(h, s, b)

						pixels[currentLayer][2][y][x] = {hex1, hex2, pixels[currentLayer][2][y][x][3]}
					end
				end
			end
		end
	end
end

--------------------------------------ПРОЖКА-------------------------------------------------------

if arg[1] == "-o" or arg[1] == "open" then
	open(arg[2])
	currentFile = arg[2]
	drawAll()
elseif arg[1] == "-n" or arg[1] == "new" then
	imageWidth = arg[2]
	imageHeight = arg[3]
	createMassiv()
	currentLayer = 1
	drawAll()
else
	newFile()
end

--ecs.palette(5,5,0xff0000)

local breakLags = false

while true do

	local eventData = {event.pull()}
	breakLags = false

	if eventData[1] == "touch" or eventData[1] == "drag" then

		local coordInMassivX = eventData[3] - drawImageFromX + 1
		local coordInMassivY = eventData[4] - drawImageFromY + 1

		if eventData[5] == 0 then
			consoleText = "Левый клик мышью, x = "..eventData[3]..", y = "..eventData[4]
			console(7,ySize)
			if ecs.clickedAtArea(eventData[3],eventData[4],obj["tools"]["imageZone"]["x1"],obj["tools"]["imageZone"]["y1"],obj["tools"]["imageZone"]["x2"],obj["tools"]["imageZone"]["y2"]) then
				
				if pixels[currentLayer][3] then
					--ЕСЛИ КИСТЬ
					if currentInstrument == 2 then
						
						ecs.colorTextWithBack(eventData[3],eventData[4],foreground,background,symbol)
						
						changePixelInMassiv(coordInMassivX,coordInMassivY,currentLayer,background,foreground,symbol)
						
					elseif currentInstrument == 3 then
						
						ecs.colorTextWithBack(eventData[3],eventData[4],transparentForeground,transparentBackground,transparentSymbol)
						
						changePixelInMassiv(coordInMassivX,coordInMassivY,currentLayer,transparentBackground,transparentForeground,transparentSymbol)
					elseif currentInstrument == 4 then

						local limit = imageWidth - coordInMassivX + 1
						local text = inputText(eventData[3],eventData[4],limit)
						if text == "" then text = transparentSymbol end

						local sText = unicode.len(text)
						if sText > limit then text = unicode.sub(text,1,limit) end

						saveTextToPixels(coordInMassivX,coordInMassivY,text)
						drawFromMassiv()
					elseif currentInstrument == 1 then
						local symbol, _, back = gpu.get(eventData[3], eventData[4])
						if symbol ~= transparentSymbol then
							background = back
							drawLeftToolbar()
						end
					end

					breakLags = true
				else
					ecs.error("Каким раком я тебе буду рисовать на выключенном слое, тупой ты сын спидозной шлюхи?")
				end

			end

			for key,val in pairs(obj["instruments"]) do
				if breakLags then break end
				if ecs.clickedAtArea(eventData[3],eventData[4],obj["instruments"][key]["x1"],obj["instruments"][key]["y1"],obj["instruments"][key]["x2"],obj["instruments"][key]["y2"]) then
					currentInstrument = key
					consoleText = "Выбран инструмент "..instruments[key][1]
					drawLeftToolbar()

					breakLags = true
				end
			end

			for key,val in pairs(obj["colors"]) do
				if breakLags then break end
				if ecs.clickedAtArea(eventData[3],eventData[4],obj["colors"][key]["x1"],obj["colors"][key]["y1"],obj["colors"][key]["x2"],obj["colors"][key]["y2"]) then
					local CYKA = {gpu.get(eventData[3],eventData[4])}
					local chosenColor = palette.draw("auto","auto", CYKA[3])
					--ecs.error("ЦВЕТ ИЗМЕНИЛСЯ НА "..tostring(chosenColor))
					if chosenColor then
						if key == 1 then
							background = chosenColor
							consoleText = "Основной цвет изменен на 0x"..string.format("%x",chosenColor)
						else
							foreground = chosenColor
							consoleText = "Вторичный цвет изменен на 0x"..string.format("%x",chosenColor)
						end
					end
					drawLeftToolbar()

					breakLags = true
					break
				end
			end

			if ecs.clickedAtArea(eventData[3],eventData[4],obj["swapper"][1]["x1"],obj["swapper"][1]["y1"],obj["swapper"][1]["x2"],obj["swapper"][1]["y2"]) then
				ecs.colorTextWithBack(3,ySize-1,0xff0000,toolbarColor,"←→")
				os.sleep(0.3)
				swapColors()
			end

			for key,val in pairs(obj["layers"]) do
				if breakLags then break end
				if ecs.clickedAtArea(eventData[3],eventData[4],obj["layers"][key]["x1"],obj["layers"][key]["y"],obj["layers"][key]["x2"],obj["layers"][key]["y"]) then
					if currentLayer ~= key then
						currentLayer = key
					else
						local limit = xSize - xRightToolbar - 5
						ecs.square(xRightToolbar+4, obj["layers"][key]["y"], limit, 1, ecs.colors.blue)
						local text = inputText(xRightToolbar + 4, obj["layers"][key]["y"], limit, 0xffffff)
						if text == "" then
							text = pixels[key][1]
						else
							pixels[key][1] = text
						end
					end

					drawLayers(drawLayersFrom)
					breakLags = true
				end
			end

			for key,val in pairs(obj["layerEyes"]) do
				if breakLags then break end
				if ecs.clickedAtArea(eventData[3],eventData[4],obj["layerEyes"][key]["x1"],obj["layerEyes"][key]["y"],obj["layerEyes"][key]["x2"],obj["layerEyes"][key]["y"]) then
					if pixels[key][3] then
						pixels[key][3] = false
					else
						pixels[key][3] = true
					end

					drawLayers(drawLayersFrom)
					drawFromMassiv()

					breakLags = true
				end
			end

			for key,val in pairs(obj["top"]) do
				if breakLags then break end
				if ecs.clickedAtArea(eventData[3],eventData[4],obj["top"][key]["x1"],obj["top"][key]["y1"],obj["top"][key]["x2"],obj["top"][key]["y2"]) then
					ecs.colorTextWithBack(obj["top"][key]["x1"],obj["top"][key]["y1"],toolbarTextColor,toolbarPressColor," "..obj["top"][key]["name"].." ")

					---------------------------------------------

					if obj["top"][key]["name"] == "Файл" then
						local action = context.menu(obj["top"][key]["x1"],obj["top"][key]["y1"]+1,{"Новый",false,"^N"},{"Открыть",false,"^O"},"-",{"Сохранить",not currentFile,"^S"},{"Сохранить как",false,"^!S"},"-",{"Выйти"})
						if action == "Сохранить как" then
							local data = ecs.beautifulInput("auto", "auto", 30, "Сохранить как", "Ок", ecs.windowColors.background, ecs.windowColors.usualText, 0xcccccc, true, {"Путь"}, {"Формат"})
							if data[1] == "" or data[1] == " " or data[1] == nil then data[1] = "NewImage" end
							if data[2] == "" or data[2] == " " or data[2] == nil then data[2] = ".jpg" end
							data[1] = data[1]..data[2]

							currentFile = data[1]
							save(currentFile, data[2])
							consoleText = "Файл сохранен как "..currentFile
							console(7, ySize)
						elseif action == "Открыть" then
							local data = ecs.beautifulInput("auto", "auto", 30, "Открыть", "Ок", ecs.windowColors.background, ecs.windowColors.usualText, 0xcccccc, true, {"Путь к файлу"})
							if data[1] ~= "" and data[1] ~= " " and data[1] ~= nil then
								if fs.exists(data[1]) then
									local fileFormat = ecs.getFileFormat(data[1])
									if fileFormat == ".png" or fileFormat == ".jpg" then
										clearScreen(padColor)
										drawLeftToolbar()
										drawTopToolbar()
										drawRightToolbar()
										open(data[1])
										drawFromMassiv()
										consoleText = "Открыт файл "..data[1]
										console(7, ySize)
									else
										ecs.error("Формат файла не распознан.")
									end
								else
									ecs.error("Файл "..data[1].." не существует.")
								end
							else
								ecs.error("Что за хуйню ты ввел?")
							end						
						elseif action == "Сохранить" then
							local fileFormat = ecs.getFileFormat(currentFile)
							save(currentFile, fileFormat)
							consoleText = "Файл перезаписан как "..currentFile
							console(7, ySize)
						elseif action == "Выйти" then
							ecs.clearScreen(0x000000)
							gpu.setForeground(0xffffff)
							gpu.set(1, 1, "")
							return 0
						elseif action == "Новый" then
							newFile()
						end

					elseif obj["top"][key]["name"] == "Фильтры" then
						local action = context.menu(obj["top"][key]["x1"],obj["top"][key]["y1"]+1, {"Инверсия цвета"}, {"Черно-белый фильтр"})
						if action == "Инверсия цвета" then
							filter("invert")
						elseif action == "Черно-белый фильтр" then
							filter("b&w")
						end
						drawFromMassiv()
					elseif obj["top"][key]["name"] == "Инструменты" then
						local action = context.menu(obj["top"][key]["x1"],obj["top"][key]["y1"]+1, {"Пипетка", false, "Alt"}, {"Кисть", false, "B"}, {"Ластик", false, "E"}, {"Текст", false, "T"})
						
						if action == "Пипетка" then
							currentInstrument = 1
						elseif action == "Кисть" then
							currentInstrument = 2
						elseif action == "Ластик" then
							currentInstrument = 3
						elseif action == "Текст" then
							currentInstrument = 4
						end

						drawLeftToolbar()
					end

					---------------------------------------------

					drawTopToolbar()
					
					breakLags = true
				end
			end

			for key,val in pairs(obj["layerButtons"]) do
				if breakLags then break end
				if ecs.clickedAtArea(eventData[3],eventData[4],obj["layerButtons"][key]["x1"],obj["layerButtons"][key]["y"],obj["layerButtons"][key]["x2"],obj["layerButtons"][key]["y"]) then
					ecs.colorTextWithBack(obj["layerButtons"][key]["x1"],obj["layerButtons"][key]["y"],0xff0000,toolbarPressColor+0x111111,key)
					os.sleep(0.3)
					if key == buttons[5] then
						addElementToLayers(discription)
						drawLayers(drawLayersFrom)
					elseif key == buttons[6] then
						deleteLayer(currentLayer)
					elseif key == buttons[3] then
						duplicateLayer(currentLayer)
						drawLayers(drawLayersFrom)
					elseif key == buttons[1] then
						moveLayer(currentLayer,"up")
						drawLayers(drawLayersFrom)
					elseif key == buttons[2] then
						moveLayer(currentLayer,"down")
						drawLayers(drawLayersFrom)
					elseif key == buttons[4] then
						joinLayer(currentLayer)
						drawLayers(drawLayersFrom)
					end

					breakLags = true
				end
			end
		end

	elseif eventData[1] == "key_down" then
		--КЛАВИША SPACE
		if eventData[4] == 57 then
			consoleText = "Интерфейс программы перерисован"
			drawAll()
		--КЛАВИША ENTER
		elseif eventData[4] == 28 then
			newFile()
		--КЛАВИША BACKSPACE
		elseif eventData[4] == 14 then
			deleteLayer(currentLayer)
		--КЛАВИША N
		elseif eventData[4] == 49 then
			addElementToLayers(discription)
			drawLayers(drawLayersFrom)
		--КЛАВИША X
		elseif eventData[4] == 45 then
			swapColors()
		--КЛАВИША D
		elseif eventData[4] == 32 then
			background = 0x000000
			foreground = 0xffffff
			drawLeftToolbar()
		--КЛАВИША T
		elseif eventData[4] == 20 then
			currentInstrument = 4
			drawLeftToolbar()
		--КЛАВИША B
		elseif eventData[4] == 48 then
			currentInstrument = 2
			drawLeftToolbar()
		--КЛАВИША E
		elseif eventData[4] == 18 then
			currentInstrument = 3
			drawLeftToolbar()
		--Клавиша ALT
		elseif eventData[4] == 56 then
			currentInstrument = 1
			drawLeftToolbar()
		elseif eventData[4] == 200 then
			drawImageFromY = drawImageFromY - 1
			drawFromMassiv(true)
		elseif eventData[4] == 208 then
			drawImageFromY = drawImageFromY + 1
			drawFromMassiv(true)
		elseif eventData[4] == 203 then
			drawImageFromX = drawImageFromX - 1
			drawFromMassiv(true)
		elseif eventData[4] == 205 then
			drawImageFromX = drawImageFromX + 1
			drawFromMassiv(true)
		end

	elseif eventData[1] == "scroll" then

		--[[local a1 = gpu.getResolution()

		local a2 = gpu.maxResolution()Ы
		local currentScale = a1/a2
		eventData[3] = math.floor(eventData[3]*0.5/currentScale)
		eventData[4] = math.floor(eventData[4]*0.5/currentScale)]]

		if ecs.clickedAtArea(eventData[3],eventData[4],obj["layersZone"][1]["x1"],obj["layersZone"][1]["y1"],obj["layersZone"][1]["x2"],obj["layersZone"][1]["y2"]) then
			scrollLayers(eventData[5])

		end

	end
end

--------------------------------------ВЫХОД ИЗ ПРОЖКИ------------------------------------------------------

clearScreen(0x000000)
gpu.setBackground(0x000000)
gpu.setForeground(0xffffff)
