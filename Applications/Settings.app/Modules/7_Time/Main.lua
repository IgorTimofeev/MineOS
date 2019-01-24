
local GUI = require("GUI")
local paths = require("Paths")
local system = require("System")

local module = {}

local workspace, window, localization = table.unpack({...})
local userSettings = system.getUserSettings()

--------------------------------------------------------------------------------

module.name = localization.time
module.margin = 0
module.onTouch = function()
	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.timeZone))

	local comboBox = window.contentLayout:addChild(GUI.comboBox(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0xD2D2D2, 0xA5A5A5))
	comboBox.dropDownMenu.itemHeight = 1

	for i = -12, 12 do
		comboBox:addItem("GMT" .. (i >= 0 and "+" or "") .. i)
	end

	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.timeFormat))
	
	local input = window.contentLayout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0xA5A5A5, 0xE1E1E1, 0x2D2D2D, userSettings.timeFormat or ""))

	local switch = window.contentLayout:addChild(GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xA5A5A5, localization.timeUseRealTimestamp .. ":", userSettings.timeRealTimestamp)).switch
	
	window.contentLayout:addChild(GUI.textBox(1, 1, 36, 1, nil, 0xA5A5A5, {localization.timeInfo}, 1, 0, 0, true, true))

	comboBox.selectedItem = (userSettings.timeTimezone or 0) + 13
	comboBox.onItemSelected = function()
		userSettings.timeRealTimestamp = switch.state
		userSettings.timeTimezone = (comboBox.selectedItem - 13) * 3600
		userSettings.timeFormat = input.text
		
		system.updateMenuWidgets()
		workspace:draw()

		system.saveUserSettings()
	end

	input.onInputFinished, switch.onStateChanged = comboBox.onItemSelected, comboBox.onItemSelected
end

--------------------------------------------------------------------------------

return module

