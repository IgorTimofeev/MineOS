
-------------------------------------------------------- Libraries --------------------------------------------------------

package.loaded["GUI"] = nil
package.loaded["doubleBuffering"] = nil
package.loaded["vector"] = nil
package.loaded["matrix"] = nil
package.loaded["OpenComputersGL/Main"] = nil
package.loaded["OpenComputersGL/Materials"] = nil
package.loaded["OpenComputersGL/Renderer"] = nil
package.loaded["WildCatEngine/Main"] = nil
package.loaded["WildCatEngine/PostProcessing"] = nil

local buffer = require("doubleBuffering")
local event = require("event")
local GUI = require("GUI")
local vector = require("vector")
local matrix = require("matrix")
local materials = require("OpenComputersGL/Materials")
local renderer = require("OpenComputersGL/Renderer")
local OCGL = require("OpenComputersGL/Main")
local wildCatEngine = require("WildCatEngine/Main")

-------------------------------------------------------- Constants --------------------------------------------------------

local autoRotate, showGrid, renderMode = false, true, renderer.renderModes.material 
local rotationAngle = math.rad(5)
local translationOffset = 2
local backgroundColor = 0x222222

-------------------------------------------------------- Object group --------------------------------------------------------

local scene = wildCatEngine.newScene(vector.newVector3(0, 0, 0))
-- scene:addObjects(wildCatEngine.newGridLines(
-- 	vector.newVector3(0, 0, 0),
-- 	50,
-- 	40,
-- 	8
-- ))
-- scene:addObject(wildCatEngine.newPlane(
-- 	vector.newVector3(0, 0, 0),
-- 	60,
-- 	60,
-- 	materials.newSolidMaterial(0xEEEEEE)
-- ))


local spaceBetween = 5
local cubeSize = 20
local xCube, zCube = -cubeSize - spaceBetween, -cubeSize - spaceBetween
for j = 1, 3 do
	for i = 1, 3 do
		if not (i == 2 and j == 2) then
			scene:addObject(wildCatEngine.newCube(
				vector.newVector3(xCube, 0, zCube),
				cubeSize,
				materials.newSolidMaterial(math.random(0x0, 0xFFFFFF))
			))
		end
		xCube = xCube + cubeSize + spaceBetween
	end
	zCube, xCube = zCube + cubeSize + spaceBetween, -cubeSize - spaceBetween
end





local function move(x, y, z)
	local moveMatrix = {{-x, -y, -z}}
	moveMatrix = matrix.multiply(moveMatrix, scene.camera.rotationMatrix)[1]
	scene.camera:translate(moveMatrix[1], moveMatrix[2], moveMatrix[3])

	-- scene.camera:translate(x, y, z)
end

local controls = {
	-- Arrows
	[200] = function() scene.camera:rotate(rotationAngle, 0, 0) end,
	[208] = function() scene.camera:rotate(-rotationAngle, 0, 0) end,
	[203] = function() scene.camera:rotate(0, rotationAngle, 0) end,
	[205] = function() scene.camera:rotate(0, -rotationAngle, 0) end,
	[16 ] = function() scene.camera:rotate(0, 0, rotationAngle) end,
	[18 ] = function() scene.camera:rotate(0, 0, -rotationAngle) end,

	-- +-
	[13 ] = function()  end,
	[12 ] = function()  end,
	-- G, X
	[34 ] = function() scene.showGrid = not scene.showGrid end,
	[45 ] = function() renderMode = renderMode + 1; if renderMode > 3 then renderMode = 1 end end,
	-- WASD
	[17 ] = function() move(0, 0, 2) end,
	[31 ] = function() move(0, 0, -2) end,
	[30 ] = function() move(2, 0, 0) end,
	[32 ] = function() move(-2, 0, 0) end,
	--RSHIFT, SPACE
	[42 ] = function() move(0, 2, 0) end,
	[57 ] = function() move(0, -2, 0) end,
	-- Backspace, R, Enter
	[14 ] = function() os.exit() end,
	[19 ] = function() autoRotate = not autoRotate end,
	[28 ] = function() scene.camera.projectionEnabled = not scene.camera.projectionEnabled end,
}

-------------------------------------------------------- Main shit --------------------------------------------------------

buffer.start()
local progressBar = GUI.progressBar(buffer.screen.width - 32, 2, 30, 0xFFFF00, 0xFFFFFF, 0xFFFFFF, 1, true, true, "RAM usage: ", "%")

local function renderMethod()
	scene:render(0x0, renderMode)

	local total = computer.totalMemory()
	progressBar.value = math.ceil((total - computer.freeMemory()) / total * 100)
	progressBar:draw()
	buffer.text(2, 10, 0xFFFFFF, "RenderMode: " .. renderMode)
	buffer.text(2, 12, 0xFFFFFF, "СameraPosition: " .. string.format("%.2f", scene.camera.position[1]) .. " x " .. string.format("%.2f", scene.camera.position[2]) .. " x " .. string.format("%.2f", scene.camera.position[3]))
end

while true do
	local e = {event.pull(0)}

	if e[1] == "key_down" then
		if controls[e[4]] then controls[e[4]]() end
	elseif e[1] == "touch" then
		local mesh, triangleIndex = OCGL.triangleRaycast(
			vector.newVector3(e[3], e[4] * 2, -1000),
			vector.newVector3(e[3], e[4] * 2, 1000)
		)
		if mesh then 	
			ecs.error("ТЫКНУЛОСЬ СУКА")		
			-- Правый клик
			if e[5] == 1 then
				-- local currentCube = scene.objects[objectIndex]
				-- local newPosition = vector.newVector3(currentCube.pivotPoint.position[1], currentCube.pivotPoint.position[2] + 20, currentCube.pivotPoint.position[3])

				-- scene:addObject(wildCatEngine.newCube(
				-- 	newPosition,
				-- 	20,
				-- 	materials.newSolidMaterial(math.random(0x0, 0xFFFFFF))
				-- ))
			else
				-- table.remove(scene.objects, objectIndex)
			end
		end
	-- elseif e[1] == "scroll" then
	-- 	if e[5] == 1 then
	-- 		scene:scale(OCGL.newScaleMatrix(vector.newVector3(1.2, 1.2, 1.2)))
	-- 	else
	-- 		scene:scale(OCGL.newScaleMatrix(vector.newVector3(0.8, 0.8, 0.8)))
	-- 	end
	end

	if autoRotate then
		scene.camera:rotate(0, rotationAngle, 0)
	end

	renderer.renderFPSCounter(2, 2, renderMethod, 0xFFFF00)
	buffer.draw()
end

