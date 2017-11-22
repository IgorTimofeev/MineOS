
local fs = require("filesystem")
local computer = require("computer")
local component = require("component")

-----------------------------------------------------------------------------------------------

local archive = {
	formatModules = {},
}

-----------------------------------------------------------------------------------------------

function archive.loadFormatModule(path)
	local loadedModule, result = loadfile(path)
	if loadedModule then
		local success, result = pcall(loadedModule, image)
		if success then
			table.insert(archive.formatModules, result)
			return archive.formatModules[#archive.formatModules]
		else
			error("Failed to call format module: " .. tostring(result))
		end
	else
		error("Failed to load format module: " .. tostring(result))
	end
end

-----------------------------------------------------------------------------------------------

function archive.pack(archivePath, fileList, formatModuleID, encodingMethod)
	if type(fileList) ~= "table" then
		fileList = {fileList}
	end
	formatModuleID = formatModuleID or 1

	if archive.formatModules[formatModuleID] then
		if archive.formatModules[formatModuleID].pack then
			return archive.formatModules[formatModuleID].pack(archivePath, fileList, encodingMethod or 0)
		else
			return false, "Format module doesn't have .pack() method"
		end
	else
		return false, "Format module with " .. tostring(formatModuleID) .. " doesn't exists"
	end
end

function archive.unpack(archivePath, unpackPath, formatModuleID)
	if fs.exists(archivePath) then
		formatModuleID = formatModuleID or 1

		if archive.formatModules[formatModuleID] then
			if archive.formatModules[formatModuleID].pack then
				return archive.formatModules[formatModuleID].unpack(archivePath, unpackPath)
			else
				return false, "Format module doesn't have .unpack() method"
			end
		else
			return false, "Format module with " .. tostring(formatModuleID) .. " doesn't exists"
		end
	else
		return false, "Archive file \"" .. tostring(archivePath) .. "\" doesn't exists"
	end
end

-----------------------------------------------------------------------------------------------

archive.loadFormatModule("/lib/FormatModules/OCAF.lua")

-----------------------------------------------------------------------------------------------

-- print("Packing...")
-- print(
-- 	archive.pack("/1.arc", {
-- 		"/MineOS/Applications/Finder.app/",
-- 		"/OS.lua",
-- 		"/usr/",
-- 		"/lib/",
-- 	})
-- )

-- print("Unpacking...")
-- fs.remove("/unpacked/")
-- fs.makeDirectory("/unpacked/")
-- print(
-- 	archive.unpack("/1.arc", "/unpacked/")
-- )

-----------------------------------------------------------------------------------------------

return archive






