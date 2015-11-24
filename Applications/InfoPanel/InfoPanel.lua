local ecs = require("ECSAPI")
local xml = require("xmlParser")
local image = require("image")
local event = require("event")
local unicode = require("unicode")
local fs = require("filesystem")
local gpu = require("component").gpu

------------------------------------------------------------------------------------------------------------------

local config = {
	scale = 0.63,
	leftBarWidth = 20,
	scrollSpeed = 6,
	pathToInfoPanelFolder = "MineOS/System/InfoPanel/",
	colors = {
		leftBar = 0xEEEEEE,
		leftBarText = 0x262626,
		leftBarSelection = 0x00C6FF,
		leftBarSelectionText = 0xFFFFFF,
		scrollbarBack = 0xEEEEEE,
		scrollbarPipe = 0x3366CC,
		background = 0x262626,
		text = 0xFFFFFF,
	},
}

local xOld, yOld = gpu.getResolution()
ecs.setScale(config.scale)
local xSize, ySize = gpu.getResolution()

fs.makeDirectory(config.pathToInfoPanelFolder)
local currentFile = 1
local fileList
local stroki = {}
local currentString = 1
local stringsHeightLimit = ySize - 2
local stringsWidthLimit = xSize - config.leftBarWidth - 4

------------------------------------------------------------------------------------------------------------------

local obj = {}
local function newObj(class, name, ...)
	obj[class] = obj[class] or {}
	obj[class][name] = {...}
end

local function drawLeftBar()
	--ecs.square(1, 1, config.leftBarWidth, ySize, config.colors.leftBar)
	fileList = ecs.getFileList(config.pathToInfoPanelFolder)
	obj["Files"] = {}
	local yPos = 1, 1
	for i = 1, #fileList do
		if i == currentFile then
			newObj("Files", i, ecs.drawButton(1, yPos, config.leftBarWidth, 3, ecs.hideFileFormat(fileList[i]), config.colors.leftBarSelection, config.colors.leftBarSelectionText))
		else
			if i % 2 == 0 then
				newObj("Files", i, ecs.drawButton(1, yPos, config.leftBarWidth, 3, ecs.stringLimit("end", fileList[i], config.leftBarWidth - 2), config.colors.leftBar, config.colors.leftBarText))
			else
				newObj("Files", i, ecs.drawButton(1, yPos, config.leftBarWidth, 3, ecs.stringLimit("end", fileList[i], config.leftBarWidth - 2), config.colors.leftBar - 0x111111, config.colors.leftBarText))
			end
		end
		yPos = yPos + 3
	end
	ecs.square(1, yPos, config.leftBarWidth, ySize - yPos + 1, config.colors.leftBar)
end

local function loadFile()
	currentString = 1
	stroki = {}
	local file = io.open(config.pathToInfoPanelFolder .. fileList[currentFile], "r")
	for line in file:lines() do table.insert(stroki, xml.collect(line)) end
	file:close()
end

local function drawMain()
	local x, y = config.leftBarWidth + 3, 2
	local xPos, yPos = x, y

	ecs.square(xPos, yPos, xSize - config.leftBarWidth - 5, ySize, config.colors.background)
	gpu.setForeground(config.colors.text)

	for line = currentString, (stringsHeightLimit + currentString - 1) do
		if stroki[line] then
			for i = 1, #stroki[line] do
				if type(stroki[line][i]) == "table" then
					if stroki[line][i].label == "color" then
						gpu.setForeground(tonumber(stroki[line][i][1]))
					elseif stroki[line][i].label == "image" then
						local bg, fg = gpu.getBackground(), gpu.getForeground()
						local picture = image.load(stroki[line][i][1])
						image.draw(xPos, yPos, picture)
						yPos = yPos + picture.height - 1
						gpu.setForeground(fg)
						gpu.setBackground(bg)
					end
				else
					gpu.set(xPos, yPos, stroki[line][i])
					xPos = xPos + unicode.len(stroki[line][i])
				end
			end
			yPos = yPos + 1
			xPos = x
		else
			break
		end
	end

end

local function drawScrollBar()
	local name
	name = "⬆"; newObj("Scroll", name, ecs.drawButton(xSize - 2, 1, 3, 3, name, config.colors.leftBarSelection, config.colors.leftBarSelectionText))
	name = "⬇"; newObj("Scroll", name, ecs.drawButton(xSize - 2, ySize - 2, 3, 3, name, config.colors.leftBarSelection, config.colors.leftBarSelectionText))

	ecs.srollBar(xSize - 2, 4, 3, ySize - 6, #stroki, currentString, config.colors.scrollbarBack, config.colors.scrollbarPipe)
end

------------------------------------------------------------------------------------------------------------------

ecs.prepareToExit()
drawLeftBar()
loadFile()
drawMain()
drawScrollBar()

while true do
	local e = {event.pull()}
	if e[1] == "touch" then
		for key in pairs(obj["Files"]) do
			if ecs.clickedAtArea(e[3], e[4], obj["Files"][key][1], obj["Files"][key][2], obj["Files"][key][3], obj["Files"][key][4]) then
				currentFile = key
				loadFile()
				drawLeftBar()
				drawMain()
				drawScrollBar()
				break
			end
		end

		for key in pairs(obj["Scroll"]) do
			if ecs.clickedAtArea(e[3], e[4], obj["Scroll"][key][1], obj["Scroll"][key][2], obj["Scroll"][key][3], obj["Scroll"][key][4]) then
				ecs.drawButton(obj["Scroll"][key][1], obj["Scroll"][key][2], 3, 3, key, config.colors.leftBarSelectionText, config.colors.leftBarSelection)
				os.sleep(0.2)
				ecs.drawButton(obj["Scroll"][key][1], obj["Scroll"][key][2], 3, 3, key, config.colors.leftBarSelection, config.colors.leftBarSelectionText)

				if key == "⬆" then
					if currentString > config.scrollSpeed then
						currentString = currentString - config.scrollSpeed
						drawMain()
						drawScrollBar()
					end
				else
					if currentString < (#stroki - config.scrollSpeed + 1) then
						currentString = currentString + config.scrollSpeed
						drawMain()
						drawScrollBar()
					end
				end

				break
			end
		end

	elseif e[1] == "key_down" then
		if e[4] == 28 then
			gpu.setResolution(xOld, yOld)
			ecs.prepareToExit()
			return
		end
	end
end













