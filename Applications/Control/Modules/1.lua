
local args = {...}
local mainContainer, window, localization = args[1], args[2], args[3]

require("advancedLua")
local component = require("component")
local computer = require("computer")
local GUI = require("GUI")
local buffer = require("doubleBuffering")
local image = require("image")
local MineOSPaths = require("MineOSPaths")
local MineOSInterface = require("MineOSInterface")
local unicode = require("unicode")
local syntax = require("syntax")

----------------------------------------------------------------------------------------------------------------

local module = {}
module.name = localization.moduleLua

----------------------------------------------------------------------------------------------------------------

module.onTouch = function()
	window.contentContainer:deleteChildren()

	_G.component = require("component")
	_G.computer = require("computer")

	local textBox = window.contentContainer:addChild(GUI.textBox(1, 1, window.contentContainer.width, window.contentContainer.height - 3, nil, 0x444444, localization.luaInfo, 1, 2, 1))
	textBox.scrollBarEnabled = true

	local placeholder = localization.luaType
	local input = window.contentContainer:addChild(GUI.input(1, window.contentContainer.height - 2, window.contentContainer.width, 3, 0x2D2D2D, 0xE1E1E1, 0x666666, 0x2D2D2D, 0xE1E1E1, "", placeholder, true))
	
	input.textDrawMethod = function(x, y, color, text)
		if text == placeholder then
			buffer.text(x, y, color, text)
		else
			syntax.highlightString(x, y, text, 2)
		end
	end

	local function add(data, color)
		for line in data:gmatch("[^\n]+") do
			local wrappedLine = string.wrap(line, textBox.textWidth)
			for i = 1, #wrappedLine do
				table.insert(textBox.lines, color and {color = color, text = wrappedLine[i]} or wrappedLine[i])
			end
		end

		textBox:scrollToEnd()
		-- local abc = " "; for i = 1, 30 do abc = abc .. "p " end; print(abc)
	end

	input.historyEnabled = true

	input.autoComplete.colors.default.background = 0x4B4B4B
	input.autoComplete.colors.default.text = 0xC3C3C3
	input.autoComplete.colors.default.textMatch = 0xFFFFFF
	input.autoComplete.colors.selected.background = 0x777777
	input.autoComplete.colors.selected.text = 0xD2D2D2
	input.autoComplete.colors.selected.textMatch = 0xFFFFFF
	input.autoComplete.scrollBar.colors.background = 0x666666
	input.autoComplete.scrollBar.colors.foreground = 0xAAAAAA

	input.autoCompleteVerticalAlignment = GUI.alignment.vertical.top
	input.autoCompleteEnabled = true
	input.autoCompleteMatchMethod = function()
		local inputTextLength = unicode.len(input.text)
		local left, right = 1, inputTextLength
		for i = input.cursorPosition - 1, 1, -1 do
			if not unicode.sub(input.text, i, i):match("[%w%_%.]+") then
				left = i + 1
				break
			end
		end
		for i = input.cursorPosition, inputTextLength do
			if not unicode.sub(input.text, i, i):match("[%w%_%.]+") then
				right = i - 1
				break
			end
		end
		local cykaText = unicode.sub(input.text, left, right)

		local array = {}
		local t = _G
		if cykaText:match("^[%w%_%.]+$") then
			local words = {}
			for word in cykaText:gmatch("[^%.]+") do
				table.insert(words, word)
			end
			local dotInEnd = unicode.sub(cykaText, -1, -1) == "."
			local wordCount = #words - (dotInEnd and 0 or 1)
			
			for i = 1, wordCount do
				if t[words[i]] and type(t[words[i]]) == "table" then
					t = t[words[i]]
				else
					input.autoComplete:clear()
					return
				end
			end

			input.autoComplete.resultLeft = unicode.sub(input.text, 1, left - 1)
			if wordCount > 0 then
				input.autoComplete.resultLeft = input.autoComplete.resultLeft .. table.concat(words, ".", 1, wordCount) .. "."
			end
			input.autoComplete.resultRight = unicode.sub(input.text, right + 1, -1)

			if dotInEnd then
				for key, value in pairs(t) do
					table.insert(array, tostring(key))
				end
				input.autoComplete:match(array)
			else
				for key, value in pairs(t) do
					table.insert(array, tostring(key))
				end
				input.autoComplete:match(array, words[#words])
			end
		elseif input.text == "" then
			input.autoComplete.resultLeft = ""
			input.autoComplete.resultRight = ""
			for key, value in pairs(t) do
				table.insert(array, tostring(key))
			end
			input.autoComplete:match(array)
		else
			input.autoComplete:clear()
		end
	end

	input.autoComplete.onItemSelected = function()
		input.text = input.autoComplete.resultLeft .. input.autoComplete.items[input.autoComplete.selectedItem]
		input:setCursorPosition(unicode.len(input.text) + 1)
		input.text = input.text .. input.autoComplete.resultRight
		
		if input.autoCompleteEnabled then
			input.autoCompleteMatchMethod()
		end

		mainContainer:drawOnScreen()
	end

	input.onInputFinished = function()
		if input.text:len() > 0 then
			local oldPrint = print
			
			print = function(...)
				local args = {...}
				for i = 1, #args do
					if type(args[i]) == "table" then
						args[i] = table.toString(args[i], true, 2, false, 2)
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
				local data = {xpcall(result, debug.traceback())}
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