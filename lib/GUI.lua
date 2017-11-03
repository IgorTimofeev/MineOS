
require("advancedLua")
local computer = require("computer")
local keyboard = require("keyboard")
local fs = require("filesystem")
local unicode = require("unicode")
local event = require("event")
local color = require("color")
local image = require("image")
local buffer = require("doubleBuffering")

-----------------------------------------------------------------------------------------------------

local GUI = {}

GUI.alignment = {
	horizontal = enum(
		"left",
		"center",
		"right"
	),
	vertical = enum(
		"top",
		"center",
		"bottom"
	)
}

GUI.directions = enum(
	"horizontal",
	"vertical"
)

GUI.sizePolicies = enum(
	"percentage",
	"absolute"
)

GUI.dropDownMenuElementTypes = enum(
	"default",
	"separator"
)

GUI.filesystemModes = enum(
	"file",
	"directory",
	"both",
	"open",
	"save"
)

GUI.colors = {
	disabled = {
		background = 0x888888,
		text = 0xAAAAAA
	},
	contextMenu = {
		separator = 0x888888,
		default = {
			background = 0xFFFFFF,
			text = 0x2D2D2D
		},
		disabled = 0x888888,
		pressed = {
			background = 0x3366CC,
			text = 0xFFFFFF
		},
		transparency = {
			background = 0.24,
			shadow = 0.4
		}
	},
	windows = {
		title = {
			background = 0xE1E1E1,
			text = 0x2D2D2D
		},
		backgroundPanel = 0xF0F0F0,
		tabBar = {
			default = {
				background = 0x2D2D2D,
				text = 0xF0F0F0
			},
			selected = {
				background = 0xF0F0F0,
				text = 0x2D2D2D
			}
		}
	}
}

----------------------------------------- Interface objects -----------------------------------------

local function callMethod(method, ...)
	if method then method(...) end
end

local function objectIsClicked(object, x, y)
	return
		x >= object.x and
		y >= object.y and
		x <= object.x + object.width - 1 and
		y <= object.y + object.height - 1 and
		not object.disabled and
		not object.hidden
end

local function objectDraw(object)
	return object
end

function GUI.object(x, y, width, height)
	return {
		x = x,
		y = y,
		width = width,
		height = height,
		isClicked = objectIsClicked,
		draw = objectDraw
	}
end

----------------------------------------- Object alignment -----------------------------------------

function GUI.setAlignment(object, horizontalAlignment, verticalAlignment)
	object.alignment = {
		horizontal = horizontalAlignment,
		vertical = verticalAlignment
	}

	return object
end

function GUI.getAlignmentCoordinates(object, subObject)
	local x, y
	if object.alignment.horizontal == GUI.alignment.horizontal.left then
		x = object.x
	elseif object.alignment.horizontal == GUI.alignment.horizontal.center then
		x = math.floor(object.x + object.width / 2 - subObject.width / 2)
	elseif object.alignment.horizontal == GUI.alignment.horizontal.right then
		x = object.x + object.width - subObject.width
	else
		error("Unknown horizontal alignment: " .. tostring(object.alignment.horizontal))
	end

	if object.alignment.vertical == GUI.alignment.vertical.top then
		y = object.y
	elseif object.alignment.vertical == GUI.alignment.vertical.center then
		y = math.floor(object.y + object.height / 2 - subObject.height / 2)
	elseif object.alignment.vertical == GUI.alignment.vertical.bottom then
		y = object.y + object.height - subObject.height
	else
		error("Unknown vertical alignment: " .. tostring(object.alignment.vertical))
	end

	return x, y
end

function GUI.getMarginCoordinates(object)
	local x, y = object.x, object.y

	if object.alignment.horizontal == GUI.alignment.horizontal.left then
		x = x + object.margin.horizontal
	elseif object.alignment.horizontal == GUI.alignment.horizontal.right then
		x = x - object.margin.horizontal
	end

	if object.alignment.vertical == GUI.alignment.vertical.top then
		y = y + object.margin.vertical
	elseif object.alignment.vertical == GUI.alignment.vertical.bottom then
		y = y - object.margin.vertical
	end

	return x, y
end

----------------------------------------- Containers -----------------------------------------

local function containerObjectIndexOf(object)
	if not object.parent then error("Object doesn't have a parent container") end

	for objectIndex = 1, #object.parent.children do
		if object.parent.children[objectIndex] == object then
			return objectIndex
		end
	end
end

local function containerObjectMoveForward(object)
	local objectIndex = object:indexOf()
	if objectIndex < #object.parent.children then
		object.parent.children[index], object.parent.children[index + 1] = object.parent.children[index + 1], object.parent.children[index]
	end
	
	return object
end

local function containerObjectMoveBackward(object)
	local objectIndex = object:indexOf()
	if objectIndex > 1 then
		object.parent.children[objectIndex], object.parent.children[objectIndex - 1] = object.parent.children[objectIndex - 1], object.parent.children[objectIndex]
	end
	
	return object
end

local function containerObjectMoveToFront(object)
	local objectIndex = object:indexOf()
	table.insert(object.parent.children, object)
	table.remove(object.parent.children, objectIndex)
	
	return object
end

local function containerObjectMoveToBack(object)
	local objectIndex = object:indexOf()
	table.insert(object.parent.children, 1, object)
	table.remove(object.parent.children, objectIndex + 1)
	
	return object
end

local function containerObjectGetFirstParent(object)
	local currentParent = object.parent
	while currentParent.parent do
		currentParent = currentParent.parent
	end

	return currentParent
end

local function containerObjectSelfDelete(object)
	table.remove(object.parent.children, containerObjectIndexOf(object))
end

-----------------------------------------------------------------------------------------------------

local function containerObjectAnimationStart(animation, duration)
	animation.position = 0
	animation.duration = duration
	animation.started = true
	animation.startUptime = computer.uptime()
	computer.pushSignal("GUI", "animationStarted")
end

local function containerObjectAnimationStop(animation)
	animation.position = 0
	animation.started = false
end

local function containerObjectAnimationDelete(animation)
	animation.deleteLater = true
end

local function containerObjectAddAnimation(object, frameHandler, onFinish)
	local firstParent = object:getFirstParent()
	firstParent.animations = firstParent.animations or {}
	table.insert(firstParent.animations, {
		object = object,
		position = 0,
		start = containerObjectAnimationStart,
		stop = containerObjectAnimationStop,
		delete = containerObjectAnimationDelete,
		frameHandler = frameHandler,
		onFinish = onFinish,
	})

	return firstParent.animations[#firstParent.animations]
end

function GUI.addChildToContainer(container, object, atIndex)
	object.localX = object.x
	object.localY = object.y
	object.indexOf = containerObjectIndexOf
	object.moveToFront = containerObjectMoveToFront
	object.moveToBack = containerObjectMoveToBack
	object.moveForward = containerObjectMoveForward
	object.moveBackward = containerObjectMoveBackward
	object.getFirstParent = containerObjectGetFirstParent
	object.delete = containerObjectSelfDelete
	object.parent = container
	object.addAnimation = containerObjectAddAnimation

	if atIndex then
		table.insert(container.children, atIndex, object)
	else
		table.insert(container.children, object)
	end
	
	return object
end

local function deleteContainersContent(container, from, to)
	from = from or 1
	for objectIndex = from, to or #container.children do
		table.remove(container.children, from)
	end
end

local function getRectangleIntersection(R1X1, R1Y1, R1X2, R1Y2, R2X1, R2Y1, R2X2, R2Y2)
	if R2X1 <= R1X2 and R2Y1 <= R2Y2 and R2X2 >= R1X1 and R2Y2 >= R1Y1 then
		return
			math.max(R2X1, R1X1),
			math.max(R2Y1, R1Y1),
			math.min(R2X2, R1X2),
			math.min(R2Y2, R1Y2)
	else
		return
	end
end

function GUI.drawContainerContent(container)
	local R1X1, R1Y1, R1X2, R1Y2 = buffer.getDrawLimit()
	local intersectionX1, intersectionY1, intersectionX2, intersectionY2 = getRectangleIntersection(
		R1X1,
		R1Y1,
		R1X2,
		R1Y2,
		container.x,
		container.y,
		container.x + container.width - 1,
		container.y + container.height - 1
	)

	if intersectionX1 then
		buffer.setDrawLimit(intersectionX1, intersectionY1, intersectionX2, intersectionY2)
		
		for objectIndex = 1, #container.children do
			if not container.children[objectIndex].hidden then
				container.children[objectIndex].x, container.children[objectIndex].y = container.x + container.children[objectIndex].localX - 1, container.y + container.children[objectIndex].localY - 1
				container.children[objectIndex]:draw()
			end
		end

		buffer.setDrawLimit(R1X1, R1Y1, R1X2, R1Y2)
	end

	return container
end

local function containerHandler(isScreenEvent, mainContainer, currentContainer, eventData, intersectionX1, intersectionY1, intersectionX2, intersectionY2)
	local breakRecursion = false

	if not isScreenEvent or intersectionX1 and eventData[3] >= intersectionX1 and eventData[4] >= intersectionY1 and eventData[3] <= intersectionX2 and eventData[4] <= intersectionY2 then
		for i = #currentContainer.children, 1, -1 do
			if not currentContainer.children[i].hidden then
				if currentContainer.children[i].children then
					local newIntersectionX1, newIntersectionY1, newIntersectionX2, newIntersectionY2 = getRectangleIntersection(
						intersectionX1,
						intersectionY1,
						intersectionX2,
						intersectionY2,

						currentContainer.children[i].x,
						currentContainer.children[i].y,
						currentContainer.children[i].x + currentContainer.children[i].width - 1,
						currentContainer.children[i].y + currentContainer.children[i].height - 1
					)

					if newIntersectionX1 then
						if containerHandler(isScreenEvent, mainContainer, currentContainer.children[i], eventData, newIntersectionX1, newIntersectionY1, newIntersectionX2, newIntersectionY2) then
							breakRecursion = true
							break
						end
					end
				else
					if isScreenEvent then
						if currentContainer.children[i]:isClicked(eventData[3], eventData[4]) then
							callMethod(currentContainer.children[i].eventHandler, mainContainer, currentContainer.children[i], eventData)
							breakRecursion = true
							break
						end
					else
						callMethod(currentContainer.children[i].eventHandler, mainContainer, currentContainer.children[i], eventData)
					end
				end
			end
		end

		callMethod(currentContainer.eventHandler, mainContainer, currentContainer, eventData)
	end

	if breakRecursion then
		return true
	end
end

local function containerStartEventHandling(container, eventHandlingDelay)
	container.eventHandlingDelay = eventHandlingDelay

	local eventData, animationIndex, animationNeedDraw
	while true do
		eventData = {event.pull(container.animations and 0 or container.eventHandlingDelay)}
		
		containerHandler(
			(
				eventData[1] == "touch" or
				eventData[1] == "drag" or
				eventData[1] == "drop" or
				eventData[1] == "scroll" or
				eventData[1] == "double_touch"
			),
			container,
			container,
			eventData,
			container.x,
			container.y,
			container.x + container.width - 1,
			container.y + container.height - 1
		)

		if container.animations then
			animationIndex = 1
			while animationIndex <= #container.animations do
				if container.animations[animationIndex].started then
					animationNeedDraw = true
					container.animations[animationIndex].position = (computer.uptime() - container.animations[animationIndex].startUptime) / container.animations[animationIndex].duration
					
					if container.animations[animationIndex].position <= 1 then
						container.animations[animationIndex].frameHandler(container, container.animations[animationIndex].object, container.animations[animationIndex])
					else
						container.animations[animationIndex].position = 1
						container.animations[animationIndex].started = false
						container.animations[animationIndex].frameHandler(container, container.animations[animationIndex].object, container.animations[animationIndex])
						
						if container.animations[animationIndex].onFinish then
							animationNeedDraw = false
							container:draw()
							buffer.draw()
							container.animations[animationIndex].onFinish(container, container.animations[animationIndex].object, container.animations[animationIndex])
						end

						if container.animations[animationIndex].deleteLater then
							table.remove(container.animations, animationIndex)
							animationIndex = animationIndex - 1
						end
					end
				end

				animationIndex = animationIndex + 1
			end

			if animationNeedDraw then
				container:draw()
				buffer.draw()
			end

			if #container.animations == 0 then
				container.animations = nil
			end
		end

		if container.dataToReturn then
			local dataToReturn = container.dataToReturn
			container.dataToReturn = nil
			
			return table.unpack(dataToReturn)
		end
	end
end

local function containerReturnData(container, ...)
	container.dataToReturn = {...}
end

local function containerStopEventHandling(container)
	containerReturnData(container, nil)
end

function GUI.container(x, y, width, height)
	local container = GUI.object(x, y, width, height)

	container.children = {}
	container.draw = GUI.drawContainerContent
	container.deleteChildren = deleteContainersContent
	container.addChild = GUI.addChildToContainer
	container.returnData = containerReturnData
	container.startEventHandling = containerStartEventHandling
	container.stopEventHandling = containerStopEventHandling

	return container
end

function GUI.fullScreenContainer()
	return GUI.container(1, 1, buffer.getResolution())
end

----------------------------------------- Buttons -----------------------------------------

local function buttonDraw(object)
	local xText, yText = GUI.getAlignmentCoordinates(object, {width = unicode.len(object.text), height = 1})

	local buttonColor, textColor = object.colors.default.background, object.colors.default.text
	if object.disabled then
		buttonColor, textColor = object.colors.disabled.background, object.colors.disabled.text
	else
		if object.pressed then
			buttonColor, textColor = object.colors.pressed.background, object.colors.pressed.text
		end
	end

	if buttonColor then
		if object.buttonType == 1 then
			buffer.square(object.x, object.y, object.width, object.height, buttonColor, textColor, " ")
		elseif object.buttonType == 2 then
			local x2, y2 = object.x + object.width - 1, object.y + object.height - 1
			
			if object.height > 1 then
				buffer.text(object.x + 1, object.y, buttonColor, string.rep("▄", object.width - 2))
				buffer.text(object.x, object.y, buttonColor, "⣠")
				buffer.text(x2, object.y, buttonColor, "⣄")
				
				buffer.square(object.x, object.y + 1, object.width, object.height - 2, buttonColor, textColor, " ")
				
				buffer.text(object.x + 1, y2, buttonColor, string.rep("▀", object.width - 2))
				buffer.text(object.x, y2, buttonColor, "⠙")
				buffer.text(x2, y2, buttonColor, "⠋")
			else
				buffer.square(object.x, object.y, object.width, object.height, buttonColor, textColor, " ")
				GUI.roundedCorners(object.x, object.y, object.width, object.height, buttonColor)
			end
		else
			buffer.frame(object.x, object.y, object.width, object.height, buttonColor)
		end
	end

	buffer.text(xText, yText, textColor, object.text)

	return object
end

local function buttonPress(object)
	object.pressed = true
	buttonDraw(object)
end

local function buttonRelease(object)
	object.pressed = nil
	buttonDraw(object)
end

local function buttonPressAndRelease(object, pressTime)
	buttonPress(object)
	buffer.draw()
	os.sleep(pressTime or 0.2)
	buttonRelease(object)
	buffer.draw()
end

local function buttonEventHandler(mainContainer, object, eventData)
	if eventData[1] == "touch" then
		if object.switchMode then
			object.pressed = not object.pressed
			mainContainer:draw()
			buffer.draw()
			callMethod(object.onTouch, mainContainer, object, eventData)
		else
			object.pressed = true
			mainContainer:draw()
			buffer.draw()
			os.sleep(0.2)
			object.pressed = false
			mainContainer:draw()
			buffer.draw()
			callMethod(object.onTouch, mainContainer, object, eventData)
		end
	end
end

local function buttonCreate(buttonType, x, y, width, height, buttonColor, textColor, buttonPressedColor, textPressedColor, text, disabledState)
	local object = GUI.object(x, y, width, height)

	object.colors = {
		default = {
			background = buttonColor,
			text = textColor
		},
		pressed = {
			background = buttonPressedColor,
			text = textPressedColor
		},
		disabled = {
			background = GUI.colors.disabled.background,
			text = GUI.colors.disabled.text,
		}
	}

	object.eventHandler = buttonEventHandler
	object.buttonType = buttonType
	object.disabled = disabledState
	object.text = text
	object.press = buttonPress
	object.release = buttonRelease
	object.pressAndRelease = buttonPressAndRelease
	object.draw = buttonDraw
	object.setAlignment = GUI.setAlignment
	object:setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.center)


	return object
end

function GUI.button(...)
	return buttonCreate(1, ...)
end

function GUI.adaptiveButton(x, y, xOffset, yOffset, buttonColor, textColor, buttonPressedColor, textPressedColor, text, ...) 
	return buttonCreate(1, x, y, unicode.len(text) + xOffset * 2, yOffset * 2 + 1, buttonColor, textColor, buttonPressedColor, textPressedColor, text, ...)
end

function GUI.roundedButton(...)
	return buttonCreate(2, ...)
end

function GUI.adaptiveRoundedButton(x, y, xOffset, yOffset, buttonColor, textColor, buttonPressedColor, textPressedColor, text, ...)
	return buttonCreate(2, x, y, unicode.len(text) + xOffset * 2, yOffset * 2 + 1, buttonColor, textColor, buttonPressedColor, textPressedColor, text, ...)
end

function GUI.framedButton(...)
	return buttonCreate(3, ...)
end

function GUI.adaptiveFramedButton(x, y, xOffset, yOffset, buttonColor, textColor, buttonPressedColor, textPressedColor, text, ...)
	return buttonCreate(3, x, y, unicode.len(text) + xOffset * 2, yOffset * 2 + 1, buttonColor, textColor, buttonPressedColor, textPressedColor, text, ...)
end

----------------------------------------- TabBar -----------------------------------------

local function tabBarTabEventHandler(mainContainer, object, eventData)
	if eventData[1] == "touch" then
		object.parent.selectedItem = object:indexOf() - 1
		mainContainer:draw()
		buffer.draw()
		callMethod(object.onTouch, mainContainer, object, eventData)
	end
end

local function tabBarDraw(tabBar)
	tabBar.backgroundPanel.width, tabBar.backgroundPanel.height, tabBar.backgroundPanel.colors.background = tabBar.width, tabBar.height, tabBar.colors.default.background
	
	local totalWidth = 0
	for i = 2, #tabBar.children do
		totalWidth = totalWidth + tabBar.children[i].width + tabBar.spaceBetweenTabs
	end
	totalWidth = totalWidth - tabBar.spaceBetweenTabs

	local x = math.floor(tabBar.width / 2 - totalWidth / 2)
	for i = 2, #tabBar.children do
		tabBar.children[i].localX = x
		x = x + tabBar.children[i].width + tabBar.spaceBetweenTabs
		tabBar.children[i].pressed = (i - 1) == tabBar.selectedItem
	end

	GUI.drawContainerContent(tabBar)

	return tabBar
end

local function tabBarAddItem(tabBar, text)
	local item = tabBar:addChild(GUI.button(1, 1, unicode.len(text) + tabBar.horizontalTabOffset * 2, tabBar.height, tabBar.colors.default.background, tabBar.colors.default.text, tabBar.colors.selected.background, tabBar.colors.selected.text, text))
	
	item.switchMode = true
	item.eventHandler = tabBarTabEventHandler

	return item
end

function GUI.tabBar(x, y, width, height, horizontalTabOffset, spaceBetweenTabs, backgroundColor, textColor, backgroundSelectedColor, textSelectedColor, ...)
	local tabBar = GUI.container(x, y, width, height)

	tabBar.backgroundPanel = tabBar:addChild(GUI.panel(1, 1, 1, 1, backgroundColor))
	tabBar.horizontalTabOffset = horizontalTabOffset
	tabBar.spaceBetweenTabs = spaceBetweenTabs
	tabBar.colors = {
		default = {
			background = backgroundColor,
			text = textColor
		},
		selected = {
			background = backgroundSelectedColor,
			text = textSelectedColor
		}
	}
	tabBar.selectedItem = 1
	tabBar.draw = tabBarDraw
	tabBar.addItem = tabBarAddItem

	local items = {...}
	for i = 1, #items do
		tabBar:addItem(items[i])
	end

	return tabBar
end

----------------------------------------- Panel -----------------------------------------

local function drawPanel(object)
	buffer.square(object.x, object.y, object.width, object.height, object.colors.background, 0x000000, " ", object.colors.transparency)
	return object
end

function GUI.panel(x, y, width, height, color, transparency)
	local object = GUI.object(x, y, width, height)
	
	object.colors = {
		background = color,
		transparency = transparency
	}
	object.draw = drawPanel
	
	return object
end

----------------------------------------- Label -----------------------------------------

local function drawLabel(object)
	local xText, yText = GUI.getAlignmentCoordinates(object, {width = unicode.len(object.text), height = 1})
	buffer.text(xText, yText, object.colors.text, object.text)
	return object
end

function GUI.label(x, y, width, height, textColor, text)
	local object = GUI.object(x, y, width, height)
	object.setAlignment = GUI.setAlignment
	object:setAlignment(GUI.alignment.horizontal.left, GUI.alignment.vertical.top)
	object.colors = {text = textColor}
	object.text = text
	object.draw = drawLabel
	return object
end

----------------------------------------- Image -----------------------------------------

local function drawImage(object)
	buffer.image(object.x, object.y, object.image)
	return object
end

function GUI.image(x, y, image)
	local object = GUI.object(x, y, image[1], image[2])
	object.image = image
	object.draw = drawImage
	return object
end

----------------------------------------- Action buttons -----------------------------------------

function GUI.actionButtons(x, y, fatSymbol)
	local symbol = fatSymbol and "⬤" or "●"
	
	local container = GUI.container(x, y, 5, 1)
	container.close = container:addChild(GUI.button(1, 1, 1, 1, nil, 0xFF4940, nil, 0x992400, symbol))
	container.minimize = container:addChild(GUI.button(3, 1, 1, 1, nil, 0xFFB640, nil, 0x996D00, symbol))
	container.maximize = container:addChild(GUI.button(5, 1, 1, 1, nil, 0x00B640, nil, 0x006D40, symbol))

	return container
end

----------------------------------------- Menu -----------------------------------------

local function menuDraw(menu)
	buffer.square(menu.x, menu.y, menu.width, 1, menu.colors.default.background, menu.colors.default.text, " ", menu.colors.transparency)
	menu:reimplementedDraw()
end

local function menuItemEventHandler(mainContainer, object, eventData)
	if eventData[1] == "touch" then
		if object.onTouch then
			object.pressed = true
			mainContainer:draw()
			buffer.draw()

			object.onTouch(eventData)
			
			object.pressed = false
			mainContainer:draw()
			buffer.draw()
		end
	end
end

local function menuAddItem(menu, text, textColor)
	local x = 2; for i = 1, #menu.children do x = x + unicode.len(menu.children[i].text) + 2; end
	local item = menu:addChild(GUI.adaptiveButton(x, 1, 1, 0, nil, textColor or menu.colors.default.text, menu.colors.pressed.background, menu.colors.pressed.text, text))
	item.eventHandler = menuItemEventHandler

	return item
end

function GUI.menu(x, y, width, backgroundColor, textColor, backgroundPressedColor, textPressedColor, backgroundTransparency)
	local menu = GUI.container(x, y, width, 1)
	
	menu.colors = {
		default = {
			background = backgroundColor,
			text = textColor,
		},
		pressed = {
			background = backgroundPressedColor,
			text = textPressedColor,
		},
		transparency = backgroundTransparency
	}
	menu.addItem = menuAddItem
	menu.reimplementedDraw = menu.draw
	menu.draw = menuDraw

	return menu
end

----------------------------------------- ProgressBar Object -----------------------------------------

local function drawProgressBar(object)
	local activeWidth = math.floor(object.value * object.width / 100)
	if object.thin then
		buffer.text(object.x, object.y, object.colors.passive, string.rep("━", object.width))
		buffer.text(object.x, object.y, object.colors.active, string.rep("━", activeWidth))
	else
		buffer.square(object.x, object.y, object.width, object.height, object.colors.passive, 0x0, " ")
		buffer.square(object.x, object.y, activeWidth, object.height, object.colors.active, 0x0, " ")
	end

	if object.showValue then
		local stringValue = tostring((object.valuePrefix or "") .. object.value .. (object.valuePostfix or ""))
		buffer.text(math.floor(object.x + object.width / 2 - unicode.len(stringValue) / 2), object.y + 1, object.colors.value, stringValue)
	end

	return object
end

function GUI.progressBar(x, y, width, activeColor, passiveColor, valueColor, value, thin, showValue, valuePrefix, valuePostfix)
	local object = GUI.object(x, y, width, 1)
	
	object.value = value
	object.colors = {active = activeColor, passive = passiveColor, value = valueColor}
	object.thin = thin
	object.draw = drawProgressBar
	object.showValue = showValue
	object.valuePrefix = valuePrefix
	object.valuePostfix = valuePostfix
	
	return object
end

----------------------------------------- Other GUI elements -----------------------------------------

function GUI.windowShadow(x, y, width, height, transparency, thin)
	transparency = transparency
	if thin then
		buffer.square(x + width, y + 1, 1, height - 1, 0x000000, 0x000000, " ", transparency)
		buffer.text(x + 1, y + height, 0x000000, string.rep("▀", width), transparency)
		buffer.text(x + width, y, 0x000000, "▄", transparency)
	else
		buffer.square(x + width, y + 1, 2, height, 0x000000, 0x000000, " ", transparency)
		buffer.square(x + 2, y + height, width - 2, 1, 0x000000, 0x000000, " ", transparency)
	end
end

function GUI.roundedCorners(x, y, width, height, color, transparency)
	buffer.text(x - 1, y, color, "⠰", transparency)
	buffer.text(x + width, y, color, "⠆", transparency)
end

------------------------------------------------- Error window -------------------------------------------------------------------

function GUI.error(...)
	local args = {...}
	for i = 1, #args do
		if type(args[i]) == "table" then
			args[i] = table.toString(args[i], true)
		else
			args[i] = tostring(args[i])
		end
	end
	if #args == 0 then args[1] = "nil" end

	local sign = image.fromString([[06030000FF 0000FF 00F7FF▟00F7FF▙0000FF 0000FF 0000FF 00F7FF▟F7FF00 F7FF00 00F7FF▙0000FF 00F7FF▟F7FF00CF7FF00yF7FF00kF7FF00a00F7FF▙]])
	local offset = 2
	local lines = #args > 1 and "\"" .. table.concat(args, "\", \"") .. "\"" or args[1]
	local bufferWidth, bufferHeight = buffer.getResolution()
	local width = math.floor(bufferWidth * 0.5)
	local textWidth = width - image.getWidth(sign) - 2

	lines = string.wrap(lines, textWidth)
	local height = image.getHeight(sign)
	if #lines + 2 > height then
		height = #lines + 2
	end

	local mainContainer = GUI.container(1, math.floor(bufferHeight / 2 - height / 2), bufferWidth, height + offset * 2)
	local oldPixels = buffer.copy(mainContainer.x, mainContainer.y, mainContainer.width, mainContainer.height)

	local x, y = math.floor(bufferWidth / 2 - width / 2), offset + 1
	mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x1D1D1D))
	mainContainer:addChild(GUI.image(x, y, sign))
	mainContainer:addChild(GUI.textBox(x + image.getWidth(sign) + 2, y, textWidth, #lines, 0x1D1D1D, 0xE1E1E1, lines, 1, 0, 0)).eventHandler = nil
	local buttonWidth = 10
	local button = mainContainer:addChild(GUI.roundedButton(x + image.getWidth(sign) + textWidth - buttonWidth + 2, mainContainer.height - offset, buttonWidth, 1, 0x3366CC, 0xE1E1E1, 0xE1E1E1, 0x3366CC, "OK"))
	
	button.onTouch = function()
		mainContainer:stopEventHandling()
		buffer.paste(mainContainer.x, mainContainer.y, oldPixels)
		buffer.draw()
	end

	mainContainer.eventHandler = function(mainContainer, object, eventData)
		if eventData[1] == "key_down" and eventData[4] == 28 then
			button:pressAndRelease()
			button.onTouch()
		end
	end

	mainContainer:draw()
	buffer.draw(true)
	mainContainer:startEventHandling()
end

----------------------------------------- CodeView object -----------------------------------------

local function codeViewDraw(codeView)
	local syntax = require("syntax")
	local toLine = codeView.fromLine + codeView.height - 1

	-- Line numbers bar and code area
	codeView.lineNumbersWidth = unicode.len(tostring(toLine)) + 2
	codeView.codeAreaPosition = codeView.x + codeView.lineNumbersWidth
	codeView.codeAreaWidth = codeView.width - codeView.lineNumbersWidth
	buffer.square(codeView.x, codeView.y, codeView.lineNumbersWidth, codeView.height, syntax.colorScheme.lineNumbersBackground, syntax.colorScheme.lineNumbersText, " ")	
	buffer.square(codeView.codeAreaPosition, codeView.y, codeView.codeAreaWidth, codeView.height, syntax.colorScheme.background, syntax.colorScheme.text, " ")

	-- Line numbers texts
	local y = codeView.y
	for line = codeView.fromLine, toLine do
		if codeView.lines[line] then
			local text = tostring(line)
			if codeView.highlights[line] then
				buffer.square(codeView.x, y, codeView.lineNumbersWidth, 1, codeView.highlights[line], syntax.colorScheme.text, " ", 0.3)
				buffer.square(codeView.codeAreaPosition, y, codeView.codeAreaWidth, 1, codeView.highlights[line], syntax.colorScheme.text, " ")
			end
			buffer.text(codeView.codeAreaPosition - unicode.len(text) - 1, y, syntax.colorScheme.lineNumbersText, text)
			y = y + 1
		else
			break
		end	
	end

	local oldDrawLimitX1, oldDrawLimitY1, oldDrawLimitX2, oldDrawLimitY2 = buffer.getDrawLimit()
	buffer.setDrawLimit(codeView.codeAreaPosition, codeView.y, codeView.codeAreaPosition + codeView.codeAreaWidth - 1, codeView.y + codeView.height - 1)

	local function drawUpperSelection(y, selectionIndex)
		buffer.square(
			codeView.codeAreaPosition + codeView.selections[selectionIndex].from.symbol - codeView.fromSymbol + 1,
			y + codeView.selections[selectionIndex].from.line - codeView.fromLine,
			codeView.codeAreaWidth - codeView.selections[selectionIndex].from.symbol + codeView.fromSymbol - 1,
			1,
			codeView.selections[selectionIndex].color or syntax.colorScheme.selection, syntax.colorScheme.text, " "
		)
	end

	local function drawLowerSelection(y, selectionIndex)
		buffer.square(
			codeView.codeAreaPosition,
			y + codeView.selections[selectionIndex].from.line - codeView.fromLine,
			codeView.selections[selectionIndex].to.symbol - codeView.fromSymbol + 2,
			1,
			codeView.selections[selectionIndex].color or syntax.colorScheme.selection, syntax.colorScheme.text, " "
		)
	end

	if #codeView.selections > 0 then
		for selectionIndex = 1, #codeView.selections do
			y = codeView.y
			local dy = codeView.selections[selectionIndex].to.line - codeView.selections[selectionIndex].from.line
			if dy == 0 then
				buffer.square(
					codeView.codeAreaPosition + codeView.selections[selectionIndex].from.symbol - codeView.fromSymbol + 1,
					y + codeView.selections[selectionIndex].from.line - codeView.fromLine,
					codeView.selections[selectionIndex].to.symbol - codeView.selections[selectionIndex].from.symbol + 1,
					1,
					codeView.selections[selectionIndex].color or syntax.colorScheme.selection, syntax.colorScheme.text, " "
				)
			elseif dy == 1 then
				drawUpperSelection(y, selectionIndex); y = y + 1
				drawLowerSelection(y, selectionIndex)
			else
				drawUpperSelection(y, selectionIndex); y = y + 1
				for i = 1, dy - 1 do
					buffer.square(codeView.codeAreaPosition, y + codeView.selections[selectionIndex].from.line - codeView.fromLine, codeView.codeAreaWidth, 1, codeView.selections[selectionIndex].color or syntax.colorScheme.selection, syntax.colorScheme.text, " "); y = y + 1
				end

				drawLowerSelection(y, selectionIndex)
			end
		end
	end

	-- Code strings
	y = codeView.y
	buffer.setDrawLimit(codeView.codeAreaPosition + 1, y, codeView.codeAreaPosition + codeView.codeAreaWidth - 2, y + codeView.height - 1)
	for i = codeView.fromLine, toLine do
		if codeView.lines[i] then
			if codeView.highlightLuaSyntax then
				syntax.highlightString(codeView.codeAreaPosition - codeView.fromSymbol + 2, y, codeView.lines[i], codeView.indentationWidth)
			else
				buffer.text(codeView.codeAreaPosition - codeView.fromSymbol + 2, y, syntax.colorScheme.text, codeView.lines[i])
			end
			y = y + 1
		else
			break
		end
	end
	buffer.setDrawLimit(oldDrawLimitX1, oldDrawLimitY1, oldDrawLimitX2, oldDrawLimitY2)

	if #codeView.lines > codeView.height then
		codeView.scrollBars.vertical.hidden = false
		codeView.scrollBars.vertical.colors.background, codeView.scrollBars.vertical.colors.foreground = syntax.colorScheme.scrollBarBackground, syntax.colorScheme.scrollBarForeground
		codeView.scrollBars.vertical.minimumValue, codeView.scrollBars.vertical.maximumValue, codeView.scrollBars.vertical.value, codeView.scrollBars.vertical.shownValueCount = 1, #codeView.lines, codeView.fromLine, codeView.height
		codeView.scrollBars.vertical.localX = codeView.width
		codeView.scrollBars.vertical.localY = 1
		codeView.scrollBars.vertical.height = codeView.height - 1
	else
		codeView.scrollBars.vertical.hidden = true
	end

	if codeView.maximumLineLength > codeView.codeAreaWidth - 2 then
		codeView.scrollBars.horizontal.hidden = false
		codeView.scrollBars.horizontal.colors.background, codeView.scrollBars.horizontal.colors.foreground = syntax.colorScheme.scrollBarBackground, syntax.colorScheme.scrollBarForeground
		codeView.scrollBars.horizontal.minimumValue, codeView.scrollBars.horizontal.maximumValue, codeView.scrollBars.horizontal.value, codeView.scrollBars.horizontal.shownValueCount = 1, codeView.maximumLineLength, codeView.fromSymbol, codeView.codeAreaWidth - 2
		codeView.scrollBars.horizontal.localX = codeView.lineNumbersWidth + 1
		codeView.scrollBars.horizontal.localY = codeView.height
		codeView.scrollBars.horizontal.width = codeView.codeAreaWidth - 1
	else
		codeView.scrollBars.horizontal.hidden = true
	end

	codeView:reimplementedDraw()
end

function GUI.codeView(x, y, width, height, lines, fromSymbol, fromLine, maximumLineLength, selections, highlights, highlightLuaSyntax, indentationWidth)
	local codeView = GUI.container(x, y, width, height)
	
	codeView.lines = lines
	codeView.fromSymbol = fromSymbol
	codeView.fromLine = fromLine
	codeView.maximumLineLength = maximumLineLength
	codeView.selections = selections or {}
	codeView.highlights = highlights or {}
	codeView.highlightLuaSyntax = highlightLuaSyntax
	codeView.indentationWidth = indentationWidth

	codeView.scrollBars = {
		vertical = codeView:addChild(GUI.scrollBar(1, 1, 1, 1, 0x0, 0x0, 1, 1, 1, 1, 1, true)),
		horizontal = codeView:addChild(GUI.scrollBar(1, 1, 1, 1, 0x0, 0x0, 1, 1, 1, 1, 1, true))
	}

	codeView.reimplementedDraw = codeView.draw
	codeView.draw = codeViewDraw

	return codeView
end 

----------------------------------------- Color Selector object -----------------------------------------

local function colorSelectorDraw(colorSelector)
	local overlayColor = colorSelector.color < 0x7FFFFF and 0xFFFFFF or 0x000000
	buffer.square(colorSelector.x, colorSelector.y, colorSelector.width, colorSelector.height, colorSelector.color, overlayColor, " ")
	if colorSelector.pressed then
		buffer.square(colorSelector.x, colorSelector.y, colorSelector.width, colorSelector.height, overlayColor, overlayColor, " ", 0.8)
	end
	if colorSelector.height > 1 then
		buffer.text(colorSelector.x, colorSelector.y + colorSelector.height - 1, overlayColor, string.rep("▄", colorSelector.width), 0.8)
	end
	buffer.text(colorSelector.x + 1, colorSelector.y + math.floor(colorSelector.height / 2), overlayColor, string.limit(colorSelector.text, colorSelector.width - 2))
	return colorSelector
end

local function colorSelectorEventHandler(mainContainer, object, eventData)
	if eventData[1] == "touch" then
		object.pressed = true
		mainContainer:draw()
		buffer.draw()
		
		object.color = require("palette").show(math.floor(mainContainer.width / 2 - 35), math.floor(mainContainer.height / 2 - 12), object.color) or object.color
		
		object.pressed = false
		mainContainer:draw()
		buffer.draw()
		callMethod(object.onTouch, eventData)
	end
end

function GUI.colorSelector(x, y, width, height, color, text)
	local colorSelector = GUI.object(x, y, width, height)
	
	colorSelector.eventHandler = colorSelectorEventHandler
	colorSelector.color = color
	colorSelector.text = text
	colorSelector.draw = colorSelectorDraw
	
	return colorSelector
end 

----------------------------------------- Chart object -----------------------------------------

local function getAxisValue(number, postfix, roundValues)
	if roundValues then
		return math.floor(number) .. postfix
	else
		local integer, fractional = math.modf(number)
		local firstPart, secondPart = "", ""
		if math.abs(integer) >= 1000 then
			return math.shortenNumber(integer, 2) .. postfix
		else
			if math.abs(fractional) > 0 then
				return string.format("%.2f", number) .. postfix
			else
				return number .. postfix
			end
		end
	end
end

local function drawChart(object)
	-- Sorting by x value
	local valuesCopy = {}
	for i = 1, #object.values do valuesCopy[i] = object.values[i] end
	table.sort(valuesCopy, function(a, b) return a[1] < b[1] end)
	
	if #valuesCopy == 0 then valuesCopy = {{0, 0}} end

	-- Max, min, deltas
	local xMin, xMax, yMin, yMax = valuesCopy[1][1], valuesCopy[#valuesCopy][1], valuesCopy[1][2], valuesCopy[1][2]
	for i = 1, #valuesCopy do yMin, yMax = math.min(yMin, valuesCopy[i][2]), math.max(yMax, valuesCopy[i][2]) end
	local dx, dy = xMax - xMin, yMax - yMin

	-- y axis values and helpers
	local value, chartHeight, yAxisValueMaxWidth, yAxisValues = yMin, object.height - 1 - (object.showXAxisValues and 1 or 0), 0, {}
	for y = object.y + object.height - 3, object.y + 1, -chartHeight * object.yAxisValueInterval do
		local stringValue = getAxisValue(value, object.yAxisPostfix, object.roundValues)
		yAxisValueMaxWidth = math.max(yAxisValueMaxWidth, unicode.len(stringValue))
		table.insert(yAxisValues, {y = math.ceil(y), value = stringValue})
		value = value + dy * object.yAxisValueInterval
	end
	local stringValue = getAxisValue(yMax, object.yAxisPostfix, object.roundValues)
	table.insert(yAxisValues, {y = object.y, value = stringValue})
	yAxisValueMaxWidth = math.max(yAxisValueMaxWidth, unicode.len(stringValue))

	local chartWidth = object.width - (object.showYAxisValues and yAxisValueMaxWidth + 2 or 0) 
	local chartX = object.x + object.width - chartWidth
	for i = 1, #yAxisValues do
		if object.showYAxisValues then
			buffer.text(chartX - unicode.len(yAxisValues[i].value) - 2, yAxisValues[i].y, object.colors.axisValue, yAxisValues[i].value)
		end
		buffer.text(chartX, yAxisValues[i].y, object.colors.helpers, string.rep("─", chartWidth))
	end

	-- x axis values
	if object.showXAxisValues then
		value = xMin
		for x = chartX, chartX + chartWidth - 2, chartWidth * object.xAxisValueInterval do
			local stringValue = getAxisValue(value, object.xAxisPostfix, object.roundValues)
			buffer.text(math.floor(x - unicode.len(stringValue) / 2), object.y + object.height - 1, object.colors.axisValue, stringValue)
			value = value + dx * object.xAxisValueInterval
		end
		local value = getAxisValue(xMax, object.xAxisPostfix, object.roundValues)
		buffer.text(object.x + object.width - unicode.len(value), object.y + object.height - 1, object.colors.axisValue, value)
	end

	-- Axis lines
	for y = object.y, object.y + chartHeight - 1 do
		buffer.text(chartX - 1, y, object.colors.axis, "┨")
	end
	buffer.text(chartX - 1, object.y + chartHeight, object.colors.axis, "┗" .. string.rep("┯━", math.floor(chartWidth / 2)))

	local function fillVerticalPart(x1, y1, x2, y2)
		local dx, dy = x2 - x1, y2 - y1
		local absdx, absdy = math.abs(dx), math.abs(dy)
		if absdx >= absdy then
			local step, y = dy / absdx, y1
			for x = x1, x2, (x1 < x2 and 1 or -1) do
				local yFloor = math.floor(y)
				buffer.semiPixelSquare(math.floor(x), yFloor, 1, math.floor(object.y + chartHeight) * 2 - yFloor - 1, object.colors.chart)
				y = y + step
			end
		else
			local step, x = dx / absdy, x1
			for y = y1, y2, (y1 < y2 and 1 or -1) do
				local yFloor = math.floor(y)
				buffer.semiPixelSquare(math.floor(x), yFloor, 1, math.floor(object.y + chartHeight) * 2 - yFloor - 1, object.colors.chart)
				x = x + step
			end
		end
	end

	-- chart
	for i = 1, #valuesCopy - 1 do
		local x = math.floor(chartX + (valuesCopy[i][1] - xMin) / dx * (chartWidth - 1))
		local y = math.floor(object.y + chartHeight - 1 - (valuesCopy[i][2] - yMin) / dy * (chartHeight - 1)) * 2
		local xNext = math.floor(chartX + (valuesCopy[i + 1][1] - xMin) / dx * (chartWidth - 1))
		local yNext = math.floor(object.y + chartHeight - 1 - (valuesCopy[i + 1][2] - yMin) / dy * (chartHeight - 1)) * 2
		if object.fillChartArea then
			fillVerticalPart(x, y, xNext, yNext)
		else
			buffer.semiPixelLine(x, y, xNext, yNext, object.colors.chart)
		end
	end

	return object
end

function GUI.chart(x, y, width, height, axisColor, axisValueColor, axisHelpersColor, chartColor, xAxisValueInterval, yAxisValueInterval, xAxisPostfix, yAxisPostfix, fillChartArea, values)
	local object = GUI.object(x, y, width, height)

	object.colors = {axis = axisColor, chart = chartColor, axisValue = axisValueColor, helpers = axisHelpersColor}
	object.draw = drawChart
	object.values = values or {}
	object.xAxisPostfix = xAxisPostfix
	object.yAxisPostfix = yAxisPostfix
	object.xAxisValueInterval = xAxisValueInterval
	object.yAxisValueInterval = yAxisValueInterval
	object.fillChartArea = fillChartArea
	object.showYAxisValues = true
	object.showXAxisValues = true

	return object
end

----------------------------------------- Window object -----------------------------------------

local function windowDraw(window)
	GUI.windowShadow(window.x, window.y, window.width, window.height, nil, true)
	GUI.drawContainerContent(window)
	return window
end

local function windowCheck(container, x, y)
	for i = #container.children, 1, -1 do
		if container.children[i].children then
			if windowCheck(container.children[i], x, y) then
				return true
			end
		elseif container.children[i].eventHandler and container.children[i]:isClicked(x, y) then
			return true
		end
	end
end

local function windowEventHandler(mainContainer, object, eventData)
	if eventData[1] == "touch" then
		object.lastTouchPosition = object.lastTouchPosition or {}
		object.lastTouchPosition.x, object.lastTouchPosition.y = eventData[3], eventData[4]
		
		if object ~= object.parent.children[#object.parent.children] then
			object:moveToFront()
			mainContainer:draw()
			buffer.draw()
		end
	elseif eventData[1] == "drag" and object.lastTouchPosition and not windowCheck(object, eventData[3], eventData[4]) then
		local xOffset, yOffset = eventData[3] - object.lastTouchPosition.x, eventData[4] - object.lastTouchPosition.y
		object.lastTouchPosition.x, object.lastTouchPosition.y = eventData[3], eventData[4]

		if xOffset ~= 0 or yOffset ~= 0 then
			object.localX, object.localY = object.localX + xOffset, object.localY + yOffset
			mainContainer:draw()
			buffer.draw()
		end
	elseif eventData[1] == "drop" then
		object.lastTouchPosition = nil
	elseif eventData[1] == "key_down" then
		-- Ctrl or CMD
		if keyboard.isKeyDown(29) or keyboard.isKeyDown(219) then
			-- W
			if eventData[4] == 17 then
				if object == object.parent.children[#object.parent.children] and not eventData.windowHandled then
					eventData.windowHandled = true
					object:close()
					mainContainer:draw()
					buffer.draw()
				end
			end
		end
	end
end

function GUI.window(x, y, width, height)
	local window = GUI.container(x, y, width, height)
	
	window.eventHandler = windowEventHandler
	window.draw = windowDraw

	return window
end

function GUI.filledWindow(x, y, width, height, backgroundColor)
	local window = GUI.window(x, y, width, height)

	window.backgroundPanel = window:addChild(GUI.panel(1, 1, width, height, backgroundColor))
	window.actionButtons = window:addChild(GUI.actionButtons(2, 2, false))

	return window
end

function GUI.titledWindow(x, y, width, height, title, addTitlePanel)
	local window = GUI.filledWindow(x, y, width, height, GUI.colors.windows.backgroundPanel)

	if addTitlePanel then
		window.titlePanel = window:addChild(GUI.panel(1, 1, width, 1, GUI.colors.windows.title.background))
		window.backgroundPanel.localY, window.backgroundPanel.height = 2, window.height - 1
	end
	window.titleLabel = window:addChild(GUI.label(1, 1, width, height, GUI.colors.windows.title.text, title)):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	window.actionButtons.localY = 1
	window.actionButtons:moveToFront()

	return window
end

function GUI.tabbedWindow(x, y, width, height, ...)
	local window = GUI.filledWindow(x, y, width, height, GUI.colors.windows.backgroundPanel)

	window.tabBar = window:addChild(GUI.tabBar(1, 1, window.width, 3, 2, 0, GUI.colors.windows.tabBar.default.background, GUI.colors.windows.tabBar.default.text, GUI.colors.windows.tabBar.selected.background, GUI.colors.windows.tabBar.selected.text, ...))
	window.backgroundPanel.localY, window.backgroundPanel.height = 4, window.height - 3
	window.actionButtons:moveToFront()
	window.actionButtons.localY = 2

	return window
end

----------------------------------------- Dropdown Menu -----------------------------------------

local function dropDownMenuItemDraw(item)
	local yText = item.y + math.floor(item.height / 2)

	if item.type == GUI.dropDownMenuElementTypes.default then
		local textColor = item.color or item.parent.parent.colors.default.text

		if item.pressed then
			textColor = item.parent.parent.colors.pressed.text
			buffer.square(item.x, item.y, item.width, item.height, item.parent.parent.colors.pressed.background, textColor, " ")
		elseif item.disabled then
			textColor = item.parent.parent.colors.disabled.text
		end

		buffer.text(item.x + 1, yText, textColor, item.text)
		if item.shortcut then
			buffer.text(item.x + item.width - unicode.len(item.shortcut) - 1, yText, textColor, item.shortcut)
		end
	else
		buffer.text(item.x, yText, item.parent.parent.colors.separator, string.rep("─", item.width))
	end

	return item
end

local function dropDownMenuItemEventHandler(mainContainer, object, eventData)
	if eventData[1] == "touch" then
		if object.type == GUI.dropDownMenuElementTypes.default then
			object.pressed = true
			mainContainer:draw()
			buffer.draw()

			if object.subMenu then
				object.subMenu.y = object.parent.y + object.localY - 1
				object.subMenu.x = object.parent.x + object.parent.width
				if buffer.getWidth() - object.parent.x - object.parent.width + 1 < object.subMenu.width then
					object.subMenu.x = object.parent.x - object.subMenu.width
				end

				object.subMenu:show()
			else
				os.sleep(0.2)
			end

			object.pressed = false
			mainContainer:draw()
			buffer.draw()
			mainContainer.selectedItem = object:indexOf()

			callMethod(object.onTouch)
		end

		mainContainer:stopEventHandling()
	end
end

local function dropDownMenuCalculateSizes(menu)
	local totalHeight = 0
	for i = 1, #menu.itemsContainer.children do
		totalHeight = totalHeight + (menu.itemsContainer.children[i].type == GUI.dropDownMenuElementTypes.separator and 1 or menu.itemHeight)
		menu.itemsContainer.children[i].width = menu.width
	end
	menu.height = math.min(totalHeight, menu.maximumHeight, buffer.getHeight() - menu.y)
	menu.itemsContainer.width, menu.itemsContainer.height = menu.width, menu.height

	menu.nextButton.localY = menu.height
	menu.prevButton.width, menu.nextButton.width = menu.width, menu.width
	menu.prevButton.hidden = menu.itemsContainer.children[1].localY >= 1
	menu.nextButton.hidden = menu.itemsContainer.children[#menu.itemsContainer.children].localY + menu.itemsContainer.children[#menu.itemsContainer.children].height - 1 <= menu.height
end

local function dropDownMenuAddItem(menu, text, disabled, shortcut, color)
	local item = menu.itemsContainer:addChild(GUI.object(1, #menu.itemsContainer.children == 0 and 1 or menu.itemsContainer.children[#menu.itemsContainer.children].localY + menu.itemsContainer.children[#menu.itemsContainer.children].height, menu.width, menu.itemHeight))

	item.type = GUI.dropDownMenuElementTypes.default
	item.text = text
	item.disabled = disabled
	item.shortcut = shortcut
	item.color = color
	item.draw = dropDownMenuItemDraw
	item.eventHandler = dropDownMenuItemEventHandler

	dropDownMenuCalculateSizes(menu)

	return item
end

local function dropDownMenuAddSeparator(menu)
	local item = dropDownMenuAddItem(menu)
	item.type = GUI.dropDownMenuElementTypes.separator
	item.height = 1

	return item
end

local function dropDownMenuScrollDown(menu)
	if menu.itemsContainer.children[1].localY < 1 then
		for i = 1, #menu.itemsContainer.children do
			menu.itemsContainer.children[i].localY = menu.itemsContainer.children[i].localY + 1
		end
	end
	menu:draw()
	buffer.draw()
end

local function dropDownMenuScrollUp(menu)
	if menu.itemsContainer.children[#menu.itemsContainer.children].localY + menu.itemsContainer.children[#menu.itemsContainer.children].height - 1 > menu.height then
		for i = 1, #menu.itemsContainer.children do
			menu.itemsContainer.children[i].localY = menu.itemsContainer.children[i].localY - 1
		end
	end
	menu:draw()
	buffer.draw()
end

local function dropDownMenuEventHandler(mainContainer, object, eventData)
	if eventData[1] == "scroll" then
		if eventData[5] == 1 then
			dropDownMenuScrollDown(object)
		else
			dropDownMenuScrollUp(object)
		end
	end
end

local function dropDownMenuDraw(menu)
	dropDownMenuCalculateSizes(menu)

	if menu.oldPixels then
		buffer.paste(menu.x, menu.y, menu.oldPixels)
	else
		menu.oldPixels = buffer.copy(menu.x, menu.y, menu.width + 1, menu.height + 1)
	end

	buffer.square(menu.x, menu.y, menu.width, menu.height, menu.colors.default.background, menu.colors.default.text, " ", menu.colors.transparency.background)
	GUI.drawContainerContent(menu)
	GUI.windowShadow(menu.x, menu.y, menu.width, menu.height, menu.colors.transparency.shadow, true)

	return menu
end

local function dropDownMenuShow(menu)
	local mainContainer = GUI.fullScreenContainer()
	mainContainer:addChild(GUI.object(1, 1, mainContainer.width, mainContainer.height)).eventHandler = function(mainContainer, object, eventData)
		if eventData[1] == "touch" then
			buffer.paste(menu.x, menu.y, menu.oldPixels)
			buffer.draw()
			mainContainer:stopEventHandling()
		end
	end
	mainContainer:addChild(menu)
	
	menu:draw()
	buffer.draw()
	mainContainer:startEventHandling()
	buffer.paste(menu.x, menu.y, menu.oldPixels)
	buffer.draw()
	
	if mainContainer.selectedItem then
		return menu.itemsContainer.children[mainContainer.selectedItem].text, mainContainer.selectedItem
	end
end

function GUI.dropDownMenu(x, y, width, maximumHeight, itemHeight, backgroundColor, textColor, backgroundPressedColor, textPressedColor, disabledColor, separatorColor, backgroundTransparency, shadowTransparency)
	local menu = GUI.container(x, y, width, 1)
	
	menu.colors = {
		default = {
			background = backgroundColor,
			text = textColor
		},
		pressed = {
			background = backgroundPressedColor,
			text = textPressedColor
		},
		disabled = {
			text = disabledColor
		},
		separator = separatorColor,
		transparency = {
			background = backgroundTransparency,
			shadow = shadowTransparency
		}
	}

	menu.itemsContainer = menu:addChild(GUI.container(1, 1, menu.width, menu.height))
	menu.prevButton = menu:addChild(GUI.button(1, 1, menu.width, 1, backgroundColor, textColor, backgroundPressedColor, textPressedColor, "▲"))
	menu.nextButton = menu:addChild(GUI.button(1, 1, menu.width, 1, backgroundColor, textColor, backgroundPressedColor, textPressedColor, "▼"))
	menu.prevButton.colors.default.transparency, menu.nextButton.colors.default.transparency = backgroundTransparency, backgroundTransparency
	menu.prevButton.onTouch = function()
		dropDownMenuScrollDown(menu)
	end
	menu.nextButton.onTouch = function()
		dropDownMenuScrollUp(menu)
	end

	menu.itemHeight = itemHeight
	menu.addSeparator = dropDownMenuAddSeparator
	menu.addItem = dropDownMenuAddItem
	menu.draw = dropDownMenuDraw
	menu.show = dropDownMenuShow
	menu.maximumHeight = maximumHeight
	menu.eventHandler = dropDownMenuEventHandler

	return menu
end

----------------------------------------- Context Menu -----------------------------------------

local function contextMenuCalculate(menu)
	local widestItem, widestShortcut = 0, 0
	for i = 1, #menu.itemsContainer.children do
		if menu.itemsContainer.children[i].type == GUI.dropDownMenuElementTypes.default then
			widestItem = math.max(widestItem, unicode.len(menu.itemsContainer.children[i].text))
			if menu.itemsContainer.children[i].shortcut then
				widestShortcut = math.max(widestShortcut, unicode.len(menu.itemsContainer.children[i].shortcut))
			end
		end
	end
	menu.width = 2 + widestItem + (widestShortcut > 0 and 3 + widestShortcut or 0)
	menu.height = #menu.itemsContainer.children
end

local function contextMenuShow(menu)
	contextMenuCalculate(menu)

	local bufferWidth, bufferHeight = buffer.getResolution()
	if menu.y + menu.height >= bufferHeight then menu.y = bufferHeight - menu.height end
	if menu.x + menu.width + 1 >= bufferWidth then menu.x = bufferWidth - menu.width - 1 end

	return dropDownMenuShow(menu)
end

local function contextMenuAddItem(menu, ...)
	contextMenuCalculate(menu)
	return dropDownMenuAddItem(menu, ...)
end

local function contextMenuAddSeparator(menu, ...)
	contextMenuCalculate(menu)
	return dropDownMenuAddSeparator(menu, ...)
end

local function contextMenuAddSubMenu(menu, text)
	local item = menu:addItem(text, false, "►")
	item.subMenu = GUI.contextMenu(1, 1)
	item.subMenu.colors = menu.colors
	
	return item.subMenu
end

function GUI.contextMenu(x, y, backgroundColor, textColor, backgroundPressedColor, textPressedColor, disabledColor, separatorColor, backgroundTransparency, shadowTransparency)
	local menu = GUI.dropDownMenu(x, y, 1, math.ceil(buffer.getHeight() * 0.5), 1,
		backgroundColor or GUI.colors.contextMenu.default.background,
		textColor or GUI.colors.contextMenu.default.text,
		backgroundPressedColor or GUI.colors.contextMenu.pressed.background,
		textPressedColor or GUI.colors.contextMenu.pressed.text,
		disabledColor or GUI.colors.contextMenu.disabled,
		separatorColor or GUI.colors.contextMenu.separator,
		backgroundTransparency or GUI.colors.contextMenu.transparency.background,
		shadowTransparency or GUI.colors.contextMenu.transparency.shadow
	)
	
	menu.colors.transparency.background = menu.colors.transparency.background or GUI.colors.contextMenu.transparency.background
	menu.colors.transparency.shadow = menu.colors.transparency.shadow or GUI.colors.contextMenu.transparency.shadow
	
	menu.show = contextMenuShow
	menu.addSubMenu = contextMenuAddSubMenu
	menu.addItem = contextMenuAddItem
	menu.addSeparator = contextMenuAddSeparator

	return menu
end

----------------------------------------- Combo Box Object -----------------------------------------

local function drawComboBox(object)
	buffer.square(object.x, object.y, object.width, object.height, object.colors.default.background, object.colors.default.text, " ")
	local x, y, limit, arrowSize = object.x + 1, math.floor(object.y + object.height / 2), object.width - 3, object.height
	if object.dropDownMenu.itemsContainer.children[object.selectedItem] then
		buffer.text(x, y, object.colors.default.text, string.limit(object.dropDownMenu.itemsContainer.children[object.selectedItem].text, limit, "right"))
	end
	GUI.button(object.x + object.width - arrowSize * 2 + 1, object.y, arrowSize * 2 - 1, arrowSize, object.colors.arrow.background, object.colors.arrow.text, 0x0, 0x0, object.pressed and "▲" or "▼"):draw()

	return object
end

local function comboBoxGetItem(object, index)
	return object.dropDownMenu.itemsContainer.children[index]
end

local function comboBoxClear(object)
	object.dropDownMenu.itemsContainer:deleteChildren()

	return object
end

local function comboBoxIndexOfItem(object, text)
	for i = 1, #object.dropDownMenu.itemsContainer.children do
		if object.dropDownMenu.itemsContainer.children[i].text == text then
			return i
		end
	end
end

local function selectComboBoxItem(object)
	object.pressed = true
	object:draw()

	object.dropDownMenu.x, object.dropDownMenu.y = object.x, object.y + object.height
	object.dropDownMenu.width = object.width
	local _, selectedItem = object.dropDownMenu:show()

	object.selectedItem = selectedItem or object.selectedItem
	object.pressed = false
	object:draw()
	buffer.draw()

	return object
end

local function comboBoxEventHandler(mainContainer, object, eventData)
	if eventData[1] == "touch" then
		object:selectItem()
		callMethod(object.onItemSelected, object.dropDownMenu.itemsContainer.children[object.selectedItem], eventData)
	end
end

local function comboBoxAddItem(object, ...)
	return object.dropDownMenu:addItem(...)
end

local function comboBoxAddSeparator(object)
	return object.dropDownMenu:addSeparator()
end

function GUI.comboBox(x, y, width, elementHeight, backgroundColor, textColor, arrowBackgroundColor, arrowTextColor)
	local object = GUI.object(x, y, width, elementHeight)
	
	object.eventHandler = comboBoxEventHandler
	object.colors = {
		default = {
			background = backgroundColor,
			text = textColor
		},
		pressed = {
			background = GUI.colors.contextMenu.pressed.background,
			text = GUI.colors.contextMenu.pressed.text
		},
		arrow = {
			background = arrowBackgroundColor,
			text = arrowTextColor
		}
	}

	object.dropDownMenu = GUI.dropDownMenu(1, 1, 1, math.ceil(buffer.getHeight() * 0.5), elementHeight,
		object.colors.default.background, 
		object.colors.default.text, 
		object.colors.pressed.background,
		object.colors.pressed.text,
		GUI.colors.contextMenu.disabled,
		GUI.colors.contextMenu.separator,
		GUI.colors.contextMenu.transparency.background, 
		GUI.colors.contextMenu.transparency.shadow
	)
	object.selectedItem = 1
	object.addItem = comboBoxAddItem
	object.addSeparator = comboBoxAddSeparator
	object.draw = drawComboBox
	object.selectItem = selectComboBoxItem
	object.clear = comboBoxClear
	object.indexOfItem = comboBoxIndexOfItem
	object.getItem = comboBoxGetItem

	return object
end

----------------------------------------- Switch and label object -----------------------------------------

local function switchAndLabelDraw(switchAndLabel)
	switchAndLabel.label.width = switchAndLabel.width
	switchAndLabel.switch.localX = switchAndLabel.width - switchAndLabel.switch.width

	switchAndLabel.label.x, switchAndLabel.label.y = switchAndLabel.x + switchAndLabel.label.localX - 1, switchAndLabel.y + switchAndLabel.label.localY - 1
	switchAndLabel.switch.x, switchAndLabel.switch.y = switchAndLabel.x + switchAndLabel.switch.localX - 1, switchAndLabel.y + switchAndLabel.switch.localY - 1
	
	switchAndLabel.label:draw()
	switchAndLabel.switch:draw()

	return switchAndLabel
end

function GUI.switchAndLabel(x, y, width, switchWidth, activeColor, passiveColor, pipeColor, textColor, text, switchState)
	local switchAndLabel = GUI.container(x, y, width, 1)

	switchAndLabel.label = switchAndLabel:addChild(GUI.label(1, 1, width, 1, textColor, text))
	switchAndLabel.switch = switchAndLabel:addChild(GUI.switch(1, 1, switchWidth, activeColor, passiveColor, pipeColor, switchState))
	switchAndLabel.draw = switchAndLabelDraw

	return switchAndLabel 
end

----------------------------------------- Horizontal Slider Object -----------------------------------------

local function sliderDraw(object)
	-- На всякий случай делаем значение не меньше минимального и не больше максимального
	object.value = math.min(math.max(object.value, object.minimumValue), object.maximumValue)
	
	if object.showMaximumAndMinimumValues then
		local stringMaximumValue, stringMinimumValue = tostring(object.roundValues and math.floor(object.maximumValue) or math.roundToDecimalPlaces(object.maximumValue, 2)), tostring(object.roundValues and math.floor(object.minimumValue) or math.roundToDecimalPlaces(object.minimumValue, 2))
		buffer.text(object.x - unicode.len(stringMinimumValue) - 1, object.y, object.colors.value, stringMinimumValue)
		buffer.text(object.x + object.width + 1, object.y, object.colors.value, stringMaximumValue)
	end

	if object.currentValuePrefix or object.currentValuePostfix then
		local stringCurrentValue = (object.currentValuePrefix or "") .. (object.roundValues and math.floor(object.value) or math.roundToDecimalPlaces(object.value, 2)) .. (object.currentValuePostfix or "")
		buffer.text(math.floor(object.x + object.width / 2 - unicode.len(stringCurrentValue) / 2), object.y + 1, object.colors.value, stringCurrentValue)
	end

	local activeWidth = math.floor(object.width - ((object.maximumValue - object.value) * object.width / (object.maximumValue - object.minimumValue)))
	buffer.text(object.x, object.y, object.colors.passive, string.rep("━", object.width))
	buffer.text(object.x, object.y, object.colors.active, string.rep("━", activeWidth))
	buffer.text(object.x + activeWidth - 1, object.y, object.colors.pipe, "⬤")

	return object
end

local function sliderEventHandler(mainContainer, object, eventData)
	if eventData[1] == "touch" or eventData[1] == "drag" then
		local clickPosition = eventData[3] - object.x + 1
		object.value = object.minimumValue + (clickPosition * (object.maximumValue - object.minimumValue) / object.width)
		mainContainer:draw()
		buffer.draw()
		callMethod(object.onValueChanged, object.value, eventData)
	end
end

function GUI.slider(x, y, width, activeColor, passiveColor, pipeColor, valueColor, minimumValue, maximumValue, value, showMaximumAndMinimumValues, currentValuePrefix, currentValuePostfix)
	local object = GUI.object(x, y, width, 1)
	
	object.eventHandler = sliderEventHandler
	object.colors = {active = activeColor, passive = passiveColor, pipe = pipeColor, value = valueColor}
	object.draw = sliderDraw
	object.minimumValue = minimumValue
	object.maximumValue = maximumValue
	object.value = value
	object.showMaximumAndMinimumValues = showMaximumAndMinimumValues
	object.currentValuePrefix = currentValuePrefix
	object.currentValuePostfix = currentValuePostfix
	object.roundValues = false
	
	return object
end

----------------------------------------- Switch object -----------------------------------------

local function switchDraw(switch)
	buffer.text(switch.x - 1, switch.y, switch.colors.passive, "⠰")
	buffer.square(switch.x, switch.y, switch.width, 1, switch.colors.passive, 0x000000, " ")
	buffer.text(switch.x + switch.width, switch.y, switch.colors.passive, "⠆")

	buffer.text(switch.x - 1, switch.y, switch.colors.active, "⠰")
	buffer.square(switch.x, switch.y, switch.pipePosition - 1, 1, switch.colors.active, 0x000000, " ")

	buffer.text(switch.x + switch.pipePosition - 2, switch.y, switch.colors.pipe, "⠰")
	buffer.square(switch.x + switch.pipePosition - 1, switch.y, 2, 1, switch.colors.pipe, 0x000000, " ")
	buffer.text(switch.x + switch.pipePosition + 1, switch.y, switch.colors.pipe, "⠆")
	
	return switch
end

local function switchUpdate(switch)
	switch.pipePosition = switch.state and switch.width - 1 or 1
end

local function switchEventHandler(mainContainer, switch, eventData)
	if eventData[1] == "touch" then
		switch.state = not switch.state
		switch:addAnimation(
			function(mainContainer, switch, animation)
				if switch.state then
					switch.pipePosition = math.round(1 + animation.position * (switch.width - 2))
				else	
					switch.pipePosition = math.round(1 + (1 - animation.position) * (switch.width - 2))
				end
			end,
			function(mainContainer, switch, animation)
				animation:delete()
				callMethod(switch.onStateChanged)
			end
		):start(switch.animationDuration)
	end
end

function GUI.switch(x, y, width, activeColor, passiveColor, pipeColor, state)
	local switch = GUI.object(x, y, width, 1)

	switch.pipePosition = 1
	switch.eventHandler = switchEventHandler
	switch.colors = {
		active = activeColor,
		passive = passiveColor,
		pipe = pipeColor,
	}
	switch.draw = switchDraw
	switch.state = state or false
	switch.update = switchUpdate
	switch.animated = true
	switch.animationDuration = 0.3

	switch:update()
	
	return switch
end

-----------------------------------------------------------------------------------------------------

local function brailleCanvasDraw(brailleCanvas)
	local index, background, foreground, symbol
	for y = 1, brailleCanvas.height do
		for x = 1, brailleCanvas.width do
			index = buffer.getIndex(brailleCanvas.x + x - 1, brailleCanvas.y + y - 1)
			background, foreground, symbol = buffer.rawGet(index)
			buffer.rawSet(index, background, brailleCanvas.pixels[y][x][9], brailleCanvas.pixels[y][x][10])
		end
	end

	return brailleCanvas
end

local function brailleCanvasSet(brailleCanvas, x, y, state, color)
	local xReal, yReal = math.ceil(x / 2), math.ceil(y / 4)
	if xReal <= brailleCanvas.width and yReal <= brailleCanvas.height then
		brailleCanvas.pixels[yReal][xReal][(y - (yReal - 1) * 4 - 1) * 2 + x - (xReal - 1) * 2] = state and 1 or 0
		brailleCanvas.pixels[yReal][xReal][9] = color
		brailleCanvas.pixels[yReal][xReal][10] = unicode.char(
			10240 +
			128 * brailleCanvas.pixels[yReal][xReal][8] +
			64 * brailleCanvas.pixels[yReal][xReal][7] +
			32 * brailleCanvas.pixels[yReal][xReal][6] +
			16 * brailleCanvas.pixels[yReal][xReal][4] +
			8 * brailleCanvas.pixels[yReal][xReal][2] +
			4 * brailleCanvas.pixels[yReal][xReal][5] +
			2 * brailleCanvas.pixels[yReal][xReal][3] +
			brailleCanvas.pixels[yReal][xReal][1]
		)
	end

	return brailleCanvas
end

function GUI.brailleCanvas(x, y, width, height)
	local brailleCanvas = GUI.object(x, y, width, height)
	
	brailleCanvas.pixels = {}
	brailleCanvas.set = brailleCanvasSet
	brailleCanvas.draw = brailleCanvasDraw

	for j = 1, height * 4 do
		brailleCanvas.pixels[j] = {}
		for i = 1, width * 2 do
			brailleCanvas.pixels[j][i] = { 0, 0, 0, 0, 0, 0, 0, 0, 0x0, " " }
		end
	end

	return brailleCanvas
end

----------------------------------------- Layout object -----------------------------------------

local function layoutCheckCell(layout, column, row)
	if column < 1 or column > #layout.columnSizes or row < 1 or row > #layout.rowSizes then
		error("Specified grid position (" .. tostring(column) .. "x" .. tostring(row) .. ") is out of layout grid range")
	end
end

local function layoutGetAbsoluteTotalSize(array)
	local absoluteTotalSize = 0
	for i = 1, #array do
		if array[i].sizePolicy == GUI.sizePolicies.absolute then
			absoluteTotalSize = absoluteTotalSize + array[i].size
		end
	end
	return absoluteTotalSize
end

local function layoutGetCalculatedSize(array, index, dependency)
	if array[index].sizePolicy == GUI.sizePolicies.percentage then
		array[index].calculatedSize = array[index].size * dependency
	else
		array[index].calculatedSize = array[index].size
	end
end

local function layoutUpdate(layout)
	local columnPercentageTotalSize, rowPercentageTotalSize = layout.width - layoutGetAbsoluteTotalSize(layout.columnSizes), layout.height - layoutGetAbsoluteTotalSize(layout.rowSizes)
	for row = 1, #layout.rowSizes do
		layoutGetCalculatedSize(layout.rowSizes, row, rowPercentageTotalSize)
		for column = 1, #layout.columnSizes do
			layoutGetCalculatedSize(layout.columnSizes, column, columnPercentageTotalSize)
			layout.cells[row][column].totalWidth, layout.cells[row][column].totalHeight = 0, 0
		end
	end

	-- Подготавливаем объекты к расположению и подсчитываем тотальные размеры
	local child, layoutRow, layoutColumn, cell
	for i = 1, #layout.children do
		child = layout.children[i]
		if not child.hidden then
			layoutRow, layoutColumn = child.layoutRow, child.layoutColumn

			-- Проверка на позицию в сетке
			if layoutRow >= 1 and layoutRow <= #layout.rowSizes and layoutColumn >= 1 and layoutColumn <= #layout.columnSizes then
				cell = layout.cells[layoutRow][layoutColumn]
				-- Авто-фиттинг объектов
				if cell.fitting.horizontal then
					child.width = math.round(layout.columnSizes[layoutColumn].calculatedSize - cell.fitting.horizontalRemove)
				end
				if cell.fitting.vertical then
					child.height = math.round(layout.rowSizes[layoutRow].calculatedSize - cell.fitting.verticalRemove)
				end

				-- Направление и расчет размеров
				if cell.direction == GUI.directions.horizontal then
					cell.totalWidth = cell.totalWidth + child.width + cell.spacing
					cell.totalHeight = math.max(cell.totalHeight, child.height)
				else
					cell.totalWidth = math.max(cell.totalWidth, child.width)
					cell.totalHeight = cell.totalHeight + child.height + cell.spacing
				end
			else
				error("Layout child with index " .. i .. " has been assigned to cell (" .. layoutColumn .. "x" .. layoutRow .. ") out of layout grid range")
			end
		end
	end

	-- Высчитываем позицицию объектов
	local x, y = 1, 1
	for row = 1, #layout.rowSizes do
		for column = 1, #layout.columnSizes do
			cell = layout.cells[row][column]
			cell.x, cell.y = GUI.getAlignmentCoordinates(
				{
					x = x,
					y = y,
					width = layout.columnSizes[column].calculatedSize,
					height = layout.rowSizes[row].calculatedSize,
					alignment = cell.alignment,
				},
				{
					width = cell.totalWidth - (cell.direction == GUI.directions.horizontal and cell.spacing or 0),
					height = cell.totalHeight - (cell.direction == GUI.directions.vertical and cell.spacing or 0),
				}
			)
			if cell.margin then
				cell.x, cell.y = GUI.getMarginCoordinates(cell)
			end

			x = x + layout.columnSizes[column].calculatedSize
		end

		x, y = 1, y + layout.rowSizes[row].calculatedSize
	end

	-- Размещаем все объекты
	for i = 1, #layout.children do
		child = layout.children[i]
		if not child.hidden then
			cell = layout.cells[child.layoutRow][child.layoutColumn]
			if cell.direction == GUI.directions.horizontal then
				child.localX = math.round(cell.x)
				child.localY = math.round(cell.y + cell.totalHeight / 2 - child.height / 2)
				
				cell.x = cell.x + child.width + cell.spacing
			else
				child.localX = math.round(cell.x + cell.totalWidth / 2 - child.width / 2)
				child.localY = math.round(cell.y)
				
				cell.y = cell.y + child.height + cell.spacing
			end
		end
	end
end

local function layoutSetCellPosition(layout, column, row, object)
	layoutCheckCell(layout, column, row)
	object.layoutRow = row
	object.layoutColumn = column

	return object
end

local function layoutSetCellDirection(layout, column, row, direction)
	layoutCheckCell(layout, column, row)
	layout.cells[row][column].direction = direction

	return layout
end

local function layoutSetCellSpacing(layout, column, row, spacing)
	layoutCheckCell(layout, column, row)
	layout.cells[row][column].spacing = spacing

	return layout
end

local function layoutSetCellAlignment(layout, column, row, horizontalAlignment, verticalAlignment)
	layoutCheckCell(layout, column, row)
	layout.cells[row][column].alignment.horizontal, layout.cells[row][column].alignment.vertical = horizontalAlignment, verticalAlignment

	return layout
end

local function layoutSetCellMargin(layout, column, row, horizontalMargin, verticalMargin)
	layoutCheckCell(layout, column, row)
	layout.cells[row][column].margin = {
		horizontal = horizontalMargin,
		vertical = verticalMargin
	}

	return layout
end

local function layoutNewCell()
	return {
		alignment = {
			horizontal = GUI.alignment.horizontal.center,
			vertical = GUI.alignment.vertical.center
		},
		direction = GUI.directions.vertical,
		fitting = {
		horizontal = false, vertical = false},
		spacing = 1,
	}
end

local function layoutCalculatePercentageSize(changingExistent, array, index)
	if array[index].sizePolicy == GUI.sizePolicies.percentage then
		local allPercents, beforeFromIndexPercents = 0, 0
		for i = 1, #array do
			if array[i].sizePolicy == GUI.sizePolicies.percentage then
				allPercents = allPercents + array[i].size

				if i <= index then
					beforeFromIndexPercents = beforeFromIndexPercents + array[i].size
				end
			end
		end

		local modifyer
		if changingExistent then
			if beforeFromIndexPercents > 1 then
				error("Layout summary percentage > 100% at index " .. index)
			end
			modifyer = (1 - beforeFromIndexPercents) / (allPercents - beforeFromIndexPercents)
		else
			modifyer = (1 - array[index].size) / (allPercents - array[index].size)
		end

		for i = changingExistent and index + 1 or 1, #array do
			if array[i].sizePolicy == GUI.sizePolicies.percentage and i ~= index then
				array[i].size = modifyer * array[i].size
			end
		end
	end
end

local function layoutSetColumnWidth(layout, column, sizePolicy, size)
	layout.columnSizes[column].sizePolicy, layout.columnSizes[column].size = sizePolicy, size
	layoutCalculatePercentageSize(true, layout.columnSizes, column)

	return layout
end

local function layoutSetRowHeight(layout, row, sizePolicy, size)
	layout.rowSizes[row].sizePolicy, layout.rowSizes[row].size = sizePolicy, size
	layoutCalculatePercentageSize(true, layout.rowSizes, row)

	return layout
end

local function layoutAddColumn(layout, sizePolicy, size)
	for i = 1, #layout.rowSizes do
		table.insert(layout.cells[i], layoutNewCell())
	end

	table.insert(layout.columnSizes, {
		sizePolicy = sizePolicy,
		size = size
	})
	layoutCalculatePercentageSize(false, layout.columnSizes, #layout.columnSizes)
	-- GUI.error(layout.columnSizes)

	return layout
end

local function layoutAddRow(layout, sizePolicy, size)
	local row = {}
	for i = 1, #layout.columnSizes do
		table.insert(row, layoutNewCell())
	end

	table.insert(layout.cells, row)
	table.insert(layout.rowSizes, {
		sizePolicy = sizePolicy,
		size = size
	})

	layoutCalculatePercentageSize(false, layout.rowSizes, #layout.rowSizes)
	-- GUI.error(layout.rowSizes)

	return layout
end

local function layoutRemoveRow(layout, row)
	table.remove(layout.cells, row)

	layout.rowSizes[row].size = 0
	layoutCalculatePercentageSize(false, layout.rowSizes, row)

	table.remove(layout.rowSizes, row)

	return layout
end

local function layoutRemoveColumn(layout, column)
	for i = 1, #layout.rowSizes do
		table.remove(layout.cells[i], column)
	end

	layout.columnSizes[column].size = 0
	layoutCalculatePercentageSize(false, layout.columnSizes, column)

	table.remove(layout.columnSizes, column)

	return layout
end

local function layoutSetGridSize(layout, columnCount, rowCount)
	layout.cells = {}
	layout.rowSizes = {}
	layout.columnSizes = {}

	local rowSize, columnSize = 1 / rowCount, 1 / columnCount
	for i = 1, rowCount do
		layoutAddRow(layout, GUI.sizePolicies.percentage, 1 / i)
	end

	for i = 1, columnCount do
		layoutAddColumn(layout, GUI.sizePolicies.percentage, 1 / i)
	end

	return layout
end

local function layoutDraw(layout)
	layoutUpdate(layout)
	GUI.drawContainerContent(layout)
	
	if layout.showGrid then
		local x, y = layout.x, layout.y
		for j = 1, #layout.columnSizes do
			for i = 1, #layout.rowSizes do
				buffer.frame(
					math.round(x),
					math.round(y),
					math.round(layout.columnSizes[j].calculatedSize),
					math.round(layout.rowSizes[i].calculatedSize),
					0xFF0000
				)
				y = y + layout.rowSizes[i].calculatedSize
			end
			x, y = x + layout.columnSizes[j].calculatedSize, layout.y
		end
	end
end

local function layoutFitToChildrenSize(layout, column, row)
	layout.width, layout.height = 0, 0

	for i = 1, #layout.children do
		if not layout.children[i].hidden then
			if layout.cells[row][column].direction == GUI.directions.horizontal then
				layout.width = layout.width + layout.children[i].width + layout.cells[row][column].spacing
				layout.height = math.max(layout.height, layout.children[i].height)
			else
				layout.width = math.max(layout.width, layout.children[i].width)
				layout.height = layout.height + layout.children[i].height + layout.cells[row][column].spacing
			end
		end
	end

	if layout.cells[row][column].direction == GUI.directions.horizontal then
		layout.width = layout.width - layout.cells[row][column].spacing
	else
		layout.height = layout.height - layout.cells[row][column].spacing
	end

	return layout
end

local function layoutSetCellFitting(layout, column, row, horizontal, vertical, horizontalRemove, verticalRemove )
	layoutCheckCell(layout, column, row)
	layout.cells[row][column].fitting = {
		horizontal = horizontal,
		vertical = vertical,
		horizontalRemove = horizontalRemove or 0,
		verticalRemove = verticalRemove or 0,
	}

	return layout
end

local function layoutAddChild(layout, object, ...)
	object.layoutRow = layout.defaultRow
	object.layoutColumn = layout.defaultColumn
	GUI.addChildToContainer(layout, object, ...)

	return object
end

function GUI.layout(x, y, width, height, columnCount, rowCount)
	local layout = GUI.container(x, y, width, height)

	layout.defaultRow = 1
	layout.defaultColumn = 1

	layout.addRow = layoutAddRow
	layout.addColumn = layoutAddColumn
	layout.removeRow = layoutRemoveRow
	layout.removeColumn = layoutRemoveColumn

	layout.setRowHeight = layoutSetRowHeight
	layout.setColumnWidth = layoutSetColumnWidth

	layout.setCellPosition = layoutSetCellPosition
	layout.setCellDirection = layoutSetCellDirection
	layout.setGridSize = layoutSetGridSize
	layout.setCellSpacing = layoutSetCellSpacing
	layout.setCellAlignment = layoutSetCellAlignment
	layout.setCellMargin = layoutSetCellMargin
	
	layout.fitToChildrenSize = layoutFitToChildrenSize
	layout.setCellFitting = layoutSetCellFitting

	layout.addChild = layoutAddChild
	layout.draw = layoutDraw

	layoutSetGridSize(layout, columnCount, rowCount)

	return layout
end

-----------------------------------------------------------------------------------------------------

local function filesystemDialogDraw(filesystemDialog)
	if filesystemDialog.extensionComboBox.hidden then
		filesystemDialog.input.width = filesystemDialog.cancelButton.localX - 4
	else
		filesystemDialog.input.width = filesystemDialog.extensionComboBox.localX - 3
	end

	if filesystemDialog.IOMode == GUI.filesystemModes.save then
		filesystemDialog.submitButton.disabled = not filesystemDialog.input.text
	else
		filesystemDialog.input.text = filesystemDialog.filesystemTree.selectedItem or ""
		filesystemDialog.submitButton.disabled = not filesystemDialog.filesystemTree.selectedItem
	end
	
	GUI.drawContainerContent(filesystemDialog)
	GUI.windowShadow(filesystemDialog.x, filesystemDialog.y, filesystemDialog.width, filesystemDialog.height, GUI.colors.contextMenu.transparency.shadow, true)

	return filesystemDialog
end

local function filesystemDialogSetMode(filesystemDialog, IOMode, filesystemMode)
	filesystemDialog.IOMode = IOMode
	filesystemDialog.filesystemMode = filesystemMode

	if filesystemDialog.IOMode == GUI.filesystemModes.save then
		filesystemDialog.filesystemTree.showMode = GUI.filesystemModes.directory
		filesystemDialog.filesystemTree.selectionMode = GUI.filesystemModes.directory
		filesystemDialog.input.disabled = false
		filesystemDialog.extensionComboBox.hidden = filesystemDialog.filesystemMode ~= GUI.filesystemModes.file or not filesystemDialog.filesystemTree.extensionFilters
	else
		if filesystemDialog.filesystemMode == GUI.filesystemModes.file then
			filesystemDialog.filesystemTree.showMode = GUI.filesystemModes.both
			filesystemDialog.filesystemTree.selectionMode = GUI.filesystemModes.file
		else
			filesystemDialog.filesystemTree.showMode = GUI.filesystemModes.directory
			filesystemDialog.filesystemTree.selectionMode = GUI.filesystemModes.directory
		end

		filesystemDialog.input.disabled = true
		filesystemDialog.extensionComboBox.hidden = true
	end

	filesystemDialog.filesystemTree:updateFileList()
end

local function filesystemDialogAddExtensionFilter(filesystemDialog, extension)
	filesystemDialog.extensionComboBox:addItem(extension)
	filesystemDialog.extensionComboBox.width = math.max(filesystemDialog.extensionComboBox.width, unicode.len(extension) + 3)
	filesystemDialog.extensionComboBox.localX = filesystemDialog.cancelButton.localX - filesystemDialog.extensionComboBox.width - 2
	filesystemDialog.filesystemTree:addExtensionFilter(extension)

	filesystemDialog:setMode(filesystemDialog.IOMode, filesystemDialog.filesystemMode)
end

function GUI.filesystemDialog(x, y, width, height, submitButtonText, cancelButtonText, placeholderText, path)
	local filesystemDialog = GUI.container(x, y, width, height)
	
	filesystemDialog:addChild(GUI.panel(1, height - 2, width, 3, 0xD2D2D2))
	
	filesystemDialog.cancelButton = filesystemDialog:addChild(GUI.adaptiveRoundedButton(1, height - 1, 2, 0, 0xE1E1E1, 0x3C3C3C, 0x3C3C3C, 0xE1E1E1, cancelButtonText))
	filesystemDialog.submitButton = filesystemDialog:addChild(GUI.adaptiveRoundedButton(1, height - 1, 2, 0, 0x3C3C3C, 0xE1E1E1, 0xE1E1E1, 0x3C3C3C, submitButtonText))
	filesystemDialog.submitButton.localX = filesystemDialog.width - filesystemDialog.submitButton.width - 1
	filesystemDialog.cancelButton.localX = filesystemDialog.submitButton.localX - filesystemDialog.cancelButton.width - 2

	filesystemDialog.extensionComboBox = filesystemDialog:addChild(GUI.comboBox(1, height - 1, 1, 1, 0xE1E1E1, 0x666666, 0xC3C3C3, 0x888888))
	filesystemDialog.extensionComboBox.hidden = true

	filesystemDialog.input = filesystemDialog:addChild(GUI.input(2, height - 1, 1, 1, 0xE1E1E1, 0x666666, 0x999999, 0xE1E1E1, 0x3C3C3C, "", placeholderText))

	filesystemDialog.filesystemTree = filesystemDialog:addChild(GUI.filesystemTree(1, 1, width, height - 3, 0xE1E1E1, 0x3C3C3C, 0x3C3C3C, 0xAAAAAA, 0x3C3C3C, 0xE1E1E1, 0xBBBBBB, 0xAAAAAA, 0xC3C3C3, 0x444444))
	filesystemDialog.filesystemTree.workPath = path

	filesystemDialog.draw = filesystemDialogDraw
	filesystemDialog.setMode = filesystemDialogSetMode
	filesystemDialog.addExtensionFilter = filesystemDialogAddExtensionFilter

	filesystemDialog:setMode(GUI.filesystemModes.open, GUI.filesystemModes.file)

	return filesystemDialog
end

local function filesystemDialogShow(filesystemDialog)
	filesystemDialog:addAnimation(
		function(mainContainer, object, animation)
			object.localY = math.floor(1 + (1.0 - animation.position) * (-object.height))
		end,
		function(mainContainer, switch, animation)
			animation:delete()
		end
	):start(0.5)

	return filesystemDialog
end

-----------------------------------------------------------------------------------------------------

function GUI.addFilesystemDialogToContainer(parentContainer, ...)
	local container = parentContainer:addChild(GUI.container(1, 1, parentContainer.width, parentContainer.height))
	container:addChild(GUI.object(1, 1, container.width, container.height))
	
	local filesystemDialog = container:addChild(GUI.filesystemDialog(1, 1, math.floor(container.width * 0.35), math.floor(container.height * 0.8), ...))
	filesystemDialog.localX = math.floor(container.width / 2 - filesystemDialog.width / 2)
	filesystemDialog.localY = -filesystemDialog.height

	local function onAnyTouch()
		local firstParent = filesystemDialog:getFirstParent()
		container:delete()
		firstParent:draw()
		buffer.draw()
	end

	filesystemDialog.cancelButton.onTouch = function()
		onAnyTouch()
		callMethod(filesystemDialog.onCancel)
	end

	filesystemDialog.submitButton.onTouch = function()
		onAnyTouch()
		
		local path = filesystemDialog.filesystemTree.selectedItem or filesystemDialog.filesystemTree.workPath or "/"
		if filesystemDialog.IOMode == GUI.filesystemModes.save then
			path = path .. filesystemDialog.input.text
			
			if filesystemDialog.filesystemMode == GUI.filesystemModes.file then
				local selectedItem = filesystemDialog.extensionComboBox:getItem(filesystemDialog.extensionComboBox.selectedItem)
				path = path .. (selectedItem and selectedItem.text or "")
			else
				path = path .. "/"
			end
		end

		callMethod(filesystemDialog.onSubmit, path)
	end

	filesystemDialog.show = filesystemDialogShow

	return filesystemDialog
end

-----------------------------------------------------------------------------------------------------

local function filesystemChooserDraw(object)
	local tipWidth = object.height * 2 - 1
	local y = math.floor(object.y + object.height / 2)
	
	buffer.square(object.x, object.y, object.width - tipWidth, object.height, object.colors.background, object.colors.text, " ")
	buffer.square(object.x + object.width - tipWidth, object.y, tipWidth, object.height, object.pressed and object.colors.tipText or object.colors.tipBackground, object.pressed and object.colors.tipBackground or object.colors.tipText, " ")
	buffer.text(object.x + object.width - math.floor(tipWidth / 2) - 1, y, object.pressed and object.colors.tipBackground or object.colors.tipText, "…")
	buffer.text(object.x + 1, y, object.colors.text, string.limit(object.path or object.placeholderText, object.width - tipWidth - 2, "left"))

	return filesystemChooser
end

local function filesystemChooserAddExtensionFilter(object, extension)
	object.extensionFilters[unicode.lower(extension)] = true
end

local function filesystemChooserSetMode(object, filesystemMode)
	object.filesystemMode = filesystemMode
end

local function filesystemChooserEventHandler(mainContainer, object, eventData)
	if eventData[1] == "touch" then
		object.pressed = true
		mainContainer:draw()
		buffer.draw()

		local filesystemDialog = GUI.addFilesystemDialogToContainer(mainContainer, object.submitButtonText, object.cancelButtonText, object.placeholderText, object.filesystemDialogPath)		
		
		for key in pairs(object.extensionFilters) do
			filesystemDialog:addExtensionFilter(key)
		end
		filesystemDialog:setMode(GUI.filesystemModes.open, object.filesystemMode)
		
		filesystemDialog.onCancel = function()
			object.pressed = false

			mainContainer:draw()
			buffer.draw()
		end

		filesystemDialog.onSubmit = function(path)
			object.path = path
			object.pressed = false

			mainContainer:draw()
			buffer.draw()
			callMethod(object.onSubmit, object.path)
		end

		filesystemDialog:show()
	end
end

function GUI.filesystemChooser(x, y, width, height, backgroundColor, textColor, tipBackgroundColor, tipTextColor, path, submitButtonText, cancelButtonText, placeholderText, filesystemDialogPath)
	local object = GUI.object(x, y, width, height)
	
	object.eventHandler = comboBoxEventHandler
	object.colors = {
		tipBackground = tipBackgroundColor,
		tipText = tipTextColor,
		text = textColor,
		background = backgroundColor
	}

	object.submitButtonText = submitButtonText
	object.cancelButtonText = cancelButtonText
	object.placeholderText = placeholderText
	object.pressed = false
	object.path = path
	object.filesystemDialogPath = filesystemDialogPath
	object.filesystemMode = GUI.filesystemModes.file
	object.extensionFilters = {}

	object.draw = filesystemChooserDraw
	object.eventHandler = filesystemChooserEventHandler
	object.addExtensionFilter = filesystemChooserAddExtensionFilter
	object.setMode = filesystemChooserSetMode

	return object
end

-----------------------------------------------------------------------------------------------------

local function resizerDraw(object)
	local horizontalMode = object.width >= object.height
	local x, y, symbol
	if horizontalMode then
		buffer.text(object.x, math.floor(object.y + object.height / 2), object.colors.helper, string.rep("━", object.width))
	else
		local x = math.floor(object.x + object.width / 2)
		for i = object.y, object.y + object.height - 1 do
			local index = buffer.getIndex(x, i)
			buffer.rawSet(index, buffer.rawGet(index), object.colors.helper, "┃")
		end
	end

	if object.touchPosition then
		buffer.text(object.touchPosition.x - 1, object.touchPosition.y, object.colors.arrow, "←→")
	end
end

local function resizerEventHandler(mainContainer, object, eventData)
	if eventData[1] == "touch" then
		object.touchPosition = {x = eventData[3], y = eventData[4]}
		
		mainContainer:draw()
		buffer.draw()
	elseif eventData[1] == "drag" and object.touchPosition then
		local x, y = object.touchPosition.x, object.touchPosition.y
		object.touchPosition.x, object.touchPosition.y = eventData[3], eventData[4]
		
		if object.onResize then
			object.onResize(eventData[3] - x, eventData[4] - y)
		end

		mainContainer:draw()
		buffer.draw()
	elseif eventData[1] == "drop" then
		object.touchPosition = nil

		if object.onResizeFinished then
			object.onResizeFinished()
		end

		mainContainer:draw()
		buffer.draw()
	end
end

function GUI.resizer(x, y, width, height, helperColor, arrowColor)
	local object = GUI.object(x, y, width, height)
	
	object.colors = {
		helper = helperColor,
		arrow = arrowColor
	}

	object.draw = resizerDraw
	object.eventHandler = resizerEventHandler

	return object
end

----------------------------------------- Scrollbar object -----------------------------------------

local function scrollBarDraw(scrollBar)
	local isVertical = scrollBar.height > scrollBar.width
	local valuesDelta = scrollBar.maximumValue - scrollBar.minimumValue + 1
	local part = scrollBar.value / valuesDelta

	if isVertical then
		local barSize = math.ceil(scrollBar.shownValueCount / valuesDelta * scrollBar.height)
		local halfBarSize = math.floor(barSize / 2)
		
		scrollBar.ghostPosition.y = scrollBar.y + halfBarSize
		scrollBar.ghostPosition.height = scrollBar.height - barSize

		if scrollBar.thin then
			local y1 = math.floor(scrollBar.ghostPosition.y + part * scrollBar.ghostPosition.height - halfBarSize)
			local y2 = y1 + barSize - 1
			local background

			for y = scrollBar.y, scrollBar.y + scrollBar.height - 1 do
				background = buffer.get(scrollBar.x, y)
				buffer.set(scrollBar.x, y, background, y >= y1 and y <= y2 and scrollBar.colors.foreground or scrollBar.colors.background, "┃")
			end
		else
			buffer.square(scrollBar.x, scrollBar.y, scrollBar.width, scrollBar.height, scrollBar.colors.background, scrollBar.colors.foreground, " ")
			buffer.square(
				scrollBar.x,
				math.floor(scrollBar.ghostPosition.y + part * scrollBar.ghostPosition.height - halfBarSize),
				scrollBar.width,
				barSize,
				scrollBar.colors.foreground, 0x0, " "
			)
		end
	else
		local barSize = math.ceil(scrollBar.shownValueCount / valuesDelta * scrollBar.width)
		local halfBarSize = math.floor(barSize / 2)
		
		scrollBar.ghostPosition.x = scrollBar.x + halfBarSize
		scrollBar.ghostPosition.width = scrollBar.width - barSize

		if scrollBar.thin then
			local x1 = math.floor(scrollBar.ghostPosition.x + part * scrollBar.ghostPosition.width - halfBarSize)
			local x2 = x1 + barSize - 1
			local background

			for x = scrollBar.x, scrollBar.x + scrollBar.width - 1 do
				background = buffer.get(x, scrollBar.y)
				buffer.set(x, scrollBar.y, background, x >= x1 and x <= x2 and scrollBar.colors.foreground or scrollBar.colors.background, "⠤")
			end
		else
			buffer.square(scrollBar.x, scrollBar.y, scrollBar.width, scrollBar.height, scrollBar.colors.background, scrollBar.colors.foreground, " ")
			buffer.square(
				math.floor(scrollBar.ghostPosition.x + part * scrollBar.ghostPosition.width - halfBarSize),
				scrollBar.y,
				barSize,
				scrollBar.height,
				scrollBar.colors.foreground, 0x0, " "
			)
		end
	end

	return scrollBar
end

local function scrollBarEventHandler(mainContainer, object, eventData)
	local newValue = object.value

	if eventData[1] == "touch" or eventData[1] == "drag" then
		local delta = object.maximumValue - object.minimumValue + 1
		if object.height > object.width then
			newValue = math.floor((eventData[4] - object.y + 1) / object.height * delta)
		else
			newValue = math.floor((eventData[3] - object.x + 1) / object.width * delta)
		end
	elseif eventData[1] == "scroll" then
		if eventData[5] == 1 then
			if object.value >= object.minimumValue + object.onScrollValueIncrement then
				newValue = object.value - object.onScrollValueIncrement
			else
				newValue = object.minimumValue
			end
		else
			if object.value <= object.maximumValue - object.onScrollValueIncrement then
				newValue = object.value + object.onScrollValueIncrement
			else
				newValue = object.maximumValue
			end
		end
	end

	if eventData[1] == "touch" or eventData[1] == "drag" or eventData[1] == "scroll" then
		object.value = newValue
		callMethod(object.onTouch, eventData)
		mainContainer:draw()
		buffer.draw()
	end
end

function GUI.scrollBar(x, y, width, height, backgroundColor, foregroundColor, minimumValue, maximumValue, value, shownValueCount, onScrollValueIncrement, thin)
	local scrollBar = GUI.object(x, y, width, height)

	scrollBar.eventHandler = scrollBarEventHandler
	scrollBar.maximumValue = maximumValue
	scrollBar.minimumValue = minimumValue
	scrollBar.value = value
	scrollBar.onScrollValueIncrement = onScrollValueIncrement
	scrollBar.shownValueCount = shownValueCount
	scrollBar.thin = thin
	scrollBar.colors = {
		background = backgroundColor,
		foreground = foregroundColor,
	}
	scrollBar.ghostPosition = {}
	scrollBar.draw = scrollBarDraw

	return scrollBar
end

----------------------------------------- Tree object -----------------------------------------

local function treeDraw(tree)	
	local y, yEnd, showScrollBar = tree.y, tree.y + tree.height - 1, #tree.items > tree.height
	local textLimit = tree.width - (showScrollBar and 1 or 0)

	if tree.colors.default.background then
		buffer.square(tree.x, tree.y, tree.width, tree.height, tree.colors.default.background, tree.colors.default.expandable, " ")
	end

	for i = tree.fromItem, #tree.items do
		local textColor, arrowColor, text = tree.colors.default.notExpandable, tree.colors.default.arrow, tree.items[i].expandable and "■ " or "□ "

		if tree.selectedItem == tree.items[i].definition then
			textColor, arrowColor = tree.colors.selected.any, tree.colors.selected.arrow
			buffer.square(tree.x, y, tree.width, 1, tree.colors.selected.background, textColor, " ")
		else
			if tree.items[i].expandable then
				textColor = tree.colors.default.expandable
			elseif tree.items[i].disabled then
				textColor = tree.colors.disabled
			end
		end

		if tree.items[i].expandable then
			buffer.text(tree.x + tree.items[i].offset, y, arrowColor, tree.expandedItems[tree.items[i].definition] and "▽" or "▷")
		end

		buffer.text(tree.x + tree.items[i].offset + 2, y, textColor, unicode.sub(text .. tree.items[i].name, 1, textLimit - tree.items[i].offset - 2))

		y = y + 1
		if y > yEnd then break end
	end

	if showScrollBar then
		local scrollBar = tree.scrollBar
		scrollBar.x = tree.x + tree.width - 1
		scrollBar.y = tree.y
		scrollBar.width = 1
		scrollBar.height = tree.height
		scrollBar.colors.background = tree.colors.scrollBar.background
		scrollBar.colors.foreground = tree.colors.scrollBar.foreground
		scrollBar.minimumValue = 1
		scrollBar.maximumValue = #tree.items
		scrollBar.value = tree.fromItem
		scrollBar.shownValueCount = tree.height
		scrollBar.onScrollValueIncrement = 1
		scrollBar.thin = true

		scrollBar:draw()
	end

	return tree
end

local function treeEventHandler(mainContainer, tree, eventData)
	if eventData[1] == "touch" then
		local i = eventData[4] - tree.y + tree.fromItem
		if tree.items[i] then
			if
				tree.items[i].expandable and
				(
					tree.selectionMode == GUI.filesystemModes.file or
					eventData[3] >= tree.x + tree.items[i].offset - 1 and eventData[3] <= tree.x + tree.items[i].offset + 1
				)
			then
				if tree.expandedItems[tree.items[i].definition] then
					tree.expandedItems[tree.items[i].definition] = nil
				else
					tree.expandedItems[tree.items[i].definition] = true
				end

				callMethod(tree.onItemExpanded, tree.selectedItem, eventData)
			else
				if
					(
						(
							tree.selectionMode == GUI.filesystemModes.both or
							tree.selectionMode == GUI.filesystemModes.directory and tree.items[i].expandable or
							tree.selectionMode == GUI.filesystemModes.file
						) and not tree.items[i].disabled
					)
				then
					tree.selectedItem = tree.items[i].definition
					callMethod(tree.onItemSelected, tree.selectedItem, eventData)
				end
			end

			mainContainer:draw()
			buffer.draw()
		end
	elseif eventData[1] == "scroll" then
		if eventData[5] == 1 then
			if tree.fromItem > 1 then
				tree.fromItem = tree.fromItem - 1
				mainContainer:draw()
				buffer.draw()
			end
		else
			if tree.fromItem < #tree.items then
				tree.fromItem = tree.fromItem + 1
				mainContainer:draw()
				buffer.draw()
			end
		end
	end
end

local function treeAddItem(tree, name, definition, offset, expandable, disabled)
	table.insert(tree.items, {name = name, expandable = expandable, offset = offset or 0, definition = definition, disabled = disabled})
	return tree
end

function GUI.tree(x, y, width, height, backgroundColor, expandableColor, notExpandableColor, arrowColor, backgroundSelectedColor, anySelectionColor, arrowSelectionColor, disabledColor, scrollBarBackground, scrollBarForeground, showMode, selectionMode)
	local tree = GUI.container(x, y, width, height)
	
	tree.eventHandler = treeEventHandler
	tree.colors = {
		default = {
			background = backgroundColor,
			expandable = expandableColor,
			notExpandable = notExpandableColor,
			arrow = arrowColor,
		},
		selected = {
			background = backgroundSelectedColor,
			any = anySelectionColor,
			arrow = arrowSelectionColor,
		},
		scrollBar = {
			background = scrollBarBackground,
			foreground = scrollBarForeground
		},
		disabled = disabledColor
	}
	tree.items = {}
	tree.fromItem = 1
	tree.selectedItem = nil
	tree.expandedItems = {}

	tree.scrollBar = GUI.scrollBar(1, 1, 1, 1, 0x0, 0x0, 1, 1, 1, 1, 1)

	tree.showMode = showMode
	tree.selectionMode = selectionMode
	tree.eventHandler = treeEventHandler
	tree.addItem = treeAddItem
	tree.draw = treeDraw

	return tree
end

----------------------------------------- FilesystemTree object -----------------------------------------

local function filesystemTreeUpdateFileListRecursively(tree, path, offset)
	local list = {}
	for file in fs.list(path) do
		table.insert(list, file)
	end

	local i, expandables = 1, {}
	while i <= #list do
		if fs.isDirectory(path .. list[i]) then
			table.insert(expandables, list[i])
			table.remove(list, i)
		else
			i = i + 1
		end
	end

	table.sort(expandables, function(a, b) return unicode.lower(a) < unicode.lower(b) end)
	table.sort(list, function(a, b) return unicode.lower(a) < unicode.lower(b) end)

	if tree.showMode == GUI.filesystemModes.both or tree.showMode == GUI.filesystemModes.directory then
		for i = 1, #expandables do
			tree:addItem(fs.name(expandables[i]), path .. expandables[i], offset, true)

			if tree.expandedItems[path .. expandables[i]] then
				filesystemTreeUpdateFileListRecursively(tree, path .. expandables[i], offset + 2)
			end
		end
	end

	if tree.showMode == GUI.filesystemModes.both or tree.showMode == GUI.filesystemModes.file then
		for i = 1, #list do
			tree:addItem(list[i], path .. list[i], offset, false,tree.extensionFilters and not tree.extensionFilters[fs.extension(path .. list[i], true)] or false)
		end
	end
end

local function filesystemTreeUpdateFileList(tree)
	tree.items = {}
	filesystemTreeUpdateFileListRecursively(tree, tree.workPath, 1)
end

local function filesystemTreeAddExtensionFilter(tree, extensionFilter)
	tree.extensionFilters = tree.extensionFilters or {}
	tree.extensionFilters[unicode.lower(extensionFilter)] = true
end

function GUI.filesystemTree(...)
	local tree = GUI.tree(...)

	tree.workPath = "/"
	tree.updateFileList = filesystemTreeUpdateFileList
	tree.addExtensionFilter = filesystemTreeAddExtensionFilter
	tree.onItemExpanded = function()
		tree:updateFileList()
	end

	return tree
end

----------------------------------------- Text Box object -----------------------------------------

local function textBoxCalculate(object)
	local doubleVerticalOffset = object.offset.vertical * 2
	object.textWidth = object.width - object.offset.horizontal * 2 - (object.scrollBarEnabled and 1 or 0)

	object.linesCopy = {}

	if object.autoWrap then
		for i = 1, #object.lines do
			local isTable = type(object.lines[i]) == "table"
			for subLine in (isTable and object.lines[i].text or object.lines[i]):gmatch("[^\n]+") do
				local wrappedLine = string.wrap(subLine, object.textWidth)
				for j = 1, #wrappedLine do
					table.insert(object.linesCopy, isTable and {text = wrappedLine[j], color = object.lines[i].color} or wrappedLine[j])
				end
			end
		end
	else
		for i = 1, #object.lines do
			table.insert(object.linesCopy, object.lines[i])
		end
	end

	if object.autoHeight then
		object.height = #object.linesCopy + doubleVerticalOffset
	end

	object.textHeight = object.height - doubleVerticalOffset
end

local function textBoxDraw(object)
	textBoxCalculate(object)

	if object.colors.background then
		buffer.square(object.x, object.y, object.width, object.height, object.colors.background, object.colors.text, " ", object.colors.transparency)
	end

	local x, y = nil, object.y + object.offset.vertical
	local lineType, text, textColor
	for i = object.currentLine, object.currentLine + object.textHeight - 1 do
		if object.linesCopy[i] then
			lineType = type(object.linesCopy[i])
			if lineType == "string" then
				text, textColor = string.limit(object.linesCopy[i], object.textWidth), object.colors.text
			elseif lineType == "table" then
				text, textColor = string.limit(object.linesCopy[i].text, object.textWidth), object.linesCopy[i].color
			else
				error("Unknown TextBox line type: " .. tostring(lineType))
			end

			x = GUI.getAlignmentCoordinates(
				{
					x = object.x + object.offset.horizontal,
					y = 1,
					width = object.textWidth,
					height = 1,
					alignment = object.alignment
				},
				{
					width = unicode.len(text),
					height = 1
				}
			)
			buffer.text(x, y, textColor, text)
			y = y + 1
		else
			break
		end
	end

	if object.scrollBarEnabled and object.textHeight < #object.lines then
		object.scrollBar.x = object.x + object.width - 1
		object.scrollBar.y = object.y
		object.scrollBar.height = object.height
		object.scrollBar.maximumValue = #object.lines - object.textHeight + 1
		object.scrollBar.value = object.currentLine
		object.scrollBar.shownValueCount = object.textHeight

		object.scrollBar:draw()
	end

	return object
end

local function scrollDownTextBox(object, count)
	count = math.min(count or 1, #object.lines - object.height - object.currentLine + object.offset.vertical * 2 + 1)
	if #object.lines >= object.height and object.currentLine < #object.lines - count then
		object.currentLine = object.currentLine + count
	end

	return object
end

local function scrollUpTextBox(object, count)
	count = count or 1
	if object.currentLine > count and object.currentLine >= 1 then object.currentLine = object.currentLine - count end
	return object
end

local function scrollToStartTextBox(object)
	object.currentLine = 1
	return object
end

local function scrollToEndTextBox(object)
	if #object.lines > object.textHeight then
		object.currentLine = #object.lines - object.textHeight + 1
	end

	return object
end

local function textBoxScrollEventHandler(mainContainer, object, eventData)
	if eventData[1] == "scroll" then
		if eventData[5] == 1 then
			object:scrollUp()
			mainContainer:draw()
			buffer.draw()
		else
			object:scrollDown()
			mainContainer:draw()
			buffer.draw()
		end
	end
end

function GUI.textBox(x, y, width, height, backgroundColor, textColor, lines, currentLine, horizontalOffset, verticalOffset, autoWrap, autoHeight)
	local object = GUI.object(x, y, width, height)
	
	object.eventHandler = textBoxScrollEventHandler
	object.colors = {
		text = textColor,
		background = backgroundColor
	}
	object.setAlignment = GUI.setAlignment
	object:setAlignment(GUI.alignment.horizontal.left, GUI.alignment.vertical.top)
	object.lines = lines
	object.currentLine = currentLine or 1
	object.draw = textBoxDraw
	object.scrollUp = scrollUpTextBox
	object.scrollDown = scrollDownTextBox
	object.scrollToStart = scrollToStartTextBox
	object.scrollToEnd = scrollToEndTextBox
	object.offset = {horizontal = horizontalOffset or 0, vertical = verticalOffset or 0}
	object.autoWrap = autoWrap
	object.autoHeight = autoHeight
	object.scrollBar = GUI.scrollBar(1, 1, 1, 1, 0xC3C3C3, 0x444444, 1, 1, 1, 1, 1, true)
	object.scrollBarEnabled = false

	textBoxCalculate(object)

	return object
end

----------------------------------------- Input object -----------------------------------------

local function inputSetCursorPosition(input, newPosition)
	if newPosition < 1 then
		newPosition = 1
	elseif newPosition > unicode.len(input.text) + 1 then
		newPosition = unicode.len(input.text) + 1
	end

	if newPosition > input.textCutFrom + input.width - 1 - input.textOffset * 2 then
		input.textCutFrom = input.textCutFrom + newPosition - (input.textCutFrom + input.width - 1 - input.textOffset * 2)
	elseif newPosition < input.textCutFrom then
		input.textCutFrom = newPosition
	end

	input.cursorPosition = newPosition

	return input
end

local function inputTextDrawMethod(x, y, color, text)
	buffer.text(x, y, color, text)
end

local function inputDraw(input)
	local background, foreground, transparency, text = input.colors.default.background, input.colors.default.text, input.colors.default.transparency, input.text

	if input.focused then
		background, foreground, transparency = input.colors.focused.background, input.colors.focused.text, input.colors.focused.transparency
	elseif input.text == "" then
		input.textCutFrom = 1
		text, foreground = input.placeholderText or "", input.colors.placeholderText
	end

	if background then
		buffer.square(input.x, input.y, input.width, input.height, background, foreground, " ", transparency)
	end

	local y = input.y + math.floor(input.height / 2)

	input.textDrawMethod(
		input.x + input.textOffset,
		y,
		foreground,
		unicode.sub(
			input.textMask and string.rep(input.textMask, unicode.len(text)) or text,
			input.textCutFrom,
			input.textCutFrom + input.width - 1 - input.textOffset * 2
		)
	)

	if input.cursorBlinkState then
		local index = buffer.getIndex(input.x + input.cursorPosition - input.textCutFrom + input.textOffset, y)
		local background = buffer.rawGet(index)
		buffer.rawSet(index, background, input.colors.cursor, input.cursorSymbol)
	end

	if input.autoCompleteEnabled then
		input.autoComplete.x = input.x
		if input.autoCompleteVerticalAlignment == GUI.alignment.vertical.top then
			input.autoComplete.y = input.y - input.autoComplete.height
		else
			input.autoComplete.y = input.y + input.height
		end
		input.autoComplete.width = input.width
		input.autoComplete:draw()
	end
end

local function inputEventHandler(mainContainer, input, mainEventData)
	if mainEventData[1] == "touch" then
		local textOnStart = input.text
		input.focused = true
		
		if input.historyEnabled then
			input.historyIndex = input.historyIndex + 1
		end

		if input.eraseTextOnFocus then
			input.text = ""
		end

		input.cursorBlinkState = true
		input:setCursorPosition(unicode.len(input.text) + 1)

		if input.autoCompleteEnabled then
			input.autoCompleteMatchMethod()
		end

		mainContainer:draw()
		buffer.draw()

		while true do
			local eventData = { event.pull(input.cursorBlinkDelay) }
			
			if eventData[1] == "touch" or eventData[1] == "drag" then
				if input:isClicked(eventData[3], eventData[4]) then
					input:setCursorPosition(input.textCutFrom + eventData[3] - input.x - input.textOffset)
					
					input.cursorBlinkState = true
					mainContainer:draw()
					buffer.draw()
				elseif input.autoComplete:isClicked(eventData[3], eventData[4]) then
					input.autoComplete.eventHandler(mainContainer, input.autoComplete, eventData)
				else
					input.cursorBlinkState = false
					break
				end
			elseif eventData[1] == "scroll" then
				input.autoComplete.eventHandler(mainContainer, input.autoComplete, eventData)
			elseif eventData[1] == "key_down" then
				-- Return
				if eventData[4] == 28 then
					if input.autoCompleteEnabled and input.autoComplete.itemCount > 0 then
						input.autoComplete.eventHandler(mainContainer, input.autoComplete, eventData)
					else
						if input.historyEnabled then
							-- Очистка истории
							for i = 1, (#input.history - input.historyLimit) do
								table.remove(input.history, 1)
							end

							-- Добавление введенных данных в историю
							if input.history[#input.history] ~= input.text and unicode.len(input.text) > 0 then
								table.insert(input.history, input.text)
							end
							input.historyIndex = #input.history
						end

						input.cursorBlinkState = false
						break
					end
				-- Arrows up/down/left/right
				elseif eventData[4] == 200 then
					if input.autoCompleteEnabled and input.autoComplete.selectedItem > 1 then
						input.autoComplete.eventHandler(mainContainer, input.autoComplete, eventData)
					else
						if input.historyEnabled and #input.history > 0 then
							-- Добавление уже введенного текста в историю при стрелке вверх
							if input.historyIndex == #input.history + 1 and unicode.len(input.text) > 0 then
								input.history[input.historyIndex] = input.text
							end

							input.historyIndex = input.historyIndex - 1
							if input.historyIndex > #input.history then
								input.historyIndex = #input.history
							elseif input.historyIndex < 1 then
								input.historyIndex = 1
							end

							input.text = input.history[input.historyIndex]
							input:setCursorPosition(unicode.len(input.text) + 1)

							if input.autoCompleteEnabled then
								input.autoCompleteMatchMethod()
							end
						end
					end
				elseif eventData[4] == 208 then
					if input.autoCompleteEnabled and input.historyIndex == #input.history + 1 then
						input.autoComplete.eventHandler(mainContainer, input.autoComplete, eventData)
					else
						if input.historyEnabled and #input.history > 0 then
							input.historyIndex = input.historyIndex + 1
							if input.historyIndex > #input.history then
								input.historyIndex = #input.history
							elseif input.historyIndex < 1 then
								input.historyIndex = 1
							end
							
							input.text = input.history[input.historyIndex]
							input:setCursorPosition(unicode.len(input.text) + 1)

							if input.autoCompleteEnabled then
								input.autoCompleteMatchMethod()
							end
						end
					end
				elseif eventData[4] == 203 then
					input:setCursorPosition(input.cursorPosition - 1)
				elseif eventData[4] == 205 then	
					input:setCursorPosition(input.cursorPosition + 1)
				-- Backspace
				elseif eventData[4] == 14 then
					input.text = unicode.sub(unicode.sub(input.text, 1, input.cursorPosition - 1), 1, -2) .. unicode.sub(input.text, input.cursorPosition, -1)
					input:setCursorPosition(input.cursorPosition - 1)
					
					if input.autoCompleteEnabled then
						input.autoCompleteMatchMethod()
					end
				-- Delete
				elseif eventData[4] == 211 then
					input.text = unicode.sub(input.text, 1, input.cursorPosition - 1) .. unicode.sub(input.text, input.cursorPosition + 1, -1)
					
					if input.autoCompleteEnabled then
						input.autoCompleteMatchMethod()
					end
				else
					local char = unicode.char(eventData[3])
					if not keyboard.isControl(eventData[3]) then
						input.text = unicode.sub(input.text, 1, input.cursorPosition - 1) .. char .. unicode.sub(input.text, input.cursorPosition, -1)
						input:setCursorPosition(input.cursorPosition + 1)

						if input.autoCompleteEnabled then
							input.autoCompleteMatchMethod()
						end
					end
				end

				input.cursorBlinkState = true
				mainContainer:draw()
				buffer.draw()
			elseif eventData[1] == "clipboard" then
				input.text = unicode.sub(input.text, 1, input.cursorPosition - 1) .. eventData[3] .. unicode.sub(input.text, input.cursorPosition, -1)
				input:setCursorPosition(input.cursorPosition + unicode.len(eventData[3]))
				
				input.cursorBlinkState = true
				mainContainer:draw()
				buffer.draw()
			elseif not eventData[1] then
				input.cursorBlinkState = not input.cursorBlinkState
				mainContainer:draw()
				buffer.draw()
			end
		end

		input.focused = false
		if input.autoCompleteEnabled then
			input.autoComplete:clear()
		end

		if input.validator then
			if not input.validator(input.text) then
				input.text = textOnStart
				input:setCursorPosition(unicode.len(input.text) + 1)
			end
		end
		
		callMethod(input.onInputFinished, mainContainer, input, mainEventData, input.text)
		
		mainContainer:draw()
		buffer.draw()
	end
end

function GUI.input(x, y, width, height, backgroundColor, textColor, placeholderTextColor, backgroundFocusedColor, textFocusedColor, text, placeholderText, eraseTextOnFocus, textMask)
	local input = GUI.object(x, y, width, height)
	
	input.colors = {
		default = {
			background = backgroundColor,
			text = textColor
		},
		focused = {
			background = backgroundFocusedColor,
			text = textFocusedColor
		},
		placeholderText = placeholderTextColor,
		cursor = 0x00A8FF
	}

	input.text = text or ""
	input.placeholderText = placeholderText
	input.eraseTextOnFocus = eraseTextOnFocus
	input.textMask = textMask

	input.textOffset = 1
	input.textCutFrom = 1
	input.cursorPosition = 1
	input.cursorSymbol = "┃"
	input.cursorBlinkDelay = 0.4
	input.cursorBlinkState = false
	input.textMask = textMask
	input.setCursorPosition = inputSetCursorPosition

	input.history = {}
	input.historyLimit = 20
	input.historyIndex = 0
	input.historyEnabled = false

	input.textDrawMethod = inputTextDrawMethod
	input.draw = inputDraw
	input.eventHandler = inputEventHandler

	input.autoComplete = GUI.autoComplete(1, 1, 30, 7, 0xE1E1E1, 0x999999, 0x3C3C3C, 0x3C3C3C, 0x999999, 0xE1E1E1, 0xC3C3C3, 0x444444)
	input.autoCompleteEnabled = false
	input.autoCompleteVerticalAlignment = GUI.alignment.vertical.bottom

	return input
end

-----------------------------------------------------------------------------------------------------

local function autoCompleteDraw(object)
	local y, yEnd = object.y, object.y + object.height - 1

	buffer.square(object.x, object.y, object.width, object.height, object.colors.default.background, object.colors.default.text, " ")

	for i = object.fromItem, object.itemCount do
		local textColor, textMatchColor = object.colors.default.text, object.colors.default.textMatch
		if i == object.selectedItem then
			buffer.square(object.x, y, object.width, 1, object.colors.selected.background, object.colors.selected.text, " ")
			textColor, textMatchColor = object.colors.selected.text, object.colors.selected.textMatch
		end

		buffer.text(object.x + 1, y, textMatchColor, object.matchText)
		buffer.text(object.x + 1 + object.matchTextLength, y, textColor, unicode.sub(object.items[i], object.matchTextLength + 1, object.width - 2 - object.matchTextLength))

		y = y + 1
		if y > yEnd then
			break
		end
	end

	if object.itemCount > object.height then
		object.scrollBar.x = object.x + object.width - 1
		object.scrollBar.y = object.y
		object.scrollBar.height = object.height
		object.scrollBar.maximumValue = object.itemCount - object.height + 1
		object.scrollBar.value = object.fromItem
		object.scrollBar.shownValueCount = object.height

		object.scrollBar:draw()
	end
end

local function autoCompleteScroll(mainContainer, object, direction)
	if object.itemCount >= object.height then
		object.fromItem = object.fromItem + direction
		if object.fromItem < 1 then
			object.fromItem = 1
		elseif object.fromItem > object.itemCount - object.height + 1 then
			object.fromItem = object.itemCount - object.height + 1
		end
	end
end

local function autoCompleteEventHandler(mainContainer, object, eventData)
	if eventData[1] == "touch" then
		object.selectedItem = eventData[4] - object.y + object.fromItem
		mainContainer:draw()
		buffer.draw()

		callMethod(object.onItemSelected, mainContainer, object, eventData, object.selectedItem)
	elseif eventData[1] == "scroll" then
		autoCompleteScroll(mainContainer, object, -eventData[5])
		mainContainer:draw()
		buffer.draw()
	elseif eventData[1] == "key_down" then
		if eventData[4] == 28 then
			callMethod(object.onItemSelected, mainContainer, object, eventData, object.selectedItem)
		elseif eventData[4] == 200 then
			object.selectedItem = object.selectedItem - 1
			if object.selectedItem < 1 then
				object.selectedItem = 1
			end

			if object.selectedItem == object.fromItem - 1 then
				autoCompleteScroll(mainContainer, object, -1)
			end

			mainContainer:draw()
			buffer.draw()
		elseif eventData[4] == 208 then
			object.selectedItem = object.selectedItem + 1
			if object.selectedItem > object.itemCount then
				object.selectedItem = object.itemCount
			end

			if object.selectedItem == object.fromItem + object.height then
				autoCompleteScroll(mainContainer, object, 1)
			end
			
			mainContainer:draw()
			buffer.draw()
		end
	end
end

local function autoCompleteClear(object)
	object.items = {}
	object.itemCount = 0
	object.fromItem = 1
	object.selectedItem = 1
	object.height = 0
end

local function autoCompleteMatch(object, variants, text)
	object:clear()
	
	if text then
		for i = 1, #variants do
			if variants[i] ~= text and variants[i]:match("^" .. text) then
				table.insert(object.items, variants[i])
			end
		end
	else
		for i = 1, #variants do
			table.insert(object.items, variants[i])
		end
	end

	object.matchText = text or ""
	object.matchTextLength = unicode.len(object.matchText)

	table.sort(object.items, function(a, b) return unicode.lower(a) < unicode.lower(b) end)

	object.itemCount = #object.items
	object.height = math.min(object.itemCount, object.maximumHeight)

	return object
end

function GUI.autoComplete(x, y, width, maximumHeight, backgroundColor, textColor, textMatchColor, backgroundSelectedColor, textSelectedColor, textMatchSelectedColor, scrollBarBackground, scrollBarForeground)
	local object = GUI.object(x, y, width, maximumHeight)

	object.colors = {
		default = {
			background = backgroundColor,
			text = textColor,
			textMatch = textMatchColor	
		},
		selected = {
			background = backgroundSelectedColor,
			text = textSelectedColor,
			textMatch = textMatchSelectedColor
		}
	}

	object.maximumHeight = maximumHeight
	object.fromItem = 1
	object.selectedItem = 1
	object.items = {}
	object.matchText = " "
	object.matchTextLength = 1
	object.itemCount = 0

	object.scrollBar = GUI.scrollBar(1, 1, 1, 1, scrollBarBackground, scrollBarForeground, 1, 1, 1, 1, 1, true)

	object.match = autoCompleteMatch
	object.draw = autoCompleteDraw
	object.eventHandler = autoCompleteEventHandler
	object.clear = autoCompleteClear

	object:clear()

	return object
end

-----------------------------------------------------------------------------------------------------


-- buffer.clear()
-- buffer.draw(true)

-- -- Создаем полноэкранный контейнер, добавляем на него загруженное изображение и полупрозрачную черную панель
-- local mainContainer = GUI.fullScreenContainer()
-- mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x2D2D2D))

-- local layout = mainContainer:addChild(GUI.layout(1, 1, mainContainer.width, mainContainer.height, 3, 3))
-- local button = layout:setCellPosition(2, 2, layout:addChild(GUI.button(1, 1, 10, 3, 0x0, 0xFFFFFF, 0x0, 0xFFFFFF, "AEFAEF")))
-- layout.showGrid = true

-- -- mainContainer.eventHandler = function()
-- -- 	GUI.error(button.x, button.y, button.localX, button.localY)
-- -- end

-- mainContainer:draw()
-- buffer.draw(true)
-- mainContainer:startEventHandling()


-----------------------------------------------------------------------------------------------------

return GUI






