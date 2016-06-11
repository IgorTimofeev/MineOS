local libraries = {
	colorlib = "colorlib",
	image = "image",
	buffer = "doubleBuffering",
	doubleHeight = "doubleHeight",
	files = "files",
	computer = "computer",
	event = "event",
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
rayEngine.modifer = 0
rayEngine.horizontHeight = math.floor(buffer.screen.height / 2)

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
	buffer.square(1, 1, buffer.screen.width, rayEngine.horizontHeight, rayEngine.world.colors.sky.current)

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
		startY = buffer.screen.height / 2 - height / 2 + 1 + rayEngine.modifer

		--Рисуем сценку
		tileColor = height > distanceLimit and rayEngine.world.colors.tile.byTime[#rayEngine.world.colors.tile.byTime] or rayEngine.world.colors.tile.byTime[math.floor(#rayEngine.world.colors.tile.byTime * height / distanceLimit)]
		buffer.square(math.floor(startX), math.floor(startY), 1, height, tileColor, 0x000000, " ")
		-- buffer.square(math.floor(startX), math.floor(startY), 1, height, 0x000000, 0x000000, " ")
		startX = startX + 1
	end

	doDayNightCycle()
end

function rayEngine.intro()
	local logo = image.fromString("17060000FF 0000FF 0000FF 0000FF 007EFF▄007EFF▄007EFF▄007EFF▀007EFF▀007EFF▀007EFF▀007EFF▀007EFF▀007EFF▀007EFF▄007EFF▄007EFF▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 007EFF▄007EFF▀007EFF▀0000FF 0000FF 0000FF 0000FF 0053FF▄0053FF▀0053FF▀0053FF▀0053FF▄0000FF 0000FF 0000FF 0000FF 007EFF▀007EFF▀007EFF▄0000FF 0000FF 0000FF 007EFF▀007EFF▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 530000 0000FF 0078FF▀0000FF 537800▀0078FF▀0078FF▀0078FF▀0078FF▀0078FF▀0078FF▀7E7800▀0078FF▀0000FF 0078FF▀0000FF 0000FF 007EFF▀007EFF▀007EFF▄007EFF▄007EFF▄0000FF 0000FF 0053FF▀0053FF▀0053FF▀0000FF 0000FF 007EFF▄007EFF▄007EFF▄007EFF▀007EFF▀0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 007EFF▀007EFF▀007EFF▀007EFF▀007EFF▀007EFF▀007EFF▀0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 007EFFP007EFFo007EFFw007EFFe007EFFr007EFFe007EFFd0000FF 007EFFb007EFFy0000FF 007EFFR007EFFa007EFFy007EFFE007EFFn007EFFg007EFFi007EFFn007EFFe007EFF™0000FF 0000FF ")
	local x, y = math.floor(buffer.screen.width / 2 - logo.width / 2), math.floor(buffer.screen.height / 2 - logo.height / 2)
	local function draw(transparency)
		buffer.clear(0xF0F0F0);
		buffer.image(x, y, logo)
		buffer.square(1, 1, buffer.screen.width, buffer.screen.height, 0x000000, 0x000000, " ", transparency)
		buffer.draw()
		os.sleep(0)
	end
	for i = 20, 100, 20 do draw(i) end
	os.sleep(1.5)
	for i = 100, 20, -20 do draw(i) end
end

function rayEngine.compass(x, y)
	if not rayEngine.compassImage then rayEngine.compassImage = image.fromString("1C190000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 553600▄373100▄543600▄373600▄543600▄373100▄540000 375400▄673700▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0055FF▄675400▄553700▄375500▄550000 375500▄540000 375400▄540000 373600▄310000 675500▄677E00▄375300▄365400▄373600▄540000 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 555400▄553700▄540000 543700▄540000 375300▄533100▄310B00▄310000 310000 360000 543100▄375300▄553100▄533600▄543200▄313600▄372A00▄373100▄0054FF▄0054FF▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 540000 543200▄540000 545300▄540600▄063100▄310000 315400▄365400▄373100▄313600▄530000 0000FF 0000FF 535400▄535400▄540000 365300▄533100▄065300▄310000 530600▄0054FF▄0000FF 0000FF 0000FF 0000FF 0000FF 530000 365300▄543600▄310600▄312A00▄2A5300▄365300▄543600▄540000 365300▄315300▄530000 0000FF 0000FF 535400▄540000 540000 313600▄363100▄540000 313600▄315300▄062A00▄543100▄0000FF 0000FF 0000FF 0000FF 315300▄533600▄312A00▄2A3100▄315300▄533600▄315400▄540000 535400▄540000 530000 533100▄0000FF 0000FF 540000 540000 315400▄540000 543100▄530000 543100▄313600▄2A0000 2A2900▄540000 0000FF 0000FF 0000FF 533100▄315400▄530000 062A00▄533100▄315300▄535400▄533100▄540000 315400▄543100▄530000 0000FF 0000FF 540000 535400▄315300▄535400▄363100▄535400▄530000 530000 312A00▄2A5300▄0054FF▀0000FF 0000FF 0000FF 312A00▄530000 553600▄2A5500▄2A0000 312A00▄533600▄545300▄315400▄535400▄540000 540000 0053FF▄0053FF▄540000 530000 535400▄535400▄545300▄530000 363100▄312A00▄313600▄545300▄0000FF 0000FF 0000FF 0000FF 530000 535400▄540000 545300▄555400▄315500▄315400▄533100▄543100▄530000 533100▄530000 535400▄535500▄533100▄535400▄315300▄533100▄533600▄315300▄530000 542A00▄312800▄0029FF▀0000FF 0000FF 0000FF 0000FF 530000 545500▄540000 555300▄535400▄530000 542A00▄545300▄365400▄530000 543600▄2A5400▄547E00▄550000 545300▄533600▄540000 530000 530000 542A00▄2A0000▄0029FF▀0000FF 0000FF 0000FF 0000FF 0000FF 530000 535400▄540000 540000 540000 545300▄530000 540000 2A5500▄545300▄292A00▄290000 292A00▄290000 295400▄292A00▄292A00▄290000 542A00▄543600▄285400▄0054FF▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 530000 533100▄540000 530000 535400▄0053FF▀0053FF▀542800▄542800▄532800▄2A2900▄542900▄532900▄542900▄542900▄532900▄542800▄2A2900▄2A2800▄532900▄552800▄542800▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 2A5300▄530000 535400▄540000 530000 532A00▀2A5300▄2A5500▄0029FF▀0028FF▀0028FF▀0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0028FF▀0028FF▀0028FF▀295300▄535500▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 535400▄545300▄530000 545300▄530000 2A0000 2A5300▄545300▄532A00▄542900▄532900▄2A2900▄2A2900▄2A2800▄2A2800▄2A2800▄2A2900▄2A2900▄532900▄532900▄2A2900▄542A00▄545300▄0054FF▄0054FF▄0000FF 0000FF 0000FF 545300▄530000 530000 545300▄2A5300▄532A00▄542900▄290000 295400▄297F00▄548100▄548100▄558100▄558100▄558100▄558100▄538100▄2A8100▄007E00▄295400▄2A2900▄295400▄2A2900▄290000 542A00▄557E00▄0000FF 0000FF 530000 2A0000 545300▄530000 532900▄285400▄2A8000▄7F8100▄810000 810000 810000 810000 810000 810000 812A00N810000 810000 810000 810000 810000 808100▄548100▄545500▄295300▄282900▄542900▄0000FF 0000FF 2A0000 2A0000 545300▄2A2900▄298000▄810000 810000 815500381550018155005810000 810000 810000 810000 810000 810000 810000 810000 81550048155005810000 810000 810000 558100▄2A5300▄282900▄0029FF▄0000FF 532A00▄2A0000 545300▄547E00▄810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 7F8000▄290000 292800▄0000FF 2A0000 2A0000 2A5300▄7E5300▄810000 812A00W810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 812A00E810000 807E00▄2A2900▄292800▄0000FF 2A0000 2A2900▄2A0000 2A0000 552A00▄810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 810000 815500▄542900▄280000 0028FF▀530000 2A0000 2A0000 290000 2A2900▄545300▄552A00▄815500▄810000 815500281550028155005810000 810000 810000 810000 810000 810000 810000 815500181550038155005817F00▄552900▄292800▄280000 282A00▄0000FF 530000 2A0000 540000 2A5300▄282A00▄290000 532900▄542A00▄542800▄552900▄7F5300▄815500▄817F00▄817F00▄810000 812A00S810000 817F00▄815500▄815500▄555400▄532900▄292800▄280000 282A00▄282A00▄530000 0000FF 532A00▄2A0000 530000 530000 2A5300▄290000 282900▄002900▄280000 280000 280000 290000 292A00▄2A2900▄542900▄532900▄2A0000 295300▄282900▄280000 280000 280000 282900▄295300▄295300▄2A5300▄552A00▄0000FF 530000 295300▄535400▄540000 535400▄540000 535400▄2A5500▄282900▄280000▄280000 280000▄290000▄2A2800▄2A2900▄552A00▄7E0000▄2A0000▄280000▄280000 280000▄280000▄002AFF▀002AFF▀002AFF▀002AFF▀0000FF 0000FF 532900▄532800▄0029FF▀0029FF▀0029FF▀0029FF▀0029FF▀0029FF▀0000FF 2A9800▄285500▄547E00▄7E5400▄7F5300▄7E2900▄7E2900▄552A00▄542A00▄2A5300▄282A00▄2A7E00▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF ") end	
	buffer.image(x, y, rayEngine.compassImage)

	x, y = x + 15, y + 17
	local distance = 3.4
	local northAngle = rayEngine.player.rotation
	local xScaleFactor = 2.2
	local southPoint, northPoint = {}, {}
	local northAngleRad = math.rad(northAngle)
	northPoint.x, northPoint.y = round(x + math.sin(northAngleRad) * distance * xScaleFactor), round(y - math.cos(northAngleRad) * distance)
	northAngleRad = math.rad(northAngle + 180)
	southPoint.x, southPoint.y = round(x + math.sin(northAngleRad) * distance * xScaleFactor), round(y - math.cos(northAngleRad) * distance)
	
	y = y * 2
	doubleHeight.line(x, y, northPoint.x, northPoint.y * 2, 0xFF5555)
	doubleHeight.line(x, y, southPoint.x, southPoint.y * 2, 0xFFFFFF)
	doubleHeight.set(x, y, 0x000000)
end

----------------------------------------------------------------------------------------------------------------------------------


return rayEngine
