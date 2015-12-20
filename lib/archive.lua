local fs = require("filesystem")
local unicode = require("unicode")
local package = {}
package.debugMode = false
local packageSignature = "--@luaPackageFileSignature"
local packageFileSeparator = "--@luaPackageFileSeparator"
local packageFileEnd = "--@luaPackageFileEnd"

------------------------------------------------------------------------------------------------------------------------------------

local function debug(text)
	if package.debugMode then
		print(text)
	end
end

local function doPack(packageFileStream, path, packageFilePath, whereToSavePackedPackage)
	local fileList = fs.list(path)
	for file in fileList do
		if fs.isDirectory(path .. file) then
			doPack(packageFileStream, path .. file, packageFilePath .. file, whereToSavePackedPackage)
		else
			if (path .. file) ~= ("/" .. whereToSavePackedPackage) then
				debug("Упаковка файла \"" .. path .. file .. "\"")

				packageFileStream:write(packageFileSeparator, "\n")
				packageFileStream:write("--@" .. packageFilePath .. file, "\n")
				
				local fileFileStream = io.open(path .. file, "r")
				for line in fileFileStream:lines() do
					packageFileStream:write(line, "\n")
				end
				packageFileStream:write(packageFileEnd, "\n")
				fileFileStream:close()
			end
		end
	end
end

------------------------------------------------------------------------------------------------------------------------------------

function package.pack(whereToSavePackedPackage, pathThatContainsFilesToPack)
	local packageFileStream = io.open(whereToSavePackedPackage, "w")
	packageFileStream:write(packageSignature, "\n")

	doPack(packageFileStream, pathThatContainsFilesToPack .. "/", "", whereToSavePackedPackage)

	packageFileStream:close()
end

function package.unpack(pathToPackedPackage, whereToSaveUnpackedFiles)
	fs.makeDirectory(whereToSaveUnpackedFiles)

	local packageFileStream = io.open(pathToPackedPackage, "r")
	
	--Проверка сигнатуры файла пакета
	local readedSignature = packageFileStream:read("*l")
	if readedSignature ~= packageSignature then error("Ошибка чтения файла пакета: неверная сигнатура. Возможно, вы пытаетесь наебать эту программу и подсовываете ей левый файл?\n") end

	--Распаковка файла пакета на основе записей из него
	local line = ""
	local fileFileStream
	while line do
		line = packageFileStream:read("*l")
		
		if line == packageFileSeparator then
			local path = unicode.sub(packageFileStream:read("*l"), 4, -1)
			fs.makeDirectory(whereToSaveUnpackedFiles .. "/" .. (fs.path(path) or ""))

			debug("Распаковка файла \"" .. whereToSaveUnpackedFiles .. "/" .. path .. "\"")		
			fileFileStream = io.open(whereToSaveUnpackedFiles .. "/" .. path, "w")
		elseif line == packageFileEnd then
			fileFileStream:close()
		else
			fileFileStream:write(line, "\n")
		end
	end

	packageFileStream:close()
end

------------------------------------------------------------------------------------------------------------------------------------

--package.pack("1.pkg", "MineOS")
--package.unpack("1.pkg", "unpackedFiles")

------------------------------------------------------------------------------------------------------------------------------------

return package




