local bit32 = require("bit32")

local function hashFile(path)
	local file, reason = io.open(path, "rb")
	if file then
		local bufferSize, hash, data, bytes = 4096, 0
		while true do
			data = file:read(bufferSize)
			if data then
				bytes = {string.byte(data, 1, bufferSize)}
				for i = 1, #bytes do
					hash = hash + bytes[i] * 0x990C9AB5
					hash = bit32.bxor(hash, bit32.rshift(hash, 16))
				end
			else
				break
			end
		end

		file:close()

		return string.format("%X", hash)
	else
		error("Failed to open file for reading: " .. tostring(reason))
	end
end

-- print(hashFile("/OS.lua"))

------------------------------------------------------------------------------------------------------------




