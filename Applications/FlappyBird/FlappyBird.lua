local image = require("image")
local buffer = require("doubleBuffering")
local keyboard = require("keyboard")
local bigLetters = require("bigLetters")
local fs = require("filesystem")
local serialization = require("serialization")
local ecs = require("ECSAPI")

buffer.start()

local colors = {
	background = 0x66DBFF,
	columnMain = 0x33DB00,
	columnAlternative = 0x66FF40,
	scoreText = 0xFFFFFF,
	scoreTextBackground = 0x262626,
}

local config = {
	FPS = 0.05,
	birdFlyUpSpeed = 4,
	birdFlyDownSpeed = 1,
	columnPipeHeight = 4,
	columnPipeWidth = 17,
	columnFreeSpace = 20,
	birdFlyForwardSpeed = 2,
}
config.columnWidth = config.columnPipeWidth - 2
config.spaceBetweenColumns = config.columnWidth + 40

local columns = {{x = buffer.screen.width - 1, yFreeZone = 10}}

local pathToHighScores = "MineOS/System/FlappyBird/Scores.txt"
local pathToFlappyImage = "flappy.pic"
local bird = image.load(pathToFlappyImage)
local xBird, yBird = 8, math.floor(buffer.screen.height / 2 - 3)
local birdIsAlive = true

local scores = {}
local currentScore, currentUser = 0, 0
local xScore, yScore = math.floor(buffer.screen.width / 2 - 6), math.floor(buffer.screen.height * 0.16)

local function drawColumn(x, upperCornerStartPosition)
	local y = 1
	buffer.square(x + 1, y, config.columnWidth, upperCornerStartPosition - config.columnPipeHeight, colors.columnMain)
	buffer.square(x, upperCornerStartPosition - config.columnPipeHeight, config.columnPipeWidth, config.columnPipeHeight, colors.columnAlternative)

	y = upperCornerStartPosition + config.columnFreeSpace
	buffer.square(x, y, config.columnPipeWidth, config.columnPipeHeight, colors.columnAlternative)
	y = y + config.columnPipeHeight
	buffer.square(x + 1, y, config.columnWidth, buffer.screen.height - y + 1, colors.columnMain)
end

local function dieBirdDie()
	if birdIsAlive then
		bird = image.photoFilter(bird, 0x880000, 100)
		birdIsAlive = false
	end
end

local function generateColumn()
	local yFreeZone = math.random(config.columnPipeHeight + 1, buffer.screen.height - config.columnPipeHeight - config.columnFreeSpace)
	table.insert(columns, {x = buffer.screen.width - 1, yFreeZone = yFreeZone})
end

local function moveColumns()
	local i = 1
	while i <= #columns do
		columns[i].x = columns[i].x - 1

		if  (columns[i].x >= xBird and columns[i].x <= xBird + 13) then
			if ((yBird >= columns[i].yFreeZone) and (yBird + 6 <= columns[i].yFreeZone + config.columnFreeSpace - 1)) then
				currentScore = currentScore + 1
			else
				dieBirdDie()
			end
		end

		if columns[i].x < -(config.columnPipeWidth) then table.remove(columns, i); i = i - 1 end

		i = i + 1
	end
end

local function drawColumns()
	for i = 1, #columns do
		drawColumn(columns[i].x, columns[i].yFreeZone)
	end
end

local function drawBackground()
	buffer.clear(colors.background)
end

local function drawBird()
	buffer.image(xBird, yBird, bird)
end

local function drawScore(text)
	local width = bigLetters.getTextSize(text)
	local x = math.floor(buffer.screen.width / 2 - width / 2)

	buffer.square(x - 2, yScore - 1, width + 4, 7, colors.scoreTextBackground)
	bigLetters.drawText(x, yScore, colors.scoreText, text)
end

local function drawAll(force)
	drawBackground()
	drawColumns()
	drawBird()
	drawScore(tostring(currentScore))

	buffer.draw(force)
end

local function saveHighScores()
	fs.makeDirectory(fs.path(pathToHighScores))
	local file = io.open(pathToHighScores, "w")
	file:write(serialization.serialize(scores))
	file:close()
end

local function loadHighScores()
	if fs.exists(pathToHighScores) then
		local file = io.open(pathToHighScores, "r")
		scores = serialization.unserialize(file:read("*a"))
		file:close()
	else
		scores = {}
	end
end

loadHighScores()
drawAll()
ecs.wait()

local xNewColumnGenerationVariable = 0
while true do
	local somethingHappend = false
	
	local e = {event.pull(config.FPS)}
	if birdIsAlive and e[1] == "touch" then
		yBird = yBird - config.birdFlyUpSpeed + (not birdIsAlive and 2 or 0)
		somethingHappend = true
		currentUser = e[6]
	-- elseif e[1] == "key_down" then
	-- 	if e[4] == 200 then
	-- 		yBird = yBird - 1
	-- 	elseif e[4] == 208 then
	-- 		yBird = yBird + 1
	-- 	elseif e[4] == 205 then
	-- 		moveColumns()
	-- 		xNewColumnGenerationVariable = xNewColumnGenerationVariable + 1
	-- 		if xNewColumnGenerationVariable >= config.spaceBetweenColumns then
	-- 			xNewColumnGenerationVariable = 0
	-- 			generateColumn()
	-- 		end
	-- 	end
	end

	moveColumns()
	xNewColumnGenerationVariable = xNewColumnGenerationVariable + 1
	if xNewColumnGenerationVariable >= config.spaceBetweenColumns then
		xNewColumnGenerationVariable = 0
		generateColumn()
	end

	if not somethingHappend then
		if yBird + bird.height - 1 < buffer.screen.height then
			yBird = yBird + config.birdFlyDownSpeed
		else
			scores[currentUser] = math.max(scores[currentUser] or 0, currentScore)
			saveHighScores()
			ecs.error("Вы проиграли!")
			buffer.clear(0x262626)
			buffer.draw()
			return
		end
	end

	drawAll()
end




