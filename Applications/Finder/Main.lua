
local GUI = require("GUI")
local buffer = require("doubleBuffering")
local computer = require("computer")
local filesystem = require("filesystem")
local event = require("event")
local unicode = require("unicode")
local MineOSCore = require("MineOSCore")
local MineOSPaths = require("MineOSPaths")
local MineOSNetwork = require("MineOSNetwork")
local MineOSInterface = require("MineOSInterface")

local args, options = require("shell").parse(...)

--------------------------------------------------------------------------------

local configPath = MineOSPaths.applicationData .. "Finder/Config.cfg"
local config = {
	favourites = {
		{ name = "Root", path = "/" },
		{ name = "Desktop", path = MineOSPaths.desktop },
		{ name = "Applications", path = MineOSPaths.applications },
		{ name = "Pictures", path = MineOSPaths.pictures },
		{ name = "System", path = MineOSPaths.system },
		{ name = "Libraries", path = "/lib/" },
		{ name = "Trash", path = MineOSPaths.trash },
	},
	sidebarWidth = 20,
}

if filesystem.exists(configPath) then
	config = table.fromFile(configPath)
end

local sidebarTitleColor = 0xC3C3C3
local sidebarItemColor = 0x696969

local iconFieldYOffset = 2
local scrollTimerID

local workpathHistory = {}
local workpathHistoryCurrent = 0

--------------------------------------------------------------------------------

local application, window, menu = MineOSInterface.addWindow(GUI.filledWindow(1, 1, 100, 26, 0xE1E1E1))

local titlePanel = window:addChild(GUI.panel(1, 1, 1, 3, 0x3C3C3C))

local prevButton = window:addChild(GUI.adaptiveRoundedButton(9, 2, 1, 0, 0x5A5A5A, 0xC3C3C3, 0xE1E1E1, 0x3C3C3C, "<"))
prevButton.colors.disabled.background = 0x4B4B4B
prevButton.colors.disabled.text = 0xA5A5A5

local nextButton = window:addChild(GUI.adaptiveRoundedButton(14, 2, 1, 0, 0x5A5A5A, 0xC3C3C3, 0xE1E1E1, 0x3C3C3C, ">"))
nextButton.colors.disabled = prevButton.colors.disabled

local FTPButton = window:addChild(GUI.adaptiveRoundedButton(nextButton.localX + nextButton.width + 2, 2, 1, 0, 0x5A5A5A, 0xC3C3C3, 0xE1E1E1, 0x3C3C3C, "FTP"))

FTPButton.colors.disabled = prevButton.colors.disabled
FTPButton.disabled = not MineOSNetwork.internetProxy

local sidebarContainer = window:addChild(GUI.container(1, 4, config.sidebarWidth, 1))
local sidebarPanel = sidebarContainer:addChild(GUI.object(1, 1, 1, 1, 0xFFFFFF))
sidebarPanel.draw = function(object)
	buffer.drawRectangle(object.x, object.y, object.width, object.height, 0x2D2D2D, sidebarItemColor, " ")
end

local itemsLayout = sidebarContainer:addChild(GUI.layout(1, 1, 1, 1, 1, 1))
itemsLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_TOP)
itemsLayout:setSpacing(1, 1, 0)
itemsLayout:setMargin(1, 1, 0, 0)

local searchInput = window:addChild(GUI.input(1, 2, 20, 1, 0x4B4B4B, 0xC3C3C3, 0x878787, 0x4B4B4B, 0xE1E1E1, nil, MineOSCore.localization.search, true))

local iconField = window:addChild(MineOSInterface.iconField(1, 4, 1, 1, 2, 2, 0x3C3C3C, 0x969696, MineOSPaths.desktop))

local scrollBar = window:addChild(GUI.scrollBar(1, 4, 1, 1, 0xC3C3C3, 0x4B4B4B, iconFieldYOffset, 1, 1, 1, 1, true))
scrollBar.eventHandler = nil

local statusContainer = window:addChild(GUI.container(FTPButton.localX + FTPButton.width + 2, 2, 1, 1))
local statusPanel = statusContainer:addChild(GUI.panel(1, 1, 1, 1, 0x4B4B4B))

local gotoButton = window:addChild(GUI.button(1, 2, 3, 1, 0x5A5A5A, 0xC3C3C3, 0xE1E1E1, 0x3C3C3C, "→"))

local resizer = window:addChild(GUI.resizer(1, 1, 3, 4, 0xC3C3C3, 0x0))

window.actionButtons:moveToFront()

--------------------------------------------------------------------------------

local function saveConfig()
	table.toFile(configPath, config)
end

local function updateFileListAndDraw()
	iconField:updateFileList()
	application:draw()
end

local function workpathHistoryButtonsUpdate()
	prevButton.disabled = workpathHistoryCurrent <= 1
	nextButton.disabled = workpathHistoryCurrent >= #workpathHistory
end

local function prevOrNextWorkpath(next)
	if next then
		if workpathHistoryCurrent < #workpathHistory then
			workpathHistoryCurrent = workpathHistoryCurrent + 1
		end
	else
		if workpathHistoryCurrent > 1 then
			workpathHistoryCurrent = workpathHistoryCurrent - 1
		end
	end

	workpathHistoryButtonsUpdate()
	iconField.yOffset = iconFieldYOffset
	iconField:setWorkpath(workpathHistory[workpathHistoryCurrent])
	
	updateFileListAndDraw()
end

local function addWorkpath(path)
	workpathHistoryCurrent = workpathHistoryCurrent + 1
	table.insert(workpathHistory, workpathHistoryCurrent, path)
	for i = workpathHistoryCurrent + 1, #workpathHistory do
		workpathHistory[i] = nil
	end

	workpathHistoryButtonsUpdate()
	searchInput.text = ""
	iconField.yOffset = iconFieldYOffset
	iconField:setWorkpath(path)
end

local function sidebarItemDraw(object)
	local textColor, limit = object.textColor, object.width - 2
	if object.path == iconField.workpath then
		textColor = 0x3C3C3C
		buffer.drawRectangle(object.x, object.y, object.width, 1, 0xE1E1E1, textColor, " ")

		if object.onRemove then
			limit = limit - 2
			buffer.drawText(object.x + object.width - 2, object.y, 0x969696, "x")
		end
	end
	
	buffer.drawText(object.x + 1, object.y, textColor, string.limit(object.text, limit, "center"))
end

local function sidebarItemEventHandler(application, object, e1, e2, e3, ...)
	if e1 == "touch" then
		if object.onRemove and e3 == object.x + object.width - 2 then
			object.onRemove()
		elseif object.onTouch then
			object.onTouch(e1, e2, e3, ...)
		end
	end
end

local function addSidebarObject(textColor, text, path)
	local object = itemsLayout:addChild(GUI.object(1, 1, itemsLayout.width, 1))
	
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
	return itemsLayout:addChild(GUI.object(1, 1, itemsLayout.width, 1))
end

local function onFavouriteTouch(path)
	if filesystem.exists(path) then
		addWorkpath(path)
		updateFileListAndDraw()
	else
		GUI.alert("Path doesn't exists: " .. path)
	end
end

local openFTP, updateSidebar

openFTP = function(...)
	local mountPath = MineOSNetwork.mountPaths.FTP .. MineOSNetwork.getFTPProxyName(...) .. "/"
	
	addWorkpath(mountPath)
	application:draw()

	local proxy, reason = MineOSNetwork.connectToFTP(...)
	if proxy then
		MineOSNetwork.umountFTPs()
		filesystem.mount(proxy, mountPath)
		updateSidebar()
		updateFileListAndDraw()
	else
		GUI.alert(reason)
	end
end

updateSidebar = function()
	itemsLayout:removeChildren()

	-- Favourites
	addSidebarTitle(MineOSCore.localization.favourite)
	
	for i = 1, #config.favourites do
		local object = addSidebarItem(" " .. filesystem.name(config.favourites[i].name), config.favourites[i].path)
		
		object.onTouch = function(e1, e2, e3)
			onFavouriteTouch(config.favourites[i].path)
		end

		object.onRemove = function()
			table.remove(config.favourites, i)
			updateSidebar()
			application:draw()
			saveConfig()
		end
	end

	addSidebarSeparator()

	-- Modem connections
	local added = false
	for proxy, path in filesystem.mounts() do
		if proxy.MineOSNetworkModem then
			if not added then
				addSidebarTitle(MineOSCore.localization.network)
				added = true
			end

			addSidebarItem(" " .. MineOSNetwork.getModemProxyName(proxy), path .. "/").onTouch = function()
				addWorkpath(path .. "/")
				updateFileListAndDraw()
			end
		end
	end

	if added then
		addSidebarSeparator()
	end

	-- FTP connections
	if MineOSNetwork.internetProxy and #MineOSCore.properties.FTPConnections > 0 then
		addSidebarTitle(MineOSCore.localization.networkFTPConnections)
		
		for i = 1, #MineOSCore.properties.FTPConnections do
			local connection = MineOSCore.properties.FTPConnections[i]
			local name = MineOSNetwork.getFTPProxyName(connection.address, connection.port, connection.user)
			local mountPath = MineOSNetwork.mountPaths.FTP .. name .. "/"

			local object = addSidebarItem(" " .. name, mountPath)
			
			object.onTouch = function(e1, e2, e3, e4, e5)
				openFTP(connection.address, connection.port, connection.user, connection.password)
			end

			object.onRemove = function()
				table.remove(MineOSCore.properties.FTPConnections, i)
				updateSidebar()
				application:draw()
				MineOSCore.saveProperties()
			end
		end

		addSidebarSeparator()
	end

	-- Mounts
	addSidebarTitle(MineOSCore.localization.mounts)
	
	for proxy, path in filesystem.mounts() do
		if path ~= "/" and not proxy.MineOSNetworkModem and not proxy.MineOSNetworkFTP then
			addSidebarItem(" " .. (proxy.getLabel() or filesystem.name(path)), path .. "/").onTouch = function()
				onFavouriteTouch(path .. "/")
			end
		end
	end
end

itemsLayout.eventHandler = function(application, object, e1, e2, e3, e4, e5)
	if e1 == "scroll" then
		local cell = itemsLayout.cells[1][1]
		local from = 0
		local to = -cell.childrenHeight + 1

		cell.verticalMargin = cell.verticalMargin + (e5 > 0 and 1 or -1)
		if cell.verticalMargin > from then
			cell.verticalMargin = from
		elseif cell.verticalMargin < to then
			cell.verticalMargin = to
		end

		application:draw()
	elseif e1 == "component_added" or e1 == "component_removed" then
		FTPButton.disabled = not MineOSNetwork.internetProxy
		updateSidebar()
		application:draw()
	elseif e1 == "MineOSNetwork" then
		if e2 == "updateProxyList" or e2 == "timeout" then
			updateSidebar()
			application:draw()
		end
	end
end

local function updateScrollBar()
	local shownFilesCount = #iconField.fileList - iconField.fromFile + 1
	
	local horizontalLines = math.ceil(shownFilesCount / iconField.iconCount.horizontal)
	local minimumOffset = 3 - (horizontalLines - 1) * (MineOSCore.properties.iconHeight + MineOSCore.properties.iconVerticalSpaceBetween) - MineOSCore.properties.iconVerticalSpaceBetween
	
	if iconField.yOffset > iconFieldYOffset then
		iconField.yOffset = iconFieldYOffset
	elseif iconField.yOffset < minimumOffset then
		iconField.yOffset = minimumOffset
	end

	if shownFilesCount > iconField.iconCount.total then
		scrollBar.hidden = false
		scrollBar.maximumValue = math.abs(minimumOffset)
		scrollBar.value = math.abs(iconField.yOffset - iconFieldYOffset)
	else
		scrollBar.hidden = true
	end
end

searchInput.onInputFinished = function()
	iconField.filenameMatcher = searchInput.text
	iconField.fromFile = 1
	iconField.yOffset = iconFieldYOffset

	updateFileListAndDraw()
end

nextButton.onTouch = function()
	prevOrNextWorkpath(true)
end

prevButton.onTouch = function()
	prevOrNextWorkpath(false)
end

FTPButton.onTouch = function()
	local container = MineOSInterface.addBackgroundContainer(application, MineOSCore.localization.networkFTPNewConnection)

	local ad, po, us, pa, la = "ftp.example.com", "21", "root", "1234"
	if #MineOSCore.properties.FTPConnections > 0 then
		local la = MineOSCore.properties.FTPConnections[#MineOSCore.properties.FTPConnections]
		ad, po, us, pa = la.address, tostring(la.port), la.user, la.password
	end

	local addressInput = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0x696969, 0xE1E1E1, 0x2D2D2D, ad, MineOSCore.localization.networkFTPAddress, true))
	local portInput = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0x696969, 0xE1E1E1, 0x2D2D2D, po, MineOSCore.localization.networkFTPPort, true))
	local userInput = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0x696969, 0xE1E1E1, 0x2D2D2D, us, MineOSCore.localization.networkFTPUser, true))
	local passwordInput = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0x696969, 0xE1E1E1, 0x2D2D2D, pa, MineOSCore.localization.networkFTPPassword, true, "*"))
	container.layout:addChild(GUI.button(1, 1, 36, 3, 0xA5A5A5, 0xFFFFFF, 0x2D2D2D, 0xE1E1E1, "OK")).onTouch = function()
		container:remove()

		local port = tonumber(portInput.text)
		if port then
			local found = false
			for i = 1, #MineOSCore.properties.FTPConnections do
				if
					MineOSCore.properties.FTPConnections[i].address == addressInput.text and
					MineOSCore.properties.FTPConnections[i].port == port and
					MineOSCore.properties.FTPConnections[i].user == userInput.text and
					MineOSCore.properties.FTPConnections[i].password == passwordInput.text
				then
					found = true
					break
				end
			end

			if not found then
				table.insert(MineOSCore.properties.FTPConnections, {
					address = addressInput.text,
					port = port,
					user = userInput.text,
					password = passwordInput.text
				})
				MineOSCore.saveProperties()

				updateSidebar()
				application:draw()

				openFTP(addressInput.text, port, userInput.text, passwordInput.text)
			end
		end
	end

	application:draw()
end

iconField.eventHandler = function(application, object, e1, e2, e3, e4, e5)
	if e1 == "scroll" then
		iconField.yOffset = iconField.yOffset + e5 * 2

		updateScrollBar()

		local delta = iconField.yOffset - iconField.iconsContainer.children[1].localY
		for i = 1, #iconField.iconsContainer.children do
			iconField.iconsContainer.children[i].localY = iconField.iconsContainer.children[i].localY + delta
		end

		application:draw()

		if scrollTimerID then
			event.cancel(scrollTimerID)
			scrollTimerID = nil
		end

		scrollTimerID = event.timer(0.3, function()
			computer.pushSignal("Finder", "updateFileList")
		end, 1)
	elseif e1 == "MineOSCore" or e1 == "Finder" then
		if e2 == "updateFileList" then
			if e1 == "MineOSCore" then
				iconField.yOffset = iconFieldYOffset
			end

			updateFileListAndDraw()
		elseif e2 == "updateFavourites" then
			if e3 then
				table.insert(config.favourites, e3)
			end

			saveConfig()
			updateSidebar()
			application:draw()
		end	
	end
end

iconField.launchers.directory = function(icon)
	addWorkpath(icon.path)
	updateFileListAndDraw()
end

iconField.launchers.showPackageContent = function(icon)
	addWorkpath(icon.path)
	updateFileListAndDraw()
end

iconField.launchers.showContainingFolder = function(icon)
	addWorkpath(filesystem.path(MineOSCore.readShortcut(icon.path)))
	updateFileListAndDraw()
end

local overrideUpdateFileList = iconField.updateFileList
iconField.updateFileList = function(...)
	statusContainer:removeChildren(2)

	local x, path = 2, "/"

	local function addNode(text, path)
		statusContainer:addChild(GUI.adaptiveButton(x, 1, 0, 0, nil, 0xB4B4B4, nil, 0xFFFFFF, text)).onTouch = function()
			addWorkpath(path)
			updateFileListAndDraw()
		end

		x = x + unicode.len(text)
	end

	addNode("root", "/")

	for node in iconField.workpath:gsub("/$", ""):gmatch("[^/]+") do
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

	application:draw()
	overrideUpdateFileList(...)
	updateScrollBar()
end

gotoButton.onTouch = function()
	local input = window:addChild(GUI.input(statusContainer.localX, statusContainer.localY, statusContainer.width, 1, 0x4B4B4B, 0xC3C3C3, 0xC3C3C3, 0x4B4B4B, 0xC3C3C3, nil, nil))
	
	input.onInputFinished = function()
		input:remove()
		statusContainer.hidden = false
		input.text = ("/" .. input.text .. "/"):gsub("/+", "/")

		if filesystem.exists(input.text) and filesystem.isDirectory(input.text) then
			addWorkpath(input.text)
			iconField:updateFileList()
		end

		application:draw()
	end

	statusContainer.hidden = true
	input:startInput()
end

local overrideMaximize = window.actionButtons.maximize.onTouch
window.actionButtons.maximize.onTouch = function()
	iconField.yOffset = iconFieldYOffset
	overrideMaximize()
end

window.actionButtons.close.onTouch = function()
	window:close()
end

local function calculateSizes()
	sidebarContainer.height = window.height - 3
	
	sidebarPanel.width = sidebarContainer.width
	sidebarPanel.height = sidebarContainer.height
	
	itemsLayout.width = sidebarContainer.width
	itemsLayout.height = sidebarContainer.height
	for i = 1, #itemsLayout.children do
		itemsLayout.children[i].width = itemsLayout.width
	end

	resizer.localX = sidebarContainer.width
	resizer.localY = math.floor(4 + sidebarContainer.height / 2 - resizer.height / 2)

	window.backgroundPanel.width = window.width - sidebarContainer.width
	window.backgroundPanel.height = window.height - 3
	window.backgroundPanel.localX = sidebarContainer.width + 1
	window.backgroundPanel.localY = 4

	titlePanel.width = window.width
	searchInput.localX = window.width - searchInput.width

	statusContainer.width = window.width - searchInput.width - FTPButton.width - 25
	statusPanel.width = statusContainer.width

	gotoButton.localX = statusContainer.localX + statusContainer.width

	iconField.width = window.backgroundPanel.width
	iconField.height = window.height + 3
	iconField.localX = window.backgroundPanel.localX

	scrollBar.localX = window.width
	scrollBar.height = window.backgroundPanel.height
	scrollBar.shownValueCount = scrollBar.height - 1
end

window.onResize = function(width, height)
	window.width = width
	window.height = height
	calculateSizes()

	application:draw()
	updateFileListAndDraw()
end

resizer.onResize = function(deltaX)
	sidebarContainer.width = sidebarContainer.width + deltaX
	calculateSizes()

	application:draw()
end

resizer.onResizeFinished = function()
	updateFileListAndDraw()

	config.sidebarWidth = sidebarContainer.width
	saveConfig()
end

--------------------------------------------------------------------------------

if (options.o or options.open) and args[1] and filesystem.isDirectory(args[1]) then
	addWorkpath(args[1])
else
	addWorkpath("/")
end

updateSidebar()
window:resize(window.width, window.height)
