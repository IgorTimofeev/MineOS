local component = require("component")
local event = require("event")
local term = require("term")
local unicode = require("unicode")
local ecs = require("ECSAPI")
local fs = require("filesystem")
local context = require("context")
local computer = require("computer")
local keyboard = require("keyboard")
local image = require("image")

local gpu = component.gpu

------------------------------------------------------------------------------------------------------------------------

local xSize, ySize = gpu.getResolution()

local workPath = ""

local icons = {}
icons["folder"] = image.load("System/OS/Icons/Folder.png")
icons["script"] = image.load("System/OS/Icons/Script.png")

------------------------------------------------------------------------------------------------------------------------

local obj = {}
local function newObj(class, name, ...)
	obj[class] = obj[class] or {}
	obj[class][name] = {...}
end

local function drawIcons()

	local x = 3
	local y = 3

	local widthOfIcon = 12
	local heightOfIcon = 5
	local xSpaceBetweenIcons = 4
	local ySpaceBetweenIcons = 2
	local xCountOfIcons = math.floor(xSize / (widthOfIcon + xSpaceBetweenIcons))
	local yCountOfIcons = math.floor(ySize / (heightOfIcon + ySpaceBetweenIcons))

	local fileList = ecs.getFileList(workPath)

	fileList = ecs.reorganizeFilesAndFolders(fileList)

	local xIcons, yIcons = x, y
	local counter = 1
	for i = 1, yCountOfIcons do
		for j = 1, xCountOfIcons do
			if not fileList[counter] then break end

			--НАЗНАЧЕНИЕ ВЕРНОЙ ИКОНКИ
			local icon = ""
			local path = workPath.."/"..fileList[counter]

			if fs.isDirectory(path) then
				if ecs.getFileFormat(path) == ".app" then
					icon = path .. "/Resources/Icon.png" 
					icons[icon] = image.load(icon)
				else
					icon = "folder"
				end
			else
				icon = "script"
			end

			image.draw(xIcons, yIcons, icons[icon] or icons["script"])

			local text = ecs.stringLimit("end", fileList[counter], widthOfIcon)
			local textPos = xIcons + math.floor(widthOfIcon / 2 - unicode.len(text) / 2) - 2

			ecs.adaptiveText(textPos, yIcons + heightOfIcon, text, 0xffffff)


			xIcons = xIcons + widthOfIcon + xSpaceBetweenIcons

			counter = counter + 1
		end

		xIcons = x
		yIcons = yIcons + heightOfIcon + ySpaceBetweenIcons
	end
end


------------------------------------------------------------------------------------------------------------------------

ecs.clearScreen(0x262626)

drawIcons()
