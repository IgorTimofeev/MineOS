
require("advancedLua")
local bit32 = require("bit32")
local unicode = require("unicode")
local fs = require("filesystem")

-----------------------------------------------------------------------------------------------

local module = {}
local OCAFSignature = "OCAF"
local ignoredFiles = {
	[".DS_Store"] = true
}
local readBufferSize = 1024

-----------------------------------------------------------------------------------------------

local function getFileList(path)
	local fileList = {}
	for file in fs.list(path) do
		table.insert(fileList, path .. "/" .. file)
	end
	
	return fileList
end

-----------------------------------------------------------------------------------------------

-- Записываем путь в виде <кол-во байт для размера пути> <размер пути> <путь>
local function writePath(archiveFileHandle, path)
	-- Получаем юникод-байтики названия файла или папки
	local pathBytes = {}
	for i = 1, unicode.len(path) do
		local charBytes = { string.byte(unicode.sub(path, i, i), 1, 6) }
		for j = 1, #charBytes do
			table.insert(pathBytes, charBytes[j])
		end
	end

	-- Записываем количество всякой хуйни
	local bytesForCountPathBytes = bit32.numberToByteArray(#pathBytes)
	archiveFileHandle:write(string.char(#bytesForCountPathBytes))
	for i = 1, #bytesForCountPathBytes do
		archiveFileHandle:write(string.char(bytesForCountPathBytes[i]))
	end

	-- Записываем путь
	for i = 1, #pathBytes do
		archiveFileHandle:write(string.char(pathBytes[i]))
	end
end

local function recursivePack(archiveFileHandle, fileList, localPath)
	for i = 1, #fileList do
		local filename = fs.name(fileList[i]) or ""
		local currentLocalPath = localPath .. "/" .. filename
		-- print("Writing path:", currentLocalPath)

		if not ignoredFiles[filename] then
			if fs.isDirectory(fileList[i]) then
				archiveFileHandle:write(string.char(1))
				writePath(archiveFileHandle, currentLocalPath)

				local success, reason = recursivePack(archiveFileHandle, getFileList(fileList[i]), currentLocalPath)
				if not success then
					return reason
				end
			else
				archiveFileHandle:write(string.char(0))
				writePath(archiveFileHandle, currentLocalPath)

				local fileHandle, reason = io.open(fileList[i], "rb")
				if fileHandle then	
					-- Пишем размер файла
					local fileSize = fs.size(fileList[i])
					local fileSizeBytes = bit32.numberToByteArray(fileSize)
					archiveFileHandle:write(string.char(#fileSizeBytes))
					for i = 1, #fileSizeBytes do
						archiveFileHandle:write(string.char(fileSizeBytes[i]))
					end

					-- Пишем содержимое
					local data
					while true do
						data = fileHandle:read(readBufferSize)
						if data then
							archiveFileHandle:write(data)
						else
							break
						end
					end
					
					fileHandle:close()
				else
					return false, "Failed to open file for reading: " .. tostring(reason)
				end
			end
		end
	end

	return true
end

module.pack = function(archivePath, fileList)
	local archiveFileHandle, reason = io.open(archivePath, "wb")
	if archiveFileHandle then
		archiveFileHandle:write(OCAFSignature)
		local success, reason = recursivePack(archiveFileHandle, fileList, "")
		archiveFileHandle:close()
		
		return success, reason
	else
		return false, "Failed to open archive file for writing: " .. tostring(reason)
	end
end

-----------------------------------------------------------------------------------------------

local function readPath(archiveFileHandle)
	local sizeOfSizeArray = {}
	for i = 1, string.byte(archiveFileHandle:read(1)) do
		table.insert(sizeOfSizeArray, string.byte(archiveFileHandle:read(1)))
	end

	return archiveFileHandle:read(bit32.byteArrayToNumber(sizeOfSizeArray))
end

module.unpack = function(archivePath, unpackPath)
	local archiveFileHandle, reason = io.open(archivePath, "rb")
	if archiveFileHandle then
		local readedSignature = archiveFileHandle:read(#OCAFSignature)
		if readedSignature == OCAFSignature then
			while true do
				local typeData = archiveFileHandle:read(1)
				if typeData then
					local type = string.byte(typeData)
					local localPath = unpackPath .. readPath(archiveFileHandle)
					-- print("Readed path:", localPath)

					if type == 0 then
						-- Читаем размер файлика
						local sizeOfSizeArray = {}
						for i = 1, string.byte(archiveFileHandle:read(1)) do
							table.insert(sizeOfSizeArray, string.byte(archiveFileHandle:read(1)))
						end
						local fileSize = bit32.byteArrayToNumber(sizeOfSizeArray)
						-- print("Readed file size:", fileSize)

						-- Читаем и записываем содержимое файлика
						local fileHandle, reason = io.open(localPath, "wb")
						if fileHandle then
							local readedCount, needToRead, data = 0
							while readedCount < fileSize do
								needToRead = math.min(readBufferSize, fileSize - readedCount)
								fileHandle:write(archiveFileHandle:read(needToRead))
								readedCount = readedCount + needToRead
							end
							
							fileHandle:close()
						else
							fileHandle:close()
							return false, "Failed to open file for writing: " .. tostring(reason)
						end
					else
						fs.makeDirectory(localPath)
					end
				else
					break
				end
			end

			archiveFileHandle:close()
			
			return true
		else
			archiveFileHandle:close()
			return false, "Archive signature doesn't match OCAF"
		end
	else
		return false, "Failed to open archive file for reading: " .. tostring(reason)
	end
end

-----------------------------------------------------------------------------------------------

return module


