
local GUI = require("GUI")
local MineOSInterface = require("MineOSInterface")

local mainContainer, window = MineOSInterface.addWindow(GUI.palette(1, 1, 0x9900FF))
window.submitButton.onTouch = function()
	window:close()
	mainContainer:drawOnScreen()
end

window.cancelButton.onTouch = window.submitButton.onTouch