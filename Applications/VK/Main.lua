local computer = require("computer")
local component = require("component")
local GUI = require("GUI")
local buffer = require("doubleBuffering")
local fs = require("filesystem")
local color = require("color")
local image = require("image")
local web = require("web")
local json = require("json")
local color = require("color")
local unicode = require("unicode")
local MineOSInterface = require("MineOSInterface")
local MineOSPaths = require("MineOSPaths")
local MineOSCore = require("MineOSCore")

--------------------------------------------------------------------------------

local VKAPIVersion = 5.85

local config = {
	avatars = {
		[7799889] = 0x2D2D2D,
	},
	conversationsLoadCount = 10,
	messagesLoadCount = 10,
}

local configPath = MineOSPaths.applicationData .. "VK/Config.cfg"
if fs.exists(configPath) then
	config = table.fromFile(configPath)
end

local function saveConfig()
	table.toFile(configPath, config)
end

local scriptDirectory = MineOSCore.getCurrentScriptDirectory()
local localization = MineOSCore.getLocalization(scriptDirectory .. "Localizations/")
-- local icons = {}
-- for file in fs.list(scriptDirectory .. "Icons/") do
-- 	icons[file]
-- end

--------------------------------------------------------------------------------

local mainContainer, window = MineOSInterface.addWindow(GUI.filledWindow(1, 1, 100, 26, 0xF0F0F0))

local leftPanel = window:addChild(GUI.panel(1, 1, 1, 1, 0x2D2D2D))
local leftLayout = window:addChild(GUI.layout(1, 3, 1, 1, 1, 1))
leftLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_TOP)
leftLayout:setSpacing(1, 1, 1)
leftLayout:setMargin(1, 1, 0, 1)

local progressIndicator = window:addChild(GUI.progressIndicator(1, 1, 0x1E1E1E, 0x00B640, 0x99FF80))

local contentContainer = window:addChild(GUI.container(1, 1, 1, 1))

local loginContainer = window:addChild(GUI.container(1, 1, 1, 1))
local loginPanel = loginContainer:addChild(GUI.panel(1, 1, loginContainer.width, loginContainer.height, 0xF0F0F0))
local loginLayout = loginContainer:addChild(GUI.layout(1, 1, loginContainer.width, loginContainer.height, 1, 1))
local loginLogo = loginLayout:addChild(GUI.image(1, 1, image.load(scriptDirectory .. "Icon.pic")))
loginLogo.height = loginLogo.height + 1
local loginUsernameInput = loginLayout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x787878, 0xA5A5A5, 0xE1E1E1, 0x3C3C3C, config.username or "", localization.username))
local loginPasswordInput = loginLayout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x787878, 0xA5A5A5, 0xE1E1E1, 0x3C3C3C, config.password or "", localization.password, true, "•"))
local loginButton = loginLayout:addChild(GUI.button(1, 1, 36, 3, 0xD2D2D2, 0x2D2D2D, 0x2D2D2D, 0xE1E1E1, localization.login))
loginButton.colors.disabled = {
	background = 0xB4B4B4,
	text = 0x969696,
}
local loginSaveSwitch = loginLayout:addChild(GUI.switchAndLabel(1, 1, 36, 6, 0x66DB80, 0xD2D2D2, 0xFFFFFF, 0xB4B4B4, localization.saveLogin, true)).switch
local loginInvalidLabel = loginLayout:addChild(GUI.label(1, 1, 36, 1, 0xFF4940, localization.invalidPassword))
loginInvalidLabel.hidden = true

local function request(url, postData)
	progressIndicator.active = true
	mainContainer:drawOnScreen()

	local file = io.open("/urlLog.lua", "a")
	file:write(url)
	file:close()

	local data = ""
	local success, reason = web.rawRequest(
		url,
		postData,
		{
			["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:42.0) Gecko/20100101 Firefox/42.0"
		},
		function(chunk)
			data = data .. chunk

			progressIndicator:roll()
			mainContainer:drawOnScreen()
		end,
		math.huge
	)

	progressIndicator.active = false
	mainContainer:drawOnScreen()

	if success then
		return json:decode(data)
	else
		GUI.alert("Failed to perform web request: " .. tostring(reason))
	end
end

local function responseRequest(...)
	local result = request(...)
	if result then
		if result.response then
			return result.response
		else
			GUI.alert("API request was successfult, but response field is missing")
		end
	end
end

local function methodRequest(method, ...)
	return responseRequest("https://api.vk.com/method/" .. method .. "?" .. table.concat({...}, "&") .. "&access_token=" .. config.accessToken .. "&v=" .. VKAPIVersion)
end

local function truncateEmoji(text)
	text = text:gsub("&#%d+;", ":)")
	return text
end

local function drawSelection(object, backgroundColor, textColor)
	buffer.drawText(object.x, object.y - 1, backgroundColor, string.rep("⣤", object.width - 1) .. "⣴")
	buffer.drawText(object.x, object.y + object.height, backgroundColor, string.rep("⠛", object.width - 1) .. "⠻")
	buffer.drawRectangle(object.x, object.y, object.width, object.height, backgroundColor, textColor, " ")
end

local function selectableSelect(object)
	for i = 1, #object.parent.children do
		object.parent.children[i].selected = object.parent.children[i] == object
	end

	mainContainer:drawOnScreen()

	if object.onTouch then
		object.onTouch()
	end
end

local function selectableEventHandler(mainContainer, object, e1)
	if e1 == "touch" then
		object:select()
	end
end

local function addSelectable(layout, height)
	local object = layout:addChild(GUI.object(1, 1, layout.width, height))
	
	object.eventHandler = selectableEventHandler
	object.selected = false
	object.select = selectableSelect

	return object
end

local function pizdaDraw(object)
	local textColor = 0xE1E1E1
	if object.selected then
		textColor = 0x2D2D2D
		drawSelection(object, 0xF0F0F0, textColor)
	end

	buffer.drawText(object.x + 2, math.floor(object.y + object.height / 2), textColor, object.name)
end

local maxPizdaLength = 0
local function addPizda(name)
	local object = addSelectable(leftLayout, 1)
	
	object.draw = pizdaDraw
	object.name = name
	maxPizdaLength = math.max(maxPizdaLength, unicode.len(name))

	return object
end

local function getAbbreviatedFileSize(size, decimalPlaces)
	if size < 1024 then
		return math.roundToDecimalPlaces(size, 2) .. " B"
	else
		local power = math.floor(math.log(size, 1024))
		return math.roundToDecimalPlaces(size / 1024 ^ power, decimalPlaces) .. " " .. ({"KB", "MB", "GB", "TB"})[power]
	end
end

local function capitalize(text)
	return unicode.upper(unicode.sub(text, 1, 1)) .. unicode.sub(text, 2, -1)
end

local function isPeerChat(id)
	return id > 2000000000
end

local function isPeerGroup(id)
	return id < 0
end

local function getEblo(where, id)
	for i = 1, #where do
		if where[i].id == id then
			return where[i]
		end
	end
end

local function getSenderName(profiles, conversations, groups, peerID)
	if isPeerChat(peerID) then
		return conversations.chat_settings.title
	elseif isPeerGroup(peerID) then
		return getEblo(groups, -peerID).name
	else
		local eblo = getEblo(profiles, peerID)
		return eblo.first_name .. " " .. eblo.last_name
	end
end

local function getNameShortcut(name)
	local first, second = name:match("([^%s]+)%s(.+)")
	if first and second then
		return unicode.upper(unicode.sub(first, 1, 1) .. unicode.sub(second, 1, 1))
	else
		return unicode.upper(unicode.sub(name, 1, 2))
	end
end

local function getAvatarColors(peerID)
	config.avatars[peerID] = config.avatars[peerID] or color.HSBToInteger(math.random(360), 1, 1)
	local r, g, b = color.integerToRGB(config.avatars[peerID])

	return config.avatars[peerID], (r + g + b) / 3 > 127 and 0x0 or 0xFFFFFF
end

local function avatarDraw(object)
	buffer.drawRectangle(object.x, object.y, object.width, object.height, object.backgroundColor, object.textColor, " ")
	buffer.drawText(math.floor(object.x + object.width / 2 - unicode.len(object.shortcut) / 2), math.floor(object.y + object.height / 2 - 1), object.textColor, object.shortcut)
end

local function newAvatar(x, y, width, height, name, peerID)
	local object = GUI.object(x, y, width, height)
	object.backgroundColor, object.textColor = getAvatarColors(peerID)
	object.draw = avatarDraw
	object.shortcut = getNameShortcut(name)

	return object
end

local function separatorDraw(object)
	for i = 1, object.height do
		buffer.drawText(object.x, object.y + i - 1, 0xE1E1E1, "│")
	end
end

local function newSeparator(x, y, height)
	local object = GUI.object(x, y, 1, height)
	object.draw = separatorDraw

	return object
end

local function attachmentDraw(object)
	-- buffer.drawRectangle(object.x, object.y, object.width, 1, 0x880000, 0xA5A5A5, " ")
	local x, y, typeLength = object.x, object.y, unicode.len(object.type)
	-- Type
	buffer.drawText(x, y, 0xF0F0F0, "⠰"); x = x + 1
	buffer.drawRectangle(x, y, typeLength + 2, 1, 0xF0F0F0, 0xA5A5A5, " "); x = x + 1
	buffer.drawText(x, y, 0xA5A5A5, object.type); x = x + typeLength + 1
	buffer.set(x, y, 0xE1E1E1, 0xF0F0F0, "⠆"); x = x + 1
	-- Text
	buffer.drawRectangle(x, y, object.width - typeLength - 5, 1, 0xE1E1E1, 0xA5A5A5, " "); x = x + 1
	buffer.drawText(x, y, 0x787878, string.limit(object.text, object.width - typeLength - 7))
	buffer.drawText(object.x + object.width - 1, y, 0xE1E1E1, "⠆")
end

local function newAttachment(x, y, maxWidth, attachment)
	local object = GUI.object(x, y, 1, 1)

	object.type = capitalize(localization.attachmentsTypes[attachment.type])

	if attachment.photo then
		object.text = attachment.photo.sizes[#attachment.photo.sizes].url
	elseif attachment.video then
		object.text = attachment.video.title
	elseif attachment.audio then
		object.text = attachment.audio.artist .. " - " .. attachment.audio.title
	elseif attachment.sticker then
		object.text = ":)"
	elseif attachment.link then
		object.text = #attachment.link.title > 0 and attachment.link.title or attachment.link.url
	elseif attachment.doc then
		object.text = attachment.doc.title .. ", " .. getAbbreviatedFileSize(attachment.doc.size)
	elseif attachment.audio_message then
		local length = 30

		local values, trigger, value, counter, stepper, maxValue = {}, #attachment.audio_message.waveform / length, 0, 0, 0, 0
		for i = 1, #attachment.audio_message.waveform do
			value = value + attachment.audio_message.waveform[i]

			if stepper > trigger then
				table.insert(values, value / counter)
				maxValue = math.max(maxValue, values[#values])
				
				value, counter, stepper = 0, 0, stepper - trigger
			else
				counter, stepper = counter + 1, stepper + 1
			end
		end

		local pixels = {"⡀", "⡄", "⡆", "⡇"}

		object.text = ""
		for i = 1, #values do
			object.text = object.text .. (pixels[math.ceil(values[i] / maxValue * 4)] or "⡀")
		end
	else
		object.text = "N/A"
	end

	object.width = math.min(maxWidth, unicode.len(object.type) + unicode.len(object.text) + 7)

	object.draw = attachmentDraw
	object.eventHandler = attachmentEventHandler

	return object
end

local function getHistory(container, peerID)
	local result = methodRequest("messages.getHistory", "offset=0", "count=" .. config.messagesLoadCount, "peer_id=" .. peerID, "extended=1", "fields=first_name,last_name,online")
	if result then
		container:removeChildren()

		local input = container:addChild(GUI.input(1, container.height - 2, container.width, 3, 0xE1E1E1, 0x787878, 0xA5A5A5, 0xE1E1E1, 0x3C3C3C, "", localization.typeMessageHere))
		local layout = container:addChild(GUI.layout(2, 1, container.width - 2, container.height - input.height, 1, 1))
		layout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_BOTTOM)
		layout:setMargin(1, 1, 0, 1)

		local function newMessage(x, y, width, fwdOffset, message)
			local object = GUI.container(x, y, width, 1)
			
			local localX, localY = 1, 1

			local name = getSenderName(result.profiles, result.conversations, result.groups, message.from_id)
			local avatar = object:addChild(newAvatar(localX, localY, 4, 2, getNameShortcut(name), message.from_id))
			localX = localX + avatar.width + 1
			
			object:addChild(GUI.text(localX, localY, 0x3C3C3C, name))
			localY = localY + 1

			if #message.text > 0 then
				local lines = string.wrap(message.text, width - localX)
				object.textBox = object:addChild(GUI.textBox(localX, localY, width - localX, #lines, nil, 0xA5A5A5, lines, 1, 0, 0))
				object.textBox.eventHandler = nil
				localY = localY + object.textBox.height + 1
			else
				localY = localY + 1
			end

			if #message.attachments > 0 then
				for i = 1, #message.attachments do
					local attachment = message.attachments[i]
					if localization.attachmentsTypes[attachment.type] then
						local attachment = object:addChild(newAttachment(localX, localY, object.width - localX, message.attachments[i]))
						localY = localY + 2
					end
				end
			end

			if message.fwd_messages then
				object.fwdMessages = {}

				for i = 1, #message.fwd_messages do
					object.fwdMessages[i] = object:addChild(newMessage(fwdOffset + 3, localY, width - 2, 0, message.fwd_messages[i]))
					object:addChild(newSeparator(fwdOffset + 1, localY, object.fwdMessages[i].height))
					localY = localY + object.fwdMessages[i].height + 1
				end
			end

			object.height = localY - 2

			-- object:addChild(GUI.panel(1, 1, width, object.height, 0x0), 1)

			return object
		end

		for i = 1, #result.items do
			local message = layout:addChild(newMessage(2, y, container.width - 2, 5, result.items[i]), 1)
		end

		input.onInputFinished = function()
			if #input.text > 0 then
				local result = methodRequest("messages.send", "peer_id=" .. peerID, "message=" .. web.encode(input.text))
				if result then
					getHistory(container, peerID)
				end
			end
		end

		mainContainer:drawOnScreen()
	end
end

addPizda(localization.profile)

addPizda(localization.news)

local conversationsSelectable = addPizda(localization.conversations)
conversationsSelectable.onTouch = function()
	local result = methodRequest("messages.getConversations", "offset=0", "count=" .. config.conversationsLoadCount, "filter=all", "extended=1", "fields=first_name,last_name,online,id")
	if result then
		contentContainer:removeChildren()

		local conversationsLayout = contentContainer:addChild(GUI.layout(1, 1, 28, contentContainer.height, 1, 1))
		conversationsLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_TOP)
		conversationsLayout:setSpacing(1, 1, 1)
		conversationsLayout:setMargin(1, 1, 0, 1)

		local conversationPanel = contentContainer:addChild(GUI.panel(conversationsLayout.width + 1, 1, contentContainer.width - conversationsLayout.width, contentContainer.height, 0xFFFFFF))
		local conversationContainer = contentContainer:addChild(GUI.container(conversationPanel.localX, 1, conversationPanel.width, conversationPanel.height))

		local function conversationDraw(object)
			local color1, color2, color3 = 0x3C3C3C, 0x969696, 0xD2D2D2
			if object.selected then
				color1, color2, color3 = 0x3C3C3C, 0x969696, 0xD2D2D2
				drawSelection(object, 0xFFFFFF, color2)
			end

			buffer.drawRectangle(object.x + 1, object.y, 4, 2, object.avatarColor, object.avatarTextColor, " ")
			buffer.drawText(object.x + 2, object.y, object.avatarTextColor, object.shortcut)

			buffer.drawText(object.x + 6, object.y, color1, string.limit(object.name, object.width - 13))
			buffer.drawText(object.x + object.width - 6, object.y, color3, object.date)
			buffer.drawText(object.x + 6, object.y + 1, color2, string.limit(truncateEmoji(object.message), object.width - 7))
		end

		for i = 1, #result.items do
			local item = result.items[i]

			config.avatars[item.conversation.peer.id] = config.avatars[item.conversation.peer.id] or color.HSBToInteger(math.random(360), 1, 1)

			local object = addSelectable(conversationsLayout, 2)
			
			-- Превью текста сообщеньки с вложениями и прочей залупой
			if #item.last_message.text == 0 then
				if #item.last_message.fwd_messages > 0 then
					object.message = localization.fwdMessages .. #item.last_message.fwd_messages
				elseif #item.last_message.attachments > 0 then
					local data = {}
					for i = 1, #item.last_message.attachments do
						if localization.attachmentsTypes[item.last_message.attachments[i].type] then
							data[i] = localization.attachmentsTypes[item.last_message.attachments[i].type] or "N/A"
						end
					end

					object.message = table.concat(data, ", ")
				else
					object.message = item.last_message.text
				end
			else
				object.message = item.last_message.text
			end

			-- Префиксы для отправленных мною, либо же для имен отправителей в конфах
			if item.last_message.out == 1 then
				object.message = localization.you .. object.message
			else
				if isPeerChat(item.conversation.peer.id) then
					local eblo = getEblo(result.profiles, item.last_message.from_id)
					object.message = eblo.first_name .. ": " .. object.message
				end
			end

			object.date = os.date("%H:%M", item.last_message.date)
			object.out = item.last_message.out
			object.avatarColor, object.avatarTextColor = getAvatarColors(item.conversation.peer.id)

			-- Имя отправителя
			object.name = getSenderName(result.profiles, item.conversation, result.groups, item.conversation.peer.id)	

			-- Превьюха имени отправителя для аватарки
			object.shortcut = getNameShortcut(object.name)

			object.draw = conversationDraw

			object.onTouch = function()
				getHistory(conversationContainer, item.conversation.peer.id)
			end
		end


		if #conversationsLayout.children > 0 then
			conversationsLayout.children[1]:select()
		else
			mainContainer:drawOnScreen()
		end

		saveConfig()
	end
end

addPizda(localization.friends)

addPizda(localization.documents)

loginUsernameInput.onInputFinished = function()
	loginButton.disabled = #loginUsernameInput.text == 0 or #loginPasswordInput.text == 0
	mainContainer:drawOnScreen()
end

loginPasswordInput.onInputFinished = loginUsernameInput.onInputFinished

local function login()
	if config.accessToken then
		loginContainer.hidden = true
		conversationsSelectable:select()
	else
		loginUsernameInput.onInputFinished()
	end
end

loginButton.onTouch = function()
	local result, reason = request("https://oauth.vk.com/token?grant_type=password&client_id=3697615&client_secret=AlVXZFMUqyrnABp8ncuU&username=" .. loginUsernameInput.text .. "&password=" .. loginPasswordInput.text .. "&v=" .. VKAPIVersion)
	if result then
		if result.access_token then
			config.accessToken = result.access_token
			config.username = loginSaveSwitch.state and loginUsernameInput.text or nil
			
			login()
		else
			config.accessToken = nil
			loginInvalidLabel.hidden = false

			mainContainer:drawOnScreen()
		end
	end
end

addPizda(localization.settings)

addPizda(localization.exit)

window.onResize = function(width, height)
	loginContainer.width, loginContainer.height = width, height
	loginPanel.width, loginPanel.height = loginContainer.width, loginContainer.height
	loginLayout.width, loginLayout.height = loginContainer.width, loginContainer.height

	leftPanel.width, leftPanel.height = maxPizdaLength + 5, height
	leftLayout.width, leftLayout.height = leftPanel.width, leftPanel.height - 2
	progressIndicator.localX, progressIndicator.localY = math.floor(leftPanel.width / 2 - 1), leftPanel.height - progressIndicator.height + 1

	for i = 1, #leftLayout.children do
		leftLayout.children[i].width = leftLayout.width
	end

	window.backgroundPanel.localX, window.backgroundPanel.width, window.backgroundPanel.height = leftPanel.width + 1, width - leftPanel.width, height
	contentContainer.localX, contentContainer.width, contentContainer.height = window.backgroundPanel.localX, window.backgroundPanel.width, window.backgroundPanel.height
end

window.actionButtons.localX = 3
window.actionButtons:moveToFront()
window:resize(window.width, window.height)

login()
