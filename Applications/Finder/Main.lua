
local GUI = require("GUI")
local buffer = require("doubleBuffering")
local computer = require("computer")
local fs = require("filesystem")
local event = require("event")
local MineOSPaths = require("MineOSPaths")
local MineOSCore = require("MineOSCore")
local MineOSNetwork = require("MineOSNetwork")
local MineOSInterface = require("MineOSInterface")

local args, options = require("shell").parse(...)

------------------------------------------------------------------------------------------------------

local favourites = {
	{name = "Root", path = "/"},
	{name = "Desktop", path = MineOSPaths.desktop},
	{name = "Applications", path = MineOSPaths.applications},
	{name = "Pictures", path = MineOSPaths.pictures},
	{name = "System", path = MineOSPaths.system},
	{name = "Libraries", path = "/lib/"},
	{name = "Trash", path = MineOSPaths.trash},
}
local resourcesPath = MineOSCore.getCurrentScriptDirectory()
local favouritesPath = MineOSPaths.applicationData .. "Finder/Favourites3.cfg"

local sidebarFromY = 1
local iconFieldYOffset = 2
local scrollTimerID

local workpathHistory = {}
local workpathHistoryCurrent = 0

------------------------------------------------------------------------------------------------------

local mainContainer, window, menu = MineOSInterface.addWindow(GUI.filledWindow(1, 1, 88, 26, 0xF0F0F0))

local titlePanel = window:addChild(GUI.panel(1, 1, 1, 3, 0xE1E1E1))

local prevButton = window:addChild(GUI.adaptiveRoundedButton(9, 2, 1, 0, 0xFFFFFF, 0x4B4B4B, 0x3C3C3C, 0xFFFFFF, "<"))
prevButton.colors.disabled.background = prevButton.colors.default.background
prevButton.colors.disabled.text = 0xC3C3C3

local nextButton = window:addChild(GUI.adaptiveRoundedButton(14, 2, 1, 0, 0xFFFFFF, 0x4B4B4B, 0x3C3C3C, 0xFFFFFF, ">"))
nextButton.colors.disabled = prevButton.colors.disabled

local FTPButton = window:addChild(GUI.adaptiveRoundedButton(20, 2, 1, 0, 0xFFFFFF, 0x4B4B4B, 0x3C3C3C, 0xFFFFFF, MineOSCore.localization.networkFTPNewConnection))
FTPButton.colors.disabled = prevButton.colors.disabled
FTPButton.disabled = not MineOSNetwork.internetProxy

local sidebarContainer = window:addChild(GUI.container(1, 4, 20, 1))
local sidebarPanel = sidebarContainer:addChild(GUI.object(1, 1, sidebarContainer.width, 1, 0xFFFFFF))
sidebarPanel.draw = function(object)
	buffer.drawRectangle(object.x, object.y, object.width, object.height, 0xFFFFFF, 0x0, " ", MineOSCore.properties.transparencyEnabled and 0.3)
end

sidebarContainer.itemsContainer = sidebarContainer:addChild(GUI.container(1, 1, sidebarContainer.width, 1))

local searchInput = window:addChild(GUI.input(1, 2, 36, 1, 0xFFFFFF, 0x4B4B4B, 0xA5A5A5, 0xFFFFFF, 0x2D2D2D, nil, MineOSCore.localization.search, true))

local iconField = window:addChild(MineOSInterface.iconField(1, 4, 1, 1, 2, 2, 0x3C3C3C, 0x969696, MineOSPaths.desktop))

local scrollBar = window:addChild(GUI.scrollBar(1, 4, 1, 1, 0xC3C3C3, 0x4B4B4B, iconFieldYOffset, 1, 1, 1, 1, true))
scrollBar.eventHandler = nil

local statusBar = window:addChild(GUI.object(1, 1, 1, 1))

statusBar.draw = function(object)
	buffer.drawRectangle(object.x, object.y, object.width, object.height, 0xFFFFFF, 0x3C3C3C, " ")
	buffer.drawText(object.x + 1, object.y, 0x3C3C3C, string.limit(("root/" .. iconField.workpath):gsub("/+$", ""):gsub("%/+", " ► "), object.width - 2, "left"))
end

local sidebarResizer = window:addChild(GUI.resizer(1, 4, 3, 5, 0xFFFFFF, 0x0))

------------------------------------------------------------------------------------------------------

local function saveFavourites()
	table.toFile(favouritesPath, favourites)
end

local function updateFileListAndDraw()
	iconField:updateFileList()
	MineOSInterface.mainContainer:drawOnScreen()
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

local function newSidebarItem(y, textColor, text, path)
	local object = sidebarContainer.itemsContainer:addChild(GUI.object(1, y, 1, 1))
	
	if text then
		object.draw = function(object)
			object.width = sidebarContainer.itemsContainer.width

			local currentTextColor = textColor
			if path == iconField.workpath then
				buffer.drawRectangle(object.x, object.y, object.width, 1, 0x3366CC, 0xFFFFFF, " ")
				currentTextColor = 0xFFFFFF
			end
			
			buffer.drawText(object.x + 1, object.y, currentTextColor, string.limit(text, object.width - 2, "center"))
		end

		object.eventHandler = function(mainContainer, object, e1, ...)
			if e1 == "touch" and object.onTouch then
				object.onTouch(e1, ...)
			end
		end
	end

	return object
end

local function onFavouriteTouch(path)
	if fs.exists(path) then
		addWorkpath(path)
		updateFileListAndDraw()
	else
		GUI.alert("Path doesn't exists: " .. path)
	end
end

local openFTP, updateSidebar

openFTP = function(...)
	local mountPath = MineOSNetwork.mountPaths.FTP .. MineOSNetwork.getFTPProxyName(...) .. "/"
	local proxy, reason = MineOSNetwork.connectToFTP(...)
	if proxy then
		MineOSNetwork.umountFTPs()
		fs.mount(proxy, mountPath)
		addWorkpath(mountPath)
		updateSidebar()
		updateFileListAndDraw()
	else
		GUI.alert(reason)
	end
end

updateSidebar = function()
	local y = sidebarFromY
	sidebarContainer.itemsContainer:removeChildren()

	newSidebarItem(y, 0x3C3C3C, MineOSCore.localization.favourite)
	y = y + 1
	for i = 1, #favourites do
		local object = newSidebarItem(y, 0x555555, " " .. fs.name(favourites[i].name), favourites[i].path)
		
		object.onTouch = function(e1, e2, e3, e4, e5)
			if e5 == 1 then
				local menu = GUI.addContextMenu(mainContainer, e3, e4)
				
				menu:addItem(MineOSCore.localization.removeFromFavourites).onTouch = function()
					table.remove(favourites, i)
					saveFavourites()
					updateSidebar()
					MineOSInterface.mainContainer:drawOnScreen()
				end

				mainContainer:drawOnScreen()
			else
				onFavouriteTouch(favourites[i].path)
			end
		end

		y = y + 1
	end

	local added = false
	for proxy, path in fs.mounts() do
		if proxy.MineOSNetworkModem then
			if not added then
				y = y + 1
				newSidebarItem(y, 0x3C3C3C, MineOSCore.localization.network)
				y, added = y + 1, true
			end

			newSidebarItem(y, 0x555555, " " .. MineOSNetwork.getModemProxyName(proxy), path .. "/").onTouch = function()
				addWorkpath(path .. "/")
				updateFileListAndDraw()
			end

			y = y + 1
		end
	end

	if MineOSNetwork.internetProxy and #MineOSCore.properties.FTPConnections > 0 then
		y = y + 1
		newSidebarItem(y, 0x3C3C3C, MineOSCore.localization.networkFTPConnections)
		y = y + 1
		
		for i = 1, #MineOSCore.properties.FTPConnections do
			local connection = MineOSCore.properties.FTPConnections[i]
			local name = MineOSNetwork.getFTPProxyName(connection.address, connection.port, connection.user)
			local mountPath = MineOSNetwork.mountPaths.FTP .. name .. "/"

			newSidebarItem(y, 0x555555, " " .. name, mountPath).onTouch = function(e1, e2, e3, e4, e5)
				if e5 == 1 then
					local menu = GUI.addContextMenu(mainContainer, e3, e4)
					
					menu:addItem(MineOSCore.localization.delete).onTouch = function()
						table.remove(MineOSCore.properties.FTPConnections, i)
						MineOSCore.saveProperties()
						updateSidebar()
						MineOSInterface.mainContainer:drawOnScreen()
					end

					mainContainer:drawOnScreen()
				else
					openFTP(connection.address, connection.port, connection.user, connection.password)
				end
			end

			y = y + 1
		end
	end

	y = y + 1
	newSidebarItem(y, 0x3C3C3C, MineOSCore.localization.mounts)
	y = y + 1
	for proxy, path in fs.mounts() do
		if path ~= "/" and not proxy.MineOSNetworkModem and not proxy.MineOSNetworkFTP then
			newSidebarItem(y, 0x555555, " " .. (proxy.getLabel() or fs.name(path)), path .. "/").onTouch = function()
				onFavouriteTouch(path .. "/")
			end

			y = y + 1
		end
	end
end

sidebarContainer.itemsContainer.eventHandler = function(mainContainer, object, e1, e2, e3, e4, e5)
	if e1 == "scroll" then
		if (e5 > 0 and sidebarFromY < 1) or (e5 < 0 and sidebarContainer.itemsContainer.children[#sidebarContainer.itemsContainer.children].localY > 1) then
			sidebarFromY = sidebarFromY + e5
			updateSidebar()
			MineOSInterface.mainContainer:drawOnScreen()
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
	local container = MineOSInterface.addBackgroundContainer(MineOSInterface.mainContainer, MineOSCore.localization.networkFTPNewConnection)

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
				MineOSInterface.mainContainer:drawOnScreen()

				openFTP(addressInput.text, port, userInput.text, passwordInput.text)
			end
		end
	end

	MineOSInterface.mainContainer:drawOnScreen()
end

statusBar.eventHandler = function(mainContainer, object, e1, e2)
	if e1 == "component_added" or e1 == "component_removed" then
		FTPButton.disabled = not MineOSNetwork.internetProxy
		updateSidebar()
		MineOSInterface.mainContainer:drawOnScreen()
	elseif e1 == "MineOSNetwork" then
		if e2 == "updateProxyList" or e2 == "timeout" then
			updateSidebar()
			MineOSInterface.mainContainer:drawOnScreen()
		end
	end
end

iconField.eventHandler = function(mainContainer, object, e1, e2, e3, e4, e5)
	if e1 == "scroll" then
		iconField.yOffset = iconField.yOffset + e5 * 2

		updateScrollBar()

		local delta = iconField.yOffset - iconField.iconsContainer.children[1].localY
		for i = 1, #iconField.iconsContainer.children do
			iconField.iconsContainer.children[i].localY = iconField.iconsContainer.children[i].localY + delta
		end

		MineOSInterface.mainContainer:drawOnScreen()

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
				table.insert(favourites, e3)
			end
			saveFavourites()
			updateSidebar()
			MineOSInterface.mainContainer:drawOnScreen()
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
	addWorkpath(fs.path(MineOSCore.readShortcut(icon.path)))
	updateFileListAndDraw()
end

local overrideUpdateFileList = iconField.updateFileList
iconField.updateFileList = function(...)
	mainContainer:drawOnScreen()
	overrideUpdateFileList(...)
	updateScrollBar()
end

local function calculateSizes(width, height)
	sidebarContainer.height = height - 3
	
	sidebarPanel.width = sidebarContainer.width
	sidebarPanel.height = sidebarContainer.height
	
	sidebarContainer.itemsContainer.width = sidebarContainer.width
	sidebarContainer.itemsContainer.height = sidebarContainer.height

	sidebarResizer.localX = sidebarContainer.width - 1
	sidebarResizer.localY = math.floor(sidebarContainer.localY + sidebarContainer.height / 2 - sidebarResizer.height / 2 - 1)

	window.backgroundPanel.width = width - sidebarContainer.width
	window.backgroundPanel.height = height - 4
	window.backgroundPanel.localX = sidebarContainer.width + 1
	window.backgroundPanel.localY = 4

	statusBar.localX = sidebarContainer.width + 1
	statusBar.localY = height
	statusBar.width = window.backgroundPanel.width

	titlePanel.width = width
	searchInput.width = math.floor(width * 0.25)
	searchInput.localX = width - searchInput.width - 1

	iconField.width = window.backgroundPanel.width
	iconField.height = height + 4
	iconField.localX = window.backgroundPanel.localX

	scrollBar.localX = window.width
	scrollBar.height = window.backgroundPanel.height
	scrollBar.shownValueCount = scrollBar.height - 1
	
	window.actionButtons:moveToFront()
end

window.onResize = function(width, height)
	calculateSizes(width, height)
	MineOSInterface.mainContainer:drawOnScreen()
	updateFileListAndDraw()
end

sidebarResizer.onResize = function(dragWidth, dragHeight)
	sidebarContainer.width = sidebarContainer.width + dragWidth
	sidebarContainer.width = sidebarContainer.width >= 5 and sidebarContainer.width or 5
	calculateSizes(window.width, window.height)
end

sidebarResizer.onResizeFinished = function()
	updateFileListAndDraw()
end

local overrideMaximize = window.actionButtons.maximize.onTouch
window.actionButtons.maximize.onTouch = function()
	iconField.yOffset = iconFieldYOffset
	overrideMaximize()
end

window.actionButtons.close.onTouch = function()
	window:close()
end

------------------------------------------------------------------------------------------------------

if fs.exists(favouritesPath) then
	favourites = table.fromFile(favouritesPath)
else
	saveFavourites()
end

if (options.o or options.open) and args[1] and fs.isDirectory(args[1]) then
	addWorkpath(args[1])
else
	addWorkpath("/")
end

updateSidebar()
window:resize(window.width, window.height)

