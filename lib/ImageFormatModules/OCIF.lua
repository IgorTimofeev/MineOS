
local args = {...}
local image = args[1]

---------------------------------------- Libraries ----------------------------------------

local bit32 = require("bit32")
local advancedLua = require("advancedLua")
local unicode = require("unicode")
local fs = require("filesystem")
local colorlib = require("colorlib")

------------------------------------------------------------------------------------------------------------

local module = {}
local OCIFSignature = "OCIF"
local encodingMethods = {
	load = {},
	save = {}
}

------------------------------------------------------------------------------------------------------------

local function writeByteArrayToFile(file, byteArray)
	for i = 1, #byteArray do
		file:write(string.char(byteArray[i]))
	end
end

local function readNumberFromFile(file, countOfBytes)
	local byteArray = {}
	for i = 1, countOfBytes do
		table.insert(byteArray, string.byte(file:read(1)))
	end

	return bit32.byteArrayToNumber(byteArray)
end

---------------------------------------- Uncompressed OCIF1 encoding ----------------------------------------

encodingMethods.save[1] = function(file, picture)
	for i = 3, #picture, 4 do
		writeByteArrayToFile(file, {colorlib.HEXtoRGB(picture[i])})
		writeByteArrayToFile(file, {colorlib.HEXtoRGB(picture[i + 1])})
		file:write(string.char(picture[i + 2]))
		writeByteArrayToFile(file, {string.byte(picture[i + 3], 1, 6)})
	end
end

encodingMethods.load[1] = function(file, picture)
	for i = 1, image.getWidth(picture) * image.getHeight(picture) do
		table.insert(picture, colorlib.RGBtoHEX(string.byte(file:read(1)), string.byte(file:read(1)), string.byte(file:read(1))))
		table.insert(picture, colorlib.RGBtoHEX(string.byte(file:read(1)), string.byte(file:read(1)), string.byte(file:read(1))))
		table.insert(picture, string.byte(file:read(1)))
		table.insert(picture, string.readUnicodeChar(file))
	end
end

---------------------------------------- Grouped and compressed OCIF6 encoding ----------------------------------------

encodingMethods.save[6] = function(file, picture)
	-- Grouping picture by it's alphas, symbols and colors
	local groupedPicture = image.group(picture, true)
	-- Writing 1 byte for alphas array size
	file:write(string.char(table.size(groupedPicture)))

	for alpha in pairs(groupedPicture) do
		-- Writing 1 byte for current alpha value
		file:write(string.char(alpha))
		-- Writing 2 bytes for symbols array size
		writeByteArrayToFile(file, bit32.numberToFixedSizeByteArray(table.size(groupedPicture[alpha]), 2))

		for symbol in pairs(groupedPicture[alpha]) do
			-- Writing N bytes for current unicode symbol value
			writeByteArrayToFile(file, { string.byte(symbol, 1, 6) })
			-- Writing 1 byte for backgrounds array size
			file:write(string.char(table.size(groupedPicture[alpha][symbol])))

			for background in pairs(groupedPicture[alpha][symbol]) do
				-- Writing 1 byte for background color value (compressed by colorlib)
				file:write(string.char(background))
				-- Writing 1 byte for foregrounds array size
				file:write(string.char(table.size(groupedPicture[alpha][symbol][background])))

				for foreground in pairs(groupedPicture[alpha][symbol][background]) do
					-- Writing 1 byte for foreground color value (compressed by colorlib)
					file:write(string.char(foreground))
					-- Writing 1 byte for y array size
					file:write(string.char(table.size(groupedPicture[alpha][symbol][background][foreground])))
					
					for y in pairs(groupedPicture[alpha][symbol][background][foreground]) do
						-- Writing 1 byte for current y value
						file:write(string.char(y))
						-- Writing 1 byte for x array size
						file:write(string.char(#groupedPicture[alpha][symbol][background][foreground][y]))

						for x = 1, #groupedPicture[alpha][symbol][background][foreground][y] do
							file:write(string.char(groupedPicture[alpha][symbol][background][foreground][y][x]))
						end
					end
				end
			end
		end
	end
end

encodingMethods.load[6] = function(file, picture)
	local currentAlpha, currentSymbol, currentBackground, currentForeground, currentY, currentX
	local alphaSize, symbolSize, backgroundSize, foregroundSize, ySize, xSize

	alphaSize = string.byte(file:read(1))
	
	for alpha = 1, alphaSize do
		currentAlpha = string.byte(file:read(1))
		symbolSize = readNumberFromFile(file, 2)
		
		for symbol = 1, symbolSize do
			currentSymbol = string.readUnicodeChar(file)
			backgroundSize = string.byte(file:read(1))
			
			for background = 1, backgroundSize do
				currentBackground = colorlib.convert8BitTo24Bit(string.byte(file:read(1)))
				foregroundSize = string.byte(file:read(1))
				
				for foreground = 1, foregroundSize do
					currentForeground = colorlib.convert8BitTo24Bit(string.byte(file:read(1)))
					ySize = string.byte(file:read(1))
					
					for y = 1, ySize do
						currentY = string.byte(file:read(1))
						xSize = string.byte(file:read(1))
						
						for x = 1, xSize do
							currentX = string.byte(file:read(1))
							image.set(picture, currentX, currentY, currentBackground, currentForeground, currentAlpha, currentSymbol)
						end
					end
				end
			end
		end
	end
end

---------------------------------------- Public load&save methods of module ----------------------------------------

function module.load(path)
	local file, reason = io.open(path, "rb")
	if file then
		local readedSignature = file:read(#OCIFSignature)
		if readedSignature == OCIFSignature then
			local encodingMethod = string.byte(file:read(1))
			if encodingMethods.load[encodingMethod] then
				-- Reading width and height of a picture
				local picture = {string.byte(file:read(1)), string.byte(file:read(1))}
				-- Continue parsing
				encodingMethods.load[encodingMethod](file, picture)
				file:close()	
				return picture
			else
				file:close()
				error("Failed to load OCIF image: encoding method \"" .. tostring(encodingMethod) .. "\" is not supported")
			end
		else
			file:close()
			error("Failed to load OCIF image: wrong signature (\"" .. tostring(readedSignature) .. "\")")
		end
	else
		error("Failed to open file for reading: " .. tostring(reason))
	end
end

function module.save(path, picture, encodingMethod)
	encodingMethod = encodingMethod or 6
	
	local file, reason = io.open(path, "wb")
	if file then	
		if encodingMethods.save[encodingMethod] then
			-- Writing signature, encoding method, image width and height
			file:write(OCIFSignature, string.char(encodingMethod), string.char(picture[1]), string.char(picture[2]))
			-- Executing selected encoding method
			encodingMethods.save[encodingMethod](file, picture)
			file:close()
		else
			file:close()
			error("Failed to save file as OCIF image: encoding method \"" .. tostring(encodingMethod) .. "\" is not supported")
		end
	else
		error("Failed to open file for writing: " .. tostring(reason))
	end
end

------------------------------------------------------------------------------------------------------------

return module


