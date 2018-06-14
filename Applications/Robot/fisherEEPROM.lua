
local robot = component.proxy(component.list("robot")())
local redstone = component.proxy(component.list("redstone")())
local gpu = component.proxy(component.list("gpu")())

local width, height = gpu.getResolution()
local tryCatchTime = 30
local startSleepTime = 3
local catchSleepTime = 3
local side = 0
local useTime = 1

local function print(text)
	gpu.copy(1, 1, width, height, 0, -1)
	gpu.set(1, height, text)
end

local function sleep(timeout)
	local deadline = computer.uptime() + (timeout or 0)
	while computer.uptime() < deadline do
		computer.pullSignal(deadline - computer.uptime())
	end
end

local function pushRod()
	print("Pushing rod...")
	robot.use(side, true, useTime)
	sleep(startSleepTime)
end

local function pullRod()
	print("Pulling rod...")
	robot.use(side, true, useTime)
	sleep(catchSleepTime)
end

pushRod()

while true do	
	local e = {computer.pullSignal(tryCatchTime)}
	if e[1] == "redstone_changed" then
		if e[5] == 0 then
			pullRod()
			pushRod()
		end
	elseif not e[1] then
		pullRod()
		pushRod()
	end
end

