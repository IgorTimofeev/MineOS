
-------------------------------------------------- Libraries --------------------------------------------------

local color = require("color")
local unicode = require("unicode")
local fs = require("filesystem")
local gpu = require("component").gpu

-------------------------------------------------- Constants --------------------------------------------------

local image = {}
image.formatModules = {}

-------------------------------------------------- Low-level methods --------------------------------------------------

function image.iterationYield(iteration)
	if iteration % 603 == 0 then os.sleep(0) end
end

function image.getImageCoordinatesByIndex(index, width)
	local integer, fractional = math.modf((index - 2) / (width * 4))
	return math.ceil(fractional * width), integer + 1
end

function image.getImageIndexByCoordinates(x, y, width)
	return (width * 4) * (y - 1) + x * 4 - 1
end

function image.group(picture, compressColors)
	local groupedPicture, x, y, iPlus2, iPlus3, background, foreground = {}, 1, 1

	for i = 3, #picture, 4 do
		iPlus2, iPlus3 = i + 2, i + 3

		if compressColors then
			background, foreground = color.to8Bit(picture[i]), color.to8Bit(picture[i + 1])
			image.iterationYield(i)
		else
			background, foreground = picture[i], picture[i + 1]
		end

		groupedPicture[picture[iPlus2]] = groupedPicture[picture[iPlus2]] or {}
		groupedPicture[picture[iPlus2]][picture[iPlus3]] = groupedPicture[picture[iPlus2]][picture[iPlus3]] or {}
		groupedPicture[picture[iPlus2]][picture[iPlus3]][background] = groupedPicture[picture[iPlus2]][picture[iPlus3]][background] or {}
		groupedPicture[picture[iPlus2]][picture[iPlus3]][background][foreground] = groupedPicture[picture[iPlus2]][picture[iPlus3]][background][foreground] or {}
		groupedPicture[picture[iPlus2]][picture[iPlus3]][background][foreground][y] = groupedPicture[picture[iPlus2]][picture[iPlus3]][background][foreground][y] or {}

		table.insert(groupedPicture[picture[iPlus2]][picture[iPlus3]][background][foreground][y], x)

		x = x + 1
		if x > picture[1] then
			x, y = 1, y + 1
		end
	end

	return groupedPicture
end

function image.draw(x, y, picture)
	local groupedPicture = image.group(picture)
	local _, _, currentBackground, currentForeground, gpuGetBackground, imageX, imageY

	for alpha in pairs(groupedPicture) do
		for symbol in pairs(groupedPicture[alpha]) do
			
			if not (symbol == " " and alpha == 1) then
				for background in pairs(groupedPicture[alpha][symbol]) do
					
					if background ~= currentBackground then
						currentBackground = background
						gpu.setBackground(background)
					end

					for foreground in pairs(groupedPicture[alpha][symbol][background]) do
						
						if foreground ~= currentForeground and symbol ~= " " then
							currentForeground = foreground
							gpu.setForeground(foreground)
						end
						
						for yPos in pairs(groupedPicture[alpha][symbol][background][foreground]) do
							for xPos = 1, #groupedPicture[alpha][symbol][background][foreground][yPos] do
								imageX, imageY = x + groupedPicture[alpha][symbol][background][foreground][yPos][xPos] - 1, y + yPos - 1

								if alpha > 0 then
									_, _, gpuGetBackground = gpu.get(imageX, imageY)
									
									if alpha == 1 then
										currentBackground = gpuGetBackground
										gpu.setBackground(currentBackground)
									else
										currentBackground = color.blend(gpuGetBackground, background, alpha)
										gpu.setBackground(currentBackground)
									end
								end

								gpu.set(imageX, imageY, symbol)
							end
						end
					end
				end
			end
		end
	end
end

function image.create(width, height, background, foreground, alpha, symbol, random)
	local picture = {width, height}

	for i = 1, width * height do
		table.insert(picture, random and math.random(0x0, 0xFFFFFF) or (background or 0x0))
		table.insert(picture, random and math.random(0x0, 0xFFFFFF) or (foreground or 0x0))
		table.insert(picture, alpha or 0x0)
		table.insert(picture, random and string.char(math.random(65, 90)) or (symbol or " "))
	end

	return picture
end

function image.copy(picture)
	local newPicture = {}
	for i = 1, #picture do
		table.insert(newPicture, picture[i])
	end

	return newPicture
end

function image.optimize(picture)
	local iPlus1, iPlus2, iPlus3

	for i = 3, #picture, 4 do
		iPlus1, iPlus2, iPlus3 = i + 1, i + 2, i + 3

		if picture[i] == picture[iPlus1] and (picture[iPlus3] == "▄" or picture[iPlus3] == "▀") then
			picture[iPlus3] = " "
		end
		
		if picture[iPlus3] == " " then		
			picture[iPlus1] = 0x000000
		end
	end

	return picture
end

-------------------------------------------------- Filesystem related methods --------------------------------------------------

function image.loadFormatModule(path, fileExtension)
	local loadSuccess, loadReason = loadfile(path)
	if loadSuccess then
		local xpcallSuccess, xpcallReason = pcall(loadSuccess, image)
		if xpcallSuccess then
			image.formatModules[fileExtension] = xpcallReason
		else
			error("Failed to execute image format module: " .. tostring(xpcallReason))
		end
	else
		error("Failed to load image format module: " .. tostring(loadReason))
	end
end

local function getFileExtension(path)
	return string.match(path, "^.+(%.[^%/]+)%/?$")
end

local function loadOrSave(methodName, path, ...)
	local fileExtension = getFileExtension(path)
	if image.formatModules[fileExtension] then
		return image.formatModules[fileExtension][methodName](path, ...)
	else
		error("Failed to open file \"" .. tostring(path) .. "\" as image: format module for extension \"" .. tostring(fileExtension) .. "\" is not loaded")
	end
end

function image.save(path, picture, encodingMethod)
	return loadOrSave("save", path, image.optimize(picture), encodingMethod)
end

function image.load(path)
	return loadOrSave("load", path)
end

-------------------------------------------------- Image serialization --------------------------------------------------

function image.toString(picture)
	local charArray = {
		string.format("%02X", picture[1]),
		string.format("%02X", picture[2])
	}
	
	for i = 3, #picture, 4 do
		table.insert(charArray, string.format("%02X", color.to8Bit(picture[i])))
		table.insert(charArray, string.format("%02X", color.to8Bit(picture[i + 1])))
		table.insert(charArray, string.format("%02X", math.floor(picture[i + 2] * 255)))
		table.insert(charArray, picture[i + 3])

		image.iterationYield(i)
	end

	return table.concat(charArray)
end

function image.fromString(pictureString)
	local picture = {
		tonumber("0x" .. unicode.sub(pictureString, 1, 2)),
		tonumber("0x" .. unicode.sub(pictureString, 3, 4))
	}

	for i = 5, unicode.len(pictureString), 7 do
		table.insert(picture, color.to24Bit(tonumber("0x" .. unicode.sub(pictureString, i, i + 1))))
		table.insert(picture, color.to24Bit(tonumber("0x" .. unicode.sub(pictureString, i + 2, i + 3))))
		table.insert(picture, tonumber("0x" .. unicode.sub(pictureString, i + 4, i + 5)) / 255)
		table.insert(picture, unicode.sub(pictureString, i + 6, i + 6))
	end

	return picture
end

-------------------------------------------------- Image processing --------------------------------------------------

function image.set(picture, x, y, background, foreground, alpha, symbol)
	local index = image.getImageIndexByCoordinates(x, y, picture[1])
	picture[index], picture[index + 1], picture[index + 2], picture[index + 3] = background, foreground, alpha, symbol

	return picture
end

function image.get(picture, x, y)
	local index = image.getImageIndexByCoordinates(x, y, picture[1])
	return picture[index], picture[index + 1], picture[index + 2], picture[index + 3]
end

function image.getSize(picture)
	return picture[1], picture[2]
end

function image.getWidth(picture)
	return picture[1]
end

function image.getHeight(picture)
	return picture[2]
end

function image.transform(picture, newWidth, newHeight)
	local newPicture, stepWidth, stepHeight, background, foreground, alpha, symbol = {newWidth, newHeight}, picture[1] / newWidth, picture[2] / newHeight
	
	local x, y = 1, 1
	for j = 1, newHeight do
		for i = 1, newWidth do
			background, foreground, alpha, symbol = image.get(picture, math.floor(x), math.floor(y))
			table.insert(newPicture, background)
			table.insert(newPicture, foreground)
			table.insert(newPicture, alpha)
			table.insert(newPicture, symbol)

			x = x + stepWidth
		end
		x, y = 1, y + stepHeight
	end

	return newPicture
end

function image.crop(picture, fromX, fromY, width, height)
	if fromX >= 1 and fromY >= 1 and fromX + width - 1 <= picture[1] and fromY + height - 1 <= picture[2] then
		local newPicture, background, foreground, alpha, symbol = {width, height}
		
		for y = fromY, fromY + height - 1 do
			for x = fromX, fromX + width - 1 do
				background, foreground, alpha, symbol = image.get(picture, x, y)
				table.insert(newPicture, background)
				table.insert(newPicture, foreground)
				table.insert(newPicture, alpha)
				table.insert(newPicture, symbol)
			end
		end

		return newPicture
	else
		error("Failed to crop image: target coordinates are out of source range")
	end
end

function image.flipHorizontally(picture)
	local newPicture, background, foreground, alpha, symbol = {picture[1], picture[2]}
	
	for y = 1, picture[2] do
		for x = picture[1], 1, -1 do
			background, foreground, alpha, symbol = image.get(picture, x, y)
			table.insert(newPicture, background)
			table.insert(newPicture, foreground)
			table.insert(newPicture, alpha)
			table.insert(newPicture, symbol)
		end
	end

	return newPicture
end

function image.flipVertically(picture)
	local newPicture, background, foreground, alpha, symbol = {picture[1], picture[2]}
	
	for y = picture[2], 1, -1 do
		for x = 1, picture[1] do
			background, foreground, alpha, symbol = image.get(picture, x, y)
			table.insert(newPicture, background)
			table.insert(newPicture, foreground)
			table.insert(newPicture, alpha)
			table.insert(newPicture, symbol)
		end
	end

	return newPicture
end

function image.expand(picture, fromTop, fromBottom, fromLeft, fromRight, background, foreground, alpha, symbol)
	local newPicture = image.create(picture[1] + fromRight + fromLeft, picture[2] + fromTop + fromBottom, background, foreground, alpha, symbol)

	for y = 1, picture[2] do
		for x = 1, picture[1] do
			image.set(newPicture, x + fromLeft, y + fromTop, image.get(picture, x, y))
		end
	end

	return newPicture
end

function image.blend(picture, blendColor, transparency)
	local newPicture = {picture[1], picture[2]}

	for i = 3, #picture, 4 do
		table.insert(newPicture, color.blend(picture[i], blendColor, transparency))
		table.insert(newPicture, color.blend(picture[i + 1], blendColor, transparency))
		table.insert(newPicture, picture[i + 2])
		table.insert(newPicture, picture[i + 3])
	end

	return newPicture
end

function image.blur(picture, radius, strength)
	local blurMatrix = {}

	local xValue, yValue, step = 1, 1, 1 / radius		
	for y = 0, radius do
		for x = 0, radius do
			blurMatrix[y], blurMatrix[-y] = blurMatrix[y] or {}, blurMatrix[-y] or {}
			
			blurMatrix[y][x] = (xValue + yValue) / 2 * strength
			blurMatrix[y][-x], blurMatrix[-y][x], blurMatrix[-y][-x] = blurMatrix[y][x], blurMatrix[y][x], blurMatrix[y][x]

			xValue = xValue - step
		end

		xValue, yValue = 1, yValue - step
	end

	local newPicture, xImage, yImage = image.copy(picture)
	for y = 1, image.getHeight(picture) do
		for x = 1, image.getWidth(picture) do
			local backgroundOld, foregroundOld, alpha, symbol = image.get(picture, x, y)

			for yMatrix = -radius, radius do
				for xMatrix = -radius, radius do
					xImage, yImage = x + xMatrix, y + yMatrix
					
					if xImage >= 1 and xImage <= image.getWidth(picture) and yImage >= 1 and yImage <= image.getHeight(picture) then
						local backgroundNew, foregroundNew = image.get(newPicture, xImage, yImage)

						image.set(newPicture, xImage, yImage,
							color.blend(backgroundOld, backgroundNew, blurMatrix[yMatrix][xMatrix]),
							color.blend(foregroundOld, foregroundNew, blurMatrix[yMatrix][xMatrix]),
							alpha,
							symbol
						)
					end
				end
			end
		end
		
		if y % 2 == 0 then
			os.sleep(0.05)
		end
	end

	return newPicture
end

function image.rotate(picture, angle)
	local radAngle = math.rad(angle)
	local sin, cos = math.sin(radAngle), math.cos(radAngle)
	local pixMap = {}

	local xCenter, yCenter = picture[1] / 2, picture[2] / 2
	local xMin, xMax, yMin, yMax = math.huge, -math.huge, math.huge, -math.huge
	for y = 1, picture[2] do
		for x = 1, picture[1] do
			local xNew = math.round(xCenter + (x - xCenter) * cos - (y - yCenter) * sin)
			local yNew = math.round(yCenter + (y - yCenter) * cos + (x - xCenter) * sin)

			xMin, xMax, yMin, yMax = math.min(xMin, xNew), math.max(xMax, xNew), math.min(yMin, yNew), math.max(yMax, yNew)

			pixMap[yNew] = pixMap[yNew] or {}
			pixMap[yNew][xNew] = {image.get(picture, x, y)}
		end
	end

	local newPicture = image.create(xMax - xMin + 1, yMax - yMin + 1, 0xFF0000, 0x0, 0x0, "#")
	for y in pairs(pixMap) do
		for x in pairs(pixMap[y]) do
			image.set(newPicture, x - xMin + 1, y - yMin + 1, pixMap[y][x][1], pixMap[y][x][2], pixMap[y][x][3], pixMap[y][x][4])
		end
	end

	return newPicture
end

------------------------------------------------------------------------------------------------------------------------

image.loadFormatModule("/lib/FormatModules/OCIF.lua", ".pic")

------------------------------------------------------------------------------------------------------------------------

-- local picture = image.load("/MineOS/Pictures/Block.pic")
-- gpu.setBackground(0x2D2D2D)
-- gpu.fill(1, 1, 160, 50, " ")
-- image.draw(2, 2, image.rotate(picture, 180))

------------------------------------------------------------------------------------------------------------------------

return image











