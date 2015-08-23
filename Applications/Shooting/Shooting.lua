local component = require("component")
local gpu = component.gpu
local event = require("event")
local ecs = require("ECSAPI")
local colorlib = require("colorlib")

---------------------------
local xOld, yOld = gpu.getResolution()
gpu.setResolution(160, 50)
local xSize, ySize = 160, 50

local players = {}
local xCenter, yCenter = math.floor(xSize/4 - 15), math.floor(ySize/2)

local xScore, yScore = 106, 5

local symbols = {
   ["1"] = {
    {0, 0, 1, 0, 0},
    {0, 0, 1, 0, 0},
    {0, 1, 1, 0, 0},
    {0, 0, 1, 0, 0},
    {0, 0, 1, 0, 0},
    {0, 0, 1, 0, 0},
    {0, 1, 1, 1, 0},
  },
  ["2"] = {
    {0, 1, 1, 1, 0},
    {1, 0, 0, 0, 1},
    {0, 0, 0, 0, 1},
    {0, 1, 1, 1, 0},
    {1, 0, 0, 0, 0},
    {1, 0, 0, 0, 0},
    {1, 1, 1, 1, 1},
  },
  ["3"] = {
    {0, 1, 1, 1, 0},
    {1, 0, 0, 0, 1},
    {0, 0, 0, 0, 1},
    {0, 0, 1, 1, 0},
    {0, 0, 0, 0, 1},
    {1, 0, 0, 0, 1},
    {0, 1, 1, 1, 0},
  },
  ["4"] = {
    {1, 0, 0, 0, 1},
    {1, 0, 0, 0, 1},
    {1, 0, 0, 0, 1},
    {1, 1, 1, 1, 1},
    {0, 0, 0, 0, 1},
    {0, 0, 0, 0, 1},
    {0, 0, 0, 0, 1},
  },
  ["5"] = {
    {1, 1, 1, 1, 1},
    {1, 0, 0, 0, 0},
    {1, 0, 0, 0, 0},
    {1, 1, 1, 1, 0},
    {0, 0, 0, 0, 1},
    {1, 0, 0, 0, 1},
    {0, 1, 1, 1, 0},
  },
  ["6"] = {
    {0, 0, 1, 1, 1},
    {0, 1, 0, 0, 0},
    {1, 0, 0, 0, 0},
    {1, 1, 1, 1, 0},
    {1, 0, 0, 0, 1},
    {1, 0, 0, 0, 1},
    {0, 1, 1, 1, 0},
  },
  ["7"] = {
    {1, 1, 1, 1, 1},
    {0, 0, 0, 0, 1},
    {0, 0, 0, 1, 0},
    {0, 0, 1, 0, 0},
    {0, 0, 1, 0, 0},
    {0, 0, 1, 0, 0},
    {0, 0, 1, 0, 0},
  },
  ["8"] = {
    {0, 1, 1, 1, 0},
    {1, 0, 0, 0, 1},
    {1, 0, 0, 0, 1},
    {0, 1, 1, 1, 0},
    {1, 0, 0, 0, 1},
    {1, 0, 0, 0, 1},
    {0, 1, 1, 1, 0},
  },
  ["9"] = {
    {0, 1, 1, 1, 0},
    {1, 0, 0, 0, 1},
    {1, 0, 0, 0, 1},
    {0, 1, 1, 1, 1},
    {0, 0, 0, 0, 1},
    {0, 0, 0, 1, 0},
    {1, 1, 1, 0, 0},
  },
  ["0"] = {
    {0, 1, 1, 1, 0},
    {1, 0, 0, 0, 1},
    {1, 0, 0, 0, 1},
    {1, 0, 0, 0, 1},
    {1, 0, 0, 0, 1},
    {1, 0, 0, 0, 1},
    {0, 1, 1, 1, 0},
  }
}

--OBJECTS, CYKA
local obj = {}
local function newObj(class, name, ...)
	obj[class] = obj[class] or {}
	obj[class][name] = {...}
end

local function SetPixel(x, y, color)
  ecs.square(x*2, y, 2, 1, color)
end

local function GetDistance(x1, y1, x2, y2)
	local distance
	distance = math.sqrt((x1 - x2)*(x1 - x2) + (y1 - y2)*(y1 - y2))
	return distance
end

local function drawKrug(x1, y1, r, color)
	for x = x1 - r, x1 + r do
		for y = y1 - r, y1 + r do
			if GetDistance(x1, y1, x, y) <= r then
				SetPixel(x, y, color)
			end
		end
	end
end

local function drawMishen()
	for i = 0, 9 do
		local color = 0xffffff
		if i % 2 == 0 then
			color = 0x010101
		end
		drawKrug(xCenter, yCenter, 20 - i*2, color)
	end
	SetPixel(xCenter, yCenter, 0xff0000)
end

local function AddPlayer(name)
	if not players[name] then
		players[name] = {0, colorlib.HSBtoHEX(math.random(0, 359), 100, math.random(50, 100))}
	end
end

local function AddScore(name, score)
	players[name][1] = players[name][1] + score
end

local function GetScore(x, y)
	local score = 1
	local distance = GetDistance(xCenter, yCenter, x, y)
	if distance == 0 then
		score = 25
	else
		for i = 0, 6 do
			if distance <= 20 - i*3 then
				score = score + 2
			end
		end
	end
	return score
end

local function showPlayers(x, y)
	local width = 40
	local nicknameLimit = 20
	local mode = false
	local counter = 1
	local stro4ka = string.rep(" ", nicknameLimit).."│"..string.rep(" ", width - nicknameLimit)
	ecs.colorTextWithBack(x, y, 0xffffff, ecs.colors.blue, stro4ka)
	gpu.set(x + 1, y, "Имя игрока")
	gpu.set(x + nicknameLimit + 2, y, "Очки")

	for key, val in pairs(players) do
		local color = 0xffffff

		if mode then
			color = color - 0x222222
		end

		gpu.setForeground(0x262626)
		gpu.setBackground(color)
		gpu.set(x, y + counter, stro4ka)
		gpu.set(x + 3, y + counter, ecs.stringLimit("end", key, nicknameLimit - 4))
		gpu.set(x + nicknameLimit + 2, y + counter, tostring(players[key][1]))
		ecs.colorTextWithBack(x + 1, y + counter, players[key][2], color, "●")

		counter = counter + 1
		mode = not mode
	end
end

local function drawSymb(x, y, symb, color)
	for i = 1, 7 do
		for j = 1, 5 do
			if symbols[symb][i][j] == 1 then
				SetPixel(x + j - 1, y + i - 1, color)
			end
		end
	end
end

local function drawText(x, y, text, color)
	if text >=10 then
		drawSymb(x, y, tostring(math.floor(text/10)), color)
		drawSymb(x + 6, y, tostring(math.floor(text%10)), color)
	else
		drawSymb(x, y, tostring(text), color)
	end
end

local function isIn(x1, y1, x2, y2, xClick, yClick)
	if xClick >= x1 and xClick <= x2 and yClick >=y1 and yClick <= y2 then
		return true
	else
		return false
	end
end

local function drawLastScore(x, y, score, color)
	ecs.square((x + 6) * 2, y, 35, 7, 0x262626)
	drawKrug(x + 3, y + 3, 3, color)
	drawText(x + 9, y, score, 0xffffff)

	local yPos = 34
	newObj("Buttons", "Заново", ecs.drawAdaptiveButton(xScore, yPos, 18, 1, "Заново", ecs.colors.blue, 0xffffff))
	yPos = yPos + 4
	newObj("Buttons", "Выйти ", ecs.drawAdaptiveButton(xScore, yPos, 18, 1, "Выйти ", ecs.colors.blue, 0xffffff))

end

local function Tir()
	ecs.prepareToExit()

	showPlayers(xScore, yScore)
	drawLastScore(xScore / 2, 22, 0, 0xffffff)

	drawMishen()
	while true do
		local e = {event.pull()}
		if e[1] == "touch" then
			for key, val in pairs(obj["Buttons"]) do
				if ecs.clickedAtArea(e[3], e[4], obj["Buttons"][key][1], obj["Buttons"][key][2], obj["Buttons"][key][3], obj["Buttons"][key][4]) then
					ecs.drawAdaptiveButton(obj["Buttons"][key][1], obj["Buttons"][key][2], 18, 1, key, 0xffffff, 0x000000)
					os.sleep(0.5)

					if key == "Выйти " then
						return "exit"
					else
						players = {}
						return 0
					end
				end
			end
			e[3] = e[3]/2
			AddPlayer(e[6])
			AddScore(e[6], GetScore(e[3], e[4]))
			SetPixel(e[3], e[4], players[e[6]][2])
			showPlayers(xScore, yScore)
			drawLastScore(xScore / 2, 22, GetScore(e[3], e[4]),players[e[6]][2])
		end
	end
end

--------------------------

while true do
	local exit = Tir()
	if exit == "exit" then break end
end

gpu.setResolution(xOld, yOld)
ecs.prepareToExit()

