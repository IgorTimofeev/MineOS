
local GUI = require("GUI")
local system = require("System")
local color = require("Color")
local screen = require("Screen")
local paths = require("Paths")

--------------------------------------------------------------------

local buttonWidth = 7
local buttonHeight = 3
local displayHeight = 5
local binaryHeight = 8

local value = 0
local memory = 0
local absValue
local oldValue
local action

local binaryButtons = {}
local digitHexadecimalButtons = {}
local digitOctalButtons = {}
local digitDecimalButtons = {}

--------------------------------------------------------------------

local workspace, window, menu = system.addWindow(GUI.window(1, 1, buttonWidth * 12, buttonHeight * 5 + displayHeight + binaryHeight))

local displayContainer = window:addChild(GUI.container(1, 1, window.width, displayHeight + binaryHeight))

local displayPanel = displayContainer:addChild(GUI.panel(1, 1, window.width, displayHeight, 0x2D2D2D, 0.1))

local actionButtons = window:addChild(GUI.actionButtons(3, 3, true))

actionButtons.close.onTouch = function()
	window:remove()
end

actionButtons.minimize.onTouch = function()
	window:minimize()
end

local binaryPanel = displayContainer:addChild(GUI.panel(1, displayHeight + 1, window.width, binaryHeight, 0x3C3C3C))

local binaryLayout = displayContainer:addChild(GUI.layout(1, displayHeight + 2, window.width, binaryHeight, 1, 1))
binaryLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
binaryLayout:setSpacing(1, 1, 0)

local binaryListsLayout = binaryLayout:addChild(GUI.layout(1, 1, binaryLayout.width, 1, 1, 1))
binaryListsLayout:setSpacing(1, 1, 2)
binaryListsLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
binaryListsLayout:setDirection(1, 1, GUI.DIRECTION_HORIZONTAL)

binaryLayout:addChild(GUI.object(1, 1, 1, 1))

local function addBinaryLayoutList(width)
	local list = binaryListsLayout:addChild(GUI.list(1, 1, width, 1, 2, 0, 0x5A5A5A, 0xE1E1E1, 0x5A5A5A, 0xE1E1E1, 0xE1E1E1, 0x5A5A5A, true))
	list:setDirection(GUI.DIRECTION_HORIZONTAL)

	return list
end

-- local binaryPanelButton = binaryListsLayout:addChild(GUI.adaptiveButton(1, 1, 2, 0, 0x5A5A5A, 0xD2D2D2, 0xE1E1E1, 0x5A5A5A, "Binary panel"))
-- binaryPanelButton.switchMode = true

local charList = addBinaryLayoutList(18)
charList:addItem("UTF-8")
charList:addItem("ASCII")

local degereeList = addBinaryLayoutList(14)
degereeList:addItem("RAD")
degereeList:addItem("DEG")

local floatingList = addBinaryLayoutList(16)
floatingList:addItem("INT")
floatingList:addItem("FRACT")
table.insert(digitDecimalButtons, floatingList)

local modeList = addBinaryLayoutList(17)

modeList.selectedItem = 2

local displayWidget = displayContainer:addChild(GUI.object(10, 1, window.width - 12, displayHeight))

local function parseFloat(v)
	v = tostring(v)

	local integer, fractional = v:match("(.+)%.(.+)")
	if integer then
		return integer, fractional
	else
		return v, "0"
	end
end

local function isNumber(v)
	return v ~= "inf" and v ~= "-inf" and v ~= "nan"
end

local function format(v)
	local integer, fractional = parseFloat(v)

	if not isNumber(integer) then
		return integer
	elseif modeList.selectedItem == 1 then
		return string.format("%o", integer)
	elseif modeList.selectedItem == 2 then
		return integer .. "." .. fractional, #integer
	else
		return string.format("0x%X", integer)
	end
end

displayWidget.draw = function()
	local x, y = displayWidget.x + displayWidget.width, displayWidget.y + 2
	local result, integerLength = format(value)
	
	-- Result
	x = x - #result
	screen.drawText(x, y, 0xFFFFFF, result)
		
	-- Digit mode
	if modeList.selectedItem == 2 and integerLength then
		if floatingList.selectedItem == 1 then
			screen.drawText(x, y + 1, 0x696969, string.rep("─", integerLength))
		else
			screen.drawText(x + integerLength + 1, y + 1, 0x696969, string.rep("─", #result - integerLength - 1))
		end
	end

	-- Action and old value
	if oldValue then
		local oldValueText = format(oldValue) .. " " .. action.button.text .. " "
		screen.drawText(x - #oldValueText, y, 0xA5A5A5, oldValueText)
	end

	-- Char
	screen.drawText(displayWidget.x, y, 0x696969, "\"")
	screen.drawText(displayWidget.x + 1, y, 0xFFFFFF, charList.selectedItem == 1 and unicode.char(absValue) or (absValue < 256 and string.char(absValue) or "?"))
	screen.drawText(displayWidget.x + 2, y, 0x696969, "\"")
end

local function setValueRaw(v)
	value, absValue = v, math.floor(math.abs(v))
end

local function numberToBinary()
	for i = 1, #binaryButtons do
		binaryButtons[i].text = "0"
	end

	local i, copy = #binaryButtons, absValue
	while copy > 0 do
		binaryButtons[i].text = tostring(bit32.band(copy, 1))
		copy = bit32.rshift(copy, 1)

		i = i - 1
	end
end

local function setValue(v)
	setValueRaw(v)
	numberToBinary()
end

local function setButtonsDisabled(array, state)
	for i = 1, #array do
		array[i].disabled = state
	end
end

modeList:addItem("8").onTouch = function()
	setButtonsDisabled(digitOctalButtons, true)
	setButtonsDisabled(digitDecimalButtons, true)
	setButtonsDisabled(digitHexadecimalButtons, true)

	floatingList.selectedItem = 1
	setValue(math.floor(value))

	workspace:draw()
end

modeList:addItem("10").onTouch = function()
	setButtonsDisabled(digitOctalButtons, false)
	setButtonsDisabled(digitDecimalButtons, false)
	setButtonsDisabled(digitHexadecimalButtons, true)

	workspace:draw()
end

modeList:addItem("16").onTouch = function()
	setButtonsDisabled(digitOctalButtons, false)
	setButtonsDisabled(digitDecimalButtons, true)
	setButtonsDisabled(digitHexadecimalButtons, false)

	floatingList.selectedItem = 1
	setValue(math.floor(value))

	workspace:draw()
end

local function binaryToNumber()
	local firstNotNullBitIndex = 0

	for i = 1, #binaryButtons do
		if binaryButtons[i].text == "1" then
			firstNotNullBitIndex = i
			break
		end
	end

	local number = 1
	for i = firstNotNullBitIndex + 1, #binaryButtons do
		number = bit32.bor(bit32.lshift(number, 1), binaryButtons[i].text == "1" and 1 or 0)
	end

	setValueRaw(number)
end

local function addBinaryButtonsRowLayout()
	local layout = binaryLayout:addChild(GUI.layout(1, 1, binaryLayout.width, 2, 1, 1))
	layout:setSpacing(1, 1, 3)
	layout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
	layout:setDirection(1, 1, GUI.DIRECTION_HORIZONTAL)

	return layout
end

local function addBinaryButtonsContainer(row, leftText, rightText)
	local container = row:addChild(GUI.container(1, 1, 15, 2))
	local x = 1
	for i = 1, 8 do
		local button = container:addChild(GUI.button(x, 1, 1, 1, nil, 0x969696, nil, 0xFFFFFF, "0"))
		button.onTouch = function()
			button.text = button.text == "0" and "1" or "0"
			binaryToNumber()
		end

		table.insert(binaryButtons, button)

		x = x + 2
	end

	container:addChild(GUI.text(1, 2, 0xE1E1E1, leftText))
	container:addChild(GUI.text(container.width - #rightText + 1, 2, 0xE1E1E1, rightText))
end

local row1 = addBinaryButtonsRowLayout()
addBinaryButtonsContainer(row1, "64", "57")
addBinaryButtonsContainer(row1, "56", "49")
addBinaryButtonsContainer(row1, "48", "41")
addBinaryButtonsContainer(row1, "40", "33")

local row2 = addBinaryButtonsRowLayout()
addBinaryButtonsContainer(row2, "32", "25")
addBinaryButtonsContainer(row2, "24", "17")
addBinaryButtonsContainer(row2, "16", "9")
addBinaryButtonsContainer(row2, "8", "1")

local buttonsContainer = window:addChild(GUI.container(1, displayContainer.height + 1, window.width, window.height - displayContainer.height))

local function addButton(x, y, c1, c2, c3, c4, text, onTouch, width, height)
	local button = buttonsContainer:addChild(GUI.button(
		(x - 1) * buttonWidth + 1,
		(y - 1) * buttonHeight + 1,
		(width or 1) * buttonWidth,
		(height or 1) * buttonHeight,
		c1, c2, c3, c4, text
	))

	button.onTouch = onTouch
	button.colors.disabled.background = c1
	button.colors.disabled.text = 0xB4B4B4

	return button
end

local function addEngineerButton(x, y, ...)
	return addButton(x, y, 0xD2D2D2, 0x2D2D2D, 0xB4B4B4, 0x2D2D2D, ...)
end

local function addBinaryButton(x, y, ...)
	return addButton(x, y, 0xE1E1E1, 0x2D2D2D, 0xB4B4B4, 0x2D2D2D, ...)
end

local function addRegularButton(x, y, ...)
	return addButton(x, y, 0xF0F0F0, 0x2D2D2D, 0xB4B4B4, 0x2D2D2D, ...)
end

local function addMathButton(x, y, ...)
	return addButton(x, y, 0xFF9240, 0xFFFFFF, 0xCC6D00, 0xFFFFFF, ...)
end

local function onDigitPressed(digit)
	if modeList.selectedItem == 1 then
		setValue(tonumber(string.format("%o", value) .. digit, 8))
	elseif modeList.selectedItem == 2 then
		local integer, fractional = parseFloat(value)

		if isNumber(integer) then
			if floatingList.selectedItem == 1 then
				setValue(tonumber(integer .. digit .. "." .. fractional))
			else
				setValue(tonumber(integer .. "." .. (fractional == "0" and "" or fractional) .. digit))
			end
		end
	else
		setValue(math.floor(value) * 16 + digit)
	end
end

local function reset()
	oldValue = nil
	floatingList.selectedItem = 1
	if action then
		action.button.pressed = false
		action = nil
	end
end

local function getActionResult()
	setValue(action.getResult())
end

local function addAction(button, getResult)
	button.switchMode = true
	button.onTouch = function()
		-- Если уже имеется какое-то действие
		if action then
			-- Если мы повторно жмякаем на ранее нажатую кнопку
			if action.button == button then
				button.pressed = true
			-- Отжимаем кнопку другого действия, если она была ранее нажата
			else
				action.button.pressed = false
			end

			getActionResult()
		end

		oldValue = value
		setValue(0)
		floatingList.selectedItem = 1

		action = {
			button = button,
			getResult = getResult
		}
	end
end

local function getDegree(v)
	return degereeList.selectedItem == 1 and v or math.rad(v)
end

--------------------------------------------------------------------

-- Digits row 1
addRegularButton(9, 1, "C", function()
	setValue(0)
	reset()
end)

addRegularButton(10, 1, "CE", function()
	setValue(0)
end)

addRegularButton(11, 1, "%", function()
	value = value / 100
	
	if action then
		getActionResult()
		reset()
	else
		setValue(value)
	end
end)

addAction(addMathButton(12, 1, "/"), function()
	return oldValue / value
end)

-- Digits row 2
addRegularButton(9, 2, "7", function()
	onDigitPressed(7)
end)

table.insert(digitOctalButtons, addRegularButton(10, 2, "8", function()
	onDigitPressed(8)
end))

table.insert(digitOctalButtons, addRegularButton(11, 2, "9", function()
	onDigitPressed(9)
end))

addAction(addMathButton(12, 2, "*"), function()
	return oldValue * value
end)

-- Digits row 3
for i = 4, 6 do
	addRegularButton(i + 5, 3, tostring(i), function()
		onDigitPressed(i)
	end)
end

addAction(addMathButton(12, 3, "-"), function()
	return oldValue - value
end)

-- Digits row 4
for i = 1, 3 do
	addRegularButton(i + 8, 4, tostring(i), function()
		onDigitPressed(i)
	end)
end

addAction(addMathButton(12, 4, "+"), function()
	return oldValue + value
end)

-- Digits row 5
addRegularButton(9, 5, "0", function()
	onDigitPressed(0)
end)

table.insert(digitDecimalButtons, addRegularButton(10, 5, ".", function()
	floatingList.selectedItem = floatingList.selectedItem == 1 and 2 or 1
end))

addRegularButton(11, 5, "+-", function()
	setValue(-value)
end)

addMathButton(12, 5, "=", function()
	if action then
		getActionResult()
		reset()
	end
end)

--------------------------------------------------------------------

-- Engineer row 1
addEngineerButton(1, 1, "mc", function()
	memory = 0
end)

addEngineerButton(2, 1, "m+", function()
	memory = memory + value
end)

addEngineerButton(3, 1, "m-", function()
	memory = memory - value
end)

addEngineerButton(4, 1, "mr", function()
	setValue(memory)
	reset()
end)

addEngineerButton(5, 1, "rnd", function()
	setValue(math.random())
	reset()
end)

-- Engineer row 2
addEngineerButton(1, 2, "x^2", function()
	setValue(value ^ 2)
	reset()
end)

addAction(addEngineerButton(2, 2, "x^y"), function()
	return oldValue ^ value
end)

addEngineerButton(3, 2, "√x", function()
	setValue(math.sqrt(value))
	reset()
end)

addAction(addEngineerButton(4, 2, "y√x"), function()
	return oldValue ^ (1 / value)
end)

addEngineerButton(5, 2, "x!", function()
	local fact = 1
	for i = 2, absValue do
		fact = fact * i
	end

	setValue(fact)
	reset()
end)

-- Engineer row 3
addEngineerButton(1, 3, "sin", function()
	setValue(math.sin(getDegree(value)))
	reset()
end)

addEngineerButton(2, 3, "cos", function()
	setValue(math.cos(getDegree(value)))
	reset()
end)

addEngineerButton(3, 3, "tan", function()
	setValue(math.tan(getDegree(value)))
	reset()
end)

addEngineerButton(4, 3, "1/x", function()
	setValue(1 / value)
	reset()
end)

addAction(addEngineerButton(5, 3, "e^x"), function()
	return math.exp(value)
end)

-- Engineer row 4
addEngineerButton(1, 4, "asin", function()
	setValue(math.asin(getDegree(value)))
	reset()
end)

addEngineerButton(2, 4, "acos", function()
	setValue(math.acos(getDegree(value)))
	reset()
end)

addEngineerButton(3, 4, "atan", function()
	setValue(math.atan(getDegree(value)))
	reset()
end)

addAction(addEngineerButton(4, 4, "log"), function()
	return math.log(oldValue, value)
end)

addAction(addEngineerButton(5, 4, "mod"), function()
	return oldValue % value
end)

-- Engineer row 5
addEngineerButton(1, 5, "sinh", function()
	setValue(math.sinh(getDegree(value)))
	reset()
end)

addEngineerButton(2, 5, "cosh", function()
	setValue(math.cosh(getDegree(value)))
	reset()
end)

addEngineerButton(3, 5, "tanh", function()
	setValue(math.tanh(getDegree(value)))
	reset()
end)

addEngineerButton(4, 5, "e", function()
	setValue(2.718281828459045)
	reset()
end)

addEngineerButton(5, 5, "π", function()
	setValue(math.pi)
	reset()
end)

--------------------------------------------------------------------

-- Binary row 1
table.insert(digitHexadecimalButtons, addBinaryButton(6, 1, "D", function()
	onDigitPressed(0xD)
end))

table.insert(digitHexadecimalButtons, addBinaryButton(7, 1, "E", function()
	onDigitPressed(0xE)
end))

table.insert(digitHexadecimalButtons, addBinaryButton(8, 1, "F", function()
	onDigitPressed(0xF)
end))

-- Binary row 2
table.insert(digitHexadecimalButtons, addBinaryButton(6, 2, "A", function()
	onDigitPressed(0xA)
end))

table.insert(digitHexadecimalButtons, addBinaryButton(7, 2, "B", function()
	onDigitPressed(0xB)
end))

table.insert(digitHexadecimalButtons, addBinaryButton(8, 2, "C", function()
	onDigitPressed(0xC)
end))

-- Binary row 3
addAction(addBinaryButton(6, 3, "AND"), function()
	return bit32.band(math.floor(oldValue), math.floor(value))
end)

addAction(addBinaryButton(7, 3, "OR"), function()
	return bit32.bor(math.floor(oldValue), math.floor(value))
end)

addAction(addBinaryButton(8, 3, "XOR"), function()
	return bit32.bxor(math.floor(oldValue), math.floor(value))
end)


-- Binary row 4
addAction(addBinaryButton(6, 4, "NOR"), function()
	return bit32.bnot(bit32.bor(math.floor(oldValue), math.floor(value)))
end)

addAction(addBinaryButton(7, 4, "ROL"), function()
	return bit32.lrotate(math.floor(oldValue), math.floor(value))
end)

addAction(addBinaryButton(8, 4, "ROR"), function()
	return bit32.rrotate(math.floor(oldValue), math.floor(value))
end)

-- Binary row 5
addAction(addBinaryButton(6, 5, "x<<y"), function()
	return bit32.lshift(math.floor(oldValue), math.floor(value))
end)

addAction(addBinaryButton(7, 5, "NOT"), function()
	return bit32.bnot(math.floor(oldValue), math.floor(value))
end)

addAction(addBinaryButton(8, 5, "x>>y"), function()
	return bit32.rshift(math.floor(oldValue), math.floor(value))
end)

--------------------------------------------------------------------

setValue(0)
modeList:getItem(2).onTouch()
