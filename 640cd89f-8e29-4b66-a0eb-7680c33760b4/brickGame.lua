local buffer = require("doubleBuffering")
local color = require("color")
local GUI = dofile("/lib/GUI.lua")

local brickGame = {}

------------------------------------------------------------------------------------------

local function brickGameDraw(object)
	buffer.square(object.x + 1, object.y, object.width - 2, 1, object.colors.shade)
	buffer.square(object.x, object.y + 1, object.width, , object.colors.shade)

end

function brickGame.new(x, y, width, height, caseColor, screenColor, screenPixelColor)
	local object = GUI.object(x, y, width, height)
	object.colors = {
		case = caseColor,
		screen = screenColor,
		pixel = screenPixelColor,
	}
	
	object.screen = {}
	for j = 1, #object.screen do
		object.screen[j] = {}
		for i = 1, #object.screen[j] do
			object.screen[j][i] = false
		end
	end
	object.draw = brickGameDraw

	return object
end


------------------------------------------------------------------------------------------

return brickGame
