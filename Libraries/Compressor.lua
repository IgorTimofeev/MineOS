
local filesystem = require("Filesystem")

-----------------------------------------------------------------------------------------------

local compressor = {}
local OCAFSignature = "OCAF"
local readBufferSize = 1024
local ignoredFiles = {
	[".DS_Store"] = true
}

-----------------------------------------------------------------------------------------------

local function numberToByteArray(number)
	local byteArray = {}

	repeat
		table.insert(byteArray, 1, bit32.band(number, 0xFF))
		number = bit32.rshift(number, 8)
	until number <= 0

	return byteArray
end

-- Записываем путь в виде <кол-во байт для размера пути> <размер пути> <путь>
local function writePath(handle, path)
	-- Получаем юникод-байтики названия файла или папки
	local pathBytes = {string.byte(path, 1, #path)}
	
	-- Записываем количество всякой хуйни
	local bytesForCountPathBytes = numberToByteArray(#pathBytes)

	handle:writeBytes(#bytesForCountPathBytes)
	handle:writeBytes(table.unpack(bytesForCountPathBytes))

	-- Записываем путь
	handle:write(path)
end

-----------------------------------------------------------------------------------------------

function compressor.pack(archivePath, fileList)
	if type(fileList) == "string" then
		fileList = {fileList}
	end

	local handle, reason = filesystem.open(archivePath, "wb")
	if handle then
		-- Writing signature
		handle:write(OCAFSignature)
		
		-- Recursive packing
		local function doPack(fileList, localPath)
			for i = 1, #fileList do
				local filename = filesystem.name(fileList[i])
				local currentLocalPath = localPath .. "/" .. filename
				-- print("Writing path:", currentLocalPath)

				if not ignoredFiles[filename] then
					if filesystem.isDirectory(fileList[i]) then
						handle:writeBytes(1)
						writePath(handle, currentLocalPath)

						-- Obtaining new file list
						local newList = filesystem.list(fileList[i])
						-- Forming absolute paths for list
						for j = 1, #newList do
							newList[j] = fileList[i] .. newList[j]
						end

						-- Do recursion
						local success, reason = doPack(newList, currentLocalPath)
						if not success then
							return success, reason
						end
					else
						handle:writeBytes(0)
						writePath(handle, currentLocalPath)

						local otherHandle, reason = filesystem.open(fileList[i], "rb")
						if otherHandle then	
							-- Пишем размер файла
							local fileSizeBytes = numberToByteArray(filesystem.size(fileList[i]))
							
							handle:writeBytes(#fileSizeBytes)
							handle:writeBytes(table.unpack(fileSizeBytes))

							-- Пишем содержимое
							local data
							while true do
								data = otherHandle:readString(readBufferSize)
								
								if data then
									handle:write(data)
								else
									break
								end
							end
							
							otherHandle:close()
						else
							return false, "Failed to open file for reading: " .. tostring(reason)
						end
					end
				end
			end

			return true
		end

		local success, reason = doPack(fileList, "")
		handle:close()

		return success, reason
	else
		return false, "Failed to open archive file for writing: " .. tostring(reason)
	end
end


function compressor.unpack(archivePath, unpackPath)
	local handle, reason = filesystem.open(archivePath, "rb")
	if handle then
		local readedSignature = handle:readString(#OCAFSignature)
		if readedSignature == OCAFSignature then
			while true do
				local typeData = handle:readString(1)
				if typeData then
					local type = string.byte(typeData)
					-- Reading path
					local localPath = unpackPath .. handle:readString(handle:readBytes(handle:readBytes(1)))
					-- print("Readed path:", localPath)

					if type == 0 then
						-- Читаем размер файлика
						local fileSize = handle:readBytes(handle:readBytes(1))
						-- Читаем и записываем содержимое файлика
						local otherHandle, reason = filesystem.open(localPath, "wb")
						if otherHandle then
							local readedCount, needToRead, data = 0
							while readedCount < fileSize do
								needToRead = math.min(readBufferSize, fileSize - readedCount)
								otherHandle:write(handle:readString(needToRead))
								readedCount = readedCount + needToRead
							end
							
							otherHandle:close()
						else
							handle:close()
							return false, "Failed to open file for writing: " .. tostring(reason)
						end
					else
						filesystem.makeDirectory(localPath)
					end
				else
					handle:close()
					return true
				end
			end

			handle:close()
			return success, reason
		else
			handle:close()
			return false, "archive signature doesn't match OCAF"
		end
	else
		return false, "failed to open archive file for reading: " .. tostring(reason)
	end
end

-----------------------------------------------------------------------------------------------

return compressor
