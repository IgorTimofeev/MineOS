
local buffer = require("doubleBuffering")
local GUI = require("GUI")
local image = require("image")
local unicode = require("unicode")

local module = {
	name = "Интерпретатор Lua"
}

----------------------------------------------------------------------------------------------------------------------------

function module.execute(window)
	local luaConsoleHistoryLimit = 50

	local colors, printColor = {
		passive = 0x777777,
		error = 0xFF4940,
	}

	window.drawingArea:deleteChildren()
	local logoPanelWidth = 20
	local consolePanelWidth = window.drawingArea.width - logoPanelWidth
	local luaLogoPanel = window.drawingArea:addPanel(1, 1, logoPanelWidth, window.drawingArea.height, 0xEEEEEE)
	local luaLogoImage = window.drawingArea:addImage(2, 1, image.load(window.resourcesPath .. "LuaLogo.pic"))
	local luaCopyrightTextBox = window.drawingArea:addTextBox(2, luaLogoImage.height + 2, luaLogoPanel.width - 2, 5, nil, 0x999999, {_G._VERSION, "(C) 1994-2016", "Lua.org, PUC-Rio", "", "GUI-based by ECS"}, 1)
	luaCopyrightTextBox:setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	local consolePanel = window.drawingArea:addPanel(logoPanelWidth + 1, 1, consolePanelWidth, window.drawingArea.height, 0x1E1E1E)

	local lines = {
		{color = 0xFFDB40, text = "Система " .. _VERSION .. " инициализирована"},
		{color = colors.passive, text = "● Введите выражение и нажимте Enter для его "},
		{color = colors.passive, text = "  исполнения в виде Lua-кода"},
		{color = colors.passive, text = "● Используйте Tab для автозаполнения названий"},
		{color = colors.passive, text = "  переменных"},
		{color = colors.passive, text = "● Введите \"=переменная\", чтобы узнать значение"},
		{color = colors.passive, text = "  конкретной переменной"},
		" "
	}
	local consoleTextBox = window.drawingArea:addTextBox(logoPanelWidth + 2, 1, consolePanelWidth - 2, window.drawingArea.height - 3, nil, 0xFFFFFF, lines, 1)

	local consoleCommandInputTextBox = window.drawingArea:addInputTextBox(logoPanelWidth + 1, consolePanel.height - 2, consolePanel.width, 3, 0x333333, 0x777777, 0x333333, 0x444444, nil, "print(\"Hello, world!\")")
	consoleCommandInputTextBox.highlightLuaSyntax = true
	consoleCommandInputTextBox.autocompleteVariables = true

	local function addLines(lines, printColor)
		for i = 1, #lines do
			if #consoleTextBox.lines > luaConsoleHistoryLimit then table.remove(consoleTextBox.lines, 1) end
			table.insert(consoleTextBox.lines, printColor and {color = printColor, text = lines[i]} or lines[i])
		end
		consoleTextBox:scrollDown(#lines)
	end

	local function getStringValueOfVariable(variable)
		local type, value = type(variable)
		if type == "table" then
			value = table.serialize(variable, true, nil, nil, 1)
		else
			value = tostring(variable)
		end

		return value
	end

	local function reimplementedPrint(...)
		local args = {...}
		local resultText = {}; for i = 1, #args do table.insert(resultText, getStringValueOfVariable(args[i])) end
		if #resultText > 0 then
			local lines = {table.concat(resultText, "  ")}
			lines = string.wrap(lines, consoleTextBox.width - 2)
			addLines(lines)
		end
	end

	-- Функцию стер - хуй проглотил!
	-- abc = function(a, b, c) local d = b ^ 2 - 4 * a * c; if d < 0 then error("Сууука!!! D < 0") end; x1 = (-b + math.sqrt(d)) / (2 * a); x2 = (-b - math.sqrt(d)) / (2 * a); return x1, x2 end

	consoleCommandInputTextBox.onInputFinished = function()
		if consoleCommandInputTextBox.text then
			-- Подменяем стандартный print() на мой пиздатый
			local oldPrint = print
			print = reimplementedPrint
			-- Пишем, че мы вообще исполняли
			addLines({"> " .. consoleCommandInputTextBox.text}, colors.passive)

			-- Ебашим поддержку =
			consoleCommandInputTextBox.text = consoleCommandInputTextBox.text:gsub("^[%s+]?%=[%s+]?", "return ")
			local loadSuccess, loadReason = load(consoleCommandInputTextBox.text)
			if loadSuccess then
				local xpcallResult = {xpcall(loadSuccess, debug.traceback)}
				if xpcallResult[1] then
					table.remove(xpcallResult, 1)
					reimplementedPrint(table.unpack(xpcallResult))
				else
					addLines({xpcallResult[2]}, colors.error)
				end
			else
				addLines({loadReason}, colors.error)
			end

			consoleCommandInputTextBox.text = nil
			print = oldPrint

			window:draw()
			buffer.draw()
		end
	end
end

----------------------------------------------------------------------------------------------------------------------------

return module






