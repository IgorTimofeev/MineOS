
local event = require("Event")
local gpu = require("Screen").getGPUProxy()

--------------------------------------------------------------------------------------------------------------------

local maximumLines = 60
local minimumLineLength = 5
local maximumLineLength = 55
local backgroundColor = 0x000000
local speed = 0.00

local chars = { "ァ", "ア", "ィ", "イ", "ゥ", "ウ", "ェ", "エ", "ォ", "オ", "カ", "ガ", "キ", "ギ", "ク", "グ", "ケ", "ゲ", "コ", "ゴ", "サ", "ザ", "シ", "ジ", "ス", "ズ", "セ", "ゼ", "ソ", "ゾ", "タ", "ダ", "チ", "ヂ", "ッ", "ツ", "ヅ", "テ", "デ", "ト", "ド", "ナ", "ニ", "ヌ", "ネ", "ノ", "ハ", "バ", "パ", "ヒ", "ビ", "ピ", "フ", "ブ", "プ", "ヘ", "ベ", "ペ", "ホ", "ボ", "ポ", "マ", "ミ", "ム", "メ", "モ", "ャ", "ヤ", "ュ", "ユ", "ョ", "ヨ", "ラ", "リ", "ル", "レ", "ロ", "ヮ", "ワ", "ヰ", "ヱ", "ヲ", "ン", "ヴ", "ヵ", "ヶ", "・", "ー", "ヽ", "ヾ" }
local lineColorsForeground = { 0xFFFFFF, 0xBBFFBB, 0x88FF88, 0x33FF33, 0x00FF00, 0x00EE00, 0x00DD00, 0x00CC00, 0x00BB00, 0x00AA00, 0x009900, 0x008800, 0x007700, 0x006600, 0x005500, 0x004400, 0x003300, 0x002200, 0x001100 }
local lineColorsBackground = { 0x004400, 0x004400, 0x003300, 0x003300, 0x002200, 0x001100 }

--------------------------------------------------------------------------------------------------------------------

local lines = {}
local lineColorsForegroundCount = #lineColorsForeground
local charsCount = #chars
local screenWidth, screenHeight = gpu.getResolution()
local currentBackground, currentForeground

local function setBackground(color)
	if currentBackground ~= color then
		gpu.setBackground(color)
		currentBackground = color
	end
end

local function setForeground(color)
	if currentForeground ~= color then
		gpu.setForeground(color)
		currentForeground = color
	end
end

--------------------------------------------------------------------------------------------------------------------

setBackground(backgroundColor)
gpu.fill(1, 1, screenWidth, screenHeight, " ")

local i, colors, background, part, eventType
while true do
	while #lines < maximumLines do
		table.insert(lines, {
			x = math.random(1, screenWidth),
			y = 1,
			length = math.random(minimumLineLength, maximumLineLength)
		})
	end

	gpu.copy(1, 1, screenWidth, screenHeight, 0, 1)
	setBackground(backgroundColor)
	gpu.fill(1, 1, screenWidth, 1, " ")
	
	i, colors = 1, {}
	while i <= #lines do
		lines[i].y = lines[i].y + 1
		if lines[i].y - lines[i].length > 0 then
			table.remove(lines, i)
		else
			part = math.ceil(lineColorsForegroundCount * lines[i].y / lines[i].length)
			
			background = lineColorsBackground[part] or 0x000000
			colors[background] = colors[background] or {}
			colors[background][lineColorsForeground[part]] = colors[background][lineColorsForeground[part]] or {}
			table.insert(colors[background][lineColorsForeground[part]], i)

			i = i + 1
		end
	end

	for background in pairs(colors) do
		setBackground(background)
		for foreground in pairs(colors[background]) do
			setForeground(foreground)
			for i = 1, #colors[background][foreground] do
				gpu.set(lines[colors[background][foreground][i]].x, 1, chars[math.random(1, charsCount)])
			end
		end
	end

	eventType = event.pull(speed)
	if eventType == "key_down" or eventType == "touch" then
		setBackground(0x000000)
		setForeground(0xFFFFFF)
		gpu.fill(1, 1, screenWidth, screenHeight, " ")
		break
	end
end




