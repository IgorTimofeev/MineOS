local ecs = require("ECSAPI")
local components = require("component")
local serialization = require("serialization")
local fs = require("filesystem")
local event = require("event")
local unicode = require("unicode")
local bit32 = require("bit32")

package.loaded.libPNGImage = nil

--------------------------------------------------------------------------------------------------------------------------------------------

local pathToMultiScreenFolder = "MultiScreen/"
local pathToConfigFile = pathToMultiScreenFolder .. "Config.cfg"

local colors = {
	background = 0x262626,
	foreground = 0xDDDDDD,
	currentScreen = ecs.colors.green,
	screen = 0xDDDDDD,
}

local baseResolution = {
	width = 135,
	height = 50,
}

local monitors = {}

--------------------------------------------------------------------------------------------------------------------------------------------

local function getAllConnectedScreens()
	local massiv = {}
	for address in pairs(components.list("screen")) do
		table.insert(massiv, address)
	end
	return massiv
end

local function configurator()
	fs.makeDirectory(pathToMultiScreenFolder)
	
	ecs.setScale(0.7)

	local data = ecs.universalWindow("auto", "auto", 40, 0xeeeeee, true, {"EmptyLine"}, {"CenterText", 0x880000, "Здорово, ебана!"}, {"EmptyLine"}, {"WrappedText", 0x262626, "Добро пожаловать в программу конфигурации мультимонитора. Вам необходимо указать количество мониторов по ширине и высоте, которые вы желаете объединить, а также выбрать желаемый масштаб."}, {"EmptyLine"}, {"Input", 0x262626, 0x880000, "Ширина"}, {"Input", 0x262626, 0x880000, "Высота"},  {"Slider", 0x262626, 0x880000, 1, 100, 100, "Масштаб: ", "%"}, {"EmptyLine"}, {"Button", {ecs.colors.orange, 0xffffff, "Подтвердить"}, {0x777777, 0xffffff, "Отмена"}})
	local width, height, scale = tonumber(data[1]), tonumber(data[2]), tonumber(data[3]) / 100
	if data[4] == "Отмена" then
		ecs.prepareToExit()
		print("Калибровка отменена!")
		os.exit()
	end

	baseResolution.width, baseResolution.height = math.floor(baseResolution.width * scale), math.floor(baseResolution.height * scale)

	-- ecs.error(baseResolution.width .. "x" ..baseResolution.height .. " ccale = " ..scale)

	local countOfConnectedScreens = #getAllConnectedScreens()

	while ((countOfConnectedScreens - 1) ~= width * height) do
		data = ecs.universalWindow("auto", "auto", 44, 0xeeeeee, true, {"EmptyLine"}, {"WrappedText", 0x262626, "Теперь вам необходимо подключить внешние мониторы. Вы указали, что собираетесь сделать мультимонитор из " .. width*height .. " мониторов, но на данный момент вы подключили " .. countOfConnectedScreens - 1 .. " мониторов. Так что подключайте все так, как указали, и жмите \"Далее\"."}, {"EmptyLine"}, {"Button", {ecs.colors.orange, 0xffffff, "Далее"}, {0x777777, 0xffffff, "Отмена"}})
		if data[1] == "Отмена" then
			ecs.prepareToExit()
			print("Калибровка отменена!")
			os.exit()
		end
		countOfConnectedScreens = #getAllConnectedScreens()
	end

	----

	local w, h = 8, 3
	local xC, yC = 1, 1
	local xSize, ySize = gpu.getResolution()
	local mainScreenAddress = gpu.getScreen()

	local function drawMonitors()
		ecs.clearScreen(colors.background)
		local x, y = 3, 2
		local xPos, yPos = x, y
		for j = 1, height do
			for i = 1, width do
				if j == yC and i == xC then
					ecs.square(xPos, yPos, w, h, colors.currentScreen)
				else
					ecs.square(xPos, yPos, w, h, colors.screen)
				end
				xPos = xPos + w + 2
			end
			yPos = yPos + h + 1
			xPos = x
		end

		gpu.setBackground(colors.background)
		gpu.setForeground(colors.foreground)
		ecs.centerText("x", ySize - 5, "Начинаем процесс калибровки. Коснитесь монитора, подсвеченного зеленым цветом.")
		ecs.centerText("x", ySize - 4, "Не нарушайте порядок прокосновений!")
	end

	local touchArray = {}

	while xC <= width and yC <= height do
		drawMonitors()
		local e = {event.pull()}
		if e[1] == "touch" then
			if e[2] ~= mainScreenAddress then
				local success = true
				for i = 1, #touchArray do
					if touchArray[i] == e[2] then
						success = false
						break
					end
				end
				if success then
					ecs.rebindGPU(e[2])
					gpu.setResolution(baseResolution.width, baseResolution.height)
					local color = math.random(0x555555, 0xffffff)
					ecs.square(1,1,160,50,color)
					gpu.setForeground(0xffffff - color)
					ecs.centerText("xy", 0, "Монитор " .. xC .. "x" .. yC .. " откалиброван!")
					
					-- table.insert(touchArray, {address = e[2], position = {x = xC, y = yC}})
					touchArray[xC] = touchArray[xC] or {}
					touchArray[xC][yC] = touchArray[xC][yC] or {}
					touchArray[xC][yC].address = e[2]

					ecs.rebindGPU(mainScreenAddress)
					ecs.setScale(0.7)

					xC = xC + 1
					if xC > width and yC < height then xC = 1; yC = yC + 1 end
				else
					ecs.error("Тупая скотина, зачем ты тыкаешь на монитор, которого уже касался? На твое счастье в этой проге есть защита от конченных дебилов вроде тебя.")
				end
			else
				ecs.error("Ну что ты за мудак криворукий! Сказано же, каких мониторов касаться. Не трогай этот монитор.")
			end
		end
	end

	monitors = touchArray
	monitors.countOfScreensByWidth = width
	monitors.countOfScreensByHeight = height
	monitors.screenResolutionByWidth = baseResolution.width
	monitors.screenResolutionByHeight = baseResolution.height
	monitors.totalResolutionByWidth = baseResolution.width * width
	monitors.totalResolutionByHeight = baseResolution.height * height

	ecs.prepareToExit()
	ecs.universalWindow("auto", "auto", 40, 0xeeeeee, true, {"EmptyLine"}, {"CenterText", 0x262626, "Калибровка успешно завершена!"}, {"EmptyLine"}, {"Button", {ecs.colors.orange, 0xffffff, "Отлично"}})

	gpu.setBackground(0x000000)
	for x = 1, #monitors do
		for y = 1, #monitors[x] do
			gpu.bind(monitors[x][y].address)
			gpu.fill(1, 1, 160, 50, " ")
		end
	end
	gpu.bind(mainScreenAddress)
	ecs.prepareToExit()
end

local function saveConfig()
	local file = io.open(pathToConfigFile, "w")
	file:write(serialization.serialize(monitors))
	file:close()
end

local function loadConfig()
	if fs.exists(pathToConfigFile) then
		local file = io.open(pathToConfigFile, "r")
		monitors = serialization.unserialize(file:read("*a"))
		file:close()
		print(" ")
		print("Файл конфигурации мультимонитора успешно загружен.")
		print(" ")
		print("Количество экранов: " .. monitors.countOfScreensByWidth .. "x" .. monitors.countOfScreensByHeight .. " шт")
		print("Разрешение каждого экрана: " .. monitors.screenResolutionByWidth .. "x" .. monitors.screenResolutionByHeight .. " px")
		print("Суммарного разрешение кластера: ".. monitors.totalResolutionByWidth .. "x" .. monitors.totalResolutionByHeight .. " px")
		print(" ")
	else
		configurator()
		saveConfig()
		loadConfig()
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------

local currentBackground, currentForeground, currentAddress = 0x000000, 0xffffff, ""

local multiScreen = {}

function multiScreen.setBackground(color)
	currentBackground = color
end

function multiScreen.setForeground(color)
	currentForeground = color
end

local function getMonitorAndCoordinates(x, y)
	local xMonitor = math.ceil(x / monitors.screenResolutionByWidth)
	local yMonitor = math.ceil(y / monitors.screenResolutionByHeight)
	local xPos = x - (xMonitor - 1) * monitors.screenResolutionByWidth
	local yPos = y - (yMonitor - 1) * monitors.screenResolutionByHeight

	-- print("x = " .. x)
	-- print("y = " .. y)
	-- print("xMonitor = " .. xMonitor)
	-- print("yMonitor = " .. yMonitor)
	-- print("xPos = " .. xPos)
	-- print("yPos = " .. yPos)

	return xMonitor, yMonitor, xPos, yPos
end

function multiScreen.clear(color)
	for x = 1, #monitors do
		for y = 1, #monitors[x] do
			gpu.bind(monitors[x][y].address)
			gpu.setResolution(monitors.screenResolutionByWidth, monitors.screenResolutionByHeight)
			gpu.setBackground(color)
			gpu.fill(1, 1, 160, 50, " ")
		end
	end
end

function multiScreen.set(x, y, text)
	for i = 1, unicode.len(text) do
		local xMonitor, yMonitor, xPos, yPos = getMonitorAndCoordinates(x + i - 1, y)
		
		if monitors[xMonitor] and monitors[xMonitor][yMonitor] then
			if currentAddress ~= monitors[xMonitor][yMonitor].address then
				gpu.bind(monitors[xMonitor][yMonitor].address)
				currentAddress = monitors[xMonitor][yMonitor].address
				gpu.setResolution(monitors.screenResolutionByWidth, monitors.screenResolutionByHeight)
			end
			
			if gpu.getBackground ~= currentBackground then gpu.setBackground(currentBackground) end
			if gpu.getForeground ~= currentForeground then gpu.setForeground(currentForeground) end
			
			gpu.set(xPos, yPos, unicode.sub(text, i, i))
		end
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------

--Склеить байты и создать из них число
local function mergeBytesToNumber(...)
	local bytes = {...}
	local finalNumber = bytes[1]
	for i = 2, #bytes do
		finalNumber = bit32.bor(bit32.lshift(finalNumber, 8), bytes[i])
	end
	return finalNumber
end

--Прочитать n байтов из файла, возвращает прочитанные байты как число, если не удалось прочитать, то возвращает 0
local function readBytes(file, count)
	local readedBytes = file:read(count)
	return mergeBytesToNumber(string.byte(readedBytes, 1, count))
end

local function selectTerminateBit_l()
	local prevByte = nil
	local prevTerminateBit = nil

	return function( byte )
		local x, terminateBit = nil
		if ( prevByte == byte ) then
			return prevTerminateBit
		end

		x = bit32.band( bit32.bnot(byte), 0x000000FF )
		x = bit32.bor( x, bit32.rshift(x, 1) )
		x = bit32.bor( x, bit32.rshift(x, 2) )
		x = bit32.bor( x, bit32.rshift(x, 4) )
		x = bit32.bor( x, bit32.rshift(x, 8) )
		x = bit32.bor( x, bit32.rshift(x, 16) )

		terminateBit = x - bit32.rshift(x, 1)

		prevByte = byte
		prevTerminateBit = terminateBit

		return terminateBit
	end
end
local selectTerminateBit = selectTerminateBit_l()

--Декодирование UTF-8 символа
local function decodeChar(file)
	local first_byte = readBytes(file, 1)
	local charcode_array = {first_byte}
	local len = 1

	local middle = selectTerminateBit(first_byte)
	if ( middle == 32 ) then
		len = 2
	elseif ( middle == 16 ) then 
		len = 3
	elseif ( middle == 8 ) then
		len = 4
	elseif ( middle == 4 ) then
		len = 5
	elseif ( middle == 2 ) then
		len = 6
	end

	for i = 1, len-1 do
		table.insert( charcode_array, readBytes(file, 1) )
	end

	return string.char( table.unpack( charcode_array ) )
end

local function drawBigImageFromOCIFRawFile(x, y, path)
	local file = io.open(path, "rb")
	print("Открываем файл " .. path)
	--Читаем ширину и высоту файла
	local signature = file:read(4)
	print("Читаем сигнатуру файла: " .. signature)
	local encodingMethod = string.byte(file:read(1))
	print("Читаем метод кодирования: " .. encodingMethod)

	if encodingMethod ~= 5 then error("Неподдерживаемый метод кодирования: " .. encodingMethod) end

	local width = readBytes(file, 2)
	local height = readBytes(file, 2)

	print("Ширина пикчи: " .. tostring(width))
	print("Высота пикчи: " .. tostring(height))

	print("Начинаю отросовку пикчи...")

	for j = 1, height do
		for i = 1, width do
			local background = readBytes(file, 3)
			local foreground = readBytes(file, 3)
			local alpha = readBytes(file, 1)
			local symbol = decodeChar( file )

			multiScreen.setBackground(background)
			multiScreen.setForeground(foreground)
			multiScreen.set(x + i - 1, y + j - 1, symbol)
		end
	end

	file:close()

	print("Отрисовка пикчи завершена")
end

--------------------------------------------------------------------------------------------------------------------------------------------

local args = {...}

if args[1] == "draw" and args[2] then
	loadConfig()
	multiScreen.clear(0x000000)
	drawBigImageFromOCIFRawFile(1, 1, args[2])
elseif args[1] == "calibrate" then
	fs.remove(pathToMultiScreenFolder)
	loadConfig()
elseif args[1] == "clear" then
	loadConfig()
	multiScreen.clear(tonumber(args[2] or 0x000000))
else
	print("Использование программы:")
	print("  MultiScreen calibrate - перекалибровать мониторы")
	print("  MultiScreen draw <путь к изображению> - отобразить изображение из файла на мониторах")
	print("  MultiScreen clear <цвет> - очистить мониторы с указанным цветом (черным по умолчанию)")
end

--------------------------------------------------------------------------------------------------------------------------------------------

return multiScreen






