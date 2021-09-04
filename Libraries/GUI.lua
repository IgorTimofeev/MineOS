local keyboard = require("Keyboard")
local filesystem = require("Filesystem")
local event = require("Event")
local color = require("Color")
local image = require("Image")
local screen = require("Screen")
local paths = require("Paths")
local text = require("Text")
local number = require("Number")

-----------------------------------------------------------------------------------------

local GUI = {
	ALIGNMENT_HORIZONTAL_LEFT = 1,
	ALIGNMENT_HORIZONTAL_CENTER = 2,
	ALIGNMENT_HORIZONTAL_RIGHT = 3,
	ALIGNMENT_VERTICAL_TOP = 4,
	ALIGNMENT_VERTICAL_CENTER = 5,
	ALIGNMENT_VERTICAL_BOTTOM = 6,

	DIRECTION_HORIZONTAL = 7,
	DIRECTION_VERTICAL = 8,

	SIZE_POLICY_ABSOLUTE = 9,
	SIZE_POLICY_RELATIVE = 10,

	IO_MODE_FILE = 11,
	IO_MODE_DIRECTORY = 12,
	IO_MODE_BOTH = 13,
	IO_MODE_OPEN = 14,
	IO_MODE_SAVE = 15,

	BUTTON_PRESS_DURATION = 0.2,
	BUTTON_ANIMATION_DURATION = 0.2,
	SWITCH_ANIMATION_DURATION = 0.3,
	FILESYSTEM_DIALOG_ANIMATION_DURATION = 0.5,
	
	CONTEXT_MENU_SEPARATOR_COLOR = 0xA5A5A5,
	CONTEXT_MENU_DEFAULT_TEXT_COLOR = 0x2D2D2D,
	CONTEXT_MENU_DEFAULT_BACKGROUND_COLOR = 0xFFFFFF,
	CONTEXT_MENU_PRESSED_BACKGROUND_COLOR = 0x3366CC,
	CONTEXT_MENU_PRESSED_TEXT_COLOR = 0xFFFFFF,
	CONTEXT_MENU_DISABLED_COLOR = 0x878787,
	CONTEXT_MENU_BACKGROUND_TRANSPARENCY = 0.18,
	CONTEXT_MENU_SHADOW_TRANSPARENCY = 0.4,

	BACKGROUND_CONTAINER_PANEL_COLOR = 0x0,
	BACKGROUND_CONTAINER_TITLE_COLOR = 0xE1E1E1,
	BACKGROUND_CONTAINER_PANEL_TRANSPARENCY = 0.3,

	WINDOW_BACKGROUND_PANEL_COLOR = 0xF0F0F0,
	WINDOW_SHADOW_TRANSPARENCY = 0.6,
	WINDOW_TITLE_BACKGROUND_COLOR = 0xE1E1E1,
	WINDOW_TITLE_TEXT_COLOR = 0x2D2D2D,
	WINDOW_TAB_BAR_DEFAULT_BACKGROUND_COLOR = 0x2D2D2D,
	WINDOW_TAB_BAR_DEFAULT_TEXT_COLOR = 0xF0F0F0,
	WINDOW_TAB_BAR_SELECTED_BACKGROUND_COLOR = 0xF0F0F0,
	WINDOW_TAB_BAR_SELECTED_TEXT_COLOR = 0x2D2D2D,

	LUA_SYNTAX_COLOR_SCHEME = {
		background = 0x1E1E1E,
		text = 0xE1E1E1,
		strings = 0x99FF80,
		loops = 0xFFFF98,
		comments = 0x898989,
		boolean = 0xFFDB40,
		logic = 0xFFCC66,
		numbers = 0x66DBFF,
		functions = 0xFFCC66,
		compares = 0xFFCC66,
		lineNumbersBackground = 0x2D2D2D,
		lineNumbersText = 0xC3C3C3,
		scrollBarBackground = 0x2D2D2D,
		scrollBarForeground = 0x5A5A5A,
		selection = 0x4B4B4B,
		indentation = 0x2D2D2D
	},

	LUA_SYNTAX_PATTERNS = {
		"[%.%,%>%<%=%~%+%-%*%/%^%#%%%&]", "compares", 0, 0,
		"[^%a%d][%.%d]+[^%a%d]", "numbers", 1, 1,
		"[^%a%d][%.%d]+$", "numbers", 1, 0,
		"0x%w+", "numbers", 0, 0,
		" not ", "logic", 0, 1,
		" or ", "logic", 0, 1,
		" and ", "logic", 0, 1,
		"function%(", "functions", 0, 1,
		"function%s[^%s%(%)%{%}%[%]]+%(", "functions", 9, 1,
		"nil", "boolean", 0, 0,
		"false", "boolean", 0, 0,
		"true", "boolean", 0, 0,
		" break$", "loops", 0, 0,
		"elseif ", "loops", 0, 1,
		"else[%s%;]", "loops", 0, 1,
		"else$", "loops", 0, 0,
		"function ", "loops", 0, 1,
		"local ", "loops", 0, 1,
		"return", "loops", 0, 0,
		"until ", "loops", 0, 1,
		"then", "loops", 0, 0,
		"if ", "loops", 0, 1,
		"repeat$", "loops", 0, 0,
		" in ", "loops", 0, 1,
		"for ", "loops", 0, 1,
		"end[%s%;]", "loops", 0, 1,
		"end$", "loops", 0, 0,
		"do ", "loops", 0, 1,
		"do$", "loops", 0, 0,
		"while ", "loops", 0, 1,
		"\'[^\']+\'", "strings", 0, 0,
		"\"[^\"]+\"", "strings", 0, 0,
		"%-%-.+", "comments", 0, 0,
	},
}

--------------------------------------------------------------------------------

function GUI.setAlignment(object, horizontalAlignment, verticalAlignment)
	object.horizontalAlignment, object.verticalAlignment = horizontalAlignment, verticalAlignment
	
	return object
end

function GUI.getAlignmentCoordinates(x, y, width1, height1, horizontalAlignment, verticalAlignment, width2, height2)
	if horizontalAlignment == GUI.ALIGNMENT_HORIZONTAL_CENTER then
		x = x + width1 / 2 - width2 / 2
	elseif horizontalAlignment == GUI.ALIGNMENT_HORIZONTAL_RIGHT then
		x = x + width1 - width2
	elseif horizontalAlignment ~= GUI.ALIGNMENT_HORIZONTAL_LEFT then
		error("Unknown horizontal alignment: " .. tostring(horizontalAlignment))
	end

	if verticalAlignment == GUI.ALIGNMENT_VERTICAL_CENTER then
		y = y + height1 / 2 - height2 / 2
	elseif verticalAlignment == GUI.ALIGNMENT_VERTICAL_BOTTOM then
		y = y + height1 - height2
	elseif verticalAlignment ~= GUI.ALIGNMENT_VERTICAL_TOP then
		error("Unknown vertical alignment: " .. tostring(verticalAlignment))
	end

	return x, y
end

function GUI.getMarginCoordinates(x, y, horizontalAlignment, verticalAlignment, horizontalMargin, verticalMargin)
	if horizontalAlignment == GUI.ALIGNMENT_HORIZONTAL_RIGHT then
		x = x - horizontalMargin
	else
		x = x + horizontalMargin
	end
	
	if verticalAlignment == GUI.ALIGNMENT_VERTICAL_BOTTOM then
		y = y - verticalMargin
	else
		y = y + verticalMargin
	end

	return x, y
end

--------------------------------------------------------------------------------

local function objectIsPointInside(object, x, y)
	return 
		x >= object.x and
		x < object.x + object.width and
		y >= object.y and
		y < object.y + object.height
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
		isPointInside = objectIsPointInside,
		draw = objectDraw
	}
end

--------------------------------------------------------------------------------

local function containerObjectIndexOf(object)
	if not object.parent then error("Object doesn't have a parent container") end

	for objectIndex = 1, #object.parent.children do
		if object.parent.children[objectIndex] == object then
			return objectIndex
		end
	end
end

local function containerObjectMoveForward(object)
	local objectIndex = containerObjectIndexOf(object)
	if objectIndex < #object.parent.children then
		object.parent.children[objectIndex], object.parent.children[objectIndex + 1] = object.parent.children[objectIndex + 1], object.parent.children[objectIndex]
	end
	
	return object
end

local function containerObjectMoveBackward(object)
	local objectIndex = containerObjectIndexOf(object)
	if objectIndex > 1 then
		object.parent.children[objectIndex], object.parent.children[objectIndex - 1] = object.parent.children[objectIndex - 1], object.parent.children[objectIndex]
	end
	
	return object
end

local function containerObjectMoveToFront(object)
	table.remove(object.parent.children, containerObjectIndexOf(object))
	table.insert(object.parent.children, object)
	
	return object
end

local function containerObjectMoveToBack(object)
	table.remove(object.parent.children, containerObjectIndexOf(object))
	table.insert(object.parent.children, 1, object)
	
	return object
end

local function containerObjectRemove(object)
	table.remove(object.parent.children, containerObjectIndexOf(object))
end

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

local function containerObjectAnimationRemove(animation)
	animation.removeLater = true
end

local function containerObjectAddAnimation(object, frameHandler, onFinish)
	local animation = {
		object = object,
		position = 0,
		start = containerObjectAnimationStart,
		stop = containerObjectAnimationStop,
		remove = containerObjectAnimationRemove,
		frameHandler = frameHandler,
		onFinish = onFinish,
	}

	object.firstParent.animations = object.firstParent.animations or {}
	table.insert(object.firstParent.animations, animation)

	return animation
end

local function containerAddChild(container, object, atIndex)
	object.localX = object.x
	object.localY = object.y
	object.indexOf = containerObjectIndexOf
	object.moveToFront = containerObjectMoveToFront
	object.moveToBack = containerObjectMoveToBack
	object.moveForward = containerObjectMoveForward
	object.moveBackward = containerObjectMoveBackward
	object.remove = containerObjectRemove
	object.addAnimation = containerObjectAddAnimation

	local function updateFirstParent(object, firstParent)
		object.firstParent = firstParent
		if object.children then
			for i = 1, #object.children do
				updateFirstParent(object.children[i], firstParent)
			end
		end
	end

	object.parent = container
	updateFirstParent(object, container.firstParent or container)

	if atIndex then
		table.insert(container.children, atIndex, object)
	else
		table.insert(container.children, object)
	end
	
	return object
end

local function containerRemoveChildren(container, from, to)
	from = from or 1
	for objectIndex = from, to or #container.children do
		table.remove(container.children, from)
	end
end

local function getRectangleIntersection(R1X1, R1Y1, R1X2, R1Y2, R2X1, R2Y1, R2X2, R2Y2)
	if R2X1 <= R1X2 and R2Y1 <= R1Y2 and R2X2 >= R1X1 and R2Y2 >= R1Y1 then
		return
			math.max(R2X1, R1X1),
			math.max(R2Y1, R1Y1),
			math.min(R2X2, R1X2),
			math.min(R2Y2, R1Y2)
	else
		return
	end
end

local function containerDraw(container)
	local R1X1, R1Y1, R1X2, R1Y2, child = screen.getDrawLimit()
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
		screen.setDrawLimit(intersectionX1, intersectionY1, intersectionX2, intersectionY2)
		
		for i = 1, #container.children do
			child = container.children[i]
			
			if not child.hidden then
				child.x, child.y = container.x + child.localX - 1, container.y + child.localY - 1
				child:draw()
			end
		end

		screen.setDrawLimit(R1X1, R1Y1, R1X2, R1Y2)
	end

	return container
end

function GUI.container(x, y, width, height)
	local container = GUI.object(x, y, width, height)

	container.children = {}
	container.passScreenEvents = true
	
	container.draw = containerDraw
	container.removeChildren = containerRemoveChildren
	container.addChild = containerAddChild
	
	return container
end

--------------------------------------------------------------------------------

local function workspaceStart(workspace, eventPullTimeout)
	local animation, animationIndex, animationOnFinishMethodsIndex, animationOnFinishMethods, e1, e2, e3, e4, e5, e6, e7, e8, e9, e10, e11, e12, e13, e14, e15, e16, e17, e18, e19, e20, e21, e22, e23, e24, e25, e26, e27, e28, e29, e30, e31, e32
	
	local function handle(isScreenEvent, currentContainer, intersectionX1, intersectionY1, intersectionX2, intersectionY2)
		if
			not isScreenEvent or
			intersectionX1 and
			e3 >= intersectionX1 and
			e3 <= intersectionX2 and
			e4 >= intersectionY1 and
			e4 <= intersectionY2
		then
			local currentContainerPassed, child, newIntersectionX1, newIntersectionY1, newIntersectionX2, newIntersectionY2

			if isScreenEvent then
				if currentContainer.eventHandler and not currentContainer.disabled then
					currentContainer.eventHandler(workspace, currentContainer, e1, e2, e3, e4, e5, e6, e7, e8, e9, e10, e11, e12, e13, e14, e15, e16, e17, e18, e19, e20, e21, e22, e23, e24, e25, e26, e27, e28, e29, e30, e31, e32)
				end

				currentContainerPassed = not currentContainer.passScreenEvents
			elseif currentContainer.eventHandler then
				currentContainer.eventHandler(workspace, currentContainer, e1, e2, e3, e4, e5, e6, e7, e8, e9, e10, e11, e12, e13, e14, e15, e16, e17, e18, e19, e20, e21, e22, e23, e24, e25, e26, e27, e28, e29, e30, e31, e32)
			end

			for i = #currentContainer.children, 1, -1 do
				child = currentContainer.children[i]

				if not child.hidden then
					if child.children then
						newIntersectionX1, newIntersectionY1, newIntersectionX2, newIntersectionY2 = getRectangleIntersection(
							intersectionX1,
							intersectionY1,
							intersectionX2,
							intersectionY2,
							child.x,
							child.y,
							child.x + child.width - 1,
							child.y + child.height - 1
						)

						if 
							newIntersectionX1 and
							handle(
								isScreenEvent,
								child,
								newIntersectionX1,
								newIntersectionY1,
								newIntersectionX2,
								newIntersectionY2,
								e1, e2, e3, e4, e5, e6, e7, e8, e9, e10, e11, e12, e13, e14, e15, e16, e17, e18, e19, e20, e21, e22, e23, e24, e25, e26, e27, e28, e29, e30, e31, e32
							)
						then
							return true
						end
					else
						if workspace.needConsume then
							workspace.needConsume = nil
							return true
						end

						if isScreenEvent then
							if child:isPointInside(e3, e4) then
								if child.eventHandler and not child.disabled then
									child.eventHandler(workspace, child, e1, e2, e3, e4, e5, e6, e7, e8, e9, e10, e11, e12, e13, e14, e15, e16, e17, e18, e19, e20, e21, e22, e23, e24, e25, e26, e27, e28, e29, e30, e31, e32)
								end

								if not child.passScreenEvents then
									return true
								end
							end
						elseif child.eventHandler then
							child.eventHandler(workspace, child, e1, e2, e3, e4, e5, e6, e7, e8, e9, e10, e11, e12, e13, e14, e15, e16, e17, e18, e19, e20, e21, e22, e23, e24, e25, e26, e27, e28, e29, e30, e31, e32)
						end
					end
				end
			end

			if currentContainerPassed then
				return true
			end
		end
	end

	workspace.eventPullTimeout = eventPullTimeout

	repeat
		e1, e2, e3, e4, e5, e6, e7, e8, e9, e10, e11, e12, e13, e14, e15, e16, e17, e18, e19, e20, e21, e22, e23, e24, e25, e26, e27, e28, e29, e30, e31, e32 = event.pull(workspace.animations and 0 or workspace.eventPullTimeout)
		
		handle(
			e1 == "touch" or
			e1 == "drag" or
			e1 == "drop" or
			e1 == "scroll" or
			e1 == "double_touch",
			workspace,
			workspace.x,
			workspace.y,
			workspace.x + workspace.width - 1,
			workspace.y + workspace.height - 1
		)

		if workspace.animations then
			animationIndex, animationOnFinishMethodsIndex, animationOnFinishMethods = 1, 1, {}
			-- Продрачиваем анимации и вызываем обработчики кадров
			while animationIndex <= #workspace.animations do
				animation = workspace.animations[animationIndex]

				if animation.removeLater then
					table.remove(workspace.animations, animationIndex)

					if #workspace.animations == 0 then
						workspace.animations = nil
						break
					end
				else
					if animation.started then
						animation.position = (computer.uptime() - animation.startUptime) / animation.duration
						
						if animation.position < 1 then
							animation.frameHandler(animation)
						else
							animation.position, animation.started = 1, false
							animation.frameHandler(animation)
							
							if animation.onFinish then
								animationOnFinishMethods[animationOnFinishMethodsIndex] = animation
								animationOnFinishMethodsIndex = animationOnFinishMethodsIndex + 1
							end
						end
					end

					animationIndex = animationIndex + 1
				end
			end

			-- По завершению продрочки отрисовываем изменения на экране
			workspace:draw()

			-- Вызываем поочередно все методы .onFinish
			for i = 1, #animationOnFinishMethods do
				animationOnFinishMethods[i].onFinish(animationOnFinishMethods[i])
			end
		end
	until workspace.needClose

	workspace.needClose = nil
end

local function workspaceStop(workspace)
	workspace.needClose = true
end

local function workspaceConsumeEvent(workspace)
	workspace.needConsume = true
end

local function workspaceDraw(object, ...)
	containerDraw(object)
	screen.update(...)
end

function GUI.workspace(x, y, width, height)
	local workspace = GUI.container(x or 1, y or 1, width or screen.getWidth(), height or screen.getHeight())
	
	workspace.draw = workspaceDraw
	workspace.start = workspaceStart
	workspace.stop = workspaceStop
	workspace.consumeEvent = workspaceConsumeEvent

	return workspace
end

--------------------------------------------------------------------------------

local function pressableDraw(pressable)
	local background = pressable.pressed and pressable.colors.pressed.background or pressable.disabled and pressable.colors.disabled.background or pressable.colors.default.background
	local text = pressable.pressed and pressable.colors.pressed.text or pressable.disabled and pressable.colors.disabled.text or pressable.colors.default.text

	if background then
		screen.drawRectangle(pressable.x, pressable.y, pressable.width, pressable.height, background, text, " ")
	end
	
	screen.drawText(math.floor(pressable.x + pressable.width / 2 - unicode.len(pressable.text) / 2), math.floor(pressable.y + pressable.height / 2), text, pressable.text)
end

local function pressableHandlePress(workspace, pressable, ...)
	pressable.pressed = not pressable.pressed
	workspace:draw()

	if not pressable.switchMode then
		pressable.pressed = not pressable.pressed
		event.sleep(GUI.BUTTON_PRESS_DURATION)
		
		workspace:draw()
	end

	if pressable.onTouch then
		pressable.onTouch(workspace, pressable, ...)
	end
end

local function pressableEventHandler(workspace, pressable, e1, ...)
	if e1 == "touch" then
		pressableHandlePress(workspace, pressable, e1, ...)
	end
end

local function pressable(x, y, width, height, backgroundColor, textColor, backgroundPressedColor, textPressedColor, backgroundDisabledColor, textDisabledColor, text)
	local pressable = GUI.object(x, y, width, height)

	pressable.colors = {
		default = {
			background = backgroundColor,
			text = textColor
		},
		pressed = {
			background = backgroundPressedColor,
			text = textPressedColor
		},
		disabled = {
			background = backgroundDisabledColor,
			text = textDisabledColor
		}
	}

	pressable.pressed = false
	pressable.text = text
	pressable.draw = pressableDraw
	pressable.eventHandler = pressableEventHandler

	return pressable
end

--------------------------------------------------------------------------------

local function buttonPlayAnimation(button, onFinish)
	button.animationStarted = true
	button:addAnimation(
		function(animation)
			if button.pressed then
				if button.colors.default.background and button.colors.pressed.background then
					button.animationCurrentBackground = color.transition(button.colors.pressed.background, button.colors.default.background, animation.position)
				end
				button.animationCurrentText = color.transition(button.colors.pressed.text, button.colors.default.text, animation.position)
			else
				if button.colors.default.background and button.colors.pressed.background then
					button.animationCurrentBackground = color.transition(button.colors.default.background, button.colors.pressed.background, animation.position)
				end
				button.animationCurrentText = color.transition(button.colors.default.text, button.colors.pressed.text, animation.position)
			end
		end,
		function(animation)
			button.animationStarted = false
			button.pressed = not button.pressed
			onFinish(animation)
		end
	):start(button.animationDuration)
end

local function buttonPress(button, workspace, object, ...)
	if button.animated then
		local eventData = {...}
		
		buttonPlayAnimation(button, function(animation)
			if button.onTouch then
				button.onTouch(workspace, button, table.unpack(eventData))
			end

			animation:remove()

			if not button.switchMode then
				buttonPlayAnimation(button, function(animation)
					animation:remove()
				end)
			end
		end)
	else
		pressableHandlePress(workspace, button, ...)
	end
end

local function buttonEventHandler(workspace, button, e1, ...)
	if e1 == "touch" and (not button.animated or not button.animationStarted) then
		button:press(workspace, button, e1, ...)
	end
end

local function buttonGetColors(button)
	if button.disabled then
		return button.colors.disabled.background, button.colors.disabled.text
	else
		if button.animated and button.animationStarted then
			return button.animationCurrentBackground, button.animationCurrentText
		else
			if button.pressed then
				return button.colors.pressed.background, button.colors.pressed.text
			else
				return button.colors.default.background, button.colors.default.text
			end
		end
	end
end

local function buttonDrawText(button, textColor)
	screen.drawText(math.floor(button.x + button.width / 2 - unicode.len(button.text) / 2), math.floor(button.y + button.height / 2), textColor, button.text)
end

local function buttonDraw(button)
	local backgroundColor, textColor = buttonGetColors(button)
	
	if backgroundColor then
		screen.drawRectangle(button.x, button.y, button.width, button.height, backgroundColor, textColor, " ", button.colors.transparency)
	end
	buttonDrawText(button, textColor)
end

local function framedButtonDraw(button)
	local backgroundColor, textColor = buttonGetColors(button)
	
	if backgroundColor then
		screen.drawFrame(button.x, button.y, button.width, button.height, backgroundColor)
	end
	buttonDrawText(button, textColor)
end

local function roundedButtonDraw(button)
	local backgroundColor, textColor = buttonGetColors(button)

	if backgroundColor then
		local x2, y2 = button.x + button.width - 1, button.y + button.height - 1
		if button.height > 1 then
			screen.drawText(button.x + 1, button.y, backgroundColor, string.rep("▄", button.width - 2))
			screen.drawText(button.x, button.y, backgroundColor, "⣠")
			screen.drawText(x2, button.y, backgroundColor, "⣄")
			
			screen.drawRectangle(button.x, button.y + 1, button.width, button.height - 2, backgroundColor, textColor, " ")
			
			screen.drawText(button.x + 1, y2, backgroundColor, string.rep("▀", button.width - 2))
			screen.drawText(button.x, y2, backgroundColor, "⠙")
			screen.drawText(x2, y2, backgroundColor, "⠋")
		else
			screen.drawRectangle(button.x, button.y, button.width, button.height, backgroundColor, textColor, " ")
			GUI.roundedCorners(button.x, button.y, button.width, button.height, backgroundColor)
		end
	end

	buttonDrawText(button, textColor)
end

local function tagButtonDraw(button)
	local backgroundColor, textColor = buttonGetColors(button)
	
	screen.drawRectangle(button.x, button.y, button.width, button.height, backgroundColor, textColor, " ")
	screen.drawText(button.x - 1, button.y, backgroundColor, "◀")
	buttonDrawText(button, textColor)
end

local function buttonCreate(x, y, width, height, backgroundColor, textColor, backgroundPressedColor, textPressedColor, text)
	local button = pressable(x, y, width, height, backgroundColor, textColor, backgroundPressedColor, textPressedColor, 0x878787, 0xA5A5A5, text)

	button.animationDuration = GUI.BUTTON_ANIMATION_DURATION
	button.animated = true

	button.animationCurrentBackground = backgroundColor
	button.animationCurrentText = textColor
	
	button.press = buttonPress
	button.eventHandler = buttonEventHandler

	return button
end

local function adaptiveButtonCreate(x, y, xOffset, yOffset, backgroundColor, textColor, backgroundPressedColor, textPressedColor, text)
	return buttonCreate(x, y, unicode.len(text) + xOffset * 2, yOffset * 2 + 1, backgroundColor, textColor, backgroundPressedColor, textPressedColor, text)
end

function GUI.button(...)
	local button = buttonCreate(...)
	button.draw = buttonDraw

	return button
end

function GUI.adaptiveButton(...)
	local button = adaptiveButtonCreate(...)
	button.draw = buttonDraw

	return button
end

function GUI.framedButton(...)
	local button = buttonCreate(...)
	button.draw = framedButtonDraw

	return button
end

function GUI.adaptiveFramedButton(...)
	local button = adaptiveButtonCreate(...)
	button.draw = framedButtonDraw

	return button
end

function GUI.roundedButton(...)
	local button = buttonCreate(...)
	button.draw = roundedButtonDraw

	return button
end

function GUI.adaptiveRoundedButton(...)
	local button = adaptiveButtonCreate(...)
	button.draw = roundedButtonDraw

	return button
end

function GUI.tagButton(...)
	local button = buttonCreate(...)
	button.draw = tagButtonDraw

	return button
end

function GUI.adaptiveTagButton(...)
	local button = adaptiveButtonCreate(...)
	button.draw = tagButtonDraw

	return button
end

--------------------------------------------------------------------------------

local function drawPanel(object)
	screen.drawRectangle(object.x, object.y, object.width, object.height, object.colors.background, 0x0, " ", object.colors.transparency)
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

--------------------------------------------------------------------------------

local function blurredPanelDraw(object)
	screen.blur(object.x, object.y, object.width, object.height, object.radius, object.color, object.transparency)
end

function GUI.blurredPanel(x, y, width, height, radius, color, transparency)
	local object = GUI.object(x, y, width, height)

	object.radius = radius or 3
	object.color = color
	object.transparency = transparency

	object.draw = blurredPanelDraw

	return object
end

--------------------------------------------------------------------------------

local function drawLabel(object)
	local xText, yText = GUI.getAlignmentCoordinates(
		object.x,
		object.y,
		object.width,
		object.height,
		object.horizontalAlignment,
		object.verticalAlignment,
		unicode.len(object.text),
		1
	)
	screen.drawText(math.floor(xText), math.floor(yText), object.colors.text, object.text)
	return object
end

function GUI.label(x, y, width, height, textColor, text)
	local object = GUI.object(x, y, width, height)
	
	object.setAlignment = GUI.setAlignment
	object:setAlignment(GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_TOP)
	object.colors = {text = textColor}
	object.text = text
	object.draw = drawLabel

	return object
end

--------------------------------------------------------------------------------

local function drawImage(object)
	screen.drawImage(object.x, object.y, object.image)
	return object
end

function GUI.image(x, y, image)
	local object = GUI.object(x, y, image[1], image[2])

	object.image = image
	object.draw = drawImage

	return object
end

--------------------------------------------------------------------------------

function GUI.actionButtons(x, y, fatSymbol)
	local symbol = fatSymbol and "⬤" or "●"
	
	local container = GUI.container(x, y, 5, 1)
	container.close = container:addChild(GUI.button(1, 1, 1, 1, nil, 0xFF4940, nil, 0x992400, symbol))
	container.minimize = container:addChild(GUI.button(3, 1, 1, 1, nil, 0xFFB640, nil, 0x996D00, symbol))
	container.maximize = container:addChild(GUI.button(5, 1, 1, 1, nil, 0x00B640, nil, 0x006D40, symbol))

	return container
end

--------------------------------------------------------------------------------

local function drawProgressBar(object)
	local activeWidth = math.floor(math.min(object.value, 100) / 100 * object.width)
	if object.thin then
		screen.drawText(object.x, object.y, object.colors.passive, string.rep("━", object.width))
		screen.drawText(object.x, object.y, object.colors.active, string.rep("━", activeWidth))
	else
		screen.drawRectangle(object.x, object.y, object.width, object.height, object.colors.passive, 0x0, " ")
		screen.drawRectangle(object.x, object.y, activeWidth, object.height, object.colors.active, 0x0, " ")
	end

	if object.showValue then
		local stringValue = (object.valuePrefix or "") .. object.value .. (object.valuePostfix or "")
		screen.drawText(math.floor(object.x + object.width / 2 - unicode.len(stringValue) / 2), object.y + 1, object.colors.value, stringValue)
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

--------------------------------------------------------------------------------

function GUI.drawShadow(x, y, width, height, transparency, thin)
	if thin then
		screen.drawRectangle(x + width, y + 1, 1, height - 1, 0x0, 0x0, " ", transparency)
		screen.drawText(x + 1, y + height, 0x0, string.rep("▀", width), transparency)
		screen.drawText(x + width, y, 0x0, "▄", transparency)
	else
		screen.drawRectangle(x + width, y + 1, 2, height, 0x0, 0x0, " ", transparency)
		screen.drawRectangle(x + 2, y + height, width - 2, 1, 0x0, 0x0, " ", transparency)
	end
end

function GUI.roundedCorners(x, y, width, height, color, transparency)
	screen.drawText(x - 1, y, color, "⠰", transparency)
	screen.drawText(x + width, y, color, "⠆", transparency)
end

--------------------------------------------------------------------------------

function GUI.alert(...)
	local args = {...}
	for i = 1, #args do
		if type(args[i]) == "table" then
			args[i] = text.serialize(args[i], true)
		else
			args[i] = tostring(args[i])
		end
	end
	if #args == 0 then args[1] = "nil" end

	local sign = image.fromString([[06030000FF 0000FF 00F7FF▟00F7FF▙0000FF 0000FF 0000FF 00F7FF▟F7FF00 F7FF00 00F7FF▙0000FF 00F7FF▟F7FF00CF7FF00yF7FF00kF7FF00a00F7FF▙]])
	local offset = 2
	local lines = #args > 1 and "\"" .. table.concat(args, "\", \"") .. "\"" or args[1]
	local bufferWidth, bufferHeight = screen.getResolution()
	local width = math.floor(bufferWidth * 0.5)
	local textWidth = width - image.getWidth(sign) - 2

	lines = text.wrap(lines, textWidth)
	local height = image.getHeight(sign)
	if #lines + 2 > height then
		height = #lines + 2
	end

	local workspace = GUI.workspace(1, math.floor(bufferHeight / 2 - height / 2), bufferWidth, height + offset * 2)
	local oldPixels = screen.copy(workspace.x, workspace.y, workspace.width, workspace.height)

	local x, y = math.floor(bufferWidth / 2 - width / 2), offset + 1
	workspace:addChild(GUI.panel(1, 1, workspace.width, workspace.height, 0x1D1D1D))
	workspace:addChild(GUI.image(x, y, sign))
	workspace:addChild(GUI.textBox(x + image.getWidth(sign) + 2, y, textWidth, #lines, 0x1D1D1D, 0xE1E1E1, lines, 1, 0, 0)).eventHandler = nil
	local buttonWidth = 10
	local button = workspace:addChild(GUI.roundedButton(x + image.getWidth(sign) + textWidth - buttonWidth + 2, workspace.height - offset, buttonWidth, 1, 0x3366CC, 0xE1E1E1, 0xE1E1E1, 0x3366CC, "OK"))
	
	button.onTouch = function()
		workspace:stop()
		screen.paste(workspace.x, workspace.y, oldPixels)
		screen.update()
	end

	workspace.eventHandler = function(workspace, object, e1, e2, e3, e4, ...)
		if e1 == "key_down" and e4 == 28 then
			button.animated = false
			button:press(workspace, object, e1, e2, e3, e4, ...)
		end
	end

	workspace:draw(true)
	workspace:start()
end

--------------------------------------------------------------------------------

local function codeViewDraw(codeView)
	local y, toLine, colorScheme, patterns = codeView.y, codeView.fromLine + codeView.height - 1, codeView.syntaxColorScheme, codeView.syntaxPatterns
	
	-- Line numbers bar and code area
	codeView.lineNumbersWidth = unicode.len(tostring(toLine)) + 2
	codeView.codeAreaPosition = codeView.x + codeView.lineNumbersWidth
	codeView.codeAreaWidth = codeView.width - codeView.lineNumbersWidth
	
	-- Line numbers 
	screen.drawRectangle(codeView.x, y, codeView.lineNumbersWidth, codeView.height, colorScheme.lineNumbersBackground, colorScheme.lineNumbersText, " ")	
	
	-- Background
	screen.drawRectangle(codeView.codeAreaPosition, y, codeView.codeAreaWidth, codeView.height, colorScheme.background, colorScheme.text, " ")
	
	-- Line numbers texts
	local text
	for line = codeView.fromLine, toLine do
		if codeView.lines[line] then
			text = line .. ""
			if codeView.highlights[line] then
				screen.drawRectangle(codeView.x, y, codeView.lineNumbersWidth, 1, codeView.highlights[line], colorScheme.text, " ", 0.3)
				screen.drawRectangle(codeView.codeAreaPosition, y, codeView.codeAreaWidth, 1, codeView.highlights[line], colorScheme.text, " ")
			end

			screen.drawText(codeView.codeAreaPosition - unicode.len(text) - 1, y, colorScheme.lineNumbersText, text)
			
			y = y + 1
		else
			break
		end	
	end
	
	if #codeView.selections > 0 then
		local function drawUpperSelection(y, selectionIndex)
			screen.drawRectangle(
				math.max(codeView.codeAreaPosition, codeView.codeAreaPosition + codeView.selections[selectionIndex].from.symbol - codeView.fromSymbol + 1),
				y + codeView.selections[selectionIndex].from.line - codeView.fromLine,
				codeView.codeAreaWidth - codeView.selections[selectionIndex].from.symbol + codeView.fromSymbol - 1,
				1,
				codeView.selections[selectionIndex].color or colorScheme.selection,
				colorScheme.text,
				" "
			)
		end

		local function drawLowerSelection(y, selectionIndex)
			screen.drawRectangle(
				codeView.codeAreaPosition,
				y + codeView.selections[selectionIndex].from.line - codeView.fromLine,
				codeView.selections[selectionIndex].to.symbol - codeView.fromSymbol + 2,
				1,
				codeView.selections[selectionIndex].color or colorScheme.selection,
				colorScheme.text,
				" "
			)
		end

		for selectionIndex = 1, #codeView.selections do
			y = codeView.y
			local dy = codeView.selections[selectionIndex].to.line - codeView.selections[selectionIndex].from.line
			
			if dy == 0 then
				screen.drawRectangle(
					codeView.codeAreaPosition + codeView.selections[selectionIndex].from.symbol - codeView.fromSymbol + 1,
					y + codeView.selections[selectionIndex].from.line - codeView.fromLine,
					codeView.selections[selectionIndex].to.symbol - codeView.selections[selectionIndex].from.symbol + 1,
					1,
					codeView.selections[selectionIndex].color or colorScheme.selection, colorScheme.text, " "
				)
			elseif dy == 1 then
				drawUpperSelection(y, selectionIndex)
				y = y + 1

				drawLowerSelection(y, selectionIndex)
			else
				drawUpperSelection(y, selectionIndex)
				y = y + 1
				
				for i = 1, dy - 1 do
					screen.drawRectangle(
						codeView.codeAreaPosition, 
						y + codeView.selections[selectionIndex].from.line - codeView.fromLine,
						codeView.codeAreaWidth,
						1,
						codeView.selections[selectionIndex].color or colorScheme.selection,
						colorScheme.text,
						" "
					)

					y = y + 1
				end

				drawLowerSelection(y, selectionIndex)
			end
		end
	end

	-- Code strings
	y = codeView.y
	for i = codeView.fromLine, toLine do
		if codeView.lines[i] then
			if codeView.syntaxHighlight then
				GUI.highlightString(
					codeView.codeAreaPosition + 1,
					y,
					codeView.fromSymbol,
					codeView.indentationWidth,
					patterns,
					colorScheme,
					codeView.lines[i]
				)
			else
				screen.drawText(
					codeView.codeAreaPosition + 1,
					y,
					colorScheme.text,
					unicode.sub(
						codeView.lines[i],
						codeView.fromSymbol,
						codeView.fromSymbol + codeView.codeAreaWidth - 3
					)
				)
			end

			y = y + 1
		else
			break
		end
	end

	-- Scrollbars
	if #codeView.lines > codeView.height then
		codeView.verticalScrollBar.colors.background, codeView.verticalScrollBar.colors.foreground = colorScheme.scrollBarBackground, colorScheme.scrollBarForeground
		codeView.verticalScrollBar.minimumValue, codeView.verticalScrollBar.maximumValue, codeView.verticalScrollBar.value, codeView.verticalScrollBar.shownValueCount = 1, #codeView.lines, codeView.fromLine, codeView.height
		codeView.verticalScrollBar.localX = codeView.width
		codeView.verticalScrollBar.localY = 1
		codeView.verticalScrollBar.height = codeView.height - 1
		codeView.verticalScrollBar.hidden = false
	else
		codeView.verticalScrollBar.hidden = true
	end

	if codeView.maximumLineLength > codeView.codeAreaWidth - 2 then
		codeView.horizontalScrollBar.colors.background, codeView.horizontalScrollBar.colors.foreground = colorScheme.scrollBarBackground, colorScheme.scrollBarForeground
		codeView.horizontalScrollBar.minimumValue, codeView.horizontalScrollBar.maximumValue, codeView.horizontalScrollBar.value, codeView.horizontalScrollBar.shownValueCount = 1, codeView.maximumLineLength, codeView.fromSymbol, codeView.codeAreaWidth - 2
		codeView.horizontalScrollBar.localX = codeView.lineNumbersWidth + 1
		codeView.horizontalScrollBar.localY = codeView.height
		codeView.horizontalScrollBar.width = codeView.codeAreaWidth - 1
		codeView.horizontalScrollBar.hidden = false
	else
		codeView.horizontalScrollBar.hidden = true
	end

	codeView:overrideDraw()
end

function GUI.codeView(x, y, width, height, fromSymbol, fromLine, maximumLineLength, selections, highlights, syntaxPatterns, syntaxColorScheme, syntaxHighlight, lines)	
	local codeView = GUI.container(x, y, width, height)
	
	codeView.passScreenEvents = false
	codeView.lines = lines
	codeView.fromSymbol = fromSymbol
	codeView.fromLine = fromLine
	codeView.maximumLineLength = maximumLineLength
	codeView.selections = selections or {}
	codeView.highlights = highlights or {}
	codeView.syntaxHighlight = syntaxHighlight
	codeView.syntaxPatterns = syntaxPatterns
	codeView.syntaxColorScheme = syntaxColorScheme
	codeView.indentationWidth = 2

	codeView.verticalScrollBar = codeView:addChild(GUI.scrollBar(1, 1, 1, 1, 0x0, 0x0, 1, 1, 1, 1, 1, true))
	codeView.horizontalScrollBar = codeView:addChild(GUI.scrollBar(1, 1, 1, 1, 0x0, 0x0, 1, 1, 1, 1, 1, true))

	codeView.overrideDraw = codeView.draw
	codeView.draw = codeViewDraw

	return codeView
end 

--------------------------------------------------------------------------------

local function colorSelectorDraw(colorSelector)
	local overlayColor = colorSelector.color < 0x7FFFFF and 0xFFFFFF or 0x0
		
	screen.drawRectangle(
		colorSelector.x,
		colorSelector.y,
		colorSelector.width,
		colorSelector.height,
		colorSelector.pressed and color.blend(colorSelector.color, overlayColor, 0.8) or colorSelector.color,
		overlayColor,
		" "
	)
	
	if colorSelector.height > 1 and colorSelector.drawLine then
		screen.drawText(colorSelector.x, colorSelector.y + colorSelector.height - 1, overlayColor, string.rep("▄", colorSelector.width), 0.8)
	end
	
	screen.drawText(colorSelector.x + 1, colorSelector.y + math.floor(colorSelector.height / 2), overlayColor, text.limit(colorSelector.text, colorSelector.width - 2))
	
	return colorSelector
end

local function colorSelectorEventHandler(workspace, object, e1, ...)
	if e1 == "touch" then
		local eventData = {...}
		object.pressed = true

		local palette = workspace:addChild(GUI.palette(1, 1, object.color))
		palette.localX, palette.localY = math.floor(workspace.width / 2 - palette.width / 2), math.floor(workspace.height / 2 - palette.height / 2)

		palette.cancelButton.onTouch = function()
			object.pressed = false
			palette:remove()
			workspace:draw()

			if object.onColorSelected then
				object.onColorSelected(workspace, object, e1, table.unpack(eventData))
			end
		end

		palette.submitButton.onTouch = function()
			object.color = palette.color.integer
			palette.cancelButton.onTouch()
		end
		
		workspace:draw()
	end
end

function GUI.colorSelector(x, y, width, height, color, text)
	local colorSelector = GUI.object(x, y, width, height)
	
	colorSelector.drawLine = true
	colorSelector.eventHandler = colorSelectorEventHandler
	colorSelector.color = color
	colorSelector.text = text
	colorSelector.draw = colorSelectorDraw
	
	return colorSelector
end 

--------------------------------------------------------------------------------

local function getAxisValue(num, postfix, roundValues)
	if roundValues then
		return math.floor(num) .. postfix
	else
		local integer, fractional = math.modf(num)
		local firstPart, secondPart = "", ""
		if math.abs(integer) >= 1000 then
			return number.shorten(integer, 2) .. postfix
		else
			if math.abs(fractional) > 0 then
				return string.format("%.2f", num) .. postfix
			else
				return num .. postfix
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
			screen.drawText(chartX - unicode.len(yAxisValues[i].value) - 2, yAxisValues[i].y, object.colors.axisValue, yAxisValues[i].value)
		end
		screen.drawText(chartX, yAxisValues[i].y, object.colors.helpers, string.rep("─", chartWidth))
	end

	-- x axis values
	if object.showXAxisValues then
		value = xMin
		for x = chartX, chartX + chartWidth - 2, chartWidth * object.xAxisValueInterval do
			local stringValue = getAxisValue(value, object.xAxisPostfix, object.roundValues)
			screen.drawText(math.floor(x - unicode.len(stringValue) / 2), object.y + object.height - 1, object.colors.axisValue, stringValue)
			value = value + dx * object.xAxisValueInterval
		end
		local value = getAxisValue(xMax, object.xAxisPostfix, object.roundValues)
		screen.drawText(object.x + object.width - unicode.len(value), object.y + object.height - 1, object.colors.axisValue, value)
	end

	-- Axis lines
	for y = object.y, object.y + chartHeight - 1 do
		screen.drawText(chartX - 1, y, object.colors.axis, "┨")
	end
	screen.drawText(chartX - 1, object.y + chartHeight, object.colors.axis, "┗" .. string.rep("┯━", math.floor(chartWidth / 2)))

	local function fillVerticalPart(x1, y1, x2, y2)
		local dx, dy = x2 - x1, y2 - y1
		local absdx, absdy = math.abs(dx), math.abs(dy)
		if absdx >= absdy then
			local step, y = dy / absdx, y1
			for x = x1, x2, (x1 < x2 and 1 or -1) do
				local yFloor = math.floor(y)
				screen.drawSemiPixelRectangle(math.floor(x), yFloor, 1, math.floor(object.y + chartHeight) * 2 - yFloor - 1, object.colors.chart)
				y = y + step
			end
		else
			local step, x = dx / absdy, x1
			for y = y1, y2, (y1 < y2 and 1 or -1) do
				local yFloor = math.floor(y)
				screen.drawSemiPixelRectangle(math.floor(x), yFloor, 1, math.floor(object.y + chartHeight) * 2 - yFloor - 1, object.colors.chart)
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
			screen.drawSemiPixelLine(x, y, xNext, yNext, object.colors.chart)
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

--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------

local function sliderDraw(object)
	-- На всякий случай делаем значение не меньше минимального и не больше максимального
	object.value = math.min(math.max(object.value, object.minimumValue), object.maximumValue)
	
	if object.showMaximumAndMinimumValues then
		local stringMaximumValue, stringMinimumValue = tostring(object.roundValues and math.floor(object.maximumValue) or number.roundToDecimalPlaces(object.maximumValue, 2)), tostring(object.roundValues and math.floor(object.minimumValue) or number.roundToDecimalPlaces(object.minimumValue, 2))
		screen.drawText(object.x - unicode.len(stringMinimumValue) - 1, object.y, object.colors.value, stringMinimumValue)
		screen.drawText(object.x + object.width + 1, object.y, object.colors.value, stringMaximumValue)
	end

	if object.currentValuePrefix or object.currentValuePostfix then
		local stringCurrentValue = (object.currentValuePrefix or "") .. (object.roundValues and math.floor(object.value) or number.roundToDecimalPlaces(object.value, 2)) .. (object.currentValuePostfix or "")
		screen.drawText(math.floor(object.x + object.width / 2 - unicode.len(stringCurrentValue) / 2), object.y + 1, object.colors.value, stringCurrentValue)
	end

	local activeWidth = number.round((object.value - object.minimumValue) / (object.maximumValue - object.minimumValue) * object.width)
	screen.drawText(object.x, object.y, object.colors.passive, string.rep("━", object.width))
	screen.drawText(object.x, object.y, object.colors.active, string.rep("━", activeWidth))
	screen.drawText(activeWidth >= object.width and object.x + activeWidth - 1 or object.x + activeWidth, object.y, object.colors.pipe, "⬤")

	return object
end

local function sliderEventHandler(workspace, object, e1, e2, e3, e4, e5, ...)
	if e1 == "touch" or e1 == "drag" then
		local clickPosition = e3 - object.x

		if clickPosition == 0 then
			object.value = object.minimumValue
		elseif clickPosition == object.width - 1 then
			object.value = object.maximumValue
		else
			object.value = object.minimumValue + (clickPosition / object.width * (object.maximumValue - object.minimumValue))
		end

		workspace:draw()

		if object.onValueChanged then
			object.onValueChanged(workspace, object, e1, e2, e3, e4, e5, ...)
		end
	elseif e1 == "scroll" then
		object.value = object.value + (object.maximumValue - object.minimumValue) * object.scrollSensivity * e5

		if object.value > object.maximumValue then
			object.value = object.maximumValue 
		elseif object.value < object.minimumValue then
			object.value = object.minimumValue
		end

		workspace:draw()

		if object.onValueChanged then
			object.onValueChanged(workspace, object, e1, e2, e3, e4, e5, ...)
		end
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
	object.scrollSensivity = 0.05
	object.showMaximumAndMinimumValues = showMaximumAndMinimumValues
	object.currentValuePrefix = currentValuePrefix
	object.currentValuePostfix = currentValuePostfix
	object.roundValues = false
	
	return object
end

--------------------------------------------------------------------------------

local function switchDraw(switch)
	screen.drawText(switch.x - 1, switch.y, switch.colors.passive, "⠰")
	screen.drawRectangle(switch.x, switch.y, switch.width, 1, switch.colors.passive, 0x0, " ")
	screen.drawText(switch.x + switch.width, switch.y, switch.colors.passive, "⠆")

	screen.drawText(switch.x - 1, switch.y, switch.colors.active, "⠰")
	screen.drawRectangle(switch.x, switch.y, switch.pipePosition - 1, 1, switch.colors.active, 0x0, " ")

	screen.drawText(switch.x + switch.pipePosition - 2, switch.y, switch.colors.pipe, "⠰")
	screen.drawRectangle(switch.x + switch.pipePosition - 1, switch.y, 2, 1, switch.colors.pipe, 0x0, " ")
	screen.drawText(switch.x + switch.pipePosition + 1, switch.y, switch.colors.pipe, "⠆")
	
	return switch
end

local function switchSetState(switch, state)
	switch.state = state
	switch.pipePosition = switch.state and switch.width - 1 or 1

	return switch
end

local function switchEventHandler(workspace, switch, e1, ...)
	if e1 == "touch" then
		local eventData = {...}

		switch.state = not switch.state
		switch:addAnimation(
			function(animation)
				if switch.state then
					switch.pipePosition = number.round(1 + animation.position * (switch.width - 2))
				else	
					switch.pipePosition = number.round(1 + (1 - animation.position) * (switch.width - 2))
				end
			end,
			function(animation)
				animation:remove()
				if switch.onStateChanged then
					switch.onStateChanged(switch, e1, table.unpack(eventData))
				end
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
	switch.animated = true
	switch.animationDuration = GUI.SWITCH_ANIMATION_DURATION
	switch.setState = switchSetState

	switch:setState(state)
	
	return switch
end

--------------------------------------------------------------------------------

local function layoutCheckCell(layout, column, row)
	if column < 1 or column > #layout.columnSizes or row < 1 or row > #layout.rowSizes then
		error("Specified grid position (" .. tostring(column) .. "x" .. tostring(row) .. ") is out of layout grid range")
	end
end

local function layoutGetAbsoluteTotalSize(array)
	local absoluteTotalSize = 0
	for i = 1, #array do
		if array[i].sizePolicy == GUI.SIZE_POLICY_ABSOLUTE then
			absoluteTotalSize = absoluteTotalSize + array[i].size
		end
	end
	return absoluteTotalSize
end

local function layoutGetCalculatedSize(array, index, dependency)
	if array[index].sizePolicy == GUI.SIZE_POLICY_RELATIVE then
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
			layout.cells[row][column].childrenWidth, layout.cells[row][column].childrenHeight = 0, 0
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
				if cell.horizontalFitting then
					child.width = number.round(layout.columnSizes[layoutColumn].calculatedSize - cell.horizontalFittingRemove)
				end

				if cell.verticalFitting then
					child.height = number.round(layout.rowSizes[layoutRow].calculatedSize - cell.verticalFittingRemove)
				end

				-- Направление и расчет размеров
				if cell.direction == GUI.DIRECTION_HORIZONTAL then
					cell.childrenWidth = cell.childrenWidth + child.width + cell.spacing
					cell.childrenHeight = math.max(cell.childrenHeight, child.height)
				else
					cell.childrenWidth = math.max(cell.childrenWidth, child.width)
					cell.childrenHeight = cell.childrenHeight + child.height + cell.spacing
				end
			else
				error("Layout child with index " .. i .. " has been assigned to cell (" .. layoutColumn .. "x" .. layoutRow .. ") out of layout grid range")
			end
		end
	end

	-- Высчитываем стартовую позицию объектов ячейки
	local x, y = 1, 1
	for row = 1, #layout.rowSizes do
		for column = 1, #layout.columnSizes do
			cell = layout.cells[row][column]
			cell.x, cell.y = GUI.getAlignmentCoordinates(
				x,
				y,
				layout.columnSizes[column].calculatedSize,
				layout.rowSizes[row].calculatedSize,
				cell.horizontalAlignment,
				cell.verticalAlignment,
				cell.childrenWidth - (cell.direction == GUI.DIRECTION_HORIZONTAL and cell.spacing or 0),
				cell.childrenHeight - (cell.direction == GUI.DIRECTION_VERTICAL and cell.spacing or 0)
			)

			-- Учитываем отступы от краев ячейки
			if cell.horizontalMargin ~= 0 or cell.verticalMargin ~= 0 then
				cell.x, cell.y = GUI.getMarginCoordinates(
					cell.x,
					cell.y,
					cell.horizontalAlignment,
					cell.verticalAlignment,
					cell.horizontalMargin,
					cell.verticalMargin
				)
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
			
			child.localX, cell.localY = GUI.getAlignmentCoordinates(
				cell.x,
				cell.y,
				cell.childrenWidth,
				cell.childrenHeight,
				cell.horizontalAlignment,
				cell.verticalAlignment,
				child.width,
				child.height
			)

			if cell.direction == GUI.DIRECTION_HORIZONTAL then
				child.localX, child.localY = math.floor(cell.x), math.floor(cell.localY)
				cell.x = cell.x + child.width + cell.spacing
			else
				child.localX, child.localY = math.floor(child.localX), math.floor(cell.y)
				cell.y = cell.y + child.height + cell.spacing
			end
		end
	end
end

local function layoutSetPosition(layout, column, row, object)
	layoutCheckCell(layout, column, row)
	object.layoutRow = row
	object.layoutColumn = column

	return object
end

local function layoutSetDirection(layout, column, row, direction)
	layoutCheckCell(layout, column, row)
	layout.cells[row][column].direction = direction

	return layout
end

local function layoutSetSpacing(layout, column, row, spacing)
	layoutCheckCell(layout, column, row)
	layout.cells[row][column].spacing = spacing

	return layout
end

local function layoutSetAlignment(layout, column, row, horizontalAlignment, verticalAlignment)
	layoutCheckCell(layout, column, row)
	layout.cells[row][column].horizontalAlignment, layout.cells[row][column].verticalAlignment = horizontalAlignment, verticalAlignment

	return layout
end

local function layoutGetMargin(layout, column, row)
	layoutCheckCell(layout, column, row)

	return layout.cells[row][column].horizontalMargin, layout.cells[row][column].verticalMargin
end

local function layoutSetMargin(layout, column, row, horizontalMargin, verticalMargin)
	layoutCheckCell(layout, column, row)
	layout.cells[row][column].horizontalMargin = horizontalMargin
	layout.cells[row][column].verticalMargin = verticalMargin

	return layout
end

local function layoutNewCell()
	return {
		horizontalAlignment = GUI.ALIGNMENT_HORIZONTAL_CENTER,
		verticalAlignment = GUI.ALIGNMENT_VERTICAL_CENTER,
		horizontalMargin = 0,
		verticalMargin = 0,
		direction = GUI.DIRECTION_VERTICAL,
		spacing = 1
	}
end

local function layoutCalculatePercentageSize(changingExistent, array, index)
	if array[index].sizePolicy == GUI.SIZE_POLICY_RELATIVE then
		local allPercents, beforeFromIndexPercents = 0, 0
		for i = 1, #array do
			if array[i].sizePolicy == GUI.SIZE_POLICY_RELATIVE then
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
			if array[i].sizePolicy == GUI.SIZE_POLICY_RELATIVE and i ~= index then
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
		layoutAddRow(layout, GUI.SIZE_POLICY_RELATIVE, 1 / i)
	end

	for i = 1, columnCount do
		layoutAddColumn(layout, GUI.SIZE_POLICY_RELATIVE, 1 / i)
	end

	return layout
end

local function layoutDraw(layout)
	layout:update()
	containerDraw(layout)
	
	if layout.showGrid then
		local x, y = layout.x, layout.y
		for j = 1, #layout.columnSizes do
			for i = 1, #layout.rowSizes do
				screen.drawFrame(
					number.round(x),
					number.round(y),
					number.round(layout.columnSizes[j].calculatedSize),
					number.round(layout.rowSizes[i].calculatedSize),
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
			if layout.cells[row][column].direction == GUI.DIRECTION_HORIZONTAL then
				layout.width = layout.width + layout.children[i].width + layout.cells[row][column].spacing
				layout.height = math.max(layout.height, layout.children[i].height)
			else
				layout.width = math.max(layout.width, layout.children[i].width)
				layout.height = layout.height + layout.children[i].height + layout.cells[row][column].spacing
			end
		end
	end

	if layout.cells[row][column].direction == GUI.DIRECTION_HORIZONTAL then
		layout.width = layout.width - layout.cells[row][column].spacing
	else
		layout.height = layout.height - layout.cells[row][column].spacing
	end

	return layout
end

local function layoutSetFitting(layout, column, row, horizontal, vertical, horizontalRemove, verticalRemove)
	layoutCheckCell(layout, column, row)
	layout.cells[row][column].horizontalFitting = horizontal
	layout.cells[row][column].verticalFitting = vertical
	layout.cells[row][column].horizontalFittingRemove = horizontalRemove or 0
	layout.cells[row][column].verticalFittingRemove = verticalRemove or 0

	return layout
end

local function layoutAddChild(layout, object, ...)
	object.layoutRow = layout.defaultRow
	object.layoutColumn = layout.defaultColumn
	containerAddChild(layout, object, ...)

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

	layout.setPosition = layoutSetPosition
	layout.setDirection = layoutSetDirection
	layout.setGridSize = layoutSetGridSize
	layout.setSpacing = layoutSetSpacing
	layout.setAlignment = layoutSetAlignment
	layout.setMargin = layoutSetMargin
	layout.getMargin = layoutGetMargin
	
	layout.fitToChildrenSize = layoutFitToChildrenSize
	layout.setFitting = layoutSetFitting

	layout.update = layoutUpdate
	layout.addChild = layoutAddChild
	layout.draw = layoutDraw

	layout:setGridSize(columnCount, rowCount)

	return layout
end

--------------------------------------------------------------------------------

local function filesystemDialogDraw(filesystemDialog)
	if filesystemDialog.extensionComboBox.hidden then
		filesystemDialog.input.width = filesystemDialog.cancelButton.localX - 4
	else
		filesystemDialog.input.width = filesystemDialog.extensionComboBox.localX - 3
	end

	if filesystemDialog.IOMode == GUI.IO_MODE_SAVE then
		filesystemDialog.submitButton.disabled = not filesystemDialog.input.text or filesystemDialog.input.text == ""
	else
		filesystemDialog.input.text = filesystemDialog.filesystemTree.selectedItem or ""
		filesystemDialog.submitButton.disabled = not filesystemDialog.filesystemTree.selectedItem
	end
	
	containerDraw(filesystemDialog)
	GUI.drawShadow(filesystemDialog.x, filesystemDialog.y, filesystemDialog.width, filesystemDialog.height, GUI.CONTEXT_MENU_SHADOW_TRANSPARENCY, true)

	return filesystemDialog
end

local function filesystemDialogSetMode(filesystemDialog, IOMode, filesystemMode)
	filesystemDialog.IOMode = IOMode
	filesystemDialog.filesystemMode = filesystemMode

	if filesystemDialog.IOMode == GUI.IO_MODE_SAVE then
		filesystemDialog.filesystemTree.showMode = GUI.IO_MODE_DIRECTORY
		filesystemDialog.filesystemTree.selectionMode = GUI.IO_MODE_DIRECTORY
		filesystemDialog.input.disabled = false
		filesystemDialog.extensionComboBox.hidden = filesystemDialog.filesystemMode ~= GUI.IO_MODE_FILE or not filesystemDialog.filesystemTree.extensionFilters
	else
		if filesystemDialog.filesystemMode == GUI.IO_MODE_FILE then
			filesystemDialog.filesystemTree.showMode = GUI.IO_MODE_BOTH
			filesystemDialog.filesystemTree.selectionMode = GUI.IO_MODE_FILE
		else
			filesystemDialog.filesystemTree.showMode = GUI.IO_MODE_DIRECTORY
			filesystemDialog.filesystemTree.selectionMode = GUI.IO_MODE_DIRECTORY
		end

		filesystemDialog.input.disabled = true
		filesystemDialog.extensionComboBox.hidden = true
	end
end

local function filesystemDialogAddExtensionFilter(filesystemDialog, extension)
	filesystemDialog.extensionComboBox:addItem(extension)
	filesystemDialog.extensionComboBox.width = math.max(filesystemDialog.extensionComboBox.width, unicode.len(extension) + 3)
	filesystemDialog.extensionComboBox.localX = filesystemDialog.cancelButton.localX - filesystemDialog.extensionComboBox.width - 2
	filesystemDialog.filesystemTree:addExtensionFilter(extension)

	filesystemDialog:setMode(filesystemDialog.IOMode, filesystemDialog.filesystemMode)
end

local function filesystemDialogExpandPath(filesystemDialog, ...)
	filesystemDialog.filesystemTree:expandPath(...)
end

function GUI.filesystemDialog(x, y, width, height, submitButtonText, cancelButtonText, placeholderText, path)
	local filesystemDialog = GUI.container(x, y, width, height)
	
	filesystemDialog:addChild(GUI.panel(1, height - 2, width, 3, 0xD2D2D2))
	
	filesystemDialog.cancelButton = filesystemDialog:addChild(GUI.adaptiveRoundedButton(1, height - 1, 1, 0, 0xE1E1E1, 0x3C3C3C, 0x3C3C3C, 0xE1E1E1, cancelButtonText))
	filesystemDialog.submitButton = filesystemDialog:addChild(GUI.adaptiveRoundedButton(1, height - 1, 1, 0, 0x3C3C3C, 0xE1E1E1, 0xE1E1E1, 0x3C3C3C, submitButtonText))
	filesystemDialog.submitButton.localX = filesystemDialog.width - filesystemDialog.submitButton.width - 1
	filesystemDialog.cancelButton.localX = filesystemDialog.submitButton.localX - filesystemDialog.cancelButton.width - 2

	filesystemDialog.extensionComboBox = filesystemDialog:addChild(GUI.comboBox(1, height - 1, 1, 1, 0xE1E1E1, 0x696969, 0xC3C3C3, 0x878787))
	filesystemDialog.extensionComboBox.hidden = true

	filesystemDialog.input = filesystemDialog:addChild(GUI.input(2, height - 1, 1, 1, 0xE1E1E1, 0x696969, 0x969696, 0xE1E1E1, 0x3C3C3C, "", placeholderText))

	filesystemDialog.filesystemTree = filesystemDialog:addChild(GUI.filesystemTree(1, 1, width, height - 3, 0xE1E1E1, 0x3C3C3C, 0x3C3C3C, 0xA5A5A5, 0x3C3C3C, 0xE1E1E1, 0xB4B4B4, 0xA5A5A5, 0xC3C3C3, 0x4B4B4B))
	filesystemDialog.filesystemTree.workPath = path
	filesystemDialog.animationDuration = GUI.FILESYSTEM_DIALOG_ANIMATION_DURATION

	filesystemDialog.draw = filesystemDialogDraw
	filesystemDialog.setMode = filesystemDialogSetMode
	filesystemDialog.addExtensionFilter = filesystemDialogAddExtensionFilter

	filesystemDialog.expandPath = filesystemDialogExpandPath
	filesystemDialog:setMode(GUI.IO_MODE_OPEN, GUI.IO_MODE_FILE)

	return filesystemDialog
end

local function filesystemDialogShow(filesystemDialog)
	filesystemDialog.filesystemTree:updateFileList()
	filesystemDialog:addAnimation(
		function(animation)
			filesystemDialog.localY = math.floor(1 + (1.0 - animation.position) * (-filesystemDialog.height))
		end,
		function(animation)
			animation:remove()
		end
	):start(filesystemDialog.animationDuration)

	return filesystemDialog
end

--------------------------------------------------------------------------------

function GUI.addFilesystemDialog(parentContainer, addPanel, ...)
	local container = GUI.addBackgroundContainer(parentContainer, addPanel, false, nil)

	local filesystemDialog = container:addChild(GUI.filesystemDialog(1, 1, ...))
	filesystemDialog.localX = math.floor(container.width / 2 - filesystemDialog.width / 2)
	filesystemDialog.localY = -filesystemDialog.height

	local function onAnyTouch()
		container:remove()
		filesystemDialog.firstParent:draw()
	end

	filesystemDialog.cancelButton.onTouch = function()
		onAnyTouch()

		if filesystemDialog.onCancel then
			filesystemDialog.onCancel()
		end
	end

	filesystemDialog.submitButton.onTouch = function()
		onAnyTouch()
		
		local path = filesystemDialog.filesystemTree.selectedItem or filesystemDialog.filesystemTree.workPath or "/"
		if filesystemDialog.IOMode == GUI.IO_MODE_SAVE then
			path = path .. filesystemDialog.input.text
			
			if filesystemDialog.filesystemMode == GUI.IO_MODE_FILE then
				local selectedItem = filesystemDialog.extensionComboBox:getItem(filesystemDialog.extensionComboBox.selectedItem)
				path = path .. (selectedItem and selectedItem.text or "")
			else
				path = path .. "/"
			end
		end

		if filesystemDialog.onSubmit then
			filesystemDialog.onSubmit(path)
		end
	end

	filesystemDialog.show = filesystemDialogShow

	return filesystemDialog
end

--------------------------------------------------------------------------------

local function filesystemChooserDraw(object)
	local tipWidth = object.height * 2 - 1
	local y = math.floor(object.y + object.height / 2)
	
	screen.drawRectangle(object.x, object.y, object.width - tipWidth, object.height, object.colors.background, object.colors.text, " ")
	screen.drawRectangle(object.x + object.width - tipWidth, object.y, tipWidth, object.height, object.pressed and object.colors.tipText or object.colors.tipBackground, object.pressed and object.colors.tipBackground or object.colors.tipText, " ")
	screen.drawText(object.x + object.width - math.floor(tipWidth / 2) - 1, y, object.pressed and object.colors.tipBackground or object.colors.tipText, "…")
	screen.drawText(object.x + 1, y, object.colors.text, text.limit(object.path or object.placeholderText, object.width - tipWidth - 2, "left"))

	return object
end

local function filesystemChooserAddExtensionFilter(object, extension)
	object.extensionFilters[unicode.lower(extension)] = true
end

local function filesystemChooserSetMode(object, IOMode, filesystemMode)
	object.IOMode = IOMode
	object.filesystemMode = filesystemMode
end

local function filesystemChooserEventHandler(workspace, object, e1)
	if e1 == "touch" then
		object.pressed = true
		workspace:draw()

		local filesystemDialog = GUI.addFilesystemDialog(workspace, false, 50, math.floor(workspace.height * 0.8), object.submitButtonText, object.cancelButtonText, object.placeholderText, object.filesystemDialogPath)

		for key in pairs(object.extensionFilters) do
			filesystemDialog:addExtensionFilter(key)
		end

		filesystemDialog:setMode(object.IOMode, object.filesystemMode)

		if object.path and #object.path > 0 then
			-- local path = object.path:gsub("/+", "/")
			filesystemDialog.filesystemTree.selectedItem = object.IOMode == GUI.IO_MODE_OPEN and object.path or filesystem.path(object.path)
			filesystemDialog.input.text = filesystem.name(object.path)
			filesystemDialog:expandPath(object.IOMode == GUI.IO_MODE_OPEN and filesystem.path(object.path) or filesystem.path(filesystem.path(object.path)))
		end
		
		filesystemDialog.onCancel = function()
			object.pressed = false
			workspace:draw()
		end

		filesystemDialog.onSubmit = function(path)
			object.path = path
			filesystemDialog.onCancel()
			if object.onSubmit then
				object.onSubmit(object.path)
			end
		end

		filesystemDialog:show()
	end
end

function GUI.filesystemChooser(x, y, width, height, backgroundColor, textColor, tipBackgroundColor, tipTextColor, path, submitButtonText, cancelButtonText, placeholderText, filesystemDialogPath)
	local object = GUI.object(x, y, width, height)
	
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
	object.filesystemMode = GUI.IO_MODE_FILE
	object.IOMode = GUI.IO_MODE_OPEN
	object.extensionFilters = {}

	object.draw = filesystemChooserDraw
	object.eventHandler = filesystemChooserEventHandler
	object.addExtensionFilter = filesystemChooserAddExtensionFilter
	object.setMode = filesystemChooserSetMode

	return object
end

--------------------------------------------------------------------------------

local function resizerDraw(object)
	local horizontalMode, x, y, symbol = object.width >= object.height

	if horizontalMode then
		screen.drawText(object.x, math.floor(object.y + object.height / 2), object.colors.helper, string.rep("━", object.width))
		
		if object.lastTouchX then
			screen.drawText(object.lastTouchX, object.lastTouchY, object.colors.arrow, "↑")
		end
	else
		local x = math.floor(object.x + object.width / 2)
		local bufferWidth, bufferHeight, index = screen.getResolution()
		
		for i = object.y, object.y + object.height - 1 do
			if x >= 1 and x <= bufferWidth and i >= 1 and i <= bufferHeight then
				index = screen.getIndex(x, i)
				screen.rawSet(index, screen.rawGet(index), object.colors.helper, "┃")
			end
		end

		if object.lastTouchX then
			screen.drawText(object.lastTouchX - 1, object.lastTouchY, object.colors.arrow, "←→")
		end
	end
end

local function resizerEventHandler(workspace, object, e1, e2, e3, e4)
	if e1 == "touch" then
		object.lastTouchX, object.lastTouchY = e3, e4
		workspace:draw()
	elseif e1 == "drag" and object.lastTouchX then		
		if object.onResize then
			object.onResize(e3 - object.lastTouchX, e4 - object.lastTouchY)
		end
		
		object.lastTouchX, object.lastTouchY = e3, e4
		workspace:draw()
	elseif e1 == "drop" then
		if object.onResizeFinished then
			object.onResizeFinished()
		end

		object.lastTouchX, object.lastTouchY = nil, nil
		workspace:draw()
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

--------------------------------------------------------------------------------

local function scrollBarDraw(scrollBar)
	local isVertical = scrollBar.height > scrollBar.width
	local valuesDelta = scrollBar.maximumValue - scrollBar.minimumValue
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
				background = screen.get(scrollBar.x, y)
				screen.set(scrollBar.x, y, background, y >= y1 and y <= y2 and scrollBar.colors.foreground or scrollBar.colors.background, "┃")
			end
		else
			screen.drawRectangle(scrollBar.x, scrollBar.y, scrollBar.width, scrollBar.height, scrollBar.colors.background, scrollBar.colors.foreground, " ")
			screen.drawRectangle(
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
				background = screen.get(x, scrollBar.y)
				screen.set(x, scrollBar.y, background, x >= x1 and x <= x2 and scrollBar.colors.foreground or scrollBar.colors.background, "⠤")
			end
		else
			screen.drawRectangle(scrollBar.x, scrollBar.y, scrollBar.width, scrollBar.height, scrollBar.colors.background, scrollBar.colors.foreground, " ")
			screen.drawRectangle(
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

local function scrollBarEventHandler(workspace, object, e1, e2, e3, e4, e5, ...)
	local newValue = object.value

	if e1 == "touch" or e1 == "drag" then
		if object.height > object.width then
			if e4 == object.y + object.height - 1 then
				newValue = object.maximumValue
			else
				newValue = object.minimumValue + (e4 - object.y) / object.height * (object.maximumValue - object.minimumValue)
			end
		else
			if e3 == object.x + object.width - 1 then
				newValue = object.maximumValue
			else
				newValue = object.minimumValue + (e3 - object.x) / object.width * (object.maximumValue - object.minimumValue)
			end
		end
	elseif e1 == "scroll" then
		if e5 == 1 then
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

	if e1 == "touch" or e1 == "drag" or e1 == "scroll" then
		object.value = newValue
		if object.onTouch then
			object.onTouch(workspace, object, e1, e2, e3, e4, e5, ...)
		end

		workspace:draw()
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

--------------------------------------------------------------------------------

local function treeDraw(tree)	
	local y, yEnd, showScrollBar = tree.y, tree.y + tree.height - 1, #tree.items > tree.height
	local textLimit = tree.width - (showScrollBar and 1 or 0)

	if tree.colors.default.background then
		screen.drawRectangle(tree.x, tree.y, tree.width, tree.height, tree.colors.default.background, tree.colors.default.expandable, " ")
	end

	for i = tree.fromItem, #tree.items do
		local textColor, arrowColor, text = tree.colors.default.notExpandable, tree.colors.default.arrow, tree.items[i].expandable and "■ " or "□ "

		if tree.selectedItem == tree.items[i].definition then
			textColor, arrowColor = tree.colors.selected.any, tree.colors.selected.arrow
			screen.drawRectangle(tree.x, y, tree.width, 1, tree.colors.selected.background, textColor, " ")
		else
			if tree.items[i].expandable then
				textColor = tree.colors.default.expandable
			elseif tree.items[i].disabled then
				textColor = tree.colors.disabled
			end
		end

		if tree.items[i].expandable then
			screen.drawText(tree.x + tree.items[i].offset, y, arrowColor, tree.expandedItems[tree.items[i].definition] and "▽" or "▷")
		end

		screen.drawText(tree.x + tree.items[i].offset + 2, y, textColor, unicode.sub(text .. tree.items[i].name, 1, textLimit - tree.items[i].offset - 2))

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

local function treeEventHandler(workspace, tree, e1, e2, e3, e4, e5, ...)
	if e1 == "touch" then
		local i = e4 - tree.y + tree.fromItem
		if tree.items[i] then
			if
				tree.items[i].expandable and
				(
					tree.selectionMode == GUI.IO_MODE_FILE or
					e3 >= tree.x + tree.items[i].offset - 1 and e3 <= tree.x + tree.items[i].offset + 1
				)
			then
				if tree.expandedItems[tree.items[i].definition] then
					tree.expandedItems[tree.items[i].definition] = nil
				else
					tree.expandedItems[tree.items[i].definition] = true
				end

				if tree.onItemExpanded then
					tree.onItemExpanded(tree.selectedItem, e1, e2, e3, e4, e5, ...)
				end
			else
				if
					(
						tree.selectionMode == GUI.IO_MODE_BOTH or
						tree.selectionMode == GUI.IO_MODE_DIRECTORY and tree.items[i].expandable or
						tree.selectionMode == GUI.IO_MODE_FILE
					) and not tree.items[i].disabled
				then
					tree.selectedItem = tree.items[i].definition

					if tree.onItemSelected then
						tree.onItemSelected(tree.selectedItem, e1, e2, e3, e4, e5, ...)
					end
				end
			end

			workspace:draw()
		end
	elseif e1 == "scroll" then
		if e5 == 1 then
			if tree.fromItem > 1 then
				tree.fromItem = tree.fromItem - 1
				workspace:draw()
			end
		else
			if tree.fromItem < #tree.items then
				tree.fromItem = tree.fromItem + 1
				workspace:draw()
			end
		end
	end
end

local function treeAddItem(tree, name, definition, offset, expandable, disabled)
	local item = {
		name = name, 
		expandable = expandable,
		offset = offset or 0,
		definition = definition,
		disabled = disabled
	}
	table.insert(tree.items, item)

	return item
end

function GUI.tree(x, y, width, height, backgroundColor, expandableColor, notExpandableColor, arrowColor, backgroundSelectedColor, anySelectionColor, arrowSelectionColor, disabledColor, scrollBarBackground, scrollBarForeground, showMode, selectionMode)
	local tree = GUI.object(x, y, width, height)
	
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

--------------------------------------------------------------------------------

local function filesystemTreeUpdateFileListRecursively(tree, path, offset)
	local list = filesystem.list(path)

	local i, expandables = 1, {}
	while i <= #list do
		if filesystem.isDirectory(path .. list[i]) then
			table.insert(expandables, list[i])
			table.remove(list, i)
		else
			i = i + 1
		end
	end

	table.sort(expandables, function(a, b) return unicode.lower(a) < unicode.lower(b) end)
	table.sort(list, function(a, b) return unicode.lower(a) < unicode.lower(b) end)

	if tree.showMode == GUI.IO_MODE_BOTH or tree.showMode == GUI.IO_MODE_DIRECTORY then
		for i = 1, #expandables do
			tree:addItem(filesystem.name(expandables[i]):sub(1, -2), path .. expandables[i], offset, true)

			if tree.expandedItems[path .. expandables[i]] then
				filesystemTreeUpdateFileListRecursively(tree, path .. expandables[i], offset + 2)
			end
		end
	end

	if tree.showMode == GUI.IO_MODE_BOTH or tree.showMode == GUI.IO_MODE_FILE then
		for i = 1, #list do
			tree:addItem(list[i], path .. list[i], offset, false, tree.extensionFilters and not tree.extensionFilters[filesystem.extension(path .. list[i], true)] or false)
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

local function filesystemTreeExpandPath(tree, path)
	local blyadina = tree.workPath
	for pizda in path:gmatch("[^/]+") do
		blyadina = blyadina .. pizda .. "/"
		tree.expandedItems[blyadina] = true
	end
end

function GUI.filesystemTree(...)
	local tree = GUI.tree(...)

	tree.workPath = "/"
	tree.updateFileList = filesystemTreeUpdateFileList
	tree.addExtensionFilter = filesystemTreeAddExtensionFilter
	tree.expandPath = filesystemTreeExpandPath
	tree.onItemExpanded = function()
		tree:updateFileList()
	end

	return tree
end

--------------------------------------------------------------------------------

local function textBoxUpdate(object)
	local doubleVerticalOffset = object.offset.vertical * 2
	object.textWidth = object.width - object.offset.horizontal * 2 - (object.scrollBarEnabled and 1 or 0)

	object.linesCopy = {}

	if object.autoWrap then
		for i = 1, #object.lines do
			local isTable = type(object.lines[i]) == "table"
			for subLine in (isTable and object.lines[i].text or object.lines[i]):gmatch("[^\n]+") do
				local wrappedLine = text.wrap(subLine, object.textWidth)
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
	object:update()

	if object.colors.background then
		screen.drawRectangle(object.x, object.y, object.width, object.height, object.colors.background, object.colors.text, " ", object.colors.transparency)
	end

	local x, y = nil, object.y + object.offset.vertical
	local lineType, line, textColor
	for i = object.currentLine, object.currentLine + object.textHeight - 1 do
		if object.linesCopy[i] then
			lineType = type(object.linesCopy[i])
			if lineType == "string" then
				line, textColor = text.limit(object.linesCopy[i], object.textWidth), object.colors.text
			elseif lineType == "table" then
				line, textColor = text.limit(object.linesCopy[i].text, object.textWidth), object.linesCopy[i].color
			else
				error("Unknown TextBox line type: " .. tostring(lineType))
			end

			x = GUI.getAlignmentCoordinates(
				object.x + object.offset.horizontal,
				1,
				object.textWidth,
				1,
				object.horizontalAlignment,
				object.verticalAlignment,
				unicode.len(line),
				1
			)

			screen.drawText(math.floor(x), y, textColor, line)
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

local function textBoxScrollEventHandler(workspace, object, e1, e2, e3, e4, e5)
	if e1 == "scroll" then
		if e5 == 1 then
			object:scrollUp()
		else
			object:scrollDown()
		end

		workspace:draw()
	end
end

function GUI.textBox(x, y, width, height, backgroundColor, textColor, lines, currentLine, horizontalOffset, verticalOffset, autoWrap, autoHeight)
	local object = GUI.object(x, y, width, height)
	
	object.colors = {
		text = textColor,
		background = backgroundColor
	}
	object.lines = lines
	object.currentLine = currentLine or 1
	object.scrollUp = scrollUpTextBox
	object.scrollDown = scrollDownTextBox
	object.scrollToStart = scrollToStartTextBox
	object.scrollToEnd = scrollToEndTextBox
	object.offset = {horizontal = horizontalOffset or 0, vertical = verticalOffset or 0}
	object.autoWrap = autoWrap
	object.autoHeight = autoHeight
	object.scrollBar = GUI.scrollBar(1, 1, 1, 1, 0xC3C3C3, 0x4B4B4B, 1, 1, 1, 1, 1, true)
	object.scrollBarEnabled = false
	
	object.eventHandler = textBoxScrollEventHandler
	object.draw = textBoxDraw
	object.update = textBoxUpdate

	object.setAlignment = GUI.setAlignment
	object:setAlignment(GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_TOP)
	object:update()

	return object
end

--------------------------------------------------------------------------------

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
	screen.drawText(x, y, color, text)
end

local function inputDraw(input)
	local background, foreground, transparency, text
	if input.focused then
		background, transparency = input.colors.focused.background, input.colors.focused.transparency
		if input.text == "" then
			input.textCutFrom = 1
			foreground, text = input.colors.placeholderText, input.text
		else
			foreground = input.colors.focused.text
			if input.textMask then
				text = string.rep(input.textMask, unicode.len(input.text))
			else
				text = input.text
			end
		end
	else
		background, transparency = input.colors.default.background, input.colors.default.transparency
		if input.text == "" then
			input.textCutFrom = 1
			foreground, text = input.colors.placeholderText, input.placeholderText
		else
			foreground = input.colors.default.text
			if input.textMask then
				text = string.rep(input.textMask, unicode.len(input.text))
			else
				text = input.text
			end
		end
	end

	if background then
		screen.drawRectangle(input.x, input.y, input.width, input.height, background, foreground, " ", transparency)
	end

	local y = input.y + math.floor(input.height / 2)

	input.textDrawMethod(
		input.x + input.textOffset,
		y,
		foreground,
		unicode.sub(
			text or "",
			input.textCutFrom,
			input.textCutFrom + input.width - 1 - input.textOffset * 2
		)
	)

	if input.cursorBlinkState then
		local index = screen.getIndex(input.x + input.cursorPosition - input.textCutFrom + input.textOffset, y)
		local background = screen.rawGet(index)
		screen.rawSet(index, background, input.colors.cursor, input.cursorSymbol)
	end
end

local function inputCursorBlink(workspace, input, state)
	input.cursorBlinkState = state
	input.cursorBlinkUptime = computer.uptime()
	workspace:draw()
end

local function inputStopInput(workspace, input)
	input.stopInputObject:remove()
	input.focused = false

	if input.validator then
		if not input.validator(input.text) then
			input.text = input.startText
			input.startText = nil

			input:setCursorPosition(unicode.len(input.text) + 1)
		end
	end
	
	if input.onInputFinished then
		input.onInputFinished(workspace, input)
	end

	inputCursorBlink(workspace, input, false)
end

local function inputStartInput(input)
	input.startText = input.text
	input.focused = true

	if input.historyEnabled then
		input.historyIndex = input.historyIndex + 1
	end

	if input.eraseTextOnFocus then
		input.text = ""
	end
	
	input:setCursorPosition(input.cursorPosition)

	input.stopInputObject.width, input.stopInputObject.height = input.firstParent.width, input.firstParent.height
	input.firstParent:addChild(input.stopInputObject)

	inputCursorBlink(input.firstParent, input, true)
end

local function inputEventHandler(workspace, input, e1, e2, e3, e4, e5, e6, ...)
	if e1 == "touch" or e1 == "drag" then
		input:setCursorPosition(input.textCutFrom + e3 - input.x - input.textOffset)

		if input.focused then
			inputCursorBlink(workspace, input, true)
		else
			input:startInput()
		end
	elseif e1 == "key_down" and input.focused then
		workspace:consumeEvent()

		-- Return
		if e4 == 28 then
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

			inputStopInput(workspace, input)

			if input.onKeyDown then
				input.onKeyDown(workspace, input, e1, e2, e3, e4, e5, e6, ...)
			end

			return
		-- Arrows up/down/left/right
		elseif e4 == 200 then
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
			end
		elseif e4 == 208 then
			if input.historyEnabled and #input.history > 0 then
				input.historyIndex = input.historyIndex + 1
				if input.historyIndex > #input.history then
					input.historyIndex = #input.history
				elseif input.historyIndex < 1 then
					input.historyIndex = 1
				end
				
				input.text = input.history[input.historyIndex]
				input:setCursorPosition(unicode.len(input.text) + 1)
			end
		elseif e4 == 203 then
			input:setCursorPosition(input.cursorPosition - 1)
		elseif e4 == 205 then	
			input:setCursorPosition(input.cursorPosition + 1)
		-- Backspace
		elseif e4 == 14 then
			input.text = unicode.sub(unicode.sub(input.text, 1, input.cursorPosition - 1), 1, -2) .. unicode.sub(input.text, input.cursorPosition, -1)
			input:setCursorPosition(input.cursorPosition - 1)
		-- Delete
		elseif e4 == 211 then
			input.text = unicode.sub(input.text, 1, input.cursorPosition - 1) .. unicode.sub(input.text, input.cursorPosition + 1, -1)
		-- Home
		elseif e4 == 199 then
			input:setCursorPosition(1)
		-- End
		elseif e4 == 207 then 
			input:setCursorPosition(unicode.len(input.text) + 1)
		else
			local char = unicode.char(e3)
			if not keyboard.isControl(e3) then
				input.text = unicode.sub(input.text, 1, input.cursorPosition - 1) .. char .. unicode.sub(input.text, input.cursorPosition, -1)
				input:setCursorPosition(input.cursorPosition + 1)
			end
		end

		if input.onKeyDown then
			input.onKeyDown(workspace, input, e1, e2, e3, e4, e5, e6, ...)
		end

		inputCursorBlink(workspace, input, true)
	elseif e1 == "clipboard" and input.focused then
		input.text = unicode.sub(input.text, 1, input.cursorPosition - 1) .. e3 .. unicode.sub(input.text, input.cursorPosition, -1)
		input:setCursorPosition(input.cursorPosition + unicode.len(e3))
		
		inputCursorBlink(workspace, input, true)
		workspace:consumeEvent()
	elseif not e1 and input.focused and computer.uptime() - input.cursorBlinkUptime > input.cursorBlinkDelay then
		inputCursorBlink(workspace, input, not input.cursorBlinkState)
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

	input.stopInputObject = GUI.object(1, 1, 1, 1)
	input.stopInputObject.eventHandler = function(workspace, object, e1, e2, e3, e4, ...)
		if e1 == "touch" or e1 == "drop" then
			if input:isPointInside(e3, e4) then
				input.eventHandler(workspace, input, e1, e2, e3, e4, ...)
			else
				inputStopInput(workspace, input)
			end
		end
	end

	input.textDrawMethod = inputTextDrawMethod
	input.draw = inputDraw
	input.eventHandler = inputEventHandler
	input.startInput = inputStartInput

	return input
end

--------------------------------------------------------------------------------

local function autoCompleteDraw(object)
	local y, yEnd = object.y, object.y + object.height - 1

	screen.drawRectangle(object.x, object.y, object.width, object.height, object.colors.default.background, object.colors.default.text, " ")

	for i = object.fromItem, object.itemCount do
		local textColor, textMatchColor = object.colors.default.text, object.colors.default.textMatch
		if i == object.selectedItem then
			screen.drawRectangle(object.x, y, object.width, 1, object.colors.selected.background, object.colors.selected.text, " ")
			textColor, textMatchColor = object.colors.selected.text, object.colors.selected.textMatch
		end

		screen.drawText(object.x + 1, y, textMatchColor, unicode.sub(object.matchText, 1, object.width - 2))
		screen.drawText(object.x + object.matchTextLength + 1, y, textColor, unicode.sub(object.items[i], object.matchTextLength + 1, object.matchTextLength + object.width - object.matchTextLength - 2))

		y = y + 1
		if y > yEnd then
			break
		end
	end

	if object.itemCount > object.height then
		object.scrollBar.x = object.x + object.width - 1
		object.scrollBar.y = object.y
		object.scrollBar.height = object.height
		object.scrollBar.maximumValue = object.itemCount - object.height + 2
		object.scrollBar.value = object.fromItem
		object.scrollBar.shownValueCount = object.height

		object.scrollBar:draw()
	end
end

local function autoCompleteScroll(workspace, object, direction)
	if object.itemCount >= object.height then
		object.fromItem = object.fromItem + direction
		if object.fromItem < 1 then
			object.fromItem = 1
		elseif object.fromItem > object.itemCount - object.height + 1 then
			object.fromItem = object.itemCount - object.height + 1
		end
	end
end

local function autoCompleteEventHandler(workspace, object, e1, e2, e3, e4, e5, ...)
	if e1 == "touch" then
		object.selectedItem = e4 - object.y + object.fromItem
		workspace:draw()

		if object.onItemSelected then
			event.sleep(0.2)
			object.onItemSelected(workspace, object, e1, e2, e3, e4, e5, ...)
		end
	elseif e1 == "scroll" then
		autoCompleteScroll(workspace, object, -e5)
		workspace:draw()
	elseif e1 == "key_down" then
		if e4 == 28 then
			if object.onItemSelected then
				object.onItemSelected(workspace, object, e1, e2, e3, e4, e5, ...)
			end
		elseif e4 == 200 then
			object.selectedItem = object.selectedItem - 1
			if object.selectedItem < 1 then
				object.selectedItem = 1
			end

			if object.selectedItem == object.fromItem - 1 then
				autoCompleteScroll(workspace, object, -1)
			end

			workspace:draw()
		elseif e4 == 208 then
			object.selectedItem = object.selectedItem + 1
			if object.selectedItem > object.itemCount then
				object.selectedItem = object.itemCount
			end

			if object.selectedItem == object.fromItem + object.height then
				autoCompleteScroll(workspace, object, 1)
			end
			
			workspace:draw()
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

local function autoCompleteMatch(object, variants, text, asKey)
	object:clear()
	
	if asKey then
		if text then
			for key in pairs(variants) do
				if key ~= text and key:match("^" .. text) then
					table.insert(object.items,key)
				end
			end
		else
			for key in pairs(variants) do
				table.insert(object.items, key)
			end
		end
	else
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

--------------------------------------------------------------------------------

local function brailleCanvasDraw(brailleCanvas)
	local index, background, foreground, symbol
	for y = 1, brailleCanvas.height do
		for x = 1, brailleCanvas.width do
			index = screen.getIndex(brailleCanvas.x + x - 1, brailleCanvas.y + y - 1)
			background, foreground, symbol = screen.rawGet(index)
			screen.rawSet(index, background, brailleCanvas.pixels[y][x][9], brailleCanvas.pixels[y][x][10])
		end
	end

	return brailleCanvas
end

local function brailleCanvasSet(brailleCanvas, x, y, state, color)
	local xReal, yReal = math.ceil(x / 2), math.ceil(y / 4)
	
	brailleCanvas.pixels[yReal][xReal][(y - (yReal - 1) * 4 - 1) * 2 + x - (xReal - 1) * 2] = state and 1 or 0
	brailleCanvas.pixels[yReal][xReal][9] = color or brailleCanvas.pixels[yReal][xReal][9]
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

	return brailleCanvas
end

local function brailleCanvasGet(brailleCanvas, x, y)
	local xReal, yReal = math.ceil(x / 2), math.ceil(y / 4)
	return brailleCanvas.pixels[yReal][xReal][(y - (yReal - 1) * 4 - 1) * 2 + x - (xReal - 1) * 2], brailleCanvas.pixels[yReal][xReal][9], brailleCanvas.pixels[yReal][xReal][10]
end

local function brailleCanvasFill(brailleCanvas, x, y, width, height, state, color)
	for j = y, y + height - 1 do
		for i = x, x + width - 1 do
			brailleCanvas:set(i, j, state, color)
		end
	end
end

local function brailleCanvasClear(brailleCanvas)
	for j = 1, brailleCanvas.height * 4 do
		brailleCanvas.pixels[j] = {}
		for i = 1, brailleCanvas.width * 2 do
			brailleCanvas.pixels[j][i] = { 0, 0, 0, 0, 0, 0, 0, 0, 0x0, " " }
		end
	end
end

function GUI.brailleCanvas(x, y, width, height)
	local brailleCanvas = GUI.object(x, y, width, height)
	
	brailleCanvas.pixels = {}

	brailleCanvas.get = brailleCanvasGet
	brailleCanvas.set = brailleCanvasSet
	brailleCanvas.fill = brailleCanvasFill
	brailleCanvas.clear = brailleCanvasClear

	brailleCanvas.draw = brailleCanvasDraw

	brailleCanvas:clear()

	return brailleCanvas
end

--------------------------------------------------------------------------------

local function paletteShow(palette)
	local workspace = GUI.workspace()
	
	workspace:addChild(palette)

	palette.submitButton.onTouch = function()
		workspace:stop()
	end
	palette.cancelButton.onTouch = palette.submitButton.onTouch

	workspace:draw()
	workspace:start()	

	return palette.color.integer
end

function GUI.palette(x, y, startColor)
	local palette = GUI.window(x, y, 71, 25)
	
	palette.color = {hsb = {}, rgb = {}}
	palette:addChild(GUI.panel(1, 1, palette.width, palette.height, 0xF0F0F0))
	
	local bigImage = palette:addChild(GUI.image(1, 1, image.create(50, 25)))
	local bigCrest = palette:addChild(GUI.object(1, 1, 5, 3))

	local function paletteDrawBigCrestPixel(x, y, symbol)
		local background, foreground = screen.get(x, y)
		local r, g, b = color.integerToRGB(background)
		screen.set(x, y, background, (r + g + b) / 3 >= 127 and 0x0 or 0xFFFFFF, symbol)
	end

	bigCrest.draw = function(object)
		paletteDrawBigCrestPixel(object.x, object.y + 1, "─")
		paletteDrawBigCrestPixel(object.x + 1, object.y + 1, "─")
		paletteDrawBigCrestPixel(object.x + 3, object.y + 1, "─")
		paletteDrawBigCrestPixel(object.x + 4, object.y + 1, "─")
		paletteDrawBigCrestPixel(object.x + 2, object.y, "│")
		paletteDrawBigCrestPixel(object.x + 2, object.y + 2, "│")
	end
	bigCrest.passScreenEvents = true
	
	local miniImage = palette:addChild(GUI.image(53, 1, image.create(3, 25)))
	
	local miniCrest = palette:addChild(GUI.object(52, 1, 5, 1))
	miniCrest.draw = function(object)
		screen.drawText(object.x, object.y, 0x0, ">")
		screen.drawText(object.x + 4, object.y, 0x0, "<")
	end

	local colorPanel = palette:addChild(GUI.panel(58, 2, 12, 3, 0x0))
	palette.submitButton = palette:addChild(GUI.roundedButton(58, 6, 12, 1, 0x4B4B4B, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, "OK"))
	palette.cancelButton = palette:addChild(GUI.roundedButton(58, 8, 12, 1, 0xFFFFFF, 0x696969, 0x2D2D2D, 0xFFFFFF, "Cancel"))

	local function paletteRefreshBigImage()
		local saturationStep, brightnessStep, saturation, brightness = 1 / bigImage.width, 1 / bigImage.height, 0, 1
		for j = 1, bigImage.height do
			for i = 1, bigImage.width do
				image.set(bigImage.image, i, j, color.optimize(color.HSBToInteger(palette.color.hsb.hue, saturation, brightness)), 0x0, 0x0, " ")
				saturation = saturation + saturationStep
			end
			saturation, brightness = 0, brightness - brightnessStep
		end
	end

	local function paletteRefreshMiniImage()
		local hueStep, hue = 360 / miniImage.height, 0
		for j = 1, miniImage.height do
			for i = 1, miniImage.width do
				image.set(miniImage.image, i, j, color.optimize(color.HSBToInteger(hue, 1, 1)), 0x0, 0, " ")
			end
			hue = hue + hueStep
		end
	end

	local function paletteUpdateCrestsCoordinates()
		bigCrest.localX = math.floor((bigImage.width - 1) * palette.color.hsb.saturation) - 1
		bigCrest.localY = math.floor((bigImage.height - 1) - (bigImage.height - 1) * palette.color.hsb.brightness)
		miniCrest.localY = math.ceil(palette.color.hsb.hue / 360 * miniImage.height + 0.5)
	end

	local inputs

	local function paletteUpdateInputs()
		inputs[1].text = tostring(palette.color.rgb.red)
		inputs[2].text = tostring(palette.color.rgb.green)
		inputs[3].text = tostring(palette.color.rgb.blue)
		inputs[4].text = tostring(math.floor(palette.color.hsb.hue))
		inputs[5].text = tostring(math.floor(palette.color.hsb.saturation * 100))
		inputs[6].text = tostring(math.floor(palette.color.hsb.brightness * 100))
		inputs[7].text = string.format("%06X", palette.color.integer)
		colorPanel.colors.background = palette.color.integer
	end

	local function paletteSwitchColorFromHex(hex)
		palette.color.integer = hex
		palette.color.rgb.red, palette.color.rgb.green, palette.color.rgb.blue = color.integerToRGB(hex)
		palette.color.hsb.hue, palette.color.hsb.saturation, palette.color.hsb.brightness = color.RGBToHSB(palette.color.rgb.red, palette.color.rgb.green, palette.color.rgb.blue)
		paletteUpdateInputs()
	end

	local function paletteSwitchColorFromHsb(hue, saturation, brightness)
		palette.color.hsb.hue, palette.color.hsb.saturation, palette.color.hsb.brightness = hue, saturation, brightness
		palette.color.rgb.red, palette.color.rgb.green, palette.color.rgb.blue = color.HSBToRGB(hue, saturation, brightness)
		palette.color.integer = color.RGBToInteger(palette.color.rgb.red, palette.color.rgb.green, palette.color.rgb.blue)
		paletteUpdateInputs()
	end

	local function paletteSwitchColorFromRgb(red, green, blue)
		palette.color.rgb.red, palette.color.rgb.green, palette.color.rgb.blue = red, green, blue
		palette.color.hsb.hue, palette.color.hsb.saturation, palette.color.hsb.brightness = color.RGBToHSB(red, green, blue)
		palette.color.integer = color.RGBToInteger(red, green, blue)
		paletteUpdateInputs()
	end

	local function onAnyInputFinished()
		paletteRefreshBigImage()
		paletteUpdateCrestsCoordinates()
		palette.firstParent:draw()
	end

	local function onHexInputFinished()
		paletteSwitchColorFromHex(tonumber("0x" .. inputs[7].text))
		onAnyInputFinished()
	end

	local function onRgbInputFinished()
		paletteSwitchColorFromRgb(tonumber(inputs[1].text), tonumber(inputs[2].text), tonumber(inputs[3].text))
		onAnyInputFinished()
	end

	local function onHsbInputFinished()
		paletteSwitchColorFromHsb(tonumber(inputs[4].text), tonumber(inputs[5].text) / 100, tonumber(inputs[6].text) / 100)
		onAnyInputFinished()
	end

	local function rgbValidaror(text)
		local number = tonumber(text) if number and number >= 0 and number <= 255 then return true end
	end

	local function hValidator(text)
		local number = tonumber(text) if number and number >= 0 and number <= 359 then return true end
	end

	local function sbValidator(text)
		local number = tonumber(text) if number and number >= 0 and number <= 100 then return true end
	end

	local function hexValidator(text)
		if string.match(text, "^[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]$") then
			return true
		end
	end

	inputs = {
		{ shortcut = "R:", validator = rgbValidaror, onInputFinished = onRgbInputFinished },
		{ shortcut = "G:", validator = rgbValidaror, onInputFinished = onRgbInputFinished },
		{ shortcut = "B:", validator = rgbValidaror, onInputFinished = onRgbInputFinished },
		{ shortcut = "H:", validator = hValidator,   onInputFinished = onHsbInputFinished },
		{ shortcut = "S:", validator = sbValidator,  onInputFinished = onHsbInputFinished },
		{ shortcut = "L:", validator = sbValidator,  onInputFinished = onHsbInputFinished },
		{ shortcut = "0x", validator = hexValidator, onInputFinished = onHexInputFinished }
	}

	local y = 10
	for i = 1, #inputs do
		palette:addChild(GUI.label(58, y, 2, 1, 0x0, inputs[i].shortcut))
		
		local validator, onInputFinished = inputs[i].validator, inputs[i].onInputFinished
		inputs[i] = palette:addChild(GUI.input(61, y, 9, 1, 0xFFFFFF, 0x696969, 0x696969, 0xFFFFFF, 0x0, "", "", true))
		inputs[i].validator = validator
		inputs[i].onInputFinished = onInputFinished
		
		y = y + 2
	end
	
	local paletteConfigPath = paths.user.applicationData .. "GUI/Palette.cfg"
	
	local favourites
	if filesystem.exists(paletteConfigPath) then
		favourites = filesystem.readTable(paletteConfigPath)
	else
		favourites = {}
		for i = 1, 6 do favourites[i] = color.HSBToInteger(math.random(0, 360), 1, 1) end
		filesystem.writeTable(paletteConfigPath, favourites)
	end

	local favouritesContainer = palette:addChild(GUI.container(58, 24, 12, 1))
	for i = 1, #favourites do
		favouritesContainer:addChild(GUI.button(i * 2 - 1, 1, 2, 1, favourites[i], 0x0, 0x0, 0x0, " ")).onTouch = function(workspace)
			paletteSwitchColorFromHex(favourites[i])
			paletteRefreshBigImage()
			paletteUpdateCrestsCoordinates()
			workspace:draw()
		end
	end
	
	palette:addChild(GUI.button(58, 25, 12, 1, 0xFFFFFF, 0x4B4B4B, 0x2D2D2D, 0xFFFFFF, "+")).onTouch = function(workspace)
		local favouriteExists = false
		for i = 1, #favourites do
			if favourites[i] == palette.color.integer then
				favouriteExists = true
				break
			end
		end
		
		if not favouriteExists then
			table.insert(favourites, 1, palette.color.integer)
			table.remove(favourites, #favourites)
			for i = 1, #favourites do
				favouritesContainer.children[i].colors.default.background = favourites[i]
				favouritesContainer.children[i].colors.pressed.background = 0x0
			end
			
			filesystem.writeTable(paletteConfigPath, favourites)

			workspace:draw()
		end
	end

	bigImage.eventHandler = function(workspace, object, e1, e2, e3, e4)
		if e1 == "touch" or e1 == "drag" then
			bigCrest.localX, bigCrest.localY = e3 - palette.x - 1, e4 - palette.y
			paletteSwitchColorFromHex(select(3, screen.getGPUProxy().get(e3, e4)))
			workspace:draw()
		end
	end
	
	miniImage.eventHandler = function(workspace, object, e1, e2, e3, e4)
		if e1 == "touch" or e1 == "drag" then
			miniCrest.localY = e4 - palette.y + 1
			paletteSwitchColorFromHsb((e4 - miniImage.y) * 360 / miniImage.height, palette.color.hsb.saturation, palette.color.hsb.brightness)
			paletteRefreshBigImage()
			workspace:draw()
		end
	end

	palette.show = paletteShow

	paletteSwitchColorFromHex(startColor)
	paletteUpdateCrestsCoordinates()
	paletteRefreshBigImage()
	paletteRefreshMiniImage()

	return palette
end

--------------------------------------------------------------------------------

local function textUpdate(object)
	object.width = unicode.len(object.text)
	
	return object
end

local function textDraw(object)
	object:update()
	screen.drawText(object.x, object.y, object.color, object.text, object.transparency)

	return object
end

function GUI.text(x, y, color, text, transparency)
	local object = GUI.object(x, y, 1, 1)

	object.text = text
	object.color = color
	object.transparency = transparency
	object.update = textUpdate
	object.draw = textDraw
	object:update()

	return object
end

--------------------------------------------------------------------------------

function GUI.addBackgroundContainer(parentContainer, addPanel, addLayout, title)
	local container = parentContainer:addChild(GUI.container(1, 1, parentContainer.width, parentContainer.height))
	
	if addPanel then
		container.panel = container:addChild(GUI.panel(1, 1, container.width, container.height, GUI.BACKGROUND_CONTAINER_PANEL_COLOR, GUI.BACKGROUND_CONTAINER_PANEL_TRANSPARENCY))
		container.panel.eventHandler = function(parentContainer, object, e1)
			if e1 == "touch" then
				container:remove()
				parentContainer:draw()
			end
		end
	end

	if addLayout then
		container.layout = container:addChild(GUI.layout(1, 1, container.width, container.height, 1, 1))

		if title then
			container.label = container.layout:addChild(GUI.label(1, 1, 1, 1, GUI.BACKGROUND_CONTAINER_TITLE_COLOR, title)):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
		end
	end

	return container
end

--------------------------------------------------------------------------------

local function listUpdate(list)
	local step, child = false

	for i = 1, #list.children do
		child = list.children[i]
		-- Жмяканье пизды
		child.pressed = i == list.selectedItem
		
		-- Цвет залупы
		if step then
			child.colors.default = list.colors.alternative
		else
			child.colors.default = list.colors.default
		end

		child.colors.pressed, step = list.colors.selected, not step
		
		-- Размеры хуйни
		if list.cells[1][1].direction == GUI.DIRECTION_HORIZONTAL then
			if list.offsetMode then
				child.width, child.height = list.itemSize * 2 + unicode.len(child.text), list.height
			else
				child.width, child.height = list.itemSize, list.height
			end
		else
			if list.offsetMode then
				child.width, child.height = list.width, list.itemSize * 2 + 1
			else
				child.width, child.height = list.width, list.itemSize
			end
		end
	end

	layoutUpdate(list)
end

local function listItemEventHandler(workspace, item, e1, ...)
	if e1 == "touch" or e1 == "drag" then
		item.parent.selectedItem = item:indexOf()
		item.parent:update()
		workspace:draw()

		if item.onTouch then
			item.onTouch(workspace, item, e1, ...)
		end
	end
end

local function listAddItem(list, text)
	local item = list:addChild(pressable(1, 1, 1, 1, 0, 0, 0, 0, 0, 0, text))
	
	item.switchMode = true
	item.eventHandler = listItemEventHandler

	return item
end

local function listSetAlignment(list, ...)
	layoutSetAlignment(list, 1, 1, ...)
	return list
end

local function listSetSpacing(list, ...)
	layoutSetSpacing(list, 1, 1, ...)
	return list
end

local function listSetDirection(list, ...)
	layoutSetDirection(list, 1, 1, ...)
	return list
end

local function listSetFitting(list, ...)
	layoutSetFitting(list, 1, 1, ...)
	return list
end

local function listSetMargin(list, ...)
	layoutSetMargin(list, 1, 1, ...)
	return list
end

local function listGetMargin(list, ...)
	return layoutGetMargin(list, 1, 1, ...)
end

local function listGetItem(list, what)
	if type(what) == "number" then
		return list.children[what]
	else
		for i = 1, #list.children do
			if list.children[i].text == what then
				return list.children[i], i
			end
		end
	end
end

local function listCount(list)
	return #list.children
end

local function listDraw(list)
	if list.colors.default.background then
		screen.drawRectangle(list.x, list.y, list.width, list.height, list.colors.default.background, list.colors.default.text, " ")
	end

	layoutDraw(list)
end

function GUI.list(x, y, width, height, itemSize, spacing, backgroundColor, textColor, backgroundAlternatingColor, textAlternatingColor, backgroundSelectedColor, textSelectedColor, offsetMode)
	local list = GUI.layout(x, y, width, height, 1, 1)

	list.colors = {
		default = {
			background = backgroundColor,
			text = textColor
		},
		alternative = {
			background = backgroundAlternatingColor,
			text = textAlternatingColor
		},
		selected = {
			background = backgroundSelectedColor,
			text = textSelectedColor
		},
	}

	list.passScreenEvents = false
	list.selectedItem = 1
	list.offsetMode = offsetMode
	list.itemSize = itemSize
	
	list.addItem = listAddItem
	list.getItem = listGetItem
	list.count = listCount
	list.setAlignment = listSetAlignment
	list.setSpacing = listSetSpacing
	list.setDirection = listSetDirection
	list.setFitting = listSetFitting
	list.setMargin = listSetMargin
	list.getMargin = listGetMargin
	list.update = listUpdate
	list.draw = listDraw

	list:setAlignment(GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_TOP)
	list:setSpacing(spacing)
	list:setDirection(GUI.DIRECTION_VERTICAL)

	return list
end

---------------------------------------------------------------------------------------------------

local function keyAndValueUpdate(object)
	object.keyLength, object.valueLength = unicode.len(object.key), unicode.len(object.value)
	object.width = object.keyLength + object.valueLength
end

local function keyAndValueDraw(object)
	keyAndValueUpdate(object)
	screen.drawText(object.x, object.y, object.colors.key, object.key)
	screen.drawText(object.x + object.keyLength, object.y, object.colors.value, object.value)
end

function GUI.keyAndValue(x, y, keyColor, valueColor, key, value)
	local object = GUI.object(x, y, 1, 1)
	
	object.colors = {
		key = keyColor,
		value = valueColor
	}
	object.key = key
	object.value = value

	object.update = keyAndValueUpdate
	object.draw = keyAndValueDraw

	object:update()

	return object
end

---------------------------------------------------------------------------------------------------

function GUI.highlightString(x, y, fromChar, indentationWidth, patterns, colorScheme, s)	
	local stringLength, x1, y1, x2, y2 = unicode.len(s), screen.getDrawLimit()

	fromChar = fromChar or 1
	if x < x1 then
		fromChar = fromChar + x1 - x
		x = x1
	end

	-- local toChar, endX = stringLength, x + stringLength - 1
	-- if endX > x2 then
	-- 	toChar = toChar - endX + x2
	-- end
	local toChar = fromChar + x2 - x
	if toChar > stringLength then
		toChar = stringLength
	end

	local counter, symbols, colors, bufferIndex, newFrameBackgrounds, newFrameForegrounds, newFrameSymbols, searchFrom, starting, ending = indentationWidth, {}, {}, screen.getIndex(x, y), screen.getNewFrameTables()

	-- Пидорасим на символы
	for i = fromChar, toChar do
		symbols[i] = unicode.sub(s, i, i)
	end

	-- Вгоняем в цветовую карту синтаксическую подсветку
	for j = 1, #patterns, 4 do
		searchFrom = 1
		
		while true do
			starting, ending = text.unicodeFind(s, patterns[j], searchFrom)
			
			if starting then
				for i = starting + patterns[j + 2], ending - patterns[j + 3] do
					colors[i] = colorScheme[patterns[j + 1]]
				end
			else
				break
			end

			searchFrom = ending + 1 - patterns[j + 3]
		end
	end

	-- Ебошим индентейшны
	for i = fromChar, toChar do
		if symbols[i] == " " then
			colors[i] = colorScheme.indentation
			
			if counter == indentationWidth then
				symbols[i], counter = "│", 0
			end

			counter = counter + 1
		else
			break
		end
	end

	-- Рисуем текст
	for i = fromChar, toChar do
		newFrameForegrounds[bufferIndex], newFrameSymbols[bufferIndex] = colors[i] or colorScheme.text, symbols[i] or " "
		bufferIndex = bufferIndex + 1
	end
end

--------------------------------------------------------------------------------

local function dropDownMenuItemDraw(item)
	local yText = item.y + math.floor(item.height / 2)

	if item.type == 1 then
		local textColor = item.color or item.parent.parent.colors.default.text

		if item.pressed then
			textColor = item.parent.parent.colors.selected.text
			screen.drawRectangle(item.x, item.y, item.width, item.height, item.parent.parent.colors.selected.background, textColor, " ")
		elseif item.disabled then
			textColor = item.parent.parent.colors.disabled.text
		end

		screen.drawText(item.x + 1, yText, textColor, item.text)
		if item.shortcut then
			screen.drawText(item.x + item.width - unicode.len(item.shortcut) - 1, yText, textColor, item.shortcut)
		end
	else
		screen.drawText(item.x, yText, item.parent.parent.colors.separator, string.rep("─", item.width))
	end

	return item
end

local function dropDownMenuReleaseItems(menu)
	for i = 1, #menu.itemsContainer.children do
		menu.itemsContainer.children[i].pressed = false
	end

	return menu
end

local function dropDownMenuItemEventHandler(workspace, object, e1, ...)
	if e1 == "touch" then
		if object.type == 1 and not object.pressed then
			object.pressed = true
			workspace:draw()

			if object.subMenu then
				object.parent.parent.parent:addChild(object.subMenu:releaseItems())
				object.subMenu.localX = object.parent.parent.localX + object.parent.parent.width
				object.subMenu.localY = object.parent.parent.localY + object.localY - 1
				if screen.getWidth() - object.parent.parent.localX - object.parent.parent.width + 1 < object.subMenu.width then
					object.subMenu.localX = object.parent.parent.localX - object.subMenu.width
					object.parent.parent:moveToFront()
				end

				workspace:draw()
			else
				event.sleep(0.2)

				object.parent.parent.parent:remove()
				
				local objectIndex = object:indexOf()
				for i = 2, #object.parent.parent.parent.children do
					if object.parent.parent.parent.children[i].onMenuClosed then
						object.parent.parent.parent.children[i].onMenuClosed(objectIndex)
					end
				end

				if object.onTouch then
					object.onTouch()
				end

				workspace:draw()
			end
		end
	end
end

local function dropDownMenuGetHeight(menu)
	local height = 0
	for i = 1, #menu.itemsContainer.children do
		height = height + (menu.itemsContainer.children[i].type == 2 and 1 or menu.itemHeight)
	end

	return height
end

local function dropDownMenuReposition(menu)
	menu.itemsContainer.width, menu.itemsContainer.height = menu.width, menu.height
	menu.prevButton.width, menu.nextButton.width = menu.width, menu.width
	menu.nextButton.localY = menu.height

	local y = menu.itemsContainer.children[1].localY
	for i = 1, #menu.itemsContainer.children do
		menu.itemsContainer.children[i].localY = y
		menu.itemsContainer.children[i].width = menu.itemsContainer.width
		y = y + menu.itemsContainer.children[i].height
	end

	menu.prevButton.hidden = menu.itemsContainer.children[1].localY >= 1
	menu.nextButton.hidden = menu.itemsContainer.children[#menu.itemsContainer.children].localY + menu.itemsContainer.children[#menu.itemsContainer.children].height - 1 <= menu.height
end

local function dropDownMenuUpdate(menu)
	if #menu.itemsContainer.children > 0 then
		menu.height = math.min(dropDownMenuGetHeight(menu), menu.maximumHeight, screen.getHeight() - menu.y)
		dropDownMenuReposition(menu)
	end
end

local function dropDownMenuRemoveItem(menu, index)
	table.remove(menu.itemsContainer.children, index)

	menu:update()

	return menu
end

local function dropDownMenuAddItem(menu, text, disabled, shortcut, color)
	local item = menu.itemsContainer:addChild(GUI.object(1, 1, 1, menu.itemHeight))
	item.type = 1
	item.text = text
	item.disabled = disabled
	item.shortcut = shortcut
	item.color = color
	item.draw = dropDownMenuItemDraw
	item.eventHandler = dropDownMenuItemEventHandler

	menu:update()

	return item
end

local function dropDownMenuAddSeparator(menu)
	local item = menu.itemsContainer:addChild(GUI.object(1, 1, 1, 1))
	item.type = 2
	item.draw = dropDownMenuItemDraw
	item.eventHandler = dropDownMenuItemEventHandler

	menu:update()

	return item
end

local function dropDownMenuScrollDown(workspace, menu)
	local limit, first = 1, menu.itemsContainer.children[1]

	first.localY = first.localY + menu.scrollSpeed
	if first.localY > limit then
		first.localY = limit
	end

	dropDownMenuReposition(menu)
	workspace:draw()
end

local function dropDownMenuScrollUp(workspace, menu)
	local limit, first = -(#menu.itemsContainer.children * menu.itemHeight - menu.height - 1), menu.itemsContainer.children[1]

	first.localY = first.localY - menu.scrollSpeed
	if first.localY < limit then
		first.localY = limit
	end

	dropDownMenuReposition(menu)
	workspace:draw()
end

local function dropDownMenuEventHandler(workspace, menu, e1, e2, e3, e4, e5)
	if e1 == "scroll" then
		if e5 == 1 then
			dropDownMenuScrollDown(workspace, menu)
		else
			dropDownMenuScrollUp(workspace, menu)
		end
	end
end

local function dropDownMenuPrevButtonOnTouch(workspace, button)
	dropDownMenuScrollDown(workspace, button.parent)
end

local function dropDownMenuNextButtonOnTouch(workspace, button)
	dropDownMenuScrollUp(workspace, button.parent)
end

local function dropDownMenuDraw(menu)
	screen.drawRectangle(menu.x, menu.y, menu.width, menu.height, menu.colors.default.background, menu.colors.default.text, " ", menu.colors.transparency.background)
	GUI.drawShadow(menu.x, menu.y, menu.width, menu.height, menu.colors.transparency.shadow, true)
	containerDraw(menu)
end

local function dropDownMenuBackgroundObjectEventHandler(workspace, object, e1)
	if e1 == "touch" then
		for i = 2, #object.parent.children do
			if object.parent.children[i].onMenuClosed then
				object.parent.children[i].onMenuClosed()
			end
		end

		object.parent:remove()
		workspace:draw()
	end
end

local function dropDownMenuAdd(parentContainer, menu)
	local container = parentContainer:addChild(GUI.container(1, 1, parentContainer.width, parentContainer.height))
	container:addChild(GUI.object(1, 1, container.width, container.height)).eventHandler = dropDownMenuBackgroundObjectEventHandler
	
	return container:addChild(menu:releaseItems())
end

function GUI.dropDownMenu(x, y, width, maximumHeight, itemHeight, backgroundColor, textColor, backgroundPressedColor, textPressedColor, disabledColor, separatorColor, backgroundTransparency, shadowTransparency)
	local menu = GUI.container(x, y, width, 1)
	
	menu.colors = {
		default = {
			background = backgroundColor,
			text = textColor
		},
		selected = {
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

	menu.scrollSpeed = 1

	menu.itemsContainer = menu:addChild(GUI.container(1, 1, menu.width, menu.height))
	menu.prevButton = menu:addChild(GUI.button(1, 1, menu.width, 1, backgroundColor, textColor, backgroundPressedColor, textPressedColor, "▲"))
	menu.nextButton = menu:addChild(GUI.button(1, 1, menu.width, 1, backgroundColor, textColor, backgroundPressedColor, textPressedColor, "▼"))
	menu.prevButton.colors.transparency, menu.nextButton.colors.transparency = backgroundTransparency, backgroundTransparency
	menu.prevButton.onTouch = dropDownMenuPrevButtonOnTouch
	menu.nextButton.onTouch = dropDownMenuNextButtonOnTouch

	menu.releaseItems = dropDownMenuReleaseItems
	menu.itemHeight = itemHeight
	menu.addSeparator = dropDownMenuAddSeparator
	menu.addItem = dropDownMenuAddItem
	menu.removeItem = dropDownMenuRemoveItem
	menu.draw = dropDownMenuDraw
	menu.maximumHeight = maximumHeight
	menu.eventHandler = dropDownMenuEventHandler
	menu.update = dropDownMenuUpdate

	return menu
end

--------------------------------------------------------------------------------

local function contextMenuUpdate(menu)
	if #menu.itemsContainer.children > 0 then
		local widestItem, widestShortcut = 0, 0
		for i = 1, #menu.itemsContainer.children do
			if menu.itemsContainer.children[i].type == 1 then
				widestItem = math.max(widestItem, unicode.len(menu.itemsContainer.children[i].text))
				if menu.itemsContainer.children[i].shortcut then
					widestShortcut = math.max(widestShortcut, unicode.len(menu.itemsContainer.children[i].shortcut))
				end
			end
		end

		menu.width, menu.height = 2 + widestItem + (widestShortcut > 0 and 3 + widestShortcut or 0), math.min(dropDownMenuGetHeight(menu), menu.maximumHeight)
		dropDownMenuReposition(menu)

		local bufferWidth, bufferHeight = screen.getResolution()
		if menu.x + menu.width + 1 >= bufferWidth then
			menu.localX = bufferWidth - menu.width - 1
		end
		if menu.y + menu.height >= bufferHeight then
			menu.localY = bufferHeight - menu.height
		end
	end
end

local contextMenuCreate, contextMenuaddSubMenuItem

contextMenuaddSubMenuItem = function(menu, text, disabled)
	local item = menu:addItem(text, disabled, "►")
	item.subMenu = contextMenuCreate(1, 1)
	item.subMenu.colors = menu.colors
	
	return item.subMenu
end

contextMenuCreate = function(x, y, backgroundColor, textColor, backgroundPressedColor, textPressedColor, disabledColor, separatorColor, backgroundTransparency, shadowTransparency)
	local menu = GUI.dropDownMenu(
		x,
		y,
		1,
		math.ceil(screen.getHeight() * 0.5),
		1,
		backgroundColor or GUI.CONTEXT_MENU_DEFAULT_BACKGROUND_COLOR,
		textColor or GUI.CONTEXT_MENU_DEFAULT_TEXT_COLOR,
		backgroundPressedColor or GUI.CONTEXT_MENU_PRESSED_BACKGROUND_COLOR,
		textPressedColor or GUI.CONTEXT_MENU_PRESSED_TEXT_COLOR,
		disabledColor or GUI.CONTEXT_MENU_DISABLED_COLOR,
		separatorColor or GUI.CONTEXT_MENU_SEPARATOR_COLOR,
		backgroundTransparency or GUI.CONTEXT_MENU_BACKGROUND_TRANSPARENCY,
		shadowTransparency or GUI.CONTEXT_MENU_SHADOW_TRANSPARENCY
	)

	menu.update = contextMenuUpdate
	menu.addSubMenuItem = contextMenuaddSubMenuItem

	return menu
end

function GUI.addContextMenu(parentContainer, arg1, ...)
	if type(arg1) == "table" then
		return dropDownMenuAdd(parentContainer, arg1, ...)
	else
		return dropDownMenuAdd(parentContainer, contextMenuCreate(arg1, ...))
	end
end

--------------------------------------------------------------------------------

local function comboBoxDraw(object)
	screen.drawRectangle(object.x, object.y, object.width, object.height, object.colors.default.background, object.colors.default.text, " ")
	if object.dropDownMenu.itemsContainer.children[object.selectedItem] then
		screen.drawText(object.x + 1, math.floor(object.y + object.height / 2), object.colors.default.text, text.limit(object.dropDownMenu.itemsContainer.children[object.selectedItem].text, object.width - object.height - 2, "right"))
	end

	local width = object.height * 2 - 1
	screen.drawRectangle(object.x + object.width - object.height * 2 + 1, object.y, width, object.height, object.colors.arrow.background, object.colors.arrow.text, " ")
	screen.drawText(math.floor(object.x + object.width - width / 2), math.floor(object.y + object.height / 2), object.colors.arrow.text, object.pressed and "▲" or "▼")

	return object
end

local function comboBoxGetItem(object, what)
	if type(what) == "number" then
		return object.dropDownMenu.itemsContainer.children[what]
	else
		local children = object.dropDownMenu.itemsContainer.children
		for i = 1, #children do
			if children[i].text == what then
				return children[i], i
			end
		end
	end
end

local function comboBoxRemoveItem(object, index)
	object.dropDownMenu:removeItem(index)
	if object.selectedItem > #object.dropDownMenu.itemsContainer.children then
		object.selectedItem = #object.dropDownMenu.itemsContainer.children
	end
end

local function comboBoxCount(object)
	return #object.dropDownMenu.itemsContainer.children
end

local function comboBoxClear(object)
	object.dropDownMenu.itemsContainer:removeChildren()
	object.selectedItem = 1

	return object
end

local function comboBoxEventHandler(workspace, object, e1, ...)
	if e1 == "touch" and #object.dropDownMenu.itemsContainer.children > 0 then
		object.pressed = true
		object.dropDownMenu.x, object.dropDownMenu.y, object.dropDownMenu.width = object.x, object.y + object.height, object.width
		object.dropDownMenu:update()
		dropDownMenuAdd(workspace, object.dropDownMenu)
		workspace:draw()
	end
end

local function comboBoxAddItem(object, ...)
	return object.dropDownMenu:addItem(...)
end

local function comboBoxAddSeparator(object)
	return object.dropDownMenu:addSeparator()
end

function GUI.comboBox(x, y, width, itemSize, backgroundColor, textColor, arrowBackgroundColor, arrowTextColor)
	local comboBox = GUI.object(x, y, width, itemSize)
	
	comboBox.colors = {
		default = {
			background = backgroundColor,
			text = textColor
		},
		selected = {
			background = GUI.CONTEXT_MENU_PRESSED_BACKGROUND_COLOR,
			text = GUI.CONTEXT_MENU_PRESSED_TEXT_COLOR
		},
		arrow = {
			background = arrowBackgroundColor,
			text = arrowTextColor
		}
	}

	comboBox.dropDownMenu = GUI.dropDownMenu(
		1,
		1,
		1,
		math.ceil(screen.getHeight() * 0.5),
		itemSize,
		comboBox.colors.default.background, 
		comboBox.colors.default.text, 
		comboBox.colors.selected.background,
		comboBox.colors.selected.text,
		GUI.CONTEXT_MENU_DISABLED_COLOR,
		GUI.CONTEXT_MENU_SEPARATOR_COLOR,
		GUI.CONTEXT_MENU_BACKGROUND_TRANSPARENCY, 
		GUI.CONTEXT_MENU_SHADOW_TRANSPARENCY
	)

	comboBox.dropDownMenu.onMenuClosed = function(index)
		comboBox.pressed = false
		comboBox.selectedItem = index or comboBox.selectedItem
		comboBox.firstParent:draw()
		
		if index and comboBox.onItemSelected then
			comboBox.onItemSelected(index)
		end
	end

	comboBox.selectedItem = 1
	comboBox.addItem = comboBoxAddItem
	comboBox.removeItem = comboBoxRemoveItem
	comboBox.addSeparator = comboBoxAddSeparator
	comboBox.draw = comboBoxDraw
	comboBox.clear = comboBoxClear
	comboBox.getItem = comboBoxGetItem
	comboBox.count = comboBoxCount
	comboBox.eventHandler = comboBoxEventHandler

	return comboBox
end

---------------------------------------------------------------------------------------------------

local function windowDraw(window)
	containerDraw(window)
	GUI.drawShadow(window.x, window.y, window.width, window.height, GUI.WINDOW_SHADOW_TRANSPARENCY, true)

	return window
end

local function windowCheck(window, x, y)
	local child
	for i = #window.children, 1, -1 do
		child = window.children[i]
		
		if
			not child.hidden and
			not child.disabled and
			child:isPointInside(x, y)
		then
			if not child.passScreenEvents and child.eventHandler then
				return true
			elseif child.children then
				local result = windowCheck(child, x, y)
				
				if result == true then
					return true
				elseif result == false then
					return false
				end
			end
		end
	end
end

local function windowEventHandler(workspace, window, e1, e2, e3, e4, ...)
	if window.movingEnabled then
		if e1 == "touch" then
			if not windowCheck(window, e3, e4) then
				window.lastTouchX, window.lastTouchY = e3, e4
			end

			if window ~= window.parent.children[#window.parent.children] then
				window:focus()
				
				workspace:draw()
			end
		elseif e1 == "drag" and window.lastTouchX and not windowCheck(window, e3, e4) then
			local xOffset, yOffset = e3 - window.lastTouchX, e4 - window.lastTouchY
			
			if xOffset ~= 0 or yOffset ~= 0 then
				window.localX, window.localY = window.localX + xOffset, window.localY + yOffset
				window.lastTouchX, window.lastTouchY = e3, e4
				
				workspace:draw()
			end
		elseif e1 == "drop" then
			window.lastTouchX, window.lastTouchY = nil, nil
		end
	end
end

local function windowResize(window, width, height, ignoreOnResizeFinished)
	window.width, window.height = width, height
	
	if window.onResize then
		window.onResize(width, height)
	end

	if window.onResizeFinished and not ignoreOnResizeFinished then
		window.onResizeFinished()
	end

	return window
end

function GUI.windowMaximize(window, animationDisabled)
	local fromX, fromY, fromWidth, fromHeight, toX, toY, toWidth, toHeight = window.localX, window.localY, window.width, window.height
	
	if window.maximized then
		toX, toY, toWidth, toHeight = window.oldGeometryX, window.oldGeometryY, window.oldGeometryWidth, window.oldGeometryHeight

		window.oldGeometryX, window.oldGeometryY, window.oldGeometryWidth, window.oldGeometryHeight = nil, nil, nil, nil
		window.maximized = nil
	else
		toWidth, toHeight = window.parent.width, window.parent.height
		
		if window.maxWidth then
			toWidth = math.min(toWidth, window.maxWidth)
		end
		
		if window.maxHeight then
			toHeight = math.min(toHeight, window.maxHeight)
		end

		toX, toY = math.floor(1 + window.parent.width / 2 - toWidth / 2), math.floor(1 + window.parent.height / 2 - toHeight / 2)

		window.oldGeometryX, window.oldGeometryY, window.oldGeometryWidth, window.oldGeometryHeight = window.localX, window.localY, window.width, window.height
		window.maximized = true
	end

	if animationDisabled then
		window.localX, window.localY = toX, toY
		window:resize(toWidth, toHeight)
	else
		window:addAnimation(
			function(animation)
				window.localX, window.localY =
					math.floor(fromX + (toX - fromX) * animation.position),
					math.floor(fromY + (toY - fromY) * animation.position)

				window:resize(
					math.floor(fromWidth + (toWidth - fromWidth) * animation.position),
					math.floor(fromHeight + (toHeight - fromHeight) * animation.position),
					animation.position < 1
				)
			end,
			function(animation)
				animation:remove()
			end
		):start(0.5)
	end
end

function GUI.windowMinimize(window)
	window.hidden = not window.hidden
end

function GUI.windowFocus(window)
	GUI.focusedObject = window
	window.hidden = false
	window:moveToFront()

	if window.onFocus then
		window.onFocus()
	end
end

function GUI.window(x, y, width, height)
	local window = GUI.container(x, y, width, height)
	
	window.passScreenEvents = false
	window.movingEnabled = true

	window.resize = windowResize
	window.maximize = GUI.windowMaximize
	window.minimize = GUI.windowMinimize
	window.focus = GUI.windowFocus

	window.eventHandler = windowEventHandler
	window.draw = windowDraw

	return window
end

function GUI.filledWindow(x, y, width, height, backgroundColor)
	local window = GUI.window(x, y, width, height)

	window.backgroundPanel = window:addChild(GUI.panel(1, 1, width, height, backgroundColor))
	window.actionButtons = window:addChild(GUI.actionButtons(2, 2, true))

	return window
end

function GUI.titledWindow(x, y, width, height, title, addTitlePanel)
	local window = GUI.filledWindow(x, y, width, height, GUI.WINDOW_BACKGROUND_PANEL_COLOR)

	if addTitlePanel then
		window.titlePanel = window:addChild(GUI.panel(1, 1, width, 1, GUI.WINDOW_TITLE_BACKGROUND_COLOR))
		window.backgroundPanel.localY, window.backgroundPanel.height = 2, window.height - 1
	end

	window.titleLabel = window:addChild(GUI.label(1, 1, width, height, GUI.WINDOW_TITLE_TEXT_COLOR, title)):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
	window.actionButtons.localY = 1
	window.actionButtons:moveToFront()

	return window
end

function GUI.tabbedWindow(x, y, width, height, ...)
	local window = GUI.filledWindow(x, y, width, height, GUI.WINDOW_BACKGROUND_PANEL_COLOR)

	window.tabBar = window:addChild(GUI.tabBar(1, 1, window.width, 3, 2, 0, GUI.WINDOW_TAB_BAR_DEFAULT_BACKGROUND_COLOR, GUI.WINDOW_TAB_BAR_DEFAULT_TEXT_COLOR, GUI.WINDOW_TAB_BAR_DEFAULT_BACKGROUND_COLOR, GUI.WINDOW_TAB_BAR_DEFAULT_TEXT_COLOR, GUI.WINDOW_TAB_BAR_SELECTED_BACKGROUND_COLOR, GUI.WINDOW_TAB_BAR_SELECTED_TEXT_COLOR, true))
	
	window.backgroundPanel.localY, window.backgroundPanel.height = 4, window.height - 3
	window.actionButtons:moveToFront()
	window.actionButtons.localY = 2

	return window
end

---------------------------------------------------------------------------------------------------

function GUI.tabBar(...)
	local tabBar = GUI.list(...)

	tabBar:setDirection(GUI.DIRECTION_HORIZONTAL)
	tabBar:setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)

	return tabBar
end

--------------------------------------------------------------------------------

local function menuDraw(menu)
	screen.drawRectangle(menu.x, menu.y, menu.width, 1, menu.colors.default.background, menu.colors.default.text, " ", menu.colors.transparency)
	layoutDraw(menu)
end

local function menuAddItem(menu, text, textColor)
	local item = menu:addChild(pressable(1, 1, unicode.len(text) + 2, 1, nil, textColor or menu.colors.default.text, menu.colors.selected.background, menu.colors.selected.text, 0x0, 0x0, text))
	item.eventHandler = pressableEventHandler

	return item
end

local function menuGetItem(menu, what)
	if type(what) == "number" then
		return menu.children[what]
	else
		for i = 1, #menu.children do
			if menu.children[i].text == what then
				return menu.children[i], i
			end
		end
	end
end

local function menuContextMenuItemOnTouch(workspace, item)
	item.contextMenu.x, item.contextMenu.y = item.x, item.y + 1
	dropDownMenuAdd(workspace, item.contextMenu)

	workspace:draw()
end

local function menuAddContextMenuItem(menu, ...)
	local item = menu:addItem(...)

	item.switchMode = true
	item.onTouch = menuContextMenuItemOnTouch
	item.contextMenu = contextMenuCreate(1, 1)
	item.contextMenu.onMenuClosed = function()
		item.pressed = false
		item.firstParent:draw()
	end

	return item.contextMenu
end

function GUI.menu(x, y, width, backgroundColor, textColor, backgroundPressedColor, textPressedColor, backgroundTransparency)
	local menu = GUI.layout(x, y, width, 1, 1, 1)
	
	menu.colors = {
		default = {
			background = backgroundColor,
			text = textColor,
		},
		selected = {
			background = backgroundPressedColor,
			text = textPressedColor,
		},
		transparency = backgroundTransparency
	}
	
	menu.passScreenEvents = false
	menu.addContextMenuItem = menuAddContextMenuItem
	menu.addItem = menuAddItem
	menu.getItem = menuGetItem
	menu.draw = menuDraw

	menu:setDirection(1, 1, GUI.DIRECTION_HORIZONTAL)
	menu:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_TOP)
	menu:setSpacing(1, 1, 0)
	menu:setMargin(1, 1, 1, 0)

	return menu
end

---------------------------------------------------------------------------------------------------

local function progressIndicatorDraw(self)
	local color = self.active and (self.position == 1 and self.colors.secondary or self.colors.primary) or self.colors.passive
	screen.drawText(self.x + 1, self.y, color, "⢀")
	screen.drawText(self.x + 2, self.y, color, "⡀")

	color = self.active and (self.position == 2 and self.colors.secondary or self.colors.primary) or self.colors.passive
	screen.drawText(self.x + 3, self.y + 1, color, "⠆")
	screen.drawText(self.x + 2, self.y + 1, color, "⢈")

	color = self.active and (self.position == 3 and self.colors.secondary or self.colors.primary) or self.colors.passive
	screen.drawText(self.x + 1, self.y + 2, color, "⠈")
	screen.drawText(self.x + 2, self.y + 2, color, "⠁")

	color = self.active and (self.position == 4 and self.colors.secondary or self.colors.primary) or self.colors.passive
	screen.drawText(self.x, self.y + 1, color, "⠰")
	screen.drawText(self.x + 1, self.y + 1, color, "⡁")
end

local function progressIndicatorRoll(self)
	self.position = self.position + 1
	if self.position > 4 then
		self.position = 1
	end
end

local function progressIndicatorReset(self, state)
	self.active = state
	self.position = 1
end

function GUI.progressIndicator(x, y, passiveColor, primaryColor, secondaryColor)
	local object = GUI.object(x, y, 4, 3)
	
	object.colors = {
		passive = passiveColor,
		primary = primaryColor,
		secondary = secondaryColor
	}

	object.active = false
	object.reset = progressIndicatorReset
	object.draw = progressIndicatorDraw
	object.roll = progressIndicatorRoll

	object:reset()

	return object
end

---------------------------------------------------------------------------------------------------

local function tableHeaderDraw(self)
	screen.drawRectangle(self.x, self.y, self.width, self.height, self.parent.colors.headerBackground, self.parent.colors.headerText, " ")
	screen.drawText(self.x + 1, self.y, self.parent.colors.headerText, self.text)
end

local function tableAddColumn(self, headerText, sizePolicy, size)
	layoutAddColumn(self, sizePolicy, size)
	
	local lastColumn = #self.columnSizes
	
	local header = self:setPosition(lastColumn, 1, self:addChild(GUI.object(1, 1, 1, self.itemHeight)))
	header.text = headerText
	header.draw = tableHeaderDraw

	for row = 1, 2 do
		self:setAlignment(lastColumn, row, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_TOP)
		self:setSpacing(lastColumn, row, 0)
		self:setFitting(lastColumn, row, true, false)
	end
end

local function tableAddRow(self, ...)
	local objects, columnCount = {...}, #self.columnSizes
	local index = #self.children - columnCount + 1
	
	if #objects == columnCount then
		for i = #objects, 1, -1 do
			local object = self:setPosition(i, 2, self:addChild(objects[i], index))

			object.height = self.itemHeight
			object.alternative = self.nextRowAlternative
		end

		self.nextRowAlternative = not self.nextRowAlternative
	else
		error("Failed to add row: count of columns ~= count of objects in row")
	end
end

local function tableUpdateSelection(self)
	local columnCount, row = #self.columnSizes, 1
	
	for i = 1, #self.children - columnCount, columnCount do
		for j = i, i + columnCount - 1 do
			self.children[j].selected = self.selectedRows[row]
		end

		row = row + 1
	end
end

local function tableClear(self)
	local columnCount, childrenCount = #self.columnSizes, #self.children
	if childrenCount > columnCount then
		self:removeChildren(1, childrenCount - columnCount)
	end

	self.selectedRows, self.nextRowAlternative = {}, nil
end

function GUI.tableCellEventHandler(workspace, self, e1, e2, e3, e4, e5, ...)
	if e1 == "touch" or e1 == "drag" or e1 == "double_touch" then
		local row = math.ceil(self:indexOf() / #self.parent.columnSizes)

		-- Deselecting all rows
		if (e5 == 0 or not self.parent.selectedRows[row]) and not (keyboard.isControlDown() or keyboard.isCommandDown()) then
			self.parent.selectedRows = {}
		end

		-- Selecting this row
		self.parent.selectedRows[row] = true
		tableUpdateSelection(self.parent)

		if self.parent.onCellTouch then
			self.parent.onCellTouch(workspace, self, e1, e2, e3, e4, e5, ...)
		end

		workspace:draw()
	end
end

function GUI.tableCellDraw(self)
	local background, foreground
	if self.selected then
		background, foreground = self.colors.selectionBackground, self.colors.selectionText
	elseif self.alternative then
		background, foreground = self.colors.alternativeBackground, self.colors.alternativeText
	else
		background, foreground = self.colors.defaultBackground, self.colors.defaultText
	end

	if background then
		screen.drawRectangle(self.x, self.y, self.width, self.height,
			background,
			foreground,
		" ")
	end

	return foreground
end

function GUI.tableCell(colors)
	local cell = GUI.object(1, 1, 1, 1)

	cell.colors = colors
	cell.draw = GUI.tableCellDraw
	cell.eventHandler = GUI.tableCellEventHandler

	return cell
end

local function tableTextCellDraw(self)
	screen.drawText(self.x + 1, self.y, GUI.tableCellDraw(self), self.text)
end

function GUI.tableTextCell(colors, text)
	local cell = GUI.tableCell(colors)

	cell.text = text
	cell.draw = tableTextCellDraw

	return cell
end

local function tableDraw(self)
	-- Items background
	screen.drawRectangle(self.x, self.y + self.itemHeight, self.width, self.height - self.itemHeight, self.colors.background, 0x0, " ")
	-- Content
	layoutDraw(self)
end

function GUI.tableEventHandler(workspace, self, e1, e2, e3, e4, e5, ...)
	if e1 == "touch" then
		local itemTouched = false
		for i = 1, #self.children do
			if self.children[i]:isPointInside(e3, e4) then
				itemTouched = true
				break
			end
		end

		if not itemTouched then
			self.onBackgroundTouch(workspace, self, e1, e2, e3, e4, e5, ...)
		end
	elseif e1 == "scroll" then
		local columnCount = #self.columnSizes
		local horizontalMargin, verticalMargin = self:getMargin(1, 2)

		for i = 1, columnCount do
			self:setMargin(i, 2, horizontalMargin,
				math.max(
					-self.itemHeight * (#self.children - columnCount) / columnCount + 1,
					math.min(
						0,
						verticalMargin + e5
					)
				)
			)
		end

		workspace:draw()
	end
end

function GUI.table(x, y, width, height, itemHeight, backgroundColor, headerBackgroundColor, headerTextColor)
	local table = GUI.layout(x, y, width, height, 0, 2)

	table.colors = {
		background = backgroundColor,
		headerBackground = headerBackgroundColor,
		headerText = headerTextColor
	}

	table.itemHeight = itemHeight
	table.selectedRows = {}

	table.addColumn = tableAddColumn
	table.addRow = tableAddRow
	table.clear = tableClear
	table.draw = tableDraw
	table.eventHandler = GUI.tableEventHandler

	table:setRowHeight(1, GUI.SIZE_POLICY_ABSOLUTE, itemHeight)
	table:setRowHeight(2, GUI.SIZE_POLICY_RELATIVE, 1.0)

	return table
end

---------------------------------------------------------------------------------------------------

-- local workspace = GUI.workspace()

-- workspace:addChild(GUI.panel(1, 1, workspace.width, workspace.height, 0x2D2D2D))

-- local t = workspace:addChild(GUI.table(3, 2, 80, 30, 1,
-- 	0xF0F0F0,
-- 	0xFFFFFF,
-- 	0x000000
-- ))

-- t:addColumn("Name", GUI.SIZE_POLICY_RELATIVE, 0.6)
-- t:addColumn("Date", GUI.SIZE_POLICY_RELATIVE, 0.4)
-- t:addColumn("Size", GUI.SIZE_POLICY_ABSOLUTE, 16)
-- t:addColumn("Type", GUI.SIZE_POLICY_ABSOLUTE, 10)

-- local colors1 = {
-- 	defaultBackground = nil,
-- 	defaultText = 0x3C3C3C,
-- 	alternativeBackground = 0xE1E1E1,
-- 	alternativeText = 0x3C3C3C,
-- 	selectionBackground = 0xCC2440,
-- 	selectionText = 0xFFFFFF,
-- }

-- local colors2 = {}
-- for key, value in pairs(colors1) do
-- 	colors2[key] = value
-- end
-- colors2.defaultText, colors2.alternativeText = 0xA5A5A5, 0xA5A5A5

-- for i = 1, 10 do
-- 	t:addRow(
-- 		GUI.tableTextCell(colors1, "Ehehehe " .. i),
-- 		GUI.tableTextCell(colors2, "12.02.2018"),
-- 		GUI.tableTextCell(colors2, "114.23 KB"),
-- 		GUI.tableTextCell(colors2, ".lua")
-- 	)
-- end

-- workspace:draw()
-- workspace:start()


---------------------------------------------------------------------------------------------------

return GUI
