
-------------------------------------------------------- Libraries --------------------------------------------------------

package.loaded.matrix, package.loaded.doubleBuffering, package.loaded.OpenComputersGL = nil, nil, nil
_G.OCGL, _G.buffer, _G.matrix = nil, nil, nil

local buffer = require("doubleBuffering")
local OCGL = require("OpenComputersGL")
local event = require("event")

-------------------------------------------------------- Playground --------------------------------------------------------

buffer.start()

local scene = OCGL.newScene()
OCGL.addAxisLinesToScene(scene, 100)
local cube = OCGL.newCube(OCGL.newVector3(-10, 0, -10), 20)
scene:addObject(cube)
scene:addObject(OCGL.newPlane(OCGL.newVector3(-30, 0, -30), 60, 60))

local autoRotate, showGrid = false, true

local controls = {
	-- Arrows
	[200] = function() scene:rotateAroundAxis(OCGL.axis.x, -0.1) end,
	[208] = function() scene:rotateAroundAxis(OCGL.axis.x, 0.1) end,
	[203] = function() scene:rotateAroundAxis(OCGL.axis.y, -0.1) end,
	[205] = function() scene:rotateAroundAxis(OCGL.axis.y, 0.1) end,

	-- +-
	[13 ] = function() cube:rotateAroundPoint(cube.verticesMatrix[1], OCGL.axis.y, 0.1) end,
	[12 ] = function() cube:rotateAroundPoint(cube.verticesMatrix[1], OCGL.axis.y, -0.1) end,

	-- WASD
	[17 ] = function() scene:translate(0, 2, 0) end,
	[31 ] = function() scene:translate(0, -2, 0) end,
	[30 ] = function() scene:translate(2, 0, 0) end,
	[32 ] = function() scene:translate(-2, 0, 0) end,

	-- R, Enter
	[18 ] = function() scene:rotateAroundAxis(OCGL.axis.x, -0.1) end,
	[28 ] = function() autoRotate = not autoRotate end,
}

while true do
	local e = {event.pull(0)}
	local currentClock = os.clock()

	if e[1] == "key_down" then
		if controls[e[4]] then controls[e[4]]() end
	elseif e[1] == "scroll" then
		if e[5] == 1 then
			scene:scale(2, 2, 2)
		else
			scene:scale(0.5, 0.5, 0.5)
		end
	end

	if autoRotate then
		local speed = 0.05
		-- scene:rotateAroundAxis(OCGL.axis.x, speed)
		scene:rotateAroundAxis(OCGL.axis.y, speed)
		-- scene:rotateAroundAxis(OCGL.axis.z, speed)
	end

	buffer.clear(0x0)
	
	scene:render(OCGL.renderModes.wireframe)
	buffer.text(1, 1, 0xFFFFFF, "Free RAM: " .. math.floor(computer.freeMemory() / 1024))
	local timePerFrame = os.clock() - currentClock
	-- 1 - timePerFrame
	-- x - 1
	buffer.text(1, 2, 0xFFFFFF, "Frame render time: " .. timePerFrame)
	
	buffer.draw()
end

