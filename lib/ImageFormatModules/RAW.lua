
local args = {...}
local image = args[1]

local unicode = require("unicode")
local module = {}

--------------------------------------------------------------------------------------------------------------

function module.load(path)
	local file, reason = io.open(path, "r")
	if file then
		local picture, pictureWidth, lineCounter = {0, 0}, nil, 0
		for line in file:lines() do
			local lineLength = unicode.len(line)
			if not pictureWidth then
				pictureWidth = (lineLength + 1) / 19
				picture[1] = pictureWidth
			end

			for x = 1, lineLength, 19 do
				table.insert(picture, tonumber("0x" .. unicode.sub(line, x, x + 5)))
				table.insert(picture, tonumber("0x" .. unicode.sub(line, x + 7, x + 12)))
				table.insert(picture, tonumber("0x" .. unicode.sub(line, x + 14, x + 15)))
				table.insert(picture, unicode.sub(line, x + 17, x + 17))
			end

			lineCounter = lineCounter + 1
		end

		picture[2] = lineCounter
		file:close()
		return picture
	else
		error("Failed to open file \"" .. tostring(path) .. "\" for reading: " .. tostring(reason))
	end
end

function module.save(path, picture, encodingMethod)
	local file, reason = io.open(path, "w")
	if file then	
		local x = 1
		for i = 3, #picture, 4 do
			file:write(
				string.format("%06X", picture[i]), " ",
				string.format("%06X", picture[i + 1]), " ",
				string.format("%02X", picture[i + 2]), " ",
				picture[i + 3]
			)

			x = x + 1
			if x > picture[1] then
				x = 1
				file:write("\n")
			else
				file:write(" ")
			end
		end

		file:close()
	else
		error("Failed to open file for writing: " .. tostring(reason))
	end
end

--------------------------------------------------------------------------------------------------------------

return module


