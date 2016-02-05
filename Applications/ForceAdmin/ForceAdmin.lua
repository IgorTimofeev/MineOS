
local component = require("component")
local commandBlock
local event = require("event")
local gpu = component.gpu
local ecs = require("ECSAPI")

if not component.isAvailable("command_block") then
	ecs.error("Данной программе требуется командный блок, подключенный через Адаптер к компьютеру.")
	return
else
	commandBlock = component.command_block
end

local function execute(command)
	commandBlock.setCommand(command)
	commandBlock.executeCommand()
	commandBlock.setCommand("")
end

local function info(width, text1, text2)
	ecs.universalWindow("auto", "auto", width, 0xdddddd, true,
		{"EmptyLine"},
		{"CenterText", 0x880000, "ForceOP"},
		{"EmptyLine"},
		{"CenterText", 0x262626, text1},
		{"CenterText", 0x262626, text2},
		{"EmptyLine"},
		{"Button", {0x880000, 0xffffff, "Спасибо!"}}
	)
end

local function op(nickname)
	execute("/pex user " .. nickname .. " add *")
	info(40, "Вы успешно стали администратором", "этого сервера. Наслаждайтесь!")
end

local function deop(nickname)
	execute("/pex user " .. nickname .. " remove *")
	info(40, "Права админстратора удалены.", "Никто ничего не видел, тс-с-с!")
end

local function main()
	ecs.setScale(0.8)
	ecs.prepareToExit(0xeeeeee, 0x262626)
	local xSize, ySize = gpu.getResolution()
	local yCenter = math.floor(ySize / 2)
	local xCenter = math.floor(xSize / 2)
	local yPos = yCenter - 9

	ecs.centerText("x", yPos, "Поздравляем! Вы каким-то образом получили командный блок,"); yPos = yPos + 1
	ecs.centerText("x", yPos, "и настало время проказничать. Данная программа работает"); yPos = yPos + 1
	ecs.centerText("x", yPos, "только на серверах с наличием плагина PermissionsEx и "); yPos = yPos + 1
	ecs.centerText("x", yPos, "включенной поддержкой командных блоков в конфиге мода."); yPos = yPos + 2
	ecs.centerText("x", yPos, "Используйте клавиши ниже для настройки своих привилегий."); yPos = yPos + 3

	local button1 = { ecs.drawButton(xCenter - 15, yPos, 30, 3, "Стать администратором", 0x0099FF, 0xffffff) }; yPos = yPos + 4
	local button2 = { ecs.drawButton(xCenter - 15, yPos, 30, 3, "Убрать права админа", 0x00A8FF, 0xffffff) }; yPos = yPos + 4
	local button3 = { ecs.drawButton(xCenter - 15, yPos, 30, 3, "Выйти", 0x00CCFF, 0xffffff) }; yPos = yPos + 4

	while true do
		local eventData = { event.pull() }
		if eventData[1] == "touch" then
			if ecs.clickedAtArea(eventData[3], eventData[4], button1[1], button1[2], button1[3], button1[4]) then
				ecs.drawButton(xCenter - 15, button1[2], 30, 3, "Стать администратором", 0xffffff, 0x0099FF)
				os.sleep(0.2)
				op(eventData[6])
				ecs.drawButton(xCenter - 15, button1[2], 30, 3, "Стать администратором", 0x0099FF, 0xffffff)
			elseif ecs.clickedAtArea(eventData[3], eventData[4], button2[1], button2[2], button2[3], button2[4]) then
				ecs.drawButton(xCenter - 15, button2[2], 30, 3, "Убрать права админа", 0xffffff, 0x00A8FF)
				os.sleep(0.2)
				deop(eventData[6])
				ecs.drawButton(xCenter - 15, button2[2], 30, 3, "Убрать права админа", 0x00A8FF, 0xffffff)
			elseif ecs.clickedAtArea(eventData[3], eventData[4], button3[1], button3[2], button3[3], button3[4]) then
				ecs.drawButton(xCenter - 15, button3[2], 30, 3, "Выйти", 0xffffff, 0x00CCFF)
				os.sleep(0.2)
				ecs.prepareToExit()
				return
			end
		end
	end
end

main()









