local screen = require("Screen")
local fs = require("Filesystem")
local system = require("System")
local GUI = require("GUI")

local wallpaper = {}

--------------------------------------------------------------------------------

local configPath = fs.path(system.getCurrentScript()) .. "Config.cfg"

local function saveConfig()
    fs.writeTable(configPath, wallpaper.config)
end

if fs.exists(configPath) then
    wallpaper.config = fs.readTable(configPath)
else
    wallpaper.config = {
        backgroundColor = 0x161616,
        lineCount = 10,
        lineColor = 0xFFFFFF
    }
end

--------------------------------------------------------------------------------

local function reset()
    wallpaper.points = {}

    local resX, resY = screen.getResolution()
    for i = 1, wallpaper.config.lineCount do
        table.insert(wallpaper.points, {
            x = math.random(0, resX-1),
            y = math.random(0, resY-1),
            vx = (2 * math.random() - 1) * 25,
            vy = (2 * math.random() - 1) * 25
        })
    end

    wallpaper.lastUpdateTime = computer.uptime()
end

reset(object)

function wallpaper.draw(object)
    screen.drawRectangle(object.x, object.y, object.width, object.height, wallpaper.config.backgroundColor, 0, " ")

    for i = 1, wallpaper.config.lineCount - 1 do
        screen.drawSemiPixelLine(
            math.floor(wallpaper.points[i  ].x), math.floor(wallpaper.points[i  ].y),
            math.floor(wallpaper.points[i+1].x), math.floor(wallpaper.points[i+1].y),
            wallpaper.config.lineColor
        )
    end

    local currentTime = computer.uptime()
    local dt = currentTime - wallpaper.lastUpdateTime
    wallpaper.lastUpdateTime = currentTime

    for i = 1, wallpaper.config.lineCount do
        local point = wallpaper.points[i]

        point.x = point.x + point.vx * dt
        point.y = point.y + point.vy * dt

        if point.x < 0 or point.x >= object.width  then point.vx = -point.vx end
        if point.y < 0 or point.y >= object.height then point.vy = -point.vy end
    end
end

function wallpaper.configure(layout)
    layout:addChild(GUI.colorSelector(1, 1, 36, 3, wallpaper.config.backgroundColor, "Background color")).onColorSelected = function(_, object)
        wallpaper.config.backgroundColor = object.color
        saveConfig()
    end

    layout:addChild(GUI.colorSelector(1, 1, 36, 3, wallpaper.config.lineColor, "Line color")).onColorSelected = function(_, object)
        wallpaper.config.lineColor = object.color
        saveConfig()
    end

    local slider = layout:addChild(
        GUI.slider(
            1, 1, 
            36,
            0x66DB80, 
            0xE1E1E1, 
            0xFFFFFF, 
            0xA5A5A5, 
            1, 10, 
            wallpaper.config.lineCount, 
            false, 
            "Line count: "
        )
    )
    
    slider.roundValues = true

    slider.onValueChanged = function(workspace, object)
        wallpaper.config.lineCount = math.floor(object.value)
        saveConfig()
        reset()
    end
end

--------------------------------------------------------------------------------

return wallpaper