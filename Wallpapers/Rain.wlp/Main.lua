local screen = require("Screen")
local color = require("Color")
local filesystem = require("Filesystem")
local system = require("System")
local GUI = require("GUI")

--------------------------------------------------------------------------------

local configPath = filesystem.path(system.getCurrentScript()) .. "Config.cfg"

local config = {
    dropAmount = 50,
    dropColor = 0x00AAFF,
    backgroundColor = 0x0F0F0F,
    speed = 1
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

local drops = {}
local lastUpdateTime = computer.uptime()

return {
    draw = function(object)
        -- Spawning drops
        for i = 1, config.dropAmount - #drops do
            local distance = math.random()

            table.insert(drops, {
                x = math.random(object.width) - 1,
                y = 0,
                speed = 50 - 40 * distance,
                color = color.transition(config.dropColor, config.backgroundColor, .2 + .8 * distance)
            })
        end

        -- Clear the area
        screen.drawRectangle(object.x, object.y, object.width, object.height, config.backgroundColor, 0, " ")

        -- Rendering drops
        for index, drop in pairs(drops) do
            local x, y = math.floor(drop.x), math.floor(drop.y)

            screen.set(
                object.x + x,
                object.y + y,
                config.backgroundColor, 
                drop.color,
                (x == object.width - 1 or y == object.height - 1) and '*' or '\\'
            )
        end

        -- Updating drops
        local currentTime = computer.uptime()
        local deltaTime = currentTime - lastUpdateTime
        
        for index, drop in pairs(drops) do
            drop.x = drop.x + drop.speed * config.speed * deltaTime
            drop.y = drop.y + drop.speed * config.speed * deltaTime

            if drop.x < 0 then
                drop.x = object.width - drop.x
            elseif drop.x >= object.width then
                drop.x = object.width - drop.x
            end

            if drop.y < 0 or drop.y >= object.height then
                table.remove(drops, index)
            end
        end

        lastUpdateTime = currentTime
    end,

    configure = function(layout)
        layout:addChild(GUI.colorSelector(1, 1, 36, 3, config.backgroundColor, "Background color")).onColorSelected = function(_, object)
			config.backgroundColor = object.color
			saveConfig()
		end

		layout:addChild(GUI.colorSelector(1, 1, 36, 3, config.dropColor, "Drop color")).onColorSelected = function(_, object)
			config.dropColor = object.color
			saveConfig()
		end

        local dropAmountSlider = layout:addChild(
			GUI.slider(
				1, 1, 
				36,
				0x66DB80, 
				0xE1E1E1, 
				0xFFFFFF, 
				0xA5A5A5, 
				10, 500, 
				config.dropAmount, 
				false, 
				"Drop amount: "
			)
		)
		
		dropAmountSlider.roundValues = true
		dropAmountSlider.onValueChanged = function()
			config.dropAmount = math.floor(dropAmountSlider.value)
			saveConfig()
		end

        local speedSlider = layout:addChild(
            GUI.slider(
				1, 1, 
				36,
				0x66DB80, 
				0xE1E1E1, 
				0xFFFFFF, 
				0xA5A5A5, 
				20, 200, 
				config.speed * 100,
				false, 
				"Speed: ",
                "%"
            )
        )

        speedSlider.roundValues = true
        speedSlider.onValueChanged = function()
            config.speed = speedSlider.value / 100
            saveConfig()
        end
    end
}

--------------------------------------------------------------------------------