local ecs = require("ECSAPI")
local fs = require("filesystem")
local event = require("event")
local component = require("component")
local gpu = component.gpu

--Список месяцев
local months = {
  "Январь",
  "Февраль",
  "Март",
  "Апрель",
  "Май",
  "Июнь",
  "Июль",
  "Август",
  "Сентябрь",
  "Октябрь",
  "Ноябрь",
  "Декабрь",
}

--Количество дней в месяцах
local countOfDays = {
  31,
  28,
  31,
  30,
  31,
  30,
  31,
  31,
  30,
  31,
  30,
  31,
}

--Сдвиг дня недели по дате в каждом месяце
local monthDateMove = {
  3,
  2,
  3,
  2,
  3,
  2,
  3,
  3,
  2,
  3,
  2,
  3,
}

--Графика
local numbers = {
  ["1"] = {
    {0, 1, 0},
    {0, 1, 0},
    {0, 1, 0},
    {0, 1, 0},
    {0, 1, 0},
  },
  ["2"] = {
    {1, 1, 1},
    {0, 0, 1},
    {1, 1, 1},
    {1, 0, 0},
    {1, 1, 1},
  },
  ["3"] = {
    {1, 1, 1},
    {0, 0, 1},
    {1, 1, 1},
    {0, 0, 1},
    {1, 1, 1},
  },
  ["4"] = {
    {1, 0, 1},
    {1, 0, 1},
    {1, 1, 1},
    {0, 0, 1},
    {0, 0, 1},
  },
  ["5"] = {
    {1, 1, 1},
    {1, 0, 0},
    {1, 1, 1},
    {0, 0, 1},
    {1, 1, 1},
  },
  ["6"] = {
    {1, 1, 1},
    {1, 0, 0},
    {1, 1, 1},
    {1, 0, 1},
    {1, 1, 1},
  },
  ["7"] = {
    {1, 1, 1},
    {0, 0, 1},
    {0, 0, 1},
    {0, 0, 1},
    {0, 0, 1},
  },
  ["8"] = {
    {1, 1, 1},
    {1, 0, 1},
    {1, 1, 1},
    {1, 0, 1},
    {1, 1, 1},
  },
  ["9"] = {
    {1, 1, 1},
    {1, 0, 1},
    {1, 1, 1},
    {0, 0, 1},
    {1, 1, 1},
  },
  ["0"] = {
    {1, 1, 1},
    {1, 0, 1},
    {1, 0, 1},
    {1, 0, 1},
    {1, 1, 1},
  },
}

--Всякие переменные
local constants = {
  xSpaceBetweenNumbers = 2,
  ySpaceBetweenNumbers = 1,
  xSpaceBetweenMonths = 4,
  ySpaceBetweenMonths = 1,
  currentYear = 2015,
  currentMonth = 9,
  currentDay = 26,
  programYear = 2015,
  programMonth = 1,
  proramDay = 1,
  usualDayColor = 0x262626,
  weekendColor = 0x880000,
  backgroundColor = 0xEEEEEE,
  dayNamesColor = 0x888888,
  monthsColor = 0xCC0000,
  currentDayColor = 0xFFFFFF,
  bigNumberColor = 0x262626,
}

--Объекты для тача
local obj = {}
local function newObj(class, name, ...)
  obj[class] = obj[class] or {}
  obj[class][name] = {...}
end

--Проверка года на "високосность"
local function visokosniy(year)
  if year % 4 == 0 or year % 400 == 0 then return true else return false end
end

--Отрисовать месяц
local function drawMonth(x, y, firstDay, countOfDays, year, month)

  local xPos, yPos = x, y + 4
  local counter = 1
  local startDrawing = false
  local separator = string.rep(" ", constants.xSpaceBetweenNumbers)
  ecs.colorText(x, y, constants.monthsColor, months[month])
  ecs.colorText(x, y + 2, constants.dayNamesColor,"Пн"..separator.."Вт"..separator.."Ср"..separator.."Чт"..separator.."Пт"..separator.."Сб"..separator.."Вс")
  for j = 1, 6 do
    xPos = x
    for i = 1, 7 do
      if i < 6 then gpu.setForeground(constants.usualDayColor) else gpu.setForeground(constants.weekendColor) end
      if counter == constants.currentDay and year == constants.currentYear and month == constants.currentMonth then ecs.square(xPos-1, yPos, 4, 1, constants.weekendColor); gpu.setForeground(constants.currentDayColor) else gpu.setBackground(constants.backgroundColor) end
      if counter > countOfDays then break end
      if i >= firstDay then startDrawing = true end
      if startDrawing then gpu.set(xPos, yPos, tostring(counter)); counter = counter + 1 end
      xPos = xPos + constants.xSpaceBetweenNumbers + 2
    end
    yPos = yPos + constants.ySpaceBetweenNumbers + 1
  end
end

--Получить номер следующего дня
local function getNextDay(day)
  if day < 7 then
    return (day + 1)
  else
    return 1
  end
end

--Просчитать данные о годе
local function calculateYear(year, dayOf1Jan)
  local massivGoda = {}
  local visokosniy = visokosniy(year)

  local firstDayPosition = dayOf1Jan

  --Получаем количество дней в каждом месяце
  for month = 1, 12 do
    --Создаем подмассив месяца в массиве года
    massivGoda[month] = {}
    --Если это февраль
    if month == 2 then
      --Если год високосный
      if visokosniy then
        massivGoda[month].countOfDays = 29
        massivGoda[month].firstDayPosition = firstDayPosition
        firstDayPosition = getNextDay(firstDayPosition)
      --Если не високосный
      else
        massivGoda[month].countOfDays = 28
        massivGoda[month].firstDayPosition = firstDayPosition
      end
    --Если не февраль
    else
      massivGoda[month].countOfDays = countOfDays[month]
      massivGoda[month].firstDayPosition = firstDayPosition
      for i = 1, monthDateMove[month] do
        firstDayPosition = getNextDay(firstDayPosition)
      end
    end
  end

  return massivGoda
end

--Получить день недели первого января указанного года
local function polu4itDenNedeliPervogoJanvarja(year, debug)
  local den = 0

  local difference = math.abs(year - 1010)
  local koli4estvoVisokosnih
  
  if difference % 4 == 0 then
    koli4estvoVisokosnih = difference / 4
  elseif difference % 4 == 1 then
    koli4estvoVisokosnih = math.floor(difference / 4)
  elseif difference % 4 == 2 then
    koli4estvoVisokosnih = math.floor(difference / 4)
  elseif difference % 4 == 3 then
    koli4estvoVisokosnih = math.floor(difference / 4) + 1
  end

  local sdvig = difference + koli4estvoVisokosnih

  if sdvig % 7 == 0 then
    den = 1
  else
    den = sdvig % 7 + 1
  end

  if debug then
    print("Год: "..year)
    print("Разница в годах: "..difference)
    print("Кол-во високосных: "..koli4estvoVisokosnih)
    print("Сдвиг по дням: "..sdvig)
    print("День недели: "..den)
    print(" ")
  end

  return den
end

--Нарисовать календарь
local function drawCalendar(xPos, yPos, year)
  ecs.square(xPos, yPos, 120, 48, constants.backgroundColor)
  --Получаем позицию первого января указанного года
  local janFirst = polu4itDenNedeliPervogoJanvarja(year)
  --Получаем массив года
  local massivGoda = calculateYear(year, janFirst)

  --Перебираем массив года
  for i = 1, #massivGoda do
    --Рисуем месяц
    drawMonth(xPos, yPos, massivGoda[i].firstDayPosition, massivGoda[i].countOfDays, year, i)
    --Корректируем коорды
    xPos = xPos + constants.xSpaceBetweenMonths + 27
    if i % 4 == 0 then xPos = 2; yPos = yPos + constants.ySpaceBetweenMonths + 15 end
  end
end

local function drawSymbol(x, y, symbol)
  local xPos, yPos = x, y
  for j = 1, #numbers[symbol] do
    xPos = x
    for i = 1, #numbers[symbol][j] do
      if numbers[symbol][j][i] ~= 0 then
        gpu.set(xPos, yPos, "  ")
      end
      xPos = xPos + 2
    end
    yPos = yPos + 1
  end
end

local function drawYear(x, y, year)
  year = tostring(year)
  for i = 1, #year do
    drawSymbol(x, y, string.sub(year, i, i))
    x = x + 8
  end
end

local next, prev

local function drawInfo()
  local xPos, yPos = 127, 4
  ecs.square(xPos, yPos, 30, 5, constants.backgroundColor)
  gpu.setBackground(constants.bigNumberColor)
  drawYear(xPos, yPos, constants.programYear)
  yPos = yPos + 6

  local name = "Следующий год"; newObj("Buttons", name, ecs.drawButton(xPos, yPos, 30, 3, name, 0xDDDDDD, 0x262626)); yPos = yPos + 4
  name = "Предыдущий год"; newObj("Buttons", name, ecs.drawButton(xPos, yPos, 30, 3, name, 0xDDDDDD, 0x262626)); yPos = yPos + 4
  name = "Выйти"; newObj("Buttons", name, ecs.drawButton(xPos, yPos, 30, 3, name, 0xDDDDDD, 0x262626)); yPos = yPos + 4

end

local function drawAll()
  --Очищаем экран
  ecs.prepareToExit(constants.backgroundColor)
  --Рисуем календарик
  drawCalendar(2, 2, constants.programYear)
  --Рисуем парашу
  drawInfo()
end

--------------------------------------------------------------------------------------------------------------------

--Проверяем соответствие системным требованиям
local xMax, yMax = gpu.maxResolution()
if xMax < 150 then error("This program requires Tier 3 GPU and Tier 3 Screen.") end
--Запоминаем старое разрешение экрана
local xOld, yOld = gpu.getResolution()
--Ставим максимальное
gpu.setResolution(xMax, yMax)
--Получаем данные о текущей дате (os.date выдает неверную дату и месяц, забавно)
constants.currentDay, constants.currentMonth, constants.currentYear = ecs.getHostTime(2)
constants.programDay, constants.programMonth, constants.programYear = constants.currentDay, constants.currentMonth, constants.currentYear 
--Рисуем все
drawAll()

while true do
  local e = {event.pull()}
  if e[1] == "touch" then
    for key in pairs(obj["Buttons"]) do
      if ecs.clickedAtArea(e[3], e[4], obj["Buttons"][key][1], obj["Buttons"][key][2], obj["Buttons"][key][3], obj["Buttons"][key][4]) then
        ecs.drawButton(obj["Buttons"][key][1], obj["Buttons"][key][2], 30, 3, key, constants.weekendColor, constants.currentDayColor)
        os.sleep(0.2)

        if key == "Следующий год" then
          constants.programYear = constants.programYear + 1
        elseif key == "Предыдущий год" then
          constants.programYear = constants.programYear - 1
        elseif key == "Выйти" then
          gpu.setResolution(xOld, yOld)
          ecs.prepareToExit()
          return
        end

        drawInfo()
        drawCalendar(2, 2, constants.programYear)

        break
      end
    end
  end
end








