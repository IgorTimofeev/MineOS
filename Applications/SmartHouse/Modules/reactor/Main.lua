
local GUI = require("GUI")

local module = {
	allowSignalConnections = false,
	updateWhenModuleDetailsIsHidden = false,
}

-------------------------------------------------------------------------------------------------------------------------------------------------------

-- This method is called once during module initialization
function module.start(moduleContainer)
	local x, y = 2, moduleContainer.children[#moduleContainer.children].localPosition.y + 2
	
	moduleContainer.heatLabel = moduleContainer:addLabel(x, y, moduleContainer.width - 2, 1, 0xDDDDDD, ""); y = y + 1
	moduleContainer.outputLabel = moduleContainer:addLabel(x, y, moduleContainer.width - 2, 1, 0xDDDDDD, "")
end

-- This method is called on each frame update (every second by default), but only if module details is not hidden or updateWhenModuleDetailsIsHidden == true
function module.update(moduleContainer, eventData)
	moduleContainer.heatLabel.text = "Heat: " .. math.ceil(moduleContainer.componentProxy.getHeat() / moduleContainer.componentProxy.getMaxHeat() * 100) .. "%"
	moduleContainer.outputLabel.text = "Output: " .. moduleContainer.componentProxy.getReactorEnergyOutput()
end

-- This method is called when a this module receives virtual signal from the another module, but only if field allowSignalConnections == true
function module.onSignalReceived(moduleContainer, ...)

end

-------------------------------------------------------------------------------------------------------------------------------------------------------

return module








