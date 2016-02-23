
local component = require("component")
local robot = require("robot")
local event = require("event")
local fs = require("filesystem")
local port = 512
local keyWord = "ECSGrief"
local modem
local redstone = component.redstone
local redstoneState = false
local toolUsingMode = false
local toolUsingSide = 1

if component.isAvailable("modem") then
	modem = component.modem
else
	error("Этой программе требуется беспроводной модем для работы!")
end

modem.open(port)

-------------------------------------------------------------------------------------

local commands = {
	forward = robot.forward,
	back = robot.back,
	turnRight = robot.turnRight,
	turnLeft = robot.turnLeft,
	up = robot.up,
	down = robot.down,
	swing = robot.swing,
	drop = robot.drop
}

local function redstoneControl()
	if not redstone then return end
	if redstoneState then
		for i = 0, 5 do
			redstone.setOutput(i, 0)
		end
		print("Сигнал редстоуна включен со всех сторон робота!")
		redstoneState = false
	else
		for i = 0, 5 do
			redstone.setOutput(i, 15)
		end
		print("Сигнал редстоуна отключен.")
		redstoneState = true
	end
end

local function receive()
	while true do
		local eventData = { event.pull() }
		if eventData[1] == "modem_message" and eventData[4] == port and eventData[6] == keyWord then
			local message = eventData[7]
			local message2 = eventData[8]

			if commands[message] then
				commands[message]()
			else
				if message == "selfDestroy" then
					local fs = require("filesystem")
					for file in fs.list("") do
						print("Уничтожаю \"" .. file .. "\"")
						fs.remove(file)
					end
					require("term").clear()
					require("computer").shutdown()
				elseif message == "use" then
					if toolUsingMode then
						if toolUsingSide == 1 then
							print("Использую экипированный предмет в режиме правого клика перед роботом")
							robot.use()
						elseif toolUsingSide == 0 then
							print("Использую экипированный предмет в режиме правого клика под роботом")
							robot.useDown()
						elseif toolUsingSide == 2 then
							print("Использую экипированный предмет в режиме правого клика над роботом")
							robot.useUp()
						end
					else
						if toolUsingSide == 1 then
							print("Использую экипированный предмет в режиме левого клика перед роботом")
							robot.swing()
						elseif toolUsingSide == 0 then
							print("Использую экипированный предмет в режиме левого клика под роботом")
							robot.swingDown()
						elseif toolUsingSide == 2 then
							print("Использую экипированный предмет в режиме левого клика над роботом")
							robot.swingUp()
						end
					end
				elseif message == "exit" then
					return
				elseif message == "redstone" then
					redstoneControl()
				elseif message == "changeToolUsingMode" then
					toolUsingMode = not toolUsingMode
				elseif message == "increaseToolUsingSide" then
					print("Изменяю режим использования вещи")
					toolUsingSide = toolUsingSide + 1
					if toolUsingSide > 2 then toolUsingSide = 2 end
				elseif message == "decreaseToolUsingSide" then
					print("Изменяю режим использования вещи")
					toolUsingSide = toolUsingSide - 1
					if toolUsingSide < 0 then toolUsingSide = 0 end
				end
			end
		end
	end
end

local function main()
	print(" ")
	print("Добро пожаловать в программу ECSGrief Receiver v1.0 alpha early access! Идет ожидание команд с беспроводного устройства.")
	print(" ")
	receive()
	print(" ")
	print("Программа приема сообщений завершена!")
end

-------------------------------------------------------------------------------------

main()

-------------------------------------------------------------------------------------







