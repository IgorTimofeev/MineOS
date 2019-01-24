
local paths = require("Paths")
local system = require("System")

local workspace, icon, menu = select(1, ...), select(2, ...), select(3, ...)
local localization = system.getSystemLocalization()

menu:addItem(localization.edit).onTouch = function()
	system.execute(paths.editor, icon.path)
end

menu:addItem(localization.uploadToPastebin, not component.isAvailable("internet")).onTouch = function()
	system.uploadToPastebin(icon.path)
end
