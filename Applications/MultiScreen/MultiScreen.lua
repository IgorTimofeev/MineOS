
require("advancedLua")
local ecs = require("ECSAPI")
local components = require("component")
local serialization = require("serialization")
local fs = require("filesystem")
local event = require("event")
local unicode = require("unicode")
local bit32 = require("bit32")
local color = require("color")
local gpu = components.gpu

--------------------------------------------------------------------------------------------------------------------------------------------

local mainScreenAddress = gpu.getScreen()
local pathToConfigFile = "/MultiScreen.cfg"

local colors = {
	background = 0x262626,
	foreground = 0xDDDDDD,
	currentScreen = ecs.colors.green,
	screen = 0xDDDDDD,
}

local baseResolution = {
	width = 146,
	height = 54,
}

local monitors = {}

--------------------------------------------------------------------------------------------------------------------------------------------

local currentBackground, currentForeground, currentAddress = 0x000000, 0xffffff, ""

local function multiScreenSet(x, y, background, foreground, text)
	local xMonitor = math.ceil(x / monitors.screenResolutionByWidth)
	local yMonitor = math.ceil(y / monitors.screenResolutionByHeight)
		
	if monitors[xMonitor] and monitors[xMonitor][yMonitor] then
		if currentAddress ~= monitors[xMonitor][yMonitor].address then
			gpu.bind(monitors[xMonitor][yMonitor].address, false)
			gpu.setBackground(background)
			gpu.setForeground(foreground)

			currentBackground, currentForeground = background, foreground

			currentAddress = monitors[xMonitor][yMonitor].address
		end

		if currentBackground ~= background then
			gpu.setBackground(background)
			currentBackground = background
		end

		if currentForeground ~= foreground then
			gpu.setForeground(foreground)
			currentForeground = foreground
		end

		gpu.set(x - (xMonitor - 1) * monitors.screenResolutionByWidth, y - (yMonitor - 1) * monitors.screenResolutionByHeight, text)
	end
end

local function multiScreenClear(color)
	for address in components.list("screen") do
		if address ~= mainScreenAddress then
			gpu.bind(address, false)
			gpu.setResolution(baseResolution.width, baseResolution.height)
			gpu.setDepth(8)
			gpu.setBackground(0x0)
			gpu.setForeground(0xffffff)
			gpu.fill(1, 1, baseResolution.width, baseResolution.height, " ")
		end
	end

	gpu.bind(mainScreenAddress, false)
end

--------------------------------------------------------------------------------------------------------------------------------------------

local function getAllConnectedScreens()
	local massiv = {}
	for address in pairs(components.list("screen")) do
		table.insert(massiv, address)
	end
	return massiv
end

local function configurator()
	fs.makeDirectory(fs.path(pathToConfigFile))

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

	while ((countOfConnectedScreens - 1) < width * height) do
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

	ecs.prepareToExit()
	print("Идет подготовка мониторов...")
	multiScreenClear(0x0)

	monitors = {}
	local monitorCount = width * height
	local counter = 1
	while counter <= monitorCount do
		drawMonitors()
		local e = {event.pull("touch")}
		if e[2] ~= mainScreenAddress then
			local exists = false
			for x = 1, #monitors do
				for y = 1, #monitors[x] do
					if monitors[x][y].address == e[2] then
						ecs.error("Ты уже кликал на этот монитор. Совсем уебок штоле?")
						exists = true
					end
				end
			end

			if not exists then
				gpu.bind(e[2], false)
				gpu.setResolution(baseResolution.width, baseResolution.height)
				gpu.setDepth(8)

				local color = color.HSBToInteger(counter / monitorCount * 360, 1, 1)
				gpu.setBackground(color)
				gpu.setForeground(0xffffff - color)
				gpu.fill(1, 1, baseResolution.width, baseResolution.height, " ")
				
				ecs.centerText("xy", 0, "Монитор " .. xC .. "x" .. yC .. " откалиброван!")

				gpu.bind(mainScreenAddress, false)

				monitors[xC] = monitors[xC] or {}
				monitors[xC][yC] = {address = e[2]}

				xC = xC + 1
				if xC > width and yC < height then
					xC, yC = 1, yC + 1
				end
			end
		else
			ecs.error("Ну что ты за мудак криворукий! Сказано же, каких мониторов касаться. Не трогай этот монитор.")
		end

		counter = counter + 1
	end

	monitors.countOfScreensByWidth = width
	monitors.countOfScreensByHeight = height
	monitors.screenResolutionByWidth = baseResolution.width
	monitors.screenResolutionByHeight = baseResolution.height
	monitors.totalResolutionByWidth = baseResolution.width * width
	monitors.totalResolutionByHeight = baseResolution.height * height

	ecs.prepareToExit()
	ecs.universalWindow("auto", "auto", 40, 0xeeeeee, true, {"EmptyLine"}, {"CenterText", 0x262626, "Калибровка успешно завершена!"}, {"EmptyLine"}, {"Button", {ecs.colors.orange, 0xffffff, "Отлично"}})
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
		print("Файл конфигурации мультимонитора загружен")
		print(" ")
		print("Количество экранов: " .. monitors.countOfScreensByWidth .. "x" .. monitors.countOfScreensByHeight .. " шт")
		print("Разрешение каждого экрана: " .. monitors.screenResolutionByWidth .. "x" .. monitors.screenResolutionByHeight .. " px")
		print("Суммарное разрешение кластера: " .. monitors.totalResolutionByWidth .. "x" .. monitors.totalResolutionByHeight .. " px")
		-- print("Суммарное разрешение кластера через шрифт Брайля: ".. monitors.totalResolutionByWidth * 2 .. "x" .. monitors.totalResolutionByHeight * 4 .. " px")
		print(" ")
	else
		configurator()
		saveConfig()
		loadConfig()
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------

--Прочитать n байтов из файла, возвращает прочитанные байты как число, если не удалось прочитать, то возвращает 0
local function readNumber(file, count)
	return bit32.byteArrayToNumber({string.byte(file:read(count), 1, count)})
end

local function drawBigImageFromOCIFRawFile(x, y, path)
	local file = io.open(path, "rb")
	print("Открываем файл " .. path)
	local signature = file:read(4)
	print("Читаем сигнатуру файла: " .. signature)
	local encodingMethod = string.byte(file:read(1))
	print("Читаем метод кодирования: " .. tostring(encodingMethod))

	if encodingMethod ~= 5 then
		print("Неподдерживаемый метод кодирования. Откройте конвертер, измените формат на OCIF5 (Multiscreen) и повторите попытку")
		file:close()
	end

	local width = readNumber(file, 2)
	local height = readNumber(file, 2)

	print("Ширина пикчи: " .. tostring(width))
	print("Высота пикчи: " .. tostring(height))

	print("Начинаю отросовку пикчи...")

	for j = 1, height do
		for i = 1, width do
			local background = color.to24Bit(string.byte(file:read(1)))
			local foreground = color.to24Bit(string.byte(file:read(1)))
			file:read(1)
			local symbol = string.readUnicodeChar(file)

			multiScreenSet(x + i - 1, y + j - 1, background, foreground, symbol)
		end
	end

	file:close()
	
	gpu.bind(mainScreenAddress, false)
	print("Отрисовка пикчи завершена")
end

--------------------------------------------------------------------------------------------------------------------------------------------

local args = {...}

if args[1] == "draw" and args[2] then
	loadConfig()
	print("Идет очистка мониторов...")
	multiScreenClear(0x000000)
	if fs.exists(args[2]) then
		drawBigImageFromOCIFRawFile(1, 1, args[2])
	else
		print("Файл " .. tostring(args[2]) .. " не найден. Используйте абсолютный путь к файлу, добавив / в начало")
	end
elseif args[1] == "calibrate" then
	fs.remove(pathToConfigFile)
	loadConfig()
elseif args[1] == "clear" then
	loadConfig()
	multiScreenClear(tonumber(args[2] or 0x000000))
else
	loadConfig()
	print("Использование программы:")
	print("  MultiScreen calibrate - перекалибровать мониторы")
	print("  MultiScreen draw <путь к изображению> - отобразить изображение из файла на мониторах")
	print("  MultiScreen clear <цвет> - очистить мониторы с указанным цветом (черным по умолчанию)")
end

--------------------------------------------------------------------------------------------------------------------------------------------

return multiScreen





