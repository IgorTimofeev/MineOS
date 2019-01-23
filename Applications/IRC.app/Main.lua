
local screen = require("Screen")
local GUI = require("GUI")
local color = require("Color")
local filesystem = require("Filesystem")
local system = require("System")
local paths = require("Paths")
local system = require("System")
local text = require("Text")
local event = require("Event")
local number = require("Number")

-------------------------------------------------------------------------------

local socketHandle
local socketConnectDelay = 1
local socketReadDelay = 1
local oldUptime = 0

local channelUsersList = {operators = {}, voiced = {}, default = {}}
local channelUsersListUpdatingFinished = true

local userZoneMaxWidth = 26
local chatTimeWidth = 5

local selectedItem

local socketUsername = "Socket "

local systemNames = {
	["NickServ"] = true,
	["ChanServ"] = true,
	["DerpServ"] = true,
	[socketUsername] = true,
}

local colorScheme = {
	noticeMessageSender = 0x0049BF,
	noticeMessageText = 0x0092FF,
	actionMessageSender = 0xCC9200,
	actionMessageText = 0xFFB600,
	myMessageSender = 0x2D2D2D,
	myMessageText = 0x969696,
	otherMessageSender = 0x2D2D2D,
	otherMessageText = 0x696969,
	channelDataMessageSender = 0x696969,
	channelDataMessageText = 0xB4B4B4,
}

local applicationPath = paths.user.applicationData .. "IRC/"
local configPath = applicationPath .. "Config.cfg"
local historyPath = applicationPath .. "History.cfg"

local config = {
	server = "irc.esper.net",
	port = 6667,
	username = "",
	password = "",
	historyLimit = 50,
}

local history = {
	["#cc.ru"] = {},
	["#oc"] = {},
	[socketUsername] = {},
	["NickServ"] = {},
	["ECS"] = {},
}

if filesystem.exists(configPath) then
	config = filesystem.readTable(configPath)
end

if filesystem.exists(historyPath) then
	history = filesystem.readTable(historyPath)
end

-------------------------------------------------------------------------------

local workspace, window = system.addWindow(GUI.filledWindow(1, 1, 110, 27, 0xE1E1E1))

local leftPanel = window:addChild(GUI.panel(1, 1, 21, 1, 0x2D2D2D))
local leftLayout = window:addChild(GUI.layout(1, 4, leftPanel.width, 1, 1, 1))
leftLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_TOP)
leftLayout:setMargin(1, 1, 0, 0)

local channelsText = leftLayout:addChild(GUI.text(1, 1, 0xE1E1E1, "  Channels"))
local channelsList = leftLayout:addChild(GUI.list(1, 1, leftPanel.width, 1, 1, 0, 0x2D2D2D, 0x696969, 0x2D2D2D, 0x696969, 0x3366CC, 0xE1E1E1, false))

local usersText = leftLayout:addChild(GUI.text(1, 1, 0xE1E1E1, "  Users"))
local usersList = leftLayout:addChild(GUI.list(1, 1, leftPanel.width, 1, 1, 0, 0x2D2D2D, 0x696969, 0x2D2D2D, 0x696969, 0x3366CC, 0xE1E1E1, false))

local systemText = leftLayout:addChild(GUI.text(1, 1, 0xE1E1E1, "  System"))
local systemList = leftLayout:addChild(GUI.list(1, 1, leftPanel.width, 1, 1, 0, 0x2D2D2D, 0x696969, 0x2D2D2D, 0x696969, 0x3366CC, 0xE1E1E1, false))

local contactLayout = window:addChild(GUI.layout(1, 1, leftPanel.width, 3, 1, 1))
contactLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
contactLayout:setDirection(1, 1, GUI.DIRECTION_HORIZONTAL)
contactLayout:setSpacing(1, 1, 0)

local contactButtonWidth = 7
local contactAddButton = contactLayout:addChild(GUI.button(1, 1, contactButtonWidth, contactLayout.height, 0x3C3C3C, 0xA5A5A5, 0x878787, 0xB4B4B4, "+"))
local contactRemoveButton = contactLayout:addChild(GUI.button(1, 1, contactButtonWidth, contactLayout.height, 0x4B4B4B, 0xA5A5A5, 0x878787, 0xB4B4B4, "-"))
contactRemoveButton.colors.disabled.background = 0x4B4B4B
contactRemoveButton.colors.disabled.text = 0x696969
local settingsButton = contactLayout:addChild(GUI.button(1, 1, contactButtonWidth, contactLayout.height, 0x3C3C3C, 0xA5A5A5, 0x878787, 0xB4B4B4, "*"))

window.backgroundPanel.width = 18
local rightLayout = window:addChild(GUI.layout(1, 1, window.backgroundPanel.width - 2, 1, 1, 1))
rightLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_TOP)
rightLayout:setMargin(1, 1, 0, 0)
rightLayout:setSpacing(1, 1, 0)

local chat = window:addChild(GUI.object(1, 1, 1, 1))
chat.passScreenEvents = true

local scrollBar = window:addChild(GUI.scrollBar(1, 1, 1, 1, 0xD2D2D2, 0x878787, 1, 1, 1, 1, 1, true))

local chatInputLayout = window:addChild(GUI.layout(1, 1, 1, 3, 1, 1))
chatInputLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_TOP)
chatInputLayout:setDirection(1, 1, GUI.DIRECTION_HORIZONTAL)
chatInputLayout:setSpacing(1, 1, 0)

local chatInput = chatInputLayout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0xA5A5A5, 0xE1E1E1, 0x2D2D2D, "", "Type message here"))
chatInput.historyEnabled = true

local chatComboBox = chatInputLayout:addChild(GUI.comboBox(1, 1, 14, 3, 0xD2D2D2, 0x4B4B4B, 0xD2D2D2, 0x969696))
chatComboBox.dropDownMenu.itemHeight = 1
chatComboBox:addItem("/msg")
chatComboBox:addItem("/me")
chatComboBox:addItem("/notice")
chatComboBox:addItem("/ctcp")
chatComboBox:addItem("/raw")

local backgroundContainer = window:addChild(GUI.container(1, 1, 1, 1))
local backgroundPanel = backgroundContainer:addChild(GUI.panel(1, 1, 1, 1, 0xF0F0F0))
local backgroundLayout = backgroundContainer:addChild(GUI.layout(1, 1, 1, 1, 1, 1))
backgroundLayout.hidden = true

local loginServerLayout = GUI.layout(1, 1, 36, 3, 1, 1)
loginServerLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_TOP)
loginServerLayout:setDirection(1, 1, GUI.DIRECTION_HORIZONTAL)

local loginServerInput = loginServerLayout:addChild(GUI.input(1, 1, 27, 3, 0xE1E1E1, 0x787878, 0xB4B4B4, 0xE1E1E1, 0x2D2D2D, config.server or "", "Server"))
local loginPortInput = loginServerLayout:addChild(GUI.input(1, 1, loginServerLayout.width - loginServerInput.width - 1, 3, 0xE1E1E1, 0x787878, 0xB4B4B4, 0xE1E1E1, 0x2D2D2D, config.port and tostring(config.port) or "", "Port"))

local loginUsernameInput = GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x787878, 0xB4B4B4, 0xE1E1E1, 0x2D2D2D, config.username or "", "Username")
local loginPasswordInput = GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x787878, 0xB4B4B4, 0xE1E1E1, 0x2D2D2D, config.password or "", "Password")
local loginPasswordSwitchAndLabel = GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xB4B4B4, "Log into NickServ:", true)
local loginSubmitButton = GUI.button(1, 1, 36, 3, 0xC3C3C3, 0xFFFFFF, 0x969696, 0xFFFFFF, "Connect")
local loginStatusText = GUI.text(1, 1, 0xA5A5A5, "")

window.actionButtons.localX = 3
window.actionButtons:moveToFront()

local function getProperList(name)
	return systemNames[name] and systemList or name:sub(1, 1) == "#" and channelsList or usersList
end

local function getItemByText(name)
	return getProperList(name):getItem(name)
end

local function saveConfig()
	filesystem.writeTable(configPath, config)
end

local function socketWrite(data)
	local success, result = pcall(socketHandle.write, data .. "\r\n")
	if success then
		return true, result
	else
		return false, result
	end
end

local function sendMessage(target, text, notice, ctcp)
	socketWrite((notice and "NOTICE " or "PRIVMSG ") .. target .. (ctcp and " :\x01" or " :") .. text .. (ctcp and "\x01" or ""))
end

local function status(text)
	local state = text ~= nil
	if text then
		loginStatusText.text = text
		loginStatusText:update()
	end

	loginStatusText.hidden, loginServerLayout.hidden, loginUsernameInput.hidden, loginPasswordSwitchAndLabel.hidden, loginSubmitButton.hidden = not state, state, state, state, state
	loginPasswordInput.hidden = state and true or not loginPasswordSwitchAndLabel.switch.state

	workspace:draw()
end

local function updateLeftLayout()
	local function checkTextAndList(text, list)
		text.hidden = #list.children == 0
		list.hidden = text.hidden
		list.height = #list.children
	end

	checkTextAndList(channelsText, channelsList)
	checkTextAndList(usersText, usersList)
	checkTextAndList(systemText, systemList)
end

local function contactItemDraw(item)
	local background = item.pressed and item.colors.pressed.background or item.colors.default.background
	local foreground = item.pressed and item.colors.pressed.text or item.colors.default.text

	screen.drawRectangle(item.x, item.y, item.width, item.height, background, foreground, " ")

	local y, textLimit = math.floor(item.y + item.height / 2)
	if not item.pressed and item.unreadCount > 0 then
		local tipString = tostring(item.unreadCount)
		local tipWidth = #tipString + 2
		
		screen.drawRectangle(item.x + item.width - tipWidth - 1, y, tipWidth, 1, 0x3C3C3C, 0xE1E1E1, " ")
		screen.drawText(item.x + item.width - tipWidth, y, 0xE1E1E1, tipString)

		textLimit = item.width - 4 - tipWidth
	else
		textLimit = item.width - 4
	end

	screen.drawText(item.x + 2, y, foreground, text.limit(item.text, textLimit, "right"))
end

local function addContactItemToList(name)
	if not history[name] then
		history[name] = {}
	end

	local list = getProperList(name)
	local item = list:addItem(name)

	item.unreadCount = 0
	item.draw = contactItemDraw

	item.onTouch = function()
		if list == channelsList then
			usersList.selectedItem = nil
			systemList.selectedItem = nil
		elseif list == usersList then
			channelsList.selectedItem = nil
			systemList.selectedItem = nil
		else
			channelsList.selectedItem = nil
			usersList.selectedItem = nil
		end

		selectedItem = item
		item.unreadCount = 0
		contactRemoveButton.disabled = systemNames[item.text]
		rightLayout.cells[1][1].verticalMargin = 0

		scrollBar.maximumValue = #history[name]
		scrollBar.value = scrollBar.maximumValue
		
		rightLayout:removeChildren()
		workspace:draw()

		if socketHandle then
			if list == channelsList then
				if item.joined then
					socketWrite("NAMES " .. name)
				else
					item.joined = true
					socketWrite("JOIN " .. name)
				end
			end
		end
	end

	table.sort(list.children, function(a, b) return a.text:lower() < b.text:lower() end)
	updateLeftLayout()

	return item
end

local function addChatMessage(conversationName, text, sender)
	if not history[conversationName] then
		addContactItemToList(conversationName)
	end

	text = text:gsub("[\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0A\x0B\x0C\x0D\x0E\x0F\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1A\x1B\x1C\x1D\x1E\x1F]+", "")
	
	local chars = {}
	for i = 1, unicode.len(text) do
		chars[i] = unicode.sub(text, i, i)
		if unicode.isWide(chars[i]) then
			chars[i] = "?"
		end
	end
	text = table.concat(chars)

	local message = {
		text = text,
		time = os.date("%H:%M", system.getTime()),
		sender = sender
	}

	table.insert(history[conversationName], message)
	if #history[conversationName] > config.historyLimit then
		table.remove(history[conversationName], 1)
	end

	local item = getItemByText(conversationName)
	if item == selectedItem then
		scrollBar.maximumValue = #history[conversationName]
		
		if scrollBar.value == scrollBar.maximumValue - 1 then
			scrollBar.value = scrollBar.maximumValue
		end
	elseif item.unreadCount < config.historyLimit then
		item.unreadCount = item.unreadCount + 1
	end

	return message
end

chat.draw = function()
	screen.drawRectangle(chat.x, chat.y, chat.width, chat.height, 0xF0F0F0, colorScheme.otherMessageText, " ")

	if history[selectedItem.text] and #history[selectedItem.text] > 0 then
		local y, userZoneWidth, messages = chat.y + chat.height - 2, 0, history[selectedItem.text]

		for i = scrollBar.value, 1, -1 do
			userZoneWidth = math.max(userZoneWidth, unicode.len(messages[i].sender or selectedItem.text))
		end
		userZoneWidth = math.min(userZoneWidth + chatTimeWidth + 4, userZoneMaxWidth)

		for i = chat.y, chat.y + chat.height - 1 do
			local index = screen.getIndex(chat.x + userZoneWidth - 1, i)
			local background, foreground, symbol = screen.rawGet(index)

			screen.rawSet(index, background, 0xE1E1E1, "│")
		end
		
		for i = scrollBar.value, 1, -1 do
			if messages[i].newMessages then
				local elda = " New messages "
				local pizda = chat.width - userZoneWidth - 3 - unicode.len(elda)
				local klitor = math.floor(pizda / 2)
				local vagina = pizda - klitor

				screen.drawText(chat.x + userZoneWidth + 1, y, 0xFF9280, string.rep("─", klitor) .. elda .. string.rep("─", vagina))
				y = y - 1
			else
				local wrappedLines = text.wrap(messages[i].text, chat.width - userZoneWidth - 3)

				local senderColor, textColor
				if messages[i].notice then
					senderColor, textColor = colorScheme.noticeMessageSender, colorScheme.noticeMessageText
				elseif messages[i].action then
					senderColor, textColor = colorScheme.actionMessageSender, colorScheme.actionMessageText
				elseif messages[i].channelAction then
					senderColor, textColor = colorScheme.channelDataMessageSender, colorScheme.channelDataMessageText
				elseif messages[i].sender == config.username then
					senderColor, textColor = colorScheme.myMessageSender, colorScheme.myMessageText
				else
					senderColor, textColor = colorScheme.otherMessageSender, colorScheme.otherMessageText
				end

				for j = #wrappedLines, 1, -1 do
					screen.drawText(chat.x + userZoneWidth + 1, y, textColor, wrappedLines[j])

					y = y - 1
					if y < chat.y then
						return
					end
				end

				local sender = messages[i].sender or selectedItem.text
				local limited = text.limit(sender, userZoneWidth - chatTimeWidth - 4, "center")
				screen.drawText(chat.x + userZoneWidth - unicode.len(limited) - 2, y + 1, senderColor, limited)
				screen.drawText(chat.x + 1, y + 1, 0xC3C3C3, messages[i].time)
			end

			y = y - 1
		end
	end
end

local function checkLoginInputs()
	loginSubmitButton.disabled = #loginUsernameInput.text == 0 or #loginServerInput.text == 0 or not loginPortInput.text:match("^%d+$")
end

loginUsernameInput.onInputFinished = function()
	checkLoginInputs()
	workspace:draw()
end

loginPasswordInput.onInputFinished = loginUsernameInput.onInputFinished
loginServerInput.onInputFinished = loginUsernameInput.onInputFinished
loginPortInput.onInputFinished = loginUsernameInput.onInputFinished

local function login()
	backgroundLayout.hidden = false

	backgroundLayout:removeChildren()
	backgroundLayout:addChild(loginServerLayout)
	backgroundLayout:addChild(loginUsernameInput)
	backgroundLayout:addChild(loginPasswordInput)
	backgroundLayout:addChild(loginPasswordSwitchAndLabel)
	backgroundLayout:addChild(loginSubmitButton)
	backgroundLayout:addChild(loginStatusText)

	checkLoginInputs()
	status()
end

chatInput.onInputFinished = function()
	if #chatInput.text > 0 then
		if chatComboBox.selectedItem == 1 then			
			sendMessage(selectedItem.text, chatInput.text)
			addChatMessage(selectedItem.text, chatInput.text, config.username)
		elseif chatComboBox.selectedItem == 2 then			
			sendMessage(selectedItem.text, "ACTION " .. chatInput.text, false, true)
			addChatMessage(selectedItem.text, chatInput.text, config.username, "!").action = true
		elseif chatComboBox.selectedItem == 3 then
			sendMessage(selectedItem.text, chatInput.text, true)
			addChatMessage(selectedItem.text, chatInput.text, config.username, "!").notice = true
		elseif chatComboBox.selectedItem == 3 then
			sendMessage(selectedItem.text, chatInput.text, false, true)
			addChatMessage(selectedItem.text, chatInput.text, config.username, "!").action = true
		else
			socketWrite(chatInput.text)
			addChatMessage(selectedItem.text, chatInput.text, config.username)
		end

		chatInput.text = ""

		workspace:draw()
	end
end

local function addScrollEventHandler(layout)
	local function getTotalHeight(layout)
		local height = 0

		for i = 1, #layout.children do
			height = height + layout.children[i].height + (i < #layout.children and layout.cells[1][1].spacing or 0)
		end

		return height
	end

	layout.eventHandler = function(workspace, layout, e1, e2, e3, e4, e5)
		if e1 == "scroll" then
			if e5 > 0 then
				if layout.cells[1][1].verticalMargin < 0 then
					layout.cells[1][1].verticalMargin = layout.cells[1][1].verticalMargin + 1
					workspace:draw()
				end
			else
				if layout.cells[1][1].verticalMargin > -getTotalHeight(layout) + 1 then
					layout.cells[1][1].verticalMargin = layout.cells[1][1].verticalMargin - 1
					workspace:draw()
				end
			end
		end
	end
end

addScrollEventHandler(leftLayout)
addScrollEventHandler(rightLayout)

local function selectItem(item)
	selectedItem = item
	item.parent.selectedItem = item:indexOf()
	item.onTouch()
end

local function userButtonOnTouch(workspace, object)
	local text = object.text:gsub("^[@+]", "")
	if history[text] then
		selectItem(getItemByText(text))
	else
		selectItem(addContactItemToList(text))
	end
end

local function updateUsersLayoutFromList()
	local function addCategory(field, name)
		if #channelUsersList[field] > 0 then
			rightLayout:addChild(GUI.object(1, 1, 1, 1))
			rightLayout:addChild(GUI.text(1, 1, 0x5A5A5A, name)).height = 2

			table.sort(channelUsersList[field], function(a, b) return unicode.lower(a) < unicode.lower(b) end)

			for i = 1, #channelUsersList[field] do
				rightLayout:addChild(GUI.adaptiveButton(1, 1, 0, 0, nil, 0x969696, nil, 0x2D2D2D, channelUsersList[field][i])).onTouch = userButtonOnTouch
			end
		end
	end

	rightLayout:removeChildren()
	addCategory("operators", "Operators")
	addCategory("voiced", "Voiced")
	addCategory("default", "Users")
end

local function addUserToList(name)
	local firstSymbol = name:sub(1, 1)
	local field = firstSymbol == "@" and "operators" or firstSymbol == "+" and "voiced" or "default"

	for i = 1, #channelUsersList[field] do
		if channelUsersList[field][i] == name then
			return true
		end
	end

	table.insert(channelUsersList[field], name)
end

local function removeUserFromList(name)
	for field in pairs(channelUsersList) do
		for i = 1, #channelUsersList[field] do
			if channelUsersList[field][i] == name then
				table.remove(channelUsersList[field], i)
				updateUsersLayoutFromList()
				return true
			end
		end
	end
end

chat.eventHandler = function(workspace, chat, e1, e2, e3, e4, e5)
	if e1 == "scroll" then
		if e5 > 0 then
			if scrollBar.value > 1 then
				scrollBar.value = scrollBar.value - 1
				workspace:draw()
			end
		else
			if scrollBar.value < scrollBar.maximumValue then
				scrollBar.value = scrollBar.value + 1
				workspace:draw()
			end
		end
	elseif not e1 and socketHandle and computer.uptime() - oldUptime > socketReadDelay then
		local data = ""
		while true do
			local success, result = pcall(socketHandle.read, math.huge)
			if success then
				if result and #result > 0 then
					data = data .. result
				elseif #data > 0 then
					for line in data:gmatch("[^\r\n]+") do
						addChatMessage(socketUsername, line)

						local lineWithoutDots = line:match("^:(.+)")
						if lineWithoutDots then
							local words = {}
							for word in lineWithoutDots:gmatch("[^%s]+") do
								table.insert(words, word)
							end

							if #words >= 2 then
								local beforeDots, afterDots = lineWithoutDots:match("^([^:]+):(.+)")
								local username, address = words[1]:match("([^!]+)!([^!]+)")

								if words[2] == "NOTICE" then
									if username then
										if username == "NickServ" and afterDots then
											if afterDots:match("You are now identified") then
												backgroundContainer.hidden = true
											elseif afterDots:match("Invalid password for") then
												GUI.alert("Invalid password")
											end
										end

										addChatMessage(selectedItem.text, afterDots, username).notice = true
									else
										if afterDots and afterDots:match("Looking up your hostname...") then
											socketWrite("USER " .. config.username .. " 0 * :" .. config.username .. "\r\nNICK " .. config.username)
										end
									end
								elseif words[2] == "PRIVMSG" and username then
									local conversationName = words[3]:sub(1, 1) == "#" and words[3] or username

									local ctcp = afterDots:match("^\1(.+)\1$")
									if ctcp then
										local command, data = ctcp:match("^([^%s]+)%s(.+)")
										if ctcp == "VERSION" then
											sendMessage(username, "VERSION MineOS IRC Client / OpenComputers (Lua 5.3)", true, true)
										elseif ctcp == "TIME" then
											sendMessage(username, "TIME " .. os.date(system.getTime()), true, true)
										elseif command == "PING" then
											sendMessage(username, "PING " .. data, true, true)
										elseif command == "ACTION" then
											addChatMessage(conversationName, username .. " " .. data, "*").action = true
										else
											message = "Unsupported CTCP command: " .. ctcp
										end
									-- Regular message
									else
										addChatMessage(conversationName, afterDots, username)
									end

									if config.soundNotifications then
										computer.beep(2000, 0.05)
									end
								elseif words[2] == "JOIN" and username then
									if selectedItem.text == words[3] then
										if not addUserToList(username) then
											updateUsersLayoutFromList()
										end
									end

									addChatMessage(words[3], username .. " (" .. address .. ") has joined the channel", "!").channelAction = true
								elseif words[2] == "NICK" and username then
									addChatMessage(selectedItem.text, username .. " is now known as " .. afterDots, "!").channelAction = true
									local item = getItemByText(username)
									if item then
										history[item.text] = afterDots
										item.text = afterDots
									end
								elseif words[2] == "MODE" and username then
									addChatMessage(words[3], username .. " sets " .. words[5] .. " mode to " .. words[4], "!").channelAction = true
								elseif (words[2] == "QUIT" or words[2] == "PART") and username then
									if removeUserFromList(username) and words[2] == "QUIT" then
										addChatMessage(selectedItem.text, username .. " (" .. address .. ") has quit (" .. afterDots .. ")", "!").channelAction = true
									end

									if words[2] == "PART" and username ~= config.username  then
										addChatMessage(words[3], username .. " (" .. address .. ") has left the channel", "!").channelAction = true
									end
								-- User list
								elseif words[2] == "353" then
									if channelUsersListUpdatingFinished then
										channelUsersList.operators, channelUsersList.voiced, channelUsersList.default = {}, {}, {}
										channelUsersListUpdatingFinished = false
									end

									for username in afterDots:gmatch("[^%s]+") do
										addUserToList(username)
									end									
								-- User list finish
								elseif words[2] == "366" then
									channelUsersListUpdatingFinished = true
									updateUsersLayoutFromList()
								-- No password authorization
								elseif words[2] == "001" then
									if loginPasswordSwitchAndLabel.switch.state then
										status("Waiting for login request...")
									else
										backgroundContainer.hidden = true
									end
								-- Nickname in use
								elseif words[2] == "433" then
									status()
									GUI.alert("Nickname is already in use")
								-- Channel topic
								elseif words[2] == "332" then
									addChatMessage(words[4], afterDots, ">").channelAction = true
								-- Wait a while
								elseif words[2] == "263" then
									addChatMessage(selectedItem.text, afterDots, "!").channelAction = true
								-- End of MOTD
								elseif words[2] == "376" then
									if loginPasswordSwitchAndLabel.switch.state then
										status("Logging in...")
										socketWrite("IDENTIFY " .. config.username .. " " .. config.password)
									end
								-- No such nick/channel
								elseif words[2] == "401" then
									addChatMessage(words[4], "There's no " .. (words[4]:sub(1, 1) == "#" and "channel with such name" or "user with such nick") .. " online", "!").channelAction = true
								end
							end
						else
							local ping = line:match("^PING( :.+)")
							if ping then
								socketWrite("PONG" .. ping)
							end
						end
					end

					workspace:draw()
					break
				else
					break
				end
			else
				GUI.alert("Failed to read data from socket: " .. tostring(result))
				break
			end
		end

		oldUptime = computer.uptime()
	end
end

loginSubmitButton.onTouch = function()
	config.server = loginServerInput.text
	config.port = tonumber(loginPortInput.text)
	config.username = loginUsernameInput.text
	config.password = loginPasswordInput.text
	saveConfig()

	status("Connecting to server socket...")
	
	local result, reason = component.get("internet").connect(config.server, config.port)
	if result then
		socketHandle = result
		repeat
			event.sleep(socketConnectDelay)
		until socketHandle.finishConnect()

		status("Connection estabilished, waiting for response...")
		socketWrite("")
	else
		GUI.alert("Failed to connect to server: " .. tostring(socketHandle))
	end
end

settingsButton.onTouch = function()
	backgroundContainer.hidden = false
	backgroundLayout:removeChildren()
	
	local slider = backgroundLayout:addChild(GUI.slider(1, 1, 36, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xB4B4B4, 0, 500, config.historyLimit, false, "History limit: ", ""))
	slider.height = 2
	slider.roundValues = true

	local switchAndLabel = backgroundLayout:addChild(GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xB4B4B4, "Sound notifications:", config.soundNotifications))
	
	backgroundLayout:addChild(GUI.button(1, 1, 36, 3, 0xC3C3C3, 0xFFFFFF, 0x969696, 0xFFFFFF, "Save")).onTouch = function()
		config.historyLimit = math.floor(slider.value)
		config.soundNotifications = switchAndLabel.switch.state
		backgroundContainer.hidden = true
		
		workspace:draw()
		saveConfig()
	end

	workspace:draw()
end

contactAddButton.onTouch = function()
	backgroundContainer.hidden = false
	backgroundLayout:removeChildren()

	local input = backgroundLayout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x787878, 0xB4B4B4, 0xE1E1E1, 0x2D2D2D, "", "User or chat name"))
	backgroundLayout:addChild(GUI.button(1, 1, 36, 3, 0xB4B4B4, 0xFFFFFF, 0x969696, 0xB4B4B4, "Add contact")).onTouch = function()
		backgroundContainer.hidden = true

		if #input.text > 0 and not history[input.text] then
			selectItem(addContactItemToList(input.text))
		else
			workspace:draw()
		end
	end

	workspace:draw()
end

contactRemoveButton.onTouch = function()
	history[selectedItem.text] = nil
	selectedItem:remove()

	if selectedItem.joined then
		socketWrite("PART " .. selectedItem.text)
	end

	selectItem(systemList:getItem(socketUsername))
	updateLeftLayout()

	workspace:draw()
end

loginPasswordSwitchAndLabel.switch.onStateChanged = function()
	status()
end

window.onResize = function(width, height)
	backgroundContainer.width, backgroundContainer.height = width, height
	backgroundPanel.width, backgroundPanel.height = backgroundContainer.width, backgroundContainer.height
	backgroundLayout.width, backgroundLayout.height = backgroundContainer.width, backgroundContainer.height
	chat.localX, chat.width, chat.height = leftLayout.width + 1, width - leftLayout.width - window.backgroundPanel.width, height - chatInput.height
	window.backgroundPanel.localX, window.backgroundPanel.height = width - window.backgroundPanel.width + 1, height
	rightLayout.localX, rightLayout.height = window.backgroundPanel.localX + 1, window.backgroundPanel.height
	leftPanel.height = height - contactLayout.height
	leftLayout.height = leftPanel.height
	contactLayout.localY = height - contactLayout.height + 1
	scrollBar.localX, scrollBar.height = chat.localX + chat.width - 1, chat.height

	chatInputLayout.localX, chatInputLayout.localY, chatInputLayout.width = chat.localX, height - chatInputLayout.height + 1, chat.width
	chatInput.width = chatInputLayout.width - chatComboBox.width
end

scrollBar.onTouch = function()
	scrollBar.value = number.round(scrollBar.value)
	if scrollBar.value < 1 then
		scrollBar.value = 1
	elseif scrollBar.value > #history[selectedItem.text] then
		scrollBar.value = #history[selectedItem.text]
	end

	workspace:draw()
end

local overrideWindowRemove = window.remove
window.remove = function(...)
	if socketHandle then
		socketWrite("QUIT")
	end
	
	overrideWindowRemove(...)

	for key in pairs(history) do
		local i = 1
		while i <= #history[key] do
			if history[key][i].text then
				history[key][i].text = history[key][i].text:gsub("\\", "\\\\")
				history[key][i].text = history[key][i].text:gsub("\"", "\\\"")
				history[key][i].text = history[key][i].text:gsub("\'", "\\\'")
			end

			if history[key][i].newMessages then
				table.remove(history[key], i)
			else
				i = i + 1
			end
		end

		if #history[key] > 0 then
			table.insert(history[key], {newMessages = true})
		end
	end
	
	filesystem.writeTable(historyPath, history)
end

-------------------------------------------------------------------------------

for key in pairs(history) do
	addContactItemToList(key)
end

window:resize(window.width, window.height)

selectItem(systemList:getItem(socketUsername))
login()
-- backgroundContainer.hidden = true