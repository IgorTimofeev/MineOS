
local GUI = require("GUI")
local MineOSInterface = require("MineOSInterface")

local mainContainer, window = MineOSInterface.addWindow(GUI.windowFromContainer(GUI.palette(1, 1, 0x9900FF)))
window.onSubmit = function()
	window:close()
	mainContainer:drawOnScreen()
end

window.onCancel = window.onSubmit