local path = select(1, ...)

local success, reason = require("Compressor").unpack(path, require("Filesystem").path(path))
if not success then
	require("GUI").alert(reason)
end

computer.pushSignal("system", "updateFileList")