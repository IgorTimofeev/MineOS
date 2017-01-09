
local GUI = require("GUI")
local sides = require("sides")

local module = {
	allowSignalConnections = true,
	updateWhenModuleDetailsIsHidden = false,
}

-------------------------------------------------------------------------------------------------------------------------------------------------------

local function changeRedstoneState(moduleContainer, state)
	local sidesThatWillBeChanged = {}
	local comboBoxText = moduleContainer.sidesComboBox.items[moduleContainer.sidesComboBox.currentItem].text
	if comboBoxText == "All" then
		sidesThatWillBeChanged = {0,1,2,3,4,5}
		-- ecs.error("ALLL SIDES YOPTA")
	else
		sidesThatWillBeChanged = {sides[string.lower(comboBoxText)]}
		-- ecs.error("HERE HERE: " .. sides[string.lower(comboBoxText)])
	end
	
	for i = 1, #sidesThatWillBeChanged do
		moduleContainer.redstoneStates[sidesThatWillBeChanged[i]] = state
		moduleContainer.componentProxy.setOutput(sidesThatWillBeChanged[i], state and 15 or 0)
	end
end

-- This method is called once during module initialization
function module.start(moduleContainer)
	local x, y = 2, moduleContainer.children[#moduleContainer.children].localPosition.y + 2
	
	moduleContainer.redstoneStates = {}
	for i = 0, 5 do
		local signalStrength = moduleContainer.componentProxy.getOutput(i)
		moduleContainer.redstoneStates[i] = signalStrength > 0 and true or false
	end

	moduleContainer:addLabel(x, y, moduleContainer.width - 2, 1, 0xDDDDDD, "Signal:")
	moduleContainer.signalSwitch = moduleContainer:addSwitch(moduleContainer.width - 6, y, 6, 0xFFDB40, 0xBBBBBB, 0xFFFFFF, false)
	moduleContainer.signalSwitch.onStateChanged = function()
		changeRedstoneState(moduleContainer, moduleContainer.signalSwitch.state)
	end
	y = y + 2
	moduleContainer.emitOnceButton = moduleContainer:addButton(2, y, moduleContainer.width - 2, 1, 0xDDDDDD, 0x262626, 0xAAAAAA, 0x262626, "Emit once")
	moduleContainer.emitOnceButton.onTouch = function()
		changeRedstoneState(moduleContainer, true)
		os.sleep(0.1)
		changeRedstoneState(moduleContainer, false)
		moduleContainer.signalSwitch.state = false
	end
	y = y + 2
	moduleContainer:addLabel(x, y, moduleContainer.width - 2, 1, 0xFFFFFF, "Side"):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	y = y + 2
	moduleContainer.sidesComboBox = moduleContainer:addComboBox(x, y, moduleContainer.width - 2, 1, 0xDDDDDD, 0x262626, 0xCCCCCC, 0x262626, {"All", "Up", "Down", "North", "South", "West", "East"})
	moduleContainer.sidesComboBox.onItemSelected = function()
		local comboBoxText = moduleContainer.sidesComboBox.items[moduleContainer.sidesComboBox.currentItem].text
		if comboBoxText == "All" then
			moduleContainer.signalSwitch.state = false
		else
			local side = sides[string.lower(comboBoxText)]
			moduleContainer.signalSwitch.state = moduleContainer.redstoneStates[side]
		end
	end
	y = y + 2
end

-- This method is called on each frame update (every second by default), but only if module details is not hidden or updateWhenModuleDetailsIsHidden == true
function module.update(moduleContainer, eventData)

end

-- This method is called when a this module receives virtual signal from the another module, but only if field allowSignalConnections == true
function module.onSignalReceived(moduleContainer, ...)
	local data = {...}
	if data[1] == "redstone" and data[2] == "pulse" then
		changeRedstoneState(moduleContainer, data[3])
	end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------

return module









