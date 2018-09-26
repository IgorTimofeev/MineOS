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
local currentAccessToken, currentPeerID
local showUserProfile, showConversations
local lastPizda

local config = {
	avatars = {
		[7799889] = 0x2D2D2D,
	},
	loadCountConversations = 10,
	loadCountMessages = 10,
	loadCountNews = 10,
	scrollSpeed = 2,
	addMessagePostfix = true,
	updateContentTrigger = 0.2,
	loadCountWall = 10,
	loadCountFriends = 10,
	loadCountDocs = 10,
}

local configPath = MineOSPaths.applicationData .. "VK/Config3.cfg"
if fs.exists(configPath) then
	config = table.fromFile(configPath)
end

local scriptDirectory = MineOSCore.getCurrentScriptDirectory()
local localization = MineOSCore.getLocalization(scriptDirectory .. "Localizations/")

local icons = {}
for file in fs.list(scriptDirectory .. "Icons/") do
	local icon = image.load(scriptDirectory .. "Icons/" .. file)

	for y = 1, image.getHeight(icon) do
		for x = 1, image.getWidth(icon) do
			local b, f, a, s = image.get(icon, x, y)
			image.set(icon, x, y, b, 0xD2D2D2, a, s)
		end
	end

	icons[unicode.lower(fs.hideExtension(file))] = icon
end

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

local function saveConfig()
	table.toFile(configPath, config)
end

local function log(...)
	local file = io.open("/url.log", "a")
	file:write(...)
	file:close()
end

local function request(url, postData, headers)
	progressIndicator.active = true
	mainContainer:drawOnScreen()

	-- log(url, "\n")

	headers = headers or {}
	headers["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:42.0) Gecko/20100101 Firefox/42.0"

	local data = ""
	local success, reason = web.rawRequest(
		url,
		postData,
		headers,
		function(chunk)
			data = data .. chunk

			progressIndicator:roll()
			mainContainer:drawOnScreen()
		end,
		math.huge
	)

	if success then
		data = json.decode(data)
		progressIndicator.active = false
		mainContainer:drawOnScreen()

		return data
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
			GUI.alert("API request was successfult, but response field is missing, shit saved to /url.log")
			log(table.toString(result, true), "\n")
		end
	end
end

local function methodRequest(data)
	return responseRequest("https://api.vk.com/method/" .. data .. "&access_token=" .. currentAccessToken .. "&v=" .. VKAPIVersion)
end

local function addPanel(container, color)
	return container:addChild(GUI.panel(1, 1, container.width, container.height, color), 1)
end

local function fitToLastChild(what, addition)
	if what.update then
		what:update()
	end

	local endPoint = -math.huge
	for i = 1, #what.children do
		local child = what.children[i]
		if not child.hidden then
			endPoint = math.max(endPoint, child.localY + child.height - 1)
		end
	end

	what.height = endPoint + addition
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
		contentContainer.eventHandler = nil
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

local function pizdaSelect(object)
	lastPizda = object
	selectableSelect(object)
end

local function addPizda(name)
	local object = addSelectable(leftLayout, 1)
	
	object.draw = pizdaDraw
	object.name = name
	object.select = pizdaSelect
	maxPizdaLength = math.max(maxPizdaLength, unicode.len(name))

	return object
end

local function addScrollEventHandler(layout, regularDirection, updater)
	layout.eventHandler = function(mainContainer, layout, e1, e2, e3, e4, e5)
		if e1 == "scroll" then
			local cell = layout.cells[1][1]

			if regularDirection then
				if e5 > 0 then
					cell.verticalMargin = cell.verticalMargin + config.scrollSpeed
					if cell.verticalMargin > 1 then
						cell.verticalMargin = 1
					end
				else
					cell.verticalMargin = cell.verticalMargin - config.scrollSpeed
					local lastChild = layout.children[#layout.children]
					if lastChild.localY + lastChild.height - 1 < layout.height * (1 - config.updateContentTrigger) then
						updater()
					end
				end
			else
				if e5 > 0 then
					cell.verticalMargin = cell.verticalMargin - config.scrollSpeed
					layout:update()

					if layout.children[1].localY > layout.height * config.updateContentTrigger then
						updater()
					end
				else
					cell.verticalMargin = cell.verticalMargin + config.scrollSpeed
					if cell.verticalMargin > 1 then
						cell.verticalMargin = 1
					end
				end
			end
			
			mainContainer:drawOnScreen()
		end
	end
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
	local hue = math.abs(peerID) % 360
	return color.HSBToInteger(hue, 0.25, 1), color.HSBToInteger(hue, 1, 0.9)
	-- config.avatars[peerID] = config.avatars[peerID] or math.random(360)
	-- return color.HSBToInteger(config.avatars[peerID], 0.25, 1), color.HSBToInteger(config.avatars[peerID], 1, 0.9)
end

local function avatarDraw(object)
	buffer.drawRectangle(object.x, object.y, object.width, object.height, object.backgroundColor, object.textColor, " ")
	buffer.drawText(math.floor(object.x + object.width / 2 - unicode.len(object.shortcut) / 2), math.floor(object.y + object.height / 2 - 1), object.textColor, object.shortcut)

	if object.selected then
		buffer.drawRectangle(object.x, object.y, object.width, object.height, 0x0, 0x0, " ", 0.5)
	end
end

local function avatarEventHandler(mainContainer, object, e1)
	if e1 == "touch" then
		object.selected = true
		mainContainer:drawOnScreen()

		os.sleep(0.2)
		
		object.selected = false
		showUserProfile(object.peerID)
	end
end

local function newAvatar(x, y, width, height, name, peerID)
	local object = GUI.object(x, y, width, height)
	
	object.backgroundColor, object.textColor = getAvatarColors(peerID)
	object.draw = avatarDraw
	object.shortcut = getNameShortcut(name)
	object.peerID = peerID
	object.eventHandler = avatarEventHandler

	return object
end

local function verticalLineDraw(object)
	for i = 1, object.height do
		buffer.drawText(object.x, object.y + i - 1, object.color, "│")
	end
end

local function newVerticalLine(x, y, height, color)
	local object = GUI.object(x, y, 1, height)
	
	object.draw = verticalLineDraw
	object.color = color
	
	return object
end

local function horizontalLineDraw(object)
	buffer.drawText(object.x, object.y, object.color, string.rep("─", object.width))
end

local function newHorizontalLine(x, y, width, color)
	local object = GUI.object(x, y, width, 1)
	
	object.draw = horizontalLineDraw
	object.color = color
	
	return object
end

local function attachmentDraw(object)
	-- buffer.drawRectangle(object.x, object.y, object.width, 1, 0x880000, 0xA5A5A5, " ")
	local x, y, typeLength = object.x, object.y, unicode.len(object.type)
	-- Type
	buffer.drawText(x, y, object.typeB, "⠰"); x = x + 1
	buffer.drawRectangle(x, y, typeLength + 2, 1, object.typeB, object.typeT, " "); x = x + 1
	buffer.drawText(x, y, object.typeT, object.type); x = x + typeLength + 1

	local textB = object.selected and object.selectionB or object.textB
	local textT = object.selected and object.selectionT or object.textT

	buffer.set(x, y, textB, object.typeB, "⠆"); x = x + 1
	-- Text
	buffer.drawRectangle(x, y, object.width - typeLength - 5, 1, textB, textT, " "); x = x + 1
	buffer.drawText(x, y, textT, string.limit(object.text, object.width - typeLength - 7))
	buffer.drawText(object.x + object.width - 1, y, textB, "⠆")
end

local function newAttachment(x, y, maxWidth, attachment, typeB, typeT, textB, textT, selectionB, selectionT)
	local object = GUI.object(x, y, 1, 1)

	object.typeB = typeB
	object.typeT = typeT
	object.textB = textB
	object.textT = textT
	object.selectionB = selectionB
	object.selectionT = selectionT

	object.type = capitalize(localization.attachmentsTypes[attachment.type])

	if attachment.photo then
		local maxIndex, maxWidth = 1, 0
		for i = 1, #attachment.photo.sizes do
			if maxWidth < attachment.photo.sizes[i].width then
				maxIndex, maxWidth = i, attachment.photo.sizes[i].width
			end
		end

		object.text = attachment.photo.sizes[maxIndex].width .. " x " .. attachment.photo.sizes[maxIndex].height .. " px"
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
	elseif attachment.gift then
		object.text = ":3"
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

local function newPost(x, y, width, mainMessage, profiles, conversations, groups, senderName, fwdMessagesFieldName, data)
	local object = GUI.container(x, y, width, 1)
	
	local localX, localY = 1, 1

	local avatar = object:addChild(newAvatar(localX, localY, 4, 2, getNameShortcut(senderName), data.from_id or data.source_id))
	localX = localX + avatar.width + 1
	
	local nameText = object:addChild(GUI.text(localX, localY, 0x3C3C3C, senderName))
	object:addChild(GUI.text(localX + nameText.width + 1, localY, 0xD2D2D2, os.date("%H:%M", data.date)))

	localY = localY + 1

	if #data.text > 0 then
		local lines = string.wrap(data.text, width - localX)
		object.textBox = object:addChild(GUI.textBox(localX, localY, width - localX, #lines, nil, 0xA5A5A5, lines, 1, 0, 0))
		object.textBox.eventHandler = nil
		localY = localY + object.textBox.height + 1
	else
		localY = localY + 1
	end

	local function addAnotherPost(senderName, data)
		localY = localY + (mainMessage and 0 or 1)

		local offset = mainMessage and 6 or 1
		local attachment = object:addChild(
			newPost(
				offset + 2,
				localY,
				math.max(16, width - 6),
				false,
				profiles,
				conversations,
				groups,
				senderName,
				fwdMessagesFieldName,
				data
			)
		)
		object:addChild(newVerticalLine(offset, localY, attachment.height, 0xE1E1E1))
		
		localY = localY + attachment.height + 1
	end

	if data.attachments and #data.attachments > 0 then
		for i = 1, #data.attachments do
			local attachment = data.attachments[i]
			if localization.attachmentsTypes[attachment.type] then
				if attachment.wall then
					addAnotherPost(
						attachment.wall.from.name or (attachment.wall.from.first_name .. " " .. attachment.wall.from.last_name),
						attachment.wall
					)
				else
					object:addChild(newAttachment(localX, localY, object.width - localX, attachment, 0xF0F0F0, 0xA5A5A5, 0xE1E1E1, 0x787878, 0x3392FF, 0xE1E1E1))
					localY = localY + 2
				end
			end
		end
	end

	-- fwd_messages
	if data[fwdMessagesFieldName] then
		for i = 1, #data[fwdMessagesFieldName] do
			addAnotherPost(
				getSenderName(profiles, conversations, groups, data[fwdMessagesFieldName][i].from_id),
				data[fwdMessagesFieldName][i]
			)
		end
	end

	if data.likes or data.reposts or data.views or data.comments then
		local layout = object:addChild(GUI.layout(localX, localY, object.width - localX, 2, 1, 1))
		layout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_BOTTOM)
		layout:setDirection(1, 1, GUI.DIRECTION_HORIZONTAL)
		layout:setSpacing(1, 1, 2)

		local function addStuff(icon, text)
			local container = layout:addChild(GUI.container(1, 1, 5 + unicode.len(text), 2))
			container:addChild(GUI.image(1, 1, icon))
			container:addChild(GUI.text(6, 2, 0x969696, text))
		end

		addStuff(icons.likes, tostring(data.likes and data.likes.count or 0))
		addStuff(icons.comments, tostring(data.comments and data.comments.count or 0))
		addStuff(icons.reposts, tostring(data.reposts and data.reposts.count or 0))
		addStuff(icons.views, tostring(data.views and data.views.count or 0))
		
		localY = localY + 3
	end

	object.height = localY - 2

	-- object:addChild(GUI.panel(1, 1, width, object.height, 0x0), 1)

	return object
end

local function uploadDocument(path)
	local fileName = fs.name(path)
	local uploadServer = methodRequest("docs.getUploadServer?")
	if uploadServer then
		local boundary = "----WebKitFormBoundaryISgaMqjePLcGZFOx"
		local handle = io.open(path, "rb")
		
		local data =
			"--" .. boundary .. "\r\n" ..
			"Content-Disposition: form-data; name=\"file\"; filename=\"" .. fileName .. "\"\r\n" ..
			"Content-Type: application/octet-stream\r\n\r\n" ..
			handle:read("*a") .. "\r\n" ..
			"--" .. boundary .. "--"

		handle:close()

		local uploadResult, reason = request(
			uploadServer.upload_url,
			data,
			{
				["Content-Type"] = "multipart/form-data; boundary=" .. boundary,
				["Content-Length"] = #data,
			}
		)

		table.toFile("/test.txt", {
			url = uploadServer.upload_url,
			data = data,
			size = #data,
		}, true)

		if uploadResult then
			if uploadResult.file then
				return methodRequest("docs.save?file=" .. uploadResult.file .. "&title=" .. fileName)
			else
				GUI.alert("UPLOAD ALMOST ZAEBIS, BUT NOT FILE", uploadResult)
			end
		else
			GUI.alert("UPLOAD FAIL", reason)
		end
	end
end

local function getHistory(peerID, startMessageID)
	return methodRequest("messages.getHistory?extended=1&fields=first_name,last_name,online&count=" .. config.loadCountMessages .. "&peer_id=" .. peerID .. (startMessageID and "&offset=1" or "") .. (startMessageID and ("&start_message_id=" .. startMessageID) or ""))
end

local function showHistory(container, peerID)
	local messagesHistory = getHistory(peerID, nil)
	if messagesHistory then
		container:removeChildren()

		local inputLayout = container:addChild(GUI.layout(1, container.height - 2, container.width, 3, 1, 1))
		inputLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_TOP)
		inputLayout:setSpacing(1, 1, 0)
		inputLayout:setDirection(1, 1, GUI.DIRECTION_HORIZONTAL)

		local attachButton = inputLayout:addChild(GUI.adaptiveButton(1, 1, 2, 1, 0xE1E1E1, 0x3C3C3C, 0x2D2D2D, 0xFFFFFF, "+"))
		attachButton.switchMode = true
		local sendButton = inputLayout:addChild(GUI.adaptiveButton(1, 1, 2, 1, 0xE1E1E1, 0x3C3C3C, 0x2D2D2D, 0xFFFFFF, localization.send))
		local input = inputLayout:addChild(GUI.input(1, 1, inputLayout.width - sendButton.width - attachButton.width, 3, 0xF0F0F0, 0x787878, 0xA5A5A5, 0xF0F0F0, 0x3C3C3C, "", localization.typeMessageHere), 2)
		
		local layout = container:addChild(GUI.layout(2, 1, container.width - 2, container.height - input.height, 1, 1))
		layout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_BOTTOM)
		layout:setMargin(1, 1, 0, 1)

		local function addFromHistory(history)
			for i = 1, #history.items do
				local post = layout:addChild(
					newPost(2, y, container.width - 2, true,
						history.profiles,
						history.conversations,
						history.groups,
						getSenderName(
							history.profiles,
							history.conversations,
							history.groups,
							history.items[i].from_id
						),
						"fwd_messages",
						history.items[i]
					), 1
				)

				post.id = history.items[i].id
			end
		end

		addFromHistory(messagesHistory)

		addScrollEventHandler(layout, false, function()
			local newMessagesHistory = getHistory(peerID, layout.children[1].id)
			if newMessagesHistory then
				addFromHistory(newMessagesHistory)
			end
		end)

		local attachedPath
		attachButton.onTouch = function()
			if attachedPath then
				attachedPath = nil
			else
				local filesystemDialog = GUI.addFilesystemDialog(window, true, 45, window.height - 5, "Open", "Cancel", "File name", "/")
				filesystemDialog:setMode(GUI.IO_MODE_OPEN, GUI.IO_MODE_FILE)
				filesystemDialog.onSubmit = function(path)
					attachedPath = path
				end

				filesystemDialog:show()
			end
		end

		sendButton.onTouch = function()
			if #input.text > 0 or filesystemChooser.path then
				local attachment
				if attachedPath then
					local saveResult = uploadDocument(attachedPath)
					if saveResult then
						attachment = "&attachment=doc" .. saveResult[1].owner_id .. "_" .. saveResult[1].id
					end
					
					attachedPath = nil
				end

				local sendResult = methodRequest("messages.send?peer_id=" .. peerID .. (attachment or "") .. (#input.text > 0 and ("&message=" .. web.encode(input.text)) or ""))
				if sendResult then
					showHistory(container, peerID)
				end
			end
		end

		mainContainer:drawOnScreen()
	end
end

local function usersRequest(ids, nameCase, fields)
	return methodRequest("users.get?name_case=" .. nameCase .. "&user_ids=" .. ids .. (fields and "&fields=" .. fields or ""))
end

local function friendsRequest(online, peerID, order, offset, count, fields)
	return methodRequest("friends.get" .. (online and "Online" or "") .. "?name_case=Nom&user_id=" .. peerID .. "&order=" .. order .. (offset and "&offset=" .. offset or "") .. (count and "&count=" .. count or "") .. (fields and "&fields=" .. fields or ""))
end

local function wallRequest(peerID, offset, filter)
	return methodRequest("wall.get?extended=1&fields=first_name,last_name&owner_id=" .. peerID .. "&offset=" .. offset .. "&count=" .. config.loadCountWall .. "&filter=" .. filter)
end

showUserProfile = function(peerID)
	local friendsDisplayColumns, friendsDisplayRows = 3, 2
	local friendsDisplayCount = friendsDisplayColumns * friendsDisplayRows
	local friendsNameLimit = 6

	local user = usersRequest(peerID, "Nom", "activities,education,tv,status,sex,schools,relation,quotes,personal,occupation,connections,counters,contacts,verified,city,country,site,last_seen,online,bdate,books,movies,music,games,universities,interests,home_town,relatives,friend_status")
	if user then
		local allFriends = friendsRequest(false, peerID, "random", 0, friendsDisplayCount)
		if allFriends then
			-- GUI.alert(table.toFile("/test.txt", allFriends, true))
			local onlineFriends = friendsRequest(true, peerID, "random")
			if onlineFriends then
				local wall = wallRequest(peerID, 0, "all")
				if wall then
					-- GUI.alert(table.toFile("/test.txt", onlineFriends, true))
					local friendsInfo = usersRequest(table.concat(allFriends.items, ",") .. "," .. table.concat(onlineFriends, ",", 1, math.min(#onlineFriends, friendsDisplayCount)), "Nom", "first_name,last_name")
					if friendsInfo then
						user = user[1]
						local fullName = user.first_name .. " " .. user.last_name
						local profileKeys = localization.profileKeys

						contentContainer:removeChildren()

						local userContainer = contentContainer:addChild(GUI.container(1, 1, contentContainer.width, 1))

						-- Авочка
						local leftLayout = userContainer:addChild(GUI.layout(3, 2, 24, 1, 1, 1))
						leftLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_TOP)

						local avatarContainer = leftLayout:addChild(GUI.container(1, 1, leftLayout.width, 1))
						local avatar = avatarContainer:addChild(newAvatar(3, 2, avatarContainer.width - 4, math.floor((avatarContainer.width - 4) / 2), getNameShortcut(fullName), user.id))

						if peerID ~= currentPeerID then
							local messageButton = avatarContainer:addChild(GUI.roundedButton(3, avatar.localY + avatar.height + 1, avatar.width, 1, 0xA5A5A5, 0xFFFFFF, 0x3C3C3C, 0xFFFFFF, localization.message))
							messageButton.onTouch = function()
								showConversations(peerID)
							end

							-- local friendButton = avatarContainer:addChild(GUI.roundedButton(3, messageButton.localY + messageButton.height + 1, avatar.width, 1, 0xA5A5A5, 0xFFFFFF, 0x3C3C3C, 0xFFFFFF, user.friend_status == 0 and localization.addToFriends or user.friend_status == 1 and localization.friendRequestSent or user.friend_status == 2 and localization.userSubscribedToYou or localization.userIsYourFriend))
						end

						fitToLastChild(avatarContainer, 1)
						addPanel(avatarContainer, 0xFFFFFF)

						-- Список друзяшек
						local function addFriendsList(title, titleCount, list)
							if #list > 0 then
								local rowsCount = math.min(math.ceil(#list / friendsDisplayColumns), friendsDisplayRows)
								
								local container = leftLayout:addChild(GUI.container(1, 1, leftLayout.width, 3 + rowsCount * 5))
								
								addPanel(container, 0xFFFFFF)
								title = container:addChild(GUI.text(3, 2, 0x3C3C3C, title))
								container:addChild(GUI.text(title.localX + title.width + 1, 2, 0xB4B4B4, tostring(titleCount)))

								local layout = container:addChild(GUI.layout(1, 4, container.width, container.height - 3, friendsDisplayColumns, rowsCount))
								
								local index = 1
								for row = 1, rowsCount do
									for column = 1, friendsDisplayColumns do
										if list[index] then
											local eblo = getEblo(friendsInfo, list[index])
											if eblo then
												layout.defaultColumn, layout.defaultRow = column, row

												layout:addChild(newAvatar(1, 1, 4, 2, getNameShortcut(eblo.first_name .. " " .. eblo.last_name), eblo.id))
												layout:addChild(GUI.text(1, 4, 0xA5A5A5, string.limit(eblo.first_name, friendsNameLimit)))

												index = index + 1
											else
												GUI.alert("EBLO NOT FOUND", list[index])
											end
										else
											break
										end
									end
								end
							end
						end

						addFriendsList(localization.friends, allFriends.count, allFriends.items)
						addFriendsList(localization.friendsOnline, #onlineFriends, onlineFriends)

						-- Инфа о юзвере
						local rightLayout = userContainer:addChild(GUI.layout(leftLayout.localX + leftLayout.width + 2, 2, userContainer.width - leftLayout.width - 6, 1, 1, 1))
						rightLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_TOP)

						local infoContainer = rightLayout:addChild(GUI.container(1, 1, rightLayout.width, 1))
						local infoPanel = addPanel(infoContainer, 0xFFFFFF)
						local infoLayout = infoContainer:addChild(GUI.layout(infoPanel.localX + 2, infoPanel.localY + 1, infoPanel.width - 4, 1, 1, 1))
						infoLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_TOP)
						infoLayout:setSpacing(1, 1, 0)

						local layoutToAdd = infoLayout

						local function addTitle(text)
							local container = layoutToAdd:addChild(GUI.container(1, 1, layoutToAdd.width, 3))
							
							if text then
								text = container:addChild(GUI.text(1, 2, 0x3C3C3C, text))
								container:addChild(newHorizontalLine(text.width + 2, 2, container.width - text.width - 1, 0xE1E1E1))
							else
								container:addChild(newHorizontalLine(1, 2, container.width, 0xE1E1E1))
							end
						end

						local maxProfileKeyLength = 0
						for key, value in pairs(profileKeys) do
							maxProfileKeyLength = math.max(maxProfileKeyLength, unicode.len(value))
						end
						maxProfileKeyLength = maxProfileKeyLength + 4

						local function addKeyAndValue(key, value)
							local container = layoutToAdd:addChild(GUI.container(1, 1, layoutToAdd.width, 1))
							container:addChild(GUI.text(1, 1, 0xB4B4B4, key .. ": "))

							local width = container.width - maxProfileKeyLength
							local lines = string.wrap(value, width)
							container:addChild(GUI.textBox(maxProfileKeyLength, 1, width, #lines, nil, 0x969696, lines, 1)).eventHandler = nil

							container.height = #lines
						end

						local function anyExists(...)
							local args = {...}
							for i = 1, #args do
								if args[i] and (type(args[i]) ~= "string" or #args[i] > 0) then
									return true
								end
							end
						end

						local function addIfExists(what, ...)
							if what and (type(what) ~= "string" or #what > 0) then
								addKeyAndValue(...)
							end
						end

						infoLayout:addChild(GUI.text(1, 1, 0x0, fullName))

						if user.status and #user.status > 0 then
							local statusButton = infoLayout:addChild(GUI.adaptiveButton(1, 1, 0, 0, nil, 0x696969, nil, 0x0, user.status_audio and ("* " .. user.status_audio.artist .. " - " .. user.status_audio.title) or user.status))
						end

						addTitle()

						if user.bdate then
							local cyka = {}
							for part in user.bdate:gmatch("%d+") do
								table.insert(cyka, part)
							end
							addKeyAndValue(profileKeys.birthday, cyka[1] .. " " .. localization.months[tonumber(cyka[2])] .. (cyka[3] and " " .. cyka[3] or ""))
						end

						if user.city then
							addKeyAndValue(profileKeys.city, user.city.title == "Москва" and "Массква" or user.city.title)
						end

						addIfExists(user.relation, profileKeys.relation, localization.relationStatuses[user.sex > 0 and user.sex or 1][user.relation])
						
						if user.occupation then
							addKeyAndValue(profileKeys.occupation, user.occupation.name)
						end
						
						if user.university_name and #user.university_name > 0 then
							addKeyAndValue(profileKeys.education, user.university_name .. "'" .. tostring(user.graduation):sub(-2, -1))
						end

						addIfExists(user.site, profileKeys.site, user.site)

						-- Вот тута начинается дополнительная инфа
						local expandButton = infoLayout:addChild(GUI.button(1, 1, infoLayout.width, 2, nil, 0x969696, nil, 0x0, ""))

						local additionalLayout = infoLayout:addChild(GUI.layout(1, 1, infoLayout.width, 1, 1, 1))
						additionalLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_TOP)
						additionalLayout:setSpacing(1, 1, 0)
						additionalLayout.hidden = true

						layoutToAdd = additionalLayout

						-- Основная инфа
						if anyExists(user.home_town, user.personal and user.personal.langs) then
							addTitle(localization.profileTitleMainInformation)

							addIfExists(user.home_town, profileKeys.homeCity, user.home_town)

							if user.personal and user.personal.langs then
								addKeyAndValue(profileKeys.languages, table.concat(user.personal.langs, ", "))
							end
						end

						-- Контакты
						if anyExists(user.mobile_phone, user.home_phone, user.skype, user.instagram, user.facebook) then
							addTitle(localization.profileTitleContacts)

							addIfExists(user.mobile_phone, profileKeys.mobilePhone, user.mobile_phone)
							addIfExists(user.home_phone, profileKeys.homePhone, user.home_phone)
							addIfExists(user.skype, "Skype", user.skype)
							addIfExists(user.instagram, "Instagram", user.instagram)
							addIfExists(user.facebook, "Facebook", user.facebook)
						end

						if user.personal and anyExists(user.personal.political, user.personal.religon, user.personal.life_main, user.personal.people_main, user.personal.smoking, user.personal.alcohol, user.personal.inspired_by) then
							addTitle(localization.profileTitlePersonal)

							addIfExists(user.personal.political, profileKeys.political, localization.personalPoliticalTypes[user.personal.political])

							addIfExists(user.personal.religon, profileKeys.religion, user.personal.religon)

							addIfExists(user.personal.life_main, profileKeys.lifeMain, localization.personalLifeMainTypes[user.personal.life_main])

							addIfExists(user.personal.people_main, profileKeys.peopleMain, localization.personalPeopleMainTypes[user.personal.people_main])

							addIfExists(user.personal.smoking, profileKeys.smoking, localization.personalBlyadTypes[user.personal.smoking])

							addIfExists(user.personal.alcohol, profileKeys.alcohol, localization.personalBlyadTypes[user.personal.alcohol])

							addIfExists(user.personal.inspired_by, profileKeys.inspiredBy, user.personal.inspired_by)
						end

						if anyExists(user.activities, user.interests, user.music, user.movies, user.tv, user.games, user.books, user.quotes) then
							addTitle(localization.profileTitleAdditions)

							addIfExists(user.activities, profileKeys.activities, user.activities)
							addIfExists(user.interests, profileKeys.interests, user.interests)
							addIfExists(user.music, profileKeys.music, user.music)
							addIfExists(user.movies, profileKeys.movies, user.movies)
							addIfExists(user.tv, profileKeys.tv, user.tv)
							addIfExists(user.games, profileKeys.games, user.games)
							addIfExists(user.books, profileKeys.books, user.books)
							addIfExists(user.quotes, profileKeys.quotes, user.quotes)
						end
						
						-- И снова добавляем в основной лейаут
						layoutToAdd = infoLayout

						addTitle()

						local statsLayout = layoutToAdd:addChild(GUI.layout(1, 1, layoutToAdd.width, 2, 1, 1))
						statsLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
						statsLayout:setDirection(1, 1, GUI.DIRECTION_HORIZONTAL)
						statsLayout:setSpacing(1, 1, 3)	

						local function counterDraw(object)
							local centerX = object.x + object.width / 2
							buffer.drawText(math.floor(centerX - object.countLength / 2), object.y, 0x3C3C3C, object.count)
							buffer.drawText(math.floor(centerX - object.descriptionLength / 2), object.y + 1, 0x969696, object.description)
						end

						for i = 1, #localization.profileCounters do
							local count = user.counters[localization.profileCounters[i].field]
							if count then
								local object = GUI.object(1, 1, 1, 2)

								object.count = tostring(count)
								object.description = localization.profileCounters[i].description
								object.countLength = unicode.len(object.count)
								object.descriptionLength = unicode.len(object.description)
								object.width = math.max(object.countLength, object.descriptionLength)
								object.draw = counterDraw

								statsLayout:addChild(object)
							end
						end

						-- Стена
						local wallLayout = rightLayout:addChild(GUI.layout(1, 1, rightLayout.width, 1, 1, 1))
						wallLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_TOP)

						for i = 1, #wall.items do
							local item = wall.items[i]
							local post = newPost(3, 2, rightLayout.width - 4, true,
								wall.profiles,
								wall.conversations,
								wall.groups,
								getSenderName(wall.profiles, wall.conversations, wall.groups, item.from_id),
								"copy_history",
								item
							)

							local container = wallLayout:addChild(GUI.container(1, 1, rightLayout.width, post.height + 2))
							addPanel(container, 0xFFFFFF)
							container:addChild(post)
						end

						fitToLastChild(wallLayout, 0)

						local function update()
							-- Фиттим дополнительный лейаут
							fitToLastChild(additionalLayout, 0)
							-- Фиттим лейаут с инфой
							fitToLastChild(infoLayout, 0)
							-- Подгоняем контейнер под него
							infoContainer.height = infoLayout.height + 2
							infoPanel.height = infoContainer.height
							-- Фиттим лево-правые лейауты
							fitToLastChild(leftLayout, 1)
							fitToLastChild(rightLayout, 1)
							-- Фиттим весь юзер-контейнер с авой, друганами и всем дерьмом
							fitToLastChild(userContainer, 0)
							-- Ой, кнопочка!
							expandButton.text = additionalLayout.hidden and localization.profileShowAdditional or localization.profileHideAdditional
						end

						update()

						expandButton.onTouch = function()
							additionalLayout.hidden = not additionalLayout.hidden
							update()
						end

						contentContainer.eventHandler = function(mainContainer, contentContainer, e1, e2, e3, e4, e5)
							if e1 == "scroll" then
								userContainer.localY = userContainer.localY + (e5 > 0 and 1 or -1) * config.scrollSpeed
								
								if userContainer.localY + userContainer.height - 1 < contentContainer.height then
									userContainer.localY = contentContainer.height - userContainer.height
								end

								if userContainer.localY > 1 then
									userContainer.localY = 1
								end

								mainContainer:drawOnScreen()
							end
						end
					end
				end
			end
		end
	end
end

local profileSelectable = addPizda(localization.profile)
profileSelectable.onTouch = function()
	showUserProfile(currentPeerID)

	-- Яша
	-- showUserProfile(60991376)

	-- Яна
	-- showUserProfile(155326634)

	-- Крутой
	-- showUserProfile(21321257)
end

local function showFriends(peerID)
	local offset = 0

	local function getFriendsAndLists()
		local friends = friendsRequest(false, peerID, "hints", offset, config.loadCountFriends, "first_name,last_name,occupation")
		if friends then
			local lists = methodRequest("friends.getLists?return_system=1&user_id=" .. peerID)
			if lists then
				-- Удобнее!
				for i = 1, #lists.items do
					lists[lists.items[i].id] = lists.items[i].name
					lists.items[i] = nil
				end
				lists.items, lists.count = nil, nil

				return friends, lists
			end
		end
	end

	local friends, lists = getFriendsAndLists()
	if friends then
		contentContainer:removeChildren()

		local layout = contentContainer:addChild(GUI.layout(3, 1, contentContainer.width - 4, contentContainer.height, 1, 1))
		layout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_TOP)
		layout:setMargin(1, 1, 0, 1)

		local function addFromList(friends, lists)
			for i = 1, #friends.items do
				local item = friends.items[i]
				local fullName = item.first_name .. " " .. item.last_name
				local container = layout:addChild(GUI.container(1, 1, layout.width, 1))

				local avatar = container:addChild(newAvatar(3, 2, 8, 4, getNameShortcut(fullName), item.id))

				local startX = avatar.localX + avatar.width + 2
				local x, y = startX, avatar.localY
				
				container:addChild(GUI.text(startX, y, 0x3C3C3C, fullName)); y = y + 1
				if item.occupation then
					container:addChild(GUI.text(startX, y, 0xA5A5A5, item.occupation.name)); y = y + 1
				end
				y = y + 1

				if item.lists then
					local offset, space = 1, 2
					
					for j = 1, #item.lists do
						local text = lists[item.lists[j]] or "N/A"

						if x + unicode.len(text) + offset * 2 >= container.width then
							x, y = startX, y + 2
						end

						local button = container:addChild(GUI.adaptiveRoundedButton(x, y, offset, 0, 0xC3C3C3, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, text))

						x = x + button.width + space
					end

					y = y + 2
				end

				container:addChild(GUI.adaptiveButton(startX, y, 0, 0, nil, 0x696969, nil, 0x0, localization.sendMessage)).onTouch = function()
					showConversations(item.id)
				end

				fitToLastChild(container, 1)
				addPanel(container, 0xFFFFFF)
			end
		end

		addFromList(friends, lists)

		addScrollEventHandler(layout, true, function()
			offset = offset + config.loadCountFriends

			local friends, lists = getFriendsAndLists()
			if friends then
				addFromList(friends, lists)
				mainContainer:drawOnScreen()
			end
		end)
	end
end

local newsSelectable = addPizda(localization.news)
newsSelectable.onTouch = function()
	local function getNews(startFrom)
		return methodRequest("newsfeed.get?filters=post&fields=first_name,last_name,name&count=" .. config.loadCountNews .. (startFrom and ("&start_from=" .. startFrom) or ""))
	end

	local news = getNews(nil)
	if news then
		contentContainer:removeChildren()

		local layout = contentContainer:addChild(GUI.layout(3, 1, contentContainer.width - 4, contentContainer.height, 1, 1))
		layout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_TOP)
		layout:setSpacing(1, 1, 1)
		layout:setMargin(1, 1, 0, 1)
		
		local function addFromList(list)
			for i = 1, #list.items do
				local item = list.items[i]

				local postContainer = layout:addChild(GUI.container(1, 1, layout.width, 1))

				local post = postContainer:addChild(newPost(
					3, 2, postContainer.width - 4, true,
					list.profiles,
					list.conversations,
					list.groups,
					getSenderName(list.profiles, list.conversations, list.groups, item.source_id),
					"copy_history",
					item
				))

				postContainer.height = post.height + 2

				postContainer:addChild(GUI.panel(1, 1, postContainer.width, postContainer.height, 0xFFFFFF), 1)
			end
		end

		addFromList(news)

		local nextFrom = news.next_from
		addScrollEventHandler(layout, true, function()
			local newNews = getNews(nextFrom)
			if newNews then
				nextFrom = newNews.next_from
				addFromList(newNews)
			end
		end)

		mainContainer:drawOnScreen()
	end
end

showConversations = function(peerID)
	local function getConversations(startMessageID)
		return methodRequest("messages.getConversations?filter=all&extended=1&fields=first_name,last_name,online,id&count=" .. config.loadCountConversations .. (startMessageID and "&offset=1" or "") .. (startMessageID and ("&start_message_id=" .. startMessageID) or ""))
	end

	local result = getConversations(nil)
	if result then
		contentContainer:removeChildren()

		local layout = contentContainer:addChild(GUI.layout(1, 1, 28, contentContainer.height, 1, 1))
		layout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_TOP)
		layout:setSpacing(1, 1, 1)
		layout:setMargin(1, 1, 0, 1)

		local conversationPanel = contentContainer:addChild(GUI.panel(layout.width + 1, 1, contentContainer.width - layout.width, contentContainer.height, 0xFFFFFF))
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

		local function addFromList(list)
			for i = 1, #list.items do
				local item = list.items[i]

				local object = addSelectable(layout, 2)

				object.id = item.last_message.id
				object.selected = item.conversation.peer.id == peerID

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
						local eblo = getEblo(list.profiles, item.last_message.from_id)
						object.message = eblo.first_name .. ": " .. object.message
					end
				end

				object.date = os.date("%H:%M", item.last_message.date)
				object.out = item.last_message.out
				object.avatarColor, object.avatarTextColor = getAvatarColors(item.conversation.peer.id)

				-- Имя отправителя
				object.name = getSenderName(list.profiles, item.conversation, list.groups, item.conversation.peer.id)

				-- Превьюха имени отправителя для аватарки
				object.shortcut = getNameShortcut(object.name)

				object.draw = conversationDraw

				object.onTouch = function()
					showHistory(conversationContainer, item.conversation.peer.id)
				end
			end
		end

		addFromList(result)

		addScrollEventHandler(layout, true, function()
			local newConversations = getConversations(layout.children[#layout.children].id)
			if newConversations then
				addFromList(newConversations)
			end
		end)

		if peerID then
			showHistory(conversationContainer, peerID)
		else
			if #layout.children > 0 then
				layout.children[1]:select()
			else
				mainContainer:drawOnScreen()
			end
		end
	end
end

local conversationsSelectable = addPizda(localization.conversations)
conversationsSelectable.onTouch = function()
	showConversations()
end

local friendsSelectable = addPizda(localization.friends)
friendsSelectable.onTouch = function()
	showFriends(currentPeerID)
end

loginUsernameInput.onInputFinished = function()
	loginButton.disabled = #loginUsernameInput.text == 0 or #loginPasswordInput.text == 0
	mainContainer:drawOnScreen()
end

loginPasswordInput.onInputFinished = loginUsernameInput.onInputFinished

local function logout()
	currentAccessToken = nil
	currentPeerID = nil
	config.accessToken = nil
	config.peerID = nil
	loginContainer.hidden = false
	
	mainContainer:drawOnScreen()
end

local function login()
	if currentAccessToken then
		loginContainer.hidden = true
		conversationsSelectable:select()
	else
		loginUsernameInput.onInputFinished()
	end
end

loginButton.onTouch = function()
	local result, reason = request("https://oauth.vk.com/token?grant_type=password&client_id=3697615&client_secret=AlVXZFMUqyrnABp8ncuU&username=" .. loginUsernameInput.text .. "&password=" .. loginPasswordInput.text .. "&v=" .. VKAPIVersion)
	if result then
		loginPasswordInput.text = nil

		if result.access_token then
			currentAccessToken = result.access_token
			currentPeerID = result.user_id
			config.accessToken = loginSaveSwitch.state and currentAccessToken or nil
			config.username = loginSaveSwitch.state and loginUsernameInput.text or nil
			config.peerID = loginSaveSwitch.state and currentPeerID or nil
			
			login()
		else
			loginInvalidLabel.hidden = false
			logout()
		end

		saveConfig()
	end
end

addPizda(localization.documents).onTouch = function()
	local offset = 0

	local function getDocs()
		return methodRequest("docs.get?owner_id=" .. currentPeerID .. "&count=" .. config.loadCountDocs .. "&offset=" .. offset)
	end

	local docs = getDocs()
	if docs then
		contentContainer:removeChildren()

		local layout = contentContainer:addChild(GUI.layout(3, 1, contentContainer.width - 4, contentContainer.height, 1, 1))
		layout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_TOP)
		layout:setSpacing(1, 1, 1)
		layout:setMargin(1, 1, 0, 1)

		local container = layout:addChild(GUI.container(1, 1, layout.width, 3))
		addPanel(container, 0xFFFFFF)
		container:addChild(GUI.keyAndValue(3, 2, 0x3C3C3C, 0xA5A5A5, localization.documentsCount .. ": ", tostring(docs.count)))

		local button = container:addChild(GUI.adaptiveRoundedButton(1, 2, 1, 0, 0xA5A5A5, 0xFFFFFF, 0x2D2D2D, 0xE1E1E1, localization.documentsAdd))
		button.localX = container.width - button.width - 1

		local function addFromList(list)
			for i = 1, #list do
				local item = list[i]
				local container = layout:addChild(GUI.container(1, 1, layout.width, 4))
				addPanel(container, 0xFFFFFF)

				container:addChild(GUI.text(3, 2, 0x3C3C3C, item.title))
				container:addChild(GUI.text(3, 3, 0xA5A5A5, getAbbreviatedFileSize(item.size, 2) .. ", " .. os.date("%d.%m.%Y %H:%M", item.date)))
			end
		end
		
		addFromList(docs.items)

		addScrollEventHandler(layout, true, function()
			offset = offset + config.loadCountDocs
			local newDocs = getDocs()
			if newDocs then
				addFromList(newDocs.items)
			end
		end)
	end
end

addPizda(localization.settings).onTouch = function()
	contentContainer:removeChildren()

	local layout = contentContainer:addChild(GUI.layout(1, 1, contentContainer.width, contentContainer.height, 1, 1))

	local function addSlider(...)
		local slider = layout:addChild(GUI.slider(1, 1, 36, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xA5A5A5, ...))
		slider.height = 2
		slider.roundValues = true

		return slider
	end

	local function addYobaSlider(min, max, field)
		local slider = addSlider(min, max, config[field], false, localization[field] .. ": ", "")
		slider.onValueChanged = function()
			config[field] = math.round(slider.value)
			saveConfig()
		end
	end

	addYobaSlider(2, 50, "loadCountConversations")
	addYobaSlider(2, 50, "loadCountMessages")
	addYobaSlider(2, 50, "loadCountFriends")
	addYobaSlider(2, 50, "loadCountNews")
	addYobaSlider(2, 50, "loadCountWall")
	addYobaSlider(2, 50, "loadCountDocs")
	addYobaSlider(2, 10, "scrollSpeed")
end

addPizda(localization.exit).onTouch = function()
	logout()
	saveConfig()
end

window.onResize = function(width, height)
	loginContainer.width, loginContainer.height = width, height
	loginPanel.width, loginPanel.height = loginContainer.width, loginContainer.height
	loginLayout.width, loginLayout.height = loginContainer.width, loginContainer.height

	leftPanel.width, leftPanel.height = maxPizdaLength + localization.leftBarOffset, height
	leftLayout.width, leftLayout.height = leftPanel.width, leftPanel.height - 2
	progressIndicator.localX, progressIndicator.localY = math.floor(leftPanel.width / 2 - 1), leftPanel.height - progressIndicator.height + 1

	for i = 1, #leftLayout.children do
		leftLayout.children[i].width = leftLayout.width
	end

	window.backgroundPanel.localX, window.backgroundPanel.width, window.backgroundPanel.height = leftPanel.width + 1, width - leftPanel.width, height
	contentContainer.localX, contentContainer.width, contentContainer.height = window.backgroundPanel.localX, window.backgroundPanel.width, window.backgroundPanel.height

	if lastPizda then
		lastPizda:select()
	end
end

--------------------------------------------------------------------------------

currentAccessToken = config.accessToken
currentPeerID = config.peerID

window.actionButtons.localX = 3
window.actionButtons:moveToFront()

window:resize(window.width, window.height)
login()
