
local unicode = require("unicode")
local fs = require("filesystem")
local compressor = {}

------------------------------------------------------------------------------------------------------------------

local function numberToByteArray(number)
	local byteArray = {}
	while number > 0 do
		table.insert(byteArray, 1, bit32.band(number, 0xFF))
		number = bit32.rshift(number, 8)
	end
	return byteArray
end

local function byteArrayToNumber(byteArray)
	local number = byteArray[1]
	for i = 2, #byteArray do
		number = bit32.bor(byteArray[i], bit32.lshift(number, 8))
	end
	return number
end

local function getFileList(path)
	local fileList = {}
	for file in fs.list(path) do
		table.insert(fileList, path .. file)
	end
	return fileList
end

------------------------------------------------------------------------------------------------------------------

local function writePath(compressedFile, path)
	-- Получаем юникод-байтики названия файла или папки
	local pathBytes = {}
	for i = 1, unicode.len(path) do
		local charBytes = { string.byte(unicode.sub(path, i, i), 1, 6) }
		for j = 1, #charBytes do
			table.insert(pathBytes, charBytes[j])
		end
	end
	-- Записываем количество байт, необходимое для записи РАЗМЕРА байт пути
	local bytesForCountOfBytesForPath = numberToByteArray(#pathBytes)
	compressedFile:write(string.char(#bytesForCountOfBytesForPath))
	-- Записываем количество байт, необходимое для записи самого пути
	for i = 1, #bytesForCountOfBytesForPath do
		compressedFile:write(string.char(bytesForCountOfBytesForPath[i]))
	end
	-- Записываем байтики пути
	for i = 1, #pathBytes do
		compressedFile:write(string.char(pathBytes[i]))
	end
end

local function writeFileSize(compressedFile, path)
	local size = fs.size(path)
	local bytesForSize = numberToByteArray(size)
	-- Записываем количество байт, необходимое для записи РАЗМЕРА байт размера файла
	compressedFile:write(string.char(#bytesForSize))
	-- Записываем сами байты размера файла
	for i = 1, #bytesForSize do
		compressedFile:write(string.char(bytesForSize[i]))
	end
end

local function doCompressionRecursively(fileList, compressedFile)
	for file = 1, #fileList do
		if fs.name(fileList[file]) ~= "mnt/" and fs.name(fileList[file]) ~= ".DS_Store" then
			if fs.isDirectory(fileList[file]) then
				-- print("Это папка: " .. fileList[file])
				compressedFile:write("D")
				writePath(compressedFile, fileList[file])
				
				doCompressionRecursively(getFileList(fileList[file]), compressedFile)
			else
				-- print("Это файл: " .. fileList[file])
				compressedFile:write("F")
				writePath(compressedFile, fileList[file])
				writeFileSize(compressedFile, fileList[file])
				
				local compressionFile = io.open(fileList[file], "rb")
				compressedFile:write(compressionFile:read("*a"))
				compressionFile:close()
			end
		-- else
		-- 	print("Говно-путь: " .. fileList[file])
		end
	end
end

function compressor.pack(pathToCompress, pathToCompressedFile)
	fs.makeDirectory(fs.path(pathToCompressedFile))
	-- Открываем файл со сжатым контентом
	local compressedFile, reason = io.open(pathToCompressedFile, "wb")
	if not compressedFile then
		error("Failed to open file for writing while packing: " .. tostring(reason))
	end
	-- Записываем сигнатурку
	compressedFile:write("ARCH")
	-- Пакуем данные
	doCompressionRecursively({ pathToCompress }, compressedFile)
	-- Закрываем файл со сжатым контентом
	compressedFile:close()
end

------------------------------------------------------------------------------------------------------------------

local function readPath(compressedFile)
	local countOfBytesForPathBytes = string.byte(compressedFile:read(1))
	local pathBytes = {}
	for i = 1, countOfBytesForPathBytes do
		table.insert(pathBytes, string.byte(compressedFile:read(1)))
	end
	local pathSize = byteArrayToNumber(pathBytes)
	local path = compressedFile:read(pathSize)
	-- print("Колво байт под байты пути: ", countOfBytesForPathBytes)
	-- print("Колво байт под путь: ", pathSize)
	-- print("Путь: ", path)
	return path
end

local function readFileSize(compressedFile)
	local countOfBytesForFileSize = string.byte(compressedFile:read(1))
	local fileSizeBytes = {}
	for i = 1, countOfBytesForFileSize do
		table.insert(fileSizeBytes, string.byte(compressedFile:read(1)))
	end
	local fileSize = byteArrayToNumber(fileSizeBytes)
	-- print("Размер файла: ", fileSize)
	return fileSize
end

function compressor.unpack(pathToCompressedFile, pathWhereToUnpack)
	if not fs.exists(pathToCompressedFile) then
		error("Failed to unpack file \"" .. tostring(pathToCompressedFile) .. "\" because it doesn't exists")
	end
	fs.makeDirectory(pathWhereToUnpack)

	local compressedFile = io.open(pathToCompressedFile, "rb")
	local signature = compressedFile:read(4)
	if signature == "ARCH" then
		while true do
			local type = compressedFile:read(1)
			if type == "D" then
				-- print("Это папка")
				local path = readPath(compressedFile)
				fs.makeDirectory(pathWhereToUnpack .. path)
			elseif type == "F" then
				-- print("Это файл")
				local path = readPath(compressedFile)
				local size = readFileSize(compressedFile)
				
				local file, reason = io.open(pathWhereToUnpack .. path, "wb")
				if not file then
					error("Failed to open file for writing while unpacking: " .. tostring(reason))
				end
				file:write(compressedFile:read(size))
				file:close()
			elseif not type then
				break
			else
				compressedFile:close()
				error("Packed file is corrupted, unknown path type: " .. tostring(type))
			end
		end
	else
		compressedFile:close()
		error("Packed file is corrupted, wrong signature: " .. tostring(signature))
	end

	compressedFile:close()
end

------------------------------------------------------------------------------------------------------------------

-- compressor.pack("/etc/", "/test1.pkg")
-- print(" ")
-- compressor.unpack("/test1.pkg", "/papkaUnpacked/")

------------------------------------------------------------------------------------------------------------------

return compressor



