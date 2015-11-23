local gpu = require("component").gpu
local buffer = require("doubleBuffering")
local unicode = require("unicode")
local syntax = {}

----------------------------------------------------------------------------------------------------------------------------------------

--Стандартные цветовые схемы
syntax.colorSchemes = {
	midnight = {
		background = 0x262626,
		text = 0xffffff,
		strings = 0xff2024,
		loops = 0xffff98,
		comments = 0xa2ffb7,
		boolean = 0xffcc66,
		logic = 0xffcc66,
		numbers = 0x24c0ff,
		functions = 0xffcc66,
		compares = 0xffff98,
		lineNumbers = 0x444444,
		lineNumbersText = 0xDDDDDD,
		scrollBar = 0x444444,
		scrollBarPipe = 0x24c0ff,
		selection = 0x99B2F2,
	},
	sunrise = {
		background = 0xffffff,
		text = 0x262626,
		strings = 0x880000,
		loops = 0x24c0ff,
		comments = 0xa2ffb7,
		boolean = 0x19c0cc,
		logic = 0x880000,
		numbers = 0x24c0ff,
		functions = 0x24c0ff,
		compares = 0x880000,
		lineNumbers = 0x444444,
		lineNumbersText = 0xDDDDDD,
		scrollBar = 0x444444,
		scrollBarPipe = 0x24c0ff,
		selection = 0x99B2F2,
	},
}

--Текущая цветовая схема
local currentColorScheme = {}
--Шаблоны поиска
local patterns

----------------------------------------------------------------------------------------------------------------------------------------

--Пересчитать цвета шаблонов
--Приоритет поиска шаблонов снижается сверху вниз
local function definePatterns()
	patterns = {
		--Комментарии
		{ pattern = "%-%-.*", color = currentColorScheme.comments, cutFromLeft = 0, cutFromRight = 0 },
		
		--Строки
		{ pattern = "\"[^\"\"]*\"", color = currentColorScheme.strings, cutFromLeft = 0, cutFromRight = 0 },
		
		--Циклы, условия, объявления
		{ pattern = "while ", color = currentColorScheme.loops, cutFromLeft = 0, cutFromRight = 1 },
		{ pattern = "do$", color = currentColorScheme.loops, cutFromLeft = 0, cutFromRight = 0 },
		{ pattern = "do ", color = currentColorScheme.loops, cutFromLeft = 0, cutFromRight = 1 },
		{ pattern = "end$", color = currentColorScheme.loops, cutFromLeft = 0, cutFromRight = 0 },
		{ pattern = "end ", color = currentColorScheme.loops, cutFromLeft = 0, cutFromRight = 1 },
		{ pattern = "for ", color = currentColorScheme.loops, cutFromLeft = 0, cutFromRight = 1 },
		{ pattern = " in ", color = currentColorScheme.loops, cutFromLeft = 0, cutFromRight = 1 },
		{ pattern = "repeat ", color = currentColorScheme.loops, cutFromLeft = 0, cutFromRight = 1 },
		{ pattern = "if ", color = currentColorScheme.loops, cutFromLeft = 0, cutFromRight = 1 },
		{ pattern = "then", color = currentColorScheme.loops, cutFromLeft = 0, cutFromRight = 0 },
		{ pattern = "until ", color = currentColorScheme.loops, cutFromLeft = 0, cutFromRight = 1 },
		{ pattern = "return", color = currentColorScheme.loops, cutFromLeft = 0, cutFromRight = 0 },
		{ pattern = "local ", color = currentColorScheme.loops, cutFromLeft = 0, cutFromRight = 1 },
		{ pattern = "function ", color = currentColorScheme.loops, cutFromLeft = 0, cutFromRight = 1 },
		{ pattern = "else$", color = currentColorScheme.loops, cutFromLeft = 0, cutFromRight = 0 },
		{ pattern = "else ", color = currentColorScheme.loops, cutFromLeft = 0, cutFromRight = 1 },
		{ pattern = "elseif ", color = currentColorScheme.loops, cutFromLeft = 0, cutFromRight = 1 },

		--Состояния переменной
		{ pattern = "true", color = currentColorScheme.boolean, cutFromLeft = 0, cutFromRight = 0 },
		{ pattern = "false", color = currentColorScheme.boolean, cutFromLeft = 0, cutFromRight = 0 },
		{ pattern = "nil", color = currentColorScheme.boolean, cutFromLeft = 0, cutFromRight = 0 },
				
		--Функции
		{ pattern = "%s([%a%d%_%-%.]*)%(", color = currentColorScheme.functions, cutFromLeft = 0, cutFromRight = 1 },
		
		--And, or, not, break
		{ pattern = " and ", color = currentColorScheme.logic, cutFromLeft = 0, cutFromRight = 1 },
		{ pattern = " or ", color = currentColorScheme.logic, cutFromLeft = 0, cutFromRight = 1 },
		{ pattern = " not ", color = currentColorScheme.logic, cutFromLeft = 0, cutFromRight = 1 },
		{ pattern = " break$", color = currentColorScheme.logic, cutFromLeft = 0, cutFromRight = 0 },
		{ pattern = "^break", color = currentColorScheme.logic, cutFromLeft = 0, cutFromRight = 0 },
		{ pattern = " break ", color = currentColorScheme.logic, cutFromLeft = 0, cutFromRight = 0 },

		--Сравнения и мат. операции
		{ pattern = "<=", color = currentColorScheme.compares, cutFromLeft = 0, cutFromRight = 0 },
		{ pattern = ">=", color = currentColorScheme.compares, cutFromLeft = 0, cutFromRight = 0 },
		{ pattern = "<", color = currentColorScheme.compares, cutFromLeft = 0, cutFromRight = 0 },
		{ pattern = ">", color = currentColorScheme.compares, cutFromLeft = 0, cutFromRight = 0 },
		{ pattern = "==", color = currentColorScheme.compares, cutFromLeft = 0, cutFromRight = 0 },
		{ pattern = "~=", color = currentColorScheme.compares, cutFromLeft = 0, cutFromRight = 0 },
		{ pattern = "=", color = currentColorScheme.compares, cutFromLeft = 0, cutFromRight = 0 },
		{ pattern = "%+", color = currentColorScheme.compares, cutFromLeft = 0, cutFromRight = 0 },
		{ pattern = "%-", color = currentColorScheme.compares, cutFromLeft = 0, cutFromRight = 0 },
		{ pattern = "%*", color = currentColorScheme.compares, cutFromLeft = 0, cutFromRight = 0 },
		{ pattern = "%/", color = currentColorScheme.compares, cutFromLeft = 0, cutFromRight = 0 },
		{ pattern = "%.%.", color = currentColorScheme.compares, cutFromLeft = 0, cutFromRight = 0 },
		{ pattern = "%#", color = currentColorScheme.compares, cutFromLeft = 0, cutFromRight = 0 },
		{ pattern = "#^", color = currentColorScheme.compares, cutFromLeft = 0, cutFromRight = 0 },

		--Числа
		{ pattern = "%s(0x)(%w*)", color = currentColorScheme.numbers, cutFromLeft = 0, cutFromRight = 0 },
		{ pattern = "(%s)([%d%.]*)", color = currentColorScheme.numbers, cutFromLeft = 0, cutFromRight = 0 },	
	}
end

--Костыльная замена обычному string.find()
--Работает медленнее, но хотя бы поддерживает юникод
function unicode.find(str, pattern, init, plain)
	-- checkArg(1, str, "string")
	-- checkArg(2, pattern, "string")
	-- checkArg(3, init, "number", "nil")
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

--Объявить новую цветовую схему
function syntax.setColorScheme(colorScheme)
	--Выбранная цветовая схема
	currentColorScheme = colorScheme
	--Пересчитываем шаблоны
	definePatterns()
end

----------------------------------------------------------------------------------------------------------------------------------------

--Проанализировать строку и создать на ее основе цветовую карту
function syntax.highlight(x, y, text, limit)
	--Кароч вооот, хыыы
	local searchFrom, starting, ending
	--Загоняем в буфер всю строку базового цвета
	buffer.text(x, y, currentColorScheme.text, limit and unicode.sub(text, 1, limit) or text)
	limit = limit or math.huge
	--Перебираем шаблоны
	for i = #patterns, 1, -1 do
		searchFrom = 1
		--Перебираем весь текст, а то мало ли шаблон дохуя раз встречается
		while true do
			starting, ending = unicode.find(text, patterns[i].pattern, searchFrom)
			if starting and ending then
				if ending <= limit then
					buffer.text(x + starting - 1, y, patterns[i].color, unicode.sub(text, starting, ending - patterns[i].cutFromRight))
					searchFrom = ending + 1
				else
					buffer.text(x + starting - 1, y, patterns[i].color, unicode.sub(text, starting, limit))
					break
				end
			else
				break
			end
		end
	end
end

function syntax.convertFileToStrings(path)
	local array = {}
	local file = io.open(path, "r")
	for line in file:lines() do table.insert(array, line) end
	file:close()
	return array
end

-- Открыть окно-просмотрщик кода
function syntax.viewCode(x, y, width, height, strings, fromSymbol, fromString, highlightLuaSyntax, selection)

	--Рассчитываем максимальное количество строк, которое мы будем отображать
	local maximumNumberOfAvailableStrings
	if strings[fromString + height - 1] then
		maximumNumberOfAvailableStrings = fromString + height - 1
	else
		maximumNumberOfAvailableStrings = #strings
	end
	--Рассчитываем ширину полоски с номерами строк
	local widthOfStringCounter = unicode.len(maximumNumberOfAvailableStrings) + 2

	--Рисуем номера строк
	buffer.square(x, y, widthOfStringCounter, height, currentColorScheme.lineNumbers, 0xFFFFFF, " ")
	local yPos = y
	for i = fromString, maximumNumberOfAvailableStrings do
		buffer.text(x + widthOfStringCounter - unicode.len(i) - 1, yPos, currentColorScheme.text, tostring(i))
		yPos = yPos + 1
	end

	--Рассчитываем стратовую позицию текстового поля
	local textFieldPosition = x + widthOfStringCounter
	local widthOfText = width - widthOfStringCounter - 3

	--Рисуем подложку под текст
	buffer.square(textFieldPosition, y, width - widthOfStringCounter - 1, height, currentColorScheme.background, 0xFFFFFF, " ")

	--Рисуем выделение, если оно имеется
	if selection then
		if selection.to.y < selection.from.y then
			local temp = selection.from.y
			selection.from.y = selection.to.y
			selection.to.y = temp
		end

		local heightOfSelection = selection.to.y - selection.from.y + 1

		local function selectString(number, from, to)
			if number >= fromString and number <= fromString + height then

			end
		end

		if heightOfSelection == 1 then

		elseif heightOfSelection == 2 then

		else

		end
	end

	--Рисуем текст
	yPos = y
	for i = fromString, maximumNumberOfAvailableStrings do
		--Учитываем опциональную подсветку ситнаксиса
		if highlightLuaSyntax then
			syntax.highlight(textFieldPosition + 1, yPos, strings[i], widthOfText)
		else
			buffer.text(textFieldPosition + 1, yPos, currentColorScheme.text, unicode.sub(strings[i], 1, widthOfText))
		end

		yPos = yPos + 1
	end
	
	--Рисуем скроллбар
	buffer.scrollBar(x + width - 1, y, 1, height, #strings, fromString, currentColorScheme.scrollBar, currentColorScheme.scrollBarPipe)

	--Рисуем изменения из буфера
	buffer.draw()
end

----------------------------------------------------------------------------------------------------------------

--Стартовое объявление цветовой схемы при загрузке библиотеки
syntax.setColorScheme(syntax.colorSchemes.midnight)

--Епты бля!
local strings = syntax.convertFileToStrings("MineOS/Applications/Highlight.app/Resources/TestFile.txt")

local xSize, ySize = gpu.getResolution()
buffer.square(1, 1, xSize, ySize, ecs.colors.green, 0xFFFFFF, " ")
buffer.draw(true)

syntax.viewCode(2, 2, 70, 20, strings, 1, 1, true, {from = {x = 6, y = 2}, to = {x = 3, y = 8}})

----------------------------------------------------------------------------------------------------------------

return syntax




