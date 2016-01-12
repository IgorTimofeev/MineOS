--         Hologram Editor
-- by NEO, Totoro
-- 10/14/2014, all right reserved =)

local unicode = require('unicode')
local event = require('event')
local term = require('term')
local fs = require('filesystem')
local com = require('component')
local gpu = com.gpu

local config = require("config")
local lang = config.readAll("MineOS/Applications/HoloEdit.app/Resources/" .. _OSLANGUAGE .. ".lang")

--   Константы   --
HOLOH = 32
HOLOW = 48

--     Цвета     --
backcolor = 0x000000
forecolor = 0xFFFFFF
infocolor = 0x0066FF
errorcolor = 0xFF0000
helpcolor = 0x006600
graycolor = 0x080808
goldcolor = 0xFFDF00
--      ***      --


-- загружаем доп. оборудование
function trytofind(name)
  if com.isAvailable(name) then
    return com.getPrimary(name)
  else
    return nil
  end
end

local h = trytofind('hologram')

-- ========================================= H O L O G R A P H I C S ========================================= --
holo = {}
function set(x, y, z, value)
  if holo[x] == nil then holo[x] = {} end
  if holo[x][y] == nil then holo[x][y] = {} end
  holo[x][y][z] = value
end
function get(x, y, z)
  if holo[x] ~= nil and holo[x][y] ~= nil and holo[x][y][z] ~= nil then 
    return holo[x][y][z]
  else
    return 0
  end
end

function save(filename)
  -- сохраняем палитру
  file = io.open(filename, 'wb')
  for i=1, 3 do
    for c=1, 3 do
      file:write(string.char(colortable[i][c]))
    end
  end
  -- сохраняем массив
  for x=1, HOLOW do
    for y=1, HOLOH do
      for z=1, HOLOW, 4 do
        a = get(x,y,z)
        b = get(x,y,z+1)
        c = get(x,y,z+2)
        d = get(x,y,z+3)
        byte = d*64 + c*16 + b*4 + a
        file:write(string.char(byte))
      end
    end
  end
  file:close()
end

function load(filename)
  if fs.exists(filename) then
    file = io.open(filename, 'rb')
    -- загружаем палитру
    for i=1, 3 do
      for c=1, 3 do
        colortable[i][c] = string.byte(file:read(1))
      end
      setHexColor(i,colortable[i][1],
                    colortable[i][2],
                    colortable[i][3])
    end
    -- загружаем массив
    holo = {}
    for x=1, HOLOW do
      for y=1, HOLOH do
        for z=1, HOLOW, 4 do
          byte = string.byte(file:read(1))
          for i=0, 3 do
            a = byte % 4
            byte = math.floor(byte / 4)
            if a ~= 0 then set(x,y,z+i, a) end
          end
        end
      end
    end
    file:close()
    return true
  else
    --print("[ОШИБКА] Файл "..filename.." не найден.")
    return false
  end
end


-- ============================================= G R A P H I C S ============================================= --
-- проверка разрешения экрана, для комфортной работы необходимо разрешение > HOLOW по высоте и ширине
OLDWIDTH, OLDHEIGHT = gpu.getResolution()
WIDTH, HEIGHT = gpu.maxResolution()
if HEIGHT < HOLOW+2 then
  error(lang.badGPU)
else
  WIDTH = HOLOW*2+40
  HEIGHT = HOLOW+2
  gpu.setResolution(WIDTH, HEIGHT)
end
gpu.setForeground(forecolor)
gpu.setBackground(backcolor)

-- рисуем линию
local strLine = "+"
for i=1, WIDTH do
  strLine = strLine..'-'
end
function line(x1, x2, y)
  gpu.set(x1,y,string.sub(strLine, 1, x2-x1))
  gpu.set(x2,y,'+')
end

-- рисуем фрейм
function frame(x1, y1, x2, y2, caption)
  line(x1, x2, y1)
  line(x1, x2, y2)

  if caption ~= nil then
    gpu.set(x1+(x2-x1)/2-unicode.len(caption)/2, y1, caption)
  end
end

-- рисуем сетку
local strGrid = ""
for i=1, HOLOW/2 do
  strGrid = strGrid.."██  "
end
function drawGrid(x, y)
  gpu.fill(0, y, MENUX, HOLOW, ' ')
  gpu.setForeground(graycolor)
  for i=0, HOLOW-1 do
    if view>0 and i==HOLOH then 
      gpu.setForeground(forecolor)
      line(1, MENUX-1, y+HOLOH)
      break
    end
    gpu.set(x+(i%2)*2, y+i, strGrid)
  end
  if view == 0 then gpu.setForeground(forecolor) end
end

-- рисуем цветной прямоугольник
function drawRect(x, y, color)
  gpu.set(x, y,   "╓──────╖")
  gpu.set(x, y+1, "║      ║")
  gpu.set(x, y+2, "╙──────╜")
  gpu.setForeground(color)
  gpu.set(x+2, y+1, "████")
  gpu.setForeground(forecolor)
end

MENUX = HOLOW*2+5
BUTTONW = 12

-- рисуем меню выбора "кисти"
function drawColorSelector()
  frame(MENUX, 3, WIDTH-2, 16, lang.palette)
  for i=0, 3 do
    drawRect(MENUX+1+i*8, 5, hexcolortable[i])
  end
  gpu.set(MENUX+1, 10, "R:")
  gpu.set(MENUX+1, 11, "G:")
  gpu.set(MENUX+1, 12, "B:")
end
function drawColorCursor(force)
  if brush.color*8 ~= brush.x then brush.x = brush.color*8 end
  if force or brush.gx ~= brush.x then
    gpu.set(MENUX+1+brush.gx, 8, "        ")
    if brush.gx < brush.x then brush.gx = brush.gx + 1 end
    if brush.gx > brush.x then brush.gx = brush.gx - 1 end
    gpu.set(MENUX+1+brush.gx, 8, " -^--^- ")
  end
end
function drawLayerSelector()
  frame(MENUX, 16, WIDTH-2, 28, lang.layer)
  gpu.set(MENUX+13, 18, lang.level)
  gpu.set(MENUX+1, 23, lang.mainLevel)
end
function drawButtonsPanel()
  frame(MENUX, 28, WIDTH-2, 36, lang.control)
end

function mainScreen()
  term.clear()
  frame(1,1, WIDTH, HEIGHT, "{ Hologram Editor }")
  -- "холст"
  drawLayer()
  drawColorSelector()
  drawColorCursor(true)
  drawLayerSelector()
  drawButtonsPanel()
  buttonsDraw()
  textboxesDraw()
  -- "about" - коротко о создателях
  gpu.setForeground(infocolor)
  gpu.setBackground(graycolor)
  gpu.set(MENUX+3, HEIGHT-11, " Hologram Editor v0.60 Beta  ")
  gpu.setForeground(forecolor)
  gpu.set(MENUX+3, HEIGHT-10, "            * * *            ")
  gpu.set(MENUX+3, HEIGHT-9,  lang.developers)
  gpu.set(MENUX+3, HEIGHT-8,  "         NEO, Totoro         ")
  gpu.set(MENUX+3, HEIGHT-7,  "            * * *            ")
  gpu.set(MENUX+3, HEIGHT-6,  lang.contact)
  gpu.set(MENUX+3, HEIGHT-5,  "   computercraft.ru/forum    ")
  gpu.setBackground(backcolor)
  -- выход
  gpu.set(MENUX, HEIGHT-2, lang.quit)
end


-- =============================================== L A Y E R S =============================================== --
GRIDX = 3
GRIDY = 2
function drawLayer()
  drawGrid(GRIDX, GRIDY)
  -- вид сверху (y)
  if view == 0 then
    for x=1, HOLOW do
      for z=1, HOLOW do
        gn = get(x, ghost_layer, z)
        n = get(x, layer, z)
        if n == 0 and gn ~= 0 then
          gpu.setForeground(darkhexcolors[gn])
          gpu.set((GRIDX-2) + x*2, (GRIDY-1) + z, "░░")
        end
        if n ~= 0 then
          gpu.setForeground(hexcolortable[n])
          gpu.set((GRIDX-2) + x*2, (GRIDY-1) + z, "██")
        end
      end
    end
  -- вид спереди (z)
  elseif view == 1 then
    for x=1, HOLOW do
      for y=1, HOLOH do
        n = get(x, y, layer)
        gn = get(x, y, ghost_layer)
        if n == 0 and gn ~= 0 then
          gpu.setForeground(darkhexcolors[gn])
          gpu.set((GRIDX-2) + x*2, (GRIDY+HOLOH) - y, "░░")
        end
        if n ~= 0 then
          gpu.setForeground(hexcolortable[n])
          gpu.set((GRIDX-2) + x*2, (GRIDY+HOLOH) - y, "██")
        end
      end
    end
  -- вид сбоку (x)
  else
    for z=1, HOLOW do
      for y=1, HOLOH do
        gn = get(ghost_layer, y, z)
        n = get(layer, y, z)
        if n == 0 and gn ~= 0 then
          gpu.setForeground(darkhexcolors[gn])
          gpu.set((GRIDX+HOLOW*2) - z*2, (GRIDY+HOLOH) - y, "░░")
        end
        if n ~= 0 then
          gpu.setForeground(hexcolortable[n])
          gpu.set((GRIDX+HOLOW*2) - z*2, (GRIDY+HOLOH) - y, "██")
        end
      end
    end
  end
  gpu.setForeground(forecolor)
  -- for messages
  repaint = false
end
function fillLayer()
  for x=1, HOLOW do
    for z=1, HOLOW do
      set(x, layer, z, brush.color)
    end
  end
  drawLayer()
end
function clearLayer()
  for x=1, HOLOW do
    if holo[x] ~= nil then holo[x][layer] = nil end
  end
  drawLayer()
end


-- ============================================== B U T T O N S ============================================== --
Button = {}
Button.__index = Button
function Button.new(func, x, y, text, color, width)
  self = setmetatable({}, Button)

  self.form = '[ '
  if width == nil then width = 0
    else width = (width - unicode.len(text))-4 end
  for i=1, math.floor(width/2) do
    self.form = self.form.. ' '
  end
  self.form = self.form..text
  for i=1, math.ceil(width/2) do
    self.form = self.form.. ' '
  end
  self.form = self.form..' ]'

  self.func = func

  self.x = x; self.y = y
  self.color = color
  self.visible = true

  return self
end
function Button:draw(color)
  if self.visible then
    local color = color or self.color
    gpu.setBackground(color)
    if color > 0x888888 then gpu.setForeground(backcolor) end
    gpu.set(self.x, self.y, self.form)
    gpu.setBackground(backcolor)
    if color > 0x888888 then gpu.setForeground(forecolor) end
  end
end
function Button:click(x, y)
  if self.visible then
    if y == self.y then
      if x >= self.x and x < self.x+unicode.len(self.form) then
        self.func()
        self:draw(self.color/2)
        os.sleep(0.1)
        self:draw()
        return true
      end
    end
  end
  return false
end
buttons = {}
function buttonsNew(func, x, y, text, color, width)
  table.insert(buttons, Button.new(func, x, y, text, color, width))
end 
function buttonsDraw()
  for i=1, #buttons do
    buttons[i]:draw()
  end
end
function buttonsClick(x, y)
  for i=1, #buttons do
    buttons[i]:click(x, y)
  end
end

-- ================================ B U T T O N S   F U N C T I O N A L I T Y ================================ --
function exit() running = false end
function nextLayer()
  -- ограничения разные для разных видов/проекций
  local limit = HOLOH
  if view > 0 then limit = HOLOW end

  if layer < limit then 
    layer = layer + 1
    tb_layer:setValue(layer)
    tb_layer:draw(true)
    moveGhost()
    drawLayer()
  end
end
function prevLayer()
  if layer > 1 then 
    layer = layer - 1 
    tb_layer:setValue(layer)
    tb_layer:draw(true)
    moveGhost()
    drawLayer()
  end
end
function setLayer(value)
  local n = tonumber(value)
  local limit = HOLOH
  if view > 0 then limit = HOLOW end
  if n == nil or n < 1 or n > limit then return false end
  layer = n
  moveGhost()
  drawLayer()
  return true
end
function nextGhost()
  local limit = HOLOH
  if view > 0 then limit = HOLOW end
  
  if ghost_layer_below then
    ghost_layer_below = false
    if ghost_layer < limit then
      ghost_layer = layer + 1
    else ghost_layer = limit end
    drawLayer()
  else  
    if ghost_layer < limit then
      ghost_layer = ghost_layer + 1 
      drawLayer()
    end
  end
end
function prevGhost()
  if not ghost_layer_below then
    ghost_layer_below = true
    if layer > 1 then
      ghost_layer = layer - 1
    else ghost_layer = 1 end
    drawLayer()
  else
    if ghost_layer > 1 then
      ghost_layer = ghost_layer - 1
      drawLayer()
    end
  end
end
function setGhostLayer(value)
  local n = tonumber(value)
  local limit = HOLOH
  if view > 0 then limit = HOLOW end
  if n == nil or n < 1 or n > limit then return false end
  ghost_layer = n
  drawLayer()
  return true
end
function moveGhost()
  if ghost_layer_below then
    if layer > 1 then ghost_layer = layer - 1
    else ghost_layer = 1 end
  else
    local limit = HOLOH
    if view > 0 then limit = HOLOW end
    if layer < limit then ghost_layer = layer + 1
    else ghost_layer = limit end
  end
end

function setFilename(str)
  if str ~= nil and str ~= '' and unicode.len(str)<30 then 
    return true
  else
    return false
  end
end

function setHexColor(n, r, g, b)
  local hexcolor = rgb2hex(r,g,b)
  hexcolortable[n] = hexcolor
  darkhexcolors[n] = bit32.rshift(bit32.band(hexcolor, 0xfefefe), 1)
end
function rgb2hex(r,g,b)
  return r*65536+g*256+b
end
function changeRed(value) return changeColor(1, value) end
function changeGreen(value) return changeColor(2, value) end
function changeBlue(value) return changeColor(3, value) end
function changeColor(rgb, value)
  if value == nil then return false end
  n = tonumber(value)
  if n == nil or n < 0 or n > 255 then return false end
  -- сохраняем данные в таблицу
  colortable[brush.color][rgb] = n
  setHexColor(brush.color, colortable[brush.color][1],
                           colortable[brush.color][2],
                           colortable[brush.color][3])
  -- обновляем цвета на панельке
  for i=0, 3 do
    drawRect(MENUX+1+i*8, 5, hexcolortable[i])
  end
  return true
end

function moveSelector(num)
  brush.color = num
  tb_red:setValue(colortable[num][1]); tb_red:draw(true)
  tb_green:setValue(colortable[num][2]); tb_green:draw(true)
  tb_blue:setValue(colortable[num][3]); tb_blue:draw(true)
end

function setTopView() 
  view = 0 
  -- в виде сверху меньше слоев
  if layer > HOLOH then layer = HOLOH end
  drawLayer()
end
function setFrontView() view = 1; drawLayer() end
function setSideView() view = 2; drawLayer() end

function drawHologram()
  -- проверка на наличие проектора
  h = trytofind('hologram')
  if h ~= nil then
    local depth = h.maxDepth()
    -- очищаем
    h.clear()
    -- отправляем палитру
    if depth == 2 then
      for i=1, 3 do
        h.setPaletteColor(i, hexcolortable[i])
      end
    else
      h.setPaletteColor(1, hexcolortable[1])
    end
    -- отправляем массив
    for x=1, HOLOW do
      for y=1, HOLOH do
        for z=1, HOLOW do
          n = get(x,y,z)
          if n ~= 0 then
            if depth == 2 then
              h.set(x,y,z,n)
            else
              h.set(x,y,z,1)
            end
          end
        end
      end      
    end
  end
end

function newHologram()
  holo = {}
  drawLayer()
end

function saveHologram()
  local filename = tb_file:getValue()
  if filename ~= FILE_REQUEST then
    -- выводим предупреждение
    showMessage(lang.savingFile, lang.attention, goldcolor)
    -- добавляем фирменное расширение =)
    if string.sub(filename, -3) ~= '.3d' then
      filename = filename..'.3d'
    end
    -- сохраняем
    save(filename)
    -- выводим предупреждение
    showMessage(lang.complete, lang.attention, goldcolor)
    repaint = true
  end
end

function loadHologram()
  local filename = tb_file:getValue()
  if filename ~= FILE_REQUEST then
    -- выводим предупреждение
    showMessage(lang.loadingFile, lang.attention, goldcolor)
    -- добавляем фирменное расширение =)
    if string.sub(filename, -3) ~= '.3d' then
      filename = filename..'.3d'
    end
    -- загружаем
    load(filename)
    -- обновляем значения в текстбоксах
    tb_red:setValue(colortable[brush.color][1]); tb_red:draw(true)
    tb_green:setValue(colortable[brush.color][2]); tb_green:draw(true)
    tb_blue:setValue(colortable[brush.color][3]); tb_blue:draw(true)
    -- обновляем цвета на панельке
    for i=0, 3 do
      drawRect(MENUX+1+i*8, 5, hexcolortable[i])
    end
    -- обновляем слой
    drawLayer()
  end
end

-- ============================================ T E X T B O X E S ============================================ --
Textbox = {}
Textbox.__index = Textbox
function Textbox.new(func, x, y, value, width)
  self = setmetatable({}, Textbox)

  self.form = '>'
  if width == nil then width = 10 end
  for i=1, width-1 do
    self.form = self.form..' '
  end

  self.func = func
  self.value = tostring(value)

  self.x = x; self.y = y
  self.visible = true

  return self
end
function Textbox:draw(content)
  if self.visible then
    if content then gpu.setBackground(graycolor) end
    gpu.set(self.x, self.y, self.form)
    if content then gpu.set(self.x+2, self.y, self.value) end
    gpu.setBackground(backcolor)
  end
end
function Textbox:click(x, y)
  if self.visible then
    if y == self.y then
      if x >= self.x and x < self.x+unicode.len(self.form) then
        self:draw(false)
        term.setCursor(self.x+2, self.y)
        value = string.sub(term.read({self.value}), 1, -2)
        if self.func(value) then
          self.value = value
        end
        self:draw(true)
        return true
      end
    end
  end
  return false
end
function Textbox:setValue(value)
  self.value = tostring(value)
end
function Textbox:getValue()
  return self.value
end
textboxes = {}
function textboxesNew(func, x, y, value, width)
  textbox = Textbox.new(func, x, y, value, width)
  table.insert(textboxes, textbox)
  return textbox
end 
function textboxesDraw()
  for i=1, #textboxes do
    textboxes[i]:draw(true)
  end
end
function textboxesClick(x, y)
  for i=1, #textboxes do
    textboxes[i]:click(x, y)
  end
end


-- ============================================= M E S S A G E S ============================================= --
repaint = false
function showMessage(text, caption, color)
  local x = WIDTH/2 - unicode.len(text)/2 - 4
  local y = HEIGHT/2 - 2
  gpu.fill(x, y, unicode.len(text)+8, 5, ' ')
  frame(x, y, x+unicode.len(text)+7, y+4, caption)
  gpu.setForeground(color)
  gpu.set(x+4,y+2, text)
  gpu.setForeground(forecolor)
end


-- =========================================== M A I N   C Y C L E =========================================== --
-- инициализация
colortable = {{255, 0, 0}, {0, 255, 0}, {0, 102, 255}}
colortable[0] = {0, 0, 0}
hexcolortable = {}
darkhexcolors = {}
for i=0,3 do setHexColor(i, colortable[i][1], colortable[i][2], colortable[i][3]) end
brush = {color = 1, x = 8, gx = 8}
ghost_layer = 1
ghost_layer_below = true
layer = 1
view = 0
running = true

buttonsNew(exit, WIDTH-BUTTONW-2, HEIGHT-2, lang.exit, errorcolor, BUTTONW)
buttonsNew(drawLayer, MENUX+10, 14, lang.refresh, goldcolor, BUTTONW)
buttonsNew(prevLayer, MENUX+1, 19, '-', infocolor, 5)
buttonsNew(nextLayer, MENUX+7, 19, '+', infocolor, 5)
buttonsNew(setTopView, MENUX+1, 21, lang.fromUp, infocolor, 10)
buttonsNew(setFrontView, MENUX+12, 21, lang.fromFront, infocolor, 10)
buttonsNew(setSideView, MENUX+24, 21, lang.fromSide, infocolor, 9)

buttonsNew(prevGhost, MENUX+1, 24, lang.lower, infocolor, 6)
buttonsNew(nextGhost, MENUX+10, 24, lang.upper, infocolor, 6)

buttonsNew(clearLayer, MENUX+1, 26, lang.clear, infocolor, BUTTONW)
buttonsNew(fillLayer, MENUX+2+BUTTONW, 26, lang.fill, infocolor, BUTTONW)

buttonsNew(drawHologram, MENUX+8, 30, lang.toProjector, goldcolor, 16)
buttonsNew(saveHologram, MENUX+1, 33, lang.save, helpcolor, BUTTONW)
buttonsNew(loadHologram, MENUX+8+BUTTONW, 33, lang.load, infocolor, BUTTONW)
buttonsNew(newHologram, MENUX+1, 35, lang.new, infocolor, BUTTONW)

tb_red = textboxesNew(changeRed, MENUX+5, 10, '255', WIDTH-MENUX-7)
tb_green = textboxesNew(changeGreen, MENUX+5, 11, '0', WIDTH-MENUX-7)
tb_blue = textboxesNew(changeBlue, MENUX+5, 12, '0', WIDTH-MENUX-7)
tb_layer = textboxesNew(setLayer, MENUX+13, 19, '1', WIDTH-MENUX-15)
tb_ghostlayer = textboxesNew(setGhostLayer, MENUX+19, 24, ' ', WIDTH-MENUX-21)
FILE_REQUEST = lang.enterFileName
tb_file = textboxesNew(setFilename, MENUX+1, 32, FILE_REQUEST, WIDTH-MENUX-3)
mainScreen()

while running do
  if brush.x ~= brush.gx then name, add, x, y, b = event.pull(0.02)
  else name, add, x, y, b = event.pull(1.0) end

  if name == 'key_down' then 
    -- если нажата 'Q' - выходим
    if y == 16 then break 
    elseif y == 41 then
      moveSelector(0)
    elseif y>=2 and y<=4 then
      moveSelector(y-1)
    elseif y == 211 then
      clearLayer()
    end
  elseif name == 'touch' then
    -- проверка GUI
    buttonsClick(x, y)
    textboxesClick(x, y)
    -- выбор цвета
    if x>MENUX+1 and x<MENUX+37 then
      if y>4 and y<8 then
        moveSelector(math.floor((x-MENUX-1)/8))
      end
    end
  end
  if name == 'touch' or name == 'drag' then
    -- "рисование"
    local limit = HOLOW
    if view > 0 then limit = HOLOH end
    if x >= GRIDX and x < GRIDX+HOLOW*2 then
      if y >= GRIDY and y < GRIDY+limit then
        -- перерисуем, если на экране был мессейдж
        if repaint then drawLayer() end
        -- рассчет клика
        if view == 0 then
          dx = math.floor((x-GRIDX)/2)+1; gx = dx
          dy = layer; gy = ghost_layer
          dz = y-GRIDY+1; gz = dz
        elseif view == 1 then
          dx = math.floor((x-GRIDX)/2)+1; gx = dx
          dy = HOLOH - (y-GRIDY); gy = dy
          dz = layer; gz = ghost_layer
        else
          dx = layer; gx = ghost_layer
          dy = HOLOH - (y-GRIDY); gy = dy
          dz = HOLOW - math.floor((x-GRIDX)/2); gz = dz
        end
        if b == 0 and brush.color ~= 0 then
          set(dx, dy, dz, brush.color)
          gpu.setForeground(hexcolortable[brush.color])
          gpu.set(x-(x-GRIDX)%2, y, "██")
        else
          set(dx, dy, dz, 0)
          gpu.setForeground(darkhexcolors[get(gx,gy,gz)])
          gpu.set(x-(x-GRIDX)%2, y, "░░")
        end
        gpu.setForeground(forecolor)
      end
    end
  end

  drawColorCursor()
end

-- завершение
term.clear()
gpu.setResolution(OLDWIDTH, OLDHEIGHT)
gpu.setForeground(0xFFFFFF)
gpu.setBackground(0x000000)
