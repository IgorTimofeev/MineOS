
local args = {...}
local workspace, window, localization = args[1], args[2], args[3]

local GUI = require("GUI")
local screen = require("Screen")
local image = require("Image")
local paths = require("Paths")
local text = require("Text")

----------------------------------------------------------------------------------------------------------------

local module = {}
module.name = localization.moduleLua

----------------------------------------------------------------------------------------------------------------

module.onTouch = function()
	window.contentContainer:removeChildren()

	local textBox = window.contentContainer:addChild(GUI.textBox(1, 1, window.contentContainer.width, window.contentContainer.height - 3, nil, 0x444444, localization.luaInfo, 1, 2, 1))
	textBox.scrollBarEnabled = true

	local placeholder = localization.luaType
	local input = window.contentContainer:addChild(GUI.input(1, window.contentContainer.height - 2, window.contentContainer.width, 3, 0x2D2D2D, 0xE1E1E1, 0x666666, 0x2D2D2D, 0xE1E1E1, "", placeholder, true))
	
	input.textDrawMethod = function(x, y, color, text)
		if text == placeholder then
			screen.drawText(x, y, color, text)
		else
			GUI.highlightString(x, y, 1, 2, GUI.LUA_SYNTAX_PATTERNS, GUI.LUA_SYNTAX_COLOR_SCHEME, text)
		end
	end

	local function add(data, color)
		for line in data:gmatch("[^\n]+") do
			local wrappedLine = text.wrap(line, textBox.textWidth)
			for i = 1, #wrappedLine do
				table.insert(textBox.lines, color and {color = color, text = wrappedLine[i]} or wrappedLine[i])
			end
		end

		textBox:scrollToEnd()
		-- local abc = " "; for i = 1, 30 do abc = abc .. "p " end; print(abc)
	end

	input.historyEnabled = true
	
	input.onInputFinished = function()
		if input.text:len() > 0 then
			local oldPrint = print
			
			print = function(...)
				local args = {...}
				for i = 1, #args do
					if type(args[i]) == "table" then
						args[i] = text.serialize(args[i], true, 2, false, 2)
					else
						args[i] = tostring(args[i])
					end
				end
				add(table.concat(args, " "))
			end

			add("> " .. input.text, 0xAAAAAA)

			if input.text:match("^%=") then
				input.text = "return " .. unicode.sub(input.text, 2, -1)
			end

			local result, reason = load(input.text)
			if result then
				local data = {xpcall(result, debug.traceback)}
				if data[1] then
					print(table.unpack(data, 2))
				else
					add(tostring(data[2]), 0x880000)
				end
			else
				add(tostring(reason), 0x880000)
			end

			print = oldPrint

			input.text = ""
		end
	end
end

----------------------------------------------------------------------------------------------------------------

return module