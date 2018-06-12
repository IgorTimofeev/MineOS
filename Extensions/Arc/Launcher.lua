
local args = {...}

local success, reason = require("archive").unpack(args[1], require("filesystem").path(args[1]))
if not success then
	require("GUI").alert(reason)
end

require("computer").pushSignal("MineOSCore", "updateFileList")