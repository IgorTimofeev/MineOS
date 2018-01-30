
require("advancedLua")
local computer = require("computer")
local component = require("component")
local fs = require("filesystem")
local buffer = require("doubleBuffering")
local GUI = require("GUI")
local unicode = require("unicode")
local image = require("image")
local color = require("color")
local MineOSCore = require("MineOSCore")

---------------------------------------------------------------------------------------------------------

local tankImages = {}
for i = 1, 4 do
	table.insert(tankImages, image.load("/Tanks/" .. i .. ".pic"))
end

local function newTank(x, y, rotation, speed)
	local object = GUI.object(x, y, 8, 4)
	
	object.type = "tank"
	object.controllable = false
	object.rotation = rotation
	object.speed = speed
	
	object.draw = function(object)
		buffer.image(object.x, object.y, tankImages[object.rotation])

		if object.controllable then
			buffer.frame(object.x - 1, object.y - 1, object.width + 2, object.height + 2, 0xFFFFFF)
		end
	end

	return object
end

---------------------------------------------------------------------------------------------------------

local function newBullet(x, y, rotation, speed)
	local object = GUI.object(x, y, 1, 1)
	
	object.type = "bullet"
	object.rotation = rotation
	object.speed = speed
	
	object.draw = function(object)
		buffer.text(object.x, object.y, 0xFF0000, "*")
	end

	return object
end

---------------------------------------------------------------------------------------------------------

local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x1E1E1E))

local tanksContainer = mainContainer:addChild(GUI.container(1, 1, mainContainer.width, mainContainer.height))
for i = 1, 10 do
	tanksContainer:addChild(
		newTank(
			math.random(mainContainer.width - 8),
			math.random(mainContainer.height - 4),
			math.random(4),
			1
		)
	)
end

local myTank = tanksContainer.children[1]
myTank.controllable = true

local moveSpeed = 0
local lastComputerUptime = computer.uptime()

mainContainer.eventHandler = function(mainContainer, object, eventData)
	if eventData[1] == "touch" then
	elseif eventData[1] == "key_down" then
		if eventData[4] == 17 then
			myTank.rotation = 1
		elseif eventData[4] == 31 then
			myTank.rotation = 3
		elseif eventData[4] == 30 then
			myTank.rotation = 4
		elseif eventData[4] == 32 then
			myTank.rotation = 2
		elseif eventData[4] == 57 then
			tanksContainer:addChild(newBullet(myTank.x + 2, myTank.y + 2, myTank.rotation, 4))
		elseif eventData[4] == 42 then
			myTank.speed = myTank.speed == 0 and 1 or 0
		end
	end

	local computerUptime = computer.uptime()
	if computerUptime - lastComputerUptime > moveSpeed then
		local i = 1
		while i <= #tanksContainer.children do
			local child = tanksContainer.children[i]
			
			local function deleteBullet()
				if child.type == "bullet" then
					child:delete()
					i = i - 1
				end
			end

			if child.rotation == 1 then
				child.localY = child.localY - child.speed
				if child.localY <= 1 then
					deleteBullet()

					child.localY = 1
					child.rotation = math.random(4)
				end
			elseif child.rotation == 2 then
				child.localX = child.localX + child.speed * 2
				if child.localX + child.width - 1 >= tanksContainer.width then
					deleteBullet()

					child.localX = tanksContainer.width - child.width
					child.rotation = math.random(4)
				end
			elseif child.rotation == 3 then
				child.localY = child.localY + child.speed
				if child.localY + child.height - 1 >= tanksContainer.height then
					deleteBullet()

					child.localY = tanksContainer.height - child.height
					child.rotation = math.random(4)
				end
			else
				child.localX = child.localX - child.speed * 2
				if child.localX <= 1 then
					deleteBullet()

					child.localX = 1
					child.rotation = math.random(4)
				end
			end

			i = i + 1
		end

		lastComputerUptime = computerUptime
		mainContainer:draw()
		buffer.draw()
	end
end


---------------------------------------------------------------------------------------------------------

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling(0)



