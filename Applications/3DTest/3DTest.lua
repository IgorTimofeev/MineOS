
-------------------------------------------------------- Libraries --------------------------------------------------------

-- package.loaded["GUI"] = nil
-- package.loaded["doubleBuffering"] = nil
package.loaded["vector"] = nil
package.loaded["matrix"] = nil
package.loaded["OpenComputersGL/Main"] = nil
package.loaded["OpenComputersGL/Materials"] = nil
package.loaded["OpenComputersGL/Renderer"] = nil
package.loaded["PolyCatEngine/Main"] = nil

local colorlib = require("colorlib")
local ecs = require("ECSAPI")
local computer = require("computer")
local buffer = require("doubleBuffering")
local event = require("event")
local GUI = require("GUI")
local windows = require("windows")
local vector = require("vector")
local matrix = require("matrix")
local materials = require("OpenComputersGL/Materials")
local renderer = require("OpenComputersGL/Renderer")
local OCGL = require("OpenComputersGL/Main")
local polyCatEngine = require("PolyCatEngine/Main")

---------------------------------------------- Anus preparing ----------------------------------------------

buffer.start()
polyCatEngine.intro(vector.newVector3(0, 0, 0), 20)
local mainWindow = windows.fullScreen()
local scene = polyCatEngine.newScene(0x1D1D1D)
scene:addLight(polyCatEngine.newLight(vector.newVector3(0, 20, 0), 1000))
scene.camera:translate(-2.5, 8.11, -19.57)
scene.camera:rotate(math.rad(30), 0, 0)

---------------------------------------------- Constants ----------------------------------------------

local blockSize = 5
local rotationAngle = math.rad(5)
local translationOffset = 1

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

---------------------------------------------- Voxel-world system ----------------------------------------------

local world = {{{}}}

local worldMesh = scene:addObject(
	polyCatEngine.newMesh(
		vector.newVector3(0, 0, 0), { }, { },
		materials.newSolidMaterial(0xFF00FF)
	)
)

local function checkBlock(x, y, z)
	if world[z] and world[z][y] and world[z][y][x] then
		return true
	end
	return false
end

local function setBlock(x, y, z, value)
	world[z] = world[z] or {}
	world[z][y] = world[z][y] or {}
	world[z][y][x] = value
end

local blockSides = {
	front = 1,
	left = 2,
	back = 3,
	right = 4,
	up = 5,
	down = 6
}

local function renderWorld()
	worldMesh.vertices = {}
	worldMesh.triangles = {}

	for z in pairs(world) do
		for y in pairs(world[z]) do
			for x in pairs(world[z][y]) do
				local firstVertexIndex = #worldMesh.vertices + 1
				local xBlock, yBlock, zBlock = (x - 1) * blockSize, (y - 1) * blockSize, (z - 1) * blockSize
				local material = materials.newSolidMaterial(world[z][y][x])

				table.insert(worldMesh.vertices, vector.newVector3(xBlock, yBlock, zBlock))
				table.insert(worldMesh.vertices, vector.newVector3(xBlock, yBlock + blockSize, zBlock))
				table.insert(worldMesh.vertices, vector.newVector3(xBlock + blockSize, yBlock + blockSize, zBlock))
				table.insert(worldMesh.vertices, vector.newVector3(xBlock + blockSize, yBlock, zBlock))
				table.insert(worldMesh.vertices, vector.newVector3(xBlock, yBlock, zBlock + blockSize))
				table.insert(worldMesh.vertices, vector.newVector3(xBlock, yBlock + blockSize, zBlock + blockSize))
				table.insert(worldMesh.vertices, vector.newVector3(xBlock + blockSize, yBlock + blockSize, zBlock + blockSize))
				table.insert(worldMesh.vertices, vector.newVector3(xBlock + blockSize, yBlock, zBlock + blockSize))

				-- Front (1, 2)
				if not checkBlock(x, y, z - 1) then
					local triangle1 = OCGL.newIndexedTriangle(firstVertexIndex, firstVertexIndex + 1, firstVertexIndex + 2, material)
					triangle1[6] = blockSides.front
					table.insert(worldMesh.triangles, triangle1)
					
					local triangle2 = OCGL.newIndexedTriangle(firstVertexIndex, firstVertexIndex + 3, firstVertexIndex + 2, material)
					triangle2[6] = blockSides.front
					table.insert(worldMesh.triangles, triangle2)
				end

				-- Left (3, 4)
				if not checkBlock(x - 1, y, z) then
					local triangle1 = OCGL.newIndexedTriangle(firstVertexIndex + 1, firstVertexIndex + 5, firstVertexIndex + 4, material)
					triangle1[6] = blockSides.left
					table.insert(worldMesh.triangles, triangle1)
					
					local triangle2 = OCGL.newIndexedTriangle(firstVertexIndex + 1, firstVertexIndex, firstVertexIndex + 4, material)
					triangle2[6] = blockSides.left
					table.insert(worldMesh.triangles, triangle2)
				end

				-- Back (5, 6)
				if not checkBlock(x, y, z + 1) then
					local triangle1 = OCGL.newIndexedTriangle(firstVertexIndex + 5, firstVertexIndex + 6, firstVertexIndex + 7, material)
					triangle1[6] = blockSides.back
					table.insert(worldMesh.triangles, triangle1)
					
					local triangle2 = OCGL.newIndexedTriangle(firstVertexIndex + 5, firstVertexIndex + 4, firstVertexIndex + 7, material)
					triangle2[6] = blockSides.back
					table.insert(worldMesh.triangles, triangle2)
				end

				-- Right (7, 8)
				if not checkBlock(x + 1, y, z) then
					local triangle1 = OCGL.newIndexedTriangle(firstVertexIndex + 3, firstVertexIndex + 2, firstVertexIndex + 6, material)
					triangle1[6] = blockSides.right
					table.insert(worldMesh.triangles, triangle1)
					
					local triangle2 = OCGL.newIndexedTriangle(firstVertexIndex + 3, firstVertexIndex + 7, firstVertexIndex + 6, material)
					triangle2[6] = blockSides.right
					table.insert(worldMesh.triangles, triangle2)
				end

				-- Up (9, 10)
				if not checkBlock(x, y + 1, z) then
					local triangle1 = OCGL.newIndexedTriangle(firstVertexIndex + 1, firstVertexIndex + 5, firstVertexIndex + 6, material)
					triangle1[6] = blockSides.up
					table.insert(worldMesh.triangles, triangle1)
					
					local triangle2 = OCGL.newIndexedTriangle(firstVertexIndex + 1, firstVertexIndex + 2, firstVertexIndex + 6, material)
					triangle2[6] = blockSides.up
					table.insert(worldMesh.triangles, triangle2)
				end

				-- Down (11, 12)
				if not checkBlock(x, y - 1, z) then
					local triangle1 = OCGL.newIndexedTriangle(firstVertexIndex, firstVertexIndex + 4, firstVertexIndex + 7, material)
					triangle1[6] = blockSides.down
					table.insert(worldMesh.triangles, triangle1)
					
					local triangle2 = OCGL.newIndexedTriangle(firstVertexIndex, firstVertexIndex + 3, firstVertexIndex + 7, material)
					triangle2[6] = blockSides.down
					table.insert(worldMesh.triangles, triangle2)
				end
			end
		end
	end
end

local hue, hueStep = 0, 360 / 9
for i = -1, 1 do
	for j = -1, 1 do
		if not (i == 0 and j == 0) then
			setBlock(i, 0, j, colorlib.HSBtoHEX(hue, 100, 100))
			hue = hue + hueStep
		end
	end
end

---------------------------------------------- Cat ----------------------------------------------

-- scene:addObject(polyCatEngine.newPolyCatMesh(vector.newVector3(0, 5, 0), 5))
-- scene:addObject(polyCatEngine.newFloatingText(vector.newVector3(0, -2, 0), 0xEEEEEE, "Тест плавающего текста"))

---------------------------------------------- Texture ----------------------------------------------

-- scene.camera:translate(0, 20, 0)
-- scene.camera:rotate(math.rad(90), 0, 0)
-- local texturedPlane = scene:addObject(polyCatEngine.newTexturedPlane(vector.newVector3(0, 0, 0), 20, 20, materials.newDebugTexture(16, 16, 40)))

---------------------------------------------- Fractal field ----------------------------------------------

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
-- plane:randomizeTrianglesColor(10, 10, 50)

-------------------------------------------------------- Controls --------------------------------------------------------

local function move(x, y, z)
	local moveVector = vector.newVector3(x, y, z)
	OCGL.rotateVector(moveVector, OCGL.axis.x, scene.camera.rotation[1])
	OCGL.rotateVector(moveVector, OCGL.axis.y, scene.camera.rotation[2])
	scene.camera:translate(moveVector[1], moveVector[2], moveVector[3])
end

local function moveLight(x, y, z)
	scene.lights[mainWindow.toolbar.lightSelectComboBox.currentItem].position[1] = scene.lights[mainWindow.toolbar.lightSelectComboBox.currentItem].position[1] + x
	scene.lights[mainWindow.toolbar.lightSelectComboBox.currentItem].position[2] = scene.lights[mainWindow.toolbar.lightSelectComboBox.currentItem].position[2] + y
	scene.lights[mainWindow.toolbar.lightSelectComboBox.currentItem].position[3] = scene.lights[mainWindow.toolbar.lightSelectComboBox.currentItem].position[3] + z
end

local controls = {
	-- F1
	[59 ] = function() mainWindow.toolbar.isHidden = not mainWindow.toolbar.isHidden; mainWindow.infoTextBox.isHidden = not mainWindow.infoTextBox.isHidden end,
	-- Arrows
	[200] = function() scene.camera:rotate(-rotationAngle, 0, 0) end,
	[208] = function() scene.camera:rotate(rotationAngle, 0, 0) end,
	[203] = function() scene.camera:rotate(0, -rotationAngle, 0) end,
	[205] = function() scene.camera:rotate(0, rotationAngle, 0) end,
	[16 ] = function() scene.camera:rotate(0, 0, rotationAngle) end,
	[18 ] = function() scene.camera:rotate(0, 0, -rotationAngle) end,
	-- WASD
	[17 ] = function() move(0, 0, translationOffset) end,
	[31 ] = function() move(0, 0, -translationOffset) end,
	[30 ] = function() move(-translationOffset, 0, 0) end,
	[32 ] = function() move(translationOffset, 0, 0) end,
	-- RSHIFT, SPACE
	[42 ] = function() move(0, -translationOffset, 0) end,
	[57 ] = function() move(0, translationOffset, 0) end,
	-- NUM 4 6 8 5 1 3
	[75 ] = function() moveLight(-translationOffset, 0, 0) end,
	[77 ] = function() moveLight(translationOffset, 0, 0) end,
	[72 ] = function() moveLight(0, 0, translationOffset) end,
	[80 ] = function() moveLight(0, 0, -translationOffset) end,
	[79 ] = function() moveLight(0, -translationOffset, 0) end,
	[81 ] = function() moveLight(0, translationOffset, 0) end,
}

-------------------------------------------------------- GUI --------------------------------------------------------

local OCGLView = GUI.object(1, 1, mainWindow.width, mainWindow.height)

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

OCGLView.draw = function(object)
	mainWindow.oldClock = os.clock()
	if world then renderWorld() end
	scene:render()
	if mainWindow.toolbar.zBufferSwitch.state then
		renderer.visualizeDepthBuffer()
	end
	drawCross(renderer.viewport.xCenter, math.floor(renderer.viewport.yCenter / 2))
end

OCGLView.onTouch = function(e)
	local targetVector = vector.newVector3(scene.camera.position[1], scene.camera.position[2], scene.camera.position[3] + 1000)
	OCGL.rotateVector(targetVector, OCGL.axis.x, scene.camera.rotation[1])
	OCGL.rotateVector(targetVector, OCGL.axis.y, scene.camera.rotation[2])
	local objectIndex, triangleIndex, distance = polyCatEngine.sceneRaycast(scene, scene.camera.position, targetVector)

	if objectIndex then
		local triangle = scene.objects[objectIndex].triangles[triangleIndex]
		local xMiddle = (scene.objects[objectIndex].vertices[triangle[1]][1] + scene.objects[objectIndex].vertices[triangle[2]][1] + scene.objects[objectIndex].vertices[triangle[3]][1]) / 3
		local yMiddle = (scene.objects[objectIndex].vertices[triangle[1]][2] + scene.objects[objectIndex].vertices[triangle[2]][2] + scene.objects[objectIndex].vertices[triangle[3]][2]) / 3
		local zMiddle = (scene.objects[objectIndex].vertices[triangle[1]][3] + scene.objects[objectIndex].vertices[triangle[2]][3] + scene.objects[objectIndex].vertices[triangle[3]][3]) / 3

		local xWorld = math.floor(xMiddle / blockSize) + 1
		local yWorld = math.floor(yMiddle / blockSize) + 1
		local zWorld = math.floor(zMiddle / blockSize) + 1

		if e[5] == 1 then
			if triangle[6] == blockSides.front then
				zWorld = zWorld - 1
			elseif triangle[6] == blockSides.left then
				xWorld = xWorld - 1
			elseif triangle[6] == blockSides.down then
				yWorld = yWorld - 1
			end
			setBlock(xWorld, yWorld, zWorld, mainWindow.toolbar.blockColorSelector.color)
		else
			if triangle[6] == blockSides.back then
				zWorld = zWorld - 1
			elseif triangle[6] == blockSides.right then
				xWorld = xWorld - 1
			elseif triangle[6] == blockSides.up then
				yWorld = yWorld - 1
			end
			setBlock(xWorld, yWorld, zWorld, nil)
		end
	end
end

mainWindow:addChild(OCGLView)

mainWindow.infoTextBox = mainWindow:addTextBox(2, 5, 45, mainWindow.height, nil, 0xEEEEEE, {}, 1, 0, 0)
mainWindow:addLabel(2, mainWindow.height, mainWindow.width - 1, 1, 0x444444, "Authors: Timofeef Igor (vk.com/id7799889), Trifonov Gleb (vk.com/id88323331), Verevkin Yakov (vk.com/id60991376)")

local elementY = 2
mainWindow.toolbar = mainWindow:addContainer(mainWindow.width - 31, 1, 32, mainWindow.height)
local elementWidth = mainWindow.toolbar.width - 2
mainWindow.toolbar:addPanel(1, 1, mainWindow.toolbar.width, mainWindow.toolbar.height, 0x0, 50)

mainWindow.toolbar:addLabel(2, elementY, elementWidth, 1, 0xEEEEEE, "Render mode"):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top); elementY = elementY + 2
mainWindow.toolbar.renderModeComboBox = mainWindow.toolbar:addComboBox(2, elementY, elementWidth, 1, 0x2D2D2D, 0xAAAAAA, 0x555555, 0x888888); elementY = elementY + mainWindow.toolbar.renderModeComboBox.height + 1
mainWindow.toolbar.renderModeComboBox:addItem("disabled")
mainWindow.toolbar.renderModeComboBox:addItem("constantShading")
mainWindow.toolbar.renderModeComboBox:addItem("flatShading")
mainWindow.toolbar.renderModeComboBox.currentItem = 2
mainWindow.toolbar.renderModeComboBox.onItemSelected = function()
	scene.renderMode = mainWindow.toolbar.renderModeComboBox.currentItem
end

mainWindow.toolbar.auxiliaryModeComboBox = mainWindow.toolbar:addComboBox(2, elementY, elementWidth, 1, 0x2D2D2D, 0xAAAAAA, 0x555555, 0x888888); elementY = elementY + mainWindow.toolbar.auxiliaryModeComboBox.height + 1
mainWindow.toolbar.auxiliaryModeComboBox:addItem("disabled")
mainWindow.toolbar.auxiliaryModeComboBox:addItem("wireframe")
mainWindow.toolbar.auxiliaryModeComboBox:addItem("vertices")
mainWindow.toolbar.auxiliaryModeComboBox.currentItem = 1
mainWindow.toolbar.auxiliaryModeComboBox.onItemSelected = function()
	scene.auxiliaryMode = mainWindow.toolbar.auxiliaryModeComboBox.currentItem
end

mainWindow.toolbar:addLabel(2, elementY, elementWidth, 1, 0xAAAAAA, "Perspective proj:")
mainWindow.toolbar.perspectiveSwitch = mainWindow.toolbar:addSwitch(mainWindow.toolbar.width - 8, elementY, 8, 0x66DB80, 0x2D2D2D, 0xEEEEEE, scene.camera.projectionEnabled); elementY = elementY + 2
mainWindow.toolbar.perspectiveSwitch.onStateChanged = function(state)
	scene.camera.projectionEnabled = state
end

mainWindow.toolbar:addLabel(2, elementY, elementWidth, 1, 0xAAAAAA, "Z-buffer visualize:")
mainWindow.toolbar.zBufferSwitch = mainWindow.toolbar:addSwitch(mainWindow.toolbar.width - 8, elementY, 8, 0x66DB80, 0x2D2D2D, 0xEEEEEE, false); elementY = elementY + 2


local function calculateLightComboBox()
	mainWindow.toolbar.lightSelectComboBox.items = {}
	for i = 1, #scene.lights do
		mainWindow.toolbar.lightSelectComboBox:addItem(tostring(i))
	end
	mainWindow.toolbar.lightSelectComboBox.currentItem = #mainWindow.toolbar.lightSelectComboBox.items
end

mainWindow.toolbar:addLabel(2, elementY, elementWidth, 1, 0xEEEEEE, "Light control"):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top); elementY = elementY + 2
mainWindow.toolbar.lightSelectComboBox = mainWindow.toolbar:addComboBox(2, elementY, elementWidth, 1, 0x2D2D2D, 0xAAAAAA, 0x555555, 0x888888); elementY = elementY + mainWindow.toolbar.lightSelectComboBox.height + 1
calculateLightComboBox()


mainWindow.toolbar.addLightButton = mainWindow.toolbar:addButton(2, elementY, elementWidth, 1, 0x2D2D2D, 0xAAAAAA, 0x555555, 0xAAAAAA, "Add light"); elementY = elementY + 2
mainWindow.toolbar.addLightButton.onTouch = function()
	scene:addLight(polyCatEngine.newLight(vector.newVector3(0, 10, 0), mainWindow.toolbar.lightEmissionSlider.value))
	calculateLightComboBox()
end

mainWindow.toolbar.removeLightButton = mainWindow.toolbar:addButton(2, elementY, elementWidth, 1, 0x2D2D2D, 0xAAAAAA, 0x555555, 0xAAAAAA, "Remove light"); elementY = elementY + 2
mainWindow.toolbar.removeLightButton.onTouch = function()
	if #scene.lights > 1 then
		table.remove(scene.lights, mainWindow.toolbar.lightSelectComboBox.currentItem)
		calculateLightComboBox()
	end
end

mainWindow.toolbar.lightEmissionSlider = mainWindow.toolbar:addHorizontalSlider(2, elementY, elementWidth, 0xCCCCCC, 0x2D2D2D, 0xEEEEEE, 0xAAAAAA, 5, 500, 450, false, "Emission: ", ""); elementY = elementY + 3
mainWindow.toolbar.lightEmissionSlider.onValueChanged = function(value)
	scene.lights[mainWindow.toolbar.lightSelectComboBox.currentItem].emissionDistance = value
end

mainWindow.toolbar.blockColorSelector = mainWindow.toolbar:addColorSelector(2, elementY, elementWidth, 1, 0xEEEEEE, "Block color"); elementY = elementY + mainWindow.toolbar.blockColorSelector.height + 1
mainWindow.toolbar.backgroundColorSelector = mainWindow.toolbar:addColorSelector(2, elementY, elementWidth, 1, scene.backgroundColor, "Background color"); elementY = elementY + mainWindow.toolbar.blockColorSelector.height + 1
mainWindow.toolbar.backgroundColorSelector.onTouch = function()
	scene.backgroundColor = mainWindow.toolbar.backgroundColorSelector.color
end

mainWindow.toolbar:addLabel(2, elementY, elementWidth, 1, 0xEEEEEE, "RAM monitoring"):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top); elementY = elementY + 2
mainWindow.toolbar.RAMChart = mainWindow.toolbar:addChart(2, elementY, elementWidth, mainWindow.toolbar.height - elementY - 3, 0xEEEEEE, 0xAAAAAA, 0x555555, 0x66DB80, 0.35, 0.25, "s", "%", true, {}); elementY = elementY + mainWindow.toolbar.RAMChart.height + 1
mainWindow.toolbar.RAMChart.roundValues = true
mainWindow.toolbar.RAMChart.counter = 1
mainWindow.toolbar:addButton(1, mainWindow.toolbar.height - 2, mainWindow.toolbar.width, 3, 0xEEEEEE, 0x2D2D2D, 0xAAAAAA, 0x2D2D2D, "Exit").onTouch = function()
	mainWindow:close()
end

mainWindow.onDrawFinished = function()
	-- clock sec - 1 frame
	-- 1 sec - x frames
	renderer.renderFPSCounter(2, 2, tostring(math.ceil(1 / (os.clock() - mainWindow.oldClock) / 10)), 0xFFFF00)
end

mainWindow.onAnyEvent = function(e)
	if not mainWindow.toolbar.isHidden then
		local totalMemory = computer.totalMemory()
		table.insert(mainWindow.toolbar.RAMChart.values, {mainWindow.toolbar.RAMChart.counter, math.ceil((totalMemory - computer.freeMemory()) / totalMemory * 100)})
		mainWindow.toolbar.RAMChart.counter = mainWindow.toolbar.RAMChart.counter + 1
		if #mainWindow.toolbar.RAMChart.values > 20 then table.remove(mainWindow.toolbar.RAMChart.values, 1) end

		mainWindow.infoTextBox.lines = {
			" ",
			"SceneObjects: " .. #scene.objects,
			" ",
			"OCGLVertices: " .. #OCGL.vertices,
			"OCGLTriangles: " .. #OCGL.triangles,
			"OCGLLines: " .. #OCGL.lines,
			"OCGLFloatingTexts: " .. #OCGL.floatingTexts,
			"OCGLLights: " .. #OCGL.lights,
			" ",
			"CameraFOV: " .. string.format("%.2f", math.deg(scene.camera.FOV)),
			"СameraPosition: " .. string.format("%.2f", scene.camera.position[1]) .. " x " .. string.format("%.2f", scene.camera.position[2]) .. " x " .. string.format("%.2f", scene.camera.position[3]),
			"СameraRotation: " .. string.format("%.2f", math.deg(scene.camera.rotation[1])) .. " x " .. string.format("%.2f", math.deg(scene.camera.rotation[2])) .. " x " .. string.format("%.2f", math.deg(scene.camera.rotation[3])),
			"CameraNearClippingSurface: " .. string.format("%.2f", scene.camera.nearClippingSurface),
			"CameraFarClippingSurface: " .. string.format("%.2f", scene.camera.farClippingSurface),
			"CameraProjectionSurface: " .. string.format("%.2f", scene.camera.projectionSurface),
			"CameraPerspectiveProjection: " .. tostring(scene.camera.projectionEnabled),
			" ",
			"Controls:",
			" ",
			"Arrows - camera rotation",
			"WASD/Shift/Space - camera movement",
			"LMB/RMB - destroy/place block",
			"NUM 8/2/4/6/1/3 - selected light movement",
			"F1 - toggle GUI overlay",
		}

		mainWindow.infoTextBox.height = #mainWindow.infoTextBox.lines
	end

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
	end

	mainWindow:draw()
	buffer.draw()
end

-------------------------------------------------------- Ebat-kopat --------------------------------------------------------

mainWindow:handleEvents(0)



