
---------------------------------------------------- Libraries ----------------------------------------------------

-- "/MineOS/Applications/MineCode IDE.app/MineCode IDE.lua" open OS.lua

package.loaded.syntax = nil
-- package.loaded.ECSAPI = nil
-- package.loaded.GUI = nil
-- package.loaded.windows = nil
-- package.loaded.MineOSCore = nil

require("advancedLua")
local computer = require("computer")
local component = require("component")
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
local palette = require("palette")
local term = require("term")

---------------------------------------------------- Constants ----------------------------------------------------

local args = {...}

local about = {
	"MineCode IDE",
	"Copyright © 2014-2017 ECS Inc.",
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

local config = {
	syntaxColorScheme = syntax.colorScheme,
	scrollSpeed = 8,
	cursorColor = 0x00A8FF,
	cursorSymbol = "┃",
	cursorBlinkDelay = 0.5,
	doubleClickDelay = 0.4,
	screenScale = 1,
	enableAutoBrackets = true,
	highlightLuaSyntax = true,
}

local colors = {
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
			sides = 0x555555,
			background = 0x3C3C3C,
			text = 0xEEEEEE,
		},
		onError = {
			sides = 0xCC4940,
			background = 0x880000,
			text = 0xEEEEEE,
		},
	},
	leftTreeView = {
		background = 0xCCCCCC,
	},
	highlights = {
		onError = 0xFF4940,
		onBreakpoint = 0x990000,
	}
}

local possibleBrackets = {
	openers = {
		["{"] = "}",
		["["] = "]",
		["("] = ")",
		["\""] = "\"",
		["\'"] = "\'"
	},
	closers = {
		["}"] = "{",
		["]"] = "[",
		[")"] = "(",
		["\""] = "\"",
		["\'"] = "\'"
	}
}

local cursor = {
	position = {
		symbol = 1,
		line = 1
	},
	blinkState = false
}

local resourcesPath = MineOSCore.getCurrentApplicationResourcesDirectory() 
local configPath = resourcesPath .. "Config.cfg"
local localization = MineOSCore.getLocalization(resourcesPath .. "Localization/")
local findStartFrom
local clipboard
local lastErrorLine
local breakpointLine = 5
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
	mainWindow.width, mainWindow.height = buffer.screen.width, buffer.screen.height
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

	mainWindow.settingsContainer.width, mainWindow.settingsContainer.height = mainWindow.width, mainWindow.height
	mainWindow.settingsContainer.backgroundPanel.width, mainWindow.settingsContainer.backgroundPanel.height = mainWindow.settingsContainer.width, mainWindow.settingsContainer.height

	mainWindow.bottomToolBar.localPosition.y = mainWindow.height - 2
	mainWindow.bottomToolBar.findButton.localPosition.x = mainWindow.bottomToolBar.width - mainWindow.bottomToolBar.findButton.width + 1
	mainWindow.bottomToolBar.inputTextBox.width = mainWindow.bottomToolBar.width - mainWindow.bottomToolBar.inputTextBox.localPosition.x - mainWindow.bottomToolBar.findButton.width + 1

	mainWindow.topToolBar.width, mainWindow.topToolBar.backgroundPanel.width = mainWindow.width, mainWindow.width
	mainWindow.titleTextBox.width = math.floor(mainWindow.topToolBar.width * 0.32)
	mainWindow.titleTextBox.localPosition.x = math.floor(mainWindow.topToolBar.width / 2 - mainWindow.titleTextBox.width / 2)
	mainWindow.runButton.localPosition.x = mainWindow.titleTextBox.localPosition.x - mainWindow.runButton.width - 2
	mainWindow.toggleSyntaxHighlightingButton.localPosition.x = mainWindow.runButton.localPosition.x - mainWindow.toggleSyntaxHighlightingButton.width - 2
	mainWindow.addBreakpointButton.localPosition.x = mainWindow.toggleSyntaxHighlightingButton.localPosition.x - mainWindow.addBreakpointButton.width - 2
	mainWindow.toggleLeftToolBarButton.localPosition.x = mainWindow.titleTextBox.localPosition.x + mainWindow.titleTextBox.width + 2
	mainWindow.toggleBottomToolBarButton.localPosition.x = mainWindow.toggleLeftToolBarButton.localPosition.x + mainWindow.toggleLeftToolBarButton.width + 2
	mainWindow.toggleTopToolBarButton.localPosition.x = mainWindow.toggleBottomToolBarButton.localPosition.x + mainWindow.toggleBottomToolBarButton.width + 2

	mainWindow.RAMUsageProgressBar.localPosition.x = mainWindow.toggleTopToolBarButton.localPosition.x + mainWindow.toggleTopToolBarButton.width + 3
	mainWindow.RAMUsageProgressBar.width = mainWindow.topToolBar.width - mainWindow.RAMUsageProgressBar.localPosition.x - 3

	mainWindow.errorMessage.localPosition.x, mainWindow.errorMessage.width = mainWindow.titleTextBox.localPosition.x, mainWindow.titleTextBox.width
	mainWindow.errorMessage.backgroundPanel.width, mainWindow.errorMessage.errorTextBox.width = mainWindow.errorMessage.width, mainWindow.errorMessage.width - 4

	mainWindow.topMenu.width = mainWindow.width
end

local function changeScale(newScale)
	buffer.changeResolution(ecs.getScaledResolution(newScale))
	calculateSizes()
	mainWindow:draw()
	buffer.draw()
	config.screenScale = newScale
end

local function scalePlus()
	if config.screenScale > 0.3 then changeScale(config.screenScale - 0.1); saveConfig() end
end

local function scaleMinus()
	if config.screenScale < 1 then changeScale(config.screenScale + 0.1); saveConfig() end
end

local function updateTitle()
	if not mainWindow.topToolBar.isHidden then
		if mainWindow.errorMessage.isHidden then
			mainWindow.titleTextBox.lines[1] = string.limit(localization.file .. ": " .. (mainWindow.leftTreeView.currentFile or localization.none), mainWindow.titleTextBox.width - 4)
			mainWindow.titleTextBox.lines[2] = string.limit(localization.cursor .. cursor.position.line .. localization.line .. cursor.position.symbol .. localization.symbol, mainWindow.titleTextBox.width - 4)
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
				mainWindow.titleTextBox.lines[3] = string.limit(localization.selection .. countOfSelectedLines .. localization.lines .. countOfSelectedSymbols .. localization.symbols, mainWindow.titleTextBox.width - 4)
			else
				mainWindow.titleTextBox.lines[3] = string.limit(localization.selection .. localization.none, mainWindow.titleTextBox.width - 4)
			end
		else
			mainWindow.titleTextBox.lines[1], mainWindow.titleTextBox.lines[3] = " ", " "
			if breakpointLine then
				mainWindow.titleTextBox.lines[2] = localization.debugging .. cursor.position.line
			else
				mainWindow.titleTextBox.lines[2] = localization.runtimeError
			end
		end
	end
end

local function calculateErrorMessageSizeAndBeep()
	mainWindow.errorMessage.height = 2 + #mainWindow.errorMessage.errorTextBox.lines
	mainWindow.errorMessage.backgroundPanel.height = mainWindow.errorMessage.height
	mainWindow.errorMessage.errorTextBox.height = mainWindow.errorMessage.height - 2

	updateTitle()
	mainWindow:draw()
	buffer.draw()

	for i = 1, 3 do component.computer.beep(1500, 0.08) end
end

local function showBreakpointMessage(variables)
	mainWindow.titleTextBox.colors.background, mainWindow.titleTextBox.colors.text = colors.title.onError.background, colors.title.onError.text
	mainWindow.errorMessage.isHidden = false

	mainWindow.errorMessage.errorTextBox:setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	mainWindow.errorMessage.errorTextBox.lines = {}

	for variable, value in pairs(variables) do
		table.insert(mainWindow.errorMessage.errorTextBox.lines, variable .. " = " .. value)
	end

	if #mainWindow.errorMessage.errorTextBox.lines > 0 then
		table.insert(mainWindow.errorMessage.errorTextBox.lines, 1, " ")
		table.insert(mainWindow.errorMessage.errorTextBox.lines, 1, {text = localization.variables, color = 0x0})
	else
		table.insert(mainWindow.errorMessage.errorTextBox.lines, 1, {text = localization.variablesNotAvailable, color = 0x0})
	end

	calculateErrorMessageSizeAndBeep()
end

local function showErrorMessage(text)
	mainWindow.titleTextBox.colors.background, mainWindow.titleTextBox.colors.text = colors.title.onError.background, colors.title.onError.text
	mainWindow.errorMessage.isHidden = false

	mainWindow.errorMessage.errorTextBox:setAlignment(GUI.alignment.horizontal.left, GUI.alignment.vertical.top)
	mainWindow.errorMessage.errorTextBox.lines = string.wrap({text}, mainWindow.errorMessage.errorTextBox.width)	
	
	calculateErrorMessageSizeAndBeep()
end

local function hideErrorMessage()
	mainWindow.titleTextBox.colors.background, mainWindow.titleTextBox.colors.text = colors.title.default.background, colors.title.default.text
	mainWindow.errorMessage.isHidden = true
end

local function hideSettingsContainer()
	for childIndex = 2, #mainWindow.settingsContainer.children do mainWindow.settingsContainer.children[childIndex] = nil end
	mainWindow.settingsContainer.isHidden = true
	mainWindow:draw()
	buffer.draw()
end

local function clearHighlights()
	if lastErrorLine then
		mainWindow.codeView.highlights[lastErrorLine] = nil
		lastErrorLine = nil
	end

	if breakpointLine then
		mainWindow.codeView.highlights[breakpointLine] = nil
		breakpointLine = nil
	end
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
	clearHighlights()
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

local function pageUp()
	scroll(1, mainWindow.codeView.height - 2)
end

local function pageDown()
	scroll(-1, mainWindow.codeView.height - 2)
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
		cursor.position.symbol = to
	end
end

------------------------------------------------------------------------------------------------------------------

local function removeTabs(text)
	local result = text:gsub("\t", string.rep(" ", mainWindow.codeView.indentationWidth))
	return result
end

local function removeWindowsLineEndings(text)
	local result = text:gsub("\r\n", "\n")
	return result
end

local function createInputTextBoxForSettingsWindow(title, placeholder)
	mainWindow.settingsContainer.isHidden = false
	local elementWidth = math.floor(mainWindow.width * 0.3)
	local x, y = math.floor(mainWindow.width / 2 - elementWidth / 2), math.floor(mainWindow.height / 2) - 3
	mainWindow.settingsContainer:addLabel(1, y, mainWindow.settingsContainer.width, 1, 0xFFFFFF, title):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top); y = y + 3
	return mainWindow.settingsContainer:addInputTextBox(x, y, elementWidth, 3, 0xCCCCCC, 0x777777, 0xCCCCCC, 0x2D2D2D, "", placeholder)
end

local function newFile()
	mainWindow.codeView.lines = {""}
	mainWindow.codeView.maximumLineLength = 1
	mainWindow.leftTreeView.currentFile = nil
	setCursorPositionAndClearSelection(1, 1)
end

local function loadFile(path)
	newFile()
	local file = io.open(path, "r")
	for line in file:lines() do
		line = removeWindowsLineEndings(removeTabs(line))
		table.insert(mainWindow.codeView.lines, line)
		mainWindow.codeView.maximumLineLength = math.max(mainWindow.codeView.maximumLineLength, unicode.len(line))
	end
	file:close()
	mainWindow.leftTreeView.currentFile = path
end

local function saveFile(path)
	fs.makeDirectory(fs.path(path))
	local file = io.open(path, "w")
	for line = 1, #mainWindow.codeView.lines do
		file:write(mainWindow.codeView.lines[line], "\n")
	end
	file:close()
end

local function open()
	local inputTextBox = createInputTextBoxForSettingsWindow(localization.openFile, localization.pathToFile)
	inputTextBox.validator = function(text)
		if fs.exists(text) then return true end
	end
	inputTextBox.onInputFinished = function()
		loadFile(inputTextBox.text)
		hideSettingsContainer()
	end
end

local function saveAs()
	local inputTextBox = createInputTextBoxForSettingsWindow(localization.saveAs, localization.pathToFile)
	inputTextBox.onInputFinished = function()
		saveFile(inputTextBox.text)
		mainWindow.leftTreeView.currentFile = inputTextBox.text
		mainWindow.leftTreeView:updateFileList()
		hideSettingsContainer()
	end
end

local function save()
	saveFile(mainWindow.leftTreeView.currentFile)
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

local function downloadFromWeb()
	local inputTextBox = createInputTextBoxForSettingsWindow(localization.getFromWeb, localization.url)
	inputTextBox.onInputFinished = function()
		local success, reason = ecs.internetRequest(inputTextBox.text)
		if success then
			newFile()
			mainWindow.codeView.lines, mainWindow.codeView.maximumLineLength = splitStringIntoLines(reason)
			hideSettingsContainer()
		else
			GUI.error(reason, {title = {color = 0xFFDB40, text = "Failed to connect to URL"}})
		end
	end
end

------------------------------------------------------------------------------------------------------------------

local function addErrorLine(line)
	lastErrorLine = line
	mainWindow.codeView.highlights[line] = colors.highlights.onError
end

local function addBreakpoint()
	clearHighlights()
	breakpointLine = cursor.position.line
	mainWindow.codeView.highlights[breakpointLine] = colors.highlights.onBreakpoint
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
				not word:match("^%d+$") and
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

local function createBreakpointError(variables)
	local errorMessage = "error({variables={"

	for variable in pairs(variables) do
		errorMessage = errorMessage .. "[\"" .. variable .. "\"] = type(" .. variable .. ") == \"string\" and \"\\\"\" .. " .. variable .. " .. \"\\\"\" or tostring(" .. variable .. "),"
	end

	return errorMessage .. "}})"
end

local function run()
	if breakpointLine then
		table.insert(mainWindow.codeView.lines, breakpointLine, createBreakpointError(getVariables(mainWindow.codeView.lines[breakpointLine])))
	end

	local loadSuccess, loadReason = load(table.concat(mainWindow.codeView.lines, "\n"))
	if loadSuccess then
		local oldResolutionX, oldResolutionY = component.gpu.getResolution()
		component.gpu.setBackground(0x1B1B1B)
		component.gpu.setForeground(0xFFFFFF)
		component.gpu.fill(1, 1, oldResolutionX, oldResolutionY, " ")
		term.setCursor(1, 1)
		
		local xpcallSuccess, xpcallReason = xpcall(loadSuccess, debug.traceback)
		local xpcallReasonType = type(xpcallReason)

		if breakpointLine then
			table.remove(mainWindow.codeView.lines, breakpointLine)
		end

		if xpcallSuccess or (xpcallReasonType == "table" and xpcallReason.terminated == true) then
			MineOSCore.waitForPressingAnyKey()
		end

		buffer.changeResolution(oldResolutionX, oldResolutionY)	

		if not xpcallSuccess then
			if xpcallReasonType == "table" then
				if xpcallReason.variables then
					gotoLine(breakpointLine)
					showBreakpointMessage(xpcallReason.variables)
				end
			else
				showErrorMessage(xpcallReason)
			end
		end

		mainWindow:draw()
		buffer:draw()		
	else
		addErrorLine(tonumber(loadReason:match("^%[.+%]%:(%d+)%:")))
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

local function pasteRegularChar(unicodeByte, char)
	if not keyboard.isControl(unicodeByte) then
		deleteSelectedData()
		paste({char})
	end
end

local function pasteAutoBrackets(unicodeByte)
	local char = unicode.char(unicodeByte)
	local currentSymbol = unicode.sub(mainWindow.codeView.lines[cursor.position.line], cursor.position.symbol, cursor.position.symbol)

	-- Если у нас вообще врублен режим автоскобок, то чекаем их
	if config.enableAutoBrackets then
		-- Ситуация, когда курсор находится на закрывающей скобке, и нехуй ее еще раз вставлять
		if possibleBrackets.closers[char] and currentSymbol == char then
			deleteSelectedData()
			setCursorPosition(cursor.position.symbol + 1, cursor.position.line)
		-- Если нажата открывающая скобка
		elseif possibleBrackets.openers[char] then
			-- А вот тут мы берем в скобочки уже выделенный текст
			if mainWindow.codeView.selections[1] then
				local firstPart = unicode.sub(mainWindow.codeView.lines[mainWindow.codeView.selections[1].from.line], 1, mainWindow.codeView.selections[1].from.symbol - 1)
				local secondPart = unicode.sub(mainWindow.codeView.lines[mainWindow.codeView.selections[1].from.line], mainWindow.codeView.selections[1].from.symbol, -1)
				mainWindow.codeView.lines[mainWindow.codeView.selections[1].from.line] = firstPart .. char .. secondPart
				mainWindow.codeView.selections[1].from.symbol = mainWindow.codeView.selections[1].from.symbol + 1

				if mainWindow.codeView.selections[1].to.line == mainWindow.codeView.selections[1].from.line then
					mainWindow.codeView.selections[1].to.symbol = mainWindow.codeView.selections[1].to.symbol + 1
				end

				firstPart = unicode.sub(mainWindow.codeView.lines[mainWindow.codeView.selections[1].to.line], 1, mainWindow.codeView.selections[1].to.symbol)
				secondPart = unicode.sub(mainWindow.codeView.lines[mainWindow.codeView.selections[1].to.line], mainWindow.codeView.selections[1].to.symbol + 1, -1)
				mainWindow.codeView.lines[mainWindow.codeView.selections[1].to.line] = firstPart .. possibleBrackets.openers[char] .. secondPart
			-- А тут мы делаем двойную автоскобку, если можем
			elseif possibleBrackets.openers[char] and not currentSymbol:match("[%a%d%_]") then
				paste({char .. possibleBrackets.openers[char]})
				setCursorPosition(cursor.position.symbol - 1, cursor.position.line)
				cursor.blinkState = false
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
	local previousSymbol = unicode.sub(mainWindow.codeView.lines[cursor.position.line], cursor.position.symbol - 1, cursor.position.symbol - 1)
	local currentSymbol = unicode.sub(mainWindow.codeView.lines[cursor.position.line], cursor.position.symbol, cursor.position.symbol)
	if config.enableAutoBrackets and possibleBrackets.openers[previousSymbol] and possibleBrackets.openers[previousSymbol] == currentSymbol then
		deleteSpecifiedData(cursor.position.symbol, cursor.position.line, cursor.position.symbol, cursor.position.line)
	end
end

local function delete()
	if mainWindow.codeView.selections[1] then
		deleteSelectedData()
	else
		if cursor.position.symbol < unicode.len(mainWindow.codeView.lines[cursor.position.line]) + 1 then
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
			backspaceAutoBrackets()
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
	mainWindow.codeView.selections[1] = {
		from = {
			symbol = 1, line = 1
		},
		to = {
			symbol = unicode.len(mainWindow.codeView.lines[#mainWindow.codeView.lines]), line = #mainWindow.codeView.lines
		}
	}
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

local function updateRAMProgressBar()
	if not mainWindow.topToolBar.isHidden then
		local totalMemory = computer.totalMemory()
		mainWindow.RAMUsageProgressBar.value = math.ceil((totalMemory - computer.freeMemory()) / totalMemory * 100)
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

	mainWindow.codeView = mainWindow:addCodeView(1, 1, 1, 1, {""}, 1, 1, 1, {}, {}, config.highlightLuaSyntax, 2)
	mainWindow.codeView.scrollBars.vertical.onTouch = function()
		mainWindow.codeView.fromLine = mainWindow.codeView.scrollBars.vertical.value
	end
	mainWindow.codeView.scrollBars.horizontal.onTouch = function()
		mainWindow.codeView.fromSymbol = mainWindow.codeView.scrollBars.horizontal.value
	end
	mainWindow.topMenu = mainWindow:addMenu(1, 1, 1, colors.topMenu.backgroundColor, colors.topMenu.textColor, colors.topMenu.backgroundPressedColor, colors.topMenu.textPressedColor)
	
	local item1 = mainWindow.topMenu:addItem("MineCode", 0x0)
	item1.onTouch = function()
		local menu = GUI.contextMenu(item1.x, item1.y + 1)
		menu:addItem(localization.about).onTouch = function()
			mainWindow.settingsContainer.isHidden = false
			local y = math.floor(mainWindow.settingsContainer.height / 2 - #about / 2)
			mainWindow.settingsContainer:addTextBox(1, y, mainWindow.settingsContainer.width, #about, nil, 0xEEEEEE, about, 1):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
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
		menu:addItem(localization.getFromWeb, false, "^U").onTouch = function()
			downloadFromWeb()
		end
		menu:addSeparator()
		menu:addItem(localization.save, not mainWindow.leftTreeView.currentFile, "^S").onTouch = function()
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
		menu:addItem(localization.selectWord).onTouch = function()
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
			mainWindow.settingsContainer.isHidden = false
			
			local colorSelectorsCount, colorSelectorCountX = 0, 4; for key in pairs(config.syntaxColorScheme) do colorSelectorsCount = colorSelectorsCount + 1 end
			local colorSelectorCountY = math.ceil(colorSelectorsCount / colorSelectorCountX)
			local colorSelectorWidth, colorSelectorHeight, colorSelectorSpaceX, colorSelectorSpaceY = math.floor(mainWindow.settingsContainer.width / colorSelectorCountX * 0.8), 3, 2, 1
			
			local startX, y = math.floor(mainWindow.settingsContainer.width / 2 - (colorSelectorCountX * (colorSelectorWidth + colorSelectorSpaceX) - colorSelectorSpaceX) / 2), math.floor(mainWindow.settingsContainer.height / 2 - (colorSelectorCountY * (colorSelectorHeight + colorSelectorSpaceY) - colorSelectorSpaceY + 3) / 2)
			mainWindow.settingsContainer:addLabel(1, y, mainWindow.settingsContainer.width, 1, 0xFFFFFF, localization.colorScheme):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top); y = y + 3
			local x, counter = startX, 1

			for key in pairs(config.syntaxColorScheme) do
				local colorSelector = mainWindow.settingsContainer:addColorSelector(x, y, colorSelectorWidth, colorSelectorHeight, config.syntaxColorScheme[key], key)
				colorSelector.onTouch = function()
					config.syntaxColorScheme[key] = colorSelector.color
					syntax.colorScheme = config.syntaxColorScheme
					saveConfig()
				end

				x, counter = x + colorSelectorWidth + colorSelectorSpaceX, counter + 1
				if counter > colorSelectorCountX then
					x, y, counter = startX, y + colorSelectorHeight + colorSelectorSpaceY, 1
				end
			end
		end
		menu:addItem(localization.cursorProperties).onTouch = function()
			mainWindow.settingsContainer.isHidden = false

			local elementWidth = math.floor(mainWindow.width * 0.3)
			local x, y = math.floor(mainWindow.width / 2 - elementWidth / 2), math.floor(mainWindow.height / 2) - 7
			mainWindow.settingsContainer:addLabel(1, y, mainWindow.settingsContainer.width, 1, 0xFFFFFF, localization.cursorProperties):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top); y = y + 3
			local inputTextBox = mainWindow.settingsContainer:addInputTextBox(x, y, elementWidth, 3, 0xCCCCCC, 0x777777, 0xCCCCCC, 0x2D2D2D, config.cursorSymbol, localization.cursorSymbol); y = y + 5
			inputTextBox.validator = function(text)
				if unicode.len(text) == 1 then return true end
			end
			inputTextBox.onInputFinished = function()
				config.cursorSymbol = inputTextBox.text; saveConfig()
			end
			local colorSelector = mainWindow.settingsContainer:addColorSelector(x, y, elementWidth, 3, config.cursorColor, localization.cursorColor); y = y + 5
			colorSelector.onTouch = function()
				config.cursorColor = colorSelector.color; saveConfig()
			end
			local horizontalSlider = mainWindow.settingsContainer:addHorizontalSlider(x, y, elementWidth, 0xFFDB80, 0x000000, 0xFFDB40, 0xDDDDDD, 1, 1000, config.cursorBlinkDelay * 1000, false, localization.cursorBlinkDelay .. ": ", " ms")
			horizontalSlider.onValueChanged = function()
				config.cursorBlinkDelay = horizontalSlider.value / 1000; saveConfig()
			end
		end

		if mainWindow.topToolBar.isHidden then
			menu:addItem(localization.toggleTopToolBar).onTouch = function()
				toggleTopToolBar()
			end
		end
		if config.enableAutoBrackets then
			menu:addItem(localization.disableAutoBrackets, false, "^]").onTouch = function()
				config.enableAutoBrackets = false
				saveConfig()
			end
		else
			menu:addItem(localization.enableAutoBrackets, false, "^]").onTouch = function()
				config.enableAutoBrackets = true
				saveConfig()
			end
		end

		menu:addSeparator()
		menu:addItem(localization.scalePlus, false, "^+").onTouch = function()
			scalePlus()
		end
		menu:addItem(localization.scaleMinus, false, "^-").onTouch = function()
			scaleMinus()
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
	mainWindow.topToolBar.backgroundPanel = mainWindow.topToolBar:addPanel(1, 1, 1, 3, colors.topToolBar)
	mainWindow.titleTextBox = mainWindow.topToolBar:addTextBox(1, 1, 1, 3, 0x0, 0x0, {}, 1):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	local titleTextBoxOldDraw = mainWindow.titleTextBox.draw
	mainWindow.titleTextBox.draw = function(titleTextBox)
		titleTextBoxOldDraw(titleTextBox)
		local sidesColor = mainWindow.errorMessage.isHidden and colors.title.default.sides or colors.title.onError.sides
		buffer.square(titleTextBox.x, titleTextBox.y, 1, titleTextBox.height, sidesColor, titleTextBox.colors.text, " ")
		buffer.square(titleTextBox.x + titleTextBox.width - 1, titleTextBox.y, 1, titleTextBox.height, sidesColor, titleTextBox.colors.text, " ")
	end

	mainWindow.RAMUsageProgressBar = mainWindow.topToolBar:addProgressBar(1, 2, 1, 0x777777, 0xBBBBBB, 0xAAAAAA, 50, true, true, "RAM: ", "%")

	--☯◌☺
	mainWindow.addBreakpointButton = mainWindow.topToolBar:addAdaptiveButton(1, 1, 3, 1, 0x878787, 0xEEEEEE, 0xCCCCCC, 0x444444, "x")
	mainWindow.addBreakpointButton.onTouch = function()
		addBreakpoint()
	end

	mainWindow.toggleSyntaxHighlightingButton = mainWindow.topToolBar:addAdaptiveButton(1, 1, 3, 1, 0xCCCCCC, 0x444444, 0x696969, 0xEEEEEE, "◌")
	mainWindow.toggleSyntaxHighlightingButton.switchMode, mainWindow.toggleSyntaxHighlightingButton.pressed = true, true
	mainWindow.toggleSyntaxHighlightingButton.onTouch = function()
		mainWindow.codeView.highlightLuaSyntax = not mainWindow.codeView.highlightLuaSyntax
		config.highlightLuaSyntax = mainWindow.codeView.highlightLuaSyntax
		saveConfig()
	end

	mainWindow.runButton = mainWindow.topToolBar:addAdaptiveButton(1, 1, 3, 1, 0x4B4B4B, 0xEEEEEE, 0xCCCCCC, 0x444444, "▷")
	mainWindow.runButton.onTouch = function()
		run()
	end

	mainWindow.toggleLeftToolBarButton = mainWindow.topToolBar:addAdaptiveButton(1, 1, 3, 1, 0xCCCCCC, 0x444444, 0x4B4B4B, 0xEEEEEE, "⇦")
	mainWindow.toggleLeftToolBarButton.switchMode, mainWindow.toggleLeftToolBarButton.pressed = true, true
	mainWindow.toggleLeftToolBarButton.onTouch = function()
		mainWindow.leftTreeView.isHidden = not mainWindow.toggleLeftToolBarButton.pressed
		calculateSizes()
	end

	mainWindow.toggleBottomToolBarButton = mainWindow.topToolBar:addAdaptiveButton(1, 1, 3, 1, 0xCCCCCC, 0x444444, 0x696969, 0xEEEEEE, "⇩")
	mainWindow.toggleBottomToolBarButton.switchMode, mainWindow.toggleBottomToolBarButton.pressed = true, false
	mainWindow.toggleBottomToolBarButton.onTouch = function()
		mainWindow.bottomToolBar.isHidden = not mainWindow.toggleBottomToolBarButton.pressed
		calculateSizes()
	end

	mainWindow.toggleTopToolBarButton = mainWindow.topToolBar:addAdaptiveButton(1, 1, 3, 1, 0xCCCCCC, 0x444444, 0x878787, 0xEEEEEE, "⇧")
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

	mainWindow.leftTreeView = mainWindow:addTreeView(1, 1, 1, 1, colors.leftTreeView.background, 0x3C3C3C, 0x3C3C3C, 0xEEEEEE, 0x888888, 0x444444, 0x00DBFF, "/")
	mainWindow.leftTreeView.onFileSelected = function(path)
		loadFile(path)
	end

	mainWindow.errorMessage = mainWindow:addContainer(1, 1, 1, 1)
	mainWindow.errorMessage.backgroundPanel = mainWindow.errorMessage:addPanel(1, 1, 1, 1, 0xFFFFFF, 30)
	mainWindow.errorMessage.errorTextBox = mainWindow.errorMessage:addTextBox(3, 2, 1, 1, nil, 0x4B4B4B, {}, 1)
	hideErrorMessage()

	mainWindow.settingsContainer = mainWindow:addContainer(1, 1, 1, 1)
	mainWindow.settingsContainer.backgroundPanel = mainWindow.settingsContainer:addPanel(1, 1, mainWindow.settingsContainer.width, mainWindow.settingsContainer.height, 0x0, 30)
	mainWindow.settingsContainer.backgroundPanel.onTouch = hideSettingsContainer
	mainWindow.settingsContainer.isHidden = true

	mainWindow.onAnyEvent = function(eventData)		
		if eventData[1] == "touch" and isClickedOnCodeArea(eventData[3], eventData[4]) then
			cursor.blinkState = true
			
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
				menu:addItem(localization.selectWord).onTouch = function()
					selectWord()
				end
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
			cursor.blinkState = true
			
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
			cursor.blinkState = true

			-- Ctrl or CMD
			if keyboard.isKeyDown(29) or keyboard.isKeyDown(219) then
				-- Slash
				if eventData[4] == 53 then
					toggleComment()
				-- ]
				elseif eventData[4] == 27 then
					config.enableAutoBrackets = not config.enableAutoBrackets
					saveConfig()
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
				-- U
				elseif eventData[4] == 22 then
					downloadFromWeb()
				-- S
				elseif eventData[4] == 31 then
					-- Shift
					if mainWindow.leftTreeView.currentFile and not keyboard.isKeyDown(42) then
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
				-- +
				elseif eventData[4] == 13 then
					scalePlus()
				-- -
				elseif eventData[4] == 12 then
					scaleMinus()
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
				pasteAutoBrackets(eventData[3])
			end
		elseif eventData[1] == "clipboard" then
			paste(splitStringIntoLines(eventData[3]))
		elseif eventData[1] == "scroll" then
			if isClickedOnCodeArea(eventData[3], eventData[4]) then
				scroll(eventData[5], config.scrollSpeed)
			end
		elseif eventData[1] == "component_added" or eventData[1] == "component_removed" then
			if eventData[3] == "screen" then
				os.sleep(0.5)
				changeScale(config.screenScale)
			end
		elseif not eventData[1] then
			cursor.blinkState = not cursor.blinkState
		end

		updateTitle()
		updateRAMProgressBar()
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

loadConfig()
createWindow()
changeScale(config.screenScale)
updateTitle()
updateRAMProgressBar()
mainWindow:draw()

if args[1] == "open" and fs.exists(args[2] or "") then
	loadFile(args[2])
else
	newFile()
end

mainWindow:draw()
buffer.draw()
mainWindow:handleEvents(config.cursorBlinkDelay)


