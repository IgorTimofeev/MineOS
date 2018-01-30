
require("advancedLua")
local component = require("component")
local computer = require("computer")
local keyboard = require("keyboard")
local fs = require("filesystem")
local unicode = require("unicode")
local event = require("event")
local color = require("color")
local image = require("image")
local buffer = require("doubleBuffering")

--------------------------------------------------------------------------------------------

local GUIAlignment = {
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

local GUIDirections = enum(
	"horizontal",
	"vertical"
)

--------------------------------------------------------------------------------------------

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

local function GUIObject(x, y, width, height)
	return {
		x = x,
		y = y,
		width = width,
		height = height,
		isClicked = objectIsClicked,
		draw = objectDraw
	}
end

--------------------------------------------------------------------------------------------

local function GUISetAlignment(object, horizontalAlignment, verticalAlignment)
	object.alignment = {
		horizontal = horizontalAlignment,
		vertical = verticalAlignment
	}

	return object
end

local function GUIGetAlignmentCoordinates(object, subObject)
	local x, y
	if object.alignment.horizontal == GUIAlignment.horizontal.left then
		x = object.x
	elseif object.alignment.horizontal == GUIAlignment.horizontal.center then
		x = math.floor(object.x + object.width / 2 - subObject.width / 2)
	elseif object.alignment.horizontal == GUIAlignment.horizontal.right then
		x = object.x + object.width - subObject.width
	else
		error("Unknown horizontal alignment: " .. tostring(object.alignment.horizontal))
	end

	if object.alignment.vertical == GUIAlignment.vertical.top then
		y = object.y
	elseif object.alignment.vertical == GUIAlignment.vertical.center then
		y = math.floor(object.y + object.height / 2 - subObject.height / 2)
	elseif object.alignment.vertical == GUIAlignment.vertical.bottom then
		y = object.y + object.height - subObject.height
	else
		error("Unknown vertical alignment: " .. tostring(object.alignment.vertical))
	end

	return x, y
end

local function GUIGetMarginCoordinates(object)
	local x, y = object.x, object.y

	if object.alignment.horizontal == GUIAlignment.horizontal.left then
		x = x + object.margin.horizontal
	elseif object.alignment.horizontal == GUIAlignment.horizontal.right then
		x = x - object.margin.horizontal
	end

	if object.alignment.vertical == GUIAlignment.vertical.top then
		y = y + object.margin.vertical
	elseif object.alignment.vertical == GUIAlignment.vertical.bottom then
		y = y - object.margin.vertical
	end

	return x, y
end

--------------------------------------------------------------------------------------------

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
		object.parent.children[index], object.parent.children[index + 1] = object.parent.children[index + 1], object.parent.children[index]
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

--------------------------------------------------------------------------------------------

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
	local animation = {
		object = object,
		position = 0,
		start = containerObjectAnimationStart,
		stop = containerObjectAnimationStop,
		delete = containerObjectAnimationDelete,
		frameHandler = frameHandler,
		onFinish = onFinish,
	}

	local firstParent = object:getFirstParent()
	firstParent.animations = firstParent.animations or {}
	table.insert(firstParent.animations, animation)

	return animation
end

local function GUIAddChildToContainer(container, object, atIndex)
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

local function GUIDrawContainerContent(container)
	local R1X1, R1Y1, R1X2, R1Y2, child = buffer.getDrawLimit()
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
		
		for i = 1, #container.children do
			child = container.children[i]
			
			if not child.hidden then
				child.x, child.y = container.x + child.localX - 1, container.y + child.localY - 1
				child:draw()
			end
		end

		buffer.setDrawLimit(R1X1, R1Y1, R1X2, R1Y2)
	end

	return container
end

local function containerHandler(isScreenEvent, mainContainer, currentContainer, eventData, intersectionX1, intersectionY1, intersectionX2, intersectionY2)
	local breakRecursion, child = false

	if not isScreenEvent or intersectionX1 and eventData[3] >= intersectionX1 and eventData[4] >= intersectionY1 and eventData[3] <= intersectionX2 and eventData[4] <= intersectionY2 then
		for i = #currentContainer.children, 1, -1 do
			child = currentContainer.children[i]

			if not child.hidden then
				if child.children then
					local newIntersectionX1, newIntersectionY1, newIntersectionX2, newIntersectionY2 = getRectangleIntersection(
						intersectionX1,
						intersectionY1,
						intersectionX2,
						intersectionY2,
						child.x,
						child.y,
						child.x + child.width - 1,
						child.y + child.height - 1
					)

					if newIntersectionX1 then
						if containerHandler(isScreenEvent, mainContainer, child, eventData, newIntersectionX1, newIntersectionY1, newIntersectionX2, newIntersectionY2) then
							breakRecursion = true
							break
						end
					end
				else
					if isScreenEvent then
						if child:isClicked(eventData[3], eventData[4]) then
							if child.eventHandler then child.eventHandler(mainContainer, child, eventData) end
							breakRecursion = true
							break
						end
					else
						if child.eventHandler then child.eventHandler(mainContainer, child, eventData) end
					end
				end
			end
		end

		if currentContainer.eventHandler then currentContainer.eventHandler(mainContainer, currentContainer, eventData) end
	end

	if breakRecursion then
		return true
	end
end

local function containerStartEventHandling(container, eventHandlingDelay)
	container.eventHandlingDelay = eventHandlingDelay

	local eventData, animationIndex, animation, animationOnFinishMethods
	repeat
		eventData = { event.pull(container.animations and 0 or container.eventHandlingDelay) }
		
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
			animationIndex, animationOnFinishMethods = 1, {}

			-- Продрачиваем анимации и вызываем обработчики кадров
			while animationIndex <= #container.animations do
				animation = container.animations[animationIndex]

				if animation.deleteLater then
					table.remove(container.animations, animationIndex)
					if #container.animations == 0 then
						container.animations = nil
						break
					end
				else
					if animation.started then
						animationNeedDraw = true
						animation.position = (computer.uptime() - animation.startUptime) / animation.duration
						
						if animation.position < 1 then
							animation.frameHandler(container, animation)
						else
							animation.position = 1
							animation.started = false
							animation.frameHandler(container, animation)
							
							if animation.onFinish then
								table.insert(animationOnFinishMethods, animation)
							end
						end
					end

					animationIndex = animationIndex + 1
				end
			end

			-- По завершению продрочки отрисовываем изменения на экране
			container:draw()
			buffer.draw()

			-- Вызываем поочередно все методы .onFinish
			for i = 1, #animationOnFinishMethods do
				animationOnFinishMethods[i].onFinish(container, animationOnFinishMethods[i])
			end
		end
	until container.dataToReturn

	local dataToReturn = container.dataToReturn
	container.dataToReturn = nil
	return table.unpack(dataToReturn)
end

local function containerReturnData(container, ...)
	container.dataToReturn = {...}
end

local function containerStopEventHandling(container)
	containerReturnData(container, nil)
end

local function GUIContainer(x, y, width, height)
	local container = GUIObject(x, y, width, height)

	container.children = {}
	container.draw = GUIDrawContainerContent
	container.deleteChildren = deleteContainersContent
	container.addChild = GUIAddChildToContainer
	container.returnData = containerReturnData
	container.startEventHandling = containerStartEventHandling
	container.stopEventHandling = containerStopEventHandling

	return container
end

local function GUIFullScreenContainer()
	return GUIContainer(1, 1, buffer.getResolution())
end

--------------------------------------------------------------------------------------------

return 





