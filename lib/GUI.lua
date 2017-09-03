
----------------------------------------- Libraries -----------------------------------------

require("advancedLua")
local computer = require("computer")
local keyboard = require("keyboard")
local unicode = require("unicode")
local event = require("event")
local fs = require("filesystem")
local color = require("color")
local image = require("image")
local buffer = require("doubleBuffering")

----------------------------------------- Constants -----------------------------------------

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
			background = 30,
			shadow = 40
		}
	},
	windows = {
		title = {
			background = 0xEEEEEE,
			text = 0x3C3C3C
		},
		backgroundPanel = 0xFFFFFF,
		tabBar = {
			default = {
				background = 0xDDDDDD,
				text = 0x3C3C3C
			},
			selected = {
				background = 0xCCCCCC,
				text = 0x3C3C3C
			}
		}
	}
}

----------------------------------------- Interface objects -----------------------------------------

local function callMethod(method, ...)
	if method then method(...) end
end

function GUI.point(x, y)
	return { x = x, y = y }
end

function GUI.rectangle(x, y, width, height)
	return { x = x, y = y, width = width, height = height}
end

local function isObjectClicked(object, x, y)
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
	local rectangle = GUI.rectangle(x, y, width, height)
	rectangle.isClicked = isObjectClicked
	rectangle.draw = objectDraw

	return rectangle
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

local function checkObjectParentExists(object)
	if not object.parent then error("Object doesn't have a parent container") end
end

local function containerObjectIndexOf(object)
	checkObjectParentExists(object)
	for objectIndex = 1, #object.parent.children do
		if object.parent.children[objectIndex] == object then
			return objectIndex
		end
	end
end

local function containerObjectMoveForward(object)
	local objectIndex = object:indexOf()
	if objectIndex < #object.parent.children then
		object.parent.children[index], object.parent.children[index + 1] = swap(object.parent.children[index], object.parent.children[index + 1])
	end
	return object
end

local function containerObjectMoveBackward(object)
	local objectIndex = object:indexOf()
	if objectIndex > 1 then
		object.parent.children[objectIndex], object.parent.children[objectIndex - 1] = swap(object.parent.children[objectIndex], object.parent.children[objectIndex - 1])
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
	if object.parent then
		local currentParent = object.parent
		while currentParent.parent do
			currentParent = currentParent.parent
		end
		return currentParent
	else
		error("Object doesn't have any parents")
	end
end

local function containerObjectSelfDelete(object)
	table.remove(object.parent.children, containerObjectIndexOf(object))
end

--------------------------------------------------------------------------------------------------------------------------------

local function containerObjectAnimationStart(animation, duration)
	animation.position = 0
	animation.duration = duration
	animation.started = true
	animation.startUptime = computer.uptime()
	computer.pushSignal("GUIAnimationStart")
end

local function containerObjectAnimationStop(animation)
	animation.position = 0
	animation.started = false
end

local function containerObjectAnimationDelete(animation)
	animation.deleteLater = true
end

function containerObjectAddAnimation(object, frameHandler, onFinish)
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
	object.localPosition = {
		x = object.x,
		y = object.y
	}
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
	end
end

function GUI.calculateChildAbsolutePosition(object)
	object.x, object.y = object.parent.x + object.localPosition.x - 1, object.parent.y + object.localPosition.y - 1
end

function GUI.drawContainerContent(container)
	local R1X1, R1Y1, R1X2, R1Y2 = buffer.getDrawLimit()
	local x1, y1, x2, y2 = getRectangleIntersection(R1X1, R1Y1, R1X2, R1Y2, container.x, container.y, container.x + container.width - 1, container.y + container.height - 1)

	if x1 then
		buffer.setDrawLimit(x1, y1, x2, y2)
		
		for objectIndex = 1, #container.children do
			if not container.children[objectIndex].hidden then
				GUI.calculateChildAbsolutePosition(container.children[objectIndex])
				container.children[objectIndex]:draw()
			end
		end

		buffer.setDrawLimit(R1X1, R1Y1, R1X2, R1Y2)
	end

	return container
end

local function containerHandler(isScreenEvent, mainContainer, currentContainer, eventData, x1, y1, x2, y2)
	local breakRecursion = false
	
	if not isScreenEvent or x1 and eventData[3] >= x1 and eventData[4] >= y1 and eventData[3] <= x2 and eventData[4] <= y2 then
		for i = #currentContainer.children, 1, -1 do
			if not currentContainer.children[i].hidden then
				if currentContainer.children[i].children then
					if containerHandler(isScreenEvent, mainContainer, currentContainer.children[i], eventData, getRectangleIntersection(
							x1, y1, x2, y2,
							currentContainer.children[i].x,
							currentContainer.children[i].y,
							currentContainer.children[i].x + currentContainer.children[i].width - 1,
							currentContainer.children[i].y + currentContainer.children[i].height - 1
						))
					then
						breakRecursion = true
						break
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

	local eventData, animationIndex, needDraw
	while true do
		eventData = {event.pull(container.animations and 0 or container.eventHandlingDelay)}
		containerHandler(
			eventData[1] == "touch" or
			eventData[1] == "drag" or
			eventData[1] == "drop" or
			eventData[1] == "scroll",
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
					needDraw = true
					container.animations[animationIndex].position = (computer.uptime() - container.animations[animationIndex].startUptime) / container.animations[animationIndex].duration
					
					if container.animations[animationIndex].position <= 1 then
						container.animations[animationIndex].frameHandler(container, container.animations[animationIndex].object, container.animations[animationIndex])
					else
						container.animations[animationIndex].position = 1
						container.animations[animationIndex].started = false
						container.animations[animationIndex].frameHandler(container, container.animations[animationIndex].object, container.animations[animationIndex])
						
						if container.animations[animationIndex].onFinish then
							needDraw = false
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

			if needDraw then
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
	computer.pushSignal("containerAction")
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
	return GUI.container(1, 1, buffer.width, buffer.height)
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
			
			buffer.text(object.x + 1, object.y, buttonColor, string.rep("▄", object.width - 2))
			buffer.text(object.x, object.y, buttonColor, "⣠")
			buffer.text(x2, object.y, buttonColor, "⣄")
			
			buffer.square(object.x, object.y + 1, object.width, object.height - 2, buttonColor, textColor, " ")
			
			buffer.text(object.x + 1, y2, buttonColor, string.rep("▀", object.width - 2))
			buffer.text(object.x, y2, buttonColor, "⠙")
			buffer.text(x2, y2, buttonColor, "⠋")
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
		tabBar.children[i].localPosition.x = x
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
	
	object.colors = {background = color, transparency = transparency}
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
		object.pressed = true
		mainContainer:draw()
		buffer.draw()
		callMethod(object.onTouch, eventData)
		object.pressed = false
		mainContainer:draw()
		buffer.draw()
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
		buffer.square(object.x, object.y, object.width, object.height, object.colors.passive)
		buffer.square(object.x, object.y, activeWidth, object.height, object.colors.active)
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

------------------------------------------------- Error window -------------------------------------------------------------------

function GUI.error(...)
	local args = {...}
	for i = 1, #args do
		if type(args[i]) == "table" then
			args[i] = table.toString(args[i])
		else
			args[i] = tostring(args[i])
		end
	end
	if #args == 0 then args[1] = "nil" end

	local sign = image.fromString([[06030000FF 0000FF 00F7FF▟00F7FF▙0000FF 0000FF 0000FF 00F7FF▟F7FF00 F7FF00 00F7FF▙0000FF 00F7FF▟F7FF00CF7FF00yF7FF00kF7FF00a00F7FF▙]])
	local offset = 2
	local lines = #args > 1 and "\"" .. table.concat(args, "\", \"") .. "\"" or args[1]
	local width = math.floor(buffer.width * 0.5)
	local textWidth = width - image.getWidth(sign) - 2

	lines = string.wrap(lines, textWidth)
	local height = image.getHeight(sign)
	if #lines + 2 > height then
		height = #lines + 2
	end

	local mainContainer = GUI.container(1, math.floor(buffer.height / 2 - height / 2), buffer.width, height + offset * 2)
	local oldPixels = buffer.copy(mainContainer.x, mainContainer.y, mainContainer.width, mainContainer.height)

	local x, y = math.floor(buffer.width / 2 - width / 2), offset + 1
	mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x1D1D1D))
	mainContainer:addChild(GUI.image(x, y, sign))
	mainContainer:addChild(GUI.textBox(x + image.getWidth(sign) + 2, y, textWidth, #lines, 0x1D1D1D, 0xEEEEEE, lines, 1, 0, 0)).eventHandler = nil
	local buttonWidth = 12
	local button = mainContainer:addChild(GUI.button(x + image.getWidth(sign) + textWidth - buttonWidth + 2, mainContainer.height - offset, buttonWidth, 1, 0x3366CC, 0xEEEEEE, 0xEEEEEE, 0x3366CC, "Ok"))
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

----------------------------------------- Scrollbar object -----------------------------------------

local function scrollBarDraw(scrollBar)
	local isVertical = scrollBar.height > scrollBar.width
	local valuesDelta = scrollBar.maximumValue - scrollBar.minimumValue + 1
	local part = scrollBar.value / valuesDelta

	if not isVertical and scrollBar.thinHorizontalMode then
		buffer.text(scrollBar.x, scrollBar.y, scrollBar.colors.background, string.rep("▄", scrollBar.width))
	else
		buffer.square(scrollBar.x, scrollBar.y, scrollBar.width, scrollBar.height, scrollBar.colors.background, 0x0, " ")
	end

	if isVertical then
		local barSize = math.ceil(scrollBar.shownValueCount / valuesDelta * scrollBar.height)
		local halfBarSize = math.floor(barSize / 2)
		
		scrollBar.ghostPosition.x = scrollBar.x
		scrollBar.ghostPosition.y = scrollBar.y + halfBarSize
		scrollBar.ghostPosition.width = scrollBar.width
		scrollBar.ghostPosition.height = scrollBar.height - barSize

		buffer.square(
			scrollBar.ghostPosition.x,
			math.floor(scrollBar.ghostPosition.y + part * scrollBar.ghostPosition.height - halfBarSize),
			scrollBar.ghostPosition.width,
			barSize,
			scrollBar.colors.foreground, 0x0, " "
		)
	else
		local barSize = math.ceil(scrollBar.shownValueCount / valuesDelta * scrollBar.width)
		local halfBarSize = math.floor(barSize / 2)
		
		scrollBar.ghostPosition.x = scrollBar.x + halfBarSize
		scrollBar.ghostPosition.y = scrollBar.y
		scrollBar.ghostPosition.width = scrollBar.width - barSize
		scrollBar.ghostPosition.height = scrollBar.height

		if not isVertical and scrollBar.thinHorizontalMode then
			buffer.text(math.floor(scrollBar.ghostPosition.x + part * scrollBar.ghostPosition.width - halfBarSize), scrollBar.ghostPosition.y, scrollBar.colors.foreground, string.rep("▄", barSize))
		else
			buffer.square(
				math.floor(scrollBar.ghostPosition.x + part * scrollBar.ghostPosition.width - halfBarSize),
				scrollBar.ghostPosition.y,
				barSize,
				scrollBar.ghostPosition.height,
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

function GUI.scrollBar(x, y, width, height, backgroundColor, foregroundColor, minimumValue, maximumValue, value, shownValueCount, onScrollValueIncrement, thinHorizontalMode)
	local scrollBar = GUI.object(x, y, width, height)

	scrollBar.eventHandler = scrollBarEventHandler
	scrollBar.maximumValue = maximumValue
	scrollBar.minimumValue = minimumValue
	scrollBar.value = value
	scrollBar.onScrollValueIncrement = onScrollValueIncrement
	scrollBar.shownValueCount = shownValueCount
	scrollBar.thinHorizontalMode = thinHorizontalMode
	scrollBar.colors = {
		background = backgroundColor,
		foreground = foregroundColor,
	}
	scrollBar.ghostPosition = {}
	scrollBar.draw = scrollBarDraw

	return scrollBar
end

----------------------------------------- CodeView object -----------------------------------------

local function codeViewDraw(codeView)
	-- local toLine = codeView.fromLine + codeView.height - (codeView.scrollBars.horizontal.hidden and 1 or 2)
	local toLine = codeView.fromLine + codeView.height - 1

	-- Line numbers bar and code area
	codeView.lineNumbersWidth = unicode.len(tostring(toLine)) + 2
	codeView.codeAreaPosition = codeView.x + codeView.lineNumbersWidth
	codeView.codeAreaWidth = codeView.width - codeView.lineNumbersWidth
	buffer.square(codeView.x, codeView.y, codeView.lineNumbersWidth, codeView.height, require("syntax").colorScheme.lineNumbersBackground, require("syntax").colorScheme.lineNumbersText, " ")	
	buffer.square(codeView.codeAreaPosition, codeView.y, codeView.codeAreaWidth, codeView.height, require("syntax").colorScheme.background, require("syntax").colorScheme.text, " ")

	-- Line numbers texts
	local y = codeView.y
	for line = codeView.fromLine, toLine do
		if codeView.lines[line] then
			local text = tostring(line)
			if codeView.highlights[line] then
				buffer.square(codeView.x, y, codeView.lineNumbersWidth, 1, codeView.highlights[line], require("syntax").colorScheme.text, " ", 30)
				buffer.square(codeView.codeAreaPosition, y, codeView.codeAreaWidth, 1, codeView.highlights[line], require("syntax").colorScheme.text, " ")
			end
			buffer.text(codeView.codeAreaPosition - unicode.len(text) - 1, y, require("syntax").colorScheme.lineNumbersText, text)
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
			codeView.selections[selectionIndex].color or require("syntax").colorScheme.selection, require("syntax").colorScheme.text, " "
		)
	end

	local function drawLowerSelection(y, selectionIndex)
		buffer.square(
			codeView.codeAreaPosition,
			y + codeView.selections[selectionIndex].from.line - codeView.fromLine,
			codeView.selections[selectionIndex].to.symbol - codeView.fromSymbol + 2,
			1,
			codeView.selections[selectionIndex].color or require("syntax").colorScheme.selection, require("syntax").colorScheme.text, " "
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
					codeView.selections[selectionIndex].color or require("syntax").colorScheme.selection, require("syntax").colorScheme.text, " "
				)
			elseif dy == 1 then
				drawUpperSelection(y, selectionIndex); y = y + 1
				drawLowerSelection(y, selectionIndex)
			else
				drawUpperSelection(y, selectionIndex); y = y + 1
				for i = 1, dy - 1 do
					buffer.square(codeView.codeAreaPosition, y + codeView.selections[selectionIndex].from.line - codeView.fromLine, codeView.codeAreaWidth, 1, codeView.selections[selectionIndex].color or require("syntax").colorScheme.selection, require("syntax").colorScheme.text, " "); y = y + 1
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
				require("syntax").highlightString(codeView.codeAreaPosition - codeView.fromSymbol + 2, y, codeView.lines[i], codeView.indentationWidth)
			else
				buffer.text(codeView.codeAreaPosition - codeView.fromSymbol + 2, y, require("syntax").colorScheme.text, codeView.lines[i])
			end
			y = y + 1
		else
			break
		end
	end
	buffer.setDrawLimit(oldDrawLimitX1, oldDrawLimitY1, oldDrawLimitX2, oldDrawLimitY2)

	if #codeView.lines > codeView.height then
		codeView.scrollBars.vertical.hidden = false
		codeView.scrollBars.vertical.colors.background, codeView.scrollBars.vertical.colors.foreground = require("syntax").colorScheme.scrollBarBackground, require("syntax").colorScheme.scrollBarForeground
		codeView.scrollBars.vertical.minimumValue, codeView.scrollBars.vertical.maximumValue, codeView.scrollBars.vertical.value, codeView.scrollBars.vertical.shownValueCount = 1, #codeView.lines, codeView.fromLine, codeView.height
		codeView.scrollBars.vertical.localPosition.x = codeView.width
		codeView.scrollBars.vertical.localPosition.y = 1
		codeView.scrollBars.vertical.height = codeView.height
	else
		codeView.scrollBars.vertical.hidden = true
	end

	if codeView.maximumLineLength > codeView.codeAreaWidth - 2 then
		codeView.scrollBars.horizontal.hidden = false
		codeView.scrollBars.horizontal.colors.background, codeView.scrollBars.horizontal.colors.foreground = require("syntax").colorScheme.scrollBarBackground, require("syntax").colorScheme.scrollBarForeground
		codeView.scrollBars.horizontal.minimumValue, codeView.scrollBars.horizontal.maximumValue, codeView.scrollBars.horizontal.value, codeView.scrollBars.horizontal.shownValueCount = 1, codeView.maximumLineLength, codeView.fromSymbol, codeView.codeAreaWidth - 2
		codeView.scrollBars.horizontal.localPosition.x, codeView.scrollBars.horizontal.width = codeView.lineNumbersWidth + 1, codeView.codeAreaWidth - 1
		codeView.scrollBars.horizontal.localPosition.y = codeView.height
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
		vertical = codeView:addChild(GUI.scrollBar(1, 1, 1, 1, 0x0, 0x0, 1, 1, 1, 1, 1, false)),
		horizontal = codeView:addChild(GUI.scrollBar(1, 1, 1, 1, 0x0, 0x0, 1, 1, 1, 1, 1, true))
	}

	codeView.reimplementedDraw = codeView.draw
	codeView.draw = codeViewDraw

	return codeView
end 

----------------------------------------- Color Selector object -----------------------------------------

local function updateFileList(directoriesToShowContent, xOffset, path)
	local localFileList = {}
	for file in fs.list(path) do
		local element = {}
		element.path = path .. file
		element.xOffset = xOffset
		element.isDirectory = fs.isDirectory(element.path)
		table.insert(localFileList, element)
	end

	-- Sort file list alphabeitcally
	table.sort(localFileList, function(a, b) return unicode.lower(a.path) < unicode.lower(b.path) end)
	-- Move folders on top and recursively get their content if needed
	local i, nextDirectoryIndex, nextLocalFileListIndex = 1, 1, 1
	while i <= #localFileList do
		if localFileList[i].isDirectory then
			table.insert(localFileList, nextDirectoryIndex, localFileList[i])
			table.remove(localFileList, i + 1)

			if directoriesToShowContent[localFileList[nextDirectoryIndex].path] then
				local nextLocalFileList = updateFileList(directoriesToShowContent, xOffset + 2, localFileList[nextDirectoryIndex].path)
				
				nextLocalFileListIndex = nextDirectoryIndex + 1
				for j = 1, #nextLocalFileList do
					table.insert(localFileList, nextLocalFileListIndex, nextLocalFileList[j])
					nextLocalFileListIndex = nextLocalFileListIndex + 1
				end
				i, nextDirectoryIndex = i + #nextLocalFileList, nextDirectoryIndex + #nextLocalFileList
			end

			nextDirectoryIndex = nextDirectoryIndex + 1
		end

		i = i + 1
	end

	return localFileList
end

local function treeViewUpdateFileList(treeView)
	treeView.fileList = updateFileList(treeView.directoriesToShowContent, 1, treeView.workPath)
	return treeView
end

local function treeViewDraw(treeView)
	local y = treeView.y
	local showScrollBar = #treeView.fileList > treeView.height
	local textLimit = treeView.width - (showScrollBar and 2 or 1)

	if treeView.colors.default.background then
		buffer.square(treeView.x, treeView.y, treeView.width, treeView.height, treeView.colors.default.background, treeView.colors.default.text, " ")
	end

	for fileIndex = treeView.fromFile, #treeView.fileList do
		local textColor = treeView.colors.default.text
		if treeView.fileList[fileIndex].path == treeView.currentFile then
			textColor = treeView.colors.selected.text
			buffer.square(treeView.x, y, treeView.width, 1, treeView.colors.selected.background, textColor, " ") 
		end

		if treeView.fileList[fileIndex].isDirectory then
			buffer.text(treeView.x + treeView.fileList[fileIndex].xOffset, y, treeView.colors.arrow, treeView.directoriesToShowContent[treeView.fileList[fileIndex].path] and "▽" or "▷")
			buffer.text(treeView.x + treeView.fileList[fileIndex].xOffset + 2, y, textColor, unicode.sub("■ " .. fs.name(treeView.fileList[fileIndex].path), 1, textLimit - treeView.fileList[fileIndex].xOffset - 2))
		else
			buffer.text(treeView.x + treeView.fileList[fileIndex].xOffset, y, textColor, unicode.sub("  □ " .. fs.name(treeView.fileList[fileIndex].path), 1, textLimit - treeView.fileList[fileIndex].xOffset))
		end

		y = y + 1
		if y > treeView.y + treeView.height - 1 then
			break
		end
	end

	if showScrollBar then
		GUI.scrollBar(
			treeView.x + treeView.width - 1,
			treeView.y,
			1,
			treeView.height,
			treeView.colors.scrollBar.background, 
			treeView.colors.scrollBar.foreground,
			1,
			#treeView.fileList,
			treeView.fromFile,
			treeView.height - 2,
			1
		):draw()	
	end

	return treeView
end

local function treeViewEventHandler(mainContainer, object, eventData)
	if eventData[1] == "touch" then
		local fileIndex = eventData[4] - object.y + object.fromFile
		if object.fileList[fileIndex] then
			if object.fileList[fileIndex].isDirectory then
				if object.directoriesToShowContent[object.fileList[fileIndex].path] then
					object.directoriesToShowContent[object.fileList[fileIndex].path] = nil
				else
					object.directoriesToShowContent[object.fileList[fileIndex].path] = true
				end
				object:updateFileList()
				mainContainer:draw()
				buffer.draw()
			else
				object.currentFile = object.fileList[fileIndex].path
				mainContainer:draw()
				buffer.draw()
				callMethod(object.onFileSelected, object.currentFile, eventData)
			end
		end
	elseif eventData[1] == "scroll" then
		if eventData[5] == 1 then
			if object.fromFile > 1 then
				object.fromFile = object.fromFile - 1
				mainContainer:draw()
				buffer.draw()
			end
		else
			if object.fromFile < #object.fileList then
				object.fromFile = object.fromFile + 1
				mainContainer:draw()
				buffer.draw()
			end
		end
	end
end

function GUI.treeView(x, y, width, height, backgroundColor, textColor, selectionColor, selectionTextColor, arrowColor, scrollBarBackground, scrollBarForeground, workPath)
	local treeView = GUI.container(x, y, width, height)
	
	treeView.eventHandler = treeViewEventHandler
	treeView.colors = {
		default = {
			background = backgroundColor,
			text = textColor,
		},
		selected = {
			background = selectionColor,
			text = selectionTextColor,
		},
		scrollBar = {
			background = scrollBarBackground,
			foreground = scrollBarForeground
		},
		arrow = arrowColor
	}
	treeView.directoriesToShowContent = {}
	treeView.fileList = {}
	treeView.workPath = workPath

	treeView.updateFileList = treeViewUpdateFileList
	treeView.draw = treeViewDraw
	treeView.currentFile = nil
	treeView.fromFile = 1

	treeView:updateFileList()

	return treeView
end

----------------------------------------- Color Selector object -----------------------------------------

local function colorSelectorDraw(colorSelector)
	local overlayColor = colorSelector.color < 0x7FFFFF and 0xFFFFFF or 0x000000
	buffer.square(colorSelector.x, colorSelector.y, colorSelector.width, colorSelector.height, colorSelector.color, overlayColor, " ")
	if colorSelector.pressed then
		buffer.square(colorSelector.x, colorSelector.y, colorSelector.width, colorSelector.height, overlayColor, overlayColor, " ", 80)
	end
	if colorSelector.height > 1 then
		buffer.text(colorSelector.x, colorSelector.y + colorSelector.height - 1, overlayColor, string.rep("▄", colorSelector.width), 80)
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
	GUI.drawContainerContent(window)
	GUI.windowShadow(window.x, window.y, window.width, window.height, nil, true)
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
	if eventData ~= mainContainer.focusedWindowEventData then
		mainContainer.focusedWindowEventData = eventData

		if eventData[1] == "touch" then
			mainContainer.focusedWindow = object
			object.lastTouchPosition = object.lastTouchPosition or {}
			object.lastTouchPosition.x, object.lastTouchPosition.y = eventData[3], eventData[4]
			
			if object ~= object.parent.children[#object.parent.children] then
				object:moveToFront()
				mainContainer:draw()
				buffer.draw()
			end
		elseif eventData[1] == "drag" and object == mainContainer.focusedWindow and object.lastTouchPosition and not windowCheck(object, eventData[3], eventData[4]) then
			local xOffset, yOffset = eventData[3] - object.lastTouchPosition.x, eventData[4] - object.lastTouchPosition.y
			object.lastTouchPosition.x, object.lastTouchPosition.y = eventData[3], eventData[4]

			if xOffset ~= 0 or yOffset ~= 0 then
				object.localPosition.x, object.localPosition.y = object.localPosition.x + xOffset, object.localPosition.y + yOffset
				mainContainer:draw()
				buffer.draw()
			end
		elseif eventData[1] == "drop" then
			mainContainer.focusedWindow = nil
			object.lastTouchPosition = nil
		end
	end
end

function GUI.window(x, y, width, height)
	local window = GUI.container(x, y, width, height)
	
	window.eventHandler = windowEventHandler
	window.allowDragMovement = true
	window.draw = windowDraw

	return window
end

function GUI.filledWindow(x, y, width, height, backgroundColor)
	local window = GUI.window(x, y, width, height)

	window.backgroundPanel = window:addChild(GUI.panel(1, 1, width, height, backgroundColor))
	window.actionButtons = window:addChild(GUI.actionButtons(2, 1, false))

	return window
end

function GUI.titledWindow(x, y, width, height, title, addTitlePanel)
	local window = GUI.filledWindow(x, y, width, height, GUI.colors.windows.backgroundPanel)

	if addTitlePanel then
		window.titlePanel = window:addChild(GUI.panel(1, 1, width, 1, GUI.colors.windows.title.background))
		window.backgroundPanel.localPosition.y, window.backgroundPanel.height = 2, window.height - 1
	end
	window.titleLabel = window:addChild(GUI.label(1, 1, width, height, GUI.colors.windows.title.text, title)):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	window.actionButtons:moveToFront()

	return window
end

function GUI.tabbedWindow(x, y, width, height, ...)
	local window = GUI.filledWindow(x, y, width, height, GUI.colors.windows.backgroundPanel)

	window.tabBar = window:addChild(GUI.tabBar(1, 1, window.width, 3, 2, 0, GUI.colors.windows.tabBar.default.background, GUI.colors.windows.tabBar.default.text, GUI.colors.windows.tabBar.selected.background, GUI.colors.windows.tabBar.selected.text, ...))
	window.backgroundPanel.localPosition.y, window.backgroundPanel.height = 4, window.height - 3
	window.actionButtons:moveToFront()
	window.actionButtons.localPosition.y = 2

	return window
end

----------------------------------------- Universal keyboard-input function -----------------------------------------

local function inputDraw(input)
	if input.oldPixels then
		buffer.paste(input.x, input.y, input.oldPixels)
	else
		input.oldPixels = buffer.copy(input.x, input.y, input.width, 1)
	end
	
	buffer.text(
		input.x,
		input.y,
		input.colors.text,
		unicode.sub(
			input.textMask and string.rep(input.textMask, unicode.len(input.text)) or input.text,
			input.textCutFrom,
			input.textCutFrom + input.width - 1
		)
	)

	if input.cursorBlinkState then
		buffer.text(input.x + input.cursorPosition - input.textCutFrom, input.y, input.cursorColor, input.cursorSymbol)
	end

	return input
end

local function inputSetCursorPosition(input, newPosition)
	if newPosition < 1 then
		newPosition = 1
	elseif newPosition > unicode.len(input.text) + 1 then
		newPosition = unicode.len(input.text) + 1
	end

	if newPosition > input.textCutFrom + input.width - 1 then
		input.textCutFrom = input.textCutFrom + newPosition - (input.textCutFrom + input.width - 1)
	elseif newPosition < input.textCutFrom then
		input.textCutFrom = newPosition
	end

	input.cursorPosition = newPosition

	return input
end

local function inputBeginInput(input)
	input.cursorBlinkState = true; input:draw(); buffer.draw()

	while true do
		local e = { event.pull(input.cursorBlinkDelay) }
		if e[1] == "touch" or e[1] == "drag" then
			if input:isClicked(e[3], e[4]) then
				input:setCursorPosition(input.textCutFrom + e[3] - input.x)
				input.cursorBlinkState = true; input:draw(); buffer.draw()
			else
				input.cursorBlinkState = false; input:draw(); buffer.draw()
				return input
			end
		elseif e[1] == "key_down" then
			-- Return
			if e[4] == 28 then
				input.cursorBlinkState = false; input:draw(); buffer.draw()
				return input
			-- Arrows left/right
			elseif e[4] == 203 then
				input:setCursorPosition(input.cursorPosition - 1)
			elseif e[4] == 205 then	
				input:setCursorPosition(input.cursorPosition + 1)
			-- Backspace
			elseif e[4] == 14 then
				input.text = unicode.sub(unicode.sub(input.text, 1, input.cursorPosition - 1), 1, -2) .. unicode.sub(input.text, input.cursorPosition, -1)
				input:setCursorPosition(input.cursorPosition - 1)
			-- Delete
			elseif e[4] == 211 then
				input.text = unicode.sub(input.text, 1, input.cursorPosition - 1) .. unicode.sub(input.text, input.cursorPosition + 1, -1)
			else
				if not keyboard.isControl(e[3]) then
					input.text = unicode.sub(input.text, 1, input.cursorPosition - 1) .. unicode.char(e[3]) .. unicode.sub(input.text, input.cursorPosition, -1)
					input:setCursorPosition(input.cursorPosition + 1)
				end
			end

			input.cursorBlinkState = true; input:draw(); buffer.draw()
		elseif e[1] == "clipboard" then
			input.text = unicode.sub(input.text, 1, input.cursorPosition - 1) .. e[3] .. unicode.sub(input.text, input.cursorPosition, -1)
			input:setCursorPosition(input.cursorPosition + unicode.len(e[3]))
			input.cursorBlinkState = true; input:draw(); buffer.draw()
		elseif not e[1] then
			input.cursorBlinkState = not input.cursorBlinkState; input:draw(); buffer.draw()
		end
	end
end

function GUI.input(x, y, width, textColor, text, textMask)
	local input = GUI.object(x, y, width, 1)

	input.textCutFrom = 1
	input.cursorPosition = 1
	input.cursorColor = 0x00A8FF
	input.cursorSymbol = "┃"
	input.cursorBlinkDelay = 0.4
	input.cursorBlinkState = false

	input.colors = {text = textColor}
	input.text = text
	input.textMask = textMask

	input.setCursorPosition = inputSetCursorPosition
	input.draw = inputDraw
	input.startInput = inputBeginInput

	input:setCursorPosition(unicode.len(input.text) + 1)

	return input
end

----------------------------------------- Input Text Box object -----------------------------------------

local function drawInputTextBox(inputField)
	local background = inputField.isFocused and inputField.colors.focused.background or inputField.colors.default.background
	local y = math.floor(inputField.y + inputField.height / 2)
	
	local text, foreground, textMask = inputField.text or "", inputField.colors.default.text, inputField.textMask
	if inputField.isFocused then
		if inputField.eraseTextOnFocus then
			text = ""
		else
			text = inputField.text or ""
		end

		foreground = inputField.colors.focused.text
	else
		if inputField.text == "" or not inputField.text then
			text, foreground, textMask = inputField.placeholderText or "", inputField.colors.placeholderText, nil
		end
	end

	if background then
		buffer.square(inputField.x, inputField.y, inputField.width, inputField.height, background, foreground, " ")
	end

	local input = GUI.input(inputField.x + 1, y, inputField.width - 2, foreground, text, textMask)	
	input.onKeyDown = inputField.onKeyDown

	if inputField.isFocused then
		input:startInput()
		if inputField.validator then
			if inputField.validator(input.text) then
				inputField.text = input.text
			end
		else
			inputField.text = input.text
		end
	else
		input:draw()
	end

	return inputField
end

local function inputFieldStartInput(inputField)
	inputField.isFocused = true
	inputField:draw()
	inputField.isFocused = false
	callMethod(inputField.onInputFinished, inputField.text)

	return inputField
end

local function inputFieldEventHandler(mainContainer, object, eventData)
	if eventData[1] == "touch" then
		object:startInput()
		mainContainer:draw()
		buffer.draw()
	end
end

function GUI.inputField(x, y, width, height, backgroundColor, textColor, placeholderTextColor, backgroundFocusedColor, textFocusedColor, text, placeholderText, eraseTextOnFocus, textMask)
	local inputField = GUI.object(x, y, width, height)
	inputField.colors = {
		default = {
			background = backgroundColor,
			text = textColor
		},
		focused = {
			background = backgroundFocusedColor,
			text = textFocusedColor
		},
		placeholderText = placeholderTextColor
	}

	inputField.eventHandler = inputFieldEventHandler
	inputField.text = text
	inputField.placeholderText = placeholderText
	inputField.draw = drawInputTextBox
	inputField.startInput = inputFieldStartInput
	inputField.eraseTextOnFocus = eraseTextOnFocus
	inputField.textMask = textMask

	return inputField
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
				object.subMenu.y = object.parent.y + object.localPosition.y - 1
				object.subMenu.x = object.parent.x + object.parent.width
				if buffer.width - object.parent.x - object.parent.width + 1 < object.subMenu.width then
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
	menu.height = math.min(totalHeight, menu.maximumHeight, buffer.height - menu.y)
	menu.itemsContainer.width, menu.itemsContainer.height = menu.width, menu.height

	menu.nextButton.localPosition.y = menu.height
	menu.prevButton.width, menu.nextButton.width = menu.width, menu.width
	menu.prevButton.hidden = menu.itemsContainer.children[1].localPosition.y >= 1
	menu.nextButton.hidden = menu.itemsContainer.children[#menu.itemsContainer.children].localPosition.y + menu.itemsContainer.children[#menu.itemsContainer.children].height - 1 <= menu.height
end

local function dropDownMenuAddItem(menu, text, disabled, shortcut, color)
	local item = menu.itemsContainer:addChild(GUI.object(1, #menu.itemsContainer.children == 0 and 1 or menu.itemsContainer.children[#menu.itemsContainer.children].localPosition.y + menu.itemsContainer.children[#menu.itemsContainer.children].height, menu.width, menu.itemHeight))

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
	if menu.itemsContainer.children[1].localPosition.y < 1 then
		for i = 1, #menu.itemsContainer.children do
			menu.itemsContainer.children[i].localPosition.y = menu.itemsContainer.children[i].localPosition.y + 1
		end
	end
	menu:draw()
	buffer.draw()
end

local function dropDownMenuScrollUp(menu)
	if menu.itemsContainer.children[#menu.itemsContainer.children].localPosition.y + menu.itemsContainer.children[#menu.itemsContainer.children].height - 1 > menu.height then
		for i = 1, #menu.itemsContainer.children do
			menu.itemsContainer.children[i].localPosition.y = menu.itemsContainer.children[i].localPosition.y - 1
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
end

local function contextMenuShow(menu)
	contextMenuCalculate(menu)
	if menu.y + menu.height >= buffer.height then menu.y = buffer.height - menu.height end
	if menu.x + menu.width + 1 >= buffer.width then menu.x = buffer.width - menu.width - 1 end

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
	local menu = GUI.dropDownMenu(x, y, 1, math.ceil(buffer.height * 0.5), 1,
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
	buffer.square(object.x, object.y, object.width, object.height, object.colors.default.background)
	local x, y, limit, arrowSize = object.x + 1, math.floor(object.y + object.height / 2), object.width - 5, object.height
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

	object.dropDownMenu = GUI.dropDownMenu(1, 1, 1, math.ceil(buffer.height * 0.5), elementHeight, object.colors.default.background, object.colors.default.text, object.colors.pressed.background, object.colors.pressed.text, GUI.colors.contextMenu.disabled, GUI.colors.contextMenu.separator, GUI.colors.contextMenu.transparency.background, GUI.colors.contextMenu.transparency.shadow)
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
	switchAndLabel.switch.localPosition.x = switchAndLabel.width - switchAndLabel.switch.width
	GUI.calculateChildAbsolutePosition(switchAndLabel.label)
	GUI.calculateChildAbsolutePosition(switchAndLabel.switch)
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

----------------------------------------- Text Box object -----------------------------------------

local function textBoxCalculate(object)
	object.textWidth = object.width - object.offset.horizontal * 2

	object.linesCopy = {}
	for i = 1, #object.lines do
		table.insert(object.linesCopy, object.lines[i])
	end

	if object.autoWrap then
		object.linesCopy = string.wrap(object.linesCopy, object.textWidth)
	end

	if object.autoHeight then
		object.height = #object.linesCopy
	end

	object.textHeight = object.height - object.offset.vertical * 2
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

	return object
end

local function scrollDownTextBox(object, count)
	count = count or 1
	local maxCountAvailableToScroll = #object.lines - object.height - object.currentLine + 1
	count = math.min(count, maxCountAvailableToScroll)
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
	object.currentLine = #lines
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

	textBoxCalculate(object)

	return object
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

--------------------------------------------------------------------------------------------------------------------------------

local function brailleCanvasDraw(brailleCanvas)
	local index, background, foreground, symbol
	for y = 1, brailleCanvas.height do
		for x = 1, brailleCanvas.width do
			index = buffer.getIndexByCoordinates(brailleCanvas.x + x - 1, brailleCanvas.y + y - 1)
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
	if column < 1 or column > #layout.grid.columnSizes or row < 1 or row > #layout.grid.rowSizes then
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
	local columnPercentageTotalSize, rowPercentageTotalSize = layout.width - layoutGetAbsoluteTotalSize(layout.grid.columnSizes), layout.height - layoutGetAbsoluteTotalSize(layout.grid.rowSizes)
	for row = 1, #layout.grid.rowSizes do
		layoutGetCalculatedSize(layout.grid.rowSizes, row, rowPercentageTotalSize)
		for column = 1, #layout.grid.columnSizes do
			layoutGetCalculatedSize(layout.grid.columnSizes, column, columnPercentageTotalSize)
			layout.grid[row][column].totalWidth, layout.grid[row][column].totalHeight = 0, 0
		end
	end

	-- Подготавливаем объекты к расположению и подсчитываем тотальные размеры
	for i = 1, #layout.children do
		if not layout.children[i].hidden then
			layout.children[i].layoutGridPosition = layout.children[i].layoutGridPosition or {column = 1, row = 1}

			-- Проверка на позицию в сетке
			if layout.children[i].layoutGridPosition.row >= 1 and layout.children[i].layoutGridPosition.row <= #layout.grid.rowSizes and layout.children[i].layoutGridPosition.column >= 1 and layout.children[i].layoutGridPosition.column <= #layout.grid.columnSizes then
				-- Авто-фиттинг объектов
				if layout.grid[layout.children[i].layoutGridPosition.row][layout.children[i].layoutGridPosition.column].fitting.horizontal then
					layout.children[i].width = math.floor(layout.grid.columnSizes[layout.children[i].layoutGridPosition.column].calculatedSize)
				end
				if layout.grid[layout.children[i].layoutGridPosition.row][layout.children[i].layoutGridPosition.column].fitting.vertical then
					layout.children[i].height = math.floor(layout.grid.rowSizes[layout.children[i].layoutGridPosition.row].calculatedSize)
				end

				-- Алигнмент и расчет размеров
				if layout.grid[layout.children[i].layoutGridPosition.row][layout.children[i].layoutGridPosition.column].direction == GUI.directions.horizontal then
					layout.grid[layout.children[i].layoutGridPosition.row][layout.children[i].layoutGridPosition.column].totalWidth = layout.grid[layout.children[i].layoutGridPosition.row][layout.children[i].layoutGridPosition.column].totalWidth + layout.children[i].width + layout.grid[layout.children[i].layoutGridPosition.row][layout.children[i].layoutGridPosition.column].spacing
					layout.grid[layout.children[i].layoutGridPosition.row][layout.children[i].layoutGridPosition.column].totalHeight = math.max(layout.grid[layout.children[i].layoutGridPosition.row][layout.children[i].layoutGridPosition.column].totalHeight, layout.children[i].height)
				else
					layout.grid[layout.children[i].layoutGridPosition.row][layout.children[i].layoutGridPosition.column].totalWidth = math.max(layout.grid[layout.children[i].layoutGridPosition.row][layout.children[i].layoutGridPosition.column].totalWidth, layout.children[i].width)
					layout.grid[layout.children[i].layoutGridPosition.row][layout.children[i].layoutGridPosition.column].totalHeight = layout.grid[layout.children[i].layoutGridPosition.row][layout.children[i].layoutGridPosition.column].totalHeight + layout.children[i].height + layout.grid[layout.children[i].layoutGridPosition.row][layout.children[i].layoutGridPosition.column].spacing
				end
			else
				error("Layout child with index " .. i .. " has been assigned to cell (" .. layout.children[i].layoutGridPosition.column .. "x" .. layout.children[i].layoutGridPosition.row .. ") out of layout grid range")
			end
		end
	end

	-- Высчитываем позицицию объектов
	local x, y = 1, 1
	for row = 1, #layout.grid.rowSizes do
		for column = 1, #layout.grid.columnSizes do
			layout.grid[row][column].x, layout.grid[row][column].y = GUI.getAlignmentCoordinates(
				{
					x = x,
					y = y,
					width = layout.grid.columnSizes[column].calculatedSize,
					height = layout.grid.rowSizes[row].calculatedSize,
					alignment = layout.grid[row][column].alignment,
				},
				{
					width = layout.grid[row][column].totalWidth - (layout.grid[row][column].direction == GUI.directions.horizontal and layout.grid[row][column].spacing or 0),
					height = layout.grid[row][column].totalHeight - (layout.grid[row][column].direction == GUI.directions.vertical and layout.grid[row][column].spacing or 0),
				}
			)
			if layout.grid[row][column].margin then
				layout.grid[row][column].x, layout.grid[row][column].y = GUI.getMarginCoordinates(layout.grid[row][column])
			end

			x = x + layout.grid.columnSizes[column].calculatedSize
		end

		x, y = 1, y + layout.grid.rowSizes[row].calculatedSize
	end

	-- Размещаем все объекты
	for i = 1, #layout.children do
		if not layout.children[i].hidden then
			if layout.grid[layout.children[i].layoutGridPosition.row][layout.children[i].layoutGridPosition.column].direction == GUI.directions.horizontal then
				layout.children[i].localPosition.x = math.floor(layout.grid[layout.children[i].layoutGridPosition.row][layout.children[i].layoutGridPosition.column].x)
				layout.children[i].localPosition.y = math.floor(layout.grid[layout.children[i].layoutGridPosition.row][layout.children[i].layoutGridPosition.column].y + layout.grid[layout.children[i].layoutGridPosition.row][layout.children[i].layoutGridPosition.column].totalHeight / 2 - layout.children[i].height / 2)
				layout.grid[layout.children[i].layoutGridPosition.row][layout.children[i].layoutGridPosition.column].x = layout.grid[layout.children[i].layoutGridPosition.row][layout.children[i].layoutGridPosition.column].x + layout.children[i].width + layout.grid[layout.children[i].layoutGridPosition.row][layout.children[i].layoutGridPosition.column].spacing
			else
				layout.children[i].localPosition.x = math.floor(layout.grid[layout.children[i].layoutGridPosition.row][layout.children[i].layoutGridPosition.column].x + layout.grid[layout.children[i].layoutGridPosition.row][layout.children[i].layoutGridPosition.column].totalWidth / 2 - layout.children[i].width / 2)
				layout.children[i].localPosition.y = math.floor(layout.grid[layout.children[i].layoutGridPosition.row][layout.children[i].layoutGridPosition.column].y)
				layout.grid[layout.children[i].layoutGridPosition.row][layout.children[i].layoutGridPosition.column].y = layout.grid[layout.children[i].layoutGridPosition.row][layout.children[i].layoutGridPosition.column].y + layout.children[i].height + layout.grid[layout.children[i].layoutGridPosition.row][layout.children[i].layoutGridPosition.column].spacing
			end
		end
	end
end

local function layoutSetCellPosition(layout, column, row, object)
	layoutCheckCell(layout, column, row)
	object.layoutGridPosition = {column = column, row = row}

	return object
end

local function layoutSetCellDirection(layout, column, row, direction)
	layoutCheckCell(layout, column, row)
	layout.grid[row][column].direction = direction

	return layout
end

local function layoutSetCellSpacing(layout, column, row, spacing)
	layoutCheckCell(layout, column, row)
	layout.grid[row][column].spacing = spacing

	return layout
end

local function layoutSetCellAlignment(layout, column, row, horizontalAlignment, verticalAlignment)
	layoutCheckCell(layout, column, row)
	layout.grid[row][column].alignment.horizontal, layout.grid[row][column].alignment.vertical = horizontalAlignment, verticalAlignment

	return layout
end

local function layoutSetCellMargin(layout, column, row, horizontalMargin, verticalMargin)
	layoutCheckCell(layout, column, row)
	layout.grid[row][column].margin = {
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
	layout.grid.columnSizes[column].sizePolicy, layout.grid.columnSizes[column].size = sizePolicy, size
	layoutCalculatePercentageSize(true, layout.grid.columnSizes, column)

	return layout
end

local function layoutSetRowHeight(layout, row, sizePolicy, size)
	layout.grid.rowSizes[row].sizePolicy, layout.grid.rowSizes[row].size = sizePolicy, size
	layoutCalculatePercentageSize(true, layout.grid.rowSizes, row)

	return layout
end

local function layoutAddColumn(layout, sizePolicy, size)
	for i = 1, #layout.grid.rowSizes do
		table.insert(layout.grid[i], layoutNewCell())
	end

	table.insert(layout.grid.columnSizes, {
		sizePolicy = sizePolicy,
		size = size
	})
	layoutCalculatePercentageSize(false, layout.grid.columnSizes, #layout.grid.columnSizes)
	-- GUI.error(layout.grid.columnSizes)

	return layout
end

local function layoutAddRow(layout, sizePolicy, size)
	local row = {}
	for i = 1, #layout.grid.columnSizes do
		table.insert(row, layoutNewCell())
	end

	table.insert(layout.grid, row)
	table.insert(layout.grid.rowSizes, {
		sizePolicy = sizePolicy,
		size = size
	})

	layoutCalculatePercentageSize(false, layout.grid.rowSizes, #layout.grid.rowSizes)
	-- GUI.error(layout.grid.rowSizes)

	return layout
end

local function layoutRemoveRow(layout, row)
	table.remove(layout.grid, row)

	layout.grid.rowSizes[row].size = 0
	layoutCalculatePercentageSize(false, layout.grid.rowSizes, row)

	table.remove(layout.grid.rowSizes, row)

	return layout
end

local function layoutRemoveColumn(layout, column)
	for i = 1, #layout.grid.rowSizes do
		table.remove(layout.grid[i], column)
	end

	layout.grid.columnSizes[column].size = 0
	layoutCalculatePercentageSize(false, layout.grid.columnSizes, column)

	table.remove(layout.grid.columnSizes, column)

	return layout
end

local function layoutSetGridSize(layout, columnCount, rowCount)
	layout.grid = {
		rowSizes = {},
		columnSizes = {}
	}

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
		for j = 1, #layout.grid.columnSizes do
			for i = 1, #layout.grid.rowSizes do
				buffer.frame(
					math.round(x),
					math.round(y),
					math.round(layout.grid.columnSizes[j].calculatedSize),
					math.round(layout.grid.rowSizes[i].calculatedSize),
					0xFF0000
				)
				y = y + layout.grid.rowSizes[i].calculatedSize
			end
			x, y = x + layout.grid.columnSizes[j].calculatedSize, layout.y
		end
	end
end

local function layoutFitToChildrenSize(layout, column, row)
	layout.width, layout.height = 0, 0

	for i = 1, #layout.children do
		if not layout.children[i].hidden then
			if layout.grid[row][column].direction == GUI.directions.horizontal then
				layout.width = layout.width + layout.children[i].width + layout.grid[row][column].spacing
				layout.height = math.max(layout.height, layout.children[i].height)
			else
				layout.width = math.max(layout.width, layout.children[i].width)
				layout.height = layout.height + layout.children[i].height + layout.grid[row][column].spacing
			end
		end
	end

	if layout.grid[row][column].direction == GUI.directions.horizontal then
		layout.width = layout.width - layout.grid[row][column].spacing
	else
		layout.height = layout.height - layout.grid[row][column].spacing
	end

	return layout
end

local function layoutSetCellFitting(layout, column, row, horizontalFitting, verticalFitting)
	layoutCheckCell(layout, column, row)
	layout.grid[row][column].fitting = {horizontal = horizontalFitting, vertical = verticalFitting}

	return layout
end

function GUI.layout(x, y, width, height, columnCount, rowCount)
	local layout = GUI.container(x, y, width, height)

	layout.addRow = layoutAddRow
	layout.addColumn = layoutAddColumn
	layout.removeRow = layoutRemoveRow
	layout.removeColumn = layoutRemoveColumn

	layout.setRowHeight = layoutSetRowHeight
	layout.setColumnWidth = layoutSetColumnWidth

	layout.update = layoutUpdate
	layout.setCellPosition = layoutSetCellPosition
	layout.setCellDirection = layoutSetCellDirection
	layout.setGridSize = layoutSetGridSize
	layout.setCellSpacing = layoutSetCellSpacing
	layout.setCellAlignment = layoutSetCellAlignment
	layout.setCellMargin = layoutSetCellMargin
	layout.fitToChildrenSize = layoutFitToChildrenSize
	layout.setCellFitting = layoutSetCellFitting

	layout.draw = layoutDraw

	layoutSetGridSize(layout, columnCount, rowCount)

	return layout
end

--------------------------------------------------------------------------------------------------------------------------------

-- local mainContainer = GUI.fullScreenContainer()
-- mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x262626))

-- local layout = mainContainer:addChild(GUI.layout(1, 1, mainContainer.width, mainContainer.height, 5, 1))
-- for i = 1, 5 do
-- 	layout:setCellPosition(3, 1, layout:addChild(GUI.button(1, 1, 30, 3, 0xFFFFFF, 0x0, 0xAAAAAA, 0x0, "Text " .. i)))
-- end
-- layout.showGrid = true
-- layout:setCellFitting(3, 1, true, false)

-- local brailleCanvas = mainContainer:addChild(GUI.brailleCanvas(2, 2, 30, 15))
-- for i = 1, brailleCanvas.width do
-- 	brailleCanvas:set(i, i, true, 0xFFFFFF)
-- 	brailleCanvas:set(brailleCanvas.width - i + 1, i, true, 0xFF0000)
-- end

-- mainContainer:draw()
-- buffer.draw(true)
-- mainContainer:startEventHandling()

--------------------------------------------------------------------------------------------------------------------------------

return GUI






