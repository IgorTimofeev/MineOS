
local filesystem = require("Filesystem")
local GUI = require("GUI")
local paths = require("Paths")
local system = require("System")

local workspace, icon, menu = select(1, ...), select(2, ...), select(3, ...)
local localization = system.getSystemLocalization()

menu:addItem("˃", localization.launch).onTouch = function()
	system.execute(icon.path)
end

menu:addItem("˃.", localization.launchWithArguments).onTouch = function()
	system.launchWithArguments(icon.path)
end

menu:addItem("⚡", localization.flashEEPROM, not component.isAvailable("eeprom") or filesystem.size(icon.path) > 4096).onTouch = function()
	local container = GUI.addBackgroundContainer(workspace, true, true, localization.areYouSure)
	local buttonYes = container.layout:addChild(GUI.button(1, 1, 30, 1, 0xE1E1E1, 0x2D2D2D, 0xA5A5A5, 0x2D2D2D, localization.yes))
	--Тёма заебался мискликать так шо он добавил код де спрашивает себя миснул ли он
	buttonYes.onTouch = function()
		container.label.text = localization.flashEEPROM
		buttonYes:remove()
		container.layout:addChild(GUI.label(1, 1, container.width, 1, 0x969696, localization.flashingEEPROM)):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
		workspace:draw()

		component.get("eeprom").set(filesystem.read(icon.path))
		
		container:remove()
		workspace:draw()
	end
end

system.addUploadToPastebinMenuItem(menu, icon.path)
