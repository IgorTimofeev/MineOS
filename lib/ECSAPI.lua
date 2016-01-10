
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

local ECSAPI = {}

----------------------------------------------------------------------------------------------------

ECSAPI.windowColors = {
	background = 0xeeeeee,
	usualText = 0x444444,
	subText = 0x888888,
	tab = 0xaaaaaa,
	title = 0xffffff,
	shadow = 0x444444,
}

ECSAPI.colors = {
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

--Установка масштаба монитора
function ECSAPI.setScale(scale, debug)
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
	local xScreens, yScreens = component.screen.getAspectRatio()
	local xPixels, yPixels = calculateAspect(xScreens), calculateAspect(yScreens)
	local proportion = xPixels / yPixels

	--Получаем максимально возможное разрешение данной видеокарты
	local xMax, yMax = gpu.maxResolution()

	--Получаем теоретическое максимальное разрешение монитора с учетом его пропорции, но без учета лимита видеокарты
	local newWidth, newHeight
	if proportion >= 1 then
		newWidth = math.floor(xMax)
		newHeight = math.floor(newWidth / proportion / 2)
	else
		newHeight = math.floor(yMax)
		newWidth = math.floor(newHeight * proportion * 2)
	end

	--Получаем оптимальное разрешение для данного монитора с поддержкой видеокарты
	local optimalNewWidth, optimalNewHeight = newWidth, newHeight

	if optimalNewWidth > xMax then
		local difference = optimalNewWidth - xMax
		optimalNewWidth = xMax
		optimalNewHeight = optimalNewHeight - math.ceil(difference / 2 )
	end

	if optimalNewHeight > yMax then
		local difference = optimalNewHeight - yMax
		optimalNewHeight = yMax
		--optimalNewWidth = optimalNewWidth - difference * 2 - math.ceil(difference / 2)
		optimalNewWidth = optimalNewWidth - difference * 2
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

	--Устанавливаем выбранное разрешение
	gpu.setResolution(finalNewWidth, finalNewHeight)
end

function ECSAPI.rebindGPU(address)
	gpu.bind(address)
end

--Получаем всю инфу об оперативку в килобайтах
function ECSAPI.getInfoAboutRAM()
	local free = math.floor(computer.freeMemory() / 1024)
	local total = math.floor(computer.totalMemory() / 1024)
	local used = total - free

	return free, total, used
end

--Получить информацию о жестких дисках
function ECSAPI.getHDDs()
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
function ECSAPI.formatHDD(address)
	local proxy = component.proxy(address)
	local list = proxy.list("")
	ECSAPI.info("auto", "auto", "", "Formatting disk...")
	for _, file in pairs(list) do
		if type(file) == "string" then
			if not proxy.isReadOnly(file) then proxy.remove(file) end
		end
	end
	list = nil
end

--Установить имя жесткого диска
function ECSAPI.setHDDLabel(address, label)
	local proxy = component.proxy(address)
	proxy.setLabel(label or "Untitled")
end

--Найти монтированный путь конкретного адреса диска
function ECSAPI.findMount(address)
  for fs1, path in fs.mounts() do
    if fs1.address == component.get(address) then
      return path
    end
  end
end

--Скопировать файлы с одного диска на другой с заменой
function ECSAPI.duplicateFileSystem(fromAddress, toAddress)
	local source, destination = ECSAPI.findMount(fromAddress), ECSAPI.findMount(toAddress)
	ECSAPI.info("auto", "auto", "", "Copying file system...")
	shell.execute("bin/cp -rx "..source.."* "..destination)
end

--Загрузка файла с инета
function ECSAPI.getFileFromUrl(url, path)
	if not _G.internet then _G.internet = require("internet") end
	local sContent = ""
	local result, response = pcall(internet.request, url)
	if not result then
		ECSAPI.error("Could not connect to to URL address \"" .. url .. "\"")
		return
	end

	fs.remove(path)
	fs.makeDirectory(fs.path(path))
	local file = io.open(path, "w")

	for chunk in response do
		file:write(chunk)
		sContent = sContent .. chunk
	end

	file:close()

	return sContent
end

--Загрузка файла с пастебина
function ECSAPI.getFromPastebin(paste, path)
	local url = "http://pastebin.com/raw.php?i=" .. paste
	ECSAPI.getFileFromUrl(url, path)
end

--Загрузка файла с гитхаба
function ECSAPI.getFromGitHub(url, path)
	url = "https://raw.githubusercontent.com/" .. url
	ECSAPI.getFileFromUrl(url, path)
end

--Загрузить ОС-приложение
function ECSAPI.getOSApplication(elementFromMassiv)
	--Удаляем старый файл и получаем путь
	local path = elementFromMassiv.name
	fs.remove(path)
	--Если тип = приложение
	if elementFromMassiv.type == "Application" then
		fs.makeDirectory(path .. ".app/Resources")
		ECSAPI.getFromGitHub(elementFromMassiv.url, path .. ".app/" .. fs.name(elementFromMassiv.name .. ".lua"))
		ECSAPI.getFromGitHub(elementFromMassiv.icon, path .. ".app/Resources/Icon.pic")
		if elementFromMassiv.resources then
			for i = 1, #elementFromMassiv.resources do
				ECSAPI.getFromGitHub(elementFromMassiv.resources[i].url, path .. ".app/Resources/" .. elementFromMassiv.resources[i].name)
			end
		end
	--А если че-то другое
	else
		ECSAPI.getFromGitHub(elementFromMassiv.url, path)
	end
end

--Получить список приложений, которые требуется обновить
function ECSAPI.getAppsToUpdate(debug)
	--Задаем стартовые пути
	local pathToApplicationsFile = "MineOS/System/OS/Applications.txt"
	local pathToSecondApplicationsFile = "MineOS/System/OS/Applications2.txt"
	--Путь к файл-листу на пастебине
	local paste = "3j2x4dDn"
	--Выводим инфу
	local oldPixels
	if debug then oldPixels = ECSAPI.info("auto", "auto", " ", "Checking for updates...") end
	--Получаем свеженький файл
	ECSAPI.getFromPastebin(paste, pathToSecondApplicationsFile)
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
	if oldPixels then ECSAPI.drawOldPixels(oldPixels) end
	--Возвращаем массив с тем, че нужно обновить и просто старый аппликашнс на всякий случай
	return applications2, countOfUpdates
end

--Сделать строку пригодной для отображения в ОпенКомпах
function ECSAPI.stringOptimize(sto4ka, indentatonWidth)
	indentatonWidth = indentatonWidth or 2
    sto4ka = string.gsub(sto4ka, "\r\n", "\n")
    sto4ka = string.gsub(sto4ka, "	", string.rep(" ", indentatonWidth))
    return stro4ka
end

--ИЗ ДЕСЯТИЧНОЙ В ШЕСТНАДЦАТИРИЧНУЮ
function ECSAPI.decToBase(IN,BASE)
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
function ECSAPI.HEXtoString(color, bitCount, withNull)
	local stro4ka = string.format("%X",color)
	local sStro4ka = unicode.len(stro4ka)
	if sStro4ka < bitCount then
		stro4ka = string.rep("0", bitCount - sStro4ka) .. stro4ka
	end
	sStro4ka = nil
	if withNull then return "0x"..stro4ka else return stro4ka end
end

--КЛИКНУЛИ ЛИ В ЗОНУ
function ECSAPI.clickedAtArea(x,y,sx,sy,ex,ey)
  if (x >= sx) and (x <= ex) and (y >= sy) and (y <= ey) then return true end    
  return false
end

--Заливка всего экрана указанным цветом
function ECSAPI.clearScreen(color)
  if color then gpu.setBackground(color) end
  term.clear()
end

--Установка пикселя нужного цвета
function ECSAPI.setPixel(x,y,color)
  gpu.setBackground(color)
  gpu.set(x,y," ")
end

--Простая установка цветов в одну строку, ибо я ленивый
function ECSAPI.setColor(background, foreground)
	gpu.setBackground(background)
	gpu.setForeground(foreground)
end

--Цветной текст
function ECSAPI.colorText(x,y,textColor,text)
  gpu.setForeground(textColor)
  gpu.set(x,y,text)
end

--Цветной текст с жопкой!
function ECSAPI.colorTextWithBack(x,y,textColor,backColor,text)
  gpu.setForeground(textColor)
  gpu.setBackground(backColor)
  gpu.set(x,y,text)
end

--Инверсия цвета
function ECSAPI.invertColor(color)
  return 0xffffff - color
end

--Адаптивный текст, подстраивающийся под фон
function ECSAPI.adaptiveText(x,y,text,textColor)
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
function ECSAPI.smartText(x, y, text)
	local sText = unicode.len(text)
	local specialSymbol = "§"
	--Разбираем по кусочкам строку и получаем цвета
	local massiv = {}
	local iterator = 1
	local currentColor = gpu.getForeground()
	while iterator <= sText do
		local symbol = unicode.sub(text, iterator, iterator)
		if symbol == specialSymbol then
			currentColor = ECSAPI.colors[unicode.sub(text, iterator + 1, iterator + 1) or "f"]
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
function ECSAPI.formattedText(x, y, text, limit)
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
function ECSAPI.invertedText(x,y,symbol)
  local info = {gpu.get(x,y)}
  ECSAPI.adaptiveText(x,y,symbol,ECSAPI.invertColor(info[3]))
end

--Адаптивное округление числа
function ECSAPI.adaptiveRound(chislo)
  local celaya,drobnaya = math.modf(chislo)
  if drobnaya >= 0.5 then
    return (celaya + 1)
  else
    return celaya
  end
end

--Округление до опред. кол-ва знаков после запятой
function ECSAPI.round(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

--Обычный квадрат указанного цвета
function ECSAPI.square(x,y,width,height,color)
  gpu.setBackground(color)
  gpu.fill(x,y,width,height," ")
end

--Юникодовская рамка
function ECSAPI.border(x, y, width, height, back, fore)
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
function ECSAPI.drawFramedButton(x, y, width, height, text, color)
	ECSAPI.border(x, y, width, height, gpu.getBackground(), color)
	gpu.fill(x + 1, y + 1, width - 2, height - 2, " ")
	x = x + math.floor(width / 2 - unicode.len(text) / 2)
	y = y + math.floor(width / 2 - 1)
	gpu.set(x, y, text)
end

--Юникодовский разделитель
function ECSAPI.separator(x, y, width, back, fore)
	ECSAPI.colorTextWithBack(x, y, fore, back, string.rep("─", width))
end

--Автоматическое центрирование текста по указанной координате (x, y, xy)
function ECSAPI.centerText(mode,coord,text)
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
function ECSAPI.drawCustomImage(x,y,pixels)
	x = x - 1
	y = y - 1
	local pixelsWidth = #pixels[1]
	local pixelsHeight = #pixels
	local xEnd = x + pixelsWidth
	local yEnd = y + pixelsHeight

	for i=1,pixelsHeight do
		for j=1,pixelsWidth do
			if pixels[i][j][3] ~= "#" then
				gpu.setBackground(pixels[i][j][1])
				gpu.setForeground(pixels[i][j][2])
				gpu.set(x+j,y+i,pixels[i][j][3])
			end
		end
	end

	return (x+1),(y+1),xEnd,yEnd
end

--Корректировка стартовых координат. Core-функция для всех моих программ
function ECSAPI.correctStartCoords(xStart,yStart,xWindowSize,yWindowSize)
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
function ECSAPI.rememberOldPixels(x, y, x2, y2)
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
function ECSAPI.drawOldPixels(massivSudaPihay)
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
function ECSAPI.stringLimit(mode, text, size, noDots)
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
function ECSAPI.getHostTime(timezone)
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
function ECSAPI.getFileList(path)
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
function ECSAPI.getFileTree(path)
	local massiv = {}
	local list = ECSAPI.getFileList(path)
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
function ECSAPI.find(path, cheBudemIskat)
	--Массив, в котором будут находиться все найденные соответствия
	local massivNaydennogoGovna = {}
	--Костыль, но удобный
	local function dofind(path, cheBudemIskat)
		--Получаем список файлов в директории
		local list = ECSAPI.getFileList(path)
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
function ECSAPI.getFileFormat(path)
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
function ECSAPI.isFileHidden(path)
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
function ECSAPI.hideFileFormat(path)
	local name = fs.name(path)
	local fileFormat = ECSAPI.getFileFormat(name)
	if fileFormat == nil then
		return name
	else
		return unicode.sub(name, 1, unicode.len(name) - unicode.len(fileFormat))
	end
end

--Ожидание клика либо нажатия какой-либо клавиши
function ECSAPI.waitForTouchOrClick()
	while true do
		local e = { event.pull() }
		if e[1] == "key_down" or e[1] == "touch" then break end
	end
end

--То же самое, но в сокращенном варианте
function ECSAPI.wait()
	ECSAPI.waitForTouchOrClick()
end

--Нарисовать кнопочки закрытия окна
function ECSAPI.drawCloses(x, y, active)
	local symbol = "⮾"
	ECSAPI.colorText(x, y , (active == 1 and ECSAPI.colors.blue) or 0xCC4C4C, symbol)
	ECSAPI.colorText(x + 2, y , (active == 2 and ECSAPI.colors.blue) or 0xDEDE6C, symbol)
	ECSAPI.colorText(x + 4, y , (active == 3 and ECSAPI.colors.blue) or 0x57A64E, symbol)
end

--Нарисовать верхнюю оконную панель с выбором объектов
function ECSAPI.drawTopBar(x, y, width, selectedObject, background, foreground, ...)
	local objects = { ... }
	ECSAPI.square(x, y, width, 3, background)
	local widthOfObjects = 0
	local spaceBetween = 2
	for i = 1, #objects do
		widthOfObjects = widthOfObjects + unicode.len(objects[i][1]) + spaceBetween
	end
	local xPos = x + math.floor(width / 2 - widthOfObjects / 2)
	for i = 1, #objects do
		if i == selectedObject then
			ECSAPI.square(xPos, y, unicode.len(objects[i][1]) + spaceBetween, 3, ECSAPI.colors.blue)
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
function ECSAPI.drawTopMenu(x, y, width, color, selectedObject, ...)
	local objects = { ... }
	local objectsToReturn = {}
	local xPos = x + 2
	local spaceBetween = 2
	ECSAPI.square(x, y, width, 1, color)
	for i = 1, #objects do
		if i == selectedObject then
			ECSAPI.square(xPos - 1, y, unicode.len(objects[i][1]) + spaceBetween, 1, ECSAPI.colors.blue)
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
function ECSAPI.drawButton(x,y,width,height,text,backColor,textColor)
	x,y = ECSAPI.correctStartCoords(x,y,width,height)

	local textPosX = math.floor(x + width / 2 - unicode.len(text) / 2)
	local textPosY = math.floor(y + height / 2)
	ECSAPI.square(x,y,width,height,backColor)
	ECSAPI.colorText(textPosX,textPosY,textColor,text)

	return x, y, (x + width - 1), (y + height - 1)
end

--Отрисовка кнопки с указанными отступами от текста
function ECSAPI.drawAdaptiveButton(x,y,offsetX,offsetY,text,backColor,textColor)
	local length = unicode.len(text)
	local width = offsetX*2 + length
	local height = offsetY*2 + 1

	x,y = ECSAPI.correctStartCoords(x,y,width,height)

	ECSAPI.square(x,y,width,height,backColor)
	ECSAPI.colorText(x+offsetX,y+offsetY,textColor,text)

	return x,y,(x+width-1),(y+height-1)
end

--Отрисовка оконной "тени"
function ECSAPI.windowShadow(x,y,width,height)
	gpu.setBackground(ECSAPI.windowColors.shadow)
	gpu.fill(x+width,y+1,2,height," ")
	gpu.fill(x+1,y+height,width,1," ")
end

--Просто белое окошко с тенью
function ECSAPI.blankWindow(x,y,width,height)
	local oldPixels = ECSAPI.rememberOldPixels(x,y,x+width+1,y+height)

	ECSAPI.square(x,y,width,height,ECSAPI.windowColors.background)

	ECSAPI.windowShadow(x,y,width,height)

	return oldPixels
end

--Белое окошко, но уже с титлом вверху!
function ECSAPI.emptyWindow(x,y,width,height,title)

	local oldPixels = ECSAPI.rememberOldPixels(x,y,x+width+1,y+height)

	--ОКНО
	gpu.setBackground(ECSAPI.windowColors.background)
	gpu.fill(x,y+1,width,height-1," ")

	--ТАБ СВЕРХУ
	gpu.setBackground(ECSAPI.windowColors.tab)
	gpu.fill(x,y,width,1," ")

	--ТИТЛ
	gpu.setForeground(ECSAPI.windowColors.title)
	local textPosX = x + math.floor(width/2-unicode.len(title)/2) -1
	gpu.set(textPosX,y,title)

	--ТЕНЬ
	ECSAPI.windowShadow(x,y,width,height)

	return oldPixels

end

--Функция по переносу слов на новую строку в зависимости от ограничения по ширине
function ECSAPI.stringWrap(strings, limit)
	local massiv = {}

    --Перебираем все указанные строки
    for i = 1, #strings do
       
        --Создаем массив слов данной строки
        local words = {}
        for match in string.gmatch(strings[i], "[^%s]+") do table.insert(words, match) end

        --Если длина слов не превышает лимита
        if unicode.len(strings[i]) <= limit then
            table.insert(massiv, table.concat(words, " "))
        else
            --Перебираем все слова данной строки с 1 до конца
            local from = 1
            local to = 1
            while to <= #words do
                --Если длина соединенных слов превышает лимит, то
                if unicode.len(table.concat(words, " ", from, to)) > limit then
                    --Вставить в новый массив строк 
                    table.insert(massiv, table.concat(words, " ", from, to - 1))
                    from = to
                else
                    if to == #words then
                        table.insert(massiv, table.concat(words, " ", from, to))
                    end
                end

                to = to + 1
            end
        end
    end

    return massiv
end

--Моя любимая функция ошибки C:
function ECSAPI.error(...)
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
	ECSAPI.universalWindow("auto", "auto", math.ceil(gpu.getResolution() * 0.45), ECSAPI.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x880000, "Ошибка!"}, {"EmptyLine"}, {"WrappedText", 0x262626, text}, {"EmptyLine"}, {"Button", {0x880000, 0xffffff, "OK!"}})
end

--Очистить экран, установить комфортные цвета и поставить курсок на 1, 1
function ECSAPI.prepareToExit(color1, color2)
	ECSAPI.clearScreen(color1 or 0x333333)
	gpu.setForeground(color2 or 0xffffff)
	gpu.set(1, 1, "")
end

--Конвертация из юникода в символ. Вроде норм, а вроде и не норм. Но полезно.
function ECSAPI.convertCodeToSymbol(code)
	local symbol
	if code ~= 0 and code ~= 13 and code ~= 8 and code ~= 9 and code ~= 200 and code ~= 208 and code ~= 203 and code ~= 205 and not keyboard.isControlDown() then
		symbol = unicode.char(code)
		if keyboard.isShiftPressed then symbol = unicode.upper(symbol) end
	end
	return symbol
end

--Шкала прогресса - маст-хев!
function ECSAPI.progressBar(x, y, width, height, background, foreground, percent)
	local activeWidth = math.ceil(width * percent / 100)
	ECSAPI.square(x, y, width, height, background)
	ECSAPI.square(x, y, activeWidth, height, foreground)
end

--Окошко с прогрессбаром! Давно хотел
function ECSAPI.progressWindow(x, y, width, percent, text)
	local height = 6
	local barWidth = width - 6

	x, y = ECSAPI.correctStartCoords(x, y, width, height)

	ECSAPI.emptyWindow(x, y, width, height, " ")
	ECSAPI.colorTextWithBack(x + math.floor(width / 2 - unicode.len(text) / 2), y + 4, 0x000000, ECSAPI.windowColors.background, text)
	ECSAPI.progressBar(x + 3, y + 2, barWidth, 1, 0xCCCCCC, ECSAPI.colors.blue, percent)
end

--Функция для ввода текста в мини-поле.
function ECSAPI.inputText(x, y, limit, cheBiloVvedeno, background, foreground, justDrawNotEvent, maskTextWith)
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
			gpu.set(x, y, ECSAPI.stringLimit("start", string.rep("●", dlina), limit))
		else
			gpu.set(x, y, ECSAPI.stringLimit("start", text, limit))
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
				local symbol = ECSAPI.convertCodeToSymbol(e[3])
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
function ECSAPI.parseErrorMessage(error, translate)

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
			parsedError[i] = string.gsub(parsedError[i], "bad argument #", "Неверный аргумент №")
			parsedError[i] = string.gsub(parsedError[i], "stack traceback", "Отслеживание ошибки")
			parsedError[i] = string.gsub(parsedError[i], "tail calls", "Дочерние функции")
			parsedError[i] = string.gsub(parsedError[i], "in function", "в функции")
			parsedError[i] = string.gsub(parsedError[i], "in main chunk", "в основной программе")
			parsedError[i] = string.gsub(parsedError[i], "unexpected symbol near", "неожиданный символ рядом с")
			parsedError[i] = string.gsub(parsedError[i], "attempt to index", "несуществующий индекс")
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
		end
	end

	starting, ending = nil, nil

	return parsedError
end

--Отображение сообщения об ошибке компиляции скрипта в красивом окошке.
function ECSAPI.displayCompileMessage(y, reason, translate, withAnimation)

	local xSize, ySize = gpu.getResolution()

	--Переводим причину в массив
	reason = ECSAPI.parseErrorMessage(reason, translate)

	--Получаем ширину и высоту окошка
	local width = math.floor(xSize * 7 / 10)
	local height = #reason + 6
	local textWidth = width - 11

	--Просчет вот этой хуйни, аааахаахах
	local difference = ySize - (height + y)
	if difference < 0 then
		for i = 1, (math.abs(difference) + 1) do
			table.remove(reason, 1)
		end
		table.insert(reason, 1, "…")
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
	local oldPixels = ECSAPI.rememberOldPixels(x, y, x + width + 1, y + height)

	--Типа анимация, ога
	if withAnimation then
		for i = 1, height, 1 do
			ECSAPI.square(x, y, width, i, ECSAPI.windowColors.background)
			ECSAPI.windowShadow(x, y, width, i)
			os.sleep(0.01)
		end
	else
		ECSAPI.square(x, y, width, height, ECSAPI.windowColors.background)
		ECSAPI.windowShadow(x, y, width, height)
	end

	--Рисуем воскл знак
	ECSAPI.drawCustomImage(x + 2, y + 1, errorImage)

	--Рисуем текст
	local yPos = y + 1
	local xPos = x + 9
	gpu.setBackground(ECSAPI.windowColors.background)

	ECSAPI.colorText(xPos, yPos, ECSAPI.windowColors.usualText, "Код ошибки:")
	yPos = yPos + 2

	gpu.setForeground( 0xcc0000 )
	for i = 1, #reason do
		gpu.set(xPos, yPos, ECSAPI.stringLimit("end", reason[i], textWidth))
		yPos = yPos + 1
	end

	yPos = yPos + 1
	ECSAPI.colorText(xPos, yPos, ECSAPI.windowColors.usualText, ECSAPI.stringLimit("end", "Нажмите любую клавишу, чтобы продолжить", textWidth))

	--Пикаем звуком кароч
	for i = 1, 3 do
		computer.beep(1000)
	end

	--Ждем сам знаешь чего
	ECSAPI.waitForTouchOrClick()

	--Рисуем, че было нарисовано
	ECSAPI.drawOldPixels(oldPixels)
end

--Спросить, заменять ли файл (если таковой уже имеется)
function ECSAPI.askForReplaceFile(path)
	if fs.exists(path) then
		local action = ECSAPI.universalWindow("auto", "auto", 46, ECSAPI.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x262626, "Файл \"".. fs.name(path) .. "\" уже имеется в этом месте."}, {"CenterText", 0x262626, "Заменить его перемещаемым объектом?"}, {"EmptyLine"}, {"Button", {0xdddddd, 0x262626, "Оставить оба"}, {0xffffff, 0x262626, "Отмена"}, {ECSAPI.colors.lightBlue, 0xffffff, "Заменить"}})
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
function ECSAPI.checkName(name, path)
	--Если ввели хуйню какую-то, то
	if name == "" or name == " " or name == nil then
		ECSAPI.error("Неверное имя файла.")
		return false
	else
		--Если файл с новым путем уже существует, то
		if fs.exists(path .. name) then
			ECSAPI.error("Файл \"".. name .. "\" уже имеется в этом месте.")
			return false
		--А если все заебок, то
		else
			return true
		end
	end
end

--Переименование файлов (для операционки)
function ECSAPI.rename(mainPath)
	--Задаем стартовую щнягу
	local name = fs.name(mainPath)
	path = fs.path(mainPath)
	--Рисуем окошко ввода нового имени файла
	local inputs = ECSAPI.universalWindow("auto", "auto", 30, ECSAPI.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x262626, "Переименовать"}, {"EmptyLine"}, {"Input", 0x262626, 0x880000, name}, {"EmptyLine"}, {"Button", {0xbbbbbb, 0xffffff, "OK"}})
	--Переименовываем
	if ECSAPI.checkName(inputs[1], path) then
		fs.rename(mainPath, path .. inputs[1])
	end
end

--Создать новую папку (для операционки)
function ECSAPI.newFolder(path)
	--Рисуем окошко ввода нового имени файла
	local inputs = ECSAPI.universalWindow("auto", "auto", 30, ECSAPI.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x262626, "Новая папка"}, {"EmptyLine"}, {"Input", 0x262626, 0x880000, ""}, {"EmptyLine"}, {"Button", {0xbbbbbb, 0xffffff, "OK"}})

	if ECSAPI.checkName(inputs[1], path) then
		fs.makeDirectory(path .. inputs[1])
	end
end

--Создать новый файл (для операционки)
function ECSAPI.newFile(path)
	--Рисуем окошко ввода нового имени файла
	local inputs = ECSAPI.universalWindow("auto", "auto", 30, ECSAPI.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x262626, "Новый файл"}, {"EmptyLine"}, {"Input", 0x262626, 0x880000, ""}, {"EmptyLine"}, {"Button", {0xbbbbbb, 0xffffff, "OK"}})

	if ECSAPI.checkName(inputs[1], path) then
		ECSAPI.prepareToExit()
		ECSAPI.editFile(path .. inputs[1])
	end
end

--Создать новое приложение (для операционки)
function ECSAPI.newApplication(path, startName)
	--Рисуем окошко ввода нового имени файла
	local inputs
	if not startName then
		inputs = ECSAPI.universalWindow("auto", "auto", 30, ECSAPI.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x262626, "Новое приложение"}, {"EmptyLine"}, {"Input", 0x262626, 0x880000, "Введите имя"}, {"EmptyLine"}, {"Button", {0xbbbbbb, 0xffffff, "OK"}})
	end

	if ECSAPI.checkName(inputs[1] .. ".app", path) then
		local name = path .. inputs[1] .. ".app/Resources/"
		fs.makeDirectory(name)
		fs.copy("MineOS/System/OS/Icons/SampleIcon.pic", name .. "Icon.pic")
		local file = io.open(path .. inputs[1] .. ".app/" .. inputs[1] .. ".lua", "w")
		file:write("local ecs = require(\"ECSAPI\")", "\n")
		file:write("ecs.universalWindow(\"auto\", \"auto\", 30, 0xeeeeee, true, {\"EmptyLine\"}, {\"CenterText\", 0x262626, \"Hello world!\"}, {\"EmptyLine\"}, {\"Button\", {0x880000, 0xffffff, \"Hello!\"}})", "\n")
		file:close()
	end
end

--Создать приложение на основе существующего ЛУА-файла
function ECSAPI.newApplicationFromLuaFile(pathToLuaFile, pathWhereToCreateApplication)
	local data = ECSAPI.universalWindow("auto", "auto", 30, ECSAPI.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x000000, "Новое приложение"}, {"EmptyLine"}, {"Input", 0x262626, 0x880000, "Имя приложения"}, {"Input", 0x262626, 0x880000, "Путь к иконке приложения"}, {"EmptyLine"}, {"Button", {0xbbbbbb, 0xffffff, "OK"}})
	data[1] = data[1] or "MyApplication"
	data[2] = data[2] or "MineOS/System/OS/Icons/SampleIcon.pic"
	if fs.exists(data[2]) then
		fs.makeDirectory(pathWhereToCreateApplication .. "/" .. data[1] .. ".app/Resources")
		fs.copy(pathToLuaFile, pathWhereToCreateApplication .. "/" .. data[1] .. ".app/" .. data[1] .. ".lua")
		fs.copy(data[2], pathWhereToCreateApplication .. "/" .. data[1] .. ".app/Resources/Icon.pic")

		--ECSAPI.universalWindow("auto", "auto", 30, ECSAPI.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x000000, "Приложение создано!"}, {"EmptyLine"}, {"Button", {ecs.colors.green, 0xffffff, "OK"}})
	else
		ECSAPI.error("Указанный файл иконки не существует.")
		return
	end
end

--Простое информационное окошечко. Возвращает старые пиксели - мало ли понадобится.
function ECSAPI.info(x, y, title, text)
	x = x or "auto"
	y = y or "auto"
	title = title or " "
	text = text or "Sample text"

	local width = unicode.len(text) + 4
	local height = 4
	x, y = ECSAPI.correctStartCoords(x, y, width, height)

	local oldPixels = ECSAPI.rememberOldPixels(x, y, x + width + 1, y + height)

	ECSAPI.emptyWindow(x, y, width, height, title)
	ECSAPI.colorTextWithBack(x + 2, y + 2, ECSAPI.windowColors.usualText, ECSAPI.windowColors.background, text)

	return oldPixels
end

--Вертикальный скроллбар. Маст-хев!
function ECSAPI.srollBar(x, y, width, height, countOfAllElements, currentElement, backColor, frontColor)
	local sizeOfScrollBar = math.ceil(1 / countOfAllElements * height)
	local displayBarFrom = math.floor(y + height * ((currentElement - 1) / countOfAllElements))

	ECSAPI.square(x, y, width, height, backColor)
	ECSAPI.square(x, displayBarFrom, width, sizeOfScrollBar, frontColor)

	sizeOfScrollBar, displayBarFrom = nil, nil
end

--Отрисовка поля с текстом. Сюда пихать массив вида {"строка1", "строка2", "строка3", ...}
function ECSAPI.textField(x, y, width, height, lines, displayFrom, background, foreground, scrollbarBackground, scrollbarForeground)
	x, y = ECSAPI.correctStartCoords(x, y, width, height)

	background = background or 0xffffff
	foreground = foreground or ECSAPI.windowColors.usualText

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

	ECSAPI.square(x, y, width - 1, height, background)
	ECSAPI.srollBar(x + width - 1, y, 1, height, sLines, displayFrom, scrollbarBackground, scrollbarForeground)

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
function ECSAPI.getCorrectLangName(pathToLangs)
	local language = _G.OSSettings.language .. ".lang"
	if not fs.exists(pathToLangs .. "/" .. language) then
		language = "English.lang"
	end
	return language
end

--Чтение языкового файла  (для операционки)
function ECSAPI.readCorrectLangFile(pathToLangs)
	local lang
	
	local language = ECSAPI.getCorrectLangName(pathToLangs)

	lang = config.readAll(pathToLangs .. "/" .. language)

	return lang
end

-------------------------ВСЕ ДЛЯ ОСКИ-------------------------------------------------------------------------------

function ECSAPI.sortFiles(path, fileList, sortingMethod, showHiddenFiles)
	local sortedFileList = {}
	if sortingMethod == "type" then
		local typeList = {}
		for i = 1, #fileList do
			local fileFormat = ECSAPI.getFileFormat(fileList[i]) or "Script"
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
	elseif sortingMethod == "name" then
		sortedFileList = fileList
	elseif sortingMethod == "date" then
		for i = 1, #fileList do
			fileList[i] = {fileList[i], fs.lastModified(path .. fileList[i])}
		end
		table.sort(fileList, function(a,b) return a[2] > b[2] end)
		for i = 1, #fileList do
			table.insert(sortedFileList, fileList[i][1])
		end
	else
		error("Unknown sorting method")
	end

	local i = 1
	while i <= #sortedFileList do
		if not showHiddenFiles and ECSAPI.isFileHidden(sortedFileList[i]) then
			table.remove(sortedFileList, i)
		else
			i = i + 1
		end
	end

	return sortedFileList
end

--Сохранить файл конфигурации ОС
function ECSAPI.saveOSSettings()
	local pathToOSSettings = "MineOS/System/OS/OSSettings.cfg"
	if not _G.OSSettings then error("Массив настроек ОС отсутствует в памяти!") end
	fs.makeDirectory(fs.path(pathToOSSettings))
	local file = io.open(pathToOSSettings, "w")
	file:write(serialization.serialize(_G.OSSettings))
	file:close()
end

--Загрузить файл конфигурации ОС, а если его не существует, то создать
function ECSAPI.loadOSSettings()
	local pathToOSSettings = "MineOS/System/OS/OSSettings.cfg"
	if fs.exists(pathToOSSettings) then
		local file = io.open(pathToOSSettings, "r")
		_G.OSSettings = serialization.unserialize(file:read("*a"))
		file:close()
	else
		_G.OSSettings = { showHelpOnApplicationStart = true, language = "Russian" }
		ECSAPI.saveOSSettings()
	end
end

--Отобразить окно с содержимым файла информации о приложении
function ECSAPI.applicationHelp(pathToApplication)
	local pathToAboutFile = pathToApplication .. "/resources/About.txt"
	if fs.exists(pathToAboutFile) and _G.OSSettings and _G.OSSettings.showHelpOnApplicationStart then
		local applicationName = fs.name(pathToApplication)
		local file = io.open(pathToAboutFile, "r")
		local text = ""
		for line in file:lines() do text = text .. line .. " " end
		file:close()

		local data = ECSAPI.universalWindow("auto", "auto", 52, 0xeeeeee, true, {"EmptyLine"}, {"CenterText", 0x262626, "О приложении " .. applicationName}, {"EmptyLine"}, {"TextField", 14, 0xffffff, 0x262626, 0xcccccc, 0x3366CC, text}, {"EmptyLine"}, {"Switch", 0x3366CC, 0xffffff, 0x262626, "Показывать информацию о приложениях", true}, {"EmptyLine"}, {"Button", {ECSAPI.colors.green, 0xffffff, "OK"}})
		if data[1] == false then
			_G.OSSettings.showHelpOnApplicationStart = false
			ECSAPI.saveOSSettings()
		end
	end
end

--Создать ярлык для конкретной проги (для операционки)
function ECSAPI.createShortCut(path, pathToProgram)
	fs.remove(path)
	fs.makeDirectory(fs.path(path))
	local file = io.open(path, "w")
	file:write("return ", "\"", pathToProgram, "\"")
	file:close()
end

--Получить данные о файле из ярлыка (для операционки)
function ECSAPI.readShortcut(path)
	local success, filename = pcall(loadfile(path))
	if success then
		return filename
	else
		error("Ошибка чтения файла ярлыка. Вероятно, он создан криво, либо не существует в папке " .. path)
	end
end

--Редактирование файла (для операционки)
function ECSAPI.editFile(path)
	ECSAPI.prepareToExit()
	shell.execute("edit "..path)
end

-- Копирование папки через рекурсию, т.к. fs.copy() не поддерживает папки
-- Ну долбоеб автор мода - хули я тут сделаю? Придется так вот
-- Хотя можно юзать обычный bin/cp, как это сделано в дисковом дубляже. Надо перекодить, короч
function ECSAPI.copyFolder(path, toPath)
	local function doCopy(path)
		local fileList = ECSAPI.getFileList(path)
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
function ECSAPI.copy(from, to)
	local name = fs.name(from)
	local toName = to .. "/" .. name
	local action = ECSAPI.askForReplaceFile(toName)
	if action == nil or action == "replace" then
		fs.remove(toName)
		if fs.isDirectory(from) then
			ECSAPI.copyFolder(from, toName)
		else
			fs.copy(from, toName)
		end
	elseif action == "keepBoth" then
		if fs.isDirectory(from) then
			ECSAPI.copyFolder(from, to .. "/(copy)" .. name)
		else
			fs.copy(from, to .. "/(copy)" .. name)
		end	
	end
end

ECSAPI.OSIconsWidth = 12
ECSAPI.OSIconsHeight = 6

--Вся необходимая информация для иконок
local function OSIconsInit()
	if not _G.image then _G.image = require("image") end
	if not _G.buffer then _G.buffer = require("doubleBuffering") end
	if not ECSAPI.OSIcons then
		--Константы для иконок
		ECSAPI.OSIcons = {}
		ECSAPI.pathToIcons = "MineOS/System/OS/Icons/"

		--Иконки
		ECSAPI.OSIcons.folder = image.load(ECSAPI.pathToIcons .. "Folder.pic")
		ECSAPI.OSIcons.script = image.load(ECSAPI.pathToIcons .. "Script.pic")
		ECSAPI.OSIcons.text = image.load(ECSAPI.pathToIcons .. "Text.pic")
		ECSAPI.OSIcons.config = image.load(ECSAPI.pathToIcons .. "Config.pic")
		ECSAPI.OSIcons.lua = image.load(ECSAPI.pathToIcons .. "Lua.pic")
		ECSAPI.OSIcons.image = image.load(ECSAPI.pathToIcons .. "Image.pic")
		ECSAPI.OSIcons.imageJPG = image.load(ECSAPI.pathToIcons .. "RawImage.pic")
		ECSAPI.OSIcons.pastebin = image.load(ECSAPI.pathToIcons .. "Pastebin.pic")
		ECSAPI.OSIcons.fileNotExists = image.load(ECSAPI.pathToIcons .. "FileNotExists.pic")
		ECSAPI.OSIcons.archive = image.load(ECSAPI.pathToIcons .. "Archive.pic")
	end
end

--Отрисовка одной иконки
function ECSAPI.drawOSIcon(x, y, path, showFileFormat, nameColor)
	--Инициализируем переменные иконок. Чисто для уменьшения расхода оперативки.
	OSIconsInit()
	--Получаем формат файла
	local fileFormat = ECSAPI.getFileFormat(path)
	--Создаем пустую переменную для конкретной иконки, для ее типа
	local icon
	--Если данный файл является папкой, то
	if fs.isDirectory(path) then
		if fileFormat == ".app" then
			icon = path .. "/Resources/Icon.pic"
			--Если данной иконки еще нет в оперативке, то загрузить ее
			if not ECSAPI.OSIcons[icon] then
				ECSAPI.OSIcons[icon] = image.load(icon)
			end
		else
			icon = "folder"
		end
	else
		if fileFormat == ".lnk" then
			local shortcutLink = ECSAPI.readShortcut(path)
			ECSAPI.drawOSIcon(x, y, shortcutLink, showFileFormat, nameColor)
			--Стрелочка
			buffer.set(x + ECSAPI.OSIconsWidth - 3, y + ECSAPI.OSIconsHeight - 3, 0xFFFFFF, 0x000000, "<")
			return 0
		elseif fileFormat == ".cfg" or fileFormat == ".config" then
			icon = "config"
		elseif fileFormat == ".txt" or fileFormat == ".rtf" then
			icon = "text"
		elseif fileFormat == ".lua" then
		 	icon = "lua"
		elseif fileFormat == ".pic" or fileFormat == ".png" then
		 	icon = "image"
		elseif fileFormat == ".rawpic" then
		 	icon = "imageJPG"
		elseif fileFormat == ".paste" then
			icon = "pastebin"
		elseif fileFormat == ".pkg" then
			icon = "archive"
		elseif not fs.exists(path) then
			icon = "fileNotExists"
		else
			icon = "script"
		end
	end

	--Рисуем иконку
	buffer.image(x + 2, y, ECSAPI.OSIcons[icon])

	--Делаем текст для иконки
	local text = fs.name(path)
	if not showFileFormat and fileFormat then
		text = unicode.sub(text, 1, -(unicode.len(fileFormat) + 1))
	end
	text = ECSAPI.stringLimit("end", text, ECSAPI.OSIconsWidth)
	--Рассчитываем позицию текста
	local textPos = x + math.floor(ECSAPI.OSIconsWidth / 2 - unicode.len(text) / 2)
	--Рисуем текст под иконкой
	buffer.text(textPos, y + ECSAPI.OSIconsHeight - 1, nameColor or 0xffffff, text)

end

--ЗАПУСТИТЬ ПРОГУ
function ECSAPI.launchIcon(path, arguments)
	--Запоминаем, какое разрешение было
	local oldWidth, oldHeight = gpu.getResolution()
	--Создаем нормальные аргументы для Шелла
	if arguments then arguments = " " .. arguments else arguments = "" end
	--Получаем файл формат заранее
	local fileFormat = ECSAPI.getFileFormat(path)
	local isDirectory = fs.isDirectory(path)
	--Если это приложение
	if fileFormat == ".app" then
		ECSAPI.applicationHelp(path)
		local cyka = path .. "/" .. ECSAPI.hideFileFormat(fs.name(path)) .. ".lua"
		local success, reason = shell.execute(cyka)
		if not success then ECSAPI.displayCompileMessage(1, reason, true) end
	--Если это папка
	elseif (fileFormat == "" or fileFormat == nil) and isDirectory then
		shell.execute("MineOS/Applications/Finder.app/Finder.lua " .. path)
	--Если это обычный луа файл - т.е. скрипт
	elseif fileFormat == ".lua" or fileFormat == nil then
		ECSAPI.prepareToExit()
		local success, reason = shell.execute(path .. arguments)
		if success then
			print(" ")
			print("Program sucessfully executed. Press any key to continue.")
			print(" ")
		else
			ECSAPI.displayCompileMessage(1, reason, true)
		end
	--Если это фоточка
	elseif fileFormat == ".pic" then
		shell.execute("MineOS/Applications/Photoshop.app/Photoshop.lua open " .. path)
	--Если это фоточка
	elseif fileFormat == ".raw" then
		shell.execute("MineOS/Applications/Photoshop.app/Photoshop.lua open " .. path)
	--Если это текст или конфиг или языковой
	elseif fileFormat == ".txt" or fileFormat == ".cfg" or fileFormat == ".lang" then
		ECSAPI.prepareToExit()
		shell.execute("edit "..path)
	--Если это ярлык
	elseif fileFormat == ".lnk" then
		local shortcutLink = ECSAPI.readShortcut(path)
		if fs.exists(shortcutLink) then
			ECSAPI.launchIcon(shortcutLink)
		else
			ECSAPI.error("File from shortcut link doesn't exists.")
		end
	--Если это ссылка на пастебин
	elseif fileFormat == ".paste" then
		local shortcutLink = ECSAPI.readShortcut(path)
		ECSAPI.prepareToExit()
		local success, reason = shell.execute("pastebin run " .. shortcutLink)
		if success then
			print(" ")
			print("Program sucessfully executed. Press any key to continue.")
			ECSAPI.waitForTouchOrClick()
		else
			ECSAPI.displayCompileMessage(1, reason, false)
		end
	--Если это архив
	elseif fileFormat == ".zip" then
		zip.unarchive(path, (fs.path(path) or ""))
	end
	--Ставим старое разрешение
	gpu.setResolution(oldWidth, oldHeight)
end




---------------------------------------------ОКОШЕЧКИ------------------------------------------------------------


--Описание ниже, ебана. Ниже - это значит в самой жопе кода!
function ECSAPI.universalWindow(x, y, width, background, closeWindowAfter, ...)
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
			correctWidth(7)
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
			objects[i].wrapped = ECSAPI.stringWrap({objects[i][3]}, width - 4)
			objects[i].height = #objects[i].wrapped
			height = height + objects[i].height
		else
			height = height + objectsHeights[objectType]
		end
	end

	--Коорректируем стартовые координаты
	x, y = ECSAPI.correctStartCoords(x, y, width, height)
	--Запоминаем инфу о том, что было нарисовано, если это необходимо
	local oldPixels, oldBackground, oldForeground
	if closeWindowAfter then
		oldBackground = gpu.getBackground()
		oldForeground = gpu.getForeground()
		oldPixels = ECSAPI.rememberOldPixels(x, y, x + width - 1, y + height - 1)
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
			gpu.set(xPos, objects[number].y, objects[number][3])
		
		elseif objectType == "input" then

			if active then
				--Рамочка
				ECSAPI.border(x + 1, objects[number].y, width - 2, objectsHeights.input, background, objects[number][3])
				--Тестик
				objects[number][4] = ECSAPI.inputText(x + 3, objects[number].y + 1, width - 6, "", background, objects[number][3], false, objects[number][5])
			else
				--Рамочка
				ECSAPI.border(x + 1, objects[number].y, width - 2, objectsHeights.input, background, objects[number][2])
				--Текстик
				gpu.set(x + 3, objects[number].y + 1, ECSAPI.stringLimit("start", objects[number][4], width - 6))
				ECSAPI.inputText(x + 3, objects[number].y + 1, width - 6, objects[number][4], background, objects[number][2], true, objects[number][5])
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
			ECSAPI.separator(xOfSlider, yOfSlider, position, background, objects[number][3])
			ECSAPI.separator(xOfSlider + position, yOfSlider, widthOfSlider - position, background, objects[number][2])
			--Слудир
			ECSAPI.square(xOfSlider + position, yOfSlider, 2, 1, objects[number][3])

			--Текстик под слудиром
			if showSliderValue then
				local text = showSliderValue .. tostring(objects[number][6]) .. (objects[number][8] or "")
				local textPos = (xOfSlider + widthOfSlider / 2 - unicode.len(text) / 2)
				ECSAPI.square(x, yOfSlider + 1, width, 1, background)
				ECSAPI.colorText(textPos, yOfSlider + 1, objects[number][2], text)
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
				ECSAPI.border(x + 1, yPos, 5, 3, background, usualColor)
				--Текст
				gpu.set(x + 7, yPos + 1, objects[number][i])
				--Галочка
				if objects[number].selectedData == (i - 3) then
					ECSAPI.colorText(x + 3, yPos + 1, selectionColor, symbol)
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
				gpu.set(x + 3, objects[number].y + 1, ECSAPI.stringLimit("start", objects[number].selectedElement, width - 6))
				ECSAPI.colorText(x + width - 4, objects[number].y + 1, arrowColor, "▼")
			end

			bordak(borderColor)
		
			--Выпадающий список, самый гемор, блядь
			if active then
				local xPos, yPos = x + 1, objects[number].y + 3
				local spisokWidth = width - 2
				local countOfElements = #objects[number] - 3
				local spisokHeight = countOfElements + 1
				local oldPixels = ECSAPI.rememberOldPixels( xPos, yPos, xPos + spisokWidth - 1, yPos + spisokHeight - 1)

				local coords = {}

				bordak(arrowColor)

				--Рамку рисуем поверх фоника
				local topLine = "├"..string.rep("─", spisokWidth - 6).."┴───┤"
				local midLine = "│"..string.rep(" ", spisokWidth - 2).."│"
				local botLine = "└"..string.rep("─", selectorWidth - 2) .. "┘"
				ECSAPI.colorTextWithBack(xPos, yPos - 1, arrowColor, background, topLine)
				for i = 1, spisokHeight - 1 do
					gpu.set(xPos, yPos + i - 1, midLine)
				end
				gpu.set(xPos, yPos + spisokHeight - 1, botLine)

				--Элементы рисуем
				xPos = xPos + 2
				for i = 1, countOfElements do
					ECSAPI.colorText(xPos, yPos, borderColor, ECSAPI.stringLimit("start", objects[number][i + 3], spisokWidth - 4))
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
							if ECSAPI.clickedAtArea(e[3], e[4], coords[i][1], coords[i][2], coords[i][3], coords[i][4]) then
								ECSAPI.square(coords[i][1], coords[i][2], spisokWidth - 2, 1, ECSAPI.colors.blue)
								ECSAPI.colorText(coords[i][1] + 1, coords[i][2], 0xffffff, objects[number][i + 3])
								os.sleep(0.3)
								objects[number].selectedElement = objects[number][i + 3]
								exit = true
								break
							end
						end
					end
				end

				ECSAPI.drawOldPixels(oldPixels)
			end

			newObj("Selectors", number, x + 1, objects[number].y, x + width - 2, objects[number].y + 2)

		elseif objectType == "separator" then
			ECSAPI.separator(x, objects[number].y, width, background, objects[number][2])
		
		elseif objectType == "textfield" then
			newObj("TextFields", number, x + 1, objects[number].y, x + width - 2, objects[number].y + objects[number][2] - 1)
			if not objects[number].strings then objects[number].strings = ECSAPI.stringWrap({objects[number][7]}, width - 7) end
			objects[number].displayFrom = objects[number].displayFrom or 1
			ECSAPI.textField(x + 2, objects[number].y, width - 4, objects[number][2], objects[number].strings, objects[number].displayFrom, objects[number][3], objects[number][4], objects[number][5], objects[number][6])
		
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
					local x1, y1, x2, y2 = ECSAPI.drawButton(xPos, yPos, widthOfButton, 3, objects[number][i][3], objects[number][i][1], objects[number][i][2])
					table.insert(obj["MultiButtons"][number], {x1, y1, x2, y2, widthOfButton})
					xPos = x2 + 1

					if i == #objects[number] then
						ECSAPI.square(xPos, yPos, x + width - xPos, 3, objects[number][i][1])
						obj["MultiButtons"][number][i - 1][5] = obj["MultiButtons"][number][i - 1][5] + x + width - xPos
					end

					x1, y1, x2, y2 = nil, nil, nil, nil
				end
			end

		elseif objectType == "switch" then

			local xPos, yPos = x + 2, objects[number].y
			local activeColor, passiveColor, textColor, text, state = objects[number][2], objects[number][3], objects[number][4], objects[number][5], objects[number][6]
			local switchWidth = 8
			ECSAPI.colorTextWithBack(xPos, yPos, textColor, background, text)

			xPos = x + width - switchWidth - 2
			if state then
				ECSAPI.square(xPos, yPos, switchWidth, 1, activeColor)
				ECSAPI.square(xPos + switchWidth - 2, yPos, 2, 1, passiveColor)
				--ECSAPI.colorTextWithBack(xPos + 4, yPos, passiveColor, activeColor, "ON")
			else
				ECSAPI.square(xPos, yPos, switchWidth, 1, passiveColor - 0x444444)
				ECSAPI.square(xPos, yPos, 2, 1, passiveColor)
				--ECSAPI.colorTextWithBack(xPos + 4, yPos, passiveColor, passiveColor - 0x444444, "OFF")
			end
			newObj("Switches", number, xPos, yPos, xPos + switchWidth - 1, yPos)
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
			else
				table.insert(massiv, nil)
			end
		end

		return massiv
	end

	local function redrawBeforeClose()
		if closeWindowAfter then
			ECSAPI.drawOldPixels(oldPixels)
			gpu.setBackground(oldBackground)
			gpu.setForeground(oldForeground)
		end
	end

	--Рисуем окно
	ECSAPI.square(x, y, width, height, background)
	displayAllObjects()

	while true do
		local e = {event.pull()}
		if e[1] == "touch" or e[1] == "drag" then

			--Анализируем клик на кнопки
			if obj["MultiButtons"] then
				for key in pairs(obj["MultiButtons"]) do
					for i = 1, #obj["MultiButtons"][key] do
						if ECSAPI.clickedAtArea(e[3], e[4], obj["MultiButtons"][key][i][1], obj["MultiButtons"][key][i][2], obj["MultiButtons"][key][i][3], obj["MultiButtons"][key][i][4]) then
							ECSAPI.drawButton(obj["MultiButtons"][key][i][1], obj["MultiButtons"][key][i][2], obj["MultiButtons"][key][i][5], 3, objects[key][i + 1][3], objects[key][i + 1][2], objects[key][i + 1][1])
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
					if ECSAPI.clickedAtArea(e[3], e[4], obj["Inputs"][key][1], obj["Inputs"][key][2], obj["Inputs"][key][3], obj["Inputs"][key][4]) then
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
						if ECSAPI.clickedAtArea(e[3], e[4], obj["Selects"][key][i][1], obj["Selects"][key][i][2], obj["Selects"][key][i][3], obj["Selects"][key][i][4]) then
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
					if ECSAPI.clickedAtArea(e[3], e[4], obj["Selectors"][key][1], obj["Selectors"][key][2], obj["Selectors"][key][3], obj["Selectors"][key][4]) then
						displayObject(key, true)
						displayObject(key)
						break
					end
				end
			end

			--Слайдеры, епта! "Потный матан", все делы
			if obj["Sliders"] then
				for key in pairs(obj["Sliders"]) do
					if ECSAPI.clickedAtArea(e[3], e[4], obj["Sliders"][key][1], obj["Sliders"][key][2], obj["Sliders"][key][3], obj["Sliders"][key][4]) then
						local xOfSlider, dolya = obj["Sliders"][key][1], obj["Sliders"][key][5]
						local currentPixels = e[3] - xOfSlider
						local currentValue = math.floor(currentPixels / dolya)
						--Костыль
						if e[3] == obj["Sliders"][key][3] then currentValue = objects[key][5] end
						objects[key][6] = currentValue
						displayObject(key)
						break
					end
				end
			end

			if obj["Switches"] then
				for key in pairs(obj["Switches"]) do
					if ECSAPI.clickedAtArea(e[3], e[4], obj["Switches"][key][1], obj["Switches"][key][2], obj["Switches"][key][3], obj["Switches"][key][4]) then
						objects[key][6] = not objects[key][6]
						displayObject(key)
						break
					end
				end
			end

		elseif e[1] == "scroll" then
			if obj["TextFields"] then
				for key in pairs(obj["TextFields"]) do
					if ECSAPI.clickedAtArea(e[3], e[4], obj["TextFields"][key][1], obj["TextFields"][key][2], obj["TextFields"][key][3], obj["TextFields"][key][4]) then
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
function ECSAPI.demoWindow()
	--Очищаем экран перед юзанием окна и ставим курсор на 1, 1
	ECSAPI.prepareToExit()
	--Рисуем окно и получаем данные после взаимодействия с ним
	local data = ECSAPI.universalWindow("auto", "auto", 36, 0xeeeeee, true, {"EmptyLine"}, {"CenterText", 0x880000, "Здорово, ебана!"}, {"EmptyLine"}, {"Input", 0x262626, 0x880000, "Сюда вводить можно"}, {"Selector", ECSAPI.colors.green, 0x880000, "Выбор формата", "PNG", "JPG", "GIF", "PSD"}, {"EmptyLine"}, {"WrappedText", 0x262626, "Тест автоматического переноса букв в зависимости от ширины данного окна. Пока что тупо режет на куски, не особо красиво."}, {"EmptyLine"}, {"Select", 0x262626, 0x880000, "Я пидор", "Я не пидор"}, {"Slider", 0x262626, 0x880000, 1, 100, 50, "Убито ", " младенцев"}, {"EmptyLine"}, {"Separator", 0xaaaaaa}, {"Switch", 0xF2B233, 0xffffff, 0x262626, "✈ Авиарежим", false}, {"EmptyLine"}, {"Switch", 0x3366CC, 0xffffff, 0x262626, "☾  Не беспокоить", true}, {"Separator", 0xaaaaaa},  {"EmptyLine"}, {"TextField", 5, 0xffffff, 0x262626, 0xcccccc, 0x3366CC, "Тест текстового информационного поля. По сути это тот же самый WrappedText, разве что эта хрень ограничена по высоте, и ее можно скроллить. Ну же, поскролль меня! Скролль меня полностью! Моя жадная пизда жаждет твой хуй!"}, {"EmptyLine"}, {"Button", {0x57A64E, 0xffffff, "Да"}, {0xF2B233, 0xffffff, "Нет"}, {0xCC4C4C, 0xffffff, "Отмена"}})
	--Еще разок
	ECSAPI.prepareToExit()
	--Выводим данные
	print(" ")
	print("Вывод данных из окна:")
	for i = 1, #data do print("["..i.."] = "..tostring(data[i])) end
	print(" ")
end

-- ECSAPI.demoWindow()

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
--ECSAPI.demoWindow()

--Функция-отладчик, выдающая окно с указанным сообщением об ошибке. Полезна при дебаге.
--ECSAPI.error("Это сообщение об ошибке! Hello world!")

--Функция, спрашивающая, стоит ли заменять указанный файл, если он уже имеется
--ECSAPI.askForReplaceFile("OS.lua")

--Функция, предлагающая сохранить файл в нужном месте в нужном формате.
--ECSAPI.universalWindow("auto", "auto", 30, ECSAPI.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x262626, "Сохранить как"}, {"EmptyLine"}, {"Input", 0x262626, 0x880000, "Путь"}, {"Selector", 0x262626, 0x880000, "PNG", "JPG", "PSD"}, {"EmptyLine"}, {"Button", {0xbbbbbb, 0xffffff, "OK!"}})


----------------------------------------------------------------------------------------------------

ECSAPI.applicationHelp("MineOS/Applications/InfoPanel.app")

return ECSAPI




