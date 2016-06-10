local libraries = {
	buffer = "doubleBuffering",
	event = "event",
	files = "files",
	computer = "computer",
	doubleHeight = "doubleHeight",
	colorlib = "colorlib",
}

for library in pairs(libraries) do if not _G[library] then _G[library] = require(libraries[library]) end end; libraries = nil
local rayEngine = {}

----------------------------------------------------------------------------------------------------------------------------------

local function round(num) 
	if num >= 0 then 
		return math.floor(num + 0.5) 
	else
		return math.ceil(num - 0.5)
	end
end

local function convertRadiansToDegrees(rad)
	return rad * (180 / 3.14)
end

local function convertDegreesToRadians(ang)
	return ang * (3.14 / 180)
end

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
	return rayEngine.world.colors.brightnessMultiplyer[rayEngine.world.dayNightCycle.currentTime > 0 and math.ceil(rayEngine.world.dayNightCycle.currentTime / rayEngine.world.dayNightCycle.length * #rayEngine.world.colors.brightnessMultiplyer) or 1]
end

local function getTimeDependentColors()
	rayEngine.world.colors.sky.current = getSkyColorByTime()
	rayEngine.world.colors.brightnessMultiplyer.current = math.floor(getBrightnessByTime() * 2.55)
	rayEngine.world.colors.groundByTime = colorlib.alphaBlend(rayEngine.world.colors.ground, 0x000000, rayEngine.world.colors.brightnessMultiplyer.current)

	rayEngine.world.colors.tile.byTime = {}
	for i = 1, #rayEngine.world.colors.tile do
		rayEngine.world.colors.tile.byTime[i] = colorlib.alphaBlend(rayEngine.world.colors.tile[i], 0x000000, rayEngine.world.colors.brightnessMultiplyer.current)
	end
end

local function doDayNightCycle()
	if rayEngine.world.dayNightCycle.enabled then
		local computerUptime = computer.uptime()
		if (computerUptime - rayEngine.world.dayNightCycle.lastComputerUptime) >= rayEngine.world.dayNightCycle.speed then
			rayEngine.world.dayNightCycle.currentTime = rayEngine.world.dayNightCycle.currentTime + rayEngine.world.dayNightCycle.speed
			if rayEngine.world.dayNightCycle.currentTime > rayEngine.world.dayNightCycle.length then rayEngine.world.dayNightCycle.currentTime = 0 end	
			rayEngine.world.dayNightCycle.lastComputerUptime = computerUptime

			getTimeDependentColors()
		end
	end
end

local function correctDouble(number)
	return string.format("%.1f", number)
end

----------------------------------------------------------------------------------------------------------------------------------

rayEngine.tileWidth = 32

function rayEngine.loadWorld(pathToWorldFolder)
	rayEngine.world = files.loadTableFromFile(pathToWorldFolder .. "/World.cfg")
	rayEngine.map = files.loadTableFromFile(pathToWorldFolder .. "/Map.cfg")
	rayEngine.player = files.loadTableFromFile(pathToWorldFolder .. "/Player.cfg")

	rayEngine.map.width = #rayEngine.map[1]
	rayEngine.map.height = #rayEngine.map
	rayEngine.player.position.x = rayEngine.tileWidth * rayEngine.player.position.x - rayEngine.tileWidth / 2
	rayEngine.player.position.y = rayEngine.tileWidth * rayEngine.player.position.y - rayEngine.tileWidth / 2
	getTimeDependentColors()
	rayEngine.world.dayNightCycle.lastComputerUptime = computer.uptime()
	rayEngine.distanceToProjectionPlane = (buffer.screen.width / 2) / math.tan(convertDegreesToRadians(rayEngine.player.fieldOfView / 2))
end

----------------------------------------------------------------------------------------------------------------------------------

local function convertWorldCoordsToMapCoords(x, y)
	return round(x / rayEngine.tileWidth), round(y / rayEngine.tileWidth)
end

local function getBlockCoordsByLook(distance)
	local radRotation = math.rad(rayEngine.player.rotation + 90)
	return convertWorldCoordsToMapCoords(rayEngine.player.position.x + distance * math.sin(radRotation) * rayEngine.tileWidth, rayEngine.player.position.y + distance * math.cos(radRotation) * rayEngine.tileWidth)
end

function rayEngine.move(distanceForward, distanceRight)
	local forwardRotation = math.rad(rayEngine.player.rotation + 90)
	local rightRotation = math.rad(rayEngine.player.rotation + 180)
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

function rayEngine.destroy(distance)
	local xBlock, yBlock = getBlockCoordsByLook(distance)
	rayEngine.map[yBlock][xBlock] = nil
end

function rayEngine.place(distance, blockColor)
	local xBlock, yBlock = getBlockCoordsByLook(distance)
	rayEngine.map[yBlock][xBlock] = blockColor or 0x0
end

----------------------------------------------------------------------------------------------------------------------------------

local function drawFieldOfViewAngle(x, y, distance, color)
	local fieldOfViewHalf = rayEngine.player.fieldOfView / 2
	local firstAngle, secondAngle = math.rad(-(rayEngine.player.rotation - fieldOfViewHalf + 90)), math.rad(-(rayEngine.player.rotation + fieldOfViewHalf + 90))
	local xFirst, yFirst = math.floor(x + math.sin(firstAngle) * distance), math.floor(y + math.cos(firstAngle) * distance)
	local xSecond, ySecond = math.floor(x + math.sin(secondAngle) * distance), math.floor(y + math.cos(secondAngle) * distance)
	doubleHeight.line(x, y, xFirst, yFirst, color)
	doubleHeight.line(x, y, xSecond, ySecond, color)
end

function rayEngine.drawMap(x, y, width, height, transparency)
	buffer.square(x, y, width, height, 0x000000, 0x000000, " ", transparency)
	local xHalf, yHalf = math.floor(width / 2), math.floor(height / 2)
	local xMap, yMap = convertWorldCoordsToMapCoords(rayEngine.player.position.x, rayEngine.player.position.y)

	local xPos, yPos = x, y
	for i = yMap - yHalf + 1, yMap + yHalf + 1 do
		for j = xMap + xHalf + 1, xMap - xHalf + 1, -1 do
			if rayEngine.map[i] and rayEngine.map[i][j] then
				buffer.square(xPos, yPos, 1, 1, 0xEEEEEE)
			end
			xPos = xPos + 1
		end
		xPos = x; yPos = yPos + 1
	end

	--Поворот
	local xPlayer, yPlayer = x + xHalf, (y + yHalf) * 2
	--Поле зрения
	drawFieldOfViewAngle(xPlayer, yPlayer, 5, 0xCCFFBF)
	--Игрок
	doubleHeight.set(xPlayer, yPlayer, 0x66FF40)
	--Инфа
	y = y + height
	buffer.square(x, y, width, 1, 0x000000, 0x000000, " ", transparency + 10)
	x = x + 1
	buffer.text(x, y, 0xFFFFFF, "POS: " .. correctDouble(rayEngine.player.position.x) .. " x " .. correctDouble(rayEngine.player.position.y))
end

----------------------------------------------------------------------------------------------------------------------------------

local function hRaycast(player, angle)
	local rayInTop = math.sin( angle ) > 0

	local tanAng = math.tan( angle )

	local Ay = math.floor(rayEngine.player.position.y / rayEngine.tileWidth) * rayEngine.tileWidth; Ay = Ay + ( (rayInTop) and -1 or rayEngine.tileWidth )
	local Ax = rayEngine.player.position.x + (rayEngine.player.position.y - Ay) / tanAng

	local Ya = (rayInTop) and -rayEngine.tileWidth or rayEngine.tileWidth
	local Xa = rayEngine.tileWidth / tanAng; Xa = Xa * ( (rayInTop) and 1 or -1 )

	local x, y = math.floor(Ax / rayEngine.tileWidth), math.floor(Ay / rayEngine.tileWidth)

	while (rayEngine.map[y + 1] and not rayEngine.map[y + 1][x + 1]) do
		Ax = Ax + Xa; Ay = Ay + Ya

		if (Ax < 0 or Ax > rayEngine.tileWidth * rayEngine.map.width or Ay < 0 or Ay > rayEngine.tileWidth * rayEngine.map.height) then
			break
		end

		x, y = math.floor(Ax / rayEngine.tileWidth), math.floor(Ay / rayEngine.tileWidth)
	end

	return math.abs(rayEngine.player.position.x - Ax) / math.abs(math.cos( angle ))
end

local function vRaycast(player, angle)
	local rayInRight = math.cos( angle ) > 0

	local tanAng = math.tan( angle )

	local Bx = math.floor(rayEngine.player.position.x / rayEngine.tileWidth) * rayEngine.tileWidth; Bx = Bx + ( (rayInRight) and rayEngine.tileWidth or -1 )
	local By = rayEngine.player.position.y + (rayEngine.player.position.x - Bx) * tanAng

	local Xa = (rayInRight) and rayEngine.tileWidth or -rayEngine.tileWidth
	local Ya = rayEngine.tileWidth * tanAng; Ya = Ya * ( (rayInRight) and -1 or 1 )

	local x, y = math.floor(Bx / rayEngine.tileWidth), math.floor(By / rayEngine.tileWidth)

	while (rayEngine.map[y + 1] and not rayEngine.map[y + 1][x + 1]) do
		Bx = Bx + Xa; By = By + Ya

		if (Bx < 0 or Bx > rayEngine.tileWidth * rayEngine.map.width or By < 0 or By > rayEngine.tileWidth * rayEngine.map.height) then
			break
		end

		x, y = math.floor(Bx / rayEngine.tileWidth), math.floor(By / rayEngine.tileWidth)
	end

	return math.abs(rayEngine.player.position.y - By) / math.abs(math.sin( angle ))
end

function rayEngine.drawWorld()
	buffer.clear(rayEngine.world.colors.groundByTime)
	buffer.square(1, 1, buffer.screen.width, math.floor(buffer.screen.height / 2), rayEngine.world.colors.sky.current)

	local startColumn = rayEngine.player.rotation - (rayEngine.player.fieldOfView / 2)
	local endColumn = rayEngine.player.rotation + (rayEngine.player.fieldOfView / 2)
	local step = rayEngine.player.fieldOfView / buffer.screen.width

	local startX = 1
	local distanceLimit = buffer.screen.height * 0.8
	local hDist, vDist, dist, height, startY, tileColor
	for angle = startColumn, endColumn, step do
		hDist = hRaycast(player, convertDegreesToRadians(angle) )
		vDist = vRaycast(player, convertDegreesToRadians(angle) )

		-- local dist = math.min( hDist, vDist ) * math.cos( convertDegreesToRadians(angle) )
		dist = math.min( hDist, vDist )
		height = rayEngine.tileWidth / dist * rayEngine.distanceToProjectionPlane
		startY = buffer.screen.height / 2 - height / 2 + 1

		--Рисуем сценку
		tileColor = height > distanceLimit and rayEngine.world.colors.tile.byTime[#rayEngine.world.colors.tile.byTime] or rayEngine.world.colors.tile.byTime[math.floor(#rayEngine.world.colors.tile.byTime * height / distanceLimit)]
		buffer.square(math.floor(startX), math.floor(startY), 1, height, tileColor, 0x000000, " ")
		-- buffer.square(math.floor(startX), math.floor(startY), 1, height, 0x000000, 0x000000, " ")
		startX = startX + 1
	end

	doDayNightCycle()
end

function rayEngine.intro()
	local pixMap = {{{15790320,0," "},{15790320,0," "},{15790320,0," "},{15790320,0," "},{15790320,0," "},{15790320,0," "},{15790320,0," "},{15790320,6908265,"▄"},{15790320,6908265,"▄"},{15790320,6908265,"▄"},{15790320,6908265,"▄"},{15790320,6908265,"▄"},{15790320,6908265,"▄"},{15790320,6908265,"▄"},{15790320,0," "},{15790320,0," "},{15790320,0," "},{15790320,0," "},{15790320,0," "},{15790320,0," "},{15790320,0," "},{15790320,0," "}},{{15790320,0," "},{15790320,0," "},{15790320,6908265,"▄"},{15790320,6908265,"▄"},{15790320,6908265,"▀"},{15790320,6908265,"▀"},{15790320,6908265,"▀"},{15790320,0," "},{15790320,0," "},{15790320,3947580,"▄"},{15790320,3947580,"▄"},{15790320,3947580,"▄"},{15790320,0," "},{15790320,0," "},{15790320,6908265,"▀"},{15790320,6908265,"▀"},{15790320,6908265,"▀"},{15790320,6908265,"▄"},{15790320,6908265,"▄"},{15790320,0," "},{15790320,0," "},{15790320,0," "}},{{15790320,6908265,"▄"},{15790320,6908265,"▀"},{15790320,0," "},{15790320,0," "},{15790320,0," "},{15790320,0," "},{15790320,0," "},{15790320,0," "},{15790320,0," "},{15790320,0," "},{15790320,10083327,"▄"},{15790320,10083327,"▄"},{15790320,10083327,"▄"},{15790320,10083327,"▄"},{15790320,10083327,"▄"},{15790320,10083327,"▄"},{15790320,10083327,"▄"},{15790320,10083327,"▄"},{15790320,10083327,"▄"},{15790320,10083327,"▄"},{15790320,10083327,"▄"},{15790320,10083327,"▄"}},{{15790320,0," "},{15790320,6908265,"▀"},{15790320,6908265,"▄"},{15790320,6908265,"▄"},{15790320,0," "},{15790320,0," "},{15790320,0," "},{15790320,0," "},{15790320,3947580,"▀"},{15790320,3947580,"▄"},{15790320,3947580,"▄"},{15790320,3947580,"▄"},{15790320,3947580,"▀"},{15790320,0," "},{15790320,0," "},{15790320,0," "},{15790320,0," "},{15790320,6908265,"▄"},{15790320,6908265,"▄"},{15790320,0," "},{15790320,0," "},{15790320,0," "}},{{15790320,0," "},{15790320,0," "},{15790320,0," "},{15790320,0," "},{15790320,6908265,"▀"},{15790320,6908265,"▀"},{15790320,6908265,"▀"},{15790320,6908265,"▄"},{15790320,6908265,"▄"},{15790320,6908265,"▄"},{15790320,6908265,"▄"},{15790320,6908265,"▄"},{15790320,6908265,"▄"},{15790320,6908265,"▄"},{15790320,6908265,"▀"},{15790320,6908265,"▀"},{15790320,6908265,"▀"},{15790320,0," "},{15790320,0," "},{15790320,0," "},{15790320,0," "},{15790320,0," "}}}
	local x, y = math.floor(buffer.screen.width / 2 - #pixMap[1] / 2), math.floor(buffer.screen.height / 2 - #pixMap / 2)
	local function draw(transparency)
		buffer.clear(0xF0F0F0);
		buffer.customImage(x, y, pixMap)
		buffer.square(1, 1, buffer.screen.width, buffer.screen.height, 0x000000, 0x000000, " ", transparency)
		buffer.text(x + 1, y + #pixMap + 1, 0x777777, "Powered by RayEngine")
		buffer.draw()
		os.sleep(0)
	end
	for i = 20, 100, 20 do draw(i) end
	os.sleep(1.5)
	for i = 100, 20, -20 do draw(i) end
end

----------------------------------------------------------------------------------------------------------------------------------


return rayEngine
