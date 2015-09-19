local c = require("component")
local gpu = c.gpu

---------------------------------------------------------------------------

local colors = {
	usualButton = 0xeeeeee,
	actionButton = 0xF69332,
	usualButtonText = 0x262626,
	actionButtonText = 0xffffff,
	equal = 0x363636,
	equalText = 0xffffff,
}

local buttons = {
	{{"C", colors.usualButton, colors.usualButtonText}, {"sin", colors.usualButton, colors.usualButtonText}, {"cos", colors.usualButton, colors.usualButtonText}, {"/", colors.actionButton, colors.actionButtonText}},
	{{"7", colors.usualButton, colors.usualButtonText}, {"8", colors.usualButton, colors.usualButtonText}, {"9", colors.usualButton, colors.usualButtonText}, {"*", colors.actionButton, colors.actionButtonText}},
	{{"4", colors.usualButton, colors.usualButtonText}, {"5", colors.usualButton, colors.usualButtonText}, {"6", colors.usualButton, colors.usualButtonText}, {"-", colors.actionButton, colors.actionButtonText}},
	{{"1", colors.usualButton, colors.usualButtonText}, {"2", colors.usualButton, colors.usualButtonText}, {"3", colors.usualButton, colors.usualButtonText}, {"+", colors.actionButton, colors.actionButtonText}},
	{{"0", colors.usualButton, colors.usualButtonText}, {".", colors.usualButton, colors.usualButtonText}, {"rnd", colors.usualButton, colors.usualButtonText}, {"=", colors.actionButton, colors.actionButtonText}},
}

local buttonWidth, buttonHeight, equalHeight = 7, 3, 3
local calcWidth = #buttons[1] * buttonWidth
local calcHeight = #buttons * buttonHeight + equalHeight

local equal, number1, number2 = 0, 0, 0

local function drawButtons(x, y)
	local yPos, xPos = y, x
	for i = 1, #buttons do
		xPos = x
		for j = 1, #buttons[i] do
			ecs.drawButton(xPos, yPos, buttonWidth, buttonHeight, buttons[i][j][1], buttons[i][j][2], buttons[i][j][3])
			xPos = xPos + buttonWidth
		end
		yPos = yPos + buttonHeight
	end
end

local function drawEqual(x, y)
	ecs.square(x, y, calcWidth, equalHeight, colors.equal)
	ecs.colorText(x + 1, y, ecs.colors.red, "⬤")
	ecs.colorText(x + 3, y, ecs.colors.orange, "⬤")
	ecs.colorText(x + 5, y, ecs.colors.green, "⬤")
	--
	local limit = calcWidth - 4
	local strEqual = ecs.stringLimit("start", tostring(equal), limit)
	local sEqual = #strEqual
	local xPos, yPos = x + calcWidth - sEqual - 3, y + 1
	ecs.colorText(xPos, yPos, colors.equalText, strEqual)
end

local function drawCalc(x, y)
	drawEqual(x, y)
	drawButtons(x, y + equalHeight)
end

--ecs.prepareToExit()
drawCalc(2, 2)
ecs.waitForTouchOrClick()
