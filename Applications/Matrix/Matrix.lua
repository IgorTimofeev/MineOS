

local event = require("event")
local gpu = require("component").gpu
if not _G.buffer then _G.buffer = require("doubleBuffering") end
local ecs = require("ECSAPI")

local xOld, yOld = gpu.getResolution()
local xSize, ySize = 80, 25
gpu.setResolution(xSize, ySize)

local lengthOfLine = 14
local countOfLinesToGenerate = 5
local counter = 0
local speed = 0.08 

local lines = {
	{x = 2, y = 3},
}

local chars = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "%", "!", "@", "#", ":", "<", ">", "&", "?", "~", "/", "+", "=", "-", "*"}

local function generateLines()
	for i = 1, countOfLinesToGenerate do
		table.insert(lines, {x = math.random(1, xSize), y = 1})
	end
end

local function moveLines()
	local i = 1
	while i <= #lines do
		lines[i].y = lines[i].y + 1
		if lines[i].y - lengthOfLine > ySize then table.remove(lines, i) else i = i + 1 end
	end
end

local function showLine(lineNumber)
	local baseColor = 0x00FF00
	local yPos = lines[lineNumber].y
	for i = 1, lengthOfLine do
		local symbol = chars[math.random(1, #chars)]

		if i == 1 then
			buffer.set(lines[lineNumber].x, yPos, 0x000000, 0xFFFFFF, symbol)
		else
			buffer.set(lines[lineNumber].x, yPos, 0x000000, baseColor, symbol)
			baseColor = baseColor - 0x001100
		end

		yPos = yPos - 1
	end
	buffer.set(lines[lineNumber].x, yPos, 0x000000, 0x000000, " ")
end

local function showLines()
	for i = 1, #lines do
		showLine(i)
	end
end

local counter = 0
local function matrix()
	showLines()
	moveLines()
	counter = counter + 1
	if counter >= 5 then counter = 0; generateLines() end
	buffer.draw()
end

buffer.square(1, 1, xSize, ySize, 0x000000, 0x000000, " ")
buffer.draw()

local timerID = event.timer(speed, matrix, math.huge)

ecs.wait()
event.cancel(timerID)
gpu.setResolution(xOld, yOld)

buffer.square(1, 1, xSize, ySize, 0x000000, 0x000000, " ")
buffer.draw()




