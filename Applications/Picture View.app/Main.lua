local GUI = require("GUI")
local system = require("System")
local fs = require("Filesystem")
local image = require("Image")
local text = require("Text")
local screen = require("Screen")
local paths = require("Paths")

local localization = system.getCurrentScriptLocalization()

local args, options = system.parseArguments(...)
local iconsPath = fs.path(system.getCurrentScript()) .. "Icons/"
local currentDir, files = ((options.o or options.open) and args[1] and fs.exists(args[1])) and fs.path(args[1]) or paths.system.pictures
local fileIndex = 1
local loadedImage, title

--------------------------------------------------------------------------------

local workspace, window, menu = system.addWindow(GUI.filledWindow(1, 1, 80, 25, 0x1E1E1E))

local imageObject = window:addChild(GUI.object(1, 1, 1, 1))

imageObject.draw = function()
	local halfX, halfY = imageObject.x + imageObject.width / 2, imageObject.y + imageObject.height / 2

	if loadedImage then
		screen.drawImage(
			math.floor(halfX - loadedImage[1] / 2),
			math.floor(halfY - loadedImage[2] / 2),
			loadedImage
		)

		if title then
			screen.drawText(math.floor(halfX - unicode.len(title) / 2), imageObject.y + 1, 0xFFFFFF, title, 0.5)
		end
	elseif #files == 0 then
		screen.drawText(math.floor(halfX - unicode.len(localization.noPictures) / 2), math.floor(halfY), 0x5A5A5A, localization.noPictures)
	end
end

window.actionButtons:moveToFront()

local panel = window:addChild(GUI.panel(1, 1, 1, 6, 0x000000, 0.5))
local panelContainer = window:addChild(GUI.container(1, 1, 1, panel.height))
local slideShowDelay, slideShowDeadline

local function updateTitle()
	if panel.hidden then
		title = nil
	else
		title = fs.name(files[fileIndex])
	end
end

local function setUIHidden(state)
	panel.hidden = state
	panelContainer.hidden = state
	window.actionButtons.hidden = state

	updateTitle()
end

local function updateSlideshowDeadline()
	slideShowDeadline = computer.uptime() + slideShowDelay
end

local function loadImage()	
	local result, reason = image.load(files[fileIndex])
	
	if result then
		loadedImage = result

		updateTitle()
	else
		GUI.alert(reason)
		window:remove()
	end

	workspace:draw()
end

local function loadIncremented(value)
	fileIndex = fileIndex + value

	if fileIndex > #files then
		fileIndex = 1
	elseif fileIndex < 1 then
		fileIndex = #files
	end

	loadImage()
end

local function addButton(imageName, onTouch)
	-- Spacing
	if #panelContainer.children > 0 then
		panelContainer.width = panelContainer.width + 5
	end

	local i = GUI.image(panelContainer.width, 2, image.load(iconsPath .. imageName .. ".pic"))

	panelContainer:addChild(i).eventHandler = function(_, _, e)
		if e == "touch" then
			onTouch()
		end
	end

	panelContainer.width = panelContainer.width + i.width
end

addButton("ArrowLeft", function()
	loadIncremented(-1)
end)

addButton("Play", function()
	local container = GUI.addBackgroundContainer(workspace, true, true, localization.slideShow)
	container.panel.eventHandler = nil
	container.layout:setSpacing(1, 1, 2)
	
	local delay = container.layout:addChild(GUI.slider(1, 1, 50, 0x66DB80, 0x0, 0xFFFFFF, 0xFFFFFF, 3, 30, 0, true, localization.delay, localization.seconds))
	delay.roundValues = true
	
	local buttonsLay = container.layout:addChild(GUI.layout(1, 1, 30, 7, 1, 1))
	
	buttonsLay:addChild(GUI.button(1, 1, 30, 3, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, localization.start)).onTouch = function()
		setUIHidden(true)

		if not window.maximized then
			window:maximize()
		end

		slideShowDelay = delay.value
		updateSlideshowDeadline()
			
		container:remove()
	end
	
	buttonsLay:addChild(GUI.button(1, 1, 30, 3, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, localization.cancel)).onTouch = function()
		container:remove()
	end

	workspace:draw()
end)

-- Arrow right
addButton("ArrowRight", function()
	loadIncremented(1)
end)

-- Set wallpaper
addButton("SetWallpaper", function()
	local container = GUI.addBackgroundContainer(workspace, true, true, localization.setWallpaper)
	container.panel.eventHandler = nil
	
	local buttLay = container.layout:addChild(GUI.layout(1, 1, 24, 6, 2, 1))
	
	buttLay:addChild(GUI.button(1, 1, 10, 3, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, localization.yes)).onTouch = function()
		local sets = system.getUserSettings()
		sets.interfaceWallpaperPath = files[fileIndex]
		system.saveUserSettings()
		system.updateWallpaper()
			
		container:remove()
	end

	local cancel = buttLay:addChild(GUI.button(1, 1, 10, 3, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, localization.no))
	
	cancel.onTouch = function()
		container:remove()
	end
	
	buttLay:setPosition(2, 1, cancel)
end)

window.onResize = function(newWidth, newHeight)
	window.backgroundPanel.width, window.backgroundPanel.height = newWidth, newHeight
	imageObject.width, imageObject.height = newWidth, newHeight
	panel.width, panel.localY = newWidth, newHeight - 5
	panelContainer.localX, panelContainer.localY = math.floor(newWidth / 2 - panelContainer.width / 2), panel.localY
end

local overrideWindowEventHandler = window.eventHandler
window.eventHandler = function(workspace, window, e1, ...)
	if e1 == "double_touch" then
		setUIHidden(not panel.hidden)
		workspace:draw()
	elseif e1 == "touch" or e1 == "key_down" then
		if slideShowDeadline then
			setUIHidden(false)
			slideShowDelay, slideShowDeadline = nil, nil

			workspace:draw()
		end
	else
		if slideShowDelay and computer.uptime() > slideShowDeadline then
			loadIncremented(1)
			workspace:draw()

			updateSlideshowDeadline()
		end
	end

	overrideWindowEventHandler(workspace, window, e1, ...)
end

--------------------------------------------------------------------------------

window.onResize(window.width, window.height)

files = fs.list(currentDir)

local i, extension = 1
while i <= #files do
	extension = fs.extension(files[i])

	if extension and extension:lower() == ".pic" then
		files[i] = currentDir .. files[i]

		if args and args[1] == files[i] then
			fileIndex = i
		end

		i = i + 1
	else
		table.remove(files, i)
	end
end

if #files == 0 then
	panel.hidden = true
	panelContainer.hidden = true
else
	loadImage()
end

workspace:draw()
