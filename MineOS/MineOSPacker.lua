
local args = {...}
local fs = require("filesystem")
local component = require("component")
local compressor

------------------------------------------------------------------------------------------------------------

local compressorPath = "/lib/compressor.lua"
local MineOSPackagePath = "/MineOS.pkg"

local compressorURL = "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/lib/compressor.lua"
local MineOSPackageURL = "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/MineOS/MineOS.pkg"

local packageFileList = {
	"/MineOS/",
	"/lib/",
	"/OS.lua",
	"/init.lua",
	"/autorun.lua",
}

------------------------------------------------------------------------------------------------------------

function getFile(url, path)
	local file = io.open(path, "w")

	local pcallSuccess, requestHandle, requestReason = pcall(component.internet.request, url)
	if pcallSuccess then
		if requestHandle then
			while true do
				local data, reason = requestHandle.read(math.huge)	
				if data then
					file:write(data)
				else
					requestHandle:close()
					if not reason then
						file:close()
						return
					end
				end
			end
		end		
	end

	file:close()
	print("Failed")
	os.exit()
end

local function getCompressor()
	print("Downloading compressor library...")
	getFile(compressorURL, compressorPath)
	compressor = dofile(compressorPath)
	print("Done.")
	print(" ")
end

local function getPackage()
	print("Downloading MineOS package...")
	getFile(MineOSPackageURL, MineOSPackagePath)
	print("Done.")
	print(" ")
end

------------------------------------------------------------------------------------------------------------

if args[1] == "pack" then
	getCompressor()
	packageFileList[#packageFileList + 1] = true
	compressor.pack(args[2], table.unpack(packageFileList))
elseif args[1] == "unpack" and args[2] and fs.exists(args[2]) then
	getCompressor()
	compressor.unpack(args[2], "/", true)
	require("computer").shutdown(true)
elseif args[1] == "unpackFromMineOSRepository" then
	getCompressor()
	getPackage()
	compressor.unpack(MineOSPackagePath, "/", true)
	fs.remove(MineOSPackagePath)
	require("computer").shutdown(true)
else
	print("Usage:")
	print("  MineOSPacker pack <path>")
	print("  MineOSPacker unpack <path>")
	print("  MineOSPacker unpackFromMineOSRepository")
end
