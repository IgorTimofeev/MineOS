
-------------------------------------------------------- Libraries --------------------------------------------------------

local event = require("Event")
local screen = require("Screen")
local vector = require("Vector")
local OCGL = require("OpenComputersGL/Main")
local renderer = require("OpenComputersGL/Renderer")
local materials = require("OpenComputersGL/Materials")
local meowEngine = {}

-------------------------------------------------------- Universal object methods --------------------------------------------------------

function meowEngine.newPivotPoint(vector3Position)
	return {
		position = vector3Position,
		axis = {
			vector.newVector3(1, 0, 0),
			vector.newVector3(0, 1, 0),
			vector.newVector3(0, 0, 1),
		}
	}
end

-------------------------------------------------------- Light object --------------------------------------------------------

function meowEngine.newLight(vector3Position, intensity, emissionDistance)
	return {
		position = vector3Position,
		emissionDistance = emissionDistance,
		intensity = intensity
	}
end

-------------------------------------------------------- Mesh object --------------------------------------------------------

local function pushMeshToRenderQueue(mesh)
	local vector3Vertex1, vector3Vertex2, vector3Vertex3
	for triangleIndex = 1, #mesh.triangles do
		vector3Vertex1, vector3Vertex2, vector3Vertex3 = mesh.vertices[mesh.triangles[triangleIndex][1]], mesh.vertices[mesh.triangles[triangleIndex][2]], mesh.vertices[mesh.triangles[triangleIndex][3]]
		OCGL.pushTriangleToRenderQueue(
			vector.newVector5(vector3Vertex1[1], vector3Vertex1[2], vector3Vertex1[3], vector3Vertex1[4], vector3Vertex1[5]),
			vector.newVector5(vector3Vertex2[1], vector3Vertex2[2], vector3Vertex2[3], vector3Vertex2[4], vector3Vertex2[5]),
			vector.newVector5(vector3Vertex3[1], vector3Vertex3[2], vector3Vertex3[3], vector3Vertex3[4], vector3Vertex3[5]),
			mesh.triangles[triangleIndex][4] or mesh.material
		)
	end
end


function meowEngine.newMesh(vector3Position, vertices, triangles, material)
	local mesh = {}

	mesh.vertices = vertices
	mesh.position = vector3Position
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

function meowEngine.newLine(vector3Position, vector3Vertex1, vector3Vertex2, color)
	return {
		vertices = { vector3Vertex1, vector3Vertex2 },
		color = color,
		pushToRenderQueue = pushLineToRenderQueue
	}
end

-------------------------------------------------------- Floating text object --------------------------------------------------------

local function pushFloatingTextToRenderQueue(floatingText)
	OCGL.pushFloatingTextToRenderQueue(
		vector.newVector3(floatingText.position[1], floatingText.position[2], floatingText.position[3]),
		floatingText.text,
		floatingText.color
	)
end

function meowEngine.newFloatingText(vector3Position, color, text)
	return {
		position = vector3Position,
		color = color,
		text = text,
		pushToRenderQueue = pushFloatingTextToRenderQueue
	}
end

-------------------------------------------------------- Plane object --------------------------------------------------------

function meowEngine.newPlane(vector3Position, width, height, segmentsWidth, segmentsHeight, material)
	local vertices, triangles, widthCellSize, heightCellSize, vertexIndex = {}, {}, width / segmentsWidth, height / segmentsHeight, 1
	segmentsWidth, segmentsHeight = segmentsWidth + 1, segmentsHeight + 1
	
	for zSegment = 1, segmentsHeight do
		for xSegment = 1, segmentsWidth do
			table.insert(vertices, vector.newVector3(xSegment * widthCellSize - widthCellSize, 0, zSegment * heightCellSize - heightCellSize))

			if xSegment < segmentsWidth and zSegment < segmentsHeight then
				table.insert(triangles,
					OCGL.newIndexedTriangle(
						vertexIndex,
						vertexIndex + 1,
						vertexIndex + segmentsWidth
					)
				)
				table.insert(triangles,
					OCGL.newIndexedTriangle(
						vertexIndex + 1,
						vertexIndex + segmentsWidth + 1,
						vertexIndex + segmentsWidth
					)
				)
			end

			vertexIndex = vertexIndex + 1
		end
	end
	
	return meowEngine.newMesh(vector3Position, vertices, triangles, material)
end

-------------------------------------------------------- Textured plane object --------------------------------------------------------

function meowEngine.newTexturedPlane(vector3Position, width, height, texture)
	width, height = width / 2, height / 2
	return meowEngine.newMesh(
		vector3Position,
		{
			vector.newVector5(-width, 0, -height, 1, texture.height),
			vector.newVector5(-width, 0, height, 1, 1),
			vector.newVector5(width, 0, height, texture.width, 1),
			vector.newVector5(width, 0, -height, texture.width, texture.height),
		},
		{
			OCGL.newIndexedTriangle(1, 2, 3),
			OCGL.newIndexedTriangle(1, 4, 3)
		},
		materials.newTexturedMaterial(texture)
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

function meowEngine.newCube(vector3Position, size, material)
	local halfSize = size / 2
	return meowEngine.newMesh(
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

-------------------------------------------------------- Camera object --------------------------------------------------------


local function cameraSetRotation(camera, axisXRotation, axisYRotation, axisZRotation)
	camera.rotation[1], camera.rotation[2], camera.rotation[3] = axisXRotation, axisYRotation, axisZRotation
	return camera
end

local function cameraRotate(camera, axisXAdditionalRotation, axisYAdditionalRotation, axisZAdditionalRotation)
	cameraSetRotation(camera, camera.rotation[1] + axisXAdditionalRotation, camera.rotation[2] + axisYAdditionalRotation, camera.rotation[3] + axisZAdditionalRotation)
	return camera
end

local function cameraLookAt(camera, xLook, yLook, zLook)
	local dx, dy, dz = xLook - camera.position[1], yLook - camera.position[2], zLook - camera.position[3]
	local rad180 = math.rad(180)

	local roty = math.atan(dx / dz)
	if dz < 0 then roty = roty + rad180 end
	
	local rotx = math.atan(math.sqrt(dx ^ 2 + dz ^ 2) / dy) - math.rad(90)
	if dy < 0 then rotx = rotx + rad180 end

	cameraSetRotation(camera, rotx, roty, 0)
end

local function cameraSetPosition(camera, x, y, z)
	camera.position[1], camera.position[2], camera.position[3] = x, y, z
	return camera
end

local function cameraTranslate(camera, xTranslation, yTranslation, zTranslation, xLookingAtTranslation, yLookingAtTranslation, zLookingAtTranslation)
	cameraSetPosition(camera, camera.position[1] + xTranslation, camera.position[2] + yTranslation, camera.position[3] + zTranslation)
	return camera
end

local function cameraSetFOV(camera, FOV)
	if FOV > 0 and FOV < math.pi then
		camera.FOV = FOV
		camera.projectionSurface = camera.farClippingSurface - camera.FOV / math.rad(180) * (camera.farClippingSurface - camera.nearClippingSurface)
	else
		error("FOV can't be < 0 or > 180 degrees")
	end

	return camera
end

function meowEngine.newCamera(vector3Position, FOV, nearClippingSurface, farClippingSurface)
	local camera = {}

	camera.projectionEnabled = true
	camera.position = vector3Position
	camera.rotation = {}
	camera.nearClippingSurface = nearClippingSurface
	camera.farClippingSurface = farClippingSurface
	camera.FOV = FOV

	camera.setPosition = cameraSetPosition
	camera.translate = cameraTranslate
	camera.rotate = cameraRotate
	camera.setRotation = cameraSetRotation
	camera.setFOV = cameraSetFOV
	camera.lookAt = cameraLookAt

	-- Создаем точку "лука" (и матрицу поворота камеры), а также ее плоскость проекции через ФОВ
	cameraSetRotation(camera, 0, 0, 0)
	cameraSetFOV(camera, camera.FOV)

	return camera
end

-------------------------------------------------------- Scene object --------------------------------------------------------

local function sceneAddObject(scene, object)
	table.insert(scene.objects, object)
	return object
end

local function sceneAddLight(scene, light)
	table.insert(scene.lights, light)
	return light
end

local function sceneAddObjects(scene, objects)
	for objectIndex = 1, #objects do table.insert(scene.objects, objects[objectIndex]) end
	return objects
end

local function sceneRender(scene)
	renderer.setViewport( 1, 1, screen.getWidth(), screen.getHeight() * 2, scene.camera.nearClippingSurface, scene.camera.farClippingSurface, scene.camera.projectionSurface)
	OCGL.clearBuffer(scene.backgroundColor)
	OCGL.renderMode = scene.renderMode
	OCGL.auxiliaryMode = scene.auxiliaryMode

	for objectIndex = 1, #scene.objects do
		scene.objects[objectIndex]:pushToRenderQueue()
	end

	for lightIndex = 1, #scene.lights do
		OCGL.pushLightToRenderQueue(
			vector.newVector3(scene.lights[lightIndex].position[1], scene.lights[lightIndex].position[2], scene.lights[lightIndex].position[3]),
			scene.lights[lightIndex].intensity,
			scene.lights[lightIndex].emissionDistance
		)
	end
	
	OCGL.translate(-scene.camera.position[1], -scene.camera.position[2], -scene.camera.position[3])
	OCGL.rotate(OCGL.rotateVectorRelativeToYAxis, -scene.camera.rotation[2])
	OCGL.rotate(OCGL.rotateVectorRelativeToXAxis, -scene.camera.rotation[1])
	-- OCGL.rotate(OCGL.rotateVectorRelativeToZAxis, -scene.camera.rotation[3])
	
	if scene.renderMode == OCGL.renderModes.flatShading then
		OCGL.calculateLights()
	end

	if scene.camera.projectionEnabled then
		OCGL.createPerspectiveProjection()
	end
	
	OCGL.render()
	
	return scene
end

function meowEngine.newScene(backgroundColor)
	local scene = {}

	scene.renderMode = OCGL.renderModes.constantShading
	scene.auxiliaryMode = OCGL.auxiliaryModes.disabled

	scene.backgroundColor = backgroundColor

	scene.objects = {}
	scene.lights = {}
	scene.addObject = sceneAddObject
	scene.addLight = sceneAddLight
	scene.addObjects = sceneAddObjects
	scene.render = sceneRender

	scene.camera = meowEngine.newCamera(vector.newVector3(0, 0, 0), math.rad(90), 1, 100)

	return scene
end

-------------------------------------------------------- Raycasting methods --------------------------------------------------------

local function vectorMultiply(a, b)
	return vector.newVector3(
		a[2] * b[3] - a[3] * b[2],
		a[3] * b[1] - a[1] * b[3],
		a[1] * b[2] - a[2] * b[1]
	)
end

local function getVectorDistance(a)
	return math.sqrt(a[1] ^ 2 + a[2] ^ 2 + a[3] ^ 2)
end

-- В случае попадания лучика этот метод вернет сам треугольник, а также дистанцию до его плоскости
function meowEngine.meshRaycast(mesh, vector3RayStart, vector3RayEnd)
	local minimalDistance, closestTriangleIndex
	for triangleIndex = 1, #mesh.triangles do
		-- Это вершины треугольника
		local A, B, C = mesh.vertices[mesh.triangles[triangleIndex][1]], mesh.vertices[mesh.triangles[triangleIndex][2]], mesh.vertices[mesh.triangles[triangleIndex][3]]
		-- Это вектор, образованный произведением двух векторов-сторон треугольника, он образует параллелограмм
		local ABC = vectorMultiply(
			vector.newVector3(C[1] - A[1], C[2] - A[2], C[3] - A[3]),
			vector.newVector3(B[1] - A[1], B[2] - A[2], B[3] - A[3])
		)
		-- Рассчитываем удаленность виртуальной плоскости треугольника от старта нашего луча
		local D = -ABC[1] * A[1] - ABC[2] * A[2] - ABC[3] * A[3]
		local firstPart = D + ABC[1] * vector3RayStart[1] + ABC[2] * vector3RayStart[2] + ABC[3] * vector3RayStart[3]
		local secondPart = ABC[1] * vector3RayStart[1] - ABC[1] * vector3RayEnd[1] + ABC[2] * vector3RayStart[2] - ABC[2] * vector3RayEnd[2] + ABC[3] * vector3RayStart[3] - ABC[3] * vector3RayEnd[3]
		
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
				--											*ABC	

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
	
	return closestTriangleIndex, minimalDistance
end

function meowEngine.sceneRaycast(scene, vector3RayStart, vector3RayEnd)
	local closestObjectIndex, closestTriangleIndex, minimalDistance
	
	for objectIndex = 1, #scene.objects do
		if scene.objects[objectIndex].triangles then
			local triangleIndex, distance = meowEngine.meshRaycast(scene.objects[objectIndex], vector3RayStart, vector3RayEnd)
			if triangleIndex and (not minimalDistance or distance < minimalDistance ) then
				closestObjectIndex, closestTriangleIndex, minimalDistance = objectIndex, triangleIndex, distance
			end
		end
	end

	return closestObjectIndex, closestTriangleIndex, minimalDistance
end

-------------------------------------------------------- Intro --------------------------------------------------------

function meowEngine.newPolyCatMesh(vector3Position, size)
	return meowEngine.newMesh(
		vector3Position,
		{
			vector.newVector3(-1.0 * size, 0.8 * size, 0.3 * size),
			vector.newVector3(-0.5 * size, 0.5 * size, 0.3 * size),
			vector.newVector3(0.0 * size, 0.5 * size, 0.3 * size),
			vector.newVector3(0.5 * size, 0.5 * size, 0.3 * size),
			vector.newVector3(1.0 * size, 0.8 * size, 0.3 * size),
			vector.newVector3(0.8 * size, 0.2 * size, 0.3 * size),
			vector.newVector3(0.7 * size, -0.3 * size, 0.3 * size),
			vector.newVector3(0.0 * size, -0.8 * size, 0.3 * size),
			vector.newVector3(-0.7 * size, -0.3 * size, 0.3 * size),
			vector.newVector3(-0.8 * size, 0.2 * size, 0.3 * size),
			vector.newVector3(-0.2 * size, -0.1 * size, 0.0 * size),
			vector.newVector3(0.2 * size, -0.1 * size, 0.0 * size),
			vector.newVector3(0.0 * size, -0.3 * size, 0.0 * size)
		},
		{
			OCGL.newIndexedTriangle(1, 2, 10, materials.newSolidMaterial(0x555555)),
			OCGL.newIndexedTriangle(2, 11, 10, materials.newSolidMaterial(0x6fe7fc)),
			OCGL.newIndexedTriangle(2, 3, 11, materials.newSolidMaterial(0xDDDDDD)),
			OCGL.newIndexedTriangle(3, 12, 11, materials.newSolidMaterial(0xDDDDDD)),
			OCGL.newIndexedTriangle(3, 4, 12, materials.newSolidMaterial(0xDDDDDD)),
			OCGL.newIndexedTriangle(4, 6, 12, materials.newSolidMaterial(0xa8f1fd)),
			OCGL.newIndexedTriangle(4, 5, 6, materials.newSolidMaterial(0x808080)),
			
			OCGL.newIndexedTriangle(6, 7, 8, materials.newSolidMaterial(0xCCCCCC)),
			OCGL.newIndexedTriangle(12, 6, 8, materials.newSolidMaterial(0xCCCCCC)),
			OCGL.newIndexedTriangle(13, 12, 8, materials.newSolidMaterial(0xCCCCCC)),
			
			OCGL.newIndexedTriangle(11, 12, 13, materials.newSolidMaterial(0x555555)),
			OCGL.newIndexedTriangle(11, 13, 8, materials.newSolidMaterial(0xBBBBBB)),
			OCGL.newIndexedTriangle(10, 11, 8, materials.newSolidMaterial(0xBBBBBB)),
			OCGL.newIndexedTriangle(10, 8, 9, materials.newSolidMaterial(0xBBBBBB))
		},
		materials.newSolidMaterial(0xFF0000)
	)
end

function meowEngine.intro(vector3Position, size)
	local GUI = require("GUI")
	local scene = meowEngine.newScene(0xEEEEEE)
	scene:addObject(meowEngine.newPolyCatMesh(vector3Position, size))
	scene:addObject(meowEngine.newFloatingText(vector.newVector3(vector3Position[1] + 2, vector3Position[2] - size, vector3Position[3] + size * 0.1), 0xBBBBBB, "Powered by MeowEngine™"))

	local from, to, speed = -30, 20, 4
	local transparency, transparencyStep = 0, 1 / math.abs(to - from) * speed

	scene.camera:setPosition(from, 0, -32)
	while scene.camera.position[1] < to do
		scene.camera:translate(speed, 0, 0)
		scene.camera:lookAt(0, 0, 0)
		scene:render()
		if scene.camera.position[1] < to then screen.clear(0x0, transparency) end
		screen.update()

		transparency = transparency + transparencyStep
		-- ecs.error("POS: " .. scene.camera.position[1] .. ", " .. scene.camera.position[2] .. ", " .. scene.camera.position[3] .. ", ROT: " .. math.deg(scene.camera.rotation[1]) .. ", " .. math.deg(scene.camera.rotation[2]) .. ", " .. math.deg(scene.camera.rotation[3]))
		event.sleep(0.01)
	end

	event.sleep(2)

	for i = 1, 0, -0.2 do
		scene:render()
		screen.clear(0x0, i)
		screen.update()
	end
end

-------------------------------------------------------- Zalupa --------------------------------------------------------

return meowEngine
