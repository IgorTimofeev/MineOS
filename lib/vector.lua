
local vectorLibrary = {}

------------------------------------------------------------------------------------------------------------------------

function vectorLibrary.newVector2(x, y)
	return { x, y }
end

function vectorLibrary.newVector3(x, y, z)
	return { x, y, z }
end

function vectorLibrary.newVector4(x, y, z, w)
	return { x, y, z, w }
end

function vectorLibrary.newVector5(x, y, z, u, v)
	return { x, y, z, u, v }
end

------------------------------------------------------------------------------------------------------------------------

function vectorLibrary.scalarMultiply(vectorA, vectorB)
	local result = 0
	for dismension = 1, #vectorA do
		result = result + vectorA[dismension] * vectorB[dismension]
	end

	return result
end

function vectorLibrary.length(vector)
	local result = 0
	for dismension = 1, #vector do
		result = result + vector[dismension] ^ 2
	end

	return math.sqrt(result)
end

function vectorLibrary.normalize(vector)
	local invertedLength = 1 / vectorLibrary.length(vector)
	vector[1], vector[2], vector[3] = vector[1] * invertedLength, vector[2] * invertedLength, vector[3] * invertedLength

	return vector
end

function vectorLibrary.getSurfaceNormal(vector1, vector2, vector3)
	return {
		vector1[2] * (vector2[3] - vector3[3]) + vector2[2] * (vector3[3] - vector1[3]) + vector3[2] * (vector1[3] - vector2[3]),
		vector1[3] * (vector2[1] - vector3[1]) + vector2[3] * (vector3[1] - vector1[1]) + vector3[3] * (vector1[1] - vector2[1]),
		vector1[1] * (vector2[2] - vector3[2]) + vector2[1] * (vector3[2] - vector1[2]) + vector3[1] * (vector1[2] - vector2[2])
	}
end

function vectorLibrary.toString(vector)
	local result = "("
	for dismension = 1, #vector do
		result = result .. string.format("%.2f", vector[dismension])
		if dismension < #vector then
			result = result .. "; "
		end
	end
	return result .. ")"
end

------------------------------------------------------------------------------------------------------------------------

return vectorLibrary

