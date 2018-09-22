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

local VKAPIVersion = 5.58
local accessToken

local config = {avatars = {
	[7799889] = 0xFFFFFF,
}}

local configPath = MineOSPaths.applicationData .. "VK Messenger/Config.cfg"
if fs.exists(configPath) then
	config = table.fromFile(configPath)
end

local function saveConfig()
	table.toFile(configPath, config)
end

local scriptDirectory = MineOSCore.getCurrentScriptDirectory()
local localization = MineOSCore.getLocalization(scriptDirectory .. "Localizations/")

--------------------------------------------------------------------------------

local mainContainer, window = MineOSInterface.addWindow(GUI.filledWindow(1, 1, 90, 30, 0xF0F0F0))

local conversationPanel = window:addChild(GUI.panel(1, 1, 25, 1, 0x2D2D2D))
local conversationsLayout = window:addChild(GUI.layout(1, 4, conversationPanel.width, 1, 1, 1))
conversationsLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_TOP)
conversationsLayout:setSpacing(1, 1, 1)
conversationsLayout:setMargin(1, 1, 0, 0)

local loginContainer = window:addChild(GUI.container(1, 1, 1, 1))
local loginPanel = loginContainer:addChild(GUI.panel(1, 1, loginContainer.width, loginContainer.height, 0x002440))
local loginLayout = loginContainer:addChild(GUI.layout(1, 1, loginContainer.width, loginContainer.height, 1, 1))
local loginLogo = loginLayout:addChild(GUI.image(1, 1, image.load(scriptDirectory .. "Logo.pic")))
loginLogo.height = loginLogo.height + 1
local loginUsernameInput = loginLayout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x787878, 0xA5A5A5, 0xE1E1E1, 0x3C3C3C, config.username or "", localization.username))
local loginPasswordInput = loginLayout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x787878, 0xA5A5A5, 0xE1E1E1, 0x3C3C3C, config.password or "", localization.password, true, "•"))
local loginButton = loginLayout:addChild(GUI.button(1, 1, 36, 3, 0x004980, 0xE1E1E1, 0xE1E1E1, 0x3C3C3C, localization.login))
loginButton.colors.disabled = {
	background = 0x666D80,
	text = 0x969696,
}
local loginSaveSwitch = loginLayout:addChild(GUI.switchAndLabel(1, 1, 36, 6, 0x66DB80, 0x1E1E1E, 0xFFFFFF, 0xE1E1E1, localization.saveLogin, true)).switch
local loginInvalidLabel = loginLayout:addChild(GUI.label(1, 1, 36, 1, 0xFF4940, localization.invalidPassword))
loginInvalidLabel.hidden = true

local function request(url, postData)
	local result, reason = web.request(url, postData, {
		["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:42.0) Gecko/20100101 Firefox/42.0"
	})

	if result then
		return json:decode(result)
	else
		GUI.alert("Failed to perform API request: " .. tostring(reason))
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

local function loginRequest(username, password)
	local result, reason = request("https://oauth.vk.com/token?grant_type=password&client_id=3697615&client_secret=AlVXZFMUqyrnABp8ncuU&username=" .. username .. "&password=" .. password .. "&v=" .. VKAPIVersion)
	if result then
		if result.access_token then
			return result.access_token
		end
	end
end

local function methodRequest(method, ...)
	return responseRequest("https://api.vk.com/method/" .. method .. "?" .. table.concat({...}, "&") .. "&access_token=" .. accessToken .. "&v=" .. VKAPIVersion)
end

local function truncateEmoji(text)
	text = text:gsub("&#%d+;", ":)")
	return text
end

local function conversationDraw(object)
	local color1, color2 = 0xF0F0F0, 0xA5A5A5
	if object.selected then
		color1, color2 = 0x3C3C3C, 0x787878
		buffer.drawText(object.x, object.y - 1, 0xE1E1E1, string.rep("▄", object.width))
		buffer.drawRectangle(object.x, object.y, object.width, object.height, 0xE1E1E1, color2, " ")
		buffer.drawText(object.x, object.y + 1, 0xE1E1E1, string.rep("▀", object.width))
	end


	local avatarTextColor = 0xFFFFFF - object.avatarColor
	buffer.drawRectangle(object.x + 1, object.y, 4, 2, object.avatarColor, avatarTextColor, " ")
	buffer.drawText(object.x + 2, object.y, avatarTextColor, object.shortcut)

	buffer.drawText(object.x + 6, object.y, color1, object.name)
	buffer.drawText(object.x + 6, object.y + 1, color2, truncateEmoji(object.message))
end

local function updateConversations()
	local result = methodRequest("messages.getConversations", "offset=0", "count=20", "filter=all", "extended=1", "fields=first_name,last_name,online,id")
	if result then
		table.toFile("/test.lua", result)
		conversationsLayout:removeChildren()

		local function getEblo(where, id)
			for i = 1, #where do
				if where[i].id == id then
					return where[i]
				end
			end
		end

		for i = 1, #result.items do
			local item = result.items[i]

			config.avatars[item.conversation.peer.id] = config.avatars[item.conversation.peer.id] or color.HSBToInteger(math.random(360), 1, 1)

			local object = conversationsLayout:addChild(GUI.object(1, 1, conversationsLayout.width, 2))
			object.draw = conversationDraw
			object.message = item.last_message.text

			object.out = item.last_message.out
			object.avatarColor = config.avatars[item.conversation.peer.id]

			if item.conversation.peer.type == "chat" then
				object.name = item.conversation.chat_settings.title
			elseif item.conversation.peer.type == "group" then
				local eblo = getEblo(result.groups, -item.conversation.peer.id)
				if eblo then
					object.name = eblo.name
				else
					object.name = "Eblo group"
				end
			elseif item.conversation.peer.type == "user" then
				local eblo = getEblo(result.profiles, item.conversation.peer.id)
				if eblo then
					object.name = eblo.first_name .. " " .. eblo.last_name
				else
					object.name = "Eblo user"
				end
			else
				object.name = "Eblo type unknown"
			end

			object.shortcut = object.name:sub(1, 2)
		end

		mainContainer:drawOnScreen()
		saveConfig()
	end
end

loginUsernameInput.onInputFinished = function()
	loginButton.disabled = #loginUsernameInput.text == 0 or #loginPasswordInput.text == 0
	mainContainer:drawOnScreen()
end
loginPasswordInput.onInputFinished = loginUsernameInput.onInputFinished
loginButton.onTouch = function()
	accessToken = loginRequest(loginUsernameInput.text, loginPasswordInput.text)
	
	if accessToken then
		loginContainer:remove()

		if loginSaveSwitch.state then
			config.username, config.password = loginUsernameInput.text, loginPasswordInput.text
		else
			config.username, config.password = nil, nil
		end

		updateConversations()
	else
		loginInvalidLabel.hidden = false
	end

	mainContainer:drawOnScreen()
end

window.onResize = function(width, height)
	if not accessToken then
		loginContainer.width, loginContainer.height = width, height
		loginPanel.width, loginPanel.height = loginContainer.width, loginContainer.height
		loginLayout.width, loginLayout.height = loginContainer.width, loginContainer.height
	end

	conversationPanel.height = height
	conversationsLayout.height = conversationPanel.height - 3
	window.backgroundPanel.localX, window.backgroundPanel.width, window.backgroundPanel.height = conversationPanel.width + 1, width - conversationPanel.width, height
end

window.actionButtons:moveToFront()
window:resize(window.width, window.height)

loginUsernameInput.onInputFinished()
