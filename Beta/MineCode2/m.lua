
package.loaded.syntax = nil
package.loaded.filemanager = nil

local fs = require("filesystem")
local syntax = require("syntax")
local ecs = require("ECSAPI")
local term = require("term")
local buffer = require("doubleBuffering")
local unicode = require("unicode")
local context = require("context")
local event = require("event")
local component = require("component")
local filemanager = require("filemanager")
local gpu = component.gpu

local pathToFile = "OS.lua"
local fileSize = 0
local indentationWidth = 4

local strings
local fromString = 1
local fromSymbol = 1
local scrollSpeed = 5
local showLuaSyntax = true

local xCursor, yCursor = 1, 1
local textFieldPosition

local selection = {
	from = {x = 18, y = 6}, 
	to = {x = 4, y = 8}
}

local highlightedStrings = {
	{number = 31, color = 0xFF4444},
	{number = 32, color = 0xFF4444},
	{number = 34, color = 0x66FF66},
}

local constants = {
	colors = {
		infoPanel = 0xCCCCCC,
		infoPanelText = 0x262626,
		topBar = 0xDDDDDD,
		topBarButton = 0xCCCCCC,
		topBarButtonText = 0x262626,
		topMenu = 0xFFFFFF,
		topMenuText = 0x262626,
	},
	buttons = {
		launch = "‣",
		toggleSyntax = "*"
	},
	sizes = {
		xCode = 31,
		yCode = 5,
		widthOfManager = 30,
	}
}

---------------------------------------------------------------------------

--Объекты для тача
local obj = {}
local function newObj(class, name, ...)
	obj[class] = obj[class] or {}
	obj[class][name] = {...}
end

local function readFile(path)
	local massivStrok = {}
	if fs.exists(path) then
		fileSize = math.floor(fs.size(path) / 1024)
		local file = io.open(path, "r")
		for line in file:lines() do
			line = string.gsub(line, "	", string.rep(" ", indentationWidth))
			table.insert(massivStrok, line)
		end
		file:close()
	else
		ecs.error("Файл не существует!")
	end

	return massivStrok
end

local function drawInfoPanel()
	local width = math.floor(buffer.screen.width * 0.3)
	local x, y = math.floor(buffer.screen.width / 2 - width / 2), 2

	buffer.square(x, y, width, 3, constants.colors.infoPanel, 0x000000, " ")
	
	local textArray = {
		"Файл: " .. pathToFile,
		"Размер: " .. fileSize .. " KB",
		"Позиция курсора: " .. xCursor .. "x" .. yCursor,
	}

	for i = 1, #textArray do
		textArray[i] = ecs.stringLimit("end", textArray[i], width)
		x = math.floor(buffer.screen.width / 2 - unicode.len(textArray[i]) / 2)
		
		buffer.text(x, y, constants.colors.infoPanelText, textArray[i])
		
		y = y + 1
	end
end

local function drawTopBar()
	obj["TopBarButtons"] = {}

	local x, y = 1, 2
	local buttonWidth = 7
	buffer.square(x, y, buffer.screen.width, 3, constants.colors.topBar, 0x000000, " ")
	
	local buttonNames = {
		constants.buttons.launch,
		constants.buttons.toggleSyntax,
	}

	for i = 1, #buttonNames do
		newObj("TopBarButtons", buttonNames[i], buffer.button(x, y, buttonWidth, 3, constants.colors.topBarButton, constants.colors.topBarButtonText, buttonNames[i]))
		x = x + buttonWidth + 1
	end
end

local function drawTopMenu()
	local x, y = 1, 1 

	buffer.square(x, y, buffer.screen.width, 1, constants.colors.topMenu, 0x000000, " ")
	
	local buttonNames = {
		"Файл",
		"Правка",
		"Вид",
		"О программе"
	}

	for i = 1, #buttonNames do
		local length = unicode.len(buttonNames[i]) + 2
		buffer.button(x, y, length, 1, constants.colors.topMenu, constants.colors.topMenuText, buttonNames[i])
		x = x + length
	end
end

local function drawCode()
	textFieldPosition = syntax.viewCode(constants.sizes.xCode, constants.sizes.yCode, buffer.screen.width - constants.sizes.xCode + 1, buffer.screen.height - 4, strings, fromSymbol, fromString, showLuaSyntax, selection, highlightedStrings)
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
	filemanager.draw(1, constants.sizes.yCode, constants.sizes.widthOfManager, buffer.screen.height - 4, fs.path(pathToFile), 1)
end

local function drawAll()
	drawTopBar()
	drawInfoPanel()
	drawTopMenu()
	drawFileManager()
	drawCode()
end

---------------------------------------------------------------------------

buffer.square(1, 1, buffer.screen.width, buffer.screen.height, ecs.colors.red, 0xFFFFFF, " ")
buffer.draw(true)

strings = readFile(pathToFile)

drawAll()

---------------------------------------------------------------------------

while true do
	local e = { event.pull() }
	if e[1] == "touch" then
		for key in pairs(obj.TopBarButtons) do
			if ecs.clickedAtArea(e[3], e[4], obj.TopBarButtons[key][1], obj.TopBarButtons[key][2], obj.TopBarButtons[key][3], obj.TopBarButtons[key][4]) then
				buffer.button(obj.TopBarButtons[key][1], obj.TopBarButtons[key][2], 7, 3, ecs.colors.blue, ecs.colors.white, key)
				buffer.draw()
				os.sleep(0.2)
				buffer.button(obj.TopBarButtons[key][1], obj.TopBarButtons[key][2], 7, 3, constants.colors.topBarButton, constants.colors.topBarButtonText, key)
				buffer.draw()

				if key == constants.buttons.launch then
					launch()
					drawAll()
				elseif key == constants.buttons.toggleSyntax then
					showLuaSyntax = not showLuaSyntax
					drawAll()
				end

				break
			end
		end
	elseif e[1] == "scroll" then
		if e[5] == 1 then
			if fromString > scrollSpeed then 
				fromString = fromString - scrollSpeed
				drawInfoPanel()
				drawCode()
			end
		else
			if fromString < (#strings - scrollSpeed) then 
				fromString = fromString + scrollSpeed
				drawInfoPanel()
				drawCode()
			end
		end
	end
end











