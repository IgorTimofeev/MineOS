
local MineOSCore = require("MineOSCore")

local mainContainer, window = MineOSCore.addWindow(require("palette").window(nil, nil, 0x9900FF))
window.OKButton.onTouch = function()
	window:close()
end
window.cancelButton.onTouch = window.OKButton.onTouch