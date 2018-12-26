
local GUI = require("GUI")
local MineOSInterface = require("MineOSInterface")

local application, window = MineOSInterface.addWindow(GUI.palette(1, 1, 0x9900FF))
window.submitButton.onTouch = function()
	window:close()
	application:draw()
end

window.cancelButton.onTouch = window.submitButton.onTouch