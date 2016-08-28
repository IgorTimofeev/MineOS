
if not _G.buffer then _G.buffer = require("doubleBuffering") end
local doubleHeight = {}

------------------------------------------------------------------------------------------------------------------------------------------

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
			buffer.semiPixelSet(y, x, color);
		else
			buffer.semiPixelSet(x, y, color)
		end

		error2 = error2 + derror2;

		if error2 > dx then
			y = y + (y1 > y0 and 1 or -1);
			error2 = error2 - dx * 2;
		end
	end
end

------------------------------------------------------------------------------------------------------------------------------------------

-- buffer.clear(0x262626); buffer.draw(true)
-- doubleHeight.square(3, 3, 20, 20, 0xFF8888)    
-- buffer.draw()

------------------------------------------------------------------------------------------------------------------------------------------

return doubleHeight







