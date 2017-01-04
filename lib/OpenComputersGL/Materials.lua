

local materials = {}

------------------------------------------------------------------------------------------------------------------------

materials.types = {
	textured = 1,
	solid = 2,
}

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

