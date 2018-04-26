
local component = require("component")
local unicode = require("unicode")
local color = require("color")
local image = require("image")

--------------------------------------------------------------------------------

local bufferWidth, bufferHeight
local currentFrameBackgrounds, currentFrameForegrounds, currentFrameSymbols, newFrameBackgrounds, newFrameForegrounds, newFrameSymbols
local drawLimitX1, drawLimitX2, drawLimitY1, drawLimitY2
local GPUProxy, GPUProxyGetResolution, GPUProxySetResolution, GPUProxyBind, GPUProxyGetBackground, GPUProxyGetForeground, GPUProxySetBackground, GPUProxySetForeground, GPUProxyGet, GPUProxySet, GPUProxyFill

local mathCeil, mathFloor, mathModf, mathAbs = math.ceil, math.floor, math.modf, math.abs
local tableInsert, tableConcat = table.insert, table.concat
local colorBlend = color.blend
local unicodeLen, unicodeSub = unicode.len, unicode.sub

--------------------------------------------------------------------------------

local function getCoordinates(index)
	local integer, fractional = mathModf(index / bufferWidth)
	return mathCeil(fractional * bufferWidth), integer + 1
end

local function getIndex(x, y)
	return bufferWidth * (y - 1) + x
end

local function getCurrentFrameTables()
	return currentFrameBackgrounds, currentFrameForegrounds, currentFrameSymbols
end

local function getNewFrameTables()
	return newFrameBackgrounds, newFrameForegrounds, newFrameSymbols
end

--------------------------------------------------------------------------------

local function setDrawLimit(x1, y1, x2, y2)
	drawLimitX1, drawLimitY1, drawLimitX2, drawLimitY2 = x1, y1, x2, y2
end

local function resetDrawLimit()
	drawLimitX1, drawLimitY1, drawLimitX2, drawLimitY2 = 1, 1, bufferWidth, bufferHeight
end

local function getDrawLimit()
	return drawLimitX1, drawLimitY1, drawLimitX2, drawLimitY2
end

--------------------------------------------------------------------------------

local function flush(width, height)
	if not width or not height then
		width, height = GPUProxyGetResolution()
	end

	currentFrameBackgrounds, currentFrameForegrounds, currentFrameSymbols, newFrameBackgrounds, newFrameForegrounds, newFrameSymbols = {}, {}, {}, {}, {}, {}
	bufferWidth = width
	bufferHeight = height
	resetDrawLimit()

	for y = 1, bufferHeight do
		for x = 1, bufferWidth do
			tableInsert(currentFrameBackgrounds, 0x010101)
			tableInsert(currentFrameForegrounds, 0xFEFEFE)
			tableInsert(currentFrameSymbols, " ")

			tableInsert(newFrameBackgrounds, 0x010101)
			tableInsert(newFrameForegrounds, 0xFEFEFE)
			tableInsert(newFrameSymbols, " ")
		end
	end
end

local function setResolution(width, height)
	GPUProxySetResolution(width, height)
	flush(width, height)
end

local function getResolution()
	return bufferWidth, bufferHeight
end

local function getWidth()
	return bufferWidth
end

local function getHeight()
	return bufferHeight
end

local function bindScreen(...)
	GPUProxyBind(...)
	flush(GPUProxyGetResolution())
end

local function getGPUProxy()
	return GPUProxy
end

local function updateGPUProxyMethods()
	GPUProxyGet = GPUProxy.get
	GPUProxyGetResolution = GPUProxy.getResolution
	GPUProxyGetBackground = GPUProxy.getBackground
	GPUProxyGetForeground = GPUProxy.getForeground

	GPUProxySet = GPUProxy.set
	GPUProxySetResolution = GPUProxy.setResolution
	GPUProxySetBackground = GPUProxy.setBackground
	GPUProxySetForeground = GPUProxy.setForeground

	GPUProxyBind = GPUProxy.bind
	GPUProxyFill = GPUProxy.fill
end

local function bindGPU(address)
	GPUProxy = component.proxy(address)
	updateGPUProxyMethods()
	flush(GPUProxyGetResolution())
end

--------------------------------------------------------------------------------

local function rawSet(index, background, foreground, symbol)
	newFrameBackgrounds[index], newFrameForegrounds[index], newFrameSymbols[index] = background, foreground, symbol
end

local function rawGet(index)
	return newFrameBackgrounds[index], newFrameForegrounds[index], newFrameSymbols[index]
end

local function get(x, y)
	if x >= 1 and y >= 1 and x <= bufferWidth and y <= bufferHeight then
		local index = getIndex(x, y)
		return newFrameBackgrounds[index], newFrameForegrounds[index], newFrameSymbols[index]
	else
		return 0x000000, 0x000000, " "
	end
end

local function set(x, y, background, foreground, symbol)
	if x >= drawLimitX1 and y >= drawLimitY1 and x <= drawLimitX2 and y <= drawLimitY2 then
		local index = getIndex(x, y)
		newFrameBackgrounds[index], newFrameForegrounds[index], newFrameSymbols[index] = background, foreground, symbol
	end
end

local function square(x, y, width, height, background, foreground, symbol, transparency) 
	local index, indexStepOnReachOfSquareWidth = getIndex(x, y), bufferWidth - width
	for j = y, y + height - 1 do
		if j >= drawLimitY1 and j <= drawLimitY2 then
			for i = x, x + width - 1 do
				if i >= drawLimitX1 and i <= drawLimitX2 then
					if transparency then
						newFrameBackgrounds[index], newFrameForegrounds[index] =
							colorBlend(newFrameBackgrounds[index], background, transparency),
							colorBlend(newFrameForegrounds[index], background, transparency)
					else
						newFrameBackgrounds[index], newFrameForegrounds[index], newFrameSymbols[index] = background, foreground, symbol
					end
				end

				index = index + 1
			end

			index = index + indexStepOnReachOfSquareWidth
		else
			index = index + bufferWidth
		end
	end
end

local function clear(color, transparency)
	square(1, 1, bufferWidth, bufferHeight, color or 0x0, 0x000000, " ", transparency)
end

local function copy(x, y, width, height)
	local copyArray, index = { width, height }

	for j = y, y + height - 1 do
		for i = x, x + width - 1 do
			if i >= 1 and j >= 1 and i <= bufferWidth and j <= bufferHeight then
				index = getIndex(i, j)
				tableInsert(copyArray, newFrameBackgrounds[index])
				tableInsert(copyArray, newFrameForegrounds[index])
				tableInsert(copyArray, newFrameSymbols[index])
			else
				tableInsert(copyArray, 0x0)
				tableInsert(copyArray, 0x0)
				tableInsert(copyArray, " ")
			end
		end
	end

	return copyArray
end

local function paste(xStart, yStart, picture)
	local imageWidth = picture[1]
	local bufferIndex, imageIndex, bufferIndexStepOnReachOfImageWidth = getIndex(xStart, yStart), 3, bufferWidth - imageWidth

	for y = yStart, yStart + picture[2] - 1 do
		if y >= drawLimitY1 and y <= drawLimitY2 then
			for x = xStart, xStart + imageWidth - 1 do
				if x >= drawLimitX1 and x <= drawLimitX2 then
					newFrameBackgrounds[bufferIndex] = picture[imageIndex]
					newFrameForegrounds[bufferIndex] = picture[imageIndex + 1]
					newFrameSymbols[bufferIndex] = picture[imageIndex + 2]
				end

				bufferIndex, imageIndex = bufferIndex + 1, imageIndex + 3
			end

			bufferIndex = bufferIndex + bufferIndexStepOnReachOfImageWidth
		else
			bufferIndex, imageIndex = bufferIndex + bufferWidth, imageIndex + imageWidth * 3
		end
	end
end

local function rasterizeLine(x1, y1, x2, y2, method)
	local inLoopValueFrom, inLoopValueTo, outLoopValueFrom, outLoopValueTo, isReversed, inLoopValueDelta, outLoopValueDelta = x1, x2, y1, y2, false, mathAbs(x2 - x1), mathAbs(y2 - y1)
	if inLoopValueDelta < outLoopValueDelta then
		inLoopValueFrom, inLoopValueTo, outLoopValueFrom, outLoopValueTo, isReversed, inLoopValueDelta, outLoopValueDelta = y1, y2, x1, x2, true, outLoopValueDelta, inLoopValueDelta
	end

	if outLoopValueFrom > outLoopValueTo then
		outLoopValueFrom, outLoopValueTo = outLoopValueTo, outLoopValueFrom
		inLoopValueFrom, inLoopValueTo = inLoopValueTo, inLoopValueFrom
	end

	local outLoopValue, outLoopValueCounter, outLoopValueTriggerIncrement = outLoopValueFrom, 1, inLoopValueDelta / outLoopValueDelta
	local outLoopValueTrigger = outLoopValueTriggerIncrement
	for inLoopValue = inLoopValueFrom, inLoopValueTo, inLoopValueFrom < inLoopValueTo and 1 or -1 do
		if isReversed then
			method(outLoopValue, inLoopValue)
		else
			method(inLoopValue, outLoopValue)
		end

		outLoopValueCounter = outLoopValueCounter + 1
		if outLoopValueCounter > outLoopValueTrigger then
			outLoopValue, outLoopValueTrigger = outLoopValue + 1, outLoopValueTrigger + outLoopValueTriggerIncrement
		end
	end
end

local function rasterizeEllipse(centerX, centerY, radiusX, radiusY, method)
	local function rasterizeEllipsePoints(XP, YP)
		method(centerX + XP, centerY + YP)
		method(centerX - XP, centerY + YP)
		method(centerX - XP, centerY - YP)
		method(centerX + XP, centerY - YP) 
	end

	local x, y, changeX, changeY, ellipseError, twoASquare, twoBSquare = radiusX, 0, radiusY * radiusY * (1 - 2 * radiusX), radiusX * radiusX, 0, 2 * radiusX * radiusX, 2 * radiusY * radiusY
	local stoppingX, stoppingY = twoBSquare * radiusX, 0

	while stoppingX >= stoppingY do
		rasterizeEllipsePoints(x, y)
		
		y, stoppingY, ellipseError = y + 1, stoppingY + twoASquare, ellipseError + changeY
		changeY = changeY + twoASquare

		if (2 * ellipseError + changeX) > 0 then
			x, stoppingX, ellipseError = x - 1, stoppingX - twoBSquare, ellipseError + changeX
			changeX = changeX + twoBSquare
		end
	end

	x, y, changeX, changeY, ellipseError, stoppingX, stoppingY = 0, radiusY, radiusY * radiusY, radiusX * radiusX * (1 - 2 * radiusY), 0, 0, twoASquare * radiusY

	while stoppingX <= stoppingY do 
		rasterizeEllipsePoints(x, y)
		
		x, stoppingX, ellipseError = x + 1, stoppingX + twoBSquare, ellipseError + changeX
		changeX = changeX + twoBSquare
		
		if (2 * ellipseError + changeY) > 0 then
			y, stoppingY, ellipseError = y - 1, stoppingY - twoASquare, ellipseError + changeY
			changeY = changeY + twoASquare
		end
	end
end

local function line(x1, y1, x2, y2, background, foreground, symbol)
	rasterizeLine(x1, y1, x2, y2, function(x, y)
		set(x, y, background, foreground, symbol)
	end)
end

local function text(x, y, textColor, data, transparency)
	if y >= drawLimitY1 and y <= drawLimitY2 then
		local charIndex, bufferIndex = 1, getIndex(x, y)
		
		for charIndex = 1, unicodeLen(data) do
			if x >= drawLimitX1 and x <= drawLimitX2 then
				if transparency then
					newFrameForegrounds[bufferIndex] = colorBlend(newFrameBackgrounds[bufferIndex], textColor, transparency)
				else
					newFrameForegrounds[bufferIndex] = textColor
				end

				newFrameSymbols[bufferIndex] = unicodeSub(data, charIndex, charIndex)
			end

			x, bufferIndex = x + 1, bufferIndex + 1
		end
	end
end

local function formattedText(x, y, data)
	if y >= drawLimitY1 and y <= drawLimitY2 then
		local charIndex, bufferIndex, textColor, char, number = 1, getIndex(x, y), 0xFFFFFF
		
		while charIndex <= unicodeLen(text) do
			if x >= drawLimitX1 and x <= drawLimitX2 then
				char = unicodeSub(data, charIndex, charIndex)
				if char == "#" then
					number = tonumber("0x" .. unicodeSub(data, charIndex + 1, charIndex + 6))
					if number then
						textColor, charIndex = number, charIndex + 7
					else
						newFrameForegrounds[bufferIndex], newFrameSymbols[bufferIndex], x, charIndex, bufferIndex = textColor, char, x + 1, charIndex + 1, bufferIndex + 1
					end
				else
					newFrameForegrounds[bufferIndex], newFrameSymbols[bufferIndex], x, charIndex, bufferIndex = textColor, char, x + 1, charIndex + 1, bufferIndex + 1
				end
			else
				x, charIndex, bufferIndex = x + 1, charIndex + 1, bufferIndex + 1
			end
		end
	end
end

local function image(xStart, yStart, picture, blendForeground)
	local imageWidth = picture[1]
	local bufferIndex, imageIndex, bufferIndexStepOnReachOfImageWidth, imageIndexPlus1, imageIndexPlus2, imageIndexPlus3 = getIndex(xStart, yStart), 3, bufferWidth - imageWidth

	for y = yStart, yStart + picture[2] - 1 do
		if y >= drawLimitY1 and y <= drawLimitY2 then
			for x = xStart, xStart + imageWidth - 1 do
				if x >= drawLimitX1 and x <= drawLimitX2 then
					imageIndexPlus1, imageIndexPlus2, imageIndexPlus3 = imageIndex + 1, imageIndex + 2, imageIndex + 3
					
					if picture[imageIndexPlus2] == 0 then
						newFrameBackgrounds[bufferIndex], newFrameForegrounds[bufferIndex] = picture[imageIndex], picture[imageIndexPlus1]
					elseif picture[imageIndexPlus2] > 0 and picture[imageIndexPlus2] < 1 then
						newFrameBackgrounds[bufferIndex] = colorBlend(newFrameBackgrounds[bufferIndex], picture[imageIndex], picture[imageIndexPlus2])
						
						if blendForeground then
							newFrameForegrounds[bufferIndex] = colorBlend(newFrameForegrounds[bufferIndex], picture[imageIndexPlus1], picture[imageIndexPlus2])
						else
							newFrameForegrounds[bufferIndex] = picture[imageIndexPlus1]
						end
					elseif picture[imageIndexPlus2] == 1 and picture[imageIndexPlus3] ~= " " then
						newFrameForegrounds[bufferIndex] = picture[imageIndexPlus1]
					end

					newFrameSymbols[bufferIndex] = picture[imageIndexPlus3]
				end

				bufferIndex, imageIndex = bufferIndex + 1, imageIndex + 4
			end

			bufferIndex = bufferIndex + bufferIndexStepOnReachOfImageWidth
		else
			bufferIndex, imageIndex = bufferIndex + bufferWidth, imageIndex + imageWidth * 4
		end
	end
end

local function frame(x, y, width, height, color)
	local stringUp, stringDown, x2 = "┌" .. string.rep("─", width - 2) .. "┐", "└" .. string.rep("─", width - 2) .. "┘", x + width - 1
	
	text(x, y, color, stringUp); y = y + 1
	for i = 1, height - 2 do
		text(x, y, color, "│")
		text(x2, y, color, "│")
		y = y + 1
	end
	text(x, y, color, stringDown)
end

--------------------------------------------------------------------------------

local function semiPixelRawSet(index, color, yPercentTwoEqualsZero)
	local upperPixel, lowerPixel, bothPixel = "▀", "▄", " "
	local background, foreground, symbol = newFrameBackgrounds[index], newFrameForegrounds[index], newFrameSymbols[index]

	if yPercentTwoEqualsZero then
		if symbol == upperPixel then
			if color == foreground then
				newFrameBackgrounds[index], newFrameForegrounds[index], newFrameSymbols[index] = color, foreground, bothPixel
			else
				newFrameBackgrounds[index], newFrameForegrounds[index], newFrameSymbols[index] = color, foreground, symbol
			end
		elseif symbol == bothPixel then
			if color ~= background then
				newFrameBackgrounds[index], newFrameForegrounds[index], newFrameSymbols[index] = background, color, lowerPixel
			end
		else
			newFrameBackgrounds[index], newFrameForegrounds[index], newFrameSymbols[index] = background, color, lowerPixel
		end
	else
		if symbol == lowerPixel then
			if color == foreground then
				newFrameBackgrounds[index], newFrameForegrounds[index], newFrameSymbols[index] = color, foreground, bothPixel
			else
				newFrameBackgrounds[index], newFrameForegrounds[index], newFrameSymbols[index] = color, foreground, symbol
			end
		elseif symbol == bothPixel then
			if color ~= background then
				newFrameBackgrounds[index], newFrameForegrounds[index], newFrameSymbols[index] = background, color, upperPixel
			end
		else
			newFrameBackgrounds[index], newFrameForegrounds[index], newFrameSymbols[index] = background, color, upperPixel
		end
	end
end

local function semiPixelSet(x, y, color)
	local yFixed = mathCeil(y / 2)
	if x >= drawLimitX1 and yFixed >= drawLimitY1 and x <= drawLimitX2 and yFixed <= drawLimitY2 then
		semiPixelRawSet(getIndex(x, yFixed), color, y % 2 == 0)
	end
end

local function semiPixelSquare(x, y, width, height, color)
	local index, indexStepForward, indexStepBackward, jPercentTwoEqualsZero, jFixed = getIndex(x, mathCeil(y / 2)), (bufferWidth - width), width
	for j = y, y + height - 1 do
		jPercentTwoEqualsZero = j % 2 == 0
		
		for i = x, x + width - 1 do
			jFixed = mathCeil(j / 2)
			semiPixelRawSet(index, color, jPercentTwoEqualsZero)
			index = index + 1
		end

		if jPercentTwoEqualsZero then
			index = index + indexStepForward
		else
			index = index - indexStepBackward
		end
	end
end

local function semiPixelLine(x1, y1, x2, y2, color)
	rasterizeLine(x1, y1, x2, y2, function(x, y)
		semiPixelSet(x, y, color)
	end)
end

local function semiPixelCircle(xCenter, yCenter, radius, color)
	local function insertPoints(x, y)
		semiPixelSet(xCenter + x, yCenter + y, color)
		semiPixelSet(xCenter + x, yCenter - y, color)
		semiPixelSet(xCenter - x, yCenter + y, color)
		semiPixelSet(xCenter - x, yCenter - y, color)
	end

	local x, y = 0, radius
	local delta = 3 - 2 * radius;
	while (x < y) do
		insertPoints(x, y);
		insertPoints(y, x);
		if (delta < 0) then
			delta = delta + (4 * x + 6)
		else 
			delta = delta + (4 * (x - y) + 10)
			y = y - 1
		end
		x = x + 1
	end

	if x == y then insertPoints(x, y) end
end

--------------------------------------------------------------------------------

local function getPointTimedPosition(firstPoint, secondPoint, time)
	return {
		x = firstPoint.x + (secondPoint.x - firstPoint.x) * time,
		y = firstPoint.y + (secondPoint.y - firstPoint.y) * time
	}
end

local function getConnectionPoints(points, time)
	local connectionPoints = {}
	for point = 1, #points - 1 do
		tableInsert(connectionPoints, getPointTimedPosition(points[point], points[point + 1], time))
	end
	return connectionPoints
end

local function getMainPointPosition(points, time)
	if #points > 1 then
		return getMainPointPosition(getConnectionPoints(points, time), time)
	else
		return points[1]
	end
end

local function semiPixelBezierCurve(points, color, precision)
	local linePoints = {}
	for time = 0, 1, precision or 0.01 do
		tableInsert(linePoints, getMainPointPosition(points, time))
	end
	
	for point = 1, #linePoints - 1 do
		semiPixelLine(mathFloor(linePoints[point].x), mathFloor(linePoints[point].y), mathFloor(linePoints[point + 1].x), mathFloor(linePoints[point + 1].y), color)
	end
end

-- DELETE THIS CYKA BLYAD NAHOOOY ZAEBAL GOVNOKOD PLODIT ----------------------------------------------

local function button(x, y, width, height, background, foreground, data)
	local textLength = unicodeLen(data)
	if textLength > width - 2 then data = unicodeSub(data, 1, width - 2) end
	
	local textPosX = mathFloor(x + width / 2 - textLength / 2)
	local textPosY = mathFloor(y + height / 2)
	square(x, y, width, height, background, foreground, " ")
	text(textPosX, textPosY, foreground, data)

	return x, y, (x + width - 1), (y + height - 1)
end

local function adaptiveButton(x, y, xOffset, yOffset, background, foreground, data)
	local width = xOffset * 2 + unicodeLen(data)
	local height = yOffset * 2 + 1

	square(x, y, width, height, background, 0xFFFFFF, " ")
	text(x + xOffset, y + yOffset, foreground, data)

	return x, y, (x + width - 1), (y + height - 1)
end

local function framedButton(x, y, width, height, backColor, buttonColor, data)
	square(x, y, width, height, backColor, buttonColor, " ")
	frame(x, y, width, height, buttonColor)
	
	x = mathFloor(x + width / 2 - unicodeLen(data) / 2)
	y = mathFloor(y + height / 2)

	text(x, y, buttonColor, data)
end

local function scrollBar(x, y, width, height, countOfAllElements, currentElement, backColor, frontColor)
	local sizeOfScrollBar = mathCeil(height / countOfAllElements)
	local displayBarFrom = mathFloor(y + height * ((currentElement - 1) / countOfAllElements))

	square(x, y, width, height, backColor, 0xFFFFFF, " ")
	square(x, displayBarFrom, width, sizeOfScrollBar, frontColor, 0xFFFFFF, " ")

	sizeOfScrollBar, displayBarFrom = nil, nil
end

local function horizontalScrollBar(x, y, width, countOfAllElements, currentElement, background, foreground)
	local pipeSize = mathCeil(width / countOfAllElements)
	local displayBarFrom = mathFloor(x + width * ((currentElement - 1) / countOfAllElements))

	text(x, y, background, string.rep("▄", width))
	text(displayBarFrom, y, foreground, string.rep("▄", pipeSize))
end

local function customImage(x, y, pixels)
	x = x - 1
	y = y - 1

	for i=1, #pixels do
		for j=1, #pixels[1] do
			if pixels[i][j][3] ~= "#" then
				set(x + j, y + i, pixels[i][j][1], pixels[i][j][2], pixels[i][j][3])
			end
		end
	end

	return (x + 1), (y + 1), (x + #pixels[1]), (y + #pixels)
end

--------------------------------------------------------------------------------

local function debug(...)
	local args = {...}
	local text = {}
	for i = 1, #args do
		tableInsert(text, tostring(args[i]))
	end

	local b = GPUProxyGetBackground()
	local f = GPUProxyGetForeground()
	GPUProxySetBackground(0x0)
	GPUProxySetForeground(0xFFFFFF)
	GPUProxyFill(1, bufferHeight, bufferWidth, 1, " ")
	GPUProxySet(2, bufferHeight, tableConcat(text, ", "))
	GPUProxySetBackground(b)
	GPUProxySetForeground(f)
end

local function draw(force)
	-- local oldClock = os.clock()
	
	local index, indexStepOnEveryLine, changes = getIndex(drawLimitX1, drawLimitY1), (bufferWidth - drawLimitX2 + drawLimitX1 - 1), {}
	local x, equalChars, charX, charIndex, currentForeground
	local currentFrameBackground, currentFrameForeground, currentFrameSymbol, changesCurrentFrameBackground, changesCurrentFrameBackgroundCurrentFrameForeground

	for y = drawLimitY1, drawLimitY2 do
		x = drawLimitX1
		while x <= drawLimitX2 do			
			-- Determine if some pixel data was changed (or if <force> argument was passed)
			if
				currentFrameBackgrounds[index] ~= newFrameBackgrounds[index] or
				currentFrameForegrounds[index] ~= newFrameForegrounds[index] or
				currentFrameSymbols[index] ~= newFrameSymbols[index] or
				force
			then
				-- Make pixel at both frames equal
				currentFrameBackground, currentFrameForeground, currentFrameSymbol = newFrameBackgrounds[index], newFrameForegrounds[index], newFrameSymbols[index]
				currentFrameBackgrounds[index] = currentFrameBackground
				currentFrameForegrounds[index] = currentFrameForeground
				currentFrameSymbols[index] = currentFrameSymbol

				-- Look for pixels with equal chars from right of current pixel
				equalChars, charX, charIndex = {currentFrameSymbol}, x + 1, index + 1
				while charX <= drawLimitX2 do
					-- Pixels becomes equal only if they have same background and (whitespace char or same foreground)
					if	
						currentFrameBackground == newFrameBackgrounds[charIndex] and
						(
							newFrameSymbols[charIndex] == " " or
							currentFrameForeground == newFrameForegrounds[charIndex]
						)
					then
						-- Make pixel at both frames equal
					 	currentFrameBackgrounds[charIndex] = newFrameBackgrounds[charIndex]
					 	currentFrameForegrounds[charIndex] = newFrameForegrounds[charIndex]
					 	currentFrameSymbols[charIndex] = newFrameSymbols[charIndex]

					 	tableInsert(equalChars, currentFrameSymbols[charIndex])
					else
						break
					end

					charX, charIndex = charX + 1, charIndex + 1
				end

				-- Group pixels that need to be drawn by background and foreground
				changes[currentFrameBackground] = changes[currentFrameBackground] or {}
				changesCurrentFrameBackground = changes[currentFrameBackground]
				changesCurrentFrameBackground[currentFrameForeground] = changesCurrentFrameBackground[currentFrameForeground] or {}
				changesCurrentFrameBackgroundCurrentFrameForeground = changesCurrentFrameBackground[currentFrameForeground]

				tableInsert(changesCurrentFrameBackgroundCurrentFrameForeground, x)
				tableInsert(changesCurrentFrameBackgroundCurrentFrameForeground, y)
				tableInsert(changesCurrentFrameBackgroundCurrentFrameForeground, tableConcat(equalChars))
				
				x, index = x + #equalChars - 1, index + #equalChars - 1
			end

			x, index = x + 1, index + 1
		end

		index = index + indexStepOnEveryLine
	end
	
	-- Draw grouped pixels on screen
	for background, foregrounds in pairs(changes) do
		GPUProxySetBackground(background)

		for foreground, pixels in pairs(foregrounds) do
			if currentForeground ~= foreground then
				GPUProxySetForeground(foreground)
				currentForeground = foreground
			end

			for i = 1, #pixels, 3 do
				GPUProxySet(pixels[i], pixels[i + 1], pixels[i + 2])
			end
		end
	end

	changes = nil

	-- debug("os.clock() delta: " .. (os.clock() - oldClock))
end

--------------------------------------------------------------------------------

bindGPU(component.getPrimary("gpu").address)

--------------------------------------------------------------------------------

return {
	getCoordinates = getCoordinates,
	getIndex = getIndex,
	setDrawLimit = setDrawLimit,
	resetDrawLimit = resetDrawLimit,
	getDrawLimit = getDrawLimit,
	flush = flush,
	setResolution = setResolution,
	bindScreen = bindScreen,
	bindGPU = bindGPU,
	getGPUProxy = getGPUProxy,
	getResolution = getResolution,
	getWidth = getWidth,
	getHeight = getHeight,
	rawSet = rawSet,
	rawGet = rawGet,
	get = get,
	set = set,
	square = square,
	clear = clear,
	copy = copy,
	paste = paste,
	rasterizeLine = rasterizeLine,
	rasterizeEllipse = rasterizeEllipse,
	line = line,
	text = text,
	formattedText = formattedText,
	image = image,
	frame = frame,
	semiPixelRawSet = semiPixelRawSet,
	semiPixelSet = semiPixelSet,
	semiPixelSquare = semiPixelSquare,
	semiPixelLine = semiPixelLine,
	semiPixelCircle = semiPixelCircle,
	semiPixelBezierCurve = semiPixelBezierCurve,
	draw = draw,
	debug = debug,
	getCurrentFrameTables = getCurrentFrameTables,
	getNewFrameTables = getNewFrameTables,

	button = button,
	adaptiveButton = adaptiveButton,
	framedButton = framedButton,
	scrollBar = scrollBar,
	horizontalScrollBar = horizontalScrollBar,
	customImage = customImage,
}