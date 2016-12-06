
-------------------------------------------------------- Libraries --------------------------------------------------------

package.loaded.matrix, package.loaded.doubleBuffering, package.loaded.OpenComputersGL = nil, nil, nil
_G.OCGL, _G.buffer, _G.matrix = nil, nil, nil

local buffer = require("doubleBuffering")
local OCGL = require("OpenComputersGL")
local event = require("event")

-------------------------------------------------------- Constants --------------------------------------------------------

local autoRotate, showGrid, renderMode = false, true, OCGL.renderModes.wireframe
local translationOffset = 2
local rotationAngle = 0.05

local axisXTranslationVector1 = OCGL.newVector3(translationOffset, 0, 0)
local axisXTranslationVector2 = OCGL.newVector3(-translationOffset, 0, 0)
local axisYTranslationVector1 = OCGL.newVector3(0, translationOffset, 0)
local axisYTranslationVector2 = OCGL.newVector3(0, -translationOffset, 0)

local axisXrotationMatrix1 = OCGL.newRotationMatrix(OCGL.axis.x, rotationAngle)
local axisXrotationMatrix2 = OCGL.newRotationMatrix(OCGL.axis.x, -rotationAngle)
local axisYrotationMatrix1 = OCGL.newRotationMatrix(OCGL.axis.y, rotationAngle)
local axisYrotationMatrix2 = OCGL.newRotationMatrix(OCGL.axis.y, -rotationAngle)

-------------------------------------------------------- Object group --------------------------------------------------------

local objectGroup = OCGL.newObjectGroup(OCGL.newVector3(0, 0, 0))
objectGroup:addObjects(OCGL.newGridLines(
	OCGL.newVector3(0, 0, 0),
	50,
	10
))
local cube = objectGroup:addObject(OCGL.newCube(
	OCGL.newVector3(0, 10, 0),
	20
))
cube.showPivotPoint = true
-- objectGroup:addObject(OCGL.newPlane(
-- 	OCGL.newVector3(0, 0, 0),
-- 	60,
-- 	60
-- ))

local controls = {
	-- Arrows
	[200] = function() objectGroup:rotate(axisXrotationMatrix1) end,
	[208] = function() objectGroup:rotate(axisXrotationMatrix2) end,
	[203] = function() objectGroup:rotate(axisYrotationMatrix1) end,
	[205] = function() objectGroup:rotate(axisYrotationMatrix2) end,
	-- +-
	[13 ] = function() cube:rotate(axisXrotationMatrix1) end,
	[12 ] = function() cube:rotate(axisYrotationMatrix1) end,
	-- G, X
	[34 ] = function() objectGroup.showGrid = not objectGroup.showGrid end,
	[45 ] = function() renderMode = renderMode == OCGL.renderModes.wireframe and OCGL.renderModes.dots or OCGL.renderModes.wireframe end,
	-- WASD
	[17 ] = function() objectGroup:translate(axisYTranslationVector1) end,
	[31 ] = function() objectGroup:translate(axisYTranslationVector2) end,
	[30 ] = function() objectGroup:translate(axisXTranslationVector1) end,
	[32 ] = function() objectGroup:translate(axisXTranslationVector2) end,
	-- R, Enter
	[19 ] = function() autoRotate = not autoRotate end,
	[28 ] = function() os.exit() end,
}

-------------------------------------------------------- Main shit --------------------------------------------------------

buffer.start()

while true do
	local e = {event.pull(0)}
	local currentClock = os.clock()

	if e[1] == "key_down" then
		if controls[e[4]] then controls[e[4]]() end
	elseif e[1] == "scroll" then
		if e[5] == 1 then
			objectGroup:scale(OCGL.newScaleMatrix(OCGL.newVector3(1.2, 1.2, 1.2)))
		else
			objectGroup:scale(OCGL.newScaleMatrix(OCGL.newVector3(0.8, 0.8, 0.8)))
		end
	end

	if autoRotate then
		-- objectGroup:rotate(axisXrotationMatrix1)
		objectGroup:rotate(axisYrotationMatrix1)
	end

	buffer.clear(0x1B1B1B)
	
	objectGroup:render(renderMode)

	buffer.text(1, 1, 0xFFFFFF, "RAM: " .. math.floor(computer.freeMemory() / 1024))
	buffer.text(1, 2, 0xFFFFFF, "FPS: " .. math.floor(0.1 / (os.clock() - currentClock)))
	
	buffer.draw()
end

