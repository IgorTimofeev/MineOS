local component = require("component")
local event = require("event")
local gpu = component.gpu
local ecs = require("ECSAPI")

local xOld, yOld = gpu.getResolution()
local xSize, ySize
local circles = {}
local bg, fg, mode, speed

--============================  Ф У Н К Ц И И  ==============================--

local function tanci()
    -- отрисовка кругов
    local function draw()
        gpu.setBackground(bg)
        gpu.fill(1, 1, xSize*2, ySize, " ")
        
        for i=#circles, 1, -1 do
            local x = circles[i][1]+1
            local y = circles[i][2]-circles[i][4]+2
            gpu.setBackground(circles[i][3])
            
            for c=1, (circles[i][4]-1)*4 do
                if x>0 and x<=(xSize*2) then
                    if y>0 and y<=ySize then
                        gpu.set((x)*2 - 1, y, "  ")
                    end
                end
                -- следующий "пиксель" круга
                if x>circles[i][1] then
                    if y<circles[i][2] then
                        x = x+1
                    else
                        x = x-1
                    end
                    y = y+1
                else
                    if y>circles[i][2] then
                        x = x-1
                    else
                        x = x+1
                    end
                    y = y-1
                end
            end

            circles[i][4] = circles[i][4] + 1
            if circles[i][4] > xSize then table.remove(circles, i) end
        end
    end

    while true do
        -- обработка сигналов
        local e = {event.pull(speed)}
        
        if e[1] == "touch" then
            table.insert(circles, {e[3] / 2, e[4], math.random(0xffffff), 1})
        elseif e[1] == "walk" then
            table.insert(circles, {e[3], e[4], math.random(0xffffff), 1})
        elseif e[1] == "key_down" then
            if e[4] == 28 then break end
        end
        
        draw()
    end
end

local function shahmati()
    local c1 = 0x000000
    local c2 = 0xffffff
    for j = 1, ySize do
        for i = 1, xSize do
            circles[j] = circles[j] or {}
            if j % 2 == 0 then
                if i % 2 == 0 then
                    circles[j][i] = c1
                else
                    circles[j][i] = c2
                end
            else
                if i % 2 == 0 then
                    circles[j][i] = c2
                else
                    circles[j][i] = c1
                end
            end
        end
    end

    local function cyka()
        for j = 1, #circles do
            for i = 1, #circles[j] do
                circles[j][i] = 0xffffff - circles[j][i]
                gpu.setBackground(circles[j][i])
                gpu.set(i*2 - 1, j, "  ")
            end
        end
    end

    cyka()

    while true do
        local e = {event.pull(speed)}
        
        if e[1] == "touch" then
            circles[e[4]][e[3] / 2] = math.random(0xffffff)
        elseif e[1] == "walk" then
            circles[e[4]][e[3]] = math.random(0xffffff)
        elseif e[1] == "key_down" then
            if e[4] == 28 then break end
        end
        
        cyka()
    end
end

local function spidi()
    local function cyka()
        for j = 1, ySize do
            for i = 1, xSize do
                gpu.setBackground(math.random(0xffffff))
                gpu.set(i*2 - 1, j, "  ")
            end
        end
    end

    cyka()

    while true do
        local e = {event.pull(speed)}
        
        if e[1] == "key_down" then
            if e[4] == 28 then break end
        end
        
        cyka()
    end
end

local function beg()
    local function cyka()
        local cyka2 = {bg, fg}
        gpu.copy(1,1,xSize*2,ySize, 2, 0)
        for j = 1, ySize do
            gpu.setBackground(cyka2[math.random(1, 2)])
            gpu.set(1, j, "  ")
        end
    end

    cyka()

    while true do
        local e = {event.pull(speed)}
        
        if e[1] == "key_down" then
            if e[4] == 28 then break end
        end
        
        cyka()
    end
end

--===========================================================================--

local data = ecs.universalWindow("auto", "auto", 36, 0xeeeeee, true,
    {"EmptyLine"},
    {"CenterText", 0x880000, "Танцпол v1.0"},
    {"EmptyLine"},
    {"CenterText", 0x262626, "Реагинует на хождение"},
    {"CenterText", 0x262626, "по экрану и прикосновение к нему,"},
    {"CenterText", 0x262626, "для выхода удерживайте Enter"},
    {"EmptyLine"},
    {"Selector", 0x262626, 0x880000, "ШАХМАТЫ", "СПИДЫ", "ТАНЦЫ", "БЕГ"},
    {"Color", "Цвет 1", 0x000000},
    {"Color", "Цвет 2", 0xFFFFFF},
    {"Slider", 0x262626, 0x880000, 1, 100, 100, "Скорость ", " FPS"},
    {"EmptyLine"},
    {"Button", {0x888888, 0xffffff, "OK"}, {0xaaaaaa, 0xffffff, "Отмена"}}
)

if data[5] == "OK" then
    mode = data[1]
    bg = data[2]
    fg = data[3]
    speed = (102 - tonumber(data[4])) / 100
else
    ecs.prepareToExit()
    return
end

xSize, ySize = component.screen.getAspectRatio()
gpu.setResolution(xSize * 2, ySize)
gpu.fill(1, 1, 16, 6, " ")

if mode == "СПИДЫ" then
    spidi()
elseif mode == "ТАНЦЫ" then
    tanci()
elseif mode == "ШАХМАТЫ" then
    shahmati()
elseif mode == "БЕГ" then
    beg()
end

gpu.setResolution(xOld, yOld)
ecs.prepareToExit()





