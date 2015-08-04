local zip = require("zip")
local fs = require("filesystem")

local arg = {...}

if arg[1] == "archive" then
	fs.makeDirectory(fs.path(arg[3]))
	zip.archive(arg[2], arg[3], true)
elseif arg[1] == "unarchive" then
	if not fs.exists(arg[2]) then error("There is no file named as \"" .. arg[2] .. "\"") end
	fs.makeDirectory(arg[3])
	zip.unarchive(arg[2], arg[3], true)
else
	print("Usage: zip <archive/unarchive> <open path> <save path>")
end
