
local text = require("Text")
local number = require("Number")
local color = require("Color")
local image = require("Image")
local screen = require("Screen")
local GUI = require("GUI")
local event = require("Event")
local filesystem = require("Filesystem")

---------------------------------------------------- Константы ------------------------------------------------------------------

local rayEngine = {}

rayEngine.debugInformationEnabled = true
rayEngine.minimapEnabled = true
rayEngine.compassEnabled = false
rayEngine.watchEnabled = false
rayEngine.drawFieldOfViewOnMinimap = false
rayEngine.chatShowTime = 4
rayEngine.chatHistory = {}

---------------------------------------------- Расчетные функции ------------------------------------------------------------------

-- Позиция горизонта, относительно которой рисуется мир
function rayEngine.calculateHorizonPosition()
	rayEngine.horizonPosition = math.floor(screen.getHeight() / 2)
end

-- Размер панели чата и лимита его истории
function rayEngine.calculateChatSize()
	rayEngine.chatPanelWidth, rayEngine.chatPanelHeight = math.floor(screen.getWidth() * 0.4), math.floor(screen.getHeight() * 0.4)
	rayEngine.chatHistoryLimit = rayEngine.chatPanelHeight
end

-- Шаг, с которым будет изменяться угол рейкаста
function rayEngine.calculateRaycastStep()
	rayEngine.raycastStep = rayEngine.player.fieldOfView / screen.getWidth()
end

-- Позиция оружия на экране и всех его вспомогательных текстур
function rayEngine.calculateWeaponPosition()
	rayEngine.currentWeapon.xWeapon = screen.getWidth() - rayEngine.currentWeapon.weaponTexture[1] + 1
	rayEngine.currentWeapon.yWeapon = screen.getHeight() - rayEngine.currentWeapon.weaponTexture[2] + 1
	rayEngine.currentWeapon.xFire = rayEngine.currentWeapon.xWeapon + rayEngine.weapons[rayEngine.currentWeapon.ID].firePosition.x
	rayEngine.currentWeapon.yFire = rayEngine.currentWeapon.yWeapon + rayEngine.weapons[rayEngine.currentWeapon.ID].firePosition.y
	rayEngine.currentWeapon.xCrosshair = math.floor(screen.getWidth() / 2 - rayEngine.currentWeapon.crosshairTexture[1] / 2)
	rayEngine.currentWeapon.yCrosshair = math.floor(screen.getHeight() / 2 - rayEngine.currentWeapon.crosshairTexture[2] / 2)
end

-- Грубо говоря, это расстояние от камеры до виртуального экрана, на котором рисуется весь наш мир, влияет на размер блоков
function rayEngine.calculateDistanceToProjectionPlane()
	rayEngine.distanceToProjectionPlane = (screen.getWidth() / 2) / math.tan(math.rad((rayEngine.player.fieldOfView / 2)))
end

-- Быстрый перерасчет всего, что нужно
function rayEngine.calculateAllParameters()
	rayEngine.calculateHorizonPosition()
	rayEngine.calculateChatSize()
	rayEngine.calculateRaycastStep()
	rayEngine.calculateDistanceToProjectionPlane()
	if rayEngine.currentWeapon then rayEngine.calculateWeaponPosition() end
end

---------------------------------------------- Вспомогательные функции ------------------------------------------------------------------

local function constrainAngle(value)
	if ( value < 0 ) then
		value = value + 360
	elseif ( value > 360 )  then
		value = value - 360
	end
	return value
end

local function getSkyColorByTime()
	return rayEngine.world.colors.sky[rayEngine.world.dayNightCycle.currentTime > 0 and math.ceil(rayEngine.world.dayNightCycle.currentTime / rayEngine.world.dayNightCycle.length * #rayEngine.world.colors.sky) or 1]
end

local function getBrightnessByTime()
	return rayEngine.properties.shadingTransparencyMap[rayEngine.world.dayNightCycle.currentTime > 0 and math.ceil(rayEngine.world.dayNightCycle.currentTime / rayEngine.world.dayNightCycle.length * #rayEngine.properties.shadingTransparencyMap) or 1]
end

local function getTileColor(basecolor, distance)
	local limitedDistance = math.floor(distance * rayEngine.properties.shadingCascades / rayEngine.properties.shadingDistance)
	local transparency = rayEngine.currentShadingTransparencyMapValue - limitedDistance / rayEngine.properties.shadingCascades
	transparency = (transparency >= rayEngine.properties.shadingTransparencyMap[1] and transparency <= 1) and transparency or rayEngine.properties.shadingTransparencyMap[1]	
	return color.blend(basecolor, 0x000000, transparency)
end

function rayEngine.refreshTimeDependentColors()
	rayEngine.world.colors.sky.current = getSkyColorByTime()
	rayEngine.currentShadingTransparencyMapValue = getBrightnessByTime()
	rayEngine.world.colors.groundByTime = color.blend(rayEngine.world.colors.ground, 0x000000, rayEngine.currentShadingTransparencyMapValue)
end

local function doDayNightCycle()
	if rayEngine.world.dayNightCycle.enabled then
		local computerUptime = computer.uptime()
		if (computerUptime - rayEngine.world.dayNightCycle.lastComputerUptime) >= rayEngine.world.dayNightCycle.speed then
			rayEngine.world.dayNightCycle.currentTime = rayEngine.world.dayNightCycle.currentTime + rayEngine.world.dayNightCycle.speed
			if rayEngine.world.dayNightCycle.currentTime > rayEngine.world.dayNightCycle.length then rayEngine.world.dayNightCycle.currentTime = 0 end	
			rayEngine.world.dayNightCycle.lastComputerUptime = computerUptime

			rayEngine.refreshTimeDependentColors()
		end
	end
end

local function convertWorldCoordsToMapCoords(x, y)
	return number.round(x / rayEngine.properties.tileWidth), number.round(y / rayEngine.properties.tileWidth)
end

local function getBlockCoordsByLook(distance)
	local radRotation = math.rad(rayEngine.player.rotation)
	return convertWorldCoordsToMapCoords(rayEngine.player.position.x + distance * math.sin(radRotation) * rayEngine.properties.tileWidth, rayEngine.player.position.y + distance * math.cos(radRotation) * rayEngine.properties.tileWidth)
end

---------------------------------------------------- Работа с файлами ------------------------------------------------------------------

-- Загрузка параметров движка
function rayEngine.loadEngineProperties(pathToRayEnginePropertiesFile)
	rayEngine.properties = filesystem.readTable(pathToRayEnginePropertiesFile)
end

-- Загрузка конифгурации оружия
function rayEngine.loadWeapons(pathToWeaponsFolder)
	rayEngine.weaponsFolder = pathToWeaponsFolder
	rayEngine.weapons = filesystem.readTable(rayEngine.weaponsFolder .. "Weapons.cfg")
	rayEngine.changeWeapon(1)
end

-- Загрузка конкретного мира
function rayEngine.loadWorld(pathToWorldFolder)
	rayEngine.world = filesystem.readTable(pathToWorldFolder .. "/World.cfg")
	rayEngine.map = filesystem.readTable(pathToWorldFolder .. "/Map.cfg")
	rayEngine.player = filesystem.readTable(pathToWorldFolder .. "/Player.cfg")
	rayEngine.blocks = filesystem.readTable(pathToWorldFolder .. "/Blocks.cfg")
	-- Дополняем карту ее размерами
	rayEngine.map.width = #rayEngine.map[1]
	rayEngine.map.height = #rayEngine.map
	-- Ебашим правильную позицию игрока, основанную на этой ХУЙНЕ, которую ГЛЕБ так ЛЮБИТ
	rayEngine.player.position.x = rayEngine.properties.tileWidth * rayEngine.player.position.x - rayEngine.properties.tileWidth / 2
	rayEngine.player.position.y = rayEngine.properties.tileWidth * rayEngine.player.position.y - rayEngine.properties.tileWidth / 2
	-- Рассчитываем цвета, зависимые от времени - небо, землю, стены
	rayEngine.refreshTimeDependentColors()
	-- Обнуляем текущее время, если превышен лимит, а то мало ли какой пидорас начнет править конфиги мира
	rayEngine.world.dayNightCycle.currentTime = rayEngine.world.dayNightCycle.currentTime > rayEngine.world.dayNightCycle.length and 0 or rayEngine.world.dayNightCycle.currentTime
	-- Осуществляем базовое получение аптайма пекарни
	rayEngine.world.dayNightCycle.lastComputerUptime = computer.uptime()
	-- Рассчитываем необходимые параметры движка
	rayEngine.calculateAllParameters()

	-- rayEngine.wallsTexture = image.load("/heart.pic")
	-- rayEngine.wallsTexture = image.transform(rayEngine.wallsTexture, rayEngine.properties.tileWidth, rayEngine.properties.tileWidth / 2)
end

---------------------------------------------------- Функции, связанные с игроком ------------------------------------------------------------------

function rayEngine.changeWeapon(weaponID)
	if rayEngine.weapons[weaponID] then 
		rayEngine.currentWeapon = {
			ID = weaponID,
			damage = rayEngine.weapons[weaponID].damage,
			weaponTexture = image.load(rayEngine.weaponsFolder .. rayEngine.weapons[weaponID].weaponTexture),
			fireTexture = image.load(rayEngine.weaponsFolder .. rayEngine.weapons[weaponID].fireTexture),
			crosshairTexture = image.load(rayEngine.weaponsFolder .. rayEngine.weapons[weaponID].crosshairTexture)
		}
		rayEngine.calculateWeaponPosition()
	else
		rayEngine.currentWeapon = nil
	end
end

function rayEngine.move(distanceForward, distanceRight)
	local forwardRotation = math.rad(rayEngine.player.rotation)
	local rightRotation = math.rad(rayEngine.player.rotation + 90)
	local xNew = rayEngine.player.position.x + distanceForward * math.sin(forwardRotation) + distanceRight * math.sin(rightRotation)
	local yNew = rayEngine.player.position.y + distanceForward * math.cos(forwardRotation) + distanceRight * math.cos(rightRotation)

	local xWorld, yWorld = convertWorldCoordsToMapCoords(xNew, yNew)
	if rayEngine.map[yWorld][xWorld] == nil then
		rayEngine.player.position.x, rayEngine.player.position.y = xNew, yNew
	end
end

function rayEngine.rotate(angle)
	rayEngine.player.rotation = constrainAngle(rayEngine.player.rotation + angle)
end

function rayEngine.turnRight()
	rayEngine.rotate(rayEngine.player.rotationSpeed)
end

function rayEngine.turnLeft()
	rayEngine.rotate(-rayEngine.player.rotationSpeed)
end

function rayEngine.moveForward()
	rayEngine.move(rayEngine.player.moveSpeed, 0)
end

function rayEngine.moveBackward()
	rayEngine.move(-rayEngine.player.moveSpeed, 0)
end

function rayEngine.moveLeft()
	rayEngine.move(0, -rayEngine.player.moveSpeed)
end

function rayEngine.moveRight()
	rayEngine.move(0, rayEngine.player.moveSpeed)
end

function rayEngine.jump()
	if not rayEngine.player.jumpTimer then
		local function onJumpFinished()
			rayEngine.horizonPosition = rayEngine.horizonPosition - rayEngine.player.jumpHeight;
			rayEngine.horizonPosition = rayEngine.horizonPosition - rayEngine.player.jumpHeight;
			rayEngine.player.jumpTimer = nil
		end

		rayEngine.player.jumpTimer = event.timer(1, onJumpFinished)
		rayEngine.horizonPosition = rayEngine.horizonPosition + rayEngine.player.jumpHeight
		rayEngine.horizonPosition = rayEngine.horizonPosition + rayEngine.player.jumpHeight
	end
end

function rayEngine.crouch()
	rayEngine.player.isCrouched = not rayEngine.player.isCrouched
	local heightAdder = rayEngine.player.isCrouched and -rayEngine.player.crouchHeight or rayEngine.player.crouchHeight
	rayEngine.horizonPosition = rayEngine.horizonPosition + heightAdder
	rayEngine.horizonPosition = rayEngine.horizonPosition + heightAdder
end

function rayEngine.destroy(distance)
	local xBlock, yBlock = getBlockCoordsByLook(distance)
	if rayEngine.map[yBlock] and rayEngine.map[yBlock][xBlock] and rayEngine.blocks[rayEngine.map[yBlock][xBlock]] and rayEngine.blocks[rayEngine.map[yBlock][xBlock]].canBeDestroyed then rayEngine.map[yBlock][xBlock] = nil end
end

function rayEngine.place(distance, blockColor)
	local xBlock, yBlock = getBlockCoordsByLook(distance)
	if rayEngine.map[yBlock] and rayEngine.map[yBlock][xBlock] == nil then rayEngine.map[yBlock][xBlock] = blockColor end
end

---------------------------------------------------- Функции интерфейса ------------------------------------------------------------------

function rayEngine.drawDebugInformation(x, y, width, transparency, ...)
	local lines = {...}
	screen.drawRectangle(x, y, width, #lines, 0x000000, 0x000000, " ", transparency); x = x + 1
	for line = 1, #lines do screen.drawText(x, y, 0xEEEEEE, lines[line]); y = y + 1 end
end

local function drawFieldOfViewAngle(x, y, distance, color)
	local fieldOfViewHalf = rayEngine.player.fieldOfView / 2
	local firstAngle, secondAngle = math.rad(-(rayEngine.player.rotation - fieldOfViewHalf)), math.rad(-(rayEngine.player.rotation + fieldOfViewHalf))
	local xFirst, yFirst = math.floor(x + math.sin(firstAngle) * distance), math.floor(y + math.cos(firstAngle) * distance)
	local xSecond, ySecond = math.floor(x + math.sin(secondAngle) * distance), math.floor(y + math.cos(secondAngle) * distance)
	screen.drawSemiPixelLine(x, y, xFirst, yFirst, color)
	screen.drawSemiPixelLine(x, y, xSecond, ySecond, color)
end

function rayEngine.drawMap(x, y, width, height, transparency)
	local xHalf, yHalf = math.floor(width / 2), math.floor(height / 2)
	local xMap, yMap = convertWorldCoordsToMapCoords(rayEngine.player.position.x, rayEngine.player.position.y)

	screen.drawRectangle(x, y, width, yHalf, 0x000000, 0x000000, " ", transparency)

	local xPos, yPos = x, y * 2 - 1
	for i = yMap - yHalf + 1, yMap + yHalf do
		for j = xMap + xHalf + 1, xMap - xHalf + 2, -1 do
			if rayEngine.map[i] and rayEngine.map[i][j] then
				screen.semiPixelSet(xPos, yPos, rayEngine.blocks[rayEngine.map[i][j]].color)
			end
			xPos = xPos + 1
		end
		xPos = x; yPos = yPos + 1
	end

	local xPlayer, yPlayer = x + xHalf, y + yHalf
	--Поле зрения
	if rayEngine.drawFieldOfViewOnMinimap then drawFieldOfViewAngle(xPlayer, yPlayer, 5, 0xCCFFBF) end
	--Игрок
	screen.semiPixelSet(xPlayer, yPlayer, 0x66FF40)
end

function rayEngine.intro()
	local logo = image.fromString("17060000FF 0000FF 0000FF 0000FF 007EFF▄007EFF▄007EFF▄007EFF▀007EFF▀007EFF▀007EFF▀007EFF▀007EFF▀007EFF▀007EFF▄007EFF▄007EFF▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 007EFF▄007EFF▀007EFF▀0000FF 0000FF 0000FF 0000FF 0053FF▄0053FF▀0053FF▀0053FF▀0053FF▄0000FF 0000FF 0000FF 0000FF 007EFF▀007EFF▀007EFF▄0000FF 0000FF 0000FF 007EFF▀007EFF▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 530000 0000FF 0078FF▀0000FF 537800▀0078FF▀0078FF▀0078FF▀0078FF▀0078FF▀0078FF▀7E7800▀0078FF▀0000FF 0078FF▀0000FF 0000FF 007EFF▀007EFF▀007EFF▄007EFF▄007EFF▄0000FF 0000FF 0053FF▀0053FF▀0053FF▀0000FF 0000FF 007EFF▄007EFF▄007EFF▄007EFF▀007EFF▀0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 007EFF▀007EFF▀007EFF▀007EFF▀007EFF▀007EFF▀007EFF▀0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 007EFFP007EFFo007EFFw007EFFe007EFFr007EFFe007EFFd0000FF 007EFFb007EFFy0000FF 007EFFR007EFFa007EFFy007EFFE007EFFn007EFFg007EFFi007EFFn007EFFe007EFF™0000FF 0000FF ")
	local x, y = math.floor(screen.getWidth() / 2 - logo[1] / 2), math.floor(screen.getHeight() / 2 - logo[2] / 2)
	local function draw(transparency)
		screen.clear(0xF0F0F0);
		screen.drawImage(x, y, logo)
		screen.drawRectangle(1, 1, screen.getWidth(), screen.getHeight(), 0x000000, 0x000000, " ", transparency)
		screen.update()
		event.sleep(0)
	end
	for i = 0, 100, 20 do draw(i) end
	event.sleep(1.5)
	for i = 100, 0, -20 do draw(i) end
end

function rayEngine.compass(x, y)
	if not rayEngine.compassImage then rayEngine.compassImage = image.fromString("1C190000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 553600▄373100▄543600▄373600▄543600▄373100▄540000 375400▄673700▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0055FF▄675400▄553700▄375500▄550000 375500▄540000 375400▄540000 373600▄310000 675500▄677E00▄375300▄365400▄373600▄540000 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 555400▄553700▄540000 543700▄540000 375300▄533100▄310B00▄310000 310000 360000 543100▄375300▄553100▄533600▄543200▄313600▄372A00▄373100▄0054FF▄0054FF▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 540000 543200▄540000 545300▄540600▄063100▄310000 315400▄365400▄373100▄313600▄530000 0000FF 0000FF 535400▄535400▄540000 365300▄533100▄065300▄310000 530600▄0054FF▄0000FF 0000FF 0000FF 0000FF 0000FF 530000 365300▄543600▄310600▄312A00▄2A5300▄365300▄543600▄540000 365300▄315300▄530000 0000FF 0000FF 535400▄540000 540000 313600▄363100▄540000 313600▄315300▄062A00▄543100▄0000FF 0000FF 0000FF 0000FF 315300▄533600▄312A00▄2A3100▄315300▄533600▄315400▄540000 535400▄540000 530000 533100▄0000FF 0000FF 540000 540000 315400▄540000 543100▄530000 543100▄313600▄2A0000 2A2900▄540000 0000FF 0000FF 0000FF 533100▄315400▄530000 062A00▄533100▄315300▄535400▄533100▄540000 315400▄543100▄530000 0000FF 0000FF 540000 535400▄315300▄535400▄363100▄535400▄530000 530000 312A00▄2A5300▄0054FF▀0000FF 0000FF 0000FF 312A00▄530000 553600▄2A5500▄2A0000 312A00▄533600▄545300▄315400▄535400▄540000 540000 0053FF▄0053FF▄540000 530000 535400▄535400▄545300▄530000 363100▄312A00▄313600▄545300▄0000FF 0000FF 0000FF 0000FF 530000 535400▄540000 545300▄555400▄315500▄315400▄533100▄543100▄530000 533100▄530000 535400▄535500▄533100▄535400▄315300▄533100▄533600▄315300▄530000 542A00▄312800▄0029FF▀0000FF 0000FF 0000FF 0000FF 530000 545500▄540000 555300▄535400▄530000 542A00▄545300▄365400▄530000 543600▄2A5400▄547E00▄550000 545300▄533600▄540000 530000 530000 542A00▄2A0000▄0029FF▀0000FF 0000FF 0000FF 0000FF 0000FF 530000 535400▄540000 540000 540000 545300▄530000 540000 2A5500▄545300▄292A00▄290000 292A00▄290000 295400▄292A00▄292A00▄290000 542A00▄543600▄285400▄0054FF▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 530000 533100▄540000 530000 535400▄0053FF▀0053FF▀542800▄542800▄532800▄2A2900▄542900▄532900▄542900▄542900▄532900▄542800▄2A2900▄2A2800▄532900▄552800▄542800▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 2A5300▄530000 535400▄540000 530000 532A00▀2A5300▄2A5500▄0029FF▀0028FF▀0028FF▀0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0028FF▀0028FF▀0028FF▀295300▄535500▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 535400▄545300▄530000 545300▄530000 2A0000 2A5300▄545300▄532A00▄542900▄532900▄2A2900▄2A2900▄2A2800▄2A2800▄2A2800▄2A2900▄2A2900▄532900▄532900▄2A2900▄542A00▄545300▄0054FF▄0054FF▄0000FF 0000FF 0000FF 545300▄530000 530000 545300▄2A5300▄532A00▄542900▄290000 295400▄297F00▄548100▄548100▄558100▄558100▄558100▄558100▄538100▄2A8100▄007E00▄295400▄2A2900▄295400▄2A2900▄290000 542A00▄557E00▄0000FF 0000FF 530000 2A0000 545300▄530000 532900▄285400▄2A8000▄7F8100▄810000 810000 810000 810000 810000 810000 812A00N810000 810000 810000 810000 810000 808100▄548100▄545500▄295300▄282900▄542900▄0000FF 0000FF 2A0000 2A0000 545300▄2A2900▄298000▄810000 810000 815500381550018155005810000 810000 810000 810000 810000 810000 810000 810000 81550048155005810000 810000 810000 558100▄2A5300▄282900▄0029FF▄0000FF 532A00▄2A0000 545300▄547E00▄810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 7F8000▄290000 292800▄0000FF 2A0000 2A0000 2A5300▄7E5300▄810000 812A00W810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 812A00E810000 807E00▄2A2900▄292800▄0000FF 2A0000 2A2900▄2A0000 2A0000 552A00▄810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 815500▄542900▄280000 0028FF▀530000 2A0000 2A0000 290000 2A2900▄545300▄552A00▄815500▄810000 815500281550028155005810000 810000 810000 810000 810000 810000 810000 815500181550038155005817F00▄552900▄292800▄280000 282A00▄0000FF 530000 2A0000 540000 2A5300▄282A00▄290000 532900▄542A00▄542800▄552900▄7F5300▄815500▄817F00▄817F00▄810000 812A00S810000 817F00▄815500▄815500▄555400▄532900▄292800▄280000 282A00▄282A00▄530000 0000FF 532A00▄2A0000 530000 530000 2A5300▄290000 282900▄002900▄280000 280000 280000 290000 292A00▄2A2900▄542900▄532900▄2A0000 295300▄282900▄280000 280000 280000 282900▄295300▄295300▄2A5300▄552A00▄0000FF 530000 295300▄535400▄540000 535400▄540000 535400▄2A5500▄282900▄280000▄280000 280000▄290000▄2A2800▄2A2900▄552A00▄7E0000▄2A0000▄280000▄280000 280000▄280000▄002AFF▀002AFF▀002AFF▀002AFF▀0000FF 0000FF 532900▄532800▄0029FF▀0029FF▀0029FF▀0029FF▀0029FF▀0029FF▀0000FF 2A9800▄285500▄547E00▄7E5400▄7F5300▄7E2900▄7E2900▄552A00▄542A00▄2A5300▄282A00▄2A7E00▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF ") end	
	screen.drawImage(x, y, rayEngine.compassImage)

	x, y = x + 15, y + 17
	local distance = 3.4
	local northAngle = -rayEngine.player.rotation
	local xScaleFactor = 2.2
	local southPoint, northPoint = {}, {}
	local northAngleRad = math.rad(northAngle)
	northPoint.x, northPoint.y = number.round(x + math.sin(northAngleRad) * distance * xScaleFactor), number.round(y - math.cos(northAngleRad) * distance)
	northAngleRad = math.rad(northAngle + 180)
	southPoint.x, southPoint.y = number.round(x + math.sin(northAngleRad) * distance * xScaleFactor), number.round(y - math.cos(northAngleRad) * distance)
	
	y = y * 2
	screen.drawSemiPixelLine(x, y, northPoint.x, northPoint.y * 2, 0xFF5555)
	screen.drawSemiPixelLine(x, y, southPoint.x, southPoint.y * 2, 0xFFFFFF)
	screen.semiPixelSet(x, y, 0x000000)
end

function rayEngine.watch(x, y)
	if not rayEngine.watchImage then rayEngine.watchImage = image.fromString("20190000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0053FF▄552900▄673100▄7E2A00▄7E3100▄7E2A00▄7E3100▄672A00▄7E2A00▄672900▄7F3100▄7E2A00▄0053FF▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 313600▄290000 290600▄062900▄290000 062900▄290000 062900▄290000 290600▄062900▄2A2900▄2A0600▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 313600▄012900▄2A2900▄290000 012900▄290000 290000 012A00▄290000 290000 312900▄293100▄310600▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 310000 292800▄062A00▄290000 290100▄062900▄290000 290000 2C2900▄290600▄293100▄2A2900▄292800▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0054FF▄557F00▄012800▄290000 290000 292800▄290000 012900▄292800▄290600▄290000 292800▄290000 012800▄807E00▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF AB8100▄7F8000▄283100▄280000 015400▄318100▄005300▄065500▄315500▄282A00▄296700▄015500▄290000 002900▄677E00▄81AA00▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 807F00▄7F8000▄677E00▄812900▄672800▄542800▄2A0000▄2A0000▄815400▄ACAA00▄555400▄283100▄2A0000 312900▄672800▄7F5300▄7F0000 7F0000 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 007EFF▄817E00▄7E2900▄2A0000▄805300▄54AA00▄003100▄2A0000 310600▄532900▄312800▄532900▄360100▄552900▄672800▄7E2A00▄315500▄678000▄555300▄540000▄805400▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0081FF▄802900▄280100▄280000 285400▄310600▄532900▄290000 290000 290000 290000 29D700129D7002290000 290000 290000 282900▄062900▄2A2900▄550600▄556700▄285500▄542800▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0080FF▄557E00▄28AA00▄005500▄552900▄290000 290000 290000 29D700129D7001290000 290000 290000 290000 290000 290000 290000 29D7001290000 290000 290000 290000 672900▄318000▄297F00▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 543100▄002800▄553100▄7E2800▄290000 29D700129D7000290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 29D7002290000 290000 7E2900▄7E6700▄282900▄808100▄0000FF 0000FF 0000FF 0000FF 805500▄280000▄290000 310600▄290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 555400▄535400▄533100▄D58000▄0080FF▄0000FF 552900▀550000 54AB00▄558100▄290000 290000 29D7009290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 29D7003290000 315400▄548100▄067E00▄557F00▄806700▄ACAB00▄0055FF▀545500▄AB3100▄815400▄290100▄290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 545300▄AB5500▄815300▄558000▄558000▄0000FF 0000FF 538100▄002800▄290600▄290000 290000 290000 29D7008290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 29D7004290000 290000 530000 000000 286700▄0080FF▀0000FF 0000FF 0000FF 0000FF 292A00▄000100▄530000 285400▄290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 296700▄063100▄280000 818000▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 550000 810000▄532800▄015300▄280000 292800▄290000 29D7007290000 290000 290000 290000 290000 290000 290000 290000 290000 29D7005290000 290100▄292A00▄065300▄7F0000▄802900▄81C900▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 549900▄002900▄292800▄312800▄290600▄283100▄290600▄292800▄290000 290000 290000 29D7006290000 290000 292800▄292800▄290000 285300▄2A0600▄362800▄280000 285500▄0081FF▀0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 7EAA00▄317E00▄005300▄547E00▄7F2900▄290000▄292A00▄063100▄283100▄295500▄286200▄285500▄012A00▄292A00▄310600▄540000▄807E00▄005500▄015500▄530000 0081FF▀0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 7E8100▄7E8000▄557F00▄317E00▄2A3600▄283100▄005400▄2A5300▄817E00▄AA7E00▄545300▄005300▄005400▄283100▄537E00▄548100▄7F0000 7E8000▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 819800▄807F00▄280000 002900▄312900▄7E2800▄292800▄532800▄552900▄280000 550100▄542800▄282900▄000100▄7E0000 AA9800▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 555300▄012800▄290000 062900▄290000 062900▄290000 062900▄290000 290000 290000 290600▄280000 007EFF▀0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 313600▄062900▄312900▄290000 012900▄293100▄290000 062900▄312900▄290600▄312900▄2A0000 2A2900▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 315400▄290600▄310000 062900▄290000 293100▄062900▄290000 293100▄290000 293100▄062900▄312A00▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0054FF▀285500▄285500▄015500▄285500▄285500▄015500▄295500▄015500▄285500▄015500▄285500▄065500▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF ") end
	
	screen.drawImage(x, y, rayEngine.watchImage)
	x, y = x + 15, y + 12

	local realTimeInSeconds = rayEngine.world.dayNightCycle.currentTime * 86400 / rayEngine.world.dayNightCycle.length
	local hours = realTimeInSeconds / 3600
	local _, minutes = math.modf(hours)
	local hourAngle = math.rad(hours * 360 / 12)
	local minuteAngle = math.rad(minutes * 360)
	local hourArrowLength, minuteArrowLength = 2.8, 4.5
	local xMinute, yMinute = number.round(x + math.sin(minuteAngle) * minuteArrowLength * 2), number.round(y - math.cos(minuteAngle) * minuteArrowLength)
	local xHour, yHour = number.round(x + math.sin(hourAngle) * hourArrowLength * 2), number.round(y - math.cos(hourAngle) * hourArrowLength)

	y = y * 2
	screen.drawSemiPixelLine(x, y, xMinute, yMinute * 2, 0xEEEEEE)
	screen.drawSemiPixelLine(x, y, xHour, yHour * 2, 0xEEEEEE)
end	

local function addItemToChatHistory(text, color)
	text = text.wrap({text}, rayEngine.chatPanelWidth - 2)
	table.insert(rayEngine.chatHistory, {color = color, text = text})
	if #rayEngine.chatHistory > rayEngine.chatHistoryLimit then table.remove(rayEngine.chatHistory, 1) end
end

function rayEngine.chat(transparency)
	local x, y = 1, screen.getHeight() - rayEngine.chatPanelHeight - 3
	screen.drawRectangle(x, y, rayEngine.chatPanelWidth, rayEngine.chatPanelHeight, 0x000000, 0xFFFFFF, " ", transparency or 0.5)
	screen.setDrawLimit(x, y, x + rayEngine.chatPanelWidth - 1, y + rayEngine.chatPanelHeight - 1)
	local yMessage = y + rayEngine.chatPanelHeight - 1
	x = x + 1

	for message = #rayEngine.chatHistory, 1, -1 do
		for line = #rayEngine.chatHistory[message].text, 1, -1 do
			screen.drawText(x, yMessage, rayEngine.chatHistory[message].color or 0xFFFFFF, rayEngine.chatHistory[message].text[line])
			yMessage = yMessage - 1
			if yMessage < y then screen.resetDrawLimit(); return end
		end
	end

	screen.resetDrawLimit()
end

function rayEngine.commandLine(transparency)
	transparency = transparency or 50
	local inputPanelHeight = 3
	local x, y = 1, screen.getHeight() - inputPanelHeight + 1
	--Врубаем чат и рисуем все, включая его
	rayEngine.chatEnabled = true
	rayEngine.update()

	--Ввод данных
	local input = GUI.input(x, y, screen.getWidth(), 3, 0xFFFFFF, 0x3C3C3C, 0x666666, 0xFFFFFF, 0x3C3C3C, "")
	input.eventHandler({draw = function() input:draw() end}, input, "touch", input.x, input.y)
	
	local words = {}; for word in string.gmatch(input.text, "[^%s]+") do table.insert(words, unicode.lower(word)) end
	if #words > 0 then
		if unicode.sub(words[1], 1, 1) == "/" then
			words[1] = unicode.sub(words[1], 2, -1)
			if words[1] == "time" then
				if words[2] == "set" and words[3] and tonumber(words[3]) then
					local newTime = tonumber(words[3])
					if newTime < 0 or newTime > rayEngine.world.dayNightCycle.length then
						addItemToChatHistory("Время не может быть отрицательным и превышать длину суток (" .. rayEngine.world.dayNightCycle.length .. " секю)", 0xFF8888)
					else
						rayEngine.world.dayNightCycle.currentTime = math.floor(newTime)
						addItemToChatHistory("Время успешно изменено на: " .. newTime, 0xFFDB40)
					end
				elseif words[2] == "get" then
					addItemToChatHistory("Текущее время: " .. rayEngine.world.dayNightCycle.currentTime, 0xFFDB40)
					addItemToChatHistory("Длина суток: " .. rayEngine.world.dayNightCycle.length, 0xFFDB40)
				elseif words[2] == "lock" then
					rayEngine.world.dayNightCycle.enabled = not rayEngine.world.dayNightCycle.enabled
					addItemToChatHistory("Состояние цикла дня и ночи: " .. tostring(rayEngine.world.dayNightCycle.enabled), 0xFFDB40)
				end
			elseif words[1] == "setrenderquality" and tonumber(words[2]) then
				rayEngine.properties.raycastQuality = tonumber(words[2])
				addItemToChatHistory("Качество рендера изменено на: " .. tonumber(words[2]), 0xFFDB40)
			elseif words[1] == "setdrawdistance" and tonumber(words[2]) then
				rayEngine.properties.drawDistance = tonumber(words[2])
				addItemToChatHistory("Дистанция прорисовки изменена на: " .. tonumber(words[2]), 0xFFDB40)
			elseif words[1] == "setshadingcascades" and tonumber(words[2]) then
				rayEngine.properties.shadingCascades = tonumber(words[2])
				addItemToChatHistory("Количество цветов для отрисовки блока изменено на: " .. tonumber(words[2]), 0xFFDB40)
			elseif words[1] == "setshadingdistance" and tonumber(words[2]) then
				rayEngine.properties.shadingDistance = tonumber(words[2])
				addItemToChatHistory("Дистация затенения блоков изменена на: " .. tonumber(words[2]), 0xFFDB40)
			elseif words[1] == "help" then
				addItemToChatHistory("Доступные команды:", 0xFFDB40)
				addItemToChatHistory("/time get", 0xFFFFBF)
				addItemToChatHistory("/time set <value>", 0xFFFFBF)
				addItemToChatHistory("/time lock", 0xFFFFBF)
				addItemToChatHistory(" ", 0xFFFFFF)
				addItemToChatHistory("/setRenderQuality <value>", 0xFFFFBF)
				addItemToChatHistory("/setDrawDistance <value>", 0xFFFFBF)
				addItemToChatHistory("/setShadingCascades <value>", 0xFFFFBF)
				addItemToChatHistory("/setShadingDistance <value>", 0xFFFFBF)
			else
				addItemToChatHistory("Неизвестная команда. Введите /help для получения списка команд", 0xFF8888)
			end
		else
			addItemToChatHistory("> " .. input.text, 0xFFFFFF)
		end
	end

	--Активируем таймер
	if rayEngine.chatTimer then event.cancel(rayEngine.chatTimer) end
	rayEngine.chatEnabled = true
	rayEngine.chatTimer = event.timer(rayEngine.chatShowTime, function() rayEngine.chatEnabled = false; rayEngine.chatTimer = nil; update() end)
end

function rayEngine.toggleMinimap()
	rayEngine.minimapEnabled = not rayEngine.minimapEnabled
end

function rayEngine.toggleDebugInformation()
	rayEngine.debugInformationEnabled = not rayEngine.debugInformationEnabled
end

function rayEngine.toggleCompass()
	rayEngine.compassEnabled = not rayEngine.compassEnabled
	if not rayEngine.compassEnabled then rayEngine.compassImage = nil end
end

function rayEngine.toggleWatch()
	rayEngine.watchEnabled = not rayEngine.watchEnabled
	if not rayEngine.watchEnabled then rayEngine.watchImage = nil end
end

function rayEngine.drawWeapon()
	if rayEngine.currentWeapon.needToFire then screen.drawImage(rayEngine.currentWeapon.xFire, rayEngine.currentWeapon.yFire, rayEngine.currentWeapon.fireTexture); rayEngine.currentWeapon.needToFire = false end
	screen.drawImage(rayEngine.currentWeapon.xWeapon, rayEngine.currentWeapon.yWeapon, rayEngine.currentWeapon.weaponTexture)
	screen.drawImage(rayEngine.currentWeapon.xCrosshair, rayEngine.currentWeapon.yCrosshair, rayEngine.currentWeapon.crosshairTexture)
end

function rayEngine.drawStats()
	local width = math.floor(screen.getWidth() * 0.3)
	local height = 5
	local x, y = screen.getWidth() - width - 1, 2
	screen.drawRectangle(x, y, width, height, 0x000000, 0xFFFFFF, " ", 0.5)

	GUI.progressBar(x + 1, y + 4, width - 2, 1, 0x000000, 0xFF5555, rayEngine.player.health.current, rayEngine.player.health.maximum, true)
end

---------------------------------------------------- Функции отрисовки мира ------------------------------------------------------------------

local function raycast(angle)
	angle = math.rad(angle)
	local angleSinDistance, angleCosDistance, currentDistance, xWorld, yWorld, xMap, yMap, tile = math.sin(angle) * rayEngine.properties.raycastQuality, math.cos(angle) * rayEngine.properties.raycastQuality, 0, rayEngine.player.position.x, rayEngine.player.position.y

	while true do
		if currentDistance <= rayEngine.properties.drawDistance then
			xMap, yMap = math.floor(xWorld / rayEngine.properties.tileWidth), math.floor(yWorld / rayEngine.properties.tileWidth)
			if rayEngine.map[yMap] and rayEngine.map[yMap][xMap] then
				return currentDistance, rayEngine.map[yMap][xMap]
			end

			xWorld, yWorld = xWorld + angleSinDistance, yWorld + angleCosDistance
			currentDistance = currentDistance + rayEngine.properties.raycastQuality
		else
			return nil
		end
	end
end

function rayEngine.drawWorld()
	--Земля
	screen.clear(rayEngine.world.colors.groundByTime)
	--Небо
	screen.drawRectangle(1, 1, screen.getWidth(), rayEngine.horizonPosition, rayEngine.world.colors.sky.current, 0x0, " ")
	--Сцена
	local startAngle, endAngle, startX, distanceToTile, tileID, height, startY, tileColor = rayEngine.player.rotation - rayEngine.player.fieldOfView / 2, rayEngine.player.rotation + rayEngine.player.fieldOfView / 2, 1
	for angle = startAngle, endAngle, rayEngine.raycastStep do
		distanceToTile, tileID = raycast(angle)
		if distanceToTile then
			-- Получаем цвет стенки
			tileColor = getTileColor(rayEngine.blocks[tileID].color, distanceToTile)
			
			-- Поддержка "высококачественной" doubleHeight-графики
			if rayEngine.properties.useSimpleRenderer then
				height = rayEngine.properties.tileWidth / distanceToTile * rayEngine.distanceToProjectionPlane
				startY = rayEngine.horizonPosition - height / 2 + 1
				screen.drawRectangle(math.floor(startX), math.floor(startY), 1, math.floor(height), tileColor, 0x000000, " ")
			else
				height = rayEngine.properties.tileWidth / distanceToTile * rayEngine.distanceToProjectionPlane * 2
				startY = rayEngine.horizonPosition * 2 - height / 2 + 1
				screen.drawSemiPixelRectangle(math.floor(startX), math.floor(startY), 1, height, tileColor)
			end

			--ТИКСТУРКА)))00
			-- local xTexture = startX % rayEngine.properties.tileWidth + 1
			-- if xTexture >= 1 and xTexture <= screen.getWidth() then
			-- 	local column = image.getColumn(rayEngine.wallsTexture, xTexture)
			-- 	column = image.transform(column, 1, height)
			-- 	screen.drawImage(math.floor(startX), math.floor(startY), column)
			-- end
		end
		startX = startX + 1
	end
end

function rayEngine.update()
	local frameRenderClock = os.clock()
	
	rayEngine.drawWorld()
	if rayEngine.currentWeapon then rayEngine.drawWeapon() end
	if rayEngine.minimapEnabled then rayEngine.drawMap(3, 2, 24, 24, 0.5) end
	-- rayEngine.drawStats()
	local xTools, yTools = 3, screen.getHeight() - 25
	if rayEngine.compassEnabled then rayEngine.compass(xTools, yTools); xTools = xTools + 30 end
	if rayEngine.watchEnabled then rayEngine.watch(xTools, yTools) end
	if rayEngine.chatEnabled then rayEngine.chat() end
	doDayNightCycle()

	if rayEngine.debugInformationEnabled then
		rayEngine.drawDebugInformation(3, 2 + (rayEngine.minimapEnabled and 12 or 0), 24, 0.6, 
			"renderTime: " .. string.format("%.2f", (os.clock() - frameRenderClock) * 1000) .. " ms",
			"freeRAM: " .. string.format("%.2f", computer.freeMemory() / 1024) .. " KB",
			"pos: " .. string.format("%.2f", rayEngine.player.position.x) .. " x " .. string.format("%.2f", rayEngine.player.position.y)
		)
	end

	screen.update()
end

----------------------------------------------------------------------------------------------------------------------------------

function rayEngine.changeResolution(width, height)
	screen.setResolution(width, height)
	rayEngine.calculateAllParameters()
end

function rayEngine.fire()
	rayEngine.currentWeapon.needToFire = true
	rayEngine.update()
	event.sleep(0.1)
	rayEngine.update()
end

----------------------------------------------------------------------------------------------------------------------------------

return rayEngine
