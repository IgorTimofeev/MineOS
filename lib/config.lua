local config = {}
local fs = require("filesystem")

---------------------------------------------------------------

local function readFile(path)
	local massiv = {}
	
	if not fs.exists(path) then return {} end

	local f = io.open(path, "r")
	for line in f:lines() do
		table.insert(massiv, line)
	end
	f:close()

	return massiv
end

function config.readAll(path)
	local massiv = {}
	local lines = readFile(path)

	for _, stro4ka in pairs(lines) do
		local key, value = string.match(stro4ka, "(.*)%s=%s(.*)")
		if not key then key, value = string.match(stro4ka, "(.*)=(.*)") end

        if key then massiv[key] = value end
	end

	return massiv
end

function config.write(path, key, value)
	local readedConfig = config.readAll(path)
	readedConfig[key] = value

	if fs.exists(path) then fs.remove(path) end
	local file = io.open(path, "w")
	print(" ")
	for key1, value1 in pairs(readedConfig) do
		file:write(key1, " = ", value1, "\n")
		print("Записано "..key1.." = ".. value1)
	end
	print(" ")
	file:close()
end

---------------------------------------------------------------

return config
