
local args = {...}
local component = require("component")
local computer = require("computer")
local MineOSCore = require("MineOSCore")
local fs = require("filesystem")

local icon, menu = args[1], args[2]
menu:addItem(MineOSCore.localization.edit).onTouch = function()
	MineOSCore.safeLaunch(MineOSCore.paths.editor, icon.path)
end

menu:addSeparator()

menu:addItem(MineOSCore.localization.launchWithArguments).onTouch = function()
	MineOSCore.launchWithArguments(MineOSCore.OSMainContainer, icon.path)
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