
---------------------------------------------------- Libraries ----------------------------------------------------

-- "/MineOS/Applications/MineCode IDE.app/MineCode IDE.lua" -o /OS.lua

-- package.loaded.syntax = nil
-- package.loaded.ECSAPI = nil
-- package.loaded.GUI = nil
-- package.loaded.MineOSCore = nil

local args = {...}
require("advancedLua")
local computer = require("computer")
local component = require("component")
local fs = require("filesystem")
local buffer = require("doubleBuffering")
local event = require("event")
local syntax = require("syntax")
local unicode = require("unicode")
local web = require("web")
local image = require("image")
local keyboard = require("keyboard")
local GUI = require("GUI")
local MineOSPaths = require("MineOSPaths")
local MineOSCore = require("MineOSCore")
local MineOSInterface = require("MineOSInterface")

---------------------------------------------------- Constants ----------------------------------------------------

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
	leftTreeViewWidth = 26,
	syntaxColorScheme = syntax.colorScheme,
	scrollSpeed = 8,
	cursorColor = 0x00A8FF,
	cursorSymbol = "┃",
	cursorBlinkDelay = 0.5,
	doubleClickDelay = 0.4,
	screenResolution = {},
	enableAutoBrackets = true,
	highlightLuaSyntax = true,
	enableAutocompletion = true,
}
config.screenResolution.width, config.screenResolution.height = component.gpu.getResolution()

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

local scriptCoroutine
local resourcesPath = MineOSCore.getCurrentScriptDirectory() 
local configPath = MineOSPaths.applicationData .. "MineCode IDE/Config.cfg"
local localization = MineOSCore.getLocalization(resourcesPath .. "Localizations/")
local findStartFrom
local clipboard
local breakpointLines
local lastErrorLine
local autocompleteDatabase

------------------------------------------------------------------------------------------------------------------

local function convertTextPositionToScreenCoordinates(symbol, line)
	return
		mainContainer.codeView.codeAreaPosition + symbol - mainContainer.codeView.fromSymbol + 1,
		mainContainer.codeView.y + line - mainContainer.codeView.fromLine
end

local function convertScreenCoordinatesToTextPosition(x, y)
	return x - mainContainer.codeView.codeAreaPosition + mainContainer.codeView.fromSymbol - 1, y - mainContainer.codeView.y + mainContainer.codeView.fromLine
end

------------------------------------------------------------------------------------------------------------------

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

------------------------------------------------------------------------------------------------------------------

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
		for line = 1, #mainContainer.codeView.lines do
			updateAutocompleteDatabaseFromString(mainContainer.codeView.lines[line], true)
		end
	end
end

local function getCurrentWordStartingAndEnding(fromSymbol)
	local shittySymbolsRegexp, from, to = "[%s%c%p]"

	for i = fromSymbol, 1, -1 do
		if unicode.sub(mainContainer.codeView.lines[cursor.position.line], i, i):match(shittySymbolsRegexp) then break end
		from = i
	end

	for i = fromSymbol, unicode.len(mainContainer.codeView.lines[cursor.position.line]) do
		if unicode.sub(mainContainer.codeView.lines[cursor.position.line], i, i):match(shittySymbolsRegexp) then break end
		to = i
	end

	return from, to
end

local function aplhabeticalSort(t)
	table.sort(t, function(a, b) return a[1] < b[1] end)
end

local function getAutocompleteDatabaseMatches(stringToSearch)
	local matches = {}

	for word in pairs(autocompleteDatabase) do
		if word ~= stringToSearch then
			local match = word:match("^" .. stringToSearch)
			if match then
				table.insert(matches, { word, match })
			end
		end
	end

	aplhabeticalSort(matches)
	return matches
end

local function hideAutocompleteWindow()
	mainContainer.autocompleteWindow.hidden = true
end

local function showAutocompleteWindow()
	if config.enableAutocompletion then
		mainContainer.autocompleteWindow.currentWordStarting, mainContainer.autocompleteWindow.currentWordEnding = getCurrentWordStartingAndEnding(cursor.position.symbol - 1)

		if mainContainer.autocompleteWindow.currentWordStarting then
			mainContainer.autocompleteWindow.matches = getAutocompleteDatabaseMatches(
				unicode.sub(
					mainContainer.codeView.lines[cursor.position.line],
					mainContainer.autocompleteWindow.currentWordStarting,
					mainContainer.autocompleteWindow.currentWordEnding
				)
			)

			if #mainContainer.autocompleteWindow.matches > 0 then
				mainContainer.autocompleteWindow.fromMatch, mainContainer.autocompleteWindow.currentMatch = 1, 1
				mainContainer.autocompleteWindow.hidden = false
			else
				hideAutocompleteWindow()
			end
		else
			hideAutocompleteWindow()
		end
	end
end

local function toggleEnableAutocompleteDatabase()
	config.enableAutocompletion = not config.enableAutocompletion
	autocompleteDatabase = {}
	saveConfig()
end

------------------------------------------------------------------------------------------------------------------

local function calculateSizes()
	mainContainer.width, mainContainer.height = buffer.getResolution()

	if mainContainer.leftTreeView.hidden then
		mainContainer.codeView.localX, mainContainer.codeView.width = 1, mainContainer.width
		mainContainer.bottomToolBar.localX, mainContainer.bottomToolBar.width = mainContainer.codeView.localX, mainContainer.codeView.width
	else
		mainContainer.codeView.localX, mainContainer.codeView.width = mainContainer.leftTreeView.width + 1, mainContainer.width - mainContainer.leftTreeView.width
		mainContainer.bottomToolBar.localX, mainContainer.bottomToolBar.width = mainContainer.codeView.localX, mainContainer.codeView.width
	end

	if mainContainer.topToolBar.hidden then
		mainContainer.leftTreeView.localY, mainContainer.leftTreeView.height = 2, mainContainer.height - 1
		mainContainer.codeView.localY, mainContainer.codeView.height = 2, mainContainer.height - 1
		mainContainer.errorContainer.localY = 2
	else
		mainContainer.leftTreeView.localY, mainContainer.leftTreeView.height = 5, mainContainer.height - 4
		mainContainer.codeView.localY, mainContainer.codeView.height = 5, mainContainer.height - 4
		mainContainer.errorContainer.localY = 5
	end

	if mainContainer.bottomToolBar.hidden then

	else
		mainContainer.codeView.height = mainContainer.codeView.height - 3
	end

	mainContainer.leftTreeViewResizer.localX = mainContainer.leftTreeView.width - 2
	mainContainer.leftTreeViewResizer.localY = math.floor(mainContainer.leftTreeView.localY + mainContainer.leftTreeView.height / 2 - mainContainer.leftTreeViewResizer.height / 2)

	mainContainer.settingsContainer.width, mainContainer.settingsContainer.height = mainContainer.width, mainContainer.height
	mainContainer.settingsContainer.backgroundPanel.width, mainContainer.settingsContainer.backgroundPanel.height = mainContainer.settingsContainer.width, mainContainer.settingsContainer.height

	mainContainer.bottomToolBar.localY = mainContainer.height - 2
	mainContainer.bottomToolBar.findButton.localX = mainContainer.bottomToolBar.width - mainContainer.bottomToolBar.findButton.width + 1
	mainContainer.bottomToolBar.inputField.width = mainContainer.bottomToolBar.width - mainContainer.bottomToolBar.inputField.localX - mainContainer.bottomToolBar.findButton.width + 1

	mainContainer.topToolBar.width, mainContainer.topToolBar.backgroundPanel.width = mainContainer.width, mainContainer.width
	mainContainer.titleTextBox.width = math.floor(mainContainer.topToolBar.width * 0.32)
	mainContainer.titleTextBox.localX = math.floor(mainContainer.topToolBar.width / 2 - mainContainer.titleTextBox.width / 2)
	mainContainer.runButton.localX = mainContainer.titleTextBox.localX - mainContainer.runButton.width - 2
	mainContainer.toggleSyntaxHighlightingButton.localX = mainContainer.runButton.localX - mainContainer.toggleSyntaxHighlightingButton.width - 2
	mainContainer.addBreakpointButton.localX = mainContainer.toggleSyntaxHighlightingButton.localX - mainContainer.addBreakpointButton.width - 2
	mainContainer.toggleLeftToolBarButton.localX = mainContainer.titleTextBox.localX + mainContainer.titleTextBox.width + 2
	mainContainer.toggleBottomToolBarButton.localX = mainContainer.toggleLeftToolBarButton.localX + mainContainer.toggleLeftToolBarButton.width + 2
	mainContainer.toggleTopToolBarButton.localX = mainContainer.toggleBottomToolBarButton.localX + mainContainer.toggleBottomToolBarButton.width + 2

	mainContainer.RAMUsageProgressBar.localX = mainContainer.toggleTopToolBarButton.localX + mainContainer.toggleTopToolBarButton.width + 3
	mainContainer.RAMUsageProgressBar.width = mainContainer.topToolBar.width - mainContainer.RAMUsageProgressBar.localX - 3

	mainContainer.errorContainer.localX, mainContainer.errorContainer.width = mainContainer.titleTextBox.localX, mainContainer.titleTextBox.width
	mainContainer.errorContainer.backgroundPanel.width, mainContainer.errorContainer.errorTextBox.width = mainContainer.errorContainer.width, mainContainer.errorContainer.width - 4

	mainContainer.topMenu.width = mainContainer.width
end

local function updateTitle()
	if not mainContainer.topToolBar.hidden then
		if mainContainer.errorContainer.hidden then
			mainContainer.titleTextBox.lines[1] = string.limit(localization.file .. ": " .. (mainContainer.leftTreeView.selectedItem or localization.none), mainContainer.titleTextBox.width - 4)
			mainContainer.titleTextBox.lines[2] = string.limit(localization.cursor .. cursor.position.line .. localization.line .. cursor.position.symbol .. localization.symbol, mainContainer.titleTextBox.width - 4)
			if mainContainer.codeView.selections[1] then
				local countOfSelectedLines = mainContainer.codeView.selections[1].to.line - mainContainer.codeView.selections[1].from.line + 1
				local countOfSelectedSymbols
				if mainContainer.codeView.selections[1].from.line == mainContainer.codeView.selections[1].to.line then
					countOfSelectedSymbols = unicode.len(unicode.sub(mainContainer.codeView.lines[mainContainer.codeView.selections[1].from.line], mainContainer.codeView.selections[1].from.symbol, mainContainer.codeView.selections[1].to.symbol))
				else
					countOfSelectedSymbols = unicode.len(unicode.sub(mainContainer.codeView.lines[mainContainer.codeView.selections[1].from.line], mainContainer.codeView.selections[1].from.symbol, -1))
					for line = mainContainer.codeView.selections[1].from.line + 1, mainContainer.codeView.selections[1].to.line - 1 do
						countOfSelectedSymbols = countOfSelectedSymbols + unicode.len(mainContainer.codeView.lines[line])
					end
					countOfSelectedSymbols = countOfSelectedSymbols + unicode.len(unicode.sub(mainContainer.codeView.lines[mainContainer.codeView.selections[1].to.line], 1, mainContainer.codeView.selections[1].to.symbol))
				end
				mainContainer.titleTextBox.lines[3] = string.limit(localization.selection .. countOfSelectedLines .. localization.lines .. countOfSelectedSymbols .. localization.symbols, mainContainer.titleTextBox.width - 4)
			else
				mainContainer.titleTextBox.lines[3] = string.limit(localization.selection .. localization.none, mainContainer.titleTextBox.width - 4)
			end
		else
			mainContainer.titleTextBox.lines[1], mainContainer.titleTextBox.lines[3] = " ", " "
			if lastErrorLine then
				mainContainer.titleTextBox.lines[2] = localization.runtimeError
			else
				mainContainer.titleTextBox.lines[2] = localization.debugging .. (_G.MineCodeIDEDebugInfo and _G.MineCodeIDEDebugInfo.line or "N/A")
			end
		end
	end
end

local function gotoLine(line)
	mainContainer.codeView.fromLine = math.ceil(line - mainContainer.codeView.height / 2)
	if mainContainer.codeView.fromLine < 1 then
		mainContainer.codeView.fromLine = 1
	elseif mainContainer.codeView.fromLine > #mainContainer.codeView.lines then
		mainContainer.codeView.fromLine = #mainContainer.codeView.lines
	end
end

local function updateHighlights()
	mainContainer.codeView.highlights = {}

	if breakpointLines then
		for i = 1, #breakpointLines do
			mainContainer.codeView.highlights[breakpointLines[i]] = colors.highlights.onBreakpoint
		end
	end

	if lastErrorLine then
		mainContainer.codeView.highlights[lastErrorLine] = colors.highlights.onError
	end
end

local function calculateErrorContainerSizeAndBeep(hideBreakpointButtons, frequency, times)
	mainContainer.errorContainer.errorTextBox.height = #mainContainer.errorContainer.errorTextBox.lines
	mainContainer.errorContainer.height = 2 + mainContainer.errorContainer.errorTextBox.height
	mainContainer.errorContainer.backgroundPanel.height = mainContainer.errorContainer.height

	mainContainer.errorContainer.breakpointExitButton.hidden, mainContainer.errorContainer.breakpointContinueButton.hidden = hideBreakpointButtons, hideBreakpointButtons
	if not hideBreakpointButtons then
		mainContainer.errorContainer.height = mainContainer.errorContainer.height + 1
		mainContainer.errorContainer.breakpointExitButton.localY, mainContainer.errorContainer.breakpointContinueButton.localY = mainContainer.errorContainer.height, mainContainer.errorContainer.height
		mainContainer.errorContainer.breakpointExitButton.width = math.floor(mainContainer.errorContainer.width / 2)
		mainContainer.errorContainer.breakpointContinueButton.localX, mainContainer.errorContainer.breakpointContinueButton.width = mainContainer.errorContainer.breakpointExitButton.width + 1, mainContainer.errorContainer.width - mainContainer.errorContainer.breakpointExitButton.width
	end

	updateTitle()
	mainContainer:draw()
	buffer.draw()

	for i = 1, times do component.computer.beep(frequency, 0.08) end	
end

local function showBreakpointMessage(variables)
	mainContainer.titleTextBox.colors.background, mainContainer.titleTextBox.colors.text = colors.title.onError.background, colors.title.onError.text
	mainContainer.errorContainer.hidden = false

	mainContainer.errorContainer.errorTextBox:setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	mainContainer.errorContainer.errorTextBox.lines = {}

	for variable, value in pairs(variables) do
		table.insert(mainContainer.errorContainer.errorTextBox.lines, variable .. " = " .. value)
	end

	if #mainContainer.errorContainer.errorTextBox.lines > 0 then
		table.insert(mainContainer.errorContainer.errorTextBox.lines, 1, " ")
		table.insert(mainContainer.errorContainer.errorTextBox.lines, 1, {text = localization.variables, color = 0x0})
	else
		table.insert(mainContainer.errorContainer.errorTextBox.lines, 1, {text = localization.variablesNotAvailable, color = 0x0})
	end

	calculateErrorContainerSizeAndBeep(false, 1800, 1)
end

local function showErrorContainer(errorCode)
	mainContainer.titleTextBox.colors.background, mainContainer.titleTextBox.colors.text = colors.title.onError.background, colors.title.onError.text
	mainContainer.errorContainer.hidden = false

	mainContainer.errorContainer.errorTextBox:setAlignment(GUI.alignment.horizontal.left, GUI.alignment.vertical.top)
	mainContainer.errorContainer.errorTextBox.lines = string.wrap({errorCode}, mainContainer.errorContainer.errorTextBox.width)	
	
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
	calculateErrorContainerSizeAndBeep(true, 1500, 3)
end

local function hideErrorContainer()
	mainContainer.titleTextBox.colors.background, mainContainer.titleTextBox.colors.text = colors.title.default.background, colors.title.default.text
	mainContainer.errorContainer.hidden = true
	lastErrorLine, scriptCoroutine = nil, nil
	updateHighlights()
end

local function hideSettingsContainer()
	for childIndex = 2, #mainContainer.settingsContainer.children do mainContainer.settingsContainer.children[childIndex] = nil end
	mainContainer.settingsContainer.hidden = true
	mainContainer:draw()
	buffer.draw()
end

local function clearSelection()
	mainContainer.codeView.selections[1] = nil
end

local function clearBreakpoints()
	breakpointLines = nil
	updateHighlights()
end

local function addBreakpoint()
	hideErrorContainer()
	breakpointLines = breakpointLines or {}
	
	local lineExists
	for i = 1, #breakpointLines do
		if breakpointLines[i] == cursor.position.line then
			lineExists = i
			break
		end
	end
	
	if lineExists then
		table.remove(breakpointLines, lineExists)
	else
		table.insert(breakpointLines, cursor.position.line)
	end

	if #breakpointLines > 0 then
		table.sort(breakpointLines, function(a, b) return a < b end)
	else
		breakpointLines = nil
	end

	updateHighlights()
end

local function fixFromLineByCursorPosition()
	if mainContainer.codeView.fromLine > cursor.position.line then
		mainContainer.codeView.fromLine = cursor.position.line
	elseif mainContainer.codeView.fromLine + mainContainer.codeView.height - 2 < cursor.position.line then
		mainContainer.codeView.fromLine = cursor.position.line - mainContainer.codeView.height + 2
	end
end

local function fixFromSymbolByCursorPosition()
	if mainContainer.codeView.fromSymbol > cursor.position.symbol then
		mainContainer.codeView.fromSymbol = cursor.position.symbol
	elseif mainContainer.codeView.fromSymbol + mainContainer.codeView.codeAreaWidth - 3 < cursor.position.symbol then
		mainContainer.codeView.fromSymbol = cursor.position.symbol - mainContainer.codeView.codeAreaWidth + 3
	end
end

local function fixCursorPosition(symbol, line)
	if line < 1 then
		line = 1
	elseif line > #mainContainer.codeView.lines then
		line = #mainContainer.codeView.lines
	end

	local lineLength = unicode.len(mainContainer.codeView.lines[line])
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
	hideAutocompleteWindow()
	hideErrorContainer()
end

local function setCursorPositionAndClearSelection(symbol, line)
	setCursorPosition(symbol, line)
	clearSelection()
end

local function moveCursor(symbolOffset, lineOffset)
	if mainContainer.autocompleteWindow.hidden or lineOffset == 0 then
		if mainContainer.codeView.selections[1] then
			if symbolOffset < 0 or lineOffset < 0 then
				setCursorPositionAndClearSelection(mainContainer.codeView.selections[1].from.symbol, mainContainer.codeView.selections[1].from.line)
			else
				setCursorPositionAndClearSelection(mainContainer.codeView.selections[1].to.symbol, mainContainer.codeView.selections[1].to.line)
			end
		else
			local newSymbol, newLine = cursor.position.symbol + symbolOffset, cursor.position.line + lineOffset
			
			if symbolOffset < 0 and newSymbol < 1 then
				newLine, newSymbol = newLine - 1, math.huge
			elseif symbolOffset > 0 and newSymbol > unicode.len(mainContainer.codeView.lines[newLine] or "") + 1 then
				newLine, newSymbol = newLine + 1, 1
			end

			setCursorPositionAndClearSelection(newSymbol, newLine)
		end
	elseif not mainContainer.autocompleteWindow.hidden then
		mainContainer.autocompleteWindow.currentMatch = mainContainer.autocompleteWindow.currentMatch + lineOffset
		
		if mainContainer.autocompleteWindow.currentMatch < 1 then
			mainContainer.autocompleteWindow.currentMatch = 1
		elseif mainContainer.autocompleteWindow.currentMatch > #mainContainer.autocompleteWindow.matches then
			mainContainer.autocompleteWindow.currentMatch = #mainContainer.autocompleteWindow.matches
		elseif mainContainer.autocompleteWindow.currentMatch < mainContainer.autocompleteWindow.fromMatch then
			mainContainer.autocompleteWindow.fromMatch = mainContainer.autocompleteWindow.currentMatch
		elseif mainContainer.autocompleteWindow.currentMatch > mainContainer.autocompleteWindow.fromMatch + mainContainer.autocompleteWindow.height - 1 then
			mainContainer.autocompleteWindow.fromMatch = mainContainer.autocompleteWindow.currentMatch - mainContainer.autocompleteWindow.height + 1
		end
	end
end

local function setCursorPositionToHome()
	setCursorPositionAndClearSelection(1, 1)
end

local function setCursorPositionToEnd()
	setCursorPositionAndClearSelection(unicode.len(mainContainer.codeView.lines[#mainContainer.codeView.lines]) + 1, #mainContainer.codeView.lines)
end

local function scroll(direction, speed)
	if direction == 1 then
		if mainContainer.codeView.fromLine > speed then
			mainContainer.codeView.fromLine = mainContainer.codeView.fromLine - speed
		else
			mainContainer.codeView.fromLine = 1
		end
	else
		if mainContainer.codeView.fromLine < #mainContainer.codeView.lines - speed then
			mainContainer.codeView.fromLine = mainContainer.codeView.fromLine + speed
		else
			mainContainer.codeView.fromLine = #mainContainer.codeView.lines
		end
	end
end

local function pageUp()
	scroll(1, mainContainer.codeView.height - 2)
end

local function pageDown()
	scroll(-1, mainContainer.codeView.height - 2)
end

local function selectWord()
	local from, to = getCurrentWordStartingAndEnding(cursor.position.symbol)
	if from and to then
		mainContainer.codeView.selections[1] = {
			from = {symbol = from, line = cursor.position.line},
			to = {symbol = to, line = cursor.position.line},
		}
		cursor.position.symbol = to
	end
end

local function removeTabs(text)
	local result = text:gsub("\t", string.rep(" ", mainContainer.codeView.indentationWidth))
	return result
end

local function removeWindowsLineEndings(text)
	local result = text:gsub("\r\n", "\n")
	return result
end

local function changeResolution(width, height)
	buffer.setResolution(width, height)
	calculateSizes()
	mainContainer:draw()
	buffer.draw()
	config.screenResolution.width = width
	config.screenResolution.height = height
end

local function changeResolutionWindow()
	mainContainer.settingsContainer.hidden = false
	local textBoxesWidth = math.floor(mainContainer.width * 0.3)
	local textBoxWidth, x, y = math.floor(textBoxesWidth / 2), math.floor(mainContainer.width / 2 - textBoxesWidth / 2), math.floor(mainContainer.height / 2) - 3
	
	mainContainer.settingsContainer:addChild(GUI.label(1, y, mainContainer.width, 1, 0xFFFFFF, localization.changeResolution)):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top); y = y + 3
	local inputFieldWidth = mainContainer.settingsContainer:addChild(GUI.input(x, y, textBoxWidth, 3, 0xCCCCCC, 0x777777, 0x777777, 0xCCCCCC, 0x2D2D2D, tostring(config.screenResolution.width))); x = x + textBoxWidth + 2
	local inputFieldHeight = mainContainer.settingsContainer:addChild(GUI.input(x, y, textBoxWidth, 3, 0xCCCCCC, 0x777777, 0x777777, 0xCCCCCC, 0x2D2D2D, tostring(config.screenResolution.height)))
	
	local maxResolutionWidth, maxResolutionHeight = component.gpu.maxResolution()
	inputFieldWidth.validator = function(text)
		local number = tonumber(text)
		if number and number >= 1 and number <= maxResolutionWidth then return true end
	end
	inputFieldHeight.validator = function(text)
		local number = tonumber(text)
		if number and number >= 1 and number <= maxResolutionHeight then return true end
	end

	mainContainer.settingsContainer.backgroundPanel.eventHandler = function(mainContainer, object, eventData)
		if eventData[1] == "touch" then
			config.screenResolution.width, config.screenResolution.height = tonumber(inputFieldWidth.text), tonumber(inputFieldHeight.text)
			saveConfig()
			hideSettingsContainer()
			changeResolution(config.screenResolution.width, config.screenResolution.height)
		end
	end
end

local function createInputTextBoxForSettingsWindow(title, placeholder, onInputFinishedMethod, validatorMethod)
	mainContainer.settingsContainer.hidden = false
	local textBoxWidth = math.floor(mainContainer.width * 0.3)
	local x, y = math.floor(mainContainer.width / 2 - textBoxWidth / 2), math.floor(mainContainer.height / 2) - 3
	
	mainContainer.settingsContainer:addChild(GUI.label(1, y, mainContainer.width, 1, 0xFFFFFF, title)):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top); y = y + 3
	mainContainer.settingsContainer.inputField = mainContainer.settingsContainer:addChild(GUI.input(x, y, textBoxWidth, 3, 0xCCCCCC, 0x777777, 0x777777, 0xCCCCCC, 0x2D2D2D, "", placeholder))
	
	mainContainer.settingsContainer.inputField.validator = validatorMethod
	mainContainer.settingsContainer.inputField.onInputFinished = function(...)
		onInputFinishedMethod(...)
		hideSettingsContainer()
	end
end

local function newFile()
	autocompleteDatabase = {}
	mainContainer.codeView.lines = {""}
	mainContainer.codeView.maximumLineLength = 1
	setCursorPositionAndClearSelection(1, 1)
	mainContainer.leftTreeView.selectedItem = nil
	clearBreakpoints()
end

local function loadFile(path)
	local file, reason = io.open(path, "r")
	if file then
		newFile()
		for line in file:lines() do
			line = removeWindowsLineEndings(removeTabs(line))
			table.insert(mainContainer.codeView.lines, line)
			mainContainer.codeView.maximumLineLength = math.max(mainContainer.codeView.maximumLineLength, unicode.len(line))
		end
		file:close()
		
		if #mainContainer.codeView.lines > 1 then
			table.remove(mainContainer.codeView.lines, 1)
		end
		
		mainContainer.leftTreeView.selectedItem = path
		updateAutocompleteDatabaseFromFile()
	else
		GUI.error(reason)
	end
end

local function saveFile(path)
	fs.makeDirectory(fs.path(path))
	local file, reason = io.open(path, "w")
		if file then
		for line = 1, #mainContainer.codeView.lines do
			file:write(mainContainer.codeView.lines[line], "\n")
		end
		file:close()
	else
		GUI.error("Failed to open file for writing: " .. tostring(reason))
	end
end

local function gotoLineWindow()
	createInputTextBoxForSettingsWindow(localization.gotoLine, localization.lineNumber,
		function()
			gotoLine(tonumber(mainContainer.settingsContainer.inputField.text))
		end,
		function()
			if mainContainer.settingsContainer.inputField.text:match("%d+") then return true end
		end
	)
end

local function openFileWindow()
	createInputTextBoxForSettingsWindow(localization.openFile, localization.pathToFile,
		function()
			loadFile(mainContainer.settingsContainer.inputField.text)
		end,
		function()
			if fs.exists(mainContainer.settingsContainer.inputField.text) then return true end
		end
	)
end

local function saveFileAsWindow()
	createInputTextBoxForSettingsWindow(localization.saveAs, localization.pathToFile,
		function()
			if unicode.len(mainContainer.settingsContainer.inputField.text or "") > 0 then
				saveFile(mainContainer.settingsContainer.inputField.text)
				mainContainer.leftTreeView:updateFileList()
				mainContainer.leftTreeView.selectedItem = mainContainer.leftTreeView.workPath .. mainContainer.settingsContainer.inputField.text
				
				updateTitle()
				mainContainer:draw()
				buffer.draw()
			end
		end
	)
end

local function saveFileWindow()
	saveFile(mainContainer.leftTreeView.selectedItem)
	mainContainer.leftTreeView:updateFileList()
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
	createInputTextBoxForSettingsWindow(localization.getFromWeb, localization.url,
		function()
			local result, reason = web.request(mainContainer.settingsContainer.inputField.text)
			if result then
				newFile()
				mainContainer.codeView.lines, mainContainer.codeView.maximumLineLength = splitStringIntoLines(result)
			else
				GUI.error("Failed to connect to URL: " .. tostring(reason))
			end
			hideSettingsContainer()
		end
	)
end

------------------------------------------------------------------------------------------------------------------

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

local function continue()
	-- Готовим экран к запуску
	local oldResolutionX, oldResolutionY = component.gpu.getResolution()
	MineOSInterface.clearTerminal()

	-- Запускаем
	_G.MineCodeIDEDebugInfo = nil
	local coroutineResumeSuccess, coroutineResumeReason = coroutine.resume(scriptCoroutine)

	-- Анализируем результат запуска
	if coroutineResumeSuccess then
		if coroutine.status(scriptCoroutine) == "dead" then
			MineOSInterface.waitForPressingAnyKey()
			hideErrorContainer()
			buffer.setResolution(oldResolutionX, oldResolutionY); mainContainer:draw(); buffer.draw(true)
		else
			-- Тест на пидора, мало ли у чувака в проге тоже есть yield
			if _G.MineCodeIDEDebugInfo then
				buffer.setResolution(oldResolutionX, oldResolutionY); mainContainer:draw(); buffer.draw(true)
				gotoLine(_G.MineCodeIDEDebugInfo.line)
				showBreakpointMessage(_G.MineCodeIDEDebugInfo.variables)
			end
		end
	else
		buffer.setResolution(oldResolutionX, oldResolutionY); mainContainer:draw(); buffer.draw(true)
		showErrorContainer(debug.traceback(scriptCoroutine, coroutineResumeReason))
	end
end

local function run()
	hideErrorContainer()

	-- Инсертим брейкпоинты
	if breakpointLines then
		local offset = 0
		for i = 1, #breakpointLines do
			local variables = getVariables(mainContainer.codeView.lines[breakpointLines[i] + offset])
			
			local breakpointMessage = "_G.MineCodeIDEDebugInfo = {variables = {"
			for variable in pairs(variables) do
				breakpointMessage = breakpointMessage .. "[\"" .. variable .. "\"] = type(" .. variable .. ") == 'string' and '\"' .. " .. variable .. " .. '\"' or tostring(" .. variable .. "), "
			end
			breakpointMessage =  breakpointMessage .. "}, line = " .. breakpointLines[i] .. "}; coroutine.yield()"

			table.insert(mainContainer.codeView.lines, breakpointLines[i] + offset, breakpointMessage)
			offset = offset + 1
		end
	end

	-- Лоадим кодыч
	local loadSuccess, loadReason = load(table.concat(mainContainer.codeView.lines, "\n"))
	
	-- Чистим дерьмо вилочкой, чистим
	if breakpointLines then
		for i = 1, #breakpointLines do
			table.remove(mainContainer.codeView.lines, breakpointLines[i])
		end
	end

	-- Запускаем кодыч
	if loadSuccess then
		scriptCoroutine = coroutine.create(loadSuccess)
		continue()
	else
		showErrorContainer(loadReason)
	end
end

local function deleteLine(line)
	if #mainContainer.codeView.lines > 1 then
		table.remove(mainContainer.codeView.lines, line)
		setCursorPositionAndClearSelection(1, cursor.position.line)

		updateAutocompleteDatabaseFromFile()
	end
end

local function deleteSpecifiedData(fromSymbol, fromLine, toSymbol, toLine)
	local upperLine = unicode.sub(mainContainer.codeView.lines[fromLine], 1, fromSymbol - 1)
	local lowerLine = unicode.sub(mainContainer.codeView.lines[toLine], toSymbol + 1, -1)
	for line = fromLine + 1, toLine do
		table.remove(mainContainer.codeView.lines, fromLine + 1)
	end
	mainContainer.codeView.lines[fromLine] = upperLine .. lowerLine
	setCursorPositionAndClearSelection(fromSymbol, fromLine)

	updateAutocompleteDatabaseFromFile()
end

local function deleteSelectedData()
	if mainContainer.codeView.selections[1] then
		deleteSpecifiedData(
			mainContainer.codeView.selections[1].from.symbol,
			mainContainer.codeView.selections[1].from.line,
			mainContainer.codeView.selections[1].to.symbol,
			mainContainer.codeView.selections[1].to.line
		)

		clearSelection()
	end
end

local function copy()
	if mainContainer.codeView.selections[1] then
		if mainContainer.codeView.selections[1].to.line == mainContainer.codeView.selections[1].from.line then
			clipboard = { unicode.sub(mainContainer.codeView.lines[mainContainer.codeView.selections[1].from.line], mainContainer.codeView.selections[1].from.symbol, mainContainer.codeView.selections[1].to.symbol) }
		else
			clipboard = { unicode.sub(mainContainer.codeView.lines[mainContainer.codeView.selections[1].from.line], mainContainer.codeView.selections[1].from.symbol, -1) }
			for line = mainContainer.codeView.selections[1].from.line + 1, mainContainer.codeView.selections[1].to.line - 1 do
				table.insert(clipboard, mainContainer.codeView.lines[line])
			end
			table.insert(clipboard, unicode.sub(mainContainer.codeView.lines[mainContainer.codeView.selections[1].to.line], 1, mainContainer.codeView.selections[1].to.symbol))
		end
	end
end

local function cut()
	if mainContainer.codeView.selections[1] then
		copy()
		deleteSelectedData()
	end
end

local function pasteSelectedAutocompletion()
	local firstPart = unicode.sub(mainContainer.codeView.lines[cursor.position.line], 1, mainContainer.autocompleteWindow.currentWordStarting - 1)
	local secondPart = unicode.sub(mainContainer.codeView.lines[cursor.position.line], mainContainer.autocompleteWindow.currentWordEnding + 1, -1)
	mainContainer.codeView.lines[cursor.position.line] = firstPart .. mainContainer.autocompleteWindow.matches[mainContainer.autocompleteWindow.currentMatch][1] .. secondPart
	setCursorPositionAndClearSelection(unicode.len(firstPart .. mainContainer.autocompleteWindow.matches[mainContainer.autocompleteWindow.currentMatch][1]) + 1, cursor.position.line)
	hideAutocompleteWindow()
end

local function paste(pasteLines)
	if pasteLines then
		if mainContainer.codeView.selections[1] then
			deleteSelectedData()
		end

		local firstPart = unicode.sub(mainContainer.codeView.lines[cursor.position.line], 1, cursor.position.symbol - 1)
		local secondPart = unicode.sub(mainContainer.codeView.lines[cursor.position.line], cursor.position.symbol, -1)

		if #pasteLines == 1 then
			mainContainer.codeView.lines[cursor.position.line] = firstPart .. pasteLines[1] .. secondPart
			setCursorPositionAndClearSelection(cursor.position.symbol + unicode.len(pasteLines[1]), cursor.position.line)
		else
			mainContainer.codeView.lines[cursor.position.line] = firstPart .. pasteLines[1]
			for pasteLine = #pasteLines - 1, 2, -1 do
				table.insert(mainContainer.codeView.lines, cursor.position.line + 1, pasteLines[pasteLine])
			end
			table.insert(mainContainer.codeView.lines, cursor.position.line + #pasteLines - 1, pasteLines[#pasteLines] .. secondPart)
			setCursorPositionAndClearSelection(unicode.len(pasteLines[#pasteLines]) + 1, cursor.position.line + #pasteLines - 1)
		end

		updateAutocompleteDatabaseFromFile()
	end
end

local function selectAndPasteColor()
	local startColor = 0xFF0000
	if mainContainer.codeView.selections[1] and mainContainer.codeView.selections[1].from.line == mainContainer.codeView.selections[1].to.line then
		startColor = tonumber(unicode.sub(mainContainer.codeView.lines[mainContainer.codeView.selections[1].from.line], mainContainer.codeView.selections[1].from.symbol, mainContainer.codeView.selections[1].to.symbol)) or startColor
	end

	local selectedColor = GUI.palette(math.floor(mainContainer.width / 2 - 35), math.floor(mainContainer.height / 2 - 12), startColor):show()
	if selectedColor then
		paste({string.format("0x%06X", selectedColor)})
	end
end

local function pasteRegularChar(unicodeByte, char)
	if not keyboard.isControl(unicodeByte) then
		paste({char})
		if char == " " then
			updateAutocompleteDatabaseFromFile()
		end
		showAutocompleteWindow()
	end
end

local function pasteAutoBrackets(unicodeByte)
	local char = unicode.char(unicodeByte)
	local currentSymbol = unicode.sub(mainContainer.codeView.lines[cursor.position.line], cursor.position.symbol, cursor.position.symbol)

	-- Если у нас вообще врублен режим автоскобок, то чекаем их
	if config.enableAutoBrackets then
		-- Ситуация, когда курсор находится на закрывающей скобке, и нехуй ее еще раз вставлять
		if possibleBrackets.closers[char] and currentSymbol == char then
			deleteSelectedData()
			setCursorPosition(cursor.position.symbol + 1, cursor.position.line)
		-- Если нажата открывающая скобка
		elseif possibleBrackets.openers[char] then
			-- А вот тут мы берем в скобочки уже выделенный текст
			if mainContainer.codeView.selections[1] then
				local firstPart = unicode.sub(mainContainer.codeView.lines[mainContainer.codeView.selections[1].from.line], 1, mainContainer.codeView.selections[1].from.symbol - 1)
				local secondPart = unicode.sub(mainContainer.codeView.lines[mainContainer.codeView.selections[1].from.line], mainContainer.codeView.selections[1].from.symbol, -1)
				mainContainer.codeView.lines[mainContainer.codeView.selections[1].from.line] = firstPart .. char .. secondPart
				mainContainer.codeView.selections[1].from.symbol = mainContainer.codeView.selections[1].from.symbol + 1

				if mainContainer.codeView.selections[1].to.line == mainContainer.codeView.selections[1].from.line then
					mainContainer.codeView.selections[1].to.symbol = mainContainer.codeView.selections[1].to.symbol + 1
				end

				firstPart = unicode.sub(mainContainer.codeView.lines[mainContainer.codeView.selections[1].to.line], 1, mainContainer.codeView.selections[1].to.symbol)
				secondPart = unicode.sub(mainContainer.codeView.lines[mainContainer.codeView.selections[1].to.line], mainContainer.codeView.selections[1].to.symbol + 1, -1)
				mainContainer.codeView.lines[mainContainer.codeView.selections[1].to.line] = firstPart .. possibleBrackets.openers[char] .. secondPart
				cursor.position.symbol = cursor.position.symbol + 2
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
	local previousSymbol = unicode.sub(mainContainer.codeView.lines[cursor.position.line], cursor.position.symbol - 1, cursor.position.symbol - 1)
	local currentSymbol = unicode.sub(mainContainer.codeView.lines[cursor.position.line], cursor.position.symbol, cursor.position.symbol)
	if config.enableAutoBrackets and possibleBrackets.openers[previousSymbol] and possibleBrackets.openers[previousSymbol] == currentSymbol then
		deleteSpecifiedData(cursor.position.symbol, cursor.position.line, cursor.position.symbol, cursor.position.line)
	end
end

local function delete()
	if mainContainer.codeView.selections[1] then
		deleteSelectedData()
	else
		if cursor.position.symbol < unicode.len(mainContainer.codeView.lines[cursor.position.line]) + 1 then
			deleteSpecifiedData(cursor.position.symbol, cursor.position.line, cursor.position.symbol, cursor.position.line)
		else
			if cursor.position.line > 1 and mainContainer.codeView.lines[cursor.position.line + 1] then
				deleteSpecifiedData(unicode.len(mainContainer.codeView.lines[cursor.position.line]) + 1, cursor.position.line, 0, cursor.position.line + 1)
			end
		end

		-- updateAutocompleteDatabaseFromFile()
		showAutocompleteWindow()
	end
end

local function backspace()
	if mainContainer.codeView.selections[1] then
		deleteSelectedData()
	else
		if cursor.position.symbol > 1 then
			backspaceAutoBrackets()
			deleteSpecifiedData(cursor.position.symbol - 1, cursor.position.line, cursor.position.symbol - 1, cursor.position.line)
		else
			if cursor.position.line > 1 then
				deleteSpecifiedData(unicode.len(mainContainer.codeView.lines[cursor.position.line - 1]) + 1, cursor.position.line - 1, 0, cursor.position.line)
			end
		end

		-- updateAutocompleteDatabaseFromFile()
		showAutocompleteWindow()
	end
end

local function enter()
	local firstPart = unicode.sub(mainContainer.codeView.lines[cursor.position.line], 1, cursor.position.symbol - 1)
	local secondPart = unicode.sub(mainContainer.codeView.lines[cursor.position.line], cursor.position.symbol, -1)
	mainContainer.codeView.lines[cursor.position.line] = firstPart
	table.insert(mainContainer.codeView.lines, cursor.position.line + 1, secondPart)
	setCursorPositionAndClearSelection(1, cursor.position.line + 1)
end

local function selectAll()
	mainContainer.codeView.selections[1] = {
		from = {
			symbol = 1, line = 1
		},
		to = {
			symbol = unicode.len(mainContainer.codeView.lines[#mainContainer.codeView.lines]), line = #mainContainer.codeView.lines
		}
	}
end

local function isLineCommented(line)
	if mainContainer.codeView.lines[line] == "" or mainContainer.codeView.lines[line]:match("%-%-%s?") then return true end
end

local function commentLine(line)
	mainContainer.codeView.lines[line] = "-- " .. mainContainer.codeView.lines[line]
end

local function uncommentLine(line)
	local countOfReplaces
	mainContainer.codeView.lines[line], countOfReplaces = mainContainer.codeView.lines[line]:gsub("%-%-%s?", "", 1)
	return countOfReplaces
end

local function toggleComment()
	if mainContainer.codeView.selections[1] then
		local allLinesAreCommented = true
		
		for line = mainContainer.codeView.selections[1].from.line, mainContainer.codeView.selections[1].to.line do
			if not isLineCommented(line) then
				allLinesAreCommented = false
				break
			end
		end
		
		for line = mainContainer.codeView.selections[1].from.line, mainContainer.codeView.selections[1].to.line do
			if allLinesAreCommented then
				uncommentLine(line)
			else
				commentLine(line)
			end
		end

		local modifyer = 3
		if allLinesAreCommented then modifyer = -modifyer end
		setCursorPosition(cursor.position.symbol + modifyer, cursor.position.line)
		mainContainer.codeView.selections[1].from.symbol, mainContainer.codeView.selections[1].to.symbol = mainContainer.codeView.selections[1].from.symbol + modifyer, mainContainer.codeView.selections[1].to.symbol + modifyer
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
	mainContainer.codeView.lines[line] = string.rep(" ", mainContainer.codeView.indentationWidth) .. mainContainer.codeView.lines[line]
end

local function unindentLine(line)
	mainContainer.codeView.lines[line], countOfReplaces = string.gsub(mainContainer.codeView.lines[line], "^" .. string.rep("%s", mainContainer.codeView.indentationWidth), "")
	return countOfReplaces
end

local function indentOrUnindent(isIndent)
	if mainContainer.codeView.selections[1] then
		local countOfReplacesInFirstLine, countOfReplacesInLastLine
		
		for line = mainContainer.codeView.selections[1].from.line, mainContainer.codeView.selections[1].to.line do
			if isIndent then
				indentLine(line)
			else
				local countOfReplaces = unindentLine(line)
				if line == mainContainer.codeView.selections[1].from.line then
					countOfReplacesInFirstLine = countOfReplaces
				elseif line == mainContainer.codeView.selections[1].to.line then
					countOfReplacesInLastLine = countOfReplaces
				end
			end
		end		

		if isIndent then
			setCursorPosition(cursor.position.symbol + mainContainer.codeView.indentationWidth, cursor.position.line)
			mainContainer.codeView.selections[1].from.symbol, mainContainer.codeView.selections[1].to.symbol = mainContainer.codeView.selections[1].from.symbol + mainContainer.codeView.indentationWidth, mainContainer.codeView.selections[1].to.symbol + mainContainer.codeView.indentationWidth
		else
			if countOfReplacesInFirstLine > 0 then
				mainContainer.codeView.selections[1].from.symbol = mainContainer.codeView.selections[1].from.symbol - mainContainer.codeView.indentationWidth
				if cursor.position.line == mainContainer.codeView.selections[1].from.line then
					setCursorPosition(cursor.position.symbol - mainContainer.codeView.indentationWidth, cursor.position.line)
				end
			end

			if countOfReplacesInLastLine > 0 then
				mainContainer.codeView.selections[1].to.symbol = mainContainer.codeView.selections[1].to.symbol - mainContainer.codeView.indentationWidth
				if cursor.position.line == mainContainer.codeView.selections[1].to.line then
					setCursorPosition(cursor.position.symbol - mainContainer.codeView.indentationWidth, cursor.position.line)
				end
			end
		end
	else
		if isIndent then
			indentLine(cursor.position.line)
			setCursorPositionAndClearSelection(cursor.position.symbol + mainContainer.codeView.indentationWidth, cursor.position.line)
		else
			if unindentLine(cursor.position.line) > 0 then
				setCursorPositionAndClearSelection(cursor.position.symbol - mainContainer.codeView.indentationWidth, cursor.position.line)
			end
		end
	end
end

local function updateRAMProgressBar()
	if not mainContainer.topToolBar.hidden then
		local totalMemory = computer.totalMemory()
		mainContainer.RAMUsageProgressBar.value = math.ceil((totalMemory - computer.freeMemory()) / totalMemory * 100)
	end
end

local function find()
	if not mainContainer.bottomToolBar.hidden and mainContainer.bottomToolBar.inputField.text ~= "" then
		findStartFrom = findStartFrom + 1
	
		for line = findStartFrom, #mainContainer.codeView.lines do
			local whereToFind, whatToFind = mainContainer.codeView.lines[line], mainContainer.bottomToolBar.inputField.text
			if not mainContainer.bottomToolBar.caseSensitiveButton.pressed then
				whereToFind, whatToFind = unicode.lower(whereToFind), unicode.lower(whatToFind)
			end

			local success, starting, ending = pcall(string.unicodeFind, whereToFind, whatToFind)
			if success then
				if starting then
					mainContainer.codeView.selections[1] = {
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
	findStartFrom = mainContainer.codeView.fromLine
	find()
end

local function toggleBottomToolBar()
	mainContainer.bottomToolBar.hidden = not mainContainer.bottomToolBar.hidden
	mainContainer.toggleBottomToolBarButton.pressed = not mainContainer.bottomToolBar.hidden
	calculateSizes()
		
	if not mainContainer.bottomToolBar.hidden then
		mainContainer:draw()
		findFromFirstDisplayedLine()
	end
end

local function toggleTopToolBar()
	mainContainer.topToolBar.hidden = not mainContainer.topToolBar.hidden
	mainContainer.toggleTopToolBarButton.pressed = not mainContainer.topToolBar.hidden
	calculateSizes()
end

local function createEditOrRightClickMenu(x, y)
	local editOrRightClickMenu = GUI.contextMenu(x, y)
	editOrRightClickMenu:addItem(localization.cut, not mainContainer.codeView.selections[1], "^X").onTouch = function()
		cut()
	end
	editOrRightClickMenu:addItem(localization.copy, not mainContainer.codeView.selections[1], "^C").onTouch = function()
		copy()
	end
	editOrRightClickMenu:addItem(localization.paste, not clipboard, "^V").onTouch = function()
		paste(clipboard)
	end
	editOrRightClickMenu:addSeparator()
	editOrRightClickMenu:addItem(localization.comment, false, "^/").onTouch = function()
		toggleComment()
	end
	editOrRightClickMenu:addItem(localization.indent, false, "Tab").onTouch = function()
		indentOrUnindent(true)
	end
	editOrRightClickMenu:addItem(localization.unindent, false, "⇧Tab").onTouch = function()
		indentOrUnindent(false)
	end
	editOrRightClickMenu:addItem(localization.deleteLine, false, "^Del").onTouch = function()
		deleteLine(cursor.position.line)
	end
	editOrRightClickMenu:addSeparator()
	editOrRightClickMenu:addItem(localization.addBreakpoint, false, "F9").onTouch = function()
		addBreakpoint()
		mainContainer:draw()
		buffer.draw()
	end
	editOrRightClickMenu:addItem(localization.clearBreakpoints, not breakpointLines, "^F9").onTouch = function()
		clearBreakpoints()
	end
	editOrRightClickMenu:addSeparator()
	editOrRightClickMenu:addItem(localization.selectAndPasteColor, false, "^⇧C").onTouch = function()
		selectAndPasteColor()
	end
	editOrRightClickMenu:addItem(localization.selectWord).onTouch = function()
		selectWord()
	end
	editOrRightClickMenu:addItem(localization.selectAll, false, "^A").onTouch = function()
		selectAll()
	end
	editOrRightClickMenu:show()
end

local function tick()
	updateTitle()
	updateRAMProgressBar()
	mainContainer:draw()
	
	if cursor.blinkState and mainContainer.settingsContainer.hidden then
		local x, y = convertTextPositionToScreenCoordinates(cursor.position.symbol, cursor.position.line)
		if
			x >= mainContainer.codeView.codeAreaPosition + 1 and
			y >= mainContainer.codeView.y and
			x <= mainContainer.codeView.codeAreaPosition + mainContainer.codeView.codeAreaWidth - 2 and
			y <= mainContainer.codeView.y + mainContainer.codeView.height - 2
		then
			buffer.text(x, y, config.cursorColor, config.cursorSymbol)
		end
	end

	buffer.draw()
end

local function createMainContainer()
	mainContainer = GUI.fullScreenContainer()
	
	mainContainer.codeView = mainContainer:addChild(GUI.codeView(1, 1, 1, 1, {""}, 1, 1, 1, {}, {}, config.highlightLuaSyntax, 2))
	mainContainer.codeView.scrollBars.vertical.onTouch = function()
		mainContainer.codeView.fromLine = mainContainer.codeView.scrollBars.vertical.value
	end
	mainContainer.codeView.scrollBars.horizontal.onTouch = function()
		mainContainer.codeView.fromSymbol = mainContainer.codeView.scrollBars.horizontal.value
	end

	mainContainer.topMenu = mainContainer:addChild(GUI.menu(1, 1, 1, colors.topMenu.backgroundColor, colors.topMenu.textColor, colors.topMenu.backgroundPressedColor, colors.topMenu.textPressedColor))
	
	local item1 = mainContainer.topMenu:addItem("MineCode", 0x0)
	item1.onTouch = function()
		local menu = GUI.contextMenu(item1.x, item1.y + 1)
		menu:addItem(localization.about).onTouch = function()
			mainContainer.settingsContainer.hidden = false
			local y = math.floor(mainContainer.settingsContainer.height / 2 - #about / 2)
			mainContainer.settingsContainer:addChild(GUI.textBox(1, y, mainContainer.settingsContainer.width, #about, nil, 0xEEEEEE, about, 1)):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
		end
		menu:addItem(localization.quit, false, "^W").onTouch = function()
			mainContainer:stopEventHandling()
		end
		menu:show()
	end

	local item2 = mainContainer.topMenu:addItem(localization.file)
	item2.onTouch = function()
		local menu = GUI.contextMenu(item2.x, item2.y + 1)
		menu:addItem(localization.new, false, "^N").onTouch = function()
			newFile()
			mainContainer:draw()
			buffer.draw()
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
		menu:addItem(localization.save, not mainContainer.leftTreeView.selectedItem, "^S").onTouch = function()
			saveFileWindow()
		end
		menu:addItem(localization.saveAs, false, "^⇧S").onTouch = function()
			saveFileAsWindow()
		end
		menu:show()
	end

	local item3 = mainContainer.topMenu:addItem(localization.edit)
	item3.onTouch = function()
		createEditOrRightClickMenu(item3.x, item3.y + 1)
	end

	local item4 = mainContainer.topMenu:addItem(localization.properties)
	item4.onTouch = function()
		local menu = GUI.contextMenu(item4.x, item4.y + 1)
		menu:addItem(localization.colorScheme).onTouch = function()
			mainContainer.settingsContainer.hidden = false
			
			local colorSelectorsCount, colorSelectorCountX = 0, 4; for key in pairs(config.syntaxColorScheme) do colorSelectorsCount = colorSelectorsCount + 1 end
			local colorSelectorCountY = math.ceil(colorSelectorsCount / colorSelectorCountX)
			local colorSelectorWidth, colorSelectorHeight, colorSelectorSpaceX, colorSelectorSpaceY = math.floor(mainContainer.settingsContainer.width / colorSelectorCountX * 0.8), 3, 2, 1
			
			local startX, y = math.floor(mainContainer.settingsContainer.width / 2 - (colorSelectorCountX * (colorSelectorWidth + colorSelectorSpaceX) - colorSelectorSpaceX) / 2), math.floor(mainContainer.settingsContainer.height / 2 - (colorSelectorCountY * (colorSelectorHeight + colorSelectorSpaceY) - colorSelectorSpaceY + 3) / 2)
			mainContainer.settingsContainer:addChild(GUI.label(1, y, mainContainer.settingsContainer.width, 1, 0xFFFFFF, localization.colorScheme)):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top); y = y + 3
			local x, counter = startX, 1

			local colors = {}
			for key in pairs(config.syntaxColorScheme) do
				table.insert(colors, {key})
			end

			aplhabeticalSort(colors)

			for i = 1, #colors do
				local colorSelector = mainContainer.settingsContainer:addChild(GUI.colorSelector(x, y, colorSelectorWidth, colorSelectorHeight, config.syntaxColorScheme[colors[i][1]], colors[i][1]))
				colorSelector.onTouch = function()
					config.syntaxColorScheme[colors[i][1]] = colorSelector.color
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
			mainContainer.settingsContainer.hidden = false

			local elementWidth = math.floor(mainContainer.width * 0.3)
			local x, y = math.floor(mainContainer.width / 2 - elementWidth / 2), math.floor(mainContainer.height / 2) - 7
			mainContainer.settingsContainer:addChild(GUI.label(1, y, mainContainer.settingsContainer.width, 1, 0xFFFFFF, localization.cursorProperties)):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top); y = y + 3
			local inputField = mainContainer.settingsContainer:addChild(GUI.input(x, y, elementWidth, 3, 0xCCCCCC, 0x777777, 0x777777, 0xCCCCCC, 0x2D2D2D, config.cursorSymbol, localization.cursorSymbol)); y = y + 5
			inputField.validator = function(text)
				if unicode.len(text) == 1 then return true end
			end
			inputField.onInputFinished = function()
				config.cursorSymbol = inputField.text; saveConfig()
			end
			local colorSelector = mainContainer.settingsContainer:addChild(GUI.colorSelector(x, y, elementWidth, 3, config.cursorColor, localization.cursorColor)); y = y + 5
			colorSelector.onTouch = function()
				config.cursorColor = colorSelector.color; saveConfig()
			end
			local horizontalSlider = mainContainer.settingsContainer:addChild(GUI.slider(x, y, elementWidth, 0xFFDB80, 0x000000, 0xFFDB40, 0xDDDDDD, 1, 1000, config.cursorBlinkDelay * 1000, false, localization.cursorBlinkDelay .. ": ", " ms"))
			horizontalSlider.onValueChanged = function()
				config.cursorBlinkDelay = horizontalSlider.value / 1000; saveConfig()
			end
		end

		if mainContainer.topToolBar.hidden then
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

	local item5 = mainContainer.topMenu:addItem(localization.gotoCyka)
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
		menu:addSeparator()
		menu:addItem(localization.gotoLine, false, "^L").onTouch = function()
			gotoLineWindow()
		end
		menu:show()
	end

	mainContainer.topToolBar = mainContainer:addChild(GUI.container(1, 2, 1, 3))
	mainContainer.topToolBar.backgroundPanel = mainContainer.topToolBar:addChild(GUI.panel(1, 1, 1, 3, colors.topToolBar))
	mainContainer.titleTextBox = mainContainer.topToolBar:addChild(GUI.textBox(1, 1, 1, 3, 0x0, 0x0, {}, 1):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top))
	local titleTextBoxOldDraw = mainContainer.titleTextBox.draw
	mainContainer.titleTextBox.draw = function(titleTextBox)
		titleTextBoxOldDraw(titleTextBox)
		local sidesColor = mainContainer.errorContainer.hidden and colors.title.default.sides or colors.title.onError.sides
		buffer.square(titleTextBox.x, titleTextBox.y, 1, titleTextBox.height, sidesColor, titleTextBox.colors.text, " ")
		buffer.square(titleTextBox.x + titleTextBox.width - 1, titleTextBox.y, 1, titleTextBox.height, sidesColor, titleTextBox.colors.text, " ")
	end

	mainContainer.RAMUsageProgressBar = mainContainer.topToolBar:addChild(GUI.progressBar(1, 2, 1, 0x777777, 0xBBBBBB, 0xAAAAAA, 50, true, true, "RAM: ", "%"))

	--☯◌☺
	mainContainer.addBreakpointButton = mainContainer.topToolBar:addChild(GUI.adaptiveButton(1, 1, 3, 1, 0x878787, 0xEEEEEE, 0xCCCCCC, 0x444444, "x"))
	mainContainer.addBreakpointButton.onTouch = function()
		addBreakpoint()
		mainContainer:draw()
		buffer.draw()
	end

	mainContainer.toggleSyntaxHighlightingButton = mainContainer.topToolBar:addChild(GUI.adaptiveButton(1, 1, 3, 1, 0xCCCCCC, 0x444444, 0x696969, 0xEEEEEE, "◌"))
	mainContainer.toggleSyntaxHighlightingButton.switchMode, mainContainer.toggleSyntaxHighlightingButton.pressed = true, true
	mainContainer.toggleSyntaxHighlightingButton.onTouch = function()
		mainContainer.codeView.highlightLuaSyntax = not mainContainer.codeView.highlightLuaSyntax
		config.highlightLuaSyntax = mainContainer.codeView.highlightLuaSyntax
		saveConfig()
		mainContainer:draw()
		buffer.draw()
	end

	mainContainer.runButton = mainContainer.topToolBar:addChild(GUI.adaptiveButton(1, 1, 3, 1, 0x4B4B4B, 0xEEEEEE, 0xCCCCCC, 0x444444, "▷"))
	mainContainer.runButton.onTouch = function()
		run()
	end

	mainContainer.toggleLeftToolBarButton = mainContainer.topToolBar:addChild(GUI.adaptiveButton(1, 1, 3, 1, 0xCCCCCC, 0x444444, 0x4B4B4B, 0xEEEEEE, "⇦"))
	mainContainer.toggleLeftToolBarButton.switchMode, mainContainer.toggleLeftToolBarButton.pressed = true, true
	mainContainer.toggleLeftToolBarButton.onTouch = function()
		mainContainer.leftTreeView.hidden = not mainContainer.toggleLeftToolBarButton.pressed
		mainContainer.leftTreeViewResizer.hidden = mainContainer.leftTreeView.hidden
		calculateSizes()
		mainContainer:draw()
		buffer.draw()
	end

	mainContainer.toggleBottomToolBarButton = mainContainer.topToolBar:addChild(GUI.adaptiveButton(1, 1, 3, 1, 0xCCCCCC, 0x444444, 0x696969, 0xEEEEEE, "⇩"))
	mainContainer.toggleBottomToolBarButton.switchMode, mainContainer.toggleBottomToolBarButton.pressed = true, false
	mainContainer.toggleBottomToolBarButton.onTouch = function()
		mainContainer.bottomToolBar.hidden = not mainContainer.toggleBottomToolBarButton.pressed
		calculateSizes()
		mainContainer:draw()
		buffer.draw()
	end

	mainContainer.toggleTopToolBarButton = mainContainer.topToolBar:addChild(GUI.adaptiveButton(1, 1, 3, 1, 0xCCCCCC, 0x444444, 0x878787, 0xEEEEEE, "⇧"))
	mainContainer.toggleTopToolBarButton.switchMode, mainContainer.toggleTopToolBarButton.pressed = true, true
	mainContainer.toggleTopToolBarButton.onTouch = function()
		mainContainer.topToolBar.hidden = not mainContainer.toggleTopToolBarButton.pressed
		calculateSizes()
		mainContainer:draw()
		buffer.draw()
	end

	mainContainer.bottomToolBar = mainContainer:addChild(GUI.container(1, 1, 1, 3))
	mainContainer.bottomToolBar.caseSensitiveButton = mainContainer.bottomToolBar:addChild(GUI.adaptiveButton(1, 1, 2, 1, 0x3C3C3C, 0xEEEEEE, 0xBBBBBB, 0x2D2D2D, "Aa"))
	mainContainer.bottomToolBar.caseSensitiveButton.switchMode = true
	mainContainer.bottomToolBar.onTouch = function()
		find()
	end
	mainContainer.bottomToolBar.inputField = mainContainer.bottomToolBar:addChild(GUI.input(7, 1, 10, 3, 0xCCCCCC, 0x999999, 0x999999, 0xCCCCCC, 0x2D2D2D, "", localization.findSomeShit))
	mainContainer.bottomToolBar.inputField.onInputFinished = function()
		findFromFirstDisplayedLine()
	end
	mainContainer.bottomToolBar.findButton = mainContainer.bottomToolBar:addChild(GUI.adaptiveButton(1, 1, 3, 1, 0x3C3C3C, 0xEEEEEE, 0xBBBBBB, 0x2D2D2D, localization.find))
	mainContainer.bottomToolBar.findButton.onTouch = function()
		find()
	end
	mainContainer.bottomToolBar.hidden = true

	mainContainer.leftTreeView = mainContainer:addChild(GUI.filesystemTree(1, 1, config.leftTreeViewWidth, 1, 0xCCCCCC, 0x3C3C3C, 0x3C3C3C, 0x999999, 0x3C3C3C, 0xE1E1E1, 0xBBBBBB, 0xAAAAAA, 0xBBBBBB, 0x444444, GUI.filesystemModes.both, GUI.filesystemModes.file))
	mainContainer.leftTreeView.onItemSelected = function(path)
		loadFile(path)

		updateTitle()
		mainContainer:draw()
		buffer.draw()
	end
	mainContainer.leftTreeView:updateFileList()
	mainContainer.leftTreeViewResizer = mainContainer:addChild(GUI.resizer(1, 1, 3, 5, 0x888888, 0x0))
	mainContainer.leftTreeViewResizer.onResize = function(mainContainer, object, eventData, dragWidth, dragHeight)
		mainContainer.leftTreeView.width = mainContainer.leftTreeView.width + dragWidth
		calculateSizes()
	end

	mainContainer.leftTreeViewResizer.onResizeFinished = function()
		config.leftTreeViewWidth = mainContainer.leftTreeView.width
		saveConfig()
	end

	mainContainer.errorContainer = mainContainer:addChild(GUI.container(1, 1, 1, 1))
	mainContainer.errorContainer.backgroundPanel = mainContainer.errorContainer:addChild(GUI.panel(1, 1, 1, 1, 0xFFFFFF, 0.3))
	mainContainer.errorContainer.errorTextBox = mainContainer.errorContainer:addChild(GUI.textBox(3, 2, 1, 1, nil, 0x4B4B4B, {}, 1))
	mainContainer.errorContainer.breakpointExitButton = mainContainer.errorContainer:addChild(GUI.button(1, 1, 1, 1, 0x3C3C3C, 0xCCCCCC, 0x2D2D2D, 0x888888, localization.finishDebug))
	mainContainer.errorContainer.breakpointContinueButton = mainContainer.errorContainer:addChild(GUI.button(1, 1, 1, 1, 0x444444, 0xCCCCCC, 0x2D2D2D, 0x888888, localization.continueDebug))
	mainContainer.errorContainer.breakpointExitButton.onTouch = hideErrorContainer
	mainContainer.errorContainer.breakpointContinueButton.onTouch = continue
	hideErrorContainer()

	mainContainer.settingsContainer = mainContainer:addChild(GUI.container(1, 1, 1, 1))
	mainContainer.settingsContainer.backgroundPanel = mainContainer.settingsContainer:addChild(GUI.panel(1, 1, mainContainer.settingsContainer.width, mainContainer.settingsContainer.height, 0x0, 0.3))
	mainContainer.settingsContainer.backgroundPanel.eventHandler = function(mainContainer, object, eventData)
		if eventData[1] == "touch" then
			hideSettingsContainer()
		end
	end
	mainContainer.settingsContainer.hidden = true
	
	mainContainer.autocompleteWindow = mainContainer:addChild(GUI.object(1, 1, 40, 1))
	mainContainer.autocompleteWindow.maximumHeight = 8
	mainContainer.autocompleteWindow.matches = {}
	mainContainer.autocompleteWindow.fromMatch = 1
	mainContainer.autocompleteWindow.currentMatch = 1
	mainContainer.autocompleteWindow.hidden = true
	mainContainer.autocompleteWindow.draw = function(object)
		mainContainer.autocompleteWindow.x, mainContainer.autocompleteWindow.y = convertTextPositionToScreenCoordinates(mainContainer.autocompleteWindow.currentWordStarting, cursor.position.line)
		mainContainer.autocompleteWindow.x, mainContainer.autocompleteWindow.y = mainContainer.autocompleteWindow.x, mainContainer.autocompleteWindow.y + 1

		object.height = object.maximumHeight
		if object.height > #object.matches then object.height = #object.matches end
		
		buffer.square(object.x, object.y, object.width, object.height, 0xFFFFFF, 0x0, " ")

		local y = object.y
		for i = object.fromMatch, #object.matches do
			local firstColor, secondColor = 0x3C3C3C, 0x999999
			
			if i == object.currentMatch then
				buffer.square(object.x, y, object.width, 1, 0x2D2D2D, 0xEEEEEE, " ")
				firstColor, secondColor = 0xEEEEEE, 0x999999
			end

			buffer.text(object.x + 1, y, secondColor, unicode.sub(object.matches[i][1], 1, object.width - 2))
			buffer.text(object.x + 1, y, firstColor, unicode.sub(object.matches[i][2], 1, object.width - 2))

			y = y + 1
			if y > object.y + object.height - 1 then break end
		end

		if object.height < #object.matches then
			GUI.scrollBar(object.x + object.width - 1, object.y, 1, object.height, 0x444444, 0x00DBFF, 1, #object.matches, object.currentMatch, object.height, 1, true):draw()
		end
	end

	mainContainer.codeView.eventHandler = function(mainContainer, object, eventData)
		if eventData[1] == "touch" then
			if eventData[5] == 1 then
				createEditOrRightClickMenu(eventData[3], eventData[4])
			else
				setCursorPositionAndClearSelection(convertScreenCoordinatesToTextPosition(eventData[3], eventData[4]))
			end

			cursor.blinkState = true
			tick()
		elseif eventData[1] == "double_touch" then
			cursor.blinkState = true
			selectWord()
			
			mainContainer:draw()
			buffer.draw()
		elseif eventData[1] == "drag" then
			if eventData[5] ~= 1 then
				mainContainer.codeView.selections[1] = mainContainer.codeView.selections[1] or {from = {}, to = {}}
				mainContainer.codeView.selections[1].from.symbol, mainContainer.codeView.selections[1].from.line = cursor.position.symbol, cursor.position.line
				mainContainer.codeView.selections[1].to.symbol, mainContainer.codeView.selections[1].to.line = fixCursorPosition(convertScreenCoordinatesToTextPosition(eventData[3], eventData[4]))
				
				if mainContainer.codeView.selections[1].from.line > mainContainer.codeView.selections[1].to.line then
					mainContainer.codeView.selections[1].from.line, mainContainer.codeView.selections[1].to.line = mainContainer.codeView.selections[1].to.line, mainContainer.codeView.selections[1].from.line
					mainContainer.codeView.selections[1].from.symbol, mainContainer.codeView.selections[1].to.symbol = mainContainer.codeView.selections[1].to.symbol, mainContainer.codeView.selections[1].from.symbol
				elseif mainContainer.codeView.selections[1].from.line == mainContainer.codeView.selections[1].to.line then
					if mainContainer.codeView.selections[1].from.symbol > mainContainer.codeView.selections[1].to.symbol then
						mainContainer.codeView.selections[1].from.symbol, mainContainer.codeView.selections[1].to.symbol = mainContainer.codeView.selections[1].to.symbol, mainContainer.codeView.selections[1].from.symbol
					end
				end
			end

			cursor.blinkState = true
			tick()
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
				-- S
				elseif eventData[4] == 31 then
					-- Shift
					if mainContainer.leftTreeView.selectedItem and not keyboard.isKeyDown(42) then
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
					deleteLine(cursor.position.line)
				-- Delete
				elseif eventData[4] == 211 then
					deleteLine(cursor.position.line)
				-- R
				elseif eventData[4] == 19 then
					changeResolutionWindow()
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
				if mainContainer.autocompleteWindow.hidden then
					enter()
				else
					pasteSelectedAutocompletion()
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

			cursor.blinkState = true
			tick()
		elseif eventData[1] == "scroll" then
			scroll(eventData[5], config.scrollSpeed)
			tick()
		elseif eventData[1] == "clipboard" then
			paste(splitStringIntoLines(eventData[3]))
			tick()
		elseif not eventData[1] then
			cursor.blinkState = not cursor.blinkState
			tick()
		end
	end
end

---------------------------------------------------- RUSH B! ----------------------------------------------------

loadConfig()
createMainContainer()
changeResolution(config.screenResolution.width, config.screenResolution.height)
updateTitle()
updateRAMProgressBar()
mainContainer:draw()

if args[1] and fs.exists(args[1]) then
	loadFile(args[1])
else
	newFile()
end

mainContainer:draw()
buffer.draw()
mainContainer:startEventHandling(config.cursorBlinkDelay)


