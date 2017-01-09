
local GUI = require("GUI")

local module = {
	allowSignalConnections = false,
	updateWhenModuleDetailsIsHidden = false,
}

-------------------------------------------------------------------------------------------------------------------------------------------------------

-- This method is called once during module initialization
function module.start(moduleContainer)
	local x, y = 2, moduleContainer.children[#moduleContainer.children].localPosition.y + 2
	
	moduleContainer.capaticyLabel = moduleContainer:addLabel(x, y, moduleContainer.width - 2, 1, 0xDDDDDD, "Capacity"):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top); y = y + 1
	moduleContainer.chart = moduleContainer:addChart(x, y, moduleContainer.width - 2, math.floor(moduleContainer.width - 2) / 2, 0xFFFFFF, 0x999999, 0xFFDB40, "t", "%", 0, 100, {})
end

-- This method is called on each frame update (every second by default), but only if module details is not hidden or updateWhenModuleDetailsIsHidden == true
function module.update(moduleContainer, eventData)
	table.insert(moduleContainer.chart.values, math.ceil(moduleContainer.componentProxy.getStored() / moduleContainer.componentProxy.getCapacity() * 100))
	if #moduleContainer.chart.values > 100 then
		table.remove(moduleContainer.chart.values, 1)
	end
end

-- This method is called when a this module receives virtual signal from the another module, but only if field allowSignalConnections == true
function module.onSignalReceived(moduleContainer, ...)

end

-------------------------------------------------------------------------------------------------------------------------------------------------------

return module









