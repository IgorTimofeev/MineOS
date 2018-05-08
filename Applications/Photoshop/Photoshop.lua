
local args, options = require("shell").parse(...)
local GUI = require("GUI")
local web = require("web")
local MineOSCore = require("MineOSCore")
local fs = require("filesystem")
local image = require("image")
local unicode = require("unicode")
local color = require("color")
local buffer = require("doubleBuffering")
local MineOSPaths = require("MineOSPaths")
local MineOSInterface = require("MineOSInterface")

--------------------------------------------------------------------

local recentColorsLimit = 52
local recentFilesLimit = 10

local config = {
	recentColors = {},
	recentFiles = {},
	transparencyBackground = 0xFFFFFF,
	transparencyForeground = 0xD2D2D2,
}

local resourcesPath = MineOSCore.getCurrentScriptDirectory()
local toolsPath = resourcesPath .. "Tools/"
local configPath = MineOSPaths.applicationData .. "Picture Edit/Config2.cfg"
local savePath
local tool

--------------------------------------------------------------------

local function saveConfig()
	table.toFile(configPath, config)
end

local function loadConfig()
	if fs.exists(configPath) then
		config = table.fromFile(configPath)
	else
		local perLine = 13
		local value, step = 0, 360 / (recentColorsLimit - perLine)
		for i = 1, recentColorsLimit - perLine do
			table.insert(config.recentColors, color.HSBToInteger(value, 1, 1))
			value = value + step
		end

		value, step = 0, 255 / perLine
		for i = 1, perLine do
			table.insert(config.recentColors, color.RGBToInteger(math.floor(value), math.floor(value), math.floor(value)))
			value = value + step
		end

		saveConfig()
	end
end

local function addRecentFile(path)
	for i = 1, #config.recentFiles do
		if config.recentFiles[i] == path then
			return
		end
	end

	table.insert(config.recentFiles, 1, path)
	if #config.recentFiles > recentFilesLimit then
		table.remove(config.recentFiles, #config.recentFiles)
	end

	saveConfig()
end

loadConfig()

local mainContainer = GUI.fullScreenContainer()

mainContainer.menu = mainContainer:addChild(GUI.menu(1, 1, mainContainer.width, 0xE1E1E1, 0x5A5A5A, 0x3366CC, 0xFFFFFF, nil))

local function addTitle(container, text)
	local titleContainer = container:addChild(GUI.container(1, 1, container.width, 1))
	titleContainer:addChild(GUI.panel(1, 1, titleContainer.width, 1, 0x2D2D2D))
	titleContainer:addChild(GUI.text(2, 1, 0xD2D2D2, text))

	return titleContainer
end

local pizdaWidth = 28
mainContainer.sidebarPanel = mainContainer:addChild(GUI.panel(mainContainer.width - pizdaWidth + 1, 2, pizdaWidth, mainContainer.height - 1, 0x3C3C3C))
mainContainer.sidebarLayout = mainContainer:addChild(GUI.layout(mainContainer.sidebarPanel.localX, 2, mainContainer.sidebarPanel.width, mainContainer.sidebarPanel.height, 1, 1))
mainContainer.sidebarLayout:setCellAlignment(1, 1, GUI.alignment.horizontal.center, GUI.alignment.vertical.top)

addTitle(mainContainer.sidebarLayout, "Recent colors")

local recentColorsContainer = mainContainer.sidebarLayout:addChild(GUI.container(1, 1, mainContainer.sidebarLayout.width - 2, 4))
local x, y = 1, 1
for i = 1, #config.recentColors do
	local button = recentColorsContainer:addChild(GUI.button(x, y, 2, 1, 0x0, 0x0, 0x0, 0x0, " "))
	button.onTouch = function()
		mainContainer.primaryColorSelector.color = config.recentColors[i]
		mainContainer:drawOnScreen()
	end

	x = x + 2
	if x > recentColorsContainer.width - 1 then
		x, y = 1, y + 1
	end
end

local currentToolTitle = addTitle(mainContainer.sidebarLayout, "Tool properties")

mainContainer.currentToolLayout = mainContainer.sidebarLayout:addChild(GUI.layout(1, 1, mainContainer.sidebarLayout.width, 1, 1, 1))
mainContainer.currentToolLayout:setCellAlignment(1, 1, GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
mainContainer.currentToolLayout:setCellFitting(1, 1, true, false, 2, 0)

local aboutToolTitle = addTitle(mainContainer.sidebarLayout, "About tool")
local aboutToolTextBox = mainContainer.sidebarLayout:addChild(GUI.textBox(1, 1, mainContainer.sidebarLayout.width - 2, 1, nil, 0x787878, {}, 1, 0, 0))

mainContainer.toolsList = mainContainer:addChild(GUI.list(1, 2, 6, mainContainer.height - 1, 3, 0, 0x3C3C3C, 0xD2D2D2, 0x3C3C3C, 0xD2D2D2, 0x2D2D2D, 0xD2D2D2))
mainContainer.backgroundPanel = mainContainer:addChild(GUI.panel(mainContainer.toolsList.width + 1, 2, mainContainer.width - mainContainer.toolsList.width - mainContainer.sidebarPanel.width, mainContainer.height - 1, 0x1E1E1E))
mainContainer.image = mainContainer:addChild(GUI.object(1, 1, 1, 1))
mainContainer.image.data = {}

local function onToolTouch(index)
	tool = mainContainer.toolsList.itemsLayout.children[index].tool
	
	mainContainer.toolsList:select(index)
	mainContainer.currentToolOverlay:deleteChildren()
	mainContainer.currentToolLayout:deleteChildren()

	currentToolTitle.hidden = not tool.onSelection
	mainContainer.currentToolLayout.hidden = currentToolTitle.hidden
	
	if tool.onSelection then
		local result, reason = pcall(tool.onSelection, mainContainer)
		if result then
			mainContainer.currentToolLayout:update()
			local lastChild = mainContainer.currentToolLayout.children[#mainContainer.currentToolLayout.children]
			if lastChild then
				mainContainer.currentToolLayout.height = lastChild.localY + lastChild.height - 1
			end
		else
			GUI.error(reason)
		end
	end

	aboutToolTitle.hidden = not tool.about
	aboutToolTextBox.hidden = aboutToolTitle.hidden
	
	if tool.about then
		aboutToolTextBox.lines = string.wrap({tool.about}, aboutToolTextBox.width)
		aboutToolTextBox.height = #aboutToolTextBox.lines
	end

	mainContainer:drawOnScreen()
end

local modules = fs.sortedList(toolsPath, "name", false)
for i = 1, #modules do
	local result, reason = loadfile(toolsPath .. modules[i])
	if result then
		result, reason = pcall(result)
		if result then
			local item = mainContainer.toolsList:addItem(reason.shortcut)
			item.tool = reason
			item.onTouch = function()
				onToolTouch(i)
			end
		else
			error("Failed to perform pcall() on module " .. modules[i] .. ": " .. reason)
		end
	else
		error("Failed to perform loadfile() on module " .. modules[i] .. ": " .. reason)
	end
end

mainContainer.image.draw = function(object)
	GUI.windowShadow(object.x, object.y, object.width, object.height, nil, true)
	
	local y, text = object.y + object.height + 1, "Size: " .. object.width .. "x" .. object.height
	buffer.text(math.floor(object.x + object.width / 2 - unicode.len(text) / 2), y, 0x5A5A5A, text)

	if savePath then
		text = "Path: " .. savePath
		buffer.text(math.floor(object.x + object.width / 2 - unicode.len(text) / 2), y + 1, 0x5A5A5A, text)
	end
	
	local x, y, step, notStep, background, foreground, symbol = object.x, object.y, false, mainContainer.image.width % 2
	for i = 3, #mainContainer.image.data, 4 do
		
		if mainContainer.image.data[i + 2] == 0 then
			background = mainContainer.image.data[i]
			foreground = mainContainer.image.data[i + 1]
			symbol = mainContainer.image.data[i + 3]
		elseif mainContainer.image.data[i + 2] < 1 then
			background = color.blend(config.transparencyBackground, mainContainer.image.data[i], mainContainer.image.data[i + 2])
			foreground = mainContainer.image.data[i + 1]
			symbol = mainContainer.image.data[i + 3]
		else
			if mainContainer.image.data[i + 3] == " " then
				background = config.transparencyBackground
				foreground = config.transparencyForeground
				symbol = step and "▒" or "░"
			else
				background = config.transparencyBackground
				foreground = mainContainer.image.data[i + 1]
				symbol = mainContainer.image.data[i + 3]
				
			end
		end

		buffer.set(x, y, background, foreground, symbol)

		x, step = x + 1, not step
		if x > object.x + object.width - 1 then
			x, y = object.x, y + 1
			if notStep == 0 then
				step = not step
			end
		end
	end
end

local function updateRecentColorsButtons()
	for i = 1, #config.recentColors do
		recentColorsContainer.children[i].colors.default.background = config.recentColors[i]
		recentColorsContainer.children[i].colors.pressed.background = 0xFFFFFF - config.recentColors[i]
	end
end

local function swapColors()
	mainContainer.primaryColorSelector.color, mainContainer.secondaryColorSelector.color = mainContainer.secondaryColorSelector.color, mainContainer.primaryColorSelector.color
	mainContainer:drawOnScreen()
end

local function colorSelectorDraw(object)
	buffer.square(object.x + 1, object.y, object.width - 2, object.height, object.color, 0x0, " ")
	for y = object.y, object.y + object.height - 1 do
		buffer.text(object.x, y, object.color, "⢸")
		buffer.text(object.x + object.width - 1, y, object.color, "⡇")
	end
end

mainContainer.secondaryColorSelector = mainContainer:addChild(GUI.colorSelector(2, mainContainer.toolsList.height - 3, 5, 2, 0xFFFFFF, " "))
mainContainer.primaryColorSelector = mainContainer:addChild(GUI.colorSelector(1, mainContainer.toolsList.height - 4, 5, 2, 0x880000, " "))
mainContainer.secondaryColorSelector.draw, mainContainer.primaryColorSelector.draw = colorSelectorDraw, colorSelectorDraw

mainContainer:addChild(GUI.adaptiveButton(3, mainContainer.secondaryColorSelector.localY + mainContainer.secondaryColorSelector.height + 1, 0, 0, nil, 0xD2D2D2, nil, 0xA5A5A5, "<>")).onTouch = swapColors

mainContainer.image.eventHandler = function(mainContainer, object, e1, e2, e3, e4, ...)
	if e1 == "key_down" then
		-- D
		if e4 == 32 then
			mainContainer.primaryColorSelector.color, mainContainer.secondaryColorSelector.color = 0x0, 0xFFFFFF
			mainContainer:drawOnScreen()
		-- X
		elseif e4 == 45 then
			swapColors()
		else
			for i = 1, #mainContainer.toolsList.itemsLayout.children do
				if e4 == mainContainer.toolsList.itemsLayout.children[i].tool.keyCode then
					onToolTouch(i)
					return
				end
			end
		end
	end

	local result, reason = pcall(tool.eventHandler, mainContainer, object, e1, e2, e3, e4, ...)
	if not result then
		GUI.error("Tool eventHandler() failed: " .. reason)
	end
end

mainContainer.image.reposition = function()
	mainContainer.image.width, mainContainer.image.height = mainContainer.image.data[1], mainContainer.image.data[2]
	if mainContainer.image.width <= mainContainer.backgroundPanel.width then
		mainContainer.image.localX = math.floor(mainContainer.backgroundPanel.x + mainContainer.backgroundPanel.width / 2 - mainContainer.image.width / 2)
		mainContainer.image.localY = math.floor(mainContainer.backgroundPanel.y + mainContainer.backgroundPanel.height / 2 - mainContainer.image.height / 2)
	else
		mainContainer.image.localX, mainContainer.image.localY = 9, 3
	end
end

local function newNoGUI(width, height)
	savePath = nil
	mainContainer.image.data = {width, height}
	mainContainer.image.reposition()	
	
	for i = 1, width * height do
		table.insert(mainContainer.image.data, 0x0)
		table.insert(mainContainer.image.data, 0x0)
		table.insert(mainContainer.image.data, 1)
		table.insert(mainContainer.image.data, " ")
	end
end

local function new()
	local container = MineOSInterface.addUniversalContainer(mainContainer, "New picture")

	local widthInput = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0x696969, 0xE1E1E1, 0x2D2D2D, "51", "Width"))
	local heightInput = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0x696969, 0xE1E1E1, 0x2D2D2D, "19", "Height"))
	
	widthInput.validator = function(text)
		return tonumber(text)
	end
	heightInput.validator = widthInput.validator

	container.panel.eventHandler = function(mainContainer, object, e1)
		if e1 == "touch" then
			newNoGUI(tonumber(widthInput.text), tonumber(heightInput.text))
			container:delete()
			mainContainer:drawOnScreen()
		end
	end

	mainContainer:drawOnScreen()
end

local function loadImage(path)
	local result, reason = image.load(path)
	if result then
		savePath = path
		addRecentFile(path)
		mainContainer.image.data = result
		mainContainer.image.reposition()
	else
		GUI.error(reason)
	end
end

local function saveImage(path)
	local result, reason = image.save(path, mainContainer.image.data, 6)
	if result then
		savePath = path
		addRecentFile(path)
	else
		GUI.error(reason)
	end
end

mainContainer.menu:addItem("PE", 0x00B6FF)

local fileItem = mainContainer.menu:addItem("File")
fileItem.onTouch = function()
	local menu = GUI.contextMenu(fileItem.x, fileItem.y + 1)
	
	menu:addItem("New").onTouch = new

	menu:addSeparator()

	menu:addItem("Open").onTouch = function()
		local filesystemDialog = GUI.addFilesystemDialogToContainer(mainContainer, 50, math.floor(mainContainer.height * 0.8), true, "Open", "Cancel", "File name", "/")
		filesystemDialog:setMode(GUI.filesystemModes.open, GUI.filesystemModes.file)
		filesystemDialog:addExtensionFilter(".pic")
		filesystemDialog:expandPath(MineOSPaths.desktop)
		filesystemDialog:show()

		filesystemDialog.onSubmit = function(path)
			loadImage(path)
			mainContainer:drawOnScreen()
		end
	end

	local subMenu = menu:addSubMenu("Open recent", #config.recentFiles == 0)
	for i = 1, #config.recentFiles do
		subMenu:addItem(string.limit(config.recentFiles[i], 32, "left")).onTouch = function()
			loadImage(config.recentFiles[i])
			mainContainer:drawOnScreen()
		end
	end

	menu:addItem("Open from URL").onTouch = function()
		local container = MineOSInterface.addUniversalContainer(mainContainer, "Open from URL")

		local input = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0x969696, 0xE1E1E1, 0x2D2D2D, "", "http://example.com/test.pic"))
		input.onInputFinished = function()
			if #input.text > 0 then
				input:delete()
				container.layout:addChild(GUI.label(1, 1, container.width, 1, 0x969696, "Downloading file..."):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top))
				mainContainer:drawOnScreen()

				local temporaryPath = MineOSCore.getTemporaryPath() .. ".pic"
				local result, reason = web.download(input.text, temporaryPath)

				container:delete()

				if result then
					loadImage(temporaryPath)
					fs.remove(temporaryPath)
					savePath = nil
				else
					GUI.error(reason)
				end

				mainContainer:drawOnScreen()
			end
		end

		mainContainer:drawOnScreen()
	end

	menu:addSeparator()

	menu:addItem("Save", not savePath).onTouch = function()
		saveImage(savePath)
	end

	menu:addItem("Save as").onTouch = function()
		local filesystemDialog = GUI.addFilesystemDialogToContainer(mainContainer, 50, math.floor(mainContainer.height * 0.8), true, "Save", "Cancel", "File name", "/")
		filesystemDialog:setMode(GUI.filesystemModes.save, GUI.filesystemModes.file)
		filesystemDialog:addExtensionFilter(".pic")
		filesystemDialog:expandPath(MineOSPaths.desktop)
		filesystemDialog.filesystemTree.selectedItem = MineOSPaths.desktop
		filesystemDialog:show()

		filesystemDialog.onSubmit = function(path)
			saveImage(path)
		end
	end

	menu:addSeparator()

	menu:addItem("Exit").onTouch = function()
		mainContainer:stopEventHandling()
	end

	menu:show()
end

mainContainer.menu:addItem("View").onTouch = function()
	local container = MineOSInterface.addUniversalContainer(mainContainer, "View")

	local colorSelector1 = container.layout:addChild(GUI.colorSelector(1, 1, 36, 3, config.transparencyBackground, "Transparency background"))
	local colorSelector2 = container.layout:addChild(GUI.colorSelector(1, 1, 36, 3, config.transparencyForeground, "Transparency foreground"))

	container.panel.eventHandler = function(mainContainer, object, e1)
		if e1 == "touch" then
			config.transparencyBackground, config.transparencyForeground = colorSelector1.color, colorSelector2.color
			
			container:delete()
			mainContainer:drawOnScreen()
			saveConfig()
		end
	end

	mainContainer:drawOnScreen()
end

mainContainer.menu:addItem("Hotkeys").onTouch = function()
	local container = MineOSInterface.addUniversalContainer(mainContainer, "Hotkeys")
	local lines = {
		"There are some hotkeys that works exactly like in real Photoshop:",
		" ",
		"M - selection tool",
		"V - move tool",
		"C - resizer tool",
		"Alt - picker tool",
		"B - brush tool",
		"E - eraser tool",
		"T - text tool",
		"G - fill tool",
		"F - braille tool",
		" ",
		"X - switch colors",
		"D - make colors B/W",
	}

	container.layout:addChild(GUI.textBox(1, 1, 36, 1, nil, 0x969696, lines, 1, 0, 0, true, true)).eventHandler = nil
	mainContainer:drawOnScreen()
end

mainContainer.currentToolOverlay = mainContainer:addChild(GUI.container(1, 1, mainContainer.width, mainContainer.height))

----------------------------------------------------------------

mainContainer.image:moveToBack()
mainContainer.backgroundPanel:moveToBack()

updateRecentColorsButtons()
onToolTouch(5)

if options.o or options.open and args[1] and fs.exists(args[1]) then
	loadImage(args[1])
else
	newNoGUI(51, 19)
end

mainContainer:drawOnScreen(true)
mainContainer:startEventHandling()