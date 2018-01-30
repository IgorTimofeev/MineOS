
local component = require("component")
local buffer = require("doubleBuffering")
local event = require("event")
local color = require("color")
local unicode = require("unicode")
local GUI = require("GUI")
local MineOSCore = require("MineOSCore")

--------------------------------------------------------------------------------------------

local cells = {}
for y = 1, 9 do
	cells[y] = {}
	for x = 1, 9 do
		cells[y][x] = {value = nil, variants = {}}
	end
end

--------------------------------------------------------------------------------------------

local function getCellVariants(xCell, yCell)
	for i = 1, 9 do
		cells[yCell][xCell].variants[i] = true
	end

	for y = 1, 9 do
		if y ~= yCell and cells[y][xCell].value then
			cells[yCell][xCell].variants[cells[y][xCell].value] = false
		end
	end

	for x = 1, 9 do
		if x ~= xCell and cells[yCell][x].value then
			cells[yCell][xCell].variants[cells[yCell][x].value] = false
		end
	end

	local xCellGroup, yCellGroup = math.ceil(xCell / 3) * 3, math.ceil(yCell / 3) * 3
	for y = yCellGroup - 2, yCellGroup do
		for x = xCellGroup - 2, xCellGroup do
			if x ~= xCell and y ~= yCell and cells[y][x].value then
				cells[yCell][xCell].variants[cells[y][x].value] = false
			end
		end
	end
end

local function getAllVariants()
	for y = 1, 9 do
		for x = 1, 9 do
			getCellVariants(x, y)
		end
	end
end

local function drawVerticalLine(x, y, height, color)
	for i = y, y + height - 1 do
		buffer.text(x, i, color, "│")
	end
end

local function drawHorizontalLine(x, y, width, color)
	buffer.text(x, y, color, string.rep("─", width))
end

--------------------------------------------------------------------------------------------

local mainContainer, window = MineOSCore.addWindow(GUI.filledWindow(1, 1, 72, 36, 0xEEEEEE))

local sudoku = window:addChild(GUI.object(1, 2, 72, 36))
sudoku.draw = function(sudoku)
	local x, y = sudoku.x + 2, sudoku.y + 1
	for i = 1, 8 do
		drawVerticalLine(x, sudoku.y, sudoku.height, 0x0)
		x = x + 3
	end
	for i = 1, 8 do
		drawHorizontalLine(sudoku.x, y, sudoku.width, 0x0)
		y = y + 2
	end
end