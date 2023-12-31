
-- This's a copy-paste of orignal software from https://github.com/Maxu5/

-------------------------------------------------------------------------------------

local screen = require("Screen")

local starAmount, delay, colors, background, braille1, braille2, braille3, braille4, braille5, braille6, braille7, braille8, braille9, braille10 =
	100,
	0.05,
	{
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
		0xF0F0F0,
	},
	0x0F0F0F,
	"⠁", "⠈", "⠂", "⠐", "⠄", "⠠", "⡀", "⢀", "⠛", "⣤"

-- Faster access without tables indexing
local computerUptime, tableRemove, mathSin, mathCos, mathRandom, screenUpdate =
	computer.uptime,
	table.remove,
	math.sin,
	math.cos,
	math.random,
	screen.update

-- Other variables, nil by default
local stars, deadline, hitsDeadline, i, star, rotationAngle, targetX, targetY, startWay, x, y, xmod, ymod, prevX, prevY, signalType, char, color = {}, 0

return function(self)
	hitsDeadline = computerUptime() >= deadline

	-- Spawing stars
	while #stars < starAmount do
		rotationAngle = mathRandom(6265) / 1000
		
		targetX, targetY, startWay =
			mathCos(rotationAngle) * self.width * 0.75 + self.width / 2,
			mathSin(rotationAngle) * self.width * 0.375 + self.height / 2,
			mathRandom()

		stars[#stars + 1] = {
			targetX = targetX,
			targetY = targetY,
			startX = (targetX - self.width / 2) * startWay + self.width / 2,
			startY = (targetY - self.height / 2) * startWay + self.height / 2,
			way = 0.01,
			speed = mathRandom(25, 75) / 1000 + 1,
		}
	end

	screen.drawRectangle(self.x, self.y, self.width, self.height, background, colors[1], " ")

	-- Drawing stars
	i = 1
	while i <= #stars do
		star = stars[i]

		x, y =
			star.startX + (star.targetX - star.startX) * star.way,
			star.startY + (star.targetY - star.startY) * star.way

		if x > self.width + 1 or x < 1 or y > self.height + 1 or y < 1 then
			tableRemove(stars, i)
		else
			-- Star type
			xmod = x * 2
			xmod = (xmod - xmod % 1) % 2

			ymod = y * 4
			ymod = (ymod - ymod % 1) % 4

			-- Star color
			color = star.way * 4.0156862745098 * #colors
			color = colors[color - color % 1 + 1] or 0xFFFFFF

			if star.way < 0.3 then
				if xmod == 0 then
					if ymod == 0 then
						char = braille1
					elseif ymod == 1 then
						char = braille3
					elseif ymod == 2 then
						char = braille5
					else
						char = braille7
					end
				else
					if ymod == 0 then
						char = braille2
					elseif ymod == 1 then
						char = braille4
					elseif ymod == 2 then
						char = braille6
					else
						char = braille8
					end
				end
			else
				if ymod < 2 then
					char = braille9
				else
					char = braille10
				end
			end

			screen.set(x - x % 1, y - y % 1, background, color, char)

			i = i + 1

			if hitsDeadline then
				star.way = star.way * star.speed
			end
		end
	end

	if hitsDeadline then
		deadline = computerUptime() + delay
	end
end