
local bit32 = require("bit32")
local color = {}

-----------------------------------------------------------------------------------------------------------------------

function color.HEXToRGB(HEXColor)
	return bit32.rshift(HEXColor, 16), bit32.band(bit32.rshift(HEXColor, 8), 0xFF), bit32.band(HEXColor, 0xFF)
end

function color.RGBToHEX(r, g, b)
	return bit32.lshift(r, 16) + bit32.lshift(g, 8) + b
end

function color.RGBToHSB(rr, gg, bb)
	local max = math.max(rr, math.max(gg, bb))
	local min = math.min(rr, math.min(gg, bb))
	local delta = max - min

	local h = 0
	if ( max == rr and gg >= bb) then h = 60 * (gg - bb) / delta end
	if ( max == rr and gg <= bb ) then h = 60 * (gg - bb) / delta + 360 end
	if ( max == gg ) then h = 60 * (bb - rr) / delta + 120 end
	if ( max == bb ) then h = 60 * (rr - gg) / delta + 240 end

	local s = 0
	if ( max ~= 0 ) then s = 1 - (min / max) end

	local b = max * 100 / 255

	if delta == 0 then h = 0 end

	return h, s * 100, b
end

function color.HSBToRGB(h, s, v)
	if h > 359 then h = 0 end
	local rr, gg, bb = 0, 0, 0
	local const = 255

	s = s / 100
	v = v / 100
	
	local i = math.floor(h / 60)
	local f = h / 60 - i
	
	local p = v * (1 - s)
	local q = v * (1 - s * f)
	local t = v * (1 - (1 - f) * s)

	if ( i == 0 ) then rr, gg, bb = v, t, p end
	if ( i == 1 ) then rr, gg, bb = q, v, p end
	if ( i == 2 ) then rr, gg, bb = p, v, t end
	if ( i == 3 ) then rr, gg, bb = p, q, v end
	if ( i == 4 ) then rr, gg, bb = t, p, v end
	if ( i == 5 ) then rr, gg, bb = v, p, q end

	return math.floor(rr * const), math.floor(gg * const), math.floor(bb * const)
end

function color.HEXToHSB(HEXColor)
	local rr, gg, bb = color.HEXToRGB(HEXColor)
	local h, s, b = color.RGBToHSB( rr, gg, bb )
	
	return h, s, b
end

function color.HSBToHEX(h, s, b)
	local rr, gg, bb = color.HSBToRGB(h, s, b)
	local color = color.RGBToHEX(rr, gg, bb)

	return color
end

function color.average(colors)
	local sColors, averageRed, averageGreen, averageBlue, r, g, b = #colors, 0, 0, 0

	for i = 1, sColors do
		r, g, b = color.HEXToRGB(colors[i])
		averageRed, averageGreen, averageBlue = averageRed + r, averageGreen + g, averageBlue + b
	end

	return color.RGBToHEX(math.floor(averageRed / sColors), math.floor(averageGreen / sColors), math.floor(averageBlue / sColors))
end

function color.blend(firstColor, secondColor, secondColorTransparency)
	local invertedTransparency, firstColorR, firstColorG, firstColorB = 1 - secondColorTransparency, color.HEXToRGB(firstColor)
	local secondColorR, secondColorG, secondColorB = color.HEXToRGB(secondColor)

	return color.RGBToHEX(
		secondColorR * invertedTransparency + firstColorR * secondColorTransparency,
		secondColorG * invertedTransparency + firstColorG * secondColorTransparency,
		secondColorB * invertedTransparency + firstColorB * secondColorTransparency
	)
end

-----------------------------------------------------------------------------------------------------------------------

local openComputersPalette = {}

for r = 0x0, 0xFF, 0xFF / 5 do
	for g = 0x0, 0xFF, 0xFF / 7 do
		for b = 0x0, 0xFF, 0xFF / 4 do
			table.insert(openComputersPalette, color.RGBToHEX(r, math.floor(g + 0,5), math.floor(b + 0.5)))
		end
	end
 end
 for gr = 0x1, 0x10 do
	table.insert(openComputersPalette, gr * 0xF0F0F)
 end
 table.sort(openComputersPalette)

function color.to8Bit(color24Bit)
	local closestDelta, r, g, b, closestIndex, delta, openComputersPaletteR, openComputersPaletteG, openComputersPaletteB = math.huge, color.HEXToRGB(color24Bit)

	for index = 1, #openComputersPalette do
		if color24Bit == openComputersPalette[index] then
			return index - 1
		else
			openComputersPaletteR, openComputersPaletteG, openComputersPaletteB = color.HEXToRGB(openComputersPalette[index])
			delta = (openComputersPaletteR - r) ^ 2 + (openComputersPaletteG - g) ^ 2 + (openComputersPaletteB - b) ^ 2
			
			if delta < closestDelta then
				closestDelta, closestIndex = delta, index
			end
		end
	end

	return closestIndex - 1
end

function color.to24Bit(color8Bit)
	return openComputersPalette[color8Bit + 1]
end

function color.optimize(color24Bit)
	return color.to24Bit(color.to8Bit(color24Bit))
end

-----------------------------------------------------------------------------------------------------------------------

return color



