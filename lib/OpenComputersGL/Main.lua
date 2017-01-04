
-------------------------------------------------------- Libraries --------------------------------------------------------

local vector = require("vector")
local matrix = require("matrix")
local buffer = require("doubleBuffering")
local materials = require("OpenComputersGL/Materials")
local renderer = require("OpenComputersGL/Renderer")
local OCGL = {}

-------------------------------------------------------- Constants --------------------------------------------------------

OCGL.axis = {
	x = 1,
	y = 2,
	z = 3,
}

OCGL.vertices = {}
OCGL.triangles = {}
OCGL.lines = {}
OCGL.floatingTexts = {}

-------------------------------------------------------- Vertex field methods --------------------------------------------------------

function OCGL.rotateVector(vector, axis, angle)
	local sin, cos = math.sin(angle), math.cos(angle)
	if axis == OCGL.axis.x then
		vector[1], vector[2], vector[3] = vector[1], cos * vector[2] - sin * vector[3], sin * vector[2] + cos * vector[3]
	elseif axis == OCGL.axis.y then
		vector[1], vector[2], vector[3] = cos * vector[1] + sin * vector[3], vector[2], cos * vector[3] - sin * vector[1]
	elseif axis == OCGL.axis.z then
		vector[1], vector[2], vector[3] = cos * vector[1] - sin * vector[2], sin * vector[1] + cos * vector[2], vector[3]
	else
		error("Axis enum " .. tostring(axis) .. " doesn't exists")
	end
end

function OCGL.translate(xTranslation, yTranslation, zTranslation)
	for vertexIndex = 1, #OCGL.vertices do
		OCGL.vertices[vertexIndex][1], OCGL.vertices[vertexIndex][2], OCGL.vertices[vertexIndex][3] = OCGL.vertices[vertexIndex][1] + xTranslation, OCGL.vertices[vertexIndex][2] + yTranslation, OCGL.vertices[vertexIndex][3] + zTranslation
	end
end

function OCGL.rotate(axis, angle)
	for vertexIndex = 1, #OCGL.vertices do
		OCGL.rotateVector(OCGL.vertices[vertexIndex], axis, angle)
	end
end

-------------------------------------------------------- Render queue methods --------------------------------------------------------

function OCGL.newIndexedTriangle(indexOfVertex1, indexOfVertex2, indexOfVertex3, material)
	return { indexOfVertex1, indexOfVertex2, indexOfVertex3, material }
end

function OCGL.newIndexedLine(indexOfVertex1, indexOfVertex2, color)
	return { indexOfVertex1, indexOfVertex2, color }
end

function OCGL.newIndexedFloatingText(indexOfVertex, color, text)
	return {indexOfVertex, text, color}
end

function OCGL.pushTriangleToRenderQueue(vector3Vertex1, vector3Vertex2, vector3Vertex3, material, meshPointer, meshTriangleIndexPointer)
	table.insert(OCGL.vertices, vector3Vertex1)
	table.insert(OCGL.vertices, vector3Vertex2)
	table.insert(OCGL.vertices, vector3Vertex3)
	table.insert(OCGL.triangles, OCGL.newIndexedTriangle(OCGL.nextVertexIndex, OCGL.nextVertexIndex + 1, OCGL.nextVertexIndex + 2, material, meshPointer, meshTriangleIndexPointer))
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

OCGL.setViewport = renderer.setViewport

function OCGL.clearBuffer(backgroundColor)
	OCGL.nextVertexIndex, OCGL.vertices, OCGL.triangles, OCGL.lines, OCGL.floatingTexts = 1, {}, {}, {}, {}
	renderer.clearDepthBuffer()
	buffer.clear(backgroundColor)
end

function OCGL.createPerspectiveProjection() 
	local zNearDivZ
	for vertexIndex = 1, #OCGL.vertices do
		zNearDivZ = math.abs(renderer.viewport.projectionSurface / OCGL.vertices[vertexIndex][3])
		OCGL.vertices[vertexIndex][1] = zNearDivZ * OCGL.vertices[vertexIndex][1]
		OCGL.vertices[vertexIndex][2] = zNearDivZ * OCGL.vertices[vertexIndex][2]
		-- OCGL.vertices[vertexIndex][3] = zNearDivZ * OCGL.vertices[vertexIndex][3]
	end
end

function OCGL.render(renderMode)
	local vector3Vertex1, vector3Vertex2, vector3Vertex3, material = {}, {}, {}

	-- for lineIndex = 1, #OCGL.lines do
	-- 	vector3Vertex1, vector3Vertex2, material = OCGL.vertices[OCGL.lines[lineIndex][1]], OCGL.vertices[OCGL.lines[lineIndex][2]], OCGL.lines[lineIndex][3]

	-- 	if renderMode == renderer.renderModes.vertices then
	-- 		renderer.renderDot(vector3Vertex1, material)
	-- 		renderer.renderDot(vector3Vertex2, material)
	-- 	else
	-- 		renderer.renderLine(
	-- 			math.floor(vector3Vertex1[1]),
	-- 			math.floor(vector3Vertex1[2]),
	-- 			vector3Vertex1[3],
	-- 			math.floor(vector3Vertex2[1]),
	-- 			math.floor(vector3Vertex2[2]),
	-- 			vector3Vertex2[3],
	-- 			material
	-- 		)
	-- 	end
	-- end

	for floatingTextIndex = 1, #OCGL.floatingTexts do
		vector3Vertex1 = OCGL.vertices[OCGL.floatingTexts[floatingTextIndex][1]]
		renderer.renderFloatingText(
			renderer.viewport.xCenter + vector3Vertex1[1],
			renderer.viewport.yCenter - vector3Vertex1[2],
			vector3Vertex1[3],
			OCGL.floatingTexts[floatingTextIndex][2],
			OCGL.floatingTexts[floatingTextIndex][3]
		)
	end

	for triangleIndex = 1, #OCGL.triangles do
		material = OCGL.triangles[triangleIndex][4]
		vector3Vertex1[1], vector3Vertex1[2], vector3Vertex1[3] = renderer.viewport.xCenter + OCGL.vertices[OCGL.triangles[triangleIndex][1]][1], renderer.viewport.yCenter - OCGL.vertices[OCGL.triangles[triangleIndex][1]][2], OCGL.vertices[OCGL.triangles[triangleIndex][1]][3]
		vector3Vertex2[1], vector3Vertex2[2], vector3Vertex2[3] = renderer.viewport.xCenter + OCGL.vertices[OCGL.triangles[triangleIndex][2]][1], renderer.viewport.yCenter - OCGL.vertices[OCGL.triangles[triangleIndex][2]][2], OCGL.vertices[OCGL.triangles[triangleIndex][2]][3]
		vector3Vertex3[1], vector3Vertex3[2], vector3Vertex3[3] = renderer.viewport.xCenter + OCGL.vertices[OCGL.triangles[triangleIndex][3]][1], renderer.viewport.yCenter - OCGL.vertices[OCGL.triangles[triangleIndex][3]][2], OCGL.vertices[OCGL.triangles[triangleIndex][3]][3]
		
		if
			renderer.isVertexInViewRange(vector3Vertex1[1], vector3Vertex1[2], vector3Vertex1[3]) or
			renderer.isVertexInViewRange(vector3Vertex2[1], vector3Vertex2[2], vector3Vertex2[3]) or
			renderer.isVertexInViewRange(vector3Vertex3[1], vector3Vertex3[2], vector3Vertex3[3])
		then
			if renderMode == renderer.renderModes.material then
				if material.type == materials.types.solid then
					renderer.renderFilledTriangle(
						{
							vector3Vertex1,
							vector3Vertex2,
							vector3Vertex3
						},
						material.color
					)
				else
					error("Material type " .. tostring(material.type) .. " doesn't supported for rendering triangles")
				end
			elseif renderMode == renderer.renderModes.wireframe then
				renderer.renderLine(math.floor(vector3Vertex1[1]), math.floor(vector3Vertex1[2]), vector3Vertex1[3], math.floor(vector3Vertex2[1]), math.floor(vector3Vertex2[2]), vector3Vertex2[3], material.color or renderer.colors.wireframe)
				renderer.renderLine(math.floor(vector3Vertex2[1]), math.floor(vector3Vertex2[2]), vector3Vertex2[3], math.floor(vector3Vertex3[1]), math.floor(vector3Vertex3[2]), vector3Vertex3[3], material.color or renderer.colors.wireframe)
				renderer.renderLine(math.floor(vector3Vertex1[1]), math.floor(vector3Vertex1[2]), vector3Vertex1[3], math.floor(vector3Vertex3[1]), math.floor(vector3Vertex3[2]), vector3Vertex3[3], material.color or renderer.colors.wireframe)
			elseif renderMode == renderer.renderModes.vertices then
				renderer.renderDot(vector3Vertex1, material.color or renderer.colors.wireframe)
				renderer.renderDot(vector3Vertex2, material.color or renderer.colors.wireframe)
				renderer.renderDot(vector3Vertex3, material.color or renderer.colors.wireframe)
			else
				error("Rendermode enum " .. tostring(renderMode) .. " doesn't supported for rendering triangles")
			end
		end
	end
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
