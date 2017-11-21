
local args = {...}

require("archive").unpack(args[1], require("filesystem").path(args[1]))
require("computer").pushSignal("MineOSCore", "updateFileList")