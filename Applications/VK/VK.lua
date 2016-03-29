
---------------------------------------------------- Библиотеки ----------------------------------------------------------------

local internet = require("internet")
local json = require("json")
local serialization = require("serialization")
local event = require("event")
local ecs = require("ECSAPI")
local fs = require("filesystem")
local buffer = require("doubleBuffering")
local context = require("context")
local image = require("image")
local unicode = require("unicode")
local component = require("component")
local computer = require("computer")

---------------------------------------------------- Константы ----------------------------------------------------------------

local VKAPIVersion = "5.50"

local colors = {
	leftBar = 0x262626,
	leftBarAlternative = 0x383838,
	leftBarText = 0xFFFFFF,
	leftBarSelection = 0x00A8FF,
	leftBarSelectionText = 0xFFFFFF,

	scrollBar = 0xCCCCCC,
	scrollBarPipe = 0x666666,

	mainZone = 0xFFFFFF,
	senderCloudColor = 0x3392FF,
	senderCloudTextColor = 0xFFFFFF,
	yourCloudColor = 0x55BBFF,
	yourCloudTextColor = 0xFFFFFF,
	systemMessageColor = 0x555555,
	dateTime = 0x777777,

	loginGUIBackground = 0x002440,

	topBar = 0x002440,
	topBarText = 0xFFFFFF,

	statusBar = 0x262626,
	statusBarText = 0xAAAAAA,

	audioPlayButton = 0x002440,
	audioPlayButtonText = 0xFFFFFF,

	messageInputBarColor = 0xEEEEEE,
	messageInputBarTextBackgroundColor = 0xFFFFFF,
	messsageInputBarTextColor = 0x262626,
}

local leftBarHeight = buffer.screen.height - 9
local leftBarWidth = math.floor(buffer.screen.width * 0.17)

local topBarHeight = 3

local mainZoneWidth = buffer.screen.width - leftBarWidth
local mainZoneHeight = buffer.screen.height - topBarHeight - 1
local mainZoneX = leftBarWidth + 1
local mainZoneY = topBarHeight + 1

local cloudWidth = math.floor(mainZoneWidth * 0.7)

-------------------------------------------------------------------------------------------------------------------------------

local VKLogoImagePath = "MineOS/Applications/VK.app/Resources/VKLogo.pic"
-- local leftBarElements = {"Новости", "Друзья", "Сообщения", "Настройки", "Выход"}
local leftBarElements = { "Сообщения", "Аудиозаписи", "Группы", "Выход" }
local currentLeftBarElement = 1
local personalInfo
local access_token
local whatIsOnScreen

local countOfDialogsToLoadFromServer = 10
local countOfAudioToLoadFromServer = 10
local countOfMessagesToLoadFromServer = 10

local dialogToShowFrom = 1
local audioToShowFrom = 1
local messageToShowFrom = 1

local dialogScrollSpeed = 5
local audioScrollSpeed = 5
local messagesScrollSpeed = 5

local currentMessagesPeerID, currentMessagesAvatarText, currentMessagesFullName
local dialogPreviewTextLimit = mainZoneWidth - 15

---------------------------------------------------- Веб-часть ----------------------------------------------------------------

--Объекты
local obj = {}
local function newObj(class, name, ...)
	obj[class] = obj[class] or {}
	obj[class][name] = {...}
end

--Дебаг-функция на сохранение говна в файл, МАЛО ЛИ ЧО
local function saveToFile(stro4ka)
	local file = io.open("test.lua", "w")
	file:write(stro4ka)
	file:close()
end

--Модифицированная функция интернет-запросов, стандартная фу-фу-фу, ошибка на ошибке и HTTP Response Error погоняет!
--Заметка: переписать на компонетное API, в рот ебал автора либы. Хм, велосипеды?
local function request(url)
	local data = ""
	--Выполняем запрос на подключение
	local success, response = pcall(internet.request, url)
	--Если все ок, то делаем чтение из response, иначе выдаем ошибку, че не так с подключением 
	--(скорее всего, ошибка будет связана с отстутствием инета или неверными URL, которые ТЫ, СУКА, лично и вбиваешь в код)
	if success then
		while true do
			--Делаем запрос на чтение из response
			local success, reason = pcall(response)
			--Если все ок, то идем дальше, иначе кидаем ошибку 
			--(скорее всего, это будет серверная ошибка, неверный пасс там, 404, бла-бла)
			if success then
				--Если конец response не достигнут, то записываем в data все, что пришло с сервака, иначе по съебкам!
				if reason then
					data = data .. reason
				else
					break
				end
			else
				return false, reason
			end
		end
		
		--Если все охуенно, то возвращаем true и преобразованный JSON-ответ в таблицу Lua
		return true, json:decode(data)
	else
		return false, response
	end
end

--Отправляем запрос на авторизацию по логину и паролю
local function getLoginDataRequest(username, password)
	local url = "https://oauth.vk.com/token?grant_type=password&client_id=3697615&client_secret=AlVXZFMUqyrnABp8ncuU&username=" .. username .. "&password=" .. password .. "&v=" .. VKAPIVersion
	return request(url)
end

--Запрос к методам VK API
local function VKAPIRequest(method, ... )
	local arguments = { ... }
	local stringArguments = ""

	local url = "https://api.vk.com/method/" .. method .. "?" .. table.concat(arguments, "&") .. "&access_token=" .. access_token .. "&v=" .. VKAPIVersion

	return request(url)
end

--Запрос на получение списка диалогов
local function getDialogsRequest(fromDialog, count)
	return VKAPIRequest("messages.getDialogs", "offset=" .. fromDialog, "count=" .. count, "preview_length=" .. dialogPreviewTextLimit)
end

--Запрос на получение списка диалогов
local function getMessagesRequest(peerID, fromMessage, count)
	return VKAPIRequest("messages.getHistory", "offset=" .. fromMessage, "count=" .. count, "peer_id=" .. peerID)
end

--Запрос на получение списка музычки
local function getAudioRequest(id, fromAudio, count)
	return VKAPIRequest("audio.get", "offset=" .. fromAudio, "count=" .. count, "owner_id=" .. id, "need_user=1")
end

--Эта хуйня делает строку охуенной путем замены говна на конфетку
local function optimizeStringForURLSending(code)
  if code then
    code = string.gsub(code, "([^%w ])", function (c)
      return string.format("%%%02X", string.byte(c))
    end)
    code = string.gsub(code, " ", "+")
  end
  return code 
end

local function optimizeStringForWrongSymbols(s)
	--Удаляем некорректные символы
	s = string.gsub(s, "	", " ")
	s = string.gsub(s, "\r\n", "\n")
	s = string.gsub(s, "\n", "")
	--Заменяем "широкие" двухпиксельные символы на знак вопроса
	local massiv = {}
	for i = 1, unicode.len(s) do
		massiv[i] = unicode.sub(s, i, i)
		if unicode.isWide(massiv[i]) then massiv[i] = "?" end
	end
	--Возвращаем оптимизрованную строку
	return table.concat(massiv)
end

local function convertIDtoPeerID(whatIsThisID, ID)
	if whatIsThisID == "user" then
		return ID
	elseif whatIsThisID == "chat" then
		return (2000000000 + ID)
	elseif whatIsThisID == "group" then
		return -ID
	end
end

local function getPeerIDFromMessageArray(messageArray)
	local peerID
	--Если это чат
	if messageArray.users_count then
		peerID = convertIDtoPeerID("chat", messageArray.chat_id)
	--Или если это диалог с группой какой-то
	elseif messageArray.user_id < 0 then
		peerID = convertIDtoPeerID("group", messageArray.user_id)
	--Или если просто какой-то сталкер-одиночка
	else
		peerID = convertIDtoPeerID("user", messageArray.user_id)
	end

	return peerID
end

--Запрос на отправку сообщения указанному пидору
local function sendMessageRequest(peerID, message)
	--Делаем строчку не пидорской
	message = optimizeStringForURLSending(message)
	return VKAPIRequest("messages.send", "peer_id=" .. peerID, "message=" .. message)
end

local function usersInformationRequest(...)
	return VKAPIRequest("users.get", "user_ids=" .. table.concat({...}, ","), "fields=city,bdate,online,status,last_seen,followers_count")
end

---------------------------------------------------- GUI-часть ----------------------------------------------------------------

local function createAvatarHashColor(hash)
	return math.abs(hash % 0xFFFFFF)
end

local function drawAvatar(x, y, user_id, text)
	local avatarColor = createAvatarHashColor(user_id)
	local textColor = avatarColor > 8388607 and 0x000000 or 0xFFFFFF

	buffer.square(x, y, 6, 3, avatarColor, textColor, " ")
	buffer.text(x + 2, y + 1, textColor, unicode.upper(text))
end

--Проверка клика в определенную область по "объекту". Кому на хуй вссалось ООП?
local function clickedAtZone(x, y, zone)
	if x >= zone[1] and y >= zone[2] and x <= zone[3] and y <= zone[4] then
		return true
	end
	return false
end

--Интерфейс логина в аккаунт ВК, постараюсь сделать пографонистей
--Хотя хах! Кого я обманываю, ага
local function loginGUI(startUsername, startPassword)
	local background = 0x002440
	local buttonColor = 0x666DFF
	local textColor = 0x262626
	local username, password = startUsername or "E-Mail или номер телефона", startPassword or "Пароль"

	local textFieldWidth = 50
	local textFieldHeight = 3
	local x, y = math.floor(buffer.screen.width / 2 - textFieldWidth / 2), math.floor(buffer.screen.height / 2 - 3)

	local obj = {}
	obj.username = {x, y, x + textFieldWidth - 1, y + 2}; y = y + textFieldHeight + 1
	obj.password = {x, y, x + textFieldWidth - 1, y + 2}; y = y + textFieldHeight + 1
	obj.button = {x, y, x + textFieldWidth - 1, y + 2}

	local VKLogoImage = image.load(VKLogoImagePath)

	local function draw()
		buffer.clear(colors.loginGUIBackground)

		buffer.image(x + 5, obj.username[2] - 15, VKLogoImage)

		buffer.square(x, obj.username[2], textFieldWidth, 3, 0xFFFFFF, 0x000000, " ")
		buffer.square(x, obj.password[2], textFieldWidth, 3, 0xFFFFFF, 0x000000, " ")
		buffer.text(x + 1, obj.username[2] + 1, textColor, ecs.stringLimit("end", username, textFieldWidth - 2))
		buffer.text(x + 1, obj.password[2] + 1, textColor, ecs.stringLimit("end", string.rep("●", unicode.len(password)), textFieldWidth - 2))

		buffer.button(x, obj.button[2], textFieldWidth, textFieldHeight, buttonColor, 0xFFFFFF, "Войти")

		buffer.draw()
	end

	while true do
		draw()
		local e = {event.pull()}
		if e[1] == "touch" then
			if clickedAtZone(e[3], e[4], obj.username) then
				username = ""
				username = ecs.inputText(x + 1, obj.username[2] + 1, textFieldWidth - 2, username, 0xFFFFFF, 0x262626) or ""
			
			elseif clickedAtZone(e[3], e[4], obj.password) then
				password = ""
				password = ecs.inputText(x + 1, obj.password[2] + 1, textFieldWidth - 2, password, 0xFFFFFF, 0x262626, false, "*") or ""
			
			elseif clickedAtZone(e[3], e[4], obj.button) then
				buffer.button(x, obj.button[2], textFieldWidth, textFieldHeight, 0xFFFFFF, buttonColor, "Войти")
				buffer.draw()
				os.sleep(0.2)
				draw()
				local success, loginData = getLoginDataRequest(username, password)
				if success then 
					return loginData
				else
					ecs.error("Неверный пароль!" .. tostring(loginData))
				end
			end
		end
	end
end

---------------------------------------------------- GUI для взаимодействия с VK API ----------------------------------------------

local function drawPersonalAvatar(x, y)
	drawAvatar(x, y, personalInfo.id, unicode.sub(personalInfo.first_name, 1, 1) .. unicode.sub(personalInfo.last_name, 1, 1))
end

local function status(text)
	buffer.square(mainZoneX, buffer.screen.height, mainZoneWidth, 1, colors.statusBar)
	buffer.text(mainZoneX + 1, buffer.screen.height, colors.statusBarText, text)
	buffer.draw()
end

local function drawTopBar(text)
	buffer.square(mainZoneX, 1, mainZoneWidth, 3, colors.topBar)
	local x = math.floor(mainZoneX + mainZoneWidth / 2 - unicode.len(text) / 2 - 1)
	buffer.text(x, 2, colors.topBarText, text)
end

--Рисуем главную зону
local function clearGUIZone()
	buffer.square(mainZoneX, mainZoneY, mainZoneWidth, mainZoneHeight, colors.mainZone)
end







local function drawEmptyCloud(x, y, cloudWidth, cloudHeight, cloudColor, fromYou)
	local upperPixel = "▀"
	local lowerPixel = "▄"

	--Рисуем финтифлюшечки
	if not fromYou then
		buffer.set(x, y - cloudHeight + 2, colors.mainZone, cloudColor, upperPixel)
		buffer.set(x + 1, y - cloudHeight + 2, cloudColor, 0xFFFFFF, " ")
		x = x + 2
	else
		buffer.set(x + cloudWidth + 3, y - cloudHeight + 2, colors.mainZone, cloudColor, upperPixel)
		buffer.set(x + cloudWidth + 2, y - cloudHeight + 2, cloudColor, 0xFFFFFF, " ")
	end

	--Заполняшечки
	buffer.square(x + 1, y - cloudHeight + 1, cloudWidth, cloudHeight, cloudColor, 0xFFFFFF, " ")
	buffer.square(x, y - cloudHeight + 2, cloudWidth + 2, cloudHeight - 2, cloudColor, 0xFFFFFF, " ")
	
	--Сгругленные краешки
	buffer.set(x, y - cloudHeight + 1, colors.mainZone, cloudColor, lowerPixel)
	buffer.set(x + cloudWidth + 1, y - cloudHeight + 1, colors.mainZone, cloudColor, lowerPixel)
	buffer.set(x, y, colors.mainZone, cloudColor, upperPixel)
	buffer.set(x + cloudWidth + 1, y, colors.mainZone, cloudColor, upperPixel)

	return y - cloudHeight + 1
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

local function drawTextCloud(x, y, cloudColor, textColor, fromYou, text)
	local y = drawEmptyCloud(x, y, cloudWidth, #text + 2, cloudColor, fromYou)
	x = fromYou and x + 2 or x + 4

	for i = 1, #text do
		buffer.text(x, y + i, textColor, text[i])
	end

	return y
end

local function getAttachments(messageArray)
	local text = "Вложения: "
	for j = 1, #messageArray.attachments do
		if messageArray.attachments[j].type == "sticker" then
			text = text .. "стикер, "
		elseif messageArray.attachments[j].type == "photo" then
			text = text .. "фото, "
		elseif messageArray.attachments[j].type == "video" then
			text = text .. "видео, "
		elseif messageArray.attachments[j].type == "audio" then
			text = text .. "аудио, "
		elseif messageArray.attachments[j].type == "wall" then
			text = text .. "запись на стене, "
		end
	end
	text = unicode.sub(text, 1, -3)

	return text
end

local function drawMessageInputBar(currentText)
	local x, y = mainZoneX, buffer.screen.height - 5
	obj.messageInputBar = { x, y, x + mainZoneWidth - 7, y + 2}
	buffer.square(x, y, mainZoneWidth, 5, colors.messageInputBarColor)
	buffer.square(x + 2, y + 1, mainZoneWidth - 4, 3, colors.messageInputBarTextBackgroundColor)
	buffer.text(x + 4, y + 2, colors.messsageInputBarTextColor, ecs.stringLimit("start", currentText or "Введите сообщение", mainZoneWidth - 8))
end

local function getUserNamesFromMessagesArray(messagesArray)
	local usersToGetNames = {}
	for i = 1, #messagesArray do
		if messagesArray[i].user_id and messagesArray[i].user_id > 0 then
			table.insert(usersToGetNames, messagesArray[i].user_id)
		end
	end

	local success, usersData = usersInformationRequest(table.unpack(usersToGetNames))
	if success and usersData.response then
		for i = 1, #messagesArray do
			if messagesArray[i].user_id and messagesArray[i].user_id > 0 then
				for j = 1, #usersData.response do
					if usersData.response[j].id == messagesArray[i].user_id then
						messagesArray[i].first_name = usersData.response[j].first_name
						messagesArray[i].last_name = usersData.response[j].last_name
					end
				end
			end
		end
	end

	return messagesArray
end

local function messagesGUI()

	local success, messages = getMessagesRequest(currentMessagesPeerID, messageToShowFrom - 1, countOfMessagesToLoadFromServer)
	if success and messages.response then

		whatIsOnScreen = "messages"

		if currentMessagesPeerID > 2000000000 then
			status("Загружаю имена пользователей из переписки (актуально для конференций)")
			messages.response.items = getUserNamesFromMessagesArray(messages.response.items)
		end

		clearGUIZone()
		drawTopBar("Диалог с \"" .. currentMessagesFullName .. "\"")

		saveToFile(serialization.serialize(messages))

		buffer.setDrawLimit(mainZoneX, mainZoneY, mainZoneWidth, mainZoneHeight)

		local y = buffer.screen.height - 7
		local xSender = mainZoneX + 2
		local xYou = buffer.screen.width - 7

		for i = 1, #messages.response.items do

			local messageTextArray = {}

			if messages.response.items[i].body ~= "" then table.insert(messageTextArray, optimizeStringForWrongSymbols(messages.response.items[i].body)) end
			if messages.response.items[i].fwd_messages then table.insert(messageTextArray, "Пересланные сообщения") end
			if messages.response.items[i].attachments then table.insert(messageTextArray, getAttachments(messages.response.items[i])) end

			messageTextArray = ecs.stringWrap(messageTextArray, cloudWidth - 4)
			local peerID = getPeerIDFromMessageArray(messages.response.items[i])

			--Делаем дату пиздатой
			-- messages.response.items[i].date = os.date("%d.%m.%y в %X", messages.response.items[i].date)
			messages.response.items[i].date = os.date("%H:%M", messages.response.items[i].date)

			if messages.response.items[i].out == 1 then
				y = drawTextCloud(xYou - cloudWidth - 6, y, colors.yourCloudColor, colors.yourCloudTextColor, true, messageTextArray)
				drawPersonalAvatar(xYou, y)
				buffer.text(xYou - cloudWidth - unicode.len(messages.response.items[i].date) - 8, y + 1, colors.dateTime, messages.response.items[i].date)
			else
				y = drawTextCloud(xSender + 8, y, colors.senderCloudColor, colors.senderCloudTextColor, false, messageTextArray)
				drawAvatar(xSender, y, peerID, messages.response.items[i].first_name and (unicode.sub(messages.response.items[i].first_name, 1, 1) .. unicode.sub(messages.response.items[i].last_name, 1, 1)) or currentMessagesAvatarText)
				buffer.text(xSender + cloudWidth + 14, y + 1, colors.dateTime, messages.response.items[i].date)
			end

			y = y - 2
		end

		local currentText

		drawMessageInputBar(currentText)

		status("История переписки загружена, ожидаю ввода сообщения")

		buffer.resetDrawLimit()
		-- buffer.draw()
	end
end






--У-у-у, господи, какие же уроды! Вроде такое охуенное вк апи, а пиздец!
--Крч, эта функция получает имена юзеров по их айдишникам и загоняет их
--в массив вместо title.
--Собсна, нахуя? ДА ПОТОМУ ЧТО dialogs возвращают только ID юзеров с историей
--сообщений, а не их имя. Ну, а имена КОНФ нормас пишутся. Что за бред?
--Идите на хуйЙ!!!!!! КОСТЫЛЕЕБСТВО
local function getUserNamesFromDialogArray(dialogs)
	local usersToGetNames = {}
	
	for i = 1, #dialogs.response.items do
		if dialogs.response.items[i].message.user_id and dialogs.response.items[i].message.user_id > 0 then
			table.insert(usersToGetNames, dialogs.response.items[i].message.user_id)
		end
	end

	local success, usersData = usersInformationRequest(table.unpack(usersToGetNames))
	if success and usersData.response then
		for i = 1, #dialogs.response.items do
			if not dialogs.response.items[i].message.chat_id then
				for j = 1, #usersData.response do
					if usersData.response[j].id == dialogs.response.items[i].message.user_id then
						dialogs.response.items[i].message.title = usersData.response[j].first_name .. " " .. usersData.response[j].last_name
					end
				end
			end
		end
	end

	return dialogs
end

local function drawDialog(y, dialogBackground, avatarID, avatarText, text1, text2, text3)
	--Рисуем подложку под диалог нужного цвета
	buffer.square(mainZoneX, y, mainZoneWidth, 5, dialogBackground)
	--Рисуем аватарку, чо уж
	drawAvatar(mainZoneX + 2, y + 1, avatarID, avatarText)
	--Пишем все, что нужно
	y = y + 1
	if text1 then buffer.text(mainZoneX + 10, y, 0x000000, text1); y = y + 1 end
	if text2 then buffer.text(mainZoneX + 10, y, 0x555555, text2); y = y + 1 end
	if text3 then buffer.text(mainZoneX + 10, y, 0x666666, text3); y = y + 1 end
end

local function dialogsGUI()

	local success, dialogs = getDialogsRequest(dialogToShowFrom - 1, countOfDialogsToLoadFromServer)
	if success and dialogs.response then

		-- saveToFile(serialization.serialize(dialogs))
		
		whatIsOnScreen = "dialogs"

		obj.dialogList = {}

		clearGUIZone()
		drawTopBar("Сообщения")
		buffer.draw()

		--НУ ТЫ ПОНЯЛ, АГА
		status("Получаю имена пользователей по ID")
		dialogs = getUserNamesFromDialogArray(dialogs)

		local y = mainZoneY
		local avatarText = ""
		local peerID
		local color

		for i = 1, #dialogs.response.items do
			--Ебемся с цветами
			if dialogs.response.items[i].unread then
				if i % 2 == 0 then 
					color = 0xCCDBFF
				else
					color = 0xCCDBFF
				end
			else
				if i % 2 == 0 then 
					color = 0xEEEEEE
				else
					color = 0xFFFFFF
				end
			end
			
			--Рисуем пиздюлинку, показывающую кол-во непрочитанных сообщений
			if dialogs.response.items[i].unread and dialogs.response.items[i].unread ~= 0 then
				local cyka = tostring(dialogs.response.items[i].unread)
				local cykaWidth = unicode.len(cyka) + 2
				local cykaX = buffer.screen.width - cykaWidth - 4
				buffer.square(cykaX, y + 2, cykaWidth, 1, ecs.colors.blue)
				buffer.text(cykaX + 1, y + 2, 0xFFFFFF, cyka)
			end

			
			avatarText = unicode.sub(dialogs.response.items[i].message.title, 1, 2)
			peerID = getPeerIDFromMessageArray(dialogs.response.items[i].message)

			--Ебля с текстом диалога
			local text1 = dialogs.response.items[i].message.title
			local text2
			local text3

			--Если это банальное сообщение
			if dialogs.response.items[i].message.body and dialogs.response.items[i].message.body ~= "" then
				text2 = optimizeStringForWrongSymbols(dialogs.response.items[i].message.body)
			end

			--Если есть какие-либо пересланные сообщения, то
			if dialogs.response.items[i].message.fwd_messages then
				text3 = "Пересланные сообщения"
			--Если есть какие-либо вложения, то
			elseif dialogs.response.items[i].message.attachments then
				text3 = getAttachments(dialogs.response.items[i].message)
			end

			--Рисуем диалог
			drawDialog(y, color, peerID, avatarText, text1, text2, text3)

			newObj("dialogList", i, mainZoneX, y, mainZoneX + mainZoneWidth - 1, y + 4, peerID, avatarText, text1, text2, text3)

			y = y + 5
		end
	end

	status("Список диалогов получен")
end

local function audioGUI(ID)
	local success, audios = getAudioRequest(ID, audioToShowFrom - 1, countOfAudioToLoadFromServer)
	if success and audios.response then
		whatIsOnScreen = "audio"

		obj.audio = {}

		clearGUIZone()
		drawTopBar("Аудиозаписи " .. audios.response.items[1].name_gen)

		local y = mainZoneY
		local color
		for i = 2, #audios.response.items do
			color = 0xFFFFFF
			if i % 2 == 0 then color = 0xEEEEEE end

			buffer.square(mainZoneX, y, mainZoneWidth, 5, color)

			buffer.button(mainZoneX + 2, y + 1, 5, 3, colors.audioPlayButton, colors.audioPlayButtonText, "ᐅ")

			newObj("audio", i, mainZoneX + 2, y + 1, mainZoneX + 7, y + 3, audios.response.items[i].url)

			local x = mainZoneX + 9
			buffer.text(x, y + 1, colors.audioPlayButton, audios.response.items[i].artist)
			x = x + unicode.len(audios.response.items[i].artist)
			buffer.text(x, y + 1, 0x000000, " - " .. audios.response.items[i].title)

			x = mainZoneX + 9
			local hours = string.format("%02.f", math.floor(audios.response.items[i].duration / 3600))
			local minutes = string.format("%02.f", math.floor(audios.response.items[i].duration / 60 - (hours * 60)))
			local seconds = string.format("%02.f", math.floor(audios.response.items[i].duration - hours * 3600 - minutes * 60))
			buffer.text(x, y + 2, 0x555555, "Длительность: " .. hours .. ":" .. minutes .. ":" .. seconds)

			y = y + 5
		end
	end
end

--Главное ГУИ с левтбаром и прочим
local function mainGUI()
	--Подложка под элементы
	buffer.square(1, 1, leftBarWidth, buffer.screen.height, colors.leftBar, 0xFFFFFF, " ")
	
	if personalInfo then
		drawPersonalAvatar(3, 2)
		buffer.text(11, 3, 0xFFFFFF, ecs.stringLimit("end", personalInfo.first_name .. " " .. personalInfo.last_name, leftBarWidth - 11))
	end

	--Элементы
	obj.leftBar = {}
	local y, color = 6
	for i = 1, #leftBarElements do
		color = colors.leftBarAlternative
		if i % 2 == 0 then color = colors.leftBar end
		if i == currentLeftBarElement then color = colors.leftBarSelection end

		newObj("leftBar", i, 1, y, leftBarWidth, y + 2)

		buffer.square(1, y, leftBarWidth, 3, color, 0xFFFFFF, " ")
		y = y + 1
		buffer.text(3, y, colors.leftBarText, ecs.stringLimit("end", leftBarElements[i], leftBarWidth - 4))
		y = y + 2
	end

	if leftBarElements[currentLeftBarElement] == "Сообщения" then
		status("Получаю список диалогов")
		messageToShowFrom = 1
		dialogToShowFrom = 1
		dialogsGUI()
	elseif leftBarElements[currentLeftBarElement] == "Аудиозаписи" then
		status("Получаю список аудозаписей")
		audioToShowFrom = 1
		audioGUI(personalInfo.id)
	end

	buffer.draw()
end

---------------------------------------------------- Старт скрипта ----------------------------------------------------------------

--Инициализируем библиотеку двойного буффера
--Эх, что бы я делал, если б не накодил ее? 0.2 фпс на GPU мертвеца!
buffer.start()
--Активируем форму логина
local loginData = loginGUI("cyka@yandex.com", "13131313")
access_token = loginData.access_token
--Получаем персональные данные
_, personalInfo = usersInformationRequest(loginData.user_id)
personalInfo = personalInfo.response[1]

--Активируем главное GUI
clearGUIZone()
mainGUI()

while true do
	local e = {event.pull()}
	if e[1] == "touch" then

		if whatIsOnScreen == "audio" then
			for key in pairs(obj.audio) do
				if clickedAtZone(e[3], e[4], obj.audio[key]) then
					buffer.button(obj.audio[key][1], obj.audio[key][2], 5, 3, 0x66FF80,  colors.audioPlayButton, "ᐅ")
					buffer.draw()
					os.sleep(0.2)
					buffer.button(obj.audio[key][1], obj.audio[key][2], 5, 3, colors.audioPlayButton, colors.audioPlayButtonText, "ᐅ")
					buffer.draw()

					if component.isAvailable("openfm_radio") then
						component.openfm_radio.stop()
						component.openfm_radio.setURL(obj.audio[key][5])
						component.openfm_radio.start()
					else
						ecs.error("Эта функция доступна только при наличии установленного мода OpenFM, добавляющего полноценное интернет-радио")
					end

					break
				end
			end
		end

		if whatIsOnScreen == "dialogs" then
			for key in pairs(obj.dialogList) do
				if clickedAtZone(e[3], e[4], obj.dialogList[key]) then
					drawDialog(obj.dialogList[key][2], 0xFF8888, obj.dialogList[key][5], obj.dialogList[key][6], obj.dialogList[key][7], obj.dialogList[key][8], obj.dialogList[key][9])
					buffer.draw()
					os.sleep(0.2)
					status("Загружаю переписку с пользователем " .. obj.dialogList[key][7])
					currentMessagesPeerID = obj.dialogList[key][5]
					currentMessagesAvatarText = obj.dialogList[key][6]
					currentMessagesFullName = obj.dialogList[key][7]
					messagesGUI()
					break
				end
			end
		end

		if whatIsOnScreen == "messages" then
			if clickedAtZone(e[3], e[4], obj.messageInputBar) then
				drawMessageInputBar(" ")
				buffer.draw()
				local newText = ecs.inputText(obj.messageInputBar[1] + 4, obj.messageInputBar[2] + 2, obj.messageInputBar[3] - obj.messageInputBar[1], "", colors.messageInputBarTextBackgroundColor, colors.messsageInputBarTextColor)
				if newText and newText ~= " " then
					computer.beep(1700)
					status("Отправляю сообщение пользователю")
					sendMessageRequest(currentMessagesPeerID, newText .. " (отправлено с OpenComputers)")
					status("Обновляю историю переписки")
					messageToShowFrom = 1
					messagesGUI()
				end
				drawMessageInputBar(" ")
			end
		end

		for key in pairs(obj.leftBar) do
			if clickedAtZone(e[3], e[4], obj.leftBar[key]) then
				-- ecs.error("Кликнули на лефт бар ээлемент")
				currentLeftBarElement = key
				mainGUI()

				if leftBarElements[currentLeftBarElement] == "Выход" then
					os.sleep(0.3)
					buffer.clear(0x262626)
					ecs.prepareToExit()
					return
				end

				break
			end
		end
	elseif e[1] == "scroll" then
		if e[5] == 1 then
			if whatIsOnScreen == "dialogs" then
				dialogToShowFrom = dialogToShowFrom - dialogScrollSpeed
				if dialogToShowFrom < 1 then dialogToShowFrom = 1 end
				status("Прокручиваю диалоги, отправляю запрос на сервер")
				dialogsGUI()
				buffer.draw()
			elseif whatIsOnScreen == "messages" then
				messageToShowFrom = messageToShowFrom + messagesScrollSpeed
				status("Прокручиваю сообщения, отправляю запрос на сервер")
				messagesGUI()
				buffer.draw()
			elseif whatIsOnScreen == "audio" then
				audioToShowFrom = audioToShowFrom - audioScrollSpeed
				if audioToShowFrom < 1 then audioToShowFrom = 1 end
				status("Прокручиваю аудозаписи, отправляю запрос на сервер")
				audioGUI(personalInfo.id)
				buffer.draw()
			end
		else
			if whatIsOnScreen == "dialogs" then
				dialogToShowFrom = dialogToShowFrom + dialogScrollSpeed
				status("Прокручиваю диалоги, отправляю запрос на сервер")
				dialogsGUI()
				buffer.draw()
			elseif whatIsOnScreen == "messages" then
				messageToShowFrom = messageToShowFrom - messagesScrollSpeed
				if messageToShowFrom < 1 then messageToShowFrom = 1 end
				status("Прокручиваю сообщения, отправляю запрос на сервер")
				messagesGUI()
				buffer.draw()
			elseif whatIsOnScreen == "audio" then
				audioToShowFrom = audioToShowFrom + audioScrollSpeed
				status("Прокручиваю аудозаписи, отправляю запрос на сервер")
				audioGUI(personalInfo.id)
				buffer.draw()
			end
		end
	end
end

-- local success, dialogs = getDialogsRequest(0, 5)
-- saveToFile(serialization.serialize(dialogs))


-- sendMessageRequest(dialogs.response.items[2], "тестовое сообщение, отправлено через OpenComputers VK Client by Игорь, епта")





