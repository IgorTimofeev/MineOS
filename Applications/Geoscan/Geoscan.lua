local c = require("component")
local event = require("event")
local geo, holo
local gpu = c.gpu
local ecs = require("ECSAPI")
local palette = require("palette")
local computer = require("computer")

local args = {...}

--Проверка на наличие нужных устройств
if not c.isAvailable("geolyzer") or not c.isAvailable("hologram") then
  ecs.error("Подключите геоанализатор и голографический проектор 2-ого уровня")
  return
else
  geo = c.geolyzer
  holo = c.hologram
end

-------------------------

local massiv = {}

local yModifyer = -20
local scales = {0.33, 0.75, 1, 1.5, 2, 2.5, 3}
local currentScale = 1
local countOfScales = #scales

local xScanFrom = tonumber(args[1]) or -24
local xScanTo = tonumber(args[2]) or 23
local zScanFrom, zScanTo = xScanFrom, xScanTo

local xSize, ySize = gpu.getResolution()
local yCenter = math.floor(ySize / 2)

---------------------------------------

local function clear()
  holo.clear()
end

local function getMemory()
  local totalMemory = computer.totalMemory() /  1024
  local freeMemory = computer.freeMemory() / 1024
  local usedMemory = totalMemory - freeMemory

  local stro4ka = math.ceil(usedMemory).."/"..math.floor(totalMemory).."KB"

  totalMemory, freeMemory, usedMemory = nil, nil, nil

  return stro4ka
end

local function changeScale()
  if currentScale < countOfScales then
    currentScale = currentScale + 1
  else
    currentScale = 1
  end

  holo.setScale(scales[currentScale])
end

local function displayRow(x, yModifyer, z,  tablica)
  local color
  for i = 1, #tablica do
    
    massiv[x][z][i] = math.ceil(massiv[x][z][i])
      
    if tablica[i] > 0 then
      
      color = 1

      if tablica[i] > 4 then
        color = 2
      end

      if tablica[i + yModifyer] then
        holo.set(xScanTo - x + 1, i + yModifyer, zScanTo - z + 1, color)
      end
    end
  end
  color = nil
  tablica = nil
end

local function displayAllRows()
  clear()
  for x, val in pairs(massiv) do
    for z, val2 in pairs(massiv[x]) do
      displayRow(x, yModifyer, z, val2)
    end
  end
end

local function scan()
  clear()
  ecs.clearScreen(0xffffff)
  local barWidth = math.floor(xSize / 3 * 2)
  local percent = 0
  local xBar, yBar = math.floor(xSize/2 - barWidth / 2), yCenter
  local countOfAll = (math.abs(xScanFrom) + math.abs(xScanTo) + 1) ^ 2

  local counter = 0
  for x = xScanFrom, xScanTo do
    massiv[x] = {}
    for z = zScanFrom, zScanTo do

      massiv[x][z] = geo.scan(x, z, true)
      for i = 1, #massiv[x][z] do
        displayRow(x, yModifyer, z, massiv[x][z])
      end
      percent = counter / countOfAll * 100
      ecs.progressBar(xBar, yBar, barWidth, 1, 0xcccccc, ecs.colors.blue, percent)
      gpu.setForeground(0x444444)
      gpu.setBackground(0xffffff)
      ecs.centerText("x", yBar + 1, "   Сканирование стека на x = "..x..", z = "..z.."   ")
      ecs.centerText("x", yBar + 3, "   "..math.floor(percent).."% завершено   ")
      ecs.centerText("x", yBar + 2, "   "..getMemory().." RAM   ")
      counter = counter + 1

    end
  end
end

local obj = {}
local function newObj(class, name, ...)
  obj[class] = obj[class] or {}
  obj[class][name] = {...}
end

local currentHoloColor = ecs.colors.lime

local function changeColorTo(color)
  currentHoloColor = color
  holo.setPaletteColor(1, color)
  holo.setPaletteColor(2, 0xffffff - color)
end


local function main()
  ecs.clearScreen(0xffffff)
  local yPos = yCenter - 14
  newObj("buttons", "Сканировать местность", ecs.drawAdaptiveButton("auto", yPos, 3, 1, "Сканировать местность", 0x444444, 0xffffff)); yPos = yPos + 4
  newObj("buttons", "Масштаб", ecs.drawAdaptiveButton("auto", yPos, 3, 1, "Масштаб", 0x444444, 0xffffff)); yPos = yPos + 4
  newObj("buttons", "Перерисовать голограмму", ecs.drawAdaptiveButton("auto", yPos, 3, 1, "Перерисовать голограмму", 0x444444, 0xffffff)); yPos = yPos + 4
  newObj("buttons", "+ 10 блоков", ecs.drawAdaptiveButton("auto", yPos, 3, 1, "+ 10 блоков", 0x444444, 0xffffff)); yPos = yPos + 4
  newObj("buttons", "- 10 блоков", ecs.drawAdaptiveButton("auto", yPos, 3, 1, "- 10 блоков", 0x444444, 0xffffff)); yPos = yPos + 4
  newObj("buttons", "Изменить цвет", ecs.drawAdaptiveButton("auto", yPos, 3, 1, "Изменить цвет", currentHoloColor, 0xffffff)); yPos = yPos + 4
  newObj("buttons", "Выйти", ecs.drawAdaptiveButton("auto", yPos, 3, 1, "Выйти", 0x666666, 0xffffff)); yPos = yPos + 4
  gpu.setBackground(0xffffff)
  gpu.setForeground(0x444444)
  ecs.centerText("x", yPos, "Модификатор высоты: "..yModifyer)
end

----------------------------

changeColorTo(0x009900)
changeScale()
main()

while true do
  local e = {event.pull()}
  if e[1] == "touch" then
    for key, val in pairs(obj["buttons"]) do
      if ecs.clickedAtArea(e[3], e[4], obj["buttons"][key][1], obj["buttons"][key][2], obj["buttons"][key][3], obj["buttons"][key][4]) then
        ecs.drawAdaptiveButton(obj["buttons"][key][1], obj["buttons"][key][2], 3, 1, key, ecs.colors.green, 0xffffff)
        os.sleep(0.3)
        if key == "Сканировать местность" then
          scan()
        elseif key == "Масштаб" then
          changeScale()
        elseif key == "Перерисовать голограмму" then
          displayAllRows()
        elseif key == "+ 10 блоков" then
          yModifyer = yModifyer - 10
        elseif key == "- 10 блоков" then
          yModifyer = yModifyer + 10
        elseif key == "Выйти" then
          ecs.prepareToExit()
          return 0
        elseif key == "Изменить цвет" then
          local color = palette.draw("auto", "auto", currentHoloColor)
          if color ~= nil then
            changeColorTo(color)
          end
        end
        main()
        break
      end
    end
  end
end
