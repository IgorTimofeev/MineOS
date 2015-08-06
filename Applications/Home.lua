local c = require("component")
local computer = require("computer")
local event = require("event")
local ecs = require("ECSAPI")
local colors = require("colors")
local sides = require("sides")
local config = require("config")
local fs = require("filesystem")
local rs = c.redstone
local gpu = c.gpu
local modem = c.modem

modem.open(512)

---------------------------------------------------------------------

local pathToWhitelist = "System/Home/whitelist.txt"
local pathToDoors = "System/Home/doors.txt"

local whitelist
local doors

if not fs.exists(pathToWhitelist) then
  fs.makeDirectory(fs.path(pathToWhitelist))
  config.write(pathToWhitelist, "Igor_Timofeev", "owner")
end

if not fs.exists(pathToDoors) then
  config.write(pathToDoors, "3b1ea", colors.lightblue)
  config.write(pathToDoors, "9d482", colors.yellow)
  doors = config.readAll(pathToDoors)
end

whitelist = config.readAll(pathToWhitelist)
doors = config.readAll(pathToDoors)

------------------------------------------------------------------------

local redstoneSide = sides.bottom

local xScale, yScale = 40, 20
local xSize, ySize = gpu.getResolution()

local doorTimer = 3

local buttons = {{false, 0x444444, colors.lightblue}, {false, 0x444444, colors.black}, {false, 0x444444, colors.brown}, {true, ecs.colors.green, colors.pink}, {true, ecs.colors.green, colors.red}, {true, ecs.colors.green, colors.orange}}

local killWireColor = colors.blue

---------------------------------------

local obj = {}
local function newObj(class, name, ...)
  obj[class] = obj[class] or {}
  obj[class][name] = {...}
end

local function getScreens()
  local list = c.list()
  local screens = {}
  for key, val in pairs(list) do
    if val == "screen" then
      screens[key] = {val, c.isPrimary(key)}
    end
  end
  return screens
end

local function clearMonitor(backColor, frontColor, text)
  gpu.setBackground(backColor)
  local xSize, ySize = gpu.getResolution()
  gpu.fill(1, 1, xSize, ySize, " ")
  gpu.setForeground(frontColor)
  ecs.centerText("xy", 1, text)
end

local screens = getScreens()
local primaryScreen = c.getPrimary("screen").address

local function bind(address)
  if address then
    gpu.bind(address)
    gpu.setResolution(xScale, yScale)
  else
    gpu.bind(primaryScreen)
    gpu.setResolution(xSize, ySize)
  end
end

local function checkNick(nick)
  for key, val in pairs(whitelist) do
    if key == nick then return true end
  end
  return false 
end

--DOORS

local function door(which, open)
  
  local color = 0
  local address
  for key, val in pairs(doors) do
    address = c.get(key, "screen")
    if address == which then
       color = tonumber(val)
       break
    end
  end


  if open then
    rs.setBundledOutput(redstoneSide, color, 100)
  else
    rs.setBundledOutput(redstoneSide, color, 0)
  end
end

local function openAllDoors(open)
  local color
  for key, val in pairs(doors) do
    color = tonumber(val)
    if open then
      rs.setBundledOutput(redstoneSide, color, 100)
    else
      rs.setBundledOutput(redstoneSide, color, 0)
    end
  end
end

local function mini()
  clearMonitor(0xffffff, 0x444444, "Приложите палец для идентификации")
end

local function infa()
  gpu.setBackground(0xffffff)
  gpu.setForeground(0x444444)

  local yPos = ySize - 3
  if c.isAvailable("mfsu") then ecs.centerText("x", yPos, "Заряд МФСУ: "..c.mfsu.getStored()); yPos = yPos + 1 end
  if c.isAvailable("reactor") then ecs.centerText("x", yPos, "Нагрев реактора: "..math.ceil(c.reactor.getHeat() / c.reactor.getMaxHeat() * 100).."%"); yPos = yPos + 1 end
  if c.isAvailable("reactor_chamber") then ecs.centerText("x", yPos, "Нагрев реактора: "..math.ceil(c.reactor_chamber.getHeat() / c.reactor_chamber.getMaxHeat() * 100).."%"); yPos = yPos + 1 end
end

local function main()
  gpu.setBackground(0xffffff)
  gpu.fill(1, 1, xSize, ySize, " ")
  
  local yCenter = math.floor(ySize / 2)
  local yPos = yCenter - 12
  newObj("buttons", 1, ecs.drawAdaptiveButton("auto", yPos, 3, 1, "Открыть двери", buttons[1][2] or 0x444444, 0xffffff)); yPos = yPos + 4
  newObj("buttons", 2, ecs.drawAdaptiveButton("auto", yPos, 3, 1, "Фабрика материи", buttons[2][2] or 0x444444, 0xffffff)); yPos = yPos + 4
  newObj("buttons", 3, ecs.drawAdaptiveButton("auto", yPos, 3, 1, "Управление реактором", buttons[3][2] or 0x444444, 0xffffff)); yPos = yPos + 4
  newObj("buttons", 4, ecs.drawAdaptiveButton("auto", yPos, 3, 1, "Свет на втором этаже", buttons[4][2] or 0x444444, 0xffffff)); yPos = yPos + 4
  newObj("buttons", 5, ecs.drawAdaptiveButton("auto", yPos, 3, 1, "Свет на первом этаже", buttons[5][2] or 0x444444, 0xffffff)); yPos = yPos + 4
  newObj("buttons", 6, ecs.drawAdaptiveButton("auto", yPos, 3, 1, "Свет в шахте", buttons[6][2] or 0x444444, 0xffffff)); yPos = yPos + 4

  infa()
end

local function redstoneRecontrol()
  for i = 1, #buttons do
    if buttons[i][1] then
      rs.setBundledOutput(redstoneSide, buttons[i][3], 100)
    else
      rs.setBundledOutput(redstoneSide, buttons[i][3], 0)
    end
  end
end

local function killThemAll()
  ecs.square(1, 1, xSize, ySize, 0xff0000)
  gpu.setForeground(0xffffff)
  ecs.centerText("xy", 1, "KILL THEM ALL!")
  rs.setBundledOutput(redstoneSide, killWireColor, 100)
  os.sleep(2)
  rs.setBundledOutput(redstoneSide, killWireColor, 0)
  main("Помещение очищено от всего живого.")
end

local function switchButton(key, buttonColor)
  if buttons[key][1] then
    buttons[key][1] = false
    buttons[key][2] = 0x444444
  else
    buttons[key][1] = true
    buttons[key][2] = buttonColor or ecs.colors.green
  end
end

-----------------------------------------

main("Ничего интересного.")

for key, val in pairs(screens) do
  if not val[2] then
    bind(key)
    mini()
    bind()
  end
end

while true do
  local e = {event.pull()}
  if e[1] == "touch" then

    --ЕСЛИ КЛИКНУТО НА ГЛАВНОМ МОНИКЕ
    if e[2] == primaryScreen then
      for key, val in pairs(obj["buttons"]) do
        if ecs.clickedAtArea(e[3], e[4], obj["buttons"][key][1], obj["buttons"][key][2], obj["buttons"][key][3], obj["buttons"][key][4]) then
	  local color
	  if key == 3 then color = ecs.colors.red end
	  switchButton(key, color)
          main("Изменен параметр кнопки "..tostring(key).." на "..tostring(buttons[key][1]))
          if key == 1 then
            openAllDoors(buttons[key][1])
          else
            redstoneRecontrol()
          end
          break
        end
      end

    --ЕСЛИ КЛИКНУТО НА КАКОМ-ТО ЛЕВОМ МОНИКЕ
    else
      bind(e[2])

      if checkNick(e[6]) then
        clearMonitor(0x44ff44, 0xffffff,  "С возвращением, "..e[6].."!")
        door(e[2], true)
        os.sleep(doorTimer)
        door(e[2], false)
        mini()
        bind()
        main(e[6].." вернулся в нашу скромную обитель!")
      else
        clearMonitor(0xff0000, 0xffffff, "Недостойным дороги нет.")
        bind()
        killThemAll()
        bind(e[2])
        os.sleep(doorTimer)
        mini()
        bind()
        main(e[6].." попытался зайти в дом. Убей его. Убей чужака!")
      end
    end

    infa()
  elseif e[1] == "modem_message" then
    if e[6] == "killThemAll!" then
      killThemAll()
    elseif e[6] == "openAllDoors" then
        switchButton(1)
	openAllDoors(buttons[1][1])
	main("Двери открыты!")
    end
  elseif e[1] == "key_down" then
    if e[4] == 28 then
      killThemAll()
    end
  end
end
