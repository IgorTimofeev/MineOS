local unicode = require("unicode")
local files = require("files")
local buffer = require("doubleBuffering")
local event = require("event")
local fs = require("filesystem")
local context = require("context")
local ecs = require("ECSAPI")

--------------------------------------------------------------------------------------------------------------------------------

local xSize, ySize = buffer.screen.width, buffer.screen.height
local file = {}

local config = {
	x = 1,
	y = 1,
	width = 98,
	height = 25,
	heightOfTopBar = 3,
	fromString = 1,
	xCurrentByte = 1,
	yCurrentByte = 1,
	pathToFile = "bin/resolution.lua",
	sizeOfFile = 1,
	transparency = 30,
	colors = {
		background = 0xdddddd,
		topBar = 0xdddddd,
		topBarText = 0x262626,
		topBarButton = 0x444444,
		hexText = 0x262626,
		hexSelection = 0x880000,
		hexSelectionText = 0xffffff,
		numberBar = 0x262626,
		numberBarText = 0xcccccc,
		infoPanel = 0x880000,
		infoPanelText = 0xffffff,
	}
}

--------------------------------------------------------------------------------------------------------------------------------

local obj = {}
local function newObj(class, name, ...)
	obj[class] = obj[class] or {}
	obj[class][name] = {...}
end

local function convertIndexToCoords(index)
	local ostatok = index % 16
	local x = (ostatok == 0) and 16 or ostatok
	local y = math.ceil(index / 16)
	return x, y
end

local function convertCoordsToIndex(xByte, yByte)
	return (yByte - 1) * 16 + xByte
end

local function readFile()
	config.fromString = 1
	config.CurrentByte = 1
	config.CurrentByte = 1

	file = {}
	local fileStream = files.openForReadingBytes(config.pathToFile)

	local readedByte
	while true do
		readedByte = fileStream.readByteAsHex()
		if not readedByte then break end
		table.insert(file, readedByte)
	end

	fileStream.close()
	config.sizeOfFile = math.ceil(fs.size(config.pathToFile) / 1024)
end

local function drawInfoPanel()
	local x = config.x
	local y = config.y

	local width = 30
	local xPos = x + math.floor(config.width / 2 - width / 2) - 1
	buffer.square(xPos, y, width, config.heightOfTopBar, config.colors.infoPanel, 0x000000, " ")
	
	local text = fs.name(config.pathToFile)
	xPos = x + math.floor(config.width / 2 - unicode.len(text) / 2) - 1
	buffer.text(xPos, y, config.colors.infoPanelText, unicode.sub(text, 1, width - 2))

	text = "Размер файла: " .. config.sizeOfFile .. " КБ"
	xPos = x + math.floor(config.width / 2 - unicode.len(text) / 2) - 1
	buffer.text(xPos, y + 1, 0xffaaaa, unicode.sub(text, 1, width - 2))

	text = "Текущий байт: " .. convertCoordsToIndex(config.xCurrentByte, config.yCurrentByte)
	xPos = x + math.floor(config.width / 2 - unicode.len(text) / 2) - 1
	buffer.text(xPos, y + 2, 0xffaaaa, unicode.sub(text, 1, width - 2))
end

local function drawTopBar()
	local x = config.x
	local y = config.y

	buffer.square(x, y, config.width, 3, 0xffffff, 0xffffff, " ", config.transparency)
	newObj("Buttons", 1, buffer.button(x, y, 10, 3, 0xdddddd, 0x000000, "Файл"))

	drawInfoPanel()
end

local function printDebug(line, text)
	if debug then
		ecs.square(1, line, buffer.screen.width, 1, 0x262626)
		ecs.colorText(2, line, 0xFFFFFF, text)
	end
end

local function drawHexAndText()
	local x, y = config.x, config.y + 3
	local textOffset = 67
	local hexOffset = 12
	local xHex, yHex = x + hexOffset, y + 2
	local xText, yText = xHex + textOffset, y + 2

	obj["hex"] = {}
	obj["text"] = {}

	--Главный белый
	buffer.square(config.x, config.y + 3, config.width, config.height - 3, config.colors.background, 0x000000, " ")
	--Левый серый
	buffer.square(x, y, 10, config.height - 3, config.colors.numberBar, 0xffffff, " ")
	--Верхний серый
	buffer.square(x, y, config.width, 1, config.colors.numberBar, 0xffffff, " ")
	--Вертикальная полоска
	buffer.square(xText - 3, y + 1, 1, config.height - 4, config.colors.background, 0xaaaaaa, "│")
	--Скроллбар
	buffer.scrollBar(x + config.width - 1, y + 1, 1, config.height - 4, math.ceil(#file / 16), config.fromString, 0x262626, ecs.colors.lightBlue)

	--Рисуем верхние номерки
	local xCyka = xHex
	for i = 1, 16 do
		if i == config.xCurrentByte then
			buffer.square(xCyka - 1, y, 4, 1, config.colors.hexSelection, 0xffffff, " ")
			buffer.text(xCyka, y, config.colors.hexSelectionText, string.format("%02X", i - 1))
		else
			buffer.text(xCyka, y, config.colors.numberBarText, string.format("%02X", i - 1))
		end
		
		xCyka = xCyka + 4
	end

	--Рисуем хекс и текст
	local xByte, yByte, text
	local byteCounter = 1
	local fromByte = config.fromString * 16 - 15
	for byte = fromByte, fromByte + 10 * 16 - 1 do

		if not file[byte] then break end
		
		xByte, yByte = convertIndexToCoords(byte)

		text = unicode.char(tonumber("0x" .. file[byte]))
		if unicode.isWide(text) then text = "." end

		if config.xCurrentByte == xByte and config.yCurrentByte == yByte then
			buffer.square(xHex - 1, yHex, 4, 1, config.colors.hexSelection, 0xffffff, " ")
			buffer.set(xText, yText, config.colors.hexSelection, 0xffffff, " ")

			buffer.text(xHex, yHex, config.colors.hexSelectionText, file[byte])
			buffer.text(xText, yText, config.colors.hexSelectionText, text)
		else
			buffer.text(xHex, yHex, config.colors.hexText, file[byte])
			buffer.text(xText, yText, config.colors.hexText, text)
		end

		--Рисуем левые номерки
		if yByte == config.yCurrentByte then
			buffer.square(x, yHex, 10, 1, config.colors.hexSelection, 0xffffff, " ")
			buffer.text(x + 1, yHex, config.colors.hexSelectionText, string.format("%07X", yByte - 1) .. "0")
		else
			buffer.text(x + 1, yHex, config.colors.numberBarText, string.format("%07X", yByte - 1) .. "0")
		end

		--Обжектыыы!! Ы!
		newObj("hex", byteCounter, xHex, yHex, xByte, yByte)
		newObj("text", byteCounter, xText, yText, xByte, yByte)
		byteCounter = byteCounter + 1

		--Коорды!
		if xByte == 16 then
			xHex = x + hexOffset
			xText = xHex + textOffset
			yHex = yHex + 2
			yText = yText + 2
		else
			xHex = xHex + 4
			xText = xText + 1
		end
	end
end


local function drawAll(force)
	drawTopBar()
	drawHexAndText()
	--Тень
	buffer.square(config.x + config.width, config.y + 1, 2, config.height, 0x000000, 0xffffff, " ", 50)
	buffer.square(config.x + 2, config.y + config.height, config.width - 2, 1, 0x000000, 0xffffff, " ", 50)
	buffer.draw(force)
end

local function getCenterOfScreen()
	config.x = math.floor(xSize / 2 - config.width / 2)
	config.y = math.floor(ySize / 2 - config.height / 2)
end

local function checkInput(text, pattern)
	if string.find(text, pattern) then
		return true
	else
		ecs.error("Что за говно ты сюда ввел? Переделывай на хуй!")
	end
end

local function editByte(xByte, yByte)
	local index = convertCoordsToIndex(xByte, yByte)
	local data = ecs.universalWindow("auto", "auto", 36, 0x262626, true, {"EmptyLine"}, {"CenterText", 0xffffff, "Редактировать байт"}, {"EmptyLine"}, {"Input", 0xffffff, 0xff5555, "Введите значение HEX"}, {"EmptyLine"}, {"Button", {0x880000, 0xffffff, "Принять"}, {0xaaaaaa, 0xffffff, "Отмена"}})
	if data[2] == "Принять" and checkInput(data[1], "^[1234567890abcdefABCDEF][1234567890abcdefABCDEF]$") then
		file[index] = data[1]
	end
end

local function editText(xByte, yByte)
	local index = convertCoordsToIndex(xByte, yByte)
	local data = ecs.universalWindow("auto", "auto", 36, 0x262626, true, {"EmptyLine"}, {"CenterText", 0xffffff, "Редактировать байт"}, {"EmptyLine"}, {"Input", 0xffffff, 0xff5555, "Введите значение CHAR"}, {"EmptyLine"}, {"Button", {0x880000, 0xffffff, "Принять"}, {0xaaaaaa, 0xffffff, "Отмена"}})
	if data[2] == "Принять" and checkInput(data[1], "^.$") then
		file[index] = string.format("%02X", string.byte(byteValue))
	end
end

local function insertByte(xByte, yByte)
	local index = convertCoordsToIndex(xByte, yByte)
	local data = ecs.universalWindow("auto", "auto", 36, 0x262626, true, {"EmptyLine"}, {"CenterText", 0xffffff, "Вставить байт"}, {"EmptyLine"}, {"Input", 0xffffff, 0xff5555, "Введите значение HEX"}, {"EmptyLine"}, {"Button", {0x880000, 0xffffff, "Вставить"}, {0xaaaaaa, 0xffffff, "Отмена"}})
	if data[2] == "Вставить" and checkInput(data[1], "^[1234567890abcdefABCDEF][1234567890abcdefABCDEF]$") then
		table.insert(file, index, data[1])
	end
end

local function invertByte(xByte, yByte)
	local index = convertCoordsToIndex(xByte, yByte)
	file[index] = bit32.band( bit32.bnot(tonumber("0x" .. file[index])), 0xff )
	file[index] = string.format("%02X", string.byte(file[index]))
end

local function askForWhatToDoWithByte(x, y, xByte, yByte, asByte)
	local action = context.menu(x, y, {"Редактировать байт"}, {"Инвертировать байт"}, {"Вставить байт"}, "-", {"Удалить байт"})

	if action == "Редактировать байт" then
		if asByte then
			editByte(xByte, yByte)
		else
			editText(xByte, yByte)
		end
	elseif action == "Инвертировать байт" then
		local index = convertCoordsToIndex(xByte, yByte)
		invertByte(xByte, yByte)
	elseif action == "Вставить байт" then
		insertByte(xByte, yByte)
	elseif action == "Удалить байт" then
		local index = convertCoordsToIndex(xByte, yByte)
		table.remove(file, index)
	end
end

local function save(path)
	fs.makeDirectory(fs.path(path) or "")
	local fileStream = files.openForWriting(path)
	for i = 1, #file do
		fileStream.write(unicode.char(tonumber(table.concat({"0x", file[i]}))))
	end
	fileStream.close()
end

--------------------------------------------------------------------------------------------------------------------------------

readFile()
--buffer.square(1, 1, xSize, ySize, ecs.colors.red, 0x000000, " ")
getCenterOfScreen()

local oldPixels = buffer.copy(config.x, config.y, config.width + 2, config.height + 1)
drawAll(true)

while true do
	local e = {event.pull()}
	if e[1] == "touch" then
		for key in pairs(obj["hex"]) do
			if e[3] >= obj["hex"][key][1] - 1 and e[3] <= obj["hex"][key][1] + 2 and e[4] == obj["hex"][key][2] then
				if config.xCurrentByte == obj["hex"][key][3] and config.yCurrentByte == obj["hex"][key][4] then
					if e[5] == 0 then
						editByte(obj["hex"][key][3], obj["hex"][key][4])
					else
						askForWhatToDoWithByte(obj["hex"][key][1] - 1, obj["hex"][key][2] + 1, obj["hex"][key][3], obj["hex"][key][4], true)
					end
				else
					config.xCurrentByte = obj["hex"][key][3]
					config.yCurrentByte = obj["hex"][key][4]
				end
				
				drawHexAndText()
				drawInfoPanel()
				buffer.draw()

				break
			end
		end

		for key in pairs(obj["text"]) do
			if e[3] == obj["text"][key][1] and e[4] == obj["text"][key][2] then
				if config.xCurrentByte == obj["text"][key][3] and config.yCurrentByte == obj["text"][key][4] then
					if e[5] == 0 then
						editText(obj["text"][key][3], obj["text"][key][4])
					else
						askForWhatToDoWithByte(obj["text"][key][1], obj["text"][key][2] + 1, obj["text"][key][3], obj["text"][key][4], true)
					end
				else
					config.xCurrentByte = obj["text"][key][3]
					config.yCurrentByte = obj["text"][key][4]
				end
				
				drawHexAndText()
				drawInfoPanel()
				buffer.draw()

				break
			end
		end

		if ecs.clickedAtArea(e[3], e[4], obj["Buttons"][1][1], obj["Buttons"][1][2], obj["Buttons"][1][3], obj["Buttons"][1][4]) then
			buffer.button(obj["Buttons"][1][1], obj["Buttons"][1][2], 10, 3, 0x333333, 0xdddddd, "Файл")
			buffer.draw()

			local action = context.menu(obj["Buttons"][1][1], obj["Buttons"][1][2] + 3, {"Открыть"}, {"Сохранить"}, {"Сохранить как"}, "-", {"Выход"})

			buffer.button(obj["Buttons"][1][1], obj["Buttons"][1][2], 10, 3, 0xdddddd, 0x000000, "Файл")
			buffer.draw()

			if action == "Открыть" then
				local data = ecs.universalWindow("auto", "auto", 36, 0x262626, true, {"EmptyLine"}, {"CenterText", 0xffffff, "Открыть файл"}, {"EmptyLine"}, {"Input", 0xffffff, 0x880000, "Путь к файлу"}, {"EmptyLine"}, {"Button", {0x880000, 0xffffff, "Открыть"}, {0xaaaaaa, 0xffffff, "Отмена"}})
				if data[2] == "Открыть" then
					if fs.exists(data[1]) then
						config.pathToFile = data[1]
						readFile()
						drawHexAndText()
						drawInfoPanel()
						buffer.draw()
					else
						ecs.error("Файл \"" .. data[1] .. "\" не существует!")
					end
				end
			elseif action == "Сохранить" then
				save(config.pathToFile)
			elseif action == "Сохранить как" then
				local data = ecs.universalWindow("auto", "auto", 36, 0x262626, true, {"EmptyLine"}, {"CenterText", 0xffffff, "Сохранить как"}, {"EmptyLine"}, {"Input", 0xffffff, 0x880000, "Путь к файлу"}, {"EmptyLine"}, {"Button", {0x880000, 0xffffff, "Сохранить"}, {0xaaaaaa, 0xffffff, "Отмена"}})
				if data[2] == "Сохранить" then
					save(data[1])
				end
			elseif action == "Выход" then
				buffer.paste(config.x, config.y, oldPixels)
				buffer.draw()
				return
			end			
		end
	elseif e[1] == "scroll" then
		if e[5] == 1 then
			if config.fromString > 1 then
				config.fromString = config.fromString - 1
				drawHexAndText()
				buffer.draw()
			end
		else
			if config.fromString <= math.ceil(#file / 16) - 1 then
				config.fromString = config.fromString + 1
				drawHexAndText()
				buffer.draw()
			end
		end
	end
end
















