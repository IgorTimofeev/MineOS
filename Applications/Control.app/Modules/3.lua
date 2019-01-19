
local args = {...}
local workspace, window, localization = args[1], args[2], args[3]

local GUI = require("GUI")
local screen = require("Screen")
local image = require("Image")
local paths = require("Paths")
local text = require("Text")

----------------------------------------------------------------------------------------------------------------

local module = {}
module.name = localization.moduleRAM

----------------------------------------------------------------------------------------------------------------

module.onTouch = function()	
	window.contentContainer:removeChildren()
	
	local cykaPanel = window.contentContainer:addChild(GUI.panel(1, 1, 1, 1, 0xE1E1E1))

	local mainLayout = window.contentContainer:addChild(GUI.layout(1, 1, window.contentContainer.width, window.contentContainer.height, 2, 1))
	mainLayout:setColumnWidth(1, GUI.SIZE_POLICY_RELATIVE, 0.3)
	mainLayout:setColumnWidth(2, GUI.SIZE_POLICY_RELATIVE, 0.7)
	mainLayout:setFitting(1, 1, true, true)
	mainLayout:setFitting(2, 1, true, true)

	local tree = mainLayout:setPosition(1, 1, mainLayout:addChild(GUI.tree(1, 1, 1, 1, 0xE1E1E1, 0x3C3C3C, 0x3C3C3C, 0xAAAAAA, 0x3C3C3C, 0xFFFFFF, 0xBBBBBB, 0xAAAAAA, 0xC3C3C3, 0x444444, GUI.IO_MODE_BOTH, GUI.IO_MODE_FILE)))

	local itemsLayout = mainLayout:setPosition(2, 1, mainLayout:addChild(GUI.layout(1, 1, 1, 1, 1, 2)))
	itemsLayout:setRowHeight(1, GUI.SIZE_POLICY_RELATIVE, 0.6)
	itemsLayout:setRowHeight(2, GUI.SIZE_POLICY_RELATIVE, 0.4)
	itemsLayout:setFitting(1, 1, true, false, 4, 0)
	itemsLayout:setFitting(1, 2, true, true)

	local infoLabel = itemsLayout:setPosition(1, 1, itemsLayout:addChild(GUI.label(1, 1, 1, 1, 0x3C3C3C, "nil")):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP))
	local argumentsInputField = itemsLayout:setPosition(1, 1, itemsLayout:addChild(GUI.input(1, 1, 1, 3, 0xFFFFFF, 0x666666, 0x888888, 0xFFFFFF, 0x262626, nil, localization.arguments)))
	local executeButton = itemsLayout:setPosition(1, 1, itemsLayout:addChild(GUI.button(1, 1, 1, 3, 0x3C3C3C, 0xFFFFFF, 0x0, 0xFFFFFF, localization.execute)))
	local outputTextBox = itemsLayout:setPosition(1, 2, itemsLayout:addChild(GUI.textBox(1, 1, 1, 1, 0xFFFFFF, 0x888888, {"nil"}, 1, 1, 0)))

	local function updateList(tree, t, definitionName, offset)
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
			local definition = definitionName .. expandables[i]

			tree:addItem(tostring(expandables[i]), definition, offset, true)
			if tree.expandedItems[definition] then
				updateList(tree, t[expandables[i]], definition, offset + 2)
			end
		end

		for i = 1, #list do
			tree:addItem(tostring(list[i]), {key = list[i], value = t[list[i]]}, offset, false)
		end
	end

	local function out(t)		
		local wrappedLines = text.wrap(t, outputTextBox.width - 2)
		for i = 1, #wrappedLines do
			table.insert(outputTextBox.lines, wrappedLines[i])
		end
	end

	tree.onItemExpanded = function()
		tree.items = {}
		updateList(tree, _G, "_G", 1)
	end

	tree.onItemSelected = function()
		local valueType = type(tree.selectedItem.value)
		local valueIsFunction = valueType == "function"
		
		executeButton.disabled = not valueIsFunction
		argumentsInputField.disabled = executeButton.disabled

		infoLabel.text = tostring(tree.selectedItem.key) .. " (" .. valueType .. ")"
		outputTextBox.lines = {}

		if valueIsFunction then
			out("nil")
		else
			out(tostring(tree.selectedItem.value))
		end
	end

	executeButton.onTouch = function()
		outputTextBox.lines = {}

		local data = "local method = ({...})[1]; return method(" .. (argumentsInputField.text or "") .. ")"
		local success, reason = load(data)
		if success then
			local success, reason = pcall(success, tree.selectedItem.value)
			if success then
				if type(reason) == "table" then
					local serialized = text.serialize(reason, true, 2, false, 3)
					for line in serialized:gmatch("[^\n]+") do
						out(line)
					end
				else
					out(tostring(reason))
				end
			else
				out("Failed to pcall loaded string \"" .. data .. "\": " .. reason)
			end
		else
			out("Failed to load string \"" .. data .. "\": " .. reason)
		end

		workspace:draw()
	end


	executeButton.disabled = true
	argumentsInputField.disabled = true
	executeButton.colors.disabled.background = 0x777777
	executeButton.colors.disabled.text = 0xD2D2D2

	tree.onItemExpanded()
end

----------------------------------------------------------------------------------------------------------------

return module