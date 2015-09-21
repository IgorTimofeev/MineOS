local c = require("component")
local event = require("event")
local unicode = require("unicode")
local modem = c.modem
local gpu = c.gpu

--------------------------------------------------------------------------------------------------------------

--Открываем порт
local port = 512
modem.open(port)

--Запрашиваем адрес клиента
local clientAddress = "3659a020-b21d-4993-aa79-1d8acd5110f3"
local data = ecs.universalWindow("auto", "auto", 40, ecs.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x880000, "RCON"}, {"EmptyLine"}, {"CenterText", 0x262626, "Введите адрес удаленного компьютера:"}, {"EmptyLine"}, {"Input", 0x262626, 0x880000, clientAddress}, {"EmptyLine"}, {"Button", {0xbbbbbb, 0xffffff, "Далее"}})
clientAddress = data[1]

local oldPixels = ecs.info("auto", "auto", " ", "Connecting to client...")
--Отправляем сообщение
modem.send(clientAddress, port, "RCON", "iWantToControl")
--Ждем результата
local controlAccepted
local e = {event.pull(5, "modem_message")}
local protocol, messsage = e[6], e[7]
if protocol == "RCON" then
	if messsage == "acceptControl" then
		controlAccepted = 1
	elseif messsage == "denyControl" then
		controlAccepted = 2
	end
end

--Удаляем окошко коннекта
ecs.drawOldPixels(oldPixels)

--Проверяем, че там и как
if controlAccepted == 2 then
	ecs.error("Клиент отклонил управление!")
	return
elseif controlAccepted == nil then
	ecs.error("Клиент не принял запрос, отключаюсь.")
	return
end

local function RCONExecute(...)
	modem.send(clientAddress, port, "RCON", ...)
end


--Для окошечка все
local commandsHistory = {
	"Добро пожаловать в RCON-клиент для OpenComputers!",
	" ",
	"Нажмите любую клавишу - и эта же клавиша нажмется на",
	"удаленном компьютере.",
	" ",
	"Кликните на экран - и удаленный компьютер также кликнет",
	"в эту же точку.",
	" ",
	"Введите команду в командную строку ниже - и эта команда",
	"выполнится на удаленном ПК через shell.execute()",
	" ",
	"----------------------------------------------------------------",
	" ",
}

local width, height = 80, 25
local x, y = ecs.correctStartCoords("auto", "auto", width, height)
local xEnd, yEnd = x + width - 1, y + height - 1

local function drawWindow()
	ecs.square(x, y, width, height, 0xeeeeee)
	ecs.colorText(x + 1, y, ecs.colors.red, "⮾")
	ecs.colorText(x + 3, y, ecs.colors.orange, "⮾")
	ecs.colorText(x + 5, y, ecs.colors.green, "⮾")
	local text = "RCON"; ecs.colorText(x + math.floor(width / 2 - #text / 2) - 1, y, 0x262626, text)
	ecs.border(x + 1, yEnd - 2, width - 2, 3, 0xeeeeee, 0x262626)

	--Подпарсиваем историю
	local xPos, yPos = x + 2, y + 2
	local limit = height - 6
	if #commandsHistory > limit then
		for i = 1, (#commandsHistory - limit) do
			table.remove(commandsHistory, 1)
		end
	end

	--Рисуем историю
	gpu.setBackground(0xeeeeee)
	gpu.setForeground(0x555555)
	for i = 1, limit do
		local stro4ka = commandsHistory[i]
		if stro4ka then
			gpu.set(xPos, yPos, ecs.stringLimit("end", stro4ka, width - 4))
			yPos = yPos + 1
		else
			break
		end
	end
end

local function insertToHistory(che)
	table.insert(commandsHistory, che)
	drawWindow()
end

--------------------------------------------------------------------------------

oldPixels = ecs.rememberOldPixels(x, y, x + width - 1, y + height - 1)
drawWindow()

while true do
	local e = {event.pull()}
	if e[1] == "key_down" then
		RCONExecute("key_down", e[3], e[4], e[5])
		insertToHistory("Нажать клавишу \""..unicode.char(e[3]).."\" от имени "..e[5])
	elseif e[1] == "touch" then
		--Если в комманд зону
		if ecs.clickedAtArea(e[3], e[4], x + 2, yEnd - 1, xEnd - 2, yEnd - 1) then
			local cmd = ecs.inputText(x + 3, yEnd - 1, width - 6, "", 0xeeeeee, 0x262626)
			RCONExecute("execute", cmd)
			insertToHistory("Выполнить \""..cmd.."\"")
		elseif ecs.clickedAtArea(e[3], e[4], x + 1, y, x + 2, y) then
			ecs.colorTextWithBack(x + 1, y, ecs.colors.blue, 0xeeeeee, "⮾")
			os.sleep(0.2)
			RCONExecute("closeConnection")
			ecs.drawOldPixels(oldPixels)
			return
		else
			RCONExecute("touch", e[3], e[4], e[5], e[6])
			insertToHistory("Кликнуть на экран на позиции "..tostring(e[3]).."x"..tostring(e[4]).." клавишей мыши "..tostring(e[5]).." от имени "..tostring(e[6]))
		end
	end
end

