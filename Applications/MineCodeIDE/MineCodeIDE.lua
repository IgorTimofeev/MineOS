
---------------------------------------------------- Libraries ----------------------------------------------------

-- package.loaded.syntax = nil
-- package.loaded.GUI = nil
-- package.loaded.windows = nil
-- package.loaded.MineOSCore = nil

require("advancedLua")
local fs = require("filesystem")
local buffer = require("doubleBuffering")
local GUI = require("GUI")
local windows = require("windows")
local MineOSCore = require("MineOSCore")
local event = require("event")
local syntax = require("syntax")
local unicode = require("unicode")
local keyboard = require("keyboard")

---------------------------------------------------- Constants ----------------------------------------------------

-- "/MineOS/Desktop/MineCode IDE.app/MineCode IDE.lua"

local clipboard
local cursor = {
	position = {
		symbol = 20,
		line = 8
	},
	color = 0x00A8FF,
	symbol = "┃",
	blinkDelay = 0.4,
	blinkState = false,
}

local mainWindow = {}
local config = {
	indentaionWidth = 2,
	colorScheme = {
		topToolBar = 0xBBBBBB,
		topMenu = {
			backgroundColor = 0xEEEEEE,
			textColor = 0x444444,
			backgroundPressedColor = 0x3366CC,
			textPressedColor = 0xFFFFFF,
		},
	},
	scrollSpeed = 8,
}

---------------------------------------------------- File processing methods ----------------------------------------------------

local function loadFile(path)
	mainWindow.codeView.fromLine, mainWindow.codeView.fromSymbol, mainWindow.codeView.lines, mainWindow.codeView.maximumLineLength = 1, 1, {}, 0
	local file = io.open(path, "r")
	for line in file:lines() do
		line = line:gsub("\t", string.rep(" ", config.indentaionWidth))
		table.insert(mainWindow.codeView.lines, line)
		mainWindow.codeView.maximumLineLength = math.max(mainWindow.codeView.maximumLineLength, unicode.len(line))
	end
	file:close()

	mainWindow.titleTextBox.lines = {
		"File: " .. path,
		"Cursor position: 1x1",
		"Zalupa, penis"
	}
end

---------------------------------------------------- Cursor methods ----------------------------------------------------

local function fixFromLineByCursorPosition()
	if mainWindow.codeView.fromLine > cursor.position.line then
		mainWindow.codeView.fromLine = cursor.position.line
	elseif mainWindow.codeView.fromLine + mainWindow.codeView.height - 2 < cursor.position.line then
		mainWindow.codeView.fromLine = cursor.position.line - mainWindow.codeView.height + 2
	end
end

local function fixFromSymbolByCursorPosition()
	if mainWindow.codeView.fromSymbol > cursor.position.symbol then
		mainWindow.codeView.fromSymbol = cursor.position.symbol
	elseif mainWindow.codeView.fromSymbol + mainWindow.codeView.codeAreaWidth - 3 < cursor.position.symbol then
		mainWindow.codeView.fromSymbol = cursor.position.symbol - mainWindow.codeView.codeAreaWidth + 3
	end
end

local function fixCursorPosition(symbol, line)
	if line < 1 then
		line = 1
	elseif line > #mainWindow.codeView.lines then
		line = #mainWindow.codeView.lines
	end

	local lineLength = unicode.len(mainWindow.codeView.lines[line])
	if symbol < 1 or lineLength == 0 then
		symbol = 1
	elseif symbol > lineLength then
		symbol = lineLength + 1
	end

	return symbol, line
end

local function setCursorPosition(symbol, line)
	cursor.position.symbol, cursor.position.line = fixCursorPosition(symbol, line)
	fixFromLineByCursorPosition()
	fixFromSymbolByCursorPosition()
end

local function convertScreenCoordinatesToCursorPosition(x, y)
	return x - mainWindow.codeView.codeAreaPosition + mainWindow.codeView.fromSymbol - 1, y - mainWindow.codeView.y + mainWindow.codeView.fromLine
end

local function clearSelection()
	mainWindow.codeView.selections[1] = nil
end

local function moveCursor(symbolOffset, lineOffset)
	local newSymbol, newLine = cursor.position.symbol + symbolOffset, cursor.position.line + lineOffset
	
	if newSymbol < 1 then
		newLine, newSymbol = newLine - 1, math.huge
	elseif newSymbol > unicode.len(mainWindow.codeView.lines[newLine] or "") + 1 then
		newLine, newSymbol = newLine + 1, 1
	end

	setCursorPosition(newSymbol, newLine)
end

---------------------------------------------------- Text processing methods ----------------------------------------------------

local function deleteLine(line)
	if #lines > 0 then
		table.remove(mainWindow.codeView.lines, line)
		setCursorPosition(1, cursor.position.line)
	end
end

local function deleteSpecifiedData(fromSymbol, fromLine, toSymbol, toLine)
	local upperLine = unicode.sub(mainWindow.codeView.lines[fromLine], 1, fromSymbol - 1)
	local lowerLine = unicode.sub(mainWindow.codeView.lines[toLine], toSymbol + 1, -1)
	for i = fromLine + 1, toLine do
		table.remove(mainWindow.codeView.lines, fromLine + 1)
	end
	mainWindow.codeView.lines[fromLine] = upperLine .. lowerLine
	setCursorPosition(fromSymbol, fromLine)
end

local function deleteSelectedData()
	if mainWindow.codeView.selections[1] then
		deleteSpecifiedData(
			mainWindow.codeView.selections[1].from.symbol,
			mainWindow.codeView.selections[1].from.line,
			mainWindow.codeView.selections[1].to.symbol,
			mainWindow.codeView.selections[1].to.line
		)
		clearSelection()
	end
end

local function copy()
	if mainWindow.codeView.selections[1] then
		if mainWindow.codeView.selections[1].to.line == mainWindow.codeView.selections[1].from.line then
			clipboard = { unicode.sub(mainWindow.codeView.lines[mainWindow.codeView.selections[1].from.line], mainWindow.codeView.selections[1].from.symbol, mainWindow.codeView.selections[1].to.symbol) }
		else
			clipboard = { unicode.sub(mainWindow.codeView.lines[mainWindow.codeView.selections[1].from.line], mainWindow.codeView.selections[1].from.symbol, -1) }
			for line = mainWindow.codeView.selections[1].from.line + 1, mainWindow.codeView.selections[1].to.line - 1 do
				table.insert(clipboard, mainWindow.codeView.lines[line])
			end
			table.insert(clipboard, unicode.sub(mainWindow.codeView.lines[mainWindow.codeView.selections[1].to.line], 1, mainWindow.codeView.selections[1].to.symbol))
		end
	end
end

local function cut()
	if mainWindow.codeView.selections[1] then
		copy()
		deleteSelectedData()
	end
end

local function paste(pasteLines)
	local firstPart = unicode.sub(mainWindow.codeView.lines[cursor.position.line], 1, cursor.position.symbol - 1)
	local secondPart = unicode.sub(mainWindow.codeView.lines[cursor.position.line], cursor.position.symbol, -1)

	if #pasteLines == 1 then
		mainWindow.codeView.lines[cursor.position.line] = firstPart .. pasteLines[1] .. secondPart
		setCursorPosition(cursor.position.symbol + unicode.len(pasteLines[1]), cursor.position.line)
	else
		local line = cursor.position.line
		mainWindow.codeView.lines[line] = firstPart .. pasteLines[1]
		line = line + 1
		for i = #pasteLines - 1, 2, -1 do
			table.insert(mainWindow.codeView.lines, line, pasteLines[i])
			line = line + 1
		end
		mainWindow.codeView.lines[line] = pasteLines[#pasteLines] .. secondPart
		setCursorPosition(unicode.len(pasteLines[#pasteLines]) + 1, cursor.position.line + #pasteLines - 1)
	end
end

local function backspace()
	if mainWindow.codeView.selections[1] then
		deleteSelectedData()
	else
		if cursor.position.symbol > 1 then
			deleteSpecifiedData(cursor.position.symbol - 1, cursor.position.line, cursor.position.symbol - 1, cursor.position.line)
		else
			deleteSpecifiedData(unicode.len(mainWindow.codeView.lines[cursor.position.line - 1]) + 1, cursor.position.line - 1, 0, cursor.position.line)
		end
	end
end

local function enter()
	local firstPart = unicode.sub(mainWindow.codeView.lines[cursor.position.line], 1, cursor.position.symbol - 1)
	local secondPart = unicode.sub(mainWindow.codeView.lines[cursor.position.line], cursor.position.symbol, -1)
	mainWindow.codeView.lines[cursor.position.line] = firstPart
	table.insert(mainWindow.codeView.lines, cursor.position.line + 1, secondPart)
	setCursorPosition(1, cursor.position.line + 1)
end

---------------------------------------------------- Text comments-related methods ----------------------------------------------------

local function isLineCommented(line)
	return mainWindow.codeView.lines[line]:match("%-%-[^%-]")
end

local function commentLine(line)
	mainWindow.codeView.lines[line] = "-- " .. mainWindow.codeView.lines[line]
end

local function uncommentLine(line)
	mainWindow.codeView.lines[line], countOfReplaces = mainWindow.codeView.lines[line]:gsub("%-%-%s", "", 1)
	return countOfReplaces
end

local function toggleComment()
	if mainWindow.codeView.selections[1] then
		local allLinesAreCommented = true
		
		for line = mainWindow.codeView.selections[1].from.line, mainWindow.codeView.selections[1].to.line do
			if not isLineCommented(line) then
				allLinesAreCommented = false
			end
		end
		
		for line = mainWindow.codeView.selections[1].from.line, mainWindow.codeView.selections[1].to.line do
			if allLinesAreCommented then
				uncommentLine(line)
			else
				commentLine(line)
			end
		end

		local modifyer = 3
		if allLinesAreCommented then
			modifyer = -3
		end
		setCursorPosition(cursor.position.symbol + modifyer, cursor.position.line)
		mainWindow.codeView.selections[1].from.symbol, mainWindow.codeView.selections[1].to.symbol = mainWindow.codeView.selections[1].from.symbol + modifyer, mainWindow.codeView.selections[1].to.symbol + modifyer
	else
		if isLineCommented(cursor.position.line) then
			if uncommentLine(cursor.position.line) > 0 then
				setCursorPosition(cursor.position.symbol - 3, cursor.position.line)
			end
		else
			commentLine(cursor.position.line)
			setCursorPosition(cursor.position.symbol + 3, cursor.position.line)
		end
	end
end

---------------------------------------------------- Text indentation-related methods ----------------------------------------------------

local function indentLine(line)
	mainWindow.codeView.lines[line] = string.rep(" ", config.indentaionWidth) .. mainWindow.codeView.lines[line]
end

local function unindentLine(line)
	mainWindow.codeView.lines[line], countOfReplaces = string.gsub(mainWindow.codeView.lines[line], "^" .. string.rep("%s", config.indentaionWidth), "")
	return countOfReplaces
end

local function indentOrUnindent(isIndent)
	if mainWindow.codeView.selections[1] then
		local countOfReplacesInFirstLine, countOfReplacesInLastLine
		
		for line = mainWindow.codeView.selections[1].from.line, mainWindow.codeView.selections[1].to.line do
			if isIndent then
				indentLine(line)
			else
				local countOfReplaces = unindentLine(line)
				if line == mainWindow.codeView.selections[1].from.line then
					countOfReplacesInFirstLine = countOfReplaces
				elseif line == mainWindow.codeView.selections[1].to.line then
					countOfReplacesInLastLine = countOfReplaces
				end
			end
		end		

		if isIndent then
			setCursorPosition(cursor.position.symbol + config.indentaionWidth, cursor.position.line)
			mainWindow.codeView.selections[1].from.symbol, mainWindow.codeView.selections[1].to.symbol = mainWindow.codeView.selections[1].from.symbol + config.indentaionWidth, mainWindow.codeView.selections[1].to.symbol + config.indentaionWidth
		else
			if countOfReplacesInFirstLine > 0 then
				mainWindow.codeView.selections[1].from.symbol = mainWindow.codeView.selections[1].from.symbol - config.indentaionWidth
				if cursor.position.line == mainWindow.codeView.selections[1].from.line then
					setCursorPosition(cursor.position.symbol - config.indentaionWidth, cursor.position.line)
				end
			end

			if countOfReplacesInLastLine > 0 then
				mainWindow.codeView.selections[1].to.symbol = mainWindow.codeView.selections[1].to.symbol - config.indentaionWidth
				if cursor.position.line == mainWindow.codeView.selections[1].to.line then
					setCursorPosition(cursor.position.symbol - config.indentaionWidth, cursor.position.line)
				end
			end
		end
	else
		if isIndent then
			indentLine(cursor.position.line)
			setCursorPosition(cursor.position.symbol + config.indentaionWidth, cursor.position.line)
		else
			if unindentLine(cursor.position.line) > 0 then
				setCursorPosition(cursor.position.symbol - config.indentaionWidth, cursor.position.line)
			end
		end
	end
end

---------------------------------------------------- Main window related methods ----------------------------------------------------

local function calculateSizes()
	if mainWindow.topToolBar.isHidden then
		mainWindow.codeView.localPosition.y = 2
	else
		mainWindow.codeView.localPosition.y = 5
		mainWindow.topToolBar.width = mainWindow.width
		mainWindow.topToolBar.backgroundPanel.width = mainWindow.width
		mainWindow.titleTextBox.width = mainWindow.topToolBar.width * 0.25 
		mainWindow.titleTextBox.localPosition.x = math.floor(mainWindow.topToolBar.width / 2 - mainWindow.titleTextBox.width / 2)
	end

	mainWindow.topMenu.width = mainWindow.width
	mainWindow.codeView.width, mainWindow.codeView.height = mainWindow.width, mainWindow.height - 4
end

local function createWindow()
	mainWindow = windows.fullScreen()

	mainWindow.codeView = mainWindow:addCodeView(1, 1, 1, 1, {}, 1, 1, 1, {}, {}, true)
	mainWindow.topMenu = mainWindow:addMenu(1, 1, 1, config.colorScheme.topMenu.backgroundColor, config.colorScheme.topMenu.textColor, config.colorScheme.topMenu.backgroundPressedColor, config.colorScheme.topMenu.textPressedColor)
	mainWindow.topMenu:addItem("MineCode", 0x0)
	mainWindow.topMenu:addItem("File")
	mainWindow.topMenu:addItem("View")
	mainWindow.topMenu:addItem("Properties")
	mainWindow.topToolBar = mainWindow:addContainer(1, 2, 1, 3)
	mainWindow.topToolBar.backgroundPanel = mainWindow.topToolBar:addPanel(1, 1, 1, 3, config.colorScheme.topToolBar)
	mainWindow.titleTextBox = mainWindow.topToolBar:addTextBox(1, 1, 1, 3, 0xDDDDDD, 0x444444, {}, 1):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	mainWindow.runButton = mainWindow.topToolBar:addAdaptiveButton(1, 1, 2, 1, 0x444444, 0xFFFFFF, 0xFFFFFF, 0x444444, "Run")
	mainWindow.runButton.onTouch = function()
		GUI.error("RUN ВАСЯ РАН")
	end
	mainWindow.toggleSyntaxHighlightingButton = mainWindow.topToolBar:addAdaptiveButton(8, 1, 2, 1, 0xDDDDDD, 0x262626, 0x262626, 0xDDDDDD, "Syntax")
	mainWindow.toggleSyntaxHighlightingButton.onTouch = function()
		mainWindow.codeView.highlightLuaSyntax = not mainWindow.codeView.highlightLuaSyntax
	end

	mainWindow.onAnyEvent = function(eventData)
		cursor.blinkState = not cursor.blinkState
		local oldCursorState = cursor.blinkState
		cursor.blinkState = true
			
		if eventData[1] == "touch" and mainWindow.codeView:isClicked(eventData[3], eventData[4]) then
			if eventData[5] == 1 then
				local menu = GUI.contextMenu(eventData[3], eventData[4])
				menu:addItem("Copy", false, "^C")
				menu:addItem("Paste", false, "^V")
				menu:addItem("Delete")
				menu:addSeparator()
				menu:addItem("Select all", false, "^A")
				menu:show()
			else
				clearSelection()
				setCursorPosition(convertScreenCoordinatesToCursorPosition(eventData[3], eventData[4]))
			end
		elseif eventData[1] == "drag" then
			if eventData[5] ~= 1 then
				mainWindow.codeView.selections[1] = mainWindow.codeView.selections[1] or {from = {}, to = {}}
				mainWindow.codeView.selections[1].from.symbol, mainWindow.codeView.selections[1].from.line = cursor.position.symbol, cursor.position.line
				mainWindow.codeView.selections[1].to.symbol, mainWindow.codeView.selections[1].to.line = fixCursorPosition(convertScreenCoordinatesToCursorPosition(eventData[3], eventData[4]))
				
				if mainWindow.codeView.selections[1].from.line > mainWindow.codeView.selections[1].to.line then
					mainWindow.codeView.selections[1].from.line, mainWindow.codeView.selections[1].to.line = swap(mainWindow.codeView.selections[1].from.line, mainWindow.codeView.selections[1].to.line)
					mainWindow.codeView.selections[1].from.symbol, mainWindow.codeView.selections[1].to.symbol = swap(mainWindow.codeView.selections[1].from.symbol, mainWindow.codeView.selections[1].to.symbol)
				end
			end
		elseif eventData[1] == "key_down" then
			-- Ctrl or CMD
			if keyboard.isKeyDown(29) or keyboard.isKeyDown(219) then
				-- Slash
				if eventData[4] == 53 then
					toggleComment()
				-- A
				elseif eventData[4] == 30 then
					mainWindow.codeView.selections[1] = {from = {}, to = {}}
					mainWindow.codeView.selections[1].from.symbol, mainWindow.codeView.selections[1].from.line = 1, 1
					mainWindow.codeView.selections[1].to.symbol, mainWindow.codeView.selections[1].to.line = unicode.len(mainWindow.codeView.lines[#mainWindow.codeView.lines]), #mainWindow.codeView.lines
				-- C
				elseif eventData[4] == 46 then
					copy()
				-- V
				elseif eventData[4] == 47 then
					paste(clipboard)
				-- X
				elseif eventData[4] == 45 then
					cut()
				-- W
				elseif eventData[4] == 17 then

				end
			-- Arrows up, down, left, right
			elseif eventData[4] == 200 then
				moveCursor(0, -1)
			elseif eventData[4] == 208 then
				moveCursor(0, 1)
			elseif eventData[4] == 203 then
				moveCursor(-1, 0)
			elseif eventData[4] == 205 then
				moveCursor(1, 0)
			-- Backspace
			elseif eventData[4] == 14 then
				backspace()
			-- Tab
			elseif eventData[4] == 15 then
				if keyboard.isKeyDown(42) then
					indentOrUnindent(false)
				else
					indentOrUnindent(true)
				end
			-- Enter
			elseif eventData[4] == 28 then
				enter()
			else
				if not keyboard.isControl(eventData[3]) then
					deleteSelectedData()
					paste({unicode.char(eventData[3])})
				end
			end
		elseif eventData[1] == "clipboard" then
			paste({eventData[3]})
		elseif eventData[1] == "scroll" then
			if mainWindow.codeView:isClicked(eventData[3], eventData[4]) then
				if eventData[5] == 1 then
					if mainWindow.codeView.fromLine > config.scrollSpeed then
						mainWindow.codeView.fromLine = mainWindow.codeView.fromLine - config.scrollSpeed
					else
						mainWindow.codeView.fromLine = 1
					end
				else
					if mainWindow.codeView.fromLine < #mainWindow.codeView.lines - config.scrollSpeed then
						mainWindow.codeView.fromLine = mainWindow.codeView.fromLine + config.scrollSpeed
					else
						mainWindow.codeView.fromLine = #mainWindow.codeView.lines
					end
				end
			end
		elseif not eventData[1] then
			cursor.blinkState = oldCursorState
		end

		mainWindow:draw()
		if cursor.blinkState then
			local x, y = mainWindow.codeView.codeAreaPosition + cursor.position.symbol - mainWindow.codeView.fromSymbol + 1, mainWindow.codeView.y + cursor.position.line - mainWindow.codeView.fromLine
			if 
				x >= mainWindow.codeView.codeAreaPosition + 1 and
				x <= mainWindow.codeView.codeAreaPosition + mainWindow.codeView.codeAreaWidth - 2 and
				y >= mainWindow.codeView.y and
				y <= mainWindow.codeView.y + mainWindow.codeView.height - 2
			then
				buffer.text(x, y, cursor.color, cursor.symbol)
			end
		end
		buffer.draw()
	end
end

-----------------------------------------------------------------------------------------------------------------------------

buffer.start()

createWindow()
calculateSizes()
loadFile("/OS.lua")

mainWindow.drawShadow = true
mainWindow:draw()
buffer.draw()
mainWindow.drawShadow = false
setCursorPosition(1, 1)
mainWindow:handleEvents(cursor.blinkDelay)


