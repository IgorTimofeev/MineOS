local event = require("event")
local c = require("component")
local unicode = require("unicode")
local gpu = c.gpu

--------------------------------------------------------------------------------------------------------

local currentMode = 3
local xSize, ySize = gpu.getResolution()

local rarityColors = {
	["Immortal"] = 0xff9200,
	["Rare"] = 0x3349ff,
	["Uncommon"] = 0x66b6ff,
	["Common"] = 0xccdbff,
	["Mythical"] = 0x9900bf,
	["Arcana"] = 0x66ff00,
}

local colors = {
	["background"] = 0x262626,
	["topbar"] = 0xeeeeee,
	["topbarText"] = 0x444444,
	["topbarButton"] = ecs.colors.blue,
	["topbarButtonText"] = 0xffffff,
	["inventoryBorder"] = 0xffffff,
	["inventoryBorderSelect"] = ecs.colors.blue,
	["inventoryText"] = 0xffffff,
	["inventoryTextDarker"] = 0xaaaaaaa,
}

--------------------------------------------------------------------------------------------------------

local massivWithProfile = {
	["name"] = "IT",
	["money"] = 1000000,
	["inventory"] = {
		{
			["id"] = "minecraft:stone",
			["label"] = "Stone",
			["data"] = 0,
			["count"] = 64,
			["rarity"] = "Immortal",
		},
		{
			["id"] = "minecraft:grass",
			["data"] = 0,
			["label"] = "Grass",
			["count"] = 32,
			["rarity"] = "Arcana",
		},
		{
			["id"] = "minecraft:wool",
			["data"] = 14,
			["label"] = "Red wool",
			["count"] = 12,
		},
		{
			["id"] = "minecraft:wool",
			["data"] = 14,
			["label"] = "Red wool",
			["count"] = 12,
		},
	},
}

--Показ инвентаря
local function showInventory(x, y, massivOfInventory, page, currentItem)
	local widthOfOneElement = 12
	local heightOfOneElement = widthOfOneElement / 2
	local xSpaceBetweenElements = 1
	local ySpaceBetweenEmenents = 0
	local widthOfItemInfoPanel = 20
	local width = math.floor((xSize - widthOfItemInfoPanel - 4) / (widthOfOneElement + xSpaceBetweenElements))
	local height = math.floor((ySize - 8) / (heightOfOneElement + ySpaceBetweenEmenents))
	currentItem = currentItem or 1

	--Рисуем айтемы
	local borderColor, itemCounter, xPos, yPos = nil, nil, x, y
	for j = 1, height do
		xPos = x
		for i = 1, width do
			--Получаем номер предмета с учетом всего
			local itemCounter = ((j - 1) * width + i + page * width * height - width * height)

			--Если такой предмет вообще существует
			if massivOfInventory.inventory[itemCounter] then
				--Делаем цвет рамки
				if itemCounter == currentItem then borderColor = colors.inventoryBorderSelect else borderColor = colors.inventoryBorder end
				--Рисуем рамку
				ecs.border(xPos, yPos, widthOfOneElement, heightOfOneElement, colors.background, borderColor)
				--Рисуем текст в рамке
				ecs.colorText(xPos + 2, yPos + 2, colors.inventoryText, ecs.stringLimit("end", massivOfInventory.inventory[itemCounter].label, widthOfOneElement - 2))
				ecs.colorText(xPos + 2, yPos + 3, colors.inventoryTextDarker, ecs.stringLimit("end", tostring(massivOfInventory.inventory[itemCounter].count), widthOfOneElement - 2))
				
			else
				break
			end
			xPos = xPos + widthOfOneElement + xSpaceBetweenElements
		end
		yPos = yPos + heightOfOneElement + ySpaceBetweenEmenents
	end

	--Рисуем инфу о кнкретном айтеме
	xPos = x + (widthOfOneElement + xSpaceBetweenElements) * width
	yPos = y
	--Рамку рисуем
	ecs.border(xPos, yPos, xSize - xPos - 2, height * (heightOfOneElement + ySpaceBetweenEmenents), colors.background, colors.inventoryBorder)
	yPos = yPos + 2
	xPos = xPos + 2
	local currentRarity = massivOfInventory.inventory[currentItem].rarity or "Common"
	ecs.colorText(xPos, yPos, colors.inventoryText, massivOfInventory.inventory[currentItem].label); yPos = yPos + 1
	ecs.colorText(xPos, yPos, rarityColors[currentRarity], currentRarity); yPos = yPos + 1
	ecs.colorText(xPos, yPos, colors.inventoryTextDarker, "ID: " .. massivOfInventory.inventory[currentItem].id); yPos = yPos + 1
	ecs.colorText(xPos, yPos, colors.inventoryTextDarker, "Цвет: " .. massivOfInventory.inventory[currentItem].data); yPos = yPos + 1
	ecs.colorText(xPos, yPos, colors.inventoryTextDarker, "Количество: " .. massivOfInventory.inventory[currentItem].count); yPos = yPos + 1

end

local function sell()
	--Показываем инвентарь
	showInventory(3, 5, massivWithProfile, 1, 2)
end

local function main()
	--Кнопы
	local topButtons = {{"🏠", "Главная"}, {"⟱", "Купить"}, {"⟰", "Продать"}, {"☯", "Лотерея"},{"€", "Мой профиль"}}
	--Расстояние между кнопами
	local spaceBetweenTopButtons = 2
	--Считаем ширину
	local widthOfTopButtons = 0
	for i = 1, #topButtons do
		topButtons[i][3] = unicode.len(topButtons[i][2]) + 2
		widthOfTopButtons = widthOfTopButtons + topButtons[i][3] + spaceBetweenTopButtons
	end
	--Считаем коорду старта кноп
	local xStartOfTopButtons = math.floor(xSize / 2 - widthOfTopButtons / 2)

	--Рисуем топбар
	ecs.square(1, 1, xSize, 3, colors.topbar)

	--Рисуем белую подложку
	ecs.square(1, 4, xSize, ySize - 3, colors.background)

	--Отрисовка одной кнопки
	local function drawButton(i, x)
		local back, fore
		if i == currentMode then
			back = colors.topbarButton
			fore = colors.topbarButtonText
		else
			back = colors.topbar
			fore = colors.topbarText
		end	

		ecs.drawButton(x, 1, topButtons[i][3], 2, topButtons[i][1], back, fore)
		ecs.drawButton(x, 3, topButtons[i][3], 1, topButtons[i][2], back, fore)
	end

	--Рисуем топ кнопочки
	for i = 1, #topButtons do
		drawButton(i, xStartOfTopButtons)
		xStartOfTopButtons = xStartOfTopButtons + topButtons[i][3] + spaceBetweenTopButtons
	end

	--Запускаем нужный режим работы проги
	if currentMode == 3 then
		sell()
	end
end

main()


ecs.error("Программа разрабатывается. По сути это будет некий аналог Торговой Площадки Стима с разными доп. фичами.")
