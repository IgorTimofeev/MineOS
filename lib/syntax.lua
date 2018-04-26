
require("advancedLua")
local buffer = require("doubleBuffering")
local unicode = require("unicode")
local unicodeLen, unicodeSub, unicodeFind = unicode.len, unicode.sub, string.unicodeFind

local syntax = {}

----------------------------------------------------------------------------------------------------------------------------------------

local indentationSymbol = "│"

local colorScheme = {
	background = 0x1E1E1E,
	text = 0xE1E1E1,
	strings = 0x99FF80,
	loops = 0xFFFF98,
	comments = 0x898989,
	boolean = 0xFFDB40,
	logic = 0xffCC66,
	numbers = 0x66DBFF,
	functions = 0xFFCC66,
	compares = 0xFFFF98,
	lineNumbersBackground = 0x2D2D2D,
	lineNumbersText = 0xC3C3C3,
	scrollBarBackground = 0x2D2D2D,
	scrollBarForeground = 0x5A5A5A,
	selection = 0x4B4B4B,
	indentation = 0x2D2D2D,
}

local patterns = {
	-- Числа
	{ "[^%a%d][%.%d]+[^%a%d]", "numbers", 1, 1 },
	{ "[^%a%d][%.%d]+$", "numbers", 1, 0 },
	{ "0x%w+", "numbers", 0, 0 },
	-- Сравнения и мат. операции
	{ "[%>%<%=%~%+%-%*%/%^%#%%%&]", "compares", 0, 0 },
	-- Конкатенация строк
	{ "[^%d]%.+[^%d]", "logic", 1, 1 },
	-- Логические выражения
	{ " not ", "logic", 0, 1 },
	{ " or ", "logic", 0, 1 },
	{ " and ", "logic", 0, 1 },
	--Функции
	{ "^[^%s%(%)%{%}%[%]]+%(", "functions", 0, 1 },
	{ "[%s%=%{%(][^%s%(%)%{%}%[%]]+%(", "functions", 1, 1 },
	-- Истина, ложь, нулл
	{ "nil", "boolean", 0, 0 },
	{ "false", "boolean", 0, 0 },
	{ "true", "boolean", 0, 0 },
	-- Циклы, условия и прочая поебень
	{ " break ", "loops", 0, 0 },
	{ " break$", "loops", 0, 0 },
	{ "elseif ", "loops", 0, 1 },
	{ "else[%s%;]", "loops", 0, 1 },
	{ "else$", "loops", 0, 0 },
	{ "function ", "loops", 0, 1 },
	{ "local ", "loops", 0, 1 },
	{ "return", "loops", 0, 0 },
	{ "until ", "loops", 0, 1 },
	{ "then", "loops", 0, 0 },
	{ "if ", "loops", 0, 1 },
	{ "repeat$", "loops", 0, 0 },
	{ " in ", "loops", 0, 1 },
	{ "for ", "loops", 0, 1 },
	{ "end[%s%;]", "loops", 0, 1 },
	{ "end$", "loops", 0, 0 },
	{ "do ", "loops", 0, 1 },
	{ "do$", "loops", 0, 0 },
	{ "while ", "loops", 0, 1 },
	-- Строки
	{ "\'[^\']+\'", "strings", 0, 0 },
	{ "\"[^\"]+\"", "strings", 0, 0 },
	-- Комментарии
	{ "%-%-.+", "comments", 0, 0 },
}

----------------------------------------------------------------------------------------------------------------------------------------

-- Отрисовка строки с подсвеченным синтаксисом
function syntax.highlightString(x, y, fromChar, limit, indentationWidth, s)
	fromChar = fromChar or 1
	
	local counter, symbols, colors, stringLength, bufferIndex, newFrameBackgrounds, newFrameForegrounds, newFrameSymbols, searchFrom, starting, ending = indentationWidth, {}, {}, unicodeLen(s), buffer.getIndex(x, y), buffer.getNewFrameTables()
	local toChar = math.min(stringLength, fromChar + limit - 1)

	for i = 1, stringLength do
		symbols[i] = unicodeSub(s, i, i)
	end

	for j = 1, #patterns do
		searchFrom = 1
		
		while true do
			starting, ending = unicodeFind(s, patterns[j][1], searchFrom)
			
			if starting then
				for i = starting + patterns[j][3], ending - patterns[j][4] do
					colors[i] = colorScheme[patterns[j][2]]
				end
			else
				break
			end

			searchFrom = ending + 1 - patterns[j][4]
		end
	end

	-- Ебошим индентейшны
	for i = fromChar, toChar do
		if symbols[i] == " " then
			colors[i] = colorScheme.indentation
			
			if counter == indentationWidth then
				symbols[i], counter = indentationSymbol, 0
			end

			counter = counter + 1
		else
			break
		end
	end

	-- А тута уже сам текст
	for i = fromChar, toChar do
		newFrameForegrounds[bufferIndex], newFrameSymbols[bufferIndex] = colors[i] or colorScheme.text, symbols[i] or " "
		bufferIndex = bufferIndex + 1
	end
end

function syntax.getColorScheme(t)
	return colorScheme
end

function syntax.setColorScheme(t)
	colorScheme = t
end

----------------------------------------------------------------------------------------------------------------

-- buffer.flush()
-- buffer.clear(0x1b1b1b)

-- buffer.square(5, 5, 30, 3, colorScheme.background, 0x0, " ")

-- local counter = 2
-- for line in io.lines("/g.lua") do
-- 	pcall(syntax.highlightString, 2, counter, 1, 160, 2, line)
	
-- 	counter = counter + 1
-- 	if counter > 50 then
-- 		break
-- 	end
-- end

-- buffer.draw(true)

----------------------------------------------------------------------------------------------------------------

return syntax




