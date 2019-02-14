
local filesystem = require("Filesystem")
local GUI = require("GUI")
local paths = require("Paths")
local system = require("System")

local workspace, icon, menu = select(1, ...), select(2, ...), select(3, ...)
local localization = system.getSystemLocalization()

menu:addItem(localization.print3D, not component.isAvailable("printer3d")).onTouch = function()
	system.execute(paths.system.applicationPrint3D, icon.path, "-p")
end

system.addUploadToPastebinMenuItem(menu, icon.path)
