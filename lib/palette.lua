local component = require("component")
local event = require("event")
local term = require("term")
local unicode = require("unicode")
local ecs = require("ECSAPI")
local colorlib = require("colorlib")

local gpu = component.gpu

local palette = {}

------------------------------------------------------------------------------------



--РИСОВАТЬ ПАЛИТРОЧКУ
function palette.drawPalette(x,y,oldColor)

  local windowSizeX = 73
  local windowSizeY = 22
  local x,y = ecs.correctStartCoords(x,y,windowSizeX,windowSizeY)

  local MasterHue = 360
  local MasterSat = 100
  local MasterBri = 100
  MasterHue,MasterSat,MasterBri = colorlib.HEXtoHSB(oldColor)
  local MasterColor = colorlib.HSBtoHEX(MasterHue,MasterSat,MasterBri)

  local rainbowBigWidth = 40
  local rainbowBigHeight = 19
  local masterColorX = x+rainbowBigWidth+9
  local masterColorY = y+2

  local krestX,krestY = 0,0
  local oldKrest = {}

  ------------------------------------------------------------------------------------

  --ОБЪЕКТЫ
  local objects = {}
  local function newObj(class,name,key,value)
    objects[class] = objects[class] or {}
    objects[class][name] = objects[class][name] or {}
    objects[class][name][key] = value
  end

  local function drawSelector(x,y)
    gpu.setBackground(ecs.windowColors.background)
    gpu.setForeground(0x000000)
    gpu.set(x,y,">")
    gpu.set(x+4,y,"<")
  end

  local function drawRainbow(x,y,width,height)
    local pizda = 360/height

    --gpu.setBackground(ecs.windowColors.background)
    --gpu.fill(x,y,5,height+1," ")

    for i=1,height do
      for j=1,width do
        gpu.setBackground(colorlib.HSBtoHEX(i*pizda-1,100,100))
        gpu.set(x+j,y+i," ")
      end
    end

    x = x + 1
    y = y + 1
    newObj("palette","small","x1",x);newObj("palette","small","x2",x+width-1);newObj("palette","small","y1",y);newObj("palette","small","y2",y+height-1)
  end

  local function drawKREST(pointX,pointY)
    --ЭТО КУРСОРЧИК КРЕСТИК
    ecs.invertedText(pointX-2,pointY,"̶")
    ecs.invertedText(pointX+2,pointY,"̶")
    ecs.invertedText(pointX-1,pointY,"̶")
    ecs.invertedText(pointX+1,pointY,"̶")
    ecs.invertedText(pointX,pointY-1,"|")
    ecs.invertedText(pointX,pointY+1,"|")
  end

  local function drawRainbowBig(x,y,width,height,MasterColor)

    --ЖИРНАЯ ГЛАВНАЯ ПИЗДОРАДУГА, ВЕРНЕЕ, ЕЕ ОЧИСТКА
    gpu.setBackground(ecs.windowColors.background)
    gpu.fill(x+width+1,y,6,height+2," ")

    --gpu.setBackground(ecs.colors.red)
    gpu.fill(x,y,width+2,1," ")
    gpu.fill(x,y,1,height," ")
    gpu.fill(x,y+height+1,width+2,1," ")
    gpu.fill(x+width+1,y,1,height," ")

    --РАСЧЕТ ВСЯКОЙ ШНЯГИ
    --local hue, sat, bri = colorlib.HEXtoHSB(MasterColor)
    local hue, sat, bri = MasterHue,MasterSat,MasterBri
    --hue = hue - 1
    --MasterColor = hue

    --МИНИ-РАДУГА
    local xMini = x+width+2
    drawRainbow(xMini,y,3,height)

    --СЕЛЕКТОР МИНИ-РАДУГИ
    local miniHue = ecs.adaptiveRound(hue*height/360)
    drawSelector(xMini,y+miniHue)

    --ВОТ ТУТ УЖЕ САМА БОЛЬШАЯ ШНЯГА
    local pizda1 = 100/width
    local pizda2 = 100/height

    for i=1,height do
      for j=1,width do
        gpu.setBackground(colorlib.HSBtoHEX(MasterHue,j*pizda1,100-i*pizda2))
        gpu.set(x+j,y+i," ")
      end
    end

    newObj("palette","big","x1",x+1);newObj("palette","big","x2",x+width);newObj("palette","big","y1",y+1);newObj("palette","big","y2",y+height)
  end

  local function drawMasterColor(x,y,MasterColor)
    gpu.setBackground(MasterColor)
    gpu.fill(x,y,5,5," ")
    gpu.setBackground(oldColor)
    gpu.fill(x+5,y,5,5," ") 
  end

  local function drawButton(x,y,width,text,backColor,textColor)
    gpu.setBackground(backColor)
    gpu.setForeground(textColor)
    local textPosX = x + math.floor(width/2-unicode.len(text)/2)
    gpu.fill(x,y,width,1," ")
    gpu.set(textPosX,y,text)
    newObj("buttons",text,"x1",x);newObj("buttons",text,"x2",x+width-1);newObj("buttons",text,"y1",y);newObj("buttons",text,"y2",y)
  end

  local function getInfoAboutColor(MasterColor)
    local rr,gg,bb = colorlib.HEXtoRGB(MasterColor)
    local hh,ss,ll = colorlib.HEXtoHSB(MasterColor)

    local colorInfo = {
      {"R:",math.floor(rr)},
      {"G:",math.floor(gg)},
      {"B:",math.floor(bb)},
      {"H:",ecs.adaptiveRound(MasterHue)},
      {"S:",math.floor(MasterSat)},
      {"B:",math.floor(MasterBri)},
      {"# ",string.format("%x", MasterColor)},
    }

    return colorInfo
  end

  local function drawInfoAboutColors(x,y,MasterColor)
    local colorInfo = getInfoAboutColor(MasterColor)

    for i=1,#colorInfo do
      gpu.setBackground(ecs.windowColors.background)
      gpu.setForeground(0x000000)
      gpu.set(x,y+i*2-2,colorInfo[i][1].." ")

      gpu.setBackground(0xffffff)
      gpu.setForeground(0x111111)
      gpu.fill(x+3,y+i*2-2,7,1," ")
      gpu.set(x+3,y+i*2-2,tostring(colorInfo[i][2]))
    end
  end

  -------------------------------------------------------

  local function recalculateKrest()
    krestX = ecs.adaptiveRound(x + 1 + MasterSat * rainbowBigWidth / 100)
    krestY = ecs.adaptiveRound(y + 2 + rainbowBigHeight - (MasterBri * rainbowBigHeight / 100))
  end

  local function drawNuzhnoe()
    drawRainbowBig(x+1,y+1,rainbowBigWidth,rainbowBigHeight,MasterColor)
    drawMasterColor(masterColorX,masterColorY,MasterColor)
    drawInfoAboutColors(masterColorX,masterColorY+6,MasterColor)
    drawKREST(krestX,krestY)
  end

  ecs.emptyWindow(x,y,windowSizeX,windowSizeY,"Выберите цвет")

  drawButton(masterColorX+12,masterColorY+1,10,"OK",ecs.colors.lightBlue,0xffffff)
  drawButton(masterColorX+12,masterColorY+3,10,"Cancel",0xaaaaaa,0x000000)

  recalculateKrest()
  drawRainbowBig(x+1,y+1,rainbowBigWidth,rainbowBigHeight,MasterColor)
  drawMasterColor(masterColorX,masterColorY,MasterColor)
  drawInfoAboutColors(masterColorX,masterColorY+6,MasterColor)
  oldKrest = ecs.rememberOldPixels(krestX-2,krestY-1,krestX+2,krestY+1)
  drawKREST(krestX,krestY)

  
  while true do
    local eventData = {event.pull()}
    if eventData[1] == "touch" or eventData[1] == "drag" then

    if ecs.clickedAtArea(eventData[3],eventData[4],objects["palette"]["small"]["x1"],objects["palette"]["small"]["y1"],objects["palette"]["small"]["x2"],objects["palette"]["small"]["y2"]) then
      local CYKA = {gpu.get(eventData[3],eventData[4])}
      MasterHue = colorlib.HEXtoHSB(CYKA[3])
      CYKA = nil
      MasterColor = colorlib.HSBtoHEX(MasterHue,MasterSat,MasterBri)


      drawRainbowBig(x+1,y+1,rainbowBigWidth,rainbowBigHeight,MasterColor)
      drawMasterColor(masterColorX,masterColorY,MasterColor)
      drawInfoAboutColors(masterColorX,masterColorY+6,MasterColor)

      oldKrest = ecs.rememberOldPixels(krestX-2,krestY-1,krestX+2,krestY+1)
      drawKREST(krestX,krestY)
      
    elseif ecs.clickedAtArea(eventData[3],eventData[4],objects["palette"]["big"]["x1"],objects["palette"]["big"]["y1"],objects["palette"]["big"]["x2"],objects["palette"]["big"]["y2"]) then
    
      local CYKA = {gpu.get(eventData[3],eventData[4])}
      local PIDOR = {colorlib.HEXtoHSB(CYKA[3])}
      MasterSat,MasterBri = PIDOR[2],PIDOR[3]
      MasterColor = colorlib.HSBtoHEX(MasterHue,MasterSat,MasterBri)
      PIDOR = nil
      CYKA = nil

      ecs.drawOldPixels(oldKrest)
      krestX,krestY = eventData[3],eventData[4]
      oldKrest = ecs.rememberOldPixels(krestX-2,krestY-1,krestX+2,krestY+1)

      --drawRainbowBig(x+1,y+1,rainbowBigWidth,rainbowBigHeight,MasterColor)
      drawMasterColor(masterColorX,masterColorY,MasterColor)
      drawInfoAboutColors(masterColorX,masterColorY+6,MasterColor)
      drawKREST(krestX,krestY)
    elseif ecs.clickedAtArea(eventData[3],eventData[4],objects["buttons"]["OK"]["x1"],objects["buttons"]["OK"]["y1"],objects["buttons"]["OK"]["x2"],objects["buttons"]["OK"]["y2"]) then
      drawButton(objects["buttons"]["OK"]["x1"],objects["buttons"]["OK"]["y1"],10,"OK",ecs.colors.blue,0xffffff)
      os.sleep(0.3)
      return MasterColor,MasterHue,MasterSat,MasterBri
    elseif ecs.clickedAtArea(eventData[3],eventData[4],objects["buttons"]["Cancel"]["x1"],objects["buttons"]["Cancel"]["y1"],objects["buttons"]["Cancel"]["x2"],objects["buttons"]["Cancel"]["y2"]) then
      drawButton(objects["buttons"]["Cancel"]["x1"],objects["buttons"]["Cancel"]["y1"],10,"Cancel",ecs.colors.blue,0xffffff)
      os.sleep(0.3)
      return nil
    end

    --[[elseif eventData[1] == "key_up" then

      if eventData[4] == 57 then
        MasterHue,MasterSat,MasterBri = 360,100,100
        MasterColor = colorlib.HSBtoHEX(MasterHue,MasterSat,MasterBri)
        recalculateKrest()
        drawNuzhnoe()
      end]]
    end
  end
end

------------------------------------------------------------------------------------

return palette
