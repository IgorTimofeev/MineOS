
require("advancedLua")
local serialization = {}

------------------------------------------------- Public methods -----------------------------------------------------------------

function serialization.serialize(variable, ...)
	local variableType = type(variable)
	if variableType == "table" then
		return table.serialize(variable, ...)
	else
		return tostring(variable)
	end
end

serialization.unserialize = table.unserialize

----------------------------------------------------------------------------------------------------------------------

return serialization
