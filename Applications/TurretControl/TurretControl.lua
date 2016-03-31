
local component = require("component")
local buffer = require("doubleBuffering")
local image = require("image")
local event = require("event")
local ecs = require("ECSAPI")
local serialization = require("serialization")
local unicode = require("unicode")

buffer.start()
local pathToTurretPicture = "turret.pic"
local turretImage = image.load(pathToTurretPicture)
local turrets = {}
local proxies = {}
local turretConfig = {
	attackPlayers = true,
	attackNeutrals = false,
	attackMobs = true,
}

local yTurrets = 2
local spaceBetweenTurretsHorizontal = 2
local spaceBetweenTurretsVertical = 1
local turretHeight = turretImage.height + 12
local turretWidth = turretImage.width + 8
local countOfTurretsCanBeShowByWidth = math.floor(buffer.screen.width / (turretWidth + spaceBetweenTurretsHorizontal))
local xTurrets = math.floor(buffer.screen.width / 2 - (countOfTurretsCanBeShowByWidth * (turretWidth + spaceBetweenTurretsHorizontal)) / 2 ) + math.floor(spaceBetweenTurretsHorizontal / 2)

local yellowColor = 0xFFDB40

local function getProxiesOfAllComponents(name)
	for address in pairs(component.list(name)) do
		table.insert(proxies, component.proxy(address))
	end
end

local function getTurrets()
	getProxiesOfAllComponents("tierOneTurretBase")
	getProxiesOfAllComponents("tierTwoTurretBase")
	getProxiesOfAllComponents("tierThreeTurretBase")
	getProxiesOfAllComponents("tierFourTurretBase")
	getProxiesOfAllComponents("tierFiveTurretBase")
	for i = 1, #proxies do
		if type(proxies[i].getCurrentEnergyStorage()) ~= "string" then
			local turret = {}
			turret.address = proxies[i].address
			turret.type = proxies[i].type
			turret.isActive = proxies[i].getActive()
			turret.energyPercent = math.ceil(proxies[i].getCurrentEnergyStorage() / proxies[i].getMaxEnergyStorage() * 100)
			table.insert(turrets, turret)
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

local function enableOrDisableEveryTurret(enable)
	for turret = 1, #turrets do
		turrets[turrets].setActive(enable)
	end
end

local function changeUserListOnEveryTurret(userlist)
	for i = 1, #userlist do

	end
end

local function drawTurrets(y)
	local counter = 0
	local x = xTurrets

	for turret = 1, #turrets do
		local yPos = y
		buffer.frame(x, yPos, turretWidth, turretHeight, yellowColor)
		yPos = yPos + 1
		buffer.text(x + 2, yPos, yellowColor, ecs.stringLimit("end", "Турель " .. turrets[turret].address, turretWidth - 4))
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
		buffer.button(x + 2, yPos, widthOfButton, 1, isActive and yellowColor or 0x000000, isActive and 0x000000 or yellowColor, "ВКЛ")
		buffer.button(x + 2 + widthOfButton + 2, yPos, widthOfButton, 1, not isActive and yellowColor or 0x000000, not isActive and 0x000000 or yellowColor, "ВЫКЛ")
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

local function drawBottomBar()
	local height = 6
	local y = buffer.screen.height - height + 1
	buffer.square(1, y, buffer.screen.width, height, 0x000000, yellowColor, " ")
	drawSeparator(y)
	local text = " ECS® Security Systems™ "
	local x = math.floor(buffer.screen.width / 2 - unicode.len(text) / 2)
	buffer.text(x, y, yellowColor, text)

	y = y + 2

	local widthOfButton = 17
	local totalWidth = (widthOfButton + 2) * 6
	local x = math.floor(buffer.screen.width / 2 - totalWidth / 2) + 1

	buffer.button(x, y, widthOfButton, 3, yellowColor, 0x000000, "Турели ВКЛ"); x = x + widthOfButton + 2
	buffer.button(x, y, widthOfButton, 3, yellowColor, 0x000000, "Турели ВЫКЛ"); x = x + widthOfButton + 2
	buffer.button(x, y, widthOfButton, 3, yellowColor, 0x000000, "Добавить игрока"); x = x + widthOfButton + 2
	if turretConfig.attackMobs then
		buffer.button(x, y, widthOfButton, 3, yellowColor, 0x000000, "Атака мобов"); x = x + widthOfButton + 2
	else
		buffer.framedButton(x, y, widthOfButton, 3, 0x000000, yellowColor, "Атака мобов"); x = x + widthOfButton + 2
	end
	if turretConfig.attackNeutrals then
		buffer.button(x, y, widthOfButton, 3, yellowColor, 0x000000, "Атака нейтралов"); x = x + widthOfButton + 2
	else
		buffer.framedButton(x, y, widthOfButton, 3, 0x000000, yellowColor, "Атака нейтралов"); x = x + widthOfButton + 2
	end
	if turretConfig.attackPlayers then
		buffer.button(x, y, widthOfButton, 3, yellowColor, 0x000000, "Атака игроков"); x = x + widthOfButton + 2
	else
		buffer.framedButton(x, y, widthOfButton, 3, 0x000000, yellowColor, "Атака игроков"); x = x + widthOfButton + 2
	end
end

local function drawAll()
	buffer.clear(0x000000)
	drawTurrets(yTurrets)
	drawBottomBar()
	buffer.draw()
end

local function refresh()
	getTurrets()
	drawAll()
end

refresh()

while true do
	local e = {event.pull()}
	if e[1] == "touch" then

	elseif e[1] == "scroll" then
		if e[5] == 1 then
			yTurrets = yTurrets - 2
		else
			yTurrets = yTurrets + 2
		end
		drawAll()
	end
end











