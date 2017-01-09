
local GUI = require("GUI")

local module = {
	allowSignalConnections = false,
	updateWhenModuleDetailsIsHidden = false,
}

-------------------------------------------------------------------------------------------------------------------------------------------------------

-- This method is called once during module initialization
function module.start(moduleContainer)
	
end

-- This method is called on each frame update (every second by default), but only if module details is not hidden or updateWhenModuleDetailsIsHidden == true
function module.update(moduleContainer, eventData)

end

-- This method is called when a this module receives virtual signal from the another module, but only if field allowSignalConnections == true
function module.onSignalReceived(moduleContainer, ...)

end

-------------------------------------------------------------------------------------------------------------------------------------------------------

return module









