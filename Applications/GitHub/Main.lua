
local computer = require("computer")
local component = require("component")
local GUI = require("GUI")
local buffer = require("doubleBuffering")
local fs = require("filesystem")
local web = require("web")
local json = require("json")
local color = require("color")
local image = require("image")
local base64 = require("base64")
local unicode = require("unicode")
local MineOSInterface = require("MineOSInterface")
local MineOSPaths = require("MineOSPaths")

--------------------------------------------------------------------------------

local user
local configPath = MineOSPaths.applicationData .. "/GitHub/Config.cfg"
local config = {
	avatarColors = {
		[11760002] = 0x3C3C3C,
	}
}

local function saveConfig()
	table.toFile(configPath, config)
end

if fs.exists(configPath) then
	config = table.fromFile(configPath)
end

local addUserShit

--------------------------------------------------------------------------------

local mainContainer, window = MineOSInterface.addWindow(GUI.tabbedWindow(1, 1, 108, 33))

local titlePanel = window:addChild(GUI.panel(1, 1, window.width, 3, 0x2D2D2D))
window.tabBar:moveToFront()
window.actionButtons:moveToFront()

window.backgroundPanel.colors.background = 0xF0F0F0

window.tabBar:addItem("Repositories")
window.tabBar:addItem("Gists")
window.tabBar:addItem("Followers")
window.tabBar:addItem("Following")

local searchInput = window:addChild(GUI.input(9, 2, 14, 1, 0x3C3C3C, 0xB4B4B4, 0x696969, 0x3C3C3C, 0xE1E1E1, "", "Search…"))

local progressIndicator = window:addChild(GUI.progressIndicator(1, 1, 0x1E1E1E, 0x99FF80, 0x00B640))

local userContainer = window:addChild(GUI.container(3, 5, 20, 1))
local contentContainer = window:addChild(GUI.container(userContainer.localX + userContainer.width + 2, 4, 1, 1))

local function request(api)
	local url = "https://api.github.com/" .. api
	-- GUI.alert(url)

	local data = ""
	local success, reason = web.rawRequest(
		url,
		nil,
		{
			["User-Agent"]="Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:42.0) Gecko/20100101 Firefox/42.0",
			["Authorization"]="Basic " .. config.authorization
		},
		function(chunk)
			data = data .. chunk

			mainContainer:drawOnScreen()
			progressIndicator:roll()
		end,
		math.huge
	)

	if success then
		return json:decode(data)
	else
		return false, "API request failed: " .. tostring(reason)
	end
end

local function avatarDraw(self)
	local textColor = 0xFFFFFF - self.color
	buffer.drawRectangle(self.x, self.y, self.width, self.height, self.color, textColor, " ")
	buffer.drawText(math.floor(self.x + self.width / 2 - unicode.len(self.text) / 2), math.floor(self.y + self.height / 2), textColor, self.text)
end

local function newAvatar(x, y, width, height, id, name)
	local self = GUI.object(x, y, width, height)

	local shortcut = ""
	for part in name:gmatch("[^%s]+") do
		shortcut = shortcut .. unicode.upper(unicode.sub(part, 1, 1))
	end

	self.text = #shortcut > 0 and shortcut or unicode.upper(unicode.sub(name, 1, 1))
	self.draw = avatarDraw
	self.color = config.avatarColors[id]
	if not self.color then
		config.avatarColors[id] = color.HSBToInteger(math.random(0, 360), math.random(100) / 100, 1)
		saveConfig()
	end

	return self
end

local function repositoryGUI(repositoryName, branches)
	progressIndicator.active = true

	local reason
	if not branches then
		branches, reason = request("repos/" .. user.login .. "/" .. repositoryName .. "/branches")
		if not branches then
			GUI.alert(reason)

			progressIndicator.active = false
			mainContainer:drawOnScreen()
			return
		end
	end

	contentContainer:removeChildren()

	local path = ""

	local branchesComboBox = contentContainer:addChild(GUI.comboBox(1, 2, 14, 1, 0xE1E1E1, 0x2D2D2D, 0xC3C3C3, 0x787878))

	local pathLayout = contentContainer:addChild(GUI.layout(branchesComboBox.localX + branchesComboBox.width + 2, 2, contentContainer.width, 10, 1, 1))
	pathLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_TOP)
	pathLayout:setDirection(1, 1, GUI.DIRECTION_HORIZONTAL)
	pathLayout:setSpacing(1, 1, 0)

	for i = 1, #branches do
		branchesComboBox:addItem(branches[i].name)
	end

	local previewContainer = contentContainer:addChild(GUI.container(1, 4, contentContainer.width - 2, contentContainer.height - 3))

	local fillList, fillPath, fillCode

	fillList = function()
		progressIndicator.active = true

		local result, reason = request("repos/" .. user.login .. "/" .. repositoryName .. "/contents/" .. path .. "?ref=" .. branchesComboBox:getItem(branchesComboBox.selectedItem).text)
		if result then
			if result.type == "file" then
				local lines = {}
				for line in base64.decode(result.content:gsub("\r\n", "\n")):gmatch("[^\n]+") do
					line = line:gsub("\t", "  ")
					table.insert(lines, line)
				end

				local codeView = previewContainer:addChild(GUI.codeView(1, 1, previewContainer.width, previewContainer.height, 1, 1, 1, {}, {}, GUI.LUA_SYNTAX_PATTERNS, GUI.LUA_SYNTAX_COLOR_SCHEME, fs.extension(result.name) == ".lua", lines))
				
			else
				-- Sort files alphabetically
				local files = {}
				local i = 1
				while i <= #result do
					if result[i].type ~= "dir" then
						table.insert(files, result[i])
						table.remove(result, i)
					else
						i = i + 1
					end
				end

				table.sort(files, function(a, b) return unicode.lower(a.name) < unicode.lower(b.name) end)

				i = 1
				while i <= #files do
					table.insert(result, files[i])
					table.remove(files, i)
				end

				-- Fill files container
				local function hyperlinkDraw(self)
					buffer.drawRectangle(self.x, self.y, self.width, self.height, self.pressed and self.pressedColor or self.backgroundColor, self.textColor, " ")
					buffer.drawText(self.x + 2, math.floor(self.y + self.height / 2), self.textColor, (self.node.type == "dir" and "■ " or "□ ") .. self.node.name)
				end

				local function hyperlinkEventHandler(mainContainer, self, e1)
					if e1 == "touch" then
						self.pressed = true
						mainContainer:drawOnScreen()
						
						-- if self.node.type == "dir" then
							path = path .. web.encode(self.node.name) .. "/"
							fillPath()
							fillList()
						-- else
							
						-- end
					end
				end

				local function newHyperlink(x, y, width, height, backgroundColor, pressedColor, textColor, node)
					local object = GUI.object(x, y, width, height)
					
					object.pressed = false
					object.backgroundColor = backgroundColor
					object.pressedColor = pressedColor
					object.textColor = textColor
					object.draw = hyperlinkDraw
					object.eventHandler = hyperlinkEventHandler
					object.node = node

					return object
				end

				previewContainer:removeChildren()

				local y, step = 1, false
				for i = 1, #result do
					local hyperlink = previewContainer:addChild(newHyperlink(1, y, previewContainer.width, 3, step and 0xD2D2D2 or 0xE1E1E1, 0xC3C3C3, result[i].type == "dir" and 0x3C3C3C or 0x787878, result[i]))
					
					y, step = y + hyperlink.height, not step
				end
			end
		else
			GUI.alert(reason)
		end

		progressIndicator.active = false
		mainContainer:drawOnScreen()
	end

	fillPath = function()
		pathLayout:removeChildren()

		pathLayout:addChild(GUI.button(1, 1, unicode.len(repositoryName), 1, nil, 0x9949BF, nil, 0x332480, repositoryName)).onTouch = function()
			path = ""
			fillPath()
			fillList()
		end

		pathLayout:addChild(GUI.text(1, 1, 0xC3C3C3, "/"))

		local segments = fs.segments(path)
		for i = 1, #segments - 1 do
			pathLayout:addChild(GUI.button(1, 1, unicode.len(segments[i]), 1, nil, 0x9949BF, nil, 0x332480, segments[i])).onTouch = function()
				path = table.concat(segments, "/", 1, i) .. "/"
				fillPath()
				fillList()
			end
			pathLayout:addChild(GUI.text(1, 1, 0xC3C3C3, "/"))
		end

		if #segments > 0 then
			pathLayout:addChild(GUI.text(1, 1, 0x787878, segments[#segments]))
		end
	end

	branchesComboBox.onItemSelected = function()
		
	end

	fillPath()
	fillList()
end

local function repositoryDraw(self)
	buffer.drawRectangle(self.x, self.y, self.width, self.height, self.pressed and 0xE1E1E1 or 0xFFFFFF, 0x969696, " ")
	buffer.drawText(self.x + 2, self.y + 1, 0x004980, self.name)
	buffer.drawText(self.x + 2, self.y + 3, 0x969696, self.lines[1])
	buffer.drawText(self.x + 2, self.y + 4, 0x969696, self.lines[2])
	buffer.drawText(self.x + 2, self.y + 6, 0x3C3C3C, self.stats)
end

local function repositoryEventHandler(mainContainer, self, e1)
	if e1 == "touch" then
		self.pressed = true
		mainContainer:drawOnScreen()

		repositoryGUI(self.name)
	end
end

local function newRepository(x, y, width, repository)
	local self = GUI.object(x, y, width, 8)
	
	self.pressed = false
	self.name = repository.name

	self.lines = string.wrap(repository.description or "No description provided", width - 4)
	if self.lines[2] then
		self.lines[2] = string.limit(table.concat(self.lines, " ", 2), width - 4)
	end
	
	self.stats = (repository.language and "• " .. repository.language .. "   " or "") .. "* " .. repository.stargazers_count .. "   # " .. repository.forks_count
	
	self.draw = repositoryDraw
	self.eventHandler = repositoryEventHandler

	return self
end

local function repositoriesGUI(forks, page)
	local startX, startY = 1, 2
	local width = 40
	local perHeight = math.floor((contentContainer.height - 3) / 9)
	local perWidth = math.floor((contentContainer.width - startX) / width)
	local perPage = perWidth * perHeight
	
	progressIndicator.active = true

	local result, reason = request("users/" .. user.login .. "/repos?page=" .. page .. "&per_page=" .. perPage .. "&sort=updated")
	if result then
		contentContainer:removeChildren()

		local x, y, maxHeightPerLine = startX, startY, 0
		for i = 1, math.min(#result, perPage) do
			-- if forks and result[i].fork or not forks and not result[i].fork then
				local repository = contentContainer:addChild(newRepository(x, y, width, result[i]))
				maxHeightPerLine = math.max(maxHeightPerLine, repository.height)

				x = x + repository.width + 2
				if x > contentContainer.width - 2 then
					x, y = startX, y + maxHeightPerLine + 1
					maxHeightPerLine = 0
				end
			-- end
		end
	else
		GUI.alert(reason)
	end

	progressIndicator.active = false
	mainContainer:drawOnScreen()
end

local function loginGUI()
	local loginContainer = window:addChild(GUI.container(1, 1, window.width, window.height))
	window.actionButtons:moveToFront()
	
	loginContainer:addChild(GUI.panel(1, 1, loginContainer.width, loginContainer.height, 0xF0F0F0))

	local layout = loginContainer:addChild(GUI.layout(1, 1, loginContainer.width, loginContainer.height, 1, 1))

	local try, again

	try = function()
		progressIndicator.active = true
		layout:removeChildren()
		
		layout:addChild(GUI.text(1, 1, 0x969696, "Logging in..."))
		mainContainer:drawOnScreen()

		local result, reason = request("users/" .. config.user)
		if result and result.id then
			loginContainer:remove()

			user = result
			addUserShit()
			repositoriesGUI(false, 1)
		else
			GUI.alert("Incorrect login or password")
			user = nil
			config.authorization = nil
			saveConfig()

			again()
		end

		progressIndicator.active = false
		mainContainer:drawOnScreen()
	end

	again = function()
		layout:removeChildren()

		local userInput = layout:addChild(GUI.input(1, 1, 26, 3, 0xE1E1E1, 0x787878, 0xB4B4B4, 0xE1E1E1, 0x2D2D2D, config.user or "", "Username"))
		local passwordInput = layout:addChild(GUI.input(1, 1, 26, 3, 0xE1E1E1, 0x787878, 0xB4B4B4, 0xE1E1E1, 0x2D2D2D, "", "Password", false, "*"))
		local submitButton = layout:addChild(GUI.button(1, 1, 26, 3, 0xC3C3C3, 0xFFFFFF, 0x969696, 0xFFFFFF, "Login"))

		submitButton.onTouch = function()
			config.user = userInput.text
			config.authorization = base64.encode(userInput.text .. ":" .. passwordInput.text)
			saveConfig()

			try()
		end

		mainContainer:drawOnScreen()
	end

	if config.authorization then
		try()
	else
		again()
	end
end

addUserShit = function()
	userContainer:removeChildren()

	local y = 1

	local avatar = userContainer:addChild(newAvatar(1, y, userContainer.width, userContainer.width / 2 - 1, user.id, user.name or user.login))
	y = y + avatar.height + 1

	userContainer:addChild(GUI.text(1, y, 0x2D2D2D, user.login))
	y = y + 2

	if user.name then
		userContainer:addChild(GUI.text(1, y - 1, 0x969696, user.name))
		y = y + 1
	end

	if user.bio then
		local lines = string.wrap(user.bio, userContainer.width)
		local textBox = userContainer:addChild(GUI.textBox(1, y, userContainer.width, #lines, nil, 0x969696, lines, 1))
		textBox.eventHandler = nil
		y = y + #lines + 1
	end

	userContainer:addChild(GUI.roundedButton(2, y, userContainer.width - 2, 1, 0xB4B4B4, 0xFFFFFF, 0x969696, 0xFFFFFF, "Logout")).onTouch = function()
		config.authorization = nil
		saveConfig()

		loginGUI()
	end
end

local function calculateSizes()	
	userContainer.height = window.height - 4
	contentContainer.width, contentContainer.height = window.width - userContainer.width - 4, window.height - 3
	progressIndicator.localX = window.width - progressIndicator.width

	titlePanel.width = window.width
	window.tabBar.width = window.width - progressIndicator.width - window.actionButtons.width - searchInput.width - 8
	window.tabBar.localX = searchInput.localX + searchInput.width + 2
end

calculateSizes()
loginGUI()
