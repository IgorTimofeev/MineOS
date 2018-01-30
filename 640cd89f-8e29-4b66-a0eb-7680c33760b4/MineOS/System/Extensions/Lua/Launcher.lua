
local args = {...}
local MineOSInterface = require("MineOSInterface")

MineOSInterface.clearTerminal()
if MineOSInterface.safeLaunch(args[1]) then
	MineOSInterface.waitForPressingAnyKey()
end
