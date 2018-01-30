
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
	if cells[yCell][xCell].value then
		cells[yCell][xCell].variants[cells[yCell][xCell].value] = false
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

local function generate(count)
	for i = 1, count do
		local indexedVariants, xCell, yCell = {}
		repeat
			xCell, yCell = math.random(1, 9), math.random(1, 9)
			for key, value in pairs(cells[yCell][xCell].variants) do
				if value == true then
					table.insert(indexedVariants, key)
				end
			end
		until cells[yCell][xCell].value == nil and #indexedVariants > 1
		

		cells[yCell][xCell].value = indexedVariants[math.random(1, #indexedVariants)]
		getAllVariants()
	end
end

--------------------------------------------------------------------------------------------

local mainContainer, window = MineOSCore.addWindow(GUI.filledWindow(1, 1, 71, 36, 0xEEEEEE))

local sudoku = window:addChild(GUI.object(1, 2, 71, 36))
sudoku.colors = {
	lines = {
		thin = 0xAAAAAA,
		fat = 0x000000
	}
}
sudoku.draw = function(sudoku)
	local x, y = sudoku.x + 7, sudoku.y + 3
	
	for i = 1, 8 do
		buffer.text(sudoku.x, y, i % 3 == 0 and sudoku.colors.lines.fat or sudoku.colors.lines.thin, string.rep("─", sudoku.width))
		y = y + 4
	end

	for i = 1, 8 do
		for j = sudoku.y, sudoku.y + sudoku.height - 1 do
			local background, foreground, symbol = buffer.get(x, j)
			if symbol == "─" then
				symbol = "┼"
			else
				symbol = "│"
			end

			buffer.set(x, j, background, i % 3 == 0 and sudoku.colors.lines.fat or sudoku.colors.lines.thin, symbol)
		end

		x = x + 8
	end

	x, y = sudoku.x, sudoku.y
	for yCell = 1, 9 do
		for xCell = 1, 9 do
			local xCyka, yCyka = x, y
			for key, value in pairs(cells[yCell][xCell].variants) do
				if value then
					buffer.text(xCyka, yCyka, 0xBBBBBB, tostring(key))
				end

				xCyka = xCyka + 2
				if xCyka - x > 5 then
					xCyka, yCyka = x, yCyka + 1
				end
			end

			if cells[yCell][xCell].value then
				buffer.text(x + 3, y + 1, 0x880000, tostring(cells[yCell][xCell].value))
			end

			x = x + 8
		end

		x, y = sudoku.x, y + 4
	end
end

-- sudoku.eventHandler = function(mainContainer, object, eventData)
-- 	if eventData[1] == "touch" then
-- 		GUI.error(eventData)
-- 	end
-- end

--------------------------------------------------------------------------------------------

getAllVariants()
generate(50)