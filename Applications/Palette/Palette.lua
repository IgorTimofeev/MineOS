
local MineOSInterface = require("MineOSInterface")

local mainContainer, window = MineOSInterface.addWindow(
	MineOSInterface.windowFromContainer(
		require("palette").container(1, 1, 0x9900FF)
	)
)

window.OKButton.onTouch = function()
	window:close()
	MineOSInterface.OSDraw()
end

window.cancelButton.onTouch = window.OKButton.onTouch