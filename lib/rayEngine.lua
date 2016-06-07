local libraries = {
	buffer = "doubleBuffering",
	event = "event",
	files = "files",
}

for library in pairs(libraries) do if not _G[library] then _G[library] = require(libraries[library]) end end; libraries = nil
local rayEngine = {}

----------------------------------------------------------------------------------------------------------------------------------

local function round(chislo)
  local celaya, drobnaya = math.modf(chislo)
  if drobnaya >= 0.5 then
    return (celaya + 1)
  else
    return celaya
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

----------------------------------------------------------------------------------------------------------------------------------

rayEngine.tileWidth = 32
rayEngine.scene = {}

function rayEngine.loadScene(sceneArray)
	rayEngine.scene = sceneArray
	rayEngine.scene.width = #rayEngine.scene.map[1]
	rayEngine.scene.height = #rayEngine.scene.map
	rayEngine.scene.player.position.x = rayEngine.tileWidth * rayEngine.scene.player.position.x - rayEngine.tileWidth / 2
	rayEngine.scene.player.position.y = rayEngine.tileWidth * rayEngine.scene.player.position.y - rayEngine.tileWidth / 2
	rayEngine.distanceToProjectionPlane = (buffer.screen.width / 2) / math.tan(convertDegreesToRadians(rayEngine.scene.player.fieldOfView / 2))
end

function rayEngine.loadSceneFromFile(path)
	rayEngine.loadScene(files.loadTableFromFile(path))
end

----------------------------------------------------------------------------------------------------------------------------------

local function convertWorldCoordsToMapCoords(x, y)
	return round(x / rayEngine.tileWidth), round(y / rayEngine.tileWidth)
end

local function getBlockCoordsByLook(distance)
	local radRotation = math.rad(rayEngine.scene.player.rotation + 90)
	return convertWorldCoordsToMapCoords(rayEngine.scene.player.position.x + distance * math.sin(radRotation) * rayEngine.tileWidth, rayEngine.scene.player.position.y + distance * math.cos(radRotation) * rayEngine.tileWidth)
end

function rayEngine.move(distanceForward, distanceRight)
	local forwardRotation = math.rad(rayEngine.scene.player.rotation + 90)
	local rightRotation = math.rad(rayEngine.scene.player.rotation + 180)
	local xNew = rayEngine.scene.player.position.x + distanceForward * math.sin(forwardRotation) + distanceRight * math.sin(rightRotation)
	local yNew = rayEngine.scene.player.position.y + distanceForward * math.cos(forwardRotation) + distanceRight * math.cos(rightRotation)

	local xWorld, yWorld = convertWorldCoordsToMapCoords(xNew, yNew)
	if rayEngine.scene.map[yWorld][xWorld] == nil then
		rayEngine.scene.player.position.x, rayEngine.scene.player.position.y = xNew, yNew
	end
end

function rayEngine.rotate(angle)
	rayEngine.scene.player.rotation = constrainAngle(rayEngine.scene.player.rotation + angle)
end

function rayEngine.destroy(distance)
	local xBlock, yBlock = getBlockCoordsByLook(distance)
	rayEngine.scene.map[yBlock][xBlock] = nil
end

function rayEngine.place(distance, blockColor)
	local xBlock, yBlock = getBlockCoordsByLook(distance)
	rayEngine.scene.map[yBlock][xBlock] = blockColor or 0x0
end

----------------------------------------------------------------------------------------------------------------------------------

function rayEngine.drawMap(x, y, width, height, transparency)
	buffer.square(x, y, width, height, 0x000000, 0x000000, " ", transparency)
	local xHalf, yHalf = math.floor(width / 2), math.floor(height / 2)
	local xMap, yMap = math.floor(rayEngine.scene.player.position.x / rayEngine.tileWidth), math.floor(rayEngine.scene.player.position.y / rayEngine.tileWidth)

	local xPos, yPos = x, y
	for i = yMap - yHalf + 1, yMap + yHalf + 1 do
		for j = xMap - xHalf + 1, xMap + xHalf + 1 do
			if rayEngine.scene.map[i] and rayEngine.scene.map[i][j] then
				buffer.square(xPos, yPos, 1, 1, 0xEEEEEE)
			end
			xPos = xPos + 1
		end
		xPos = x; yPos = yPos + 1
	end

	buffer.square(x + xHalf, y + yHalf, 1, 1, 0x55FF55, 0x000000, " ")
end

----------------------------------------------------------------------------------------------------------------------------------

local function hRaycast(player, angle)
	local rayInTop = math.sin( angle ) > 0

	local tanAng = math.tan( angle )

	local Ay = math.floor(rayEngine.scene.player.position.y / rayEngine.tileWidth) * rayEngine.tileWidth; Ay = Ay + ( (rayInTop) and -1 or rayEngine.tileWidth )
	local Ax = rayEngine.scene.player.position.x + (rayEngine.scene.player.position.y - Ay) / tanAng

	local Ya = (rayInTop) and -rayEngine.tileWidth or rayEngine.tileWidth
	local Xa = rayEngine.tileWidth / tanAng; Xa = Xa * ( (rayInTop) and 1 or -1 )

	local x, y = math.floor(Ax / rayEngine.tileWidth), math.floor(Ay / rayEngine.tileWidth)

	while (rayEngine.scene.map[y + 1] and not rayEngine.scene.map[y + 1][x + 1]) do
		Ax = Ax + Xa; Ay = Ay + Ya

		if (Ax < 0 or Ax > rayEngine.tileWidth * rayEngine.scene.width or Ay < 0 or Ay > rayEngine.tileWidth * rayEngine.scene.height) then
			break
		end

		x, y = math.floor(Ax / rayEngine.tileWidth), math.floor(Ay / rayEngine.tileWidth)
	end

	return math.abs(rayEngine.scene.player.position.x - Ax) / math.abs(math.cos( angle ))
end

local function vRaycast(player, angle)
	local rayInRight = math.cos( angle ) > 0

	local tanAng = math.tan( angle )

	local Bx = math.floor(rayEngine.scene.player.position.x / rayEngine.tileWidth) * rayEngine.tileWidth; Bx = Bx + ( (rayInRight) and rayEngine.tileWidth or -1 )
	local By = rayEngine.scene.player.position.y + (rayEngine.scene.player.position.x - Bx) * tanAng

	local Xa = (rayInRight) and rayEngine.tileWidth or -rayEngine.tileWidth
	local Ya = rayEngine.tileWidth * tanAng; Ya = Ya * ( (rayInRight) and -1 or 1 )

	local x, y = math.floor(Bx / rayEngine.tileWidth), math.floor(By / rayEngine.tileWidth)

	while (rayEngine.scene.map[y + 1] and not rayEngine.scene.map[y + 1][x + 1]) do
		Bx = Bx + Xa; By = By + Ya

		if (Bx < 0 or Bx > rayEngine.tileWidth * rayEngine.scene.width or By < 0 or By > rayEngine.tileWidth * rayEngine.scene.height) then
			break
		end

		x, y = math.floor(Bx / rayEngine.tileWidth), math.floor(By / rayEngine.tileWidth)
	end

	return math.abs(rayEngine.scene.player.position.y - By) / math.abs(math.sin( angle ))
end

function rayEngine.drawScene()
	buffer.clear(rayEngine.scene.colors.ground)
	buffer.square(1, 1, buffer.screen.width, math.floor(buffer.screen.height / 2),rayEngine.scene.colors.sky)

	local startColumn = rayEngine.scene.player.rotation - (rayEngine.scene.player.fieldOfView / 2)
	local endColumn = rayEngine.scene.player.rotation + (rayEngine.scene.player.fieldOfView / 2)
	local step = rayEngine.scene.player.fieldOfView / buffer.screen.width

	local startX = 1
	local distanceLimit = buffer.screen.height - 4
	local hDist, vDist, dist, height, startY, tileColor
	for angle = startColumn, endColumn, step do
		hDist = hRaycast(player, convertDegreesToRadians(angle) )
		vDist = vRaycast(player, convertDegreesToRadians(angle) )

		-- local dist = math.min( hDist, vDist ) * math.cos( convertDegreesToRadians(angle) )
		dist = math.min( hDist, vDist )

		height = rayEngine.tileWidth / dist * rayEngine.distanceToProjectionPlane
		startY = buffer.screen.height / 2 - height / 2 + 1

		--Рисуем сценку
		tileColor = height > distanceLimit and rayEngine.scene.colors.distanceMap[#rayEngine.scene.colors.distanceMap] or rayEngine.scene.colors.distanceMap[math.floor(#rayEngine.scene.colors.distanceMap * height / distanceLimit)]
		buffer.square(math.floor(startX), math.floor(startY), 1, height, tileColor, 0x000000, " ")
		startX = startX + 1
	end
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
