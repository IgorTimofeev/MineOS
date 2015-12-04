local filesystem = require("filesystem")
local serialization = require("serialization")
local files = {}

----------------------------------------------------------------------------------------------------------------------------

-- Открыть файл для чтения в текстовом режиме
function files.openForReading(path)
	local myFileStream = {}

	myFileStream.luaFileStream = io.open(path, "r")

	function myFileStream.readLine()
		return myFileStream.luaFileStream:read("*line")
	end

	function myFileStream.readAll()
		return myFileStream.luaFileStream:read("*all")
	end

	function myFileStream.read(count)
		return myFileStream.luaFileStream:read(count)
	end

	function myFileStream.close()
		myFileStream.luaFileStream:close()
	end

	return myFileStream
end

-- Открыть файл для записи в текстовом режиме
function files.openForWriting(path)
	local myFileStream = {}

	myFileStream.luaFileStream = io.open(path, "w")

	function myFileStream.write(...)
		myFileStream.luaFileStream:write(...)
	end

	function myFileStream.writeLine(text)
		myFileStream.luaFileStream:write(text, "\n")
	end

	function myFileStream.close()
		myFileStream.luaFileStream:close()
	end

	return myFileStream
end

-- Открыть файл для записи в байтном режиме
function files.openForWriting(path)
	local myFileStream = {}

	myFileStream.luaFileStream = io.open(path, "wb")

	function myFileStream.write(...)
		myFileStream.luaFileStream:write(...)
	end

	function myFileStream.close()
		myFileStream.luaFileStream:close()
	end

	return myFileStream
end

-- Открыть файл для записи в режиме присоединения данных
function files.openForAppending(path)
	local myFileStream = {}

	myFileStream.luaFileStream = io.open(path, "a")

	function myFileStream.write(...)
		myFileStream.luaFileStream:write(...)
	end

	function myFileStream.close()
		myFileStream.luaFileStream:close()
	end

	return myFileStream
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

-- Открыть файл в указанном режиме
function files.open(path, mode)
	local myFileStream

	local modes = {
		["reading"] = files.openForReading,
		["read"] = files.openForReading,
		["r"] = files.openForReading,
		["writing"] = files.openForWriting,
		["write"] = files.openForWriting,
		["w"] = files.openForWriting,
		["appending"] = files.openForAppending,
		["append"] = files.openForAppending,
		["a"] = files.openForAppending,
		["byteReading"] = files.openForReadingBytes,
		["readingBytes"] = files.openForReadingBytes,
		["rb"] = files.openForReadingBytes,
	}

	if modes[mode] then myFileStream = modes[mode](path) else error("Can't open file: unknown mode (" .. mode .. ")") end

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