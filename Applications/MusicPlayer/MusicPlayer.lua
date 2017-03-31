--         Музыкальный проигрыватель v1.0
--         Автор: Руслан Исаев
-- 
--         vk.com/id181265169

--		   ИНСТРУКЦИЯ:
--		   1.Создаём текстовый файл
--		   2.Ебашим туда ноты
--		   Например:
--		   1500 1400 1500 1400 1500 1400 1500 1200 1000 2001 2001 900 900 950 1200 2001 2001 900 900 950 --		    1500 2001 2001
--		   1500 1400 1500 1400 1500 1400 1500 1200 1000

--		   И всё ёпта!
--		   Если написать 2001 то будет просто задержка,равная скорости воспроизведения(по умолчанию 0.1)
--		   Если что-то непонятно, писать в лс

local component = require("component")
local fs = require("filesystem")
local GUI = require("GUI")
local ecs = require("ECSAPI") --Знаю,что устарело,не надо ругаться
local MineOSCore = require("MineOSCore")

local data = {} --Потом будем загружать сюда файл.
local file = nil
local str = nil

local resourcesPath = MineOSCore.getCurrentApplicationResourcesDirectory() 
local localization = MineOSCore.getLocalization(resourcesPath .. "Localization/")

local function loadFile(filename)
  if fs.exists(filename) then
    file = io.open(filename,"r")--Открываем файл
    str = file:read("*all")
    for token in string.gmatch(str, "[^%s]+") do
      table.insert(data, tonumber(token))
    end
    file:close()
    return true
  else
    GUI.error("Non existing file",{title = {color = 0xFFDB40, text = "Warning"}})--СУКА!!!!
    return false
  end
end

local function play(speed)
  for i = 1,#data do --Для каждой ноты
    if data[i] == 2001 then
      os.execute("sleep " .. speed)
    end
    if data[i] ~= 2001 then
      component.computer.beep(data[i], speed)--Сделать звук
    end
  end
end

local data = ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x262626, localization.load}, {"EmptyLine"}, {"Input", 0x262626, 0x880000, localization.path}, {"EmptyLine"}, {"Button", {0xbbbbbb, 0xffffff, localization.play}})

loadFile(data[1])--Input
play(0.1)
