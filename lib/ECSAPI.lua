local component = require("component")
local term = require("term")
local unicode = require("unicode")
local event = require("event")
local fs = require("filesystem")
local shell = require("shell")
local keyboard = require("keyboard")
local computer = require("computer")
local fs = require("filesystem")
--local thread = require("thread")
local gpu = component.gpu
local screen = component.screen

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
	white = 0xF0F0F0,
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
    black = 0x000000
}

----------------------------------------------------------------------------------------------------

--МАСШТАБ МОНИТОРА
function ECSAPI.setScale(scale, debug)
	--КОРРЕКЦИЯ МАСШТАБА, ЧТОБЫ ВСЯКИЕ ДАУНЫ НЕ ДЕЛАЛИ ТОГО, ЧЕГО НЕ СЛЕДУЕТ
	if scale > 1 then
		scale = 1
	elseif scale < 0.1 then
		scale = 0.1
	end

	--Просчет пикселей в блоках кароч - забей, так надо
	local function calculateAspect(screens)
	  local abc = 12

	  if screens == 2 then
	    abc = 28
	  elseif screens > 2 then
	    abc = 28 + (screens - 2) * 16
	  end

	  return abc
	end

	--Собсна, арсчет масштаба
	local xScreens, yScreens = component.screen.getAspectRatio()

	local xPixels, yPixels = calculateAspect(xScreens), calculateAspect(yScreens)

	local proportion = xPixels / yPixels

	--Костыль
	local xMax, yMax  = gpu.maxResolution()
	xMax = yMax * 2

	local newWidth, newHeight

	if proportion >= 1 then
		newWidth = math.floor(xMax * scale)
		newHeight = math.floor(newWidth / proportion / 2)
	else
		newHeight = math.floor(yMax * scale)
		newWidth = math.floor(newHeight * proportion * 2)
	end

	if debug then
		print(" ")
		print("Максимальное разрешение: "..xMax.."x"..yMax)
		print("Пропорция монитора: "..xPixels.."x"..yPixels)
		print(" ")
		print("Новое разрешение: "..newWidth.."x"..newHeight)
		print(" ")
	end

	gpu.setResolution(newWidth, newHeight)
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

--ИЗ 16 В РГБ
function ECSAPI.HEXtoRGB(color)
  color = math.ceil(color)

  local rr = bit32.rshift( color, 16 )
  local gg = bit32.rshift( bit32.band(color, 0x00ff00), 8 )
  local bb = bit32.band(color, 0x0000ff)

  return rr, gg, bb
end

--ИЗ РГБ В 16
function ECSAPI.RGBtoHEX(rr, gg, bb)
  return bit32.lshift(rr, 16) + bit32.lshift(gg, 8) + bb
end

--ИЗ ХСБ В РГБ
function ECSAPI.HSBtoRGB(h, s, v)
  local rr, gg, bb = 0, 0, 0
  local const = 255

  s = s/100
  v = v/100
  
  local i = math.floor(h/60)
  local f = h/60 - i
  
  local p = v*(1-s)
  local q = v*(1-s*f)
  local t = v*(1-(1-f)*s)

  if ( i == 0 ) then rr, gg, bb = v, t, p end
  if ( i == 1 ) then rr, gg, bb = q, v, p end
  if ( i == 2 ) then rr, gg, bb = p, v, t end
  if ( i == 3 ) then rr, gg, bb = p, q, v end
  if ( i == 4 ) then rr, gg, bb = t, p, v end
  if ( i == 5 ) then rr, gg, bb = v, p, q end

  return rr*const, gg*const, bb*const
end

--КЛИКНУЛИ ЛИ В ЗОНУ
function ECSAPI.clickedAtArea(x,y,sx,sy,ex,ey)
  if (x >= sx) and (x <= ex) and (y >= sy) and (y <= ey) then return true end    
  return false
end

--ОЧИСТКА ЭКРАНА ЦВЕТОМ
function ECSAPI.clearScreen(color)
  if color then gpu.setBackground(color) end
  term.clear()
end

--ПРОСТОЙ СЕТПИКСЕЛЬ, ИБО ЗАЕБАЛО
function ECSAPI.setPixel(x,y,color)
  gpu.setBackground(color)
  gpu.set(x,y," ")
end

--ЦВЕТНОЙ ТЕКСТ
function ECSAPI.colorText(x,y,textColor,text)
  gpu.setForeground(textColor)
  gpu.set(x,y,text)
end

--ЦВЕТНОЙ ТЕКСТ С ЖОПКОЙ!
function ECSAPI.colorTextWithBack(x,y,textColor,backColor,text)
  gpu.setForeground(textColor)
  gpu.setBackground(backColor)
  gpu.set(x,y,text)
end

--ИНВЕРСИЯ HEX-ЦВЕТА
function ECSAPI.invertColor(color)
  return 0xffffff - color
end

--
--АДАПТИВНЫЙ ТЕКСТ, ПОДСТРАИВАЮЩИЙСЯ ПОД ФОН
function ECSAPI.adaptiveText(x,y,text,textColor)
  gpu.setForeground(textColor)
  x = x - 1
  for i=1,unicode.len(text) do
    local info = {gpu.get(x+i,y)}
    gpu.setBackground(info[3])
    gpu.set(x+i,y,unicode.sub(text,i,i))
  end
end

--ИНВЕРТИРОВАННЫЙ ПО ЦВЕТУ ТЕКСТ НА ОСНОВЕ ФОНА
function ECSAPI.invertedText(x,y,symbol)
  local info = {gpu.get(x,y)}
  ECSAPI.adaptiveText(x,y,symbol,ECSAPI.invertColor(info[3]))
end

--АДАПТИВНОЕ ОКРУГЛЕНИЕ ЧИСЛА
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

function ECSAPI.square(x,y,width,height,color)
  gpu.setBackground(color)
  gpu.fill(x,y,width,height," ")
end

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

function ECSAPI.separator(x, y, width, back, fore)
	ECSAPI.colorTextWithBack(x, y, fore, back, string.rep("─", width))
end

--АВТОМАТИЧЕСКОЕ ЦЕНТРИРОВАНИЕ ТЕКСТА ПО КООРДИНАТЕ
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

--
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

--КОРРЕКТИРОВКА СТАРТОВЫХ КООРДИНАТ
function ECSAPI.correctStartCoords(xStart,yStart,xWindowSize,yWindowSize)
	local xSize,ySize = gpu.getResolution()
	if xStart == "auto" then
		xStart = math.floor(xSize/2 - xWindowSize/2)
	end
	if yStart == "auto" then
		yStart = math.floor(ySize/2 - yWindowSize/2)
	end
	return xStart,yStart
end

--ЗАПОМНИТЬ ОБЛАСТЬ ПИКСЕЛЕЙ
function ECSAPI.rememberOldPixels(x, y, x2, y2)
	local newPNGMassiv = { ["backgrounds"] = {} }
	newPNGMassiv.x, newPNGMassiv.y = x, y

	--Перебираем весь массив стандартного PNG-вида по высоте
	local xCounter, yCounter = 1, 1
	for j = y, y2 do
		xCounter = 1
		for i = x, x2 do
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

--НАРИСОВАТЬ ЗАПОМНЕННЫЕ ПИКСЕЛИ ИЗ МАССИВА
function ECSAPI.drawOldPixels(massivSudaPihay)

	--Отнимаем разок
	--massivSudaPihay.x, massivSudaPihay.y = massivSudaPihay.x - 1, massivSudaPihay.y - 1

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

--ОГРАНИЧЕНИЕ ДЛИНЫ СТРОКИ
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

--ПОЛУЧИТЬ СПИСОК ФАЙЛОВ ИЗ КОНКРЕТНОЙ ДИРЕКТОРИИ
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

--ПОЛУЧИТЬ ВСЕ ДРЕВО ФАЙЛОВ
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

--ПОЛУЧЕНИЕ ФОРМАТА ФАЙЛА
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

--ПРОВЕРКА, СКРЫТЫЙ ЛИ ФАЙЛ
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

--СКРЫТЬ РАСШИРЕНИЕ ФАЙЛА
function ECSAPI.hideFileFormat(path)
	local name = fs.name(path)
	local fileFormat = ECSAPI.getFileFormat(name)
	if fileFormat == nil then
		return name
	else
		return unicode.sub(name, 1, unicode.len(name) - unicode.len(fileFormat))
	end
end

function ECSAPI.reorganizeFilesAndFolders(massivSudaPihay, showHiddenFiles)
	showHiddenFiles = showHiddenFiles or true
	local massiv = {}
	for i = 1, #massivSudaPihay do
		if ECSAPI.isFileHidden(massivSudaPihay[i]) then
			table.insert(massiv, massivSudaPihay[i])
		end
	end
	for i = 1, #massivSudaPihay do
		local cyka = massivSudaPihay[i]
		if fs.isDirectory(cyka) and not ECSAPI.isFileHidden(cyka) and ECSAPI.getFileFormat(massivSudaPihay[i]) ~= ".app" then
			table.insert(massiv, massivSudaPihay[i])
		end
		cyka = nil
	end
	for i = 1, #massivSudaPihay do
		local cyka = massivSudaPihay[i]
		if (not fs.isDirectory(cyka) and not ECSAPI.isFileHidden(cyka)) or (fs.isDirectory(cyka) and not ECSAPI.isFileHidden(cyka) and ECSAPI.getFileFormat(massivSudaPihay[i]) == ".app") then
			table.insert(massiv, massivSudaPihay[i])
		end
		cyka = nil
	end

	return massiv
end

--Бесполезна теперь, используй string.gsub()
function ECSAPI.stringReplace(stroka, chto, nachto)
	local searchFrom = 1
	while true do
		local starting, ending = string.find(stroka, chto, searchFrom)
		if starting then
			stroka = unicode.sub(stroka, 1, starting - 1) .. nachto .. unicode.sub(stroka, ending + 1, -1)
			searchFrom = ending + unicode.len(nachto) + 1
		else
			break
		end
	end

	return stroka
end

--Ожидание клика либо нажатия какой-либо клавиши
function ECSAPI.waitForTouchOrClick()
	while true do
		local e = {event.pull()}
		if e[1] == "key_down" or e[1] == "touch" then break end
	end
end

----------------------------ОКОШЕЧКИ, СУКА--------------------------------------------------

--ECSAPI.windows = {}

function ECSAPI.drawButton(x,y,width,height,text,backColor,textColor)
	x,y = ECSAPI.correctStartCoords(x,y,width,height)

	local textPosX = math.floor(x + width / 2 - unicode.len(text) / 2)
	local textPosY = math.floor(y + height / 2)
	ECSAPI.square(x,y,width,height,backColor)
	ECSAPI.colorText(textPosX,textPosY,textColor,text)

	return x, y, (x + width - 1), (y + height - 1)
end

function ECSAPI.drawAdaptiveButton(x,y,offsetX,offsetY,text,backColor,textColor)
	local length = unicode.len(text)
	local width = offsetX*2 + length
	local height = offsetY*2 + 1

	x,y = ECSAPI.correctStartCoords(x,y,width,height)

	ECSAPI.square(x,y,width,height,backColor)
	ECSAPI.colorText(x+offsetX,y+offsetY,textColor,text)

	return x,y,(x+width-1),(y+height-1)
end

function ECSAPI.windowShadow(x,y,width,height)
	gpu.setBackground(ECSAPI.windowColors.shadow)
	gpu.fill(x+width,y+1,2,height," ")
	gpu.fill(x+1,y+height,width,1," ")
end

--Просто белое окошко безо всего
function ECSAPI.blankWindow(x,y,width,height)
	local oldPixels = ECSAPI.rememberOldPixels(x,y,x+width+1,y+height)

	ECSAPI.square(x,y,width,height,ECSAPI.windowColors.background)

	ECSAPI.windowShadow(x,y,width,height)

	return oldPixels
end

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

function ECSAPI.error(...)

	local arg = {...}
	local text = arg[1] or "С твоим компом опять хуйня"
	local buttonText = arg[2] or "ОК"
	local sText = unicode.len(text)
	local xSize, ySize = gpu.getResolution()
	local width = math.ceil(xSize * 3 / 5)
	if (width - 11) > (sText) then width = 11 + sText end
	local textLimit = width - 11

	--Восклицательный знак
	local image = {
		{{0xff0000,0xffffff,"#"},{0xff0000,0xffffff,"#"},{0xff0000,0xffffff," "},{0xff0000,0xffffff,"#"},{0xff0000,0xffffff,"#"}},
		{{0xff0000,0xffffff,"#"},{0xff0000,0xffffff," "},{0xff0000,0xffffff,"!"},{0xff0000,0xffffff," "},{0xff0000,0xffffff,"#"}},
		{{0xff0000,0xffffff," "},{0xff0000,0xffffff," "},{0xff0000,0xffffff," "},{0xff0000,0xffffff," "},{0xff0000,0xffffff," "}}
	}

	--Парсинг строки ошибки
	local parsedErr = {}
	local countOfStrings = math.ceil(sText / textLimit)
	for i=1, countOfStrings do
		parsedErr[i] = unicode.sub(text, i * textLimit - textLimit + 1, i * textLimit)
	end

	--Расчет высоты
	local height = 6
	if #parsedErr > 1 then height = height + #parsedErr - 1 end

	--Расчет позиции окна
	local xStart,yStart = ECSAPI.correctStartCoords("auto","auto",width,height)
	local xEnd,yEnd = xStart + width - 1, yStart + height - 1

	--Рисуем окно
	local oldPixels = ECSAPI.emptyWindow(xStart,yStart,width,height," ")

	--Рисуем воскл знак
	ECSAPI.drawCustomImage(xStart + 2,yStart + 2,image)

	--Рисуем текст ошибки
	gpu.setBackground(ECSAPI.windowColors.background)
	gpu.setForeground(ECSAPI.windowColors.usualText)
	local xPos, yPos = xStart + 9, yStart + 2
	for i=1, #parsedErr do
		gpu.set(xPos, yPos, parsedErr[i])
		yPos = yPos + 1
	end

	--Рисуем кнопу
	local xButton = xEnd - unicode.len(buttonText) - 7
	local button = {ECSAPI.drawAdaptiveButton(xButton,yEnd - 1,3,0,buttonText,ECSAPI.colors.lightBlue,0xffffff)}

	--Ждем
	while true do
		local e = {event.pull()}
		if e[1] == "touch" then
			if ECSAPI.clickedAtArea(e[3],e[4],button[1],button[2],button[3],button[4]) then
				ECSAPI.drawAdaptiveButton(button[1],button[2],3,0,buttonText,ECSAPI.colors.blue,0xffffff)
				os.sleep(0.4)
				break
			end
		elseif e[1] == "key_down" and e[4] == 28 then
			ECSAPI.drawAdaptiveButton(button[1],button[2],3,0,buttonText,ECSAPI.colors.blue,0xffffff)
			os.sleep(0.4)
			break	
		end
	end

	--Профит
	ECSAPI.drawOldPixels(oldPixels)

end


function ECSAPI.prepareToExit(color1, color2)
	ECSAPI.clearScreen(color1 or 0x333333)
	gpu.setForeground(color2 or 0xffffff)
	gpu.set(1, 1, "")
end

--А ЭТО КАРОЧ ИЗ ЮНИКОДА В СИМВОЛ - ВРОДЕ РАБОТАЕТ, НО ВСЯКОЕ БЫВАЕТ
function ECSAPI.convertCodeToSymbol(code)
	local symbol
	if code ~= 0 and code ~= 13 and code ~= 8 and code ~= 9 and code ~= 200 and code ~= 208 and code ~= 203 and code ~= 205 and not keyboard.isControlDown() then
		symbol = unicode.char(code)
		if keyboard.isShiftPressed then symbol = unicode.upper(symbol) end
	end
	return symbol
end

function ECSAPI.progressBar(x, y, width, height, background, foreground, percent)
	local activeWidth = math.ceil(width * percent / 100)
	ECSAPI.square(x, y, width, height, background)
	ECSAPI.square(x, y, activeWidth, height, foreground)
end

--ВВОД ТЕКСТА ПО ЛИМИТУ ВО ВСЯКИЕ ПОЛЯ - УДОБНАЯ ШТУКА КАРОЧ
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
		end
	end
end

function ECSAPI.selector(x, y, limit, cheBiloVvedeno, varianti, background, foreground, justDrawNotEvent)
	
	local selectionHeight = #varianti
	local oldPixels


	local obj = {}
	local function newObj(class, name, ...)
		obj[class] = obj[class] or {}
		obj[class][name] = {...}
	end

	local function drawPimpo4ka(color)
		ECSAPI.colorTextWithBack(x + limit - 1, y, color, 0xffffff - color, "▼")
	end

	local function drawText(color)
		gpu.setForeground(color)
		gpu.set(x, y, ECSAPI.stringLimit("start", cheBiloVvedeno, limit - 1))
	end

	local function drawSelection()
		local yPos = y + 1
		oldPixels = ECSAPI.rememberOldPixels(x, yPos, x + limit + 1, yPos + selectionHeight + 1)
		ECSAPI.windowShadow(x, yPos, limit, selectionHeight)
		ECSAPI.square(x, yPos, limit, selectionHeight, background)

		gpu.setForeground(foreground)
		for i = 1, #varianti do
			gpu.set(x, y + i, varianti[i])
			newObj("selector", varianti[i], x, y + i, x + limit - 1)
		end
	end

	ECSAPI.square(x, y, limit, 1, background)
	drawText(foreground)
	drawPimpo4ka(background - 0x555555)

	if justDrawNotEvent then return cheBiloVvedeno end

	drawPimpo4ka(0xffffff)
	drawSelection()

	while true do
		local e = {event.pull()}
		if e[1] == "touch" then
			for key, val in pairs(obj["selector"]) do
				if obj["selector"] and ECSAPI.clickedAtArea(e[3], e[4], obj["selector"][key][1], obj["selector"][key][2], obj["selector"][key][3], obj["selector"][key][2]) then
					ECSAPI.square(x, obj["selector"][key][2], limit, 1, ECSAPI.colors.blue)
					gpu.setForeground(0xffffff)
					gpu.set(x, obj["selector"][key][2], key)
					os.sleep(0.3)
					ECSAPI.drawOldPixels(oldPixels)
					cheBiloVvedeno = key
					drawPimpo4ka(background - 0x555555)
					ECSAPI.square(x, y, limit - 1, 1, background)
					drawText(foreground)

					return cheBiloVvedeno
				end
			end
		end
	end
end

function ECSAPI.input(x, y, limit, title, ...)

	local obj = {}
	local function newObj(class, name, ...)
		obj[class] = obj[class] or {}
		obj[class][name] = {...}
	end

	local activeData = 1
	local data = {...}

	local sizeOfTheLongestElement = 1
	for i = 1, #data do
		sizeOfTheLongestElement = math.max(sizeOfTheLongestElement, unicode.len(data[i][2]))
	end

	local width = 2 + sizeOfTheLongestElement + 2 + limit + 2
	local height = 2 + #data * 2 + 2

	--ПО ЦЕНТРУ ЭКРАНА, А ТО МАЛО ЛИ ЧЕ
	x, y = ECSAPI.correctStartCoords(x, y, width, height)

	local oldPixels = ECSAPI.rememberOldPixels(x, y, x + width + 1, y + height)

	ECSAPI.emptyWindow(x, y, width, height, title)

	local xPos, yPos

	local function drawElement(i, justDrawNotEvent)
		xPos = x + 2
		yPos = y + i * 2
		local color = 0x666666
		if i == activeData then color = 0x000000 end

		gpu.setBackground(ECSAPI.windowColors.background)
		ECSAPI.colorText(xPos, yPos, color, data[i][2])

		xPos = (x + width - 2 - limit)

		local data1

		if data[i][1] == "select" or data[i][1] == "selector" or data[i][1] == "selecttion" then
			data1 = ECSAPI.selector(xPos, yPos, limit, data[i][3] or "", data[i][4] or {"What?", "Bad API use :("}, 0xffffff, color, justDrawNotEvent)
		else
			data1 = ECSAPI.inputText(xPos, yPos, limit, data[i][3] or "", 0xffffff, color, justDrawNotEvent)
		end

		newObj("elements", i, xPos, yPos, xPos + limit - 1)

		return data1
	end

	local coodrs = { ECSAPI.drawAdaptiveButton(x + width - 10, y + height - 2, 3, 0, "OK", ECSAPI.colors.lightBlue, 0xffffff) }
	newObj("OK", "OK", coodrs[1], coodrs[2], coodrs[3])

	local function pressButton(press, press2)
		if press then
			ECSAPI.drawAdaptiveButton(obj["OK"]["OK"][1], obj["OK"]["OK"][2], 3, 0, "OK", press, press2)
		else
			ECSAPI.drawAdaptiveButton(obj["OK"]["OK"][1], obj["OK"]["OK"][2], 3, 0, "OK", ECSAPI.colors.lightBlue, 0xffffff)
		end
	end

	local function drawAll()
		gpu.setBackground(ECSAPI.windowColors.background)
		for i = 1, #data do
			drawElement(i, true)
		end

		if activeData > #data then
			pressButton(ECSAPI.colors.blue, 0xffffff)
		else
			pressButton(false)
		end
	end

	local function getMassiv()
		local massiv = {}
		for i = 1, #data do
			table.insert(massiv, data[i][3])
		end
		return massiv
	end

	local function drawKaro4()
		if activeData ~= -1 then data[activeData][3] = drawElement(activeData, false) end
	end

	------------------------------------------------------------------------------------------------

	drawAll()
	drawKaro4()
	activeData = activeData + 1
	drawAll()

	while true do

		local e = {event.pull()}
		if e[1] == "key_down" then

			if e[4] == 28 and activeData > #data then pressButton(false); os.sleep(0.2); pressButton(ECSAPI.colors.blue, 0xffffff); break end

			if e[4] == 200 and activeData > 1 then activeData = activeData - 1; drawAll() end
			if e[4] == 208 and activeData ~= -1 and activeData <= #data then activeData = activeData + 1; drawAll() end

			if e[4] == 28 then
				drawKaro4()
				if activeData <= #data and activeData ~= -1 then activeData = activeData + 1 end
				drawAll()
			end


			

		elseif e[1] == "touch" then
			for key, val in pairs(obj["elements"]) do
				if ECSAPI.clickedAtArea(e[3], e[4], obj["elements"][key][1], obj["elements"][key][2], obj["elements"][key][3], obj["elements"][key][2]) then
					
					if key ~= activeData then activeData = key else drawKaro4(); if activeData <= #data then activeData = activeData + 1 end end

					drawAll()
					--activeData = key

					--activeData = -1

					--if activeData <= #data then activeData = activeData + 1 end
					
					break
				end
			end

			if ECSAPI.clickedAtArea(e[3], e[4], obj["OK"]["OK"][1], obj["OK"]["OK"][2], obj["OK"]["OK"][3], obj["OK"]["OK"][2]) then
				
				if activeData > #data then
					pressButton(false); os.sleep(0.2); pressButton(ECSAPI.colors.blue, 0xffffff)
				else
					pressButton(ECSAPI.colors.blue, 0xffffff)
					os.sleep(0.3)
				end

				break
			end
		end
	end

	ECSAPI.drawOldPixels(oldPixels)

	return getMassiv()
end

function ECSAPI.getHDDs()
	local candidates = {}
	for address in component.list("filesystem") do
	  local dev = component.proxy(address)
	  if not dev.isReadOnly() and dev.address ~= computer.tmpAddress() and fs.get(os.getenv("_")).address then
	    table.insert(candidates, dev)
	  end
	end
	return candidates
end

function ECSAPI.parseErrorMessage(error, translate)

	local parsedError = {}

	-- --ВСТАВКА ВСЕГО ГОВНА ДО ПЕРВОГО ЭНТЕРА
	-- local starting, ending = string.find(error, "\n", 1)
	-- table.insert(parsedError, unicode.sub(error, 1, ending or #error))

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

function ECSAPI.select(x, y, title, textLines, buttons)

	--Ну обжекты, хули
	local obj = {}
	local function newObj(class, name, ...)
		obj[class] = obj[class] or {}
		obj[class][name] = {...}
	end

	--Вычисление ширны на основе текста
	local sizeOfTheLongestElement = 0
	for i = 1, #textLines do
		sizeOfTheLongestElement = math.max(sizeOfTheLongestElement, unicode.len(textLines[i][1]))
	end

	local width = sizeOfTheLongestElement + 4

	--Вычисление ширины на основе размера кнопок
	local buttonOffset = 2
	local spaceBetweenButtons = 2

	local sizeOfButtons = 0
	for i = 1, #buttons do
		sizeOfButtons = sizeOfButtons + unicode.len(buttons[i][1]) + buttonOffset * 2 + spaceBetweenButtons
	end

	--Финальное задание ширины и высоты
	width = math.max(width, sizeOfButtons + 2)
	local height = #textLines + 5

	--Рисуем окно
	x, y = ECSAPI.correctStartCoords(x, y, width, height)
	local oldPixels = ECSAPI.emptyWindow(x, y, width, height, title)

	--Рисуем текст
	local xPos, yPos = x + 2, y + 2
	gpu.setBackground(ECSAPI.windowColors.background)
	for i = 1, #textLines do
		ECSAPI.colorText(xPos, yPos, textLines[i][2] or ECSAPI.windowColors.usualText, textLines[i][1] or "Ну ты че, текст-то введи!")
		yPos = yPos + 1
	end

	--Рисуем кнопочки
	xPos, yPos = x + width - sizeOfButtons, y + height - 2
	for i = 1, #buttons do
		newObj("Buttons", buttons[i][1], ECSAPI.drawAdaptiveButton(xPos, yPos, buttonOffset, 0, buttons[i][1], buttons[i][2] or ECSAPI.colors.lightBlue, buttons[i][3] or 0xffffff))
		xPos = xPos + buttonOffset * 2 + spaceBetweenButtons + unicode.len(buttons[i][1])
	end

	--Жмякаем на кнопочки
	local action

	while true do
		if action then break end
		local e = {event.pull()}
		if e[1] == "touch" then
			for key, val in pairs(obj["Buttons"]) do
				if ECSAPI.clickedAtArea(e[3], e[4], obj["Buttons"][key][1], obj["Buttons"][key][2], obj["Buttons"][key][3], obj["Buttons"][key][4]) then
					ECSAPI.drawAdaptiveButton(obj["Buttons"][key][1], obj["Buttons"][key][2], buttonOffset, 0, key, ECSAPI.colors.blue, 0xffffff)
					os.sleep(0.3)
					action = key
					break
				end
			end
		elseif e[1] == "key_down" then
			if e[4] == 28 then
				action = buttons[#buttons][1]
				ECSAPI.drawAdaptiveButton(obj["Buttons"][action][1], obj["Buttons"][action][2], buttonOffset, 0, action, ECSAPI.colors.blue, 0xffffff)
				os.sleep(0.3)
				break
			end
		end
	end

	ECSAPI.drawOldPixels(oldPixels)

	return action
end

function ECSAPI.askForReplaceFile(path)
	if fs.exists(path) then
		action = ECSAPI.select("auto", "auto", " ", {{"Файл \"".. fs.name(path) .. "\" уже имеется в этом месте."}, {"Заменить его перемещаемым объектом?"}}, {{"Оставить оба", 0xffffff, 0x000000}, {"Отмена", 0xffffff, 0x000000}, {"Заменить"}})
		if action == "Оставить оба" then
			return "keepBoth"
		elseif action == "Отмена" then
			return "cancel"
		else
			return "replace"
		end
	end
end

--Переименование файлов для операционки
function ECSAPI.rename(mainPath)
	local name = fs.name(mainPath)
	path = fs.path(mainPath)

	--Рисуем окошко ввода нового имени файла
	local inputs = ECSAPI.universalWindow("auto", "auto", 30, ECSAPI.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x262626, "Переименовать"}, {"EmptyLine"}, {"Input", 0x262626, 0x880000, name}, {"EmptyLine"}, {"Button", 0xbbbbbb, 0xffffff, "Ok!"})
	
	--Если ввели в окошко хуйню какую-то
	if inputs[1] == "" or inputs[1] == " " or inputs[1] == nil then
		ECSAPI.error("Неверное имя файла.")
	else
		--Получаем новый путь к новому файлу
		local newPath = path..inputs[1]
		--Если файл с новым путем уже существует
		if fs.exists(newPath) then
			ECSAPI.error("Файл \"".. name .. "\" уже имеется в этом месте.")
			return
		else
			fs.rename(mainPath, newPath)
		end
	end
end

--Создать новую папку
function ECSAPI.newFolder(path)
	--Рисуем окошко ввода нового имени файла
	local inputs = ECSAPI.universalWindow("auto", "auto", 30, ECSAPI.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x262626, "Новая папка"}, {"EmptyLine"}, {"Input", 0x262626, 0x880000, name}, {"EmptyLine"}, {"Button", 0xbbbbbb, 0xffffff, "Ok!"})

	--Если ввели в окошко хуйню какую-то
	if inputs[1] == "" or inputs[1] == " " or inputs[1] == nil then
		ECSAPI.error("Неверное имя файла.")
	else
		--Если файл с новым путем уже существует
		if fs.exists(path.."/"..inputs[1]) then
			ECSAPI.error("Файл \"".. inputs[1] .. "\" уже имеется в этом месте.")
			return
		else
			fs.makeDirectory(path.."/"..inputs[1])
		end
	end
end

--Создать новый файл
function ECSAPI.newFile(path)
	--Рисуем окошко ввода нового имени файла
	local inputs = ECSAPI.universalWindow("auto", "auto", 30, ECSAPI.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x262626, "Новый файл"}, {"EmptyLine"}, {"Input", 0x262626, 0x880000, name}, {"EmptyLine"}, {"Button", 0xbbbbbb, 0xffffff, "Ok!"})

	--Если ввели в окошко хуйню какую-то
	if inputs[1] == "" or inputs[1] == " " or inputs[1] == nil then
		ECSAPI.error("Неверное имя файла.")
	else
		--Если файл с новым путем уже существует
		if fs.exists(path.."/"..inputs[1]) then
			ECSAPI.error("Файл \"".. inputs[1] .. "\" уже имеется в этом месте.")
			return
		else
			ECSAPI.prepareToExit()
			ECSAPI.editFile(path.."/"..inputs[1])
		end
	end
end

--Простое информационное окошечко
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

--Скроллбар вертикальный
function ECSAPI.srollBar(x, y, width, height, countOfAllElements, currentElement, backColor, frontColor)
	local sizeOfScrollBar = math.ceil(1 / countOfAllElements * height)
	local displayBarFrom = math.floor(y + height * ((currentElement - 1) / countOfAllElements))

	ECSAPI.square(x, y, width, height, backColor)
	ECSAPI.square(x, displayBarFrom, width, sizeOfScrollBar, frontColor)

	sizeOfScrollBar, displayBarFrom = nil, nil
end

--Поле с текстом. Сюда пихать массив вида {"строка1", "строка2", "строка3", ...}
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

function ECSAPI.beautifulInput(x, y, width, title, buttonText, back, fore, otherColor, autoRedraw, ...)

	if not width or width < 30 then width = 30 end
	data = {...}
	local sData = #data
	local height = 3 + sData * 3 + 1

	x, y = ECSAPI.correctStartCoords(x, y, width, height)
	local xCenter = math.floor(x + width / 2 - 1)

	local oldPixels = ECSAPI.rememberOldPixels(x, y, x + width - 1, y + height + 2)
	
	--Рисуем фон
	ECSAPI.square(x, y, width, height, back)
	--ECSAPI.windowShadow(x, y, width, height)

	local xText = x + 3
	local inputLimit = width - 6

	--Авторизация
	ECSAPI.drawButton(x, y, width, 3, title, back, fore)

	local fields

	local function drawData()
		local i = y + 4

		fields = {}

		for j = 1, sData do
			ECSAPI.border(x + 1, i - 1, width - 2, 3, back, fore)

			if data[j][3] == "" or not data[j][3] or data[j][3] == " " then
				ECSAPI.colorTextWithBack(xText, i, fore, back, data[j][1])
			else
				if data[j][2] then
					ECSAPI.inputText(xText, i, inputLimit, data[j][3], back, fore, true, true)
				else
					ECSAPI.inputText(xText, i, inputLimit, data[j][3], back, fore, true)
				end
			end

			table.insert(fields, { x + 1, i - 1, x + inputLimit - 1, i + 1 })

			i = i + 3
		end
	end

	local function getData()
		local massiv = {}
		for i = 1, sData do
			table.insert(massiv, data[i][3])
		end
		return massiv
	end

	drawData()

	--Нижняя кнопа
	local button = { ECSAPI.drawButton(x, y + sData * 3 + 4, width, 3, buttonText, otherColor, fore) }

	while true do
		local e = {event.pull()}
		if e[1] == "touch" then
			if ECSAPI.clickedAtArea(e[3], e[4], button[1], button[2], button[3], button[4]) then
				ECSAPI.drawButton(button[1], button[2], width, 3, buttonText, ECSAPI.colors.blue, 0xffffff)
				os.sleep(0.3)
				if autoRedraw then ECSAPI.drawOldPixels(oldPixels) end
				return getData()
			end

			for key, val in pairs(fields) do
				if ECSAPI.clickedAtArea(e[3], e[4], fields[key][1], fields[key][2], fields[key][3], fields[key][4]) then
					ECSAPI.border(fields[key][1], fields[key][2], width - 2, 3, back, otherColor)
					data[key][3] = ECSAPI.inputText(xText, fields[key][2] + 1, inputLimit, "", back, fore, false, data[key][2])
					--ECSAPI.border(fields[key][1], fields[key][2], width - 2, 3, back, fore)
					drawData()
					break
				end
			end
		elseif e[1] == "key_down" then
			if e[4] == 28 then
				ECSAPI.drawButton(button[1], button[2], width, 3, buttonText, ECSAPI.colors.blue, 0xffffff)
				os.sleep(0.3)
				if autoRedraw then ECSAPI.drawOldPixels(oldPixels) end
				return getData()
			end
		end
	end

end

function ECSAPI.beautifulSelect(x, y, width, title, buttonText, back, fore, otherColor, autoRedraw, ...)
	if not width or width < 30 then width = 30 end
	data = {...}
	local sData = #data
	local height = 3 + sData * 3 + 1

	x, y = ECSAPI.correctStartCoords(x, y, width, height)
	local xCenter = math.floor(x + width / 2 - 1)

	local oldPixels = ECSAPI.rememberOldPixels(x, y, x + width - 1, y + height + 2)

	--Рисуем фон
	ECSAPI.square(x, y, width, height, back)

	local xText = x + 3
	local inputLimit = width - 9

	--Первая кнопа
	ECSAPI.drawButton(x, y, width, 3, title, back, fore)

	--Нижняя кнопа
	local button = { ECSAPI.drawButton(x, y + sData * 3 + 4, width, 3, buttonText, otherColor, fore) }

	local fields

	local selectedData = 1
	local symbol = "✔"

	--Рисуем данные
	local function drawData()
		local i = y + 4

		fields = {}

		for j = 1, sData do

			--Квадратик для галочки
			ECSAPI.border(x + 1, i - 1, 5, 3, back, fore)

			--Галочку рисуем или снимаем
			local text = "  "
			if j == selectedData then text = symbol end
			ECSAPI.colorText(x + 3, i, otherColor, text)

			ECSAPI.colorText(x + 7, i, fore, ECSAPI.stringLimit("end", data[j], inputLimit))

			table.insert(fields, { x + 1, i - 1, x + inputLimit - 1, i + 1 })

			i = i + 3
		end
	end

	drawData()

	while true do
		local e = {event.pull()}
		if e[1] == "touch" then
			if ECSAPI.clickedAtArea(e[3], e[4], button[1], button[2], button[3], button[4]) then
				ECSAPI.drawButton(button[1], button[2], width, 3, buttonText, ECSAPI.colors.blue, 0xffffff)
				os.sleep(0.3)
				if autoRedraw then ECSAPI.drawOldPixels(oldPixels) end
				return data[selectedData]
			end

			for key, val in pairs(fields) do
				if ECSAPI.clickedAtArea(e[3], e[4], fields[key][1], fields[key][2], fields[key][3], fields[key][4]) then
					selectedData = key
					drawData()
					break
				end
			end
		elseif e[1] == "key_down" then
			if e[4] == 28 then
				ECSAPI.drawButton(button[1], button[2], width, 3, buttonText, ECSAPI.colors.blue, 0xffffff)
				os.sleep(0.3)
				if autoRedraw then ECSAPI.drawOldPixels(oldPixels) end
				return data[selectedData]
			end
		end
	end
end

--Получение верного имени языка. Просто для безопасности.
function ECSAPI.getCorrectLangName(pathToLangs)
	local language = _OSLANGUAGE .. ".lang"
	if not fs.exists(pathToLangs .. "/" .. language) then
		language = "English.lang"
	end
	return language
end

--Чтение языкового файла
function ECSAPI.readCorrectLangFile(pathToLangs)
	local lang
	
	local language = ECSAPI.getCorrectLangName(pathToLangs)

	lang = config.readAll(pathToLangs .. "/" .. language)

	return lang
end








-------------------------ВСЕ ДЛЯ ОСКИ-------------------------------------------------------------------------------

--То, что не нужно отрисовывать
local systemFiles = {
	"bin/",
	"lib/",
	"OS.lua",
	"autorun.lua",
	"init.lua",
	"tmp/",
	"usr/",
	"mnt/",
	"etc/",
	"boot/",
	--"System/",
}

-- Потная штучка, надо будет перекодить - а то странно выглядит, да и условия идиотские
function ECSAPI.reorganizeFilesAndFolders(massivSudaPihay, showHiddenFiles, showSystemFiles)

	local massiv = {}

	for i = 1, #massivSudaPihay do
		if ECSAPI.isFileHidden(massivSudaPihay[i]) and showHiddenFiles then
			table.insert(massiv, massivSudaPihay[i])
		end
	end

	for i = 1, #massivSudaPihay do
		local cyka = massivSudaPihay[i]
		if fs.isDirectory(cyka) and not ECSAPI.isFileHidden(cyka) and ECSAPI.getFileFormat(cyka) ~= ".app" then
			table.insert(massiv, cyka)
		end
		cyka = nil
	end

	for i = 1, #massivSudaPihay do
		local cyka = massivSudaPihay[i]
		if (not fs.isDirectory(cyka) and not ECSAPI.isFileHidden(cyka)) or (fs.isDirectory(cyka) and not ECSAPI.isFileHidden(cyka) and ECSAPI.getFileFormat(cyka) == ".app") then
			table.insert(massiv, cyka)
		end
		cyka = nil
	end


	if not showSystemFiles then
		if workPath == "" or workPath == "/" then
			--ECSAPI.error("Сработало!")
			local i = 1
			while i <= #massiv do
				for j = 1, #systemFiles do
					--ECSAPI.error("massiv[i] = " .. massiv[i] .. ", systemFiles[j] = "..systemFiles[j])
					if massiv[i] == systemFiles[j] then
						--ECSAPI.error("Удалено! massiv[i] = " .. massiv[i] .. ", systemFiles[j] = "..systemFiles[j])
						table.remove(massiv, i)
						i = i - 1
						break
					end

				end

				i = i + 1
			end
		end
	end

	return massiv
end

--Создать ярлык для конкретной проги
function ECSAPI.createShortCut(path, pathToProgram)
	fs.remove(path)
	fs.makeDirectory(fs.path(path))
	local file = io.open(path, "w")
	file:write("return ", "\"", pathToProgram, "\"")
	file:close()
end

--Получить данные о файле из ярлыка
function ECSAPI.readShortcut(path)
	local success, filename = pcall(loadfile(path))
	if success then
		return filename
	else
		error("Ошибка чтения файла ярлыка. Вероятно, он создан криво, либо не существует в папке " .. path)
	end
end

--Редактирование файла
function ECSAPI.editFile(path)
	shell.execute("edit "..path)
end

-- Копирование папки через рекурсию, т.к. fs.copy() не поддерживает папки
-- Ну долбоеб автор мода - хули я тут сделаю? Придется так вот
-- swg2you, привет маме ;)
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
	if not ECSAPI.OSIcons then
		--Константы для иконок
		ECSAPI.OSIcons = {}
		ECSAPI.pathToIcons = "System/OS/Icons/"

		--Иконки
		ECSAPI.OSIcons.folder = image.load(ECSAPI.pathToIcons .. "Folder.png")
		ECSAPI.OSIcons.script = image.load(ECSAPI.pathToIcons .. "Script.png")
		ECSAPI.OSIcons.text = image.load(ECSAPI.pathToIcons .. "Text.png")
		ECSAPI.OSIcons.config = image.load(ECSAPI.pathToIcons .. "Config.png")
		ECSAPI.OSIcons.lua = image.load(ECSAPI.pathToIcons .. "Lua.png")
		ECSAPI.OSIcons.image = image.load(ECSAPI.pathToIcons .. "Image.png")
		ECSAPI.OSIcons.imageJPG = image.load(ECSAPI.pathToIcons .. "ImageJPG.png")
		ECSAPI.OSIcons.pastebin = image.load(ECSAPI.pathToIcons .. "Pastebin.png")
		ECSAPI.OSIcons.fileNotExists = image.load(ECSAPI.pathToIcons .. "FileNotExists.png")
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
			icon = path .. "/Resources/Icon.png"
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
			ECSAPI.drawOSIcon(x, y, shortcutLink, showFileFormat)
			--Стрелочка
			ECSAPI.colorTextWithBack(x + ECSAPI.OSIconsWidth - 4, y + ECSAPI.OSIconsHeight - 3, 0x000000, 0xffffff, "⤶")
			return 0
		elseif fileFormat == ".cfg" or fileFormat == ".config" then
			icon = "config"
		elseif fileFormat == ".txt" or fileFormat == ".rtf" then
			icon = "text"
		elseif fileFormat == ".lua" then
		 	icon = "lua"
		elseif fileFormat == ".png" then
		 	icon = "image"
		elseif fileFormat == ".jpg" then
		 	icon = "imageJPG"
		elseif fileFormat == ".paste" then
			icon = "pastebin"
		elseif not fs.exists(path) then
			icon = "fileNotExists"
		else
			icon = "script"
		end
	end

	--Рисуем иконку
	image.draw(x + 2, y, ECSAPI.OSIcons[icon])

	--Делаем текст для иконки
	local text = fs.name(path)
	if not showFileFormat then
		if fileFormat then
			text = unicode.sub(text, 1, -(unicode.len(fileFormat) + 1))
		end
	end
	text = ECSAPI.stringLimit("end", text, ECSAPI.OSIconsWidth)
	--Рассчитываем позицию текста
	local textPos = x + math.floor(ECSAPI.OSIconsWidth / 2 - unicode.len(text) / 2)
	--Рисуем текст под иконкой
	ECSAPI.adaptiveText(textPos, y + ECSAPI.OSIconsHeight - 1, text, nameColor or 0xffffff)

end

--ЗАПУСТИТЬ ПРОГУ
function ECSAPI.launchIcon(path, arguments)
	--Запоминаем, какое разрешение было
	local oldWidth, oldHeight = gpu.getResolution()
	--Создаем нормальные аргументы для Шелла
	if arguments then arguments = " " .. arguments else arguments = "" end
	--Получаем файл формат заранее
	local fileFormat = ECSAPI.getFileFormat(path)
	--Если это приложение
	if fileFormat == ".app" then
		ECSAPI.prepareToExit()
		local cyka = path .. "/" .. ECSAPI.hideFileFormat(fs.name(path)) .. ".lua"
		local success, reason = shell.execute(cyka)
		ECSAPI.prepareToExit()
		if not success then ECSAPI.displayCompileMessage(1, reason, true) end
	--Если это обычный луа файл - т.е. скрипт
	elseif fileFormat == ".lua" or fileFormat == nil then
		ECSAPI.prepareToExit()
		local success, reason = shell.execute(path .. arguments)
		ECSAPI.prepareToExit()
		if success then
			print("Program sucessfully executed. Press any key to continue.")
		else
			ECSAPI.displayCompileMessage(1, reason, true)
		end
	--Если это фоточка
	elseif fileFormat == ".png" then
		shell.execute("Photoshop.app/Photoshop.lua open "..path)
	--Если это фоточка
	elseif fileFormat == ".jpg" then
		shell.execute("Photoshop.app/Photoshop.lua open "..path)
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
	end
	--Ставим старое разрешение
	gpu.setResolution(oldWidth, oldHeight)
end

--ECSAPI.drawOSIcon(2, 2, "Pastebin1.app", true)




----------------------------------------------------------------------------------------------------------------








--Описание ниже, ебана
function ECSAPI.universalWindow(x, y, width, background, closeWindowAfter, ...)
	local objects = {...}
	local countOfObjects = #objects

	local pressedButton

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
	}

	--Считаем высоту этой хуйни
	local height = 0
	for i = 1, countOfObjects do
		local objectType = string.lower(objects[i][1])
		if objectType == "select" then
			height = height + (objectsHeights[objectType] * (#objects[i] - 3))
		elseif objectType == "textfield" then
			height = height + objects[i][2]
		else
			height = height + objectsHeights[objectType]
		end
	end

	--Нужные стартовые прелесссти
	x, y = ECSAPI.correctStartCoords(x, y, width, height)
	local oldPixels = ECSAPI.rememberOldPixels(x, y, x + width - 1, y + height - 1)

	--Считаем все координаты объектов
	objects[1].y = y
	if countOfObjects > 1 then
		for i = 2, countOfObjects do
			local objectType = string.lower(objects[i - 1][1])
			if objectType == "select" then
				objects[i].y = objects[i - 1].y + (objectsHeights[objectType] * (#objects[i - 1] - 3))
			elseif objectType == "textfield" then
				objects[i].y = objects[i - 1].y + objects[i - 1][2]
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
		
		if objectType == "button" then
			local back, fore, text = objects[number][2], objects[number][3], objects[number][4]
			if active then
				newObj("Buttons", number, ECSAPI.drawButton(x, objects[number].y, width, objectsHeights.button, text, fore, back))
			else
				newObj("Buttons", number, ECSAPI.drawButton(x, objects[number].y, width, objectsHeights.button, text, back, fore))
			end
		elseif objectType == "centertext" then
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
			end

			newObj("Inputs", number, x + 1, objects[number].y, x + width - 2, objects[number].y + 2)

		elseif objectType == "slider" then
			local widthOfSlider = width - 2
			local xOfSlider = x + 1
			local yOfSlider = objects[number].y + 1
			local countOfSliderThings = objects[number][5] - objects[number][4]
			local showSliderValue = objects[number][7]

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
				local text = showSliderValue .. tostring(objects[number][6])
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
				local xPos, yPos = x + 2, objects[number].y + 3
				local spisokWidth = width - 4
				local countOfElements = #objects[number] - 3
				local spisokHeight = countOfElements
				local oldPixels = ECSAPI.rememberOldPixels( xPos, yPos, xPos + spisokWidth - 1, yPos + spisokHeight - 1)

				local coords = {}

				bordak(arrowColor)

				--Белый фоник рисуем-с
				ECSAPI.square( xPos, yPos, spisokWidth, spisokHeight, 0xffffff )
				xPos = xPos + 1
				for i = 1, countOfElements do
					ECSAPI.colorText(xPos, yPos, 0x000000, ECSAPI.stringLimit("start", objects[number][i + 3], spisokWidth - 2))
					coords[i] = {xPos - 1, yPos, xPos + spisokWidth - 1, yPos}
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
								ECSAPI.square(coords[i][1], coords[i][2], spisokWidth, 1, ECSAPI.colors.blue)
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
			objects[number].displayFrom = objects[number].displayFrom or 1
			ECSAPI.textField(x + 1, objects[number].y, width - 2, objects[number][2], objects[number][7], objects[number].displayFrom, objects[number][3], objects[number][4], objects[number][5], objects[number][6])
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
				table.insert(massiv, objects[i].selectedData)
			elseif type == "selector" then
				table.insert(massiv, objects[i].selectedElement)
			elseif type == "slider" then
				table.insert(massiv, objects[i][6])
			else
				table.insert(massiv, nil)
			end
		end

		return massiv
	end

	--Рисуем окно
	ECSAPI.square(x, y, width, height, background)
	displayAllObjects()

	while true do
		local e = {event.pull()}
		if e[1] == "touch" or event == "drag" then

			--ECSAPI.error("x1 = "..obj["Buttons"][3][1]..", y1 = "..obj["Buttons"][3][2]..", e3 = "..e[3]..", e4 = "..e[4])

			--Анализируем клик на кнопки
			if obj["Buttons"] then
				for key in pairs(obj["Buttons"]) do
					if ECSAPI.clickedAtArea(e[3], e[4], obj["Buttons"][key][1], obj["Buttons"][key][2], obj["Buttons"][key][3], obj["Buttons"][key][4]) then
						displayObject(key, true)
						os.sleep(0.3)
						pressedButton = objects[key][4]
						if closeWindowAfter then ECSAPI.drawOldPixels(oldPixels) end
						return getReturn()
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
		end
	end
end

--local strings = {"Hello world! This is a test string and I'm so happy to show it!", "Awesome! It works!", "Cool!"}

-- ECSAPI.prepareToExit()
-- --ECSAPI.universalWindow("auto", "auto", 30, ECSAPI.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x262626, "Хелло пидар!"}, {"EmptyLine"}, {"Input", 0x262626, 0x000000, "Суда вводи"}, {"Selector", 0x262626, 0x880000, "PNG", "JPG", "PSD"}, {"Slider", 0x262626, 0x880000, 0, 100, 50}, {"Select", 0x262626, 0x880000, "Выбор1", "Выбор2"}, {"EmptyLine"}, {"Button", 0xbbbbbb, 0xffffff, "Ok!"})
-- local data = ECSAPI.universalWindow("auto", "auto", 30, ECSAPI.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x262626, "Хелло пидар!"}, {"EmptyLine"}, {"Input", 0x262626, 0x880000, "Суда вводи"}, {"Selector", 0x262626, 0x880000, "PNG", "JPG", "PSD"}, {"Slider", 0x262626, 0x880000, 0, 100, 50, "Количество: "}, {"Select", 0x262626, 0x880000, "Выбор1", "Выбор2"}, {"EmptyLine"}, {"Button", 0xbbbbbb, 0xffffff, "Ok!"})
-- ECSAPI.prepareToExit()
-- print(table.unpack(data))


--[[
Функция universalWindow(x, y, width, background, closeWindowAfter, ...)
	Это универсальная модульная функция для максимально удобного и быстрого
	отображения необходимой вам информации. С ее помощью вводить данные
	с клавиатуры, осуществлять выбор из предложенных вариантов, рисовать
	красивые кнопки, отрисовывать обычный текст, отрисовывать текстовые
	поля с возможностью прокрутки, рисовать разделители и прочее.
	Любой объект выделяется с помощью клика мыши, после чего функция
	приступает к работе с этим объектом.

	Аргументы функции:
		x и y:
			Это числа, обозначающие стартовые координаты левого верхнего угла
			данного окна.
			Вместо цифр вы также можете написать "auto" - и программа
			автоматически разместит окно по центру экрана по выбранной
			координате. Или по обеим координатам, если вам угодно.
		
		width:
			Это ширина окна, которую вы можете задать по собственному желанию. 
			Если некторые объекты требуют расширения окна, то окно будет 
			автоматически расширено до нужной ширины. Да, вот такая вот тавтология ;)
		
		background:
			Базовый цвет окна (цвет фона, кому как понятнее).
		
		closeWindowAfter:
			Если true, то окно по завершению функции будет выгружено, а на его месте отрисуются пиксели,
			которые имелись на экране до выполнения функции. Удобно, если не хочешь париться
			с перерисовкой интерфейса.

		...:
			Многоточием тут является перечень объектов, указанных через запятую.
			Каждый объект является массивом и имеет собственный формат.
			Ниже перечислены все типы объектов:
				{"Button", Цвет кнопки, Цвет текста на кнопке, Сам текст}
				{"Selector", Цвет рамки, Цвет стрелки, Выбор 1, Выбор 2, Выбор 3 ...}
				{"Input", Цвет рамки и текста, Цвет при выделении, Стартовый текст, Маскировать символом}
				{"Select", Цвет рамки, Цвет галочки, Выбор 1, Выбор 2, Выбор 3 ...}
				{"TextField", Высота, Цвет фона, Цвет текста, Цвет скроллбара, Цвет пимпочки скроллбара, Массив со строками}
				{"CenterText", Цвет текста, Сам текст}
				{"Separator", Цвет разделителя}
				{"Slider", Цвет линии слайдера, Цвет пимпочки слайдера, Значения слайдера ОТ, Значения слайдера ДО, Текущее значение, Текст-подсказка}
				{"Switch", Цвет актива, Цвет пассива, Цвет текста, Текст, Изначальное состояние}
				{"EmptyLine"}
			Каждый из объектов рисуется по порядку сверху вниз. Каждый объект автоматически
			увеличивает высоту окна до необходимого значения.

	Что возвращает функция:
		Возвратом является массив, пронумерованный от 1 до <количества объектов>.
		К примеру, 1 индекс данного массива соответствует 1 указанному объекту.
		Каждый индекс данного массива несет в себе какие-то данные, которые вы
		внесли в объект во время работы функции.
		Например, если в 1-ый объект типа "Input" вы ввели фразу "Hello world",
		то первый индекс в возвращенном массиве будет равен "Hello world".
		Конкретнее это будет вот так: massiv[1] = "Hello world".

		Если взаимодействие с объектом невозможно - например, как с EmptyLine или
		CenterText, то в возвращенном массиве этот элемент будет равен nil.

	Готовые примеры использования функции:
]]


----------------------------------------------------------------------------------------------------


return ECSAPI




