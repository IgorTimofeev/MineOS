
local GUI = require("GUI")

local module = {
	allowSignalConnections = false,
	updateWhenModuleDetailsIsHidden = true,
}

-------------------------------------------------------------------------------------------------------------------------------------------------------

local sleepValue = 1

-- This method is called once during module initialization
function module.start(moduleContainer)
	local x, y = 1, moduleContainer.children[#moduleContainer.children].localPosition.y + 2
	
	local lines = {limit = 5}
	moduleContainer.editWhitelistButton = moduleContainer:addButton(2, y, moduleContainer.width - 2, 1, 0xDDDDDD, 0x262626, 0xAAAAAA, 0x262626, "Whitelist")
	y = y + 2
	moduleContainer.sleepSlider = moduleContainer:addHorizontalSlider(x, y, moduleContainer.width, 0xFFDB80, 0x000000, 0xFFDB40, 0xDDDDDD, 0.5, 2, sleepValue, false, "Sleep: ")
	moduleContainer.sleepSlider.onValueChanged = function()
		sleepValue = moduleContainer.sleepSlider.value
	end
end

-- This method is called on each frame update (every second by default), but only if module details is not hidden or updateWhenModuleDetailsIsHidden == true
function module.update(moduleContainer, eventData)
	if eventData[1] == "motion" then
		if moduleContainer.componentProxy.address == eventData[2] then
			if eventData[6] == "ECS" then
				moduleContainer:sendSignal("redstone", "pulse")
			end
		end
	end
end

-- This method is called when a this module receives virtual signal from the another module, but only if field allowSignalConnections == true
function module.onSignalReceived(moduleContainer, ...)

end

-------------------------------------------------------------------------------------------------------------------------------------------------------

return module









