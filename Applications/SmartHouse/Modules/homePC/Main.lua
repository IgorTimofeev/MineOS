
local GUI = require("GUI")

local module = {
	allowSignalConnections = false,
	updateWhenModuleDetailsIsHidden = false,
}

-------------------------------------------------------------------------------------------------------------------------------------------------------

-- This method is called once during module initialization
function module.start(moduleContainer)
	local x, y = 2, moduleContainer.children[#moduleContainer.children].localPosition.y + 2

	moduleContainer:addButton(2, y, moduleContainer.width - 2, 1, 0xDDDDDD, 0x262626, 0xAAAAAA, 0x262626, "Shutdown").onTouch = function()
		require("computer").shutdown()
	end
	y = y + 2
	moduleContainer:addButton(2, y, moduleContainer.width - 2, 1, 0xDDDDDD, 0x262626, 0xAAAAAA, 0x262626, "Reboot").onTouch = function()
		require("computer").shutdown(true)
	end
end

-- This method is called on each frame update (every second by default), but only if module details is not hidden or updateWhenModuleDetailsIsHidden == true
function module.update(moduleContainer, eventData)

end

-- This method is called when a this module receives virtual signal from the another module, but only if field allowSignalConnections == true
function module.onSignalReceived(moduleContainer, ...)

end

-------------------------------------------------------------------------------------------------------------------------------------------------------

return module









