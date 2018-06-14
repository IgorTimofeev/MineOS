local component = require("component")
local robot = require("robot")

local args = {...}

local function printUsage()
  print("Usages:")
  print("exp")
  print("  Gets the current level.")
  print("exp <slot>")
  print("  Tries to consume an enchanted item to add")
  print("  expierence to the upgrade")
  print("  from the specified slot.")
  print("exp all")
  print("  from all slots.")
end

if component.isAvailable("experience") then
  local e = component.experience
  if #args == 0 then
    print("Level: "..e.level())
  elseif tonumber(args[1]) ~= nil then
    local slot = tonumber(args[1])
    robot.select(slot)
    io.write("Experience from slot "..slot.."... ")
    local success, msg = e.consume()
    if success then
      print("success.")
    else
      print("failed: "..msg)
    end
    robot.select(1)
  elseif string.lower(args[1]) == "all" then
    io.write("Experience from all slots... ")
    for i = 1, robot.inventorySize() do
      robot.select(i)
      e.consume()
    end
    robot.select(1)
    print("done.")
  else
    printUsage()
  end
else
  print("This program requires the experience upgrade to be installed.")
end
