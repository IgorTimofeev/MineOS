
local GUI = require("GUI")
local system = require("System")

local workspace, window = system.addWindow(GUI.palette(1, 1, 0x9900FF))
window.submitButton.onTouch = function()
	window:remove()
	workspace:draw()
end

window.cancelButton.onTouch = window.submitButton.onTouch