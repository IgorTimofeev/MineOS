
require("advancedLua")
local serialization = {}

------------------------------------------------- Public methods -----------------------------------------------------------------

function serialization.serialize(...)
	return table.serialize(...)
end

function serialization.unserialize(...)
	return table.unserialize(...)
end

function serialization.serializeToFile(...)
	table.toFile(...)
end

function serialization.unserializeFromFile(...)
	return table.fromFIle(...)
end

----------------------------------------------------------------------------------------------------------------------

return serialization




