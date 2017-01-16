
---------------------------------------------------- Libraries ----------------------------------------------------

-- "/MineOS/Applications/MineCode IDE.app/MineCode IDE.lua" open OS.luaad

-- package.loaded.syntax = nil
-- package.loaded.GUI = nil
-- package.loaded.windows = nil
-- package.loaded.MineOSCore = nil

require("advancedLua")
local computer = require("computer")
local component = require("component")
local gpu = component.gpu
local fs = require("filesystem")
local buffer = require("doubleBuffering")
local GUI = require("GUI")
local windows = require("windows")
local MineOSCore = require("MineOSCore")
local event = require("event")
local syntax = require("syntax")
local unicode = require("unicode")
local ecs = require("ECSAPI")
local image = require("image")
local keyboard = require("keyboard")

---------------------------------------------------- Constants ----------------------------------------------------

local args = {...}

local config = {
	colorScheme = {
		topToolBar = 0xDDDDDD,
		bottomToolBar = {
			background = 0x3C3C3C,
			buttons = 0x2D2D2D,
			buttonsText = 0xFFFFFF,
		},
		topMenu = {
			backgroundColor = 0xEEEEEE,
			textColor = 0x444444,
			backgroundPressedColor = 0x3366CC,
			textPressedColor = 0xFFFFFF,
		},
		title = {
			default = {
				background = 0x3C3C3C,
				text = 0xEEEEEE
			},
			warning = {
				background = 0x880000,
				text = 0xEEEEEE,
			}
		},
		leftTreeView = {
			background = 0xCCCCCC,
		}
	},
	syntaxColorScheme = syntax.colorScheme,
	scrollSpeed = 8,
	cursorColor = 0x00A8FF,
	cursorSymbol = "┃",
	cursorBlinkDelay = 0.4,
	doubleClickDelay = 0.4,
}

local cursor = {
	position = {
		symbol = 20,
		line = 8
	},
	blinkState = false
}

local resourcesPath = MineOSCore.getCurrentApplicationResourcesDirectory() 
local configPath = resourcesPath .. "Config.cfg"
local localization = MineOSCore.getLocalization(resourcesPath .. "Localization/")
local findStartFrom
local workPath
local clipboard
local lastErrorLine
local lastClickUptime = computer.uptime()
local mainWindow = {}

---------------------------------------------------- Functions ----------------------------------------------------

local function saveConfig()
	table.toFile(configPath, config)
end

local function loadConfig()
	if fs.exists(configPath) then
		config = table.fromFile(configPath)
		syntax.colorScheme = config.syntaxColorScheme
	else
		saveConfig()
	end
end

local function calculateSizes()
	mainWindow.leftTreeView.width = math.floor(mainWindow.width * 0.16)

	if mainWindow.leftTreeView.isHidden then
		mainWindow.codeView.localPosition.x, mainWindow.codeView.width = 1, mainWindow.width
		mainWindow.bottomToolBar.localPosition.x, mainWindow.bottomToolBar.width = mainWindow.codeView.localPosition.x, mainWindow.codeView.width
	else
		mainWindow.codeView.localPosition.x, mainWindow.codeView.width = mainWindow.leftTreeView.width + 1, mainWindow.width - mainWindow.leftTreeView.width
		mainWindow.bottomToolBar.localPosition.x, mainWindow.bottomToolBar.width = mainWindow.codeView.localPosition.x, mainWindow.codeView.width
	end

	if mainWindow.topToolBar.isHidden then
		mainWindow.leftTreeView.localPosition.y, mainWindow.leftTreeView.height = 2, mainWindow.height - 1
		mainWindow.codeView.localPosition.y, mainWindow.codeView.height = 2, mainWindow.height - 1
		mainWindow.errorMessage.localPosition.y = 2
	else
		mainWindow.leftTreeView.localPosition.y, mainWindow.leftTreeView.height = 5, mainWindow.height - 4
		mainWindow.codeView.localPosition.y, mainWindow.codeView.height = 5, mainWindow.height - 4
		mainWindow.errorMessage.localPosition.y = 5
	end

	if mainWindow.bottomToolBar.isHidden then

	else
		mainWindow.codeView.height = mainWindow.codeView.height - 3
	end


	mainWindow.bottomToolBar.localPosition.y = mainWindow.height - 2
	mainWindow.bottomToolBar.findButton.localPosition.x = mainWindow.bottomToolBar.width - mainWindow.bottomToolBar.findButton.width + 1
	mainWindow.bottomToolBar.inputTextBox.width = mainWindow.bottomToolBar.width - mainWindow.bottomToolBar.inputTextBox.localPosition.x - mainWindow.bottomToolBar.findButton.width + 1

	mainWindow.topToolBar.width, mainWindow.topToolBar.backgroundPanel.width = mainWindow.width, mainWindow.width
	mainWindow.titleTextBox.width = math.floor(mainWindow.topToolBar.width * 0.32)
	mainWindow.titleTextBox.localPosition.x = math.floor(mainWindow.topToolBar.width / 2 - mainWindow.titleTextBox.width / 2)
	mainWindow.runButton.localPosition.x = mainWindow.titleTextBox.localPosition.x - mainWindow.runButton.width - 2
	mainWindow.toggleSyntaxHighlightingButton.localPosition.x = mainWindow.runButton.localPosition.x - mainWindow.toggleSyntaxHighlightingButton.width - 2
	mainWindow.toggleLeftToolBarButton.localPosition.x = mainWindow.titleTextBox.localPosition.x + mainWindow.titleTextBox.width + 2
	mainWindow.toggleBottomToolBarButton.localPosition.x = mainWindow.toggleLeftToolBarButton.localPosition.x + mainWindow.toggleLeftToolBarButton.width + 2
	mainWindow.toggleTopToolBarButton.localPosition.x = mainWindow.toggleBottomToolBarButton.localPosition.x + mainWindow.toggleBottomToolBarButton.width + 2

	mainWindow.errorMessage.localPosition.x, mainWindow.errorMessage.width = mainWindow.titleTextBox.localPosition.x, mainWindow.titleTextBox.width
	mainWindow.errorMessage.backgroundPanel.width, mainWindow.errorMessage.errorTextBox.width = mainWindow.errorMessage.width, mainWindow.errorMessage.width - 4

	mainWindow.topMenu.width = mainWindow.width
end

local function showErrorMessage(text)
	mainWindow.errorMessage.errorTextBox.lines = string.wrap({text}, mainWindow.errorMessage.errorTextBox.width)
	mainWindow.errorMessage.height = 2 + #mainWindow.errorMessage.errorTextBox.lines
	mainWindow.errorMessage.backgroundPanel.height = mainWindow.errorMessage.height
	mainWindow.errorMessage.errorTextBox.height = mainWindow.errorMessage.height - 2
	
	mainWindow.titleTextBox.colors.background, mainWindow.titleTextBox.colors.text = config.colorScheme.title.warning.background, config.colorScheme.title.warning.text

	for i = 1, 3 do component.computer.beep(1500, 0.08) end
	mainWindow.errorMessage.isHidden = false
end

local function hideErrorMessage()
	mainWindow.titleTextBox.colors.background = config.colorScheme.title.default.background
	mainWindow.titleTextBox.colors.text = config.colorScheme.title.default.text
	mainWindow.errorMessage.isHidden = true
end

local function deselectLastErrorLine()
	if lastErrorLine then mainWindow.codeView.highlights[lastErrorLine] = nil end
end

local function clearSelection()
	mainWindow.codeView.selections[1] = nil
end

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
	deselectLastErrorLine()
	hideErrorMessage()
end

local function setCursorPositionAndClearSelection(symbol, line)
	setCursorPosition(symbol, line)
	clearSelection()
end

local function convertScreenCoordinatesToCursorPosition(x, y)
	return x - mainWindow.codeView.codeAreaPosition + mainWindow.codeView.fromSymbol - 1, y - mainWindow.codeView.y + mainWindow.codeView.fromLine
end

local function isClickedOnCodeArea(x, y)
	return
		x >= mainWindow.codeView.codeAreaPosition and
		y >= mainWindow.codeView.y and
		x < mainWindow.width and
		y < mainWindow.codeView.y + mainWindow.codeView.height - 1
end

local function moveCursor(symbolOffset, lineOffset)
	local newSymbol, newLine = cursor.position.symbol + symbolOffset, cursor.position.line + lineOffset
	
	if symbolOffset < 0 and newSymbol < 1 then
		newLine, newSymbol = newLine - 1, math.huge
	elseif symbolOffset > 0 and newSymbol > unicode.len(mainWindow.codeView.lines[newLine] or "") + 1 then
		newLine, newSymbol = newLine + 1, 1
	end

	setCursorPositionAndClearSelection(newSymbol, newLine)
end

local function setCursorPositionToHome()
	setCursorPositionAndClearSelection(1, 1)
end

local function setCursorPositionToEnd()
	setCursorPositionAndClearSelection(unicode.len(mainWindow.codeView.lines[#mainWindow.codeView.lines]) + 1, #mainWindow.codeView.lines)
end

local function pageUp()
	scroll(1, mainWindow.codeView.height - 2)
end

local function pageDown()
	scroll(-1, mainWindow.codeView.height - 2)
end

local function scroll(direction, speed)
	if direction == 1 then
		if mainWindow.codeView.fromLine > speed then
			mainWindow.codeView.fromLine = mainWindow.codeView.fromLine - speed
		else
			mainWindow.codeView.fromLine = 1
		end
	else
		if mainWindow.codeView.fromLine < #mainWindow.codeView.lines - speed then
			mainWindow.codeView.fromLine = mainWindow.codeView.fromLine + speed
		else
			mainWindow.codeView.fromLine = #mainWindow.codeView.lines
		end
	end
end

local function gotoLine(line)
	mainWindow.codeView.fromLine = math.floor(line - mainWindow.codeView.height / 2) + 1
	if mainWindow.codeView.fromLine < 1 then
		mainWindow.codeView.fromLine = 1
	elseif mainWindow.codeView.fromLine > #mainWindow.codeView.lines then
		mainWindow.codeView.fromLine = #mainWindow.codeView.lines
	end
end

local function selectWord()
	local shittySymbolsRegexp, from, to = "[%s%c%p]"

	for i = cursor.position.symbol, 1, -1 do
		if unicode.sub(mainWindow.codeView.lines[cursor.position.line], i, i):match(shittySymbolsRegexp) then break end
		from = i
	end

	for i = cursor.position.symbol, unicode.len(mainWindow.codeView.lines[cursor.position.line]) do
		if unicode.sub(mainWindow.codeView.lines[cursor.position.line], i, i):match(shittySymbolsRegexp) then break end
		to = i
	end

	if from and to then
		mainWindow.codeView.selections[1] = {
			from = {symbol = from, line = cursor.position.line},
			to = {symbol = to, line = cursor.position.line},
		}
	end
end

local function removeTabs(text)
	local result = text:gsub("\t", string.rep(" ", mainWindow.codeView.indentationWidth))
	return result
end

local function loadFile(path)
	mainWindow.codeView.fromLine, mainWindow.codeView.fromSymbol, mainWindow.codeView.lines, mainWindow.codeView.maximumLineLength = 1, 1, {}, 0
	local file = io.open(path, "r")
	for line in file:lines() do
		line = removeTabs(line)
		table.insert(mainWindow.codeView.lines, line)
		mainWindow.codeView.maximumLineLength = math.max(mainWindow.codeView.maximumLineLength, unicode.len(line))
	end
	file:close()
	workPath = path
	mainWindow.leftTreeView.currentFile = workPath
	if #mainWindow.codeView.lines == 0 then table.insert(mainWindow.codeView.lines, "") end
	setCursorPositionAndClearSelection(1, 1)
end

local function saveFile(path)
	fs.makeDirectory(fs.path(path))
	local file = io.open(path, "w")
	for line = 1, #mainWindow.codeView.lines do
		file:write(mainWindow.codeView.lines[line], "\n")
	end
	file:close()
end

local function newFile()
	mainWindow.codeView.lines = {""}
	mainWindow.leftTreeView.currentFile = ""
	workPath = nil
	setCursorPositionAndClearSelection(1, 1)
end

local function open()
	local data = ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true,
		{"EmptyLine"},
		{"CenterText", 0x000000, localization.openFile},
		{"EmptyLine"},
		{"Input", 0x262626, 0x880000, ""},
		{"EmptyLine"},
		{"Button", {0xAAAAAA, 0xffffff, "OK"}, {0x888888, 0xffffff, MineOSCore.localization.cancel}}
	)
	if data[2] == "OK" and fs.exists(data[1]) then
		loadFile(data[1])
	end
end

local function saveAs()
	local data = ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true,
		{"EmptyLine"},
		{"CenterText", 0x000000, localization.saveAs},
		{"EmptyLine"},
		{"Input", 0x262626, 0x880000, ""},
		{"EmptyLine"},
		{"Button", {0xAAAAAA, 0xffffff, "OK"}, {0x888888, 0xffffff, MineOSCore.localization.cancel}}
	)
	if data[2] == "OK" then
		saveFile(data[1])
		workPath = data[1]
		mainWindow.leftTreeView.workPath = workPath
	end
end

local function save()
	saveFile(workPath)
end

local function run()
	deselectLastErrorLine()

	local loadSuccess, loadReason = load(table.concat(mainWindow.codeView.lines, "\n"))
	if loadSuccess then
		local oldResolutionX, oldResolutionY = gpu.getResolution()
		gpu.setBackground(0x262626); gpu.setForeground(0xFFFFFF); gpu.fill(1, 1, oldResolutionX, oldResolutionY, " "); require("term").setCursor(1, 1)
		
		local xpcallSuccess, xpcallReason = xpcall(loadSuccess, debug.traceback)
		local xpcallReasonType = type(xpcallReason)
		if xpcallSuccess or xpcallReasonType == "table" then
			MineOSCore.waitForPressingAnyKey()
		end

		gpu.setResolution(oldResolutionX, oldResolutionY)
		buffer.start()
		mainWindow:draw()

		if not xpcallSuccess and xpcallReasonType ~= "table" then
			showErrorMessage(xpcallReason)
		end

		buffer:draw()		
	else
		local match = string.match(loadReason, ":(%d+)%:")
		lastErrorLine = tonumber(match)
		mainWindow.codeView.highlights[lastErrorLine] = 0xFF4444
		gotoLine(lastErrorLine)
		showErrorMessage(loadReason)
	end
end

local function deleteLine(line)
	if #mainWindow.codeView.lines > 1 then
		table.remove(mainWindow.codeView.lines, line)
		setCursorPositionAndClearSelection(1, cursor.position.line)
	end
end

local function deleteSpecifiedData(fromSymbol, fromLine, toSymbol, toLine)
	local upperLine = unicode.sub(mainWindow.codeView.lines[fromLine], 1, fromSymbol - 1)
	local lowerLine = unicode.sub(mainWindow.codeView.lines[toLine], toSymbol + 1, -1)
	for line = fromLine + 1, toLine do
		table.remove(mainWindow.codeView.lines, fromLine + 1)
	end
	mainWindow.codeView.lines[fromLine] = upperLine .. lowerLine
	setCursorPositionAndClearSelection(fromSymbol, fromLine)
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
	if pasteLines then
		if mainWindow.codeView.selections[1] then
			deleteSelectedData()
		end

		local firstPart = unicode.sub(mainWindow.codeView.lines[cursor.position.line], 1, cursor.position.symbol - 1)
		local secondPart = unicode.sub(mainWindow.codeView.lines[cursor.position.line], cursor.position.symbol, -1)

		if #pasteLines == 1 then
			mainWindow.codeView.lines[cursor.position.line] = firstPart .. pasteLines[1] .. secondPart
			setCursorPositionAndClearSelection(cursor.position.symbol + unicode.len(pasteLines[1]), cursor.position.line)
		else
			mainWindow.codeView.lines[cursor.position.line] = firstPart .. pasteLines[1]
			for pasteLine = #pasteLines - 1, 2, -1 do
				table.insert(mainWindow.codeView.lines, cursor.position.line + 1, pasteLines[pasteLine])
			end
			table.insert(mainWindow.codeView.lines, cursor.position.line + #pasteLines - 1, pasteLines[#pasteLines] .. secondPart)
			setCursorPositionAndClearSelection(unicode.len(pasteLines[#pasteLines]) + 1, cursor.position.line + #pasteLines - 1)
		end
	end
end

local function delete()
	if mainWindow.codeView.selections[1] then
		deleteSelectedData()
	else
		if cursor.position.symbol < unicode.len(mainWindow.codeView.lines[cursor.position.line]) - 1 then
			deleteSpecifiedData(cursor.position.symbol, cursor.position.line, cursor.position.symbol, cursor.position.line)
		else
			if cursor.position.line > 1 then
				deleteSpecifiedData(unicode.len(mainWindow.codeView.lines[cursor.position.line]) + 1, cursor.position.line, 0, cursor.position.line + 1)
			end
		end
	end
end

local function backspace()
	if mainWindow.codeView.selections[1] then
		deleteSelectedData()
	else
		if cursor.position.symbol > 1 then
			deleteSpecifiedData(cursor.position.symbol - 1, cursor.position.line, cursor.position.symbol - 1, cursor.position.line)
		else
			if cursor.position.line > 1 then
				deleteSpecifiedData(unicode.len(mainWindow.codeView.lines[cursor.position.line - 1]) + 1, cursor.position.line - 1, 0, cursor.position.line)
			end
		end
	end
end

local function enter()
	local firstPart = unicode.sub(mainWindow.codeView.lines[cursor.position.line], 1, cursor.position.symbol - 1)
	local secondPart = unicode.sub(mainWindow.codeView.lines[cursor.position.line], cursor.position.symbol, -1)
	mainWindow.codeView.lines[cursor.position.line] = firstPart
	table.insert(mainWindow.codeView.lines, cursor.position.line + 1, secondPart)
	setCursorPositionAndClearSelection(1, cursor.position.line + 1)
end

local function selectAll()
	mainWindow.codeView.selections[1] = {from = {}, to = {}}
	mainWindow.codeView.selections[1].from.symbol, mainWindow.codeView.selections[1].from.line = 1, 1
	mainWindow.codeView.selections[1].to.symbol, mainWindow.codeView.selections[1].to.line = unicode.len(mainWindow.codeView.lines[#mainWindow.codeView.lines]), #mainWindow.codeView.lines
end

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
				setCursorPositionAndClearSelection(cursor.position.symbol - 3, cursor.position.line)
			end
		else
			commentLine(cursor.position.line)
			setCursorPositionAndClearSelection(cursor.position.symbol + 3, cursor.position.line)
		end
	end
end

local function indentLine(line)
	mainWindow.codeView.lines[line] = string.rep(" ", mainWindow.codeView.indentationWidth) .. mainWindow.codeView.lines[line]
end

local function unindentLine(line)
	mainWindow.codeView.lines[line], countOfReplaces = string.gsub(mainWindow.codeView.lines[line], "^" .. string.rep("%s", mainWindow.codeView.indentationWidth), "")
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
			setCursorPosition(cursor.position.symbol + mainWindow.codeView.indentationWidth, cursor.position.line)
			mainWindow.codeView.selections[1].from.symbol, mainWindow.codeView.selections[1].to.symbol = mainWindow.codeView.selections[1].from.symbol + mainWindow.codeView.indentationWidth, mainWindow.codeView.selections[1].to.symbol + mainWindow.codeView.indentationWidth
		else
			if countOfReplacesInFirstLine > 0 then
				mainWindow.codeView.selections[1].from.symbol = mainWindow.codeView.selections[1].from.symbol - mainWindow.codeView.indentationWidth
				if cursor.position.line == mainWindow.codeView.selections[1].from.line then
					setCursorPosition(cursor.position.symbol - mainWindow.codeView.indentationWidth, cursor.position.line)
				end
			end

			if countOfReplacesInLastLine > 0 then
				mainWindow.codeView.selections[1].to.symbol = mainWindow.codeView.selections[1].to.symbol - mainWindow.codeView.indentationWidth
				if cursor.position.line == mainWindow.codeView.selections[1].to.line then
					setCursorPosition(cursor.position.symbol - mainWindow.codeView.indentationWidth, cursor.position.line)
				end
			end
		end
	else
		if isIndent then
			indentLine(cursor.position.line)
			setCursorPositionAndClearSelection(cursor.position.symbol + mainWindow.codeView.indentationWidth, cursor.position.line)
		else
			if unindentLine(cursor.position.line) > 0 then
				setCursorPositionAndClearSelection(cursor.position.symbol - mainWindow.codeView.indentationWidth, cursor.position.line)
			end
		end
	end
end

local function updateTitle()
	mainWindow.titleTextBox.lines[1] = string.limit(localization.file .. ": " .. (workPath or localization.none), mainWindow.titleTextBox.width - 2)
	mainWindow.titleTextBox.lines[2] = string.limit(localization.cursor .. cursor.position.line .. localization.line .. cursor.position.symbol .. localization.symbol, mainWindow.titleTextBox.width - 2)
	if mainWindow.codeView.selections[1] then
		local countOfSelectedLines = mainWindow.codeView.selections[1].to.line - mainWindow.codeView.selections[1].from.line + 1
		local countOfSelectedSymbols
		if mainWindow.codeView.selections[1].from.line == mainWindow.codeView.selections[1].to.line then
			countOfSelectedSymbols = unicode.len(unicode.sub(mainWindow.codeView.lines[mainWindow.codeView.selections[1].from.line], mainWindow.codeView.selections[1].from.symbol, mainWindow.codeView.selections[1].to.symbol))
		else
			countOfSelectedSymbols = unicode.len(unicode.sub(mainWindow.codeView.lines[mainWindow.codeView.selections[1].from.line], mainWindow.codeView.selections[1].from.symbol, -1))
			for line = mainWindow.codeView.selections[1].from.line + 1, mainWindow.codeView.selections[1].to.line - 1 do
				countOfSelectedSymbols = countOfSelectedSymbols + unicode.len(mainWindow.codeView.lines[line])
			end
			countOfSelectedSymbols = countOfSelectedSymbols + unicode.len(unicode.sub(mainWindow.codeView.lines[mainWindow.codeView.selections[1].to.line], 1, mainWindow.codeView.selections[1].to.symbol))
		end
		mainWindow.titleTextBox.lines[3] = string.limit(localization.selection .. countOfSelectedLines .. localization.lines .. countOfSelectedSymbols .. localization.symbols, mainWindow.titleTextBox.width - 2)
	else
		mainWindow.titleTextBox.lines[3] = string.limit(localization.selection .. localization.none, mainWindow.titleTextBox.width - 2)
	end
end

local function find()
	if not mainWindow.bottomToolBar.isHidden and mainWindow.bottomToolBar.inputTextBox.text ~= "" then
		findStartFrom = findStartFrom + 1
	
		for line = findStartFrom, #mainWindow.codeView.lines do
			local whereToFind, whatToFind = mainWindow.codeView.lines[line], mainWindow.bottomToolBar.inputTextBox.text
			if not mainWindow.bottomToolBar.caseSensitiveButton.pressed then
				whereToFind, whatToFind = unicode.lower(whereToFind), unicode.lower(whatToFind)
			end

			local success, starting, ending = pcall(string.unicodeFind, whereToFind, whatToFind)
			if success then
				if starting then
					mainWindow.codeView.selections[1] = {
						from = {symbol = starting, line = line},
						to = {symbol = ending, line = line},
						color = 0xCC9200
					}
					findStartFrom = line
					gotoLine(line)
					return
				end
			else
				GUI.error("Wrong searching regex", {title = {color = 0xFFDB40, text = "Warning"}})
			end
		end

		findStartFrom = 0
	end
end

local function findFromFirstDisplayedLine()
	findStartFrom = mainWindow.codeView.fromLine
	find()
end

local function toggleBottomToolBar()
	mainWindow.bottomToolBar.isHidden = not mainWindow.bottomToolBar.isHidden
	mainWindow.toggleBottomToolBarButton.pressed = not mainWindow.bottomToolBar.isHidden
	calculateSizes()
		
	if not mainWindow.bottomToolBar.isHidden then
		mainWindow:draw()
		mainWindow.bottomToolBar.inputTextBox:input()
		findFromFirstDisplayedLine()
	end
end

local function toggleTopToolBar()
	mainWindow.topToolBar.isHidden = not mainWindow.topToolBar.isHidden
	mainWindow.toggleTopToolBarButton.pressed = not mainWindow.topToolBar.isHidden
	calculateSizes()
end

local function toggleLeftToolBar()
	mainWindow.leftTreeView.isHidden = not mainWindow.leftTreeView.isHidden
	mainWindow.toggleLeftToolBarButton.pressed = not mainWindow.leftTreeView.isHidden
	calculateSizes()
end

local function createWindow()
	mainWindow = windows.fullScreen()

	mainWindow.codeView = mainWindow:addCodeView(1, 1, 1, 1, {""}, 1, 1, 1, {}, {}, true, 2)
	mainWindow.codeView.scrollBars.vertical.onTouch = function()
		mainWindow.codeView.fromLine = mainWindow.codeView.scrollBars.vertical.value
	end
	mainWindow.codeView.scrollBars.horizontal.onTouch = function()
		mainWindow.codeView.fromSymbol = mainWindow.codeView.scrollBars.horizontal.value
	end
	mainWindow.topMenu = mainWindow:addMenu(1, 1, 1, config.colorScheme.topMenu.backgroundColor, config.colorScheme.topMenu.textColor, config.colorScheme.topMenu.backgroundPressedColor, config.colorScheme.topMenu.textPressedColor)
	
	local item1 = mainWindow.topMenu:addItem("MineCode", 0x0)
	item1.onTouch = function()
		local menu = GUI.contextMenu(item1.x, item1.y + 1)
		menu:addItem(localization.about, true).onTouch = function()
			
		end
		menu:addItem(localization.quit, false, "^W").onTouch = function()
			mainWindow:close()
		end
		menu:show()
	end

	local item2 = mainWindow.topMenu:addItem(localization.file)
	item2.onTouch = function()
		local menu = GUI.contextMenu(item2.x, item2.y + 1)
		menu:addItem(localization.new, false, "^N").onTouch = function()
			newFile()
		end
		menu:addItem(localization.open, false, "^O").onTouch = function()
			open()
		end
		menu:addSeparator()
		menu:addItem(localization.save, not workPath, "^S").onTouch = function()
			save()
		end
		menu:addItem(localization.saveAs, false, "^⇧S").onTouch = function()
			saveAs()
		end
		menu:show()
	end

	local item3 = mainWindow.topMenu:addItem(localization.edit)
	item3.onTouch = function()
		local menu = GUI.contextMenu(item3.x, item3.y + 1)
		menu:addItem(localization.cut, not mainWindow.codeView.selections[1], "^X").onTouch = function()
			cut()
		end
		menu:addItem(localization.copy, not mainWindow.codeView.selections[1], "^C").onTouch = function()
			copy()
		end
		menu:addItem(localization.paste, not clipboard, "^V").onTouch = function()
			paste(clipboard)
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
			deleteLine(cursor.position.line)
		end
		menu:addSeparator()
		menu:addItem(localization.selectWord, false, "^\\").onTouch = function()
			selectWord()
		end
		menu:addItem(localization.selectAll, false, "^A").onTouch = function()
			selectAll()
		end
		menu:show()
	end

	local item4 = mainWindow.topMenu:addItem(localization.view)
	item4.onTouch = function()
		local menu = GUI.contextMenu(item4.x, item4.y + 1)
		menu:addItem(localization.colorScheme).onTouch = function()
			local variants = {}
			for key in pairs(config.syntaxColorScheme) do
				table.insert(variants, key)
			end
			
			local data = ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true,
				{"EmptyLine"},
				{"CenterText", 0x000000, localization.colorScheme},
				{"EmptyLine"},
				{"Selector", 0x262626, 0x880000, table.unpack(variants)},
				{"Color", localization.color, 0x000000},
				{"EmptyLine"},
				{"Button", {0xAAAAAA, 0xffffff, "OK"}, {0x888888, 0xffffff, MineOSCore.localization.cancel}}
			)

			if data[#data] == "OK" then
				config.syntaxColorScheme[data[1]] = data[2]
				syntax.colorScheme = config.syntaxColorScheme
				saveConfig()
			end
		end
		menu:addItem(localization.cursorProperties).onTouch = function()
			local data = ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true,
				{"EmptyLine"},
				{"CenterText", 0x000000, localization.cursorProperties},
				{"EmptyLine"},
				{"Input", 0x262626, 0x880000, config.cursorSymbol},
				{"Color", localization.cursorColor, config.cursorColor},
				{"Slider", 0x262626, 0x880000, 1, 100, config.cursorBlinkDelay * 100, localization.cursorBlinkDelay .. ": ", " ms"},
				{"EmptyLine"},
				{"Button", {0xAAAAAA, 0xffffff, "OK"}, {0x888888, 0xffffff, MineOSCore.localization.cancel}}
			)

			if data[#data] == "OK" then
				config.cursorSymbol = data[1]
				config.cursorColor = data[2]
				config.cursorBlinkDelay = data[3] / 100
				saveConfig()
			end
		end
		menu:addSeparator()
		menu:addItem(localization.toggleLeftToolBar).onTouch = function()
			toggleLeftToolBar()
		end
		menu:addItem(localization.toggleBottomToolBar).onTouch = function()
			toggleBottomToolBar()
		end
		menu:addItem(localization.toggleTopToolBar).onTouch = function()
			toggleTopToolBar()
		end
		menu:show()
	end

	local item5 = mainWindow.topMenu:addItem(localization.gotoCyka)
	item5.onTouch = function()
		local menu = GUI.contextMenu(item5.x, item5.y + 1)
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
		menu:show()
	end

	mainWindow.topToolBar = mainWindow:addContainer(1, 2, 1, 3)
	mainWindow.topToolBar.backgroundPanel = mainWindow.topToolBar:addPanel(1, 1, 1, 3, config.colorScheme.topToolBar)
	mainWindow.titleTextBox = mainWindow.topToolBar:addTextBox(1, 1, 1, 3, 0x0, 0x0, {}, 1):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	
	mainWindow.runButton = mainWindow.topToolBar:addAdaptiveButton(1, 1, 3, 1, 0x4B4B4B, 0xEEEEEE, 0xCCCCCC, 0x444444, "▷")
	mainWindow.runButton.onTouch = function()
		run()
	end

	mainWindow.toggleSyntaxHighlightingButton = mainWindow.topToolBar:addAdaptiveButton(1, 1, 3, 1, 0xCCCCCC, 0x444444, 0x5A5A5A, 0xEEEEEE, "*")
	mainWindow.toggleSyntaxHighlightingButton.switchMode, mainWindow.toggleSyntaxHighlightingButton.pressed = true, true
	mainWindow.toggleSyntaxHighlightingButton.onTouch = function()
		mainWindow.codeView.highlightLuaSyntax = not mainWindow.codeView.highlightLuaSyntax
	end

	mainWindow.toggleLeftToolBarButton = mainWindow.topToolBar:addAdaptiveButton(1, 1, 3, 1, 0xCCCCCC, 0x444444, 0x4B4B4B, 0xEEEEEE, "⇦")
	mainWindow.toggleLeftToolBarButton.switchMode, mainWindow.toggleLeftToolBarButton.pressed = true, true
	mainWindow.toggleLeftToolBarButton.onTouch = function()
		mainWindow.leftTreeView.isHidden = not mainWindow.toggleLeftToolBarButton.pressed
		calculateSizes()
	end

	mainWindow.toggleBottomToolBarButton = mainWindow.topToolBar:addAdaptiveButton(1, 1, 3, 1, 0xCCCCCC, 0x444444, 0x5A5A5A, 0xEEEEEE, "⇩")
	mainWindow.toggleBottomToolBarButton.switchMode, mainWindow.toggleBottomToolBarButton.pressed = true, false
	mainWindow.toggleBottomToolBarButton.onTouch = function()
		mainWindow.bottomToolBar.isHidden = not mainWindow.toggleBottomToolBarButton.pressed
		calculateSizes()
	end

	mainWindow.toggleTopToolBarButton = mainWindow.topToolBar:addAdaptiveButton(1, 1, 3, 1, 0xCCCCCC, 0x444444, 0x696969, 0xEEEEEE, "⇧")
	mainWindow.toggleTopToolBarButton.switchMode, mainWindow.toggleTopToolBarButton.pressed = true, true
	mainWindow.toggleTopToolBarButton.onTouch = function()
		mainWindow.topToolBar.isHidden = not mainWindow.toggleTopToolBarButton.pressed
		calculateSizes()
	end

	mainWindow.bottomToolBar = mainWindow:addContainer(1, 1, 1, 1)
	mainWindow.bottomToolBar.caseSensitiveButton = mainWindow.bottomToolBar:addAdaptiveButton(1, 1, 2, 1, 0x3C3C3C, 0xEEEEEE, 0xBBBBBB, 0x2D2D2D, "Aa")
	mainWindow.bottomToolBar.caseSensitiveButton.switchMode = true
	mainWindow.bottomToolBar.onTouch = function()
		find()
	end
	mainWindow.bottomToolBar.inputTextBox = mainWindow.bottomToolBar:addInputTextBox(7, 1, 10, 3, 0xCCCCCC, 0x999999, 0xCCCCCC, 0x2D2D2D, "", localization.findSomeShit)
	mainWindow.bottomToolBar.inputTextBox.onInputFinished = function()
		findFromFirstDisplayedLine()
	end
	mainWindow.bottomToolBar.findButton = mainWindow.bottomToolBar:addAdaptiveButton(1, 1, 3, 1, 0x3C3C3C, 0xEEEEEE, 0xBBBBBB, 0x2D2D2D, localization.find)
	mainWindow.bottomToolBar.findButton.onTouch = function()
		find()
	end
	mainWindow.bottomToolBar.isHidden = true

	mainWindow.leftTreeView = mainWindow:addTreeView(1, 1, 1, 1, config.colorScheme.leftTreeView.background, 0x3C3C3C, 0x3C3C3C, 0xEEEEEE, 0x888888, 0x444444, 0x00DBFF, "/")
	mainWindow.leftTreeView.onFileSelected = function(path)
		loadFile(path)
	end

	mainWindow.errorMessage = mainWindow:addContainer(1, 1, 1, 1)
	mainWindow.errorMessage.backgroundPanel = mainWindow.errorMessage:addPanel(1, 1, 1, 1, 0xFFFFFF, 40)
	mainWindow.errorMessage.errorTextBox = mainWindow.errorMessage:addTextBox(3, 2, 1, 1, nil, 0x2D2D2D, {}, 1)
	hideErrorMessage()

	mainWindow.onAnyEvent = function(eventData)
		cursor.blinkState = not cursor.blinkState
		local oldCursorState = cursor.blinkState
		cursor.blinkState = true
			
		if eventData[1] == "touch" and isClickedOnCodeArea(eventData[3], eventData[4]) then
			if eventData[5] == 1 then
				local menu = GUI.contextMenu(eventData[3], eventData[4])
				menu:addItem(localization.cut, not mainWindow.codeView.selections[1], "^X").onTouch = function()
					cut()
				end
				menu:addItem(localization.copy, not mainWindow.codeView.selections[1], "^C").onTouch = function()
					copy()
				end
				menu:addItem(localization.paste, not clipboard, "^V").onTouch = function()
					paste(clipboard)
				end
				menu:addSeparator()
				menu:addItem(localization.selectAll, false, "^A").onTouch = function()
					selectAll()
				end
				menu:show()
			else
				setCursorPositionAndClearSelection(convertScreenCoordinatesToCursorPosition(eventData[3], eventData[4]))

				local newUptime = computer.uptime()
				if newUptime - lastClickUptime <= config.doubleClickDelay then selectWord() end
				lastClickUptime = newUptime
			end
		elseif eventData[1] == "drag" and isClickedOnCodeArea(eventData[3], eventData[4]) then
			if eventData[5] ~= 1 then
				mainWindow.codeView.selections[1] = mainWindow.codeView.selections[1] or {from = {}, to = {}}
				mainWindow.codeView.selections[1].from.symbol, mainWindow.codeView.selections[1].from.line = cursor.position.symbol, cursor.position.line
				mainWindow.codeView.selections[1].to.symbol, mainWindow.codeView.selections[1].to.line = fixCursorPosition(convertScreenCoordinatesToCursorPosition(eventData[3], eventData[4]))
				
				if mainWindow.codeView.selections[1].from.line > mainWindow.codeView.selections[1].to.line then
					mainWindow.codeView.selections[1].from.line, mainWindow.codeView.selections[1].to.line = swap(mainWindow.codeView.selections[1].from.line, mainWindow.codeView.selections[1].to.line)
					mainWindow.codeView.selections[1].from.symbol, mainWindow.codeView.selections[1].to.symbol = swap(mainWindow.codeView.selections[1].from.symbol, mainWindow.codeView.selections[1].to.symbol)
				elseif mainWindow.codeView.selections[1].from.line == mainWindow.codeView.selections[1].to.line then
					if mainWindow.codeView.selections[1].from.symbol > mainWindow.codeView.selections[1].to.symbol then
						mainWindow.codeView.selections[1].from.symbol, mainWindow.codeView.selections[1].to.symbol = swap(mainWindow.codeView.selections[1].from.symbol, mainWindow.codeView.selections[1].to.symbol)
					end
				end
			end
		elseif eventData[1] == "key_down" then
			-- Ctrl or CMD
			if keyboard.isKeyDown(29) or keyboard.isKeyDown(219) then
				-- Backslash
				if eventData[4] == 43 then
					selectWord()
				-- Slash
				elseif eventData[4] == 53 then
					toggleComment()
				-- A
				elseif eventData[4] == 30 then
					selectAll()
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
					mainWindow:close()
				-- N
				elseif eventData[4] == 49 then
					newFile()
				-- O
				elseif eventData[4] == 24 then
					open()
				-- S
				elseif eventData[4] == 31 then
					-- Shift
					if workPath and not keyboard.isKeyDown(42) then
						save()
					else
						saveAs()
					end
				-- F
				elseif eventData[4] == 33 then
					toggleBottomToolBar()
				-- G
				elseif eventData[4] == 34 then
					find()
				-- Backspace
				elseif eventData[4] == 14 then
					deleteLine(cursor.position.line)
				-- Delete
				elseif eventData[4] == 211 then
					deleteLine(cursor.position.line)
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
			-- F5
			elseif eventData[4] == 63 then
				run()
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
				if not keyboard.isControl(eventData[3]) then
					deleteSelectedData()
					paste({unicode.char(eventData[3])})
				end
			end
		elseif eventData[1] == "clipboard" then
			local lines = {}
			for line in eventData[3]:gmatch("([^\r\n]+)\r?\n?") do
				line = removeTabs(line)
				table.insert(lines, line)
			end
			table.insert(lines, "")
			paste(lines)
		elseif eventData[1] == "scroll" then
			if isClickedOnCodeArea(eventData[3], eventData[4]) then
				scroll(eventData[5], config.scrollSpeed)
			end
		elseif not eventData[1] then
			cursor.blinkState = oldCursorState
		end

		updateTitle()
		mainWindow:draw()
		if cursor.blinkState then
			local x, y = mainWindow.codeView.codeAreaPosition + cursor.position.symbol - mainWindow.codeView.fromSymbol + 1, mainWindow.codeView.y + cursor.position.line - mainWindow.codeView.fromLine
			if 
				x >= mainWindow.codeView.codeAreaPosition + 1 and
				x <= mainWindow.codeView.codeAreaPosition + mainWindow.codeView.codeAreaWidth - 2 and
				y >= mainWindow.codeView.y and
				y <= mainWindow.codeView.y + mainWindow.codeView.height - 2
			then
				buffer.text(x, y, config.cursorColor, config.cursorSymbol)
			end
		end
		buffer.draw()
	end
end

---------------------------------------------------- RUSH B! ----------------------------------------------------

buffer.start()

loadConfig()
createWindow()
calculateSizes()
mainWindow:draw()

if args[1] == "open" then
	if fs.exists(args[2]) then
		loadFile(args[2])
	else
		newFile()
		workPath = args[2]
	end
else
	newFile()
end

mainWindow:draw()
buffer.draw()
mainWindow:handleEvents(config.cursorBlinkDelay)


