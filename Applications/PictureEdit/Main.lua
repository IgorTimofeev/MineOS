
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
local saveItem
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

local application = GUI.application()

application.menu = application:addChild(GUI.menu(1, 1, application.width, 0xE1E1E1, 0x5A5A5A, 0x3366CC, 0xFFFFFF, nil))

local function addTitle(container, text)
	local titleContainer = container:addChild(GUI.container(1, 1, container.width, 1))
	titleContainer:addChild(GUI.panel(1, 1, titleContainer.width, 1, 0x2D2D2D))
	titleContainer:addChild(GUI.text(2, 1, 0xD2D2D2, text))

	return titleContainer
end

local pizdaWidth = 28
application.sidebarPanel = application:addChild(GUI.panel(application.width - pizdaWidth + 1, 2, pizdaWidth, application.height - 1, 0x3C3C3C))
application.sidebarLayout = application:addChild(GUI.layout(application.sidebarPanel.localX, 2, application.sidebarPanel.width, application.sidebarPanel.height, 1, 1))
application.sidebarLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)

addTitle(application.sidebarLayout, "Recent colors")

local recentColorsContainer = application.sidebarLayout:addChild(GUI.container(1, 1, application.sidebarLayout.width - 2, 4))
local x, y = 1, 1
for i = 1, #config.recentColors do
	local button = recentColorsContainer:addChild(GUI.button(x, y, 2, 1, 0x0, 0x0, 0x0, 0x0, " "))
	button.onTouch = function()
		application.primaryColorSelector.color = config.recentColors[i]
		application:draw()
	end

	x = x + 2
	if x > recentColorsContainer.width - 1 then
		x, y = 1, y + 1
	end
end

local currentToolTitle = addTitle(application.sidebarLayout, "Tool properties")

application.currentToolLayout = application.sidebarLayout:addChild(GUI.layout(1, 1, application.sidebarLayout.width, 1, 1, 1))
application.currentToolLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
application.currentToolLayout:setFitting(1, 1, true, false, 2, 0)

local aboutToolTitle = addTitle(application.sidebarLayout, "About tool")
local aboutToolTextBox = application.sidebarLayout:addChild(GUI.textBox(1, 1, application.sidebarLayout.width - 2, 1, nil, 0x787878, {}, 1, 0, 0))

application.toolsList = application:addChild(GUI.list(1, 2, 6, application.height - 1, 3, 0, 0x3C3C3C, 0xD2D2D2, 0x3C3C3C, 0xD2D2D2, 0x2D2D2D, 0xD2D2D2))
application.backgroundPanel = application:addChild(GUI.panel(application.toolsList.width + 1, 2, application.width - application.toolsList.width - application.sidebarPanel.width, application.height - 1, 0x1E1E1E))
application.image = application:addChild(GUI.object(1, 1, 1, 1))
application.image.data = {}

local function onToolTouch(index)
	tool = application.toolsList:getItem(index).tool
	
	application.toolsList.selectedItem = index
	application.currentToolOverlay:removeChildren()
	application.currentToolLayout:removeChildren()

	currentToolTitle.hidden = not tool.onSelection
	application.currentToolLayout.hidden = currentToolTitle.hidden
	
	if tool.onSelection then
		local result, reason = pcall(tool.onSelection, application)
		if result then
			application.currentToolLayout:update()
			local lastChild = application.currentToolLayout.children[#application.currentToolLayout.children]
			if lastChild then
				application.currentToolLayout.height = lastChild.localY + lastChild.height - 1
			end
		else
			GUI.alert(reason)
		end
	end

	aboutToolTitle.hidden = not tool.about
	aboutToolTextBox.hidden = aboutToolTitle.hidden
	
	if tool.about then
		aboutToolTextBox.lines = string.wrap({tool.about}, aboutToolTextBox.width)
		aboutToolTextBox.height = #aboutToolTextBox.lines
	end

	application:draw()
end

local modules = fs.sortedList(toolsPath, "name", false)
for i = 1, #modules do
	local result, reason = loadfile(toolsPath .. modules[i])
	if result then
		result, reason = pcall(result)
		if result then
			local item = application.toolsList:addItem(reason.shortcut)
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

application.image.draw = function(object)
	GUI.drawShadow(object.x, object.y, object.width, object.height, nil, true)
	
	local y, text = object.y + object.height + 1, "Size: " .. object.width .. "x" .. object.height
	buffer.drawText(math.floor(object.x + object.width / 2 - unicode.len(text) / 2), y, 0x5A5A5A, text)

	if savePath then
		text = "Path: " .. savePath
		buffer.drawText(math.floor(object.x + object.width / 2 - unicode.len(text) / 2), y + 1, 0x5A5A5A, text)
	end
	
	local x, y, step, notStep, background, foreground, symbol = object.x, object.y, false, application.image.width % 2
	for i = 1, application.image.width * application.image.height do
		if application.image.data[5][i] == 0 then
			background = application.image.data[3][i]
			foreground = application.image.data[4][i]
			symbol = application.image.data[6][i]
		elseif application.image.data[5][i] < 1 then
			background = color.blend(config.transparencyBackground, application.image.data[3][i], application.image.data[5][i])
			foreground = application.image.data[4][i]
			symbol = application.image.data[6][i]
		else
			if application.image.data[6][i] == " " then
				background = config.transparencyBackground
				foreground = config.transparencyForeground
				symbol = step and "▒" or "░"
			else
				background = config.transparencyBackground
				foreground = application.image.data[4][i]
				symbol = application.image.data[6][i]
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
	application.primaryColorSelector.color, application.secondaryColorSelector.color = application.secondaryColorSelector.color, application.primaryColorSelector.color
	application:draw()
end

local function colorSelectorDraw(object)
	buffer.drawRectangle(object.x + 1, object.y, object.width - 2, object.height, object.color, 0x0, " ")
	for y = object.y, object.y + object.height - 1 do
		buffer.drawText(object.x, y, object.color, "⢸")
		buffer.drawText(object.x + object.width - 1, y, object.color, "⡇")
	end
end

application.secondaryColorSelector = application:addChild(GUI.colorSelector(2, application.toolsList.height - 3, 5, 2, 0xFFFFFF, " "))
application.primaryColorSelector = application:addChild(GUI.colorSelector(1, application.toolsList.height - 4, 5, 2, 0x880000, " "))
application.secondaryColorSelector.draw, application.primaryColorSelector.draw = colorSelectorDraw, colorSelectorDraw

application:addChild(GUI.adaptiveButton(3, application.secondaryColorSelector.localY + application.secondaryColorSelector.height + 1, 0, 0, nil, 0xD2D2D2, nil, 0xA5A5A5, "<>")).onTouch = swapColors

application.image.eventHandler = function(application, object, e1, e2, e3, e4, ...)
	if e1 == "key_down" then
		-- D
		if e4 == 32 then
			application.primaryColorSelector.color, application.secondaryColorSelector.color = 0x0, 0xFFFFFF
			application:draw()
		-- X
		elseif e4 == 45 then
			swapColors()
		else
			for i = 1, application.toolsList:count() do
				if e4 == application.toolsList:getItem(i).tool.keyCode then
					onToolTouch(i)
					return
				end
			end
		end
	end

	local result, reason = pcall(tool.eventHandler, application, object, e1, e2, e3, e4, ...)
	if not result then
		GUI.alert("Tool eventHandler() failed: " .. reason)
	end
end

application.image.reposition = function()
	application.image.width, application.image.height = application.image.data[1], application.image.data[2]
	if application.image.width <= application.backgroundPanel.width then
		application.image.localX = math.floor(application.backgroundPanel.x + application.backgroundPanel.width / 2 - application.image.width / 2)
		application.image.localY = math.floor(application.backgroundPanel.y + application.backgroundPanel.height / 2 - application.image.height / 2)
	else
		application.image.localX, application.image.localY = 9, 3
	end
end

local function newNoGUI(width, height)
	savePath, saveItem.disabled = nil, true
	application.image.data = {width, height, {}, {}, {}, {}}
	application.image.reposition()	
	
	for i = 1, width * height do
		table.insert(application.image.data[3], 0x0)
		table.insert(application.image.data[4], 0x0)
		table.insert(application.image.data[5], 1)
		table.insert(application.image.data[6], " ")
	end
end

local function new()
	local container = MineOSInterface.addBackgroundContainer(application, "New picture")

	local widthInput = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0x696969, 0xE1E1E1, 0x2D2D2D, "51", "Width"))
	local heightInput = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0x696969, 0xE1E1E1, 0x2D2D2D, "19", "Height"))
	
	widthInput.validator = function(text)
		return tonumber(text)
	end
	heightInput.validator = widthInput.validator

	container.panel.eventHandler = function(application, object, e1)
		if e1 == "touch" then
			newNoGUI(tonumber(widthInput.text), tonumber(heightInput.text))
			container:remove()
			application:draw()
		end
	end

	application:draw()
end

local function loadImage(path)
	local result, reason = image.load(path)
	if result then
		savePath, saveItem.disabled = path, false
		addRecentFile(path)
		application.image.data = result
		application.image.reposition()
	else
		GUI.alert(reason)
	end
end

local function saveImage(path)
	if fs.extension(path) == ".pic" then
		local result, reason = image.save(path, application.image.data, 6)
		if result then
			savePath, saveItem.disabled = path, false
			
			addRecentFile(path)
		else
			GUI.alert(reason)
		end
	else
		savePath, saveItem.disabled = path, false

		local file = io.open(path, "wb")
		file:write(image.toString(application.image.data))
		file:close()
	end
end

application.menu:addItem("PE", 0x00B6FF)

local fileItem = application.menu:addContextMenu("File")
fileItem:addItem("New").onTouch = new

fileItem:addSeparator()

fileItem:addItem("Open").onTouch = function()
	local filesystemDialog = GUI.addFilesystemDialog(application, true, 50, math.floor(application.height * 0.8), "Open", "Cancel", "File name", "/")
	filesystemDialog:setMode(GUI.IO_MODE_OPEN, GUI.IO_MODE_FILE)
	filesystemDialog:addExtensionFilter(".pic")
	filesystemDialog:expandPath(MineOSPaths.desktop)
	filesystemDialog:show()

	filesystemDialog.onSubmit = function(path)
		loadImage(path)
		application:draw()
	end
end

local fileItemSubMenu = fileItem:addSubMenu("Open recent", #config.recentFiles == 0)
for i = 1, #config.recentFiles do
	fileItemSubMenu:addItem(string.limit(config.recentFiles[i], 32, "left")).onTouch = function()
		loadImage(config.recentFiles[i])
		application:draw()
	end
end

fileItem:addItem("Open from URL").onTouch = function()
	local container = MineOSInterface.addBackgroundContainer(application, "Open from URL")

	local input = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0x969696, 0xE1E1E1, 0x2D2D2D, "", "http://example.com/test.pic"))
	input.onInputFinished = function()
		if #input.text > 0 then
			input:remove()
			container.layout:addChild(GUI.label(1, 1, container.width, 1, 0x969696, "Downloading file..."):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP))
			application:draw()

			local temporaryPath = MineOSCore.getTemporaryPath() .. ".pic"
			local result, reason = web.download(input.text, temporaryPath)

			container:remove()

			if result then
				loadImage(temporaryPath)
				fs.remove(temporaryPath)
				savePath, saveItem.disabled = nil, true
			else
				GUI.alert(reason)
			end

			application:draw()
		end
	end

	application:draw()
end

fileItem:addSeparator()

saveItem = fileItem:addItem("Save")
saveItem.onTouch = function()
	saveImage(savePath)
end

fileItem:addItem("Save as").onTouch = function()
	local filesystemDialog = GUI.addFilesystemDialog(application, true, 50, math.floor(application.height * 0.8), "Save", "Cancel", "File name", "/")
	filesystemDialog:setMode(GUI.IO_MODE_SAVE, GUI.IO_MODE_FILE)
	filesystemDialog:addExtensionFilter(".pic")
	filesystemDialog:addExtensionFilter(".ocifstring")
	filesystemDialog:expandPath(MineOSPaths.desktop)
	filesystemDialog.filesystemTree.selectedItem = MineOSPaths.desktop
	filesystemDialog:show()

	filesystemDialog.onSubmit = function(path)
		saveImage(path)
	end
end

fileItem:addSeparator()

fileItem:addItem("Exit").onTouch = function()
	application:stop()
end

application.menu:addItem("View").onTouch = function()
	local container = MineOSInterface.addBackgroundContainer(application, "View")

	local colorSelector1 = container.layout:addChild(GUI.colorSelector(1, 1, 36, 3, config.transparencyBackground, "Transparency background"))
	local colorSelector2 = container.layout:addChild(GUI.colorSelector(1, 1, 36, 3, config.transparencyForeground, "Transparency foreground"))

	container.panel.eventHandler = function(application, object, e1)
		if e1 == "touch" then
			config.transparencyBackground, config.transparencyForeground = colorSelector1.color, colorSelector2.color
			
			container:remove()
			application:draw()
			saveConfig()
		end
	end

	application:draw()
end

application.menu:addItem("Hotkeys").onTouch = function()
	local container = MineOSInterface.addBackgroundContainer(application, "Hotkeys")
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
	application:draw()
end

application.currentToolOverlay = application:addChild(GUI.container(1, 1, application.width, application.height))

----------------------------------------------------------------

application.image:moveToBack()
application.backgroundPanel:moveToBack()

updateRecentColorsButtons()

if options.o or options.open and args[1] and fs.exists(args[1]) then
	loadImage(args[1])
else
	newNoGUI(51, 19)
end

onToolTouch(5)
application:start()