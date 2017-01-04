
-------------------------------------------------------- Libraries --------------------------------------------------------

local vector = require("vector")
local unicode = require("unicode")
local materials = require("OpenComputersGL/Materials")
local buffer = require("doubleBuffering")

local renderer = {
	depthBuffer = {},
	viewport = {},
}

-------------------------------------------------------- Constants --------------------------------------------------------

renderer.colors = {
	axis = {
		x = 0xFF0000,
		y = 0x00FF00,
		z = 0x0000FF,
	},
	pivotPoint = 0xFFFFFF,
	wireframe = 0x00FFFF,
}

renderer.renderModes = {
	material = 1,
	wireframe = 2,
	vertices = 3,
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
			buffer.semiPixelRawSet(buffer.getBufferIndexByCoordinates(x, math.ceil(y / 2)), pixelColor, y % 2 == 0)
			-- buffer.set(x, y, pixelColor, 0x0, " ")
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

function renderer.renderDot(vector3Vertex, color)
	renderer.setPixelUsingDepthBuffer(math.floor(vector3Vertex[1]), math.floor(vector3Vertex[2]), vector3Vertex[3], color)
end

-------------------------------------------------------- Triangles render --------------------------------------------------------

local function fillPart(x1Screen, x2Screen, z1Screen, z2Screen, y, color)
	if x2Screen < x1Screen then x1Screen, x2Screen, z1Screen, z2Screen = x2Screen, x1Screen, z2Screen, z1Screen end

	local z, zStep = z1Screen, (z2Screen - z1Screen) / (x2Screen - x1Screen)
	for x = math.floor(x1Screen), math.floor(x2Screen) do
		renderer.setPixelUsingDepthBuffer(x, y, z, color)
		-- buffer.semiPixelSet(x, y, color)
		z = z + zStep
	end
end

function renderer.renderFilledTriangle(points, color)
	local topID, centerID, bottomID = 1, 1, 1
	for i = 1, 3 do
		points[i][2] = math.floor(points[i][2])
		if points[i][2] < points[topID][2] then topID = i end
		if points[i][2] > points[bottomID][2] then bottomID = i end
	end
	for i = 1, 3 do if i ~= topID and i ~= bottomID then centerID = i end end

	local x1ScreenStep = (points[centerID][1] - points[topID][1]) / (points[centerID][2] - points[topID][2])
	local x2ScreenStep = (points[bottomID][1] - points[topID][1]) / (points[bottomID][2] - points[topID][2])
	local x1Screen, x2Screen = points[topID][1], points[topID][1]

	local z1ScreenStep = (points[centerID][3] - points[topID][3]) / (points[centerID][2] - points[topID][2])
	local z2ScreenStep = (points[bottomID][3] - points[topID][3]) / (points[bottomID][2] - points[topID][2])
	local z1Screen, z2Screen = points[topID][3], points[topID][3]

	-- Рисуем первый кусок треугольника от верхней точки до центральной
	for y = points[topID][2], points[centerID][2] - 1 do
		fillPart(x1Screen, x2Screen, z1Screen, z2Screen, y, color)
		x1Screen, x2Screen, z1Screen, z2Screen = x1Screen + x1ScreenStep, x2Screen + x2ScreenStep, z1Screen + z1ScreenStep, z2Screen + z2ScreenStep
	end

	-- Далее считаем, как будет изменяться X от центрельной точки до нижней
	x1Screen, x1ScreenStep = points[centerID][1], (points[bottomID][1] - points[centerID][1]) / (points[bottomID][2] - points[centerID][2])
	z1Screen, z1ScreenStep = points[centerID][3], (points[bottomID][3] - points[centerID][3]) / (points[bottomID][2] - points[centerID][2])
	-- И рисуем нижний кусок треугольника от центральной точки до нижней
	for y = points[centerID][2], points[bottomID][2] do
		fillPart(x1Screen, x2Screen, z1Screen, z2Screen, y, color)
		x1Screen, x2Screen, z1Screen, z2Screen = x1Screen + x1ScreenStep, x2Screen + x2ScreenStep, z1Screen + z1ScreenStep, z2Screen + z2ScreenStep
	end
end

function renderer.renderTexturedTriangle(vertices, texture)

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

				index = buffer.getBufferIndexByCoordinates(x, yInteger)
				background = buffer.rawGet(index)
				buffer.rawSet(index, background, color, unicode.sub(text, i, i))
			end
		end
		x = x + 1
	end
end

-------------------------------------------------------- FPS counter overlay render --------------------------------------------------------

local function drawSegments(x, y, segments, color)
	for i = 1, #segments do
		if segments[i] == 1 then
			buffer.semiPixelSquare(x, y, 3, 1, color)
		elseif segments[i] == 2 then
			buffer.semiPixelSquare(x + 2, y, 1, 3, color)
		elseif segments[i] == 3 then
			buffer.semiPixelSquare(x + 2, y + 2, 1, 3, color)
		elseif segments[i] == 4 then
			buffer.semiPixelSquare(x, y + 4, 3, 1, color)
		elseif segments[i] == 5 then
			buffer.semiPixelSquare(x, y + 2, 1, 3, color)
		elseif segments[i] == 6 then
			buffer.semiPixelSquare(x, y, 1, 3, color)
		elseif segments[i] == 7 then
			buffer.semiPixelSquare(x, y + 2, 3, 1, color)
		else
			error("Че за говно ты сюда напихал? Переделывай!")
		end
	end
end

function renderer.renderFPSCounter(x, y, renderMethod, color)
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

	-- clock sec - 1 frame
	-- 1 sec - x frames

	local oldClock = os.clock()
	renderMethod()
	local fps = tostring(math.ceil(1 / (os.clock() - oldClock) / 10))

	-- buffer.text(1, 1, 0xFFFFFF, "FPS: " .. os.clock() - oldClock)

	for i = 1, #fps do
		drawSegments(x, y, numbers[fps:sub(i, i)], color)
		x = x + 4
	end

	return x - 3
end



------------------------------------------------------------------------------------------------------------------------

return renderer

