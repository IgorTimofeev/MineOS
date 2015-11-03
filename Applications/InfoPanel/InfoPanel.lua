local ecs = require("ECSAPI")
local fs = require("filesystem")
local gpu = require("component").gpu

--------------------------------------------------------------------------------------------------------------

local colors = {
	background = 0x262626,
	leftBar = 0xEEEEEE,
	leftBarText = 0x262626,
	text = 0xFFFFFF,
}

local xSize, ySize = gpu.getResolution()
local leftBarWidth = 20
local fileList
local currentFile = 1
local currentLine = 1
local pathToInfoPanel = "InfoPanel"

--------------------------------------------------------------------------------------------------------------

local function loadFile(number)

end

local function getFileList()
	fs.makeDirectory(pathToInfoPanel)
	fileList = ecs.getFileList(pathToInfoPanel)
end

local function drawLeftBar()
	ecs.square(1, 1, leftBarWidth, ySize, colors.leftBar)
	gpu.setForeground(colors.leftBarText)
	for i = 1, #fileList do
		local text = ecs.stringLimit("end", fileList[i], leftBarWidth - 2)
		if i == currentFile then
			ecs.square(1, i, leftBarWidth, 1, ecs.colors.blue)
			ecs.colorText(2, i, 0xFFFFFF, text)
			gpu.setForeground(colors.leftBarText)
			gpu.setBackground(colors.leftBar)
		else
			gpu.set(2, i, text)
		end
	end
end

local function drawMain()
	local text = {}
	local file = io.open(pathToInfoPanel .. "/" .. fileList[currentFile], "r")
	for line in file:lines() do
		table.insert(text, line)
	end
	file:close()

	local xPos, yPos = leftBarWidth + 1, 1
	ecs.square(xPos, yPos, xSize, ySize, colors.background)

	xPos = xPos + 2
	yPos = yPos + 1

	gpu.setForeground(colors.text)
	for i = currentLine, currentLine + (ySize - 2) do
		if text[i] then
			ecs.smartText(xPos, yPos, text[i])
			yPos = yPos + 1
		end
	end

end

--------------------------------------------------------------------------------------------------------------

getFileList()
drawLeftBar()
drawMain()




