
local GUI = require("GUI")
local paths = require("Paths")
local system = require("System")
local filesystem = require("Filesystem")

local module = {}

local workspace, window, localization = table.unpack({...})
local userSettings = system.getUserSettings()

--------------------------------------------------------------------------------

module.name = localization.localizations
module.margin = 0
module.onTouch = function()
	local comboBox = window.contentLayout:addChild(GUI.comboBox(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0xD2D2D2, 0xA5A5A5))
	window.contentLayout:addChild(GUI.textBox(1, 1, 36, 1, nil, 0xA5A5A5, {localization.localizationsInfo}, 1, 0, 0, true, true))

	local list = filesystem.list(paths.system.localizations)
	for i = 1, #list do
		if filesystem.extension(list[i]) == ".lang" then
			local name = filesystem.hideExtension(list[i])
			
			comboBox:addItem(name).onTouch = function()
				userSettings.localizationLanguage = name
				localization = system.getLocalization(paths.system.localizations)

				system.updateWorkspace()
				system.updateDesktop()
				workspace:draw()

				system.saveUserSettings()
			end

			if name == userSettings.localizationLanguage then
				comboBox.selectedItem = comboBox:count()
			end
		end
	end
end

--------------------------------------------------------------------------------

return module

