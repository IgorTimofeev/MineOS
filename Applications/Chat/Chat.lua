
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

	topBar = 0xEEEEEE,
	topMenu = 0xFFFFFF,

	chatZone = 0xFFFFFF,
	senderCloudColor = 0x3392FF,
	senderCloudTextColor = 0xFFFFFF,
	yourCloudColor = 0x55BBFF,
	yourCloudTextColor = 0xFFFFFF,
	systemMessageColor = 0x555555,

	messageInputBarColor = 0xEEEEEE,
	messsageInputBarButtonColor = 0x3392FF,
	messsageInputBarButtonTextColor = 0xFFFFFF,
	messsageInputBarLineColor = 0x000000,
}

local chatHistory = {}
local avatars = {}

-------------------------------------------------------------------------------------------------------------------------------

local personalAvatarPath = "sampleAvatar.pic"
local chatHistoryPath = "ChatHistory.cfg"
local friendAvatarPath = "FriendAvatar.pic"
local avatarWidthLimit = 6
local avatarHeightLimit = 3

local currentChatID = 1
local currentChatMessage = 0

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
local messageInputHeight = 5

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
	file:write(serialization.serialize(chatHistoryPath))
	file:close()
end

local function loadChatHistory()
	if fs.exists(chatHistoryPath) then
		local file = io.open(chatHistoryPath, "r")
		chatHistory = serialization.unserialize(file:read("*a"))
		file:close()
	else
		chatHistory = {}
		saveChatHistory()
	end
end

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

	--Кнопочка поиска юзеров
	obj.search = {buffer.button(1, buffer.screen.height - 2, leftBarWidth, 3, colors.leftBarSearchButton, colors.leftBarSearchButtonText, "Поиск")}
end

local function drawTopBar()
	buffer.square(1, 2, buffer.screen.width, heightOfTopBar, colors.topBar, 0xFFFFFF, " ")

	buffer.image(3, 3, avatars.personal)
	-- buffer.text(chatZoneX, yLeftBar + avatarHeightLimit + 2, )
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

	-- Ставим ограничение отрисовки буфера, чтобы облачка сообщений не ебошили
	-- За края верхней зоны чатзоны, ну ты понял, да?
	buffer.setDrawLimit(x, y, chatZoneWidth, chatZoneHeight)

	--ВОТ ТУТ НАЧИНАЕТСЯ ЕБОЛААААААА
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

	-- Убираем ограничение отроисовки буфера
	buffer.resetDrawLimit()

	buffer.scrollBar(buffer.screen.width - 1, yLeftBar, 2, chatZoneHeight - messageInputHeight, #chatHistory[currentChatID], currentChatMessage, 0xDDDDDD, ecs.colors.blue)
end

local function drawMessageInputBar()
	local x, y = chatZoneX, buffer.screen.height - messageInputHeight + 1
	-- buffer.text(x, y, colors.messsageInputBarLineColor, string.rep("▄", chatZoneWidth - 2))
	buffer.square(x, y, chatZoneWidth, messageInputHeight, colors.messageInputBarColor, 0xFFFFFF, " ")
	y = y + 1
	buffer.frame(x + 2, y, chatZoneWidth - 18, 3, colors.messsageInputBarLineColor)
	buffer.button(buffer.screen.width - 3 - 10, y, 12, 3, colors.messsageInputBarButtonColor, colors.messsageInputBarButtonTextColor, "Отправить")
end

local function drawAll()
	drawTopBar()
	drawLeftBar()
	drawTopMenu()
	drawChat()
	drawMessageInputBar()
	buffer.draw()
end

local function scrollChat(direction)
	if direction == 1 then
		if currentChatMessage > 1 then
			currentChatMessage = currentChatMessage - 1
			drawChat()
			drawMessageInputBar(currentChatMessage)
			buffer.draw()
		end
	else
		if currentChatMessage < #chatHistory[currentChatID] then
			currentChatMessage = currentChatMessage + 1
			drawChat()
			drawMessageInputBar(currentChatMessage)
			buffer.draw()
		end
	end
end

-------------------------------------------------------------------------------------------------------------------------------

-- buffer.square(1, 1, buffer.screen.width, buffer.screen.height, 0x262626, 0xFFFFFF, " ")

loadChatHistory()
loadPersonalAvatar()
currentChatMessage = #chatHistory[currentChatID]

drawAll()

-------------------------------------------------------------------------------------------------------------------------------

while true do
	local e = { event.pull() }
	if e[1] == "touch" then

	elseif e[1] == "scroll" then
		if ecs.clickedAtArea(e[3], e[4], chatZoneX, yLeftBar, chatZoneX + chatZoneWidth - 1, yLeftBar + chatZoneHeight - 1) then
			scrollChat(e[5])
		end
	end
end





