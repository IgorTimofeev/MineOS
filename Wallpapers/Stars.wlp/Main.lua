local screen = require("Screen")
local fs = require("Filesystem")
local GUI = require("GUI")
local system = require("System")
local color = require("Color")

--------------------------------------------------------------------------------

local braille1, braille2, braille3, braille4, braille5, braille6, braille7, braille8, braille9, braille10 = "⠁", "⠈", "⠂", "⠐", "⠄", "⠠", "⡀", "⢀", "⠛", "⣤"

-- Faster access without tables indexing
local computerUptime, tableRemove, mathSin, mathCos, mathRandom, screenUpdate = computer.uptime, table.remove, math.sin, math.cos, math.random

--------------------------------------------------------------------------------

local wallpaper = {}

local configPath = fs.path(system.getCurrentScript()) .. "Config.cfg"
local function saveConfig()
	fs.writeTable(configPath, wallpaper.config)
end

if fs.exists(configPath) then
	wallpaper.config = fs.readTable(configPath)
else
	wallpaper.config = {
		starAmount = 100,
		backgroundColor = 0x0F0F0F,
		starColor = 0xFFFFFF,
		delay = 0.05,
		initialWay = 0.01,
		speed = 100
	}
end

--------------------------------------------------------------------------------

local stars, deadline, colors

local function resetColors()
	colors = {}
	
	local colorCount = 16
	for i = 1, colorCount do
		table.insert(colors, color.transition(wallpaper.config.backgroundColor, wallpaper.config.starColor, (i - 1) / (colorCount - 1)))
	end
end

local function resetStars()
	stars = {}
	deadline = 0
end

resetColors()
resetStars()

function wallpaper.draw(object)
	local hitsDeadline = computerUptime() >= deadline

	-- Spawning stars
	while #stars < wallpaper.config.starAmount do
		local rotationAngle = mathRandom(6265) / 1000

		local targetX = mathCos(rotationAngle) * object.width * 0.75  + object.width  / 2
		local targetY = mathSin(rotationAngle) * object.width * 0.375 + object.height / 2

		local startWay = mathRandom()
		table.insert(stars, {
			targetX = targetX,
			targetY = targetY,
			startX = (targetX - object.width  / 2) * startWay + object.width  / 2,
			startY = (targetY - object.height / 2) * startWay + object.height / 2,
			way = wallpaper.config.initialWay,
			speed = (mathRandom(25, 75) / 1000 + 1) * (wallpaper.config.speed / 100)
		})
	end

	-- Clear background
	screen.drawRectangle(object.x, object.y, object.width, object.height, wallpaper.config.backgroundColor, 0, " ")

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

			screen.set(x - x % 1, y - y % 1, wallpaper.config.backgroundColor, color, char)
			i = i + 1

			if hitsDeadline then
				star.way = star.way * star.speed
			end
		end
	end

	if hitsDeadline then
		deadline = computerUptime() + wallpaper.config.delay
	end
end

function wallpaper.configure(layout)
    layout:addChild(GUI.colorSelector(1, 1, 36, 3, wallpaper.config.backgroundColor, "Background color")).onColorSelected = function(_, object)
        wallpaper.config.backgroundColor = object.color
        saveConfig()
		resetColors()
    end

	layout:addChild(GUI.colorSelector(1, 1, 36, 3, wallpaper.config.starColor, "Star color")).onColorSelected = function(_, object)
        wallpaper.config.starColor = object.color
        saveConfig()
		resetColors()
    end

	local starAmountSlider = layout:addChild(
        GUI.slider(
            1, 1, 
            36,
            0x66DB80, 
            0xE1E1E1, 
            0xFFFFFF, 
            0xA5A5A5, 
            10, 200, 
            wallpaper.config.starAmount, 
            false, 
            "Star amount: "
        )
    )
    
    starAmountSlider.roundValues = true
    starAmountSlider.onValueChanged = function(workspace, object)
        wallpaper.config.starAmount = math.floor(object.value)
        saveConfig()
		-- resetStars()
    end

	local starSpeedSlider = layout:addChild(GUI.slider(
		1, 1, 
		36,
		0x66DB80, 
		0xE1E1E1, 
		0xFFFFFF, 
		0xA5A5A5, 
		100, 200, 
		wallpaper.config.speed,
		false, 
		"Speed: ",
		"%"
	))

	starSpeedSlider.roundValues = true
	starSpeedSlider.onValueChanged = function(_, object)
		wallpaper.config.speed = object.value
		saveConfig()
		resetStars()
	end
end

--------------------------------------------------------------------------------

return wallpaper