
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

	scrollBar = 0xDDDDDD,
	scrollBarPipe = 0x888888,

	topBar = 0xEEEEEE,
	topMenu = 0xFFFFFF,

	chatZone = 0xFFFFFF,
	senderCloudColor = 0x3392FF,
	senderCloudTextColor = 0xFFFFFF,
	yourCloudColor = 0x55BBFF,
	yourCloudTextColor = 0xFFFFFF,
	systemMessageColor = 0x555555,

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

local contactsAvatarsPath = "MineOS/System/Chat/Avatars/"
local personalAvatarPath = contactsAvatarsPath .. "MyAvatar.pic"
local chatHistoryPath = "MineOS/System/Chat/History.cfg"
local avatarWidthLimit = 6
local avatarHeightLimit = 3

local currentChatID = 1
local currentChatMessage = 0
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
local messageInputWidth = chatZoneWidth - 19

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
	buffer.text(10, 3, 0x262626, chatHistory.myName)
end

local function drawTopMenu()
	buffer.menu(1, 1, buffer.screen.width, colors.topMenu, 0, {"Чат", 0x000099}, {"Настройки", 0x262626}, {"О программе", 0x262626})
end

local function drawCloud(x, y, cloudColor, textColor, fromYou, text)
	local upperPixel = "▀"
	local lowerPixel = "▄"
	local cloudHeight = #text + 2
	-- local cloudTextWidth = unicode.len(text[1])

	if not fromYou then
		buffer.set(x, y - cloudHeight + 2, colors.chatZone, cloudColor, upperPixel)
		buffer.set(x + 1, y - cloudHeight + 2, cloudColor, 0xFFFFFF, " ")
		x = x + 2
	else
		buffer.set(x + cloudTextWidth + 3, y - cloudHeight + 2, colors.chatZone, cloudColor, upperPixel)
		buffer.set(x + cloudTextWidth + 2, y - cloudHeight + 2, cloudColor, 0xFFFFFF, " ")
	end

	buffer.square(x + 1, y - cloudHeight + 1, cloudTextWidth, cloudHeight, cloudColor, 0xFFFFFF, " ")
	buffer.square(x, y - cloudHeight + 2, cloudTextWidth + 2, cloudHeight - 2, cloudColor, 0xFFFFFF, " ")
	
	buffer.set(x, y - cloudHeight + 1, colors.chatZone, cloudColor, lowerPixel)
	buffer.set(x + cloudTextWidth + 1, y - cloudHeight + 1, colors.chatZone, cloudColor, lowerPixel)
	buffer.set(x, y, colors.chatZone, cloudColor, upperPixel)
	buffer.set(x + cloudTextWidth + 1, y, colors.chatZone, cloudColor, upperPixel)

	x = x + 1
	y = y - 1

	for i = #text, 1, -1 do
		buffer.text(x, y, textColor, text[i])
		y = y - 1
	end

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
	local xYou, xSender = x + 2, buffer.screen.width - 9
	-- Отрисовка облачков
	local cloudColor, textColor
	for i = currentChatMessage, 1, -1 do
		--Если не указан тип сообщения, то ренедрим дефолтные облачка
		if not chatHistory[currentChatID][i].type then
			--Если сообщенька от тебя, то цвет меняем
			if chatHistory[currentChatID][i].fromYou then
				cloudColor, textColor = colors.yourCloudColor, colors.yourCloudTextColor
				y = drawCloud(xSender - cloudWidth - 2, y, cloudColor, textColor, chatHistory[currentChatID][i].fromYou, stringWrap(chatHistory[currentChatID][i].message, cloudTextWidth))
				buffer.image(xSender, y, avatars.personal)
			else
				cloudColor, textColor = colors.senderCloudColor, colors.senderCloudTextColor
				y = drawCloud(xYou + 8, y, cloudColor, textColor, chatHistory[currentChatID][i].fromYou, stringWrap(chatHistory[currentChatID][i].message, cloudTextWidth))
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

	buffer.scrollBar(buffer.screen.width - 1, yLeftBar, 2, chatZoneHeight, #chatHistory[currentChatID], currentChatMessage, colors.scrollBar, colors.scrollBarPipe)
end

local function drawMessageInputBar()
	local x, y = chatZoneX, yMessageInput
	buffer.square(x, y, chatZoneWidth, messageInputHeight, colors.messageInputBarColor, 0xFFFFFF, " ")
	y = y + 1
	buffer.square(x + 2, y, messageInputWidth, 3, colors.messageInputBarInputBackgroundColor, 0xFFFFFF, " ")
	buffer.text(x + 3, y + 1, colors.messsageInputBarTextColor, ecs.stringLimit("start", currentMessageText or "Введите сообщение", messageInputWidth - 2))

	obj.send = {buffer.button(chatZoneX + messageInputWidth + 4, y, 13, 3, colors.messsageInputBarButtonColor, colors.messsageInputBarButtonTextColor, "Отправить")}
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

local function addTextToChatHistoryArray(text)
	table.insert(chatHistory[currentChatID],
	{
		fromYou = true,
		message = text
	})
end

local function sendMessage()
	if chatHistory[currentChatID] and chatHistory[currentChatID].address and currentMessageText then
		modem.send(chatHistory[currentChatID].address, port, "HereIsMessageToYou", currentMessageText)

		addTextToChatHistoryArray(currentMessageText)

		currentChatMessage = #chatHistory[currentChatID]
		saveChatHistory()
	end

	currentMessageText = nil
	drawMessageInputBar()
	drawChat()

	buffer.draw()
end

local function checkAddressExists(address)
	local addressExists = false
	for i = 1, #chatHistory do
		if chatHistory[i].address == address then
			addressExists = true
			break
		end
	end
	return addressExists
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

--Обработчик сообщений
local function dro4er(_, localAddress, remoteAddress, remotePort, distance, ...)
	local messages = { ... }
	
	if remotePort == port then
		if messages[1] == "AddMeToContactsPlease" then
			if modemConnection.remoteAddress and modemConnection.remoteAddress == remoteAddress then
				--Добавляем пидорка к себе в контакты
				addNewContact(modemConnection.remoteAddress, messages[2], messages[3])
				--Сохраняем историю чата, ники, авки, все, крч
				saveChatHistory()
				--Просим того пидорка, чтобы он добавил нас к себе в контакты
				askForAddToContacts(modemConnection.remoteAddress)
				--Чтобы не было всяких соблазнов!
				modemConnection.availableUsers = {}
				modemConnection.remoteAddress = nil
				--Переключаемся на добавленный контакт
				switchToContact(#chatHistory)
				drawAll()
			end
		elseif messages[1] == "HereIsMessageToYou" then
			for i = 1, #chatHistory do
				--Если в массиве истории чата найден юзер, отославший такое сообщение
				if chatHistory[i].address == remoteAddress then
					--То вставляем само сообщение в историю чата
					table.insert(chatHistory[i], {fromYou = false, message = messages[2]})
					saveChatHistory()
					--Если текущая открытая история чата является именно вот этой, с этим отправителем
					if currentChatID == i then
						--Если мы никуда не скроллили и находимся в конце истории чата с этим юзером
						--То автоматически проскроллить на конец
						if currentChatMessage == (#chatHistory[currentChatID] - 1) then
							currentChatMessage = #chatHistory[currentChatID]
						end
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

-------------------------------------------------------------------------------------------------------------------------------

loadChatHistory()
loadPersonalAvatar()
if chatHistory[currentChatID] then
	switchToContact(1)
else
	currentChatID, currentChatMessage = 1, 1
end
modemConnection.startReceivingData()
modemConnection.disconnect()
modemConnection.sendPersonalData()
enableDro4er()

drawAll()

-------------------------------------------------------------------------------------------------------------------------------

while true do
	local e = { event.pull() }
	if e[1] == "touch" then
		-- Клик на поле ввода сообщения
		if ecs.clickedAtArea(e[3], e[4], chatZoneX + 2, yMessageInput, chatZoneX + messageInputWidth + 2, yMessageInput + 3) then
			local text = ecs.inputText(chatZoneX + 3, yMessageInput + 2, messageInputWidth - 2, currentMessageText, colors.messageInputBarInputBackgroundColor, colors.messsageInputBarTextColor)
			if text and text ~= "" then
				currentMessageText = text
			end
			buffer.square(chatZoneX + 2, yMessageInput + 2, messageInputWidth, 3, 0x000000, 0xFFFFFF, " ")
			drawMessageInputBar()
			buffer.draw()
		-- Жмякаем на кнопочку "Отправить"
		elseif ecs.clickedAtArea(e[3], e[4], obj.send[1], obj.send[2], obj.send[3], obj.send[4]) then
			buffer.button(obj.send[1], obj.send[2], 13, 3, colors.messsageInputBarButtonTextColor, colors.messsageInputBarButtonColor, "Отправить")
			buffer.draw()
			os.sleep(0.2)
			sendMessage()
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

		for key in pairs(obj.Contacts) do
			if ecs.clickedAtArea(e[3], e[4], obj.Contacts[key][1], obj.Contacts[key][2], obj.Contacts[key][3], obj.Contacts[key][4]) then
				switchToContact(key)
				drawAll()
				break
			end
		end
	elseif e[1] == "scroll" then
		if ecs.clickedAtArea(e[3], e[4], chatZoneX, yLeftBar, chatZoneX + chatZoneWidth - 1, yLeftBar + chatZoneHeight - 1) then
			scrollChat(e[5])
		end
	elseif e[1] == "key_down" then
		--Энтер, ага
		if e[4] == 28 then
			if currentMessageText then
				sendMessage()
			end
		end
	end
end





