local component = require("component")
local computer = require("computer")
local fs = require("filesystem")
local GUI = require("GUI")
local MineOSPaths = require("MineOSPaths")
local MineOSCore = require("MineOSCore")
local MineOSInterface = require("MineOSInterface")

local icon, menu = select(1, ...), select(2, ...)
menu:addItem(MineOSCore.localization.edit).onTouch = function()
	MineOSInterface.safeLaunch(MineOSPaths.editor, icon.path)
end

menu:addSeparator()

menu:addItem(MineOSCore.localization.launchWithArguments).onTouch = function()
	MineOSInterface.launchWithArguments(MineOSInterface.mainContainer, icon.path)
end

menu:addItem(MineOSCore.localization.flashEEPROM, not component.isAvailable("eeprom") or fs.size(icon.path) > 4096).onTouch = function()
	local container = MineOSInterface.addBackgroundContainer(MineOSInterface.mainContainer, MineOSCore.localization.flashEEPROM)
	container.layout:addChild(GUI.label(1, 1, container.width, 1, 0x969696, MineOSCore.localization.flashingEEPROM .. "...")):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
	MineOSInterface.mainContainer:drawOnScreen()

	local file = io.open(icon.path, "r")
	component.eeprom.set(file:read("*a"))
	file:close()
	
	container:remove()
	MineOSInterface.mainContainer:drawOnScreen()
end