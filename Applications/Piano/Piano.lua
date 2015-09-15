local c = require("component")
local event = require("event")
local gpu = c.gpu

local xSize, ySize = gpu.getResolution()

local colors = {
	whiteKeyColor = 0xffffff,
	blackKeyColor = 0x000000,
	background = 0x262626,
}

local sizes = {
	widthOfWhiteKey = 3,
	heightOfWhiteKey = 10,
	widthOfBlackKey = 3,
	heightOfBlackKey = 5,
	doubleKeyBlockConst = 7,
}
sizes.yStartOfKeys = ySize - sizes.heightOfWhiteKey + 1
sizes.xStartOfKeys = 3
sizes.countOfKeysOnScreen = 0

local frequencyMultiplyer
local minFrequency, maxFrequency = 20, 2000

------------------------------------------------------------

--СОЗДАНИЕ ОБЪЕКТОВ
local obj = {}
local function newObj(class, name, ...)
	obj[class] = obj[class] or {}
	obj[class][name] = {...}
end

local function calculateFrequencyMultiplyer()
	local difference = maxFrequency - minFrequency
	frequencyMultiplyer = difference / sizes.countOfKeysOnScreen
end

local function drawKeysBlock(x, y, countOfWhite, countOfBlack)
	local xPos = x
	for i = 1, countOfWhite do
		ecs.square(xPos, y, sizes.widthOfWhiteKey, sizes.heightOfWhiteKey, colors.whiteKeyColor)
		
		sizes.countOfKeysOnScreen = sizes.countOfKeysOnScreen + 1

		newObj("Keys", sizes.countOfKeysOnScreen, xPos, y + sizes.heightOfBlackKey, xPos + sizes.widthOfWhiteKey - 1, y + sizes.heightOfWhiteKey - 1, true)

		xPos = xPos + sizes.widthOfWhiteKey + 1		
	end
	xPos = x + 2
	for i = 1, countOfBlack do
		ecs.square(xPos, y, sizes.widthOfBlackKey, sizes.heightOfBlackKey, colors.blackKeyColor)

		newObj("Keys", sizes.countOfKeysOnScreen + 1, xPos, y, xPos + sizes.widthOfBlackKey - 1, y + sizes.heightOfBlackKey - 1, false)

		sizes.countOfKeysOnScreen = sizes.countOfKeysOnScreen + 1

		xPos = xPos + sizes.widthOfBlackKey + 1
	end
end

local function drawTwoKeysBlock(x, y)
	drawKeysBlock(x, y, 3, 2)
end

local function drawThreeKeysBlock(x, y)
	drawKeysBlock(x, y, 4, 3)
end

local function drawDoubleKeyBlock(x, y)
	sizes.countOfKeysOnScreen = 0
	local xPos = x
	for i = 1, 3 do
		drawTwoKeysBlock(xPos, y)
		xPos = xPos + 3 * (sizes.widthOfWhiteKey + 1)
		drawThreeKeysBlock(xPos, y)
		xPos = xPos + 4 * (sizes.widthOfWhiteKey + 1)
	end
	drawTwoKeysBlock(xPos, y)

	calculateFrequencyMultiplyer()
end

local function setFrequencyToKeys()
	calculateFrequencyMultiplyer()
	local justBecomeBlack = false
	local whiteCounter = 0
	local currentWhiteFrequency, currentBlackFrequency = minFrequency, minFrequency + frequencyMultiplyer
	for i = 1, #obj["Keys"] do
		if obj["Keys"][i][5] then
			whiteCounter = whiteCounter + 1
			justBecomeBlack = true
			currentWhiteFrequency = currentWhiteFrequency + frequencyMultiplyer
			obj["Keys"][i][6] = currentWhiteFrequency
		else
			if justBecomeBlack then currentBlackFrequency = currentWhiteFrequency - frequencyMultiplyer * (whiteCounter - 1); justBecomeBlack = false end
			currentBlackFrequency = currentBlackFrequency + frequencyMultiplyer
			obj["Keys"][i][6] = currentBlackFrequency
			whiteCounter = 0
		end
	end
end

local function drawAll()
	ecs.clearScreen(colors.background)
	drawDoubleKeyBlock(sizes.xStartOfKeys, sizes.yStartOfKeys)
end

drawAll()
setFrequencyToKeys()

while true do
	local e = {event.pull()}
	if e[1] == "touch" then
		for key, val in pairs(obj["Keys"]) do
			if ecs.clickedAtArea(e[3], e[4], obj["Keys"][key][1], obj["Keys"][key][2], obj["Keys"][key][3], obj["Keys"][key][4]) then
				if obj["Keys"][key][5] then
					ecs.square(obj["Keys"][key][1], obj["Keys"][key][2], sizes.widthOfWhiteKey, sizes.heightOfWhiteKey - sizes.heightOfBlackKey, ecs.colors.green)
				else
					ecs.square(obj["Keys"][key][1], obj["Keys"][key][2], sizes.widthOfBlackKey, sizes.heightOfBlackKey, ecs.colors.green)
				end

				c.computer.beep(obj["Keys"][key][6])

				if obj["Keys"][key][5] then
					ecs.square(obj["Keys"][key][1], obj["Keys"][key][2], sizes.widthOfWhiteKey, sizes.heightOfWhiteKey - sizes.heightOfBlackKey, colors.whiteKeyColor)
				else
					ecs.square(obj["Keys"][key][1], obj["Keys"][key][2], sizes.widthOfBlackKey, sizes.heightOfBlackKey, colors.blackKeyColor)
				end

				break
			end
		end
	end
end







