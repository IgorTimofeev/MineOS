
local event = require("event")
local modemConnection = require("modemConnection")
local ecs = require("ECSAPI")
local fs = require("filesystem")
local serialization = require("serialization")
local buffer = require("doubleBuffering")
local context = require("context")
local image = require("image")
local unicode = require("unicode")
local component = require("component")
local computer = require("computer")
local modem = component.modem

-------------------------------------------------------------------------------------------------------------------------------

local colors = {
	leftBar = 0x262626,
	leftBarSelection = 0x00A8FF,
	leftBarAlternative = 0x383838,
	leftBarText = 0xFFFFFF,
	leftBarSelectionText = 0xFFFFFF,
	leftBarSearchButton = 0x555555,
	leftBarSearchButtonText = 0xFFFFFF,

	scrollBar = 0xCCCCCC,
	scrollBarPipe = 0x666666,

	topBar = 0xEEEEEE,
	topBarName = 0x000000,
	topBarAddress = 0x555555,

	topMenu = 0xFFFFFF,

	chatZone = 0xFFFFFF,
	senderCloudColor = 0x3392FF,
	senderCloudTextColor = 0xFFFFFF,
	yourCloudColor = 0x55BBFF,
	yourCloudTextColor = 0xFFFFFF,
	systemMessageColor = 0x555555,

	sendButtonColor = 0x555555,
	sendButtonTextColor = 0xFFFFFF,

	messageInputBarColor = 0xEEEEEE,
	messageInputBarInputBackgroundColor = 0xFFFFFF,
	messsageInputBarButtonColor = 0x3392FF,
	messsageInputBarButtonTextColor = 0xFFFFFF,
	messsageInputBarTextColor = 0x262626,
}

local chatHistory = {}
local avatars = {}
local port = 899
modem.open(port)

-------------------------------------------------------------------------------------------------------------------------------

local pathToSaveSendedFiles = "MineOS/Downloads/"
local contactsAvatarsPath = "MineOS/System/Chat/Avatars/"
local personalAvatarPath = contactsAvatarsPath .. "MyAvatar.pic"
local chatHistoryPath = "MineOS/System/Chat/History.cfg"
local avatarWidthLimit = 6
local avatarHeightLimit = 3

local currentChatID = 1
local currentChatMessage = 1
local currentMessageText

buffer.start()
local messageInputHeight = 5
local leftBarHeight = buffer.screen.height - 9
local leftBarWidth = math.floor(buffer.screen.width * 0.2)
local chatZoneWidth = buffer.screen.width - leftBarWidth
local heightOfTopBar = 2 + avatarHeightLimit
local yLeftBar = 2 + heightOfTopBar
local chatZoneX = leftBarWidth + 1
local bottom
local chatZoneHeight = buffer.screen.height - yLeftBar - messageInputHeight + 1
local cloudWidth = chatZoneWidth - 2 * (avatarWidthLimit + 9)
local cloudTextWidth = cloudWidth - 4
local yMessageInput = buffer.screen.height - messageInputHeight + 1
local sendButtonWidth = 7
local messageInputWidth = chatZoneWidth - sendButtonWidth - 6

-------------------------------------------------------------------------------------------------------------------------------

--Объекты для тача
local obj = {}
local function newObj(class, name, ...)
	obj[class] = obj[class] or {}
	obj[class][name] = {...}
end

local function saveChatHistory()
	fs.makeDirectory(fs.path(chatHistoryPath) or "")
	local file = io.open(chatHistoryPath, "w")
	file:write(serialization.serialize(chatHistory))
	file:close()
end

local function loadChatHistory()
	if fs.exists(chatHistoryPath) then
		local file = io.open(chatHistoryPath, "r")
		chatHistory = serialization.unserialize(file:read("*a"))
		file:close()
	else
		chatHistory = {myName = "Аноним №" .. math.random(1, 1000)}
		saveChatHistory()
	end
end

local function loadAvatarFromFile(path)
	local avatar = 	image.load(path)
	local widthDifference = avatar.width - avatarWidthLimit
	local heightDifference = avatar.height - avatarHeightLimit

	if widthDifference > 0 then
		avatar = image.crop(avatar, "fromRight", widthDifference)
	end
	if heightDifference > 0 then
		avatar = image.crop(avatar, "fromBottom", heightDifference)
	end
	
	return avatar
end

local function loadPersonalAvatar()
	avatars.personal = loadAvatarFromFile(personalAvatarPath)
end

local function loadContactAvatar(ID)
	avatars.contact = loadAvatarFromFile(contactsAvatarsPath .. ID .. ".pic")
end

local function saveContactAvatar(ID, data)
	local file = io.open(contactsAvatarsPath .. ID .. ".pic", "w")
	file:write(data)
	file:close()
end

local function switchToContact(ID)
	currentChatID = ID
	currentChatMessage = #chatHistory[currentChatID]
	loadContactAvatar(currentChatID)
	chatHistory[currentChatID].unreadedMessages = nil
end

local function drawLeftBar()
	buffer.square(1, yLeftBar, leftBarWidth, leftBarHeight, colors.leftBar, 0xFFFFFF, " ")

	local howMuchContactsCanBeShown = math.floor(leftBarHeight / 3)
	obj.Contacts = {}

	local yPos = yLeftBar
	local counter = 1
	local text, textColor
	
	for i = 1, #chatHistory do
		textColor = colors.leftBarText
	
		--Рисуем подложку
		if i == currentChatID then
			buffer.square(1, yPos, leftBarWidth, 3, colors.leftBarSelection, 0xFFFFFF, " ")
			textColor = 0xFFFFFF
		elseif counter % 2 ~= 0 then
			buffer.square(1, yPos, leftBarWidth, 3, colors.leftBarAlternative, 0xFFFFFF, " ")
		end

		--Создаем объекты для клика
		newObj("Contacts", i, 1, yPos, leftBarWidth, yPos + 2)

		--Рендерим корректное имя
		text = chatHistory[i].name or address
		text = ecs.stringLimit("end", text, leftBarWidth - 4)

		--Рисуем имя
		yPos = yPos + 1
		buffer.text(2, yPos, textColor, text)
		
		--Если имеются непрочитанные сообщения, то показать их
		if chatHistory[i].unreadedMessages then
			local stringCount = tostring(chatHistory[i].unreadedMessages)
			local stringCountLength = unicode.len(stringCount)
			local x = leftBarWidth - 3 - stringCountLength
			buffer.square(x, yPos, stringCountLength + 2, 1, colors.leftBarText, 0xFFFFFF, " ")
			buffer.text(x + 1, yPos, colors.leftBar, stringCount)
		end

		yPos = yPos + 2
		counter = counter + 1
		if counter > howMuchContactsCanBeShown or yPos > buffer.screen.height then
			break
		end
	end

	--Кнопочка поиска юзеров
	obj.search = {buffer.button(1, buffer.screen.height - 2, leftBarWidth, 3, colors.leftBarSearchButton, colors.leftBarSearchButtonText, "Поиск")}
end

local function drawTopBar()
	buffer.square(1, 2, buffer.screen.width, heightOfTopBar, colors.topBar, 0xFFFFFF, " ")

	buffer.image(3, 3, avatars.personal)
	buffer.text(11, 3, colors.topBarName, chatHistory.myName)
	buffer.text(11, 4, colors.topBarAddress, modemConnection.localAddress)
end

local function drawTopMenu()
	obj.TopMenu = buffer.menu(1, 1, buffer.screen.width, colors.topMenu, 0, {"Чат", 0x000099}, {"История", 0x000000}, {"О программе", 0x000000})
end

local function drawEmptyCloud(x, y, cloudWidth, cloudHeight, cloudColor, fromYou)
	local upperPixel = "▀"
	local lowerPixel = "▄"

	--Рисуем финтифлюшечки
	if not fromYou then
		buffer.set(x, y - cloudHeight + 2, colors.chatZone, cloudColor, upperPixel)
		buffer.set(x + 1, y - cloudHeight + 2, cloudColor, 0xFFFFFF, " ")
		x = x + 2
	else
		buffer.set(x + cloudWidth + 3, y - cloudHeight + 2, colors.chatZone, cloudColor, upperPixel)
		buffer.set(x + cloudWidth + 2, y - cloudHeight + 2, cloudColor, 0xFFFFFF, " ")
	end

	--Заполняшечки
	buffer.square(x + 1, y - cloudHeight + 1, cloudWidth, cloudHeight, cloudColor, 0xFFFFFF, " ")
	buffer.square(x, y - cloudHeight + 2, cloudWidth + 2, cloudHeight - 2, cloudColor, 0xFFFFFF, " ")
	
	--Сгругленные краешки
	buffer.set(x, y - cloudHeight + 1, colors.chatZone, cloudColor, lowerPixel)
	buffer.set(x + cloudWidth + 1, y - cloudHeight + 1, colors.chatZone, cloudColor, lowerPixel)
	buffer.set(x, y, colors.chatZone, cloudColor, upperPixel)
	buffer.set(x + cloudWidth + 1, y, colors.chatZone, cloudColor, upperPixel)

	return y - cloudHeight + 1
end

local function drawTextCloud(x, y, cloudColor, textColor, fromYou, text)
	local y = drawEmptyCloud(x, y, cloudTextWidth, #text + 2, cloudColor, fromYou)
	x = fromYou and x + 2 or x + 4

	for i = 1, #text do
		buffer.text(x, y + i, textColor, text[i])
	end

	return y
end

local function drawFileCloud(x, y, cloudColor, textColor, fromYou, fileName)
	local y = drawEmptyCloud(x, y, 14, 8, cloudColor, fromYou)
	x = fromYou and x + 2 or x + 4

	ecs.drawOSIcon(x, y + 1, fileName, true, textColor)

	return y
end

local function stringWrap(text, limit)
	local strings = {}
	local textLength = unicode.len(text)
	local subFrom = 1
	while subFrom <= textLength do
		table.insert(strings, unicode.sub(text, subFrom, subFrom + limit - 1))
		subFrom = subFrom + limit
	end
	return strings
end

local function drawChat()

	local x, y = chatZoneX, yLeftBar
	buffer.square(x, y, chatZoneWidth, chatZoneHeight, colors.chatZone, 0xFFFFFF, " ")

	--Если отстутствуют контакты, то отобразить стартовое сообщение
	if not chatHistory[currentChatID] then
		local text = ecs.stringLimit("start", "Добавьте контакты с помощью кнопки \"Поиск\"", chatZoneWidth - 2)
		local x, y = math.floor(chatZoneX + chatZoneWidth / 2 - unicode.len(text) / 2), math.floor(yLeftBar + chatZoneHeight / 2)
		buffer.text(x, y, 0x555555, text)
		return
	end

	-- Ставим ограничение отрисовки буфера, чтобы облачка сообщений не ебошили
	-- За края верхней зоны чатзоны, ну ты понял, да?
	buffer.setDrawLimit(x, y, chatZoneWidth, chatZoneHeight)

	-- Стартовая точка
	y = buffer.screen.height - messageInputHeight - 1
	local xYou, xSender = x + 2, buffer.screen.width - 8
	-- Отрисовка облачков
	for i = currentChatMessage, 1, -1 do
		--Если не указан тип сообщения, то ренедрим дефолтные облачка
		if not chatHistory[currentChatID][i].type then
			--Если сообщенька от тебя, то цвет меняем
			if chatHistory[currentChatID][i].fromYou then
				y = drawTextCloud(xSender - cloudWidth - 2, y, colors.yourCloudColor, colors.yourCloudTextColor, chatHistory[currentChatID][i].fromYou, stringWrap(chatHistory[currentChatID][i].message, cloudTextWidth - 2))
				buffer.image(xSender, y, avatars.personal)
			else
				y = drawTextCloud(xYou + 8, y, colors.senderCloudColor, colors.senderCloudTextColor, chatHistory[currentChatID][i].fromYou, stringWrap(chatHistory[currentChatID][i].message, cloudTextWidth))
				buffer.image(xYou, y, avatars.contact)
			end
		--Если сообщение имеет тип "Файл"
		elseif chatHistory[currentChatID][i].type == "file" then
			if chatHistory[currentChatID][i].fromYou then
				y = drawFileCloud(xSender - 20, y, colors.yourCloudColor, colors.yourCloudTextColor, chatHistory[currentChatID][i].fromYou, chatHistory[currentChatID][i].message)
				buffer.image(xSender, y, avatars.personal)
			else
				y = drawFileCloud(xYou + 8, y, colors.senderCloudColor, colors.senderCloudTextColor, chatHistory[currentChatID][i].fromYou, chatHistory[currentChatID][i].message)
				buffer.image(xYou, y, avatars.contact)
			end
		else
			for i = chatZoneX, buffer.screen.width - 2 do
				buffer.set(i, y, colors.chatZone, colors.systemMessageColor, "─")
			end
			local x = math.floor(chatZoneX + (chatZoneWidth - 2) / 2 - unicode.len(chatHistory[currentChatID][i].message) / 2)
			buffer.text(x, y, colors.systemMessageColor, " " .. chatHistory[currentChatID][i].message .. " ")
		end

		y = y - 2
		if y <= yLeftBar then break end
	end

	-- Убираем ограничение отроисовки буфера
	buffer.resetDrawLimit()

	buffer.scrollBar(buffer.screen.width, yLeftBar, 1, chatZoneHeight, #chatHistory[currentChatID], currentChatMessage, colors.scrollBar, colors.scrollBarPipe)
end

local function drawMessageInputBar()
	local x, y = chatZoneX, yMessageInput
	buffer.square(x, y, chatZoneWidth, messageInputHeight, colors.messageInputBarColor, 0xFFFFFF, " ")
	y = y + 1
	buffer.square(x + 2, y, messageInputWidth, 3, colors.messageInputBarInputBackgroundColor, 0xFFFFFF, " ")
	buffer.text(x + 3, y + 1, colors.messsageInputBarTextColor, ecs.stringLimit("start", currentMessageText or "Введите сообщение", messageInputWidth - 2))

	obj.send = {buffer.button(chatZoneX + messageInputWidth + 4, y, sendButtonWidth, 3, colors.sendButtonColor, colors.sendButtonTextColor, "⇪")}
end

local function drawAll(force)
	drawTopBar()
	drawLeftBar()
	drawTopMenu()
	drawChat()
	drawMessageInputBar()
	buffer.draw(force)
end

local function scrollChat(direction)
	if direction == 1 then
		if currentChatMessage > 1 then
			currentChatMessage = currentChatMessage - 1
			drawChat()
			drawMessageInputBar()
			buffer.draw()
		end
	else
		if currentChatMessage < #chatHistory[currentChatID] then
			currentChatMessage = currentChatMessage + 1
			drawChat()
			drawMessageInputBar()
			buffer.draw()
		end
	end
end

local function addMessageToArray(ID, type, fromYou, message)
	table.insert(chatHistory[ID], {type = type, fromYou = fromYou, message = message})
	saveChatHistory()
end

local function sendMessage(type, message)
	modem.send(chatHistory[currentChatID].address, port, "HereIsMessageToYou", type, message)

	addMessageToArray(currentChatID, nil, true, currentMessageText)

	currentChatMessage = #chatHistory[currentChatID]
	currentMessageText = nil
end

local function checkAddressExists(address)
	for i = 1, #chatHistory do
		if chatHistory[i].address == address then
			return true
		end
	end
	return false
end

local function addNewContact(address, name, avatarData)
	if not checkAddressExists(address) then
		table.insert(chatHistory, 
		{
			address = address,
			name = name,
			{
				type = "system",
				message = "Здесь будет показана история чата"
			}
		})
		saveChatHistory()
		saveContactAvatar(#chatHistory, avatarData)
	end
end

local function askForAddToContacts(address)
	--Загружаем авку
	local file = io.open(personalAvatarPath, "r")
	local avatarData = file:read("*a")
	file:close()
	--Отсылаем свое имечко и аватарку
	modem.send(address, port, "AddMeToContactsPlease", chatHistory.myName, avatarData)
end

local function getNameAndIDOfAddress(address)
	for i = 1, #chatHistory do
		if chatHistory[i].address == address then
			return chatHistory[i].name, i
		end
	end
	return nil, nil
end

local function autoScroll()
	--Если мы никуда не скроллили и находимся в конце истории чата с этим юзером
	--То автоматически проскроллить на конец
	if currentChatMessage == (#chatHistory[currentChatID] - 1) then
		currentChatMessage = #chatHistory[currentChatID]
	end
end

local function receiveFile(remoteAddress, fileName)
	--Чекаем, есть ли он в контактах
	if checkAddressExists(remoteAddress) then
		--Создаем директорию под файлики, а то мало ли
		fs.makeDirectory(pathToSaveSendedFiles)
		--Получаем имя отправителя из контактов
		local senderName, senderID = getNameAndIDOfAddress(remoteAddress)
		--Открываем файл для записи
		local file = io.open(pathToSaveSendedFiles .. fileName, "w")
		--Запоминаем пиксели под окошком прогресса
		local oldPixels = ecs.progressWindow("auto", "auto", 40, 0, "Прием файла", true)
		--Начинаем ожидать беспроводных сообщений в течение 10 секунд
		while true do
			local fileReceiveEvent = { event.pull(10, "modem_message") }
			--Это сообщение несет в себе процентаж передачи и сами данные пакета
			if fileReceiveEvent[6] == "FILESEND" then
				--Рисуем окошко прогресса
				ecs.progressWindow("auto", "auto", 40, fileReceiveEvent[7], "Прием файла")
				file:write(fileReceiveEvent[8])
			--Если нам присылают сообщение о завершении передачи, то закрываем файл
			elseif fileReceiveEvent[6] == "FILESENDEND" then
				ecs.progressWindow("auto", "auto", 40, 100, "Прием файла")
				file:close()
				ecs.drawOldPixels(oldPixels)

				--Вставляем сообщение с файликом-иконочкой
				addMessageToArray(senderID, "file", nil, fileName)
				autoScroll()
				drawAll()

				--Выдаем окошечко о том, что файл успешно передан
				ecs.universalWindow("auto", "auto", 30, 0x262626, true,
					{"EmptyLine"},
					{"CenterText", ecs.colors.orange, "Прием данных завершен"},
					{"EmptyLine"},
					{"CenterText", 0xFFFFFF, "Файл от " .. senderName .. " сохранен как"},
					{"CenterText", 0xFFFFFF, "\"" .. pathToSaveSendedFiles .. fileName .. "\""},
					{"EmptyLine"},
					{"Button", {ecs.colors.orange, 0x262626, "OK"}}
				)

				break
			--Если не получали в течение указанного промежутка сообщений, то выдать сообщение об ошибке и удалить файл
			elseif not fileReceiveEvent[1] then
				file:close()
				ecs.drawOldPixels(oldPixels)
				fs.remove(pathToSaveSendedFiles .. fileName)
				ecs.error("Ошибка при передаче файла: клиент не отвечает")
				drawAll()
				break
			end
		end
	end
end

--Обработчик сообщений
local function dro4er(_, localAddress, remoteAddress, remotePort, distance, ...)
	local messages = { ... }
	
	if remotePort == port then
		if messages[1] == "AddMeToContactsPlease" then
			if modemConnection.remoteAddress and modemConnection.remoteAddress == remoteAddress then
				-- ecs.error("Сообщение о добавлении получил, адрес: " .. modemConnection.remoteAddress .. ", имя:" .. messages[2] .. ", авка: " .. type(messages[3]))
				--Добавляем пидорка к себе в контакты
				addNewContact(modemConnection.remoteAddress, messages[2], messages[3])
				--Просим того пидорка, чтобы он добавил нас к себе в контакты
				askForAddToContacts(modemConnection.remoteAddress)
				--Чтобы не было всяких соблазнов!
				modemConnection.availableUsers = {}
				modemConnection.remoteAddress = nil
				--Переключаемся на добавленный контакт
				switchToContact(#chatHistory)
				drawAll()
			end
		--Если какой-то чувак просит нас принять файл
		elseif messages[1] == "FAYLPRIMI" then
			receiveFile(remoteAddress, messages[2])
		elseif messages[1] == "HereIsMessageToYou" then
			for i = 1, #chatHistory do
				--Если в массиве истории чата найден юзер, отославший такое сообщение
				if chatHistory[i].address == remoteAddress then
					--То вставляем само сообщение в историю чата
					addMessageToArray(i, messages[2], nil, messages[3])
					--Если текущая открытая история чата является именно вот этой, с этим отправителем
					if currentChatID == i then
						autoScroll()
						--Обязательно отрисовываем измененную историю чата с этим отправителем
						drawChat()
						buffer.draw()
					--Увеличиваем количество непрочитанных сообщений от отправителя
					else
						chatHistory[i].unreadedMessages = chatHistory[i].unreadedMessages and chatHistory[i].unreadedMessages + 1 or 1
						drawLeftBar()
						buffer.draw()
					end

					--Бип!
					computer.beep(1700)

					--А это небольшой костыльчик, чтобы не сбивался цвет курсора Term API
					component.gpu.setBackground(colors.messageInputBarInputBackgroundColor)
					component.gpu.setForeground(colors.messsageInputBarTextColor)

					break
				end
			end
		end
	end
end

local function enableDro4er()
	event.listen("modem_message", dro4er)
end

local function disableDro4er()
	event.ignore("modem_message", dro4er)
end

local function deleteAvatar(ID)
	fs.remove(contactsAvatarsPath .. ID .. ".pic")
end

local function clearChatHistory()
	for i = 1, #chatHistory do
		deleteAvatar(i)
		chatHistory[i] = nil
	end
	saveChatHistory()
end

local function sendFile(path)
	local data = ecs.universalWindow("auto", "auto", 30, 0x262626, true,
		{"EmptyLine"},
		{"CenterText", ecs.colors.orange, "Отправить файл"},
		{"EmptyLine"},
		{"Input", 0xFFFFFF, ecs.colors.orange, "Путь"},
		{"EmptyLine"},
		{"Button", {ecs.colors.orange, 0x262626, "OK"}, {0x666666, 0xffffff, "Отмена"}}
	)

	if data[2] == "OK" then
		if fs.exists(data[1]) then
			--Отправляем сообщение о том, что мы собираемся отправить файл
			modem.send(chatHistory[currentChatID].address, port, "FAYLPRIMI", fs.name(data[1]))
			--Открываем файл и отправляем его по количеству пакетов
			local maxPacketSize = modem.maxPacketSize() - 32
			local file = io.open(data[1], "rb")
			local fileSize = fs.size(data[1])
			local percent = 0
			local sendedBytes = 0
			local dataToSend
		
			while true do
				dataToSend = file:read(maxPacketSize)
				if dataToSend then
					modem.send(chatHistory[currentChatID].address, port, "FILESEND", percent, dataToSend)
					sendedBytes = sendedBytes + maxPacketSize
					percent = math.floor(sendedBytes / fileSize * 100)
				else
					break
				end
			end
		
			file:close()
			--Репортуем об окончании передачи файла
			modem.send(chatHistory[currentChatID].address, port, "FILESENDEND")
			--Вставляем в чат инфу об обтправленном файле
			addMessageToArray(currentChatID, "file", true, fs.name(data[1]))
			autoScroll()
			drawAll()
		else
			ecs.error("Файл \"" .. data[1] .. "\" не существует.")
		end
	end
end

local function deleteContact(ID)
	table.remove(chatHistory, ID)
	deleteAvatar(ID)
	if #chatHistory > 0 then
		switchToContact(1)
	else
		currentChatID = 1
		currentChatMessage = 1
	end
	saveChatHistory()
end

-------------------------------------------------------------------------------------------------------------------------------

--Отключаем принудительное завершение программы
ecs.disableInterrupting()
--Загружаем историю чата и свою аватарку
loadChatHistory()
loadPersonalAvatar()
--Если история не пуста, то переключаемся на указанный контакт
if chatHistory[currentChatID] then
	switchToContact(currentChatID)
end
--Включаем прием данных по модему для подключения
modemConnection.startReceivingData()
--Отсылаем всем модемам сигнал о том, чтобы они удалили нас из своего списка
modemConnection.disconnect()
--Отправляем свои данные, чтобы нас заново внесли в список
modemConnection.sendPersonalData()
--Активируем прием сообщений чата
enableDro4er()
--Рисуем весь интерфейс
drawAll()

-------------------------------------------------------------------------------------------------------------------------------

while true do
	local e = { event.pull() }
	if e[1] == "touch" then
		-- Клик на поле ввода сообщения
		if #chatHistory > 0 and ecs.clickedAtArea(e[3], e[4], chatZoneX + 2, yMessageInput, chatZoneX + messageInputWidth + 2, yMessageInput + 3) then
			local text = ecs.inputText(chatZoneX + 3, yMessageInput + 2, messageInputWidth - 2, currentMessageText, colors.messageInputBarInputBackgroundColor, colors.messsageInputBarTextColor)
			if text ~= nil and text ~= "" then
				currentMessageText = text
				sendMessage(nil, currentMessageText)
				buffer.square(chatZoneX + 2, yMessageInput + 1, messageInputWidth, 3, colors.messageInputBarInputBackgroundColor, 0xFFFFFF, " ")
				buffer.draw()
				drawMessageInputBar()
				drawChat()
				buffer.draw()
			end
		-- Жмякаем на кнопочку "Отправить"
		elseif #chatHistory > 0 and ecs.clickedAtArea(e[3], e[4], obj.send[1], obj.send[2], obj.send[3], obj.send[4]) then
			buffer.button(obj.send[1], obj.send[2], sendButtonWidth, 3, colors.sendButtonTextColor, colors.sendButtonColor, "⇪")
			buffer.draw()
			os.sleep(0.2)
			drawMessageInputBar()
			buffer.draw()
			sendFile()
		-- Кнопа поиска
		elseif ecs.clickedAtArea(e[3], e[4], obj.search[1], obj.search[2], obj.search[3], obj.search[4]) then
			buffer.button(obj.search[1], obj.search[2], leftBarWidth, 3, colors.leftBarSearchButtonText, colors.leftBarSearchButton, "Поиск")
			buffer.draw()
			os.sleep(0.2)

			modemConnection.search()

			--Если после поиска мы подключились к какому-либо адресу
			if modemConnection.remoteAddress then
				--Просим адрес добавить нас в свой список контактов
				askForAddToContacts(modemConnection.remoteAddress)
			end

			drawAll(true)
		end

		--Клик на контакты
		for key in pairs(obj.Contacts) do
			if ecs.clickedAtArea(e[3], e[4], obj.Contacts[key][1], obj.Contacts[key][2], obj.Contacts[key][3], obj.Contacts[key][4]) then
				if e[5] == 0 then
					switchToContact(key)
					drawAll()
				else
					local action = context.menu(e[3], e[4], {"Переименовать"}, {"Удалить"})
					if action == "Переименовать" then
						local data = ecs.universalWindow("auto", "auto", 30, 0x262626, true,
							{"EmptyLine"},
							{"CenterText", ecs.colors.orange, "Переименовать контакт"},
							{"EmptyLine"},
							{"Input", 0xFFFFFF, ecs.colors.orange, chatHistory[key].name},
							{"EmptyLine"},
							{"Button", {ecs.colors.orange, 0x262626, "OK"}, {0x666666, 0xffffff, "Отмена"}}
						)

						if data[2] == "OK" then
							chatHistory[key].name = data[1] or chatHistory[key].name
							drawAll()
						end
					elseif action == "Удалить" then
						deleteContact(key)
						drawAll()
					end
				end

				break
			end
		end

		for key in pairs(obj.TopMenu) do
			if ecs.clickedAtArea(e[3], e[4], obj.TopMenu[key][1], obj.TopMenu[key][2], obj.TopMenu[key][3],obj.TopMenu[key][4]) then
				buffer.button(obj.TopMenu[key][1] - 1, obj.TopMenu[key][2], unicode.len(key) + 2, 1, ecs.colors.blue, 0xFFFFFF, key)
				buffer.draw()

				local action
				if key == "Чат" then
					action = context.menu(obj.TopMenu[key][1] - 1, obj.TopMenu[key][2] + 1, {"Изменить имя"}, {"Изменить аватар"}, {"Очистить историю"},"-", {"Выход"})
				elseif key == "О программе" then
					ecs.universalWindow("auto", "auto", 36, 0x262626, true, 
						{"EmptyLine"},
						{"CenterText", ecs.colors.orange, "Chat v1.0"}, 
						{"EmptyLine"},
						{"CenterText", 0xFFFFFF, "Автор:"},
						{"CenterText", 0xBBBBBB, "Тимофеев Игорь"},
						{"CenterText", 0xBBBBBB, "vk.com/id7799889"},
						{"EmptyLine"},
						{"CenterText", 0xFFFFFF, "Тестеры:"},
						{"CenterText", 0xBBBBBB, "Егор Палиев"},
						{"CenterText", 0xBBBBBB, "vk.com/mrherobrine"},
						{"CenterText", 0xBBBBBB, "Максим Хлебников"},
						{"CenterText", 0xBBBBBB, "vk.com/mskalash"},
						{"EmptyLine"},
						{"Button", {ecs.colors.orange, 0x262626, "OK"}}
					)
				end

				if action == "Выход" then
					disableDro4er()
					modemConnection.stopReceivingData()
					modemConnection.disconnect()
					ecs.enableInterrupting()
					modem.close(port)
					buffer.clear()
					ecs.prepareToExit()
					return
				elseif action == "Очистить историю" then
					clearChatHistory()
					drawAll()
				end

				drawTopMenu()
				buffer.draw()

				break
			end
		end

	elseif e[1] == "scroll" then
		if #chatHistory > 0 and ecs.clickedAtArea(e[3], e[4], chatZoneX, yLeftBar, chatZoneX + chatZoneWidth - 1, yLeftBar + chatZoneHeight - 1) then
			scrollChat(e[5])
		end
	end
end





