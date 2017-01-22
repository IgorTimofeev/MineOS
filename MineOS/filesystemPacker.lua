
local args = {...}
local fs = require("filesystem")
local compressor = require("compressor")

if args[1] == "pack" and args[2] then
	local fileList = {}
	for file in fs.list("/") do
		table.insert(fileList, "/" .. file)
	end
	fileList[#fileList + 1] = true

	compressor.pack(args[2], table.unpack(fileList))
elseif args[2] == "unpack" and args[2] and fs.exists(args[2]) then
	compressor.unpack(args[2], "/", true)
else
	print("Usage:")
	print("  filesystemPacker pack <package path>")
	print("  filesystemPacker unpack <package path>")
end
