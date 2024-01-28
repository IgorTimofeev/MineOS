
local GUI = require("GUI")
local screen = require("Screen")
local filesystem = require("Filesystem")
local event = require("Event")
local system = require("System")
local paths = require("Paths")
local network = require("Network")
local text = require("Text")

local args, options = system.parseArguments(...)

--------------------------------------------------------------------------------

local userSettings = system.getUserSettings()
local localization = system.getSystemLocalization()

local FTPMountPath = paths.system.mounts .. "FTP/"
local configPath = paths.user.applicationData .. "Finder/Config.cfg"
local config = {
	favourites = {
		{ name = "Root", path = "/" },
		{ name = "Desktop", path = paths.user.desktop },
		{ name = "Applications", path = paths.system.applications },
		{ name = "Wallpapers", path = paths.system.wallpapers },
		{ name = "Libraries", path = paths.system.libraries },
		{ name = "User", path = paths.user.home },
		{ name = "Trash", path = paths.user.trash },
	},
	sidebarWidth = 20,
	gridMode = false,
}

if filesystem.exists(configPath) then
	config = filesystem.readTable(configPath)
end

local sidebarTitleColor = 0xC3C3C3
local sidebarItemColor = 0x5A5A5A

local pathHistory = {}
local pathHistoryCurrent = 0

--------------------------------------------------------------------------------

local windowsContainer = system.getWindowsContainer()

local workspace, window, menu = system.addWindow(GUI.filledWindow(
	1,
	1,
	math.min(100, windowsContainer.width),
	math.min(26, windowsContainer.height),
	0xF0F0F0
))

local titlePanel = window:addChild(GUI.panel(1, 1, 1, 3, 0x2D2D2D))

local prevButton = window:addChild(GUI.adaptiveButton(9, 2, 1, 0, 0x3C3C3C, 0xC3C3C3, 0xE1E1E1, 0x3C3C3C, "<"))
prevButton.colors.disabled.background = 0x4B4B4B
prevButton.colors.disabled.text = 0xA5A5A5

local nextButton = window:addChild(GUI.adaptiveButton(prevButton.localX  + prevButton.width + 1, 2, 1, 0, 0x3C3C3C, 0xC3C3C3, 0xE1E1E1, 0x3C3C3C, ">"))
nextButton.colors.disabled = prevButton.colors.disabled

local modeList = window:addChild(GUI.list(nextButton.localX + nextButton.width + 2, 2, 10, 1, 2, 0, 0x3C3C3C, 0xE1E1E1, 0x4B4B4B, 0xE1E1E1, 0xE1E1E1, 0x4B4B4B, true))
modeList:setDirection(GUI.DIRECTION_HORIZONTAL)

local FTPButton = window:addChild(GUI.adaptiveButton(modeList.localX + modeList.width + 2, 2, 1, 0, 0x3C3C3C, 0xC3C3C3, 0xE1E1E1, 0x3C3C3C, "FTP"))
FTPButton.colors.disabled = prevButton.colors.disabled
FTPButton.disabled = not network.internetProxy

local sidebarContainer = window:addChild(GUI.container(1, 4, config.sidebarWidth, 1))

local sidebarPanel = system.addBlurredOrDefaultPanel(sidebarContainer, 1, 1, 1, 1)

local sidebarItemsLayout = sidebarContainer:addChild(GUI.layout(1, 1, 1, 1, 1, 1))
sidebarItemsLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_TOP)
sidebarItemsLayout:setSpacing(1, 1, 0)
sidebarItemsLayout:setMargin(1, 1, 0, 0)

local searchInput = window:addChild(GUI.input(1, 2, 16, 1, 0x3C3C3C, 0xC3C3C3, 0x878787, 0x4B4B4B, 0xE1E1E1, nil, localization.search, true))

local iconField

local statusContainer = window:addChild(GUI.container(FTPButton.localX + FTPButton.width + 2, 2, 1, 1))
local statusPanel = statusContainer:addChild(GUI.panel(1, 1, 1, 1, 0x3C3C3C))

local gotoButton = window:addChild(GUI.button(1, 2, 3, 1, 0x4B4B4B, 0xC3C3C3, 0xE1E1E1, 0x3C3C3C, "→"))

local resizer = window:addChild(GUI.resizer(1, 1, 3, 4, 0xC3C3C3, 0x0))

window.actionButtons:moveToFront()

--------------------------------------------------------------------------------

local function saveConfig()
	filesystem.writeTable(configPath, config)
end

local function getVerticalScroll()
	return config.gridMode and iconField.yOffset or iconField:getVerticalScroll()
end

local function setVerticalScroll(value)
	if config.gridMode then
		local iconsCount = #iconField.children - 1
		local rows = math.ceil((iconsCount - 1) / iconField.iconCount.horizontal)
		local minimumOffset = (rows - 1) * (userSettings.iconHeight + userSettings.iconVerticalSpace) - userSettings.iconVerticalSpace
		
		value = math.max(-minimumOffset + 1, math.min(iconField.initialYOffset, value))

		local delta = iconField.yOffset - value
		iconField.yOffset = value

		if iconsCount < 2 then
			return
		end

		local child

		for i = 2, iconsCount do
			child = iconField.children[i]

			if child ~= iconField.backgroundObject then
				child.localY = child.localY - delta
			end
		end
	else
		iconField:setVerticalScroll(value)
	end
end

local function updateFileListAndDraw()
	iconField:updateFileList()
	setVerticalScroll(config.gridMode and iconField.initialYOffset or 0)
	workspace:draw()
end

local function pathHistoryButtonsUpdate()
	prevButton.disabled = pathHistoryCurrent <= 1
	nextButton.disabled = pathHistoryCurrent >= #pathHistory
end

local function prevOrNextpath(next)
	if next then
		if pathHistoryCurrent < #pathHistory then
			pathHistoryCurrent = pathHistoryCurrent + 1
		end
	else
		if pathHistoryCurrent > 1 then
			pathHistoryCurrent = pathHistoryCurrent - 1
		end
	end

	pathHistoryButtonsUpdate()
	iconField:setPath(pathHistory[pathHistoryCurrent])
	
	updateFileListAndDraw()
end

local function addPath(path)
	pathHistoryCurrent = pathHistoryCurrent + 1
	
	table.insert(pathHistory, pathHistoryCurrent, path)
	
	for i = pathHistoryCurrent + 1, #pathHistory do
		pathHistory[i] = nil
	end

	pathHistoryButtonsUpdate()
	searchInput.text = ""
	iconField:setPath(path)
end

local function sidebarItemDraw(object)
	local textColor, limit = object.textColor, object.width - 2
	
	if object.path == iconField.path then
		textColor = 0xB4B4B4

		screen.drawRectangle(object.x, object.y, object.width, 1, 0x2D2D2D, textColor, " ")
		screen.drawText(object.x, object.y, 0xFFDB80, "▎ ")

		if object.onRemove then
			limit = limit - 2
			screen.drawText(object.x + object.width - 2, object.y, 0x3C3C3C, "x")
		end
	end
	
	screen.drawText(object.x + 1, object.y, textColor, text.limit(object.text, limit, "center"))
end

local function sidebarItemEventHandler(workspace, object, e1, e2, e3, ...)
	if e1 == "touch" then
		if object.onRemove and math.ceil(e3) == object.x + object.width - 2 then
			object.onRemove()
		
		elseif object.onTouch then
			object.onTouch(e1, e2, e3, ...)
		end
	end
end

local function addSidebarObject(textColor, text, path)
	local object = sidebarItemsLayout:addChild(GUI.object(1, 1, sidebarItemsLayout.width, 1))
	
	object.textColor = textColor
	object.text = text
	object.path = path

	object.draw = sidebarItemDraw
	object.eventHandler = sidebarItemEventHandler

	return object
end

local function addSidebarTitle(...)
	return addSidebarObject(sidebarTitleColor, ...)
end

local function addSidebarItem(...)
	return addSidebarObject(sidebarItemColor, ...)
end

local function addSidebarSeparator()
	return sidebarItemsLayout:addChild(GUI.object(1, 1, sidebarItemsLayout.width, 1))
end

local function onFavouriteTouch(path)
	addPath(path)
	updateFileListAndDraw()
end

local openFTP, updateSidebar

openFTP = function(...)
	local mountPath = FTPMountPath .. network.getFTPProxyName(...) .. "/"
	
	addPath(mountPath)
	workspace:draw()

	local proxy, reason = network.connectToFTP(...)
	if proxy then
		network.unmountFTPs()
		filesystem.mount(proxy, mountPath)
		updateSidebar()
		updateFileListAndDraw()
	else
		GUI.alert(reason)
	end
end

updateSidebar = function()
	sidebarItemsLayout:removeChildren()

	-- Favourites
	addSidebarTitle(localization.favourite)
	
	for i = 1, #config.favourites do
		local object = addSidebarItem(" " .. filesystem.name(config.favourites[i].name), config.favourites[i].path)
		
		object.onTouch = function(e1, e2, e3)
			onFavouriteTouch(config.favourites[i].path)
		end

		object.onRemove = function()
			table.remove(config.favourites, i)
			updateSidebar()
			workspace:draw()
			saveConfig()
		end
	end

	addSidebarSeparator()

	-- Modem connections
	local added = false
	for proxy, path in filesystem.mounts() do
		if proxy.networkModem then
			if not added then
				addSidebarTitle(localization.network)
				added = true
			end

			addSidebarItem(" " .. network.getModemProxyName(proxy), path).onTouch = function()
				addPath(path)
				updateFileListAndDraw()
			end
		end
	end

	if added then
		addSidebarSeparator()
	end

	-- FTP connections
	if network.internetProxy and #userSettings.networkFTPConnections > 0 then
		addSidebarTitle(localization.networkFTPConnections)
		
		for i = 1, #userSettings.networkFTPConnections do
			local connection = userSettings.networkFTPConnections[i]
			local name = network.getFTPProxyName(connection.address, connection.port, connection.user)
			
			local object = addSidebarItem(" " .. name, FTPMountPath .. name .. "/")
			
			object.onTouch = function(e1, e2, e3, e4, e5)
				openFTP(connection.address, connection.port, connection.user, connection.password)
			end

			object.onRemove = function()
				table.remove(userSettings.networkFTPConnections, i)
				updateSidebar()
				workspace:draw()
				system.saveUserSettings()
			end
		end

		addSidebarSeparator()
	end

	-- Mounts
	addSidebarTitle(localization.mounts)
	
	for proxy, path in filesystem.mounts() do
		if not proxy.networkModem and not proxy.networkFTP then
			if proxy ~= filesystem.getProxy() then
				addSidebarItem(" " .. (proxy.getLabel() or proxy.address), path).onTouch = function()
					onFavouriteTouch(path)
				end
			end
		end
	end
end

sidebarItemsLayout.eventHandler = function(workspace, object, e1, e2, e3, e4, e5)
	if e1 == "scroll" then
		local cell = sidebarItemsLayout.cells[1][1]
		local from = 0
		local to = -cell.childrenHeight + 1

		cell.verticalMargin = cell.verticalMargin + (e5 > 0 and 1 or -1)
		if cell.verticalMargin > from then
			cell.verticalMargin = from
		elseif cell.verticalMargin < to then
			cell.verticalMargin = to
		end

		workspace:draw()
	elseif e1 == "component_added" or e1 == "component_removed" then
		FTPButton.disabled = not network.internetProxy
		updateSidebar()
		workspace:draw()
	elseif e1 == "network" then
		if e2 == "updateProxyList" or e2 == "timeout" then
			updateSidebar()
			workspace:draw()
		end
	end
end

searchInput.onInputFinished = function()
	iconField.filenameMatcher = searchInput.text
	updateFileListAndDraw()
end

nextButton.onTouch = function()
	prevOrNextpath(true)
end

prevButton.onTouch = function()
	prevOrNextpath(false)
end

FTPButton.onTouch = function()
	local container = GUI.addBackgroundContainer(workspace, true, true, localization.networkFTPNewConnection)

	local ad, po, us, pa
	if #userSettings.networkFTPConnections > 0 then
		local la = userSettings.networkFTPConnections[#userSettings.networkFTPConnections]
		ad, po, us, pa = la.address, tostring(la.port), la.user, la.password
	end

	local addressInput = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0x969696, 0xE1E1E1, 0x2D2D2D, ad, localization.networkFTPAddress, true))
	local portInput = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0x969696, 0xE1E1E1, 0x2D2D2D, po, localization.networkFTPPort, true))
	local userInput = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0x969696, 0xE1E1E1, 0x2D2D2D, us, localization.networkFTPUser, true))
	local passwordInput = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0x969696, 0xE1E1E1, 0x2D2D2D, pa, localization.networkFTPPassword, true, "*"))
	container.layout:addChild(GUI.button(1, 1, 36, 3, 0x5A5A5A, 0xE1E1E1, 0x2D2D2D, 0xE1E1E1, "OK")).onTouch = function()
		container:remove()

		local port = tonumber(portInput.text)
		if port then
			local found = false
			for i = 1, #userSettings.networkFTPConnections do
				if
					userSettings.networkFTPConnections[i].address == addressInput.text and
					userSettings.networkFTPConnections[i].port == port and
					userSettings.networkFTPConnections[i].user == userInput.text and
					userSettings.networkFTPConnections[i].password == passwordInput.text
				then
					found = true
					break
				end
			end

			if not found then
				table.insert(userSettings.networkFTPConnections, {
					address = addressInput.text,
					port = port,
					user = userInput.text,
					password = passwordInput.text
				})
				system.saveUserSettings()

				updateSidebar()
				workspace:draw()

				openFTP(addressInput.text, port, userInput.text, passwordInput.text)
			end
		end
	end

	workspace:draw()
end

local function calculateSizes()
	sidebarContainer.height = window.height - 3
	
	sidebarPanel.width = sidebarContainer.width
	sidebarPanel.height = sidebarContainer.height
	
	sidebarItemsLayout.width = sidebarContainer.width
	sidebarItemsLayout.height = sidebarContainer.height
	for i = 1, #sidebarItemsLayout.children do
		sidebarItemsLayout.children[i].width = sidebarItemsLayout.width
	end

	resizer.localX = sidebarContainer.width
	resizer.localY = math.floor(4 + sidebarContainer.height / 2 - resizer.height / 2)

	window.backgroundPanel.width = window.width - sidebarContainer.width
	window.backgroundPanel.height = window.height - 3
	window.backgroundPanel.localX = sidebarContainer.width + 1
	window.backgroundPanel.localY = 4

	titlePanel.width = window.width
	searchInput.localX = window.width - searchInput.width - 1

	statusContainer.width = window.width - statusContainer.localX - searchInput.width - 6
	statusPanel.width = statusContainer.width

	gotoButton.localX = statusContainer.localX + statusContainer.width

	iconField.width = window.backgroundPanel.width
	iconField.height = window.height + 3
	iconField.localX = window.backgroundPanel.localX
end

local function updateIconField()
	local path

	if iconField then
		path = iconField.path
		iconField:remove()
	else
		path = paths.user.desktop
	end

	iconField = window:addChild(
		config.gridMode and
		system.gridIconField(
			1, 4, 1, 1, 2, 2, path,
			0x3C3C3C,
			0xC3C3C3,
			0x3C3C3C,
			0x696969,
			nil
		) or
		system.listIconField(
			1, 4, 1, 1, path,
			
			0xF0F0F0,

			0xFFFFFF,
			0x000000,
			
			nil,
			0x3C3C3C,
			
			0xE1E1E1,
			0x3C3C3C,

			0xCC2440,
			0xFFFFFF
		)
	)

	iconField.blockScreenEvents = true
	
	iconField.launchers.directory = function(icon)
		addPath(icon.path)
		updateFileListAndDraw()
	end

	iconField.launchers.showPackageContent = function(icon)
		addPath(icon.path)
		updateFileListAndDraw()
	end

	iconField.launchers.showContainingFolder = function(icon)
		addPath(filesystem.path(system.readShortcut(icon.path)))
		updateFileListAndDraw()
	end

	iconField.eventHandler = function(workspace, self, e1, e2, e3, e4, e5, ...)
		if e1 == "scroll" then
			setVerticalScroll(getVerticalScroll() + (config.gridMode and e5 * 2 or e5))

			workspace:draw()
		elseif e1 == "system" or e1 == "Finder" then
			if e2 == "updateFileList" then
				updateFileListAndDraw()
			
			elseif e2 == "updateFavourites" then
				if e3 then
					table.insert(config.favourites, e3)
				end

				saveConfig()
				updateSidebar()
				workspace:draw()
			end	
		end
	end

	local overrideUpdateFileList = iconField.updateFileList
	iconField.updateFileList = function(...)
		statusContainer:removeChildren(2)

		local x, path = 2, "/"

		local function addNode(text, path)
			statusContainer:addChild(GUI.adaptiveButton(x, 1, 0, 0, nil, 0xC3C3C3, nil, 0xFFFFFF, text)).onTouch = function()
				addPath(path)
				updateFileListAndDraw()
			end

			x = x + unicode.len(text)
		end

		addNode("root", "/")

		for node in iconField.path:gsub("/$", ""):gmatch("[^/]+") do
			statusContainer:addChild(GUI.text(x, 1, 0x696969, " ► "))
			x = x + 3
			
			path = path .. node .. "/"
			addNode(node, path)
		end

		if x > statusContainer.width then
			for i = 2, #statusContainer.children do
				statusContainer.children[i].localX = statusContainer.children[i].localX - (x - statusContainer.width)
			end
		end

		workspace:draw()
		overrideUpdateFileList(...)
	end

	resizer:moveToFront()
	calculateSizes()
end

gotoButton.onTouch = function()
	local input = window:addChild(GUI.input(statusContainer.localX, statusContainer.localY, statusContainer.width, 1, 0x4B4B4B, 0xC3C3C3, 0xC3C3C3, 0x4B4B4B, 0xC3C3C3, nil, nil))
	
	input.onInputFinished = function()
		input:remove()
		statusContainer.hidden = false
		input.text = ("/" .. input.text .. "/"):gsub("/+", "/")

		if filesystem.exists(input.text) and filesystem.isDirectory(input.text) then
			addPath(input.text)
			iconField:updateFileList()
		end

		workspace:draw()
	end

	statusContainer.hidden = true
	input:startInput()
end

local overrideMaximize = window.actionButtons.maximize.onTouch
window.actionButtons.maximize.onTouch = function()
	overrideMaximize()
end

window.actionButtons.close.onTouch = function()
	window:remove()
end

window.onResize = function(width, height)
	window.width = width
	window.height = height
	calculateSizes()
	workspace:draw()
end

window.onResizeFinished = function()
	updateFileListAndDraw()
end

resizer.onResize = function(deltaX)
	sidebarContainer.width = sidebarContainer.width + deltaX
	calculateSizes()

	workspace:draw()
end

resizer.onResizeFinished = function()
	updateFileListAndDraw()

	config.sidebarWidth = sidebarContainer.width
	saveConfig()
end

local function saveMode(gridMode)
	config.gridMode = gridMode
	updateIconField()
	updateFileListAndDraw()
	
	saveConfig()
end

modeList:addItem("☷").onTouch = function()
	saveMode(true)
end

modeList:addItem("☰").onTouch = function()
	saveMode(false)
end

--------------------------------------------------------------------------------

modeList.selectedItem = config.gridMode == nil and 2 or (config.gridMode and 1 or 2)
updateIconField()

if (options.o or options.open) and args[1] and filesystem.isDirectory(args[1]) then
	addPath(args[1])
else
	addPath("/")
end

updateSidebar()
window:resize(window.width, window.height)
