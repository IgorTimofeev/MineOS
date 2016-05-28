
if not _G.buffer and not package.loaded.doubleBuffering then _G.buffer = require("doubleBuffering") end
if not _G.ecs and not package.loaded.ECSAPI then _G.ecs = require("ECSAPI") end
if not _G.unicode and not package.loaded.unicode then _G.unicode = require("unicode") end
local GUI = {}

---------------------------------------------------- Универсальные методы --------------------------------------------------------

GUI.directions = {
	horizontal = 0,
	vertical = 1,
}

GUI.buttonTypes = {
	default = 0,
	adaptive = 1,
}

-- Универсальный метод для проверки клика на прямоугольный объект
local function clickedAtObject(object, x, y)
	if x >= object.x and y >= object.y and x <= object.x + object.width - 1 and y <= object.y + object.height - 1 then return true end
	return false
end

--Создание базового примитива-объекта
function GUI.object(x, y, width, height)
	return {
		x = x,
		y = y,
		width = width,
		height = height,
		isClicked = clickedAtObject,
	}
end

---------------------------------------------------- Кнопки --------------------------------------------------------------------

-- Метод-рисоватор кнопки
local function drawButton(buttonObject, isPressed)
	local textLength = unicode.len(buttonObject.text)
	if textLength > buttonObject.width then buttonObject.text = unicode.sub(buttonObject.text, 1, buttonObject.width) end
	
	local xText = math.floor(buttonObject.x + buttonObject.width / 2 - textLength / 2)
	local yText = math.floor(buttonObject.y + buttonObject.height / 2)
	local buttonColor = isPressed and buttonObject.colors.pressed.button or buttonObject.colors.default.button
	local textColor = isPressed and buttonObject.colors.pressed.text or buttonObject.colors.default.text

	buffer.square(buttonObject.x, buttonObject.y, buttonObject.width, buttonObject.height, buttonColor, textColor, " ")
	buffer.text(xText, yText, textColor, buttonObject.text)
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
local function createButtonObject(x, y, width, height, buttonColor, textColor, buttonPressedColor, textPressedColor, text)
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
	}
	buttonObject.text = text
	buttonObject.press = pressButton
	buttonObject.draw = drawButton
	return buttonObject
end

-- Кнопка фиксированных размеров
function GUI.button(x, y, width, height, buttonColor, textColor, buttonPressedColor, textPressedColor, text)
	local buttonObject = createButtonObject(x, y, width, height, buttonColor, textColor, buttonPressedColor, textPressedColor, text)
	buttonObject:draw()
	return buttonObject
end

-- Кнопка, подстраивающаяся под длину текста
function GUI.adaptiveButton(x, y, xOffset, yOffset, buttonColor, textColor, buttonPressedColor, textPressedColor, text)
	local buttonObject = createButtonObject(x, y, xOffset * 2 + unicode.len(text), yOffset * 2 + 1, buttonColor, textColor, buttonPressedColor, textPressedColor, text)
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


--------------------------------------------------------------------------------------------------------------------------------

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
	if type(text) == "table" then text = serialization.serialize(text) end
	text = tostring(text)
	text = (errorWindowParameters and errorWindowParameters.truncate) and ecs.stringLimit("end", text, errorWindowParameters.truncate) or text
	text = { text }
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


