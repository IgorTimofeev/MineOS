local robot = component.proxy(component.list("robot")())
local redstone = component.proxy(component.list("redstone")())

local tryCatchTime = 20
local startSleepTime = 2
local catchSleepTime = 1
local side = 3

local function sleep(timeout)
  local deadline = computer.uptime() + (timeout or 0)
  while computer.uptime() < deadline do
    computer.pullSignal(deadline - computer.uptime())
  end
end

local function pushRod()
  robot.use(side)
  sleep(startSleepTime)
end

local function pullRod()
  robot.use(side)
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

