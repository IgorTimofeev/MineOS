
local color = require("Color")
local filesystem = require("Filesystem")

--------------------------------------------------------------------------------

local image = {}

local OCIFSignature = "OCIF"
local encodingMethodsLoad = {}
local encodingMethodsSave = {}

--------------------------------------------------------------------------------

local function group(picture, compressColors)
	local groupedPicture, x, y, background, foreground = {}, 1, 1

	for i = 3, #picture, 4 do
		if compressColors then
			background, foreground = color.to8Bit(picture[i]), color.to8Bit(picture[i + 1])

			if i % 603 == 0 then
				computer.pullSignal(0)
			end
		else
			background, foreground = picture[i], picture[i + 1]
		end

		groupedPicture[picture[i + 2]] = groupedPicture[picture[i + 2]] or {}
		groupedPicture[picture[i + 2]][picture[i + 3]] = groupedPicture[picture[i + 2]][picture[i + 3]] or {}
		groupedPicture[picture[i + 2]][picture[i + 3]][background] = groupedPicture[picture[i + 2]][picture[i + 3]][background] or {}
		groupedPicture[picture[i + 2]][picture[i + 3]][background][foreground] = groupedPicture[picture[i + 2]][picture[i + 3]][background][foreground] or {}
		groupedPicture[picture[i + 2]][picture[i + 3]][background][foreground][y] = groupedPicture[picture[i + 2]][picture[i + 3]][background][foreground][y] or {}

		table.insert(groupedPicture[picture[i + 2]][picture[i + 3]][background][foreground][y], x)

		x = x + 1

		if x > picture[1] then
			x, y = 1, y + 1
		end
	end

	return groupedPicture
end

encodingMethodsSave[5] = function(file, picture)
	file:writeBytes(
		bit32.rshift(picture[1], 8),
		bit32.band(picture[1], 0xFF)
	)

	file:writeBytes(
		bit32.rshift(picture[2], 8),
		bit32.band(picture[2], 0xFF)
	)

	for i = 3, #picture, 4 do
		file:writeBytes(
			color.to8Bit(picture[i]),
			color.to8Bit(picture[i + 1]),
			math.floor(picture[i + 2] * 255)
		)

		file:write(picture[i + 3])
	end
end

encodingMethodsLoad[5] = function(file, picture)
	picture[1] = file:readBytes(2)
	picture[2] = file:readBytes(2)

	for i = 1, image.getWidth(picture) * image.getHeight(picture) do
		table.insert(picture, color.to24Bit(file:readBytes(1)))
		table.insert(picture, color.to24Bit(file:readBytes(1)))
		table.insert(picture, file:readBytes(1) / 255)
		table.insert(picture, file:readUnicodeChar())
	end
end

local function loadOCIF678(file, picture, is7, is8)
	picture[1] = file:readBytes(1) + is8
	picture[2] = file:readBytes(1) + is8

	local currentAlpha, currentSymbol, currentBackground, currentForeground, currentY

	for alpha = 1, file:readBytes(1) + is7 do
		currentAlpha = file:readBytes(1) / 255
		
		for symbol = 1, file:readBytes(2) + is7 do
			currentSymbol = file:readUnicodeChar()
			
			for background = 1, file:readBytes(1) + is7 do
				currentBackground = color.to24Bit(file:readBytes(1))
				
				for foreground = 1, file:readBytes(1) + is7 do
					currentForeground = color.to24Bit(file:readBytes(1))
					
					for y = 1, file:readBytes(1) + is7 do
						currentY = file:readBytes(1)
						
						for x = 1, file:readBytes(1) + is7 do
							image.set(
								picture,
								file:readBytes(1) + is8,
								currentY + is8,
								currentBackground,
								currentForeground,
								currentAlpha,
								currentSymbol
							)
						end
					end
				end
			end
		end
	end
end

local function saveOCIF678(file, picture, is7, is8)
	local function getGroupSize(t)
		local size = -is7
		
		for key in pairs(t) do
			size = size + 1
		end
    
		return size
	end
	
	-- Grouping picture by it's alphas, symbols and colors
	local groupedPicture = group(picture, true)

	-- Writing 1 byte per image width and height
	file:writeBytes(
		picture[1] - is8,
		picture[2] - is8
	)

	-- Writing 1 byte for alphas array size
	file:writeBytes(getGroupSize(groupedPicture))

	local symbolsSize

	for alpha in pairs(groupedPicture) do
		symbolsSize = getGroupSize(groupedPicture[alpha])

		file:writeBytes(
			-- Writing 1 byte for current alpha value
			math.floor(alpha * 255),
			-- Writing 2 bytes for symbols array size
			bit32.rshift(symbolsSize, 8),
			bit32.band(symbolsSize, 0xFF)
		)

		for symbol in pairs(groupedPicture[alpha]) do
			-- Writing current unicode symbol value
			file:write(symbol)
			-- Writing 1 byte for backgrounds array size
			file:writeBytes(getGroupSize(groupedPicture[alpha][symbol]))

			for background in pairs(groupedPicture[alpha][symbol]) do
				file:writeBytes(
					-- Writing 1 byte for background color value (compressed by color)
					background,
					-- Writing 1 byte for foregrounds array size
					getGroupSize(groupedPicture[alpha][symbol][background])
				)

				for foreground in pairs(groupedPicture[alpha][symbol][background]) do
					file:writeBytes(
						-- Writing 1 byte for foreground color value (compressed by color)
						foreground,
						-- Writing 1 byte for y array size
						getGroupSize(groupedPicture[alpha][symbol][background][foreground])
					)
					
					for y in pairs(groupedPicture[alpha][symbol][background][foreground]) do
						file:writeBytes(
							-- Writing 1 byte for current y value
							y - is8,
							-- Writing 1 byte for x array size
							#groupedPicture[alpha][symbol][background][foreground][y] - is7
						)

						for x = 1, #groupedPicture[alpha][symbol][background][foreground][y] do
							-- Wrting 1 byte for current x value
							file:writeBytes(groupedPicture[alpha][symbol][background][foreground][y][x] - is8)
						end
					end
				end
			end
		end
	end
end

encodingMethodsSave[6] = function(file, picture)
	saveOCIF678(file, picture, 0, 0)
end

encodingMethodsLoad[6] = function(file, picture)
	loadOCIF678(file, picture, 0, 0)
end

encodingMethodsSave[7] = function(file, picture)
	saveOCIF678(file, picture, 1, 0)
end

encodingMethodsLoad[7] = function(file, picture)
	loadOCIF678(file, picture, 1, 0)
end

encodingMethodsSave[8] = function(file, picture)
	saveOCIF678(file, picture, 1, 1)
end

encodingMethodsLoad[8] = function(file, picture)
	loadOCIF678(file, picture, 1, 1)
end

--------------------------------------------------------------------------------

function image.getIndex(x, y, width)
	return 4 * (width * (y - 1) + x) - 1
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
		newPicture[i] = picture[i]
	end

	return newPicture
end

function image.save(path, picture, encodingMethod)
	encodingMethod = encodingMethod or 6
	
	local file, reason = filesystem.open(path, "wb")
	if file then	
		if encodingMethodsSave[encodingMethod] then
			file:write(OCIFSignature, string.char(encodingMethod))

			local result, reason = xpcall(encodingMethodsSave[encodingMethod], debug.traceback, file, picture)
			
			file:close()

			if result then
				return true
			else
				return false, "Failed to save OCIF image: " .. tostring(reason)
			end
		else
			file:close()
			return false, "Failed to save OCIF image: encoding method \"" .. tostring(encodingMethod) .. "\" is not supported"
		end
	else
		return false, "Failed to open file for writing: " .. tostring(reason)
	end
end

function image.load(path)
	local file, reason = filesystem.open(path, "rb")
	if file then
		local readedSignature = file:readString(#OCIFSignature)
		if readedSignature == OCIFSignature then
			local encodingMethod = file:readBytes(1)
			if encodingMethodsLoad[encodingMethod] then
				local picture = {}
				local result, reason = xpcall(encodingMethodsLoad[encodingMethod], debug.traceback, file, picture)
				
				file:close()

				if result then
					return picture
				else
					return false, "Failed to load OCIF image: " .. tostring(reason)
				end
			else
				file:close()
				return false, "Failed to load OCIF image: encoding method \"" .. tostring(encodingMethod) .. "\" is not supported"
			end
		else
			file:close()
			return false, "Failed to load OCIF image: binary signature \"" .. tostring(readedSignature) .. "\" is not valid"
		end
	else
		return false, "Failed to open file \"" .. tostring(path) .. "\" for reading: " .. tostring(reason)
	end
end

-------------------------------------------------------------------------------

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

		if i % 603 == 0 then
			computer.pullSignal(0)
		end
	end

	return table.concat(charArray)
end

function image.fromString(pictureString)
	local picture = {
		tonumber("0x" .. unicode.sub(pictureString, 1, 2)),
		tonumber("0x" .. unicode.sub(pictureString, 3, 4)),
	}

	for i = 5, unicode.len(pictureString), 7 do
		table.insert(picture, color.to24Bit(tonumber("0x" .. unicode.sub(pictureString, i, i + 1))))
		table.insert(picture, color.to24Bit(tonumber("0x" .. unicode.sub(pictureString, i + 2, i + 3))))
		table.insert(picture, tonumber("0x" .. unicode.sub(pictureString, i + 4, i + 5)) / 255)
		table.insert(picture, unicode.sub(pictureString, i + 6, i + 6))
	end

	return picture
end

--------------------------------------------------------------------------------

function image.set(picture, x, y, background, foreground, alpha, symbol)
	local index = image.getIndex(x, y, picture[1])
	picture[index], picture[index + 1], picture[index + 2], picture[index + 3] = background, foreground, alpha, symbol

	return picture
end

function image.get(picture, x, y)
	local index = image.getIndex(x, y, picture[1])
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
		return false, "Failed to crop image: target coordinates are out of source range"
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

function image.rotate(picture, angle)
	local function copyPixel(newPic, oldPic, index)
		table.insert(newPic, oldPic[index])
		table.insert(newPic, oldPic[index + 1])
		table.insert(newPic, oldPic[index + 2])
		table.insert(newPic, oldPic[index + 3])
	end

	if angle == 90 then
		local newPicture = {picture[2], picture[1]}
		
		for i = 1, picture[2] do
			for j = picture[1], 1, -1 do
				copyPixel(newPicture, picture, image.getIndex(i, j, picture[2]))
			end
		end

		return newPicture
	elseif angle == 180 then
		local newPicture = {picture[1], picture[2]}
		
		for j = picture[1], 1, -1 do
			for i = picture[2], 1, -1 do
				copyPixel(newPicture, picture, image.getIndex(i, j, picture[2]))
			end
		end

		return newPicture
	elseif angle == 270 then
		local newPicture = {picture[2], picture[1]}
		
		for i = picture[2], 1, -1 do
			for j = 1, picture[1] do
				copyPixel(newPicture, picture, image.getIndex(i, j, picture[2]))
			end
		end

		return newPicture
	else
		error("Can't rotate image: angle must be 90, 180 or 270 degrees.")
	end
end

function image.hueSaturationBrightness(picture, hue, saturation, brightness)
	local function calculate(c)
		local h, s, b = color.integerToHSB(c)
		
		b = b + brightness; if b < 0 then b = 0 elseif b > 1 then b = 1 end
		s = s + saturation; if s < 0 then s = 0 elseif s > 1 then s = 1 end
		h = h + hue; if h < 0 then h = 0 elseif h > 360 then h = 360 end

		return color.HSBToInteger(h, s, b)
	end

	for i = 3, #picture, 4 do
		picture[i] = calculate(picture[i])
		picture[i + 1] = calculate(picture[i + 1])
	end

	return picture
end

function image.hue(picture, hue)
	return image.hueSaturationBrightness(picture, hue, 0, 0)
end

function image.saturation(picture, saturation)
	return image.hueSaturationBrightness(picture, 0, saturation, 0)
end

function image.brightness(picture, brightness)
	return image.hueSaturationBrightness(picture, 0, 0, brightness)
end

function image.blackAndWhite(picture)
	return image.hueSaturationBrightness(picture, 0, -1, 0)
end

function image.colorBalance(picture, r, g, b)
	local function calculate(c)
		local rr, gg, bb = color.integerToRGB(c)

		rr = rr + r
		gg = gg + g
		bb = bb + b
		
		if rr < 0 then rr = 0 elseif rr > 255 then rr = 255 end
		if gg < 0 then gg = 0 elseif gg > 255 then gg = 255 end
		if bb < 0 then bb = 0 elseif bb > 255 then bb = 255 end

		return color.RGBToInteger(rr, gg, bb)
	end

	for i = 3, #picture, 4 do
		picture[i] = calculate(picture[i])
		picture[i + 1] = calculate(picture[i + 1])
	end

	return picture
end

function image.invert(picture)
	for i = 3, #picture, 4 do
		picture[i] = 0xffffff - picture[i]
		picture[i + 1] = 0xffffff - picture[i + 1]
	end

	return picture 
end

function image.getGaussianBlurKernel(radius, weight)
	local size, index, sum, weightSquared2, value =
		radius * 2 + 1,
		2,
		0,
		2 * weight * weight

	local kernel, constant =
		{size},
		1 / (math.pi * weightSquared2)
	
	-- Filling convolution matrix
	for y = -radius, radius do
		for x = -radius, radius do
			value = constant * math.exp(-((y * y) + (x * x)) / weightSquared2);
			kernel[index] = value
			sum = sum + value;

			index = index + 1
		end
	end

	index = 2

	for y = 1, size do
		for x = 1, size do
			kernel[index] = kernel[index] * 1 / sum;

			index = index + 1
		end
	end

    return kernel;
end

function image.convolve(picture, kernel)
	-- Processing
	local
		pictureWidth,
		pictureHeight,
		kernelSize,
		pictureIndex,
		kernelIndex,
		kernelValue,
		rAcc,
		gAcc,
		bAcc,
		r,
		g,
		b,
		x,
		y = picture[1], picture[2], kernel[1], 3

	local newPicture, kernelRadius =
		{ pictureWidth, pictureHeight },
		math.floor(kernelSize / 2)

	for pictureY = 1, pictureHeight do
		for pictureX = 1, pictureWidth do
			rAcc, gAcc, bAcc, kernelIndex = 0, 0, 0, 2

			-- Summing
			for kernelY = -kernelRadius, kernelRadius do
				y = pictureY + kernelY

				if y >= 1 and y <= pictureHeight then
					for kernelX = -kernelRadius, kernelRadius do
						x = pictureX + kernelX

						if x >= 1 and x <= pictureWidth then
							kernelValue = kernel[kernelIndex]
							r, g, b = color.integerToRGB(picture[4 * (pictureWidth * (y - 1) + x) - 1])

							rAcc, gAcc, bAcc = rAcc + r * kernelValue, gAcc + g * kernelValue, bAcc + b * kernelValue
						end

						kernelIndex = kernelIndex + 1
					end
				else
					kernelIndex = kernelIndex + kernelSize
				end
			end

			-- Setting pixel values on new picture
			if rAcc > 255 then
				rAcc =  255
			elseif rAcc < 0 then
				rAcc = 0
			else
				rAcc = rAcc - rAcc % 1
			end

			if gAcc > 255 then
				gAcc =  255
			elseif gAcc < 0 then
				gAcc = 0
			else
				gAcc = gAcc - gAcc % 1
			end

			if bAcc > 255 then
				bAcc =  255
			elseif bAcc < 0 then
				bAcc = 0
			else
				bAcc = bAcc - bAcc % 1
			end

			newPicture[pictureIndex] = color.RGBToInteger(rAcc, gAcc, bAcc)
			pictureIndex = pictureIndex + 1

			newPicture[pictureIndex] = 0x0
			pictureIndex = pictureIndex + 1

			newPicture[pictureIndex] = picture[pictureIndex]
			pictureIndex = pictureIndex + 1

			newPicture[pictureIndex] = " "
			pictureIndex = pictureIndex + 1
		end
	end

	return newPicture
end

--------------------------------------------------------------------------------

return image
