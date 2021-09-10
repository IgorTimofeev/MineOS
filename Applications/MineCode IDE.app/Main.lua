
local filesystem = require("Filesystem")
local screen = require("Screen")
local event = require("Event")
local keyboard = require("Keyboard")
local GUI = require("GUI")
local internet = require("Internet")
local system = require("System")
local paths = require("Paths")
local text = require("Text")
local number = require("Number")

------------------------------------------------------------

local config = {
	leftTreeViewWidth = 23,
	syntaxColorScheme = GUI.LUA_SYNTAX_COLOR_SCHEME,
	scrollSpeed = 8,
	cursorColor = 0x00A8FF,
	cursorSymbol = "┃",
	cursorBlinkDelay = 0.5,
	doubleClickDelay = 0.4,
	enableAutoBrackets = true,
	syntaxHighlight = true,
	enableAutocompletion = true,
	linesToShowOpenProgress = 150,
}

local openBrackets = {
	["{"] = "}",
	["["] = "]",
	["("] = ")",
	["\""] = "\"",
	["\'"] = "\'"
}

local closeBrackets = {
	["}"] = "{",
	["]"] = "[",
	[")"] = "(",
	["\""] = "\"",
	["\'"] = "\'"
}

local luaKeywords = {
	["do"] = true,
	["local"] = true,
	["return"] = true,
	["while"] = true,
	["repeat"] = true,
	["until"] = true,
	["for"] = true,
	["in"] = true,
	["if"] = true,
	["then"] = true,
	["else"] = true,
	["elseif"] = true,
	["end"] = true,
	["function"] = true,
	["true"] = true,
	["false"] = true,
	["nil"] = true,
	["not"] = true,
	["and"] = true,
	["or" ] = true,
}

local lines = {""}
local cursorPositionSymbol = 1
local cursorPositionLine = 1
local cursorBlinkState = false

local saveContextMenuItem 
local cursorUptime = computer.uptime()
local scriptCoroutine
local currentScriptDirectory = filesystem.path(system.getCurrentScript())
local configPath = paths.user.applicationData .. "MineCode IDE/Config9.cfg"
local localization = system.getLocalization(currentScriptDirectory .. "Localizations/")
local findStartFrom
local clipboard
local breakpointLines
local lastErrorLine
local autocompleteDatabase
local autoCompleteWordStart, autoCompleteWordEnd
local continue, showBreakpointMessage, showTip

------------------------------------------------------------

if filesystem.exists(configPath) then
	config = filesystem.readTable(configPath)
end

local workspace, window, menu = system.addWindow(GUI.window(1, 1, 120, 30))
menu:removeChildren()

local codeView = window:addChild(GUI.codeView(1, 1, 1, 1, 1, 1, 1, {}, {}, GUI.LUA_SYNTAX_PATTERNS, config.syntaxColorScheme, config.syntaxHighlight, lines))

local function convertScreenCoordinatesToTextPosition(x, y)
	return
		x - codeView.codeAreaPosition + codeView.fromSymbol - 1,
		y - codeView.y + codeView.fromLine
end

local overrideCodeViewDraw = codeView.draw
codeView.draw = function(...)
	overrideCodeViewDraw(...)

	if cursorBlinkState and GUI.focusedObject == window then
		local x, y = codeView.codeAreaPosition + cursorPositionSymbol - codeView.fromSymbol + 1, codeView.y + cursorPositionLine - codeView.fromLine
		if
			x >= codeView.codeAreaPosition + 1 and
			y >= codeView.y and
			x <= codeView.codeAreaPosition + codeView.codeAreaWidth - 2 and
			y <= codeView.y + codeView.height - (codeView.horizontalScrollBar.hidden and 1 or 2)
		then
			screen.drawText(x, y, config.cursorColor, config.cursorSymbol)
		end
	end
end

local function saveConfig()
	filesystem.writeTable(configPath, config)
end

local topToolBar = window:addChild(GUI.container(1, 1, 1, 3))
local topToolBarPanel = topToolBar:addChild(GUI.panel(1, 1, 1, 3, 0xE1E1E1))

local topLayout = topToolBar:addChild(GUI.layout(1, 1, 1, 3, 1, 1))
topLayout:setDirection(1, 1, GUI.DIRECTION_HORIZONTAL)
topLayout:setSpacing(1, 1, 2)
topLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)

local autocomplete = window:addChild(GUI.autoComplete(1, 1, 36, 7, 0xE1E1E1, 0xA5A5A5, 0x3C3C3C, 0x3C3C3C, 0xA5A5A5, 0xE1E1E1, 0xC3C3C3, 0x4B4B4B))

local addBreakpointButton = topLayout:addChild(GUI.adaptiveButton(1, 1, 3, 1, 0x878787, 0xE1E1E1, 0xD2D2D2, 0x4B4B4B, "x"))

local syntaxHighlightingButton = topLayout:addChild(GUI.adaptiveButton(1, 1, 3, 1, 0xD2D2D2, 0x4B4B4B, 0x696969, 0xE1E1E1, "◈"))
syntaxHighlightingButton.switchMode = true
syntaxHighlightingButton.pressed = codeView.syntaxHighlight

local runButton = topLayout:addChild(GUI.adaptiveButton(1, 1, 3, 1, 0x4B4B4B, 0xE1E1E1, 0xD2D2D2, 0x4B4B4B, "▷"))

local title = topLayout:addChild(GUI.object(1, 1, 1, 3))
local titleLines = {}
local titleDebugMode = false
title.eventHandler = nil
title.draw = function()	
	local sides = titleDebugMode and 0xCC4940 or 0x5A5A5A
	screen.drawRectangle(title.x, title.y, 1, title.height, sides, 0x0, " ")
	screen.drawRectangle(title.x + title.width - 1, title.y, 1, title.height, sides, 0x0, " ")
	screen.drawRectangle(title.x + 1, title.y, title.width - 2, 3, titleDebugMode and 0x880000 or 0x3C3C3C, 0x969696, " ")

	if titleDebugMode then
		local text = lastErrorLine and localization.runtimeError or localization.debugging .. (_G.MineCodeIDEDebugInfo and _G.MineCodeIDEDebugInfo.line or "N/A")
		screen.drawText(math.floor(title.x + title.width / 2 - unicode.len(text) / 2), title.y + 1, 0xE1E1E1, text)
	else
		for i = 1, #titleLines do
			screen.drawText(math.floor(title.x + title.width / 2 - unicode.len(titleLines[i]) / 2), title.y + i - 1, 0x969696, titleLines[i])
		end
	end
end

local toggleLeftToolBarButton = topLayout:addChild(GUI.adaptiveButton(1, 1, 3, 1, 0xD2D2D2, 0x4B4B4B, 0x4B4B4B, 0xE1E1E1, "⇦"))
toggleLeftToolBarButton.switchMode, toggleLeftToolBarButton.pressed = true, true

local toggleBottomToolBarButton = topLayout:addChild(GUI.adaptiveButton(1, 1, 3, 1, 0xD2D2D2, 0x4B4B4B, 0x696969, 0xE1E1E1, "⇩"))
toggleBottomToolBarButton.switchMode, toggleBottomToolBarButton.pressed = true, false

local toggleTopToolBarButton = topLayout:addChild(GUI.adaptiveButton(1, 1, 3, 1, 0xD2D2D2, 0x4B4B4B, 0x878787, 0xE1E1E1, "⇧"))
toggleTopToolBarButton.switchMode, toggleTopToolBarButton.pressed = true, true

local actionButtons = window:addChild(GUI.actionButtons(2, 2, true))
actionButtons.close.onTouch = function()
	window:remove()
end
actionButtons.maximize.onTouch = function()
	window:maximize()
end
actionButtons.minimize.onTouch = function()
	window:minimize()
end

local bottomToolBar = window:addChild(GUI.container(1, 1, 1, 3))
bottomToolBar.hidden = true

local caseSensitiveButton = bottomToolBar:addChild(GUI.adaptiveButton(1, 1, 2, 1, 0x3C3C3C, 0xE1E1E1, 0xB4B4B4, 0x2D2D2D, "Aa"))
caseSensitiveButton.switchMode = true

local searchInput = bottomToolBar:addChild(GUI.input(7, 1, 10, 3, 0xE1E1E1, 0x969696, 0x969696, 0xE1E1E1, 0x2D2D2D, "", localization.findSomeShit))

local searchButton = bottomToolBar:addChild(GUI.adaptiveButton(1, 1, 3, 1, 0x3C3C3C, 0xE1E1E1, 0xB4B4B4, 0x2D2D2D, localization.find))

local leftTreeView = window:addChild(GUI.filesystemTree(1, 1, config.leftTreeViewWidth, 1, 0xD2D2D2, 0x3C3C3C, 0x3C3C3C, 0x969696, 0x3C3C3C, 0xE1E1E1, 0xB4B4B4, 0xA5A5A5, 0xB4B4B4, 0x4B4B4B, GUI.IO_MODE_BOTH, GUI.IO_MODE_FILE))

local leftTreeViewResizer = window:addChild(GUI.resizer(1, 1, 3, 5, 0x696969, 0x0))

local function updateHighlights()
	codeView.highlights = {}

	if breakpointLines then
		for i = 1, #breakpointLines do
			codeView.highlights[breakpointLines[i]] = 0x990000
		end
	end

	if lastErrorLine then
		codeView.highlights[lastErrorLine] = 0xFF4940
	end
end

local function updateTitle()
	if not topToolBar.hidden then
		titleLines[1] = text.limit(leftTreeView.selectedItem or "...", title.width - 4, "left")
		titleLines[2] = text.limit(localization.cursor .. math.floor(cursorPositionLine) .. localization.line .. math.floor(cursorPositionSymbol) .. localization.symbol, title.width - 4)
		
		if codeView.selections[1] then
			local countOfSelectedLines, countOfSelectedSymbols = codeView.selections[1].to.line - codeView.selections[1].from.line + 1
			
			if codeView.selections[1].from.line == codeView.selections[1].to.line then
				countOfSelectedSymbols = unicode.len(unicode.sub(lines[codeView.selections[1].from.line], codeView.selections[1].from.symbol, codeView.selections[1].to.symbol))
			else
				countOfSelectedSymbols = unicode.len(unicode.sub(lines[codeView.selections[1].from.line], codeView.selections[1].from.symbol, -1))
				
				for line = codeView.selections[1].from.line + 1, codeView.selections[1].to.line - 1 do
					countOfSelectedSymbols = countOfSelectedSymbols + unicode.len(lines[line])
				end
				
				countOfSelectedSymbols = countOfSelectedSymbols + unicode.len(unicode.sub(lines[codeView.selections[1].to.line], 1, codeView.selections[1].to.symbol))
			end

			titleLines[3] = text.limit(localization.selection .. math.floor(countOfSelectedLines) .. localization.lines .. math.floor(countOfSelectedSymbols) .. localization.symbols, title.width - 4)
		else
			titleLines[3] = text.limit(localization.selection .. localization.none, title.width - 4)
		end
	end
end

local function tick(state)
	cursorBlinkState = state
	updateTitle()
	workspace:draw()

	cursorUptime = computer.uptime()
end

local function clearAutocompleteDatabaseFromLine(line)
	for word in lines[line]:gmatch("[%a%d%_]+") do
		if not word:match("^%d+$") then
			autocompleteDatabase[word] = (autocompleteDatabase[word] or 0) - 1
			if autocompleteDatabase[word] < 1 then
				autocompleteDatabase[word] = nil
			end
		end
	end
end

local function updateAutocompleteDatabaseFromLine(line)
	for word in lines[line]:gmatch("[%a%d%_]+") do
		if not word:match("^%d+$") then
			autocompleteDatabase[word] = (autocompleteDatabase[word] or 0) + 1
		end
	end
end

local function updateAutocompleteDatabaseFromAllLines()
	if config.enableAutocompletion then
		autocompleteDatabase = {}
		for line = 1, #lines do
			updateAutocompleteDatabaseFromLine(line)
		end
	end
end

local function getautoCompleteWordStartAndEnding(fromSymbol)
	local shittySymbolsRegexp, from, to = "[%s%c%p]"

	for i = fromSymbol, 1, -1 do
		if unicode.sub(lines[cursorPositionLine], i, i):match(shittySymbolsRegexp) then break end
		from = i
	end

	for i = fromSymbol, unicode.len(lines[cursorPositionLine]) do
		if unicode.sub(lines[cursorPositionLine], i, i):match(shittySymbolsRegexp) then break end
		to = i
	end

	return from, to
end

local function aplhabeticalSort(t)
	table.sort(t, function(a, b) return a[1] < b[1] end)
end

local function showAutocomplete()
	if config.enableAutocompletion then
		autoCompleteWordStart, autoCompleteWordEnd = getautoCompleteWordStartAndEnding(cursorPositionSymbol - 1)
		if autoCompleteWordStart then
			local word = unicode.sub(lines[cursorPositionLine], autoCompleteWordStart, autoCompleteWordEnd)
			if not luaKeywords[word] then
				autocomplete:match(autocompleteDatabase, word, true)

				if #autocomplete.items > 0 then
					autocomplete.fromItem, autocomplete.selectedItem = 1, 1
					autocomplete.localX = codeView.localX + codeView.lineNumbersWidth + autoCompleteWordStart - codeView.fromSymbol
					autocomplete.localY = codeView.localY + cursorPositionLine - codeView.fromLine + 1
					autocomplete.hidden = false
				end
			end
		end
	end
end

local function toggleEnableAutocompleteDatabase()
	config.enableAutocompletion = not config.enableAutocompletion
	autocompleteDatabase = {}
	saveConfig()
end

local function calculateSizes()
	if leftTreeView.hidden then
		codeView.localX, codeView.width = 1, window.width
		bottomToolBar.localX, bottomToolBar.width = codeView.localX, codeView.width
	else
		codeView.localX, codeView.width = leftTreeView.width + 1, window.width - leftTreeView.width
		bottomToolBar.localX, bottomToolBar.width = codeView.localX, codeView.width
	end

	if topToolBar.hidden then
		leftTreeView.localY, leftTreeView.height = 1, window.height
		codeView.localY, codeView.height = 1, window.height
	else
		leftTreeView.localY, leftTreeView.height = 4, window.height - 3
		codeView.localY, codeView.height = 4, window.height - 3
	end

	if not bottomToolBar.hidden then
		codeView.height = codeView.height - 3
	end

	leftTreeViewResizer.localX = leftTreeView.width
	leftTreeViewResizer.localY = math.floor(leftTreeView.localY + leftTreeView.height / 2 - leftTreeViewResizer.height / 2)

	bottomToolBar.localY = window.height - 2
	searchButton.localX = bottomToolBar.width - searchButton.width + 1
	searchInput.width = bottomToolBar.width - searchInput.localX - searchButton.width + 1

	topToolBar.width, topToolBarPanel.width, topLayout.width = window.width, window.width, window.width
	title.width = math.floor(topToolBar.width * 0.32)

	-- topMenu.width = window.width
end

local function gotoLine(line)
	codeView.fromLine = math.ceil(line - codeView.height / 2)
	if codeView.fromLine < 1 then
		codeView.fromLine = 1
	elseif codeView.fromLine > #lines then
		codeView.fromLine = #lines
	end
end

local function clearSelection()
	codeView.selections[1] = nil
end

local function clearBreakpoints()
	breakpointLines = nil
	updateHighlights()
end

local function addBreakpoint()
	breakpointLines = breakpointLines or {}
	
	local lineExists
	for i = 1, #breakpointLines do
		if breakpointLines[i] == cursorPositionLine then
			lineExists = i
			break
		end
	end
	
	if lineExists then
		table.remove(breakpointLines, lineExists)
	else
		table.insert(breakpointLines, cursorPositionLine)
	end

	if #breakpointLines > 0 then
		table.sort(breakpointLines, function(a, b) return a < b end)
	else
		breakpointLines = nil
	end

	updateHighlights()
end

local function fixFromLineByCursorPosition()
	local offset = codeView.horizontalScrollBar.hidden and 1 or 2
	if codeView.fromLine > cursorPositionLine then
		codeView.fromLine = cursorPositionLine
	elseif codeView.fromLine + codeView.height - offset < cursorPositionLine then
		codeView.fromLine = cursorPositionLine - codeView.height + offset
	end
end

local function fixFromSymbolByCursorPosition()
	if codeView.fromSymbol > cursorPositionSymbol then
		codeView.fromSymbol = cursorPositionSymbol
	elseif codeView.fromSymbol + codeView.codeAreaWidth - 3 < cursorPositionSymbol then
		codeView.fromSymbol = cursorPositionSymbol - codeView.codeAreaWidth + 3
	end
end

local function fixCursorPosition(symbol, line)
	if line < 1 then
		line = 1
	elseif line > #lines then
		line = #lines
	end

	local lineLength = unicode.len(lines[line])
	if symbol < 1 or lineLength == 0 then
		symbol = 1
	elseif symbol > lineLength then
		symbol = lineLength + 1
	end

	return math.floor(symbol), math.floor(line)
end

local function setCursorPosition(symbol, line)
	cursorPositionSymbol, cursorPositionLine = fixCursorPosition(symbol, line)
	fixFromLineByCursorPosition()
	fixFromSymbolByCursorPosition()
	autocomplete.hidden = true
end

local function setCursorPositionAndClearSelection(symbol, line)
	setCursorPosition(symbol, line)
	clearSelection()
end

local function moveCursor(symbolOffset, lineOffset, ignoreHidden)
	if autocomplete.hidden or ignoreHidden then
		if codeView.selections[1] then
			if symbolOffset < 0 or lineOffset < 0 then
				setCursorPositionAndClearSelection(codeView.selections[1].from.symbol, codeView.selections[1].from.line)
			else
				setCursorPositionAndClearSelection(codeView.selections[1].to.symbol, codeView.selections[1].to.line)
			end
		else
			local newSymbol, newLine = cursorPositionSymbol + symbolOffset, cursorPositionLine + lineOffset
			
			if symbolOffset < 0 and newSymbol < 1 then
				newLine, newSymbol = newLine - 1, math.huge
			elseif symbolOffset > 0 and newSymbol > unicode.len(lines[newLine] or "") + 1 then
				newLine, newSymbol = newLine + 1, 1
			end

			setCursorPosition(newSymbol, newLine)
		end
	end
end

local function setCursorPositionToHome()
	setCursorPositionAndClearSelection(1, 1)
end

local function setCursorPositionToEnd()
	setCursorPositionAndClearSelection(unicode.len(lines[#lines]) + 1, #lines)
end

local function scroll(direction, speed)
	if direction == 1 then
		if codeView.fromLine > speed then
			codeView.fromLine = codeView.fromLine - speed
		else
			codeView.fromLine = 1
		end
	else
		if codeView.fromLine < #lines - speed then
			codeView.fromLine = codeView.fromLine + speed
		else
			codeView.fromLine = #lines
		end
	end
end

local function pageUp()
	scroll(1, codeView.height - 2)
end

local function pageDown()
	scroll(-1, codeView.height - 2)
end

local function selectWord()
	local from, to = getautoCompleteWordStartAndEnding(cursorPositionSymbol)
	if from and to then
		codeView.selections[1] = {
			from = {symbol = from, line = cursorPositionLine},
			to = {symbol = to, line = cursorPositionLine},
		}
		cursorPositionSymbol = to
	end
end

local function optimizeString(s)
	return s:gsub("\t", string.rep(" ", codeView.indentationWidth)):gsub("\r\n", "\n")
end

local function addBackgroundContainer(title)
	return GUI.addBackgroundContainer(workspace, true, true, title)
end

local function addInputFadeContainer(title, placeholder)
	local container = addBackgroundContainer(title)
	container.input = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xC3C3C3, 0x787878, 0x787878, 0xC3C3C3, 0x2D2D2D, "", placeholder))

	return container
end

local function newFile()
	autocompleteDatabase = {}
	lines = {""}
	codeView.lines = lines
	codeView.maximumLineLength = 1
	leftTreeView.selectedItem = nil
	setCursorPositionAndClearSelection(1, 1)
	clearBreakpoints()
	updateTitle()
end

local function openFile(path)
	local file, reason = filesystem.open(path, "r")

	if file then
		newFile()

		leftTreeView.selectedItem = path
		codeView.hidden = true

		local container = window:addChild(GUI.container(codeView.localX, codeView.localY, codeView.width, codeView.height))
		container:addChild(GUI.panel(1, 1, container.width, container.height, 0x1E1E1E))
		
		local layout = container:addChild(GUI.layout(1, 1, container.width, container.height, 1, 1))
		
		layout:addChild(GUI.label(1, 1, layout.width, 1, 0xD2D2D2, localization.openingFile .. " " .. path):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP))
		local progressBar = layout:addChild(GUI.progressBar(1, 1, 36, 0x969696, 0x2D2D2D, 0x787878, 0, true, true, "", "%"))

		local counter, currentSize, totalSize = 1, 0, filesystem.size(path)
		for line in file:lines() do
			counter, currentSize = counter + 1, currentSize + #line + 1

			line = optimizeString(line)
			table.insert(lines, line)
			codeView.maximumLineLength = math.max(codeView.maximumLineLength, unicode.len(line))
			
			if counter % config.linesToShowOpenProgress == 0 then
				progressBar.value = math.floor(currentSize / totalSize * 100)
				computer.pullSignal(0)
				workspace:draw()
			end
		end

		file:close()

		if counter > config.linesToShowOpenProgress then
			progressBar.value = 100
			workspace:draw()
		end

		if #lines > 1 then
			table.remove(lines, 1)
		end

		codeView.hidden = false
		container:remove()
		updateAutocompleteDatabaseFromAllLines()
		updateTitle()
		saveContextMenuItem.disabled = false
	else
		GUI.alert(reason)
	end
end

local function saveFile(path)
	filesystem.makeDirectory(filesystem.path(path))
	local file, reason = filesystem.open(path, "w")
	if file then
		for line = 1, #lines do
			file:write(lines[line], "\n")
		end
		file:close()

		saveContextMenuItem.disabled = false
	else
		GUI.alert("Failed to open file for writing: " .. tostring(reason))
	end
end

local function gotoLineWindow()
	local container = addInputFadeContainer(localization.gotoLine, localization.lineNumber)

	container.input.onInputFinished = function()
		if container.input.text:match("%d+") then
			gotoLine(tonumber(container.input.text))
			container:remove()
			workspace:draw()
		end
	end

	workspace:draw()
end

local function openFileWindow()
	local filesystemDialog = GUI.addFilesystemDialog(workspace, true, 50, math.floor(window.height * 0.8), "Open", "Cancel", "File name", "/")
	filesystemDialog:setMode(GUI.IO_MODE_OPEN, GUI.IO_MODE_FILE)
	filesystemDialog.onSubmit = function(path)
		openFile(path)
		workspace:draw()
	end
	filesystemDialog:show()
end

local function saveFileAsWindow()
	local filesystemDialog = GUI.addFilesystemDialog(workspace, true, 50, math.floor(window.height * 0.8), "Save", "Cancel", "File name", "/")
	filesystemDialog:setMode(GUI.IO_MODE_SAVE, GUI.IO_MODE_FILE)
	filesystemDialog.onSubmit = function(path)
		saveFile(path)
		leftTreeView:updateFileList()
		leftTreeView.selectedItem = (leftTreeView.workPath .. path):gsub("/+", "/")

		updateTitle()
		workspace:draw()
	end
	filesystemDialog:show()
end

local function saveFileWindow()
	saveFile(leftTreeView.selectedItem)
	leftTreeView:updateFileList()
end

local function splitStringIntoLines(s)
	s = optimizeString(s)

	local lines, index, maximumLineLength, starting = {s}, 1, 0
	repeat
		starting = lines[index]:find("\n")
		if starting then
			table.insert(lines, lines[index]:sub(starting + 1, -1))
			lines[index] = lines[index]:sub(1, starting - 1)
			maximumLineLength = math.max(maximumLineLength, unicode.len(lines[index]))

			index = index + 1
		end
	until not starting

	return lines, maximumLineLength
end

local function downloadFileFromWeb()
	local container = addInputFadeContainer(localization.getFromWeb, localization.url)
	
	container.input.onInputFinished = function()
		if #container.input.text > 0 then
			container.input:remove()
			container.layout:addChild(GUI.text(1, 1, 0x969696, localization.downloading))
			workspace:draw()

			local result, reason = internet.request(container.input.text)
			if result then
				newFile()
				lines, codeView.maximumLineLength = splitStringIntoLines(result)
				codeView.lines = lines
				updateAutocompleteDatabaseFromAllLines()
			else
				GUI.alert("Failed to connect to URL: " .. tostring(reason))
			end
		end

		container:remove()
		workspace:draw()
	end

	workspace:draw()
end

local function getVariables(codePart)
	local variables = {}
	-- Сначала мы проверяем участок кода на наличие комментариев
	if
		not codePart:match("^%-%-") and
		not codePart:match("^[\t%s]+%-%-")
	then
		-- Затем заменяем все строковые куски в участке кода на "ничего", чтобы наш "прекрасный" парсер не искал переменных в строках
		codePart = codePart:gsub("\"[^\"]+\"", "")
		-- Потом разбиваем код на отдельные буквенно-цифровые слова, не забыв точечку с двоеточием
		for word in codePart:gmatch("[%a%d%.%:%_]+") do
			-- Далее проверяем, не совпадает ли это слово с одним из луа-шаблонов, то бишь, не является ли оно частью синтаксиса
			if
				not luaKeywords[word] and
				-- Также проверяем, не число ли это в чистом виде
				not word:match("^[%d%.]+$") and
				not word:match("^0x%x+$") and
				-- Или символ конкатенации, например
				not word:match("^%.+$")
			then
				variables[word] = true
			end
		end
	end

	return variables
end

continue = function(...)
	-- Готовим экран к запуску
	local oldResolutionX, oldResolutionY = screen.getResolution()
	
	-- Запускаем
	_G.MineCodeIDEDebugInfo = nil
	local coroutineResumeSuccess, coroutineResumeReason = coroutine.resume(scriptCoroutine, ...)

	-- Анализируем результат запуска
	if coroutineResumeSuccess then
		if coroutine.status(scriptCoroutine) == "dead" then
			screen.setResolution(oldResolutionX, oldResolutionY)
			workspace:draw(true)
		else
			-- Тест на пидора, мало ли у чувака в проге тоже есть yield
			if _G.MineCodeIDEDebugInfo then
				screen.setResolution(oldResolutionX, oldResolutionY)
				workspace:draw(true)
				gotoLine(_G.MineCodeIDEDebugInfo.line)
				showBreakpointMessage(_G.MineCodeIDEDebugInfo.variables)
			end
		end
	else
		screen.setResolution(oldResolutionX, oldResolutionY)
		showTip(debug.traceback(scriptCoroutine, coroutineResumeReason), "%:(%d+)%: in main chunk", true, true)
	end
end

local function run(...)
	-- Инсертим брейкпоинты
	if breakpointLines then
		local offset = 0
		for i = 1, #breakpointLines do
			local variables = getVariables(lines[breakpointLines[i] + offset])
			
			local breakpointMessage = "_G.MineCodeIDEDebugInfo = {variables = {"
			for variable in pairs(variables) do
				breakpointMessage = breakpointMessage .. "[\"" .. variable .. "\"] = type(" .. variable .. ") == 'string' and '\"' .. " .. variable .. " .. '\"' or tostring(" .. variable .. "), "
			end
			breakpointMessage =  breakpointMessage .. "}, line = " .. breakpointLines[i] .. "}; coroutine.yield()"

			table.insert(lines, breakpointLines[i] + offset, breakpointMessage)
			offset = offset + 1
		end
	end

	-- Лоадим кодыч
	local loadSuccess, loadReason = load(table.concat(lines, "\n"), leftTreeView.selectedItem and ("=" .. leftTreeView.selectedItem))
	
	-- Чистим дерьмо вилочкой, чистим
	if breakpointLines then
		for i = 1, #breakpointLines do
			table.remove(lines, breakpointLines[i])
		end
	end

	-- Запускаем кодыч
	if loadSuccess then
		scriptCoroutine = coroutine.create(loadSuccess)
		continue(...)
	else
		showTip(loadReason, "%:(%d+)%:", true)
	end
end

local function zalupa()
	local container = window:addChild(GUI.container(1, 1, window.width, window.height))

	container.close = function()
		lastErrorLine = nil
		titleDebugMode = false
		updateHighlights()
		
		container:remove()
		workspace:draw()
	end

	container:addChild(GUI.object(1, 1, window.width, window.height)).eventHandler = function(workspace, object, e1)
		if e1 == "touch" or e1 == "key_down" then
			container.close()
		end
	end

	return container
end

showTip = function(errorCode, matchCode, beep, force)
	-- Извлекаем ошибочную строку текущего скрипта
	lastErrorLine = tonumber(errorCode:match(matchCode))
	if lastErrorLine then
		-- Делаем поправку на количество брейкпоинтов в виде вставленных дебаг-строк
		if breakpointLines then
			local countOfBreakpointsBeforeLastErrorLine = 0
			for i = 1, #breakpointLines do
				if breakpointLines[i] < lastErrorLine then
					countOfBreakpointsBeforeLastErrorLine = countOfBreakpointsBeforeLastErrorLine + 1
				else
					break
				end
			end
		
			lastErrorLine = lastErrorLine - countOfBreakpointsBeforeLastErrorLine
		end

		gotoLine(lastErrorLine)
	end

	updateHighlights()

	local container = zalupa()
	local tip, tipLines = container:addChild(GUI.object(1, 1, 40))

	tip.passScreenEvents = true
	tip.draw = function()
		screen.drawText(math.floor(tip.x + tip.width / 2 - 1), tip.y, 0xE1E1E1, "◢◣")
		screen.drawRectangle(tip.x, tip.y + 1, tip.width, tip.height - 1, 0xE1E1E1, 0x2D2D2D, " ")
		for i = 1, #tipLines do
			screen.drawText(tip.x + 1, tip.y + i + 1, 0x2D2D2D, tipLines[i])
		end
	end

	tipLines = text.wrap(errorCode, tip.width - 2)
	tip.height = #tipLines + 3

	local minX = codeView.localX + codeView.codeAreaPosition - codeView.x
	local maxX = minX + codeView.width - tip.width - 5

	tip.localX = math.min(maxX, math.max(minX + 1, number.round(minX + unicode.len(lines[lastErrorLine]) / 2 - tip.width / 2)))
	tip.localY = codeView.localY + lastErrorLine - codeView.fromLine + 1

	workspace:draw(force)

	if beep then
		computer.beep(1500, 0.08)
	end
end

showBreakpointMessage = function(variables)
	local lines = {}
	
	for variable, value in pairs(variables) do
		table.insert(lines, variable .. " = " .. value)
	end

	if #lines > 0 then
		table.insert(lines, 1, {text = localization.variables, color = 0x0})
		table.insert(lines, 2, " ")
	else
		table.insert(lines, 1, {text = localization.variablesNotAvailable, color = 0x0})
	end

	local container = zalupa()
	local errorContainer = container:addChild(GUI.container(title.localX, topToolBar.hidden and 1 or 4, title.width, #lines + 3))
	local panel = errorContainer:addChild(GUI.panel(1, 1, errorContainer.width, errorContainer.height, 0xE1E1E1))
	local textBox = errorContainer:addChild(GUI.textBox(3, 2, errorContainer.width - 4, #lines, nil, 0x4B4B4B, lines, 1))
	textBox:setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)

	local exitButton = errorContainer:addChild(GUI.button(1, errorContainer.height, math.floor(errorContainer.width / 2), 1, 0x3C3C3C, 0xC3C3C3, 0x2D2D2D, 0x878787, localization.finishDebug))
	exitButton.animated = false
	exitButton.onTouch = function()
		scriptCoroutine = nil
		container.close()
	end
	
	local continueButton = errorContainer:addChild(GUI.button(exitButton.width + 1, exitButton.localY, errorContainer.width - exitButton.width, 1, 0x4B4B4B, 0xC3C3C3, 0x2D2D2D, 0x878787, localization.continueDebug))
	continueButton.animated = false
	continueButton.onTouch = function()
		container.close()
		continue()
	end
	
	titleDebugMode = true
	workspace:draw()

	computer.beep(1500, 0.08)
end

local function launchWithArgumentsWindow()
	local container = addInputFadeContainer(localization.launchWithArguments, localization.arguments)

	container.input.onInputFinished = function()
		local arguments = {}
		container.input.text = container.input.text:gsub(",%s+", ",")
		for argument in container.input.text:gmatch("[^,]+") do
			table.insert(arguments, argument)
		end

		container:remove()
		workspace:draw()

		run(table.unpack(arguments))
	end

	workspace:draw()
end

local function deleteLine(line)
	clearAutocompleteDatabaseFromLine(line)
	
	if #lines > 1 then
		table.remove(lines, line)
	else
		lines[1] = ""
	end

	setCursorPositionAndClearSelection(1, cursorPositionLine)
end

local function deleteSpecifiedData(fromSymbol, fromLine, toSymbol, toLine)	
	clearAutocompleteDatabaseFromLine(fromLine)

	lines[fromLine] = unicode.sub(lines[fromLine], 1, fromSymbol - 1) .. unicode.sub(lines[toLine], toSymbol + 1, -1)
	for line = fromLine + 1, toLine do
		clearAutocompleteDatabaseFromLine(fromLine + 1)
		
		table.remove(lines, fromLine + 1)
	end
	
	setCursorPositionAndClearSelection(fromSymbol, fromLine)
	updateAutocompleteDatabaseFromLine(fromLine)
end

local function deleteSelectedData()
	if codeView.selections[1] then
		deleteSpecifiedData(
			codeView.selections[1].from.symbol,
			codeView.selections[1].from.line,
			codeView.selections[1].to.symbol,
			codeView.selections[1].to.line
		)

		clearSelection()
	end
end

local function copy()
	if codeView.selections[1] then
		if codeView.selections[1].to.line == codeView.selections[1].from.line then
			clipboard = { unicode.sub(lines[codeView.selections[1].from.line], codeView.selections[1].from.symbol, codeView.selections[1].to.symbol) }
		else
			clipboard = { unicode.sub(lines[codeView.selections[1].from.line], codeView.selections[1].from.symbol, -1) }
			for line = codeView.selections[1].from.line + 1, codeView.selections[1].to.line - 1 do
				table.insert(clipboard, lines[line])
			end
			table.insert(clipboard, unicode.sub(lines[codeView.selections[1].to.line], 1, codeView.selections[1].to.symbol))
		end
	end
end

local function cut()
	if codeView.selections[1] then
		copy()
		deleteSelectedData()
	end
end

local function paste(data, notTable)
	if codeView.selections[1] then
		deleteSelectedData()
	end

	local firstPart = unicode.sub(lines[cursorPositionLine], 1, cursorPositionSymbol - 1)
	local secondPart = unicode.sub(lines[cursorPositionLine], cursorPositionSymbol, -1)

	if notTable then
		clearAutocompleteDatabaseFromLine(cursorPositionLine)

		lines[cursorPositionLine] = firstPart .. data .. secondPart
		setCursorPositionAndClearSelection(cursorPositionSymbol + unicode.len(data), cursorPositionLine)

		updateAutocompleteDatabaseFromLine(cursorPositionLine)
	else
		if #data == 1 then
			clearAutocompleteDatabaseFromLine(cursorPositionLine)

			lines[cursorPositionLine] = firstPart .. data[1] .. secondPart
			setCursorPositionAndClearSelection(unicode.len(firstPart .. data[1]) + 1, cursorPositionLine)

			updateAutocompleteDatabaseFromLine(cursorPositionLine)
		else
			clearAutocompleteDatabaseFromLine(cursorPositionLine)

			lines[cursorPositionLine] = firstPart .. data[1]
			updateAutocompleteDatabaseFromLine(cursorPositionLine)

			if #data > 2 then
				for pasteLine = #data - 1, 2, -1 do
					table.insert(lines, cursorPositionLine + 1, data[pasteLine])
					
					updateAutocompleteDatabaseFromLine(cursorPositionLine + 1)
				end
			end
			table.insert(lines, cursorPositionLine + #data - 1, data[#data] .. secondPart)
			updateAutocompleteDatabaseFromLine(cursorPositionLine + #data - 1)

			setCursorPositionAndClearSelection(unicode.len(data[#data]) + 1, cursorPositionLine + #data - 1)
		end
	end
end

local function selectAndPasteColor()
	local startColor = 0xFF0000
	if codeView.selections[1] and codeView.selections[1].from.line == codeView.selections[1].to.line then
		startColor = tonumber(unicode.sub(lines[codeView.selections[1].from.line], codeView.selections[1].from.symbol, codeView.selections[1].to.symbol)) or startColor
	end

	local palette = window:addChild(GUI.palette(1, 1, startColor))
	palette.localX, palette.localY = math.floor(window.width / 2 - palette.width / 2), math.floor(window.height / 2 - palette.height / 2)

	palette.cancelButton.onTouch = function()
		palette:remove()
		workspace:draw()
	end

	palette.submitButton.onTouch = function()
		paste(string.format("0x%06X", palette.color.integer), true)
		palette.cancelButton.onTouch()
	end
end

local function convertCase(method)
	if codeView.selections[1] then
		local from, to = codeView.selections[1].from, codeView.selections[1].to
		if from.line == to.line then
			lines[from.line] = unicode.sub(lines[from.line], 1, from.symbol - 1) .. unicode[method](unicode.sub(lines[from.line], from.symbol, to.symbol)) .. unicode.sub(lines[from.line], to.symbol + 1, -1)
		else
			lines[from.line] = unicode.sub(lines[from.line], 1, from.symbol - 1) .. unicode[method](unicode.sub(lines[from.line], from.symbol, -1))
			lines[to.line] = unicode[method](unicode.sub(lines[to.line], 1, to.symbol)) .. unicode.sub(lines[to.line], to.symbol + 1, -1)
			for line = from.line + 1, to.line - 1 do
				lines[line] = unicode[method](lines[line])
			end
		end
	end
end

local function pasteRegularChar(unicodeByte, char)
	if not keyboard.isControl(unicodeByte) then
		paste(char, true)
		-- if char == " " then
			-- updateAutocompleteDatabaseFromAllLines()
		-- end
		showAutocomplete()
	end
end

local function pasteAutoBrackets(unicodeByte)
	local char = unicode.char(unicodeByte)
	local currentSymbol = unicode.sub(lines[cursorPositionLine], cursorPositionSymbol, cursorPositionSymbol)

	-- Если у нас вообще врублен режим автоскобок, то чекаем их
	if config.enableAutoBrackets then
		-- Ситуация, когда курсор находится на закрывающей скобке, и нехуй ее еще раз вставлять
		if closeBrackets[char] and currentSymbol == char then
			deleteSelectedData()
			setCursorPosition(cursorPositionSymbol + 1, cursorPositionLine)
		-- Если нажата открывающая скобка
		elseif openBrackets[char] then
			-- А вот тут мы берем в скобочки уже выделенный текст
			if codeView.selections[1] then
				local firstPart = unicode.sub(lines[codeView.selections[1].from.line], 1, codeView.selections[1].from.symbol - 1)
				local secondPart = unicode.sub(lines[codeView.selections[1].from.line], codeView.selections[1].from.symbol, -1)
				lines[codeView.selections[1].from.line] = firstPart .. char .. secondPart
				codeView.selections[1].from.symbol = codeView.selections[1].from.symbol + 1

				if codeView.selections[1].to.line == codeView.selections[1].from.line then
					codeView.selections[1].to.symbol = codeView.selections[1].to.symbol + 1
				end

				firstPart = unicode.sub(lines[codeView.selections[1].to.line], 1, codeView.selections[1].to.symbol)
				secondPart = unicode.sub(lines[codeView.selections[1].to.line], codeView.selections[1].to.symbol + 1, -1)
				lines[codeView.selections[1].to.line] = firstPart .. openBrackets[char] .. secondPart
				cursorPositionSymbol = cursorPositionSymbol + 2
			-- А тут мы делаем двойную автоскобку, если можем
			elseif openBrackets[char] and not currentSymbol:match("[%a%d%_]") then
				paste(char .. openBrackets[char], true)
				setCursorPosition(cursorPositionSymbol - 1, cursorPositionLine)
				cursorBlinkState = false
			-- Ну, и если нет ни выделений, ни можем ебануть автоскобочку по регулярке
			else
				pasteRegularChar(unicodeByte, char)
			end
		-- Если мы вообще на скобку не нажимали
		else
			pasteRegularChar(unicodeByte, char)
		end
	-- Если оффнуты афтоскобки
	else
		pasteRegularChar(unicodeByte, char)
	end
end

local function delete()
	if codeView.selections[1] then
		deleteSelectedData()
	else
		if cursorPositionSymbol < unicode.len(lines[cursorPositionLine]) + 1 then
			deleteSpecifiedData(cursorPositionSymbol, cursorPositionLine, cursorPositionSymbol, cursorPositionLine)
		else
			if cursorPositionLine > 1 and lines[cursorPositionLine + 1] then
				deleteSpecifiedData(unicode.len(lines[cursorPositionLine]) + 1, cursorPositionLine, 0, cursorPositionLine + 1)
			end
		end

		showAutocomplete()
	end
end

local function selectAll()
	codeView.selections[1] = {
		from = {
			symbol = 1, line = 1
		},
		to = {
			symbol = unicode.len(lines[#lines]), line = #lines
		}
	}
end

local function isLineCommented(line)
	if lines[line] == "" or lines[line]:match("%-%-%s?") then return true end
end

local function commentLine(line)
	lines[line] = "-- " .. lines[line]
end

local function uncommentLine(line)
	local countOfReplaces
	lines[line], countOfReplaces = lines[line]:gsub("%-%-%s?", "", 1)
	return countOfReplaces
end

local function toggleComment()
	if codeView.selections[1] then
		local allLinesAreCommented = true
		
		for line = codeView.selections[1].from.line, codeView.selections[1].to.line do
			if not isLineCommented(line) then
				allLinesAreCommented = false
				break
			end
		end
		
		for line = codeView.selections[1].from.line, codeView.selections[1].to.line do
			if allLinesAreCommented then
				uncommentLine(line)
			else
				commentLine(line)
			end
		end

		local modifyer = 3
		if allLinesAreCommented then modifyer = -modifyer end
		setCursorPosition(cursorPositionSymbol + modifyer, cursorPositionLine)
		codeView.selections[1].from.symbol, codeView.selections[1].to.symbol = codeView.selections[1].from.symbol + modifyer, codeView.selections[1].to.symbol + modifyer
	else
		if isLineCommented(cursorPositionLine) then
			if uncommentLine(cursorPositionLine) > 0 then
				setCursorPositionAndClearSelection(cursorPositionSymbol - 3, cursorPositionLine)
			end
		else
			commentLine(cursorPositionLine)
			setCursorPositionAndClearSelection(cursorPositionSymbol + 3, cursorPositionLine)
		end
	end
end

local function indentLine(line)
	lines[line] = string.rep(" ", codeView.indentationWidth) .. lines[line]
end

local function unindentLine(line)
	lines[line], countOfReplaces = string.gsub(lines[line], "^" .. string.rep("%s", codeView.indentationWidth), "")
	return countOfReplaces
end

local function indentOrUnindent(isIndent)
	if codeView.selections[1] then
		local countOfReplacesInFirstLine, countOfReplacesInLastLine
		
		for line = codeView.selections[1].from.line, codeView.selections[1].to.line do
			if isIndent then
				indentLine(line)
			else
				local countOfReplaces = unindentLine(line)
				if line == codeView.selections[1].from.line then
					countOfReplacesInFirstLine = countOfReplaces
				elseif line == codeView.selections[1].to.line then
					countOfReplacesInLastLine = countOfReplaces
				end
			end
		end		

		if isIndent then
			setCursorPosition(cursorPositionSymbol + codeView.indentationWidth, cursorPositionLine)
			codeView.selections[1].from.symbol, codeView.selections[1].to.symbol = codeView.selections[1].from.symbol + codeView.indentationWidth, codeView.selections[1].to.symbol + codeView.indentationWidth
		else
			if countOfReplacesInFirstLine > 0 then
				codeView.selections[1].from.symbol = codeView.selections[1].from.symbol - codeView.indentationWidth
				if cursorPositionLine == codeView.selections[1].from.line then
					setCursorPosition(cursorPositionSymbol - codeView.indentationWidth, cursorPositionLine)
				end
			end

			if countOfReplacesInLastLine > 0 then
				codeView.selections[1].to.symbol = codeView.selections[1].to.symbol - codeView.indentationWidth
				if cursorPositionLine == codeView.selections[1].to.line then
					setCursorPosition(cursorPositionSymbol - codeView.indentationWidth, cursorPositionLine)
				end
			end
		end
	else
		if isIndent then
			paste(string.rep(" ", codeView.indentationWidth), true)
		else
			if unindentLine(cursorPositionLine) > 0 then
				setCursorPositionAndClearSelection(cursorPositionSymbol - codeView.indentationWidth, cursorPositionLine)
			end
		end
	end
end

local function find()
	if not bottomToolBar.hidden and searchInput.text ~= "" then
		findStartFrom = findStartFrom + 1
	
		for line = findStartFrom, #lines do
			local whereToFind, whatToFind = lines[line], searchInput.text
			if not caseSensitiveButton.pressed then
				whereToFind, whatToFind = unicode.lower(whereToFind), unicode.lower(whatToFind)
			end

			local success, starting, ending = pcall(text.unicodeFind, whereToFind, whatToFind)
			if success then
				if starting then
					codeView.selections[1] = {
						from = {symbol = starting, line = line},
						to = {symbol = ending, line = line},
						color = 0xCC9200
					}
					findStartFrom = line
					gotoLine(line)
					return
				end
			else
				GUI.alert("Wrong searching regex")
			end
		end

		findStartFrom = 0
	end
end

local function findFromFirstDisplayedLine()
	findStartFrom = codeView.fromLine
	find()
end

local function toggleBottomToolBar()
	bottomToolBar.hidden = not bottomToolBar.hidden
	toggleBottomToolBarButton.pressed = not bottomToolBar.hidden
	calculateSizes()
		
	if not bottomToolBar.hidden then
		workspace:draw()
		findFromFirstDisplayedLine()
	end
end

local function toggleTopToolBar()
	topToolBar.hidden = not topToolBar.hidden
	toggleTopToolBarButton.pressed = not topToolBar.hidden
	calculateSizes()
end

local function createEditOrRightClickMenu(menu)
	menu:addItem(localization.cut, not codeView.selections[1], "^X").onTouch = function()
		cut()
	end

	menu:addItem(localization.copy, not codeView.selections[1], "^C").onTouch = function()
		copy()
	end

	menu:addItem(localization.paste, not clipboard, "^V").onTouch = function()
		paste(clipboard)
	end

	menu:addSeparator()

	menu:addItem(localization.selectWord).onTouch = function()
		selectWord()
	end

	menu:addItem(localization.selectAll, false, "^A").onTouch = function()
		selectAll()
	end

	menu:addSeparator()

	menu:addItem(localization.comment, false, "^/").onTouch = function()
		toggleComment()
	end

	menu:addItem(localization.indent, false, "Tab").onTouch = function()
		indentOrUnindent(true)
	end

	menu:addItem(localization.unindent, false, "⇧Tab").onTouch = function()
		indentOrUnindent(false)
	end

	menu:addItem(localization.deleteLine, false, "^Del").onTouch = function()
		deleteLine(cursorPositionLine)
	end

	menu:addItem(localization.selectAndPasteColor, false, "^⇧C").onTouch = function()
		selectAndPasteColor()
	end
	
	local subMenu = menu:addSubMenuItem(localization.convertCase)
	
	subMenu:addItem(localization.toUpperCase, false, "^▲").onTouch = function()
		convertCase("upper")
	end

	subMenu:addItem(localization.toLowerCase, false, "^▼").onTouch = function()
		convertCase("lower")
	end

	menu:addSeparator()

	menu:addItem(localization.addBreakpoint, false, "F9").onTouch = function()
		addBreakpoint()
		workspace:draw()
	end

	menu:addItem(localization.clearBreakpoints, not breakpointLines, "^F9").onTouch = function()
		clearBreakpoints()
	end
end

local function checkScrollbar(y)
	return codeView.horizontalScrollBar.hidden or y < codeView.y + codeView.height - 1
end

local uptime = computer.uptime()
codeView.eventHandler = function(workspace, object, e1, e2, e3, e4, e5)
	if e1 == "touch" and checkScrollbar(e4) then
		if e5 == 1 then
			createEditOrRightClickMenu(GUI.addContextMenu(workspace, e3, e4))
		else
			setCursorPositionAndClearSelection(convertScreenCoordinatesToTextPosition(e3, e4))
		end

		tick(true)
	elseif e1 == "double_touch" then
		selectWord()
		tick(true)
	elseif e1 == "drag" and checkScrollbar(e4) then
		codeView.selections[1] = codeView.selections[1] or {from = {}, to = {}}
		codeView.selections[1].from.symbol, codeView.selections[1].from.line = cursorPositionSymbol, cursorPositionLine
		codeView.selections[1].to.symbol, codeView.selections[1].to.line = fixCursorPosition(convertScreenCoordinatesToTextPosition(e3, e4))
		
		if codeView.selections[1].from.line > codeView.selections[1].to.line then
			codeView.selections[1].from.line, codeView.selections[1].to.line = codeView.selections[1].to.line, codeView.selections[1].from.line
			codeView.selections[1].from.symbol, codeView.selections[1].to.symbol = codeView.selections[1].to.symbol, codeView.selections[1].from.symbol
		elseif codeView.selections[1].from.line == codeView.selections[1].to.line then
			if codeView.selections[1].from.symbol > codeView.selections[1].to.symbol then
				codeView.selections[1].from.symbol, codeView.selections[1].to.symbol = codeView.selections[1].to.symbol, codeView.selections[1].from.symbol
			end
		end

		tick(true)
	elseif e1 == "key_down" and GUI.focusedObject == window then
		-- Ctrl or CMD
		if keyboard.isControlDown() or keyboard.isCommandDown() then
			-- Slash
			if e4 == 53 then
				toggleComment()
			-- ]
			elseif e4 == 27 then
				config.enableAutoBrackets = not config.enableAutoBrackets
				saveConfig()
			-- I
			elseif e4 == 23 then
				toggleEnableAutocompleteDatabase()
			-- A
			elseif e4 == 30 then
				selectAll()
			-- C
			elseif e4 == 46 then
				-- Shift
				if keyboard.isKeyDown(42) then
					selectAndPasteColor()
				else
					copy()
				end
			-- V
			elseif e4 == 47 and clipboard then
				paste(clipboard)
			-- X
			elseif e4 == 45 then
				if codeView.selections[1] then
					cut()
				else
					deleteLine(cursorPositionLine)
				end
			-- N
			elseif e4 == 49 then
				newFile()
			-- O
			elseif e4 == 24 then
				openFileWindow()
			-- U
			elseif e4 == 22 and component.isAvailable("internet") then
				downloadFileFromWeb()
			-- Arrow UP
			elseif e4 == 200 then
				convertCase("upper")
			-- Arrow DOWN
			elseif e4 == 208 then
				convertCase("lower")
			-- S
			elseif e4 == 31 then
				-- Shift
				if leftTreeView.selectedItem and not keyboard.isKeyDown(42) then
					saveFileWindow()
				else
					saveFileAsWindow()
				end
			-- F
			elseif e4 == 33 then
				toggleBottomToolBar()
			-- G
			elseif e4 == 34 then
				find()
			-- L
			elseif e4 == 38 then
				gotoLineWindow()
			-- Backspace
			elseif e4 == 14 then
				deleteLine(cursorPositionLine)
			-- Delete
			elseif e4 == 211 then
				deleteLine(cursorPositionLine)
			-- F5
			elseif e4 == 63 then
				launchWithArgumentsWindow()
			end
		-- Arrows up, down, left, right
		elseif e4 == 200 then
			moveCursor(0, -1)
		elseif e4 == 208 then
			moveCursor(0, 1)
		elseif e4 == 203 then
			moveCursor(-1, 0, true)
		elseif e4 == 205 then
			moveCursor(1, 0, true)
		-- Tab
		elseif e4 == 15 then
			if keyboard.isKeyDown(42) then
				indentOrUnindent(false)
			else
				indentOrUnindent(true)
			end
		-- Backspace
		elseif e4 == 14 then
			if codeView.selections[1] then
				deleteSelectedData()
			else
				if cursorPositionSymbol > 1 then
					-- Удаляем автоскобочки))0
					if config.enableAutoBrackets and unicode.sub(lines[cursorPositionLine], cursorPositionSymbol, cursorPositionSymbol) == openBrackets[unicode.sub(lines[cursorPositionLine], cursorPositionSymbol - 1, cursorPositionSymbol - 1)] then
						deleteSpecifiedData(cursorPositionSymbol - 1, cursorPositionLine, cursorPositionSymbol, cursorPositionLine)
					else
						-- Удаляем индентацию
						local match = unicode.sub(lines[cursorPositionLine], 1, cursorPositionSymbol - 1):match("^(%s+)$")
						if match and #match % codeView.indentationWidth == 0 then
							deleteSpecifiedData(cursorPositionSymbol - codeView.indentationWidth, cursorPositionLine, cursorPositionSymbol - 1, cursorPositionLine)
						-- Удаляем обычные символы
						else
							deleteSpecifiedData(cursorPositionSymbol - 1, cursorPositionLine, cursorPositionSymbol - 1, cursorPositionLine)
						end
					end
				else
					-- Удаление типа с обратным энтером
					if cursorPositionLine > 1 then
						deleteSpecifiedData(unicode.len(lines[cursorPositionLine - 1]) + 1, cursorPositionLine - 1, 0, cursorPositionLine)
					end
				end

				showAutocomplete()
			end
		-- Enter
		elseif e4 == 28 then
			if autocomplete.hidden then
				if codeView.selections[1] then
					deleteSelectedData()
				end
				
				local secondPart = unicode.sub(lines[cursorPositionLine], cursorPositionSymbol, -1)
				
				local match = lines[cursorPositionLine]:match("^(%s+)")
				if match then
					secondPart = match .. secondPart
				end
				
				lines[cursorPositionLine] = unicode.sub(lines[cursorPositionLine], 1, cursorPositionSymbol - 1)
				table.insert(lines, cursorPositionLine + 1, secondPart)
				
				setCursorPositionAndClearSelection(match and #match + 1 or 1, cursorPositionLine + 1)
			else
				autocomplete.hidden = true
			end
		-- F5
		elseif e4 == 63 then
			run()
		-- F9
		elseif e4 == 67 then
			-- Shift
			if keyboard.isKeyDown(42) then
				clearBreakpoints()
			else
				addBreakpoint()
			end
		-- Home
		elseif e4 == 199 then
			setCursorPositionToHome()
		-- End
		elseif e4 == 207 then
			setCursorPositionToEnd()
		-- Page Up
		elseif e4 == 201 then
			pageUp()
		-- Page Down
		elseif e4 == 209 then
			pageDown()
		-- Delete
		elseif e4 == 211 then
			delete()
		else
			pasteAutoBrackets(e3)
		end

		tick(true)
	elseif e1 == "scroll" then
		scroll(e5, config.scrollSpeed)
		tick(cursorBlinkState)
	elseif e1 == "clipboard" then
		local lines = splitStringIntoLines(e3)
		paste(lines)
		
		tick(cursorBlinkState)
	elseif not e1 and cursorUptime + config.cursorBlinkDelay < computer.uptime() then
		tick(not cursorBlinkState)
	end
end

leftTreeView.onItemSelected = function(path)
	workspace:draw()
	openFile(path)
	workspace:draw()
end

local MineCodeContextMenu = menu:addContextMenuItem("MineCode", 0x0)
MineCodeContextMenu:addItem(localization.about).onTouch = function()
	local container = addBackgroundContainer(localization.about)
	
	local about = {
		"MineCode IDE",
		"Copyright © 2014-2018 ECS Inc.",
		" ",
		"Developers:",
		" ",
		"Timofeev Igor, vk.com/id7799889",
		"Trifonov Gleb, vk.com/id88323331",
		" ",
		"Testers:",
		" ",
		"Semyonov Semyon, vk.com/id92656626",
		"Prosin Mihail, vk.com/id75667079",
		"Shestakov Timofey, vk.com/id113499693",
		"Bogushevich Victoria, vk.com/id171497518",
		"Vitvitskaya Yana, vk.com/id183425349",
		"Golovanova Polina, vk.com/id226251826",
	}

	local textBox = container.layout:addChild(GUI.textBox(1, 1, 36, #about, nil, 0xB4B4B4, about, 1, 0, 0, true, false))
	textBox:setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
	textBox.eventHandler = nil

	workspace:draw()
end

local fileContextMenu = menu:addContextMenuItem(localization.file)
fileContextMenu:addItem(localization.new, false, "^N").onTouch = function()
	newFile()
	workspace:draw()
end

fileContextMenu:addItem(localization.open, false, "^O").onTouch = function()
	openFileWindow()
end

fileContextMenu:addItem(localization.getFromWeb, not component.isAvailable("internet"), "^U").onTouch = function()
	downloadFileFromWeb()
end


fileContextMenu:addSeparator()

saveContextMenuItem = fileContextMenu:addItem(localization.save, not leftTreeView.selectedItem, "^S")
saveContextMenuItem.onTouch = function()
	saveFileWindow()
end

fileContextMenu:addItem(localization.saveAs, false, "^⇧S").onTouch = function()
	saveFileAsWindow()
end

fileContextMenu:addItem(localization.flashEEPROM, not component.isAvailable("eeprom")).onTouch = function()
	local container = addBackgroundContainer(localization.flashEEPROM)
	container.layout:addChild(GUI.label(1, 1, container.width, 1, 0x969696, localization.flashingEEPROM .. "...")):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
	workspace:draw()

	component.get("eeprom").set(table.concat(lines, "\n"))
	
	container:remove()
	workspace:draw()
end

fileContextMenu:addSeparator()

fileContextMenu:addItem(localization.launchWithArguments, false, "^F5").onTouch = function()
	launchWithArgumentsWindow()
end

local topMenuEdit = menu:addContextMenuItem(localization.edit)
createEditOrRightClickMenu(topMenuEdit)

local gotoContextMenu = menu:addContextMenuItem(localization.gotoCyka)
gotoContextMenu:addItem(localization.pageUp, false, "PgUp").onTouch = function()
	pageUp()
end

gotoContextMenu:addItem(localization.pageDown, false, "PgDn").onTouch = function()
	pageDown()
end

gotoContextMenu:addItem(localization.gotoStart, false, "Home").onTouch = function()
	setCursorPositionToHome()
end

gotoContextMenu:addItem(localization.gotoEnd, false, "End").onTouch = function()
	setCursorPositionToEnd()
end

gotoContextMenu:addSeparator()

gotoContextMenu:addItem(localization.gotoLine, false, "^L").onTouch = function()
	gotoLineWindow()
end

local propertiesContextMenu = menu:addContextMenuItem(localization.properties)
propertiesContextMenu:addItem(localization.colorScheme).onTouch = function()
	local container = GUI.addBackgroundContainer(workspace, true, false, localization.colorScheme)
				
	local colorSelectorsCount, colorSelectorCountX = 0, 4; for key in pairs(config.syntaxColorScheme) do colorSelectorsCount = colorSelectorsCount + 1 end
	local colorSelectorCountY = math.ceil(colorSelectorsCount / colorSelectorCountX)
	local colorSelectorWidth, colorSelectorHeight, colorSelectorSpaceX, colorSelectorSpaceY = math.floor(container.width / colorSelectorCountX * 0.8), 3, 2, 1
	
	local startX, y = math.floor(container.width / 2 - (colorSelectorCountX * (colorSelectorWidth + colorSelectorSpaceX) - colorSelectorSpaceX) / 2), math.floor(container.height / 2 - (colorSelectorCountY * (colorSelectorHeight + colorSelectorSpaceY) - colorSelectorSpaceY + 3) / 2)
	container:addChild(GUI.label(1, y, container.width, 1, 0xFFFFFF, localization.colorScheme)):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP); y = y + 3
	local x, counter = startX, 1

	local colors = {}
	for key in pairs(config.syntaxColorScheme) do
		table.insert(colors, {key})
	end

	aplhabeticalSort(colors)

	for i = 1, #colors do
		local colorSelector = container:addChild(GUI.colorSelector(x, y, colorSelectorWidth, colorSelectorHeight, config.syntaxColorScheme[colors[i][1]], colors[i][1]))
		colorSelector.onColorSelected = function()
			config.syntaxColorScheme[colors[i][1]] = colorSelector.color
			saveConfig()
		end

		x, counter = x + colorSelectorWidth + colorSelectorSpaceX, counter + 1
		if counter > colorSelectorCountX then
			x, y, counter = startX, y + colorSelectorHeight + colorSelectorSpaceY, 1
		end
	end

	workspace:draw()
end

propertiesContextMenu:addItem(localization.cursorProperties).onTouch = function()
	local container = addBackgroundContainer(localization.cursorProperties)

	local input = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xC3C3C3, 0x787878, 0x787878, 0xC3C3C3, 0x2D2D2D, config.cursorSymbol, localization.cursorSymbol))
	input.onInputFinished = function()
		if #input.text == 1 then
			config.cursorSymbol = input.text
			saveConfig()
		end
	end

	local colorSelector = container.layout:addChild(GUI.colorSelector(1, 1, 36, 3, config.cursorColor, localization.cursorColor))
	colorSelector.onColorSelected = function()
		config.cursorColor = colorSelector.color
		saveConfig()
	end

	local slider = container.layout:addChild(GUI.slider(1, 1, 36, 0xFFDB80, 0x000000, 0xFFDB40, 0xDDDDDD, 1, 1000, config.cursorBlinkDelay * 1000, false, localization.cursorBlinkDelay .. ": ", " ms"))
	slider.onValueChanged = function()
		config.cursorBlinkDelay = slider.value / 1000
		saveConfig()
	end

	workspace:draw()
end

propertiesContextMenu:addItem(localization.toggleTopToolBar).onTouch = function()
	toggleTopToolBar()
end

propertiesContextMenu:addSeparator()

propertiesContextMenu:addItem(localization.toggleSyntaxHighlight).onTouch = function()
	syntaxHighlightingButton.pressed = not syntaxHighlightingButton.pressed
	syntaxHighlightingButton.onTouch()
end

propertiesContextMenu:addItem(localization.toggleAutoBrackets, false, "^]").onTouch = function()
	config.enableAutoBrackets = not config.enableAutoBrackets
	saveConfig()
end

propertiesContextMenu:addItem(localization.toggleAutocompletion, false, "^I").onTouch = function()
	toggleEnableAutocompleteDatabase()
end

leftTreeViewResizer.onResize = function(dragWidth, dragHeight)
	leftTreeView.width = leftTreeView.width + dragWidth
	calculateSizes()
end

leftTreeViewResizer.onResizeFinished = function()
	config.leftTreeViewWidth = leftTreeView.width
	saveConfig()
end

addBreakpointButton.onTouch = function()
	addBreakpoint()
	workspace:draw()
end

syntaxHighlightingButton.onTouch = function()
	config.syntaxHighlight = not config.syntaxHighlight
	codeView.syntaxHighlight = config.syntaxHighlight
	workspace:draw()
	saveConfig()
end

toggleLeftToolBarButton.onTouch = function()
	leftTreeView.hidden = not toggleLeftToolBarButton.pressed
	leftTreeViewResizer.hidden = leftTreeView.hidden
	calculateSizes()
	workspace:draw()
end

toggleBottomToolBarButton.onTouch = function()
	bottomToolBar.hidden = not toggleBottomToolBarButton.pressed
	calculateSizes()
	workspace:draw()
end

toggleTopToolBarButton.onTouch = function()
	topToolBar.hidden = not toggleTopToolBarButton.pressed
	calculateSizes()
	workspace:draw()
end

codeView.verticalScrollBar.onTouch = function()
	codeView.fromLine = math.ceil(codeView.verticalScrollBar.value)
end

codeView.horizontalScrollBar.onTouch = function()
	codeView.fromSymbol = math.ceil(codeView.horizontalScrollBar.value)
end

runButton.onTouch = function()
	run()
end

autocomplete.onItemSelected = function(workspace, object, e1)
	local firstPart = unicode.sub(lines[cursorPositionLine], 1, autoCompleteWordStart - 1)
	local secondPart = unicode.sub(lines[cursorPositionLine], autoCompleteWordEnd + 1, -1)
	local middle = firstPart .. autocomplete.items[autocomplete.selectedItem]
	lines[cursorPositionLine] = middle .. secondPart

	setCursorPositionAndClearSelection(unicode.len(middle) + 1, cursorPositionLine)
	
	if e1 == "key_down" then
		autocomplete.hidden = false
	end

	tick(true)
end

window.onResize = function(width, height)
	calculateSizes()
	workspace:draw()
end

searchInput.onInputFinished = findFromFirstDisplayedLine
caseSensitiveButton.onTouch = find
searchButton.onTouch = find

------------------------------------------------------------

autocomplete:moveToFront()
leftTreeView:updateFileList()
calculateSizes()
workspace:draw()

local initialPath = select(1, ...)
if initialPath and filesystem.exists(initialPath) then
	openFile(initialPath)
else
	newFile()
end

workspace:draw()
