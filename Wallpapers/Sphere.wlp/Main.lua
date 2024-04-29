local screen = require("Screen")
local color = require("Color")
local filesystem = require("Filesystem")
local system = require("System")
local GUI = require("GUI")

--------------------------------------------------------------------------------

local workspace, wallpaper = select(1, ...), select(2, ...)

local configPath = filesystem.path(system.getCurrentScript()) .. "Config.cfg"

local config = {
    backgroundColor = 0x000000,

    sphereRadius = 20,
    sphereColor = 0xFFFFFF,
    spherePos = {20, 0, 0},
    
    lightColor = 0xFFFF40,
    diffuseIntensity = 12,
    ambientIntensity = 0.1,
    specularIntensity = 0.5,
    specularPower = 1,

    speed = 5
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

local function vecNormalize(vec)
    local length = (vec[1]^2 + vec[2]^2 + vec[3]^2)^0.5
    if length < 0.00001 then 
        length = 0.00001 
    end

    return {
        vec[1] / length,
        vec[2] / length,
        vec[3] / length
    }
end

local function vecSubtract(a, b)
    return {a[1] - b[1], a[2] - b[2], a[3] - b[3]}
end

local function vecAdd(a, b)
    return {a[1] + b[1], a[2] + b[2], a[3] + b[3]}
end

local function vecScalarProduct(vec, scalar)
    return {vec[1] * scalar, vec[2] * scalar, vec[3] * scalar}
end

local function vecHadamardProduct(a, b)
    return {a[1] * b[1], a[2] * b[2], a[3] * b[3]}
end

local function vecDotProduct(a, b)
    return a[1] * b[1] + a[2] * b[2] + a[3] * b[3]
end

local function vecSqrDistance(a, b)
    return (a[1] - b[1])^2 + (a[2] - b[2])^2 + (a[3] - b[3])^2
end

local function vecIntegerToRGB(integer)
    local r, g, b = color.integerToRGB(integer)
    return {
        r / 0xFF,
        g / 0xFF,
        b / 0xFF
    }
end

local function vecRGBToInteger(vec)
    return color.RGBToInteger(
        math.floor(vec[1] * 0xFF), 
        math.floor(vec[2] * 0xFF), 
        math.floor(vec[3] * 0xFF)
    )
end

local function clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

--------------------------------------------------------------------------------

local lightSpinRadius, sphereRadiusSqr, lightColorVec, sphereColorVec, colorProduct, viewPos, startTime

local function precalculateValues()
    lightSpinRadius = config.sphereRadius + 5
    sphereRadiusSqr = config.sphereRadius^2
    lightColorVec = vecIntegerToRGB(config.lightColor)
    sphereColorVec = vecIntegerToRGB(config.sphereColor)
    colorProduct = vecHadamardProduct(lightColorVec, sphereColorVec)
    viewPos = {0, 0, 500}
    startTime = computer.uptime()
end

precalculateValues()

--------------------------------------------------------------------------------

wallpaper.draw = function(wallpaper)
    local t = config.speed * (computer.uptime() - startTime) / 10
    
    local lightPos = {lightSpinRadius * math.cos(t), lightSpinRadius * 0.5 * math.cos(t), lightSpinRadius * math.sin(t)}
    local cx, cy = math.floor(wallpaper.width / 2), wallpaper.height

    screen.drawRectangle(wallpaper.x, wallpaper.y, wallpaper.width, wallpaper.height, config.backgroundColor, 0, " ")

    for x = -config.sphereRadius, config.sphereRadius do
        for y = -config.sphereRadius, config.sphereRadius do
            if x^2 + y^2 <= sphereRadiusSqr then
                local fragPos = {x, y, (config.sphereRadius^2 - x^2 - y^2)^0.5}

                local L  = vecNormalize(vecSubtract(lightPos, fragPos))
                local N  = vecNormalize(fragPos)
                local V  = vecNormalize(vecSubtract(viewPos, fragPos))
                local LN = vecDotProduct(L, N)
                local Lr = vecNormalize(vecSubtract(vecScalarProduct(N, 2 * LN), L))

                local distance = vecSqrDistance(lightPos, fragPos)

                local diffuse = clamp((LN / distance) * config.diffuseIntensity, 0, 1)
                local specular = clamp(vecDotProduct(Lr, V), 0, 1)^config.specularPower * config.specularIntensity

                local fragColor = vecScalarProduct(colorProduct, diffuse)
                fragColor = vecAdd(fragColor, vecScalarProduct(colorProduct, config.ambientIntensity))
                fragColor = vecAdd(fragColor, vecScalarProduct(lightColorVec, specular))

                screen.semiPixelSet(cx + x, cy + y, vecRGBToInteger(fragColor))
            end
        end
    end

    if lightPos[1]^2 + lightPos[2]^2 > sphereRadiusSqr or lightPos[3] > (config.sphereRadius^2 - lightPos[1]^2 - lightPos[2]^2)^0.5 then
        screen.semiPixelSet(cx + math.floor(lightPos[1]), cy + math.floor(lightPos[2]), config.lightColor)
    end
end

wallpaper.configure = function(layout)
    local function addColorSelector(configValue, title)
        layout:addChild(GUI.colorSelector(1, 1, 36, 3, config[configValue], title)).onColorSelected = function(_, object)
            config[configValue] = object.color
            saveConfig()
            precalculateValues()
        end
    end

    local function addSlider(configValue, title, minValue, maxValue, roundValues)
        local slider = layout:addChild(
            GUI.slider(
                1, 1, 
                36,
                0x66DB80, 
                0xE1E1E1, 
                0xFFFFFF, 
                0xA5A5A5, 
                minValue, maxValue, 
                config[configValue], 
                false,
                title
            )
        )
        
        slider.roundValues = roundValues
        slider.onValueChanged = function()
            if roundValues then
                config[configValue] = math.floor(slider.value)
            else
                config[configValue] = slider.value
            end

            saveConfig()
            precalculateValues()
        end
    end

    addColorSelector("backgroundColor", "Background color")
    addColorSelector("sphereColor",     "Sphere color"    )
    addColorSelector("lightColor",      "Light color"     )

    addSlider("sphereRadius",      "Sphere radius: ",      5, 50, true )
    addSlider("diffuseIntensity",  "Diffuse intensity: ",  0, 50, false)
    addSlider("ambientIntensity",  "Ambient intensity: ",  0, 1,  false)
    addSlider("specularIntensity", "Specular intensity: ", 0, 5,  false)
    addSlider("specularPower",     "Specular power: ",     1, 50, true )
    addSlider("speed",             "Speed: ",              1, 10, false)
end

--------------------------------------------------------------------------------