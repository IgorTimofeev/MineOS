
local GUI = require("GUI")
local system = require("System")
local screen = require("Screen")
local text = require("Text")

---------------------------------------------------------------------------------

local workspace, window, menu = system.addWindow(GUI.filledWindow(1, 1, 82, 28, 0x000000, 0.3))

local display = window:addChild(GUI.object(2, 4, 1, 1))
local lines = {}

display.draw = function(display)
	if #lines == 0 then
		return
	end

	local y = display.y + display.height - 1
	
	for i = #lines, math.max(#lines - display.height, 1), -1 do
		screen.drawText(display.x, y, 0xFFFFFF, lines[i])
		y = y - 1
	end
end

display.eventHandler = function(workspace, display, e1, ...)
	if e1 then
		local wrappedLines = text.wrap(table.concat({e1, ...}, " "), display.width)

		for i = 1, #wrappedLines do
			local line = wrappedLines[i]:gsub(" ", "   ")
			table.insert(lines, line)

			if #lines > display.height then
				table.remove(lines, 1)
			end
		end

		workspace:draw()
	end
end

window.onResize = function(newWidth, newHeight)
	window.backgroundPanel.width, window.backgroundPanel.height = newWidth, newHeight
	display.width, display.height = newWidth - 2, newHeight - 4
end

---------------------------------------------------------------------------------

window.onResize(window.width, window.height)
workspace:draw()