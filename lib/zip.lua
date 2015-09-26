local fs = require("filesystem")
local unicode = require("unicode")
local ecs = require("ECSAPI")

local zip = {}

local pathToFileCodePhraze = "@ARCHIVE_PATH_TO_FILE = "
local archiveStartCodePhraze = "@ZIP_ARCHIVE_BY_ECS"
local dlinaOfCodePhraze = unicode.len(pathToFileCodePhraze)

-----------------------------------------------------------------------------------------------------------------------

local zhirniyPidorskiyMassivSoStrokami

local function getFileStringsMassiv(path, archivePath, debug)
	local fileList = ecs.getFileList(path)

	for _, file in pairs(fileList) do
		local pathToFile = path..file
		if fs.isDirectory(pathToFile) then
			getFileStringsMassiv(pathToFile, archivePath..file)
		else
			table.insert(zhirniyPidorskiyMassivSoStrokami, pathToFileCodePhraze..archivePath..file)

			if debug then print("Archiving file "..pathToFile) end

			local f = io.open(pathToFile, "r")

			for line in f:lines() do
				table.insert(zhirniyPidorskiyMassivSoStrokami, line)
			end

			f:close()
		end
	end

	fileList = nil
end

function zip.archive(path, kudaSohranit, debug)
	checkArg(1, path, "string")
	checkArg(2, kudaSohranit, "string")

	--ОБНУЛЯЕМ ЖИРНЫЙ ПИДОРСКИЙ МАССИВ
	zhirniyPidorskiyMassivSoStrokami = {
		archiveStartCodePhraze
	}

	--ПОЛУЧАЕМ ЖИРНЫЙ ПИДОРСКИЙ МАССИВ
	getFileStringsMassiv(path.."/", fs.name(path).."/", debug)

	--СОХРАНЯЕМ ЖИРНЫЙ ПИДОРСКИЙ МАССИВ
	fs.makeDirectory(fs.path(kudaSohranit))
	if fs.exists(kudaSohranit) then fs.remove(kudaSohranit) end
	local f = io.open(kudaSohranit, "w")
	for _, val in pairs(zhirniyPidorskiyMassivSoStrokami) do
		f:write(val, "\n")
	end
	f:close()

	if debug then print("\nArchiving complete!\n") end
end

function zip.unarchive(path, kudaSohranit, debug)
	checkArg(1, path, "string")
	checkArg(2, kudaSohranit, "string")

	local massiv = {}
	local f = io.open(path, "r")
	for line in f:lines() do
		table.insert(massiv, line)
	end
	f:close()

	if massiv[1] ~= archiveStartCodePhraze then error("Failed to unpack, archive file is corrupted.") end

	fs.makeDirectory(kudaSohranit)

	local path
	local f
	for i = 2, #massiv do
		if unicode.sub(massiv[i], 1, dlinaOfCodePhraze) == pathToFileCodePhraze then
			if f then f:close() end
			path = kudaSohranit.."/"..unicode.sub(massiv[i], dlinaOfCodePhraze + 1, -1)
			fs.makeDirectory(fs.path(path))
			if debug then print("Unarchiving file "..path) end
			f, reason = io.open(path, "w")
			if not f then error(reason) end
		else
			f:write(massiv[i], "\n")
		end
	end

	if debug then print("\nUnarchiving complete!\n") end
end

-----------------------------------------------------------------------------------------------------------------------

return zip
