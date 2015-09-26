local gpu = component.gpu

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

local constants = {
  xSpaceBetweenNumbers = 2,
  ySpaceBetweenNumbers = 1,
  xSpaceBetweenMonths = 4,
  ySpaceBetweenMonths = 1,
  currentYear = 2015,
  currentMonth = 9,
  currentDay = 26,
  programYear = 2001,
  programMonth = 1,
  proramDay = 1,
  usualDayColor = 0x262626,
  weekendColor = 0x880000,
  backgroundColor = 0xEEEEEE,
  dayNamesColor = 0x888888,
  monthsColor = 0xCC0000,
  currentDayColor = 0xFFFFFF,
}

local function visokosniy(year)
  if year % 4 == 0 or year % 400 == 0 then return true else return false end
end

local function drawMonth(x, y, firstDay, countOfDays, year, month)
  local xPos, yPos = x, y + 4
  local counter = 1
  local startDrawing = false
  local separator = string.rep(" ", 2)
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

local function getNextDay(day)
  if day < 7 then
    return (day + 1)
  else
    return 1
  end
end

--2001 2007 2018 2029
--6 11 11


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

local function drawCalendar(xPos, yPos, year)
  --Очищаем экран
  ecs.prepareToExit(constants.backgroundColor)

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


--------------------------------------------------------------------------------------------------------------------

ecs.prepareToExit()
drawCalendar(2, 2, 2015)







