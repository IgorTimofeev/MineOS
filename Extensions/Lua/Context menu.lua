
local filesystem = require("Filesystem")
local GUI = require("GUI")
local paths = require("Paths")
local system = require("System")

local workspace, icon, menu = select(1, ...), select(2, ...), select(3, ...)

menu:addItem(system.localization.edit).onTouch = function()
	system.execute(paths.system.applicationMineCodeIDE, icon.path)
end

menu:addItem(system.localization.uploadToPastebin, not component.isAvailable("internet")).onTouch = function()
	system.uploadToPastebin(icon.path)
end

menu:addSeparator()

menu:addItem(system.localization.launchWithArguments).onTouch = function()
	system.launchWithArguments(workspace, icon.path)
end

menu:addItem(system.localization.flashEEPROM, not component.isAvailable("eeprom") or filesystem.size(icon.path) > 4096).onTouch = function()
	local container = GUI.addBackgroundContainer(workspace, true, true, system.localization.flashEEPROM)
	container.layout:addChild(GUI.label(1, 1, container.width, 1, 0x969696, system.localization.flashingEEPROM .. "...")):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
	workspace:draw()

	component.get("eeprom").set(filesystem.read(icon.path))
	
	container:remove()
	workspace:draw()
end
