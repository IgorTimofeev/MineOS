local rs
local sides = require("sides")
local event = require("event")

-- if not component.isAvailable("redstone") then
-- 	ecs.error("This program requires Redstone I/O block or Redstone Card to work.")
-- 	return
-- else
-- 	rs = require("redstone")
-- end

------------------------------------------------------------------------------------------------------------

local colors = {
	background = 0x202020,
	borders = 0xFFDD00,
}

------------------------------------------------------------------------------------------------------------

local keyPad = {
	{"1", "2", "3"},
	{"4", "5", "6"},
	{"7", "8", "9"},
	{"*", "0", "#"},
}

local xSize, ySize
local buttons = {}
local biometry = {}
local input
local password = "12345"
local nicknames = {
	"IgorTimofeev",
	"IT2",
}

local function drawKeyPad(x, y)
	local xPos, yPos = x, y
	buttons = {}
	for j = 1, #keyPad do
		xPos = x
		for i = 1, #keyPad[j] do
			ecs.drawFramedButton(xPos, yPos, 5, 3, keyPad[j][i], colors.borders)
			buttons[keyPad[j][i]] = {xPos, yPos, xPos + 4, yPos + 2}
			xPos = xPos + 6
		end
		yPos = yPos + 3
	end
end

local function visualScan(x, y, timing)
	local yPos = y

	gpu.set(x, yPos, "╞══════════╡")
	yPos = yPos - 1
	os.sleep(timing)

	for i = 1, 3 do
		gpu.set(x, yPos, "╞══════════╡")
		gpu.set(x, yPos + 1, "│          │")
		yPos = yPos - 1
		os.sleep(timing)
	end

	yPos = yPos + 2

	for i = 1, 3 do
		gpu.set(x, yPos, "╞══════════╡")
		gpu.set(x, yPos - 1, "│          │")
		yPos = yPos + 1
		os.sleep(timing)
	end
	gpu.set(x, yPos - 1, "│          │")
end

local function infoPanel(info, background, foreground)
	ecs.square(1, 1, xSize, 3, background)
	ecs.colorText(math.ceil(xSize / 2 - unicode.len(info) / 2), 2, foreground, info)
end

local function drawAll()
	local xPos, yPos = 3, 5
	
	--Как прописывать знаки типа © § ® ™
	
	infoPanel(input or "CodeDoor Protection Enabled", colors.borders, colors.background)

	--кейпад
	gpu.setBackground(colors.background)
	drawKeyPad(xPos, yPos)

	--Био
	xPos = xPos + 18
	ecs.border(xPos, yPos, 12, 6, colors.background, colors.borders)
	ecs.square(xPos + 5, yPos + 2, 2, 2, colors.borders)
	gpu.setBackground(colors.background)
	biometry = {xPos, yPos, xPos + 11, yPos + 5}

	--Био текст
	yPos = yPos + 7
	xPos = xPos + 1
	gpu.set(xPos + 3, yPos, "ECS®")
	gpu.set(xPos + 1, yPos + 1, "Security")
	gpu.set(xPos + 1, yPos + 2, "Systems™")

end

local function checkNickname(name)
	for i = 1, #nicknames do
		if name == nicknames[i] then
			return true
		end
	end
	return false
end

------------------------------------------------------------------------------------------------------------

xSize, ySize = gpu.getResolution()

ecs.prepareToExit(colors.background)

drawAll()

while true do
	local e = {event.pull()}
	if e[1] == "touch" then
		for key in pairs(buttons) do
			if ecs.clickedAtArea(e[3], e[4], buttons[key][1], buttons[key][2], buttons[key][3], buttons[key][4]) then
				ecs.square(buttons[key][1], buttons[key][2], 5, 3, colors.borders)
				gpu.setForeground(colors.background)
				gpu.set(buttons[key][1] + 2, buttons[key][2] + 1, key)
				os.sleep(0.2)

				if key == "*" then
					input = nil
					drawAll()
				elseif key == "#" then
					drawAll()
					if input == password then
						infoPanel("Access granted!", ecs.colors.green, 0xFFFFFF)
					else
						infoPanel("Access denied!", ecs.colors.red, 0xFFFFFF)			
					end
					input = nil
					os.sleep(1)
					drawAll()
				else
					input = (input or "") .. key
					drawAll()
				end

				break
			end
		end

		if ecs.clickedAtArea(e[3], e[4], biometry[1], biometry[2], biometry[3], biometry[4]) then
			visualScan(biometry[1], biometry[2] + 4, 0.08)
			if checkNickname(e[6]) then
				infoPanel("Welcome, " .. e[6], ecs.colors.green, 0xFFFFFF)
			else
				infoPanel("Access denied!", ecs.colors.red, 0xFFFFFF)			
			end
			os.sleep(1)
			drawAll()
		end
	end
end








