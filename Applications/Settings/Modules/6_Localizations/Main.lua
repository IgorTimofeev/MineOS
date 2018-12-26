
local GUI = require("GUI")
local MineOSInterface = require("MineOSInterface")
local MineOSPaths = require("MineOSPaths")
local MineOSCore = require("MineOSCore")
local filesystem = require("filesystem")

local module = {}

local application, window, localization = table.unpack({...})

--------------------------------------------------------------------------------

module.name = localization.localizations
module.margin = 0
module.onTouch = function()
	local comboBox = window.contentLayout:addChild(GUI.comboBox(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0xD2D2D2, 0xA5A5A5))
	window.contentLayout:addChild(GUI.textBox(1, 1, 36, 1, nil, 0xA5A5A5, {localization.localizationsInfo}, 1, 0, 0, true, true))

	for file in filesystem.list(MineOSPaths.localizationFiles) do
		local name = filesystem.hideExtension(file)
		comboBox:addItem(name).onTouch = function()
			MineOSCore.properties.language = name
			MineOSCore.localization = MineOSCore.getLocalization(MineOSPaths.localizationFiles)

			MineOSInterface.createWidgets()
			MineOSInterface.changeResolution()
			MineOSInterface.changeWallpaper()
			MineOSCore.updateTime()
			MineOSInterface.updateFileListAndDraw()

			MineOSCore.saveProperties()
		end

		if name == MineOSCore.properties.language then
			comboBox.selectedItem = comboBox:count()
		end
	end
end

--------------------------------------------------------------------------------

return module

