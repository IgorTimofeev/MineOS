local ecs = require("ECSAPI")
local gpu = require("component").gpu

local arg = {...}
if arg[1] == "get" or arg[1] == "show" or arg[1] == "print" or arg[1] == "write" or arg[1] == "info" or arg[1] == "help" then
  local max1, max2 = gpu.maxResolution()
  local cur1, cur2 = gpu.getResolution()
  local scale = cur1/max1*100
  print(" ")
  print("Максимальное поддерживаемое разрешение: " .. max1 .. "x".. max2)
  print("Текущее разрешение: " .. cur1.."x"..cur2)
  print(" ")
  print("Масштаб: "..scale.."%")
  print(" ")
else
  ecs.setScale(tonumber(arg[1]) or 1, true)
end
