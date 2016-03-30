local image = require("image")
local buffer = require("doubleBuffering")
local keyboard = require("keyboard")
local bigLetters = require("bigLetters")
local fs = require("filesystem")
local serialization = require("serialization")
local ecs = require("ECSAPI")

buffer.start()

local config = {
	FPS = 0.05,
	birdFlyUpSpeed = 4,
	birdFlyDownSpeed = 1,
	columnPipeHeight = 4,
	columnPipeWidth = 17,
	columnWidth = 15,
	columnFreeSpace = 17,
	birdFlyForwardSpeed = 2,
	spaceBetweenColumns = 51,
}

local colors = {
	background = 0x66DBFF,
	columnMain = 0x33DB00,
	columnAlternative = 0x66FF40,
	scoreText = 0xFFFFFF,
	scoreTextBackground = 0x262626,
	button = 0xFF9200,
	buttonText = 0xFFFFFF,
	board = 0xFFDB80,
	boardText = 0xFF6600
}

local columns = {}

local pathToHighScores = "MineOS/System/FlappyBird/Scores.txt"
local pathToFlappyImage = "MineOS/Applications/FlappyBird.app/Resources/Flappy.pic"
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
	local yFreeZone = math.random(config.columnPipeHeight + 2, buffer.screen.height - config.columnPipeHeight - config.columnFreeSpace)
	table.insert(columns, {x = buffer.screen.width - 1, yFreeZone = yFreeZone})
end

local scoreCanBeAdded = true
local function moveColumns()
	local i = 1
	while i <= #columns do
		columns[i].x = columns[i].x - 1

		if (columns[i].x >= xBird and columns[i].x <= xBird + 13) then
			if ((yBird >= columns[i].yFreeZone) and (yBird + 6 <= columns[i].yFreeZone + config.columnFreeSpace - 1)) then
				if scoreCanBeAdded == true then currentScore = currentScore + 1; scoreCanBeAdded = false end
			else
				dieBirdDie()
			end
		else
			-- scoreCanBeAdded = true
		end

		if columns[i].x < -(config.columnPipeWidth) then
			scoreCanBeAdded = true
			table.remove(columns, i)
			i = i - 1
		end

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

local function drawBigCenterText(y, textColor, usePseudoShadow, text)
	local width = bigLetters.getTextSize(text)
	local x = math.floor(buffer.screen.width / 2 - width / 2)

	if usePseudoShadow then buffer.square(x - 2, y - 1, width + 4, 7, colors.scoreTextBackground) end
	bigLetters.drawText(x, y, textColor, text)
end

local function drawAll(force)
	drawBackground()
	drawColumns()
	drawBird()
	drawBigCenterText(yScore, colors.scoreText, true,tostring(currentScore))

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

local function clicked(x, y, object)
	if x >= object[1] and y >= object[2] and x <= object[3] and y <= object[4] then
		return true
	end
	return false
end

local function wait()
	while true do
		local e = {event.pull()}
		if e[1] == "touch" or e[1] == "key_down" then
			currentUser = e[6]
			return
		end
	end
end

local function showPlayers(x, y)
	local width = 40
	local nicknameLimit = 20
	local mode = false
	local counter = 1
	local stro4ka = string.rep(" ", nicknameLimit).."│"..string.rep(" ", width - nicknameLimit)
	ecs.colorTextWithBack(x, y, 0xffffff, ecs.colors.blue, stro4ka)
	gpu.set(x + 1, y, "Имя игрока")
	gpu.set(x + nicknameLimit + 2, y, "Очки")

	for key, val in pairs(players) do
		local color = 0xffffff

		if mode then
			color = color - 0x222222
		end

		gpu.setForeground(0x262626)
		gpu.setBackground(color)
		gpu.set(x, y + counter, stro4ka)
		gpu.set(x + 3, y + counter, ecs.stringLimit("end", key, nicknameLimit - 4))
		gpu.set(x + nicknameLimit + 2, y + counter, tostring(players[key][1]))
		ecs.colorTextWithBack(x + 1, y + counter, players[key][2], color, "●")

		counter = counter + 1
		mode = not mode
	end
end

local function finalGUI()
	local obj = {}
	local widthOfBoard = 56
	local heightOfBoard = 40

	local function draw()
		local y = math.floor(buffer.screen.height / 2 - 19)
		local x = math.floor(buffer.screen.width / 2 - widthOfBoard / 2)
		
		drawAll()
		
		buffer.square(x, y, widthOfBoard, heightOfBoard, colors.board, 0xFFFFFF, " ", 30)

		y = y + 2
		drawBigCenterText(y, colors.boardText, false, "score")
		y = y + 8
		drawBigCenterText(y, 0xFFFFFF, true, tostring(currentScore))
		y = y + 8
		drawBigCenterText(y, colors.boardText, false, "best")
		y = y + 8
		drawBigCenterText(y, 0xFFFFFF, true, tostring(scores[currentUser]))
		y = y + 8

		obj.retry = { buffer.button(x, y, widthOfBoard, 3, 0xFF6600, colors.buttonText, "Заново") }; y = y + 3
		-- obj.records = { buffer.button(x, y, widthOfBoard, 3, 0xFF9900, colors.buttonText, "Таблица рекордов") }; y = y + 3
		obj.exit = { buffer.button(x, y, widthOfBoard, 3, 0x262626, colors.buttonText, "Выход") }; y = y + 3

		buffer.draw()
	end

	draw()

	while true do
		local e = {event.pull("touch")}
		if clicked(e[3], e[4], obj.retry) then
			buffer.button(obj.retry[1], obj.retry[2], widthOfBoard, 3, 0xFFFFFF, 0x000000, "Заново")
			buffer.draw()
			os.sleep(0.2)
			currentScore = 0
			birdIsAlive = true
			scoreCanBeAdded = true
			columns = {}
			bird = image.load(pathToFlappyImage)
			yBird = math.floor(buffer.screen.height / 2 - 3)
			drawAll()
			wait()
			return

		elseif clicked(e[3], e[4], obj.exit) then
			buffer.button(obj.exit[1], obj.exit[2], widthOfBoard, 3, 0xFFFFFF, 0x000000, "Выход")
			buffer.draw()
			os.sleep(0.2)
			buffer.clear(0x262626)
			ecs.prepareToExit()
			os.exit()
		end
	end
end

loadHighScores()
drawAll()
wait()

local xNewColumnGenerationVariable = config.spaceBetweenColumns
while true do
	local somethingHappend = false
	
	local e = {event.pull(config.FPS)}
	if birdIsAlive and (e[1] == "touch" or e[1] == "key_down") then
		yBird = yBird - config.birdFlyUpSpeed + (not birdIsAlive and 2 or 0)
		somethingHappend = true
		currentUser = e[1] == "touch" and e[6] or e[5]
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
			finalGUI()
			xNewColumnGenerationVariable = config.spaceBetweenColumns
		end
	end

	drawAll()
end






