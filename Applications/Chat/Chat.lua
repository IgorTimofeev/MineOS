
local event = require("event")
local modemConnection = require("modemConnection")
local ecs = require("ECSAPI")
local buffer = require("doubleBuffering")
local context = require("context")
local image = require("image")
local unicode = require("unicode")
local component = require("component")
local modem = component.modem

-------------------------------------------------------------------------------------------------------------------------------

local colors = {
	leftBar = 0xEEEEEE,
	leftBarSelection = 0x00A8FF,
	leftBarAlternative = 0xDDDDDD,
	leftBarText = 0x262626,
	leftBarSelectionText = 0xFFFFFF,
	topBar = 0xEEEEEE,
	topMenu = 0xFFFFFF,
	chatZone = 0xFFFFFF,
	senderCloudColor = 0x3392FF,
	senderCloudTextColor = 0xFFFFFF,
	yourCloudColor = 0x55BBFF,
	yourCloudTextColor = 0xFFFFFF,
	systemMessageColor = 0x555555,
}

local chatHistory = {
	{
		address = "a3f0af-aef00baef-fae0aef0a",
		name = "Вася Пупкин",
		{
			type = "systemMessage",
			message = "Здесь будет выводиться история переписки"
		},
		{
			fromYou = true,
			message = "Привет! Сука, ты мой дом грифанул? Все, пизда тебе, гнида ебаная, готовь очко. Я еще не подошел просто, держи анус разогретым и растертым вазелином, блядь!"
		},
		{
			fromYou = false,
			message = "Ну здорово! Чо как?"
		},
		{
			fromYou = true,
			message = "Да ниче так, более-менее. Сам как?"
		},
		{
			fromYou = false,
			message = "Да живем потихоньку, дочку вон усыновил"
		},
		{
			fromYou = false,
			message = "Слышь, надо съебаться ща подальше, го анекдот расскажу: С рисованием повторяющихся узоров машины успешно справляются без участия человека — это лишь вопрос правильно составленного алгоритма. Если же добавить в этот процесс элемент непредсказуемости — прерогативу иррациональной человеческой натуры, то рутинная операция превращается в настоящее искусство."
		},
		{
			type = "systemMessage",
			message = "Пользователь покинул чат"
		},
		{
			fromYou = true,
			message = "Обидка!"
		},
		{
			fromYou = true,
			message = "Что за дела, сука?"
		},
		{
			fromYou = false,
			message = ")))"
		},
		{
			fromYou = true,
			message = "Ну ты чо((("
		},
		{
			fromYou = false,
			message = "Героям слава!"
		},
	},
	{
		address = "a3f0af-a14411414f00baef-fae0aef0a",
		name = "Петя Васечкин",
		{
			fromYou = true,
			message = "Сука!"
		},
		{
			fromYou = false,
			message = "Загрифил мою хату, пидорас! Пизда тебе, гнида"
		},
	},
	{
		address = "a3f0af-a14411414f00baef-fae0aef0a",
		name = "Мамка Семена",
		{
			fromYou = false,
			message = "Вчерашняя ночь была прекрасна, ты великолепен!"
		},
		{
			fromYou = true,
			message = ")))"
		},
	},
}

local avatars = {

}

-------------------------------------------------------------------------------------------------------------------------------

local personalAvatarPath = "sampleAvatar.pic"
local chatHistoryPath = "ChatHistory.cfg"
local friendAvatarPath = "FriendAvatar.pic"
local avatarWidthLimit = 6
local avatarHeightLimit = 3

local currentChatID = 1


buffer.start()
local leftBarWidth = math.floor(buffer.screen.width * 0.2)
local chatZoneWidth = buffer.screen.width - leftBarWidth
local heightOfTopBar = 2 + avatarHeightLimit
local yLeftBar = 2 + heightOfTopBar
local chatZoneX = leftBarWidth + 1
local bottom
local chatZoneHeight = buffer.screen.height - yLeftBar + 1
local cloudWidth = chatZoneWidth - 2 * (avatarWidthLimit + 9)
local cloudTextWidth = cloudWidth - 4

-------------------------------------------------------------------------------------------------------------------------------

local function loadAvatarFromFile(path)
	local avatar = 	image.load(personalAvatarPath)
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

local function drawLeftBar()
	buffer.square(1, yLeftBar, leftBarWidth, buffer.screen.height - 1, colors.leftBar, 0xFFFFFF, " ")

	local yPos = yLeftBar
	local counter = 1
	local text, textColor
	
	for i = 1, #chatHistory do
		textColor = colors.leftBarText
	
		if i == currentChatID then
			buffer.square(1, yPos, leftBarWidth, 3, colors.leftBarSelection, 0xFFFFFF, " ")
			textColor = 0xFFFFFF
		elseif counter % 2 ~= 0 then
			buffer.square(1, yPos, leftBarWidth, 3, colors.leftBarAlternative, 0xFFFFFF, " ")
		end

		text = chatHistory[i].name or address
		text = ecs.stringLimit("end", text, leftBarWidth - 4)

		yPos = yPos + 1
		buffer.text(2, yPos, textColor, text)
		
		yPos = yPos + 2
		counter = counter + 1
		if yPos > buffer.screen.height then break end
	end
end

local function drawTopBar()
	buffer.square(1, 2, buffer.screen.width, heightOfTopBar, colors.topBar, 0xFFFFFF, " ")
	buffer.image(3, 3, avatars.personal)
	-- buffer.text(chatZoneX, yLeftBar + avatarHeightLimit + 2, )
end

local function drawTopMenu()
	buffer.drawTopMenu(1, 1, buffer.screen.width, colors.topMenu, 0, {"Чат", 0x000099}, {"Настройки", 0x262626}, {"О программе", 0x262626})
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

local function drawChat(fromMessage)
	local x, y = chatZoneX, yLeftBar
	buffer.square(x, y, chatZoneWidth, chatZoneHeight, colors.chatZone, 0xFFFFFF, " ")

	-- buffer.setDrawLimit()
	-- Стартовая точка
	y = buffer.screen.height - 6
	local xYou, xSender = x + 2, buffer.screen.width - 9
	-- Отрисовка облачков
	local cloudColor, textColor
	for i = fromMessage, 1, -1 do
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
				buffer.image(xYou, y, avatars.personal)
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

	buffer.scrollBar(buffer.screen.width - 1, yLeftBar, 2, chatZoneHeight, #chatHistory[currentChatID], fromMessage, 0xCCCCCC, ecs.colors.blue)
end

local function drawAll()
	drawTopBar()
	drawLeftBar()
	drawTopMenu()
	drawChat(#chatHistory[currentChatID])
	buffer.draw()
end

-------------------------------------------------------------------------------------------------------------------------------

buffer.square(1, 1, buffer.screen.width, buffer.screen.height, 0x262626, 0xFFFFFF, " ")
loadPersonalAvatar()
drawAll()

-------------------------------------------------------------------------------------------------------------------------------






