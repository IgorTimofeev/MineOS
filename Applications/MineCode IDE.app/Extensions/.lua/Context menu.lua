
local filesystem = require("Filesystem")
local GUI = require("GUI")
local paths = require("Paths")
local system = require("System")

local workspace, icon, menu = select(1, ...), select(2, ...), select(3, ...)
local localization = system.getSystemLocalization()


menu:addItem(localization.uploadToPastebin, not component.isAvailable("internet")).onTouch = function()
	system.uploadToPastebin(icon.path)
end

menu:addItem(localization.flashEEPROM, not component.isAvailable("eeprom") or filesystem.size(icon.path) > 4096).onTouch = function()
	local container = GUI.addBackgroundContainer(workspace, true, true, localization.flashEEPROM)
	container.layout:addChild(GUI.label(1, 1, container.width, 1, 0x969696, localization.flashingEEPROM)):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
	workspace:draw()

	component.get("eeprom").set(filesystem.read(icon.path))
	
	container:remove()
	workspace:draw()
end

menu:addItem(localization.launchWithArguments).onTouch = function()
	system.launchWithArguments(workspace, icon.path)
end
