
local function matrix(backgroundColor, maximumLines, minumLineLength, maximumLineLength)
	local event = require("event")
	local gpu = require("component").gpu
	local xScreen, yScreen = gpu.getResolution()

	local chars = {"ァ", "ア", "ィ", "イ", "ゥ", "ウ", "ェ", "エ", "ォ", "オ", "カ", "ガ", "キ", "ギ", "ク", "グ", "ケ", "ゲ", "コ", "ゴ", "サ", "ザ", "シ", "ジ", "ス", "ズ", "セ", "ゼ", "ソ", "ゾ", "タ", "ダ", "チ", "ヂ", "ッ", "ツ", "ヅ", "テ", "デ", "ト", "ド", "ナ", "ニ", "ヌ", "ネ", "ノ", "ハ", "バ", "パ", "ヒ", "ビ", "ピ", "フ", "ブ", "プ", "ヘ", "ベ", "ペ", "ホ", "ボ", "ポ", "マ", "ミ", "ム", "メ", "モ", "ャ", "ヤ", "ュ", "ユ", "ョ", "ヨ", "ラ", "リ", "ル", "レ", "ロ", "ヮ", "ワ", "ヰ", "ヱ", "ヲ", "ン", "ヴ", "ヵ", "ヶ", "ヷ", "ヸ", "ヹ", "ヺ", "・", "ー", "ヽ", "ヾ", "ヿ"}
	local colorsForeground = { 0xFFFFFF, 0xBBFFBB, 0x88FF88, 0x33FF33, 0x00FF00, 0x00EE00, 0x00DD00, 0x00CC00, 0x00BB00, 0x00AA00, 0x009900, 0x008800, 0x007700, 0x006600, 0x005500, 0x004400, 0x003300, 0x002200, 0x001100 }
	local colorsBackground = { 0x004400, 0x004400, 0x003300, 0x002200, 0x001100 }

	local lines = {}
	local function generateLine()
		table.insert(lines, {
			x = math.random(1, xScreen),
			y = 1,
			length = math.random(minumLineLength, maximumLineLength)
		})
	end

	local function tick()
		while #lines < maximumLines do generateLine() end

		gpu.copy(1, 1, xScreen, yScreen - 1, 0, 1)
		gpu.setBackground(backgroundColor)
		gpu.fill(1, 1, xScreen, 1, " ")
		local i = 1
		while i <= #lines do
			local part = lines[i].y * #colorsForeground / lines[i].length
			local background = colorsBackground[math.ceil(part)]
			local foreground = colorsForeground[math.ceil(part)]

			if background then gpu.setBackground(background) end
			gpu.setForeground(foreground)
			gpu.set(lines[i].x, 1, chars[math.random(1, #chars)])

			lines[i].y = lines[i].y + 1
			if lines[i].y - lines[i].length > 0 then
				table.remove(lines, i)
				i = i - 1
			end
			i = i + 1
		end
	end

	gpu.setBackground(backgroundColor)
	gpu.fill(1, 1, xScreen, yScreen, " ")
	while true do
		tick()
		local e = {event.pull(0.03)}
		if e[1] == "key_down" and e[4] == 28 or e[1] == "touch" then
			break
		end
	end
end

matrix(0x0, 20, 5, 25)






