
local ecs = require("ECSAPI")
local image = require("image")
local fs = require("filesystem")
local buffer = require("doubleBuffering")
local unicode = require("unicode")
local event = require("event")


local pathToApplicationResources = "MineOS/Applications/Viewer.app/Resources/"
local currentPath = "MineOS/Pictures/"
local imageList = {}
local currentImage = 1
local showGUI = true
local slideShowInterval = 5
local enableSlideShow = true

local arrowLeftImage = image.load(pathToApplicationResources .. "arrowLeft.pic")
local arrowRightImage = image.load(pathToApplicationResources .. "arrowRight.pic")
local playImage = image.load(pathToApplicationResources .. "play.pic")
local wallpaperImage = image.load("MineOS/System/OS/Icons/Computer.pic")

local obj = {}

buffer.start()

local function loadImageList()
	local fileList = fs.list(currentPath)
	imageList = {}
	for file in fileList do
		if ecs.getFileFormat(file) == ".pic" then
			table.insert(imageList, currentPath .. file)
		end
	end
end

local function drawImage()
	if #imageList > 0 then
		local xImage, yImage = 1, 1   
		local currentLoadedImage = image.load(imageList[currentImage])
		
		if currentLoadedImage.width < buffer.screen.width then xImage = math.floor(buffer.screen.width / 2 - currentLoadedImage.width / 2) end
		if currentLoadedImage.height < buffer.screen.height then yImage = math.floor(buffer.screen.height / 2 - currentLoadedImage.height / 2) end
		
		buffer.image(xImage, yImage, currentLoadedImage)
		currentLoadedImage = nil
	else
		local text = "Изображения в директории \"" .. currentPath .. "\" не найдены"
		buffer.text(math.floor(buffer.screen.width / 2 - unicode.len(text) / 2), math.floor(buffer.screen.height / 2), 0x000000, text)
	end
end

local function multipleButtons(x, y, widthOfButton, heightOfButton, spaceBetweenButtons, ...)
	local buttons = {...}
	local objectsToReturn = {}
	for i = 1, #buttons do
		buffer.button(x, y, widthOfButton, heightOfButton, buttons[i][1], buttons[i][2], buttons[i][3])
		table.insert(objectsToReturn, {x, y, x + widthOfButton - 1, y + heightOfButton - 1})
		x = x + widthOfButton + spaceBetweenButtons
	end
	return objectsToReturn
end

local function drawBottomButtons()
	local y = buffer.screen.height - 4
	local x = math.floor(buffer.screen.width / 2 - 21)

	obj.arrowLeft = {x, y, x + 7, y + 3} 
	buffer.image(x, y, arrowLeftImage); x = x + 10
	obj.play = {x, y, x + 7, y + 3} 
	buffer.image(x, y, playImage); x = x + 10
	obj.arrowRight = {x, y, x + 7, y + 3} 
	buffer.image(x, y, arrowRightImage); x = x + 12
	obj.wallpaper = {x, y, x + 7, y + 3} 
	buffer.image(x, y, wallpaperImage)
end

local function drawGUI()
	if showGUI then
		--Верхний бар
		buffer.square(1, 1, buffer.screen.width, 1, 0xDDDDDD, 0xFFFFFF, " ")
		local text = #imageList > 0 and ecs.stringLimit("start", imageList[currentImage], 40) or "Viewer"
		buffer.text(math.floor(buffer.screen.width / 2 - unicode.len(text) / 2), 1, 0x000000, text)
		buffer.text(2, 1, ecs.colors.red, "⬤")
		buffer.text(5, 1, ecs.colors.orange, "⬤")
		buffer.text(8, 1, ecs.colors.green, "⬤")

		--Нижний бар
		local height = 6
		local transparency = 40
		local y = buffer.screen.height - height + 1
		buffer.square(1, y, buffer.screen.width, height, 0x000000, 0xFFFFFF, " ", transparency)
		-- multipleButtons(math.floor(buffer.screen.width / 2 - 16), y, 7, 3, 2, {0xEEEEEE, 0x262626, "←"}, {0xEEEEEE, 0x262626, "►"}, {0xEEEEEE, 0x262626, "→"}, {0xEEEEEE, 0x262626, "♥"})
		drawBottomButtons()
	end
end

local function drawAll(force)
	buffer.clear(0xFFFFFF)

	drawImage()
	drawGUI()

	buffer.draw(force)
end

local function prevImage()
	currentImage = currentImage - 1
	if currentImage < 1 then currentImage = #imageList end
	drawAll()
end

local function nextImage()
	currentImage = currentImage + 1
	if currentImage > #imageList then currentImage = 1 end
	drawAll()
end

local function slideShowDro4er()
	nextImage()
end

local function enableSlideShowDro4er()
	enableSlideShow = true
	_G.imageViewerSlideShowTimer = event.timer(slideShowInterval, slideShowDro4er, math.huge)
end

local function clicked(x, y, obj)
	if obj and ecs.clickedAtArea(x, y, obj[1], obj[2], obj[3], obj[4]) and #imageList > 0 then
		return true
	end
	return false
end

local function press(x, y)
	buffer.square(x, y, 10, 6, 0x000000, 0xFFFFFF, " ", 60)
	drawBottomButtons()
	buffer.draw()
	os.sleep(0.2)
	drawAll()
end

------------------------------------------------------------------------------------------------------------------------------------------------

local args = {...}

if args[1] == "open" then
	if args[2] then
		currentPath = fs.path(args[2])
		loadImageList()
		for i = 1, #imageList do
			if args[2] == imageList[i] then currentImage = i; break end
		end
	else
		ecs.error("Invalid arguments!")
		return
	end
else
	loadImageList()
end

drawAll()

while true do
	local e = {event.pull()}
	if e[1] == "touch" then

		if enableSlideShow then
			showGUI = true
			enableSlideShow = false
			if _G.imageViewerSlideShowTimer then event.cancel(_G.imageViewerSlideShowTimer) end
			drawAll()
		end

		if clicked(e[3], e[4], obj.arrowLeft) then
			press(obj.arrowLeft[1] - 1, obj.arrowLeft[2] - 1)
			prevImage()
		elseif clicked(e[3], e[4], obj.play) then
			press(obj.play[1] - 1, obj.play[2] - 1)
			showGUI = false
			obj = {}
			enableSlideShowDro4er()
			drawAll()
		elseif clicked(e[3], e[4], obj.arrowRight) then
			press(obj.arrowRight[1] - 1, obj.arrowRight[2] - 1)
			nextImage()
		elseif clicked(e[3], e[4], obj.wallpaper) then
			press(obj.wallpaper[1] - 1, obj.wallpaper[2] - 1)
			buffer.clear(0x262626)
			buffer.draw()
			ecs.createShortCut("MineOS/System/OS/Wallpaper.lnk", imageList[currentImage])
			computer.pushSignal("OSWallpaperChanged")
			return
		elseif (e[3] >= 2 and e[3] <= 3 and e[4] == 1) then
			buffer.text(2, 1, ecs.colors.blue, "⬤")
			buffer.draw()
			os.sleep(0.2)
			buffer.clear(0x262626)
			buffer.draw()
			return
		end
	end
end















