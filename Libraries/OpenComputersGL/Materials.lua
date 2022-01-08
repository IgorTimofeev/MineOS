
local color = require("Color")
local materials = {}

------------------------------------------------------------------------------------------------------------------------

materials.types = {
	textured = 1,
	solid = 2,
}

function materials.newDebugTexture(width, height, h)
	local texture = {width = width, height = height}
	
	for y = 1, height do
		texture[y] = {}
		for x = 1, width do
			texture[y][x] = not (x+y)%2 and 0x0 or color.HSBToInteger(h, y/height, x/width)
		end
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

