
local filesystem = require("Filesystem")

-----------------------------------------------------------------------------------------------

local compressor = {
	readBufferSize = 1024,
	ignoredFiles = {
		[".DS_Store"] = true
	}
}

local OCAFSignature = "OCAF"

-----------------------------------------------------------------------------------------------

function compressor.pack(archivePath, fileList)
	if type(fileList) == "string" then
		fileList = {fileList}
	end

	local handle, reason = filesystem.open(archivePath, "wb")
	if handle then
		-- Writing signature
		handle:write(OCAFSignature)
		-- Writing encoding method (maybe will be used in future)
		handle:writeBytes(0)

		local function numberToByteArray(number)
			local byteArray, a, b = {}

			repeat
				a = number / 256
				b = a - a % 1

				table.insert(byteArray, 1, number - b * 256)
				
				number = b
			until number <= 0

			return byteArray
		end

		-- Recursive packing
		local function doPack(fileList, localPath)
			for i = 1, #fileList do
				local filename = filesystem.name(fileList[i])
				local currentLocalPath = localPath .. filename
				-- print("Writing path:", currentLocalPath)

				if not compressor.ignoredFiles[filename] then
					local isDirectory = filesystem.isDirectory(fileList[i])

					-- Writing byte of data type (0 is a file, 1 is a directory)
					handle:writeBytes(isDirectory and 1 or 0)
					-- Writing string path as
					--   <N bytes for reading a number that represents J bytes of path length>
					--   <J bytes for reading a number that represents path length>
					--   <PathLength bytes of path>
					local bytesForCountPathBytes = numberToByteArray(#currentLocalPath)
					handle:writeBytes(#bytesForCountPathBytes)
					handle:writeBytes(table.unpack(bytesForCountPathBytes))
					handle:write(currentLocalPath)

					if isDirectory then
						-- Obtaining new file list
						local newList = filesystem.list(fileList[i])
						-- Creating absolute paths for list elements
						for j = 1, #newList do
							newList[j] = fileList[i] .. newList[j]
						end

						-- Do recursion
						local success, reason = doPack(newList, currentLocalPath)
						if not success then
							return success, reason
						end
					else
						local otherHandle, reason = filesystem.open(fileList[i], "rb")
						if otherHandle then	
							-- Writing file size
							local fileSizeBytes = numberToByteArray(filesystem.size(fileList[i]))
							handle:writeBytes(#fileSizeBytes)
							handle:writeBytes(table.unpack(fileSizeBytes))

							-- Writing file contents
							local data
							while true do
								data = otherHandle:readString(compressor.readBufferSize)
								
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
			-- Reading encoding method *just in case*
			handle:readBytes(1)
			-- Reading contents
			while true do
				local type = handle:readBytes(1)
				if type then
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
								needToRead = math.min(compressor.readBufferSize, fileSize - readedCount)
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
