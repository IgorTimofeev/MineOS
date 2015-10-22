
---------------------------------------- Библиотеки ----------------------------------------

local component = require("component")
local event = require("event")
local unicode = require("unicode")
local term = require("term")
local gpu = component.gpu

---------------------------------------- Переменные ----------------------------------------

local xSize, ySize = gpu.getResolution()

local language = "russian"

local width, height = 102, 22

local animation = false

local keyPressDelay = 0.2

local currentInput = ""

local colors = {
	keyboard = 0xd0d5d9,
	usualKey = 0xFFFFFF,
	usualKeyText = 0x262626,
	systemKey = 0x999999,
	systemKeyText = 0xFFFFFF,
	inputPanel = 0xFFFFFF,
	inputPanelText = 0x000000,
}

local keys = {
	english = {
		{ {"  ~  ", false, 1}, {"  1  ", false, 1}, {"  2  ", false, 1}, {"  3  ", false, 1}, {"  4  ", false, 1}, {"  5  ", false, 1}, {"  6  ", false, 1}, {"  7  ", false, 1}, {"  8  ", false, 1}, {"  9  ", false, 1}, {"  0  ", false, 1}, {"  -  ", false, 1}, {"  +  ", false, 1}, {"   ⌫   ", true, 1}},
		{ {"  Tab  ", true, 3}, {"  Q  ", false, 3}, {"  W  ", false, 3}, {"  E  ", false, 3}, {"  R  ", false, 3}, {"  T  ", false, 3}, {"  Y  ", false, 3}, {"  U  ", false, 3}, {"  I  ", false, 3}, {"  O  ", false, 3}, {"  P  ", false, 3}, {"  {  ", false, 3}, {"  }  ", false, 3}, {"  |  ", false, 3}},
		{ {"  Caps   ", true, 3, false}, {"  A  ", false, 3}, {"  S  ", false, 3}, {"  D  ", false, 3}, {"  F  ", false, 3}, {"  G  ", false, 3}, {"  H  ", false, 3}, {"  J  ", false, 3}, {"  K  ", false, 3}, {"  L  ", false, 3}, {"  :  ", false, 3}, {"  \"  ", false, 3}, {"   Enter  ", true, 3}},
		{ {"     ⬆     ", true, 3, false}, {"  Z  ", false, 3}, {"  X  ", false, 3}, {"  C  ", false, 3}, {"  V  ", false, 3}, {"  B  ", false, 3}, {"  N  ", false, 3}, {"  M  ", false, 3}, {"  <  ", false, 3}, {"  >  ", false, 3}, {"  ?  ", false, 3}, {"       ⬆       ", true, 3, false}},
		{ {"  .123  ", true, 3, false}, {"   Alt   ", true, 3, false},  {"                                                        ", false, 3}, {"   Alt   ", true, 3, false}, {"  .123  ", true, 3, false}},
	},
	russian = {
		{ {"  ~  ", false, 1}, {"  1  ", false, 1}, {"  2  ", false, 1}, {"  3  ", false, 1}, {"  4  ", false, 1}, {"  5  ", false, 1}, {"  6  ", false, 1}, {"  7  ", false, 1}, {"  8  ", false, 1}, {"  9  ", false, 1}, {"  0  ", false, 1}, {"  -  ", false, 1}, {"  +  ", false, 1}, {"   ⌫   ", true, 1}},
		{ {"  Tab  ", true, 3}, {"  Й  ", false, 3}, {"  Ц  ", false, 3}, {"  У  ", false, 3}, {"  К  ", false, 3}, {"  Е  ", false, 3}, {"  Н  ", false, 3}, {"  Г  ", false, 3}, {"  Ш  ", false, 3}, {"  Щ  ", false, 3}, {"  З  ", false, 3}, {"  Х  ", false, 3}, {"  Ъ  ", false, 3}, {"  |  ", false, 3}},
		{ {"  Caps   ", true, 3, false}, {"  Ф  ", false, 3}, {"  Ы  ", false, 3}, {"  В  ", false, 3}, {"  А  ", false, 3}, {"  П  ", false, 3}, {"  Р  ", false, 3}, {"  О  ", false, 3}, {"  Л  ", false, 3}, {"  Д  ", false, 3}, {"  Ж  ", false, 3}, {"  Э  ", false, 3}, {"   Enter  ", true, 3}},
		{ {"     ⬆     ", true, 3}, {"  Я  ", false, 3}, {"  Ч  ", false, 3}, {"  С  ", false, 3}, {"  М  ", false, 3}, {"  И  ", false, 3}, {"  Т  ", false, 3}, {"  Ь  ", false, 3}, {"  Б  ", false, 3}, {"  Ю  ", false, 3}, {"  ?  ", false, 3}, {"       ⬆       ", true, 3, false}},
		{ {"  .123  ", true, 3, false}, {"   Alt   ", true, 3, false},  {"                                                        ", false, 3}, {"   Alt   ", true, 3, false}, {"  .123  ", true, 3, false}},
	},
	symbols = {
		{ {"  `  ", false, 1}, {"  1  ", false, 1}, {"  2  ", false, 1}, {"  3  ", false, 1}, {"  4  ", false, 1}, {"  5  ", false, 1}, {"  6  ", false, 1}, {"  7  ", false, 1}, {"  8  ", false, 1}, {"  9  ", false, 1}, {"  0  ", false, 1}, {"  -  ", false, 1}, {"  +  ", false, 1}, {"   ⌫   ", true, 1}},
		{ {"  Tab  ", true, 3}, {"  ~  ", false, 3}, {"  !  ", false, 3}, {"  @  ", false, 3}, {"  #  ", false, 3}, {"  $  ", false, 3}, {"  %  ", false, 3}, {"  ^  ", false, 3}, {"  &  ", false, 3}, {"  *  ", false, 3}, {"  (  ", false, 3}, {"  )  ", false, 3}, {"  _  ", false, 3}, {"  =  ", false, 3}},
		{ {"  Caps   ", true, 3, false}, {"  [  ", false, 3}, {"  ]  ", false, 3}, {"  {  ", false, 3}, {"  }  ", false, 3}, {"  €  ", false, 3}, {"  ₤  ", false, 3}, {"  ¥  ", false, 3}, {"  ;  ", false, 3}, {"  :  ", false, 3}, {"  '  ", false, 3}, {"  \"  ", false, 3}, {"   Enter  ", true, 3}},
		{ {"     ⬆     ", true, 3}, {"  /  ", false, 3}, {"  \\  ", false, 3}, {"  |  ", false, 3}, {"  <  ", false, 3}, {"  >  ", false, 3}, {"  …  ", false, 3}, {"  №  ", false, 3}, {"  ,  ", false, 3}, {"  .  ", false, 3}, {"  ?  ", false, 3}, {"       ⬆       ", true, 3, false}},
		{ {"  .123  ", true, 3, false}, {"   Alt   ", true, 3, false},  {"                                                        ", false, 3}, {"   Alt   ", true, 3, false}, {"  .123  ", true, 3, false}},
	},
	current = {},
	objects = {}
}
keys.current = keys[language]

---------------------------------------- Функции ----------------------------------------

local function square(x, y, width, height, color)
	if gpu.getBackground() ~= color then gpu.setBackground(color) end
	gpu.fill(x, y, width, height, " ")
end

local function button(x, y, height, text, background, foreground)
	square(x, y, unicode.len(text), height, background)
	if gpu.getForeground() ~= foreground then gpu.setForeground(foreground) end
	gpu.set(x, y + math.floor(height / 2), text)
end

local function getButtonTextData(text)
	return string.gsub(text, " ", "")
end

local function stringLimit(mode, text, size, noDots)
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

local function drawInfoPanel(x, y)
	square(x, y, width, 3, colors.inputPanel)
	if gpu.getForeground() ~= foreground then gpu.setForeground(colors.inputPanelText) end
	gpu.set(x + 2, y + 1, stringLimit("start", currentInput, width - 4))
end

local function drawKeyboard(x, y)

	keys.objects = {}

	local xPos, yPos, widthOfKey = x, y, 0

	drawInfoPanel(xPos, yPos)
	yPos = yPos + 3

	square(xPos, yPos, width, height - 3, colors.keyboard)

	yPos = yPos + 1
	xPos = x + 2

	local background, foreground
	for j = 1, #keys.current do
		for i = 1, #keys.current[j] do

			widthOfKey = unicode.len(keys.current[j][i][1])

			if keys.current[j][i][2] then
				if keys.current[j][i][4] then
					background, foreground = colors.systemKeyText, colors.systemKey
				else
					background, foreground = colors.systemKey, colors.systemKeyText
				end
			else
				if keys.current[j][i][4] then
					background, foreground = colors.usualKeyText, colors.usualKey
				else
					background, foreground = colors.usualKey, colors.usualKeyText
				end
			end
			button(xPos, yPos, keys.current[j][i][3], keys.current[j][i][1], background, foreground)
			
			table.insert(keys.objects, { xPos, yPos, xPos + widthOfKey - 1, yPos + keys.current[j][i][3] - 1, keys.current[j][i][1], keys.current[j][i][2], i, j })

			xPos = xPos + widthOfKey + 2
		end
		xPos = x + 2
		yPos = yPos + keys.current[j][1][3] + 1
	end

	if animation then
		gpu.setBackground(colors.inputPanel)
		gpu.setForeground(colors.inputPanelText)
		term.setCursorBlink(true)
		xPos, yPos = x + 2, y + 1
		xPos = xPos + unicode.len(currentInput)
		if xPos > x + width - 3 then xPos = x + width - 3 end
		term.setCursor(xPos, yPos)
	end
end

--Ебать говнокод! Обоссы себе ебало
local isCapsPressed, isShiftPressed, isAltPressed, is123Pressed = false, false, false, false
local function pressCaps()
	isCapsPressed = not isCapsPressed
	keys.english[3][1][4] = not keys.english[3][1][4]
	keys.russian[3][1][4] = not keys.russian[3][1][4]
	keys.symbols[3][1][4] = not keys.symbols[3][1][4]
end
local function pressShift()
	isShiftPressed = not isShiftPressed
	keys.english[4][1][4] = not keys.english[4][1][4]
	keys.english[4][12][4] = not keys.english[4][12][4]
	keys.russian[4][1][4] = not keys.russian[4][1][4]
	keys.russian[4][12][4] = not keys.russian[4][12][4]
	keys.symbols[4][1][4] = not keys.symbols[4][1][4]
	keys.symbols[4][12][4] = not keys.symbols[4][12][4]
end
local function pressAlt()
	isAltPressed = not isAltPressed
	keys.english[5][2][4] = not keys.english[5][2][4]
	keys.english[5][4][4] = not keys.english[5][4][4]
	keys.russian[5][2][4] = not keys.russian[5][2][4]
	keys.russian[5][4][4] = not keys.russian[5][4][4]
	keys.symbols[5][2][4] = not keys.symbols[5][2][4]
	keys.symbols[5][4][4] = not keys.symbols[5][4][4]
end
local function press123()
	is123Pressed = not is123Pressed
	keys.english[5][1][4] = not keys.english[5][1][4]
	keys.english[5][5][4] = not keys.english[5][5][4]
	keys.russian[5][1][4] = not keys.russian[5][1][4]
	keys.russian[5][5][4] = not keys.russian[5][5][4]
	keys.symbols[5][1][4] = not keys.symbols[5][1][4]
	keys.symbols[5][5][4] = not keys.symbols[5][5][4]
end

local oldLanguage = language

--Запомнить область пикселей и возвратить ее в виде массива
local function rememberOldPixels(x, y, x2, y2)
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
local function drawOldPixels(massivSudaPihay)
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

---------------------------------------- Программа ----------------------------------------

--ecs.prepareToExit()

local args = {...}

local xPos, yPos = math.floor(xSize / 2 - width / 2), ySize 

local oldPixels = rememberOldPixels(xPos, ySize - height + 1, xPos + width - 1, ySize)

if args[1] == "-a" then
	yPos = ySize - height + 1
	drawKeyboard(xPos, yPos)
else
	for i = 1, height do
		if i == height then animation = true end
		drawKeyboard(xPos, yPos)
		os.sleep(0.01)
		yPos = yPos - 1
	end
	yPos = yPos + 1
	animation = true
end

while true do
	local e = { event.pull() }
	if e[1] == "touch" then
		term.setCursorBlink(false)
		for i = 1, #keys.objects do
			if e[3] >= keys.objects[i][1] and e[4] >= keys.objects[i][2] and e[3] <= keys.objects[i][3] and e[4] <= keys.objects[i][4] then
				
				local x, y, height, text, background, foreground = keys.objects[i][1], keys.objects[i][2], keys.objects[i][4] - keys.objects[i][2] + 1, keys.objects[i][5], nil, nil

				if keys.objects[i][6] then
					background, foreground = colors.systemKeyText, colors.systemKey
				else
					background, foreground = colors.usualKeyText, colors.usualKey
				end

				--Анализируем
				local buttonTextData = getButtonTextData(keys.objects[i][5])
				
				if buttonTextData == "Caps" then
					pressCaps()
					
				elseif buttonTextData == "Alt" then
					pressAlt()
					
				elseif buttonTextData == ".123" then
					press123()
					if language ~= "symbols" then
						oldLanguage = language
						language = "symbols"
					else
						language = oldLanguage
					end
					keys.current = keys[language]
					
				elseif buttonTextData == "⬆" then
					pressShift()
					
				else
					--Нажимаем кнопку
					button(x, y, height, text, background, foreground)
					--Ждем
					os.sleep(keyPressDelay)
					--Анализируем еще раз

					if buttonTextData == "⌫" then
						currentInput = unicode.sub(currentInput, 1, -2)
						
					elseif buttonTextData == "Tab" then
						currentInput = currentInput .. "  "
					elseif buttonTextData == "Enter" then
						term.setCursorBlink(false)
						drawOldPixels(oldPixels)
						return currentInput
					elseif buttonTextData == "" or buttonTextData == nil then
						currentInput = currentInput .. " "
						
					else
						if isCapsPressed or isShiftPressed then
							currentInput = currentInput .. buttonTextData
						else
							currentInput = currentInput .. unicode.lower(buttonTextData)
						end
						
					end

					if isShiftPressed then pressShift() end

				end

				if isAltPressed and isShiftPressed then
					if language == "russian" then language = "english" elseif language == "english" then language = "russian" end
					keys.current = keys[language]
					drawKeyboard(xPos, yPos)
					os.sleep(keyPressDelay)
					pressAlt()
					pressShift()
				end

				--Отжимаем кнопку
				drawKeyboard(xPos, yPos)

				break
			end
		end
	end
end




