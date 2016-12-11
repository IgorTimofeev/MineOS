

if not _G.buffer then _G.buffer = require("doubleBuffering") end
local OCGLTR = {}

------------------------------------------------------------------------------------------------------------------------

local function fillPart(x1Screen, x2Screen, y, color)
	local x1ScreenSorted, x2ScreenSorted = x1Screen, x2Screen
	if x2ScreenSorted < x1ScreenSorted then x1ScreenSorted, x2ScreenSorted = swap(x1ScreenSorted, x2ScreenSorted) end
	buffer.semiPixelSquare(math.floor(x1ScreenSorted), y, math.floor(x2ScreenSorted - x1ScreenSorted + 1), 1, color)
end

function OCGLTR.renderFilledTriangle(points, color)
	local topID, centerID, bottomID = 1, 1, 1
	for i = 1, 3 do
		if points[i][2] < points[topID][2] then topID = i end
		if points[i][2] > points[bottomID][2] then bottomID = i end
	end
	for i = 1, 3 do if i ~= topID and i ~= bottomID then centerID = i end end

	local x1ScreenStep = (points[centerID][1] - points[topID][1]) / (points[centerID][2] - points[topID][2])
	local x2ScreenStep = (points[bottomID][1] - points[topID][1]) / (points[bottomID][2] - points[topID][2])
	local x1Screen, x2Screen = points[topID][1], points[topID][1]

	-- Рисуем первый кусок треугольника от верхней точки до центральной
	for y = points[topID][2], points[centerID][2] - 1 do
		fillPart(x1Screen, x2Screen, y, color)
		x1Screen, x2Screen = x1Screen + x1ScreenStep, x2Screen + x2ScreenStep
	end

	-- Далее считаем, как будет изменяться X от центрельной точки до нижней
	x1Screen, x1ScreenStep = points[centerID][1], (points[bottomID][1] - points[centerID][1]) / (points[bottomID][2] - points[centerID][2])
	-- И рисуем нижний кусок треугольника от центральной точки до нижней
	for y = points[centerID][2], points[bottomID][2] do
		fillPart(x1Screen, x2Screen, y, color)
		x1Screen, x2Screen = x1Screen + x1ScreenStep, x2Screen + x2ScreenStep
	end
end

function OCGLTR.renderTexturedTriangle(vertices, texture)

end

------------------------------------------------------------------------------------------------------------------------

-- buffer.clear(0x0)
-- for i = 1, 10 do
-- 	OCGLTR.renderFilledTriangle(
-- 		{
-- 			-- { i + 40, i + 40 },
-- 			-- { i + 3, i + 3 },
-- 			-- { i + 30, i + 60 },
-- 			{math.random(1, buffer.screen.width), math.random(1, buffer.screen.height * 2)},
-- 			{math.random(1, buffer.screen.width), math.random(1, buffer.screen.height * 2)},
-- 			{math.random(1, buffer.screen.width), math.random(1, buffer.screen.height * 2)},
-- 		},
-- 		math.random(0x0, 0xFFFFFF)
-- 	)
-- end
-- buffer.draw(true)
-- while true do ecs.error(event.pull("touch")) end

------------------------------------------------------------------------------------------------------------------------

return OCGLTR






