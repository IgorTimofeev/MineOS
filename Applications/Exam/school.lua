local ecs = require("ECSAPI")

local component = require "component"
local event = require "event"
local ser = require "serialization"
local unicode = require "unicode"

local gpu = component.gpu

-- КОНСТАНТЫ --
local bgColor = 0xffffff
local fgColor = 0x000000
local questionsFilePath = "schoolQuestions.lua"
local screenWidth, screenHeight = gpu.getResolution()

-- РАЗНОЕ --
function swap(array, index1, index2)
  array[index1], array[index2] = array[index2], array[index1]
end

function shake(array)
  local counter = #array

  while counter > 1 do
    local index = math.random(counter)

    swap(array, index, counter)		
    counter = counter - 1
  end
end

-- Информация о кнопках --
local buttons = {}

local buttonStyle = {
	standart = {
		buttonColor = 0xBBBBBB,
		textColor = 0xffffff,
	},
	correct = {
		buttonColor = 0x008800,
		textColor = 0xffffff,
	},
	incorrect = {
		buttonColor = 0xFF4444,
		textColor = 0xffffff,
	}
}

-- Информация о кол-ве вопросов и текущем вопросе --
local database
local currentQuestion = 1
local currentCategory = "Информатика"
local buttonsWidth = 0

-- Получение массива вопросов из файла --
local function readDatabase( filename )
	local file = assert( io.open(filename, "r"), "File not found!" )
	database = ser.unserialize( file:read("*a") )
	file:close()
end

local xOffset, yOffset, spaceBetweenButtons = 4, 1, 2
local xPos, yPos

local function drawMain(x)

	buttons = {}
	buttonsWidth = 0
	for i = 1, #database.categories[currentCategory].exercises[currentQuestion].answers do
		buttonsWidth = buttonsWidth + spaceBetweenButtons + xOffset * 2 + unicode.len(database.categories[currentCategory].exercises[currentQuestion].answers[i])
	end
	buttonsWidth = buttonsWidth

	xPos, yPos = math.floor(x + screenWidth / 2 - buttonsWidth / 2 - 1), math.floor(screenHeight / 2) - 3
	
	ecs.square(1, yPos, screenWidth, 8, 0xFFFFFF)

	ecs.colorText(x + math.floor(screenWidth / 2 - unicode.len(database.categories[currentCategory].exercises[currentQuestion].question) / 2 - 1), yPos, 0x262626, database.categories[currentCategory].exercises[currentQuestion].question)
	yPos = yPos + 3

	local xButtons = xPos
	for i = 1, #database.categories[currentCategory].exercises[currentQuestion].answers do
		local data = { ecs.drawAdaptiveButton(xButtons, yPos, xOffset, yOffset, database.categories[currentCategory].exercises[currentQuestion].answers[i], buttonStyle.standart.buttonColor, buttonStyle.standart.textColor) }
		data.text = database.categories[currentCategory].exercises[currentQuestion].answers[i]
		table.insert(buttons, data)
		xButtons = xButtons + spaceBetweenButtons + xOffset * 2 + unicode.len(database.categories[currentCategory].exercises[currentQuestion].answers[i])
	end

	yPos = yPos - 3
end

local function startAnimation(speed)
	for i = screenWidth - screenWidth*0.2, 1, -speed do
		drawMain(i)
		os.sleep(0.05)
	end
end

local function drawProgress()
	local width = math.floor(screenWidth * 0.65)
	local xPos = math.floor(screenWidth / 2 - width / 2)
	local yPos = math.floor(screenHeight / 2 + 5)
	gpu.setBackground(0xFFFFFF)
	
	gpu.setForeground(0xCCCCCC)
	gpu.fill( xPos, yPos, width, 1, '▂' )

	gpu.setForeground(0xBF2008)
	gpu.fill( xPos, yPos, (width * (currentQuestion - 1)) / #database.categories[currentCategory].exercises, 1, '▂' )
end

local function endAnimation(speed)
	for i = screenWidth, 1, -5 do
		gpu.copy(1, yPos, screenWidth, 8, -speed, 0)
		os.sleep(0.05)
	end
end

local function test()
	local animationSpeed = 6
	ecs.square(1, 1, screenWidth, screenHeight, 0xFFFFFF)

	for i = 1, #database.categories[currentCategory].exercises do
		currentQuestion = i
		local correctAnswer = database.categories[currentCategory].exercises[i].correctAnswer

		drawProgress()
		startAnimation(animationSpeed)

		local doWhile = true
		while doWhile do
			if exitWhile then break end
			local e = {event.pull()}
			if e[1] == "touch" then
				for key = 1, #buttons do
					if ecs.clickedAtArea(e[3], e[4], buttons[key][1], buttons[key][2], buttons[key][3], buttons[key][4]) then
						if key == correctAnswer then
							ecs.drawAdaptiveButton(buttons[key][1], buttons[key][2], xOffset, yOffset, buttons[key].text, buttonStyle.correct.buttonColor, buttonStyle.correct.textColor)
						else
							ecs.drawAdaptiveButton(buttons[key][1], buttons[key][2], xOffset, yOffset, buttons[key].text, buttonStyle.incorrect.buttonColor, buttonStyle.incorrect.textColor)
						end
						doWhile = false
						break
					end
				end
			end
		end
		endAnimation(animationSpeed)
	end

	ecs.square(1, 1, screenWidth, screenHeight, 0xFFFFFF)
end

readDatabase(questionsFilePath)
test()







