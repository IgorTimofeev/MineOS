
local GUI = require("GUI")
local image = require("Image")

------------------------------------------------------

local workspace, window, menu = select(1, ...), select(2, ...), select(3, ...)
local tool = {}
local locale = select(4, ...)

tool.shortcut = "Rsz"
tool.keyCode = 46
tool.about = locale.tool3

local x, y, stepX, stepY, buttonWidth, buttonHeight, buttonCount, buttons, currentX, currentY = 1, 1, 2, 1, 7, 3, 3, {}

local buttonsContainer = GUI.container(1, 1, (buttonWidth + stepX) * buttonCount - stepX, (buttonHeight + stepY) * buttonCount - stepY)
local buttonsLayout = GUI.layout(1, 1, buttonsContainer.width, buttonsContainer.height, 1, 1)
buttonsLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
buttonsLayout:addChild(buttonsContainer)

local widthInput = window.newInput("", locale.width)
local heightInput = window.newInput("", locale.height)

local expandButton = window.newButton2(locale.expand)
local cropButton = window.newButton2(locale.crop)

local function try(x, y, symbol)
	if buttons[y] and buttons[y][x] then
		buttons[y][x].text = symbol
	end
end

local function set(x, y)
	for i = 1, #buttonsContainer.children do
		buttonsContainer.children[i].text = " "
	end

	currentX, currentY = x, y

	try(x, y, "⬤")
	try(x + 1, y, "▶")
	try(x - 1, y, "◀")
	try(x, y + 1, "▼")
	try(x, y - 1, "▲")
	try(x + 1, y + 1, "↘")
	try(x + 1, y - 1, "↗")
	try(x - 1, y + 1, "↙")
	try(x - 1, y - 1, "↖")
end

for j = 1, buttonCount do
	buttons[j] = {}
	for i = 1, buttonCount do
		buttons[j][i] = buttonsContainer:addChild(GUI.button(x, y, buttonWidth, buttonHeight, 0x3C3C3C, 0xB4B4B4, 0x696969, 0xD2D2D2, " "))
		buttons[j][i].onTouch = function()
			set(i, j)
			buttons[j][i].firstParent:draw()
		end

		x = x + buttonWidth + stepX
	end

	x, y = 1, y + buttonHeight + stepY
end

set(2, 2)

tool.onSelection = function()
	window.currentToolLayout:addChild(buttonsLayout)
	window.currentToolLayout:addChild(widthInput)
	window.currentToolLayout:addChild(heightInput)
	window.currentToolLayout:addChild(expandButton)
	window.currentToolLayout:addChild(cropButton)

	widthInput.onInputFinished = function()
		expandButton.disabled = not widthInput.text:match("^%d+$") or not heightInput.text:match("^%d+$")
		cropButton.disabled = expandButton.disabled

		workspace:draw()
	end
	heightInput.onInputFinished = widthInput.onInputFinished
	widthInput.onInputFinished()

	expandButton.onTouch = function()
		local width, height = tonumber(widthInput.text), tonumber(heightInput.text)
		
		window.image.data = image.expand(window.image.data,
			currentY > 1 and height or 0,
			currentY < 3 and height or 0,
			currentX > 1 and width or 0,
			currentX < 3 and width or 0,
		0x0, 0x0, 1, " ")

		window.image.reposition()
		workspace:draw()
	end

	cropButton.onTouch = function()
		local width, height = tonumber(widthInput.text), tonumber(heightInput.text)
		
		window.image.data = image.crop(window.image.data,
			currentX == 1 and 1 or width + 1,
			currentY == 1 and 1 or height + 1,
			(currentX == 1 or currentX == 3) and window.image.width - width or window.image.width - width * 2,
			(currentY == 1 or currentY == 3) and window.image.height - height or window.image.height - height * 2
		)

		window.image.reposition()
		workspace:draw()
	end
end

tool.eventHandler = function(workspace, object, e1)
	
end

------------------------------------------------------

return tool
