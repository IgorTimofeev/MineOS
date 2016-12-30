
local vectorLibrary = {}

------------------------------------------------------------------------------------------------------------------------

function vectorLibrary.newVector2(x, y)
	-- checkArg(1, x, "number")
	-- checkArg(2, y, "number")
	return { x, y }
end

function vectorLibrary.newVector3(x, y, z)
	-- checkArg(1, x, "number")
	-- checkArg(2, y, "number")
	-- checkArg(3, z, "number")
	return { x, y, z }
end

function vectorLibrary.newVector4(x, y, z, w)
	-- checkArg(1, x, "number")
	-- checkArg(2, y, "number")
	-- checkArg(3, z, "number")
	-- checkArg(4, w, "number")
	return { x, y, z, w }
end

------------------------------------------------------------------------------------------------------------------------

return vectorLibrary

