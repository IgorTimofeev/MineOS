
-- _G.syntax = nil
-- _G.filemanager = nil
-- _G.doubleBuffering = nil
-- package.loaded.doubleBuffering = nil
-- package.loaded.syntax = nil
-- package.loaded.filemanager = nil

-- Адаптивная загрузка необходимых библиотек и компонентов
local libraries = {
	ecs = "ECSAPI",
	fs = "fs",
	syntax = "syntax",
	buffer = "buffer",
	unicode = "unicode",
	context = "context",
	event = "event",
	component = "component",
	filemanager = "filemanager",
}

local components = {
	gpu = "gpu",
}

for library in pairs(libraries) do if not _G[library] then _G[library] = require(libraries[library]) end end
for comp in pairs(components) do if not _G[comp] then _G[comp] = _G.component[components[comp]] end end
libraries, components = nil, nil

--------------------------------------------------- Константы ------------------------------------------------------------------

local pathToFile = "OS.lua"
local fileSize = 0
local indentationWidth = 4

local strings
local maximumStringWidth
local fromString = 1
local fromSymbol = 1
local scrollSpeed = 8
local showLuaSyntax = true
local showFilemanager = true

local xCursor, yCursor = 1, 1
local textFieldPosition

local selection = {
	from = { x = 18, y = 6 }, 
	to = { x = 4, y = 8 }
}

local highlightedStrings = {
	{ number = 31, color = 0xFF4444 },
	{ number = 32, color = 0xFF4444 },
	{ number = 34, color = 0x66FF66 },
}

local colors = {
	infoPanel = 0xCCCCCC,
	infoPanelText = 0x262626,
	topBar = 0xDDDDDD,
	topBarButton = 0xCCCCCC,
	topBarButtonText = 0x262626,
	topMenu = 0xFFFFFF,
	topMenuText = 0x262626,
}

local topButtonsSymbols = {
	launch = "‣",
	toggleSyntax = "*",
}

local sizes = {
	yTopBar = 2,
	topBarHeight = 3,
	filemanagerWidth = math.floor(buffer.screen.width * 0.16),
}

--------------------------------------------------- Функции ------------------------------------------------------------------

local function recalculateSizes()
	sizes.yCode = sizes.yTopBar + sizes.topBarHeight
	sizes.codeHeight = buffer.screen.height - 1 - sizes.topBarHeight
	if showFilemanager then
		sizes.codeWidth = buffer.screen.width - sizes.filemanagerWidth
		sizes.xCode = sizes.filemanagerWidth + 1
	else
		sizes.codeWidth = buffer.screen.width
		sizes.xCode = 1
	end
end

--Объекты для тача
local obj = {}
local function newObj(class, name, ...)
	obj[class] = obj[class] or {}
	obj[class][name] = {...}
end

local function readFile(path)
	if fs.exists(path) then
		maximumStringWidth = 0
		strings = {}
		fileSize = math.floor(fs.size(path) / 1024)
		local file = io.open(path, "r")
		for line in file:lines() do
			line = string.gsub(line, "	", string.rep(" ", indentationWidth))
			maximumStringWidth = math.max(maximumStringWidth, unicode.len(line))
			table.insert(strings, line)
		end
		file:close()
	else
		ecs.error("Файл \"" .. path .. "\" не существует")
	end
end

local function drawInfoPanel()
	local width = math.floor(buffer.screen.width * 0.3)
	local x, y = math.floor(buffer.screen.width / 2 - width / 2), 2

	buffer.square(x, y, width, 3, colors.infoPanel, 0x000000, " ")
	
	local textArray = {
		"Файл: " .. pathToFile .. ", " .. fileSize .. "KB",
		"Позиция курсора: " .. xCursor .. "x" .. yCursor,
	}

	for i = 1, #textArray do
		textArray[i] = ecs.stringLimit("end", textArray[i], width)
		x = math.floor(buffer.screen.width / 2 - unicode.len(textArray[i]) / 2)
		
		buffer.text(x, y, colors.infoPanelText, textArray[i])
		
		y = y + 1
	end
end

local function drawTopBar()
	obj["TopBarButtons"] = {}

	local x, y = 1, sizes.yTopBar
	local buttonWidth = 7
	buffer.square(x, y, buffer.screen.width, sizes.topBarHeight, colors.topBar, 0x000000, " ")
	
	local buttonNames = {
		topButtonsSymbols.launch,
		topButtonsSymbols.toggleSyntax,
	}

	for i = 1, #buttonNames do
		newObj("TopBarButtons", buttonNames[i], buffer.button(x, y, buttonWidth, 3, colors.topBarButton, colors.topBarButtonText, buttonNames[i]))
		x = x + buttonWidth + 1
	end
end

local function drawTopMenu()
	local x, y = 1, 1 

	buffer.square(x, y, buffer.screen.width, 1, colors.topMenu, 0x000000, " ")
	
	local buttonNames = {
		"Файл",
		"Правка",
		"Вид",
		"О программе"
	}

	for i = 1, #buttonNames do
		local length = unicode.len(buttonNames[i]) + 2
		buffer.button(x, y, length, 1, colors.topMenu, colors.topMenuText, buttonNames[i])
		x = x + length
	end
end

local function drawCode()
	textFieldPosition = syntax.viewCode(sizes.xCode, sizes.yCode, sizes.codeWidth, sizes.codeHeight, strings, maximumStringWidth,fromSymbol, fromString, showLuaSyntax, selection, highlightedStrings)
end

local function launch()
	local callback, reason = loadfile(pathToFile)
	if callback then
		ecs.prepareToExit()
		local success, reason = pcall(callback)
		if success then
			ecs.prepareToExit()
			print("Программа успешно выполнена!")
		else
			ecs.error("Ошибка при выполнении программы: " .. reason)
		end
	else
		ecs.error("Ошибка при запуске программы: " .. reason)
	end
end

-- local function convertCoordsToCursor(x, y)

-- end

local function drawFileManager()
	filemanager.draw(1, sizes.yCode, sizes.filemanagerWidth, buffer.screen.height - 4, fs.path(pathToFile), 1)
end

local function drawAll(force)
	drawTopBar()
	drawInfoPanel()
	drawTopMenu()
	if showFilemanager then drawFileManager() end
	drawCode()
	buffer.draw(force)
end

local function scroll(direction, count)
	if direction == "up" then
		if fromString > count then 
			fromString = fromString - count
			drawInfoPanel(); drawCode(); buffer.draw()
		end
	elseif direction == "down" then
		if fromString < (#strings - count) then 
			fromString = fromString + count
			drawInfoPanel(); drawCode(); buffer.draw()
		end
	elseif direction == "left" then
		if fromSymbol > count then 
			fromSymbol = fromSymbol - count
			drawInfoPanel(); drawCode(); buffer.draw()
		end
	elseif direction == "right" then
		if fromSymbol < (maximumStringWidth - count) then 
			fromSymbol = fromSymbol + count
			drawInfoPanel(); drawCode(); buffer.draw()
		end
	end
end

--------------------------------------------------- Начало работы скрипта ------------------------------------------------------------------

local args = { ... }
if args[1] == "open" then
	pathToFile = args[2]
end

buffer.square(1, 1, buffer.screen.width, buffer.screen.height, ecs.colors.red, 0xFFFFFF, " ")
buffer.draw(true)

recalculateSizes()
readFile(pathToFile)
drawAll()

while true do
	local e = { event.pull() }
	if e[1] == "touch" then
		for key in pairs(obj.TopBarButtons) do
			if ecs.clickedAtArea(e[3], e[4], obj.TopBarButtons[key][1], obj.TopBarButtons[key][2], obj.TopBarButtons[key][3], obj.TopBarButtons[key][4]) then
				buffer.button(obj.TopBarButtons[key][1], obj.TopBarButtons[key][2], 7, 3, ecs.colors.blue, ecs.colors.white, key)
				buffer.draw()
				os.sleep(0.2)
				buffer.button(obj.TopBarButtons[key][1], obj.TopBarButtons[key][2], 7, 3, colors.topBarButton, colors.topBarButtonText, key)
				buffer.draw()

				if key == topButtonsSymbols.launch then
					launch()
					drawAll()
				elseif key == topButtonsSymbols.toggleSyntax then
					showLuaSyntax = not showLuaSyntax
					drawAll()
				end

				break
			end
		end
	elseif e[1] == "key_down" then
		if e[4] == 200 then
			scroll("up", 1)
		elseif e[4] == 208 then
			scroll("down", 1)
		elseif e[4] == 203 then
			scroll("left", 1)
		elseif e[4] == 205 then
			scroll("right", 1)
		end
	elseif e[1] == "scroll" then
		if e[5] == 1 then
			scroll("up", scrollSpeed)
		else
			scroll("down", scrollSpeed)
		end
	end
end











