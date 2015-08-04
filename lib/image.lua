local fs = require("filesystem")
local unicode = require("unicode")
local gpu = require("component").gpu

local image = {}

---------------------------------------------------------------------------------------------------------------------

local transparentSymbol = "#"

function image.load(path)
	local file = io.open(path, "r")
	local massiv = {}

	for line in file:lines() do
		local dlinaStroki = unicode.len(line)
		local lineNumber = #massiv + 1

		if dlinaStroki > 14 then
			local pixelCounter = 1
			massiv[lineNumber] = {}
			for i = 1, dlinaStroki, 16 do
				local loadedBackground = unicode.sub(line, i, i + 5)
				local loadedForeground = unicode.sub(line, i + 7, i + 12)
				local loadedSymbol = unicode.sub(line, i + 14, i + 14)

				massiv[lineNumber][pixelCounter] = { tonumber("0x" .. loadedBackground), tonumber("0x" .. loadedForeground), loadedSymbol }

				pixelCounter = pixelCounter + 1
			end
		end
	end

	file:close()
	return massiv
end

function image.draw(x, y, massivSudaPihay)
	x = x - 1
	y = y - 1
	for j = 1, #massivSudaPihay do
		for i = 1, #massivSudaPihay[j] do
			if massivSudaPihay[j][i][1] and massivSudaPihay[j][i][2] and massivSudaPihay[j][i][3] ~= transparentSymbol then
				gpu.setBackground(massivSudaPihay[j][i][1])
				gpu.setForeground(massivSudaPihay[j][i][2])
				gpu.set(x + i, y + j, massivSudaPihay[j][i][3])
			end
		end
	end
end


---------------------------------------------------------------------------------------------------------------------

return image
