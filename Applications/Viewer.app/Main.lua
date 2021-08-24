local GUI = require("GUI")
local system = require("System")
local fs = require("Filesystem")
local image = require("Image")
local text = require("Text")
local screen = require("Screen")

local args, options = system.parseArguments(...)
local currentDir, dirFiles = '/Pictures/'
local currentNum = 1

local workspace, window, menu = system.addWindow(GUI.titledWindow(1, 1, 70, 30, 'Viewer', true))

local locale = system.getCurrentScriptLocalization()

local iconsPath = fs.path(system.getCurrentScript())..'Icons/'

local arrowLeftPic = image.load(iconsPath .. "arrowLeft.pic")
local arrowRightPic = image.load(iconsPath .. "arrowRight.pic")
local playPic = image.load(iconsPath .. "play.pic")
local setWallpaperPic = image.load(iconsPath.."setWallpaper.pic")

local layout = window:addChild(GUI.layout(1, 2, window.width, window.height, 1, 1))

local panel = window:addChild(GUI.panel(1, window.height-5, window.width, 6, 0x000000, 0.5))
local panelLay = window:addChild(GUI.layout(1, window.height-5, window.width, 6, 4, 1))
local imageObj

local function scanDir()
	dirFiles = {}
	for lab, file in pairs(fs.list(currentDir)) do
		if lab ~= 'n' and string.lower(fs.extension(file) or '') == ".pic" then
			table.insert(dirFiles, currentDir .. file)
		end
	end
end

local function loadImg()
	if imageObj then imageObj:remove() end
	local newImg, ifErr = image.load(dirFiles[currentNum])
	if not newImg then GUI.alert(ifErr) window:remove() return end
	imageObj = layout:addChild(GUI.image(1, 1, newImg))
	window.titleLabel.text = 'Viewer - '..text.limit(dirFiles[currentNum], 30, "center")
	workspace:draw()
end

local arrowLeft = panelLay:addChild(GUI.image(1, 1, arrowLeftPic))
arrowLeft.eventHandler = function(_, _, typ)
	if typ == 'touch' then
		currentNum = currentNum == 1 and #dirFiles or currentNum-1
		loadImg()
	end
end

local play = panelLay:addChild(GUI.image(2, 1, playPic))
play.eventHandler = function(_, _, typ)
	if typ == 'touch' then
		local container = GUI.addBackgroundContainer(workspace, true, true, locale.slideShow)
		container.panel.eventHandler = nil
		container.layout:setSpacing(1, 1, 2)
		
		local delay = container.layout:addChild(GUI.slider(1, 1, 50, 0x66DB80, 0x0, 0xFFFFFF, 0xFFFFFF, 3, 30, 0, true, locale.delay, locale.seconds))
		delay.roundValues = true
		
		local onFull = container.layout:addChild(GUI.switchAndLabel(1, 1, 27, 8, 0x66DB80, 0x1D1D1D, 0xEEEEEE, 0xFFFFFF, locale.fullScreen..":", false))
		
		local buttonsLay = container.layout:addChild(GUI.layout(1, 1, 30, 7, 1, 1))
		
		buttonsLay:addChild(GUI.button(1, 1, 30, 3, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, locale.start)).onTouch = function()
			local slDelay = delay.value
			if onFull.switch.state then
				local w, h = screen.getResolution()
				local flScr = workspace:addChild(GUI.window(1, 1, w, h))
				flScr:addChild(GUI.panel(1, 1, w, h, 0xFFFFFF))
				local flLay = flScr:addChild(GUI.layout(1, 1, w, h, 1, 1))
				local img = flLay:addChild(GUI.image(1, 1, imageObj.image))
				
	
				flScr.eventHandler = function(_, _, typ)
					if typ == 'touch' or typ == 'key_down' then flScr:remove() loadImg()
					elseif strTim + slDelay <= system.getTime() then
						img:remove()
						currentNum = currentNum == #dirFiles and 1 or currentNum+1
						local newImg, ifErr = image.load(dirFiles[currentNum])
						if not newImg then GUI.alert(ifErr) flScr:remove() window:remove() return end
						img = flLay:addChild(GUI.image(1, 1, newImg))
						strTim = system.getTime()
					end
				end
			else
				panel.hidden = true
				panelLay.hidden = true
				local strTim = system.getTime()
				layout.eventHandler = function(_, _, typ)
					if typ == 'touch' or typ == 'key_down' then 
						layout.eventHandler = nil
						panel.hidden = false
						panelLay.hidden = false
					elseif strTim + slDelay <= system.getTime() then
						currentNum = currentNum == #dirFiles and 1 or currentNum+1
						loadImg()
						strTim = system.getTime()
					end
				end
			end
				
			container:remove()
		end
		
		buttonsLay:addChild(GUI.button(1, 1, 30, 3, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, locale.cancel)).onTouch = function()
			container:remove()
		end
	end
end
panelLay:setPosition(2, 1, play)

local arrowRight = panelLay:addChild(GUI.image(1, 1, arrowRightPic))
arrowRight.eventHandler = function(_, _, typ)
	if typ == 'touch' then
		currentNum = currentNum == #dirFiles and 1 or currentNum+1
		loadImg()
	end
end
panelLay:setPosition(3, 1, arrowRight)

local setWallpaper = panelLay:addChild(GUI.image(1, 1, setWallpaperPic))
setWallpaper.eventHandler = function(_, _, typ)
	if typ == 'touch' then
		local container = GUI.addBackgroundContainer(workspace, true, true, locale.setWallpaper)
		container.panel.eventHandler = nil
		local buttLay = container.layout:addChild(GUI.layout(1, 1, 24, 6, 2, 1))
		
		buttLay:addChild(GUI.button(1, 1, 10, 3, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, locale.yes)).onTouch = function()
			local sets = system.getUserSettings()
			sets.interfaceWallpaperPath = dirFiles[currentNum]
			system.saveUserSettings()
			system.updateWallpaper()
				
			container:remove()
		end
	
		local cancel = buttLay:addChild(GUI.button(1, 1, 10, 3, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, locale.no))
		cancel.onTouch = function()
			container:remove()
		end
		buttLay:setPosition(2, 1, cancel)
	end
end
panelLay:setPosition(4, 1, setWallpaper)

local hsPanel = menu:addItem(locale.hidePanel)
hsPanel.onTouch = function()
	hsPanel.text = panel.hidden and locale.hidePanel or locale.showPanel
	panel.hidden = not panel.hidden
	panelLay.hidden = not panelLay.hidden
end

local flScreen = menu:addItem(locale.fullScreen)
flScreen.onTouch = function()
	local w, h = screen.getResolution()
	local flScr = workspace:addChild(GUI.window(1, 1, w, h))
	flScr:addChild(GUI.panel(1, 1, w, h, 0xFFFFFF))
	local flLay = flScr:addChild(GUI.layout(1, 1, w, h, 1, 1))
	flLay:addChild(GUI.image(1, 1, imageObj.image))
	
	flScr.eventHandler = function(_, _, typ)
		if typ == 'touch' or typ == 'key_down' then flScr:remove() end
	end
end

window.onResize = function(newWidth, newHeight)
	window.backgroundPanel.width, window.backgroundPanel.height = newWidth, newHeight
	layout.width, layout.height = newWidth, newHeight
	window.titlePanel.width = newWidth
	window.titleLabel.width = newWidth
	panel.width, panel.localY = newWidth, newHeight-5
	panelLay.width, panelLay.localY = newWidth, newHeight-5
end

if (options.o or options.open) and args[1] then
	currentDir = fs.path(args[1])
	scanDir()
	for i=1, #dirFiles do
		if dirFiles[i] == args[1] then currentNum = i loadImg() break end
	end
else
	scanDir()
	if #dirFiles == 0 then
		layout:addChild(GUI.text(1, 1, 0x4B4B4B, locale.noPictures))
		panel.hidden = true
		panelLay.hidden = true
		hsPanel.disabled = true
		flScreen.disabled = true
	else
		loadImg()
	end
end

workspace:draw()
