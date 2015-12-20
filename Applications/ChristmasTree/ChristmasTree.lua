local component = require("component")
local ecs = require("ECSAPI")
local hologram
local c = 23

if not component.isAvailable("hologram") then
  ecs.error("Этой программе необходим голографический проектор 2 уровня.")
  return
else
  hologram = component.hologram
end

-- создаем модель елки
local tSpruce = {3, 2, 2, 2, 2, 8, 9, 10, 9, 8, 7, 6, 5, 4, 3, 4, 6, 8, 7, 6, 5, 4, 3, 6, 5, 4, 3, 2, 3, 2, 1}

-- создаем таблицу с падающими снежинками
local tSnow = {}

-- создаем палитру цветов
hologram.setPaletteColor(1, 0xFFFFFF) -- снег
hologram.setPaletteColor(2, 0x221100) -- ствол
hologram.setPaletteColor(3, 0x005522) -- хвоя

local function cricle(x0, y, z0, R, i) -- задействуем алгоритм Брезенхэма для рисования кругов
  local x = R
  local z = 0
  local err = -R
  while z <= x do
    hologram.set(x + x0, y, z + z0, i)
    hologram.set(z + x0, y, x + z0, i)
    hologram.set(-x + x0, y, z + z0, i)
    hologram.set(-z + x0, y, x + z0, i)
    hologram.set(-x + x0, y, -z + z0, i)
    hologram.set(-z + x0, y, -x + z0, i)
    hologram.set(x + x0, y, -z + z0, i)
    hologram.set(z + x0, y, -x + z0, i)
    z = z + 1
    if err <= 0 then
      err = err + (2 * z + 1)
    else
      x = x - 1
      err = err + (2 * (z - x) + 1)
    end
  end
end

local function spruce() -- рисуем ель
  for i = 1, 5 do
    cricle(c, i, c, tSpruce[i], 2) -- отрисовываем основание ствола
    cricle(c, i, c, tSpruce[i]-1, 2)
  end
  for j = 5, #tSpruce do
    cricle(c, j, c, tSpruce[j]-1, 3) -- отрисовываем хвою
    cricle(c, j, c, tSpruce[j]-2, 3)
  end
end

local function gen_snow() -- генерируем снежинку
  local x, y, z = math.random(1, 46), 32, math.random(1, 46)
  table.insert(tSnow,{x=x,y=y,z=z})
  hologram.set(x, y, z, 1)
end
 
local function falling_snow() -- сдвигаем снежинки вниз
  local i=1
  while i<=#tSnow do
    if tSnow[i].y>1 then
        local x,y,z=tSnow[i].x+math.random(-1, 1), tSnow[i].y-1, tSnow[i].z+math.random(-1, 1)
        if x<1 then x=1 end
        if x>46 then x=46 end
        if z<1 then z=1 end
        if z>46 then z=46 end
        c=hologram.get(x, y, z)
        if c==0 or c==1 then
          hologram.set(tSnow[i].x, tSnow[i].y, tSnow[i].z, 0)
          tSnow[i].x, tSnow[i].y, tSnow[i].z=x,y,z
          hologram.set(x, y, z, 1)
          i=i+1
        else
          table.remove(tSnow,i)
        end       
     else
        table.remove(tSnow,i)
     end
     os.sleep(0)
  end
end

ecs.info("auto", "auto", "", "Счастливого нового года!")
hologram.clear()
spruce()
while 1 do
  gen_snow()
  falling_snow()
end