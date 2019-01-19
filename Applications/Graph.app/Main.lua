
local text = require("Text")
local number = require("Number")
local screen = require("Screen")
local GUI = require("GUI")
local system = require("System")

---------------------------------------------------------------------------------------------------------

local workspace, window = system.addWindow(GUI.filledWindow(1, 1, 110, 25, 0xF0F0F0))
local yDependencyString = "math.sin(x)"
local xOffset, yOffset, xDrag, yDrag, points = 0, 0, 1, 1

---------------------------------------------------------------------------------------------------------

window.backgroundPanel.localY, window.backgroundPanel.height = 4, window.backgroundPanel.height - 3
local titlePanel = window:addChild(GUI.panel(1, 1, window.width, 3, 0x2D2D2D))
local layout = window:addChild(GUI.layout(1, 1, window.width, 3, 1, 1))
layout:setDirection(1, 1, GUI.DIRECTION_HORIZONTAL)
layout:setSpacing(1, 1, 3)

local switchAndLabel = layout:addChild(GUI.switchAndLabel(1, 1, 16, 6, 0x66DB80, 0x1E1E1E, 0xF0F0F0, 0xBBBBBB, "Quants:", false))
local scaleSlider = layout:addChild(GUI.slider(1, 1, 12, 0x66DB80, 0x0, 0xFFFFFF, 0xBBBBBB, 1, 1000, 400, false, "Scale: ", "%"))
local rangeSlider = layout:addChild(GUI.slider(1, 1, 12, 0x66DB80, 0x0, 0xFFFFFF, 0xBBBBBB, 2, 60, 25, false, "Range: ", ""))
local precisionSlider = layout:addChild(GUI.slider(1, 1, 12, 0x66DB80, 0x0, 0xFFFFFF, 0xBBBBBB, 10, 99, 72, false, "Step: 0.", ""))
local functionButton = window:addChild(GUI.button(1, 1, 1, 3, 0xF0F0F0, 0x3C3C3C, 0xCCCCCC, 0x3C3C3C, ""))

window.actionButtons:moveToFront()

local graph = window:addChild(GUI.object(1, 4, window.width, window.height - 3))
graph.draw = function(graph)
	local x1, x2, y1, y2 = screen.getDrawLimit()
	screen.setDrawLimit(graph.x, graph.y, graph.x + graph.width - 1, graph.y + graph.height - 1)

	local xCenter, yCenter = graph.x + xOffset + graph.width / 2 - 1, graph.y + yOffset + graph.height / 2 - 1
	
	screen.drawSemiPixelLine(math.floor(graph.x), math.floor(yCenter * 2), math.floor(graph.x + graph.width - 1), math.floor(yCenter * 2), 0xD2D2D2)
	screen.drawSemiPixelLine(math.floor(xCenter), math.floor(graph.y * 2 - 1), math.floor(xCenter), math.floor(graph.y + graph.height - 1) * 2, 0xD2D2D2)

	for i = 1, #points - 1 do
		local x1, x2, y1, y2 = math.floor(xCenter + points[i].x), math.floor(yCenter - points[i].y + 1) * 2, math.floor(xCenter + points[i + 1].x), math.floor(yCenter - points[i + 1].y + 1) * 2
		screen.drawSemiPixelLine(x1, x2, y1, y2, 0x0)
		if switchAndLabel.switch.state then
			screen.semiPixelSet(x1, x2, 0x66DB80)
		end
	end

	screen.setDrawLimit(x1, x2, y1, y2)
end

local function update()
	functionButton.text = "f(x)=" .. yDependencyString:gsub("%s+", "")
	functionButton.width = unicode.len(functionButton.text) + 4
	functionButton.localX = window.width - functionButton.width + 1
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
			GUI.alert("Invalid input function")
			return
		end
	end
end

functionButton.onTouch = function()
	local container = GUI.addBackgroundContainer(workspace, true, true, "Set function f(x)")
	local inputField = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0x666666, 0xEEEEEE, 0x262626, yDependencyString, "f(x)", false))
	inputField.onInputFinished = function()
		if inputField.text then
			yDependencyString = inputField.text
			update()

			container:remove()
			workspace:draw()
		end
	end

	workspace:draw()
end

scaleSlider.onValueChanged = function()
	update()
	workspace:draw()
end
rangeSlider.onValueChanged = scaleSlider.onValueChanged
precisionSlider.onValueChanged = scaleSlider.onValueChanged

scaleSlider.roundValues, rangeSlider.roundValues, precisionSlider.roundValues = true, true, true

window.onResize = function(width, height)
	window.backgroundPanel.width, window.backgroundPanel.height = width, height - 3
	graph.width, graph.height = width, height - 3

	update()
end

graph.eventHandler = function(workspace, graph, e1, e2, e3, e4, e5)
	if e1 == "touch" then
		xDrag, yDrag = e3, e4
	elseif e1 == "drag" then
		xOffset, yOffset = xOffset + (e3 - xDrag), yOffset + (e4 - yDrag)
		workspace:draw()

		xDrag, yDrag = e3, e4
	elseif e1 == "scroll" then
		scaleSlider.value = scaleSlider.value + e5 * 10
		if scaleSlider.value < scaleSlider.minimumValue then
			scaleSlider.value = scaleSlider.minimumValue
		elseif scaleSlider.value > scaleSlider.maximumValue then
			scaleSlider.value = scaleSlider.maximumValue
		end

		update()
		workspace:draw()
	end
end

---------------------------------------------------------------------------------------------------------

update()
workspace:draw()



