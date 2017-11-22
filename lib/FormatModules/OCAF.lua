
require("advancedLua")
local bit32 = require("bit32")
local unicode = require("unicode")
local fs = require("filesystem")

-----------------------------------------------------------------------------------------------

local module = {}

local encodingMethods = {}
local OCAFSignature = "OCAF"
local readBufferSize = 1024
local ignoredFiles = {
	[".DS_Store"] = true
}

-----------------------------------------------------------------------------------------------

local function getFileList(path)
	local fileList = {}
	for file in fs.list(path) do
		table.insert(fileList, path .. "/" .. file)
	end
	
	return fileList
end

local function readPath(archiveFileHandle)
	local sizeOfSizeArray = {}
	for i = 1, string.byte(archiveFileHandle:read(1)) do
		table.insert(sizeOfSizeArray, string.byte(archiveFileHandle:read(1)))
	end

	return archiveFileHandle:read(bit32.byteArrayToNumber(sizeOfSizeArray))
end

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

-----------------------------------------------------------------------------------------------

encodingMethods[0] = {}

encodingMethods[0].pack = function(archiveFileHandle, fileList, localPath)
	for i = 1, #fileList do
		local filename = fs.name(fileList[i]) or ""
		local currentLocalPath = (localPath or "") .. "/" .. filename
		-- print("Writing path:", currentLocalPath)

		if not ignoredFiles[filename] then
			if fs.isDirectory(fileList[i]) then
				archiveFileHandle:write(string.char(1))
				writePath(archiveFileHandle, currentLocalPath)

				local success, reason = encodingMethods[0].pack(archiveFileHandle, getFileList(fileList[i]), currentLocalPath)
				if not success then
					return success, reason
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

encodingMethods[0].unpack = function(archiveFileHandle, unpackPath)
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
					return false, "Failed to open file for writing: " .. tostring(reason)
				end
			else
				fs.makeDirectory(localPath)
			end
		else
			return true
		end
	end
end

-----------------------------------------------------------------------------------------------

module.pack = function(archivePath, fileList, encodingMethod)
	local archiveFileHandle, reason = io.open(archivePath, "wb")
	if archiveFileHandle then
		archiveFileHandle:write(OCAFSignature)
		archiveFileHandle:write(string.char(encodingMethod))
		
		if encodingMethods[encodingMethod] then
			local success, reason = encodingMethods[encodingMethod].pack(archiveFileHandle, fileList)
			archiveFileHandle:close()
			
			return success, reason
		else
			archiveFileHandle:close()
			
			return false, "Encoding method " .. tostring(encodingMethod) .. " doesn't supported"
		end
	else
		return false, "Failed to open archive file for writing: " .. tostring(reason)
	end
end


module.unpack = function(archivePath, unpackPath)
	local archiveFileHandle, reason = io.open(archivePath, "rb")
	if archiveFileHandle then
		local readedSignature = archiveFileHandle:read(#OCAFSignature)
		if readedSignature == OCAFSignature then
			local readedEncodingMethod = string.byte(archiveFileHandle:read(1))
			if encodingMethods[readedEncodingMethod] then
				local success, reason = encodingMethods[readedEncodingMethod].unpack(archiveFileHandle, unpackPath)
				archiveFileHandle:close()
				
				return success, reason
			else
				archiveFileHandle:close()
				
				return false, "Encoding method " .. tostring(encodingMethod) .. " doesn't supported"
			end
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


