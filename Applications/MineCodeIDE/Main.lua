
local args = {...}

require("advancedLua")
local computer = require("computer")
local component = require("component")
local fs = require("filesystem")
local buffer = require("doubleBuffering")
local event = require("event")
local syntax = require("syntax")
local unicode = require("unicode")
local keyboard = require("keyboard")
local GUI = require("GUI")
local MineOSPaths = require("MineOSPaths")
local MineOSCore = require("MineOSCore")
local MineOSInterface = require("MineOSInterface")

------------------------------------------------------------

local config = {
	leftTreeViewWidth = 27,
	syntaxColorScheme = syntax.getColorScheme(),
	scrollSpeed = 8,
	cursorColor = 0x00A8FF,
	cursorSymbol = "┃",
	cursorBlinkDelay = 0.5,
	doubleClickDelay = 0.4,
	screenResolution = {},
	enableAutoBrackets = true,
	highlightLuaSyntax = true,
	enableAutocompletion = true,
	linesToShowOpenProgress = 100,
}
config.screenResolution.width, config.screenResolution.height = component.gpu.getResolution()

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

local cursorPositionSymbol = 1
local cursorPositionLine = 1
local cursorBlinkState = false

local scriptCoroutine
local resourcesPath = MineOSCore.getCurrentScriptDirectory() 
local configPath = MineOSPaths.applicationData .. "MineCode IDE/Config6.cfg"
local localization = MineOSCore.getCurrentScriptLocalization()
local findStartFrom
local clipboard
local breakpointLines
local lastErrorLine
local autocompleteDatabase
local autoCompleteWordStart, autoCompleteWordEnd
local continue, showBreakpointMessage, showErrorContainer

------------------------------------------------------------

if fs.exists(configPath) then
	config = table.fromFile(configPath)
	syntax.setColorScheme(config.syntaxColorScheme)
end

local mainContainer = GUI.fullScreenContainer()

local codeView = mainContainer:addChild(GUI.codeView(1, 1, 1, 1, {""}, 1, 1, 1, {}, {}, config.highlightLuaSyntax, 2))

local function convertTextPositionToScreenCoordinates(symbol, line)
	return
		codeView.codeAreaPosition + symbol - codeView.fromSymbol + 1,
		codeView.y + line - codeView.fromLine
end

local function convertScreenCoordinatesToTextPosition(x, y)
	return
		x - codeView.codeAreaPosition + codeView.fromSymbol - 1,
		y - codeView.y + codeView.fromLine
end

local overrideCodeViewDraw = codeView.draw
codeView.draw = function(...)
	overrideCodeViewDraw(...)

	if cursorBlinkState then
		local x, y = convertTextPositionToScreenCoordinates(cursorPositionSymbol, cursorPositionLine)
		if
			x >= codeView.codeAreaPosition + 1 and
			y >= codeView.y and
			x <= codeView.codeAreaPosition + codeView.codeAreaWidth - 2 and
			y <= codeView.y + codeView.height - 2
		then
			buffer.text(x, y, config.cursorColor, config.cursorSymbol)
		end
	end
end

local function saveConfig()
	table.toFile(configPath, config)
end

local topMenu = mainContainer:addChild(GUI.menu(1, 1, 1, 0xF0F0F0, 0x696969, 0x3366CC, 0xFFFFFF))

local topToolBar = mainContainer:addChild(GUI.container(1, 2, 1, 3))
local topToolBarPanel = topToolBar:addChild(GUI.panel(1, 1, 1, 3, 0xE1E1E1))

local RAMProgressBar = topToolBar:addChild(GUI.progressBar(1, 2, 20, 0x787878, 0xC3C3C3, 0xB4B4B4, 50, true, true, "RAM: ", "%"))

local topLayout = topToolBar:addChild(GUI.layout(1, 1, 1, 3, 1, 1))
topLayout:setCellDirection(1, 1, GUI.directions.horizontal)
topLayout:setCellSpacing(1, 1, 2)
topLayout:setCellAlignment(1, 1, GUI.alignment.horizontal.center, GUI.alignment.vertical.top)

local autocomplete = mainContainer:addChild(GUI.autoComplete(1, 1, 36, 7, 0xE1E1E1, 0xA5A5A5, 0x3C3C3C, 0x3C3C3C, 0xA5A5A5, 0xE1E1E1, 0xC3C3C3, 0x4B4B4B))

local addBreakpointButton = topLayout:addChild(GUI.adaptiveButton(1, 1, 3, 1, 0x878787, 0xE1E1E1, 0xD2D2D2, 0x4B4B4B, "x"))

local syntaxHighlightingButton = topLayout:addChild(GUI.adaptiveButton(1, 1, 3, 1, 0xD2D2D2, 0x4B4B4B, 0x696969, 0xE1E1E1, "◌"))
syntaxHighlightingButton.switchMode = true
syntaxHighlightingButton.pressed = codeView.highlightLuaSyntax

local runButton = topLayout:addChild(GUI.adaptiveButton(1, 1, 3, 1, 0x4B4B4B, 0xE1E1E1, 0xD2D2D2, 0x4B4B4B, "▷"))

local title = topLayout:addChild(GUI.textBox(1, 1, 1, 3, 0x0, 0x0, {}, 1):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top))
local titleLines = {}
local titleDebugMode = false
title.draw = function()	
	local sides = titleDebugMode and 0xCC4940 or 0x5A5A5A
	buffer.square(title.x, 2, 1, title.height, sides, 0x0, " ")
	buffer.square(title.x + title.width - 1, 2, 1, title.height, sides, 0x0, " ")
	buffer.square(title.x + 1, 2, title.width - 2, 3, titleDebugMode and 0x880000 or 0x3C3C3C, 0xE1E1E1, " ")

	if titleDebugMode then
		local text = lastErrorLine and localization.runtimeError or localization.debugging .. (_G.MineCodeIDEDebugInfo and _G.MineCodeIDEDebugInfo.line or "N/A")
		buffer.text(math.floor(title.x + title.width / 2 - unicode.len(text) / 2), 3, 0xE1E1E1, text)
	else
		for i = 1, #titleLines do
			buffer.text(math.floor(title.x + title.width / 2 - unicode.len(titleLines[i]) / 2), i + 1, 0xE1E1E1, titleLines[i])
		end
	end
end

local toggleLeftToolBarButton = topLayout:addChild(GUI.adaptiveButton(1, 1, 3, 1, 0xD2D2D2, 0x4B4B4B, 0x4B4B4B, 0xE1E1E1, "⇦"))
toggleLeftToolBarButton.switchMode, toggleLeftToolBarButton.pressed = true, true

local toggleBottomToolBarButton = topLayout:addChild(GUI.adaptiveButton(1, 1, 3, 1, 0xD2D2D2, 0x4B4B4B, 0x696969, 0xE1E1E1, "⇩"))
toggleBottomToolBarButton.switchMode, toggleBottomToolBarButton.pressed = true, false

local toggleTopToolBarButton = topLayout:addChild(GUI.adaptiveButton(1, 1, 3, 1, 0xD2D2D2, 0x4B4B4B, 0x878787, 0xE1E1E1, "⇧"))
toggleTopToolBarButton.switchMode, toggleTopToolBarButton.pressed = true, true

local bottomToolBar = mainContainer:addChild(GUI.container(1, 1, 1, 3))
bottomToolBar.hidden = true

local caseSensitiveButton = bottomToolBar:addChild(GUI.adaptiveButton(1, 1, 2, 1, 0x3C3C3C, 0xE1E1E1, 0xB4B4B4, 0x2D2D2D, "Aa"))
caseSensitiveButton.switchMode = true

local searchInput = bottomToolBar:addChild(GUI.input(7, 1, 10, 3, 0xE1E1E1, 0x969696, 0x969696, 0xE1E1E1, 0x2D2D2D, "", localization.findSomeShit))

local searchButton = bottomToolBar:addChild(GUI.adaptiveButton(1, 1, 3, 1, 0x3C3C3C, 0xE1E1E1, 0xB4B4B4, 0x2D2D2D, localization.find))

local leftTreeView = mainContainer:addChild(GUI.filesystemTree(1, 1, config.leftTreeViewWidth, 1, 0xD2D2D2, 0x3C3C3C, 0x3C3C3C, 0x969696, 0x3C3C3C, 0xE1E1E1, 0xB4B4B4, 0xA5A5A5, 0xB4B4B4, 0x4B4B4B, GUI.filesystemModes.both, GUI.filesystemModes.file))

local leftTreeViewResizer = mainContainer:addChild(GUI.resizer(1, 1, 3, 5, 0x696969, 0x0))

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
		titleLines[1] = string.limit(localization.file .. ": " .. (leftTreeView.selectedItem or localization.none), title.width - 4)
		titleLines[2] = string.limit(localization.cursor .. cursorPositionLine .. localization.line .. cursorPositionSymbol .. localization.symbol, title.width - 4)
		
		if codeView.selections[1] then
			local countOfSelectedLines, countOfSelectedSymbols = codeView.selections[1].to.line - codeView.selections[1].from.line + 1
			
			if codeView.selections[1].from.line == codeView.selections[1].to.line then
				countOfSelectedSymbols = unicode.len(unicode.sub(codeView.lines[codeView.selections[1].from.line], codeView.selections[1].from.symbol, codeView.selections[1].to.symbol))
			else
				countOfSelectedSymbols = unicode.len(unicode.sub(codeView.lines[codeView.selections[1].from.line], codeView.selections[1].from.symbol, -1))
				
				for line = codeView.selections[1].from.line + 1, codeView.selections[1].to.line - 1 do
					countOfSelectedSymbols = countOfSelectedSymbols + unicode.len(codeView.lines[line])
				end
				
				countOfSelectedSymbols = countOfSelectedSymbols + unicode.len(unicode.sub(codeView.lines[codeView.selections[1].to.line], 1, codeView.selections[1].to.symbol))
			end

			titleLines[3] = string.limit(localization.selection .. countOfSelectedLines .. localization.lines .. countOfSelectedSymbols .. localization.symbols, title.width - 4)
		else
			titleLines[3] = string.limit(localization.selection .. localization.none, title.width - 4)
		end
	end
end

local function updateRAMProgressBar()
	if not topToolBar.hidden then
		local totalMemory = computer.totalMemory()
		RAMProgressBar.value = math.ceil((totalMemory - computer.freeMemory()) / totalMemory * 100)
	end
end

local function tick(state)
	cursorBlinkState = state
	updateTitle()
	updateRAMProgressBar()
	mainContainer:drawOnScreen()
end

local function updateAutocompleteDatabaseFromString(str, value)
	for word in str:gmatch("[%a%d%_]+") do
		if not word:match("^%d+$") then
			autocompleteDatabase[word] = value
		end
	end
end

local function updateAutocompleteDatabaseFromFile()
	if config.enableAutocompletion then
		autocompleteDatabase = {}
		for line = 1, #codeView.lines do
			updateAutocompleteDatabaseFromString(codeView.lines[line], true)
		end
	end
end

local function getautoCompleteWordStartAndEnding(fromSymbol)
	local shittySymbolsRegexp, from, to = "[%s%c%p]"

	for i = fromSymbol, 1, -1 do
		if unicode.sub(codeView.lines[cursorPositionLine], i, i):match(shittySymbolsRegexp) then break end
		from = i
	end

	for i = fromSymbol, unicode.len(codeView.lines[cursorPositionLine]) do
		if unicode.sub(codeView.lines[cursorPositionLine], i, i):match(shittySymbolsRegexp) then break end
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
			autocomplete:match(
				autocompleteDatabase,
				unicode.sub(
					codeView.lines[cursorPositionLine],
					autoCompleteWordStart,
					autoCompleteWordEnd
				),
				true
			)

			if #autocomplete.items > 0 then
				autocomplete.fromItem, autocomplete.selectedItem = 1, 1
				autocomplete.localX, autocomplete.localY = convertTextPositionToScreenCoordinates(autoCompleteWordStart - 1, cursorPositionLine + 1)
				autocomplete.hidden = false
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
	mainContainer.width, mainContainer.height = buffer.getResolution()

	if leftTreeView.hidden then
		codeView.localX, codeView.width = 1, mainContainer.width
		bottomToolBar.localX, bottomToolBar.width = codeView.localX, codeView.width
	else
		codeView.localX, codeView.width = leftTreeView.width + 1, mainContainer.width - leftTreeView.width
		bottomToolBar.localX, bottomToolBar.width = codeView.localX, codeView.width
	end

	if topToolBar.hidden then
		leftTreeView.localY, leftTreeView.height = 2, mainContainer.height - 1
		codeView.localY, codeView.height = 2, mainContainer.height - 1
	else
		leftTreeView.localY, leftTreeView.height = 5, mainContainer.height - 4
		codeView.localY, codeView.height = 5, mainContainer.height - 4
	end

	if bottomToolBar.hidden then

	else
		codeView.height = codeView.height - 3
	end

	leftTreeViewResizer.localX = leftTreeView.width
	leftTreeViewResizer.localY = math.floor(leftTreeView.localY + leftTreeView.height / 2 - leftTreeViewResizer.height / 2)

	bottomToolBar.localY = mainContainer.height - 2
	searchButton.localX = bottomToolBar.width - searchButton.width + 1
	searchInput.width = bottomToolBar.width - searchInput.localX - searchButton.width + 1

	topToolBar.width, topToolBarPanel.width, topLayout.width = mainContainer.width, mainContainer.width, mainContainer.width
	title.width = math.floor(topToolBar.width * 0.32)
	
	RAMProgressBar.localX = topToolBar.width - RAMProgressBar.width - 1

	topMenu.width = mainContainer.width
end

local function gotoLine(line)
	codeView.fromLine = math.ceil(line - codeView.height / 2)
	if codeView.fromLine < 1 then
		codeView.fromLine = 1
	elseif codeView.fromLine > #codeView.lines then
		codeView.fromLine = #codeView.lines
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
	if codeView.fromLine > cursorPositionLine then
		codeView.fromLine = cursorPositionLine
	elseif codeView.fromLine + codeView.height - 2 < cursorPositionLine then
		codeView.fromLine = cursorPositionLine - codeView.height + 2
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
	elseif line > #codeView.lines then
		line = #codeView.lines
	end

	local lineLength = unicode.len(codeView.lines[line])
	if symbol < 1 or lineLength == 0 then
		symbol = 1
	elseif symbol > lineLength then
		symbol = lineLength + 1
	end

	return symbol, line
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

local function moveCursor(symbolOffset, lineOffset)
	if autocomplete.hidden then
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
			elseif symbolOffset > 0 and newSymbol > unicode.len(codeView.lines[newLine] or "") + 1 then
				newLine, newSymbol = newLine + 1, 1
			end

			setCursorPositionAndClearSelection(newSymbol, newLine)
		end
	end
end

local function setCursorPositionToHome()
	setCursorPositionAndClearSelection(1, 1)
end

local function setCursorPositionToEnd()
	setCursorPositionAndClearSelection(unicode.len(codeView.lines[#codeView.lines]) + 1, #codeView.lines)
end

local function scroll(direction, speed)
	if direction == 1 then
		if codeView.fromLine > speed then
			codeView.fromLine = codeView.fromLine - speed
		else
			codeView.fromLine = 1
		end
	else
		if codeView.fromLine < #codeView.lines - speed then
			codeView.fromLine = codeView.fromLine + speed
		else
			codeView.fromLine = #codeView.lines
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

local function removeTabs(text)
	local result = text:gsub("\t", string.rep(" ", codeView.indentationWidth))
	return result
end

local function removeWindowsLineEndings(text)
	local result = text:gsub("\r\n", "\n")
	return result
end

local function changeResolution(width, height)
	buffer.setResolution(width, height)
	calculateSizes()
	mainContainer:drawOnScreen()
	config.screenResolution.width = width
	config.screenResolution.height = height
end

local function addFadeContainer(title)
	return GUI.addFadeContainer(mainContainer, true, true, title)
end

local function addInputFadeContainer(title, placeholder)
	local container = addFadeContainer(title)
	container.input = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xC3C3C3, 0x787878, 0x787878, 0xC3C3C3, 0x2D2D2D, "", placeholder))

	return container
end


local function changeResolutionWindow()
	local container = addFadeContainer(localization.changeResolution)
	local inputFieldWidth = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xC3C3C3, 0x787878, 0x787878, 0xC3C3C3, 0x2D2D2D, tostring(config.screenResolution.width)))
	local inputFieldHeight = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xC3C3C3, 0x787878, 0x787878, 0xC3C3C3, 0x2D2D2D, tostring(config.screenResolution.height)))
	
	local maxResolutionWidth, maxResolutionHeight = component.gpu.maxResolution()
	inputFieldWidth.validator = function(text)
		local number = tonumber(text)
		if number and number >= 1 and number <= maxResolutionWidth then return true end
	end
	inputFieldHeight.validator = function(text)
		local number = tonumber(text)
		if number and number >= 1 and number <= maxResolutionHeight then return true end
	end

	container.panel.eventHandler = function(mainContainer, object, eventData)
		if eventData[1] == "touch" then
			config.screenResolution.width, config.screenResolution.height = tonumber(inputFieldWidth.text), tonumber(inputFieldHeight.text)
			saveConfig()
			container:delete()
			changeResolution(config.screenResolution.width, config.screenResolution.height)
		end
	end

	mainContainer:drawOnScreen()
end

local function newFile()
	autocompleteDatabase = {}
	codeView.lines = {""}
	codeView.maximumLineLength = 1
	leftTreeView.selectedItem = nil
	setCursorPositionAndClearSelection(1, 1)
	clearBreakpoints()
	updateTitle()
end

local function loadFile(path)
	local file, reason = io.open(path, "r")
	if file then
		newFile()
		leftTreeView.selectedItem = path
		codeView.hidden = true

		local container = mainContainer:addChild(GUI.container(codeView.localX, codeView.localY, codeView.width, codeView.height))
		container:addChild(GUI.panel(1, 1, container.width, container.height, 0x1E1E1E))
		local layout = container:addChild(GUI.layout(1, 1, container.width, container.height, 1, 1))
		layout:addChild(GUI.label(1, 1, layout.width, 1, 0xD2D2D2, localization.openingFile .. " " .. path):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top))
		local progressBar = layout:addChild(GUI.progressBar(1, 1, 36, 0x969696, 0x2D2D2D, 0x787878, 0, true, true, "", "%"))

		local counter, currentSize, totalSize = 1, 0, fs.size(path)
		for line in file:lines() do
			line = removeWindowsLineEndings(removeTabs(line))
			table.insert(codeView.lines, line)
			codeView.maximumLineLength = math.max(codeView.maximumLineLength, unicode.len(line))
			
			counter, currentSize = counter + 1, currentSize + #line
			if counter % config.linesToShowOpenProgress == 0 then
				progressBar.value = math.floor(currentSize / totalSize * 100)
				computer.pullSignal(0)
				mainContainer:drawOnScreen()
			end
		end

		if #codeView.lines > 1 then
			table.remove(codeView.lines, 1)
		end

		if counter > config.linesToShowOpenProgress then
			progressBar.value = 100
			mainContainer:drawOnScreen()
		end

		codeView.hidden = false
		container:delete()
		updateAutocompleteDatabaseFromFile()
		updateTitle()

		file:close()
	else
		GUI.error(reason)
	end
end

local function saveFile(path)
	fs.makeDirectory(fs.path(path))
	local file, reason = io.open(path, "w")
		if file then
		for line = 1, #codeView.lines do
			file:write(codeView.lines[line], "\n")
		end
		file:close()
	else
		GUI.error("Failed to open file for writing: " .. tostring(reason))
	end
end

local function gotoLineWindow()
	local container = addInputFadeContainer(localization.gotoLine, localization.lineNumber)

	container.input.onInputFinished = function()
		if container.input.text:match("%d+") then
			gotoLine(tonumber(container.input.text))
			container:delete()
			mainContainer:drawOnScreen()
		end
	end

	mainContainer:drawOnScreen()
end

local function openFileWindow()
	local filesystemDialog = GUI.addFilesystemDialogToContainer(mainContainer, 50, math.floor(mainContainer.height * 0.8), true, "Open", "Cancel", "File name", "/")
	filesystemDialog:setMode(GUI.filesystemModes.open, GUI.filesystemModes.file)
	filesystemDialog.onSubmit = function(path)
		loadFile(path)
		mainContainer:drawOnScreen()
	end
	filesystemDialog:show()
end

local function saveFileAsWindow()
	local filesystemDialog = GUI.addFilesystemDialogToContainer(mainContainer, 50, math.floor(mainContainer.height * 0.8), true, "Save", "Cancel", "File name", "/")
	filesystemDialog:setMode(GUI.filesystemModes.save, GUI.filesystemModes.file)
	filesystemDialog.onSubmit = function(path)
		saveFile(path)
		leftTreeView:updateFileList()
		leftTreeView.selectedItem = (leftTreeView.workPath .. path):gsub("/+", "/")

		updateTitle()
		updateAutocompleteDatabaseFromFile()
		mainContainer:drawOnScreen()
	end
	filesystemDialog:show()
end

local function saveFileWindow()
	saveFile(leftTreeView.selectedItem)
	leftTreeView:updateFileList()
end

local function splitStringIntoLines(s)
	s = removeWindowsLineEndings(removeTabs(s))

	local lines, searchLineEndingFrom, maximumLineLength, lineEndingFoundAt, line = {}, 1, 0
	repeat
		lineEndingFoundAt = string.unicodeFind(s, "\n", searchLineEndingFrom)
		if lineEndingFoundAt then
			line = unicode.sub(s, searchLineEndingFrom, lineEndingFoundAt - 1)
			searchLineEndingFrom = lineEndingFoundAt + 1
		else
			line = unicode.sub(s, searchLineEndingFrom, -1)
		end

		table.insert(lines, line)
		maximumLineLength = math.max(maximumLineLength, unicode.len(line))
	until not lineEndingFoundAt

	return lines, maximumLineLength
end

local function downloadFileFromWeb()
	local container = addInputFadeContainer(localization.gotoLine, localization.lineNumber)

	container.input.onInputFinished = function()
		if #container.input.text > 0 then
			local result, reason = require("web").request(container.input.text)
			if result then
				newFile()
				codeView.lines, codeView.maximumLineLength = splitStringIntoLines(result)
			else
				GUI.error("Failed to connect to URL: " .. tostring(reason))
			end

			container:delete()
			mainContainer:drawOnScreen()
		end
	end

	mainContainer:drawOnScreen()
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
				word ~= "local" and
				word ~= "return" and
				word ~= "while" and
				word ~= "repeat" and
				word ~= "until" and
				word ~= "for" and
				word ~= "in" and
				word ~= "do" and
				word ~= "if" and
				word ~= "then" and
				word ~= "else" and
				word ~= "elseif" and
				word ~= "end" and
				word ~= "function" and
				word ~= "true" and
				word ~= "false" and
				word ~= "nil" and
				word ~= "not" and
				word ~= "and" and
				word ~= "or"  and
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
	local oldResolutionX, oldResolutionY = component.gpu.getResolution()
	MineOSInterface.clearTerminal()

	-- Запускаем
	_G.MineCodeIDEDebugInfo = nil
	local coroutineResumeSuccess, coroutineResumeReason = coroutine.resume(scriptCoroutine, ...)

	-- Анализируем результат запуска
	if coroutineResumeSuccess then
		if coroutine.status(scriptCoroutine) == "dead" then
			MineOSInterface.waitForPressingAnyKey()
			buffer.setResolution(oldResolutionX, oldResolutionY)
			mainContainer:drawOnScreen(true)
		else
			-- Тест на пидора, мало ли у чувака в проге тоже есть yield
			if _G.MineCodeIDEDebugInfo then
				buffer.setResolution(oldResolutionX, oldResolutionY)
				mainContainer:drawOnScreen(true)
				gotoLine(_G.MineCodeIDEDebugInfo.line)
				showBreakpointMessage(_G.MineCodeIDEDebugInfo.variables)
			end
		end
	else
		buffer.setResolution(oldResolutionX, oldResolutionY)
		mainContainer:drawOnScreen(true)
		showErrorContainer(debug.traceback(scriptCoroutine, coroutineResumeReason))
	end
end

local function run(...)
	-- Инсертим брейкпоинты
	if breakpointLines then
		local offset = 0
		for i = 1, #breakpointLines do
			local variables = getVariables(codeView.lines[breakpointLines[i] + offset])
			
			local breakpointMessage = "_G.MineCodeIDEDebugInfo = {variables = {"
			for variable in pairs(variables) do
				breakpointMessage = breakpointMessage .. "[\"" .. variable .. "\"] = type(" .. variable .. ") == 'string' and '\"' .. " .. variable .. " .. '\"' or tostring(" .. variable .. "), "
			end
			breakpointMessage =  breakpointMessage .. "}, line = " .. breakpointLines[i] .. "}; coroutine.yield()"

			table.insert(codeView.lines, breakpointLines[i] + offset, breakpointMessage)
			offset = offset + 1
		end
	end

	-- Лоадим кодыч
	local loadSuccess, loadReason = load(table.concat(codeView.lines, "\n"))
	
	-- Чистим дерьмо вилочкой, чистим
	if breakpointLines then
		for i = 1, #breakpointLines do
			table.remove(codeView.lines, breakpointLines[i])
		end
	end

	-- Запускаем кодыч
	if loadSuccess then
		scriptCoroutine = coroutine.create(loadSuccess)
		continue(...)
	else
		showErrorContainer(loadReason)
	end
end

local function pizda(lines, debug)
	local container = mainContainer:addChild(GUI.container(1, 1, mainContainer.width, mainContainer.height))

	local backgroundObject = container:addChild(GUI.object(1, 1, mainContainer.width, mainContainer.height))
	local errorContainer = container:addChild(GUI.container(title.localX, topToolBar.hidden and 2 or 5, title.width, #lines + 2))
	local panel = errorContainer:addChild(GUI.panel(1, 1, errorContainer.width, errorContainer.height, 0xFFFFFF, 0.3))
	local textBox = errorContainer:addChild(GUI.textBox(3, 2, errorContainer.width - 4, #lines, nil, 0x4B4B4B, lines, 1))

	local function close()
		lastErrorLine = nil
		titleDebugMode = false
		updateHighlights()
		
		container:delete()
		mainContainer:drawOnScreen()
	end

	local times, frequency = 3, 1500
	if debug then
		times, frequency = 1, 1800
		errorContainer.height = errorContainer.height + 1
		panel.height = errorContainer.height
		
		local exitButton = errorContainer:addChild(GUI.button(1, errorContainer.height, math.floor(errorContainer.width / 2), 1, 0x3C3C3C, 0xC3C3C3, 0x2D2D2D, 0x878787, localization.finishDebug))
		exitButton.animated = false
		exitButton.onTouch = function()
			scriptCoroutine = nil
			close()
		end
		
		local continueButton = errorContainer:addChild(GUI.button(exitButton.width + 1, exitButton.localY, errorContainer.width - exitButton.width, 1, 0x4B4B4B, 0xC3C3C3, 0x2D2D2D, 0x878787, localization.continueDebug))
		continueButton.animated = false
		continueButton.onTouch = function()
			close()
			continue()
		end
		
		textBox:setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	end

	backgroundObject.eventHandler = function(mainContainer, object, eventData)
		if eventData[1] == "touch" then
			close()
		end
	end

	titleDebugMode = true
	mainContainer:drawOnScreen()

	for i = 1, times do
		computer.beep(frequency, 0.08)
	end
end

showErrorContainer = function(errorCode)
	local lines = string.wrap({errorCode}, title.width - 4)
	
	-- Извлекаем ошибочную строку текущего скрипта
	lastErrorLine = tonumber(errorCode:match("%:(%d+)%: in main chunk"))
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
	pizda(lines)
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

	pizda(lines, true)
end

local function launchWithArgumentsWindow()
	local container = addInputFadeContainer(localization.launchWithArguments, localization.arguments)

	container.input.onInputFinished = function()
		local arguments = {}
		container.input.text = container.input.text:gsub(",%s+", ",")
		for argument in container.input.text:gmatch("[^,]+") do
			table.insert(arguments, argument)
		end

		container:delete()
		mainContainer:drawOnScreen()

		run(table.unpack(arguments))
	end

	mainContainer:drawOnScreen()
end

local function deleteLine(line)
	if #codeView.lines > 1 then
		table.remove(codeView.lines, line)
	else
		codeView.lines[1] = ""
	end

	setCursorPositionAndClearSelection(1, cursorPositionLine)
	updateAutocompleteDatabaseFromFile()
end

local function deleteSpecifiedData(fromSymbol, fromLine, toSymbol, toLine)
	local upperLine = unicode.sub(codeView.lines[fromLine], 1, fromSymbol - 1)
	local lowerLine = unicode.sub(codeView.lines[toLine], toSymbol + 1, -1)
	for line = fromLine + 1, toLine do
		table.remove(codeView.lines, fromLine + 1)
	end
	codeView.lines[fromLine] = upperLine .. lowerLine
	setCursorPositionAndClearSelection(fromSymbol, fromLine)

	updateAutocompleteDatabaseFromFile()
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
			clipboard = { unicode.sub(codeView.lines[codeView.selections[1].from.line], codeView.selections[1].from.symbol, codeView.selections[1].to.symbol) }
		else
			clipboard = { unicode.sub(codeView.lines[codeView.selections[1].from.line], codeView.selections[1].from.symbol, -1) }
			for line = codeView.selections[1].from.line + 1, codeView.selections[1].to.line - 1 do
				table.insert(clipboard, codeView.lines[line])
			end
			table.insert(clipboard, unicode.sub(codeView.lines[codeView.selections[1].to.line], 1, codeView.selections[1].to.symbol))
		end
	end
end

local function cut()
	if codeView.selections[1] then
		copy()
		deleteSelectedData()
	end
end

local function paste(pasteLines)
	if pasteLines then
		if codeView.selections[1] then
			deleteSelectedData()
		end

		local firstPart = unicode.sub(codeView.lines[cursorPositionLine], 1, cursorPositionSymbol - 1)
		local secondPart = unicode.sub(codeView.lines[cursorPositionLine], cursorPositionSymbol, -1)

		if #pasteLines == 1 then
			codeView.lines[cursorPositionLine] = firstPart .. pasteLines[1] .. secondPart
			setCursorPositionAndClearSelection(cursorPositionSymbol + unicode.len(pasteLines[1]), cursorPositionLine)
		else
			codeView.lines[cursorPositionLine] = firstPart .. pasteLines[1]
			for pasteLine = #pasteLines - 1, 2, -1 do
				table.insert(codeView.lines, cursorPositionLine + 1, pasteLines[pasteLine])
			end
			table.insert(codeView.lines, cursorPositionLine + #pasteLines - 1, pasteLines[#pasteLines] .. secondPart)
			setCursorPositionAndClearSelection(unicode.len(pasteLines[#pasteLines]) + 1, cursorPositionLine + #pasteLines - 1)
		end

		updateAutocompleteDatabaseFromFile()
	end
end

local function selectAndPasteColor()
	local startColor = 0xFF0000
	if codeView.selections[1] and codeView.selections[1].from.line == codeView.selections[1].to.line then
		startColor = tonumber(unicode.sub(codeView.lines[codeView.selections[1].from.line], codeView.selections[1].from.symbol, codeView.selections[1].to.symbol)) or startColor
	end

	local palette = GUI.addPaletteWindowToContainer(mainContainer, startColor)
	palette.onSubmit = function()
		palette:delete()
		paste({string.format("0x%06X", palette.color.integer)})
	end
end

local function convertCase(method)
	if codeView.selections[1] then
		local from, to = codeView.selections[1].from, codeView.selections[1].to
		if from.line == to.line then
			codeView.lines[from.line] = unicode.sub(codeView.lines[from.line], 1, from.symbol - 1) .. unicode[method](unicode.sub(codeView.lines[from.line], from.symbol, to.symbol)) .. unicode.sub(codeView.lines[from.line], to.symbol + 1, -1)
		else
			codeView.lines[from.line] = unicode.sub(codeView.lines[from.line], 1, from.symbol - 1) .. unicode[method](unicode.sub(codeView.lines[from.line], from.symbol, -1))
			codeView.lines[to.line] = unicode[method](unicode.sub(codeView.lines[to.line], 1, to.symbol)) .. unicode.sub(codeView.lines[to.line], to.symbol + 1, -1)
			for line = from.line + 1, to.line - 1 do
				codeView.lines[line] = unicode[method](codeView.lines[line])
			end
		end
	end
end

local function pasteRegularChar(unicodeByte, char)
	if not keyboard.isControl(unicodeByte) then
		paste({char})
		if char == " " then
			updateAutocompleteDatabaseFromFile()
		end
		showAutocomplete()
	end
end

local function pasteAutoBrackets(unicodeByte)
	local char = unicode.char(unicodeByte)
	local currentSymbol = unicode.sub(codeView.lines[cursorPositionLine], cursorPositionSymbol, cursorPositionSymbol)

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
				local firstPart = unicode.sub(codeView.lines[codeView.selections[1].from.line], 1, codeView.selections[1].from.symbol - 1)
				local secondPart = unicode.sub(codeView.lines[codeView.selections[1].from.line], codeView.selections[1].from.symbol, -1)
				codeView.lines[codeView.selections[1].from.line] = firstPart .. char .. secondPart
				codeView.selections[1].from.symbol = codeView.selections[1].from.symbol + 1

				if codeView.selections[1].to.line == codeView.selections[1].from.line then
					codeView.selections[1].to.symbol = codeView.selections[1].to.symbol + 1
				end

				firstPart = unicode.sub(codeView.lines[codeView.selections[1].to.line], 1, codeView.selections[1].to.symbol)
				secondPart = unicode.sub(codeView.lines[codeView.selections[1].to.line], codeView.selections[1].to.symbol + 1, -1)
				codeView.lines[codeView.selections[1].to.line] = firstPart .. openBrackets[char] .. secondPart
				cursorPositionSymbol = cursorPositionSymbol + 2
			-- А тут мы делаем двойную автоскобку, если можем
			elseif openBrackets[char] and not currentSymbol:match("[%a%d%_]") then
				paste({char .. openBrackets[char]})
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

local function backspaceAutoBrackets()	
	local previousSymbol = unicode.sub(codeView.lines[cursorPositionLine], cursorPositionSymbol - 1, cursorPositionSymbol - 1)
	local currentSymbol = unicode.sub(codeView.lines[cursorPositionLine], cursorPositionSymbol, cursorPositionSymbol)
	if config.enableAutoBrackets and openBrackets[previousSymbol] and openBrackets[previousSymbol] == currentSymbol then
		deleteSpecifiedData(cursorPositionSymbol, cursorPositionLine, cursorPositionSymbol, cursorPositionLine)
	end
end

local function delete()
	if codeView.selections[1] then
		deleteSelectedData()
	else
		if cursorPositionSymbol < unicode.len(codeView.lines[cursorPositionLine]) + 1 then
			deleteSpecifiedData(cursorPositionSymbol, cursorPositionLine, cursorPositionSymbol, cursorPositionLine)
		else
			if cursorPositionLine > 1 and codeView.lines[cursorPositionLine + 1] then
				deleteSpecifiedData(unicode.len(codeView.lines[cursorPositionLine]) + 1, cursorPositionLine, 0, cursorPositionLine + 1)
			end
		end

		-- updateAutocompleteDatabaseFromFile()
		showAutocomplete()
	end
end

local function selectAll()
	codeView.selections[1] = {
		from = {
			symbol = 1, line = 1
		},
		to = {
			symbol = unicode.len(codeView.lines[#codeView.lines]), line = #codeView.lines
		}
	}
end

local function isLineCommented(line)
	if codeView.lines[line] == "" or codeView.lines[line]:match("%-%-%s?") then return true end
end

local function commentLine(line)
	codeView.lines[line] = "-- " .. codeView.lines[line]
end

local function uncommentLine(line)
	local countOfReplaces
	codeView.lines[line], countOfReplaces = codeView.lines[line]:gsub("%-%-%s?", "", 1)
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
	codeView.lines[line] = string.rep(" ", codeView.indentationWidth) .. codeView.lines[line]
end

local function unindentLine(line)
	codeView.lines[line], countOfReplaces = string.gsub(codeView.lines[line], "^" .. string.rep("%s", codeView.indentationWidth), "")
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
			indentLine(cursorPositionLine)
			setCursorPositionAndClearSelection(cursorPositionSymbol + codeView.indentationWidth, cursorPositionLine)
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
	
		for line = findStartFrom, #codeView.lines do
			local whereToFind, whatToFind = codeView.lines[line], searchInput.text
			if not caseSensitiveButton.pressed then
				whereToFind, whatToFind = unicode.lower(whereToFind), unicode.lower(whatToFind)
			end

			local success, starting, ending = pcall(string.unicodeFind, whereToFind, whatToFind)
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
				GUI.error("Wrong searching regex")
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
		mainContainer:draw()
		findFromFirstDisplayedLine()
	end
end

local function toggleTopToolBar()
	topToolBar.hidden = not topToolBar.hidden
	toggleTopToolBarButton.pressed = not topToolBar.hidden
	calculateSizes()
end

local function createEditOrRightClickMenu(x, y)
	local menu = GUI.contextMenu(x, y)
	
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
	
	local subMenu = menu:addSubMenu(localization.convertCase)
	
	subMenu:addItem(localization.toUpperCase, false, "^▲").onTouch = function()
		convertCase("upper")
	end

	subMenu:addItem(localization.toLowerCase, false, "^▼").onTouch = function()
		convertCase("lower")
	end

	menu:addSeparator()

	menu:addItem(localization.addBreakpoint, false, "F9").onTouch = function()
		addBreakpoint()
		mainContainer:drawOnScreen()
	end

	menu:addItem(localization.clearBreakpoints, not breakpointLines, "^F9").onTouch = function()
		clearBreakpoints()
	end

	menu:show()
end

codeView.eventHandler = function(mainContainer, object, eventData)
	if eventData[1] == "touch" then
		if eventData[5] == 1 then
			createEditOrRightClickMenu(eventData[3], eventData[4])
		else
			setCursorPositionAndClearSelection(convertScreenCoordinatesToTextPosition(eventData[3], eventData[4]))
		end

		tick(true)
	elseif eventData[1] == "double_touch" then
		selectWord()
		tick(true)
	elseif eventData[1] == "drag" then
		if eventData[5] ~= 1 then
			codeView.selections[1] = codeView.selections[1] or {from = {}, to = {}}
			codeView.selections[1].from.symbol, codeView.selections[1].from.line = cursorPositionSymbol, cursorPositionLine
			codeView.selections[1].to.symbol, codeView.selections[1].to.line = fixCursorPosition(convertScreenCoordinatesToTextPosition(eventData[3], eventData[4]))
			
			if codeView.selections[1].from.line > codeView.selections[1].to.line then
				codeView.selections[1].from.line, codeView.selections[1].to.line = codeView.selections[1].to.line, codeView.selections[1].from.line
				codeView.selections[1].from.symbol, codeView.selections[1].to.symbol = codeView.selections[1].to.symbol, codeView.selections[1].from.symbol
			elseif codeView.selections[1].from.line == codeView.selections[1].to.line then
				if codeView.selections[1].from.symbol > codeView.selections[1].to.symbol then
					codeView.selections[1].from.symbol, codeView.selections[1].to.symbol = codeView.selections[1].to.symbol, codeView.selections[1].from.symbol
				end
			end
		end

		tick(true)
	elseif eventData[1] == "key_down" then
		-- Ctrl or CMD
		if keyboard.isKeyDown(29) or keyboard.isKeyDown(219) then
			-- Slash
			if eventData[4] == 53 then
				toggleComment()
			-- ]
			elseif eventData[4] == 27 then
				config.enableAutoBrackets = not config.enableAutoBrackets
				saveConfig()
			-- I
			elseif eventData[4] == 23 then
				toggleEnableAutocompleteDatabase()
			-- A
			elseif eventData[4] == 30 then
				selectAll()
			-- C
			elseif eventData[4] == 46 then
				-- Shift
				if keyboard.isKeyDown(42) then
					selectAndPasteColor()
				else
					copy()
				end
			-- V
			elseif eventData[4] == 47 then
				paste(clipboard)
			-- X
			elseif eventData[4] == 45 then
				cut()
			-- W
			elseif eventData[4] == 17 then
				mainContainer:stopEventHandling()
			-- N
			elseif eventData[4] == 49 then
				newFile()
			-- O
			elseif eventData[4] == 24 then
				openFileWindow()
			-- U
			elseif eventData[4] == 22 and component.isAvailable("internet") then
				downloadFileFromWeb()
			-- Arrow UP
			elseif eventData[4] == 200 then
				convertCase("upper")
			-- Arrow DOWN
			elseif eventData[4] == 208 then
				convertCase("lower")
			-- S
			elseif eventData[4] == 31 then
				-- Shift
				if leftTreeView.selectedItem and not keyboard.isKeyDown(42) then
					saveFileWindow()
				else
					saveFileAsWindow()
				end
			-- F
			elseif eventData[4] == 33 then
				toggleBottomToolBar()
			-- G
			elseif eventData[4] == 34 then
				find()
			-- L
			elseif eventData[4] == 38 then
				gotoLineWindow()
			-- Backspace
			elseif eventData[4] == 14 then
				deleteLine(cursorPositionLine)
			-- Delete
			elseif eventData[4] == 211 then
				deleteLine(cursorPositionLine)
			-- R
			elseif eventData[4] == 19 then
				changeResolutionWindow()
			-- F5
			elseif eventData[4] == 63 then
				launchWithArgumentsWindow()
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
			if codeView.selections[1] then
				deleteSelectedData()
			else
				if cursorPositionSymbol > 1 then
					backspaceAutoBrackets()
					deleteSpecifiedData(cursorPositionSymbol - 1, cursorPositionLine, cursorPositionSymbol - 1, cursorPositionLine)
				else
					if cursorPositionLine > 1 then
						deleteSpecifiedData(unicode.len(codeView.lines[cursorPositionLine - 1]) + 1, cursorPositionLine - 1, 0, cursorPositionLine)
					end
				end

				-- updateAutocompleteDatabaseFromFile()
				showAutocomplete()
			end
		-- Tab
		elseif eventData[4] == 15 then
			if keyboard.isKeyDown(42) then
				indentOrUnindent(false)
			else
				indentOrUnindent(true)
			end
		-- Enter
		elseif eventData[4] == 28 then
			if autocomplete.hidden then
				local firstPart = unicode.sub(codeView.lines[cursorPositionLine], 1, cursorPositionSymbol - 1)
				local secondPart = unicode.sub(codeView.lines[cursorPositionLine], cursorPositionSymbol, -1)
				codeView.lines[cursorPositionLine] = firstPart
				table.insert(codeView.lines, cursorPositionLine + 1, secondPart)
				setCursorPositionAndClearSelection(1, cursorPositionLine + 1)
			else
				autocomplete.hidden = true
			end
		-- F5
		elseif eventData[4] == 63 then
			run()
		-- F9
		elseif eventData[4] == 67 then
			-- Shift
			if keyboard.isKeyDown(42) then
				clearBreakpoints()
			else
				addBreakpoint()
			end
		-- Home
		elseif eventData[4] == 199 then
			setCursorPositionToHome()
		-- End
		elseif eventData[4] == 207 then
			setCursorPositionToEnd()
		-- Page Up
		elseif eventData[4] == 201 then
			pageUp()
		-- Page Down
		elseif eventData[4] == 209 then
			pageDown()
		-- Delete
		elseif eventData[4] == 211 then
			delete()
		else
			pasteAutoBrackets(eventData[3])
		end

		tick(true)
	elseif eventData[1] == "scroll" then
		scroll(eventData[5], config.scrollSpeed)
		tick(cursorBlinkState)
	elseif eventData[1] == "clipboard" then
		paste(splitStringIntoLines(eventData[3]))
		tick(cursorBlinkState)
	elseif not eventData[1] then
		tick(not cursorBlinkState)
	end
end

leftTreeView.onItemSelected = function(path)
	mainContainer:drawOnScreen()
	loadFile(path)
	mainContainer:drawOnScreen()
end

local topMenuMineCode = topMenu:addItem("MineCode", 0x0)
topMenuMineCode.onTouch = function()
	local menu = GUI.contextMenu(topMenuMineCode.x, topMenuMineCode.y + 1)
	
	menu:addItem(localization.about).onTouch = function()
		local container = addFadeContainer(localization.about)
		
		local lines = {
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

		local textBox = container.layout:addChild(GUI.textBox(1, 1, 36, #lines, nil, 0xB4B4B4, lines, 1, 0, 0, true, false))
		textBox:setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
		textBox.eventHandler = nil

		mainContainer:drawOnScreen()
	end

	menu:addItem(localization.quit, false, "^W").onTouch = function()
		mainContainer:stopEventHandling()
	end

	menu:show()
end

local topMenuFile = topMenu:addItem(localization.file)
topMenuFile.onTouch = function()
	local menu = GUI.contextMenu(topMenuFile.x, topMenuFile.y + 1)
	
	menu:addItem(localization.new, false, "^N").onTouch = function()
		newFile()
		mainContainer:drawOnScreen()
	end

	menu:addItem(localization.open, false, "^O").onTouch = function()
		openFileWindow()
	end

	if component.isAvailable("internet") then
		menu:addItem(localization.getFromWeb, false, "^U").onTouch = function()
			downloadFileFromWeb()
		end
	end

	menu:addSeparator()

	menu:addItem(localization.save, not leftTreeView.selectedItem, "^S").onTouch = function()
		saveFileWindow()
	end

	menu:addItem(localization.saveAs, false, "^⇧S").onTouch = function()
		saveFileAsWindow()
	end

	menu:addItem(localization.launchWithArguments, false, "^F5").onTouch = function()
		launchWithArgumentsWindow()
	end

	menu:show()
end

local topMenuEdit = topMenu:addItem(localization.edit)
topMenuEdit.onTouch = function()
	createEditOrRightClickMenu(topMenuEdit.x, topMenuEdit.y + 1)
end

local topMenuGoto = topMenu:addItem(localization.gotoCyka)
topMenuGoto.onTouch = function()
	local menu = GUI.contextMenu(topMenuGoto.x, topMenuGoto.y + 1)
	
	menu:addItem(localization.pageUp, false, "PgUp").onTouch = function()
		pageUp()
	end
	
	menu:addItem(localization.pageDown, false, "PgDn").onTouch = function()
		pageDown()
	end

	menu:addItem(localization.gotoStart, false, "Home").onTouch = function()
		setCursorPositionToHome()
	end

	menu:addItem(localization.gotoEnd, false, "End").onTouch = function()
		setCursorPositionToEnd()
	end

	menu:addSeparator()

	menu:addItem(localization.gotoLine, false, "^L").onTouch = function()
		gotoLineWindow()
	end

	menu:show()
end

local topMenuProperties = topMenu:addItem(localization.properties)
topMenuProperties.onTouch = function()
	local menu = GUI.contextMenu(topMenuProperties.x, topMenuProperties.y + 1)
	
	menu:addItem(localization.colorScheme).onTouch = function()
		local container = GUI.addFadeContainer(mainContainer, true, false, localization.colorScheme)
					
		local colorSelectorsCount, colorSelectorCountX = 0, 4; for key in pairs(config.syntaxColorScheme) do colorSelectorsCount = colorSelectorsCount + 1 end
		local colorSelectorCountY = math.ceil(colorSelectorsCount / colorSelectorCountX)
		local colorSelectorWidth, colorSelectorHeight, colorSelectorSpaceX, colorSelectorSpaceY = math.floor(container.width / colorSelectorCountX * 0.8), 3, 2, 1
		
		local startX, y = math.floor(container.width / 2 - (colorSelectorCountX * (colorSelectorWidth + colorSelectorSpaceX) - colorSelectorSpaceX) / 2), math.floor(container.height / 2 - (colorSelectorCountY * (colorSelectorHeight + colorSelectorSpaceY) - colorSelectorSpaceY + 3) / 2)
		container:addChild(GUI.label(1, y, container.width, 1, 0xFFFFFF, localization.colorScheme)):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top); y = y + 3
		local x, counter = startX, 1

		local colors = {}
		for key in pairs(config.syntaxColorScheme) do
			table.insert(colors, {key})
		end

		aplhabeticalSort(colors)

		for i = 1, #colors do
			local colorSelector = container:addChild(GUI.colorSelector(x, y, colorSelectorWidth, colorSelectorHeight, config.syntaxColorScheme[colors[i][1]], colors[i][1]))
			colorSelector.onTouch = function()
				config.syntaxColorScheme[colors[i][1]] = colorSelector.color
				syntax.setColorScheme(config.syntaxColorScheme)
				saveConfig()
			end

			x, counter = x + colorSelectorWidth + colorSelectorSpaceX, counter + 1
			if counter > colorSelectorCountX then
				x, y, counter = startX, y + colorSelectorHeight + colorSelectorSpaceY, 1
			end
		end

		mainContainer:drawOnScreen()
	end

	menu:addItem(localization.cursorProperties).onTouch = function()
		local container = addFadeContainer(localization.cursorProperties)

		local input = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xC3C3C3, 0x787878, 0x787878, 0xC3C3C3, 0x2D2D2D, config.cursorSymbol, localization.cursorSymbol))
		input.onInputFinished = function()
			if #input.text == 1 then
				config.cursorSymbol = input.text
				saveConfig()
			end
		end

		local colorSelector = container.layout:addChild(GUI.colorSelector(1, 1, 36, 3, config.cursorColor, localization.cursorColor))
		colorSelector.onTouch = function()
			config.cursorColor = colorSelector.color
			saveConfig()
		end

		local slider = container.layout:addChild(GUI.slider(1, 1, 36, 0xFFDB80, 0x000000, 0xFFDB40, 0xDDDDDD, 1, 1000, config.cursorBlinkDelay * 1000, false, localization.cursorBlinkDelay .. ": ", " ms"))
		slider.onValueChanged = function()
			config.cursorBlinkDelay = slider.value / 1000
			saveConfig()
		end

		mainContainer:drawOnScreen()
	end

	if topToolBar.hidden then
		menu:addItem(localization.toggleTopToolBar).onTouch = function()
			toggleTopToolBar()
		end
	end

	menu:addSeparator()

	menu:addItem(config.enableAutoBrackets and localization.disableAutoBrackets or localization.enableAutoBrackets, false, "^]").onTouch = function()
		config.enableAutoBrackets = not config.enableAutoBrackets
		saveConfig()
	end

	menu:addItem(config.enableAutocompletion and localization.disableAutocompletion or localization.enableAutocompletion, false, "^I").onTouch = function()
		toggleEnableAutocompleteDatabase()
	end

	menu:addSeparator()

	menu:addItem(localization.changeResolution, false, "^R").onTouch = function()
		changeResolutionWindow()
	end

	menu:show()
end

leftTreeViewResizer.onResize = function(mainContainer, object, eventData, dragWidth, dragHeight)
	leftTreeView.width = leftTreeView.width + dragWidth
	calculateSizes()
end

leftTreeViewResizer.onResizeFinished = function()
	config.leftTreeViewWidth = leftTreeView.width
	saveConfig()
end

addBreakpointButton.onTouch = function()
	addBreakpoint()
	mainContainer:drawOnScreen()
end

syntaxHighlightingButton.onTouch = function()
	codeView.highlightLuaSyntax = not codeView.highlightLuaSyntax
	config.highlightLuaSyntax = codeView.highlightLuaSyntax
	saveConfig()
	mainContainer:drawOnScreen()
end

toggleLeftToolBarButton.onTouch = function()
	leftTreeView.hidden = not toggleLeftToolBarButton.pressed
	leftTreeViewResizer.hidden = leftTreeView.hidden
	calculateSizes()
	mainContainer:drawOnScreen()
end

toggleBottomToolBarButton.onTouch = function()
	bottomToolBar.hidden = not toggleBottomToolBarButton.pressed
	calculateSizes()
	mainContainer:drawOnScreen()
end

toggleTopToolBarButton.onTouch = function()
	topToolBar.hidden = not toggleTopToolBarButton.pressed
	calculateSizes()
	mainContainer:drawOnScreen()
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

autocomplete.onItemSelected = function(mainContainer, object, eventData)
	local firstPart = unicode.sub(codeView.lines[cursorPositionLine], 1, autoCompleteWordStart - 1)
	local secondPart = unicode.sub(codeView.lines[cursorPositionLine], autoCompleteWordEnd + 1, -1)
	local middle = firstPart .. autocomplete.items[autocomplete.selectedItem]
	codeView.lines[cursorPositionLine] = middle .. secondPart

	setCursorPositionAndClearSelection(unicode.len(middle) + 1, cursorPositionLine)
	
	if eventData[1] == "key_down" then
		autocomplete.hidden = false
	end

	tick(true)
end

searchInput.onInputFinished = findFromFirstDisplayedLine
caseSensitiveButton.onTouch = find
searchButton.onTouch = find

------------------------------------------------------------

autocomplete:moveToFront()
leftTreeView:updateFileList()

changeResolution(config.screenResolution.width, config.screenResolution.height)
updateTitle()
updateRAMProgressBar()
mainContainer:drawOnScreen()

if args[1] and fs.exists(args[1]) then
	loadFile(args[1])
else
	newFile()
end

mainContainer:drawOnScreen()
mainContainer:startEventHandling(config.cursorBlinkDelay)


