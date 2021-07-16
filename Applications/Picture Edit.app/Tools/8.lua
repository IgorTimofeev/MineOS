
local image = require("Image")

------------------------------------------------------

local workspace, window, menu = select(1, ...), select(2, ...), select(3, ...)
local tool = {}
local locale = select(4, ...)

tool.shortcut = "Fil"
tool.keyCode = 34
tool.about = locale.tool8

local function check(x, y, picture, sourceB, sourceF, sourceA, sourceS, newB, newF, newA, newS)
	if x >= 1 and x <= picture[1] and y >= 1 and y <= picture[2] then
		local currentB, currentF, currentA, currentS = image.get(picture, x, y)
		if
			currentB == sourceB
			and
			currentB ~= newB
		then
			image.set(picture, x, y, newB, newF, newA, newS)
			return true
		end
	end
end

local function pizda(x, y, picture, sourceB, sourceF, sourceA, sourceS, newB, newF, newA, newS)
	if check(x, y - 1, picture, sourceB, sourceF, sourceA, sourceS, newB, newF, newA, newS) then pizda(x, y - 1, picture, sourceB, sourceF, sourceA, sourceS, newB, newF, newA, newS) end
	if check(x + 1, y, picture, sourceB, sourceF, sourceA, sourceS, newB, newF, newA, newS) then pizda(x + 1, y, picture, sourceB, sourceF, sourceA, sourceS, newB, newF, newA, newS) end
	if check(x, y + 1, picture, sourceB, sourceF, sourceA, sourceS, newB, newF, newA, newS) then pizda(x, y + 1, picture, sourceB, sourceF, sourceA, sourceS, newB, newF, newA, newS) end
	if check(x - 1, y, picture, sourceB, sourceF, sourceA, sourceS, newB, newF, newA, newS) then pizda(x - 1, y, picture, sourceB, sourceF, sourceA, sourceS, newB, newF, newA, newS) end
end

tool.eventHandler = function(workspace, object, e1, e2, e3, e4)
	if e1 == "touch" then
		local x, y = e3 - window.image.x + 1, e4 - window.image.y + 1
		local sourceB, sourceF, sourceA, sourceS = image.get(window.image.data, x, y)
		pizda(x, y, window.image.data, sourceB, sourceF, sourceA, sourceS, window.primaryColorSelector.color, 0x0, 0, " ")
		
		workspace:draw()
	end
end

------------------------------------------------------

return tool
