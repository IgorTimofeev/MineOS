local component = require("component")
local event = require("event")
local image = require("image")
local ecs = require("ECSAPI")

if not component.isAvailable("modem") then error("Этой программе требуется плата беспроводной сети."); return end

local modem = component.modem
local port1 = 1
modem.open(port1)

modem.broadcast(1, "nanomachines", "setResponsePort", 1)

local oldX, oldY = gpu.getResolution()
gpu.setResolution(80, 25)
ecs.prepareToExit(0xFFFFFF)

local name, minHealth, maxHealth, minHunger, maxHunger, minPower, maxPower, experience
local effects = "Эффекты: недоступно"

local timing = 1

local contacts = {
}
for i = 1, 18 do table.insert(contacts, {false}) end
local scan = {}
local toggle = {}
local exit = {}

local function listener(_, _, _, _, _, header, command, ...)
	if header ~= "nanomachines" then return end
	local data = { ... }
	if command == "name" then
		name = data[1]
	elseif command == "age" then
		age = data[1]
	elseif command == "experience" then
		experience = data[1]
	elseif command == "health" then
		minHealth = data[1]
		maxHealth = data[2]
	elseif command == "hunger" then
		minHunger = data[1]
		maxHunger = data[2]
	elseif command == "power" then
		minPower = data[1]
		maxPower = data[2]
	elseif command == "effects" then
		local cyka = data[1]
		effects = "Эффекты: " .. cyka
	end
end
event.listen("modem_message", listener)

local xFace, yFace = 14, 2
local xInfo, yInfo = xFace + 16 + 2, yFace
local imageCyka = image.load("System/OS/Icons/Steve.pic")
image.draw(xFace, yFace, imageCyka)

local function request()
	local oldPixels = ecs.info("auto", "auto", " ", "Осуществляется запрос к нанороботам. Ждите.")
	modem.broadcast(port1, "nanomachines", "getName"); os.sleep(timing)
	--modem.broadcast(port1, "nanomachines", "getAge"); os.sleep(timing)
	modem.broadcast(port1, "nanomachines", "getExperience"); os.sleep(timing)
	modem.broadcast(port1, "nanomachines", "getHealth"); os.sleep(timing)
	modem.broadcast(port1, "nanomachines", "getHunger"); os.sleep(timing)
	modem.broadcast(port1, "nanomachines", "getPowerState"); os.sleep(timing)
	modem.broadcast(port1, "nanomachines", "getActiveEffects"); os.sleep(timing)
	ecs.drawOldPixels(oldPixels)
end

local function redraw(x, y)
	local xPos, yPos = x, y
	local width = 35
	ecs.square(xPos, yPos, 80, 8, 0xFFFFFF)
	ecs.smartText(xPos, yPos, "§fИмя: §8" .. (name or "недоступно")); yPos = yPos + 1
	ecs.smartText(xPos, yPos, "§fОпыт: §8" .. (experience or "недоступно")); yPos = yPos + 2
	ecs.progressBar(xPos, yPos, width, 1, 0xCCCCCC, ecs.colors.red, math.floor((minHealth or 0) / (maxHealth or 1) * 100))
	ecs.adaptiveText(xPos + math.floor(width / 2) - 4, yPos, "Здоровье", 0xFFFFFF); yPos = yPos + 2
	
	if (maxHunger or 1) < 20 then maxHunger = 20 end
	ecs.progressBar(xPos, yPos, width, 1, 0xCCCCCC, ecs.colors.green, math.floor((minHunger or 0) / (maxHunger or 1) * 100))
	ecs.adaptiveText(xPos + math.floor(width / 2) - 3, yPos, "Голод", 0xFFFFFF); yPos = yPos + 2
	ecs.progressBar(xPos, yPos, width, 1, 0xCCCCCC, ecs.colors.blue, math.floor((minPower or 0) / (maxPower or 1) * 100))
	ecs.adaptiveText(xPos + math.floor(width / 2) - 8, yPos, "Заряд нанороботов", 0xFFFFFF); yPos = yPos + 2

	xPos, yPos = xFace, yFace + 9
	ecs.separator(1, yPos, 80, 0xFFFFFF, 0xCCCCCC)
	yPos = yPos + 1
	
	if effects then
		gpu.setForeground(0x000000)
		ecs.centerText("x", yPos, string.rep(" ", 40) .. effects .. string.rep(" ", 40))
		yPos = yPos + 1
	end
	yPos = yPos + 1
	
	xPos = 14
	for i = 1, #contacts do
		contacts[i][2], contacts[i][3], contacts[i][4], contacts[i][5] = ecs.drawButton(xPos, yPos, 5, 3, tostring(i), (function() if contacts[i][1] then return ecs.colors.blue else return 0xBBBBBB end end)(), 0xFFFFFF)
		xPos = contacts[i][4] + 2
		if i == 9 then yPos = yPos + 4; xPos = 14 end
	end
	yPos = yPos + 4
	xPos = 14
	scan = {ecs.drawAdaptiveButton(xPos, yPos, 2, 1, "Сканирование", 0x444444, 0xFFFFFF)}
	toggle = {ecs.drawAdaptiveButton(scan[3] + 3, yPos, 2, 1, "Переключить контакты", 0x444444, 0xFFFFFF)}
	exit = {ecs.drawAdaptiveButton(toggle[3] + 3, yPos, 2, 1, "Выйти", 0x444444, 0xFFFFFF)}

end

local function switchContacts()
	os.sleep(timing)
	for i = 1, #contacts do
		ecs.info("auto", "auto", " ", "Переключаю "..i.." контакт")
		modem.broadcast(port1, "nanomachines", "setInput", i, contacts[i][1]); os.sleep(timing)
	end
end

redraw(xInfo, yInfo)
request()
redraw(xInfo, yInfo)

while true do
	local e = {event.pull("touch")}
	for i = 1, #contacts do
		if ecs.clickedAtArea(e[3], e[4], contacts[i][2], contacts[i][3], contacts[i][4], contacts[i][5]) then
			contacts[i][1] = not contacts[i][1]
			redraw(xInfo, yInfo)
			break
		end
	end

	if ecs.clickedAtArea(e[3], e[4], scan[1], scan[2], scan[3], scan[4]) then
		ecs.drawAdaptiveButton(scan[1], scan[2], 2, 1, "Сканирование", ecs.colors.red, 0xFFFFFF)
		--os.sleep(0.3)
		request()
		ecs.prepareToExit(0xFFFFFF)
		redraw(xInfo, yInfo)
		image.draw(xFace, yFace, imageCyka)
	elseif ecs.clickedAtArea(e[3], e[4], toggle[1], toggle[2], toggle[3], toggle[4]) then
		ecs.drawAdaptiveButton(toggle[1], toggle[2], 2, 1, "Переключить контакты", ecs.colors.red, 0xFFFFFF)
		--os.sleep(0.3)
		switchContacts()
		ecs.prepareToExit(0xFFFFFF)
		redraw(xInfo, yInfo)
		image.draw(xFace, yFace, imageCyka)
	elseif ecs.clickedAtArea(e[3], e[4], exit[1], exit[2], exit[3], exit[4]) then
		ecs.drawAdaptiveButton(exit[1], exit[2], 2, 1, "Выйти", ecs.colors.red, 0xFFFFFF)
		os.sleep(0.3)
		event.ignore("modem_message", listener)
		gpu.setResolution(oldX, oldY)
		ecs.prepareToExit()
		return
	end

end

event.ignore("modem_message", listener)







