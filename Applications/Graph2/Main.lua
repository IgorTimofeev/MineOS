
require("advancedLua")
local fs = require("filesystem")
local buffer = require("doubleBuffering")
local GUI = require("GUI")
local unicode = require("unicode")
local MineOSInterface = require("MineOSInterface")

---------------------------------------------------------------------------------------------------------

local mainContainer, window = MineOSInterface.addWindow(GUI.filledWindow(nil, nil, 110, 25, 0xE1E1E1))
local yDependencyString = "math.sin(x)"
local xOffset, yOffset, xDrag, yDrag, points = 0, 0, 1, 1

---------------------------------------------------------------------------------------------------------

window.backgroundPanel.localPosition.y, window.backgroundPanel.height = 4, window.backgroundPanel.height - 3
local titlePanel = window:addChild(GUI.panel(1, 1, window.width, 3, 0x2D2D2D, 0.1))
local layout = window:addChild(GUI.layout(1, 1, window.width, 3, 1, 1))
layout:setCellDirection(1, 1, GUI.directions.horizontal)
layout:setCellSpacing(1, 1, 3)

local switchAndLabel = layout:addChild(GUI.switchAndLabel(1, 1, 16, 6, 0x66DB80, 0x1D1D1D, 0xEEEEEE, 0x999999, "Quants:", false))
local scaleSlider = layout:addChild(GUI.slider(1, 1, 12, 0x66DB80, 0x0, 0xFFFFFF, 0x999999, 1, 1000, 400, false, "Scale: ", "%"))
local rangeSlider = layout:addChild(GUI.slider(1, 1, 12, 0x66DB80, 0x0, 0xFFFFFF, 0x999999, 5, 60, 25, false, "Range: ", ""))
local precisionSlider = layout:addChild(GUI.slider(1, 1, 12, 0x66DB80, 0x0, 0xFFFFFF, 0x999999, 10, 100, 72, false, "Precision: ", ""))
local functionButton = window:addChild(GUI.button(1, 1, 1, 3, 0xE1E1E1, 0x3C3C3C, 0xCCCCCC, 0x3C3C3C, ""))

window.actionButtons:moveToFront()

local graph = window:addChild(GUI.object(1, 4, window.width, window.height - 3))
graph.draw = function(graph)
	local x1, x2, y1, y2 = buffer.getDrawLimit()
	buffer.setDrawLimit(graph.x, graph.y, graph.x + graph.width - 1, graph.y + graph.height - 1)

	local xCenter, yCenter = graph.x + xOffset + graph.width / 2 - 1, graph.y + yOffset + graph.height / 2 - 1
	
	buffer.semiPixelLine(math.floor(graph.x), math.floor(yCenter * 2), math.floor(graph.x + graph.width - 1), math.floor(yCenter * 2), 0xD2D2D2)
	buffer.semiPixelLine(math.floor(xCenter), math.floor(graph.y * 2 - 1), math.floor(xCenter), math.floor(graph.y + graph.height - 1) * 2, 0xD2D2D2)

	for i = 1, #points - 1 do
		local x1, x2, y1, y2 = math.floor(xCenter + points[i].x), math.floor(yCenter - points[i].y + 1) * 2, math.floor(xCenter + points[i + 1].x), math.floor(yCenter - points[i + 1].y + 1) * 2
		buffer.semiPixelLine(x1, x2, y1, y2, 0x0)
		if switchAndLabel.switch.state then
			buffer.semiPixelSet(x1, x2, 0x66DB80)
		end
	end

	buffer.setDrawLimit(x1, x2, y1, y2)
end

local function update()
	functionButton.text = "f(x)=" .. yDependencyString:gsub("%s+", "")
	functionButton.width = unicode.len(functionButton.text) + 4
	functionButton.localPosition.x = window.width - functionButton.width + 1
	titlePanel.width = window.width - functionButton.width
	layout.width = titlePanel.width

	points = {}
	local scale = scaleSlider.value / 100
	local xRange = rangeSlider.value
	local step = precisionSlider.value / 100

	for x = -xRange, xRange, step do
		local success, y = pcall(load("local x = " .. x .. "; local y = " .. yDependencyString .. "; return y"))
		if success and tonumber(y) then
			if not (y ~= y) then
				table.insert(points, {
					x = x * scale,
					y = y * scale
				})
			end
		else
			GUI.error("Invalid input function")
			return
		end
	end
end

functionButton.onTouch = function()
	local container = MineOSInterface.addUniversalContainer(window, "Set function f(x)")
	local inputField = container.layout:addChild(GUI.inputField(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0x666666, 0xEEEEEE, 0x262626, yDependencyString, "f(x)", false))
	inputField.onInputFinished = function()
		if inputField.text then
			yDependencyString = inputField.text
			update()

			container:delete()
			mainContainer:draw()
			buffer.draw()
		end
	end

	mainContainer:draw()
	buffer.draw()
end

scaleSlider.onValueChanged = function()
	update()
	mainContainer:draw()
	buffer.draw()
end
rangeSlider.onValueChanged = scaleSlider.onValueChanged
precisionSlider.onValueChanged = scaleSlider.onValueChanged

window.onResize = function(width, height)
	window.backgroundPanel.width, window.backgroundPanel.height = width, height - 3
	graph.width, graph.height = width, height - 3

	update()
end

graph.eventHandler = function(mainContainer, graph, eventData)
	if eventData[1] == "touch" then
		xDrag, yDrag = eventData[3], eventData[4]
	elseif eventData[1] == "drag" then
		xOffset, yOffset = xOffset + (eventData[3] - xDrag), yOffset + (eventData[4] - yDrag)
		mainContainer:draw()
		buffer.draw()

		xDrag, yDrag = eventData[3], eventData[4]
	elseif eventData[1] == "scroll" then
		scaleSlider.value = scaleSlider.value + eventData[5] * 10
		if scaleSlider.value < scaleSlider.minimumValue then
			scaleSlider.value = scaleSlider.minimumValue
		elseif scaleSlider.value > scaleSlider.maximumValue then
			scaleSlider.value = scaleSlider.maximumValue
		end

		update()

		mainContainer:draw()
		buffer.draw()
	end
end

---------------------------------------------------------------------------------------------------------

update()
mainContainer:draw()
buffer.draw()



