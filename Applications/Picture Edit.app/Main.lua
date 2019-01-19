
local GUI = require("GUI")
local internet = require("Internet")
local system = require("System")
local filesystem = require("Filesystem")
local image = require("Image")
local color = require("Color")
local screen = require("Screen")
local paths = require("Paths")
local text = require("Text")

local args, options = system.parseArguments(...)

--------------------------------------------------------------------

local recentColorsLimit = 52
local recentFilesLimit = 10

local config = {
	recentColors = {},
	recentFiles = {},
	transparencyBackground = 0xFFFFFF,
	transparencyForeground = 0xD2D2D2,
}

local currentScriptDirectory = filesystem.path(system.getCurrentScript())
local toolsPath = currentScriptDirectory .. "Tools/"
local configPath = paths.user.applicationData .. "Picture Edit/Config2.cfg"
local savePath
local saveItem
local tool

--------------------------------------------------------------------

local function saveConfig()
	filesystem.writeTable(configPath, config)
end

local function loadConfig()
	if filesystem.exists(configPath) then
		config = filesystem.readTable(configPath)
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

local workspace = GUI.workspace()

workspace.menu = workspace:addChild(GUI.menu(1, 1, workspace.width, 0xE1E1E1, 0x5A5A5A, 0x3366CC, 0xFFFFFF, nil))

local function addTitle(container, text)
	local titleContainer = container:addChild(GUI.container(1, 1, container.width, 1))
	titleContainer:addChild(GUI.panel(1, 1, titleContainer.width, 1, 0x2D2D2D))
	titleContainer:addChild(GUI.text(2, 1, 0xD2D2D2, text))

	return titleContainer
end

local pizdaWidth = 28
workspace.sidebarPanel = workspace:addChild(GUI.panel(workspace.width - pizdaWidth + 1, 2, pizdaWidth, workspace.height - 1, 0x3C3C3C))
workspace.sidebarLayout = workspace:addChild(GUI.layout(workspace.sidebarPanel.localX, 2, workspace.sidebarPanel.width, workspace.sidebarPanel.height, 1, 1))
workspace.sidebarLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)

addTitle(workspace.sidebarLayout, "Recent colors")

local recentColorsContainer = workspace.sidebarLayout:addChild(GUI.container(1, 1, workspace.sidebarLayout.width - 2, 4))
local x, y = 1, 1
for i = 1, #config.recentColors do
	local button = recentColorsContainer:addChild(GUI.button(x, y, 2, 1, 0x0, 0x0, 0x0, 0x0, " "))
	button.onTouch = function()
		workspace.primaryColorSelector.color = config.recentColors[i]
		workspace:draw()
	end

	x = x + 2
	if x > recentColorsContainer.width - 1 then
		x, y = 1, y + 1
	end
end

local currentToolTitle = addTitle(workspace.sidebarLayout, "Tool properties")

workspace.currentToolLayout = workspace.sidebarLayout:addChild(GUI.layout(1, 1, workspace.sidebarLayout.width, 1, 1, 1))
workspace.currentToolLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
workspace.currentToolLayout:setFitting(1, 1, true, false, 2, 0)

local aboutToolTitle = addTitle(workspace.sidebarLayout, "About tool")
local aboutToolTextBox = workspace.sidebarLayout:addChild(GUI.textBox(1, 1, workspace.sidebarLayout.width - 2, 1, nil, 0x787878, {}, 1, 0, 0))

workspace.toolsList = workspace:addChild(GUI.list(1, 2, 6, workspace.height - 1, 3, 0, 0x3C3C3C, 0xD2D2D2, 0x3C3C3C, 0xD2D2D2, 0x2D2D2D, 0xD2D2D2))
workspace.backgroundPanel = workspace:addChild(GUI.panel(workspace.toolsList.width + 1, 2, workspace.width - workspace.toolsList.width - workspace.sidebarPanel.width, workspace.height - 1, 0x1E1E1E))
workspace.image = workspace:addChild(GUI.object(1, 1, 1, 1))
workspace.image.data = {}

local function onToolTouch(index)
	tool = workspace.toolsList:getItem(index).tool
	
	workspace.toolsList.selectedItem = index
	workspace.currentToolOverlay:removeChildren()
	workspace.currentToolLayout:removeChildren()

	currentToolTitle.hidden = not tool.onSelection
	workspace.currentToolLayout.hidden = currentToolTitle.hidden
	
	if tool.onSelection then
		local result, reason = pcall(tool.onSelection, workspace)
		if result then
			workspace.currentToolLayout:update()
			local lastChild = workspace.currentToolLayout.children[#workspace.currentToolLayout.children]
			if lastChild then
				workspace.currentToolLayout.height = lastChild.localY + lastChild.height - 1
			end
		else
			GUI.alert(reason)
		end
	end

	aboutToolTitle.hidden = not tool.about
	aboutToolTextBox.hidden = aboutToolTitle.hidden
	
	if tool.about then
		aboutToolTextBox.lines = text.wrap({tool.about}, aboutToolTextBox.width)
		aboutToolTextBox.height = #aboutToolTextBox.lines
	end

	workspace:draw()
end

local modules = filesystem.list(toolsPath)
for i = 1, #modules do
	if filesystem.extension(modules[i]) == ".lua" then
		local result, reason = loadfile(toolsPath .. modules[i])
		if result then
			result, reason = pcall(result)
			if result then
				local item = workspace.toolsList:addItem(reason.shortcut)
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
end

workspace.image.draw = function(object)
	GUI.drawShadow(object.x, object.y, object.width, object.height, nil, true)
	
	local y, text = object.y + object.height + 1, "Size: " .. object.width .. "x" .. object.height
	screen.drawText(math.floor(object.x + object.width / 2 - unicode.len(text) / 2), y, 0x5A5A5A, text)

	if savePath then
		text = "Path: " .. savePath
		screen.drawText(math.floor(object.x + object.width / 2 - unicode.len(text) / 2), y + 1, 0x5A5A5A, text)
	end
	
	local x, y, step, notStep, background, foreground, symbol = object.x, object.y, false, workspace.image.width % 2
	for i = 3, #workspace.image.data, 4 do
		if workspace.image.data[i + 2] == 0 then
			background = workspace.image.data[i]
			foreground = workspace.image.data[i + 1]
			symbol = workspace.image.data[i + 3]
		elseif workspace.image.data[i + 2] < 1 then
			background = color.blend(config.transparencyBackground, workspace.image.data[i], workspace.image.data[i + 2])
			foreground = workspace.image.data[i + 1]
			symbol = workspace.image.data[i + 3]
		else
			if workspace.image.data[i + 3] == " " then
				background = config.transparencyBackground
				foreground = config.transparencyForeground
				symbol = step and "▒" or "░"
			else
				background = config.transparencyBackground
				foreground = workspace.image.data[i + 1]
				symbol = workspace.image.data[i + 3]
			end
		end

		screen.set(x, y, background, foreground, symbol)

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
	workspace.primaryColorSelector.color, workspace.secondaryColorSelector.color = workspace.secondaryColorSelector.color, workspace.primaryColorSelector.color
	workspace:draw()
end

local function colorSelectorDraw(object)
	screen.drawRectangle(object.x + 1, object.y, object.width - 2, object.height, object.color, 0x0, " ")
	for y = object.y, object.y + object.height - 1 do
		screen.drawText(object.x, y, object.color, "⢸")
		screen.drawText(object.x + object.width - 1, y, object.color, "⡇")
	end
end

workspace.secondaryColorSelector = workspace:addChild(GUI.colorSelector(2, workspace.toolsList.height - 3, 5, 2, 0xFFFFFF, " "))
workspace.primaryColorSelector = workspace:addChild(GUI.colorSelector(1, workspace.toolsList.height - 4, 5, 2, 0x880000, " "))
workspace.secondaryColorSelector.draw, workspace.primaryColorSelector.draw = colorSelectorDraw, colorSelectorDraw

workspace:addChild(GUI.adaptiveButton(3, workspace.secondaryColorSelector.localY + workspace.secondaryColorSelector.height + 1, 0, 0, nil, 0xD2D2D2, nil, 0xA5A5A5, "<>")).onTouch = swapColors

workspace.image.eventHandler = function(workspace, object, e1, e2, e3, e4, ...)
	if e1 == "key_down" then
		-- D
		if e4 == 32 then
			workspace.primaryColorSelector.color, workspace.secondaryColorSelector.color = 0x0, 0xFFFFFF
			workspace:draw()
		-- X
		elseif e4 == 45 then
			swapColors()
		else
			for i = 1, workspace.toolsList:count() do
				if e4 == workspace.toolsList:getItem(i).tool.keyCode then
					onToolTouch(i)
					return
				end
			end
		end
	end

	local result, reason = pcall(tool.eventHandler, workspace, object, e1, e2, e3, e4, ...)
	if not result then
		GUI.alert("Tool eventHandler() failed: " .. reason)
	end
end

workspace.image.reposition = function()
	workspace.image.width, workspace.image.height = workspace.image.data[1], workspace.image.data[2]
	if workspace.image.width <= workspace.backgroundPanel.width then
		workspace.image.localX = math.floor(workspace.backgroundPanel.x + workspace.backgroundPanel.width / 2 - workspace.image.width / 2)
		workspace.image.localY = math.floor(workspace.backgroundPanel.y + workspace.backgroundPanel.height / 2 - workspace.image.height / 2)
	else
		workspace.image.localX, workspace.image.localY = 9, 3
	end
end

local function newNoGUI(width, height)
	savePath, saveItem.disabled = nil, true
	workspace.image.data = {width, height}
	workspace.image.reposition()	
	
	for i = 1, width * height do
		table.insert(workspace.image.data, 0x0)
		table.insert(workspace.image.data, 0x0)
		table.insert(workspace.image.data, 1)
		table.insert(workspace.image.data, " ")
	end
end

local function new()
	local container = GUI.addBackgroundContainer(workspace, true, true, "New picture")

	local widthInput = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0x696969, 0xE1E1E1, 0x2D2D2D, "51", "Width"))
	local heightInput = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0x696969, 0xE1E1E1, 0x2D2D2D, "19", "Height"))
	
	widthInput.validator = function(text)
		return tonumber(text)
	end
	heightInput.validator = widthInput.validator

	container.panel.eventHandler = function(workspace, object, e1)
		if e1 == "touch" then
			newNoGUI(tonumber(widthInput.text), tonumber(heightInput.text))
			container:remove()
			workspace:draw()
		end
	end

	workspace:draw()
end

local function loadImage(path)
	local result, reason
	
	if filesystem.extension(path) == ".rawpic" then
		result = image.fromString(filesystem.read(path))
	else
		result, reason = image.load(path)
	end

	if result then
		savePath, saveItem.disabled = path, false
		addRecentFile(path)
		workspace.image.data = result
		workspace.image.reposition()
	else
		GUI.alert(reason)
	end
end

local function saveImage(path)
	if filesystem.extension(path) == ".pic" then
		local result, reason = image.save(path, workspace.image.data, 6)
		if result then
			savePath, saveItem.disabled = path, false
			
			addRecentFile(path)
		else
			GUI.alert(reason)
		end
	else
		savePath, saveItem.disabled = path, false

		filesystem.write(path, image.toString(workspace.image.data))
	end
end

workspace.menu:addItem("PE", 0x00B6FF)

local fileItem = workspace.menu:addContextMenu("File")
fileItem:addItem("New").onTouch = new

fileItem:addSeparator()

fileItem:addItem("Open").onTouch = function()
	local filesystemDialog = GUI.addFilesystemDialog(workspace, true, 50, math.floor(workspace.height * 0.8), "Open", "Cancel", "File name", "/")
	filesystemDialog:setMode(GUI.IO_MODE_OPEN, GUI.IO_MODE_FILE)
	filesystemDialog:addExtensionFilter(".pic")
	filesystemDialog:addExtensionFilter(".rawpic")
	filesystemDialog:expandPath(paths.user.desktop)
	filesystemDialog:show()

	filesystemDialog.onSubmit = function(path)
		loadImage(path)
		workspace:draw()
	end
end

local fileItemSubMenu = fileItem:addSubMenu("Open recent", #config.recentFiles == 0)
for i = 1, #config.recentFiles do
	fileItemSubMenu:addItem(text.limit(config.recentFiles[i], 32, "left")).onTouch = function()
		loadImage(config.recentFiles[i])
		workspace:draw()
	end
end

fileItem:addItem("Open from URL").onTouch = function()
	local container = GUI.addBackgroundContainer(workspace, true, true, "Open from URL")

	local input = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0x969696, 0xE1E1E1, 0x2D2D2D, "", "http://example.com/test.pic"))
	input.onInputFinished = function()
		if #input.text > 0 then
			input:remove()
			container.layout:addChild(GUI.label(1, 1, container.width, 1, 0x969696, "Downloading file..."):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP))
			workspace:draw()

			local temporaryPath = system.getTemporaryPath() .. ".pic"
			local result, reason = internet.download(input.text, temporaryPath)

			container:remove()

			if result then
				loadImage(temporaryPath)
				filesystem.remove(temporaryPath)
				savePath, saveItem.disabled = nil, true
			else
				GUI.alert(reason)
			end

			workspace:draw()
		end
	end

	workspace:draw()
end

fileItem:addSeparator()

saveItem = fileItem:addItem("Save")
saveItem.onTouch = function()
	saveImage(savePath)
end

fileItem:addItem("Save as").onTouch = function()
	local filesystemDialog = GUI.addFilesystemDialog(workspace, true, 50, math.floor(workspace.height * 0.8), "Save", "Cancel", "File name", "/")
	filesystemDialog:setMode(GUI.IO_MODE_SAVE, GUI.IO_MODE_FILE)
	filesystemDialog:addExtensionFilter(".pic")
	filesystemDialog:addExtensionFilter(".ocifstring")
	filesystemDialog:expandPath(paths.user.desktop)
	filesystemDialog.filesystemTree.selectedItem = paths.user.desktop
	filesystemDialog:show()

	filesystemDialog.onSubmit = function(path)
		saveImage(path)
	end
end

fileItem:addSeparator()

fileItem:addItem("Exit").onTouch = function()
	workspace:stop()
end

workspace.menu:addItem("View").onTouch = function()
	local container = GUI.addBackgroundContainer(workspace, true, true, "View")

	local colorSelector1 = container.layout:addChild(GUI.colorSelector(1, 1, 36, 3, config.transparencyBackground, "Transparency background"))
	local colorSelector2 = container.layout:addChild(GUI.colorSelector(1, 1, 36, 3, config.transparencyForeground, "Transparency foreground"))

	container.panel.eventHandler = function(workspace, object, e1)
		if e1 == "touch" then
			config.transparencyBackground, config.transparencyForeground = colorSelector1.color, colorSelector2.color
			
			container:remove()
			workspace:draw()
			saveConfig()
		end
	end

	workspace:draw()
end

workspace.menu:addItem("Hotkeys").onTouch = function()
	local container = GUI.addBackgroundContainer(workspace, true, true, "Hotkeys")
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
	workspace:draw()
end

workspace.currentToolOverlay = workspace:addChild(GUI.container(1, 1, workspace.width, workspace.height))

----------------------------------------------------------------

workspace.image:moveToBack()
workspace.backgroundPanel:moveToBack()

updateRecentColorsButtons()

if options.o or options.open and args[1] and filesystem.exists(args[1]) then
	loadImage(args[1])
else
	newNoGUI(51, 19)
end

onToolTouch(5)
workspace:start()