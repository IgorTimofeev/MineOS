
-- Адаптивная загрузка необходимых библиотек и компонентов
local libraries = {
	["component"] = "component",
	["term"] = "term",
	["unicode"] = "unicode",
	["event"] = "event",
	["fs"] = "filesystem",
	["shell"] = "shell",
	["keyboard"] = "keyboard",
	["computer"] = "computer",
	["serialization"] = "serialization",
	--["internet"] = "internet",
	--["image"] = "image",
}

local components = {
	["gpu"] = "gpu",
}

for library in pairs(libraries) do if not _G[library] then _G[library] = require(libraries[library]) end end
for comp in pairs(components) do if not _G[comp] then _G[comp] = _G.component[components[comp]] end end
libraries, components = nil, nil

local ecs = {}

----------------------------------------------------------------------------------------------------

ecs.windowColors = {
	background = 0xeeeeee,
	usualText = 0x444444,
	subText = 0x888888,
	tab = 0xaaaaaa,
	title = 0xffffff,
	shadow = 0x444444,
}

ecs.colors = {
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
	["0"] = 0xffffff,
	["1"] = 0xF2B233,
	["2"] = 0xE57FD8,
	["3"] = 0x99B2F2,
	["4"] = 0xDEDE6C,
	["5"] = 0x7FCC19,
	["6"] = 0xF2B2CC,
	["7"] = 0x4C4C4C,
	["8"] = 0x999999,
	["9"] = 0x4C99B2,
	["a"] = 0xB266E5,
	["b"] = 0x3366CC,
	["c"] = 0x7F664C,
	["d"] = 0x57A64E,
	["e"] = 0xCC4C4C,
	["f"] = 0x000000
}

----------------------------------------------------------------------------------------------------

--Адекватный запрос к веб-серверу вместо стандартного Internet API, бросающего stderr, когда ему вздумается
function ecs.internetRequest(url)
	local success, response = pcall(component.internet.request, url)
	if success then
		local responseData = ""
		while true do
			local data, responseChunk = response.read()	
			if data then
				responseData = responseData .. data
			else
				if responseChunk then
					return false, responseChunk
				else
					return true, responseData
				end
			end
		end
	else
		return false, reason
	end
end

--Загрузка файла с инета
function ecs.getFileFromUrl(url, path)
	local success, response = ecs.internetRequest(url)
	if success then
		fs.makeDirectory(fs.path(path) or "")
		local file = io.open(path, "w")
		file:write(response)
		file:close()
	else
		ecs.error("Could not connect to to URL address \"" .. url .. "\"")
		return
	end
end

--Отключение принудительного завершения программ
function ecs.disableInterrupting()
	_G.eventInterruptBackup = package.loaded.event.shouldInterrupt 
	_G.eventSoftInterruptBackup = package.loaded.event.shouldSoftInterrupt 
	
	package.loaded.event.shouldInterrupt = function () return false end
	package.loaded.event.shouldSoftInterrupt = function () return false end
end

--Включение принудительного завершения программ
function ecs.enableInterrupting()
	if _G.eventInterruptBackup then
		package.loaded.event.shouldInterrupt = _G.eventInterruptBackup 
		package.loaded.event.shouldSoftInterrupt = _G.eventSoftInterruptBackup
	else
		error("Cant't enable interrupting beacause of it's already enabled.")
	end
end

function ecs.getScaledResolution(scale, debug)
	--Базовая коррекция масштаба, чтобы всякие умники не писали своими погаными ручонками, чего не следует
	if scale > 1 then
		scale = 1
	elseif scale < 0.1 then
		scale = 0.1
	end

	--Просчет монитора в псевдопикселях - забей, даже объяснять не буду, работает как часы
	local function calculateAspect(screens)
	  local abc = 12

	  if screens == 2 then
	    abc = 28
	  elseif screens > 2 then
	    abc = 28 + (screens - 2) * 16
	  end

	  return abc
	end

	--Рассчитываем пропорцию монитора в псевдопикселях
	local xScreens, yScreens = component.proxy(component.gpu.getScreen()).getAspectRatio()
	local xPixels, yPixels = calculateAspect(xScreens), calculateAspect(yScreens)
	local proportion = xPixels / yPixels

	--Получаем максимально возможное разрешение данной видеокарты
	local xMax, yMax = gpu.maxResolution()

	--Получаем теоретическое максимальное разрешение монитора с учетом его пропорции, но без учета лимита видеокарты
	local newWidth, newHeight
	if proportion >= 1 then
		newWidth = xMax
		newHeight = math.floor(newWidth / proportion / 2)
	else
		newHeight = yMax
		newWidth = math.floor(newHeight * proportion * 2)
	end

	--Получаем оптимальное разрешение для данного монитора с поддержкой видеокарты
	local optimalNewWidth, optimalNewHeight = newWidth, newHeight

	if optimalNewWidth > xMax then
		local difference = newWidth / xMax
		optimalNewWidth = xMax
		optimalNewHeight = math.ceil(newHeight / difference)
	end

	if optimalNewHeight > yMax then
		local difference = newHeight / yMax
		optimalNewHeight = yMax
		optimalNewWidth = math.ceil(newWidth / difference)
	end

	--Корректируем идеальное разрешение по заданному масштабу
	local finalNewWidth, finalNewHeight = math.floor(optimalNewWidth * scale), math.floor(optimalNewHeight * scale)

	--Выводим инфу, если нужно
	if debug then
		print(" ")
		print("Максимальное разрешение: "..xMax.."x"..yMax)
		print("Пропорция монитора: "..xPixels.."x"..yPixels)
		print("Коэффициент пропорции: "..proportion)
		print(" ")
		print("Теоретическое разрешение: "..newWidth.."x"..newHeight)
		print("Оптимизированное разрешение: "..optimalNewWidth.."x"..optimalNewHeight)
		print(" ")
		print("Новое разрешение: "..finalNewWidth.."x"..finalNewHeight)
		print(" ")
	end

	return finalNewWidth, finalNewHeight
end

--Установка масштаба монитора
function ecs.setScale(scale, debug)
	--Устанавливаем выбранное разрешение
	gpu.setResolution(ecs.getScaledResolution(scale, debug))
end

function ecs.rebindGPU(address)
	gpu.bind(address)
end

--Получаем всю инфу об оперативку в килобайтах
function ecs.getInfoAboutRAM()
	local free = math.floor(computer.freeMemory() / 1024)
	local total = math.floor(computer.totalMemory() / 1024)
	local used = total - free

	return free, total, used
end

--Получить информацию о жестких дисках
function ecs.getHDDs()
	local candidates = {}
	for address in component.list("filesystem") do
	  local proxy = component.proxy(address)
	  if proxy.address ~= computer.tmpAddress() and proxy.getLabel() ~= "internet" then
	    local isFloppy, spaceTotal = false, math.floor(proxy.spaceTotal() / 1024)
	    if spaceTotal < 600 then isFloppy = true end
	    table.insert(candidates, {
	    	["spaceTotal"] = spaceTotal,
	    	["spaceUsed"] = math.floor(proxy.spaceUsed() / 1024),
	    	["label"] = proxy.getLabel(),
	    	["address"] = proxy.address,
	    	["isReadOnly"] = proxy.isReadOnly(),
	    	["isFloppy"] = isFloppy,
	    })
	  end
	end
	return candidates
end

--Форматировать диск
function ecs.formatHDD(address)
	local proxy = component.proxy(address)
	local list = proxy.list("")
	ecs.info("auto", "auto", "", "Formatting disk...")
	for _, file in pairs(list) do
		if type(file) == "string" then
			if not proxy.isReadOnly(file) then proxy.remove(file) end
		end
	end
	list = nil
end

--Установить имя жесткого диска
function ecs.setHDDLabel(address, label)
	local proxy = component.proxy(address)
	proxy.setLabel(label or "Untitled")
end

--Найти монтированный путь конкретного адреса диска
function ecs.findMount(address)
  for fs1, path in fs.mounts() do
    if fs1.address == component.get(address) then
      return path
    end
  end
end

function ecs.getArraySize(array)
	local size = 0
	for key in pairs(array) do
		size = size + 1
	end
	return size
end

--Скопировать файлы с одного диска на другой с заменой
function ecs.duplicateFileSystem(fromAddress, toAddress)
	local source, destination = ecs.findMount(fromAddress), ecs.findMount(toAddress)
	ecs.info("auto", "auto", "", "Copying file system...")
	shell.execute("bin/cp -rx "..source.."* "..destination)
end

--Загрузка файла с пастебина
function ecs.getFromPastebin(paste, path)
	local url = "http://pastebin.com/raw.php?i=" .. paste
	ecs.getFileFromUrl(url, path)
end

--Загрузка файла с гитхаба
function ecs.getFromGitHub(url, path)
	url = "https://raw.githubusercontent.com/" .. url
	ecs.getFileFromUrl(url, path)
end

--Загрузить ОС-приложение
function ecs.getOSApplication(application)
    --Если это приложение
    if application.type == "Application" then
		--Удаляем приложение, если оно уже существовало и создаем все нужные папочки
		fs.remove(application.name .. ".app")
		fs.makeDirectory(application.name .. ".app/Resources")
		
		--Загружаем основной исполняемый файл и иконку
		ecs.getFromGitHub(application.url, application.name .. ".app/" .. fs.name(application.name .. ".lua"))
		ecs.getFromGitHub(application.icon, application.name .. ".app/Resources/Icon.pic")

		--Если есть ресурсы, то загружаем ресурсы
		if application.resources then
			for i = 1, #application.resources do
				ecs.getFromGitHub(application.resources[i].url, application.name .. ".app/Resources/" .. application.resources[i].name)
			end
		end

		--Если есть файл "о программе", то грузим и его
		if application.about then
			ecs.getFromGitHub(application.about .. _G.OSSettings.language .. ".txt", application.name .. ".app/Resources/About/" .. _G.OSSettings.language .. ".txt")
		end 

		--Если имеется режим создания ярлыка, то создаем его
		if application.createShortcut then
			local desktopPath = "MineOS/Desktop/"
			local dockPath = "MineOS/System/OS/Dock/"
			
			if application.createShortcut == "dock" then
				ecs.createShortCut(dockPath .. fs.name(application.name) .. ".lnk", application.name .. ".app")
			else
				ecs.createShortCut(desktopPath .. fs.name(application.name) .. ".lnk", application.name .. ".app")
			end
		end

	--Если тип = другой, чужой, а мб и свой пастебин
	elseif application.type == "Pastebin" then
		ecs.getFromPastebin(application.url, application.name)
		
	--Если просто какой-то скрипт
	elseif application.type == "Script" or application.type == "Library" or application.type == "Icon" or application.type == "Wallpaper" then
		ecs.getFromGitHub(application.url, application.name)
	
	--А если ваще какая-то абстрактная хуйня, либо ссылка на веб, то загружаем по УРЛ-ке
	else
		ecs.getFileFromUrl(application.url, application.name)
	end
end

--Получить список приложений, которые требуется обновить
function ecs.getAppsToUpdate(debug)
	--Задаем стартовые пути
	local pathToApplicationsFile = "MineOS/System/OS/Applications.txt"
	local pathToSecondApplicationsFile = "MineOS/System/OS/Applications2.txt"
	--Путь к файл-листу на пастебине
	local paste = "3j2x4dDn"
	--Выводим инфу
	local oldPixels
	if debug then oldPixels = ecs.info("auto", "auto", " ", "Checking for updates...") end
	--Получаем свеженький файл
	ecs.getFromPastebin(paste, pathToSecondApplicationsFile)
	--Читаем оба файла
	local file = io.open(pathToApplicationsFile, "r")
	local applications = serialization.unserialize(file:read("*a"))
	file:close()
	--И второй
	file = io.open(pathToSecondApplicationsFile, "r")
	local applications2 = serialization.unserialize(file:read("*a"))
	file:close()

	local countOfUpdates = 0

	--Просматриваем свеженький файлик и анализируем, че в нем нового, все старое удаляем
	local i = 1
	while true do
		--Разрыв цикла
		if i > #applications2 then break end
		--Новая версия файла
		local newVersion, oldVersion = applications2[i].version, 0
		--Получаем старую версию этого файла
		for j = 1, #applications do
			if applications2[i].name == applications[j].name then
				oldVersion = applications[j].version or 0
				break
			end
		end
		--Если новая версия новее, чем старая, то добавить в массив то, что нужно обновить
		if newVersion > oldVersion then
			applications2[i].needToUpdate = true
			countOfUpdates = countOfUpdates + 1
		end

		i = i + 1
	end
	--Если чет рисовалось, то стереть на хер
	if oldPixels then ecs.drawOldPixels(oldPixels) end
	--Возвращаем массив с тем, че нужно обновить и просто старый аппликашнс на всякий случай
	return applications2, countOfUpdates
end

--Сделать строку пригодной для отображения в ОпенКомпах
--Заменяет табсы на пробелы и виндовый возврат каретки на человеческий UNIX-овский
function ecs.stringOptimize(sto4ka, indentatonWidth)
    sto4ka = string.gsub(sto4ka, "\r\n", "\n")
    sto4ka = string.gsub(sto4ka, "	", string.rep(" ", indentatonWidth or 2))
    return stro4ka
end

--ИЗ ДЕСЯТИЧНОЙ В ШЕСТНАДЦАТИРИЧНУЮ
function ecs.decToBase(IN,BASE)
    local hexCode = "0123456789ABCDEFGHIJKLMNOPQRSTUVW"
    OUT = ""
    local ostatok = 0
    while IN>0 do
        ostatok = math.fmod(IN,BASE) + 1
        IN = math.floor(IN/BASE)
        OUT = string.sub(hexCode,ostatok,ostatok)..OUT
    end
    if #OUT == 1 then OUT = "0"..OUT end
    if OUT == "" then OUT = "00" end
    return OUT
end

--Правильное конвертирование HEX-переменной в строковую
function ecs.HEXtoString(color, bitCount, withNull)
	local stro4ka = string.format("%X",color)
	local sStro4ka = unicode.len(stro4ka)
	if sStro4ka < bitCount then
		stro4ka = string.rep("0", bitCount - sStro4ka) .. stro4ka
	end
	sStro4ka = nil
	if withNull then return "0x"..stro4ka else return stro4ka end
end

--КЛИКНУЛИ ЛИ В ЗОНУ
function ecs.clickedAtArea(x,y,sx,sy,ex,ey)
  if (x >= sx) and (x <= ex) and (y >= sy) and (y <= ey) then return true end    
  return false
end

--Заливка всего экрана указанным цветом
function ecs.clearScreen(color)
  if color then gpu.setBackground(color) end
  term.clear()
end

--Установка пикселя нужного цвета
function ecs.setPixel(x,y,color)
  gpu.setBackground(color)
  gpu.set(x,y," ")
end

--Простая установка цветов в одну строку, ибо я ленивый
function ecs.setColor(background, foreground)
	gpu.setBackground(background)
	gpu.setForeground(foreground)
end

--Цветной текст
function ecs.colorText(x,y,textColor,text)
  gpu.setForeground(textColor)
  gpu.set(x,y,text)
end

--Цветной текст с жопкой!
function ecs.colorTextWithBack(x,y,textColor,backColor,text)
  gpu.setForeground(textColor)
  gpu.setBackground(backColor)
  gpu.set(x,y,text)
end

--Инверсия цвета
function ecs.invertColor(color)
  return 0xffffff - color
end

--Адаптивный текст, подстраивающийся под фон
function ecs.adaptiveText(x,y,text,textColor)
  gpu.setForeground(textColor)
  x = x - 1
  for i=1,unicode.len(text) do
    local info = {gpu.get(x+i,y)}
    gpu.setBackground(info[3])
    gpu.set(x+i,y,unicode.sub(text,i,i))
  end
end

--Костыльная замена обычному string.find()
--Работает медленнее, но хотя бы поддерживает юникод
function unicode.find(str, pattern, init, plain)
	if init then
		if init < 0 then
			init = -#unicode.sub(str,init)
		elseif init > 0 then
			init = #unicode.sub(str,1,init-1)+1
		end
	end
	
	a, b = string.find(str, pattern, init, plain)
	
	if a then
		local ap,bp = str:sub(1,a-1), str:sub(a,b)
		a = unicode.len(ap)+1
		b = a + unicode.len(bp)-1
		return a,b
	else
		return a
	end
end

--Умный текст по аналогии с майнчатовским. Ставишь символ параграфа, указываешь хуйню - и хуякс! Работает!
function ecs.smartText(x, y, text)
	local sText = unicode.len(text)
	local specialSymbol = "§"
	--Разбираем по кусочкам строку и получаем цвета
	local massiv = {}
	local iterator = 1
	local currentColor = gpu.getForeground()
	while iterator <= sText do
		local symbol = unicode.sub(text, iterator, iterator)
		if symbol == specialSymbol then
			currentColor = ecs.colors[unicode.sub(text, iterator + 1, iterator + 1) or "f"]
			iterator = iterator + 1
		else
			table.insert(massiv, {symbol, currentColor})
		end
		symbol = nil
		iterator = iterator + 1
	end
	x = x - 1
	for i = 1, #massiv do
		if currentColor ~= massiv[i][2] then currentColor = massiv[i][2]; gpu.setForeground(massiv[i][2]) end
		gpu.set(x + i, y, massiv[i][1])
	end
end

--Аналог умного текста, но использующий HEX-цвета для кодировки
function ecs.formattedText(x, y, text, limit)
	--Ограничение длины строки
	limit = limit or math.huge
	--Стартовая позиция курсора для отрисовки
	local xPos = x
	--Создаем массив символов данной строки
	local symbols = {}
	for i = 1, unicode.len(text) do table.insert(symbols, unicode.sub(text, i, i)) end
	--Перебираем все символы строки, пока не переберем все или не достигнем указанного лимита
	local i = 1
	while i <= #symbols and i <= limit do
		--Если находим символ параграфа, то
		if symbols[i] == "§" then
			--Меняем цвет текста на указанный
			gpu.setForeground(tonumber("0x" .. symbols[i+1] .. symbols[i+2] .. symbols[i+3] .. symbols[i+4] .. symbols[i+5] .. symbols[i+6]))
			--Увеличиваем лимит на 7, т.к.
			limit = limit + 7
			--Сдвигаем итератор цикла на 7
			i = i + 7
		end
		--Рисуем символ на нужной позиции
		gpu.set(xPos, y, symbols[i])
		--Увеличиваем позицию курсора и итератор на 1
		xPos = xPos + 1
		i = i + 1
	end
end

--Инвертированный текст на основе цвета фона
function ecs.invertedText(x,y,symbol)
  local info = {gpu.get(x,y)}
  ecs.adaptiveText(x,y,symbol,ecs.invertColor(info[3]))
end

--Адаптивное округление числа
function ecs.adaptiveRound(chislo)
  local celaya,drobnaya = math.modf(chislo)
  if drobnaya >= 0.5 then
    return (celaya + 1)
  else
    return celaya
  end
end

--Округление до опред. кол-ва знаков после запятой
function ecs.round(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

--Обычный квадрат указанного цвета
function ecs.square(x,y,width,height,color)
  gpu.setBackground(color)
  gpu.fill(x,y,width,height," ")
end

--Юникодовская рамка
function ecs.border(x, y, width, height, back, fore)
	local stringUp = "┌"..string.rep("─", width - 2).."┐"
	local stringDown = "└"..string.rep("─", width - 2).."┘"
	gpu.setForeground(fore)
	gpu.setBackground(back)
	gpu.set(x, y, stringUp)
	gpu.set(x, y + height - 1, stringDown)

	local yPos = 1
	for i = 1, (height - 2) do
		gpu.set(x, y + yPos, "│")
		gpu.set(x + width - 1, y + yPos, "│")
		yPos = yPos + 1
	end
end

--Кнопка в виде текста в рамке
function ecs.drawFramedButton(x, y, width, height, text, color)
	ecs.border(x, y, width, height, gpu.getBackground(), color)
	gpu.fill(x + 1, y + 1, width - 2, height - 2, " ")
	x = x + math.floor(width / 2 - unicode.len(text) / 2)
	y = y + math.floor(width / 2 - 1)
	gpu.set(x, y, text)
end

--Юникодовский разделитель
function ecs.separator(x, y, width, back, fore)
	ecs.colorTextWithBack(x, y, fore, back, string.rep("─", width))
end

--Автоматическое центрирование текста по указанной координате (x, y, xy)
function ecs.centerText(mode,coord,text)
	local dlina = unicode.len(text)
	local xSize,ySize = gpu.getResolution()

	if mode == "x" then
		gpu.set(math.floor(xSize/2-dlina/2),coord,text)
	elseif mode == "y" then
		gpu.set(coord,math.floor(ySize/2),text)
	else
		gpu.set(math.floor(xSize/2-dlina/2),math.floor(ySize/2),text)
	end
end

--Отрисовка "изображения" по указанному массиву
function ecs.drawCustomImage(x,y,pixels)
	x = x - 1
	y = y - 1
	local pixelsWidth = #pixels[1]
	local pixelsHeight = #pixels
	local xEnd = x + pixelsWidth
	local yEnd = y + pixelsHeight

	for i=1,pixelsHeight do
		for j=1,pixelsWidth do
			if pixels[i][j][3] ~= "#" then
				if gpu.getBackground() ~= pixels[i][j][1] then gpu.setBackground(pixels[i][j][1]) end
				if gpu.getForeground() ~= pixels[i][j][2] then gpu.setForeground(pixels[i][j][2]) end
				gpu.set(x+j,y+i,pixels[i][j][3])
			end
		end
	end

	return (x+1),(y+1),xEnd,yEnd
end

--Корректировка стартовых координат. Core-функция для всех моих программ
function ecs.correctStartCoords(xStart,yStart,xWindowSize,yWindowSize)
	local xSize,ySize = gpu.getResolution()
	if xStart == "auto" then
		xStart = math.floor(xSize/2 - xWindowSize/2)
	end
	if yStart == "auto" then
		yStart = math.ceil(ySize/2 - yWindowSize/2)
	end
	return xStart,yStart
end

--Запомнить область пикселей и возвратить ее в виде массива
function ecs.rememberOldPixels(x, y, x2, y2)
	local newPNGMassiv = { ["backgrounds"] = {} }
	local xSize, ySize = gpu.getResolution()
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

	xSize, ySize = nil, nil
	return newPNGMassiv
end

--Нарисовать запомненные ранее пиксели из массива
function ecs.drawOldPixels(massivSudaPihay)
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

--Ограничение длины строки. Маст-хев функция.
function ecs.stringLimit(mode, text, size, noDots)
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

--Получить текущее реальное время компьютера, хостящего сервер майна
function ecs.getHostTime(timezone)
	timezone = timezone or 2
	--Создаем файл с записанной в него парашей
    local file = io.open("HostTime.tmp", "w")
    file:write("")
    file:close()
    --Коррекция времени на основе часового пояса
    local timeCorrection = timezone * 3600
    --Получаем дату изменения файла в юникс-виде
    local lastModified = tonumber(string.sub(fs.lastModified("HostTime.tmp"), 1, -4)) + timeCorrection
    --Удаляем файл, ибо на хуй он нам не нужен
    fs.remove("HostTime.tmp")
    --Конвертируем юникс-время в норм время
    local year, month, day, hour, minute, second = os.date("%Y", lastModified), os.date("%m", lastModified), os.date("%d", lastModified), os.date("%H", lastModified), os.date("%M", lastModified), os.date("%S", lastModified)
    --Возвращаем все
    return tonumber(day), tonumber(month), tonumber(year), tonumber(hour), tonumber(minute), tonumber(second)
end

--Получить спискок файлов из конкретной директории, костыль
function ecs.getFileList(path)
	local list = fs.list(path)
	local massiv = {}
	for file in list do
		--if string.find(file, "%/$") then file = unicode.sub(file, 1, -2) end
		table.insert(massiv, file)
	end
	list = nil
	return massiv
end

--Получить файловое древо. Сильно нагружает систему, только для дебага!
function ecs.getFileTree(path)
	local massiv = {}
	local list = ecs.getFileList(path)
	for key, file in pairs(list) do
		if fs.isDirectory(path.."/"..file) then
			table.insert(massiv, getFileTree(path.."/"..file))
		else
			table.insert(massiv, file)
		end
	end
	list = nil

	return massiv
end

--Поиск по файловой системе
function ecs.find(path, cheBudemIskat)
	--Массив, в котором будут находиться все найденные соответствия
	local massivNaydennogoGovna = {}
	--Костыль, но удобный
	local function dofind(path, cheBudemIskat)
		--Получаем список файлов в директории
		local list = ecs.getFileList(path)
		--Перебираем все элементы файл листа
		for key, file in pairs(list) do
			--Путь к файлу
			local pathToFile = path..file
			--Если нашло совпадение в имени файла, то выдает путь к этому файлу
			if string.find(unicode.lower(file), unicode.lower(cheBudemIskat)) then
				table.insert(massivNaydennogoGovna, pathToFile)
			end
			--Анализ, что делать дальше
			if fs.isDirectory(pathToFile) then
				dofind(pathToFile, cheBudemIskat)
			end
			--Очищаем оперативку
			pathToFile = nil
		end
		--Очищаем оперативку
		list = nil
	end
	--Выполняем функцию
	dofind(path, cheBudemIskat)
	--Возвращаем, че нашло
	return massivNaydennogoGovna
end

--Получение формата файла
function ecs.getFileFormat(path)
	local name = fs.name(path)
	local starting, ending = string.find(name, "(.)%.[%d%w]*$")
	if starting == nil then
		return nil
	else
		return unicode.sub(name,starting + 1, -1)
	end
	name, starting, ending = nil, nil, nil
end

--Проверить, скрытый ли файл (.пидор, .хуй = true; пидор, хуй = false)
function ecs.isFileHidden(path)
	local name = fs.name(path)
	local starting, ending = string.find(name, "^%.(.*)$")
	if starting == nil then
		return false
	else
		return true
	end
	name, starting, ending = nil, nil, nil
end

--Скрыть формат файла
function ecs.hideFileFormat(path)
	local name = fs.name(path)
	local fileFormat = ecs.getFileFormat(name)
	if fileFormat == nil then
		return name
	else
		return unicode.sub(name, 1, unicode.len(name) - unicode.len(fileFormat))
	end
end

--Ожидание клика либо нажатия какой-либо клавиши
function ecs.waitForTouchOrClick()
	while true do
		local e = { event.pull() }
		if e[1] == "key_down" or e[1] == "touch" then break end
	end
end

--То же самое, но в сокращенном варианте
function ecs.wait()
	ecs.waitForTouchOrClick()
end

--Нарисовать кнопочки закрытия окна
function ecs.drawCloses(x, y, active)
	local symbol = "⮾"
	ecs.colorText(x, y , (active == 1 and ecs.colors.blue) or 0xCC4C4C, symbol)
	ecs.colorText(x + 2, y , (active == 2 and ecs.colors.blue) or 0xDEDE6C, symbol)
	ecs.colorText(x + 4, y , (active == 3 and ecs.colors.blue) or 0x57A64E, symbol)
end

--Нарисовать верхнюю оконную панель с выбором объектов
function ecs.drawTopBar(x, y, width, selectedObject, background, foreground, ...)
	local objects = { ... }
	ecs.square(x, y, width, 3, background)
	local widthOfObjects = 0
	local spaceBetween = 2
	for i = 1, #objects do
		widthOfObjects = widthOfObjects + unicode.len(objects[i][1]) + spaceBetween
	end
	local xPos = x + math.floor(width / 2 - widthOfObjects / 2)
	for i = 1, #objects do
		if i == selectedObject then
			ecs.square(xPos, y, unicode.len(objects[i][1]) + spaceBetween, 3, ecs.colors.blue)
			gpu.setForeground(0xffffff)
		else
			gpu.setBackground(background)
			gpu.setForeground(foreground)
		end
		gpu.set(xPos + spaceBetween / 2, y + 2, objects[i][1])
		gpu.set(xPos + math.ceil(unicode.len(objects[i][1]) / 2), y + 1, objects[i][2])

		xPos = xPos + unicode.len(objects[i][1]) + spaceBetween
	end
end

--Нарисовать топ-меню, горизонтальная полоска такая с текстами
function ecs.drawTopMenu(x, y, width, color, selectedObject, ...)
	local objects = { ... }
	local objectsToReturn = {}
	local xPos = x + 2
	local spaceBetween = 2
	ecs.square(x, y, width, 1, color)
	for i = 1, #objects do
		if i == selectedObject then
			ecs.square(xPos - 1, y, unicode.len(objects[i][1]) + spaceBetween, 1, ecs.colors.blue)
			gpu.setForeground(0xffffff)
			gpu.set(xPos, y, objects[i][1])
			gpu.setForeground(objects[i][2])
			gpu.setBackground(color)
		else
			if gpu.getForeground() ~= objects[i][2] then gpu.setForeground(objects[i][2]) end
			gpu.set(xPos, y, objects[i][1])
		end
		objectsToReturn[objects[i][1]] = { xPos, y, xPos + unicode.len(objects[i][1]) - 1, y, i }
		xPos = xPos + unicode.len(objects[i][1]) + spaceBetween
	end
	return objectsToReturn
end

--Функция отрисовки кнопки указанной ширины
function ecs.drawButton(x,y,width,height,text,backColor,textColor)
	x,y = ecs.correctStartCoords(x,y,width,height)

	local textPosX = math.floor(x + width / 2 - unicode.len(text) / 2)
	local textPosY = math.floor(y + height / 2)
	ecs.square(x,y,width,height,backColor)
	ecs.colorText(textPosX,textPosY,textColor,text)

	return x, y, (x + width - 1), (y + height - 1)
end

--Отрисовка кнопки с указанными отступами от текста
function ecs.drawAdaptiveButton(x,y,offsetX,offsetY,text,backColor,textColor)
	local length = unicode.len(text)
	local width = offsetX*2 + length
	local height = offsetY*2 + 1

	x,y = ecs.correctStartCoords(x,y,width,height)

	ecs.square(x,y,width,height,backColor)
	ecs.colorText(x+offsetX,y+offsetY,textColor,text)

	return x,y,(x+width-1),(y+height-1)
end

--Отрисовка оконной "тени"
function ecs.windowShadow(x,y,width,height)
	gpu.setBackground(ecs.windowColors.shadow)
	gpu.fill(x+width,y+1,2,height," ")
	gpu.fill(x+1,y+height,width,1," ")
end

--Просто белое окошко с тенью
function ecs.blankWindow(x,y,width,height)
	local oldPixels = ecs.rememberOldPixels(x,y,x+width+1,y+height)

	ecs.square(x,y,width,height,ecs.windowColors.background)

	ecs.windowShadow(x,y,width,height)

	return oldPixels
end

--Белое окошко, но уже с титлом вверху!
function ecs.emptyWindow(x,y,width,height,title)

	local oldPixels = ecs.rememberOldPixels(x,y,x+width+1,y+height)

	--ОКНО
	gpu.setBackground(ecs.windowColors.background)
	gpu.fill(x,y+1,width,height-1," ")

	--ТАБ СВЕРХУ
	gpu.setBackground(ecs.windowColors.tab)
	gpu.fill(x,y,width,1," ")

	--ТИТЛ
	gpu.setForeground(ecs.windowColors.title)
	local textPosX = x + math.floor(width/2-unicode.len(title)/2) -1
	gpu.set(textPosX,y,title)

	--ТЕНЬ
	ecs.windowShadow(x,y,width,height)

	return oldPixels

end

function ecs.getWordsArrayFromString(s)
	local words = {} 
	for word in string.gmatch(s, "[^%s]+") do table.insert(words, word) end
	return words
end

--Функция по переносу слов на новую строку в зависимости от ограничения по ширине
function ecs.stringWrap(strings, limit)
	local currentString = 1
	while currentString <= #strings do
		local words = ecs.getWordsArrayFromString(tostring(strings[currentString]))

		local newStringThatFormedFromWords, oldStringThatFormedFromWords = "", ""
		local word = 1
		local overflow = false
		while word <= #words do
			oldStringThatFormedFromWords = oldStringThatFormedFromWords .. (word > 1 and " " or "") .. words[word]
			if unicode.len(oldStringThatFormedFromWords) > limit then
				--ЕБЛО
				if unicode.len(words[word]) > limit then
					local left = unicode.sub(oldStringThatFormedFromWords, 1, limit)
					local right = unicode.sub(strings[currentString], unicode.len(left) + 1, -1)
					overflow = true
					strings[currentString] = left
					if strings[currentString + 1] then
						strings[currentString + 1] = right .. " " .. strings[currentString + 1]
					else
						strings[currentString + 1] = right
					end 
				end
				break
			else
				newStringThatFormedFromWords = oldStringThatFormedFromWords
			end
			word = word + 1
		end

		if word <= #words and not overflow then
			local fuckToAdd = table.concat(words, " ", word, #words)
			if strings[currentString + 1] then
				strings[currentString + 1] = fuckToAdd .. " " .. strings[currentString + 1]
			else
				strings[currentString + 1] = fuckToAdd
			end
			strings[currentString] = newStringThatFormedFromWords
		end

		currentString = currentString + 1
	end

	return strings
	-- local firstSlice, secondSlice
	-- local i = 1
	-- while i <= #strings do
	-- 	if unicode.len(strings[i]) > limit then
	-- 		firstSlice = unicode.sub(strings[i], 1, limit)
	-- 		secondSlice = unicode.sub(strings[i], limit + 1, -1)
			
	-- 		strings[i] = firstSlice
	-- 		table.insert(strings, i + 1, secondSlice)
	-- 	end
	-- 	i = i + 1
	-- end
	-- return strings
end

--Моя любимая функция ошибки C:
function ecs.error(...)
	local args = {...}
	local text = ""
	if #args > 1 then
		for i = 1, #args do
			--text = text .. "[" .. i .. "] = " .. tostring(args[i])
			if type(args[i]) == "string" then args[i] = "\"" .. args[i] .. "\"" end 
			text = text .. tostring(args[i])
			if i ~= #args then text = text .. ", " end
		end
	else
		text = tostring(args[1])
	end
	ecs.universalWindow("auto", "auto", math.ceil(gpu.getResolution() * 0.45), ecs.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x880000, "Ошибка!"}, {"EmptyLine"}, {"WrappedText", 0x262626, text}, {"EmptyLine"}, {"Button", {0x880000, 0xffffff, "OK!"}})
end

--Очистить экран, установить комфортные цвета и поставить курсок на 1, 1
function ecs.prepareToExit(color1, color2)
	term.setCursor(1, 1)
	ecs.clearScreen(color1 or 0x333333)
	gpu.setForeground(color2 or 0xffffff)
	gpu.set(1, 1, "")
end

--Конвертация из юникода в символ. Вроде норм, а вроде и не норм. Но полезно.
function ecs.convertCodeToSymbol(code)
	local symbol
	if code ~= 0 and code ~= 13 and code ~= 8 and code ~= 9 and code ~= 200 and code ~= 208 and code ~= 203 and code ~= 205 and not keyboard.isControlDown() then
		symbol = unicode.char(code)
		if keyboard.isShiftPressed then symbol = unicode.upper(symbol) end
	end
	return symbol
end

--Шкала прогресса - маст-хев!
function ecs.progressBar(x, y, width, height, background, foreground, percent)
	local activeWidth = math.ceil(width * percent / 100)
	ecs.square(x, y, width, height, background)
	ecs.square(x, y, activeWidth, height, foreground)
end

--Окошко с прогрессбаром! Давно хотел
function ecs.progressWindow(x, y, width, percent, text, returnOldPixels)
	local height = 6
	local barWidth = width - 6

	x, y = ecs.correctStartCoords(x, y, width, height)

	local oldPixels
	if returnOldPixels then
		oldPixels = ecs.rememberOldPixels(x, y, x + width + 1, y + height)
	end

	ecs.emptyWindow(x, y, width, height, " ")
	ecs.colorTextWithBack(x + math.floor(width / 2 - unicode.len(text) / 2), y + 4, 0x000000, ecs.windowColors.background, text)
	ecs.progressBar(x + 3, y + 2, barWidth, 1, 0xCCCCCC, ecs.colors.blue, percent)

	return oldPixels
end

--Функция для ввода текста в мини-поле.
function ecs.inputText(x, y, limit, cheBiloVvedeno, background, foreground, justDrawNotEvent, maskTextWith)
	limit = limit or 10
	cheBiloVvedeno = cheBiloVvedeno or ""
	background = background or 0xffffff
	foreground = foreground or 0x000000

	gpu.setBackground(background)
	gpu.setForeground(foreground)
	gpu.fill(x, y, limit, 1, " ")

	local text = cheBiloVvedeno

	local function draw()
		term.setCursorBlink(false)

		local dlina = unicode.len(text)
		local xCursor = x + dlina
		if xCursor > (x + limit - 1) then xCursor = (x + limit - 1) end

		if maskTextWith then
			gpu.set(x, y, ecs.stringLimit("start", string.rep("●", dlina), limit))
		else
			gpu.set(x, y, ecs.stringLimit("start", text, limit))
		end

		term.setCursor(xCursor, y)

		term.setCursorBlink(true)
	end

	draw()

	if justDrawNotEvent then term.setCursorBlink(false); return cheBiloVvedeno end

	while true do
		local e = {event.pull()}
		if e[1] == "key_down" then
			if e[4] == 14 then
				term.setCursorBlink(false)
				text = unicode.sub(text, 1, -2)
				if unicode.len(text) < limit then gpu.set(x + unicode.len(text), y, " ") end
				draw()
			elseif e[4] == 28 then
				term.setCursorBlink(false)
				return text
			else
				local symbol = ecs.convertCodeToSymbol(e[3])
				if symbol then
					text = text..symbol
					draw()
				end
			end
		elseif e[1] == "touch" then
			term.setCursorBlink(false)
			return text
		elseif e[1] == "clipboard" then
			if e[3] then
				text = text..e[3]
				draw()
			end
		end
	end
end

--Функция парсинга сообщения об ошибке. Конвертирует из строки в массив и переводит на русский.
function ecs.parseErrorMessage(error, translate)

	local parsedError = {}

	--ПОИСК ЭНТЕРОВ
	local starting, ending, searchFrom = nil, nil, 1
	for i = 1, unicode.len(error) do
		starting, ending = string.find(error, "\n", searchFrom)
		if starting then
			table.insert(parsedError, unicode.sub(error, searchFrom, starting - 1))
			searchFrom = ending + 1
		else
			break
		end
	end

	--На всякий случай, если сообщение об ошибке без энтеров вообще, т.е. однострочное
	if #parsedError == 0 and error ~= "" and error ~= nil and error ~= " " then
		table.insert(parsedError, error)
	end

	--Замена /r/n и табсов
	for i = 1, #parsedError do
		parsedError[i] = string.gsub(parsedError[i], "\r\n", "\n")
		parsedError[i] = string.gsub(parsedError[i], "	", "    ")
	end

	if translate then
		for i = 1, #parsedError do
			parsedError[i] = string.gsub(parsedError[i], "interrupted", "Выполнение программы прервано пользователем")
			parsedError[i] = string.gsub(parsedError[i], " got ", " получена ")
			parsedError[i] = string.gsub(parsedError[i], " expected,", " ожидается,")
			parsedError[i] = string.gsub(parsedError[i], "bad argument #", "Неверный аргумент #")
			parsedError[i] = string.gsub(parsedError[i], "stack traceback", "Отслеживание ошибки")
			parsedError[i] = string.gsub(parsedError[i], "tail calls", "Дочерние вызовы")
			parsedError[i] = string.gsub(parsedError[i], "in function", "в функции")
			parsedError[i] = string.gsub(parsedError[i], "in main chunk", "в основной программе")
			parsedError[i] = string.gsub(parsedError[i], "unexpected symbol near", "неожиданный символ рядом с")
			parsedError[i] = string.gsub(parsedError[i], "attempt to index", "пытаюсь получить значение индекса массива")
			parsedError[i] = string.gsub(parsedError[i], "attempt to get length of", "не удается получить длину")
			parsedError[i] = string.gsub(parsedError[i], ": ", ", ")
			parsedError[i] = string.gsub(parsedError[i], " module ", " модуль ")
			parsedError[i] = string.gsub(parsedError[i], "not found", "не найден")
			parsedError[i] = string.gsub(parsedError[i], "no field package.preload", "не найдена библиотека")
			parsedError[i] = string.gsub(parsedError[i], "no file", "нет файла")
			parsedError[i] = string.gsub(parsedError[i], "local", "локальной")
			parsedError[i] = string.gsub(parsedError[i], "global", "глобальной")
			parsedError[i] = string.gsub(parsedError[i], "no primary", "не найден компонент")
			parsedError[i] = string.gsub(parsedError[i], "available", "в доступе")
			parsedError[i] = string.gsub(parsedError[i], "attempt to concatenate", "не могу присоединить")
			parsedError[i] = string.gsub(parsedError[i], "a nil value", "переменная равна nil")
		end
	end

	starting, ending = nil, nil

	return parsedError
end

--Отображение сообщения об ошибке компиляции скрипта в красивом окошке.
function ecs.displayCompileMessage(y, reason, translate, withAnimation)

	local xSize, ySize = gpu.getResolution()

	--Переводим причину в массив
	reason = ecs.parseErrorMessage(reason, translate)

	--Получаем ширину и высоту окошка
	local width = math.floor(xSize * 7 / 10)
	local textWidth = width - 11
	reason = ecs.stringWrap(reason, textWidth)
	local height = #reason + 6

	--Просчет вот этой хуйни, аааахаахах
	local difference = ySize - (height + y)
	if difference < 0 then
		for i = 1, (math.abs(difference) + 1) do
			table.remove(reason, #reason)
		end
		table.insert(reason, "…")
		height = #reason + 6
	end

	local x = math.floor(xSize / 2 - width / 2)

	--Иконочка воскл знака на красном фоне
	local errorImage = {
		{{0xff0000,0xffffff,"#"},{0xff0000,0xffffff,"#"},{0xff0000,0xffffff," "},{0xff0000,0xffffff,"#"},{0xff0000,0xffffff,"#"}},
		{{0xff0000,0xffffff,"#"},{0xff0000,0xffffff," "},{0xff0000,0xffffff,"!"},{0xff0000,0xffffff," "},{0xff0000,0xffffff,"#"}},
		{{0xff0000,0xffffff," "},{0xff0000,0xffffff," "},{0xff0000,0xffffff," "},{0xff0000,0xffffff," "},{0xff0000,0xffffff," "}}
	}

	--Запоминаем, че было отображено
	local oldPixels

	local function drawCompileMessage(y)
		ecs.square(x, y, width, height, ecs.windowColors.background)
		ecs.windowShadow(x, y, width, height)
			--Рисуем воскл знак
		ecs.drawCustomImage(x + 2, y + 1, errorImage)

		--Рисуем текст
		local yPos = y + 1
		local xPos = x + 9
		gpu.setBackground(ecs.windowColors.background)

		ecs.colorText(xPos, yPos, ecs.windowColors.usualText, "Код ошибки:")
		yPos = yPos + 2

		gpu.setForeground( 0xcc0000 )
		for i = 1, #reason do
			gpu.set(xPos, yPos, reason[i])
			yPos = yPos + 1
		end

		yPos = yPos + 1
		ecs.colorText(xPos, yPos, ecs.windowColors.usualText, ecs.stringLimit("end", "Нажмите любую клавишу, чтобы продолжить", textWidth))
	end

	--Типа анимация, ога
	if withAnimation then
		oldPixels = ecs.rememberOldPixels(x, 1, x + width + 1, height + 1)
		for i = -height, 1, 1 do
			drawCompileMessage(i)
			os.sleep(0.01)
		end
	else
		oldPixels = ecs.rememberOldPixels(x, y, x + width + 1, y + height)
		drawCompileMessage(y)
	end

	--Пикаем звуком кароч
	for i = 1, 3 do
		computer.beep(1000)
	end
	--Ждем сам знаешь чего
	ecs.wait()
	--Рисуем, че было нарисовано
	ecs.drawOldPixels(oldPixels)
end

--Спросить, заменять ли файл (если таковой уже имеется)
function ecs.askForReplaceFile(path)
	if fs.exists(path) then
		local action = ecs.universalWindow("auto", "auto", 46, ecs.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x262626, "Файл \"".. fs.name(path) .. "\" уже имеется в этом месте."}, {"CenterText", 0x262626, "Заменить его перемещаемым объектом?"}, {"EmptyLine"}, {"Button", {0xdddddd, 0x262626, "Оставить оба"}, {0xffffff, 0x262626, "Отмена"}, {ecs.colors.lightBlue, 0xffffff, "Заменить"}})
		if action[1] == "Оставить оба" then
			return "keepBoth"
		elseif action[2] == "Отмена" then
			return "cancel"
		else
			return "replace"
		end
	end
end

--Проверить имя файла на соответствие критериям
function ecs.checkName(name, path)
	--Если ввели хуйню какую-то, то
	if name == "" or name == " " or name == nil then
		ecs.error("Неверное имя файла.")
		return false
	else
		--Если файл с новым путем уже существует, то
		if fs.exists(path .. name) then
			ecs.error("Файл \"".. name .. "\" уже имеется в этом месте.")
			return false
		--А если все заебок, то
		else
			return true
		end
	end
end

--Переименование файлов (для операционки)
function ecs.rename(mainPath)
	--Задаем стартовую щнягу
	local name = fs.name(mainPath)
	path = fs.path(mainPath)
	--Рисуем окошко ввода нового имени файла
	local inputs = ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x262626, "Переименовать"}, {"EmptyLine"}, {"Input", 0x262626, 0x880000, name}, {"EmptyLine"}, {"Button", {0xbbbbbb, 0xffffff, "OK"}})
	--Переименовываем
	if ecs.checkName(inputs[1], path) then
		fs.rename(mainPath, path .. inputs[1])
	end
end

--Создать новую папку (для операционки)
function ecs.newFolder(path)
	--Рисуем окошко ввода нового имени файла
	local inputs = ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x262626, "Новая папка"}, {"EmptyLine"}, {"Input", 0x262626, 0x880000, ""}, {"EmptyLine"}, {"Button", {0xbbbbbb, 0xffffff, "OK"}})

	if ecs.checkName(inputs[1], path) then
		fs.makeDirectory(path .. inputs[1])
	end
end

--Создать новый файл (для операционки)
function ecs.newFile(path)
	--Рисуем окошко ввода нового имени файла
	local inputs = ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x262626, "Новый файл"}, {"EmptyLine"}, {"Input", 0x262626, 0x880000, ""}, {"EmptyLine"}, {"Button", {0xbbbbbb, 0xffffff, "OK"}})

	if ecs.checkName(inputs[1], path) then
		ecs.prepareToExit()
		ecs.editFile(path .. inputs[1])
	end
end

--Создать новое приложение (для операционки)
function ecs.newApplication(path, startName)
	--Рисуем окошко ввода нового имени файла
	local inputs
	if not startName then
		inputs = ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x262626, "Новое приложение"}, {"EmptyLine"}, {"Input", 0x262626, 0x880000, "Введите имя"}, {"EmptyLine"}, {"Button", {0xbbbbbb, 0xffffff, "OK"}})
	end

	if ecs.checkName(inputs[1] .. ".app", path) then
		local name = path .. inputs[1] .. ".app/Resources/"
		fs.makeDirectory(name)
		fs.copy("MineOS/System/OS/Icons/SampleIcon.pic", name .. "Icon.pic")
		local file = io.open(path .. inputs[1] .. ".app/" .. inputs[1] .. ".lua", "w")
		file:write("local ecs = require(\"ecs\")", "\n")
		file:write("ecs.universalWindow(\"auto\", \"auto\", 30, 0xeeeeee, true, {\"EmptyLine\"}, {\"CenterText\", 0x262626, \"Hello world!\"}, {\"EmptyLine\"}, {\"Button\", {0x880000, 0xffffff, \"Hello!\"}})", "\n")
		file:close()
	end
end

--Создать приложение на основе существующего ЛУА-файла
function ecs.newApplicationFromLuaFile(pathToLuaFile, pathWhereToCreateApplication)
	local data = ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x000000, "Новое приложение"}, {"EmptyLine"}, {"Input", 0x262626, 0x880000, "Имя приложения"}, {"Input", 0x262626, 0x880000, "Путь к иконке приложения"}, {"EmptyLine"}, {"Button", {0xbbbbbb, 0xffffff, "OK"}})
	data[1] = data[1] or "MyApplication"
	data[2] = data[2] or "MineOS/System/OS/Icons/SampleIcon.pic"
	if fs.exists(data[2]) then
		fs.makeDirectory(pathWhereToCreateApplication .. "/" .. data[1] .. ".app/Resources")
		fs.copy(pathToLuaFile, pathWhereToCreateApplication .. "/" .. data[1] .. ".app/" .. data[1] .. ".lua")
		fs.copy(data[2], pathWhereToCreateApplication .. "/" .. data[1] .. ".app/Resources/Icon.pic")

		--ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x000000, "Приложение создано!"}, {"EmptyLine"}, {"Button", {ecs.colors.green, 0xffffff, "OK"}})
	else
		ecs.error("Указанный файл иконки не существует.")
		return
	end
end

--Простое информационное окошечко. Возвращает старые пиксели - мало ли понадобится.
function ecs.info(x, y, title, text)
	x = x or "auto"
	y = y or "auto"
	title = title or " "
	text = text or "Sample text"

	local width = unicode.len(text) + 4
	local height = 4
	x, y = ecs.correctStartCoords(x, y, width, height)

	local oldPixels = ecs.rememberOldPixels(x, y, x + width + 1, y + height)

	ecs.emptyWindow(x, y, width, height, title)
	ecs.colorTextWithBack(x + 2, y + 2, ecs.windowColors.usualText, ecs.windowColors.background, text)

	return oldPixels
end

--Вертикальный скроллбар. Маст-хев!
function ecs.srollBar(x, y, width, height, countOfAllElements, currentElement, backColor, frontColor)
	local sizeOfScrollBar = math.ceil(1 / countOfAllElements * height)
	local displayBarFrom = math.floor(y + height * ((currentElement - 1) / countOfAllElements))

	ecs.square(x, y, width, height, backColor)
	ecs.square(x, displayBarFrom, width, sizeOfScrollBar, frontColor)

	sizeOfScrollBar, displayBarFrom = nil, nil
end

--Отрисовка поля с текстом. Сюда пихать массив вида {"строка1", "строка2", "строка3", ...}
function ecs.textField(x, y, width, height, lines, displayFrom, background, foreground, scrollbarBackground, scrollbarForeground)
	x, y = ecs.correctStartCoords(x, y, width, height)

	background = background or 0xffffff
	foreground = foreground or ecs.windowColors.usualText

	local sLines = #lines
	local lineLimit = width - 3

	--Парсим строки
	local line = 1
	while lines[line] do
		local sLine = unicode.len(lines[line])
		if sLine > lineLimit then
			local part1, part2 = unicode.sub(lines[line], 1, lineLimit), unicode.sub(lines[line], lineLimit + 1, -1)
			lines[line] = part1
			table.insert(lines, line + 1, part2)
			part1, part2 = nil, nil
		end
		line = line + 1
		sLine = nil
	end
	line = nil

	ecs.square(x, y, width - 1, height, background)
	ecs.srollBar(x + width - 1, y, 1, height, sLines, displayFrom, scrollbarBackground, scrollbarForeground)

	gpu.setBackground(background)
	gpu.setForeground(foreground)
	local yPos = y
	for i = displayFrom, (displayFrom + height - 1) do
		if lines[i] then
			gpu.set(x + 1, yPos, lines[i])
			yPos = yPos + 1
		else
			break
		end
	end

	return sLines
end

--Получение верного имени языка. Просто для безопасности. (для операционки)
function ecs.getCorrectLangName(pathToLangs)
	local language = _G.OSSettings.language .. ".lang"
	if not fs.exists(pathToLangs .. "/" .. language) then
		language = "English.lang"
	end
	return language
end

--Чтение языкового файла  (для операционки)
function ecs.readCorrectLangFile(pathToLangs)
	local lang
	
	local language = ecs.getCorrectLangName(pathToLangs)

	lang = config.readAll(pathToLangs .. "/" .. language)

	return lang
end

-------------------------ВСЕ ДЛЯ ОСКИ-------------------------------------------------------------------------------

function ecs.searchInArray(array, textToSearch)
	local newArray = {}
	for i = 1, #array do
		if string.find(unicode.lower(array[i]), unicode.lower(textToSearch)) then table.insert(newArray, array[i]) end
	end
	return newArray
end

function ecs.sortFiles(path, fileList, sortingMethod, showHiddenFiles)
	local sortedFileList = {}
	if sortingMethod == "type" or sortingMethod == 0 then
		local typeList = {}
		for i = 1, #fileList do
			local fileFormat = ecs.getFileFormat(fileList[i]) or "Script"
			if fs.isDirectory(path .. fileList[i]) and fileFormat ~= ".app" then fileFormat = "Folder" end
			typeList[fileFormat] = typeList[fileFormat] or {}
			table.insert(typeList[fileFormat], fileList[i])
		end

		if typeList["Folder"] then
			for i = 1, #typeList["Folder"] do
				table.insert(sortedFileList, typeList["Folder"][i])
			end
			typeList["Folder"] = nil
		end

		for fileFormat in pairs(typeList) do
			for i = 1, #typeList[fileFormat] do
				table.insert(sortedFileList, typeList[fileFormat][i])
			end
		end
	elseif sortingMethod == "name" or sortingMethod == 1 then
		sortedFileList = fileList
	elseif sortingMethod == "date" or sortingMethod == 2 then
		for i = 1, #fileList do
			fileList[i] = {fileList[i], fs.lastModified(path .. fileList[i])}
		end
		table.sort(fileList, function(a,b) return a[2] > b[2] end)
		for i = 1, #fileList do
			table.insert(sortedFileList, fileList[i][1])
		end
	else
		error("Unknown sorting method: " .. tostring(sortingMethod))
	end

	local i = 1
	while i <= #sortedFileList do
		if not showHiddenFiles and ecs.isFileHidden(sortedFileList[i]) then
			table.remove(sortedFileList, i)
		else
			i = i + 1
		end
	end

	return sortedFileList
end

--Сохранить файл конфигурации ОС
function ecs.saveOSSettings()
	local pathToOSSettings = "MineOS/System/OS/OSSettings.cfg"
	if not _G.OSSettings then error("Массив настроек ОС отсутствует в памяти!") end
	fs.makeDirectory(fs.path(pathToOSSettings))
	local file = io.open(pathToOSSettings, "w")
	file:write(serialization.serialize(_G.OSSettings))
	file:close()
end

--Загрузить файл конфигурации ОС, а если его не существует, то создать
function ecs.loadOSSettings()
	local pathToOSSettings = "MineOS/System/OS/OSSettings.cfg"
	if fs.exists(pathToOSSettings) then
		local file = io.open(pathToOSSettings, "r")
		_G.OSSettings = serialization.unserialize(file:read("*a"))
		file:close()
	else
		_G.OSSettings = { showHelpOnApplicationStart = true, language = "Russian" }
		ecs.saveOSSettings()
	end
end

--Отобразить окно с содержимым файла информации о приложении
function ecs.applicationHelp(pathToApplication)
	local pathToAboutFile = pathToApplication .. "/resources/About/" .. _G.OSSettings.language .. ".txt"
	if _G.OSSettings and _G.OSSettings.showHelpOnApplicationStart and fs.exists(pathToAboutFile) then
		local applicationName = fs.name(pathToApplication)
		local file = io.open(pathToAboutFile, "r")
		local text = ""
		for line in file:lines() do text = text .. line .. " " end
		file:close()

		local data = ecs.universalWindow("auto", "auto", 30, 0xeeeeee, true,
			{"EmptyLine"},
			{"CenterText", 0x000000, "О приложении " .. applicationName},
			{"EmptyLine"},
			{"TextField", 16, 0xFFFFFF, 0x262626, 0xcccccc, 0x353535, text},
			{"EmptyLine"},
			{"Button", {ecs.colors.orange, 0x262626, "OK"}, {0x999999, 0xffffff, "Больше не показывать"}}
		)
		if data[1] ~= "OK" then
			_G.OSSettings.showHelpOnApplicationStart = false
			ecs.saveOSSettings()
		end
	end
end

--Создать ярлык для конкретной проги (для операционки)
function ecs.createShortCut(path, pathToProgram)
	fs.remove(path)
	fs.makeDirectory(fs.path(path))
	local file = io.open(path, "w")
	file:write("return ", "\"", pathToProgram, "\"")
	file:close()
end

--Получить данные о файле из ярлыка (для операционки)
function ecs.readShortcut(path)
	local success, filename = pcall(loadfile(path))
	if success then
		return filename
	else
		error("Ошибка чтения файла ярлыка. Вероятно, он создан криво, либо не существует в папке " .. path)
	end
end

--Редактирование файла (для операционки)
function ecs.editFile(path)
	ecs.prepareToExit()
	shell.execute("edit "..path)
end

-- Копирование папки через рекурсию, т.к. fs.copy() не поддерживает папки
-- Ну долбоеб автор мода - хули я тут сделаю? Придется так вот
-- Хотя можно юзать обычный bin/cp, как это сделано в дисковом дубляже. Надо перекодить, короч
function ecs.copyFolder(path, toPath)
	local function doCopy(path)
		local fileList = ecs.getFileList(path)
		for i = 1, #fileList do
			if fs.isDirectory(path..fileList[i]) then
				doCopy(path..fileList[i])
			else
				fs.makeDirectory(toPath..path)
				fs.copy(path..fileList[i], toPath ..path.. fileList[i])
			end
		end
	end

	toPath = fs.path(toPath)
	doCopy(path.."/")
end

--Копирование файлов для операционки
function ecs.copy(from, to)
	local name = fs.name(from)
	local toName = to .. "/" .. name
	local action = ecs.askForReplaceFile(toName)
	if action == nil or action == "replace" then
		fs.remove(toName)
		if fs.isDirectory(from) then
			ecs.copyFolder(from, toName)
		else
			fs.copy(from, toName)
		end
	elseif action == "keepBoth" then
		if fs.isDirectory(from) then
			ecs.copyFolder(from, to .. "/(copy)" .. name)
		else
			fs.copy(from, to .. "/(copy)" .. name)
		end	
	end
end

-- Анимация затухания экрана
function ecs.fadeOut(startColor, targetColor, speed)
	local xSize, ySize = gpu.getResolution()
	while startColor >= targetColor do
		gpu.setBackground(startColor)
		gpu.fill(1, 1, xSize, ySize, " ")
		startColor = startColor - 0x111111
		os.sleep(speed or 0)
	end
end

-- Анимация загорания экрана
function ecs.fadeIn(startColor, targetColor, speed)
	local xSize, ySize = gpu.getResolution()
	while startColor <= targetColor do
		gpu.setBackground(startColor)
		gpu.fill(1, 1, xSize, ySize, " ")
		startColor = startColor + 0x111111
		os.sleep(speed or 0)
	end
end

-- Анимация выхода в олдскул-телевизионном стиле
function ecs.TV(speed, targetColor)
	local xSize, ySize = gpu.getResolution()
	local xCenter, yCenter = math.floor(xSize / 2), math.floor(ySize / 2)
	gpu.setBackground(targetColor or 0x000000)
	
	for y = 1, yCenter do
		gpu.fill(1, y - 1, xSize, 1, " ")
		gpu.fill(1, ySize - y + 1, xSize, 1, " ")
		os.sleep(speed or 0)
	end
	
	for x = 1, xCenter - 1 do
		gpu.fill(x, yCenter, 1, 1, " ")
		gpu.fill(xSize - x + 1, yCenter, 1, 1, " ")
		os.sleep(speed or 0)
	end
	os.sleep(0.3)
	gpu.fill(1, yCenter, xSize, 1, " ")
end



---------------------------------------------ОКОШЕЧКИ------------------------------------------------------------


--Описание ниже, ебана. Ниже - это значит в самой жопе кода!
function ecs.universalWindow(x, y, width, background, closeWindowAfter, ...)
	local objects = {...}
	local countOfObjects = #objects

	local pressedButton
	local pressedMultiButton

	--Задаем высотные константы для объектов
	local objectsHeights = {
		["button"] = 3,
		["centertext"] = 1,
		["emptyline"] = 1,
		["input"] = 3,
		["slider"] = 3,
		["select"] = 3,
		["selector"] = 3,
		["separator"] = 1,
		["switch"] = 1,
		["color"] = 3,
	}

	--Скорректировать ширину, если нужно
	local function correctWidth(newWidthForAnalyse)
		width = math.max(width, newWidthForAnalyse)
	end

	--Корректируем ширину
	for i = 1, countOfObjects do
		local objectType = string.lower(objects[i][1])
		
		if objectType == "centertext" then
			correctWidth(unicode.len(objects[i][3]) + 2)
		elseif objectType == "slider" then --!!!!!!!!!!!!!!!!!! ВОТ ТУТ НЕ ЗАБУДЬ ФИКСАНУТЬ
			correctWidth(unicode.len(objects[i][7]..tostring(objects[i][5].." ")) + 2)
		elseif objectType == "select" then
			for j = 4, #objects[i] do
				correctWidth(unicode.len(objects[i][j]) + 2)
			end
		--elseif objectType == "selector" then
			
		--elseif objectType == "separator" then
			
		elseif objectType == "textfield" then
			correctWidth(5)
		elseif objectType == "wrappedtext" then
			correctWidth(6)
		elseif objectType == "button" then
			--Корректируем ширину
			local widthOfButtons = 0
			local maxButton = 0
			for j = 2, #objects[i] do
				maxButton = math.max(maxButton, unicode.len(objects[i][j][3]) + 2)
			end
			widthOfButtons = maxButton * #objects[i]
			correctWidth(widthOfButtons)
		elseif objectType == "switch" then
			local dlina = unicode.len(objects[i][5]) + 2 + 10 + 4
			correctWidth(dlina)
		elseif objectType == "color" then 
			correctWidth(unicode.len(objects[i][2]) + 6)
		end
	end

	--Считаем высоту этой хуйни
	local height = 0
	for i = 1, countOfObjects do
		local objectType = string.lower(objects[i][1])
		if objectType == "select" then
			height = height + (objectsHeights[objectType] * (#objects[i] - 3))
		elseif objectType == "textfield" then
			height = height + objects[i][2]
		elseif objectType == "wrappedtext" then
			--Заранее парсим текст перенесенный
			objects[i].wrapped = ecs.stringWrap({objects[i][3]}, width - 4)
			objects[i].height = #objects[i].wrapped
			height = height + objects[i].height
		else
			height = height + objectsHeights[objectType]
		end
	end

	--Коорректируем стартовые координаты
	x, y = ecs.correctStartCoords(x, y, width, height)
	--Запоминаем инфу о том, что было нарисовано, если это необходимо
	local oldPixels, oldBackground, oldForeground
	if closeWindowAfter then
		oldBackground = gpu.getBackground()
		oldForeground = gpu.getForeground()
		oldPixels = ecs.rememberOldPixels(x, y, x + width - 1, y + height - 1)
	end
	--Считаем все координаты объектов
	objects[1].y = y
	if countOfObjects > 1 then
		for i = 2, countOfObjects do
			local objectType = string.lower(objects[i - 1][1])
			if objectType == "select" then
				objects[i].y = objects[i - 1].y + (objectsHeights[objectType] * (#objects[i - 1] - 3))
			elseif objectType == "textfield" then
				objects[i].y = objects[i - 1].y + objects[i - 1][2]
			elseif objectType == "wrappedtext" then
				objects[i].y = objects[i - 1].y + objects[i - 1].height
			else
				objects[i].y = objects[i - 1].y + objectsHeights[objectType]
			end
		end
	end

	--Объекты для тача
	local obj = {}
	local function newObj(class, name, ...)
		obj[class] = obj[class] or {}
		obj[class][name] = {...}
	end

	--Отображение объекта по номеру
	local function displayObject(number, active)
		local objectType = string.lower(objects[number][1])
				
		if objectType == "centertext" then
			local xPos = x + math.floor(width / 2 - unicode.len(objects[number][3]) / 2)
			gpu.setForeground(objects[number][2])
			gpu.setBackground(background)
			gpu.set(xPos, objects[number].y, objects[number][3])
		
		elseif objectType == "input" then

			if active then
				--Рамочка
				ecs.border(x + 1, objects[number].y, width - 2, objectsHeights.input, background, objects[number][3])
				--Тестик
				objects[number][4] = ecs.inputText(x + 3, objects[number].y + 1, width - 6, "", background, objects[number][3], false, objects[number][5])
			else
				--Рамочка
				ecs.border(x + 1, objects[number].y, width - 2, objectsHeights.input, background, objects[number][2])
				--Текстик
				gpu.set(x + 3, objects[number].y + 1, ecs.stringLimit("start", objects[number][4], width - 6))
				ecs.inputText(x + 3, objects[number].y + 1, width - 6, objects[number][4], background, objects[number][2], true, objects[number][5])
			end

			newObj("Inputs", number, x + 1, objects[number].y, x + width - 2, objects[number].y + 2)

		elseif objectType == "slider" then
			local widthOfSlider = width - 2
			local xOfSlider = x + 1
			local yOfSlider = objects[number].y + 1
			local countOfSliderThings = objects[number][5] - objects[number][4]
			local showSliderValue= objects[number][7]

			local dolya = widthOfSlider / countOfSliderThings
			local position = math.floor(dolya * objects[number][6])
			--Костыль
			if (xOfSlider + position) > (xOfSlider + widthOfSlider - 1)	then position = widthOfSlider - 2 end

			--Две линии
			ecs.separator(xOfSlider, yOfSlider, position, background, objects[number][3])
			ecs.separator(xOfSlider + position, yOfSlider, widthOfSlider - position, background, objects[number][2])
			--Слудир
			ecs.square(xOfSlider + position, yOfSlider, 2, 1, objects[number][3])

			--Текстик под слудиром
			if showSliderValue then
				local text = showSliderValue .. tostring(objects[number][6]) .. (objects[number][8] or "")
				local textPos = (xOfSlider + widthOfSlider / 2 - unicode.len(text) / 2)
				ecs.square(x, yOfSlider + 1, width, 1, background)
				ecs.colorText(textPos, yOfSlider + 1, objects[number][2], text)
			end

			newObj("Sliders", number, xOfSlider, yOfSlider, x + widthOfSlider, yOfSlider, dolya)

		elseif objectType == "select" then
			local usualColor = objects[number][2]
			local selectionColor = objects[number][3]

			objects[number].selectedData = objects[number].selectedData or 1

			local symbol = "✔"
			local yPos = objects[number].y
			for i = 4, #objects[number] do
				--Коробка для галочки
				ecs.border(x + 1, yPos, 5, 3, background, usualColor)
				--Текст
				gpu.set(x + 7, yPos + 1, objects[number][i])
				--Галочка
				if objects[number].selectedData == (i - 3) then
					ecs.colorText(x + 3, yPos + 1, selectionColor, symbol)
				else
					gpu.set(x + 3, yPos + 1, "  ")
				end

				obj["Selects"] = obj["Selects"] or {}
				obj["Selects"][number] = obj["Selects"][number] or {}
				obj["Selects"][number][i - 3] = { x + 1, yPos, x + width - 2, yPos + 2 }

				yPos = yPos + objectsHeights.select
			end

		elseif objectType == "selector" then
			local borderColor = objects[number][2]
			local arrowColor = objects[number][3]
			local selectorWidth = width - 2
			objects[number].selectedElement = objects[number].selectedElement or objects[number][4]

			local topLine = "┌" .. string.rep("─", selectorWidth - 6) .. "┬───┐"
			local midLine = "│" .. string.rep(" ", selectorWidth - 6) .. "│   │"
			local botLine = "└" .. string.rep("─", selectorWidth - 6) .. "┴───┘"

			local yPos = objects[number].y

			local function bordak(borderColor)
				gpu.setBackground(background)
				gpu.setForeground(borderColor)
				gpu.set(x + 1, objects[number].y, topLine)
				gpu.set(x + 1, objects[number].y + 1, midLine)
				gpu.set(x + 1, objects[number].y + 2, botLine)
				gpu.set(x + 3, objects[number].y + 1, ecs.stringLimit("start", objects[number].selectedElement, width - 6))
				ecs.colorText(x + width - 4, objects[number].y + 1, arrowColor, "▼")
			end

			bordak(borderColor)
		
			--Выпадающий список, самый гемор, блядь
			if active then
				local xPos, yPos = x + 1, objects[number].y + 3
				local spisokWidth = width - 2
				local countOfElements = #objects[number] - 3
				local spisokHeight = countOfElements + 1
				local oldPixels = ecs.rememberOldPixels( xPos, yPos, xPos + spisokWidth - 1, yPos + spisokHeight - 1)

				local coords = {}

				bordak(arrowColor)

				--Рамку рисуем поверх фоника
				local topLine = "├"..string.rep("─", spisokWidth - 6).."┴───┤"
				local midLine = "│"..string.rep(" ", spisokWidth - 2).."│"
				local botLine = "└"..string.rep("─", selectorWidth - 2) .. "┘"
				ecs.colorTextWithBack(xPos, yPos - 1, arrowColor, background, topLine)
				for i = 1, spisokHeight - 1 do
					gpu.set(xPos, yPos + i - 1, midLine)
				end
				gpu.set(xPos, yPos + spisokHeight - 1, botLine)

				--Элементы рисуем
				xPos = xPos + 2
				for i = 1, countOfElements do
					ecs.colorText(xPos, yPos, borderColor, ecs.stringLimit("start", objects[number][i + 3], spisokWidth - 4))
					coords[i] = {xPos - 1, yPos, xPos + spisokWidth - 4, yPos}
					yPos = yPos + 1
				end

				--Обработка
				local exit
				while true do
					if exit then break end
					local e = {event.pull()}
					if e[1] == "touch" then
						for i = 1, #coords do
							if ecs.clickedAtArea(e[3], e[4], coords[i][1], coords[i][2], coords[i][3], coords[i][4]) then
								ecs.square(coords[i][1], coords[i][2], spisokWidth - 2, 1, ecs.colors.blue)
								ecs.colorText(coords[i][1] + 1, coords[i][2], 0xffffff, objects[number][i + 3])
								os.sleep(0.3)
								objects[number].selectedElement = objects[number][i + 3]
								exit = true
								break
							end
						end
					end
				end

				ecs.drawOldPixels(oldPixels)
			end

			newObj("Selectors", number, x + 1, objects[number].y, x + width - 2, objects[number].y + 2)

		elseif objectType == "separator" then
			ecs.separator(x, objects[number].y, width, background, objects[number][2])
		
		elseif objectType == "textfield" then
			newObj("TextFields", number, x + 1, objects[number].y, x + width - 2, objects[number].y + objects[number][2] - 1)
			if not objects[number].strings then objects[number].strings = ecs.stringWrap({objects[number][7]}, width - 3) end
			objects[number].displayFrom = objects[number].displayFrom or 1
			ecs.textField(x, objects[number].y, width, objects[number][2], objects[number].strings, objects[number].displayFrom, objects[number][3], objects[number][4], objects[number][5], objects[number][6])
		
		elseif objectType == "wrappedtext" then
			gpu.setBackground(background)
			gpu.setForeground(objects[number][2])
			for i = 1, #objects[number].wrapped do
				gpu.set(x + 2, objects[number].y + i - 1, objects[number].wrapped[i])
			end

		elseif objectType == "button" then

			obj["MultiButtons"] = obj["MultiButtons"] or {}
			obj["MultiButtons"][number] = {}

			local widthOfButton = math.floor(width / (#objects[number] - 1))

			local xPos, yPos = x, objects[number].y
			for i = 1, #objects[number] do
				if type(objects[number][i]) == "table" then
					local x1, y1, x2, y2 = ecs.drawButton(xPos, yPos, widthOfButton, 3, objects[number][i][3], objects[number][i][1], objects[number][i][2])
					table.insert(obj["MultiButtons"][number], {x1, y1, x2, y2, widthOfButton})
					xPos = x2 + 1

					if i == #objects[number] then
						ecs.square(xPos, yPos, x + width - xPos, 3, objects[number][i][1])
						obj["MultiButtons"][number][i - 1][5] = obj["MultiButtons"][number][i - 1][5] + x + width - xPos
					end

					x1, y1, x2, y2 = nil, nil, nil, nil
				end
			end

		elseif objectType == "switch" then

			local xPos, yPos = x + 2, objects[number].y
			local activeColor, passiveColor, textColor, text, state = objects[number][2], objects[number][3], objects[number][4], objects[number][5], objects[number][6]
			local switchWidth = 8
			ecs.colorTextWithBack(xPos, yPos, textColor, background, text)

			xPos = x + width - switchWidth - 2
			if state then
				ecs.square(xPos, yPos, switchWidth, 1, activeColor)
				ecs.square(xPos + switchWidth - 2, yPos, 2, 1, passiveColor)
				--ecs.colorTextWithBack(xPos + 4, yPos, passiveColor, activeColor, "ON")
			else
				ecs.square(xPos, yPos, switchWidth, 1, passiveColor - 0x444444)
				ecs.square(xPos, yPos, 2, 1, passiveColor)
				--ecs.colorTextWithBack(xPos + 4, yPos, passiveColor, passiveColor - 0x444444, "OFF")
			end
			newObj("Switches", number, xPos, yPos, xPos + switchWidth - 1, yPos)

		elseif objectType == "color" then
			local xPos, yPos = x + 1, objects[number].y
			local blendedColor = require("colorlib").alphaBlend(objects[number][3], 0xFFFFFF, 180)
			local w = width - 2

			ecs.colorTextWithBack(xPos, yPos + 2, blendedColor, background, string.rep("▀", w))
			ecs.colorText(xPos, yPos, objects[number][3], string.rep("▄", w))
			ecs.square(xPos, yPos + 1, w, 1, objects[number][3])		

			ecs.colorText(xPos + 1, yPos + 1, 0xffffff - objects[number][3], objects[number][2])
			newObj("Colors", number, xPos, yPos, x + width - 2, yPos + 2)
		end
	end

	--Отображение всех объектов
	local function displayAllObjects()
		for i = 1, countOfObjects do
			displayObject(i)
		end
	end

	--Подготовить массив возвращаемый
	local function getReturn()
		local massiv = {}

		for i = 1, countOfObjects do
			local type = string.lower(objects[i][1])

			if type == "button" then
				table.insert(massiv, pressedButton)
			elseif type == "input" then
				table.insert(massiv, objects[i][4])
			elseif type == "select" then
				table.insert(massiv, objects[i][objects[i].selectedData + 3])
			elseif type == "selector" then
				table.insert(massiv, objects[i].selectedElement)
			elseif type == "slider" then
				table.insert(massiv, objects[i][6])
			elseif type == "switch" then
				table.insert(massiv, objects[i][6])
			elseif type == "color" then
				table.insert(massiv, objects[i][3])	
			else
				table.insert(massiv, nil)
			end
		end

		return massiv
	end

	local function redrawBeforeClose()
		if closeWindowAfter then
			ecs.drawOldPixels(oldPixels)
			gpu.setBackground(oldBackground)
			gpu.setForeground(oldForeground)
		end
	end

	--Рисуем окно
	ecs.square(x, y, width, height, background)
	displayAllObjects()

	while true do
		local e = {event.pull()}
		if e[1] == "touch" or e[1] == "drag" then

			--Анализируем клик на кнопки
			if obj["MultiButtons"] then
				for key in pairs(obj["MultiButtons"]) do
					for i = 1, #obj["MultiButtons"][key] do
						if ecs.clickedAtArea(e[3], e[4], obj["MultiButtons"][key][i][1], obj["MultiButtons"][key][i][2], obj["MultiButtons"][key][i][3], obj["MultiButtons"][key][i][4]) then
							ecs.drawButton(obj["MultiButtons"][key][i][1], obj["MultiButtons"][key][i][2], obj["MultiButtons"][key][i][5], 3, objects[key][i + 1][3], objects[key][i + 1][2], objects[key][i + 1][1])
							os.sleep(0.3)
							pressedButton = objects[key][i + 1][3]
							redrawBeforeClose()
							return getReturn()
						end
					end
				end
			end

			--А теперь клик на инпуты!
			if obj["Inputs"] then
				for key in pairs(obj["Inputs"]) do
					if ecs.clickedAtArea(e[3], e[4], obj["Inputs"][key][1], obj["Inputs"][key][2], obj["Inputs"][key][3], obj["Inputs"][key][4]) then
						displayObject(key, true)
						displayObject(key)
						break
					end
				end
			end

			--А теперь галочковыбор!
			if obj["Selects"] then
				for key in pairs(obj["Selects"]) do
					for i in pairs(obj["Selects"][key]) do
						if ecs.clickedAtArea(e[3], e[4], obj["Selects"][key][i][1], obj["Selects"][key][i][2], obj["Selects"][key][i][3], obj["Selects"][key][i][4]) then
							objects[key].selectedData = i
							displayObject(key)
							break
						end
					end
				end
			end

			--Хм, а вот и селектор подъехал!
			if obj["Selectors"] then
				for key in pairs(obj["Selectors"]) do
					if ecs.clickedAtArea(e[3], e[4], obj["Selectors"][key][1], obj["Selectors"][key][2], obj["Selectors"][key][3], obj["Selectors"][key][4]) then
						displayObject(key, true)
						displayObject(key)
						break
					end
				end
			end

			--Слайдеры, епта! "Потный матан", все делы
			if obj["Sliders"] then
				for key in pairs(obj["Sliders"]) do
					if ecs.clickedAtArea(e[3], e[4], obj["Sliders"][key][1], obj["Sliders"][key][2], obj["Sliders"][key][3], obj["Sliders"][key][4]) then
						local xOfSlider, dolya = obj["Sliders"][key][1], obj["Sliders"][key][5]
						local currentPixels = e[3] - xOfSlider
						local currentValue = math.floor(currentPixels / dolya)
						--Костыль
						if e[3] == obj["Sliders"][key][3] then currentValue = objects[key][5] end
						objects[key][6] = currentValue or objects[key][6]
						displayObject(key)
						break
					end
				end
			end

			if obj["Switches"] then
				for key in pairs(obj["Switches"]) do
					if ecs.clickedAtArea(e[3], e[4], obj["Switches"][key][1], obj["Switches"][key][2], obj["Switches"][key][3], obj["Switches"][key][4]) then
						objects[key][6] = not objects[key][6]
						displayObject(key)
						break
					end
				end
			end

			if obj["Colors"] then
				for key in pairs(obj["Colors"]) do
					if ecs.clickedAtArea(e[3], e[4], obj["Colors"][key][1], obj["Colors"][key][2], obj["Colors"][key][3], obj["Colors"][key][4]) then
						local oldColor = objects[key][3]
						objects[key][3] = 0xffffff - objects[key][3]
						displayObject(key)
						os.sleep(0.3)
						objects[key][3] = oldColor
						displayObject(key)
						local color = loadfile("lib/palette.lua")().draw("auto", "auto", objects[key][3])
						objects[key][3] = color or oldColor
						displayObject(key)
						break
					end
				end
			end

		elseif e[1] == "scroll" then
			if obj["TextFields"] then
				for key in pairs(obj["TextFields"]) do
					if ecs.clickedAtArea(e[3], e[4], obj["TextFields"][key][1], obj["TextFields"][key][2], obj["TextFields"][key][3], obj["TextFields"][key][4]) then
						if e[5] == 1 then
							if objects[key].displayFrom > 1 then objects[key].displayFrom = objects[key].displayFrom - 1; displayObject(key) end
						else
							if objects[key].displayFrom < #objects[key].strings then objects[key].displayFrom = objects[key].displayFrom + 1; displayObject(key) end
						end
					end
				end
			end
		elseif e[1] == "key_down" then
			if e[4] == 28 then
				redrawBeforeClose()
				return getReturn()
			end
		end
	end
end

--Демонстрационное окно, показывающее всю мощь universalWindow
function ecs.demoWindow()
	--Очищаем экран перед юзанием окна и ставим курсор на 1, 1
	ecs.prepareToExit()
	--Рисуем окно и получаем данные после взаимодействия с ним
	local data = ecs.universalWindow("auto", "auto", 36, 0xeeeeee, true,
		{"EmptyLine"},
		{"CenterText", 0x880000, "Здорово, ебана!"},
		{"EmptyLine"},
		{"Input", 0x262626, 0x880000, "Сюда вводить можно"},
		{"Selector", 0x262626, 0x880000, "Выбор формата", "PNG", "JPG", "GIF", "PSD"},
		{"EmptyLine"},
		{"WrappedText", 0x262626, "Тест автоматического переноса букв в зависимости от ширины данного окна. Пока что тупо режет на куски, не особо красиво."},
		{"EmptyLine"},
		{"Select", 0x262626, 0x880000, "Я пидор", "Я не пидор"},
		{"Slider", 0x262626, 0x880000, 1, 100, 50, "Убито ", " младенцев"},
		{"EmptyLine"},
		{"Separator", 0xaaaaaa},
		{"Switch", 0xF2B233, 0xffffff, 0x262626, "✈ Авиарежим", false},
		{"EmptyLine"},
		{"Switch", 0x3366CC, 0xffffff, 0x262626, "☾  Не беспокоить", true},
		{"Separator", 0xaaaaaa},
		{"EmptyLine"},
		{"TextField", 5, 0xffffff, 0x262626, 0xcccccc, 0x3366CC, "Тест текстового информационного поля. По сути это тот же самый WrappedText, разве что эта хрень ограничена по высоте, и ее можно скроллить. Ну же, поскролль меня! Скролль меня полностью! Моя жадная пизда жаждет твой хуй!"},
		{"Color", "Цвет фона", 0xFF0000},
		{"EmptyLine"},
		{"Button", {0x57A64E, 0xffffff, "Да"}, {0xF2B233, 0xffffff, "Нет"}, {0xCC4C4C, 0xffffff, "Отмена"}}
	)
	--Еще разок
	ecs.prepareToExit()
	--Выводим данные
	print(" ")
	print("Вывод данных из окна:")
	for i = 1, #data do print("["..i.."] = "..tostring(data[i])) end
	print(" ")
end

-- ecs.demoWindow()

--[[
Функция universalWindow(x, y, width, background, closeWindowAfter, ...)

	Это универсальная модульная функция для максимально удобного и быстрого отображения
	необходимой вам информации. С ее помощью вводить данные с клавиатуры, осуществлять выбор
	из предложенных вариантов, рисовать красивые кнопки, отрисовывать обычный текст,
	отрисовывать текстовые поля с возможностью прокрутки, рисовать разделители и прочее.
	Любой объект выделяется с помощью клика мыши, после чего функция приступает к работе
	с этим объектом.
 
Аргументы функции:

	x и y: это числа, обозначающие стартовые координаты левого верхнего угла данного окна.
	Вместо цифр вы также можете написать "auto" - и программа автоматически разместит окно
	по центру экрана по выбранной координате. Или по обеим координатам, если вам угодно.
	 
	width: это ширина окна, которую вы можете задать по собственному желанию. Если некторые
	объекты требуют расширения окна, то окно будет автоматически расширено до нужной ширины.
	Да, вот такая вот тавтология ;)

	background: базовый цвет окна (цвет фона, кому как понятнее).

	closeWindowAfter: eсли true, то окно по завершению функции будет выгружено, а на его месте
	отрисуются пиксели, которые имелись на экране до выполнения функции. Удобно, если не хочешь
	париться с перерисовкой интерфейса.

	... : многоточием тут является перечень объектов, указанных через запятую. Каждый объект
	является массивом и имеет собственный формат. Ниже перечислены все возможные типы объектов.
		
		{"Button", {Цвет кнопки1, Цвет текста на кнопке1, Сам текст1}, {Цвет кнопки2, Цвет текста на кнопке2, Сам текст2}, ...}

			Это объект для рисования кнопок. Каждая кнопка - это массив, состоящий из трех элементов:
			цвета кнопки, цвета текста на кнопке и самого текста. Кнопок может быть неограниченное количество,
			однако чем их больше, тем большее требуется разрешение экрана по ширине.

			Интерактивный объект.

		{"Input", Цвет рамки и текста, Цвет при выделении, Стартовый текст [, Маскировать символом]}

			Объект для рисования полей ввода текстовой информации. Удобно для открытия или сохранения файлов,
			Опциональный аргумент "Маскировать символом" полезен, если вы делаете поле для ввода пароля.
			Никто не увидит ваш текст. В качестве данного аргумента передается символ, например "*".

			Интерактивный объект.

		{"Selector", Цвет рамки, Цвет при выделении, Выбор 1, Выбор 2, Выбор 3 ...}

			Внешне схож с объектом "Input", однако в этом случае вы будете выбирать один из предложенных
			вариантов из выпадающего списка. По умолчанию выбран первый вариант.

			Интерактивный объект.

		{"Select", Цвет рамки, Цвет галочки, Выбор 1, Выбор 2, Выбор 3 ...}

			Объект выбора. Отличается от "Selector" тем, что здесь вы выбираете один из вариантов, отмечая
			его галочкой. По умолчанию выбран первый вариант.

			Интерактивный объект. 

		{"Slider", Цвет линии слайдера, Цвет пимпочки слайдера, Значения слайдера ОТ, Значения слайдера ДО, Текущее значение [, Текст-подсказка ДО] [, Текст-подсказка ПОСЛЕ]}

			Ползунок, позволяющий задавать определенное количество чего-либо в указанном интервале. Имеются два
			опциональных аргумента, позволяющих четко понимать, с чем именно мы имеем дело.

			К примеру, если аргумент "Текст-подсказка ДО" будет равен "Съедено ", а аргумент "Текст-подсказка ПОСЛЕ"
			будет равен " яблок", а значение слайдера будет равно 50, то на экране будет написано "Съедено 50 яблок".

			Интерактивный объект.

		{"Switch", Активный цвет, Пассивный цвет, Цвет текста, Текст, Состояние}

			 Переключатель, принимающий два состояния: true или false. Текст - это всего лишь информация, некое
			 название данного переключателя.

			 Интерактивный объект.  

		{"CenterText", Цвет текста, Сам текст}

			Отображение текста указанного цвета по центру окна. Чисто для информативных целей.

		{"WrappedText", Цвет текста, Текст}

			Отображение большого количества текста с автоматическим переносом. Прото режет слова на кусочки,
			перенос символический. Чисто для информативных целей.
 
        {"TextField", Высота, Цвет фона, Цвет текста, Цвет скроллбара, Цвет пимпочки скроллбара, Сам текст}
 
        	Текстовое поле с возможностью прокрутки. Отличается от "WrappedText"
        	фиксированной высотой. Чисто для информативных целей.
   
        {"Separator", Цвет разделителя}
 
        	Линия-разделитель, помогающая лучше отделять объекты друг от друга. Декоративный объект.
 
		{"EmptyLine"}
 
        	Пустое пространство, помогающая лучше отделять объекты друг от друга. Декоративный объект.
 
		Каждый из объектов рисуется по порядку сверху вниз. Каждый объект автоматически
		увеличивает высоту окна до необходимого значения. Если объектов будет указано слишком много -
		т.е. если окно вылезет за пределы экрана, то программа завершится с ошибкой.

	Что возвращает функция:
		
		Возвратом является массив, пронумерованный от 1 до <количества объектов>.
		К примеру, 1 индекс данного массива соответствует 1 указанному объекту.
		Каждый индекс данного массива несет в себе какие-то данные, которые вы
		внесли в объект во время работы функции.
		Например, если в 1-ый объект типа "Input" вы ввели фразу "Hello world",
		то первый индекс в возвращенном массиве будет равен "Hello world".
		Конкретнее это будет вот так: massiv[1] = "Hello world".

		Если взаимодействие с объектом невозможно - например, как в случае
		с EmptyLine, CenterText, TextField или Separator, то в возвращенном
		массиве этот объект указываться не будет.

		Готовые примеры использования функции указаны ниже и закомментированы.
		Выбирайте нужный и раскомментируйте.
]]

--Функция-демонстратор, показывающая все возможные объекты в одном окне. Код окна находится выше.
--ecs.demoWindow()

--Функция-отладчик, выдающая окно с указанным сообщением об ошибке. Полезна при дебаге.
--ecs.error("Это сообщение об ошибке! Hello world!")

--Функция, спрашивающая, стоит ли заменять указанный файл, если он уже имеется
--ecs.askForReplaceFile("OS.lua")

--Функция, предлагающая сохранить файл в нужном месте в нужном формате.
--ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x262626, "Сохранить как"}, {"EmptyLine"}, {"Input", 0x262626, 0x880000, "Путь"}, {"Selector", 0x262626, 0x880000, "PNG", "JPG", "PSD"}, {"EmptyLine"}, {"Button", {0xbbbbbb, 0xffffff, "OK!"}})

----------------------------------------------------------------------------------------------------

return ecs


