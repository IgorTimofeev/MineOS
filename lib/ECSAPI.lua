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
	background = 0xdddddd,
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

	--ПОЛУЧЕНИЕ ИНФОРМАЦИИ О РАЗРЕШЕНИИ ВИДЕОКАРТЫ И КОЛ-ВЕ МОНИТОРОВ
	local maxWidth, maxHeight = gpu.maxResolution()
	maxWidth = maxHeight * 2
	local screensWidth, screensHeight = screen.getAspectRatio()

	--РАСЧЕТ МНИМОГО РАЗРЕШЕНИЯ
	local MNIMAYA_WIDTH = 12
	local MNIMAYA_HEIGHT = 5
	local MNIMAYA_WIDTH_CONST = 12
	local MNIMAYA_HEIGHT_CONST = 5

	if screensWidth == 2 then
		MNIMAYA_WIDTH = (MNIMAYA_WIDTH_CONST + 2) * 2
	elseif screensWidth > 2 then
		MNIMAYA_WIDTH = (MNIMAYA_WIDTH_CONST + 2) * 2 + (screensWidth - 2) * 16
	end

	if screensHeight == 2 then
		MNIMAYA_HEIGHT = (MNIMAYA_HEIGHT_CONST + 1) * 2
	elseif screensHeight > 2 then
		MNIMAYA_HEIGHT = (MNIMAYA_HEIGHT_CONST + 1) * 2 + (screensHeight - 2) * 8
	end	

	local newHeight = (maxHeight * MNIMAYA_HEIGHT) / MNIMAYA_HEIGHT_CONST
	local newWidth = (maxWidth * MNIMAYA_WIDTH) / MNIMAYA_WIDTH_CONST

	local proportion = newWidth / newHeight
	local optimizedWidth = math.ceil(100 * scale)
	local optimizedHeight = math.ceil(optimizedWidth / proportion) - screensHeight + math.floor((10 - scale * 10 ) / 2)

	local function printDebug()
		if debug then
			term.clear()
			print("Максимальное разрешение: "..maxWidth.."x"..maxHeight)
			print("Размер монитора в блоках: "..screensWidth.."x"..screensHeight)
			print("Мнимое разрешение: "..MNIMAYA_WIDTH.."x"..MNIMAYA_HEIGHT)
			print("Физическое идеальное разрешение: ".. newWidth.."x"..newHeight)
			print("Пропорция идеала: "..proportion)
			print("Оптимизированное разрешение: "..optimizedWidth.."x"..optimizedHeight)
		end
	end

	printDebug()

	--------------------------------------------------

	gpu.setResolution(optimizedWidth, optimizedHeight)

	printDebug()
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

function ECSAPI.square(x,y,width,height,color)
  gpu.setBackground(color)
  gpu.fill(x,y,width,height," ")
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
function ECSAPI.rememberOldPixels(fromX,fromY,toX,toY)
	local oldPixels = {}
	local counterX, counterY = 1, 1
	for j = fromY, toY do
		oldPixels[counterY] = {}
		counterX = 1
		for i = fromX, toX do
			oldPixels[counterY][counterX] = {i, j, {gpu.get(i,j)}}
			counterX = counterX + 1
		end
		counterY = counterY + 1
	end
	return oldPixels
end

--НАРИСОВАТЬ ЗАПОМНЕННЫЕ ПИКСЕЛИ ИЗ МАССИВА
function ECSAPI.drawOldPixels(oldPixels)
	for j=1,#oldPixels do
		for i=1,#oldPixels[j] do
			ECSAPI.colorTextWithBack(oldPixels[j][i][1],oldPixels[j][i][2],oldPixels[j][i][3][2],oldPixels[j][i][3][3],oldPixels[j][i][3][1])
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
	local xSize,ySize = gpu.getResolution()
	local offset = 26
	local width = xSize - offset
	if (width - 11) > (sText) then width = 11 + sText end
	local textLimit = width - 11

	local image = {
		{{0xff0000,0xffffff,"#"},{0xff0000,0xffffff,"#"},{0xff0000,0xffffff," "},{0xff0000,0xffffff,"#"},{0xff0000,0xffffff,"#"}},
		{{0xff0000,0xffffff,"#"},{0xff0000,0xffffff," "},{0xff0000,0xffffff,"!"},{0xff0000,0xffffff," "},{0xff0000,0xffffff,"#"}},
		{{0xff0000,0xffffff," "},{0xff0000,0xffffff," "},{0xff0000,0xffffff," "},{0xff0000,0xffffff," "},{0xff0000,0xffffff," "}}
	}

	local parsedErr = {}
	local countOfStrings = math.ceil(sText/textLimit)
	for i=1,countOfStrings do
		parsedErr[i] = unicode.sub(text, i * textLimit - textLimit + 1, i * textLimit)
	end

	local height = 2 + 3 + #parsedErr + 1
	if (#parsedErr < 2) then height = height - 1 end

	local xStart,yStart = ECSAPI.correctStartCoords("auto","auto",width,height)
	local xEnd,yEnd = xStart + width - 1, yStart + height - 1

	local oldPixels = ECSAPI.emptyWindow(xStart,yStart,width,height," ")

	ECSAPI.drawCustomImage(xStart + 2,yStart + 2,image)

	gpu.setBackground(ECSAPI.windowColors.background)
	gpu.setForeground(ECSAPI.windowColors.usualText)
	for i=1,#parsedErr do
		gpu.set(xStart+9,yStart+3+i*2-3,parsedErr[i])
	end

	local xButton = xEnd - unicode.len(buttonText) - 5
	local button = {ECSAPI.drawAdaptiveButton(xButton,yEnd - 1,2,0,buttonText,ECSAPI.colors.lightBlue,0xffffff)}

	while true do
		local e = {event.pull()}
		if e[1] == "touch" then
			if ECSAPI.clickedAtArea(e[3],e[4],button[1],button[2],button[3],button[4]) then
				ECSAPI.drawAdaptiveButton(button[1],button[2],2,0,buttonText,ECSAPI.colors.blue,0xffffff)
				os.sleep(0.4)
				break
			end
		elseif e[1] == "key_down" and e[4] == 28 then
			ECSAPI.drawAdaptiveButton(button[1],button[2],2,0,buttonText,ECSAPI.colors.blue,0xffffff)
			os.sleep(0.4)
			break	
		end
	end

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
	if code ~= 0 and code ~= 13 and code ~= 8 and code ~= 9 and not keyboard.isControlDown() then
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
function ECSAPI.inputText(x, y, limit, cheBiloVvedeno, background, foreground, justDrawNotEvent)
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

		gpu.set(x, y, ECSAPI.stringLimit("start", text, limit))
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
		end
	end

	starting, ending = nil, nil

	return parsedError
end

function ECSAPI.displayCompileMessage(y, reason, translate)

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
	for i = 1, height, 1 do
		ECSAPI.square(x, y, width, i, ECSAPI.windowColors.background)
		ECSAPI.windowShadow(x, y, width, i)
		os.sleep(0.01)
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

function ECSAPI.copy(from, to)
	local name = fs.name(from)
	local toName = to.."/"..name
	local action = ECSAPI.askForReplaceFile(toName)
	if action == nil or action == "replace" then
		fs.remove(toName)
		if fs.isDirectory(from) then
			ECSAPI.error("Копирование папок отключено во избежание перегрузки файловой системы. Мод говно, смирись.")
		else
			fs.copy(from, toName)
		end
	elseif action == "keepBoth" then
		if fs.isDirectory(from) then
			ECSAPI.error("Копирование папок отключено во избежание перегрузки файловой системы. Мод говно, смирись.")
		else
			fs.copy(from, fs.path(toName) .. "/(copy)"..fs.name(toName))
		end	
	end
end

----------------------------------------------------------------------------------------------------

--ECSAPI.copy("t", "System/OS")
--ECSAPI.clearScreen(0x262626)
--ECSAPI.input("auto", "auto", 20, "Сохранить как", {"input", "Имя", "pidor"}, {"input", "Пароль", ""}, {"input", "Заебал!", ""}, {"select", "Формат", ".PNG", {".PNG", ".PSD", ".JPG", ".GIF"}})
-- if not success then ECSAPI.displayCompileMessage(1, reason, true) end
-- ECSAPI.select("auto", "auto", " ", {{"С твоим компом опять хуйня!"}}, {{"Блядь!"}})


return ECSAPI
