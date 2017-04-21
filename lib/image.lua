
-------------------------------------------------- Libraries --------------------------------------------------

local colorlib = require("colorlib")
local unicode = require("unicode")
local gpu = require("component").gpu

-------------------------------------------------- Constants --------------------------------------------------

local image = {}
image.formatModules = {}

-------------------------------------------------- Low-level methods --------------------------------------------------

local function compressionYield(iteration)
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
			background, foreground = colorlib.convert24BitTo8Bit(picture[i]), colorlib.convert24BitTo8Bit(picture[i + 1])
			compressionYield(i)
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

	for alpha in pairs(groupedPicture) do
		for symbol in pairs(groupedPicture[alpha]) do
			for background in pairs(groupedPicture[alpha][symbol]) do
				gpu.setBackground(background)
				for foreground in pairs(groupedPicture[alpha][symbol][background]) do
					gpu.setForeground(foreground)
					for yPos in pairs(groupedPicture[alpha][symbol][background][foreground]) do
						for xPos = 1, #groupedPicture[alpha][symbol][background][foreground][yPos] do
							if alpha > 0x0 then
								local oldBackground = background
								local _, _, gpuGetBackground = gpu.get(x, y)
								
								gpu.setBackground(colorlib.alphaBlend(gpuGetBackground, background, alpha / 0xFF))
								gpu.set(x + groupedPicture[alpha][symbol][background][foreground][yPos][xPos] - 1, y + yPos - 1, symbol)
								gpu.setBackground(oldBackground)
							else
								gpu.set(x + groupedPicture[alpha][symbol][background][foreground][yPos][xPos] - 1, y + yPos - 1, symbol)
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

local function loadOrSave(methodName, path, picture, encodingMethod)
	local fileExtension = getFileExtension(path)
	if image.formatModules[fileExtension] then
		return image.formatModules[fileExtension][methodName](path, picture, encodingMethod)
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
		table.insert(charArray, string.format("%02X", colorlib.convert24BitTo8Bit(picture[i])))
		table.insert(charArray, string.format("%02X", colorlib.convert24BitTo8Bit(picture[i])))
		table.insert(charArray, string.format("%02X", picture[i + 2]))
		table.insert(charArray, picture[i + 3])

		compressionYield(i)
	end

	return table.concat(charArray)
end

function image.fromString(pictureString)
	local picture = {
		tonumber("0x" .. unicode.sub(pictureString, 1, 2)),
		tonumber("0x" .. unicode.sub(pictureString, 3, 4))
	}

	for i = 5, unicode.len(pictureString), 7 do
		table.insert(picture, colorlib.convert8BitTo24Bit(tonumber("0x" .. unicode.sub(pictureString, i, i + 1))))
		table.insert(picture, colorlib.convert8BitTo24Bit(tonumber("0x" .. unicode.sub(pictureString, i + 2, i + 3))))
		table.insert(picture, tonumber("0x" .. unicode.sub(pictureString, i + 4, i + 5)))
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

------------------------------------------------------------------------------------------------------------------------

image.loadFormatModule("/lib/ImageFormatModules/OCIF.lua", ".pic")

------------------------------------------------------------------------------------------------------------------------

-- local function loadImageInOldFormat(path)
-- 	local picture = require("image").load(path)
-- 	table.insert(picture, 1, picture.height)
-- 	table.insert(picture, 1, picture.width)
-- 	picture.width, picture.height = nil, nil
-- 	return picture
-- end

-- local fs = require("filesystem")
-- local function recursiveConversion(path, targetPath)
-- 	for file in fs.list(path) do
-- 		if fs.isDirectory(path .. file) then
-- 			if not string.find(path .. file, "ConvertedPics") then
-- 				recursiveConversion(path .. file, targetPath)
-- 			end
-- 		else
-- 			local fileExtension = getFileExtension(path .. file)
-- 			if fileExtension == ".pic" then
-- 				print("Загружаю пикчу в старом формате:", path .. file)
-- 				local oldPicture = loadImageInOldFormat(path .. file)

-- 				-- local newPath = string.gsub(path, ".app", "")
-- 				-- print("Сейвлю пикчу в новом:", targetPath .. newPath .. file)
-- 				-- fs.makeDirectory(targetPath .. newPath)
-- 				-- image.save(targetPath .. newPath .. file, oldPicture, 6)
-- 				-- print("---------------")

-- 				print("Пересохраняю ее в новом формате")
-- 				image.save(path .. file, oldPicture, 6)
-- 			end
-- 		end
-- 	end
-- end

-- recursiveConversion("/MineOS/", "/ConvertedPics/")

-- local function clearAndDraw(picture)
-- 	gpu.setBackground(0x2D2D2D)
-- 	gpu.setForeground(0xFFFFFF)
-- 	gpu.fill(1, 1, 160, 50, " ")

-- 	image.draw(1, 1, picture)
-- end

-- clearAndDraw(image.load("/MineOS/System/OS/Icons/Love.pic"))

-- local w, h = 2, 2
-- local picture = image.create(w, h, 0xFF0000, 0xFFFFFF, 0x0, "Q")
-- local picture = loadImageInOldFormat("/MineOS/System/OS/Icons/Love.pic")

-- print("Saving as old...")
-- require("image").save("/testPicOld.pic", picture, 4)

-- print("Processing image...")
-- local newPicture = image.transform(picture, 100, 50)
-- local newPicture = image.flipVertically(picture)
-- local newPicture = image.crop(picture, 4, 4, 20, 10)
-- local newPicture = image.expand(picture, 1, 1, 1, 1, 0xFFFFFF, 0x000000, 0x0, "#")
-- clearAndDraw(newPicture)

-- print("ToStringing...")
-- local pictureString = image.toString(picture)
-- print(pictureString)

-- print("FromStringing...")
-- local fromStringPicture = image.fromString("0804000000 000000 000000 000000 000000 000000 000000 0000FF 000000 0000FF 0000FF 0000FF 0000FF 0000FF 000000 0000FF 000000 000000 000000 000000 000000 000000 000000 0000FF 000000 0000FF 0000FF 0000FF 0000FF 0000FF 000000 0000FF ")
-- clearAndDraw(fromStringPicture)

-- print("Creating new...")
-- image.save("/testPic.pic", picture, 6)

-- print("Loading new...")
-- local loadedPicture = image.load("/testPic.pic")
-- print("Drawing new...")
-- clearAndDraw(loadedPicture)

------------------------------------------------------------------------------------------------------------------------

return image











