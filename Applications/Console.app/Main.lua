
local GUI = require("GUI")
local system = require("System")
local keyboard = require("Keyboard")
local screen = require("Screen")
local text = require("Text")

---------------------------------------------------------------------------------

local workspace, window, menu = system.addWindow(GUI.filledWindow(1, 1, 82, 28, 0x000000))

local disp = window:addChild(GUI.object(2, 4, 1, 1))
local cursorX, cursorY = 1, 1
local lineFrom = 1
local lines = {}
local input = ""

disp.draw = function(disp)
	local x, y = disp.x, disp.y
	for i = lineFrom, #lines do
		screen.drawText(x, y, 0xFFFFFF, lines[i])
		y = y + 1
	end

	local text = "> " .. input
	screen.drawText(x, y, 0xFFFFFF, text)
	screen.drawText(x + unicode.len(text), y, 0x00A8FF, "┃")
end

window.addLine = function(value)
	local value = text.wrap(value, disp.width)

	for i = 1, #value do
		table.insert(lines, value[i])

		if #lines - lineFrom + 1 > disp.height - 1 then
			lineFrom = lineFrom + 1
		end
	end
end

local overrideWindowEventHandler = window.eventHandler
window.eventHandler = function(workspace, window, ...)
	local e = {...}

	if e[1] == "scroll" then
		lineFrom = lineFrom + (e[5] > 0 and -1 or 1)

		if lineFrom < 1 then
			lineFrom = 1
		elseif lineFrom > #lines then
			lineFrom = #lines
		end

		workspace:draw()
	elseif e[1] == "key_down" and GUI.focusedObject == window then
		-- Return
		if e[4] == 28 then
			window.addLine("> " .. input)
			input = ""
		-- Backspace
		elseif e[4] == 14 then
			input = unicode.sub(input, 1, -2)
		elseif not keyboard.isControl(e[3]) then
			local char = unicode.char(e[3])

			input = input .. char
		end

		workspace:draw()
	end

	overrideWindowEventHandler(workspace, window, ...)
end

local overrideWindowRemove = window.remove
window.remove = function(...)
	system.consoleWindow = nil

	overrideWindowRemove(...)
end

window.onResize = function(newWidth, newHeight)
	window.backgroundPanel.width, window.backgroundPanel.height = newWidth, newHeight
	disp.width, disp.height = newWidth - 2, newHeight - 3
end

---------------------------------------------------------------------------------

system.consoleWindow = window

window.onResize(window.width, window.height)
workspace:draw()