
---------------------------------------------------- Библиотеки ----------------------------------------------------------------

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
local files = require("files")
local GUI = require("GUI")

---------------------------------------------------- Константы ----------------------------------------------------------------

local VKAPIVersion = "5.52"

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

	statusBar = 0x1b1b1b,
	statusBarText = 0xAAAAAA,

	audioPlayButton = 0x002440,
	audioPlayButtonText = 0xFFFFFF,

	messageInputBarColor = 0xEEEEEE,
	messageInputBarTextBackgroundColor = 0xFFFFFF,
	messsageInputBarTextColor = 0x262626,
}

local leftBarHeight = buffer.screen.height - 9
local leftBarWidth = math.floor(buffer.screen.width * 0.20)

local topBarHeight = 3

local mainZoneWidth = buffer.screen.width - leftBarWidth
local mainZoneHeight = buffer.screen.height - topBarHeight - 1
local mainZoneX = leftBarWidth + 1
local mainZoneY = topBarHeight + 1

local cloudWidth = math.floor(mainZoneWidth * 0.7)

-------------------------------------------------------------------------------------------------------------------------------

local settingsPath = "MineOS/System/VK/Settings.cfg"
local VKLogoImagePath = "MineOS/Applications/VK.app/Resources/VKLogo.pic"
-- local leftBarElements = {"Новости", "Друзья", "Сообщения", "Настройки", "Выход"}
local leftBarElements = { "Моя страница", "Друзья", "Сообщения", "Аудиозаписи", "Новости", "Настройки", "Выход" }
local currentLeftBarElement = 3
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
local profileScrollSpeed = 2
local friendsScrollSpeed = 5

local countOfFriendsToGetOnFriendsTab = 12
local currentFriendsOffset = 0
local currentFriends = {}

local countOfFriendsToDisplayInProfile = 16
local currentProfileY = mainZoneY + 2

local currentMessagesPeerID, currentMessagesAvatarText
local dialogPreviewTextLimit = mainZoneWidth - 15
local currentProfile

local settings = {saveAuthData = false, addSendingInfo = true}

local vip = {
	[7799889] = {avatarColor = 0x000000, avatarTextColor = 0xCCCCCC, avatarBottomText = "DEV", avatarBottomTextColor = 0x1b1b1b},
	[113499693] = {avatarColor = 0xFF99CC, avatarTextColor = 0x000000, avatarBottomText = "DEV", avatarBottomTextColor = 0xff6dbf},
	[60991376] = {avatarColor = 0xEEEEEE, avatarTextColor = 0x000000, avatarBottomText = "DEV", avatarBottomTextColor = 0x555555},
}

local messageEndAdderText = " (отправлено с MineOS VKClient)"

local news
local currentNews = 1
local countOfNewsToShow = 10
local countOfNewsToGet = 20

---------------------------------------------------- Веб-часть ----------------------------------------------------------------

local function loadSettings()
	if fs.exists(settingsPath) then settings = files.loadTableFromFile(settingsPath) end
end

local function saveSettings()
	files.saveTableToFile(settingsPath, settings)
end

--Объекты
local obj = {}
local function newObj(class, name, ...)
	obj[class] = obj[class] or {}
	obj[class][name] = {...}
end

--Дебаг-функция на сохранение говна в файл, МАЛО ЛИ ЧО
local function saveToFile(filename, stro4ka)
	local file = io.open(filename, "w")
	file:write(stro4ka)
	file:close()
end

--Банальный URL-запрос, декодирующийся через ЖУСОН в случае успеха, епты
local function request(url)
	local success, response = ecs.internetRequest(url)
	if success then response = json:decode(response) end
	return success, response
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
	return VKAPIRequest("users.get", "user_ids=" .. table.concat({...}, ","), "fields=contacts,education,site,city,bdate,online,status,last_seen,quotes,about,games,books,counters,relatives,connections,blacklisted,activities,interests,music,movies,tv")
end

local function userFriendsRequest(ID, count, offset, order, nameCase)
	return VKAPIRequest("friends.get", "user_id=" .. ID, "count=" .. count, "offset=" .. offset, "order=" .. order, "name_case=" .. nameCase, "fields=domain,online,last_seen")
end

local function userFriendsListsRequest(ID) 
	return VKAPIRequest("friends.getLists", "user_id=" .. ID, "return_system=1")
end

local function userWallRequest(ID, count, offset)
	return VKAPIRequest("wall.get", "owner_id=" .. ID, "count=" .. count, "offset=" .. offset)
end

local function setCurrentAudioPlaying(ownerID, audioID)
	return VKAPIRequest("audio.setBroadcast", "audio=" .. ownerID .. "_" .. audioID)
end

local function newsRequest(count)
	return VKAPIRequest("newsfeed.get", "filters=post", "return_banned=1", "max_photos=0", "count=" .. count, "fields=name,first_name,last_name")
end

local function setCrazyTypingRequest(peer_id)
	return VKAPIRequest("messages.setActivity", "type=typing", "peer_id=" .. peer_id)
end





---------------------------------------------------- GUI-часть ----------------------------------------------------------------

local function createAvatarHashColor(hash)
	return math.abs(hash % 0xFFFFFF)
end

local function drawAvatar(x, y, width, height, user_id, text)
	local avatarColor = createAvatarHashColor(user_id)
	local textColor = avatarColor > 8388607 and 0x000000 or 0xFFFFFF

	--Хочу себе персональную авку, а то че за хуйня?
	if vip[user_id] then
		avatarColor = vip[user_id].avatarColor
		textColor = vip[user_id].avatarTextColor
	end

	buffer.square(x, y, width, height, avatarColor, textColor, " ")
	buffer.text(x + math.floor(width / 2) - math.floor(unicode.len(text) / 2), y + math.floor(height / 2), textColor, unicode.upper(text))

	if vip[user_id] and vip[user_id].avatarBottomText then buffer.text(x + math.floor(width / 2) - math.floor(unicode.len(text) / 2), y + height - 1, vip[user_id].avatarBottomTextColor, vip[user_id].avatarBottomText) end
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
	local x, y = math.floor(buffer.screen.width / 2 - textFieldWidth / 2), math.floor(buffer.screen.height / 2)

	local obj = {}
	obj.username = {x, y, x + textFieldWidth - 1, y + 2}; y = y + textFieldHeight + 1
	obj.password = {x, y, x + textFieldWidth - 1, y + 2}; y = y + textFieldHeight + 1
	obj.button = GUI.button(x, y, textFieldWidth, textFieldHeight, buttonColor, 0xFFFFFF, 0xFFFFFF, buttonColor, "Войти")

	local VKLogoImage = image.load(VKLogoImagePath)

	local function draw()
		buffer.clear(colors.loginGUIBackground)

		buffer.image(x + 5, obj.username[2] - 15, VKLogoImage)

		buffer.square(x, obj.username[2], textFieldWidth, 3, 0xFFFFFF, 0x000000, " ")
		buffer.square(x, obj.password[2], textFieldWidth, 3, 0xFFFFFF, 0x000000, " ")
		buffer.text(x + 1, obj.username[2] + 1, textColor, ecs.stringLimit("end", username, textFieldWidth - 2))
		buffer.text(x + 1, obj.password[2] + 1, textColor, ecs.stringLimit("end", string.rep("●", unicode.len(password)), textFieldWidth - 2))

		obj.button:draw()

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
			
			elseif obj.button:isClicked(e[3], e[4]) then
				obj.button:press(0.2)
				draw()
				local success, loginData = getLoginDataRequest(username, password)
				if success then 
					if settings.saveAuthData then settings.username = username; settings.password = password; saveSettings() end
					loginData.username = username
					loginData.password = password
					return loginData
				else
					GUI.error("Ошибка авторизации: " .. tostring(loginData))
				end
			end
		end
	end
end

---------------------------------------------------- GUI для взаимодействия с VK API ----------------------------------------------

local function drawPersonalAvatar(x, y, width, height)
	drawAvatar(x, y, width, height, personalInfo.id, unicode.sub(personalInfo.first_name, 1, 1) .. unicode.sub(personalInfo.last_name, 1, 1))
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
	obj.messageInputBar = GUI.object(x, y, mainZoneWidth - 4, 4)
	buffer.square(x, y, mainZoneWidth, 5, colors.messageInputBarColor)
	buffer.square(x + 2, y + 1, mainZoneWidth - 4, 3, colors.messageInputBarTextBackgroundColor)
	buffer.text(x + 4, y + 2, colors.messsageInputBarTextColor, ecs.stringLimit("start", currentText or "Введите сообщение", mainZoneWidth - 8))
end

local function getUserNamesFromTheirIDs(IDsArray)
	local success, usersData = usersInformationRequest(table.unpack(IDsArray))
	local userNames = {}
	if success and usersData.response then
		for i = 1, #usersData.response do
			userNames[usersData.response[i].id] = {
				first_name = usersData.response[i].first_name,
				last_name = usersData.response[i].last_name,
			}
		end
	end
	return success, userNames
end

local function messagesGUI()

	status("Загружаю историю переписки")
	local success, messages = getMessagesRequest(currentMessagesPeerID, messageToShowFrom - 1, countOfMessagesToLoadFromServer)
	if success and messages.response then

		whatIsOnScreen = "messages"

		if currentMessagesPeerID > 2000000000 then
			status("Загружаю имена пользователей из переписки (актуально для конференций)")

			local IDsArray = {};
			for i = 1, #messages.response.items do table.insert(IDsArray, messages.response.items[i].user_id) end
			local userNamesSuccess, userNames = getUserNamesFromTheirIDs(IDsArray)
			for i = 1, #messages.response.items do 
				messages.response.items[i].first_name = userNames[messages.response.items[i].user_id].first_name or "N/A"
				messages.response.items[i].last_name = userNames[messages.response.items[i].user_id].last_name or "N/A"
			end
			IDsArray = nil
		end

		clearGUIZone()
		drawTopBar("Сообщения")

		-- saveToFile("lastMessagesRequest.json", serialization.serialize(messages))

		buffer.setDrawLimit(mainZoneX, mainZoneY, mainZoneWidth, mainZoneHeight)

		local y = buffer.screen.height - 7
		local xSender = mainZoneX + 2
		local xYou = buffer.screen.width - 7

		for i = 1, #messages.response.items do

			local messageTextArray = {}

			--Если строка пиздатая
			if messages.response.items[i].body ~= "" then table.insert(messageTextArray, optimizeStringForWrongSymbols(messages.response.items[i].body)) end
			if messages.response.items[i].fwd_messages then table.insert(messageTextArray, "Пересланные сообщения") end
			if messages.response.items[i].attachments then table.insert(messageTextArray, getAttachments(messages.response.items[i])) end
			if messages.response.items[i].action == "chat_invite_user" then table.insert(messageTextArray, "Пользователь под ID " .. messages.response.items[i].from_id .. " пригласил в беседу пользователя под ID " .. messages.response.items[i].action_mid) end

			messageTextArray = ecs.stringWrap(messageTextArray, cloudWidth - 4)
			local peerID = getPeerIDFromMessageArray(messages.response.items[i])

			--Делаем дату пиздатой
			-- messages.response.items[i].date = os.date("%d.%m.%y в %X", messages.response.items[i].date)
			messages.response.items[i].date = os.date("%H:%M", messages.response.items[i].date)

			if messages.response.items[i].out == 1 then
				y = drawTextCloud(xYou - cloudWidth - 6, y, colors.yourCloudColor, colors.yourCloudTextColor, true, messageTextArray)
				drawPersonalAvatar(xYou, y, 6, 3)
				buffer.text(xYou - cloudWidth - unicode.len(messages.response.items[i].date) - 8, y + 1, colors.dateTime, messages.response.items[i].date)
			else
				y = drawTextCloud(xSender + 8, y, colors.senderCloudColor, colors.senderCloudTextColor, false, messageTextArray)
				drawAvatar(xSender, y, 6, 3, peerID, messages.response.items[i].first_name and (unicode.sub(messages.response.items[i].first_name, 1, 1) .. unicode.sub(messages.response.items[i].last_name, 1, 1)) or currentMessagesAvatarText)
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

local function drawDialog(y, dialogBackground, avatarID, avatarText, text1, text2, text3)
	--Рисуем подложку под диалог нужного цвета
	buffer.square(mainZoneX, y, mainZoneWidth, 5, dialogBackground)
	--Рисуем аватарку, чо уж
	drawAvatar(mainZoneX + 2, y + 1, 6, 3, avatarID, avatarText)
	--Пишем все, что нужно
	y = y + 1
	if text1 then buffer.text(mainZoneX + 10, y, 0x000000, text1); y = y + 1 end
	if text2 then buffer.text(mainZoneX + 10, y, 0x555555, text2); y = y + 1 end
	if text3 then buffer.text(mainZoneX + 10, y, 0x666666, text3); y = y + 1 end
end

local function dialogsGUI()

	local success, dialogs = getDialogsRequest(dialogToShowFrom - 1, countOfDialogsToLoadFromServer)
	if success and dialogs.response then
		
		whatIsOnScreen = "dialogs"

		obj.dialogList = {}

		clearGUIZone()
		drawTopBar("Сообщения")

		--Ебашим КНОПАЧКИ спама
		obj.crazyTypingButton = GUI.adaptiveButton(mainZoneX + 2, 2, 1, 0, 0xFFFFFF, colors.topBar, 0xAAAAAA, 0x000000, "CrazyTyping")
		-- obj.spamButton = {buffer.adaptiveButton(obj.crazyTypingButton[3] + 2, 2, 1, 0, 0xFFFFFF, colors.topBar, "Спам")}

		--НУ ТЫ ПОНЯЛ, АГА
		status("Получаю имена пользователей по ID")
		local IDsArray = {}
		for i = 1, #dialogs.response.items do
			if not dialogs.response.items[i].message.chat_id and dialogs.response.items[i].message.user_id and dialogs.response.items[i].message.user_id > 0 then
				table.insert(IDsArray, dialogs.response.items[i].message.user_id)
			end
		end
		local userNamesSuccess, userNames = getUserNamesFromTheirIDs(IDsArray)
		for i = 1, #dialogs.response.items do
			if not dialogs.response.items[i].message.chat_id and dialogs.response.items[i].message.user_id and dialogs.response.items[i].message.user_id > 0 then
				dialogs.response.items[i].message.title = userNames[dialogs.response.items[i].message.user_id].first_name or "N/A" .. " " .. userNames[dialogs.response.items[i].message.user_id].last_name or ""
			end
		end

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

			--Рисуем пиздюлинку, показывающую кол-во непрочитанных сообщений
			if dialogs.response.items[i].unread and dialogs.response.items[i].unread ~= 0 then
				local cyka = tostring(dialogs.response.items[i].unread)
				local cykaWidth = unicode.len(cyka) + 2
				local cykaX = buffer.screen.width - cykaWidth - 2
				buffer.square(cykaX, y + 2, cykaWidth, 1, ecs.colors.blue)
				buffer.text(cykaX + 1, y + 2, 0xFFFFFF, cyka)
			end

			obj.dialogList[i] = GUI.object(mainZoneX, y, mainZoneWidth, 5)
			obj.dialogList[i][5], obj.dialogList[i][6], obj.dialogList[i][7], obj.dialogList[i][8], obj.dialogList[i][9] = peerID, avatarText, text1, text2, text3

			y = y + 5
		end
	end

	status("Список диалогов получен")
end

--Гуишка аудиозаписей
--А-А-А-А!!!!! МОЙ КРАСИВЫЙ ТРЕУГОЛЬНИЧЕК PLAY, БЛЯДЬ!!!! ШТО ТЫ ДЕЛАЕШЬ, SANGAR, ПРЕКРАТИ!!!!
local function audioGUI(ID)
	status("Загружаю список аудиозаписей")
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
			obj.audio[i] = GUI.button(mainZoneX + 2, y + 1, 5, 3, colors.audioPlayButton, colors.audioPlayButtonText, 0x66FF80, colors.audioPlayButton, ">")
			obj.audio[i][5] = audios.response.items[i]

			local x = mainZoneX + 9
			buffer.text(x, y + 1, colors.audioPlayButton, audios.response.items[i].artist)
			x = x + unicode.len(audios.response.items[i].artist)
			buffer.text(x, y + 1, 0x000000, " - " .. audios.response.items[i].title)

			x = mainZoneX + 9
			local hours = string.format("%02.f", math.floor(audios.response.items[i].duration / 3600))
			local minutes = string.format("%02.f", math.floor(audios.response.items[i].duration / 60 - (hours * 60)))
			local seconds = string.format("%02.f", math.floor(audios.response.items[i].duration - hours * 3600 - minutes * 60))
			buffer.text(x, y + 2, 0x888888, "Длительность: " .. hours .. ":" .. minutes .. ":" .. seconds)

			y = y + 5
		end
	else
		GUI.error("Ошибка при получении списка аудиозаписей")
	end
end

local function checkField(field)
	if field and field ~= "" and field ~= " " then return true end
	return false
end

local function userProfileRequest()
	--Ебашим основную инфу
	status("Загружаю информацию о пользователе под ID " .. currentProfile.ID)
	local profileSuccess, userProfile = usersInformationRequest(currentProfile.ID)
	
	--Ебашим стену
	status("Загружаю содержимое стены пользователя " .. currentProfile.ID)
	local wallSuccess, wall = userWallRequest(currentProfile.ID, 20, currentProfile.wallOffset)
	--Получаем инфу о юзверях со стены
	local userNamesSuccess, userNames
	if wallSuccess and wall.response then
		local IDsArray = {}
		for i = 1, #wall.response.items do table.insert(IDsArray, wall.response.items[i].from_id) end
		status("Загружаю имена людей, оставивших сообщения на стене пользователя " .. currentProfile.ID)
		userNamesSuccess, userNames = getUserNamesFromTheirIDs(IDsArray)
		IDsArray = nil
	end

	--Ебашим френдсов
	status("Загружаю информацию о друзьях пользователя под ID " .. currentProfile.ID)
	local friendsSuccess, friends = userFriendsRequest(currentProfile.ID, countOfFriendsToDisplayInProfile, 0, "random", "nom")

	--Анализируем на пиздатость
	if (profileSuccess and userProfile.response) and (wallSuccess and wall.response) and (userNamesSuccess) and (friendsSuccess and friends.response) then
		-- saveToFile("lastUserProfileRequest.json", serialization.serialize(userProfile))
		currentProfile.userProfile = userProfile
		currentProfile.wall = wall
		currentProfile.userNames = userNames
		currentProfile.friends = friends
		return true
	else
		GUI.error("Ошибка при загрузке информации о профиле")
		return false
	end
end

local function userProfileGUI()
	clearGUIZone()
	whatIsOnScreen = "userProfile"
	drawTopBar("Страница пользователя " .. currentProfile.ID)

	buffer.setDrawLimit(mainZoneX, mainZoneY, mainZoneWidth, mainZoneHeight)

	local xAvatar, yAvatar = mainZoneX + 4, currentProfileY
	local x, y = xAvatar, yAvatar
	local avatarWidth = 18
	local avatarHeight = math.floor(avatarWidth / 2)

	--Рисуем авку
	currentProfile.avatarText =  unicode.sub(currentProfile.userProfile.response[1].first_name, 1, 1) .. unicode.sub(currentProfile.userProfile.response[1].last_name, 1, 1)
	drawAvatar(x, y, avatarWidth, avatarHeight, currentProfile.ID, currentProfile.avatarText)
	--Рисуем имячко и статус
	x = x + avatarWidth + 4
	buffer.text(x, y, 0x000000, currentProfile.userProfile.response[1].first_name .. " " .. currentProfile.userProfile.response[1].last_name); y = y + 1
	buffer.text(x, y, 0xAAAAAA, currentProfile.userProfile.response[1].status); y = y + 2

	--Инфааааа
	local informationOffset = 20
	local informationKeyColor = 0x888888
	local informationTitleColor = 0x000000
	local informationValueColor = 0x002440
	local informationSeparatorColor = 0xCCCCCC

	local function drawInfo(x, y2, key, value)
		if checkField(value) then
			value = {value}
			value = ecs.stringWrap(value, buffer.screen.width - x - 4 - informationOffset)
			buffer.text(x, y2, informationKeyColor, key)
			for i = 1, #value do
				buffer.text(x + informationOffset, y2, informationValueColor, value[i])
				y2 = y2 + 1
			end
			y = y2
		end
	end

	local function drawSeparator(x, y2, text)
		buffer.text(x, y2, informationTitleColor, text)
		buffer.text(x + unicode.len(text) + 1, y2, informationSeparatorColor, string.rep("─", buffer.screen.width - x - unicode.len(text)))
		y = y + 1
	end

	drawSeparator(x, y, "Основная информация"); y = y + 1

	drawInfo(x, y, "Дата рождения:", currentProfile.userProfile.response[1].bdate)
	if currentProfile.userProfile.response[1].city then drawInfo(x, y, "Город:", currentProfile.userProfile.response[1].city.title) end
	drawInfo(x, y, "Образование:", currentProfile.userProfile.response[1].university_name)
	drawInfo(x, y, "Веб-сайт", currentProfile.userProfile.response[1].site); y = y + 1

	drawSeparator(x, y, "Контактная информация"); y = y + 1

	drawInfo(x, y, "Мобильный телефон:", currentProfile.userProfile.response[1].mobile_phone)
	drawInfo(x, y, "Домашний телефон:", currentProfile.userProfile.response[1].home_phone)
	drawInfo(x, y, "Skype:", currentProfile.userProfile.response[1].skype); y = y + 1

	drawSeparator(x, y, "Личная информация"); y = y + 1

	drawInfo(x, y, "Интересы:", currentProfile.userProfile.response[1].interests)
	drawInfo(x, y, "Деятельность:", currentProfile.userProfile.response[1].activities)
	drawInfo(x, y, "Любимая музыка:", currentProfile.userProfile.response[1].music)
	drawInfo(x, y, "Любимая фильмы:", currentProfile.userProfile.response[1].movies)
	drawInfo(x, y, "Любимая телешоу:", currentProfile.userProfile.response[1].tv)
	drawInfo(x, y, "Любимая книги:", currentProfile.userProfile.response[1].books)
	drawInfo(x, y, "Любимая игры:", currentProfile.userProfile.response[1].games)
	drawInfo(x, y, "О себе:", currentProfile.userProfile.response[1].about)

	-- А ВОТ И СТЕНОЧКА ПОДЪЕХАЛА НА ПРАЗДНИК ДУШИ
	y = y + 1
	buffer.square(x, y, buffer.screen.width - x - 2, 1, 0xCCCCCC); buffer.text(x + 1, y, 0x262626, "Стена"); y = y + 2
	--Перебираем всю стенку
	for i = 1, #currentProfile.wall.response.items do
		--Если это не репост или еще не хуйня какая-то
		if currentProfile.wall.response.items[i].text ~= "" then
			-- GUI.error(userNames)
			drawAvatar(x, y, 6, 3, currentProfile.wall.response.items[i].from_id, unicode.sub(currentProfile.userNames[currentProfile.wall.response.items[i].from_id].first_name, 1, 1) .. unicode.sub(currentProfile.userNames[currentProfile.wall.response.items[i].from_id].last_name, 1, 1))
			buffer.text(x + 8, y, informationValueColor, currentProfile.userNames[currentProfile.wall.response.items[i].from_id].first_name .. " " .. currentProfile.userNames[currentProfile.wall.response.items[i].from_id].last_name)
			local date = os.date("%d.%m.%y в %H:%M", currentProfile.wall.response.items[i].date)
			buffer.text(buffer.screen.width - unicode.len(date) - 2, y, 0xCCCCCC, date)
			y = y + 1
			local text = {currentProfile.wall.response.items[i].text}
			text = ecs.stringWrap(text, buffer.screen.width - x - 10)
			for i = 1, #text do
				buffer.text(x + 8, y, 0x000000, text[i])
				y = y + 1
			end
			y = y + 1
			if #text == 1 then y = y + 1 end
		end
	end

	--ПодАвочная параша
	informationOffset = 13
	x, y = xAvatar, yAvatar
	y = y + avatarHeight + 1

	currentProfile.avatarWidth = avatarWidth
	currentProfile.sendMessageButton = GUI.button(x, y, avatarWidth, 1, 0xCCCCCC, 0x000000, 0x888888, 0x000000,"Сообщение")
	y = y + 2
	currentProfile.audiosButton = GUI.button(x, y, avatarWidth, 1, 0xCCCCCC, 0x000000, 0x888888, 0x000000, "Аудиозаписи")
	y = y + 2

	drawInfo(x, y, "Подписчики: ", currentProfile.userProfile.response[1].counters.followers)
	drawInfo(x, y, "Фотографии: ", currentProfile.userProfile.response[1].counters.photos)
	drawInfo(x, y, "Видеозаписи: ", currentProfile.userProfile.response[1].counters.videos)
	drawInfo(x, y, "Аудиозаписи: ", currentProfile.userProfile.response[1].counters.audios)

	--Друзяшки, ЕПТАААААА, АХАХАХАХАХАХАХАХАХА		
	y = y + 1
	buffer.square(x, y, avatarWidth, 1, 0xCCCCCC); buffer.text(x + 1, y, 0x262626, "Друзья (" .. currentProfile.userProfile.response[1].counters.friends .. ")"); y = y + 2
	local xPos, yPos = x + 1, y
	local count = 1
	for i = 1, #currentProfile.friends.response.items do
		drawAvatar(xPos, yPos, 6, 3, currentProfile.friends.response.items[i].id, unicode.sub(currentProfile.friends.response.items[i].first_name, 1, 1) .. unicode.sub(currentProfile.friends.response.items[i].last_name, 1, 1))
		buffer.text(xPos - 1, yPos + 3, 0x000000, ecs.stringLimit("end", currentProfile.friends.response.items[i].first_name .. " " .. currentProfile.friends.response.items[i].last_name, 8))
		xPos = xPos + 10
		if i % 2 == 0 then xPos = x + 1; yPos = yPos + 5 end
		count = count + 1
		if count > countOfFriendsToDisplayInProfile then break end
	end

	buffer.resetDrawLimit()
end

local function loadAndShowProfile(ID)
	currentProfileY = mainZoneY + 2
	currentProfile = {ID = ID, wallOffset = 0}
	if userProfileRequest() then userProfileGUI(currentProfile.ID) end
end

local function friendsGUI()
	status("Загружаю список друзей")
	local success, friends = userFriendsRequest(personalInfo.id, countOfFriendsToGetOnFriendsTab, currentFriendsOffset, "hints", "nom")
	status("Загружаю список категорий друзей")
	local successLists, friendsLists = userFriendsListsRequest(personalInfo.id)
	if (success and friends.response) and (successLists and friendsLists.response) then
		-- saveToFile("lastFriendsResponse.json", serialization.serialize(friends))
		clearGUIZone()
		currentFriends = {sendMessageButtons = {}, openProfileButtons = {}}
		whatIsOnScreen = "friends"
		drawTopBar("Друзья")
		buffer.setDrawLimit(mainZoneX, mainZoneY, mainZoneWidth, mainZoneHeight)

		local function getListName(listID)
			local name = "N/A"
			for i = 1, #friendsLists.response.items do
				if friendsLists.response.items[i].id == listID then
					name = friendsLists.response.items[i].name
					break
				end
			end
			return name
		end

		local x, y = mainZoneX + 2, mainZoneY
		for i = 1, #friends.response.items do
			--Падложка
			if i % 2 == 0 then buffer.square(mainZoneX, y, mainZoneWidth, 5 + (friends.response.items[i].lists and 1 or 0), 0xEEEEEE) end
			--Юзер
			y = y + 1
			local subbedName = unicode.sub(friends.response.items[i].first_name, 1, 1) .. unicode.sub(friends.response.items[i].last_name, 1, 1)
			drawAvatar(x, y, 6, 3, friends.response.items[i].id, subbedName)
			local text = friends.response.items[i].first_name .. " " .. friends.response.items[i].last_name
			buffer.text(x + 8, y, colors.topBar, text)
			local text2 = friends.response.items[i].last_seen and (", " .. (friends.response.items[i].online == 1 and "онлайн" or "был(а) в сети " .. os.date("%d.%m.%y в %H:%M", friends.response.items[i].last_seen.time))) or " "
			buffer.text(x + 8 + unicode.len(text), y, 0xAAAAAA, text2)

			if friends.response.items[i].lists then
				y = y + 1
				local cykaX = x + 8
				for listID = 1, #friends.response.items[i].lists do
					local listName = getListName(friends.response.items[i].lists[listID])
					local listWidth = unicode.len(listName) + 2
					local listBackColor = math.floor(0xFFFFFF / friends.response.items[i].lists[listID])
					local listTextColor = (listBackColor > 0x7FFFFF and 0x000000 or 0xFFFFFF)
					buffer.square(cykaX, y, listWidth, 1, listBackColor, listTextColor, " ")
					buffer.text(cykaX + 1, y, listTextColor, listName)
					cykaX = cykaX + listWidth + 2
				end
			end

			y = y + 1
			buffer.text(x + 8, y, 0x999999, "Написать сообщение")
			currentFriends.sendMessageButtons[friends.response.items[i].id] = {x + 8, y, x + 18, y, subbedName}
			y = y + 1
			buffer.text(x + 8, y, 0x999999, "Открыть профиль")
			currentFriends.openProfileButtons[friends.response.items[i].id] = {x + 8, y, x + 18, y, subbedName}

			y = y + 2
		end

		buffer.resetDrawLimit()
	else
		GUI.error("Ошибка при получении списка друзей пользователя")
	end
end

local function newsGUI()
	clearGUIZone()
	drawTopBar("Новости")
	whatIsOnScreen = "news"
	buffer.setDrawLimit(mainZoneX, mainZoneY, mainZoneWidth, mainZoneHeight)

	local function getAvatarTextAndNameForNews(source_id)
		local avatarText, name = "N/A", "N/A"
		if source_id < 0 then
			for i = 1, #news.response.groups do
				if news.response.groups[i].id == math.abs(source_id) then
					avatarText = unicode.sub(news.response.groups[i].name, 1, 2)
					name = news.response.groups[i].name
					break
				end
			end
		else
			for i = 1, #news.response.profiles do
				if news.response.profiles[i].id == source_id then
					avatarText = unicode.sub(news.response.profiles[i].first_name, 1, 1) .. unicode.sub(news.response.profiles[i].last_name, 1, 1)
					name = news.response.profiles[i].first_name .. " " .. news.response.profiles[i].last_name
					break
				end
			end
		end
		return avatarText, name
	end

	local x, y = mainZoneX + 2, mainZoneY
	for item = currentNews, currentNews + countOfNewsToShow do
		if news.response.items[item] then
			--Делаем текст пиздатым
			news.response.items[item].text = optimizeStringForWrongSymbols(news.response.items[item].text)
			--Убираем говно из новостей
			if news.response.items[item].text == "" then
				if news.response.items[item].copy_history then
					news.response.items[item].text = "Репост"
				elseif news.response.items[item].attachments then
					 news.response.items[item].text = getAttachments(news.response.items[item])
				end
			end
			--Делаем его еще пизже
			local text = {news.response.items[item].text}; text = ecs.stringWrap(text, buffer.screen.width - x - 10)
			--Получаем инфу нужную
			local avatarText, name = getAvatarTextAndNameForNews(news.response.items[item].source_id)
			--Сместиться потом на стока вот
			local yShift = 5
			if #text > 2 then yShift = yShift + #text - 2 end
			
			--Рисуем авку и название хуйни
			if item % 2 == 0 then buffer.square(mainZoneX, y, mainZoneWidth, yShift, 0xEEEEEE) end
			drawAvatar(x, y + 1, 6, 3, math.abs(news.response.items[item].source_id), avatarText)
			buffer.text(x + 7, y + 1, colors.topBar, name)
			--Рисуем текст
			for line = 1, #text do
				buffer.text(x + 7, y + line + 1, 0x000000, text[line])
			end

			y = y + yShift
		end
	end

	buffer.resetDrawLimit()
end

local function getAndShowNews()
	status("Загружаю список новостей")
	local success, news1 = newsRequest(countOfNewsToGet)
	if success and news1.response then
		news = news1
		currentNews = 1
		newsGUI()
	else
		GUI.error("Ошибка при получении списка новостей")
	end
end

local function drawLeftBar()
	--Подложка под элементы
	buffer.square(1, 1, leftBarWidth, buffer.screen.height, colors.leftBar, 0xFFFFFF, " ")
	
	if personalInfo then
		drawPersonalAvatar(3, 2, 6, 3)
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
end

--Главное ГУИ с левтбаром и прочим
local function mainGUI()
	drawLeftBar()
	--Отображаем гую нужную выбранную
	if leftBarElements[currentLeftBarElement] == "Сообщения" then
		status("Получаю список диалогов")
		messageToShowFrom = 1
		dialogToShowFrom = 1
		dialogsGUI()
	elseif leftBarElements[currentLeftBarElement] == "Аудиозаписи" then
		status("Получаю список аудозаписей")
		audioToShowFrom = 1
		audioGUI(personalInfo.id)
	elseif leftBarElements[currentLeftBarElement] == "Моя страница" then
		loadAndShowProfile(personalInfo.id)
		-- loadAndShowProfile(186860159)
	elseif leftBarElements[currentLeftBarElement] == "Друзья" then
		friendsGUI()
	elseif leftBarElements[currentLeftBarElement] == "Новости" then
		getAndShowNews()
	end

	buffer.draw()
end

local function spam(id)
	while true do
		local randomMessages = {
			"Ты мое золотце",
			"Ты никогда не сделаешь сайт",
			"Ты ничтожество",
			"Твоя жизнь ничего не значит",
			"Ты ничего не добьешься",
			"Ты завалишь экзамены",
			"Ты никому не нужна",
			"Ты не напишешь курсовую",
			"Твое животное помрет завтра",
			"Не добавляй в ЧС!",
			"Передаем привет от Яши и Меня (а кто я?)",
			"Хуй!",
			"Пизда!",
			"Залупа!",
			"Пенис!",
			"Хер!",
			"Давалка!"
		}
		local text = randomMessages[math.random(1, #randomMessages)] .. " (с любовью, отправлено с OpenComputers)"
		sendMessageRequest(tostring(id), text)
		print("Отправляю сообщение: " .. text)
		os.sleep(2)
	end
end


---------------------------------------------------- Старт скрипта ----------------------------------------------------------------

--Инициализируем библиотеку двойного буффера
--Эх, что бы я делал, если б не накодил ее? 0.2 фпс на GPU мертвеца!
buffer.start()
--Хуярим настррррроечки
loadSettings()
--Активируем форму логина
local loginData = loginGUI(settings.username or "E-Mail", settings.password or "password")
access_token = loginData.access_token
--Получаем персональные данные
_, personalInfo = usersInformationRequest(loginData.user_id)
personalInfo = personalInfo.response[1]

-- --Ебемся в попчанский
-- spam(21321257)

--Активируем главное GUI
clearGUIZone()
mainGUI()

while true do
	local e = {event.pull()}
	if e[1] == "touch" then

		if whatIsOnScreen == "audio" then
			for key in pairs(obj.audio) do
				if obj.audio[key]:isClicked(e[3], e[4]) then
					obj.audio[key]:press(0.2)

					if component.isAvailable("openfm_radio") then
						component.openfm_radio.stop()
						component.openfm_radio.setURL(obj.audio[key][5].url)
						component.openfm_radio.start()
						status("Вывожу в статус играемую музыку")
						setCurrentAudioPlaying(currentProfile and currentProfile.ID or personalInfo.id, obj.audio[key][5].id)
					else
						GUI.error("Эта функция доступна только при наличии установленного мода OpenFM, добавляющего полноценное интернет-радио")
					end

					break
				end
			end
		end

		if whatIsOnScreen == "dialogs" then
			for key in pairs(obj.dialogList) do
				if obj.dialogList[key]:isClicked(e[3], e[4]) then
					drawDialog(obj.dialogList[key].y, 0xFF8888, obj.dialogList[key][5], obj.dialogList[key][6], obj.dialogList[key][7], obj.dialogList[key][8], obj.dialogList[key][9])
					buffer.draw()
					os.sleep(0.2)
					status("Загружаю переписку с пользователем " .. obj.dialogList[key][7])
					currentMessagesPeerID = obj.dialogList[key][5]
					currentMessagesAvatarText = obj.dialogList[key][6]
					messagesGUI()
					break
				end
			end

			if obj.crazyTypingButton:isClicked(e[3], e[4]) then
				obj.crazyTypingButton:press(0.2)
				local data = ecs.universalWindow("auto", "auto", 36, 0x262626, true,
					{"EmptyLine"},
					{"CenterText", ecs.colors.orange, "CrazyTyping"},
					{"EmptyLine"},
					{"Slider", 0xFFFFFF, ecs.colors.orange, 1, 15, 5, "Количество диалогов: ", ""},
					{"Slider", 0xFFFFFF, ecs.colors.orange, 1, 100, 5, "Количество запросов: ", ""},
					{"Slider", 0xFFFFFF, ecs.colors.orange, 1, 5000, 500, "Задержка между запросами: ", " мс"},
					{"EmptyLine"},
					{"Button", {ecs.colors.orange, 0xffffff, "OK"}, {0x999999, 0xffffff, "Отмена"}}
				)
				if data[4] == "OK" then
					for i = 1, data[2] do
						local count = 1
						for key in pairs(obj.dialogList) do
							-- GUI.error("Ебашу спам диалогу под пиром: " .. obj.dialogList[key][5])
							ecs.info("auto", "auto", "CrazyTyping", "Запрос: " .. i ..  " из " .. data[2] ..  ", диалог: " .. count .. " из ".. data[1] .. ", peerID: " .. obj.dialogList[key][5])
							setCrazyTypingRequest(obj.dialogList[key][5])
							count = count + 1
							if count > data[1] then break end
							os.sleep(data[3] / 1000)
						end
					end
					buffer.draw(true)
				end
			end
		end

		if whatIsOnScreen == "messages" then
			if obj.messageInputBar:isClicked(e[3], e[4]) then
				drawMessageInputBar(" ")
				buffer.draw()
				local newText = ecs.inputText(obj.messageInputBar.x + 4, obj.messageInputBar.y + 2, obj.messageInputBar.width - 4, "", colors.messageInputBarTextBackgroundColor, colors.messsageInputBarTextColor)
				if newText and newText ~= " " and newText ~= "" then
					computer.beep(1700)
					status("Отправляю сообщение пользователю")
					sendMessageRequest(currentMessagesPeerID, newText .. (settings.addSendingInfo and messageEndAdderText or ""))
					status("Обновляю историю переписки")
					messageToShowFrom = 1
					messagesGUI()
				end
				drawMessageInputBar(" ")
			end
		end

		if whatIsOnScreen == "userProfile" then
			if currentProfile.audiosButton:isClicked(e[3], e[4]) then
				currentProfile.audiosButton:press(0.2)
				audioToShowFrom = 1
				audioGUI(currentProfile.ID)
				buffer.draw()
			elseif currentProfile.sendMessageButton:isClicked(e[3], e[4]) then
				currentProfile.sendMessageButton:press(0.2)
				currentMessagesPeerID = currentProfile.ID
				messageToShowFrom = 1
				currentMessagesAvatarText = currentProfile.avatarText
				messagesGUI()
			end
		end

		if whatIsOnScreen == "friends" then
			for ID in pairs(currentFriends.sendMessageButtons) do
				if clickedAtZone(e[3], e[4], currentFriends.sendMessageButtons[ID]) then
					buffer.text(currentFriends.sendMessageButtons[ID][1], currentFriends.sendMessageButtons[ID][2], 0x000000, "Написать сообщение")
					buffer.draw()
					currentMessagesPeerID = ID
					messageToShowFrom = 1
					currentMessagesAvatarText = currentFriends.sendMessageButtons[ID][5]
					messagesGUI()
					break
				end
			end

			for ID in pairs(currentFriends.openProfileButtons) do
				if clickedAtZone(e[3], e[4], currentFriends.openProfileButtons[ID]) then
					buffer.text(currentFriends.openProfileButtons[ID][1], currentFriends.openProfileButtons[ID][2], 0x000000, "Открыть профиль")
					buffer.draw()
					loadAndShowProfile(ID)
					buffer.draw()
					break
				end
			end
		end

		for key in pairs(obj.leftBar) do
			if clickedAtZone(e[3], e[4], obj.leftBar[key]) then
				-- GUI.error("Кликнули на лефт бар ээлемент")
				local oldLeftBarElement = currentLeftBarElement
				currentLeftBarElement = key

				drawLeftBar()
				buffer.draw()

				if leftBarElements[currentLeftBarElement] == "Выход" then
					os.sleep(0.3)
					buffer.clear(0x262626)
					ecs.prepareToExit()
					return
				elseif leftBarElements[currentLeftBarElement] == "Аудиозаписи" then
					currentProfile = currentProfile or {}
					currentProfile.ID = personalInfo.id
				elseif leftBarElements[currentLeftBarElement] == "Настройки" then
					local data = ecs.universalWindow("auto", "auto", 36, 0x262626, true,
						{"EmptyLine"},
						{"CenterText", ecs.colors.orange, "Настройки"},
						{"EmptyLine"},
						{"Switch", ecs.colors.orange, 0xffffff, 0xFFFFFF, "Сохранять данные авторизации", settings.saveAuthData},
						{"EmptyLine"},
						{"Switch", ecs.colors.orange, 0xffffff, 0xFFFFFF, "Добавлять приписку \"Отправлено с ...\"", settings.addSendingInfo},
						{"EmptyLine"},
						{"CenterText", ecs.colors.orange, "OpenComputers VK Client v4.0"},
						{"EmptyLine"},
						{"CenterText", ecs.colors.white, "Автор: Игорь Тимофеев, vk.com/id7799889"},
						{"CenterText", ecs.colors.white, "Все права защищены, епта! Попробуй только спиздить!"},
						{"EmptyLine"},
						{"Button", {ecs.colors.orange, 0xffffff, "OK"}, {0x999999, 0xffffff, "Отмена"}}
					)
					if data[3] == "OK" then
						settings.saveAuthData = data[1]
						settings.addSendingInfo = data[2]

						if settings.saveAuthData then
							settings.username = loginData.username
							settings.password = loginData.password
						else
							settings.username = nil
							settings.password = nil
						end
						saveSettings()

						currentLeftBarElement = oldLeftBarElement
					end
				end

				mainGUI()
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
				audioGUI(currentProfile and currentProfile.ID or personalInfo.id)
				buffer.draw()
			elseif whatIsOnScreen == "userProfile" then
				currentProfileY = currentProfileY + profileScrollSpeed
				if currentProfileY > mainZoneY + 2 then currentProfileY = mainZoneY + 2 end
				userProfileGUI()
				buffer.draw()
			elseif whatIsOnScreen == "friends" then
				currentFriendsOffset = currentFriendsOffset - friendsScrollSpeed
				if currentFriendsOffset < 0 then currentFriendsOffset = 0 end
				friendsGUI()
				buffer.draw()
			elseif whatIsOnScreen == "news" then
				currentNews = currentNews - 1
				if currentNews < 1 then currentNews = 1 end
				newsGUI()
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
				audioGUI(currentProfile and currentProfile.ID or personalInfo.id)
				buffer.draw()
			elseif whatIsOnScreen == "userProfile" then
				currentProfileY = currentProfileY - profileScrollSpeed
				userProfileGUI()
				buffer.draw()
			elseif whatIsOnScreen == "friends" then
				currentFriendsOffset = currentFriendsOffset + friendsScrollSpeed
				friendsGUI()
				buffer.draw()
			elseif whatIsOnScreen == "news" then
				currentNews = currentNews + 1
				newsGUI()
				buffer.draw()
			end
		end
	end
end

-- local success, dialogs = getDialogsRequest(0, 5)
-- saveToFile(serialization.serialize(dialogs))


-- sendMessageRequest(dialogs.response.items[2], "тестовое сообщение, отправлено через OpenComputers VK Client by Игорь, епта")





