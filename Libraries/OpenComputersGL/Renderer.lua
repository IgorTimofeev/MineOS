
-------------------------------------------------------- Libraries --------------------------------------------------------

local vector = require("Vector")
local materials = require("OpenComputersGL/Materials")
local screen = require("Screen")

local renderer = {
	depthBuffer = {},
	viewport = {},
}

-------------------------------------------------------- Renderer --------------------------------------------------------

function renderer.clearDepthBuffer()
	for y = 1, renderer.viewport.height do
		renderer.depthBuffer[y] = {}
		for x = 1, renderer.viewport.width do
			renderer.depthBuffer[y][x] = math.huge
		end
	end
end

function renderer.setViewport(x1, y1, x2, y2, nearClippingSurface, farClippingSurface, projectionSurface)
	renderer.viewport.x1 = x1
	renderer.viewport.y1 = y1
	renderer.viewport.x2 = x2
	renderer.viewport.y2 = y2
	renderer.viewport.nearClippingSurface = nearClippingSurface
	renderer.viewport.farClippingSurface = farClippingSurface
	renderer.viewport.projectionSurface = projectionSurface
	renderer.viewport.width = x2 - x1 + 1
	renderer.viewport.height = y2 - y1 + 1
	renderer.viewport.xCenter = math.floor(x1 + renderer.viewport.width / 2)
	renderer.viewport.yCenter = math.floor(y1 + renderer.viewport.height / 2)
end

function renderer.setPixelUsingDepthBuffer(x, y, pixelDepthValue, pixelColor)
	if
		renderer.isVertexInViewRange(x, y, pixelDepthValue)
	then
		if pixelDepthValue < renderer.depthBuffer[y][x] then
			renderer.depthBuffer[y][x] = pixelDepthValue
			screen.semiPixelRawSet(screen.getIndex(x, math.ceil(y / 2)), pixelColor, y % 2 == 0)
			-- screen.set(x, y, pixelColor, 0x0, " ")
		end
	end
end

function renderer.isVertexInViewRange(x, y, z)
	return 
		x >= renderer.viewport.x1 and
		x <= renderer.viewport.x2 and
		y >= renderer.viewport.y1 and
		y <= renderer.viewport.y2 and
		-- z >= renderer.viewport.projectionSurface - (renderer.viewport.projectionSurface - renderer.viewport.nearClippingSurface) * 0.6 and
		z >= renderer.viewport.nearClippingSurface and
		z <= renderer.viewport.farClippingSurface
end

function renderer.visualizeDepthBuffer()
	local minDepth, maxDepth = math.huge, -math.huge
	for y = 1, #renderer.depthBuffer do
		for x = 1, #renderer.depthBuffer[y] do
			if renderer.depthBuffer[y][x] ~= math.huge then
				minDepth, maxDepth = math.min(minDepth, renderer.depthBuffer[y][x]), math.max(maxDepth, renderer.depthBuffer[y][x])
			end
		end
	end
	
	local delta = math.abs(maxDepth - minDepth)
	local grayscalePalette = { [0] = 0xFFFFFF, [1] = 0xEEEEEE, [2] = 0xDDDDDD, [3] = 0xCCCCCC, [4] = 0xBBBBBB, [5] = 0xAAAAAA, [6] = 0x999999, [7] = 0x888888, [8] = 0x777777, [9] = 0x666666, [10] = 0x555555, [11] = 0x444444, [12] = 0x333333, [13] = 0x222222, [14] = 0x111111, [15] = 0x000000 }

	for y = 1, #renderer.depthBuffer do
		for x = 1, #renderer.depthBuffer[y] do
			local value = (renderer.depthBuffer[y][x] - math.abs(minDepth)) / delta
			local color = grayscalePalette[math.floor(#grayscalePalette * value)]
			screen.semiPixelSet(x, y, color or 0x0)
		end
	end
end

-------------------------------------------------------- Line rendering --------------------------------------------------------

function renderer.renderLine(x1, y1, z1, x2, y2, z2, color)
	local incycleValueFrom, incycleValueTo, outcycleValueFrom, outcycleValueTo, isReversed, incycleValueDelta, outcycleValueDelta = x1, x2, y1, y2, false, math.abs(x2 - x1), math.abs(y2 - y1)
	if incycleValueDelta < outcycleValueDelta then
		incycleValueFrom, incycleValueTo, outcycleValueFrom, outcycleValueTo, isReversed, incycleValueDelta, outcycleValueDelta = y1, y2, x1, x2, true, outcycleValueDelta, incycleValueDelta
	end

	if outcycleValueFrom > outcycleValueTo then
		outcycleValueFrom, outcycleValueTo = outcycleValueTo, outcycleValueFrom
		incycleValueFrom, incycleValueTo = incycleValueTo, incycleValueFrom
		z1, z2 = z2, z1
	end

	local outcycleValue, outcycleValueCounter, outcycleValueTriggerIncrement = outcycleValueFrom, 1, incycleValueDelta / outcycleValueDelta
	local outcycleValueTrigger = outcycleValueTriggerIncrement
	local z, zStep = z1, (z2 - z1) / incycleValueDelta
	
	for incycleValue = incycleValueFrom, incycleValueTo, incycleValueFrom < incycleValueTo and 1 or -1 do
		if isReversed then
			renderer.setPixelUsingDepthBuffer(outcycleValue, incycleValue, z, color)
		else
			renderer.setPixelUsingDepthBuffer(incycleValue, outcycleValue, z, color)
		end

		outcycleValueCounter, z = outcycleValueCounter + 1, z + zStep
		if outcycleValueCounter > outcycleValueTrigger then
			outcycleValue, outcycleValueTrigger = outcycleValue + 1, outcycleValueTrigger + outcycleValueTriggerIncrement
		end
	end
end

function renderer.renderDot(x, y, z, color)
	renderer.setPixelUsingDepthBuffer(x, y, z, color)
end

-------------------------------------------------------- Triangles render --------------------------------------------------------

local function getTriangleDrawingShit(points)
	local topID, centerID, bottomID = 1, 1, 1
	
	for i = 1, 3 do
		points[i][2] = math.floor(points[i][2])
		if points[i][2] < points[topID][2] then topID = i end
		if points[i][2] > points[bottomID][2] then bottomID = i end
	end
	for i = 1, 3 do if i ~= topID and i ~= bottomID then centerID = i end end

	local yCenterMinusYTop = points[centerID][2] - points[topID][2]
	local yBottomMinusYTop = points[bottomID][2] - points[topID][2]

	local x1Screen, x2Screen = points[topID][1], points[topID][1]
	local x1ScreenStep = (points[centerID][1] - points[topID][1]) / yCenterMinusYTop
	local x2ScreenStep = (points[bottomID][1] - points[topID][1]) / yBottomMinusYTop
	
	local z1Screen, z2Screen = points[topID][3], points[topID][3]
	local z1ScreenStep = (points[centerID][3] - points[topID][3]) / yCenterMinusYTop
	local z2ScreenStep = (points[bottomID][3] - points[topID][3]) / yBottomMinusYTop

	return topID, centerID, bottomID, x1Screen, x2Screen, x1ScreenStep, x2ScreenStep, z1Screen, z2Screen, z1ScreenStep, z2ScreenStep
end


local function getTriangleSecondPartScreenCoordinates(points, centerID, bottomID)
	-- return x1Screen, x1ScreenStep, z1Screen, z1ScreenStep
	local yBottomMinusYCenter = points[bottomID][2] - points[centerID][2]
	return 
		points[centerID][1],
		(points[bottomID][1] - points[centerID][1]) / yBottomMinusYCenter,
		points[centerID][3],
		(points[bottomID][3] - points[centerID][3]) / yBottomMinusYCenter
end

local function fillPart(x1Screen, x2Screen, z1Screen, z2Screen, y, color)
	if x2Screen < x1Screen then
		x1Screen, x2Screen, z1Screen, z2Screen = x2Screen, x1Screen, z2Screen, z1Screen
	end

	local z, zStep = z1Screen, (z2Screen - z1Screen) / (x2Screen - x1Screen)
	for x = math.floor(x1Screen), math.floor(x2Screen) do
		renderer.setPixelUsingDepthBuffer(x, y, z, color)
		z = z + zStep
	end
end

function renderer.renderFilledTriangle(points, color)
	local topID, centerID, bottomID, x1Screen, x2Screen, x1ScreenStep, x2ScreenStep, z1Screen, z2Screen, z1ScreenStep, z2ScreenStep = getTriangleDrawingShit(points)
	-- Рисуем первый кусок треугольника от верхней точки до центральной
	for y = points[topID][2], points[centerID][2] - 1 do
		fillPart(x1Screen, x2Screen, z1Screen, z2Screen, y, color)
		x1Screen, x2Screen, z1Screen, z2Screen = x1Screen + x1ScreenStep, x2Screen + x2ScreenStep, z1Screen + z1ScreenStep, z2Screen + z2ScreenStep
	end

	-- Далее считаем, как будет изменяться X от центрельной точки до нижней
	x1Screen, x1ScreenStep, z1Screen, z1ScreenStep = getTriangleSecondPartScreenCoordinates(points, centerID, bottomID)
	-- И рисуем нижний кусок треугольника от центральной точки до нижней
	for y = points[centerID][2], points[bottomID][2] do
		fillPart(x1Screen, x2Screen, z1Screen, z2Screen, y, color)
		x1Screen, x2Screen, z1Screen, z2Screen = x1Screen + x1ScreenStep, x2Screen + x2ScreenStep, z1Screen + z1ScreenStep, z2Screen + z2ScreenStep
	end
end

local function fillTexturedPart(firstZ, secondZ, x1Screen, x2Screen, z1Screen, z2Screen, u1Texture, u2Texture, v1Texture, v2Texture, y, texture)
	if x2Screen < x1Screen then
		x1Screen, x2Screen, z1Screen, z2Screen = x2Screen, x1Screen, z2Screen, z1Screen
		u1Texture, u2Texture = u2Texture, u1Texture
		v1Texture, v2Texture = v2Texture, v1Texture
	end

	local z, zStep = z1Screen, (z2Screen - z1Screen) / (x2Screen - x1Screen)

	-- secondZ - (v2Texture - v1Texture)
	-- z - x

	u2Texture = u1Texture + (u2Texture - u1Texture) * (secondZ / z)
	v2Texture = v1Texture + (v2Texture - v1Texture) * (secondZ / z)

	local u, uStep = u1Texture, (u2Texture - u1Texture) / (x2Screen - x1Screen)
	local v, vStep = v1Texture, (v2Texture - v1Texture) / (x2Screen - x1Screen)

	-- screen.drawText(1, 1, 0xFF00FF, "GOVNO: " .. math.abs(renderer.viewport.projectionSurface / z))

	local color, uVal, vVal
	for x = math.floor(x1Screen), math.floor(x2Screen) do
		uVal, vVal = math.floor(u + 0.5), math.floor(v + 0.5)
		if texture[vVal] and texture[vVal][uVal] then
			color = texture[vVal][uVal]
		else
			color = 0x00FF00
		end
		renderer.setPixelUsingDepthBuffer(x, y, z, color)
		-- screen.semiPixelSet(x, y, color)
		z, u, v = z + zStep, u + uStep, v + vStep
	end
end

function renderer.renderTexturedTriangle(points, texture)
	local topID, centerID, bottomID, x1Screen, x2Screen, x1ScreenStep, x2ScreenStep, z1Screen, z2Screen, z1ScreenStep, z2ScreenStep = getTriangleDrawingShit(points)

	local u1Texture, u2Texture = points[topID][4], points[topID][4]
	local u1TextureStep = (points[centerID][4] - points[topID][4]) / (points[centerID][2] - points[topID][2])
	local u2TextureStep = (points[bottomID][4] - points[topID][4]) / (points[bottomID][2] - points[topID][2])
	
	local v1Texture, v2Texture = points[topID][5], points[topID][5]
	local v1TextureStep = (points[centerID][5] - points[topID][5]) / (points[centerID][2] - points[topID][2])
	local v2TextureStep = (points[bottomID][5] - points[topID][5]) / (points[bottomID][2] - points[topID][2])

	for y = points[topID][2], points[centerID][2] - 1 do
		fillTexturedPart(points[topID][3], points[bottomID][3], x1Screen, x2Screen, z1Screen, z2Screen, u1Texture, u2Texture, v1Texture, v2Texture, y, texture)
		x1Screen, x2Screen, z1Screen, z2Screen = x1Screen + x1ScreenStep, x2Screen + x2ScreenStep, z1Screen + z1ScreenStep, z2Screen + z2ScreenStep
		u1Texture, u2Texture, v1Texture, v2Texture = u1Texture + u1TextureStep, u2Texture + u2TextureStep, v1Texture + v1TextureStep, v2Texture + v2TextureStep
	end

	x1Screen, x1ScreenStep, z1Screen, z1ScreenStep = getTriangleSecondPartScreenCoordinates(points, centerID, bottomID)
	u1Texture, u1TextureStep = points[centerID][4], (points[bottomID][4] - points[centerID][4]) / (points[bottomID][2] - points[centerID][2])
	v1Texture, v1TextureStep = points[centerID][5], (points[bottomID][5] - points[centerID][5]) / (points[bottomID][2] - points[centerID][2])

	for y = points[centerID][2], points[bottomID][2] do
		fillTexturedPart(points[topID][3], points[bottomID][3], x1Screen, x2Screen, z1Screen, z2Screen, u1Texture, u2Texture, v1Texture, v2Texture, y, texture)
		x1Screen, x2Screen, z1Screen, z2Screen = x1Screen + x1ScreenStep, x2Screen + x2ScreenStep, z1Screen + z1ScreenStep, z2Screen + z2ScreenStep
		u1Texture, u2Texture, v1Texture, v2Texture = u1Texture + u1TextureStep, u2Texture + u2TextureStep, v1Texture + v1TextureStep, v2Texture + v2TextureStep
	end

	-- for i = 1, 3 do
	-- 	screen.drawText(math.floor(points[i][1]), math.floor(points[i][2]), 0xFFFFFF, "ID " .. i .. ": u = " ..  points[i][4] .. ", v = " .. points[topID][5])
	-- end
end

-------------------------------------------------------- Floating text rendering --------------------------------------------------------

function renderer.renderFloatingText(x, y, z, color, text)
	local textLength = unicode.len(text)
	x, y = math.floor(x - textLength / 2), math.floor(y)
	local yInteger, yFractional = math.modf(y / 2)
	local index, background

	for i = 1, textLength do
		if renderer.isVertexInViewRange(x, y, z) then
			if z < renderer.depthBuffer[y][x] then
				if yFractional == 0 then
					renderer.depthBuffer[y - 1][x] = z
					renderer.depthBuffer[y][x] = z
				else
					renderer.depthBuffer[y][x] = z
					if renderer.depthBuffer[y + 1] then
						renderer.depthBuffer[y + 1][x] = z
					end
				end

				index = screen.getIndex(x, yInteger)
				background = screen.rawGet(index)
				screen.rawSet(index, background, color, unicode.sub(text, i, i))
			end
		end
		x = x + 1
	end
end

-------------------------------------------------------- FPS counter overlay render --------------------------------------------------------

local function drawSegments(x, y, segments, color)
	for i = 1, #segments do
		if segments[i] == 1 then
			screen.drawSemiPixelRectangle(x, y, 3, 1, color)
		elseif segments[i] == 2 then
			screen.drawSemiPixelRectangle(x + 2, y, 1, 3, color)
		elseif segments[i] == 3 then
			screen.drawSemiPixelRectangle(x + 2, y + 2, 1, 3, color)
		elseif segments[i] == 4 then
			screen.drawSemiPixelRectangle(x, y + 4, 3, 1, color)
		elseif segments[i] == 5 then
			screen.drawSemiPixelRectangle(x, y + 2, 1, 3, color)
		elseif segments[i] == 6 then
			screen.drawSemiPixelRectangle(x, y, 1, 3, color)
		elseif segments[i] == 7 then
			screen.drawSemiPixelRectangle(x, y + 2, 3, 1, color)
		else
			error("Че за говно ты сюда напихал? Переделывай!")
		end
	end
end

function renderer.renderFPSCounter(x, y, fps, color)
	local numbers = {
		["0"] = { 1, 2, 3, 4, 5, 6 },
		["1"] = { 2, 3 },
		["2"] = { 1, 2, 4, 5, 7 },
		["3"] = { 1, 2, 3, 4, 7 },
		["4"] = { 2, 3, 6, 7 },
		["5"] = { 1, 3, 4, 6, 7 },
		["6"] = { 1, 3, 4, 5, 6, 7 },
		["7"] = { 1, 2, 3 },
		["8"] = { 1, 2, 3, 4, 5, 6, 7 },
		["9"] = { 1, 2, 3, 4, 6, 7 },
	}

	for i = 1, #fps do
		drawSegments(x, y, numbers[fps:sub(i, i)], color)
		x = x + 4
	end
end

------------------------------------------------------------------------------------------------------------------------

-- screen.start()
-- screen.clear(0xFFFFFF)

-- local texture = materials.newDebugTexture(16, 16, 0xFF00FF, 0x000000)
-- renderer.renderTexturedTriangle({
-- 	{2, 2, 1, 1, 1},
-- 	{2, 52, 1, 1, 16},
-- 	{52, 52, 1, 16, 16},
-- }, texture)
-- renderer.renderTexturedTriangle({
-- 	{2, 2, 1, 1, 1},
-- 	{52, 2, 1, 16, 1},
-- 	{52, 52, 1, 16, 16},
-- }, texture)

-- screen.update(true)

------------------------------------------------------------------------------------------------------------------------

return renderer

