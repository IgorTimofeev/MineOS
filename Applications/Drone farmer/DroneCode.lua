
local position = {x = 0, y = 0, z = 0}
local rotation = 0
local movePrecision = 0.5

------------------------------------------------------------------------------------

local function sleep(timeout)
	local deadline = computer.uptime() + (timeout or 0)
	while computer.uptime() < deadline do
		computer.pullSignal(deadline - computer.uptime())
	end
end

local function absoluteSwing(...)
	while true do
		local success, reason = drone.swing(...)
		if success or reason == "air" then break end
	end
end

local function absoluteMove(x, y, z)
	drone.move(x, y, z)
	while drone.getOffset() > movePrecision do
		sleep(0.05)
	end
	position.x, position.y, position.z = position.x + x, position.y + y, position.z + z
end

local function relativeMove(x, y, z)
	if rotation == 0 then
		absoluteMove(x, y, -z)
	elseif rotation == 1 then
		absoluteMove(z, y, x)
	elseif rotation == 2 then
		absoluteMove(-x, y, z)
	else
		absoluteMove(-z, y, -x)
	end
end

local function relativeSwing(preferredRotation)
	local front, right, back, left = 4, 2, 5, 3
	if rotation == 0 then
		front, right, back, left = 2, 5, 3, 4
	elseif rotation == 1 then
		front, right, back, left = 5, 3, 4, 2
	elseif rotation == 2 then
		front, right, back, left = 3, 4, 2, 5
	end

	absoluteSwing(select((preferredRotation or 0) + 1, front, right, back, left))
end

local function swingForward()
	relativeSwing(0)
end

local function moveForward(distance)
	relativeMove(0, 0, distance or 1)
end

local function moveBackward(distance)
	relativeMove(0, 0, distance and -distance or -1)
end

local function turnLeft()
	rotation = rotation - 1
	if rotation < 0 then rotation = 3 end
end

local function turnRight()
	rotation = rotation + 1
	if rotation > 3 then rotation = 0 end
end

local function moveToPoint(x, y, z)
	absoluteMove(x - position.x, y - position.y, z - position.z)
end

local function returnToStartPoint()
	moveToPoint(0, position.y, 0)
	moveToPoint(0, 0, 0)
end

------------------------------------------------------------------------------------

local fieldWidth = 18
local fieldHeight = 18

local function dropShitOnBase()
	returnToStartPoint()
	moveBackward(1)

	computer.beep(1500, 0.3)
	for slot = 1, drone.inventorySize() do
		drone.select(slot)
		drone.drop(0)
	end
	drone.select(1)
end

local function checkInventory()
	if drone.count(drone.inventorySize()) > 0 then
		local xOld, yOld, zOld = position.x, position.y, position.z
		dropShitOnBase()
		moveToPoint(xOld, yOld, zOld)
	end
end

local function doHeight()
	for y = 1, fieldHeight do
		swingForward()
		sleep(0.1)
		moveForward(1)
	end
	checkInventory()
end

local function doWidth()
	for x = 1, fieldWidth / 2 do
		doHeight()
		turnRight()
		swingForward()
		moveForward(1)
		turnRight()

		doHeight()
		turnLeft()
		swingForward()
		moveForward(1)
		turnLeft()
	end
end

rotation = 3
drone.setAcceleration(1)

absoluteMove(0, 0.5, 0)
doWidth()
dropShitOnBase()
returnToStartPoint()








