
-------------------------------------------------------- Libraries --------------------------------------------------------

package.loaded.matrix, package.loaded.doubleBuffering, package.loaded.OpenComputersGL, package.loaded.GUI = nil, nil, nil, nil
_G.OCGL, _G.buffer, _G.matrix, _G.GUI = nil, nil, nil, nil

_G.buffer = require("doubleBuffering")
_G.GUI = require("GUI")
_G.OCGL = require("OpenComputersGL")
_G.event = require("event")

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
	100,
	20
))
objectGroup:addObject(OCGL.newPlane(
	OCGL.newVector3(0, 0, 0),
	60,
	60,
	OCGL.newSolidMaterial(0xEEEEEE)
))
local cube = objectGroup:addObject(OCGL.newCube(
	OCGL.newVector3(0, 10, 0),
	20,
	OCGL.newSolidMaterial(0xBBBBBB)
))
-- cube.showPivotPoint = true

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
	[45 ] = function() renderMode = renderMode + 1; if renderMode > 3 then renderMode = 1 end end,
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
local progressBar = GUI.progressBar(buffer.screen.width - 32, 2, 30, 0xFFFF00, 0xFFFFFF, 0xFFFFFF, 1, true, true, "RAM usage: ", "%")

local function renderMethod()
	buffer.clear(0x1B1B1B)
	objectGroup:render(renderMode)
	local total = computer.totalMemory()
	progressBar.value = math.ceil((total - computer.freeMemory()) / total * 100)
	progressBar:draw()
end

while true do
	local e = {event.pull(0)}

	if e[1] == "key_down" then
		if controls[e[4]] then controls[e[4]]() end
	elseif e[1] == "touch" then
		local b, f, s = buffer.get(e[3], e[4])
		ecs.error("ВОТ ЧЕ В БУФЕРЕ: " .. b .. ", " .. f .. ", " .. s)
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

	OCGL.renderFPSCounter(2, 2, renderMethod, 0xFFFF00)
	buffer.text(2, 10, 0xFFFFFF, "RenderMode: " .. renderMode)
	buffer.draw()
end

