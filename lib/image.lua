
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
			
			if not (symbol == " " and alpha == 0xFF) then
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

								if alpha > 0x0 then
									_, _, gpuGetBackground = gpu.get(imageX, imageY)
									
									if alpha == 0xFF then
										currentBackground = gpuGetBackground
										gpu.setBackground(currentBackground)
									else
										currentBackground = color.blend(gpuGetBackground, background, alpha / 0xFF)
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
	if fs.exists(path) then
		return loadOrSave("load", path)
	else
		return image.fromString("0101FFE300x")
	end
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
		table.insert(charArray, string.format("%02X", picture[i + 2]))
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

-- clearAndDraw(image.load("/braille.pic"))

-- clearAndDraw(image.fromString([[4510AA0000 AA0000MAA0000iAA0000nAA0000eAA0000OAA0000SAA0000 AA0000 AA0000 AA0000 AA0000 AA0000 AA0000 AA0000 AA0000 AAAB00▄AB0000 AB0000 ABAA00▄AA0000 ABAA00▄ABAA00▄AB0000 AB0000 AB0000 AC0000 ABAC00▄AB0000 AB0000 AB0000 AB0000 AB0000 AB0000 AB0000 AB0000 ABAA00▄AA0000 AA0000 AA0000 AA0000 AA0000 AA0000 AA0000 AA0000 AA0000 AA0000 AA0000 AA0000 AA0000 ABAA00▄AA0000 AA0000 AA0000 AA0000 AA0000 AA0000 AA0000 AA0000 AA0000 AA0000 AA0000 AA0000 AA0000 AA0000 AA0000 AA0000 AA0000 AA0000 280000 290000 280000 2A0000 2A0000 2A0000 292800▄290000 290000 FFD500▀FFD500▀FFD500▀290000 2A5300▄530000 290000 290000 290000 536100▄610000 616600▄2A5300▀555300▀2A5300▀540000 540000 7E0000 D70000 D70000 D70000 545500▄545300▄535400▄002200▀000000 002200▀530000 2A0000 292A00▄292A00▄290000 290000 290000 292800▄290000 FF2900▗290000 FF0000 280000 280000 290000 B10000 FB0000 000000 290000 290000 290000 D50000 D55500▄D50000 280000 290000 280000 28D500▃D50000 D50000 280000 280000 280000 280000 280000 282900▄2A0000 2A0000 2A0000 290000 290000 2A0000 2AFF00▒29FF00▒29FF00▒2A5300▄540000 2A5300▄290000 290000 290000 920000 920000 920000 532A00▄530000 532A00▄537E00▄532A00▄542A00▄48D700▀48D700▀48D700▀819800▄7F7E00▄535400▄000000 00E300▀000000 530000 545300▄2A0000 D50000 D50000 D5FF00▀290000 290000 290000 FF2900▀290000 290000 280000 282900▄280000 B10000 FB0000 000000 290000 290000 290000 AA5500▝360000 553600▛290000 290000 290000 D70000 D70000 D70000 282900▄290000 290000 280000 282900▄290000 280000 290000 290000 290000 2A0000 2A0000 2A0000 292A00▄530000 555400▄292A00▄557E00▄7F7E00▄610000 669200▄920000 929300▄939800▄929800▄979800▄980000 929800▄555400▄530000 540000 555400▄AA9800▄80AB00▄550000 555400▄7E5500▄540000 545500▄2A0000 2A2900▄532A00▄2A0000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 280000 282900▄290000 290000 290000 290000 290000 282900▄290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 280000 290000 280000 280000 290000 290000 290000 2A0000 532A00▄FFD800┌FF0000─FFD800┐290000 550000 7E0000 610000 920000 920000 930000 980000 C30000 AC7F00▀AC7F00▀AC7F00▀C3C800▄C3C800▄980000 55FD00▄FD0000 7FFD00▄7E0000 7F0000 AA0000 530000 290000 290000 535400▄545300▄2A0000 060000 060000 060000 292A00▄290000 290000 290000 290000 290000 290000 290000 290000 CFD500▄787200▄484200▄290000 290000 290000 2A0000 FF0000 FF2A00▄290000 290000 290000 295400▄2A5400▀2A5400▀292A00▄290000 290000 280000 290000 290000 29A400\2A0000 29A400/292A00▄530000 2A0000 FF0000│D80000 FF0000│292A00▄7E0000 615400▄61D700▄55D700▄55D700▄939200▄C30000 C30000 818000▄818000▄815300▄AB0000 AB0000 C80000 F70000 D5D600▀D5D600▀7F7E00▄7F8000▄7F9800▄530000 29A700▀290000 545300▄532A00▄545300▄063D00C063D00i063D00t2A0000 2A0000 2A0000 585300▄2C5300▄2A0000 290000 290000 290000 675500▄3C3600▄0C0B00▄290000 290000 290000 F60000 EE2A00▀EE2A00▀290000 2A0000 290000 2A0000 A44300▄433D00▄2A2900▄292A00▄290000 280000 290000 290000 290000 290000 292A00▄2A2900▄533600▄2A0000 2A0000 550000 290000 2A0000 545300▄532900▄552A00▄7E5300▄926100▄920000 980000 C39800▄C30000 C80000 C8AA00▄C80000 ABAA00▄C8C300▄C39800▄985400▄290000 2A5400▄555300▄7F5500▄540000 988000▄7F8000▄2A5400▄2A2900▄532A00▄2A0000 295300▄545300▄555400▄530000 2A0000 2A0000 530000 2A0000 290000 292A00▄290000 290000 290000 290000 290000 290000 292A00▄290000 290000 290000 290000 290000 292A00▄290000 2A0000 2A0000 292A00▄290000 2A0000 280000 2A0000 2A0000 00D600▀00D600▀00D600▀2A2900▄540000 533600▄530000 810000 810000 290000 290000 280000 290000 291F00▙296100▄292A00▄2A0000 2A0000 00FF00▀00FF00▄00FF00▄980000 989300▄2A5300▄2A3C00▄3C0C00▄2A2800▄615300▄2A0000 292A00▄D60000 D60000 D60000 81AA00▄7E5500▄292A00▄A40000 A40000 A40000 2A0000 542A00▄557E00▄ADFF00uADFF00eAD0000 530000 540000 2A0000 2A2900▄294800╵290000 290000 290000 290000 29A400▄A40000 A40000 290000 290000 290000 2A2900▄290000 290000 2A2900▄292A00▄290000 290000 2A0000 2A0000 000000 00F200р00F200к290000 540000 540000 FF0000 FF0000 AC0000 290000 290000 2A0000 291500▟150000 281500▙292A00▄532800▄2A6600▄FF0000▄00FF00▄00FF00▄AA0000 980000 619200▄0C0000 370700▄060000 280000 362A00▄292A00▄53FF00.FF0000 FF7300▄542A00▄98AA00▄7E0000 800000 D75400▀800000 545500▄2A5300▄530000 FF0000 FF0000 FF0000 2A5400▄2A5300▄532A00▄2A5300▄2A0000 294800╹290000 2A2900▄290000 430000 43FF00d43FF00i290000 290000 2A0000 290000 29D700d29D700t290000 290000 2A2900▄290000 2A0000 290000 2A0000 2A0000 290000 290000 530000 540000 290000 7F0000 540000 292A00▄280000 280000 292800▄2A0000 295300▄616600▄C30000 C30000 989300▄980000 C80000 C80000 980000 979300▄C39200▄920000 610000 2A5C00▄292A00▄282900▄290000 282900▄545500▄532A00▄555300▄2A5400▄7F5500▄2A5500▄2A0000 290000 550000 535400▄2A0000 545300▄540000 555400▄545500▄545300▄290000 2A2900▄2A0000 292A00▄290000 290000 290000 292A00▄290000 290000 290000 290000 290000 290000 2A2900▄2A2900▄2A2900▄290000 282900▄2A0000 290000 2A0000 2A0000 290000 290000 290000 540000 292A00▄7F0000 550000 545500▄530000 669200▄7E7F00▄7F0000 980000 980000 980000 980000 930000 980000 AB0000 AB0000 980000 920000 920000 920000 920000 920000 619200▄5C0000 875B00▄5B0000 290000 2A2900▄2A0000 555300▄980000 290000 535400▄292A00▄2A2900▄2A2900▄545300▄540000 530000 545300▄2A0000 530000 545300▄530000 2A0000 290000 2A2900▄2A0000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 290000 280000 290000 290000 290000 2A2900▄292800▄290000 290000 545500▄2A0000 550000 555400▄7E0000 2A0000 666100▄920000 920000 920000 939200▄930000 930000 920000 939200▄AB0000 AC0000 AA0000 928D00▄920000 920000 920000 928D00▄8D6100▄8D5B00▄565B00▄5B5C00▄293000▄282900▄292800▄530000 545300▄980000 7F5500▄535400▄2A0000 2A0000 290000 540000 545500▄532A00▄2A5300▄2A0000 532A00▄530000 2A5300▄292A00▄290000 290000 2A0000 290000 290000 290000 2A2900▄2A2900▄2A2900▄280000 290000 290000 292800▄290000 280000 290000 290000 290000 2A0000 280000 290000 290000 550000 2A0000 530000 550000 550000 556100▄530000 610000 610000 928D00▄928D00▄920000 926600▄920000 615C00▄986100▄989200▄928D00▄615C00▄610000 8D0000 8D0000 8D0000 610000 5C5B00▄5B0000 5B5600▄300000 290000 282900▄290000 557E00▄540000 557E00▄7F7E00▄545300▄2A2900▄530000 292A00▄532900▄545500▄2A5300▄545300▄2A0000 2A0000 532A00▄2A5300▄290000 290000 292800▄290000 290000 280000 280000 292800▄290000 2A2900▄290000 290000 290000 290000 280000 282900▄292800▄290000 290000 290000 280000 2A0000 540000 540000 530000 7F7E00▄7E0000 530000 612A00▄2A5300▄610000 610000 928D00▄920000 920000 669200▄2A5300▄292A00▄2A0000 295300▄5C8D00▄8D0000 8D0000 8D0000 610000 5C6100▄2A0000 300000 300000 290000 290000 282900▄290000 290000 7E5500▄7F7E00▄540000 532A00▄545500▄535400▄290000 2A5300▄290000 532A00▄530000 540000 530000 530000 2A0000 532A00▄2A5300▄290000 290000 282900▄290000 280000 280000 280000 280000 292800▄292A00▄290000 282900▄280000 280000 282900▄280000 290000 290000 282900▄2A0000 545300▄545300▄530000 530000 555400▄535400▄290000 532A00▄530000 615C00▄610000 928D00▄930000 930000 7F6600▄7E9300▄53D600╬61D600╬8DD600╬8D9200▄8D0000 610000 29F800h29F800l29FE00a302900▄300000 280000 FF0000 FF0000 FF0000 290000 532A00▄530000 54D500▒2AD500▒55D500▒7E7F00▄547E00▄290000 535400▄290000 290000 2A5300▄540000 547E00▄530000 2A5300▄290000 2A0000 290000 290000 292800▄290000 292800▄290000 290000 280000 292800▄290000 290000 280000 290000 290000 280000 290000 290000 290000 2A2900▄530000 530000 540000 540000 2A5300▄7E5500▄615300▄292A00▄536100▄530000 5C0000 2A2900▄2A2900▄290000 297E00▟615500▄935500▄935500▄7E0000 7E0000 7E5500▄7E0000 29F800n290000 290000 7E0000 7E0000 557E00▄29FF00▀29FF00▀29FF00▀7E0000 7E0000 800000 7F0000 AB5300▄7E0000 7F7E00▄7F8100▙557F00▄2A2900▄540000 292A00▄290000 2A0000 530000 540000 535400▄2A0000 292A00▄290000 290000 290000 280000 290000 290000 290000 282900▄290000 290000 290000 ]]))
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











