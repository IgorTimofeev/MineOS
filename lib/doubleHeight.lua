
if not _G.buffer then _G.buffer = require("doubleBuffering") end
local doubleHeight = {}

local upperPixel = "▀"
local lowerPixel = "▄"

------------------------------------------------------------------------------------------------------------------------------------------

function doubleHeight.set(x, y, color)
	if x >= 1 and x <= buffer.screen.width and y >= 1 and y <= buffer.screen.height * 2 then
		local yFixed = math.ceil(y / 2)
		local background, foreground, symbol = buffer.get(x, yFixed)

		if y % 2 == 0 then
			if symbol == upperPixel then
				buffer.set(x, yFixed, color, foreground, upperPixel)
			else
				buffer.set(x, yFixed, background, color, lowerPixel)
			end
		else
			if symbol == lowerPixel then
				buffer.set(x, yFixed, color, foreground, lowerPixel)
			else
				buffer.set(x, yFixed, background, color, upperPixel)
			end
		end
	end
end

local function swap(a, b)
	return b, a
end

function doubleHeight.line(x0, y0, x1, y1, color)
   	local steep = false;
    
    if math.abs(x0 - x1) < math.abs(y0 - y1 ) then
        x0, y0 = swap(x0, y0)
        x1, y1 = swap(x1, y1)
        steep = true;
    end

    if (x0 > x1) then
    	x0, x1 = swap(x0, x1)
    	y0, y1 = swap(y0, y1)
    end

    local dx = x1 - x0;
    local dy = y1 - y0;
    local derror2 = math.abs(dy) * 2
    local error2 = 0;
    local y = y0;
    
    for x = x0, x1, 1 do
        if steep then
            doubleHeight.set(y, x, color);
        else
        	doubleHeight.set(x, y, color)
        end

        error2 = error2 + derror2;

        if error2 > dx then
            y = y + (y1 > y0 and 1 or -1);
            error2 = error2 - dx * 2;
        end
    end
end

------------------------------------------------------------------------------------------------------------------------------------------

return doubleHeight







