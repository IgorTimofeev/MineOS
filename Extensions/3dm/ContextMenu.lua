
local paths = require("Paths")
local system = require("System")

local workspace, icon, menu = select(1, ...), select(2, ...), select(3, ...)

menu:addItem(system.localization.edit).onTouch = function()
	system.execute(paths.editor, icon.path)
end