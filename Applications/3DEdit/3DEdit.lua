local c = require("component")
local gpu = c.gpu
local holo = c.hologram
local ecs = require("ECSAPI")
local event = require("event")

---------------

local model = {}

local xDraw, yDraw = 17, 2

local transparencyColors = {0xdddddd, 0xffffff}

--Призрачные слои внизу
local showFullProjection = true

local currentLayer = 1
local currentScale = 50

local colors = {0xff0000, 0x00ff00, 0x0000ff}
local currentColorPalette = 1

local maxHeight = 32
local maxWidth, maxLength = 48, 48

local oldResolution = {gpu.getResolution()}
gpu.setResolution(160, 50)
local xSize, ySize = gpu.getResolution()

---------------------------------------

--СОЗДАНИЕ ОБЪЕКТОВ
local obj = {}
local function newObj(class, name, ...)
  obj[class] = obj[class] or {}
  obj[class][name] = {...}
end

--Создать вообще пустой массив
local function createBlank()
  for x = 1, 48 do
    model[x] = {}
    for z = 1, 48 do
      model[x][z] = {}
      for y = 1, 32 do
        model[x][z][y] = nil
      end
    end
  end
end

--Прозрачная поебонька
local function drawTransparency()
  local line = ""
  for i = 1, (maxWidth / 2) do
    line = line .. "██  "
  end

  --Стартовый фон
  gpu.setBackground(transparencyColors[2])
  gpu.fill(xDraw, yDraw, maxWidth * 2, maxWidth, " ")

  --Кубики
  gpu.setForeground(transparencyColors[1])
  for i = 1, (maxWidth) do
    gpu.set(xDraw + (i % 2) * 2, yDraw + i - 1, line)
  end

  --Очистка хуйни справа
  gpu.setBackground(0x262626)
  gpu.fill(xDraw + maxWidth * 2, yDraw, 2, maxWidth, " ")

end

--░░
--Нарисовать конкретный слой
local function drawLayer(layer, symbol)
  if not symbol then symbol = "██" end

  if currentLayer > 1 and symbol ~= "░░" then
    for y = 1, currentLayer do
      drawLayer(y, "░░")
    end
  end

  for x = 1, 48 do
    for z = 1, 48 do
      if model[x][z][layer] then
        local xCoord = xDraw + x * 2 - 2
        local zCoord = yDraw + z - 1
        local fore = model[x][z][layer]

        local back

        if x % 2 == 0 then
          if z % 2 == 0 then
            back = transparencyColors[2]
          else
            back = transparencyColors[1]
          end
        else
          if z % 2 == 0 then
            back = transparencyColors[1]
          else
            back = transparencyColors[2]
          end
        end

        gpu.setForeground(fore)
        gpu.setBackground(back)
        gpu.set(xCoord, zCoord, symbol)
      end
    end
  end
end

--Мяу
local function convertScreenCoordToHoloCoords(x, z)
  x = math.floor((x - xDraw) / 2  + 1)
  z = z - yDraw + 1

  return x, z
end

--Установить пиксель на экране
local function setPixelOnScreen(x, z, color)
  --Рассчитываем смещение пикселя на экране
  local move = 0
  if x%2 == 0 then move = -1 end

  --Рисуем пиксель на экране
  ecs.square(x + move, z, 2, 1, color)

  --Запоминаем, че нарисовали
  local a, b = convertScreenCoordToHoloCoords(x + move, z)
  model[a][b][currentLayer] = color

  --И его же на голопроекторе
  holo.set(a, currentLayer, b, currentColorPalette)
end

local function redraw()
  drawTransparency()
  drawLayer(currentLayer)
end

local function changeScale(scale)
  scale = scale or 50

  local min, max = 0.33, 3
  local new = min + (scale - 1) * 0.0269696968

  new = tonumber(string.sub(tostring(new), 1, 4))
  holo.setScale(new)
end

local function toolbar()
  local widthOfToolbar = 30
  local xStartOfToolbar, yStartOfToolbar = xSize - widthOfToolbar + 1, 1

  local toolbarColor = 0xeeeeee
  local toolbarTextColor = 0x262626
  local toolbarLineColor = 0xaaaaaa
  local toolbarLineTextColor = 0xffffff
  local toolbarButtonColor = ecs.colors.blue
  local toolbarButtonTextColor = 0xffffff

  local function toolbarLine(y, text)
    ecs.square(xStartOfToolbar, y, widthOfToolbar, 1, toolbarLineColor)
    ecs.colorText(xStartOfToolbar + 1, y, toolbarLineTextColor, text)
  end

  --Фон тулбара самый главный
  ecs.square(xStartOfToolbar, yStartOfToolbar, widthOfToolbar, ySize, toolbarColor)

  local xPos, yPos = xStartOfToolbar + 5, 1
  local counter = 1
  local name

  --Слои
  toolbarLine(yPos, "Слои"); yPos = yPos + 2

  name = "-"; newObj("Buttons", counter, ecs.drawAdaptiveButton(xPos, yPos, 3, 1, name, toolbarButtonColor, toolbarButtonTextColor)); counter = counter + 1
  ecs.colorTextWithBack(obj["Buttons"][counter - 1][3] + 2, yPos + 1, toolbarTextColor, toolbarColor, " "..currentLayer.." ")
  name = "+"; newObj("Buttons", counter, ecs.drawAdaptiveButton(obj["Buttons"][counter - 1][3] + 7, yPos, 3, 1, name, toolbarButtonColor, toolbarButtonTextColor)); counter = counter + 1
 
  yPos = yPos + 4
  name = "Очистить"; newObj("Buttons", counter, ecs.drawAdaptiveButton(xPos, yPos, 6, 1, name, toolbarButtonColor, toolbarButtonTextColor)); counter = counter + 1
  yPos = yPos + 4
  name = "Залить"; newObj("Buttons", counter, ecs.drawAdaptiveButton(xPos, yPos, 7, 1, name, toolbarButtonColor, toolbarButtonTextColor)); counter = counter + 1

  yPos = yPos + 4

  --Масштаб
  toolbarLine(yPos, "Масштаб проектора"); yPos = yPos + 2

  name = "-"; newObj("Buttons", counter, ecs.drawAdaptiveButton(xPos, yPos, 3, 1, name, toolbarButtonColor, toolbarButtonTextColor)); counter = counter + 1
  ecs.colorTextWithBack(obj["Buttons"][counter - 1][3] + 2, yPos + 1, toolbarTextColor, toolbarColor, " "..currentScale.." ")
  name = "+"; newObj("Buttons", counter, ecs.drawAdaptiveButton(obj["Buttons"][counter - 1][3] + 7, yPos, 3, 1, name, toolbarButtonColor, toolbarButtonTextColor)); counter = counter + 1

  yPos = yPos + 4

  --Сохранение
  toolbarLine(yPos, "Сохранение и загрузка"); yPos = yPos + 2

  name = "Сохранить"; newObj("Buttons", counter, ecs.drawAdaptiveButton(xPos, yPos, 6, 1, name, toolbarButtonColor, toolbarButtonTextColor)); counter = counter + 1
  yPos = yPos + 4
  name = "Открыть"; newObj("Buttons", counter, ecs.drawAdaptiveButton(xPos, yPos, 7, 1, name, toolbarButtonColor, toolbarButtonTextColor)); counter = counter + 1
  yPos = yPos + 4
  name = "Выйти"; newObj("Buttons", counter, ecs.drawAdaptiveButton(xPos, yPos, 8, 1, name, toolbarButtonColor, toolbarButtonTextColor)); counter = counter + 1


  yPos = yPos + 4

  --Палитра
  toolbarLine(yPos, "Выбор цвета"); yPos = yPos + 2

  local x, y = xPos + 10, yPos + 4
  for i = 1, #colors do
    ecs.square(x, y, 6, 3, colors[#colors - i + 1])
    x = x - 3
    y = y - 2
  end

  yPos = yPos + 8

  --Инфа
  toolbarLine(yPos, " "); yPos = yPos + 1
  toolbarLine(yPos, "       Прожку накодил"); yPos = yPos + 1
  toolbarLine(yPos, "      vk.com/id7799889"); yPos = yPos + 1
  toolbarLine(yPos, " "); yPos = yPos + 1
  toolbarLine(yPos, "  Хочешь спиздить - пизди."); yPos = yPos + 1
  toolbarLine(yPos, " "); yPos = yPos + 1


end

local function swapColors()

  -- local tempColor = colors[1]
  -- colors[1] = colors[2]
  -- colors[2] = colors[3]
  -- colors[3] = tempColor

  for i = 1, 3 do
    holo.setPaletteColor(i, colors[i])
  end

  currentColorPalette = currentColorPalette + 1
  if currentColorPalette > 3 then currentColorPalette = 1 end

  toolbar()

end



--------------------------

holo.clear()
ecs.clearScreen(0x262626)
createBlank()
redraw()
toolbar()

while true do
  local e = {event.pull()}
  if e[1] == "touch" or e[1] == "drag"  then
    setPixelOnScreen(e[3], e[4], colors[1])
  elseif e[1] == "scroll" then
    if e[5] == 1 then
      if currentLayer < maxHeight then currentLayer = currentLayer + 1 end
    else
      if currentLayer > 1 then currentLayer = currentLayer - 1 end
    end

    toolbar()
  elseif e[1] == "key_down" then
    --пробельчик
    if e[4] == 57 then
      redraw()
    --бекспайс
    elseif e[4] == 14 then
      break
    --икс
    elseif e[4] == 45 then
      swapColors()
    elseif e[4] == 28 then
      currentScale = currentScale + 10
      if currentScale > 100 then currentScale = 10 end
      changeScale(currentScale)
      toolbar()
    end
  end
end

-------------

--event.pull("key_down")

gpu.setResolution(table.unpack(oldResolution))
ecs.prepareToExit()
