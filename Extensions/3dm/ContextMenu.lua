local MineOSPaths = require("MineOSPaths")
local MineOSCore = require("MineOSCore")
local MineOSInterface = require("MineOSInterface")

local icon, menu = select(1, ...), select(2, ...)
menu:addItem(MineOSCore.localization.edit).onTouch = function()
	MineOSInterface.safeLaunch(MineOSPaths.editor, icon.path)
end