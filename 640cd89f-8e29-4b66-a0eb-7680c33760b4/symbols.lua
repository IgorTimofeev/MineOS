local com = require("component")
local unicode = require("unicode")
local event = require("event")
local gpu = com.gpu
-- ─│┌┐└┘├┤┬┴┼

local w, h = gpu.maxResolution()
local hMax = math.floor((w-7)/3) -- максимум символов влезет по горизонтали
local vMax = math.floor((h-2)/3) -- максимум символов влезет по вертикали
w, h = hMax*3+7, vMax*3+1
gpu.setResolution(w, h) -- установка оптимального размера

gpu.setBackground(0)
gpu.setForeground(0xffffff)
gpu.fill(1, 1, w, h, " ")

local position = 1 -- позиция списка избранного
local startSymbol = 0 -- символ, с которого начинается отображаемый список
local liked = {}
local curSymbol = -1
local mode = false -- текущий список - избранное
local file = "" -- текущий сохраняемый файл
local fileNumber = 0

local function fillSymbols(start, count)
  local str = ""
  if start == -1 then -- заполнить средними разделителями
    str = "├"
    for i=0, (count-1) do
      str = str.."──┼"
    end
    str = str:sub(1, str:len()-("┼"):len()).."┤"
  elseif start == -2 then -- заполнить двумя пробелами и разделителем
    str = "│"
    for i=0, (count-1) do
      str = str.."  │"
    end
  else
    str = "│"
    for i=start, (start+count-1) do -- заполнить символом, пробелом и разделителем
      if i > 0xffff then
        str = str.."  │"
      else
        char = unicode.char(i)
        if unicode.charWidth(char) > 1 then
          str = str..char.."│"
        else
          str = str..char.." │"
        end
      end
    end
  end
  return str
end
local function drawAllTable()
  gpu.fill(1, 1, w-6, h, " ")
  str = "┌" -- верхняя часть
  for i=0, (hMax-1) do
    str = str.."──┬"
  end
  gpu.set(1, 1, str)
  for i=0, (vMax-1) do
    gpu.set(1, 2+i*3, fillSymbols(startSymbol+i*hMax, hMax))
    gpu.set(1, 3+i*3, fillSymbols(-2, hMax))
    gpu.set(1, 4+i*3, fillSymbols(-1, hMax))
  end
  str = "└" -- нижняя часть
  for i=0, (hMax-1) do
    str = str.."──┴"
  end
  gpu.set(1, h ,str)
end

local function fillTableSymbols(start, count, tab)
  local str = ""
  if start == -1 then -- заполнить средними разделителями
    str = "├"
    for i=0, (count-1) do
      str = str.."──┼"
    end
    str = str:sub(1, str:len()-("┼"):len()).."┤"
  elseif start == -2 then -- заполнить двумя пробелами и разделителем
    str = "│"
    for i=0, (count-1) do
      str = str.."  │"
    end
  else
    str = "│"
    for i=start, (start+count-1) do -- заполнить символом, пробелом и разделителем
      if i > #tab then
        str = str.."  │"
      else
        char = unicode.char(tab[i])
        if unicode.charWidth(char) > 1 then
          str = str..char.."│"
        else
          str = str..char.." │"
        end
      end
    end
  end
  return str
end
local function drawLikedTable()
  gpu.fill(2, 2, w-8, h-2, " ")
  for i=0, (vMax-1) do
    gpu.set(1, 2+i*3, fillTableSymbols(position+i*hMax, hMax, liked))
    gpu.set(1, 3+i*3, fillTableSymbols(-2, hMax))
    gpu.set(1, 4+i*3, fillTableSymbols(-1, hMax))
  end
  str = "└"
  for i=0, (hMax-1) do
    str = str.."──┴"
  end
  gpu.set(1, h ,str)
end

local function drawButton(x,y,text)
  gpu.set(x, y, "▁▁▁▁▁")
  gpu.set(x, y+1, text)
  gpu.set(x, y+2, "▔▔▔▔▔")
end

local function drawSaved(text)
  if text ~= "" then
    gpu.set(w-5, h-6, "Saved")
    gpu.set(w-5, h-5, "as")
    gpu.set(w-5, h-4, text)
  else
    gpu.fill(w-5, h-6, 5, 3, " ")
  end
end

local function drawCharInfo(char, liked)
  gpu.fill(w-5, 8, 5, 5, " ")
  local ch = unicode.char(char)
  gpu.set(w-5, 8, ch..(unicode.charWidth(ch) > 1 and "" or " ").." "..(liked and "◢◣" or "/\\"))
  gpu.set(w-5, 9, "   "..(liked and "◥◤" or "\\/"))
  gpu.set(w-5, 10, "Code:")
  gpu.set(w-5, 11, tostring(char))
  gpu.set(w-5, 12, string.format("x%X", char))
end

local function drawMenu()
  gpu.set(w-5, 1, "────><")
  gpu.fill(w, 2, 1, h-2, "│")
  
  gpu.set(w-5, 2, " ◢ ◣ ")
  gpu.set(w-5, 3, " ◥ ◤ ")
  gpu.set(w-5, 4, string.format("%X/", startSymbol))
  gpu.set(w-5, 5, "xFFFF")
  
  drawButton(w-5, h-9, "Liked")
  drawButton(w-5, h-3, "Save")
  
  gpu.set(w-5, h, "─────┘")
end

local function getSymbolIndex(x, y) -- считается порядковый номер по координатам клика
  if x < 2 or y < 2 or (x-1)%3==0 or
      (y-1)%3==0 then return -1 end

  return math.floor((y-1)/3)*hMax + math.floor((x-1)/3)
end

drawAllTable()
drawMenu()
while true do
  local evnt = {event.pull("touch")}
  local x, y = evnt[3], evnt[4]
  if evnt[5] == 0 then
    if x > (w-2) and y == 1 then -- выход
      break
    else
      if x < w-5 then -- выбор символа
        local i = getSymbolIndex(x, y)
        if i > -1 then
          if mode then
            if position+i <= #liked then
              drawCharInfo(liked[position+i], true)
              curSymbol = liked[position+i]
            end
          elseif startSymbol+i <= 0xffff then
            local finded = false -- есть ли символ в избранных
            for j=1, #liked do
              if liked[j] == startSymbol+i then
                finded = true
                break
              end
            end
            drawCharInfo(startSymbol+i, finded)
            curSymbol = startSymbol+i
          end
        end
      else
        if x < w then
          local str = ""
          if y > 1 and y < 4 then -- перемотка страниц
            if x > w-3 then
              if mode then
                if (position+hMax*vMax) <= #liked then
                  position = position+hMax*vMax
                  str = string.format("%X/", position)
                  gpu.set(w-5, 4, str..(" "):rep(5-str:len()))
                  drawLikedTable()
                end
              else
                if (startSymbol+hMax*vMax) <= 0xffff then
                  startSymbol = startSymbol + hMax*vMax
                  str = string.format("%X/", startSymbol)
                  gpu.set(w-5, 4, str..(" "):rep(5-str:len()))
                  drawAllTable()
                end
              end
            elseif x < w-3 then
              if mode then
                if position > 1 then
                  position = math.max(position - hMax*vMax, 0)
                  str = string.format("%X/", position)
                  gpu.set(w-5, 4, str..(" "):rep(5-str:len()))
                  drawLikedTable()
                end
              else
                if startSymbol > 0 then
                  startSymbol = math.max(startSymbol - hMax*vMax, 0)
                  str = string.format("%X/", startSymbol)
                  gpu.set(w-5, 4, str..(" "):rep(5-str:len()))
                  drawAllTable()
                end
              end
            end
          elseif y > 7 and y < 10 then
            if x > w-3 then -- добавить/убрать символ в списке "Избранное"
              local finded = false
              for i=1, #liked do
                if liked[i] == curSymbol then
                  finded = true
                  table.remove(liked, i)
                  break
                end
              end
              if not finded then
                table.insert(liked, curSymbol)
              end
              if mode then
                drawLikedTable()
              end
              drawSaved("")
              drawCharInfo(curSymbol, not finded)
            end
          elseif y > h-10 and y < h-6 then -- избранное/все
            if mode then
              mode = false
              drawButton(w-5, h-9, "Liked")
              str = string.format("%X/", startSymbol)
              gpu.set(w-5, 4, str..(" "):rep(5-str:len()))
              gpu.set(w-5, 5, "xFFFF")
              drawAllTable()
            else
              mode = true
              drawButton(w-5, h-9, " All ")
              str = string.format("%X/", position)
              gpu.set(w-5, 4, str..(" "):rep(5-str:len()))
              str = tostring(#liked)
              gpu.set(w-5, 5, str..(" "):rep(5-str:len()))
              drawLikedTable()
            end
          elseif y > h-4 and y < h then -- сохранить
            if #liked > 0 then
              if file == "" then
                fileNumber = math.random(99999)
                file = "/symbols-"..tostring(fileNumber)..".txt"
              end
              
              local fs = io.open(file, "w")
              str = ""
              for i=1, #liked do
                str = str..unicode.char(liked[i])
              end
              fs:write(str)
              fs:close()
              
              drawSaved(tostring(fileNumber))
            end
          end
        end
      end
    end
  end
end

w, h = gpu.maxResolution()
gpu.setResolution(w, h)
gpu.fill(1, 1, w, h, " ")