local event = require("event")
local component = require("component")
local chat = component.chat_box
local cb = component.command_block
local unicode = require("unicode")
local gpu = component.gpu
local term = require("term")
local computer = require("computer")

local version = "v1.3"

-- Подключаем переменные с таблицами возможных значений мяу, мур и прочей хуеты
local meow = {
  ["мяу"] = true,
  ["meow"] = true,
  ["мяя"] = true,
  ["g"] = true
}

local slozhna = {
  ["сложна"] = true
}

local pidor = {
  ["кто пидор?"] = true
}

local perpid = {
  ["насколько процентов я пидор?"] = true
} 

local whitelist = {
  ["PaladinCVM"] = true,
  ["Tinrion"] = true,
  ["Pirnogion"] = true,
  ["ECS"] = true,
  ["MrHerobrine"] = true,
}

local random = math.random(0,100)

local xSize, ySize = gpu.getResolution()
gpu.setBackground(0x000000)
gpu.fill(1, 1, xSize, ySize, " ") -- Очищаем экран к хуям

term.setCursor(1, 1) -- Какая-то непонятная хуета, которая делает все заебись

gpu.setForeground(0x00ff1a)

-- Симуляция загрузки программы

computer.beep(600)
print("--Инициализирую МЯУ--")
os.sleep(0.3)

computer.beep(600)
print("--Инициализирую МУР--")
os.sleep(0.3)

computer.beep(600)
print("--Инициализирую ШШШ--")
os.sleep(0.3)

computer.beep(600)
print("--Инициализирую ГАВ--")
os.sleep(0.3)

computer.beep(600)
print("--Инициализирую СЛОЖНА--")
os.sleep(0.3)
computer.beep(600)

print("--Инициализирую ПИДОР--")
os.sleep(0.3)
computer.beep(600)

print("--Инициализирую процентное вычисление пидорства--")
os.sleep(0.5)

computer.beep(1000)
print("--ПОДГРУЖАЮ СПИСОК ИГРОКОВ В ВАЙТЛИСТЕ--")
os.sleep(0.2)
computer.beep(600, 0.5)
print(" ")

for k, v in pairs(whitelist) do
  print( "--" ..  k .. "--" )
end

print(" ")
os.sleep(0.5)

computer.beep(1000)
print("Мяу-генератор " .. version .. " -- Copyright 2016 (C) PaladinCVM")
print("Выражаем благодарность Pirnogion за неоценимую помощь в разработке.")
print("А также человеческое спасибо ECS за удаление говнокода и рефакторинг.")
print(" ")

chat.say("Мяу-генератор " .. version .. " инициализирован")

while true do
  local e = {event.pull()}

  if (e[1] == "chat_message") then
    local lowerMessage = unicode.lower(e[4])

    if whitelist[e[3]] then
      if string.find(lowerMessage, "мяу") then
        print("Вы мяукнули, " .. e[3])      

        cb.setCommand("/playsound mob.cat.meow @a")
        cb.executeCommand()
    
      elseif string.find(lowerMessage, "мур") or string.find(lowerMessage, "мрр") then
        print("Вы муркнули, " .. e[3])

        cb.setCommand("/playsound mob.cat.purreow @a")
        cb.executeCommand()
        
      elseif string.find(lowerMessage, "гав") then
        print("Вы гавкнули, " .. e[3])

        cb.setCommand("/playsound mob.wolf.bark @a")
        cb.executeCommand()

      elseif string.find(lowerMessage, "шшш") then
        print("Вы шикнули, " .. e[3])

        cb.setCommand("/playsound mob.cat.hiss @a")
        cb.executeCommand()

      elseif slozhna[ lowerMessage ] then
        print(e[3] .. " нихуя не понимает, потому что сложна")

        chat.say("Сложна, блядь, сложна! Нихуя не понятна!")

      elseif pidor[ lowerMessage ] then
        print("Нарекаю " .. e[3] .. "'а пидором!")

        chat.say("Ты пидор, " .. e[3])
      
      elseif perpid[ lowerMessage ] then
        print(e[3] .. " - пидор на " .. random .. "%")

        chat.say(e[3] .. " - пидор на " .. random .. "%")
      end 
    end
  end
end