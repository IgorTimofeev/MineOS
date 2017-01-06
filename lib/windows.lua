
----------------------------------------- Libraries -----------------------------------------

-- _G.GUI, package.loaded.GUI = nil, nil

local computer = require("computer")
local buffer = require("doubleBuffering")
local GUI = require("GUI")
local unicode = require("unicode")
local event = require("event")

----------------------------------------- Main variables -----------------------------------------

local windows = {}

windows.alignment = GUI.alignment

windows.colors = {
	background = 0xEEEEEE,
	title = {
		background = 0xDDDDDD,
		text = 0x262626,
	},
	tabBar = {
		background = 0xDDDDDD,
		text = 0x262626,
		selectedTab = {
			background = 0xCCCCCC,
			text = 0x262626,
		}
	},
}

----------------------------------------- Universal window event handlers -----------------------------------------

local function executeObjectMethod(method, ...)
	if method then method(...) end
end

local function buttonHandler(window, object, objectIndex, eventData)
	object.pressed = true
	window:draw()
	buffer.draw()
	os.sleep(0.2)
	object.pressed = false
	window:draw()
	buffer.draw()
	executeObjectMethod(object.onTouch, eventData)
end

local function tabBarTabHandler(window, object, objectIndex, eventData)
	object.parent.parent.selectedTab = objectIndex
	window:draw()
	buffer.draw()
	executeObjectMethod(object.parent.parent.onTabSwitched, eventData)
end

local function inputTextBoxHandler(window, object, objectIndex, eventData)
	object:input()
	window:draw()
	buffer.draw()
	executeObjectMethod(object.onInputFinished, eventData)
end

local function textBoxScrollHandler(window, object, objectIndex, eventData)
	if eventData[5] == 1 then
		object:scrollUp()
		window:draw()
		buffer.draw()
	else
		object:scrollDown()
		window:draw()
		buffer.draw()
	end
end

local function horizontalSliderHandler(window, object, objectIndex, eventData)
	local clickPosition = eventData[3] - object.x + 1
	object.value = object.minimumValue + (clickPosition * (object.maximumValue - object.minimumValue) / object.width)
	window:draw()
	buffer.draw()
	executeObjectMethod(object.onValueChanged, eventData)
end

local function switchHandler(window, object, objectIndex, eventData)
	object.state = not object.state
	window:draw()
	buffer.draw()
	executeObjectMethod(object.onStateChanged, eventData)
end

local function comboBoxHandler(window, object, objectIndex, eventData)
	object:selectItem()
	executeObjectMethod(object.onItemSelected, eventData)
end

local function menuItemHandler(window, object, objectIndex, eventData)
	object.pressed = true
	window:draw()
	buffer.draw()
	executeObjectMethod(object.onTouch, eventData)
	object.pressed = false
	window:draw()
	buffer.draw()
end

function windows.handleEventData(window, eventData)
	if eventData[1] == "touch" then
		local object, objectIndex = window:getClickedObject(eventData[3], eventData[4])
		
		if object then
			if object.type == GUI.objectTypes.button then
				buttonHandler(window, object, objectIndex, eventData)
			elseif object.type == GUI.objectTypes.tabBarTab then
				tabBarTabHandler(window, object, objectIndex, eventData)
			elseif object.type == GUI.objectTypes.inputTextBox then
				inputTextBoxHandler(window, object, objectIndex, eventData)
			elseif object.type == GUI.objectTypes.horizontalSlider then
				horizontalSliderHandler(window, object, objectIndex, eventData)
			elseif object.type == GUI.objectTypes.switch then
				switchHandler(window, object, objectIndex, eventData)
			elseif object.type == GUI.objectTypes.comboBox then
				comboBoxHandler(window, object, objectIndex, eventData)
			elseif object.type == GUI.objectTypes.menuItem then
				menuItemHandler(window, object, objectIndex, eventData)
			elseif object.onTouch then
				executeObjectMethod(object.onTouch, eventData)
			end
		else
			executeObjectMethod(window.onTouch, eventData)
		end
	elseif eventData[1] == "scroll" then
		local object, objectIndex = window:getClickedObject(eventData[3], eventData[4])
		if object then
			if object.type == GUI.objectTypes.textBox then
				textBoxScrollHandler(window, object, objectIndex, eventData)
			elseif object.onScroll then
				executeObjectMethod(object.onScroll, eventData)
			end
		else
			executeObjectMethod(window.onScroll, eventData)
		end
	elseif eventData[1] == "drag" then
		local object, objectIndex = window:getClickedObject(eventData[3], eventData[4])
		if object then
			if object.type == GUI.objectTypes.horizontalSlider then
				horizontalSliderHandler(window, object, objectIndex, eventData)
			elseif object.onDrag then
				executeObjectMethod(object.onDrag, eventData)
			end
		else
			executeObjectMethod(window.onDrag, eventData)
		end
	elseif eventData[1] == "drop" then
		local object, objectIndex = window:getClickedObject(eventData[3], eventData[4])
		if object then
			if object.onDrag then
				executeObjectMethod(object.onDrop, eventData)
			end
		else
			executeObjectMethod(window.onDrop, eventData)
		end
	elseif eventData[1] == "key_down" then
		executeObjectMethod(window.onKeyDown, eventData)
	elseif eventData[1] == "key_up" then
		executeObjectMethod(window.onKeyUp, eventData)
	end

	executeObjectMethod(window.onAnyEvent, eventData)
end

function windows.handleEvents(window, pullTime)
	while true do
		window:handleEventData({event.pull(pullTime)})
		if window.dataToReturn then return table.unpack(window.dataToReturn) end
	end
end

----------------------------------------- Window actions -----------------------------------------

function windows.returnData(window, ...)
	window.dataToReturn = {...}
	computer.pushSignal("windowAction")
end

function windows.close(window)
	windows.returnData(window, nil)
end

----------------------------------------- Window creation -----------------------------------------

function windows.correctWindowCoordinates(x, y, width, height, minimumWidth, minimumHeight)
	width = minimumWidth and math.max(width, minimumWidth) or width
	height = minimumHeight and math.max(height, minimumHeight) or height
	x = (x == "auto" and math.floor(buffer.screen.width / 2 - width / 2)) or x
	y = (y == "auto" and math.floor(buffer.screen.height / 2 - height / 2)) or y

	return x, y, width, height
end

local function drawWindow(window)
	if window.onDrawStarted then window.onDrawStarted() end
	window:drawMethodOutOfWindowsLibrary()
	if window.drawShadow then GUI.windowShadow(window.x, window.y, window.width, window.height, 50) end
	if window.onDrawFinished then window.onDrawFinished() end
end

local function newWindow(x, y, width, height, minimumWidth, minimumHeight)
	x, y, width, height = windows.correctWindowCoordinates(x, y, width, height, minimumWidth, minimumHeight)

	local window = GUI.container(x, y, width, height)
	window.minimumWidth = minimumWidth
	window.minimumHeight = minimumHeight
	window.drawShadow = true
	window.drawMethodOutOfWindowsLibrary = window.draw
	window.draw = drawWindow
	window.handleEventData = windows.handleEventData
	window.handleEvents = windows.handleEvents
	window.close = windows.close
	window.returnData = windows.returnData

	return window
end

----------------------------------------- Window patterns -----------------------------------------

function windows.empty(x, y, width, height, minimumWidth, minimumHeight, title)
	local window = newWindow(x, y, width, height, minimumWidth, minimumHeight)
	window.drawShadow = false
	return window
end

function windows.fullScreen()
	local window = newWindow(1, 1, buffer.screen.width, buffer.screen.height)
	window.drawShadow = false
	return window
end

function windows.tabbed(x, y, width, height, minimumWidth, minimumHeight, ...)
	local tabs = {...}
	local window = newWindow(x, y, width, height, minimumWidth, minimumHeight)
	window:addPanel(1, 1, window.width, window.height, 0xEEEEEE).disabled = true
	window:addTabBar(1, 1, window.width, 3, 1, 0xDDDDDD, 0x262626, 0xCCCCCC, 0x262626, ...)
	window:addWindowActionButtons(2, 1, false)

	return window
end

----------------------------------------- Playground -----------------------------------------

-- buffer.clear(0x262626)
-- buffer.draw(true)

-- local myWindow = windows.empty(10, 5, 60, 20, 60, 20)
-- myWindow:addPanel(1, 1, myWindow.width, myWindow.height, 0xEEEEEE)
-- myWindow:addLabel(2, 5, 20, 1, 0x000000, tostring(10)):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
-- myWindow:addHorizontalSlider(2, 4, 20, 0x880000, 0x000000, 0xFF4444, 0, 100, 10).onValueChanged = function(object)
-- 	myWindow.counter.text = tostring(object.value)
-- end

-- myWindow:draw()
-- buffer.draw()
-- myWindow:handleEvents()

----------------------------------------- End of shit -----------------------------------------

return windows
