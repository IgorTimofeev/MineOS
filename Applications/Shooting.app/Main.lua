
local GUI = require("GUI")
local system = require("System")
local screen = require("Screen")
local color = require("Color")
local bigLetters = require("BigLetters")
local color = require("Color")
local system = require("System")

---------------------------------------------------------------------------------

local function drawcircle(x0, y0, radius, color)
	local x = radius - 1
	local y = 0
	local dx = 1
	local dy = 1
	local err = dx - bit32.lshift(radius, 1)

	while x >= y do
		screen.drawSemiPixelLine(x0 - x, y0 + y, x0 + x, y0 + y, color)
		screen.drawSemiPixelLine(x0 - y, y0 + x, x0 + y, y0 + x, color)
		screen.drawSemiPixelLine(x0 - x, y0 - y, x0 + x, y0 - y, color)
		screen.drawSemiPixelLine(x0 - y, y0 - x, x0 + y, y0 - x, color)

		if err <= 0 then
			y = y + 1
			err = err + dy
			dy = dy + 2
		end

		if err > 0 then
			x = x - 1
			dx = dx + 2
			err = err + dx - bit32.lshift(radius, 1)
		end
	end
end

local radius = 30
local size = radius * 2
local points = {}
local players = {}
local lastPlayer

local workspace, window = system.addWindow(GUI.filledWindow(1, 1, 104, 34, 0x1E1E1E))

local layout = window:addChild(GUI.layout(1, 1, window.width, window.height, 1, 1))
layout:setDirection(1, 1, GUI.DIRECTION_HORIZONTAL)
layout:setSpacing(1, 1, 8)

local circle = layout:addChild(GUI.object(1, 1, size, math.floor(size / 2)))

local function getColor()
	return lastPlayer and players[lastPlayer].color or 0x0092FF
end

circle.draw = function()
	local r, limit = radius, 6
	for i = 1, limit do
		drawcircle(circle.x + radius - 1, circle.y * 2 + radius - 2, r, i == limit and 0xFF4940 or i % 2 == 0 and 0x0 or 0xE1E1E1)
		r = r - 5
	end

	for i = 1, #points do
		screen.drawText(circle.x + points[i][1], circle.y + points[i][2], getColor(), "⬤")
	end
end

local counter = layout:addChild(GUI.object(1, 1, 24, 5))
counter.draw = function()
	local radius = 4
	drawcircle(counter.x + radius, counter.y * 2 + radius, radius, getColor())
	bigLetters.drawText(counter.x + radius * 2 + 4, counter.y, 0xE1E1E1, lastPlayer and tostring(players[lastPlayer].score) or "0")
end

circle.eventHandler = function(workspace, circle, e1, e2, e3, e4, e5, e6)
	if e1 == "touch" then
		lastPlayer = e6
		players[lastPlayer] = players[lastPlayer] or {
			color = color.HSBToInteger(math.random(360), 1, 1),
			score = 0
		}

		players[lastPlayer].score = math.max(0, radius - math.floor(math.sqrt((e3 - (circle.x + radius)) ^ 2 + (e4 * 2 - (circle.y * 2 + radius)) ^ 2)))

		table.insert(points, {e3 - circle.x, e4 - circle.y})
		workspace:draw()
	end
end

window.onResize = function(width, height)
	window.backgroundPanel.width = width
	window.backgroundPanel.height = height

	layout.width = width
	layout.height = height
end

---------------------------------------------------------------------------------

workspace:draw()
