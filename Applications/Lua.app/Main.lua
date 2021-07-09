
local GUI = require("GUI")
local system = require("System")
local screen = require("Screen")
local text = require("Text")

---------------------------------------------------------------------------------

local HISTORY_LIMIT = 100

local workspace, window, menu = system.addWindow(GUI.filledWindow(1, 1, 90, 25, 0xE1E1E1))

local lines = {
	{ text = (computer.getArchitecture and computer.getArchitecture() or "Lua 5.2") .. " Copyright (C) 1994-2019 Lua.org, PUC-Rio", color = 0x696969 },
	{ text = "Type a statement and hit Enter to evaluate it", color = 0x969696 },
	{ text = "Prefix an expression with \"=\" to show its value", color = 0x969696 },
	"\t",
}

local treePanel = window:addChild(GUI.panel(1, 1, 22, 3, 0x2D2D2D))
local tree = window:addChild(GUI.tree(1, 4, treePanel.width, 1, 0x2D2D2D, 0xD2D2D2, 0x878787, 0x696969, 0xE1E1E1, 0x2D2D2D, 0x696969, 0x696969, 0x4B4B4B, 0x696969, GUI.IO_MODE_BOTH, GUI.IO_MODE_BOTH))

local textBox = window:addChild(GUI.textBox(1, 2, 1, 1, nil, 0x3C3C3C, lines, 1, 0, 0, true))
textBox.passScreenEvents = true

local input = window:addChild(GUI.input(1, 1, 1, 3, 0xD2D2D2, 0x3C3C3C, 0x969696, 0xD2D2D2, 0x3C3C3C, "", "Type statement here"))
local lastInput = input.text
input.historyEnabled = true

-- input.textDrawMethod = function(x, y, color, text)
-- 	if text == input.placeholderText then
-- 		screen.drawText(x, y, color, text)
-- 	else
-- 		GUI.highlightString(x, y, 1, 2, GUI.LUA_SYNTAX_PATTERNS, GUI.LUA_SYNTAX_COLOR_SCHEME, text)
-- 	end
-- end

---------------------------------------------------------------------------------

local function add(color, text)
	if color then
		table.insert(lines, {
			text = text,
			color = color,
		})
	else
		table.insert(lines, text)
	end

	if #lines > HISTORY_LIMIT then
		table.remove(lines, 1)
	end
end

local function addMultiple(color, ...)
	local args = {...}
	for i = 1, #args do
		if type(args[i]) == "table" then
			args[i] = text.serialize(args[i], true, "  ", 4)
		else
			args[i] = tostring(args[i])
		end
	end

	for part in table.concat(args, ", "):gmatch("[^\r\n]+") do
		add(color, part)
	end

	textBox:scrollToEnd()
end

local function addPrint(...)
	addMultiple(nil, ...)
end

local function addError(...)
	addMultiple(0x880000, ...)
end

local sandbox = {}

for key, value in pairs(_G) do
	sandbox[key] = value
end

sandbox.print = function(...)
	addPrint(...)
	workspace:draw()
end

local function updateTree()
	local function updateRecursively(t, definitionName, offset)
		local list = {}
		for key in pairs(t) do
			table.insert(list, key)
		end

		local i, expandables = 1, {}
		while i <= #list do
			if type(t[list[i]]) == "table" then
				table.insert(expandables, list[i])
				table.remove(list, i)
			else
				i = i + 1
			end
		end

		table.sort(expandables, function(a, b) return unicode.lower(tostring(a)) < unicode.lower(tostring(b)) end)
		table.sort(list, function(a, b) return unicode.lower(tostring(a)) < unicode.lower(tostring(b)) end)

		for i = 1, #expandables do
			local definition = definitionName .. expandables[i] .. "."

			tree:addItem(
				tostring(expandables[i]),
				definition,
				offset,
				true
			)

			if tree.expandedItems[definition] then
				updateRecursively(t[expandables[i]], definition, offset + 2)
			end
		end

		for i = 1, #list do
			tree:addItem(
				tostring(list[i]),
				definitionName .. list[i] .. "()",
				offset,
				false
			)
		end
	end

	tree.items = {}
	updateRecursively(sandbox, "", 1)
end

tree.onItemExpanded = function()
	updateTree()
end

tree.onItemSelected = function()
	input.text = lastInput .. tree.selectedItem
	workspace:draw()
end

input.onKeyDown = function(workspace, input, e1, e2, e3, e4)
	if e4 == 28 then
		local text = input.text:match("^[%s%t]+(.)") or input.text	
		input.text = ""
		lastInput = ""

		add(0x969696, "> " .. text)

		local pizda = text:match("^=+(.+)")
		if pizda then
			text = "return " .. pizda
		end

		local result, reason = load(text, "=lua", "t", sandbox)
		if result then
			result = {xpcall(result, debug.traceback)}
			
			if result[1] then
				if #result > 1 then
					addPrint(table.unpack(result, 2))
				end
			else
				addError(table.unpack(result, 2))
			end
		else
			addError(reason)
		end

		workspace:draw()
	else
		lastInput = input.text
	end
end

input.onInputFinished = function()	
	
end

window.onResize = function(width, height)
	window.backgroundPanel.localX = tree.width + 1
	window.backgroundPanel.width = width - tree.width
	window.backgroundPanel.height = height - 3

	textBox.localX = window.backgroundPanel.localX + 1
	textBox.width = window.backgroundPanel.width - 2
	textBox.height = window.backgroundPanel.height - 2

	tree.height = height - 3

	input.localX = window.backgroundPanel.localX
	input.localY = height - input.height + 1
	input.width = window.backgroundPanel.width
end


---------------------------------------------------------------------------------

updateTree()
window.actionButtons:moveToFront()
window:resize(window.width, window.height)
workspace:draw()
