
local args = {...}
local fs = require("filesystem")

require("compressor").unpack(args[1], fs.path(args[1]))