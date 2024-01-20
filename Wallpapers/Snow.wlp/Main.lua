local screen = require("Screen")
local color = require("Color")
local filesystem = require("Filesystem")
local system = require("System")
local GUI = require("GUI")

--------------------------------------------------------------------------------

local configPath = filesystem.path(system.getCurrentScript()) .. "Config.cfg"

local config = {
    backgroundColor = 0x0F0F0F,
    snowflakeColor = 0xFFFFFF,
    snowflakeAmount = 20,
    maxStackHeight = 10,
    maxWind = 2
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

local mathRandom, mathFloor, tableInsert, tableRemove, screenSemiPixelSet, screenDrawSemiPixelRectangle = math.random, math.floor, table.insert, table.remove, screen.semiPixelSet, screen.drawSemiPixelRectangle

local snowflakes = {}
local stacks = {}
local wind = 0

local lastUpdateTime = computer.uptime()

return {
    draw = function(object)
        -- Spawning snowflakes
        for i = 1, config.snowflakeAmount - #snowflakes do
            local distance = math.random()

            tableInsert(snowflakes, {
                x = mathRandom(1, object.width) - 1,
                y = 0,
                color = color.transition(config.snowflakeColor, config.backgroundColor, .2 + .8 * distance),
                speed = 2 - 1.5 * distance,
                vx = 0
            })
        end

        -- Clear the area
        screen.drawRectangle(object.x, object.y, object.width, object.height, config.backgroundColor, 0, " ")

        -- Rendering snowflakes
        for index, snowflake in pairs(snowflakes) do
            local x, y = mathFloor(snowflake.x), mathFloor(snowflake.y)

            screenSemiPixelSet(
                object.x + x,
                object.y + y,
                snowflake.color
            )
        end
        
        local maxHeight = object.height * 2

        -- Rendering stacks
        local removeRow = mathRandom(1, 100) == 1
        for x, height in pairs(stacks) do
            screenDrawSemiPixelRectangle(object.x + x, object.y + object.height * 2 - height, 1, height, config.snowflakeColor)

            if height > config.maxStackHeight then
                stacks[x] = 0
            end
        end

        -- Updating snowflakes
        local currentTime = computer.uptime()
        local deltaTime = (currentTime - lastUpdateTime) * 20
        
        wind = wind + .1 * (2 * mathRandom() - 1) * deltaTime
        if wind >  config.maxWind then wind =  config.maxWind end
        if wind < -config.maxWind then wind = -config.maxWind end

        for index, snowflake in pairs(snowflakes) do
            snowflake.y = snowflake.y + deltaTime *         snowflake.speed 
            snowflake.x = snowflake.x + deltaTime * (wind * snowflake.speed + snowflake.vx)
            
            snowflake.vx = snowflake.vx + (mathRandom() * 2 - 1) * 0.1 * deltaTime
            if snowflake.vx >  1 then snowflake.vx =  1 end
            if snowflake.vx < -1 then snowflake.vx = -1 end
            
            if snowflake.x < 0 then
                snowflake.x = object.width - snowflake.x
            elseif snowflake.x >= object.width then
                snowflake.x = snowflake.x - object.width
            end
            
            local x, y = mathFloor(snowflake.x), mathFloor(snowflake.y)
            local stack = stacks[x] or 0
            if y >= maxHeight - stack then
                stacks[x] = stack + 1
                tableRemove(snowflakes, index)
            end
        end

        lastUpdateTime = currentTime
    end,

    configure = function(layout)
        layout:addChild(GUI.colorSelector(1, 1, 36, 3, config.backgroundColor, "Background color")).onColorSelected = function(_, object)
			config.backgroundColor = object.color
			saveConfig()
		end

		layout:addChild(GUI.colorSelector(1, 1, 36, 3, config.snowflakeColor, "Snowflake color")).onColorSelected = function(_, object)
			config.snowflakeColor = object.color
			saveConfig()
		end

        local snowflakeAmountSlider = layout:addChild(
			GUI.slider(
				1, 1, 
				36,
				0x66DB80, 
				0xE1E1E1, 
				0xFFFFFF, 
				0xA5A5A5, 
				5, 50, 
				config.snowflakeAmount, 
				false, 
				"Snowflake amount: "
			)
		)
		
		snowflakeAmountSlider.roundValues = true
		snowflakeAmountSlider.onValueChanged = function()
			config.snowflakeAmount = math.floor(snowflakeAmountSlider.value)
			saveConfig()
		end

        local maxStackHeightSlider = layout:addChild(
            GUI.slider(
				1, 1, 
				36,
				0x66DB80, 
				0xE1E1E1, 
				0xFFFFFF, 
				0xA5A5A5, 
				0, 50, 
				config.maxStackHeight, 
				false, 
				"Stack height limit: "
            )
        )

        maxStackHeightSlider.roundValues = true
		maxStackHeightSlider.onValueChanged = function()
			config.maxStackHeight = math.floor(maxStackHeightSlider.value)
			saveConfig()
		end
    end
}

--------------------------------------------------------------------------------