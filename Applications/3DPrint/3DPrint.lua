local com = require("component")
local gpu = com.gpu
local shell = require("shell")
local event = require("event")
local term = require("term")
local unicode = require("unicode")
local ecs = require("ECSAPI")
local holo = require("component").hologram
 
------------------------------------------------------------------
local printer = com.printer3d
local xSize, ySize = 80, 50
gpu.setResolution(xSize*2, ySize)
local rightPartSize = 30
 
local userData = {
        label = "Printered Block",
        tooltip = "byShahar",
        light = false,
        emitRedstone = false,
        buttonMode = false,
}
 
local doingShapes = {}
local onlineShape = 1
local onlineLayer = 1
 
local mode = false
 
local startHolo = 16
 
local button = {
        Name = {text = "Имя", x1, y1, x2, y2},
        Clear = {text = "Очистить", x1, y1, x2, y2},
        IsEmitRedstone = {text = "Излучает Redstone", x1, y1, x2, y2},
        IsButtonMode = {text = "Режим кнопки", x1, y1, x2, y2},
        Light = {text = "Свет", x1, y1, x2, y2},
        Texture = {text = "Текстура", x1, y1, x2, y2},
        State = {text = "Статус", x1, y1, x2, y2},
        Print = {text = "Печать", x1, y1, x2, y2},
}
 
local textures = {"sand", "grass_top", "grass_side", "dirt", "log_oak", "leaves_oak_opaque", "brick", "stone_slab_top"}
 
local colors = {
        [1] = 16711680,
        [2] = 16725760,
        [3] = 16739840,
        [4] = 16754176,
        [5] = 16768256,
        [6] = 15400704,
        [7] = 11730688,
        [8] = 8126208,
        [9] = 4521728,
        [10] = 917248,
        [11] = 6532.25,
        [12] = 65377.75,
        [13] = 65433,
        [14] = 65488.25,
        [15] = 63487,
        [16] = 49151,
        [17] = 35071,
        [18] = 20991,
        [19] = 6911,
        [20] = 1966335,
        [21] = 5570815,
        [22] = 9175295,
        [23] = 12779775,
        [24] = 16449791
}
 
 
-------------------------------------------------------------------------------------------------
 
local function Square(x, y, width, height, color)
        ecs.square(x*2 - 1, y, width*2, height, color)
end
 
local function isIn(x1, y1, x2, y2, xClick, yClick)
        if xClick >= x1 and xClick <= x2 and yClick >= y1 and yClick <= y2 then
                return true
        else
                return false
        end
end
 
local function Text(x, y, text, colorBack, colorText)
        gpu.setBackground(colorBack)
        gpu.setForeground(colorText)
        gpu.set(x, y, text)
end
 
local function inDiapason(num1, num2, num)
        if num >= num1 and num <= num2 then
                return true
        elseif num >= num2 and num <= num1 then
                return true
        else
                return false
        end
end
 
local function completeWord(wrdPart, wrds)
        for i = 1, #wrds do
                local answer = unicode.sub(wrds[i], 1, unicode.len(wrdPart))
                if answer == wrdPart then
                        return wrds[i]
                end
        end
        return "none"
end
 
local function whatsClickMain(x, y)
        if x > 1 and x < 49 and y > 1 and y < 50 then
                return math.floor((x+2)/ 3), math.floor((y + 1)/ 3)
        else
                return "fail", " "
        end
end
 
local function whatsClickShape(x, y)
        for i = 1, 24 do
                if isIn(doingShapes[i].x, doingShapes[i].y, doingShapes[i].x + 4, doingShapes[i].y, x, y) then
                        return "nofail", i
                end
        end
        return "fail"
end
 
local function whatsClickButton(x, y)
        if isIn(button.Name.x1, button.Name.y1, button.Name.x2, button.Name.y2, x, y) then
                return "name"
        elseif isIn(button.Clear.x1, button.Clear.y1, button.Clear.x2, button.Clear.y2, x, y) then
                return "clear"
        elseif isIn(button.IsEmitRedstone.x1, button.IsEmitRedstone.y1, button.IsEmitRedstone.x2, button.IsEmitRedstone.y2, x, y) then
                return "redstone"
        elseif isIn(button.IsButtonMode.x1, button.IsButtonMode.y1, button.IsButtonMode.x2, button.IsButtonMode.y2, x, y) then
                return "buttonMode"
        elseif isIn(button.Light.x1, button.Light.y1, button.Light.x2, button.Light.y2, x, y) then
                return "light"
        elseif isIn(button.Texture.x1, button.Texture.y1, button.Texture.x2, button.Texture.y2, x, y) then
                return "texture"
        elseif isIn(button.State.x1, button.State.y1, button.State.x2, button.State.y2, x, y) then
                return "state"
        elseif isIn(button.Print.x1, button.Print.y1, button.Print.x2, button.Print.y2, x, y) then
                return "print"
        else
                return "fail"
        end
end
 
local function whatsClick(x, y)
        local mainScreenX, mainScreenY = whatsClickMain(x/2, y)
        if mainScreenX ~= "fail" then
                return "main", mainScreenX, mainScreenY
        end
        local shape = {whatsClickShape(x, y)}
        if shape[1] ~= "fail" then
                return "shape", shape[2]
        end
 
        local button = whatsClickButton(x, y)
        if button ~= "fail" then
                return "button", button
        end
end
 
local function textInCount(text)
        return
end
 
------------------------------Изичные функции-----------------------------------------
local function getPosXForShapeButton(i)
        local x
        x = i % 6 * 5
        return x
end
 
local function getPosYForShapeButton(i)
        local y
        y = math.floor(i / 6) * 3
        return y
end
------------------------------------Прорисовка кнопок и окон---------------------
local function drawLayerBar(x, y, number)
        gpu.setBackground(0x111111)
        gpu.setForeground(0xff0000)
        gpu.set(x-7, y-1, "                 ")
        gpu.set(x-7, y, " Слой:           ")
        gpu.set(x-7, y+1, "                 ")
        gpu.setBackground(0xffffff)
        gpu.setForeground(0x000000)
        if number < 10 then
                gpu.set(x, y, "    "..tostring(number).."   ")
        else
                gpu.set(x, y, "   "..tostring(number).."   ")
        end
end
 
local function drawShapeButton(x, y, number)
        if number ~= onlineShape then
                gpu.setBackground(0x111111)
                gpu.setForeground(0xffffff)
        else
                gpu.setBackground(colors[number])
                gpu.setForeground(0xffffff)
        end
        if number < 10 then
                gpu.set(x, y, "  "..tostring(number).." ")
        else
                gpu.set(x, y, " "..tostring(number).." ")
        end    
end
 
local function calculateButtons(x, y)
        x = x * 2
        for i = 1, 24 do
                doingShapes[i] = {
                        x = x + getPosXForShapeButton(i - 1),
                        y = y + getPosYForShapeButton(i - 1),
                        isNil = true,
                        texture = "quartz_block_top",
                        state = false
                }
        end
end
 
local function drawShapeButtonsList()
        for i = 1, 24 do
                drawShapeButton(doingShapes[i].x, doingShapes[i].y, i)
        end
end
 
local function drawButtons(xN, yN, xC, yC, xR, yR, xB, yB, xL, yL, xT, yT, xS, yS, xP, yP)
        local function takeColorFromBool(bool)
                if bool == false then
                        return 0x111111
                else
                        return 0x00dd00
                end
        end
        button.Name.x1, button.Name.y1, button.Name.x2, button.Name.y2 = ecs.drawButton(xN, yN, 21, 3, button.Name.text, 0x111111, 0xffffff)
        button.Clear.x1, button.Clear.y1, button.Clear.x2, button.Clear.y2 = ecs.drawButton(xC, yC, 21, 3, button.Clear.text, 0x111111, 0xffffff)
        button.IsEmitRedstone.x1, button.IsEmitRedstone.y1, button.IsEmitRedstone.x2, button.IsEmitRedstone.y2 = ecs.drawButton(xR, yR, 21, 3, button.IsEmitRedstone.text, takeColorFromBool(userData.emitRedstone), 0xffffff)
        button.IsButtonMode.x1, button.IsButtonMode.y1, button.IsButtonMode.x2, button.IsButtonMode.y2 = ecs.drawButton(xB, yB, 21, 3, button.IsButtonMode.text, takeColorFromBool(userData.buttonMode), 0xffffff)
        button.Light.x1, button.Light.y1, button.Light.x2, button.Light.y2 = ecs.drawButton(xL, yL, 10, 7, button.Light.text, takeColorFromBool(userData.light), 0xffffff)
        button.Texture.x1, button.Texture.y1, button.Texture.x2, button.Texture.y2 = ecs.drawButton(xT, yT, 21, 3, button.Texture.text, 0x111111, 0xffffff)
        button.State.x1, button.State.y1, button.State.x2, button.State.y2 = ecs.drawButton(xS, yS, 21, 3, button.State.text, takeColorFromBool(doingShapes[onlineShape].state), 0xffffff)
        button.Print.x1, button.Print.y1, button.Print.x2, button.Print.y2 = ecs.drawButton(xP, yP, 45, 3, button.Print.text, 0x111111, 0xffffff)
end
 
local function digitToText(numb)
        if numb > 31 and numb < 127 then
                return unicode.char(numb)
        else
                return ""
        end
end
 
local function updateState()
        local color = 0x111111
        if doingShapes[onlineShape].state == true then
                color = 0x00dd00
        end
        ecs.drawButton(button.State.x1, button.State.y1, 21, 3, button.State.text, color, 0xffffff)
end
 
-------------------------------------------Главный экран-----------------------------------
local function drawShapeScreen(numberShape, numberLayer)
        for xShape = 1, 16 do
                for yShape = 1, 16 do
                        local color = 0x9f8f8f
                        if doingShapes[numberShape].isNil == false then
                                if doingShapes[numberShape].x1 == xShape and doingShapes[numberShape].y1 == yShape and doingShapes[numberShape].z1 == numberLayer then
                                        color = 0xffffff
                                elseif doingShapes[numberShape].x2 == xShape and doingShapes[numberShape].y2 == yShape and doingShapes[numberShape].z2 == numberLayer then
                                        color = 0x000000
                                elseif inDiapason(doingShapes[numberShape].x1, doingShapes[numberShape].x2, xShape) and inDiapason(doingShapes[numberShape].y1, doingShapes[numberShape].y2, yShape) and inDiapason(doingShapes[numberShape].z1, doingShapes[numberShape].z2, numberLayer) then
                                        color = colors[numberShape]
                                end
                        end
                        Square((xShape - 1) * 3 + 2, (yShape - 1) * 3 + 2, 3, 3, color)
                end
        end
       
end
---------------------------------------------Холограмма------------------------------------
local function converForPrinter(oldShapes)
        for i = 1, 24 do
                if oldShapes[i].isNil == false then
                        local x1 = math.min(oldShapes[i].x1, oldShapes[i].x2)
                        local x2 = math.max(oldShapes[i].x1, oldShapes[i].x2)
                        local y1 = math.min(oldShapes[i].y1, oldShapes[i].y2)
                        local y2 = math.max(oldShapes[i].y1, oldShapes[i].y2)
                        local z1 = math.min(oldShapes[i].z1, oldShapes[i].z2)
                        local z2 = math.max(oldShapes[i].z1, oldShapes[i].z2)
                        oldShapes[i].x1 = x1
                        oldShapes[i].x2 = x2
                        oldShapes[i].y1 = y1
                        oldShapes[i].y2 = y2
                        oldShapes[i].z1 = z1
                        oldShapes[i].z2 = z2
                end
        end    
        return oldShapes
end
 
local function ShapeInHolo(numb, shapes)
        if numb == onlineShape then
                holo.setPaletteColor(3, colors[numb])
                for zHolo = shapes[numb].z1, shapes[numb].z2 do
                        for xHolo = shapes[numb].x1, shapes[numb].x2 do
                                holo.fill(xHolo + startHolo, zHolo + startHolo, 32 - shapes[numb].y2, 32 - shapes[numb].y1, 3)
                        end
                end            
        else
                for zHolo = shapes[numb].z1, shapes[numb].z2 do
                        for xHolo = shapes[numb].x1, shapes[numb].x2 do
                                holo.fill(xHolo + startHolo, zHolo + startHolo, 32 - shapes[numb].y2, 32 - shapes[numb].y1, 1)
                        end            
                end    
        end
end
 
local function ShapeUgli(number)
        holo.set(doingShapes[number].x1 + startHolo, 32 - doingShapes[number].y1, doingShapes[number].z1 + startHolo, 2)
        holo.set(doingShapes[number].x2 + startHolo, 32 - doingShapes[number].y2, doingShapes[number].z2 + startHolo, 2)
end
 
local function AllShapesInHolo(color, color2)
        holo.clear()
        holo.setPaletteColor(1, color)
        holo.setPaletteColor(2, color2)
        for numb = 1, 24 do
                if doingShapes[numb].isNil == false then
                        ShapeInHolo(numb, converForPrinter(doingShapes))
                end
        end
        for numb = 1, 24 do
                if doingShapes[numb].isNil == false then
                        ShapeUgli(numb)
                end
        end
end
---------------------------------------Принтер-------------------------------------------
 
local function inputData(newLabel, newTooltip, newEmitRedstone, newButtonMode, newLight, shapes)
        printer.reset()
        printer.setLabel(newLabel)
        printer.setTooltip(newTooltip)
        if newLight == true then
                printer.setLightLevel(8)
        else
                printer.setLightLevel(0)
        end
        printer.setRedstoneEmitter(newEmitRedstone)
        printer.setButtonMode(newButtonMode)
        local normShapes = converForPrinter(shapes)
        for i = 1, 24 do
                if normShapes[i].isNil == false then
                        printer.addShape(normShapes[i].x1 - 1, 16 - (normShapes[i].y1 - 1), 16 - normShapes[i].z1 - 1, normShapes[i].x2, 16 - normShapes[i].y2, 16 - normShapes[i].z2, normShapes[i].texture, normShapes[i].state, 0xffffff)
                end
        end
end
 
local function print(count)
        printer.commit(count)
end
 
-----------------------------------------Функция для вызова окна с дописывающимся текстом---------------------------------------
 
local function WindowForIT(x, y, title, buttonText, arrayOfWords, countOfVars)
        local mainColor = 0x0024ff
        local gray1 = 0xa5a5a5
        local gray2 = 0xf0f0f0
        local width = 40
        local height = 4
       
        local text = ""
        local oldPixels = ecs.rememberOldPixels(x - width/2, y - height/2, x + width/2 + 1, y + height/2 + 1)
 
        ecs.square(x - width/2, y - height/2, width, height, 0xffffff)
        ecs.colorTextWithBack(x - (width/2 - 2), y - height/2, mainColor, 0xffffff, title)
        ecs.square(x - (width/2 - 3), y, width - 13, 1, gray1)
        local button = {ecs.drawAdaptiveButton(x + (width/2 - 7), y, 2, 0, buttonText, mainColor, 0xffffff)}
        ecs.windowShadow(x - width/2, y - height/2, width, height)
       
        local VariontsOldPixels = {}
        for i = 1, countOfVars do
                table.insert(VariontsOldPixels, i, ecs.rememberOldPixels(x - (width/2 - 3), y + i, x + width/2 - 11, y + i))
        end
       
        local function completeText(wrdPart, wrds, count)
                local massiv = {}
                if wrdPart ~= "" then
                        for i = 1, #wrds do
                                if #massiv < count then
                                        local answer = unicode.sub(wrds[i], 1, unicode.len(wrdPart))
                                        if answer == wrdPart then
                                                table.insert(massiv, wrds[i])
                                        end
                                end
                        end
                end
                return massiv
        end
 
        local function drawVariants(x, y, width, textPart, count)
                local massivText = completeText(textPart, arrayOfWords, count)
                for i = 1, count do
                        if massivText[i] ~= nil then
                                ecs.square(x, y + i - 1, width, 1, gray2)
                                ecs.colorTextWithBack(x + 1, y + i - 1, 0x000000, gray2, massivText[i])
                        end
                end
                if #massivText == 0 then
                        for i = 1, count do
                                ecs.drawOldPixels(VariontsOldPixels[i])
                        end
                elseif #massivText ~= count then
                        for i = #massivText + 1, count do
                                ecs.drawOldPixels(VariontsOldPixels[i])
                        end
                end
        end
       
        while true do
                local event = {event.pull()}
                if event[1] == "key_down" then                         
                        if event[4] == 28 then
                                ecs.drawOldPixels(oldPixels)
                                if text ~= "" and text ~= nil then
                                        return text
                                else
                                        return nil
                                end
                        elseif event[4] == 14 then
                                local dlina = unicode.len(text)
                                if dlina ~= 0 then
                                        text = unicode.sub(text, 1, unicode.len(text) - 1)
                                        ecs.colorTextWithBack(x - (width/2 - 4) + unicode.len(text), y,
0xffffff, gray1, "  ")                                 
                                end
                        elseif event[3] > 31 and event[3] < 127 then
                                text = text..unicode.char(event[3])
                        end
                        ecs.colorTextWithBack(x - (width/2 - 4), y, 0x000000, gray1, text.."|")
                        drawVariants(x - (width/2 - 3), y + 1, width - 13, text, countOfVars)
                end
                if event[1] == "touch" and ecs.clickedAtArea(event[3], event[4], button[1], button[2], button[3], button[4]) then
                        ecs.drawOldPixels(oldPixels)
                        if text ~= "" and text ~= nil then
                                return text
                        else
                                return 0
                        end
                end
        end
end
 
 
 
 
-----------------------------------------------Прога-----------------------------
ecs.prepareToExit()
Square(1, 1, xSize - rightPartSize, ySize, 0xffffff)
ecs.colorTextWithBack(xSize*2 - 59, 3,0xffffff, 0x000000,   "   Для данной модели                                        ")
ecs.colorTextWithBack(xSize*2 - 59, 13, 0xffffff, 0x000000, "   Для данного объекта                                      ")
ecs.colorTextWithBack(xSize*2 - 59, 24, 0xffffff, 0x000000, "   Объекты                                                  ")
calculateButtons(xSize - 21, ySize - 18)
drawButtons(xSize*2 - 57, 5, xSize*2 - 33, 5, xSize*2 - 57, 9, xSize*2 - 33, 9, xSize*2 - 10, 5, xSize*2 - 57, 15, xSize*2 - 33, 15, xSize*2 - 57, 19)
drawShapeButtonsList()
drawShapeScreen(onlineShape, onlineLayer)
drawLayerBar(xSize*2 - 30, 28, onlineLayer)
holo.clear()
 
while true do
        local event = {event.pull()}
        if event[1] == "touch" then
                local case = {whatsClick(event[3], event[4])}
                if case[1] == "main" then
                        if mode == false then
                                doingShapes[onlineShape].x1 = case[2]
                                doingShapes[onlineShape].y1 = case[3]
                                doingShapes[onlineShape].z1 = onlineLayer
                                doingShapes[onlineShape].x2 = case[2]
                                doingShapes[onlineShape].y2 = case[3]
                                doingShapes[onlineShape].z2 = onlineLayer
                                doingShapes[onlineShape].isNil = false
                                mode = true
                        else
                                doingShapes[onlineShape].x2 = case[2]
                                doingShapes[onlineShape].y2 = case[3]
                                doingShapes[onlineShape].z2 = onlineLayer
                                doingShapes[onlineShape].isNil = false
                                mode = false
                                AllShapesInHolo(0x00ff00, 0xffffff)
                        end
                        drawShapeScreen(onlineShape, onlineLayer)
                elseif case[1] == "shape" then
                        onlineShape = case[2]
                        drawShapeButtonsList()
                        updateState()
                        AllShapesInHolo(0x00ff00, 0xffffff)
                elseif case[1] == "button" then
                        if case[2] == "name" then
                                ecs.drawButton(button.Name.x1, button.Name.y1, 21, 3, button.Name.text, 0x00dd00, 0xffffff)
                                local New = ecs.input("auto", "auto", 20, "Ок", {"input", "Имя", "Printered Block"}, {"input", "Описание", "byShahar"})
                                if New[1] ~= "" and New[1] ~= nil then
                                        userData.label = New[1]
                                        Text(150, 1, completeWord(New[1], textures), 0xffffff, 0x000000)
                                end
                                if New[2] ~= "" and New[2] ~= nil then
                                        userData.tooltip = New[2]
                                end
                                ecs.drawButton(button.Name.x1, button.Name.y1, 21, 3, button.Name.text, 0x111111, 0xffffff)
                        elseif case[2] == "clear" then
                                ecs.drawButton(button.Clear.x1, button.Clear.y1, 21, 3, button.Clear.text, 0x00dd00, 0xffffff)
                                doingShapes = {}
                                userData = {
                                        label = "Printered Block",
                                        tooltip = "byShahar",
                                        light = false,
                                        emitRedstone = false,
                                        buttonMode = false,
                                }
                                local button = {
                                        Name = {text = "Имя", x1, y1, x2, y2},
                                        Clear = {text = "Очистить", x1, y1, x2, y2},
                                        IsEmitRedstone = {text = "Излучает Redstone", x1, y1, x2, y2},
                                        IsButtonMode = {text = "Режим кнопки", x1, y1, x2, y2},
                                        Light = {text = "Свет", x1, y1, x2, y2},
                                        Texture = {text = "Текстура", x1, y1, x2, y2},
                                        State = {text = "Статус", x1, y1, x2, y2},
                                        Print = {text = "Готово", x1, y1, x2, y2},
                                }
                                ecs.prepareToExit()
                                Square(1, 1, xSize - rightPartSize, ySize, 0xffffff)
                                ecs.colorTextWithBack(xSize*2 - 59, 3,0xffffff, 0x000000,   "   Для данной модели                                        ")
                                ecs.colorTextWithBack(xSize*2 - 59, 13, 0xffffff, 0x000000, "   Для данного объекта                                      ")
                                ecs.colorTextWithBack(xSize*2 - 59, 25, 0xffffff, 0x000000, "   Объекты                                                  ")
                                calculateButtons(xSize - 21, ySize - 18)
                                drawButtons(xSize*2 - 57, 5, xSize*2 - 33, 5, xSize*2 - 57, 9, xSize*2 - 33, 9, xSize*2 - 10, 5, xSize*2 - 57, 15, xSize*2 - 33, 15, xSize*2 - 57, 19)
                                drawShapeButtonsList()
                                drawShapeScreen(onlineShape, onlineLayer)
                                drawLayerBar(xSize*2 - 30, 28, onlineLayer)
                                holo.clear()
                        elseif case[2] == "redstone" then
                                if userData.emitRedstone == false then
                                        userData.emitRedstone = true
                                        ecs.drawButton(button.IsEmitRedstone.x1, button.IsEmitRedstone.y1, 21, 3, button.IsEmitRedstone.text, 0x00dd00, 0xffffff)
                                else
                                        userData.emitRedstone = false
                                        ecs.drawButton(button.IsEmitRedstone.x1, button.IsEmitRedstone.y1, 21, 3, button.IsEmitRedstone.text, 0x111111, 0xffffff)
                                end
                        elseif case[2] == "buttonMode" then
                                if userData.buttonMode == false then
                                        userData.buttonMode = true
                                        ecs.drawButton(button.IsButtonMode.x1, button.IsButtonMode.y1, 21, 3, button.IsButtonMode.text, 0x00dd00, 0xffffff)
                                else
                                        userData.buttonMode = false
                                        ecs.drawButton(button.IsButtonMode.x1, button.IsButtonMode.y1, 21, 3, button.IsButtonMode.text, 0x111111, 0xffffff)
                                end
                        elseif case[2] == "texture" then
                                doingShapes[onlineShape].texture = WindowForIT(xSize, ySize/2, "Введите название текстуры", "Ок", textures, 3)
                        elseif case[2] == "light" then
                                if userData.light == false then
                                        userData.light = true
                                        ecs.drawButton(button.Light.x1, button.Light.y1, 10, 7, button.Light.text, 0x00dd00, 0xffffff)
                                else
                                        userData.light = false
                                        ecs.drawButton(button.Light.x1, button.Light.y1, 10, 7, button.Light.text, 0x111111, 0xffffff)
                                end
                        elseif case[2] == "state" then
                                if doingShapes[onlineShape].state == true then
                                        doingShapes[onlineShape].state = false
                                else
                                        doingShapes[onlineShape].state = true
                                end
                                updateState()
                        elseif case[2] == "print" then
                                ecs.drawButton(button.Print.x1, button.Print.y1, 45, 3, button.Print.text, 0x00dd00, 0xffffff)
                                inputData(userData.label, userData.tooltip, userData.emitRedstone, userData.buttonMode, userData.light, doingShapes)
                                print(1)
                                ecs.drawButton(button.Print.x1, button.Print.y1, 45, 3, button.Print.text, 0x111111, 0xffffff)
                        end
                end
        elseif event[1] == "scroll" then
                onlineLayer = onlineLayer - event[5]
                if onlineLayer < 1 then
                        onlineLayer = 1
                elseif onlineLayer > 16 then
                        onlineLayer = 16
                else
                        drawShapeScreen(onlineShape, onlineLayer)
                        drawLayerBar(xSize*2 - 30, 28, onlineLayer)
                end
        end
end
