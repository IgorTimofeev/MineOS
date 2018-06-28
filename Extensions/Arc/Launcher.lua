local path = select(1, ...)

local success, reason = require("archive").unpack(path, require("filesystem").path(path))
if not success then
	require("GUI").alert(reason)
end

require("computer").pushSignal("MineOSCore", "updateFileList")