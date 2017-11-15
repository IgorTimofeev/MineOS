
local mainContainer, window = require("MineOSInterface").addWindow(require("palette").window(1, 1, 0x9900FF))
window.OKButton.onTouch = function()
	window:close()
end
window.cancelButton.onTouch = window.OKButton.onTouch