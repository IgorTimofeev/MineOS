
local libraries = {
	buffer = "doubleBuffering",
	ecs = "ECSAPI",
	unicode = "unicode"
}

for library in pairs(libraries) do if not _G[library] then _G[library] = require(libraries[library]) end end; libraries = nil
local GUI = {}

---------------------------------------------------- Универсальные методы --------------------------------------------------------

GUI.directions = {
	horizontal = 0,
	vertical = 1,
}

GUI.buttonTypes = {
	default = 0,
	adaptive = 1,
	framedDefault = 2,
	framedAdaptive = 3,
}

GUI.colors = {
	disabled = 0x888888,
}

-- Универсальный метод для проверки клика на прямоугольный объект
local function objectClicked(object, x, y)
	if x >= object.x and y >= object.y and x <= object.x + object.width - 1 and y <= object.y + object.height - 1 and not object.disabled then return true end
	return false
end

local function objectSetDisabled(object, state)
	object.disabled = state
end

--Создание базового примитива-объекта
function GUI.object(x, y, width, height)
	return {
		x = x,
		y = y,
		width = width,
		height = height,
		isClicked = objectClicked,
	}
end

---------------------------------------------------- Кнопки --------------------------------------------------------------------

-- Универсальынй метод-рисоватор кнопки
local function drawButton(buttonObject, isPressed)
	local textLength = unicode.len(buttonObject.text)
	if textLength > buttonObject.width then buttonObject.text = unicode.sub(buttonObject.text, 1, buttonObject.width) end
	
	local xText = math.floor(buttonObject.x + buttonObject.width / 2 - textLength / 2)
	local yText = math.floor(buttonObject.y + buttonObject.height / 2)
	local buttonColor = buttonObject.disabled and buttonObject.colors.disabled.button or (isPressed and buttonObject.colors.pressed.button or buttonObject.colors.default.button)
	local textColor = buttonObject.disabled and buttonObject.colors.disabled.text or (isPressed and buttonObject.colors.pressed.text or buttonObject.colors.default.text)

	if buttonObject.type == GUI.buttonTypes.default or buttonObject.type == GUI.buttonTypes.adaptive then
		buffer.square(buttonObject.x, buttonObject.y, buttonObject.width, buttonObject.height, buttonColor, textColor, " ")
		buffer.text(xText, yText, textColor, buttonObject.text)
	elseif buttonObject.type == GUI.buttonTypes.framedDefault or buttonObject.type == GUI.buttonTypes.framedAdaptive then
		buffer.frame(buttonObject.x, buttonObject.y, buttonObject.width, buttonObject.height, buttonColor)
		buffer.text(xText, yText, textColor, buttonObject.text)
	end
end

-- Метод-нажиматор кнопки
local function pressButton(buttonObject, pressTime)
	drawButton(buttonObject, true)
	buffer.draw()
	os.sleep(pressTime or 0.2)
	drawButton(buttonObject, false)
	buffer.draw()
end

-- Создание таблицы кнопки со всеми необходимыми параметрами
local function createButtonObject(buttonType, x, y, width, height, buttonColor, textColor, buttonPressedColor, textPressedColor, text, disabledState)
	local buttonObject = GUI.object(x, y, width, height)
	buttonObject.colors = {
		default = {
			button = buttonColor,
			text = textColor
		},
		pressed = {
			button = buttonPressedColor,
			text = textPressedColor
		},
		disabled = {
			button = GUI.colors.disabled,
			text = GUI.colors.disabled,
		}
	}
	buttonObject.disabled = disabledState
	buttonObject.setDisabled = objectSetDisabled
	buttonObject.type = buttonType
	buttonObject.text = text
	buttonObject.press = pressButton
	buttonObject.draw = drawButton
	return buttonObject
end

-- Кнопка фиксированных размеров
function GUI.button(x, y, width, height, buttonColor, textColor, buttonPressedColor, textPressedColor, text, disabledState)
	local buttonObject = createButtonObject(GUI.buttonTypes.default, x, y, width, height, buttonColor, textColor, buttonPressedColor, textPressedColor, text, disabledState)
	buttonObject:draw()
	return buttonObject
end

-- Кнопка, подстраивающаяся под размер текста
function GUI.adaptiveButton(x, y, xOffset, yOffset, buttonColor, textColor, buttonPressedColor, textPressedColor, text, disabledState)
	local buttonObject = createButtonObject(GUI.buttonTypes.adaptive, x, y, xOffset * 2 + unicode.len(text), yOffset * 2 + 1, buttonColor, textColor, buttonPressedColor, textPressedColor, text, disabledState)
	buttonObject:draw()
	return buttonObject
end

-- Кнопка в рамке
function GUI.framedButton(x, y, width, height, buttonColor, textColor, buttonPressedColor, textPressedColor, text, disabledState)
	local buttonObject = createButtonObject(GUI.buttonTypes.framedDefault, x, y, width, height, buttonColor, textColor, buttonPressedColor, textPressedColor, text, disabledState)
	buttonObject:draw()
	return buttonObject
end

-- Кнопка в рамке, подстраивающаяся под размер текста
function GUI.adaptiveFramedButton(x, y, xOffset, yOffset, buttonColor, textColor, buttonPressedColor, textPressedColor, text, disabledState)
	local buttonObject = createButtonObject(GUI.buttonTypes.framedAdaptive, x, y, xOffset * 2 + unicode.len(text), yOffset * 2 + 1, buttonColor, textColor, buttonPressedColor, textPressedColor, text, disabledState)
	buttonObject:draw()
	return buttonObject
end

-- Вертикальный или горизонтальный ряд кнопок
-- Каждая кнопка - это массив вида {enum GUI.buttonTypes.default или GUI.buttonTypes.adaptive, int ширина/отступ, int высота/отступ, int цвет кнопки, int цвет текста, int цвет нажатой кнопки, int цвет нажатого текста, string текст}
-- Метод возвращает обычный массив кнопочных объектов (см. выше)
function GUI.buttons(x, y, direction, spaceBetweenButtons, ...)
	local buttons = {...}
	local buttonObjects = {}

	local function drawCorrectButton(i)
		if buttons[i][1] == GUI.buttonTypes.default then
			return GUI.button(x, y, buttons[i][2], buttons[i][3], buttons[i][4], buttons[i][5], buttons[i][6], buttons[i][7], buttons[i][8])
		elseif buttons[i][1] == GUI.buttonTypes.adaptive then
			return GUI.adaptiveButton(x, y, buttons[i][2], buttons[i][3], buttons[i][4], buttons[i][5], buttons[i][6], buttons[i][7], buttons[i][8])
		elseif buttons[i][1] == GUI.buttonTypes.framedDefault then
			return GUI.framedButton(x, y, buttons[i][2], buttons[i][3], buttons[i][4], buttons[i][5], buttons[i][6], buttons[i][7], buttons[i][8])
		elseif buttons[i][1] == GUI.buttonTypes.framedAdaptive then
			return GUI.adaptiveFramedButton(x, y, buttons[i][2], buttons[i][3], buttons[i][4], buttons[i][5], buttons[i][6], buttons[i][7], buttons[i][8])
		else
			error("Неподдерживаемый тип кнопки: " .. tostring(buttons[i][1]))
		end
	end

	for i = 1, #buttons do
		buttonObjects[i] = drawCorrectButton(i)
		if direction == GUI.directions.horizontal then
			x = x + buttonObjects[i].width + spaceBetweenButtons
		elseif direction == GUI.directions.vertical then
			y = y + buttonObjects[i].height + spaceBetweenButtons
		else
			error("Неподдерживаемое направление: " .. tostring(buttons[i][1]))
		end
	end

	return buttonObjects
end

function GUI.menu(x, y, width, menuColor, ...)
	local buttons = {...}
	buffer.square(x, y, width, 1, menuColor)
	x = x + 1
	local menuObjects = {}
	for i = 1, #buttons do
		menuObjects[i] = GUI.adaptiveButton(x, y, 1, 0, menuColor, buttons[i].textColor, buttons[i].buttonPressedColor or 0x3366CC, buttons[i].textPressedColor or 0xFFFFFF, buttons[i].text)
		x = x + menuObjects[i].width
	end
	return menuObjects
end


------------------------------------------------- Окна -------------------------------------------------------------------

-- Красивое окошко для отображения сообщения об ошибке. Аргумент errorWindowParameters может принимать следующие значения:
-- local errorWindowParameters = {
--   backgroundColor = 0x262626,
--   textColor = 0xFFFFFF,
--   truncate = 50,
--   title = {color = 0xFF8888, text = "Ошибочка"}
--   noAnimation = true,
-- }
function GUI.error(text, errorWindowParameters)
	--Всякие константы, бла-бла
	local backgroundColor = (errorWindowParameters and errorWindowParameters.backgroundColor) or 0x1b1b1b
	local errorPixMap = {
		{{0xffdb40       , 0xffffff,"#"}, {0xffdb40       , 0xffffff, "#"}, {backgroundColor, 0xffdb40, "▟"}, {backgroundColor, 0xffdb40, "▙"}, {0xffdb40       , 0xffffff, "#"}, {0xffdb40       , 0xffffff, "#"}},
		{{0xffdb40       , 0xffffff,"#"}, {backgroundColor, 0xffdb40, "▟"}, {0xffdb40       , 0xffffff, " "}, {0xffdb40       , 0xffffff, " "}, {backgroundColor, 0xffdb40, "▙"}, {0xffdb40       , 0xffffff, "#"}},
		{{backgroundColor, 0xffdb40,"▟"}, {0xffdb40       , 0xffffff, "c"}, {0xffdb40       , 0xffffff, "y"}, {0xffdb40       , 0xffffff, "k"}, {0xffdb40       , 0xffffff, "a"}, {backgroundColor, 0xffdb40, "▙"}},
	}
	local textColor = (errorWindowParameters and errorWindowParameters.textColor) or 0xFFFFFF
	local buttonWidth = 12
	local verticalOffset = 2
	local minimumHeight = verticalOffset * 2 + #errorPixMap
	local height = 0
	local widthOfText = math.floor(buffer.screen.width * 0.5)

	--Ебемся с текстом, делаем его пиздатым во всех смыслах
	if type(text) ~= "table" then
		text = tostring(text)
		text = (errorWindowParameters and errorWindowParameters.truncate) and ecs.stringLimit("end", text, errorWindowParameters.truncate) or text
		text = { text }
	end
	text = ecs.stringWrap(text, widthOfText)


	--Ебашим высоту правильнуюe
	height = verticalOffset * 2 + #text + 1
	if errorWindowParameters and errorWindowParameters.title then height = height + 2 end
	if height < minimumHeight then height = minimumHeight end

	--Ебашим стартовые коорды отрисовки
	local x, y = math.ceil(buffer.screen.width / 2 - widthOfText / 2), math.ceil(buffer.screen.height / 2 - height / 2)
	local OKButton = {}
	local oldPixels = buffer.copy(1, y, buffer.screen.width, height)

	--Отрисовочка
	local function draw()
		local yPos = y
		--Подложка
		buffer.square(1, yPos, buffer.screen.width, height, backgroundColor, 0x000000); yPos = yPos + verticalOffset
		buffer.customImage(x - #errorPixMap[1] - 3, yPos, errorPixMap)
		--Титл, епта!
		if errorWindowParameters and errorWindowParameters.title then buffer.text(x, yPos, errorWindowParameters.title.color, errorWindowParameters.title.text); yPos = yPos + 2 end
		--Текстус
		for i = 1, #text do buffer.text(x, yPos, textColor, text[i]); yPos = yPos + 1 end; yPos = yPos + 1
		--Кнопачка
		OKButton = GUI.button(x + widthOfText - buttonWidth, y + height - 2, buttonWidth, 1, 0x3392FF, 0xFFFFFF, 0xFFFFFF, 0x262626, "OK")
		--Атрисовачка
		buffer.draw()
	end

	--Графонистый выход
	local function quit()
		OKButton:press(0.2)
		buffer.paste(1, y, oldPixels)
		buffer.draw()
	end

	--Онимацыя
	if not (errorWindowParameters and errorWindowParameters.noAnimation) then for i = 1, height do buffer.setDrawLimit(1, math.floor(buffer.screen.height / 2) - i, buffer.screen.width, i * 2); draw(); os.sleep(0.05) end; buffer.resetDrawLimit() end
	draw()

	--Анализ говнища
	while true do
		local e = {event.pull()}
		if e[1] == "key_down" then
			if e[4] == 28 then
				quit(); return
			end
		elseif e[1] == "touch" then
			if OKButton:isClicked(e[3], e[4]) then
				quit(); return
			end
		end
	end
end

--------------------------------------------------------------------------------------------------------------------------------

-- local textFieldProperties = {
-- 	--Регурярное выражение, которому должны соответствовать вводимые данные. При несоответствии на выходе из функции выдается первоначальный текст, поданынй на выход функции
-- 	regex = "^%d+$",
-- 	--Отключает символ многоточия при выходе за пределы текстового поля
-- 	disableDots = true,
-- 	--Попросту отрисовывает всю необходимую информацию без активации нажатия на клавиши
-- 	justDrawNotEvent = true,
-- 	--Задержка между миганимем курсора
-- 	cursorBlinkDelay = 1.5,
-- 	--Цвет курсора
-- 	cursorColor = 0xFF7777,
-- 	--Символ, используемый для отрисовки курсора
-- 	cursorSymbol = "▌",
-- 	--Символ-маскировщик, на который будет визуально заменен весь вводимый текст. Полезно для полей ввода пароля
-- 	maskTextWithSymbol = "*",
-- }

function GUI.input(x, y, width, foreground, startText, textFieldProperties)
	local text = startText
	local textLength = unicode.len(text)
	local cursorBlinkState = false
	local cursorBlinkDelay = (textFieldProperties and textFieldProperties.cursorBlinkDelay) and textFieldProperties.cursorBlinkDelay or 0.5
	local cursorColor = (textFieldProperties and textFieldProperties.cursorColor) and textFieldProperties.cursorColor or 0x00A8FF
	local cursorSymbol = (textFieldProperties and textFieldProperties.cursorSymbol) and textFieldProperties.cursorSymbol or "┃"
	
	local oldPixels = {}; for i = x, x + width - 1 do table.insert(oldPixels, { buffer.get(i, y) }) end

	local function drawOldPixels()
		for i = 1, #oldPixels do buffer.set(x + i - 1, y, oldPixels[i][1], oldPixels[i][2], oldPixels[i][3]) end
	end

	local function getTextLength()
		textLength = unicode.len(text)
	end

	local function textFormat()
		local formattedText = text

		if textFieldProperties and textFieldProperties.maskTextWithSymbol then
			formattedText = string.rep(textFieldProperties.maskTextWithSymbol or "*", textLength)
		end

		if textLength > width then
			if textFieldProperties and textFieldProperties.disableDots then
				formattedText = unicode.sub(formattedText, -width, -1)
			else
				formattedText = "…" .. unicode.sub(formattedText, -width + 1, -1)
			end
		end

		return formattedText
	end

	local function draw()
		drawOldPixels()
		buffer.text(x, y, foreground, textFormat())

		if cursorBlinkState then
			local cursorPosition = textLength < width and x + textLength or x + width - 1
			local bg = buffer.get(cursorPosition, y)
			buffer.set(cursorPosition, y, bg, cursorColor, cursorSymbol)
		end

		buffer.draw()
	end

	local function backspace()
		if unicode.len(text) > 0 then text = unicode.sub(text, 1, -2); getTextLength(); draw() end
	end

	local function quit()
		cursorBlinkState = false
		if textFieldProperties and textFieldProperties.regex and not string.match(text, textFieldProperties.regex) then
			text = startText
			draw()
			return startText
		end
		draw()
		return text
	end

	draw()

	if textFieldProperties and textFieldProperties.justDrawNotEvent then return startText end

	while true do
		local e = { event.pull(cursorBlinkDelay) }
		if e[1] == "key_down" then
			if e[4] == 14 then
				backspace()
			elseif e[4] == 28 then
				return quit()
			else
				local symbol = unicode.char(e[3])
				if not keyboard.isControl(e[3]) then
					text = text .. symbol
					getTextLength()
					draw()
				end
			end
		elseif e[1] == "clipboard" then
			text = text .. e[3]
			getTextLength()
			draw()
		elseif e[1] == "touch" then
			return quit()
		else
			cursorBlinkState = not cursorBlinkState
			draw()
		end
	end
end

--------------------------------------------------------------------------------------------------------------------------------

-- buffer.clear(0xFFAAAA)
-- buffer.draw(true)

-- GUI.error("Ублюдок, мать твою, а ну иди сюда, говно собачье, а ну решил ко мне лезть, ты... засранец вонючий, мать твою. А?! ну иди сюда, попробуй меня трахнуть, я тебя сам трахну ублюдок, анонист чертов, будь ты проклят, иди идиот, трахать тебя за свою семью, говно собачье, жлоб вонючий, дерьмо, сука, падла, иди сюда мерзавец, негодяй, гад, иди сюда ты говно, жопа!", {title = {color = 0xFF7777, text = "Ошибка авторизации"}})

-- local event = require("event")
-- local myButton = GUI.adaptiveButton(2, 2, 2, 1, 0xFFFFFF, 0x000000, 0xFF8888, 0xFFFFFF, "Кнопачка")
-- buffer.draw()
-- while true do
-- 	local e = {event.pull("touch")}
-- 	if myButton:isClicked(e[3], e[4]) then
-- 		myButton:press(0.2)
-- 	end
-- end

-- local myButtons = GUI.buttons(2, 2, GUI.directions.horizontal, 2, {GUI.buttonTypes.adaptive, 2, 0, 0xCCCCCC, 0x262626, 0xFF8888, 0xFFFFFF, "Кнопачка1"}, {GUI.buttonTypes.default, 30, 1, 0xCCCCCC, 0x262626, 0xFF8888, 0xFFFFFF, "Кнопачка2"}, {GUI.buttonTypes.adaptive, 2, 0, 0xCCCCCC, 0x262626, 0xFF8888, 0xFFFFFF, "Кнопачка3"})
-- buffer.draw()
-- while true do
-- 	local e = {event.pull("touch")}
-- 	for _, button in pairs(myButtons) do
-- 		if button:isClicked(e[3], e[4]) then
-- 			button:press(0.2)
-- 		end
-- 	end
-- end

--------------------------------------------------------------------------------------------------------------------------------

return GUI


