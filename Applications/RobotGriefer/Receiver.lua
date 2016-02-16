
local component = require("component")
local robot = require("robot")
local event = require("event")
local fs = require("filesystem")
local port = 512
local keyWord = "ECSGrief"
local modem
local redstone = component.redstone
local redstoneState = false

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
					robot.use()
					robot.useUp()
					robot.useDown()
				elseif message == "exit" then
					return
				elseif message == "redstone" then
					redstoneControl()
				end
			end
		end
	end
end

local function main()
	print("Добро пожаловать в программу ECSGrief Receiver v1.0 alpha early access! Идет ожидание команд с беспроводного устройства.")
	print(" ")
	receive()
	print(" ")
	print("Программа приема сообщений завершена!")
end

-------------------------------------------------------------------------------------

main()

-------------------------------------------------------------------------------------







