local syntax = require("syntax")
local gpu = require("component").gpu
local buffer = require("doubleBuffering")
local unicode = require("unicode")

local codeViewer = {}

----------------------------------------------------------------------------------------------------------------------------------------

local colorSchemes = {
	midnight = {
		text = 0xFFFFFF,
		background = 0x262626,
		lineNumbers = 0x444444,
		lineNumbersText = 0xDDDDDD,
		scrollBar = 0x444444,
		scrollBarPipe = 0x24c0ff,
	},
}

local currentColorScheme = colorSchemes.midnight

----------------------------------------------------------------------------------------------------------------------------------------

local function loadFile(path)
	local array = {}
	local file = io.open(path, "r")
	for line in file:lines() do table.insert(array, line) end
	file:close()
	return array
end

function codeViewer.view(x, y, width, height, strings, fromString)
	local maximumNumberOfAvailableStrings
	if strings[fromString + height - 1] then
		maximumNumberOfAvailableStrings = fromString + height - 1
	else
		maximumNumberOfAvailableStrings = #strings
	end
	local widthOfStringCounter = unicode.len(maximumNumberOfAvailableStrings) + 2

	--Рисуем номера линий
	buffer.square(x, y, widthOfStringCounter, height, currentColorScheme.lineNumbers, 0xFFFFFF, " ")
	local yPos = y
	for i = fromString, maximumNumberOfAvailableStrings do
		buffer.text(x + widthOfStringCounter - unicode.len(i) - 1, yPos, currentColorScheme.text, tostring(i))
		yPos = yPos + 1
	end

	--Рисуем подложку под текст
	buffer.square(x + widthOfStringCounter, y, width - widthOfStringCounter, height, currentColorScheme.background, 0xFFFFFF, " ")
	--Рисуем текст
	local widthOfText = width - widthOfStringCounter - 3
	yPos = y
	for i = fromString, maximumNumberOfAvailableStrings do
		syntax.highlight(x + widthOfStringCounter + 1, yPos, strings[i], widthOfText)
		yPos = yPos + 1
	end
	--Скроллбар
	buffer.scrollBar(x + width - 1, y, 1, height, #strings, fromString, currentColorScheme.scrollBar, currentColorScheme.scrollBarPipe)

	buffer.draw()
end

----------------------------------------------------------------------------------------------------------------------------------------

-- local strings = loadFile("MineOS/Applications/Highlight.app/Resources/TestFile.txt")

-- local xSize, ySize = gpu.getResolution()
-- buffer.square(1, 1, xSize, ySize, ecs.colors.red, 0xFFFFFF, " ")
-- buffer.draw(true)
-- local fromString = 1
-- codeViewer.view(2, 2, 80, 26, strings, fromString)

-- while true do
-- 	local e = {event.pull()}
-- 	if e[1] == "key_down" then
-- 		if e[4] == 200 then
-- 			if fromString > 1 then fromString = fromString - 1; codeViewer.view(2, 2, 80, 26, strings, fromString) end
-- 		elseif e[4] == 208 then
-- 			if fromString < #strings then fromString = fromString + 1; codeViewer.view(2, 2, 80, 26, strings, fromString) w end
-- 		end
-- 	end
-- end

----------------------------------------------------------------------------------------------------------------------------------------

return codeViewer