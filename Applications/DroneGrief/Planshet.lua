
local component = require("component")
local modem = component.modem
local event = require("event")
local port = 512
modem.open(port)

local keys = {
  [17] = "moveForward",
  [31] = "moveBack",
  [30] = "moveLeft",
  [32] = "moveRight",
  [42] = "moveDown",
  [57] = "moveUp",
  [46] = "changeColor",
  [18] = "OTSOS",
  [16] = "VIBROSI",
}

while true do
  local e = {event.pull()}
  if e[1] == "key_down" then
    if keys[e[4]] then
      print("Команда дрону: " .. keys[e[4]])
      modem.broadcast(port, "ECSDrone", keys[e[4]])
    end
  elseif e[1] == "scroll" then
    if e[5] == 1 then
      modem.broadcast(port, "ECSDrone", "moveSpeedUp")
      print("Увеличить скорость перемещения дрона на 0.1")
    else
      print("Уменьшить скорость перемещения дрона на 0.1")
      modem.broadcast(port, "ECSDrone", "moveSpeedDown")
    end
  end
end





