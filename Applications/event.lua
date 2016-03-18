local event = require "event"

while true do
  local eventData = { event.pull() }
  print("Ивент: " .. tostring(eventData[1]))
  for i = 2, #eventData do
    print("Аргумент" .. (i) .. ": " .. tostring(eventData[i]))
  end
  print(" ")
end
