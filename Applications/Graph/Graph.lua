
_G.buffer = require("doubleBuffering")
buffer.start()
_G.doubleHeight = require("doubleHeight")
_G.unicode = require("unicode")
_G.event = require("event")
_G.ecs = require("ECSAPI")

local xGraph, yGraph = math.floor(buffer.screen.width / 2), buffer.screen.height
local yDependencyString = "math.sin(x) * 5"
local graphScale = 4
local graphResizeSpeed = 0.4
local renderRange = 40
local renderAccuracy = 0.4
local axisColor = 0x333333
local graphColor = 0x88FF88
local selectionPointLineColor = 0x555555
local selectionPointColor = 0x5555FF
local selectionTooltipTextColor = 0xFFFFFF
local buttonColor = 0xEEEEEE
local backgroundColor = 0x1b1b1b
local buttonTextColor = 0x1b1b1b
local buttonWidth = 20
local selectedPoints = {{x = -5, y = 2}}
local showCornerPoints = false

------------------------------------------------------------------------------------------------------------------------------------------
local buttons = {}

local function assertString(x, yDependencyString)
	local stro4ka = "local x = " .. x .. "; local y = " .. yDependencyString .. "; return y"
	return pcall(load(stro4ka))
end

local function drawButtons()
	buttons = {}
	local buttonNames = {"Функция", "Масштаб", "Очистить точки", "Выход"}
	local x, y = math.floor(buffer.screen.width / 2 - (#buttonNames * (buttonWidth + 2) - 2) / 2), buffer.screen.height - 4

	for i = 1, #buttonNames do
		buttons[buttonNames[i]] = { buffer.button(x, y, buttonWidth, 3, buttonColor, buttonTextColor, buttonNames[i]) }
		x = x + buttonWidth + 2
	end
end

local function drawHorizontalLine(x, y, x2, color)
	for i = x, x2 do doubleHeight.set(i, y, color) end
end

local function drawVerticalLine(x, y, y2, color)
	for i = y, y2 do doubleHeight.set(x, i, color) end
end

local function drawAxis()
	drawHorizontalLine(1, yGraph, buffer.screen.width, axisColor)
	drawVerticalLine(xGraph, 1, buffer.screen.height * 2, axisColor)
end

local function limit(n)
	if n > -500 and n < 500 then return true end
end

local keyPoints = {}
local function calculateKeyPoints()
	keyPoints = {}
	local xOld, yOld, xNew, yNew = math.huge, math.huge
	for x = -renderRange, renderRange, renderAccuracy do
		local success, result = assertString(x, yDependencyString)
		if success then
			if not (result ~= result) then
				xNew, yNew = math.floor(x * graphScale), math.floor(result * graphScale)
				
				if limit(xOld) and limit(yOld) and limit(xNew) and limit(yNew) then
					table.insert(keyPoints, {x = xOld, y = yOld, x2 = xNew, y2 = yNew})
					-- doubleHeight.line(xOld, yOld, xNew, yNew, graphColor)
				end
				
				xOld, yOld = xNew, yNew
			end
		-- else
		-- 	error(result)
		end
	end
end

local function drawGraph()
	for i = 1, #keyPoints do
		doubleHeight.line(xGraph + keyPoints[i].x, yGraph - keyPoints[i].y, xGraph + keyPoints[i].x2, yGraph - keyPoints[i].y2, graphColor)
		if showCornerPoints then doubleHeight.set(xGraph + keyPoints[i].x, yGraph - keyPoints[i].y, 0x00A8FF) end
	end
end

local function tooltip(x, y, tooltipColor, textColor, ...)
	local stringArray = {...}
	local maxTextLength = 0; for i = 1, #stringArray do maxTextLength = math.max(maxTextLength, unicode.len(stringArray[i])) end

	buffer.square(x, y, maxTextLength + 2, #stringArray, tooltipColor, textColor, " ")
	x = x + 1
	for i = 1, #stringArray do
		buffer.text(x, y, textColor, stringArray[i])
		y = y + 1
	end
end

local function drawSelectedPoint(x, y, pointNumber)
	local xOnScreen, yOnScreen = math.floor(xGraph + x * graphScale), math.floor(yGraph - y * graphScale)

	if xOnScreen <= xGraph then drawHorizontalLine(xOnScreen, yOnScreen, xGraph - 1, selectionPointLineColor) else drawHorizontalLine(xGraph + 1, yOnScreen, xOnScreen, selectionPointLineColor) end
	if yOnScreen <= yGraph then drawVerticalLine(xOnScreen, yOnScreen, yGraph - 1, selectionPointLineColor) else drawVerticalLine(xOnScreen, yGraph + 1, yOnScreen, selectionPointLineColor) end

	doubleHeight.set(xOnScreen, yOnScreen, selectionPointColor)

	yOnScreen = math.ceil(yOnScreen / 2)

	tooltip(xOnScreen + 3, yOnScreen + 2, selectionPointLineColor, selectionTooltipTextColor, "Точка #" .. pointNumber, "x: " .. x, "y: " .. y)
end

local function drawSelectedPoints()
	if selectedPoints then
		for i = 1, #selectedPoints do
			drawSelectedPoint(selectedPoints[i].x, selectedPoints[i].y, i)
		end
	end
end

local function drawAll()
	buffer.clear(backgroundColor)
	drawAxis()
	drawGraph()
	drawSelectedPoints()
	drawButtons()
	buffer.draw()
end

local function clicked(x, y, object)
	if x >= object[1] and y >= object[2] and x <= object[3] and y <= object[4] then return true end
end

------------------------------------------------------------------------------------------------------------------------------------------

calculateKeyPoints()
drawAll()

local xMove, yMove
while true do
	local e = {event.pull()}
	if e[1] == "touch" then
		if e[5] == 1 then
			selectedPoints = selectedPoints or {}
			table.insert(selectedPoints, { x = math.floor((e[3] - xGraph) / graphScale), y = math.floor((yGraph - e[4] * 2) / graphScale) })
			drawAll()	
		else
			xMove, yMove = e[3], e[4]

			for key in pairs(buttons) do
				if clicked(e[3], e[4], buttons[key]) then
					buffer.button(buttons[key][1], buttons[key][2], buttonWidth, 3, graphColor, backgroundColor, key)
					buffer.draw()
					os.sleep(0.2)
					drawAll()

					if key == "Функция" then
						local data = ecs.universalWindow("auto", "auto", 36, 0x262626, true,
							{"EmptyLine"},
							{"CenterText", ecs.colors.orange, "Функция"},
							{"EmptyLine"},
							{"Input", 0xFFFFFF, ecs.colors.orange, yDependencyString},
							{"EmptyLine"},
							{"CenterText", ecs.colors.orange, "Параметры рендера"},
							{"Slider", 0xFFFFFF, ecs.colors.orange, 1, 100, renderRange, "Диапазон: ", ""},
							{"Slider", 0xFFFFFF, ecs.colors.orange, 1, 100, 101 - renderAccuracy * 100, "Точность: ", ""},
							{"EmptyLine"},
							{"Switch", ecs.colors.orange, 0xffffff, 0xFFFFFF, "Показывать квант-точки", showCornerPoints},
							{"EmptyLine"},
							{"Button", {ecs.colors.orange, 0xffffff, "OK"}, {0x999999, 0xffffff, "Отмена"}}
						)
						if data[5] == "OK" then
							yDependencyString = data[1]
							renderRange = tonumber(data[2])
							renderAccuracy = (101 - tonumber(data[3])) / 100
							showCornerPoints = data[4]
							calculateKeyPoints()
							drawAll()
						end
					elseif key == "Масштаб" then
						local data = ecs.universalWindow("auto", "auto", 36, 0x262626, true,
							{"EmptyLine"},
							{"CenterText", ecs.colors.orange, "Масштаб"},
							{"EmptyLine"},
							{"Slider", 0xFFFFFF, ecs.colors.orange, 1, 3000, math.floor(graphScale * 100), "", "%"},
							{"EmptyLine"},
							{"Button", {ecs.colors.orange, 0xffffff, "OK"}, {0x999999, 0xffffff, "Отмена"}}
						)

						if data[2] == "OK" then
							graphScale = data[1] / 100
							calculateKeyPoints()
							drawAll()
						end
					elseif key == "Очистить точки" then
						selectedPoints = nil
						drawAll()
					elseif key == "Выход" then
						buffer.clear(0x262626)
						buffer.draw()
						return
					end

					break
				end
			end
		end
	elseif e[1] == "drag" then
		if e[5] ~= 1 then
			local xDifference, yDifference = e[3] - xMove, e[4] - yMove
			xGraph, yGraph = xGraph + xDifference, yGraph + yDifference * 2
			xMove, yMove = e[3], e[4]
			drawAll()
		end
	elseif e[1] == "scroll" then
		if e[5] == 1 then
			graphScale = graphScale + graphResizeSpeed
			calculateKeyPoints()
		else
			graphScale = graphScale - graphResizeSpeed
			if graphScale < graphResizeSpeed then graphScale = graphResizeSpeed end
			calculateKeyPoints()
		end
		drawAll()
	elseif e[1] == "key_down" then
		if e[4] == 28 then
			selectedPoints = nil
			drawAll()
		end
	end
end









