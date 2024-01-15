local screen = require("Screen")
local filesystem = require("Filesystem")
local system = require("System")
local GUI = require("GUI")

--------------------------------------------------------------------------------

local configPath = filesystem.path(system.getCurrentScript()) .. "Config.cfg"

local config = {
    backgroundColor = 0x161616,
    lineCount = 10,
    lineColor = 0xFFFFFF
}

if filesystem.exists(configPath) then
    for key, value in pairs(filesystem.readTable(configPath)) do
        config[key] = value
    end
end

local function saveConfig()
    filesystem.writeTable(configPath, config)
end

--------------------------------------------------------------------------------

local points = {}
local lastUptime = computer.uptime()

local function reset()
    points = {}

    local resX, resY = screen.getResolution()
    for i = 1, config.lineCount do
        table.insert(points, {
            x = math.random(0, resX - 1),
            y = math.random(0, (resY - 1) * 2),
            vx = (2 * math.random() - 1) * 25,
            vy = (2 * math.random() - 1) * 25
        })
    end

    lastUptime = computer.uptime()
end

reset(object)

--------------------------------------------------------------------------------

return {
    draw = function(object)
        screen.drawRectangle(object.x, object.y, object.width, object.height, config.backgroundColor, 0, " ")

        local point1, point2

        for i = 1, config.lineCount - 1 do
            point1, point2 = points[i], points[i + 1]

            screen.drawSemiPixelLine(
                math.floor(object.x + point1.x),
                math.floor(object.y * 2 - 1 + point1.y),

                math.floor(object.x + point2.x),
                math.floor(object.y * 2 - 1 + point2.y),
                
                config.lineColor
            )

            screen.semiPixelSet(
                math.floor(object.x + point1.x),
                math.floor(object.y * 2 - 1 + point1.y),
                
                0x880000
            )

            screen.semiPixelSet(
                math.floor(object.x + point2.x),
                math.floor(object.y * 2 - 1 + point2.y),
                
                0x008800
            )
        end

        local uptime = computer.uptime()
        local deltaTime = uptime - lastUptime
        lastUptime = uptime

        for i = 1, config.lineCount do
            point1 = points[i]

            point1.x = point1.x + point1.vx * deltaTime
            point1.y = point1.y + point1.vy * deltaTime

            if point1.x < 0 or point1.x >= object.width then point1.vx = -point1.vx end
            if point1.y < 0 or point1.y >= object.height * 2 then point1.vy = -point1.vy end
        end
    end,

    configure = function(layout)
        layout:addChild(GUI.colorSelector(1, 1, 36, 3, config.backgroundColor, "Background color")).onColorSelected = function(_, object)
            config.backgroundColor = object.color
            saveConfig()
        end

        layout:addChild(GUI.colorSelector(1, 1, 36, 3, config.lineColor, "Line color")).onColorSelected = function(_, object)
            config.lineColor = object.color
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
                config.lineCount, 
                false, 
                "Line count: "
            )
        )
        
        slider.roundValues = true

        slider.onValueChanged = function(workspace, object)
            config.lineCount = math.floor(object.value)
            saveConfig()
            reset()
        end
    end
}