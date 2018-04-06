
local bit32 = require("bit32")
local computer = require("computer")

local color = {}
local bit32Lshift, bit32Rshift, bit32Band, bit32Bor, mathFloor, mathMax, mathMin, mathHuge, mathModf = bit32.lshift, bit32.rshift, bit32.band, bit32.bor, math.floor, math.max, math.min, math.huge, math.modf

-----------------------------------------------------------------------------------------------------------------------

-- Optimized Lua 5.3 bitwise support
local IntegerToRGB, RGBToInteger
if computer.getArchitecture and computer.getArchitecture() == "Lua 5.3" then
	IntegerToRGB = load([[
		return function(IntegerColor)
			return IntegerColor >> 16, IntegerColor >> 8 & 0xFF, IntegerColor & 0xFF
		end
	]])()

	RGBToInteger = load([[
		return function(r, g, b)
			return r << 16 | g << 8 | b
		end
	]])()
else
	IntegerToRGB = function(IntegerColor)
		local r = mathFloor(IntegerColor / 0x10000)
		local g = mathFloor((IntegerColor - r * 0x10000) / 0x100)
		return r, g, IntegerColor - r * 0x10000 - g * 0x100
	end

	RGBToInteger = function(r, g, b)
		return r * 65536 + g * 256 + b
	end
end

-----------------------------------------------------------------------------------------------------------------------

local function RGBToHSB(r, g, b)
	local max, min = mathMax(r, g, b), mathMin(r, g, b)

	if max == min then
		return 0, max == 0 and 0 or (1 - min / max), max / 255
	elseif max == r and g >= b then
		return 60 * (g - b) / (max - min), max == 0 and 0 or (1 - min / max), max / 255
	elseif max == r and g < b then
		return 60 * (g - b) / (max - min) + 360, max == 0 and 0 or (1 - min / max), max / 255
	elseif max == g then
		return 60 * (b - r) / (max - min) + 120, max == 0 and 0 or (1 - min / max), max / 255
	elseif max == b then
		return 60 * (r - g) / (max - min) + 240, max == 0 and 0 or (1 - min / max), max / 255
	else
		return 0, max == 0 and 0 or (1 - min / max), max / 255
	end
end

local function HSBToRGB(h, s, b)
	local integer, fractional = mathModf(h / 60)	
	local p, q, t = b * (1 - s), b * (1 - s * fractional), b * (1 - (1 - fractional) * s)

	if integer == 0 then
		return mathFloor(b * 255), mathFloor(t * 255), mathFloor(p * 255)
	elseif integer == 1 then
		return mathFloor(q * 255), mathFloor(b * 255), mathFloor(p * 255)
	elseif integer == 2 then
		return mathFloor(p * 255), mathFloor(b * 255), mathFloor(t * 255)
	elseif integer == 3 then
		return mathFloor(p * 255), mathFloor(q * 255), mathFloor(b * 255)
	elseif integer == 4 then
		return mathFloor(t * 255), mathFloor(p * 255), mathFloor(b * 255)
	else
		return mathFloor(b * 255), mathFloor(p * 255), mathFloor(q * 255)
	end
end

local function IntegerToHSB(IntegerColor)
	return RGBToHSB(IntegerToRGB(IntegerColor))
end

local function HSBToInteger(h, s, b)
	return RGBToInteger(HSBToRGB(h, s, b))
end

-----------------------------------------------------------------------------------------------------------------------

local function blend(firstColor, secondColor, secondColorTransparency)
	local invertedTransparency, r1, g1, b1 = 1 - secondColorTransparency, IntegerToRGB(firstColor)
	local r2, g2, b2 = IntegerToRGB(secondColor)

	return RGBToInteger(
		mathFloor(r2 * invertedTransparency + r1 * secondColorTransparency),
		mathFloor(g2 * invertedTransparency + g1 * secondColorTransparency),
		mathFloor(b2 * invertedTransparency + b1 * secondColorTransparency)
	)
end

-----------------------------------------------------------------------------------------------------------------------

local function transition(color1, color2, position)
	local r1, g1, b1 = IntegerToRGB(color1)
	local r2, g2, b2 = IntegerToRGB(color2)

	return RGBToInteger(
		mathFloor(r1 + (r2 - r1) * position),
		mathFloor(g1 + (g2 - g1) * position),
		mathFloor(b1 + (b2 - b1) * position)
	)
end

local function average(colors)
	local sColors, averageRed, averageGreen, averageBlue, r, g, b = #colors, 0, 0, 0

	for i = 1, sColors do
		r, g, b = IntegerToRGB(colors[i])
		averageRed, averageGreen, averageBlue = averageRed + r, averageGreen + g, averageBlue + b
	end

	return RGBToInteger(mathFloor(averageRed / sColors), mathFloor(averageGreen / sColors), mathFloor(averageBlue / sColors))
end

-----------------------------------------------------------------------------------------------------------------------

local openComputersPalette = { 0x000000, 0x000040, 0x000080, 0x0000BF, 0x0000FF, 0x002400, 0x002440, 0x002480, 0x0024BF, 0x0024FF, 0x004900, 0x004940, 0x004980, 0x0049BF, 0x0049FF, 0x006D00, 0x006D40, 0x006D80, 0x006DBF, 0x006DFF, 0x009200, 0x009240, 0x009280, 0x0092BF, 0x0092FF, 0x00B600, 0x00B640, 0x00B680, 0x00B6BF, 0x00B6FF, 0x00DB00, 0x00DB40, 0x00DB80, 0x00DBBF, 0x00DBFF, 0x00FF00, 0x00FF40, 0x00FF80, 0x00FFBF, 0x00FFFF, 0x0F0F0F, 0x1E1E1E, 0x2D2D2D, 0x330000, 0x330040, 0x330080, 0x3300BF, 0x3300FF, 0x332400, 0x332440, 0x332480, 0x3324BF, 0x3324FF, 0x334900, 0x334940, 0x334980, 0x3349BF, 0x3349FF, 0x336D00, 0x336D40, 0x336D80, 0x336DBF, 0x336DFF, 0x339200, 0x339240, 0x339280, 0x3392BF, 0x3392FF, 0x33B600, 0x33B640, 0x33B680, 0x33B6BF, 0x33B6FF, 0x33DB00, 0x33DB40, 0x33DB80, 0x33DBBF, 0x33DBFF, 0x33FF00, 0x33FF40, 0x33FF80, 0x33FFBF, 0x33FFFF, 0x3C3C3C, 0x4B4B4B, 0x5A5A5A, 0x660000, 0x660040, 0x660080, 0x6600BF, 0x6600FF, 0x662400, 0x662440, 0x662480, 0x6624BF, 0x6624FF, 0x664900, 0x664940, 0x664980, 0x6649BF, 0x6649FF, 0x666D00, 0x666D40, 0x666D80, 0x666DBF, 0x666DFF, 0x669200, 0x669240, 0x669280, 0x6692BF, 0x6692FF, 0x66B600, 0x66B640, 0x66B680, 0x66B6BF, 0x66B6FF, 0x66DB00, 0x66DB40, 0x66DB80, 0x66DBBF, 0x66DBFF, 0x66FF00, 0x66FF40, 0x66FF80, 0x66FFBF, 0x66FFFF, 0x696969, 0x787878, 0x878787, 0x969696, 0x990000, 0x990040, 0x990080, 0x9900BF, 0x9900FF, 0x992400, 0x992440, 0x992480, 0x9924BF, 0x9924FF, 0x994900, 0x994940, 0x994980, 0x9949BF, 0x9949FF, 0x996D00, 0x996D40, 0x996D80, 0x996DBF, 0x996DFF, 0x999200, 0x999240, 0x999280, 0x9992BF, 0x9992FF, 0x99B600, 0x99B640, 0x99B680, 0x99B6BF, 0x99B6FF, 0x99DB00, 0x99DB40, 0x99DB80, 0x99DBBF, 0x99DBFF, 0x99FF00, 0x99FF40, 0x99FF80, 0x99FFBF, 0x99FFFF, 0xA5A5A5, 0xB4B4B4, 0xC3C3C3, 0xCC0000, 0xCC0040, 0xCC0080, 0xCC00BF, 0xCC00FF, 0xCC2400, 0xCC2440, 0xCC2480, 0xCC24BF, 0xCC24FF, 0xCC4900, 0xCC4940, 0xCC4980, 0xCC49BF, 0xCC49FF, 0xCC6D00, 0xCC6D40, 0xCC6D80, 0xCC6DBF, 0xCC6DFF, 0xCC9200, 0xCC9240, 0xCC9280, 0xCC92BF, 0xCC92FF, 0xCCB600, 0xCCB640, 0xCCB680, 0xCCB6BF, 0xCCB6FF, 0xCCDB00, 0xCCDB40, 0xCCDB80, 0xCCDBBF, 0xCCDBFF, 0xCCFF00, 0xCCFF40, 0xCCFF80, 0xCCFFBF, 0xCCFFFF, 0xD2D2D2, 0xE1E1E1, 0xF0F0F0, 0xFF0000, 0xFF0040, 0xFF0080, 0xFF00BF, 0xFF00FF, 0xFF2400, 0xFF2440, 0xFF2480, 0xFF24BF, 0xFF24FF, 0xFF4900, 0xFF4940, 0xFF4980, 0xFF49BF, 0xFF49FF, 0xFF6D00, 0xFF6D40, 0xFF6D80, 0xFF6DBF, 0xFF6DFF, 0xFF9200, 0xFF9240, 0xFF9280, 0xFF92BF, 0xFF92FF, 0xFFB600, 0xFFB640, 0xFFB680, 0xFFB6BF, 0xFFB6FF, 0xFFDB00, 0xFFDB40, 0xFFDB80, 0xFFDBBF, 0xFFDBFF, 0xFFFF00, 0xFFFF40, 0xFFFF80, 0xFFFFBF, 0xFFFFFF }

local function to8Bit(color24Bit)
	local closestDelta, r, g, b, closestIndex, delta, openComputersPaletteR, openComputersPaletteG, openComputersPaletteB = mathHuge, IntegerToRGB(color24Bit)

	for index = 1, #openComputersPalette do
		if color24Bit == openComputersPalette[index] then
			return index - 1
		else
			openComputersPaletteR, openComputersPaletteG, openComputersPaletteB = IntegerToRGB(openComputersPalette[index])
			delta = (openComputersPaletteR - r) ^ 2 + (openComputersPaletteG - g) ^ 2 + (openComputersPaletteB - b) ^ 2
			
			if delta < closestDelta then
				closestDelta, closestIndex = delta, index
			end
		end
	end

	return closestIndex - 1
end

local function to24Bit(color8Bit)
	return openComputersPalette[color8Bit + 1]
end

local function optimize(color24Bit)
	return to24Bit(to8Bit(color24Bit))
end

-----------------------------------------------------------------------------------------------------------------------

return {
	RGBToInteger = RGBToInteger,
	IntegerToRGB = IntegerToRGB,
	RGBToHSB = RGBToHSB,
	HSBToRGB = HSBToRGB,
	IntegerToHSB = IntegerToHSB,
	HSBToInteger = HSBToInteger,
	blend = blend,

	transition = transition,

	to8Bit = to8Bit,
	to24Bit = to24Bit,
	optimize = optimize,
}



