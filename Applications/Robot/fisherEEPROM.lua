local robot = component.proxy(component.list("robot")())
local redstone = component.proxy(component.list("redstone")())
local inventory_controller = component.list("inventory_controller")()
if inventory_controller then
  inventory_controller = component.proxy(inventory_controller)
else
  error("No inventory_controller")
end

local minDurability = 0.1
local tryCatchTime = 30
local startSleepTime = 2
local catchSleepTime = 0.5
local dropSide = 0
local pullSide = 3
local rodStorageSide = 1

local function sleep(timeout)
  local deadline = computer.uptime() + timeout
  while computer.uptime() < deadline do
    computer.pullSignal(deadline - computer.uptime())
  end
end

local function push()
  robot.use(pullSide)
  sleep(startSleepTime)
end

local function tool()
  for i = 2, 1, -1 do
    robot.select(i)
    robot.drop(dropSide)
  end

  local durability = robot.durability()
  if not durability or durability <= minDurability then
    robot.suck(rodStorageSide)
    inventory_controller.equip()
  end
end

local function pull()
  robot.use(pullSide)
  sleep(catchSleepTime)

  tool()
  push()
end

tool()
push()

while true do  
  local e = {computer.pullSignal(tryCatchTime)}
  if e[1] == "redstone_changed" then
    if e[5] == 0 then
      pull()
    end
  elseif not e[1] then
    pull()
  end
end