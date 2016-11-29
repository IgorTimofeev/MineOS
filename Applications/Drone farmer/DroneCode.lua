
dronePosition = {relative = {}, absolute = {}}

local function setRelativePosition(x, y, z)
	dronePosition.relative.x, dronePosition.relative.y, dronePosition.relative.z = x, y, z
end

local function move(x, y, z)
	drone.move(x, y, z)
	while drone.getOffset() > 0.5 do
		sleep(0.05)
	end
	setRelativePosition(dronePosition.relative.x + x, dronePosition.relative.y + y, dronePosition.relative.z + z)
end

local function swing(...)
	while true do
		local success, reason = drone.swing(...)
		if success or reason == "air" then break end
	end
end

local function moveToRelativePosition(x, y, z)
	move(x - dronePosition.relative.x, y - dronePosition.relative.y, z - dronePosition.relative.z)
end

local function getRelativePosition()
	return {x = dronePosition.relative.x, y = dronePosition.relative.y, z = dronePosition.relative.z}
end

local function returnToStartPoint()
	moveToRelativePosition(0, dronePosition.relative.y, 0)
	moveToRelativePosition(0, 0, 0)
end

local function dropShitOnBase()
	returnToStartPoint()
	computer.beep(1500, 0.5)
	move(-2, 0, 0)
	for slot = 1, drone.inventorySize() do
		drone.select(slot)
		drone.drop(0)
	end
	drone.select(1)
end

-----------------------------------------

local function checkInventory()
	if drone.count(drone.inventorySize()) > 0 then
		local oldPosition = getRelativePosition()
		dropShitOnBase()
		move(0, 2, 0)
		moveToRelativePosition(oldPosition.x, oldPosition.y, oldPosition.z)
	end
end

local fieldWidth, fieldHeight = 26, 26
setRelativePosition(0, 0, 0)
drone.setAcceleration(0.8)
move(0, 1, 0)

local function doHeight(side, moveMode)
	for y = 1, fieldHeight do
		swing(side)
		move(moveMode, 0, 0)
	end
	checkInventory()
end

local function doWidth()
	for x = 1, fieldWidth / 2 do
		doHeight(5, 1)
		drone.swing(3)
		move(0, 0, 1)
		doHeight(4, -1)
		drone.swing(3)
		move(0, 0, 1)
	end
end

doWidth()
dropShitOnBase()
moveToRelativePosition(0, 0, 0)








