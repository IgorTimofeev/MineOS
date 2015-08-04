local c = require("computer")

local arg = {...}

local width = arg[1] or 50
local height = arg[2] or 50
local pixels = {}
local history = {}
local historySize = arg[3] or 1

local function mem()
  local free = c.freeMemory()
  local total = c.totalMemory()
  local used = total-free

  return math.floor(used/1024)
end

local start = mem()

for z=1,1 do
  history[z] = {"Сука блядь",{}}
  for j=1,height do
    history[z][2][j] = {}
    for i=1,width do
      history[z][2][j][i] = {0x000000,0xffffff,"#"}
    end
  end
end

local ending = mem()
print("Всего доступно "..math.floor(c.totalMemory()/1024).."КБ оперативки")
print(" ")
print("До отрисовки заюзано "..start.."КБ оперативки")
print("Начинаю отрисовку одного изображения...")
print("После отрисовки заюзано "..ending.."КБ оперативки")
print(" ")
local say = "слоем"
if tonumber(historySize) > 1 then say = "слоями" end
print("Вывод: изображение размером "..width.."x"..height.." с "..historySize.." "..say.." схавает "..((ending-start)*historySize).."КБ оперативки")
