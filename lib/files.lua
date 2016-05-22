local filesystem = require("filesystem")
local serialization = require("serialization")
local files = {}

----------------------------------------------------------------------------------------------------------------------------

function files.loadTableFromFile(path)
	local file = io.open(path, "r")
	local data = serialization.unserialize(file:read("*a"))
	file:close()
	return data
end

function files.saveTableToFile(path, tableToSave)
	filesystem.makeDirectory(filesystem.path(path) or "")
	local file = io.open(path, "w")
	file:write(serialization.serialize(tableToSave))
	file:close()
end

-- Открыть файл для чтения в байтном режиме
function files.openForReadingBytes(path)
	local myFileStream = {}

	myFileStream.luaFileStream = io.open(path, "rb")

	function myFileStream.read(count)
		return myFileStream.luaFileStream:read(count)
	end

	function myFileStream.readByteAsString()
		return myFileStream.luaFileStream:read(1)
	end

	function myFileStream.readByteAsDec()
		local readedByte = myFileStream.luaFileStream:read(1)
		if readedByte then return string.byte(readedByte) else return nil end
	end

	function myFileStream.readByteAsHex()
		local readedByte = myFileStream.luaFileStream:read(1)
		if readedByte then return string.format("%02X", string.byte(readedByte)) else return nil end
	end

	function myFileStream.readByteAsDecimal()
		return myFileStream.readByteAsDec()
	end

	function myFileStream.readByteAsHexadecimal()
		return myFileStream.readByteAsHex()
	end

	function myFileStream.close()
		myFileStream.luaFileStream:close()
	end

	return myFileStream
end

----------------------------------------------------------------------------------------------------------------------------

-- ecs.prepareToExit()

-- local file = files.open("test.txt", "rb")
-- for i = 1, 100 do
-- 	print(file.readByteAsHex())
-- end
-- file:close()


return files