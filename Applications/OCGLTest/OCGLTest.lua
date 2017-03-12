
-------------------------------------------------------- Libraries --------------------------------------------------------

-- package.loaded["GUI"] = nil
-- package.loaded["doubleBuffering"] = nil
package.loaded["vector"] = nil
package.loaded["matrix"] = nil
package.loaded["OpenComputersGL/Main"] = nil
package.loaded["OpenComputersGL/Materials"] = nil
package.loaded["OpenComputersGL/Renderer"] = nil
package.loaded["PolyCatEngine/Main"] = nil
package.loaded["PolyCatEngine/PostProcessing"] = nil

local colorlib = require("colorlib")
local ecs = require("ECSAPI")
local computer = require("computer")
local buffer = require("doubleBuffering")
local event = require("event")
local GUI = require("GUI")
local vector = require("vector")
local matrix = require("matrix")
local materials = require("OpenComputersGL/Materials")
local renderer = require("OpenComputersGL/Renderer")
local OCGL = require("OpenComputersGL/Main")
local polyCatEngine = require("PolyCatEngine/Main")

-------------------------------------------------------- Constants --------------------------------------------------------

local autoRotate, showGrid = false, true
local rotationAngle = math.rad(5)
local translationOffset = 1
local materialChange, materialHue = false, 0

local scene = polyCatEngine.newScene(0x222222)

---------------------------------------------- GRAPHEN SAMPLES YOPTA ----------------------------------------------

scene.camera:translate(0, 0, -20)
local light = scene:addObject(polyCatEngine.newLight(vector.newVector3(0, 10, 0), 1000))

---------------------------------------------- Lighting test ----------------------------------------------

-- scene:addObject(polyCatEngine.newCube(vector.newVector3(0, 0, 0), 5, materials.newSolidMaterial(0xFF4444)))
-- scene:addObject(
-- 	polyCatEngine.newMesh(
-- 		vector.newVector3(0, 0, 0),
-- 		{
-- 			vector.newVector3(0, 0, 10),
-- 			vector.newVector3(10, 0, 10),
-- 			vector.newVector3(5, 0, 0),	
-- 		},
-- 		{
-- 			OCGL.newIndexedTriangle(1, 2, 3)
-- 		},
-- 		materials.newSolidMaterial(0xFF4444)
-- 	)
-- )

---------------------------------------------- Cubes ----------------------------------------------

local spaceBetween = 2
local cubeSize = 5
local xCubes, yCubes = 3, 3
local xCubeStart = -math.floor(xCubes / 2) * (cubeSize + spaceBetween)
local xCube, zCube = xCubeStart, -math.floor(yCubes / 2) * (cubeSize + spaceBetween)
local hueCube, hueCubeStep = 0, 359 / (xCubes * yCubes)
for j = 1, yCubes do
	for i = 1, xCubes do
		if not (i == 2 and j == 2) then
			scene:addObject(polyCatEngine.newCube(
				vector.newVector3(xCube, 0, zCube),
				cubeSize,
				materials.newSolidMaterial(colorlib.HSBtoHEX(hueCube, 100, 100))
			))
			hueCube = hueCube + hueCubeStep
		end
		xCube = xCube + cubeSize + spaceBetween
	end
	zCube, xCube = zCube + cubeSize + spaceBetween, xCubeStart
end

---------------------------------------------- Cat ----------------------------------------------

-- scene:addObject(polyCatEngine.newPolyCatMesh(vector.newVector3(0, 5, 0), 5))
-- scene:addObject(polyCatEngine.newFloatingText(vector.newVector3(0, -12, 0), 0xEEEEEE, "Тест плавающего текста"))

---------------------------------------------- Texture ----------------------------------------------

-- scene.camera:translate(0, 20, 0)
-- scene.camera:rotate(math.rad(90), 0, 0)
-- local texturedPlane = scene:addObject(polyCatEngine.newTexturedPlane(vector.newVector3(0, 0, 0), 20, 20, materials.newDebugTexture(16, 16, 40)))

---------------------------------------------- Fractal ----------------------------------------------

-- local function createField(vector3Position, xCellCount, yCellCount, cellSize)
-- 	local totalWidth, totalHeight = xCellCount * cellSize, yCellCount * cellSize
-- 	local halfWidth, halfHeight = totalWidth / 2, totalHeight / 2
-- 	xCellCount, yCellCount = xCellCount + 1, yCellCount + 1
-- 	local vertices, triangles = {}, {}

-- 	local vertexIndex = 1
-- 	for yCell = 1, yCellCount do
-- 		for xCell = 1, xCellCount do
-- 			table.insert(vertices, vector.newVector3(xCell * cellSize - cellSize - halfWidth, yCell * cellSize - cellSize - halfHeight, 0))

-- 			if xCell < xCellCount and yCell < yCellCount then
-- 				table.insert(triangles,
-- 					OCGL.newIndexedTriangle(
-- 						vertexIndex,
-- 						vertexIndex + 1,
-- 						vertexIndex + xCellCount
-- 					)
-- 				)
-- 				table.insert(triangles,
-- 					OCGL.newIndexedTriangle(
-- 						vertexIndex + 1,
-- 						vertexIndex + xCellCount + 1,
-- 						vertexIndex + xCellCount
-- 					)
-- 				)
-- 			end

-- 			vertexIndex = vertexIndex + 1
-- 		end
-- 	end

-- 	local mesh = polyCatEngine.newMesh(vector3Position, vertices, triangles,materials.newSolidMaterial(0xFF8888))
	
-- 	local function getRandomSignedInt(from, to)
-- 		return (math.random(0, 1) == 1 and 1 or -1) * (math.random(from, to))
-- 	end

-- 	local function getRandomDirection()
-- 		return getRandomSignedInt(5, 100) / 100
-- 	end

-- 	mesh.randomizeTrianglesColor = function(mesh, hueChangeSpeed, brightnessChangeSpeed, minimumBrightness)
-- 		mesh.hue = mesh.hue and mesh.hue + hueChangeSpeed or math.random(0, 360)
-- 		if mesh.hue > 359 then mesh.hue = 0 end

-- 		for triangleIndex = 1, #mesh.triangles do
-- 			mesh.triangles[triangleIndex].brightness = mesh.triangles[triangleIndex].brightness and mesh.triangles[triangleIndex].brightness + getRandomSignedInt(1, brightnessChangeSpeed) or math.random(minimumBrightness, 100)
-- 			if mesh.triangles[triangleIndex].brightness > 100 then
-- 				mesh.triangles[triangleIndex].brightness = 100
-- 			elseif mesh.triangles[triangleIndex].brightness < minimumBrightness then
-- 				mesh.triangles[triangleIndex].brightness = minimumBrightness
-- 			end
-- 			mesh.triangles[triangleIndex][4] = materials.newSolidMaterial(colorlib.HSBtoHEX(mesh.hue, 100, mesh.triangles[triangleIndex].brightness))
-- 		end
-- 	end

-- 	mesh.randomizeVerticesPosition = function(mesh, speed)
-- 		local vertexIndex = 1
-- 		for yCell = 1, yCellCount do
-- 			for xCell = 1, xCellCount do
-- 				if xCell > 1 and xCell < xCellCount and yCell > 1 and yCell < yCellCount then
-- 					mesh.vertices[vertexIndex].offset = mesh.vertices[vertexIndex].offset or {0, 0}
-- 					mesh.vertices[vertexIndex].direction = mesh.vertices[vertexIndex].direction or {getRandomDirection(), getRandomDirection()}

-- 					local newOffset = {
-- 						mesh.vertices[vertexIndex].direction[1] * (speed * cellSize),
-- 						mesh.vertices[vertexIndex].direction[1] * (speed * cellSize)
-- 					}
					
-- 					for i = 1, 2 do
-- 						if math.abs(mesh.vertices[vertexIndex].offset[i] + newOffset[i]) < cellSize / 2 then
-- 							mesh.vertices[vertexIndex].offset[i] = mesh.vertices[vertexIndex].offset[i] + newOffset[i]
-- 							mesh.vertices[vertexIndex][i] = mesh.vertices[vertexIndex][i] + newOffset[i]
-- 						else
-- 							mesh.vertices[vertexIndex].direction[i] = getRandomDirection()
-- 						end
-- 					end
-- 				end
-- 				vertexIndex = vertexIndex + 1
-- 			end
-- 		end
-- 	end

-- 	return mesh
-- end

-- local plane = createField(vector.newVector3(0, 0, 0), 8, 4, 4)
-- scene:addObject(plane)

-------------------------------------------------------- Main methods --------------------------------------------------------

local function move(x, y, z)
	local moveVector = vector.newVector3(x, y, z)
	OCGL.rotateVector(moveVector, OCGL.axis.x, scene.camera.rotation[1])
	OCGL.rotateVector(moveVector, OCGL.axis.y, scene.camera.rotation[2])
	scene.camera:translate(moveVector[1], moveVector[2], moveVector[3])
end

local controls = {
	-- Arrows
	[200] = function() scene.camera:rotate(-rotationAngle, 0, 0) end,
	[208] = function() scene.camera:rotate(rotationAngle, 0, 0) end,
	[203] = function() scene.camera:rotate(0, -rotationAngle, 0) end,
	[205] = function() scene.camera:rotate(0, rotationAngle, 0) end,
	[16 ] = function() scene.camera:rotate(0, 0, rotationAngle) end,
	[18 ] = function() scene.camera:rotate(0, 0, -rotationAngle) end,

	-- +-
	[13 ] = function()  end,
	[12 ] = function()  end,
	-- G, Z, X
	[34 ] = function() scene.showGrid = not scene.showGrid end,
	[44 ] = function() scene.auxiliaryMode = scene.auxiliaryMode + 1; if scene.auxiliaryMode > 3 then scene.auxiliaryMode = 1 end end,
	[45 ] = function() scene.renderMode = scene.renderMode + 1; if scene.renderMode > 4 then scene.renderMode = 1 end end,
	-- WASD
	[17 ] = function() move(0, 0, translationOffset) end,
	[31 ] = function() move(0, 0, -translationOffset) end,
	[30 ] = function() move(-translationOffset, 0, 0) end,
	[32 ] = function() move(translationOffset, 0, 0) end,
	--RSHIFT, SPACE
	[42 ] = function() move(0, -translationOffset, 0) end,
	[57 ] = function() move(0, translationOffset, 0) end,
	-- Backspace, R, Enter
	[14 ] = function() os.exit() end,
	[19 ] = function() autoRotate = not autoRotate end,
	[28 ] = function() scene.camera.projectionEnabled = not scene.camera.projectionEnabled end,
	-- M
	[50 ] = function() materialChange = not materialChange end,
	-- NUM 4 6 8 5 1 3
	[75 ] = function() light.position[1] = light.position[1] - translationOffset end,
	[77 ] = function() light.position[1] = light.position[1] + translationOffset end,
	[72 ] = function() light.position[2] = light.position[2] + translationOffset end,
	[80 ] = function() light.position[2] = light.position[2] - translationOffset end,
	[79 ] = function() light.position[3] = light.position[3] - translationOffset end,
	[81 ] = function() light.position[3] = light.position[3] + translationOffset end,
}

-------------------------------------------------------- Main shit --------------------------------------------------------

buffer.start()
-- polyCatEngine.intro(vector.newVector3(0, 0, 0), 20)

local function drawInvertedText(x, y, text)
	local index = buffer.getBufferIndexByCoordinates(x, y)
	local background, foreground = buffer.rawGet(index)
	buffer.rawSet(index, background, 0xFFFFFF - foreground, text)
end

local function drawCross(x, y)
	drawInvertedText(x - 2, y, "━")
	drawInvertedText(x - 1, y, "━")
	drawInvertedText(x + 2, y, "━")
	drawInvertedText(x + 1, y, "━")
	drawInvertedText(x, y - 1, "┃")
	drawInvertedText(x, y + 1, "┃")
end

local function renderMethod()
	if materialChange then
		plane:randomizeTrianglesColor(5, 5, 50)
		plane:randomizeVerticesPosition(0.05)
	end

	scene:render()
	drawCross(math.floor(buffer.screen.width / 2), math.floor(buffer.screen.height / 2))

	local y = 6
	local total = computer.totalMemory()
	buffer.text(2, y, 0xFFFFFF, "RenderMode: " .. scene.renderMode); y = y + 1
	buffer.text(2, y, 0xFFFFFF, "AuxiliaryMode: " .. scene.auxiliaryMode); y = y + 2
	buffer.text(2, y, 0xFFFFFF, "CameraFOV: " .. string.format("%.2f", math.deg(scene.camera.FOV))); y = y + 1
	buffer.text(2, y, 0xFFFFFF, "СameraPosition: " .. string.format("%.2f", scene.camera.position[1]) .. " x " .. string.format("%.2f", scene.camera.position[2]) .. " x " .. string.format("%.2f", scene.camera.position[3])); y = y + 1
	buffer.text(2, y, 0xFFFFFF, "СameraRotation: " .. string.format("%.2f", math.deg(scene.camera.rotation[1])) .. " x " .. string.format("%.2f", math.deg(scene.camera.rotation[2])) .. " x " .. string.format("%.2f", math.deg(scene.camera.rotation[3]))); y = y + 1
	buffer.text(2, y, 0xFFFFFF, "CameraNearClippingSurface: " .. string.format("%.2f", scene.camera.nearClippingSurface)); y = y + 1
	buffer.text(2, y, 0xFFFFFF, "CameraFarClippingSurface: " .. string.format("%.2f", scene.camera.farClippingSurface)); y = y + 1
	buffer.text(2, y, 0xFFFFFF, "CameraProjectionSurface: " .. string.format("%.2f", scene.camera.projectionSurface)); y = y + 1
	buffer.text(2, y, 0xFFFFFF, "CameraPerspectiveProjection: " .. tostring(scene.camera.projectionEnabled)); y = y + 3
	GUI.progressBar(2, y, 30, 0xFFFF00, 0xFFFFFF, 0xFFFFFF, math.ceil((total - computer.freeMemory()) / total * 100), true, true, "RAM usage: ", "%"):draw(); y = y + 3
end

while true do
	local e = {event.pull(0)}

	if e[1] == "key_down" then
		if controls[e[4]] then controls[e[4]]() end
	elseif e[1] == "scroll" then
		if e[5] == 1 then
			if scene.camera.FOV < math.rad(170) then
				scene.camera:setFOV(scene.camera.FOV + math.rad(5))
			end
		else
			if scene.camera.FOV > math.rad(5) then
				scene.camera:setFOV(scene.camera.FOV - math.rad(5))
			end
		end
	elseif e[1] == "touch" then
		local targetVector = vector.newVector3(scene.camera.position[1], scene.camera.position[2], scene.camera.position[3] + 1000)
		OCGL.rotateVector(targetVector, OCGL.axis.x, scene.camera.rotation[1])
		OCGL.rotateVector(targetVector, OCGL.axis.y, scene.camera.rotation[2])
		local objectIndex, triangleIndex, distance = polyCatEngine.sceneRaycast(
			scene,
			scene.camera.position,
			targetVector
		)

		if objectIndex then
			if e[5] == 1 then
				scene.objects[objectIndex].triangles[triangleIndex][4] = nil
			else
				-- scene.objects[objectIndex].material = materials.newSolidMaterial(math.random(0x0, 0xFFFFFF))
				-- scene.objects[objectIndex].material = materials.newTexturedMaterial(materials.newDebugTexture(16, 16, math.random(0, 360)))
				scene.objects[objectIndex].triangles[triangleIndex][4] = materials.newSolidMaterial(math.random(0x0, 0xFFFFFF))
			end
		end
	end

	if autoRotate then
		scene.camera:rotate(0, rotationAngle, 0)
	end

	renderer.renderFPSCounter(2, 2, renderMethod, 0xFFFF00)
	buffer.draw()
end

