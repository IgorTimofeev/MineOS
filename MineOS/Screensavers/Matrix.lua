
local event = require("event")
local gpu = require("component").gpu

--------------------------------------------------------------------------------------------------------------------

local maximumLines = 20
local minumLineLength = 5
local maximumLineLength = 25
local backgroundColor = 0x000000

--------------------------------------------------------------------------------------------------------------------

-- local chars = {"%", "?", "@", "#", "$", "!", "0", "/", "№", "&"}
local chars = {"ァ", "ア", "ィ", "イ", "ゥ", "ウ", "ェ", "エ", "ォ", "オ", "カ", "ガ", "キ", "ギ", "ク", "グ", "ケ", "ゲ", "コ", "ゴ", "サ", "ザ", "シ", "ジ", "ス", "ズ", "セ", "ゼ", "ソ", "ゾ", "タ", "ダ", "チ", "ヂ", "ッ", "ツ", "ヅ", "テ", "デ", "ト", "ド", "ナ", "ニ", "ヌ", "ネ", "ノ", "ハ", "バ", "パ", "ヒ", "ビ", "ピ", "フ", "ブ", "プ", "ヘ", "ベ", "ペ", "ホ", "ボ", "ポ", "マ", "ミ", "ム", "メ", "モ", "ャ", "ヤ", "ュ", "ユ", "ョ", "ヨ", "ラ", "リ", "ル", "レ", "ロ", "ヮ", "ワ", "ヰ", "ヱ", "ヲ", "ン", "ヴ", "ヵ", "ヶ", "ヷ", "ヸ", "ヹ", "ヺ", "・", "ー", "ヽ", "ヾ", "ヿ"}
local lineColorsForeground = { 0xFFFFFF, 0xBBFFBB, 0x88FF88, 0x33FF33, 0x00FF00, 0x00EE00, 0x00DD00, 0x00CC00, 0x00BB00, 0x00AA00, 0x009900, 0x008800, 0x007700, 0x006600, 0x005500, 0x004400, 0x003300, 0x002200, 0x001100 }
local lineColorsBackground = { 0x004400, 0x004400, 0x003300, 0x003300, 0x002200, 0x001100 }
local xScreen, yScreen = gpu.getResolution()
local lines = {}

--------------------------------------------------------------------------------------------------------------------

gpu.setBackground(backgroundColor)
gpu.fill(1, 1, xScreen, yScreen, " ")

while true do
	while #lines < maximumLines do
		table.insert(lines, { x = math.random(1, xScreen), y = 1, length = math.random(minumLineLength, maximumLineLength) })
	end

	gpu.copy(1, 1, xScreen, yScreen, 0, 1)
	gpu.setBackground(backgroundColor)
	gpu.fill(1, 1, xScreen, 1, " ")

	local i = 1
	while i <= #lines do
		local part = math.ceil(lines[i].y * #lineColorsForeground / lines[i].length)
		gpu.setBackground(lineColorsBackground[part] or 0x000000)
		gpu.setForeground(lineColorsForeground[part])
		gpu.set(lines[i].x, 1, chars[math.random(1, #chars)])

		lines[i].y = lines[i].y + 1
		if lines[i].y - lines[i].length > 0 then
			table.remove(lines, i)
			i = i - 1
		end
		i = i + 1
	end

	local e = {event.pull(0.03)}
	if (e[1] == "key_down" and e[4] == 28) or e[1] == "touch" then
		gpu.setBackground(backgroundColor)
		gpu.fill(1, 1, xScreen, yScreen, " ")
		break
	end
end




