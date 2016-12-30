
-------------------------------------------------------- Libraries --------------------------------------------------------

local vector = require("vector")
local matrix = require("matrix")
local OCGL = require("OpenComputersGL/Main")
local renderer = require("OpenComputersGL/Renderer")
local materials = require("OpenComputersGL/Materials")
local postProcessing = require("WildCatEngine/PostProcessing")
local wildCatEngine = {}

-------------------------------------------------------- Universal object methods --------------------------------------------------------

function wildCatEngine.newPivotPoint(vector3Position)
	return {
		position = vector3Position,
		axis = {
			vector.newVector3(1, 0, 0),
			vector.newVector3(0, 1, 0),
			vector.newVector3(0, 0, 1),
		}
	}
end

-------------------------------------------------------- Mesh object --------------------------------------------------------

local function pushMeshToRenderQueue(mesh)
	local vector3Vertex1, vector3Vertex2, vector3Vertex3
	for triangleIndex = 1, #mesh.triangles do
		vector3Vertex1, vector3Vertex2, vector3Vertex3 = mesh.vertices[mesh.triangles[triangleIndex][1]], mesh.vertices[mesh.triangles[triangleIndex][2]], mesh.vertices[mesh.triangles[triangleIndex][3]]
		OCGL.pushTriangleToRenderQueue(
			vector.newVector3(vector3Vertex1[1], vector3Vertex1[2], vector3Vertex1[3]),
			vector.newVector3(vector3Vertex2[1], vector3Vertex2[2], vector3Vertex2[3]),
			vector.newVector3(vector3Vertex3[1], vector3Vertex3[2], vector3Vertex3[3]),
			mesh.triangles[triangleIndex][4] or mesh.material,
			mesh,
			triangleIndex
		)
	end
end


function wildCatEngine.newMesh(vector3Position, vertices, triangles, material)
	local mesh = {}

	mesh.pivotPoint = wildCatEngine.newPivotPoint(vector3Position)
	mesh.vertices = vertices
	for vertexIndex = 1, #mesh.vertices do
		mesh.vertices[vertexIndex][1], mesh.vertices[vertexIndex][2], mesh.vertices[vertexIndex][3] = mesh.vertices[vertexIndex][1] + vector3Position[1], mesh.vertices[vertexIndex][2] + vector3Position[2], mesh.vertices[vertexIndex][3] + vector3Position[3]
	end
	mesh.triangles = triangles
	mesh.material = material
	mesh.pushToRenderQueue = pushMeshToRenderQueue

	return mesh
end

-------------------------------------------------------- Line object --------------------------------------------------------

local function pushLineToRenderQueue(line)
	OCGL.pushLineToRenderQueue(
		vector.newVector3(line.vertices[1][1], line.vertices[1][2], line.vertices[1][3]),
		vector.newVector3(line.vertices[2][1], line.vertices[2][2], line.vertices[2][3]),
		line.color
	)
end

function wildCatEngine.newLine(vector3Position, vector3Vertex1, vector3Vertex2, color)
	local line = {}

	line.pivotPoint = wildCatEngine.newPivotPoint(vector3Position)
	line.vertices = { vector3Vertex1, vector3Vertex2 }
	line.color = color
	line.pushToRenderQueue = pushLineToRenderQueue

	return line
end

-------------------------------------------------------- Plane object --------------------------------------------------------

function wildCatEngine.newPlane(vector3Position, width, height, material)
	local halfWidth, halfHeight = width / 2, height / 2
	return wildCatEngine.newMesh(
		vector3Position,
		{
			vector.newVector3(-halfWidth, 0, -halfHeight),
			vector.newVector3(-halfWidth, 0, halfHeight),
			vector.newVector3(halfWidth, 0, halfHeight),
			vector.newVector3(halfWidth, 0, -halfHeight),
		},
		{
			OCGL.newIndexedTriangle(1, 2, 3),
			OCGL.newIndexedTriangle(1, 4, 3)
		},
		material
	)
end

-------------------------------------------------------- Cube object --------------------------------------------------------

--[[
	|    /
	|  /
	y z
	  x -----

	FRONT		LEFT		BACK		RIGHT		TOP 		BOTTOM
	2######3	3######6	6######7	7######2	7######6	8######5
	########	########	########	########	########	########
	1######4	4######5	5######8	8######1	2######3	1######4
]]

function wildCatEngine.newCube(vector3Position, size, material)
	local halfSize = size / 2
	return wildCatEngine.newMesh(
		vector3Position,
		{
			-- (1-2-3-4)
			vector.newVector3(-halfSize, -halfSize, -halfSize),
			vector.newVector3(-halfSize, halfSize, -halfSize),
			vector.newVector3(halfSize, halfSize, -halfSize),
			vector.newVector3(halfSize, -halfSize, -halfSize),
			-- (5-6-7-8)
			vector.newVector3(halfSize, -halfSize, halfSize),
			vector.newVector3(halfSize, halfSize, halfSize),
			vector.newVector3(-halfSize, halfSize, halfSize),
			vector.newVector3(-halfSize, -halfSize, halfSize),
		},
		{
			-- Front
			OCGL.newIndexedTriangle(1, 2, 3),
			OCGL.newIndexedTriangle(1, 4, 3),
			-- Left
			OCGL.newIndexedTriangle(4, 3, 6),
			OCGL.newIndexedTriangle(4, 5, 6),
			-- Back
			OCGL.newIndexedTriangle(5, 6, 7),
			OCGL.newIndexedTriangle(5, 8, 7),
			-- Right
			OCGL.newIndexedTriangle(8, 7, 2),
			OCGL.newIndexedTriangle(8, 1, 2),
			-- Top
			OCGL.newIndexedTriangle(2, 7, 6),
			OCGL.newIndexedTriangle(2, 3, 6),
			-- Bottom
			OCGL.newIndexedTriangle(1, 8, 5),
			OCGL.newIndexedTriangle(1, 4, 5),
		},
		material
	)
end

-------------------------------------------------------- Grid lines --------------------------------------------------------

function wildCatEngine.newGridLines(vector3Position, axisRange, gridRange, gridRangeStep)
	local objects = {}
	-- Grid
	for x = -gridRange, gridRange, gridRangeStep do
		table.insert(objects, 1, wildCatEngine.newLine(
			vector.newVector3(vector3Position[1] + x, vector3Position[2], vector3Position[3]),
			vector.newVector3(0, 0, -gridRange),
			vector.newVector3(0, 0, gridRange),
			0x444444
		))
	end
	for z = -gridRange, gridRange, gridRangeStep do
		table.insert(objects, 1, wildCatEngine.newLine(
			vector.newVector3(vector3Position[1], vector3Position[2], vector3Position[3] + z),
			vector.newVector3(-gridRange, 0, 0),
			vector.newVector3(gridRange, 0, 0),
			0x444444
		))
	end

	-- Axis
	table.insert(objects, wildCatEngine.newLine(
		vector3Position,
		vector.newVector3(-axisRange, -1, 0),
		vector.newVector3(axisRange, -1, 0),
		renderer.colors.axis.x
	))
	table.insert(objects, wildCatEngine.newLine(
		vector3Position,
		vector.newVector3(0, -axisRange, 0),
		vector.newVector3(0, axisRange, 0),
		renderer.colors.axis.y
	))
	table.insert(objects, wildCatEngine.newLine(
		vector3Position,
		vector.newVector3(0, -1, -axisRange),
		vector.newVector3(0, -1, axisRange),
		renderer.colors.axis.z
	))

	return objects
end

-------------------------------------------------------- Camera object --------------------------------------------------------

local function cameraSetRotation(camera, axisXRotation, axisYRotation, axisZRotation)
	camera.rotation[1], camera.rotation[2], camera.rotation[3] = axisXRotation, axisYRotation, axisZRotation
	camera.rotationMatrix = matrix.multiply(
		matrix.multiply(
			OCGL.newRotationMatrix(OCGL.axis.x, -camera.rotation[1]),
			OCGL.newRotationMatrix(OCGL.axis.y, -camera.rotation[2])
		),
		OCGL.newRotationMatrix(OCGL.axis.z, -camera.rotation[3])
	)
	-- local lookVectorMatrix = matrix.multiply({ camera.lookVector }, camera.rotationMatrix)
	-- camera.lookVector[1], camera.lookVector[2], camera.lookVector[3] = lookVectorMatrix[1][1], lookVectorMatrix[1][2], lookVectorMatrix[1][3]
end

local function cameraRotate(camera, axisXAdditionalRotation, axisYAdditionalRotation, axisZAdditionalRotation)
	cameraSetRotation(camera, camera.rotation[1] + axisXAdditionalRotation, camera.rotation[2] + axisYAdditionalRotation, camera.rotation[3] + axisZAdditionalRotation)
end

local function cameraSetPosition(camera, x, y, z)
	camera.position[1], camera.position[2], camera.position[3] = x, y, z
end

local function cameraTranslate(camera, xTranslation, yTranslation, zTranslation)
	camera.position[1], camera.position[2], camera.position[3] = camera.position[1] + xTranslation, camera.position[2] + yTranslation, camera.position[3] + zTranslation
end

function wildCatEngine.newCamera(vector3Position, vector3Rotation)
	local camera = {}

	camera.position = vector3Position
	camera.rotation = vector3Rotation
	camera.projectionSurface = {x = 1, y = 1, z = 100, x2 = buffer.screen.width, y2 = buffer.screen.height * 2, z2 = 1000}
	-- camera.lookVector = vector.newVector3(0, 0, 1)

	camera.setPosition = cameraSetRotation
	camera.translate = cameraTranslate
	camera.rotate = cameraRotate
	camera.setRotation = cameraSetRotation

	-- Создаем матрицу вращения камеры
	camera:rotate(0, 0, 0)

	return camera
end

-------------------------------------------------------- Scene object --------------------------------------------------------

local function sceneAddObject(scene, object)
	table.insert(scene.objects, object)

	return object
end

local function sceneAddObjects(scene, objects)
	for objectIndex = 1, #objects do
		table.insert(scene.objects, objects[objectIndex])
	end

	return objects
end

local function sceneRender(scene, backgroundColor, renderMode)
	OCGL.setProjectionSurface(scene.camera.projectionSurface.x, scene.camera.projectionSurface.y, scene.camera.projectionSurface.z, scene.camera.projectionSurface.x2, scene.camera.projectionSurface.y2, scene.camera.projectionSurface.z2)
	OCGL.clearBuffer(backgroundColor)

	for objectIndex = 1, #scene.objects do
		scene.objects[objectIndex]:pushToRenderQueue()
	end
	
	OCGL.translate(vector.newVector3(-scene.camera.position[1], -scene.camera.position[2], -scene.camera.position[3]))
	OCGL.rotate(scene.camera.rotationMatrix)
	OCGL.translate(vector.newVector3(0, 0, scene.camera.projectionSurface.z))
	-- OCGL.translate(vector.newVector3(scene.camera.position[1], scene.camera.position[2], scene.camera.position[3]))
	-- OCGL.translate(vector.newVector3(-scene.camera.position[1], -scene.camera.position[2], -scene.camera.position[3]))
	
	if scene.camera.projectionEnabled then OCGL.createPerspectiveProjection() end
	OCGL.render(renderMode)
	
	return scene
end

function wildCatEngine.newScene(...)
	local scene = {}

	scene.objects = {}
	scene.addObject = sceneAddObject
	scene.addObjects = sceneAddObjects
	scene.render = sceneRender

	scene.camera = wildCatEngine.newCamera(vector.newVector3(0, 0, 0), vector.newVector3(0, 0, 0))
	scene.raycast = wildCatEngine.sceneRaycast

	return scene
end

-- -------------------------------------------------------- Raycasting methods --------------------------------------------------------

-- local function vectorMultiply(a, b)
-- 	return vector.newVector3(a[2] * b[3] - a[3] * b[2], a[3] * b[1] - a[1] * b[3], a[1] * b[2] - a[2] * b[1])
-- end

-- local function getVectorDistance(a)
-- 	return math.sqrt(a[1] ^ 2 + a[2] ^ 2 + a[3] ^ 2)
-- end

-- -- В случае попадания лучика этот метод вернет сам треугольник, а также дистанцию до его плоскости
-- function wildCatEngine.triangleRaycast(vector3RayStart, vector3RayEnd)
-- 	local minimalDistance, closestTriangleIndex
-- 	for triangleIndex = 1, #OCGL.triangles do
-- 		-- Это вершины треугольника
-- 		local A, B, C = OCGL.vertices[OCGL.triangles[triangleIndex][1]], OCGL.vertices[OCGL.triangles[triangleIndex][3]], OCGL.vertices[OCGL.triangles[triangleIndex][3]]
-- 		-- Это хз че
-- 		local ABC = vectorMultiply(vector.newVector3(C[1] - A[1], C[2] - A[2], C[3] - A[3]), vector.newVector3(B[1] - A[1], B[2] - A[2], B[3] - A[3]))
-- 		-- Рассчитываем удаленность виртуальной плоскости треугольника от старта нашего луча
-- 		local D = -ABC[1] * A[1] - ABC[2] * A[2] - ABC[3] * A[3]
-- 		local firstPart = D + ABC[1] * vector3RayStart[1] + ABC[2] * vector3RayStart[2] + ABC[3] * vector3RayStart[3]
-- 		local secondPart = ABC[1] * vector3RayStart[1] - ABC[1] * vector3RayEnd[1] + ABC[2] * vector3RayStart[2] - ABC[2] * vector3RayEnd[2] + ABC[3] * vector3RayStart[3] - ABC[3] * vector3RayEnd[3]
		
-- 		-- Если наш лучик не параллелен той ебучей плоскости треугольника
-- 		if secondPart ~= 0 then
-- 			local distance = firstPart / secondPart
-- 			-- И если этот объект находится ближе к старту луча, нежели предыдущий
-- 			if (distance >= 0 and distance <= 1) and (not minimalDistance or distance < minimalDistance) then
	
-- 				-- То считаем точку попадания луча в данную плоскость (но ни хуя не факт, что он попадет в треугольник!)
-- 				local S = vector.newVector3(
-- 					vector3RayStart[1] + (vector3RayEnd[1] - vector3RayStart[1]) * distance,
-- 					vector3RayStart[2] + (vector3RayEnd[2] - vector3RayStart[2]) * distance,
-- 					vector3RayStart[3] + (vector3RayEnd[3] - vector3RayStart[3]) * distance
-- 				)

-- 				-- Далее считаем сумму площадей параллелограммов, образованных тремя треугольниками, образовавшихся при попадании точки в треугольник
-- 				-- Нууу тип кароч смари: точка ебанула в центр, и треугольник распидорасило на три мелких. Ну, и три мелких могут образовать параллелограммы свои
-- 				-- И, кароч, если сумма трех площадей этих мелких уебков будет сильно отличаться от площади жирного треугольника, то луч не попал
-- 				-- Ну, а площадь считается через sqrt(x^2+y^2+z^2) для каждого йоба-вектора

-- 				---- *A                      *B


-- 				--                  * Shotxyz


-- 				---                   *C

-- 				local SA = vector.newVector3(A[1] - S[1], A[2] - S[2], A[3] - S[3])
-- 				local SB = vector.newVector3(B[1] - S[1], B[2] - S[2], B[3] - S[3])
-- 				local SC = vector.newVector3(C[1] - S[1], C[2] - S[2], C[3] - S[3])
			
-- 				local vectorDistanceSum = getVectorDistance(vectorMultiply(SA, SB)) + getVectorDistance(vectorMultiply(SB, SC)) + getVectorDistance(vectorMultiply(SC, SA))
-- 				local ABCDistance = getVectorDistance(ABC)

-- 				-- Вот тут мы чекаем погрешность расчетов. Если все заебок, то кидаем этот треугольник в "проверенные""
-- 				if math.abs(vectorDistanceSum - ABCDistance) < 1 then
-- 					closestTriangleIndex = triangleIndex
-- 					minimalDistance = distance
-- 				end
-- 			end 
-- 		end
-- 	end

-- 	-- ecs.error(closestTriangleIndex)
-- 	return closestTriangleIndex, minimalDistance
-- end

-- -- function wildCatEngine.sceneRaycast(scene, vector3RayStart, vector3RayEnd)
-- -- 	local closestObjectIndex, closestTriangleIndex, minimalDistance
	
-- -- 	for objectIndex = 1, #scene.objects do
-- -- 		if scene.objects[objectIndex].triangles then
-- -- 			local triangleIndex, distance = wildCatEngine.meshRaycast(scene.objects[objectIndex], vector3RayStart, vector3RayEnd)
-- -- 			if triangleIndex and (not minimalDistance or distance < minimalDistance ) then
-- -- 				closestObjectIndex, closestTriangleIndex, minimalDistance = objectIndex, triangleIndex, distance
-- -- 			end
-- -- 		end
-- -- 	end

-- -- 	return closestObjectIndex, closestTriangleIndex, minimalDistance
-- -- end

-------------------------------------------------------- Zalupa --------------------------------------------------------

return wildCatEngine
