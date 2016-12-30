
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

-------------------------------------------------------- Vertex field methods --------------------------------------------------------

function OCGL.newRotationMatrix(axis, angle)
	local sin, cos = math.sin(angle), math.cos(angle)
	if axis == OCGL.axis.x then
		return {
			{ 1, 0, 0 },
			{ 0, cos, -sin },
			{ 0, sin, cos }
		}
	elseif axis == OCGL.axis.y then
		return {
			{ cos, 0, sin },
			{ 0, 1, 0 },
			{ -sin, 0, cos }
		}
	elseif axis == OCGL.axis.z then
		return {
			{ cos, -sin, 0 },
			{ sin, cos, 0 },
			{ 0, 0, 1 }
		}
	else
		error("Axis enum " .. tostring(axis) .. " doesn't exists")
	end
end

function OCGL.translate(vector3Translation)
	for vertexIndex = 1, #OCGL.vertices do
		OCGL.vertices[vertexIndex][1] = OCGL.vertices[vertexIndex][1] + vector3Translation[1]
		OCGL.vertices[vertexIndex][2] = OCGL.vertices[vertexIndex][2] + vector3Translation[2]
		OCGL.vertices[vertexIndex][3] = OCGL.vertices[vertexIndex][3] + vector3Translation[3]
	end
end

function OCGL.rotate(rotationMatrix)
	OCGL.vertices = matrix.multiply(OCGL.vertices, rotationMatrix)
end

-------------------------------------------------------- Render queue methods --------------------------------------------------------

function OCGL.newIndexedTriangle(indexOfVertex1, indexOfVertex2, indexOfVertex3, material)
	return { indexOfVertex1, indexOfVertex2, indexOfVertex3, material }
end

function OCGL.newIndexedLine(indexOfVertex1, indexOfVertex2, color)
	return { indexOfVertex1, indexOfVertex2, color }
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
	OCGL.nextVertexIndex = OCGL.nextVertexIndex + 3
end

-------------------------------------------------------- Rendering methods --------------------------------------------------------

OCGL.setProjectionSurface = renderer.setProjectionSurface

function OCGL.clearBuffer(backgroundColor)
	OCGL.nextVertexIndex, OCGL.vertices, OCGL.triangles, OCGL.lines = 1, {}, {}, {}
	renderer.clearDepthBuffer()
	buffer.clear(backgroundColor)
end

function OCGL.createPerspectiveProjection() 
	local zNearDivZ
	for vertexIndex = 1, #OCGL.vertices do
		zNearDivZ = renderer.projectionSurface.z / OCGL.vertices[vertexIndex][3]
		OCGL.vertices[vertexIndex][1] = zNearDivZ * OCGL.vertices[vertexIndex][1]
		OCGL.vertices[vertexIndex][2] = zNearDivZ * OCGL.vertices[vertexIndex][2]
		-- OCGL.vertices[vertexIndex][3] = zNearDivZ * OCGL.vertices[vertexIndex][3]
		-- OCGL.vertices[vertexIndex][3] = zNearDivZFar * OCGL.vertices[vertexIndex][3] * 10
		-- ecs.error(OCGL.vertices[vertexIndex][1], OCGL.vertices[vertexIndex][2], OCGL.vertices[vertexIndex][3])
	end
end

function OCGL.render(renderMode)
	local halfWidth, halfHeight = buffer.screen.width / 2, buffer.screen.height
	local vector3Vertex1, vector3Vertex2, vector3Vertex3, material

	for lineIndex = 1, #OCGL.lines do
		vector3Vertex1, vector3Vertex2, material = OCGL.vertices[OCGL.lines[lineIndex][1]], OCGL.vertices[OCGL.lines[lineIndex][2]], OCGL.lines[lineIndex][3]

		if renderMode == renderer.renderModes.vertices then
			renderer.renderDot(vector3Vertex1, material)
			renderer.renderDot(vector3Vertex2, material)
		else
			renderer.renderLine(
				math.floor(vector3Vertex1[1]),
				math.floor(vector3Vertex1[2]),
				vector3Vertex1[3],
				math.floor(vector3Vertex2[1]),
				math.floor(vector3Vertex2[2]),
				vector3Vertex2[3],
				material
			)
		end
	end

	for triangleIndex = 1, #OCGL.triangles do
		vector3Vertex1, vector3Vertex2, vector3Vertex3, material = OCGL.vertices[OCGL.triangles[triangleIndex][1]], OCGL.vertices[OCGL.triangles[triangleIndex][2]], OCGL.vertices[OCGL.triangles[triangleIndex][3]], OCGL.triangles[triangleIndex][4]
		
		vector3Vertex1[1], vector3Vertex1[2] = vector3Vertex1[1] + halfWidth, vector3Vertex1[2] + halfHeight
		vector3Vertex2[1], vector3Vertex2[2] = vector3Vertex2[1] + halfWidth, vector3Vertex2[2] + halfHeight
		vector3Vertex3[1], vector3Vertex3[2] = vector3Vertex3[1] + halfWidth, vector3Vertex3[2] + halfHeight

		if renderMode == renderer.renderModes.material then
			if material.type == materials.types.solid then
				renderer.renderFilledTriangle(
					{
						vector.newVector3(vector3Vertex1[1], math.floor(vector3Vertex1[2]), vector3Vertex1[3]),
						vector.newVector3(vector3Vertex2[1], math.floor(vector3Vertex2[2]), vector3Vertex2[3]),
						vector.newVector3(vector3Vertex3[1], math.floor(vector3Vertex3[2]), vector3Vertex3[3]),
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
