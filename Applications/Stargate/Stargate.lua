local image = require("image")
local buffer = require("doubleBuffering")
local GUI = require("GUI")
local component = require("component")
local unicode = require("unicode")
local event = require("event")
local files = require("files")
local stargate

if not component.isAvailable("stargate") then
	GUI.error("Этой программе требуются Звездные Врата из мода \"SGCraft\"", {title = {color = 0xFF8888, text = "Ошибка"}})
	return
else
	stargate = component.stargate
end

local toolbarWidth = 32
local sg = image.load("MineOS/Applications/Stargate.app/Resources/Gate.pic")
local sgCore = image.load("MineOS/Applications/Stargate.app/Resources/GateCore.pic")
local pathToContacts = "MineOS/System/Stargate/Contacts.cfg"
local buttons = {}
local contacts = {addresses = {}}
local chevrons = {
	{x = 5, y = 26, isActivated = false},
	{x = 1, y = 15, isActivated = false},
	{x = 12, y = 5, isActivated = false},
	{x = 34, y = 1, isActivated = false},
	{x = 56, y = 5, isActivated = false},
	{x = 66, y = 15, isActivated = false},
	{x = 63, y = 26, isActivated = false},
}

local function loadContacts()
	if fs.exists(pathToContacts) then
		contacts = files.loadTableFromFile(pathToContacts)
	end
end

local function saveContacts()
	files.saveTableToFile(pathToContacts, contacts)
end

local function getArraySize(array)
	local size = 0; for key in pairs(array) do size = size + 1 end; return size
end

local function drawDock(xDock, yDock, currentDockWidth, heightOfDock)
	local transparency = 25
	for i = 1, heightOfDock do
		buffer.text(xDock, yDock, 0xFFFFFF, "▟", transparency)
		buffer.square(xDock + 1, yDock, currentDockWidth, 1, 0xFFFFFF, 0xFFFFFF, " ", transparency)
		buffer.text(xDock + currentDockWidth + 1, yDock, 0xFFFFFF, "▙", transparency)

		transparency = transparency + 15
		currentDockWidth = currentDockWidth - 2
		xDock = xDock + 1; yDock = yDock - 1
	end
end

local function stateOfChevrons(state)
	for i = 1, #chevrons do chevrons[i].isActivated = state end
end

local function drawChevrons(xSg, ySg)
	local inactiveColor = 0x332400
	local activeColor = 0xFFDB00
	local fadeColor = 0xCC6D00
	for i = 1, #chevrons do
		buffer.square(xSg + chevrons[i].x - 1, ySg + chevrons[i].y - 1, 4, 2, chevrons[i].isActivated and fadeColor or inactiveColor)
		buffer.square(xSg + chevrons[i].x, ySg + chevrons[i].y - 1, 2, 2, chevrons[i].isActivated and activeColor or inactiveColor)
	end
end

local function drawSG()
	buffer.clear(0x1b1b1b)

	buttons = {}

	local toolbarHeight = 34
	local x, y = math.floor((buffer.screen.width - toolbarWidth) / 2 - sg.width / 2), math.floor(buffer.screen.height / 2 - sg.height / 2)
	buffer.image(x, y, sg)
	
	local stargateState = stargate.stargateState()
	local irisState = stargate.irisState()
	local remoteAddress = stargate.remoteAddress()
	
	if stargateState == "Connected" then
		stateOfChevrons(true)
		buffer.image(x, y, sgCore)
	end
	drawChevrons(x, y)
	local currentDockWidth, heightOfDock = 50, 4
	drawDock(math.floor(x + sg.width / 2 - currentDockWidth / 2), y + sg.height + 1, currentDockWidth, heightOfDock )

	local function centerText(y, color, text)
		local x = math.floor(buffer.screen.width - toolbarWidth / 2 - unicode.len(text) / 2 + 1)
		buffer.text(x, y, color, text)
	end

	local lineColor = 0xFFFFFF
	local pressColor = 0x6692FF
	local buttonDisabledColor = 0xAAAAAA

	local pizdos = math.floor(buffer.screen.height / 2)
	x, y = x + sg.width + 5, pizdos
	local width = buffer.screen.width - x - toolbarWidth
	buffer.text(x, y, lineColor, string.rep("─", width))
	x = x + width
	y = math.floor(buffer.screen.height / 2 - toolbarHeight / 2)
	for i = y, y + toolbarHeight do
		local bg = buffer.get(x, i)
		buffer.set(x, i, bg, lineColor, "│")
	end
	buffer.text(x, pizdos, lineColor, "┤")

	x = x + 3
	local buttonWidth = buffer.screen.width - x - 1
	centerText(y, lineColor, "Stargate " .. stargate.localAddress()); y = y + 1
	centerText(y, 0x888888, stargateState == "Connected" and "(подключено к " .. remoteAddress .. ")" or "(не подключено)"); y = y + 1


	y = y + 1
	buttons.connectButton = GUI.framedButton(x, y, buttonWidth, 3, lineColor, lineColor, pressColor, pressColor, "Прямое подключение", stargateState == "Connected"); y = y + 3
	buttons.disconnectButton = GUI.framedButton(x, y, buttonWidth, 3, lineColor, lineColor, pressColor, pressColor, "Отключиться", stargateState ~= "Connected"); y = y + 3
	buttons.messageButton = GUI.framedButton(x, y, buttonWidth, 3, lineColor, lineColor, pressColor, pressColor, "Сообщение", stargateState ~= "Connected"); y = y + 3
	buttons.closeIrisButton = GUI.framedButton(x, y, buttonWidth, 3, lineColor, lineColor, pressColor, pressColor, irisState == "Closed" and "Открыть Iris" or "Закрыть Iris", irisState == "Offline"); y = y + 3

	y = y + 1
	centerText(y, lineColor, "Контакты"); y = y + 2
	local sizeOfContacts = getArraySize(contacts.addresses)
	buttons.addContactButton = GUI.framedButton(x, y, buttonWidth, 3, lineColor, lineColor, pressColor, pressColor, "Добавить"); y = y + 3
	buttons.removeContactButton = GUI.framedButton(x, y, buttonWidth, 3, lineColor, lineColor, pressColor, pressColor, "Удалить", sizeOfContacts <= 0); y = y + 3
	buttons.connectToContactButton = GUI.framedButton(x, y, buttonWidth, 3, lineColor, lineColor, pressColor, pressColor, "Соединиться", sizeOfContacts <= 0 or stargateState == "Connected"); y = y + 3
	y = y + 1
	centerText(y, lineColor, "Затраты на активацию"); y = y + 2
	buffer.text(x, y, 0x228822, string.rep("━", buttonWidth))

	if remoteAddress ~= "" then
		local pidor = stargate.energyToDial(remoteAddress)
		local cyka = stargate.energyAvailable()
		local blyad = math.ceil(pidor * buttonWidth / cyka)
		centerText(y, lineColor, tostring(blyad) .. "%")
		buffer.text(x, y, 0x55FF55, string.rep("━", blyad))
	end

	y = y + 2
	buttons.quitButton = GUI.framedButton(x, y, buttonWidth, 3, lineColor, lineColor, pressColor, pressColor, "Выйти"); y = y + 3

end

local function drawAll(force)
	drawSG()
	buffer.draw(force)
end

local function connectSG(address)
	address = unicode.upper(address)

	local success, reason = stargate.dial(address)
	if success then
		contacts.lastAddress = address
		saveContacts()
	else
		GUI.error(reason, {title = {color = 0xFFDB40, text = "Ошибка подключения к Вратам"}, backgroundColor = 0x262626})
	end
end


-- ecs.prepareToExit()
-- for key, val in pairs(stargate) do print(key, val) end
-- ecs.wait()

loadContacts()

buffer.start()

drawAll(true)

while true do
	local e = {event.pull()}
	if e[1] == "touch" then
		for _, button in pairs(buttons) do
			if button:isClicked(e[3], e[4]) then
				button:press(0.2)

				if button.text == "Прямое подключение" then
					local data = ecs.universalWindow("auto", "auto", 36, 0x262626, true,
						{"EmptyLine"},
						{"CenterText", ecs.colors.orange, "Прямое подключение"},
						{"EmptyLine"},
						{"Input", 0xFFFFFF, ecs.colors.orange, contacts.lastAddress or "Введите адрес"},
						{"EmptyLine"},
						{"Button", {ecs.colors.orange, 0xffffff, "OK"}, {0x999999, 0xffffff, "Отмена"}}
					)
					if data[2] == "OK" then
						connectSG(data[1])
					end
				elseif button.text == "Открыть Iris" then
					stargate.openIris()
				elseif button.text == "Добавить" then
					local remoteAddress = stargate.remoteAddress()
					local data = ecs.universalWindow("auto", "auto", 36, 0x262626, true,
						{"EmptyLine"},
						{"CenterText", ecs.colors.orange, "Добавить контакт"},
						{"EmptyLine"},
						{"Input", 0xFFFFFF, ecs.colors.orange, "Название"},
						{"Input", 0xFFFFFF, ecs.colors.orange, contacts.lastAddress or component.stargate.remoteAddress() or "Адрес Звездных Врат"},
						{"EmptyLine"},
						-- remoteAddress ~= "" and
						-- {"Button", {ecs.colors.orange, 0xffffff, "OK"}, {0x999999, 0xffffff, "Добавить текущий"}, {0x777777, 0xffffff, "Отмена"}}
						-- or 
						{"Button", {ecs.colors.orange, 0xffffff, "OK"}, {0x777777, 0xffffff, "Отмена"}}
					)
					if data[3] == "OK" then
						contacts.addresses[data[1]] = data[2]
						saveContacts()
					-- elseif data[3] == "Добавить текущий" then
					-- 	contacts.addresses[data[1]] = remoteAddress
					-- 	saveContacts()
					end
					drawAll()
				elseif button.text == "Соединиться" or button.text == "Удалить" then
					local isConnect = (button.text == "Соединиться")
					local names = {}; for name in pairs(contacts.addresses) do table.insert(names, name) end
					local data = ecs.universalWindow("auto", "auto", 36, 0x262626, true,
						{"EmptyLine"},
						{"CenterText", ecs.colors.orange, isConnect and "Соединиться" or "Удалить контакт"},
						{"EmptyLine"},
						{"Selector", 0xFFFFFF, ecs.colors.orange, table.unpack(names)},
						{"EmptyLine"},
						{"Button", {ecs.colors.orange, 0xffffff, "OK"}, {0x999999, 0xffffff, "Отмена"}}
					)
					if data[2] == "OK" then
						if isConnect then
							connectSG(contacts.addresses[data[1]])
						else
							for name in pairs(contacts.addresses) do
								if name == data[1] then contacts.addresses[name] = nil; break end
							end
							saveContacts()
						end
						drawAll()
					end
				elseif button.text == "Закрыть Iris" then
					stargate.closeIris()
				elseif button.text == "Отключиться" then
					stateOfChevrons(false)
					stargate.disconnect()
				elseif button.text == "Выйти" then
					buffer.clear(0x262626)
					return
				elseif button.text == "Сообщение" then
					local data = ecs.universalWindow("auto", "auto", 36, 0x262626, true,
						{"EmptyLine"},
						{"CenterText", ecs.colors.orange, "Сообщение"},
						{"EmptyLine"},
						{"Input", 0xFFFFFF, ecs.colors.orange, "Текст сообщения"},
						{"EmptyLine"},
						{"Button", {ecs.colors.orange, 0xffffff, "OK"}, {0x999999, 0xffffff, "Отмена"}}
					)
					if data[2] == "OK" then
						component.stargate.sendMessage(data[1] or "Пустое сообщение")
					end
				end
			end
		end
	elseif e[1] == "sgIrisStateChange" then
		drawAll()
	elseif e[1] == "sgStargateStateChange" then
		if e[3] == "Closing" then stateOfChevrons(false) end
		drawAll()
	elseif e[1] == "sgChevronEngaged" then
		chevrons[e[3]].isActivated = true
		drawAll()
	elseif e[1] == "sgMessageReceived" then
		GUI.error(tostring(e[3]), {title = {color = 0xFFDB40, text = "Соообщение от Врат"}, backgroundColor = 0x262626})
	end
end
 









