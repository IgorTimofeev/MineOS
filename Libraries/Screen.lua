
local color = require("Color")
local image = require("Image")

--------------------------------------------------------------------------------

local bufferWidth, bufferHeight
local currentFrameBackgrounds, currentFrameForegrounds, currentFrameSymbols, newFrameBackgrounds, newFrameForegrounds, newFrameSymbols
local drawLimitX1, drawLimitX2, drawLimitY1, drawLimitY2
local GPUProxy, GPUProxyGetResolution, GPUProxySetResolution, GPUProxyGetBackground, GPUProxyGetForeground, GPUProxySetBackground, GPUProxySetForeground, GPUProxyGet, GPUProxySet, GPUProxyFill

local mathCeil, mathFloor, mathModf, mathAbs, mathMin, mathMax = math.ceil, math.floor, math.modf, math.abs, math.min, math.max
local tableInsert, tableConcat = table.insert, table.concat
local colorBlend, colorRGBToInteger, colorIntegerToRGB = color.blend, color.RGBToInteger, color.integerToRGB
local unicodeLen, unicodeSub = unicode.len, unicode.sub

--------------------------------------------------------------------------------

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

local function bind(address, reset)
	local success, reason = GPUProxy.bind(address, reset)
	if success then
		if reset then
			setResolution(GPUProxy.maxResolution())
		else
			setResolution(bufferWidth, bufferHeight)
		end
	else
		return success, reason
	end
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

	GPUProxyFill = GPUProxy.fill
end

local function setGPUProxy(proxy)
	GPUProxy = proxy
	updateGPUProxyMethods()
	flush()
end

local function getScaledResolution(scale)
	if not scale or scale > 1 then
		scale = 1
	elseif scale < 0.1 then
		scale = 0.1
	end

	local aspectWidth, aspectHeight = component.proxy(GPUProxy.getScreen()).getAspectRatio()
	local maxWidth, maxHeight = GPUProxy.maxResolution()
	local proportion = 2 * (16 * aspectWidth - 4.5) / (16 * aspectHeight - 4.5)
	 
	local height = scale * mathMin(
		maxWidth / proportion,
		maxWidth,
		math.sqrt(maxWidth * maxHeight / proportion)
	)

	return math.floor(height * proportion), math.floor(height)
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
		local index = bufferWidth * (y - 1) + x
		return newFrameBackgrounds[index], newFrameForegrounds[index], newFrameSymbols[index]
	else
		return 0x000000, 0x000000, " "
	end
end

local function set(x, y, background, foreground, symbol)
	if x >= drawLimitX1 and y >= drawLimitY1 and x <= drawLimitX2 and y <= drawLimitY2 then
		local index = bufferWidth * (y - 1) + x
		newFrameBackgrounds[index], newFrameForegrounds[index], newFrameSymbols[index] = background, foreground, symbol
	end
end

local function drawRectangle(x, y, width, height, background, foreground, symbol, transparency)
	local temp

	-- Clipping left
	if x < drawLimitX1 then
		width = width - drawLimitX1 + x
		x = drawLimitX1
	end

	-- Right
	temp = x + width - 1
	if temp > drawLimitX2 then
		width = width - temp + drawLimitX2
	end

	-- Top
	if y < drawLimitY1 then
		height = height - drawLimitY1 + y
		y = drawLimitY1
	end

	-- Bottom
	temp = y + height - 1
	if temp > drawLimitY2 then
		height = height - temp + drawLimitY2
	end

	temp = bufferWidth * (y - 1) + x
	local indexStepOnEveryLine = bufferWidth - width

	if transparency then
		for j = 1, height do
			for i = 1, width do
				newFrameBackgrounds[temp],
				newFrameForegrounds[temp] =
					colorBlend(newFrameBackgrounds[temp], background, transparency),
					colorBlend(newFrameForegrounds[temp], background, transparency)

				temp = temp + 1
			end

			temp = temp + indexStepOnEveryLine
		end
	else
		for j = 1, height do
			for i = 1, width do
				newFrameBackgrounds[temp],
				newFrameForegrounds[temp],
				newFrameSymbols[temp] = background, foreground, symbol

				temp = temp + 1
			end

			temp = temp + indexStepOnEveryLine
		end
	end
end

local function blur(x, y, width, height, radius, color, transparency)
	local temp

	-- Clipping left
	if x < drawLimitX1 then
		width = width - drawLimitX1 + x
		x = drawLimitX1
	end

	-- Right
	temp = x + width - 1
	if temp > drawLimitX2 then
		width = width - temp + drawLimitX2
	end

	-- Top
	if y < drawLimitY1 then
		height = height - drawLimitY1 + y
		y = drawLimitY1
	end

	-- Bottom
	temp = y + height - 1
	if temp > drawLimitY2 then
		height = height - temp + drawLimitY2
	end

	local screenIndex, indexStepOnEveryLine, buffer, bufferIndex, rSum, gSum, bSum, rSumFg, gSumFg, bSumFg, r, g, b =
		bufferWidth * (y - 1) + x,
		bufferWidth - width,
		{},
		1

	-- Copying
	temp = screenIndex

	if color then
		for j = 1, height do
			for i = 1, width do
				buffer[bufferIndex] = colorBlend(newFrameBackgrounds[temp], color, transparency)

				temp, bufferIndex = temp + 1, bufferIndex + 1
			end

			temp = temp + indexStepOnEveryLine
		end
	else
		for j = 1, height do
			for i = 1, width do
				buffer[bufferIndex] = newFrameBackgrounds[temp]

				temp, bufferIndex = temp + 1, bufferIndex + 1
			end

			temp = temp + indexStepOnEveryLine
		end
	end

	-- Blurring
	local rSum, gSum, bSum, count, r, g, b

	for j = 1, height do
		for i = 1, width do
			rSum, gSum, bSum, count = 0, 0, 0, 0

			for jr = mathMax(1, j - radius), mathMin(j + radius, height) do
				for ir = mathMax(1, i - radius), mathMin(i + radius, width) do
					r, g, b = colorIntegerToRGB(buffer[width * (jr - 1) + ir])
					rSum, gSum, bSum, count = rSum + r, gSum + g, bSum + b, count + 1
				end
			end

			-- Calculatin average channels value
			r, g, b = rSum / count, gSum / count, bSum / count
			-- Faster than math.floor
			r, g, b = r - r % 1, g - g % 1, b - b % 1

			newFrameBackgrounds[screenIndex] = colorRGBToInteger(r, g, b)
			newFrameForegrounds[screenIndex] = 0x0
			newFrameSymbols[screenIndex] = " "

			screenIndex = screenIndex + 1
		end

		screenIndex = screenIndex + indexStepOnEveryLine
	end
end

local function clear(color, transparency)
	drawRectangle(1, 1, bufferWidth, bufferHeight, color or 0x0, 0x000000, " ", transparency)
end

local function copy(x, y, width, height)
	local copyArray, index = { width, height }

	for j = y, y + height - 1 do
		for i = x, x + width - 1 do
			if i >= 1 and j >= 1 and i <= bufferWidth and j <= bufferHeight then
				index = bufferWidth * (j - 1) + i
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

local function paste(startX, startY, picture)
	local imageWidth = picture[1]
	local screenIndex, pictureIndex, screenIndexStepOnReachOfImageWidth = bufferWidth * (startY - 1) + startX, 3, bufferWidth - imageWidth

	for y = startY, startY + picture[2] - 1 do
		if y >= drawLimitY1 and y <= drawLimitY2 then
			for x = startX, startX + imageWidth - 1 do
				if x >= drawLimitX1 and x <= drawLimitX2 then
					newFrameBackgrounds[screenIndex] = picture[pictureIndex]
					newFrameForegrounds[screenIndex] = picture[pictureIndex + 1]
					newFrameSymbols[screenIndex] = picture[pictureIndex + 2]
				end

				screenIndex, pictureIndex = screenIndex + 1, pictureIndex + 3
			end

			screenIndex = screenIndex + screenIndexStepOnReachOfImageWidth
		else
			screenIndex, pictureIndex = screenIndex + bufferWidth, pictureIndex + imageWidth * 3
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

local function rasterizePolygon(centerX, centerY, startX, startY, countOfEdges, method)
	local degreeStep = 360 / countOfEdges

	local deltaX, deltaY = startX - centerX, startY - centerY
	local radius = math.sqrt(deltaX ^ 2 + deltaY ^ 2)
	local halfRadius = radius / 2
	local startDegree = math.deg(math.asin(deltaX / radius))

	local function round(num) 
		if num >= 0 then
			return math.floor(num + 0.5) 
		else
			return math.ceil(num - 0.5)
		end
	end

	local function calculatePosition(degree)
		local radDegree = math.rad(degree)
		local deltaX2 = math.sin(radDegree) * radius
		local deltaY2 = math.cos(radDegree) * radius
		return round(centerX + deltaX2), round(centerY + (deltaY >= 0 and deltaY2 or -deltaY2))
	end

	local xOld, yOld, xNew, yNew = calculatePosition(startDegree)

	for degree = (startDegree + degreeStep - 1), (startDegree + 360), degreeStep do
		xNew, yNew = calculatePosition(degree)
		rasterizeLine(xOld, yOld, xNew, yNew, method)
		xOld, yOld = xNew, yNew
	end
end

local function drawLine(x1, y1, x2, y2, background, foreground, symbol)
	rasterizeLine(x1, y1, x2, y2, function(x, y)
		set(x, y, background, foreground, symbol)
	end)
end

local function drawEllipse(centerX, centerY, radiusX, radiusY, background, foreground, symbol)
	rasterizeEllipse(centerX, centerY, radiusX, radiusY, function(x, y)
		set(x, y, background, foreground, symbol)
	end)
end

local function drawPolygon(centerX, centerY, radiusX, radiusY, background, foreground, countOfEdges, symbol)
	rasterizePolygon(centerX, centerY, radiusX, radiusY, countOfEdges, function(x, y)
		set(x, y, background, foreground, symbol)
	end)
end

local function drawText(x, y, textColor, data, transparency)
	if y >= drawLimitY1 and y <= drawLimitY2 then
		local charIndex, screenIndex = 1, bufferWidth * (y - 1) + x
		
		for charIndex = 1, unicodeLen(data) do
			if x >= drawLimitX1 and x <= drawLimitX2 then
				if transparency then
					newFrameForegrounds[screenIndex] = colorBlend(newFrameBackgrounds[screenIndex], textColor, transparency)
				else
					newFrameForegrounds[screenIndex] = textColor
				end

				newFrameSymbols[screenIndex] = unicodeSub(data, charIndex, charIndex)
			end

			x, screenIndex = x + 1, screenIndex + 1
		end
	end
end

local function drawImage(x, y, picture, blendForeground)
	local imageWidth, imageHeight, pictureIndex, temp = picture[1], picture[2], 3
	local clippedImageWidth, clippedImageHeight = imageWidth, imageHeight

	-- Clipping left
	if x < drawLimitX1 then
		temp = drawLimitX1 - x
		clippedImageWidth, x, pictureIndex = clippedImageWidth - temp, drawLimitX1, pictureIndex + temp * 4
	end

	-- Right
	temp = x + clippedImageWidth - 1
	if temp > drawLimitX2 then
		clippedImageWidth = clippedImageWidth - temp + drawLimitX2
	end

	-- Top
	if y < drawLimitY1 then
		temp = drawLimitY1 - y
		clippedImageHeight, y, pictureIndex = clippedImageHeight - temp, drawLimitY1, pictureIndex + temp * imageWidth * 4
	end

	-- Bottom
	temp = y + clippedImageHeight - 1
	if temp > drawLimitY2 then
		clippedImageHeight = clippedImageHeight - temp + drawLimitY2
	end

	local
		screenIndex,
		screenIndexStep,
		pictureIndexStep,
		background,
		foreground,
		alpha,
		symbol = bufferWidth * (y - 1) + x, bufferWidth - clippedImageWidth, (imageWidth - clippedImageWidth) * 4

	for j = 1, clippedImageHeight do
		for i = 1, clippedImageWidth do
			alpha, symbol = picture[pictureIndex + 2], picture[pictureIndex + 3]
			
			-- If it's fully transparent pixel
			if alpha == 0 then
				newFrameBackgrounds[screenIndex], newFrameForegrounds[screenIndex] = picture[pictureIndex], picture[pictureIndex + 1]
			-- If it has some transparency
			elseif alpha > 0 and alpha < 1 then
				newFrameBackgrounds[screenIndex] = colorBlend(newFrameBackgrounds[screenIndex], picture[pictureIndex], alpha)
				
				if blendForeground then
					newFrameForegrounds[screenIndex] = colorBlend(newFrameForegrounds[screenIndex], picture[pictureIndex + 1], alpha)
				else
					newFrameForegrounds[screenIndex] = picture[pictureIndex + 1]
				end
			-- If it's not transparent with whitespace
			elseif symbol ~= " " then
				newFrameForegrounds[screenIndex] = picture[pictureIndex + 1]
			end

			newFrameSymbols[screenIndex] = symbol

			screenIndex, pictureIndex = screenIndex + 1, pictureIndex + 4
		end

		screenIndex, pictureIndex = screenIndex + screenIndexStep, pictureIndex + pictureIndexStep
	end
end

local function drawFrame(x, y, width, height, color)
	local stringUp, stringDown, x2 = "┌" .. string.rep("─", width - 2) .. "┐", "└" .. string.rep("─", width - 2) .. "┘", x + width - 1
	
	drawText(x, y, color, stringUp); y = y + 1
	for i = 1, height - 2 do
		drawText(x, y, color, "│")
		drawText(x2, y, color, "│")
		y = y + 1
	end
	drawText(x, y, color, stringDown)
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
		semiPixelRawSet(bufferWidth * (yFixed - 1) + x, color, y % 2 == 0)
	end
end

local function drawSemiPixelRectangle(x, y, width, height, color)
	local index, evenYIndexStep, oddYIndexStep, realY, evenY =
		bufferWidth * (mathCeil(y / 2) - 1) + x,
		(bufferWidth - width),
		width

	for pseudoY = y, y + height - 1 do
		realY = mathCeil(pseudoY / 2)

		if realY >= drawLimitY1 and realY <= drawLimitY2 then
			evenY = pseudoY % 2 == 0
			
			for pseudoX = x, x + width - 1 do
				if pseudoX >= drawLimitX1 and pseudoX <= drawLimitX2 then
					semiPixelRawSet(index, color, evenY)
				end

				index = index + 1
			end
		else
			index = index + width
		end

		if evenY then
			index = index + evenYIndexStep
		else
			index = index - oddYIndexStep
		end
	end
end

local function drawSemiPixelLine(x1, y1, x2, y2, color)
	rasterizeLine(x1, y1, x2, y2, function(x, y)
		semiPixelSet(x, y, color)
	end)
end

local function drawSemiPixelEllipse(centerX, centerY, radiusX, radiusY, color)
	rasterizeEllipse(centerX, centerY, radiusX, radiusY, function(x, y)
		semiPixelSet(x, y, color)
	end)
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

local function drawSemiPixelCurve(points, color, precision)
	local linePoints = {}
	for time = 0, 1, precision or 0.01 do
		tableInsert(linePoints, getMainPointPosition(points, time))
	end
	
	for point = 1, #linePoints - 1 do
		drawSemiPixelLine(mathFloor(linePoints[point].x), mathFloor(linePoints[point].y), mathFloor(linePoints[point + 1].x), mathFloor(linePoints[point + 1].y), color)
	end
end

--------------------------------------------------------------------------------

local function update(force)	
	local index, indexStepOnEveryLine, changes = bufferWidth * (drawLimitY1 - 1) + drawLimitX1, (bufferWidth - drawLimitX2 + drawLimitX1 - 1), {}
	local x, equalChars, equalCharsIndex, charX, charIndex, currentForeground
	local currentFrameBackground, currentFrameForeground, currentFrameSymbol, changesCurrentFrameBackground, changesCurrentFrameBackgroundCurrentFrameForeground

	local changesCurrentFrameBackgroundCurrentFrameForegroundIndex

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
				equalChars, equalCharsIndex, charX, charIndex = {currentFrameSymbol}, 2, x + 1, index + 1
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

					 	equalChars[equalCharsIndex], equalCharsIndex = currentFrameSymbols[charIndex], equalCharsIndex + 1
					else
						break
					end

					charX, charIndex = charX + 1, charIndex + 1
				end

				-- Group pixels that need to be drawn by background and foreground
				changesCurrentFrameBackground = changes[currentFrameBackground] or {}
				changes[currentFrameBackground] = changesCurrentFrameBackground
				changesCurrentFrameBackgroundCurrentFrameForeground = changesCurrentFrameBackground[currentFrameForeground] or {index = 1}
				changesCurrentFrameBackground[currentFrameForeground] = changesCurrentFrameBackgroundCurrentFrameForeground

				changesCurrentFrameBackgroundCurrentFrameForegroundIndex = changesCurrentFrameBackgroundCurrentFrameForeground.index
				changesCurrentFrameBackgroundCurrentFrameForeground[changesCurrentFrameBackgroundCurrentFrameForegroundIndex], changesCurrentFrameBackgroundCurrentFrameForegroundIndex = x, changesCurrentFrameBackgroundCurrentFrameForegroundIndex + 1
				changesCurrentFrameBackgroundCurrentFrameForeground[changesCurrentFrameBackgroundCurrentFrameForegroundIndex], changesCurrentFrameBackgroundCurrentFrameForegroundIndex = y, changesCurrentFrameBackgroundCurrentFrameForegroundIndex + 1
				changesCurrentFrameBackgroundCurrentFrameForeground[changesCurrentFrameBackgroundCurrentFrameForegroundIndex], changesCurrentFrameBackgroundCurrentFrameForegroundIndex = tableConcat(equalChars), changesCurrentFrameBackgroundCurrentFrameForegroundIndex + 1
				
				x, index, changesCurrentFrameBackgroundCurrentFrameForeground.index = x + equalCharsIndex - 2, index + equalCharsIndex - 2, changesCurrentFrameBackgroundCurrentFrameForegroundIndex
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
end

--------------------------------------------------------------------------------

return {
	getIndex = getIndex,
	setDrawLimit = setDrawLimit,
	resetDrawLimit = resetDrawLimit,
	getDrawLimit = getDrawLimit,
	flush = flush,
	setResolution = setResolution,
	bind = bind,
	setGPUProxy = setGPUProxy,
	getGPUProxy = getGPUProxy,
	getScaledResolution = getScaledResolution,
	getResolution = getResolution,
	getWidth = getWidth,
	getHeight = getHeight,
	getCurrentFrameTables = getCurrentFrameTables,
	getNewFrameTables = getNewFrameTables,

	rawSet = rawSet,
	rawGet = rawGet,
	get = get,
	set = set,
	clear = clear,
	copy = copy,
	paste = paste,
	rasterizeLine = rasterizeLine,
	rasterizeEllipse = rasterizeEllipse,
	rasterizePolygon = rasterizePolygon,
	semiPixelRawSet = semiPixelRawSet,
	semiPixelSet = semiPixelSet,
	update = update,

	drawRectangle = drawRectangle,
	drawLine = drawLine,
	drawEllipse = drawEllipse,
	drawPolygon = drawPolygon,
	drawText = drawText,
	drawImage = drawImage,
	drawFrame = drawFrame,
	blur = blur,

	drawSemiPixelRectangle = drawSemiPixelRectangle,
	drawSemiPixelLine = drawSemiPixelLine,
	drawSemiPixelEllipse = drawSemiPixelEllipse,
	drawSemiPixelCurve = drawSemiPixelCurve,
}
