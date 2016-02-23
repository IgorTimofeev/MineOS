
local component = require("component")
local event = require("event")
local port = 512
local keyWord = "ECSGrief"
local modem

if component.isAvailable("modem") then
	modem = component.modem
else
	error("Этой программе требуется беспроводной модем для работы!")
end

modem.open(port)

-------------------------------------------------------------------------------------

local commands = {
	[17] = {
		messageToRobot = "forward",
		screenText = "Приказываю роботу двигаться вперед",
	},
	[31] = {
		messageToRobot = "back",
		screenText = "Приказываю роботу двигаться назад",
	},
	[30] = {
		messageToRobot = "turnLeft",
		screenText = "Приказываю роботу повернуться налево",
	},
	[32] = {
		messageToRobot = "turnRight",
		screenText = "Приказываю роботу повернуться направо",
	},
	[57] = {
		messageToRobot = "up",
		screenText = "Приказываю роботу двигаться вверх",
	},
	[42] = {
		messageToRobot = "down",
		screenText = "Приказываю роботу двигаться вниз",
	},
	[18] = {
		messageToRobot = "use",
		screenText = "Приказываю роботу использовать предмет в руках",
	},
	[14] = {
		messageToRobot = "exit",
		screenText = "Приказываю роботу завершить программу принятия сообщений",
	},
	[59] = {
		messageToRobot = "selfDestroy",
		screenText = "Приказываю роботу уничтожить всю информацию на диске. Ему было приятно работать с тобой, повелитель!",
	},
	[19] = {
		messageToRobot = "redstone",
		screenText = "Приказываю роботу включить/выключить редстоун вокруг себя",
	},
	[16] = {
		messageToRobot = "drop",
		screenText = "Приказываю роботу выкинуть предмет из выбранного слота",
	},
	[33] = {
		messageToRobot = "changeToolUsingMode",
		screenText = "Приказываю роботу изменить режим использования предмета, а именно swing() или use()",
	},
}

local function send()
	while true do
		local eventData = { event.pull() }
		if eventData[1] == "key_down" then
			if commands[eventData[4]] then
				print(commands[eventData[4]].screenText)
				modem.broadcast(port, keyWord, commands[eventData[4]].messageToRobot)
				if commands[eventData[4]].messageToRobot == "exit" then
					return
				end
			end
		elseif eventData[1] == "scroll" then
			if eventData[5] == 1 then
				print("Приказываю роботу увеличить режим использования предметов, т.е. useDown() изменится на use(), а use() на useUp()")
				modem.broadcast(port, keyWord, "increaseToolUsingSide")
			else
				print("Приказываю роботу уменьшить режим использования предметов, т.е. useUp() изменится на use(), а use() на useDown()")
				modem.broadcast(port, keyWord, "decreaseToolUsingSide")
			end
		end
	end
end

local function main()
	print(" ")
	print("Добро пожаловать в программу ECSGrief Sender v1.0 alpha early access!")
	print(" ")
	print("Используйте WASD, а также SPACE и SHIFT для перемещения. Нажатие клавиши E заставит робота использовать предмет, находящийся у него в руках. Также вы можете использовать клавишу F1 для экстренного удаления всех данных с робота и BACKSPACE для простого выхода из программы. Удачной охоты за ресами!")
	print(" ")
	send()
	print(" ")
	print("Программа доминации над роботом завершена!")
end

-------------------------------------------------------------------------------------

main()

-------------------------------------------------------------------------------------







