
local unicode = require("unicode")
-----------------------------------------------------------------------------------------------------------------------------

local function getBrailleChar(a, b, c, d, e, f, g, h)
	return unicode.char(10240 + 128*h + 64*g + 32*f + 16*d + 8*b + 4*e + 2*c + a)
end

table.toFile("braillePixels.lua",
	{
		getBrailleChar(
			0, 0,
			0, 0,
			0, 0,
			1, 1
		),
		getBrailleChar(
			1, 1,
			0, 0,
			0, 0,
			0, 0
		),
		getBrailleChar(
			1, 0,
			1, 0,
			1, 0,
			1, 0
		),
		getBrailleChar(
			0, 1,
			0, 1,
			0, 1,
			0, 1
		)
	}
)

-----------------------------------------------------------------------------------------------------------------------------

return brailleRenderer











