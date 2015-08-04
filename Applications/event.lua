local event = require "event"

while true do
  local cyka = {event.pull()}
  print("Ивент: "..cyka[1])
  for i=2,#cyka do
    print("Аргумент "..(i).." = "..cyka[i])
  end
  print(" ")
end
