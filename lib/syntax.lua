if not _G.buffer then _G.buffer = require("doubleBuffering") end
if not _G.unicode then _G.unicode = require("unicode") end

local syntax = {}

----------------------------------------------------------------------------------------------------------------------------------------

syntax.colorSchemes = {
	midnight = {
		background = 0x1b1b1b,
		text = 0xffffff,
		strings = 0xff2024,
		loops = 0xffff98,
		comments = 0xa2ffb7,
		boolean = 0xffcc66,
		logic = 0xffcc66,
		numbers = 0x24c0ff,
		functions = 0xffcc66,
		compares = 0xffff98,
		lineNumbers = 0x262626,
		lineNumbersText = 0xDDDDDD,
		scrollBar = 0x444444,
		scrollBarPipe = 0x24c0ff,
		selection = 0x99B2F2,
	}
}

local currentColorScheme, patterns

----------------------------------------------------------------------------------------------------------------------------------------

--Пересчитать цвета шаблонов
--Приоритет поиска шаблонов снижается сверху вниз
local function definePatterns()
	patterns = {
		--Комментарии
		{ pattern = "%-%-.+", color = currentColorScheme.comments, cutFromLeft = 0, cutFromRight = 0 },
		
		--Строки
		{ pattern = "\"[^\"\"]+\"", color = currentColorScheme.strings, cutFromLeft = 0, cutFromRight = 0 },
		
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
		{ pattern = "[%s%=][%a%d%_%-%.]+%(", color = currentColorScheme.functions, cutFromLeft = 0, cutFromRight = 1 },
		{ pattern = "^[%a%d%_%-%.%=]+%(", color = currentColorScheme.functions, cutFromLeft = 0, cutFromRight = 1 },
		
		--Логические выражения
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
		{ pattern = "%.+", color = currentColorScheme.compares, cutFromLeft = 0, cutFromRight = 0 },
		{ pattern = "%#", color = currentColorScheme.compares, cutFromLeft = 0, cutFromRight = 0 },
		{ pattern = "#^", color = currentColorScheme.compares, cutFromLeft = 0, cutFromRight = 0 },
		{ pattern = "%%", color = currentColorScheme.compares, cutFromLeft = 0, cutFromRight = 0 },

		--Числа
		{ pattern = "[%s%(%,]0x%w+", color = currentColorScheme.numbers, cutFromLeft = 1, cutFromRight = 0 },
		{ pattern = "[%s%(%,][%d%.]+", color = currentColorScheme.numbers, cutFromLeft = 1, cutFromRight = 0 },	
	}
end

local function convertFileToStrings(path)
	local array = {}
	local maximumStringWidth = 0
	local file = io.open(path, "r")
	for line in file:lines() do
		line = string.gsub(line, "	", string.rep(" ", 4))
		maximumStringWidth = math.max(maximumStringWidth, unicode.len(line))
		table.insert(array, line)
	end
	file:close()
	return array, maximumStringWidth
end

--Костыльная замена обычному string.find()
--Работает медленнее, но хотя бы поддерживает юникод
function unicode.find(str, pattern, init, plain)
	if init then
		if init < 0 then
			init = -#unicode.sub(str,init)
		elseif init > 0 then
			init = #unicode.sub(str, 1, init - 1) + 1
		end
	end
	
	a, b = string.find(str, pattern, init, plain)
	
	if a then
		local ap, bp = str:sub(1, a - 1), str:sub(a,b)
		a = unicode.len(ap) + 1
		b = a + unicode.len(bp) - 1
		return a, b
	else
		return a
	end
end

--Объявить новую цветовую схему
function syntax.setColorScheme(colorScheme)
	currentColorScheme = colorScheme
	definePatterns()
end

----------------------------------------------------------------------------------------------------------------------------------------

--Нарисовать и подсветить строку
function syntax.highlightString(x, y, text, fromSymbol, limit)
	--Кароч вооот, хыыы
	local searchFrom, starting, ending
	--Загоняем в буфер всю строку базового цвета
	buffer.text(x - fromSymbol + 1, y, currentColorScheme.text, text)
	--Перебираем шаблоны
	for i = #patterns, 1, -1 do
		searchFrom = 1
		--Перебираем весь текст, а то мало ли шаблон дохуя раз встречается
		while true do
			starting, ending = unicode.find(text, patterns[i].pattern, searchFrom)
			if starting and ending then
				buffer.text(x + starting - fromSymbol + patterns[i].cutFromLeft, y, patterns[i].color, unicode.sub(text, starting + patterns[i].cutFromLeft, ending - patterns[i].cutFromRight))		
				if ending > limit then break end
				searchFrom = ending + 1
			else
				break
			end
		end
	end
end

-- Открыть окно-просмотрщик кода
--x, y, width, height, strings, maximumStringWidth, fromSymbol, fromString, highlightLuaSyntax, selection, highlightedStrings
function syntax.viewCode(args)
	--Рассчитываем максимальное количество строк, которое мы будем отображать
	local countOfStringsOnDisplay, maximumNumberOfAvailableStrings
	if args.strings[args.fromString + args.height - 1] then
		countOfStringsOnDisplay = args.scrollbars.horizontal and args.height - 1 or args.height
		maximumNumberOfAvailableStrings = args.fromString + args.height - 1
	else
		countOfStringsOnDisplay = #args.strings
		maximumNumberOfAvailableStrings = #args.strings
	end

	--Рассчитываем ширину полоски с номерами строк
	local lineNumbersWidth = unicode.len(args.fromStringOnLineNumbers + countOfStringsOnDisplay) + 2

	--Рассчитываем стратовую позицию текстового поля
	local textFieldPosition = args.x + lineNumbersWidth
	local widthOfText = args.width - lineNumbersWidth - 3
	local xEnd, yEnd = args.x + args.width - 1, args.y + args.height - 1

	--Рисуем подложку под текст
	buffer.square(args.x, args.y, args.width, args.height, currentColorScheme.background, 0xFFFFFF, " ")
	--Рисуем подложку под номера строк
	buffer.square(args.x, args.y, lineNumbersWidth, args.height, currentColorScheme.lineNumbers, 0xFFFFFF, " ")

	--Подсвечиваем некоторые строки, если указано
	if args.highlightedStrings then
		for stringNumber, color in pairs(args.highlightedStrings) do
			if stringNumber >= args.fromStringOnLineNumbers and stringNumber < args.fromStringOnLineNumbers + countOfStringsOnDisplay then
				buffer.square(args.x, args.y + stringNumber - args.fromStringOnLineNumbers, args.width - 1, 1, color, 0xFFFFFF, " ")
				buffer.square(args.x, args.y + stringNumber - args.fromStringOnLineNumbers, lineNumbersWidth, 1, currentColorScheme.lineNumbers, 0xFFFFFF, " ", 60)
			end
		end
	end

	--Рисуем номера строк
	local yPos = args.y
	for i = args.fromStringOnLineNumbers, args.fromStringOnLineNumbers + countOfStringsOnDisplay - 1 do
		buffer.text(args.x + lineNumbersWidth - unicode.len(i) - 1, yPos, currentColorScheme.text, tostring(i))
		yPos = yPos + 1
	end

	--Рисуем выделение, если оно имеется
	if args.selection then
		--Считаем высоту выделения
		local heightOfSelection = args.selection.to.y - args.selection.from.y + 1
		--Если высота выделения > 1
		if heightOfSelection > 1 then
			--Верхнее выделение
			if args.selection.from.x < args.fromSymbol + widthOfText and args.selection.from.y >= args.fromString and args.selection.from.y < args.fromString + args.height then
				local cyka = textFieldPosition + args.selection.from.x - args.fromSymbol
				if cyka < textFieldPosition then
					cyka = textFieldPosition
				end
				buffer.square(cyka, args.y + args.selection.from.y - args.fromString, widthOfText - cyka + lineNumbersWidth + 2 + args.x, 1, currentColorScheme.selection, 0xFFFFFF, " ")
			end
			--Средние выделения
			if heightOfSelection > 2 then
				for i = 1, heightOfSelection - 2 do
					if args.selection.from.y + i >= args.fromString and args.selection.from.y + i < args.fromString + args.height then
						buffer.square(textFieldPosition, args.y + args.selection.from.y + i - args.fromString, widthOfText + 2, 1, currentColorScheme.selection, 0xFFFFFF, " ")
					end
				end
			end
			--Нижнее выделение
			if args.selection.to.x >= args.fromSymbol and args.selection.to.y >= args.fromString and args.selection.to.y < args.fromString + args.height then
				buffer.square(textFieldPosition, args.y + args.selection.to.y - args.fromString, args.selection.to.x - args.fromSymbol + 1, 1, currentColorScheme.selection, 0xFFFFFF, " ")
			end
		elseif heightOfSelection == 1 then
			local cyka = args.selection.to.x
			if cyka > args.fromSymbol + widthOfText - 1 then cyka = args.fromSymbol + widthOfText - 1 end
			buffer.square(textFieldPosition + args.selection.from.x, args.selection.from.y, cyka - args.selection.from.x, 1, currentColorScheme.selection, 0xFFFFFF, " ")

		end
	end

	--Выставляем ограничение прорисовки буфера
	textFieldPosition = textFieldPosition + 1
	buffer.setDrawLimit(textFieldPosition, args.y, widthOfText, args.height)

	--Рисуем текст
	yPos = args.y
	for i = args.fromString, maximumNumberOfAvailableStrings do
		--Учитываем опциональную подсветку ситнаксиса
		if args.highlightLuaSyntax then
			syntax.highlightString(textFieldPosition, yPos, args.strings[i], args.fromSymbol, widthOfText)
		else
			buffer.text(textFieldPosition, yPos, currentColorScheme.text, unicode.sub(args.strings[i], args.fromSymbol, widthOfText))
		end

		yPos = yPos + 1
	end

	--Убираем ограничение отрисовки
	buffer.resetDrawLimit()

	--Рисуем вертикальный скроллбар
	if args.scrollbars.vertical then buffer.scrollBar(xEnd, args.y, 1, args.height, #args.strings, args.fromString, currentColorScheme.scrollBar, currentColorScheme.scrollBarPipe) end
	--Рисуем горизонтальный скроллбар
	if args.scrollbars.horizontal then buffer.horizontalScrollBar(args.x + lineNumbersWidth, yEnd, args.width - lineNumbersWidth - 1, args.maximumStringWidth, args.fromSymbol, currentColorScheme.scrollBar, currentColorScheme.scrollBarPipe) end

	--Для всяких майнкодов, чтоб курсор можно было ставит и ТОПЕ
	return textFieldPosition
end

----------------------------------------------------------------------------------------------------------------

-- Стартовое объявление цветовой схемы при загрузке библиотеки
syntax.setColorScheme(syntax.colorSchemes.midnight)

----------------------------------------------------------------------------------------------------------------

-- buffer.start()
-- buffer.clear(0xFF8888)

-- local strings, maximumStringWidth = convertFileToStrings("/OS.lua")

-- local args = {
-- 	x = 1,
-- 	y = 1,
-- 	width = 100,
-- 	height = 40,
-- 	strings = strings,
-- 	fromString = 1,
-- 	fromSymbol = 1,
-- 	fromStringOnLineNumbers = 6,
-- 	maximumStringWidth = maximumStringWidth,
-- 	highlightLuaSyntax = true,
-- 	selection = {
-- 		from = {x = 8, y = 6}, 
-- 		to = {x = 16, y = 12}
-- 	},
-- 	highlightedStrings = {
-- 		[31] = 0xFF4444,
-- 		[33] = 0x55FF55,
-- 	},
-- 	scrollbars = {
-- 		vertical = true,
-- 		horizontal = true,
-- 	}
-- }

-- syntax.viewCode(args)
-- buffer.draw()

----------------------------------------------------------------------------------------------------------------

return syntax




