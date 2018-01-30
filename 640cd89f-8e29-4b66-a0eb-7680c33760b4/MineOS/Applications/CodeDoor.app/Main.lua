local rs
local component = require("component")
local gpu = component.gpu
local unicode = require("unicode")
local ecs = require("ECSAPI")
local sides = require("sides")
local event = require("event")
local fs = require("filesystem")
local serialization = require("serialization")

if not component.isAvailable("redstone") then
	ecs.error("This program requires Redstone I/O block or Redstone Card to work.")
	return
else
	rs = component.redstone
end

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

local showPassword = true
local showKeyPresses = true

local nicknames = {
	"IgorTimofeev"
}

local pathToConfig = "System/CodeDoor/Config.cfg"
local function saveConfig()
	local file = io.open(pathToConfig, "w")
	local massiv = {["password"] = password, ["nicknames"] = nicknames, ["showPassword"] = showPassword, ["showKeyPresses"] = showKeyPresses}
	file:write(serialization.serialize(massiv))
	file:close()
end

local function loadConfig()
	if fs.exists(pathToConfig) then
		local massiv = {}
		local file = io.open(pathToConfig, "r")
		local stroka = file:read("*a")
		massiv = serialization.unserialize(stroka)
		file:close()
		nicknames = massiv.nicknames
		password = massiv.password
		showPassword = massiv.showPassword
		showKeyPresses = massiv.showKeyPresses
	else
		fs.makeDirectory(fs.path(pathToConfig))
		local data = ecs.universalWindow("auto", "auto", 30, 0xEEEEEE, true, {"EmptyLine"}, {"CenterText", 0x880000, "Добро пожаловать в программу"}, {"CenterText", 0x880000, "конфигурации кодовой двери!"},  {"EmptyLine"},  {"CenterText", 0x262626, "Введите ваш пароль:"}, {"Input", 0x262626, 0x880000, "12345"}, {"EmptyLine"}, {"Switch", 0xF2B233, 0xffffff, 0x262626, "Показывать вводимый пароль", true}, {"EmptyLine"}, {"Switch", 0x3366CC, 0xffffff, 0x262626, "Показывать нажатие клавиш", true}, {"EmptyLine"}, {"Button", {0xbbbbbb, 0xffffff, "OK"}})
		if data[1] == "" or tonumber(data[1]) == nil then ecs.error("Указан неверный пароль. По умолчанию он будет 12345."); password = "12345" else password = data[1] end
		showPassword = data[2]
		showKeyPresses = data[3]
		saveConfig()
	end 
end

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
	gpu.setBackground(colors.background)
	gpu.setForeground(colors.borders)

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

local function infoPanel(info, background, foreground, hideData)
	ecs.square(1, 1, xSize, 3, background)
	local text	if hideData then
		text = ecs.stringLimit("start", string.rep("*", unicode.len(info)), xSize - 4)
	else
		text = ecs.stringLimit("start", info, xSize - 4)
	end
	ecs.colorText(math.ceil(xSize / 2 - unicode.len(text) / 2) + 1 , 2, foreground, text)
end

local function drawAll()
	local xPos, yPos = 3, 5
	
	--Как прописывать знаки типа © § ® ™
	
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

local function pressButton(x, y, name)
	ecs.square(x, y, 5, 3, colors.borders)
	gpu.setForeground(colors.background)
	gpu.set(x + 2, y + 1, name)
	os.sleep(0.2)
end

local function waitForExit()
	local e2 = {event.pull(3, "touch")}
	if #e2 > 0 then
		if ecs.clickedAtArea(e2[3], e2[4], buttons["*"][1], buttons["*"][2], buttons["*"][3], buttons["*"][4]) then
			pressButton(buttons["*"][1], buttons["*"][2], "*")
			return true
		end
	end
	return false
end

local function redstone(go)
	if go then
		rs.setOutput(sides.top, 15)
		local goexit = waitForExit()
		rs.setOutput(sides.top, 0)
		rs.setOutput(sides.bottom, 0)
		return goexit
	else
		rs.setOutput(sides.bottom, 15)
		os.sleep(2)
		rs.setOutput(sides.top, 0)
		rs.setOutput(sides.bottom, 0)
	end
	return false
end

------------------------------------------------------------------------------------------------------------

ecs.prepareToExit(colors.background)
loadConfig()

local oldWidth, oldHeight = gpu.getResolution()
gpu.setResolution(34, 17)
xSize, ySize = 34, 17

drawAll()
infoPanel("Введите пароль", colors.borders, colors.background)

while true do
	local e = {event.pull()}
	if e[1] == "touch" then
		for key in pairs(buttons) do
			if ecs.clickedAtArea(e[3], e[4], buttons[key][1], buttons[key][2], buttons[key][3], buttons[key][4]) then
				
				if showKeyPresses then
					pressButton(buttons[key][1], buttons[key][2], key)
				end

				if key == "*" then
					input = nil
					infoPanel("Поле ввода очищено", colors.borders, colors.background)
				elseif key == "#" then
					drawAll()
					if input == password then
						infoPanel("Доступ разрешён!", ecs.colors.green, 0xFFFFFF)
						local goexit = redstone(true)
						for i = 1, #nicknames do
							if nicknames[i] == e[6] then nicknames[i] = nil end
						end
						table.insert(nicknames, e[6])
						saveConfig()

						if goexit then
							ecs.prepareToExit()
							gpu.setResolution(oldWidth, oldHeight)
							ecs.prepareToExit()
							return
						end
					else
						infoPanel("Доступ запрещён!", ecs.colors.red, 0xFFFFFF)
						redstone(false)		
					end
					infoPanel("Введите пароль", colors.borders, colors.background)
					input = nil
				else
					input = (input or "") .. key
					
					infoPanel(input, colors.borders, colors.background, not showPassword)
				end
				drawAll()

				break
			end
		end

		if ecs.clickedAtArea(e[3], e[4], biometry[1], biometry[2], biometry[3], biometry[4]) then
			visualScan(biometry[1], biometry[2] + 4, 0.08)
			if checkNickname(e[6]) then
				infoPanel("Привет, " .. e[6], ecs.colors.green, 0xFFFFFF)
				redstone(true)
			else
				infoPanel("В доступе отказано!", ecs.colors.red, 0xFFFFFF)
				redstone(false)		
			end
			infoPanel("Введите пароль", colors.borders, colors.background)
			drawAll()
		end
	end
end








