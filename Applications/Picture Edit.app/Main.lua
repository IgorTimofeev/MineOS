
local GUI = require("GUI")
local internet = require("Internet")
local system = require("System")
local filesystem = require("Filesystem")
local image = require("Image")
local color = require("Color")
local screen = require("Screen")
local paths = require("Paths")
local text = require("Text")
local keyboard = require("Keyboard")

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

local locale = system.getCurrentScriptLocalization()
local currentScriptDirectory = filesystem.path(system.getCurrentScript())
local toolsPath = currentScriptDirectory .. "Tools/"
local configPath = paths.user.applicationData .. "Picture Edit/Config2.cfg"
local savePath
local saveItem
local tool

local workspace, window, menu = system.addWindow(GUI.filledWindow(1, 1, 125, 37, 0x1E1E1E))

--------------------------------------------------------------------

window.newInput = function(...)
	return GUI.input(1, 1, 1, 1, 0x1E1E1E, 0xC3C3C3, 0x5A5A5A, 0x1E1E1E, 0xD2D2D2, ...)
end

window.newSlider = function(...)
	local slider = GUI.slider(1, 1, 1, 0x66DB80, 0x1E1E1E, 0xE1E1E1, 0x878787, ...)
	slider.roundValues = true

	return slider
end

window.newSwitch = function(...)
	return GUI.switchAndLabel(1, 1, 1, 6, 0x66DB80, 0x1E1E1E, 0xE1E1E1, 0x878787, ...)
end

window.newButton1 = function(...)
	return GUI.roundedButton(1, 1, 36, 1, 0xE1E1E1, 0x4B4B4B, 0x4B4B4B, 0xE1E1E1, ...)
end

window.newButton2 = function(...)
	local button = GUI.roundedButton(1, 1, 36, 1, 0x4B4B4B, 0xE1E1E1, 0x2D2D2D, 0xE1E1E1, ...)
	button.colors.disabled.background, button.colors.disabled.text = 0x4B4B4B, 0x787878

	return button
end

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

local function addTitle(container, text)
	local titleContainer = container:addChild(GUI.container(1, 1, container.width, 1))
	titleContainer:addChild(GUI.panel(1, 1, titleContainer.width, 1, 0x1E1E1E))
	titleContainer:addChild(GUI.text(2, 1, 0xD2D2D2, text))

	return titleContainer
end

window.image = window:addChild(GUI.object(1, 1, 1, 1))
window.image.data = {}
window.sidebarPanel = window:addChild(GUI.panel(1, 1, 28, 1, 0x2D2D2D))
window.sidebarLayout = window:addChild(GUI.layout(1, 1, window.sidebarPanel.width, 1, 1, 1))
window.sidebarLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)

window.sidebarLayout.eventHandler = function(workspace, object, e1, e2, e3, e4, e5)
	if e1 == "scroll" then
		local h, v = window.sidebarLayout:getMargin(1, 1)
		local from = 0
		local to = -window.sidebarLayout.cells[1][1].childrenHeight + 2

		v = v + (e5 > 0 and 2 or -2)
		if v > from then
			v = from
		elseif v < to then
			v = to
		end

		window.sidebarLayout:setMargin(1, 1, h, v)
	end
end

addTitle(window.sidebarLayout, locale.recentColors)

local recentColorsContainer = window.sidebarLayout:addChild(GUI.container(1, 1, window.sidebarLayout.width - 2, 4))
local x, y = 1, 1
for i = 1, #config.recentColors do
	local button = recentColorsContainer:addChild(GUI.button(x, y, 2, 1, 0x0, 0x0, 0x0, 0x0, " "))
	button.onTouch = function()
		window.primaryColorSelector.color = config.recentColors[i]
	end

	x = x + 2
	if x > recentColorsContainer.width - 1 then
		x, y = 1, y + 1
	end
end

local currentToolTitle = addTitle(window.sidebarLayout, locale.toolProperties)

window.currentToolLayout = window.sidebarLayout:addChild(GUI.layout(1, 1, window.sidebarLayout.width, 1, 1, 1))
window.currentToolLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
window.currentToolLayout:setFitting(1, 1, true, false, 2, 0)

local aboutToolTitle = addTitle(window.sidebarLayout, locale.aboutTool)
local aboutToolTextBox = window.sidebarLayout:addChild(GUI.textBox(1, 1, window.sidebarLayout.width - 2, 1, nil, 0x787878, {}, 1, 0, 0))

window.toolsList = window:addChild(GUI.list(1, 1, 7, 1, 3, 0, 0x2D2D2D, 0x787878, 0x2D2D2D, 0x787878, 0x3C3C3C, 0xE1E1E1))
window.toolsList:setMargin(0, 3)

local function onToolTouch(index)
	tool = window.toolsList:getItem(index).tool
	
	window.toolsList.selectedItem = index
	window.currentToolOverlay:removeChildren()
	window.currentToolLayout:removeChildren()

	currentToolTitle.hidden = not tool.onSelection
	window.currentToolLayout.hidden = currentToolTitle.hidden
	window.sidebarLayout:setMargin(1, 1, 0, 0)
	
	if tool.onSelection then
		local result, reason = pcall(tool.onSelection)
		if result then
			window.currentToolLayout:update()
			local lastChild = window.currentToolLayout.children[#window.currentToolLayout.children]
			if lastChild then
				window.currentToolLayout.height = lastChild.localY + lastChild.height - 1
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

end

local tools = filesystem.list(toolsPath)
for i = 1, #tools do
	if filesystem.extension(tools[i]) == ".lua" then
		local result, reason = loadfile(toolsPath .. tools[i])
		if result then
			result, reason = pcall(result, workspace, window, menu, locale)
			if result then
				local item = window.toolsList:addItem(reason.shortcut)
				item.tool = reason
				item.onTouch = function()
					onToolTouch(i)
				end
			else
				error("Failed to perform pcall() on tool " .. tools[i] .. ": " .. reason)
			end
		else
			error("Failed to perform loadfile() on tool " .. tools[i] .. ": " .. reason)
		end
	end
end

window.image.draw = function(object)
	GUI.drawShadow(object.x, object.y, object.width, object.height, nil, true)
	
	local y, text = object.y + object.height + 1, locale.size .. object.width .. "x" .. object.height
	screen.drawText(math.floor(object.x + object.width / 2 - unicode.len(text) / 2), y, 0x5A5A5A, text)

	if savePath then
		text = locale.path .. savePath
		screen.drawText(math.floor(object.x + object.width / 2 - unicode.len(text) / 2), y + 1, 0x5A5A5A, text)
	end
	
	local x, y, step, notStep, background, foreground, symbol = object.x, object.y, false, window.image.width % 2
	for i = 3, #window.image.data, 4 do
		if window.image.data[i + 2] == 0 then
			background = window.image.data[i]
			foreground = window.image.data[i + 1]
			symbol = window.image.data[i + 3]
		elseif window.image.data[i + 2] < 1 then
			background = color.blend(config.transparencyBackground, window.image.data[i], window.image.data[i + 2])
			foreground = window.image.data[i + 1]
			symbol = window.image.data[i + 3]
		else
			if window.image.data[i + 3] == " " then
				background = config.transparencyBackground
				foreground = config.transparencyForeground
				symbol = step and "▒" or "░"
			else
				background = config.transparencyBackground
				foreground = window.image.data[i + 1]
				symbol = window.image.data[i + 3]
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
	window.primaryColorSelector.color, window.secondaryColorSelector.color = window.secondaryColorSelector.color, window.primaryColorSelector.color
end

local function colorSelectorDraw(object)
	screen.drawRectangle(object.x + 1, object.y, object.width - 2, object.height, object.color, 0x0, " ")
	for y = object.y, object.y + object.height - 1 do
		screen.drawText(object.x, y, object.color, "⢸")
		screen.drawText(object.x + object.width - 1, y, object.color, "⡇")
	end
end

window.secondaryColorSelector = window:addChild(GUI.colorSelector(3, 1, 5, 2, 0xFFFFFF, " "))
window.primaryColorSelector = window:addChild(GUI.colorSelector(2, 1, 5, 2, 0x000000, " "))
window.secondaryColorSelector.draw, window.primaryColorSelector.draw = colorSelectorDraw, colorSelectorDraw

window.swapColorsButton = window:addChild(GUI.button(1, 1, window.toolsList.width, 1, nil, 0x696969, nil, 0xA5A5A5, " ←→"))
window.swapColorsButton.onTouch = swapColors

local function setSavePath(path)
	savePath, saveItem.disabled = path, path == nil
end

local function loadImage(path)
	local result, reason
	
	if filesystem.extension(path) == ".txt" then
		result = image.fromString(filesystem.read(path))
	else
		result, reason = image.load(path)
	end

	if result then
		setSavePath(path)
		addRecentFile(path)
		window.image.data = result
	else
		GUI.alert(reason)
	end
end

local function save(path)
	if filesystem.extension(path) == ".pic" then
		local result, reason = image.save(path, window.image.data, 8)
		
		if result then
			setSavePath(path)
			addRecentFile(path)
		else
			GUI.alert(reason)
		end
	else
		setSavePath(path)
		filesystem.write(path, image.toString(window.image.data))
	end

	computer.pushSignal("system", "updateFileList")
end

local function saveAs()
	local filesystemDialog = GUI.addFilesystemDialog(workspace, true, 50, math.floor(window.height * 0.8), locale.save, locale.cancel, locale.fileName, "/")
	filesystemDialog:setMode(GUI.IO_MODE_SAVE, GUI.IO_MODE_FILE)
	filesystemDialog:addExtensionFilter(".pic")
	filesystemDialog:addExtensionFilter(".txt")
	filesystemDialog:expandPath(paths.user.desktop)
	filesystemDialog.filesystemTree.selectedItem = paths.user.desktop
	filesystemDialog:show()

	filesystemDialog.onSubmit = function(path)
		save(path)
	end
end

local function newNoGUI(width, height, path)
	setSavePath(path)

	window.image.data = {width, height}
	
	for i = 1, width * height do
		table.insert(window.image.data, 0x0)
		table.insert(window.image.data, 0x0)
		table.insert(window.image.data, 1)
		table.insert(window.image.data, " ")
	end
end

local function new()
	local container = GUI.addBackgroundContainer(workspace, true, true, locale.newPicture)
	container.panel.eventHandler = nil

	local layout = container.layout:addChild(GUI.layout(1, 1, 36, 3, 1, 1))
	layout:setDirection(1, 1, GUI.DIRECTION_HORIZONTAL)
	layout:setSpacing(1, 1, 0)

	local function addInput(...)
		return layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0x969696, 0xE1E1E1, 0x2D2D2D, ...))
	end

	local widthInput = addInput("", locale.width)
	layout:addChild(GUI.text(1, 1, 0x696969, " x "))
	local heightInput = addInput("", locale.height)
	widthInput.width, heightInput.width = 16, 17
	
	container.layout:addChild(GUI.button(1, 1, 30, 3, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, locale.ok)).onTouch = function()
		if
			widthInput.text:match("%d+") and
			heightInput.text:match("%d+")
		then
			newNoGUI(tonumber(widthInput.text), tonumber(heightInput.text), nil)
			window.image.reposition()
		end

		container:remove()
	end
	
	container.layout:addChild(GUI.button(1, 1, 30, 3, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, locale.cancel)).onTouch = function()
		container:remove()
	end

end

local function open()
	local filesystemDialog = GUI.addFilesystemDialog(workspace, true, 50, math.floor(window.height * 0.8), locale.open, locale.cancel, locale.fileName, "/")
	filesystemDialog:setMode(GUI.IO_MODE_OPEN, GUI.IO_MODE_FILE)
	filesystemDialog:addExtensionFilter(".pic")
	filesystemDialog:addExtensionFilter(".txt")
	filesystemDialog:expandPath(paths.user.desktop)
	filesystemDialog:show()

	filesystemDialog.onSubmit = function(path)
		loadImage(path)

		window.image.reposition()
	end
end

window.image.eventHandler = function(workspace, object, e1, e2, e3, e4, ...)
	if e1 == "key_down" then
		-- D
		if e4 == 32 then
			window.primaryColorSelector.color, window.secondaryColorSelector.color = 0x0, 0xFFFFFF
			workspace:draw()
		-- X
		elseif e4 == 45 then
			swapColors()
		elseif keyboard.isControlDown() or keyboard.isCommandDown() then
			-- S
			if e4 == 31 then
				if keyboard.isShiftDown() then
					saveAs()
				elseif not saveItem.disabled then
					save(savePath)
				end
			-- N
			elseif e4 == 49 then
				new()
			-- O
			elseif e4 == 24 then
				open()
			end
		else
			for i = 1, window.toolsList:count() do
				if e4 == window.toolsList:getItem(i).tool.keyCode then
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

window.image.setPosition = function(x, y)
	window.image.localX = x
	window.image.localY = y
	window.currentToolOverlay.localX = x
	window.currentToolOverlay.localY = y
end

window.image.reposition = function()
	window.image.width = window.image.data[1]
	window.image.height = window.image.data[2]
	window.currentToolOverlay.width = window.image.width
	window.currentToolOverlay.height = window.image.height

	if window.image.width < window.backgroundPanel.width then
		window.image.setPosition(
			math.floor(window.backgroundPanel.localX + window.backgroundPanel.width / 2 - window.image.width / 2),
			math.floor(window.backgroundPanel.localY + window.backgroundPanel.height / 2 - window.image.height / 2)
		)
	else
		window.image.setPosition(
			window.backgroundPanel.localX,
			window.backgroundPanel.localY
		)
	end
end

local fileItem = menu:addContextMenuItem(locale.file)
fileItem:addItem(locale.new, false, "^N").onTouch = new

fileItem:addSeparator()

fileItem:addItem(locale.open, false, "^O").onTouch = open

local fileItemSubMenu = fileItem:addSubMenuItem(locale.openRecent, #config.recentFiles == 0)
for i = 1, #config.recentFiles do
	fileItemSubMenu:addItem(text.limit(config.recentFiles[i], 32, "left")).onTouch = function()
		loadImage(config.recentFiles[i])

		window.image.reposition()
	end
end

fileItem:addItem(locale.openFromURL).onTouch = function()
	local container = GUI.addBackgroundContainer(workspace, true, true, locale.openFromURL)
	container.panel.eventHandler = nil

	local input = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0x969696, 0xE1E1E1, 0x2D2D2D, "", "http://example.com/test.pic"))
	local okBut = container.layout:addChild(GUI.button(1, 1, 30, 3, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, locale.ok))
	local cancelBut = container.layout:addChild(GUI.button(1, 1, 30, 3, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, locale.cancel))
	
	okBut.onTouch = function()
		if #input.text > 0 then
			input:remove()
			okBut:remove()
			cancelBut:remove()
			
			container.layout:addChild(GUI.label(1, 1, container.width, 1, 0x969696, locale.downloading):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP))
			workspace:draw()

			local temporaryPath = system.getTemporaryPath() .. ".pic"
			local result, reason = internet.download(input.text, temporaryPath)

			container:remove()

			if result then
				loadImage(temporaryPath)
				window.image.reposition()

				filesystem.remove(temporaryPath)
				setSavePath(nil)
			else
				GUI.alert(reason)
			end

		else
			container:remove()
		end
	end
	
	cancelBut.onTouch = function()
		container:remove()
	end
end

fileItem:addSeparator()

saveItem = fileItem:addItem(locale.save, false, "^S")
saveItem.onTouch = function()
	save(savePath)
end

fileItem:addItem(locale.saveAs, false, "^⇧S").onTouch = saveAs

menu:addItem(locale.view).onTouch = function()
	local container = GUI.addBackgroundContainer(workspace, true, true, locale.view)
	container.panel.eventHandler = nil

	local colorSelector1 = container.layout:addChild(GUI.colorSelector(1, 1, 36, 3, config.transparencyBackground, locale.transBack))
	local colorSelector2 = container.layout:addChild(GUI.colorSelector(1, 1, 36, 3, config.transparencyForeground, locale.transFor))
	
	container.layout:addChild(GUI.button(1, 1, 30, 3, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, locale.ok)).onTouch = function()
		config.transparencyBackground, config.transparencyForeground = colorSelector1.color, colorSelector2.color
			
		container:remove()
		saveConfig()
	end
	
	container.layout:addChild(GUI.button(1, 1, 30, 3, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, locale.cancel)).onTouch = function()
		container:remove()
	end
end

local imageItem = menu:addContextMenuItem(locale.image)

imageItem:addItem(locale.flipVertical).onTouch = function()
	window.image.data = image.flipVertically(window.image.data)
end

imageItem:addItem(locale.flipHorizontal).onTouch = function()
	window.image.data = image.flipHorizontally(window.image.data)
end

imageItem:addSeparator()

imageItem:addItem(locale.rotate90).onTouch = function()
	window.image.data = image.rotate(window.image.data, 90)
	window.image.width = window.image.data[1]
	window.image.height = window.image.data[2]
	window.image.reposition()
end

imageItem:addItem(locale.rotate180).onTouch = function()
	window.image.data = image.rotate(window.image.data, 180)
	window.image.width = window.image.data[1]
	window.image.height = window.image.data[2]
	window.image.reposition()
end

imageItem:addItem(locale.rotate270).onTouch = function()
	window.image.data = image.rotate(window.image.data, 270)
	window.image.width = window.image.data[1]
	window.image.height = window.image.data[2]
	window.image.reposition()
end

local editItem = menu:addContextMenuItem(locale.edit)

editItem:addItem(locale.hueSaturation).onTouch = function()
	local container = GUI.addBackgroundContainer(workspace, true, true, locale.hueSaturation)
	container.layout:setSpacing(1, 1, 2)
	container.panel.eventHandler = nil

	local hue = container.layout:addChild(GUI.slider(1, 1, 50, 0x66DB80, 0x0, 0xFFFFFF, 0xAAAAAA, -360, 360, 0, true, locale.hue))
	local satur = container.layout:addChild(GUI.slider(1, 1, 50, 0x66DB80, 0x0, 0xFFFFFF, 0xAAAAAA, -100, 100, 0, true, locale.saturation))
	local bright = container.layout:addChild(GUI.slider(1, 1, 50, 0x66DB80, 0x0, 0xFFFFFF, 0xAAAAAA, -100, 100, 0, true, locale.brightness))
	hue.roundValues = true
	satur.roundValues = true
	bright.roundValues = true
	
	local buttonsLay = container.layout:addChild(GUI.layout(1, 1, 30, 7, 1, 1))
	
	buttonsLay:addChild(GUI.button(1, 1, 30, 3, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, locale.ok)).onTouch = function()
		window.image.data = image.hueSaturationBrightness(window.image.data, hue.value, satur.value/100, bright.value/100)
		container:remove()
	end
	
	buttonsLay:addChild(GUI.button(1, 1, 30, 3, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, locale.cancel)).onTouch = function()
		container:remove()
	end
end

editItem:addItem(locale.colorBalance).onTouch = function()
	local container = GUI.addBackgroundContainer(workspace, true, true, locale.colorBalance)
	container.layout:setSpacing(1, 1, 2)
	container.panel.eventHandler = nil

	local r = container.layout:addChild(GUI.slider(1, 1, 50, 0x66DB80, 0x0, 0xFF0000, 0xAAAAAA, -255, 255, 0, true, "R: "))
	local g = container.layout:addChild(GUI.slider(1, 1, 50, 0x66DB80, 0x0, 0x00FF00, 0xAAAAAA, -255, 255, 0, true, "G: "))
	local b = container.layout:addChild(GUI.slider(1, 1, 50, 0x66DB80, 0x0, 0x0000FF, 0xAAAAAA, -255, 255, 0, true, "B: "))
	r.roundValues = true
	g.roundValues = true
	b.roundValues = true
	
	local buttonsLay = container.layout:addChild(GUI.layout(1, 1, 30, 7, 1, 1))
	
	buttonsLay:addChild(GUI.button(1, 1, 30, 3, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, locale.ok)).onTouch = function()
		window.image.data = image.colorBalance(window.image.data, math.floor(r.value), math.floor(g.value), math.floor(b.value))
		container:remove()
	end
	
	buttonsLay:addChild(GUI.button(1, 1, 30, 3, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, locale.cancel)).onTouch = function()
		container:remove()
	end
end

editItem:addItem(locale.photoFilter).onTouch = function()
	local container = GUI.addBackgroundContainer(workspace, true, true, locale.photoFilter)
	container.layout:setSpacing(1, 1, 2)
	container.panel.eventHandler = nil

	local filterColor = container.layout:addChild(GUI.colorSelector(1, 1, 30, 3, 0x333333, locale.filterColor))
	local transparency = container.layout:addChild(GUI.slider(1, 1, 50, 0x66DB80, 0x0, 0xFFFFFF, 0xAAAAAA, 0, 1, 0.5, true, locale.transparency))
	
	local buttonsLay = container.layout:addChild(GUI.layout(1, 1, 30, 7, 1, 1))
	
	buttonsLay:addChild(GUI.button(1, 1, 30, 3, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, locale.ok)).onTouch = function()
		window.image.data = image.blend(window.image.data, filterColor.color, transparency.value)
		container:remove()
	end
	
	buttonsLay:addChild(GUI.button(1, 1, 30, 3, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, locale.cancel)).onTouch = function()
		container:remove()
	end
end

editItem:addSeparator()

editItem:addItem(locale.invertColors).onTouch = function()
	window.image.data = image.invert(window.image.data)
end

editItem:addItem(locale.blackWhite).onTouch = function()
	window.image.data = image.blackAndWhite(window.image.data)
end

editItem:addSeparator()

editItem:addItem(locale.gaussianBlur).onTouch = function()
	local container = GUI.addBackgroundContainer(workspace, true, true, locale.gaussianBlur)
	container.panel.eventHandler = nil

	local radius = container.layout:addChild(GUI.slider(1, 1, 50, 0x66DB80, 0x0, 0xFFFFFF, 0xAAAAAA, 1, 10, 2, true, locale.radius))
	radius.height = 2
	radius.roundValues = true

	local force = container.layout:addChild(GUI.slider(1, 1, 50, 0x66DB80, 0x0, 0xFFFFFF, 0xAAAAAA, 0, 1, 0.5, true, locale.force))
	force.height = 2
	
	container.layout:addChild(GUI.button(1, 1, 30, 3, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, locale.ok)).onTouch = function()
		window.image.data = image.convolve(window.image.data, image.getGaussianBlurKernel(math.floor(radius.value), force.value))
		container:remove()
	end
	
	container.layout:addChild(GUI.button(1, 1, 30, 3, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, locale.cancel)).onTouch = function()
		container:remove()
	end
end

menu:addItem(locale.hotkeys).onTouch = function()
	local container = GUI.addBackgroundContainer(workspace, true, true, locale.hotkeys)

	container.layout:addChild(GUI.textBox(1, 1, 36, 1, nil, 0x969696, locale.hotkeysText, 1, 0, 0, true, true)).eventHandler = nil
end

window.currentToolOverlay = window:addChild(GUI.container(1, 1, 1, 1))

window.onResize = function(width, height)
	window.backgroundPanel.localX = window.toolsList.width + 1
	window.backgroundPanel.width = width - window.sidebarLayout.width - window.toolsList.width
	window.backgroundPanel.height = height

	window.sidebarPanel.localX = window.width - window.sidebarPanel.width + 1
	window.sidebarPanel.height = height

	window.sidebarLayout.localX = window.sidebarPanel.localX
	window.sidebarLayout.height = height

	window.toolsList.height = height

	window.secondaryColorSelector.localY = height - 4
	window.primaryColorSelector.localY = height - 5
	window.swapColorsButton.localY = height - 1

	window.image.reposition()
end

----------------------------------------------------------------

window.actionButtons:moveToFront()

updateRecentColorsButtons()

if (options.o or options.open) and args[1] then
	if filesystem.exists(args[1]) then
		loadImage(args[1])
	elseif options.n and args[2] and args[3] then
		newNoGUI(args[2], args[3], args[1])
	else
		newNoGUI(50, 20, nil)
	end
else
	newNoGUI(50, 20, nil)
end

window:resize(window.width, window.height)

onToolTouch(5)
