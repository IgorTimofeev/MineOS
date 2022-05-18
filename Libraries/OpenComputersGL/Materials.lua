
local color = require("Color")
local materials = {}

------------------------------------------------------------------------------------------------------------------------

materials.types = {
	textured = 1,
	solid = 2,
}

function materials.newDebugTexture(width, height, h)
	local texture = {width = width, height = height}
		
	local bStep = 1 / width
	local sStep = 1 / height

	local s, b = 0, 0
	local blackSquare = false
	for y = 1, height do
		texture[y] = {}
		for x = 1, width do
			texture[y][x] = blackSquare == true and 0x0 or color.HSBToInteger(h, s, b)
			blackSquare = not blackSquare
			b = b + bStep
		end
		b = 0
		s = s + sStep
		blackSquare = not blackSquare
	end
	return texture
end

function materials.newSolidMaterial(color)
	return {
		type = materials.types.solid,
		color = color
	}
end

function materials.newTexturedMaterial(texture)
	return {
		type = materials.types.textured,
		texture = texture
	}
end

------------------------------------------------------------------------------------------------------------------------

return materials

