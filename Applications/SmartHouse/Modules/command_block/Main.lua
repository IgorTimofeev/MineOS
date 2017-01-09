
local GUI = require("GUI")

local module = {
	allowSignalConnections = true,
	updateWhenModuleDetailsIsHidden = false,
}

-------------------------------------------------------------------------------------------------------------------------------------------------------

local function execute(moduleContainer, command)
	moduleContainer.componentProxy.setCommand(command)
	moduleContainer.componentProxy.executeCommand()
end

-- This method is called once during module initialization
function module.start(moduleContainer)
	local x, y = 2, moduleContainer.children[#moduleContainer.children].localPosition.y + 2
	
	moduleContainer.commandTextBox = moduleContainer:addInputTextBox(x, y, moduleContainer.width - 2, 1, nil, 0xDDDDDD, nil, 0xFFFFFF, "/say Hello", "Type command here", false, false)
	y = y + 2
	moduleContainer.executeButton = moduleContainer:addButton(2, y, moduleContainer.width - 2, 1, 0xDDDDDD, 0x262626, 0xAAAAAA, 0x262626, "Execute")
	moduleContainer.executeButton.onTouch = function()
		execute(moduleContainer, moduleContainer.commandTextBox.text)
	end
end

-- This method is called on each frame update (every second by default), but only if module details is not hidden or updateWhenModuleDetailsIsHidden == true
function module.update(moduleContainer, eventData)

end

-- This method is called when a this module receives virtual signal from the another module, but only if field allowSignalConnections == true
function module.onSignalReceived(moduleContainer, ...)
	local data = {...}
	execute(moduleContainer, moduleContainer.commandTextBox.text)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------

return module









