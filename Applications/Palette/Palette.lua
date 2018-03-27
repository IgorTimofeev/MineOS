
local MineOSInterface = require("MineOSInterface")

local mainContainer, window = MineOSInterface.addWindow(
	MineOSInterface.windowFromContainer(
		require("GUI").palette(1, 1, 0x9900FF)
	)
)

window.OKButton.onTouch = function()
	window:close()
	MineOSInterface.mainContainer:drawOnScreen()
end

window.cancelButton.onTouch = window.OKButton.onTouch