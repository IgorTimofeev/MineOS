
local component = require("component")
local buffer = require("doubleBuffering")
local image = require("image")
local event = require("event")
local ecs = require("ECSAPI")
local serialization = require("serialization")
local unicode = require("unicode")

-------------------------------------------------------------------------------------------------------------------------------------

buffer.start()
local pathToTurretPicture = "MineOS/Applications/TurretControl.app/Resources/Turret.pic"
local turretImage = image.load(pathToTurretPicture)
local turrets = {}
local proxies = {}

local turretConfig = {
	turretsOn = false,
	attacksNeutrals = false,
	attacksPlayers = false,
	attacksMobs = false,
}

local yTurrets = 2
local spaceBetweenTurretsHorizontal = 2
local spaceBetweenTurretsVertical = 1
local turretHeight = turretImage.height + 12
local turretWidth = turretImage.width + 8
local countOfTurretsCanBeShowByWidth = math.floor(buffer.screen.width / (turretWidth + spaceBetweenTurretsHorizontal))
local xTurrets = math.floor(buffer.screen.width / 2 - (countOfTurretsCanBeShowByWidth * (turretWidth + spaceBetweenTurretsHorizontal)) / 2 ) + math.floor(spaceBetweenTurretsHorizontal / 2)

local yellowColor = 0xFFDB40

-------------------------------------------------------------------------------------------------------------------------------------

--Объекты
local obj = {}
local function newObj(class, name, ...)
	obj[class] = obj[class] or {}
	obj[class][name] = {...}
end

local function getProxiesOfAllComponents(name)
	for address in pairs(component.list(name)) do
		table.insert(proxies, component.proxy(address))
	end
end

local function getTurrets()

	turretConfig.turretsOn = false
	turretConfig.attacksNeutrals = false
	turretConfig.attacksPlayers = false
	turretConfig.attacksMobs = false

	getProxiesOfAllComponents("tierOneTurretBase")
	getProxiesOfAllComponents("tierTwoTurretBase")
	getProxiesOfAllComponents("tierThreeTurretBase")
	getProxiesOfAllComponents("tierFourTurretBase")
	getProxiesOfAllComponents("tierFiveTurretBase")

	for i = 1, #proxies do
		-- print(proxies[i].type)
		if type(proxies[i].getCurrentEnergyStorage()) ~= "string" then
			local turret = {}
			turret.type = proxies[i].type
			-- turret.isActive = (proxies[i].isAttacksPlayers() and proxies[i].isAttacksMobs()) and true or false
			turret.energyPercent = math.ceil(proxies[i].getCurrentEnergyStorage() / proxies[i].getMaxEnergyStorage() * 100)
			turret.proxy = proxies[i]
			table.insert(turrets, turret)

			turret.isActive = false
			turret.proxy.setAttacksNeutrals(false)
			turret.proxy.setAttacksPlayers(false)
			turret.proxy.setAttacksMobs(false)
		end
	end
end

local function progressBar(x, y, width, height, background, foreground, percent)
	buffer.square(x, y, width, height, background)
	buffer.frame(x, y, width, height, foreground)
	width = width - 2
	local cykaWidth = math.ceil(width * percent / 100)
	buffer.text(x + 1, y + 1, foreground, string.rep("▒", cykaWidth))
end

local function drawTurrets(y)
	local counter = 0
	local x = xTurrets

	if #turrets <= 0 then 
		local text = "Подключите турели из мода OpenModularTurrets"
		local x = math.floor(buffer.screen.width / 2 - unicode.len(text) / 2)
		buffer.text(x, math.floor(buffer.screen.height / 2 - 2), yellowColor, text)
		return
	end

	for turret = 1, #turrets do
		local yPos = y
		buffer.frame(x, yPos, turretWidth, turretHeight, yellowColor)
		yPos = yPos + 1
		buffer.text(x + 2, yPos, yellowColor, ecs.stringLimit("end", "Турель " .. turrets[turret].proxy.address, turretWidth - 4))
		yPos = yPos + 2
		buffer.image(x + 4, yPos, turretImage)
		yPos = yPos + turretImage.height + 1
		buffer.text(x + 2, yPos, yellowColor, "Энергия:")
		yPos = yPos + 1
		progressBar(x + 1, yPos, turretWidth - 2, 3, 0x000000, yellowColor, turrets[turret].energyPercent)
		yPos = yPos + 4
		local widthOfButton = 13
		-- local isActive = turrets[turret].getActive()
		local isActive = turrets[turret].isActive
		newObj("TurretOn", turret, buffer.button(x + 2, yPos, widthOfButton, 1, isActive and yellowColor or 0x000000, isActive and 0x000000 or yellowColor, "ВКЛ"))
		obj.TurretOn[turret].proxy = turrets[turret].proxy
		newObj("TurretOff", turret, buffer.button(x + 2 + widthOfButton + 2, yPos, widthOfButton, 1, not isActive and yellowColor or 0x000000, not isActive and 0x000000 or yellowColor, "ВЫКЛ"))
		yPos = yPos + 1

		x = x + turretWidth + spaceBetweenTurretsHorizontal
		counter = counter + 1
		if counter % countOfTurretsCanBeShowByWidth == 0 then
			x = xTurrets
			y = y + turretHeight + spaceBetweenTurretsVertical
		end
	end
end

local function drawSeparator(y)
	buffer.text(1, y, yellowColor, string.rep("─", buffer.screen.width))
end

local function drawButtonWithState(x, y, width, height, text, state)
	if state then
		buffer.button(x, y, width, height, yellowColor, 0x000000, text)
	else
		buffer.framedButton(x, y, width, height, 0x000000, yellowColor, text)
	end

	return (x + width + 1)
end

local function drawBottomBar()
	local height = 6
	local y = buffer.screen.height - height + 1
	buffer.square(1, y, buffer.screen.width, height, 0x000000, yellowColor, " ")
	drawSeparator(y)
	local text = " ECS® Security Systems™ "
	local x = math.floor(buffer.screen.width / 2 - unicode.len(text) / 2)
	buffer.text(x, y, yellowColor, text)

	y = y + 2

	local widthOfButton = 19
	local totalWidth = (widthOfButton + 2) * 6
	local x = math.floor(buffer.screen.width / 2 - totalWidth / 2) + 1

	newObj("BottomButtons", "On", x, y, x + widthOfButton - 1, y + 2)
	x = drawButtonWithState(x, y, widthOfButton, 3, turretConfig.turretsOn and "Турели ВКЛ" or "Турели ВЫКЛ", turretConfig.turretsOn)
	newObj("BottomButtons", "AddPlayer", x, y, x + widthOfButton - 1, y + 2)
	x = drawButtonWithState(x, y, widthOfButton, 3, "Добавить игрока", false)
	newObj("BottomButtons", "AttacksMobs", x, y, x + widthOfButton - 1, y + 2)
	x = drawButtonWithState(x, y, widthOfButton, 3, "Атака мобов", turretConfig.attacksMobs)
	newObj("BottomButtons", "AttacksNeutrals", x, y, x + widthOfButton - 1, y + 2)
	x = drawButtonWithState(x, y, widthOfButton, 3, "Атака нейтралов", turretConfig.attacksNeutrals)
	newObj("BottomButtons", "AttacksPlayers", x, y, x + widthOfButton - 1, y + 2)
	x = drawButtonWithState(x, y, widthOfButton, 3, "Атака игроков", turretConfig.attacksPlayers)
	newObj("BottomButtons", "Exit", x, y, x + widthOfButton - 1, y + 2)
	x = drawButtonWithState(x, y, widthOfButton, 3, "Выход", false)
end

local function drawAll()
	buffer.clear(0x000000)
	drawTurrets(yTurrets)
	drawBottomBar()
	buffer.draw()
end

local function refresh()
	turrets = {}
	proxies = {}
	getTurrets()
	drawAll()
end

local function changeTurretState(i, state)
	turrets[i].isActive = state
	turrets[i].energyPercent = math.ceil(turrets[i].proxy.getCurrentEnergyStorage() / turrets[i].proxy.getMaxEnergyStorage() * 100)
	if state == true then
		turrets[i].proxy.setAttacksNeutrals(turretConfig.attacksNeutrals)
		turrets[i].proxy.setAttacksPlayers(turretConfig.attacksPlayers)
		turrets[i].proxy.setAttacksMobs(turretConfig.attacksMobs)
	else
		turrets[i].proxy.setAttacksNeutrals(false)
		turrets[i].proxy.setAttacksPlayers(false)
		turrets[i].proxy.setAttacksMobs(false)
	end
end

-------------------------------------------------------------------------------------------------------------------------------------

refresh()

while true do
	local e = {event.pull()}
	if e[1] == "touch" then
		for key in pairs(obj.TurretOn) do
			if ecs.clickedAtArea(e[3], e[4], obj.TurretOn[key][1], obj.TurretOn[key][2], obj.TurretOn[key][3], obj.TurretOn[key][4]) then
				changeTurretState(key, true)
				drawAll()
				break
			end
		end

		for key in pairs(obj.TurretOff) do
			if ecs.clickedAtArea(e[3], e[4], obj.TurretOff[key][1], obj.TurretOff[key][2], obj.TurretOff[key][3], obj.TurretOff[key][4]) then
				changeTurretState(key, false)
				drawAll()
				break
			end
		end

		for key in pairs(obj.BottomButtons) do
			if ecs.clickedAtArea(e[3], e[4], obj.BottomButtons[key][1], obj.BottomButtons[key][2], obj.BottomButtons[key][3], obj.BottomButtons[key][4]) then
				if key == "On" then
					turretConfig.turretsOn = not turretConfig.turretsOn
					for i = 1, #turrets do changeTurretState(i, turretConfig.turretsOn) end
					drawAll()
				elseif key == "AttacksNeutrals" then
					turretConfig.attacksNeutrals = not turretConfig.attacksNeutrals
					for i = 1, #turrets do changeTurretState(i, turrets[i].isActive) end
					drawAll()
				elseif key == "AttacksMobs" then
					turretConfig.attacksMobs = not turretConfig.attacksMobs
					for i = 1, #turrets do changeTurretState(i, turrets[i].isActive) end
					drawAll()
				elseif key == "AttacksPlayers" then
					turretConfig.attacksPlayers = not turretConfig.attacksPlayers
					for i = 1, #turrets do changeTurretState(i, turrets[i].isActive) end
					drawAll()
				elseif key == "AddPlayer" then
					buffer.button(obj.BottomButtons[key][1], obj.BottomButtons[key][2], 19, 3, yellowColor, 0x000000, "Добавить игрока")
					buffer.draw()
					os.sleep(0.2)
					drawAll()
					local data = ecs.universalWindow("auto", "auto", 30, 0x1e1e1e, true, {"EmptyLine"}, {"CenterText", ecs.colors.orange, "Добавить игрока"}, {"EmptyLine"}, {"Input", 0xFFFFFF, ecs.colors.orange, "Никнейм"}, {"EmptyLine"}, {"Button", {ecs.colors.orange, 0xffffff, "OK"}, {0x999999, 0xffffff, "Отмена"}} )
					if data[2] == "OK" then for i = 1, #turrets do turrets[i].proxy.addTrustedPlayer(data[1]) end end
				elseif key == "Exit" then
					buffer.button(obj.BottomButtons[key][1], obj.BottomButtons[key][2], 19, 3, yellowColor, 0x000000, "Выход")
					buffer.draw()
					os.sleep(0.2)
					buffer.clear(0x262626)
					ecs.prepareToExit()
					return
				end

				break
			end
		end

	elseif e[1] == "scroll" then
		if e[5] == 1 then
			yTurrets = yTurrets + 2
		else
			yTurrets = yTurrets - 2
		end
		drawAll()
	elseif e[1] == "component_added" or e[1] == "component_removed" then
		if e[3] == "tierOneTurretBase" or e[3] == "tierTwoTurretBase" or e[3] == "tierThreeTurretBase" or e[3] == "tierFourTurretBase" or e[3] == "tierFiveTurretBase" then
			refresh()
		end
	end
end











