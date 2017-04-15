local colorlib = {}
local serialization = require("serialization")

local function isNan(x)
  return x~=x
end

function colorlib.HEXtoRGB(color)
  return bit32.rshift(color, 16), bit32.band(bit32.rshift(color, 8), 0xFF), bit32.band(color, 0xFF)
end

function colorlib.RGBtoHEX(rr, gg, bb)
  return bit32.lshift(rr, 16) + bit32.lshift(gg, 8) + bb
end

--HSB model
function colorlib.RGBtoHSB(rr, gg, bb)
  local max = math.max(rr, math.max(gg, bb))
  local min = math.min(rr, math.min(gg, bb))
  local delta = max - min

  local h = 0
  if ( max == rr and gg >= bb) then h = 60*(gg-bb)/delta end
  if ( max == rr and gg <= bb ) then h = 60*(gg-bb)/delta + 360 end
  if ( max == gg ) then h = 60*(bb-rr)/delta + 120 end
  if ( max == bb ) then h = 60*(rr-gg)/delta + 240 end

  local s = 0
  if ( max ~= 0 ) then s = 1 - (min / max) end

  local b = max * 100 / 255

  if isNan(h) then h = 0 end

  return h, s * 100, b
end

function colorlib.HSBtoRGB(h, s, v)
  if h > 359 then h = 0 end
  local rr, gg, bb = 0, 0, 0
  local const = 255

  s = s/100
  v = v/100
  
  local i = math.floor(h/60)
  local f = h/60 - i
  
  local p = v*(1-s)
  local q = v*(1-s*f)
  local t = v*(1-(1-f)*s)

  if ( i == 0 ) then rr, gg, bb = v, t, p end
  if ( i == 1 ) then rr, gg, bb = q, v, p end
  if ( i == 2 ) then rr, gg, bb = p, v, t end
  if ( i == 3 ) then rr, gg, bb = p, q, v end
  if ( i == 4 ) then rr, gg, bb = t, p, v end
  if ( i == 5 ) then rr, gg, bb = v, p, q end

  return math.floor(rr * const), math.floor(gg * const), math.floor(bb * const)
end

function colorlib.HEXtoHSB(color)
  local rr, gg, bb = colorlib.HEXtoRGB(color)
  local h, s, b = colorlib.RGBtoHSB( rr, gg, bb )
  
  return h, s, b
end

function colorlib.HSBtoHEX(h, s, b)
  local rr, gg, bb = colorlib.HSBtoRGB(h, s, b)
  local color = colorlib.RGBtoHEX(rr, gg, bb)

  return color
end

--Смешивание двух цветов на основе альфа-канала второго
function colorlib.alphaBlend(firstColor, secondColor, alphaChannel)
  local invertedAlphaChannel = 1 - alphaChannel
  
  local firstColorRed, firstColorGreen, firstColorBlue = colorlib.HEXtoRGB(firstColor)
  local secondColorRed, secondColorGreen, secondColorBlue = colorlib.HEXtoRGB(secondColor)

  return colorlib.RGBtoHEX(
    secondColorRed * invertedAlphaChannel + firstColorRed * alphaChannel,
    secondColorGreen * invertedAlphaChannel + firstColorGreen * alphaChannel,
    secondColorBlue * invertedAlphaChannel + firstColorBlue * alphaChannel
  )
end

--Получение среднего цвета между перечисленными. К примеру, между черным и белым выдаст серый.
function colorlib.getAverageColor(colors)
  local sColors = #colors
  local averageRed, averageGreen, averageBlue = 0, 0, 0
  for i = 1, sColors do
    local r, g, b = colorlib.HEXtoRGB(colors[i])
    averageRed, averageGreen, averageBlue = averageRed + r, averageGreen + g, averageBlue + b
  end
  return colorlib.RGBtoHEX(math.floor(averageRed / sColors), math.floor(averageGreen / sColors), math.floor(averageBlue / sColors))
end

-----------------------------------------------------------------------------------------------------------------------

colorlib.palette = {}

for r = 0, 0xFF, 0xFF / 5 do
  for g = 0, 0xFF, 0xFF / 7 do
    for b = 0, 0xFF, 0xFF / 4 do
      table.insert(colorlib.palette, colorlib.RGBtoHEX(r, math.floor(g + 0.5), math.floor(b + 0.5))) --один красный нормальный
    end
  end
end
for gr = 1, 0x10 do --Градации серого
  table.insert(colorlib.palette, gr * 0xF0F0F) --Нет смысла использовать colorlib.RGBtoHEX()
end
table.sort(colorlib.palette)

function colorlib.convert24BitTo8Bit(hex24)
  local encodedIndex = nil
  local colorMatchFactor = nil
  local colorMatchFactor_min = math.huge

  local red24, green24, blue24 = colorlib.HEXtoRGB(hex24)

  for colorIndex, colorPalette in ipairs(colorlib.palette) do
    local redPalette, greenPalette, bluePalette = colorlib.HEXtoRGB(colorPalette)

    colorMatchFactor = (redPalette-red24)^2 + (greenPalette-green24)^2 + (bluePalette-blue24)^2

    if (colorMatchFactor < colorMatchFactor_min) then
      encodedIndex = colorIndex
      colorMatchFactor_min = colorMatchFactor
    end
  end
    
  return encodedIndex - 1
  -- return searchClosestColor(1, #palette, hex24)
end

function colorlib.convert8BitTo24Bit(hex8)
  return colorlib.palette[hex8 + 1]
end

function colorlib.debugColorCompression(color)
  local compressedColor = colorlib.convert24BitTo8Bit(color)
  local decompressedColor = colorlib.convert8BitTo24Bit(compressedColor)
  print("Исходный цвет: " .. string.format("0x%06X", color))
  print("Сжатый цвет: " .. string.format("0x%02X", compressedColor))
  print("Расжатый цвет: " .. string.format("0x%06X", decompressedColor))
end


-----------------------------------------------------------------------------------------------------------------------

return colorlib






