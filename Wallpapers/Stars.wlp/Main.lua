local screen = require("Screen")
local filesystem = require("Filesystem")
local GUI = require("GUI")
local system = require("System")
local color = require("Color")

--------------------------------------------------------------------------------

local configPath = filesystem.path(system.getCurrentScript()) .. "Config.cfg"

local config = {
	starAmount = 100,
	backgroundColor = 0x0F0F0F,
	starColor = 0xF0F0F0,
	delay = 0.05,
	offset = 0.01,
	speed = 100
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

-- Faster access without tables indexing
local computerUptime, tableRemove, mathSin, mathCos, mathRandom, screenUpdate = computer.uptime, table.remove, math.sin, math.cos, math.random

local braille1, braille2, braille3, braille4, braille5, braille6, braille7, braille8, braille9, braille10 = "⠁", "⠈", "⠂", "⠐", "⠄", "⠠", "⡀", "⢀", "⠛", "⣤"
local stars, deadline, colors

local function resetColors()
	-- This case uses default OC palette, which is based & redpilled
	if config.starColor >= 0xF0F0F0 then
		colors = {
			0x0F0F0F,
			0x1E1E1E,
			0x2D2D2D,
			0x3C3C3C,
			0x4B4B4B,
			0x5A5A5A,
			0x696969,
			0x787878,
			0x878787,
			0x969696,
			0xA5A5A5,
			0xB4B4B4,
			0xC3C3C3,
			0xD2D2D2,
			0xE1E1E1,
			0xF0F0F0
		}
	-- Otherwise palette will be auto-generated
	else
		colors = {}

		local colorCount = 16
		for i = 1, colorCount do
			colors[i] = color.transition(config.backgroundColor, config.starColor, (i - 1) / (colorCount - 1))
		end
	end
end

local function resetStars()
	stars = {}
	deadline = 0
end

resetColors()
resetStars()

--------------------------------------------------------------------------------

return {
	draw = function(object)
		local hitsDeadline = computerUptime() >= deadline

		-- Spawning stars
		while #stars < config.starAmount do
			local rotationAngle = mathRandom(6265) / 1000

			local targetX = mathCos(rotationAngle) * object.width * 0.75  + object.width  / 2
			local targetY = mathSin(rotationAngle) * object.width * 0.375 + object.height / 2

			table.insert(stars, {
				targetX = targetX,
				targetY = targetY,
				startX = (targetX - object.width  / 2) * config.offset + object.width  / 2,
				startY = (targetY - object.height / 2) * config.offset + object.height / 2,
				way = 0.01,
				speed = (mathRandom(25, 75) / 1000 + 1) * (config.speed / 100)
			})
		end

		-- Clear background
		screen.drawRectangle(object.x, object.y, object.width, object.height, config.backgroundColor, 0, " ")

		-- Drawing stars
		local i = 1
		while i <= #stars do
			local star = stars[i]

			local x = star.startX + (star.targetX - star.startX) * star.way
			local y = star.startY + (star.targetY - star.startY) * star.way

			if x > object.width + 1 or x < 1 or y > object.height + 1 or y < 1 then
				tableRemove(stars, i)
			else
				local xmod = x * 2; 
				xmod = (xmod - xmod % 1) % 2
				
				local ymod = y * 4; ymod = (ymod - ymod % 1) % 4

				local color = star.way * 4.0156862745098 * #colors
				color = colors[color - color % 1 + 1] or colors[#colors]

				if star.way < 0.3 then
					if xmod == 0 then
						if     ymod == 0 then char = braille1
						elseif ymod == 1 then char = braille3
						elseif ymod == 2 then char = braille5
						else                  char = braille7
						end
					else
						if     ymod == 0 then char = braille2
						elseif ymod == 1 then char = braille4
						elseif ymod == 2 then char = braille6
						else                  char = braille8
						end
					end
				else
					if ymod < 2 then
						char = braille9
					else
						char = braille10
					end
				end

				screen.set(x - x % 1, y - y % 1, config.backgroundColor, color, char)
				i = i + 1

				if hitsDeadline then
					star.way = star.way * star.speed
				end
			end
		end

		if hitsDeadline then
			deadline = computerUptime() + config.delay
		end
	end,

	configure = function(layout)
	    layout:addChild(GUI.colorSelector(1, 1, 36, 3, config.backgroundColor, "Background color")).onColorSelected = function(_, object)
	        config.backgroundColor = object.color
			resetColors()
	        saveConfig()
	    end

		layout:addChild(GUI.colorSelector(1, 1, 36, 3, config.starColor, "Star color")).onColorSelected = function(_, object)
	        config.starColor = object.color
			resetColors()
	        saveConfig()
	    end

		local amountSlider = layout:addChild(
	        GUI.slider(
	            1, 1, 
	            36,
	            0x66DB80, 
	            0xE1E1E1, 
	            0xFFFFFF, 
	            0xA5A5A5, 
	            10, 200, 
	            config.starAmount, 
	            false, 
	            "Star amount: "
	        )
	    )
	    
	    amountSlider.roundValues = true
	    amountSlider.onValueChanged = function()
	        config.starAmount = math.floor(amountSlider.value)
	        saveConfig()
	    end

		local speedSlider = layout:addChild(GUI.slider(
			1, 1, 
			36,
			0x66DB80, 
			0xE1E1E1, 
			0xFFFFFF, 
			0xA5A5A5, 
			100, 200, 
			config.speed,
			false, 
			"Speed: ",
			"%"
		))

		speedSlider.roundValues = true
		speedSlider.onValueChanged = function()
			config.speed = speedSlider.value
			resetStars()
			saveConfig()
		end

		local offsetSlider = layout:addChild(GUI.slider(
			1, 1, 
			36,
			0x66DB80, 
			0xE1E1E1, 
			0xFFFFFF, 
			0xA5A5A5, 
			0, 100, 
			config.offset * 100,
			false, 
			"Offset: ",
			"%"
		))

		offsetSlider.roundValues = true
		offsetSlider.onValueChanged = function()
			config.offset = offsetSlider.value / 100
			resetStars()
			saveConfig()
		end
	end
}