
-------------------------------------------------------- Libraries --------------------------------------------------------

local color = require("Color")
local vector = require("Vector")
local screen = require("Screen")
local materials = require("OpenComputersGL/Materials")
local renderer = require("OpenComputersGL/Renderer")
local OCGL = {}

-------------------------------------------------------- Constants --------------------------------------------------------

OCGL.axis = {
	x = 1,
	y = 2,
	z = 3,
}

OCGL.colors = {
	axis = {
		x = 0xFF0000,
		y = 0x00FF00,
		z = 0x0000FF,
	},
	pivotPoint = 0xFFFFFF,
	wireframe = 0x000000,
	vertices = 0xFFDB40,
	lights = 0x44FF44
}

OCGL.renderModes = {
	disabled = 1,
	constantShading = 2,
	flatShading = 3,
}

OCGL.auxiliaryModes = {
	disabled = 1,
	wireframe = 2,
	vertices = 3,
}

OCGL.renderMode = 3
OCGL.auxiliaryMode = 1

OCGL.vertices = {}
OCGL.triangles = {}
OCGL.lines = {}
OCGL.floatingTexts = {}
OCGL.lights = {}

local sinTable, cosTable = {}, {}

-------------------------------------------------------- Sin / Cos optimization --------------------------------------------------------

function OCGL.sin(angle)
	sinTable[angle] = sinTable[angle] or math.sin(angle)
	return sinTable[angle]
end

function OCGL.cos(angle)
	cosTable[angle] = cosTable[angle] or math.cos(angle)
	return cosTable[angle]
end

-------------------------------------------------------- Vertex field methods --------------------------------------------------------

function OCGL.rotateVectorRelativeToXAxis(vector, angle)
	local sin, cos = OCGL.sin(angle), OCGL.cos(angle)
	vector[2], vector[3] = cos * vector[2] - sin * vector[3], sin * vector[2] + cos * vector[3]
end

function OCGL.rotateVectorRelativeToYAxis(vector, angle)
	local sin, cos = OCGL.sin(angle), OCGL.cos(angle)
	vector[1], vector[3] = cos * vector[1] + sin * vector[3], cos * vector[3] - sin * vector[1]
end

function OCGL.rotateVectorRelativeToZAxis(vector, angle)
	local sin, cos = OCGL.sin(angle), OCGL.cos(angle)
	vector[1], vector[2] = cos * vector[1] - sin * vector[2], sin * vector[1] + cos * vector[2]
end

function OCGL.translate(xTranslation, yTranslation, zTranslation)
	for vertexIndex = 1, #OCGL.vertices do
		OCGL.vertices[vertexIndex][1], OCGL.vertices[vertexIndex][2], OCGL.vertices[vertexIndex][3] = OCGL.vertices[vertexIndex][1] + xTranslation, OCGL.vertices[vertexIndex][2] + yTranslation, OCGL.vertices[vertexIndex][3] + zTranslation
	end
end

function OCGL.rotate(vectorRotationMethod, angle)
	for vertexIndex = 1, #OCGL.vertices do
		vectorRotationMethod(OCGL.vertices[vertexIndex], angle)
	end
end

-------------------------------------------------------- Render queue methods --------------------------------------------------------

function OCGL.newIndexedLight(indexOfVertex1, intensity, emissionDistance)
	return { indexOfVertex1, intensity, emissionDistance }
end

function OCGL.newIndexedTriangle(indexOfVertex1, indexOfVertex2, indexOfVertex3, material)
	return { indexOfVertex1, indexOfVertex2, indexOfVertex3, material }
end

function OCGL.newIndexedLine(indexOfVertex1, indexOfVertex2, color)
	return { indexOfVertex1, indexOfVertex2, color }
end

function OCGL.newIndexedFloatingText(indexOfVertex, color, text)
	return {indexOfVertex, text, color}
end

function OCGL.pushLightToRenderQueue(vector3Vertex, intensity, emissionDistance)
	table.insert(OCGL.vertices, vector3Vertex)
	table.insert(OCGL.lights, OCGL.newIndexedLight(OCGL.nextVertexIndex, intensity, emissionDistance))
	OCGL.nextVertexIndex = OCGL.nextVertexIndex + 1
end

function OCGL.pushTriangleToRenderQueue(vector3Vertex1, vector3Vertex2, vector3Vertex3, material)
	table.insert(OCGL.vertices, vector3Vertex1)
	table.insert(OCGL.vertices, vector3Vertex2)
	table.insert(OCGL.vertices, vector3Vertex3)
	table.insert(OCGL.triangles, OCGL.newIndexedTriangle(OCGL.nextVertexIndex, OCGL.nextVertexIndex + 1, OCGL.nextVertexIndex + 2, material))
	OCGL.nextVertexIndex = OCGL.nextVertexIndex + 3
end

function OCGL.pushLineToRenderQueue(vector3Vertex1, vector3Vertex2, color)
	table.insert(OCGL.vertices, vector3Vertex1)
	table.insert(OCGL.vertices, vector3Vertex2)
	table.insert(OCGL.lines, OCGL.newIndexedLine(OCGL.nextVertexIndex, OCGL.nextVertexIndex + 1, color))
	OCGL.nextVertexIndex = OCGL.nextVertexIndex + 2
end

function OCGL.pushFloatingTextToRenderQueue(vector3Vertex, color, text)
	table.insert(OCGL.vertices, vector3Vertex)
	table.insert(OCGL.floatingTexts, OCGL.newIndexedFloatingText(OCGL.nextVertexIndex, color, text))
	OCGL.nextVertexIndex = OCGL.nextVertexIndex + 1
end

-------------------------------------------------------- Rendering methods --------------------------------------------------------

function OCGL.clearBuffer(backgroundColor)
	OCGL.nextVertexIndex, OCGL.vertices, OCGL.triangles, OCGL.lines, OCGL.floatingTexts, OCGL.lights = 1, {}, {}, {}, {}, {}
	renderer.clearDepthBuffer()
	screen.clear(backgroundColor)
end

function OCGL.createPerspectiveProjection() 
	local zProjectionDivZ
	for vertexIndex = 1, #OCGL.vertices do
		zProjectionDivZ = math.abs(renderer.viewport.projectionSurface / OCGL.vertices[vertexIndex][3])
		OCGL.vertices[vertexIndex][1] = zProjectionDivZ * OCGL.vertices[vertexIndex][1]
		OCGL.vertices[vertexIndex][2] = zProjectionDivZ * OCGL.vertices[vertexIndex][2]
	end
end

function OCGL.getTriangleLightIntensity(vertex1, vertex2, vertex3, indexedLight)
	local lightVector = {
		OCGL.vertices[indexedLight[1]][1] - (vertex1[1] + vertex2[1] + vertex3[1]) / 3,
		OCGL.vertices[indexedLight[1]][2] - (vertex1[2] + vertex2[2] + vertex3[2]) / 3,
		OCGL.vertices[indexedLight[1]][3] - (vertex1[3] + vertex2[3] + vertex3[3]) / 3
	}
	local lightDistance = vector.length(lightVector)

	if lightDistance <= indexedLight[3] then
		local normalVector = vector.getSurfaceNormal(vertex1, vertex2, vertex3)
		-- screen.drawText(2, screen.height - 2, 0x0, "normalVector: " .. normalVector[1] .. " x " .. normalVector[2] .. " x " .. normalVector[3])

		local cameraScalar = vector.scalarMultiply({0, 0, 100}, normalVector)
		local lightScalar = vector.scalarMultiply(lightVector, normalVector )

		-- screen.drawText(2, screen.height - 1, 0xFFFFFF, "Scalars: " .. cameraScalar .. " x " .. lightScalar)
		if cameraScalar < 0 and lightScalar >= 0 or cameraScalar >= 0 and lightScalar < 0 then			
			local absAngle = math.abs(math.acos(lightScalar / (lightDistance * vector.length(normalVector))))
			if absAngle > 1.5707963267949 then
				absAngle = 3.1415926535898 - absAngle
			end
			-- screen.drawText(2, screen.height, 0xFFFFFF, "Angle: " .. math.deg(angle) .. ", newAngle: " .. math.deg(absAngle) .. ", intensity: " .. absAngle / 1.5707963267949)
			return indexedLight[2] * (1 - lightDistance / indexedLight[3]) * (1 - absAngle / 1.5707963267949)
		else
			return 0
		end
	else
		-- screen.drawText(2, screen.height, 0x0, "Out of light range: " .. lightDistance .. " vs " .. indexedLight[2])
		return 0
	end
end

function OCGL.calculateLights()
	for triangleIndex = 1, #OCGL.triangles do
		for lightIndex = 1, #OCGL.lights do
			local intensity = OCGL.getTriangleLightIntensity(
				OCGL.vertices[OCGL.triangles[triangleIndex][1]], 
				OCGL.vertices[OCGL.triangles[triangleIndex][2]], 
				OCGL.vertices[OCGL.triangles[triangleIndex][3]], 
				OCGL.lights[lightIndex]
			)
			if OCGL.triangles[triangleIndex][5] then
				OCGL.triangles[triangleIndex][5] = OCGL.triangles[triangleIndex][5] + intensity
			else
				OCGL.triangles[triangleIndex][5] = intensity
			end
		end
	end
end

function OCGL.render()
	local vertex1, vertex2, vertex3, material, auxiliaryColor = {}, {}, {}

	for triangleIndex = 1, #OCGL.triangles do
		vertex1[1], vertex1[2], vertex1[3] = renderer.viewport.xCenter + OCGL.vertices[OCGL.triangles[triangleIndex][1]][1], renderer.viewport.yCenter - OCGL.vertices[OCGL.triangles[triangleIndex][1]][2], OCGL.vertices[OCGL.triangles[triangleIndex][1]][3]
		vertex2[1], vertex2[2], vertex2[3] = renderer.viewport.xCenter + OCGL.vertices[OCGL.triangles[triangleIndex][2]][1], renderer.viewport.yCenter - OCGL.vertices[OCGL.triangles[triangleIndex][2]][2], OCGL.vertices[OCGL.triangles[triangleIndex][2]][3]
		vertex3[1], vertex3[2], vertex3[3] = renderer.viewport.xCenter + OCGL.vertices[OCGL.triangles[triangleIndex][3]][1], renderer.viewport.yCenter - OCGL.vertices[OCGL.triangles[triangleIndex][3]][2], OCGL.vertices[OCGL.triangles[triangleIndex][3]][3]
		material = OCGL.triangles[triangleIndex][4]

		if
			renderer.isVertexInViewRange(vertex1[1], vertex1[2], vertex1[3]) or
			renderer.isVertexInViewRange(vertex2[1], vertex2[2], vertex2[3]) or
			renderer.isVertexInViewRange(vertex3[1], vertex3[2], vertex3[3])
		then
			if material.type == materials.types.solid then
				if OCGL.renderMode == OCGL.renderModes.constantShading then
					renderer.renderFilledTriangle({ vertex1, vertex2, vertex3 }, material.color)
				elseif OCGL.renderMode == OCGL.renderModes.flatShading then
					-- local finalColor = 0x0
					-- finalColor = color.blend(material.color, 0x0, OCGL.triangles[triangleIndex][5])
					-- OCGL.triangles[triangleIndex][5] = nil
					-- renderer.renderFilledTriangle({ vertex1, vertex2, vertex3 }, finalColor)

					local r, g, b = color.integerToRGB(material.color)
					r, g, b = math.floor(r * OCGL.triangles[triangleIndex][5]), math.floor(g * OCGL.triangles[triangleIndex][5]), math.floor(b * OCGL.triangles[triangleIndex][5])
					if r > 255 then r = 255 end
					if g > 255 then g = 255 end
					if b > 255 then b = 255 end
					OCGL.triangles[triangleIndex][5] = nil

					renderer.renderFilledTriangle({ vertex1, vertex2, vertex3 }, color.RGBToInteger(r, g, b))
				end
			elseif material.type == materials.types.textured then
				vertex1[4], vertex1[5] = OCGL.vertices[OCGL.triangles[triangleIndex][1]][4], OCGL.vertices[OCGL.triangles[triangleIndex][1]][5]
				vertex2[4], vertex2[5] = OCGL.vertices[OCGL.triangles[triangleIndex][2]][4], OCGL.vertices[OCGL.triangles[triangleIndex][2]][5]
				vertex3[4], vertex3[5] = OCGL.vertices[OCGL.triangles[triangleIndex][3]][4], OCGL.vertices[OCGL.triangles[triangleIndex][3]][5]
				
				renderer.renderTexturedTriangle({ vertex1, vertex2, vertex3 }, material.texture)
			else
				error("Material type " .. tostring(material.type) .. " doesn't supported for rendering triangles")
			end

			if OCGL.auxiliaryMode ~= OCGL.auxiliaryModes.disabled then
				vertex1[1], vertex1[2], vertex1[3] = math.floor(renderer.viewport.xCenter + OCGL.vertices[OCGL.triangles[triangleIndex][1]][1]), math.floor(renderer.viewport.yCenter - OCGL.vertices[OCGL.triangles[triangleIndex][1]][2]), math.floor(OCGL.vertices[OCGL.triangles[triangleIndex][1]][3])
				vertex2[1], vertex2[2], vertex2[3] = math.floor(renderer.viewport.xCenter + OCGL.vertices[OCGL.triangles[triangleIndex][2]][1]), math.floor(renderer.viewport.yCenter - OCGL.vertices[OCGL.triangles[triangleIndex][2]][2]), math.floor(OCGL.vertices[OCGL.triangles[triangleIndex][2]][3])
				vertex3[1], vertex3[2], vertex3[3] = math.floor(renderer.viewport.xCenter + OCGL.vertices[OCGL.triangles[triangleIndex][3]][1]), math.floor(renderer.viewport.yCenter - OCGL.vertices[OCGL.triangles[triangleIndex][3]][2]), math.floor(OCGL.vertices[OCGL.triangles[triangleIndex][3]][3])

				if OCGL.auxiliaryMode == OCGL.auxiliaryModes.wireframe then
					renderer.renderLine(vertex1[1], vertex1[2], vertex1[3], vertex2[1], vertex2[2], vertex2[3], OCGL.colors.wireframe)
					renderer.renderLine(vertex2[1], vertex2[2], vertex2[3], vertex3[1], vertex3[2], vertex3[3], OCGL.colors.wireframe)
					renderer.renderLine(vertex1[1], vertex1[2], vertex1[3], vertex3[1], vertex3[2], vertex3[3], OCGL.colors.wireframe)
				elseif OCGL.auxiliaryMode == OCGL.auxiliaryModes.vertices then
					renderer.renderDot(vertex1[1], vertex1[2], vertex1[3], OCGL.colors.vertices)
					renderer.renderDot(vertex2[1], vertex2[2], vertex2[3], OCGL.colors.vertices)
					renderer.renderDot(vertex3[1], vertex3[2], vertex3[3], OCGL.colors.vertices)
				end
			end
		end
	end

	if OCGL.auxiliaryMode ~= OCGL.auxiliaryModes.disabled then
		for lightIndex = 1, #OCGL.lights do
			renderer.renderDot(
				math.floor(renderer.viewport.xCenter + OCGL.vertices[OCGL.lights[lightIndex][1]][1]),
				math.floor(renderer.viewport.yCenter - OCGL.vertices[OCGL.lights[lightIndex][1]][2]),
				math.floor(OCGL.vertices[OCGL.lights[lightIndex][1]][3]),
				OCGL.colors.lights
			)
		end
	end

	for floatingTextIndex = 1, #OCGL.floatingTexts do
		vertex1 = OCGL.vertices[OCGL.floatingTexts[floatingTextIndex][1]]
		renderer.renderFloatingText(
			renderer.viewport.xCenter + vertex1[1],
			renderer.viewport.yCenter - vertex1[2],
			vertex1[3],
			OCGL.floatingTexts[floatingTextIndex][2],
			OCGL.floatingTexts[floatingTextIndex][3]
		)
	end

	-- for lineIndex = 1, #OCGL.lines do
	-- 	vertex1, vertex2, material = OCGL.vertices[OCGL.lines[lineIndex][1]], OCGL.vertices[OCGL.lines[lineIndex][2]], OCGL.lines[lineIndex][3]

	-- 	if OCGL.renderMode == renderer.renderModes.vertices then
	-- 		renderer.renderDot(vertex1, material)
	-- 		renderer.renderDot(vertex2, material)
	-- 	else
	-- 		renderer.renderLine(
	-- 			math.floor(vertex1[1]),
	-- 			math.floor(vertex1[2]),
	-- 			vertex1[3],
	-- 			math.floor(vertex2[1]),
	-- 			math.floor(vertex2[2]),
	-- 			vertex2[3],
	-- 			material
	-- 		)
	-- 	end
	-- end
end

-------------------------------------------------------- Raycasting methods --------------------------------------------------------

local function vectorMultiply(a, b)
	return vector.newVector3(a[2] * b[3] - a[3] * b[2], a[3] * b[1] - a[1] * b[3], a[1] * b[2] - a[2] * b[1])
end

local function getVectorDistance(a)
	return math.sqrt(a[1] ^ 2 + a[2] ^ 2 + a[3] ^ 2)
end

-- В случае попадания лучика этот метод вернет сам треугольник, а также дистанцию до его плоскости
function OCGL.triangleRaycast(vector3RayStart, vector3RayEnd)
	local minimalDistance, closestTriangleIndex
	for triangleIndex = 1, #OCGL.triangles do
		-- Это вершины треугольника
		local A, B, C = OCGL.vertices[OCGL.triangles[triangleIndex][1]], OCGL.vertices[OCGL.triangles[triangleIndex][3]], OCGL.vertices[OCGL.triangles[triangleIndex][3]]
		-- ecs.error(A[1], A[2], A[3], vector3RayStart[1], vector3RayStart[2], vector3RayStart[3])
		-- Это хз че
		local ABC = vectorMultiply(vector.newVector3(C[1] - A[1], C[2] - A[2], C[3] - A[3]), vector.newVector3(B[1] - A[1], B[2] - A[2], B[3] - A[3]))
		-- Рассчитываем удаленность виртуальной плоскости треугольника от старта нашего луча
		local D = -ABC[1] * A[1] - ABC[2] * A[2] - ABC[3] * A[3]
		local firstPart = D + ABC[1] * vector3RayStart[1] + ABC[2] * vector3RayStart[2] + ABC[3] * vector3RayStart[3]
		local secondPart = ABC[1] * vector3RayStart[1] - ABC[1] * vector3RayEnd[1] + ABC[2] * vector3RayStart[2] - ABC[2] * vector3RayEnd[2] + ABC[3] * vector3RayStart[3] - ABC[3] * vector3RayEnd[3]
		
		-- ecs.error(firstPart, secondPart)

		-- if firstPart ~= 0 or secondPart ~= 0 then ecs.error(firstPart, secondPart) end
		-- Если наш лучик не параллелен той ебучей плоскости треугольника
		if secondPart ~= 0 then
			local distance = firstPart / secondPart
			-- И если этот объект находится ближе к старту луча, нежели предыдущий
			if (distance >= 0 and distance <= 1) and (not minimalDistance or distance < minimalDistance) then
	
				-- То считаем точку попадания луча в данную плоскость (но ни хуя не факт, что он попадет в треугольник!)
				local S = vector.newVector3(
					vector3RayStart[1] + (vector3RayEnd[1] - vector3RayStart[1]) * distance,
					vector3RayStart[2] + (vector3RayEnd[2] - vector3RayStart[2]) * distance,
					vector3RayStart[3] + (vector3RayEnd[3] - vector3RayStart[3]) * distance
				)

				-- Далее считаем сумму площадей параллелограммов, образованных тремя треугольниками, образовавшихся при попадании точки в треугольник
				-- Нууу тип кароч смари: точка ебанула в центр, и треугольник распидорасило на три мелких. Ну, и три мелких могут образовать параллелограммы свои
				-- И, кароч, если сумма трех площадей этих мелких уебков будет сильно отличаться от площади жирного треугольника, то луч не попал
				-- Ну, а площадь считается через sqrt(x^2+y^2+z^2) для каждого йоба-вектора

				---- *A                      *B


				--                  * Shotxyz


				---                   *C

				local SA = vector.newVector3(A[1] - S[1], A[2] - S[2], A[3] - S[3])
				local SB = vector.newVector3(B[1] - S[1], B[2] - S[2], B[3] - S[3])
				local SC = vector.newVector3(C[1] - S[1], C[2] - S[2], C[3] - S[3])
			
				local vectorDistanceSum = getVectorDistance(vectorMultiply(SA, SB)) + getVectorDistance(vectorMultiply(SB, SC)) + getVectorDistance(vectorMultiply(SC, SA))
				local ABCDistance = getVectorDistance(ABC)

				-- Вот тут мы чекаем погрешность расчетов. Если все заебок, то кидаем этот треугольник в "проверенные""
				if math.abs(vectorDistanceSum - ABCDistance) < 1 then
					closestTriangleIndex = triangleIndex
					minimalDistance = distance
				end
			end 
		end
	end

	-- ecs.error(closestTriangleIndex)
	if OCGL.triangles[closestTriangleIndex] then
		return OCGL.triangles[closestTriangleIndex][5], OCGL.triangles[closestTriangleIndex][6], minimalDistance
	end
end

-------------------------------------------------------- Constants --------------------------------------------------------

return OCGL
