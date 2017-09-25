
local args = {...}
local component = require("component")
local computer = require("computer")
local fs = require("filesystem")
local MineOSPaths = require("MineOSPaths")
local MineOSCore = require("MineOSCore")
local MineOSInterface = require("MineOSInterface")

local icon, menu = args[1], args[2]
menu:addItem(MineOSCore.localization.edit).onTouch = function()
	MineOSInterface.safeLaunch(MineOSPaths.editor, icon.path)
end

menu:addSeparator()

menu:addItem(MineOSCore.localization.launchWithArguments).onTouch = function()
	MineOSInterface.launchWithArguments(MineOSInterface.mainContainer, icon.path)
end

menu:addItem(MineOSCore.localization.flashEEPROM, not component.isAvailable("eeprom") or fs.size(icon.path) > 4096).onTouch = function()
	computer.beep(1500, 0.2)
	local file = io.open(icon.path, "r")
	component.eeprom.set(file:read("*a"))
	file:close()
	for i = 1, 2 do
		computer.beep(2000, 0.2)
	end
end