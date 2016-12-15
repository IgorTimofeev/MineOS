
-------------------------------------------------------- Libraries --------------------------------------------------------

local renderer = {
	depthBuffer = {},
	projectionSurface = {},
}

-------------------------------------------------------- Additional methods --------------------------------------------------------

function renderer.setProjectionSurfaceLimit(x, y, z, x2, y2, z2)
	renderer.projectionSurface = { x = x, y = y, z = z, x2 = x2, y2 = y2, z2 = z2 }
	renderer.projectionSurface.width = x2 - x + 1
	renderer.projectionSurface.height = y2 - y + 1
	renderer.projectionSurface.depth = z2 - z + 1
end

function renderer.clearDepthBuffer()
	renderer.depthBuffer = {}
	for y = 1, renderer.projectionSurface.height do
		renderer.depthBuffer[y] = {}
		for x = 1, renderer.projectionSurface.width do
			renderer.depthBuffer[y][x] = math.huge
		end
	end
end

function renderer.getDepthBufferIndexByCoordinates(x, y)
	return (y - 1) * renderer.projectionSurface.width + x
end

function renderer.setPixelUsingDepthBuffer(x, y, pixelDepthValue, pixelColor)
	if x >= renderer.projectionSurface.x and y >= renderer.projectionSurface.y and x <= renderer.projectionSurface.x2 and y <= renderer.projectionSurface.y2 then
		if pixelDepthValue < renderer.depthBuffer[y][x] then
			renderer.depthBuffer[y][x] = pixelDepthValue
			buffer.semiPixelRawSet(buffer.getBufferIndexByCoordinates(x, math.ceil(y / 2)), pixelColor, y % 2 == 0)
			-- buffer.set(x, y, pixelColor, 0x0, " ")
		end
	end
end

function renderer.isVertexInViewRange(vector3Vertex)
	return 
		vector3Vertex[1] >= renderer.projectionSurface.x and
		vector3Vertex[1] <= renderer.projectionSurface.y and
		vector3Vertex[2] >= renderer.projectionSurface.x2 and
		vector3Vertex[2] <= renderer.projectionSurface.y2
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

function renderer.renderTriangleObject(vector3Vertex1, vector3Vertex2, vector3Vertex3, renderMode, material)
	if renderMode == OCGL.renderModes.material then
		if material.type == OCGL.materialTypes.solid then
			renderer.renderFilledTriangle(
				{
					OCGL.newVector3(vector3Vertex1[1], math.floor(vector3Vertex1[2]), vector3Vertex1[3]),
					OCGL.newVector3(vector3Vertex2[1], math.floor(vector3Vertex2[2]), vector3Vertex2[3]),
					OCGL.newVector3(vector3Vertex3[1], math.floor(vector3Vertex3[2]), vector3Vertex3[3])
				},
				material.color
			)
		else
			error("Material type " .. tostring(material.type) .. " doesn't supported for rendering triangles")
		end
	elseif renderMode == OCGL.renderModes.wireframe then
		renderer.renderLine(math.floor(vector3Vertex1[1]), math.floor(vector3Vertex1[2]), vector3Vertex1[3], math.floor(vector3Vertex2[1]), math.floor(vector3Vertex2[2]), vector3Vertex2[3], OCGL.colors.wireframe)
		renderer.renderLine(math.floor(vector3Vertex2[1]), math.floor(vector3Vertex2[2]), vector3Vertex2[3], math.floor(vector3Vertex3[1]), math.floor(vector3Vertex3[2]), vector3Vertex3[3], OCGL.colors.wireframe)
		renderer.renderLine(math.floor(vector3Vertex1[1]), math.floor(vector3Vertex1[2]), vector3Vertex1[3], math.floor(vector3Vertex3[1]), math.floor(vector3Vertex3[2]), vector3Vertex3[3], OCGL.colors.wireframe)
	elseif renderMode == OCGL.renderModes.vertices then
		renderer.renderDot(vector3Vertex1, OCGL.colors.wireframe)
		renderer.renderDot(vector3Vertex2, OCGL.colors.wireframe)
		renderer.renderDot(vector3Vertex3, OCGL.colors.wireframe)
	else
		error("Rendermode enum " .. tostring(renderMode) .. " doesn't supported for rendering triangles")
	end
end

-------------------------------------------------------- Mesh render --------------------------------------------------------

function renderer.renderMesh(mesh, renderMode)
	for triangleIndex = 1, #mesh.triangles do
		-- if
		-- 	renderer.isVertexInViewRange(mesh.verticesMatrix[mesh.triangles[triangleIndex][1]]) or
		-- 	renderer.isVertexInViewRange(mesh.verticesMatrix[mesh.triangles[triangleIndex][2]]) or
		-- 	renderer.isVertexInViewRange(mesh.verticesMatrix[mesh.triangles[triangleIndex][3]])
		-- then
			renderer.renderTriangleObject(
				mesh.verticesMatrix[mesh.triangles[triangleIndex][1]],
				mesh.verticesMatrix[mesh.triangles[triangleIndex][2]],
				mesh.verticesMatrix[mesh.triangles[triangleIndex][3]],
				renderMode,
				mesh.triangles[triangleIndex].material or mesh.material
			)
		-- end
	end

	--Рендерим локальные оси
	-- if mesh.showPivotPoint then
	-- 	local scale = 30
	-- 	renderer.renderLine(
	-- 		mesh.pivotPoint.position,
	-- 		OCGL.newVector3(mesh.pivotPoint.position[1] + mesh.pivotPoint.axis[1][1] * scale, mesh.pivotPoint.position[2] + mesh.pivotPoint.axis[1][2] * scale, mesh.pivotPoint.position[3] + mesh.pivotPoint.axis[1][3] * scale),
	-- 		OCGL.colors.axis.x
	-- 	)
	-- 	renderer.renderLine(
	-- 		mesh.pivotPoint.position,
	-- 		OCGL.newVector3(mesh.pivotPoint.position[1] + mesh.pivotPoint.axis[2][1] * scale, mesh.pivotPoint.position[2] + mesh.pivotPoint.axis[2][2] * scale, mesh.pivotPoint.position[3] + mesh.pivotPoint.axis[2][3] * scale),
	-- 		OCGL.colors.axis.y
	-- 	)
	-- 	renderer.renderLine(
	-- 		mesh.pivotPoint.position,
	-- 		OCGL.newVector3(mesh.pivotPoint.position[1] + mesh.pivotPoint.axis[3][1] * scale, mesh.pivotPoint.position[2] + mesh.pivotPoint.axis[3][2] * scale, mesh.pivotPoint.position[3] + mesh.pivotPoint.axis[3][3] * scale),
	-- 		OCGL.colors.axis.z
	-- 	)
	-- end

	return mesh
end

-------------------------------------------------------- Line object render --------------------------------------------------------

function renderer.renderLineObject(line, renderMode)
	if renderMode == OCGL.renderModes.vertices then
		renderer.renderDot(line.verticesMatrix[1], line.color)
		renderer.renderDot(line.verticesMatrix[2], line.color)
	else
		renderer.renderLine(
			math.floor(line.verticesMatrix[1][1]),
			math.floor(line.verticesMatrix[1][2]),
			line.verticesMatrix[1][3],
			math.floor(line.verticesMatrix[2][1]),
			math.floor(line.verticesMatrix[2][2]),
			line.verticesMatrix[2][3],
			line.color
		)
	-- else
	-- 	error("Rendermode enum " .. tostring(renderMode) .. " doesn't supported for rendering lines")
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

--   1
-- 6   2
--   7
-- 5   3
--   4

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

	for i = 1, #fps do
		drawSegments(x, y, numbers[fps:sub(i, i)], color)
		x = x + 4
	end

	return x - 3
end

------------------------------------------------------------------------------------------------------------------------

-- buffer.clear(0x0)
-- for i = 1, 10 do
-- 	renderer.renderFilledTriangle(
-- 		{
-- 			-- { i + 40, i + 40 },
-- 			-- { i + 3, i + 3 },
-- 			-- { i + 30, i + 60 },
-- 			{math.random(1, buffer.screen.width), math.random(1, buffer.screen.height * 2)},
-- 			{math.random(1, buffer.screen.width), math.random(1, buffer.screen.height * 2)},
-- 			{math.random(1, buffer.screen.width), math.random(1, buffer.screen.height * 2)},
-- 		},
-- 		math.random(0x0, 0xFFFFFF)
-- 	)
-- end
-- buffer.draw(true)
-- while true do ecs.error(event.pull("touch")) end

------------------------------------------------------------------------------------------------------------------------

return renderer






