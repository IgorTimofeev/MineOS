
local component = require("component")
local modem = component.modem
local event = require("event")
local keyboard = require("keyboard")
local port = 512
modem.open(port)

local keys = {
  [17] = "moveForward",
  [31] = "moveBack",
  [30] = "turnLeft",
  [32] = "turnRight",
  [42] = "moveDown",
  [57] = "moveUp",
  [46] = "changeColor",
  [18] = "OTSOS",
  [16] = "dropAll",
  [33] = "toggleLeash",
}

---------------------------------------------------------------------------------------------------------

print(" ")
print("Добро пожаловать в программу DroneGrief. Используйте клавиши W и S для перемещения дрона, а A и D для смены направления движения. По нажатию SHIFT дрон опустится ниже, а по SPACE - выше. Кнопка E заставит дрона высосать предметы из инвентаря под и над ним, а кнопка C сменит цвет его свечения. При скроллинге колесиком мыши изменяется скорость движения робота, а скроллинг с зажатым ALT изменяет его ускорение.")
print(" ")

---------------------------------------------------------------------------------------------------------

while true do
  local e = {event.pull()}
  if e[1] == "key_down" then
    if keys[e[4]] then
      print("Команда дрону: " .. keys[e[4]])
      modem.broadcast(port, "ECSDrone", keys[e[4]])
    end
  elseif e[1] == "scroll" then
    if e[5] == 1 then
      if keyboard.isAltDown() then
        modem.broadcast(port, "ECSDrone", "accelerationUp")
        print("Команда дрону: accelerationUp")
      else
        modem.broadcast(port, "ECSDrone", "moveSpeedUp")
        print("Команда дрону: moveSpeedUp")
      end
    else
      if keyboard.isAltDown() then
        modem.broadcast(port, "ECSDrone", "accelerationDown")
        print("Команда дрону: accelerationDown")
      else
        modem.broadcast(port, "ECSDrone", "moveSpeedDown")
        print("Команда дрону: moveSpeedDown")
      end
    end
  elseif e[1] == "modem_message" then
    if e[6] == "ECSDrone" and e[7] == "DroneInfo" then
      print(" ")
      print("Скорость дрона: " .. tostring(e[8]))
      print("Ускорение дрона: " .. tostring(e[9]))
      print("Направление дрона: " .. tostring(e[10]))
      print(" ")
    end
  end
end





