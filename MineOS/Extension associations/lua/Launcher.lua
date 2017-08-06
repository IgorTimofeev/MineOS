
local args = {...}
local MineOSCore = require("MineOSCore")

MineOSCore.clearTerminal()
if MineOSCore.safeLaunch(args[1]) then
	MineOSCore.waitForPressingAnyKey()
end
