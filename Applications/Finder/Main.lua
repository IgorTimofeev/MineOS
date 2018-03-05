
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
	{text = "Root", path = "/"},
	{text = "Desktop", path = MineOSPaths.desktop},
	{text = "Applications", path = MineOSPaths.applications},
	{text = "Pictures", path = MineOSPaths.pictures},
	{text = "System", path = MineOSPaths.system},
	{text = "Libraries", path = "/lib/"},
	{text = "Trash", path = MineOSPaths.trash},
}
local resourcesPath = MineOSCore.getCurrentScriptDirectory()
local favouritesPath = MineOSPaths.applicationData .. "Finder/Favourites2.cfg"

local iconFieldYOffset = 2
local scrollTimerID

local workpathHistory = {}
local workpathHistoryCurrent = 0

------------------------------------------------------------------------------------------------------

local mainContainer, window = MineOSInterface.addWindow(MineOSInterface.filledWindow(1, 1, 88, 26, 0xF0F0F0))

local titlePanel = window:addChild(GUI.panel(1, 1, 1, 3, 0xE1E1E1))

local prevButton = window:addChild(GUI.adaptiveRoundedButton(9, 2, 1, 0, 0xFFFFFF, 0x3C3C3C, 0x3C3C3C, 0xFFFFFF, "<"))
prevButton.onTouch = function()
	prevOrNextWorkpath(false)
end
prevButton.colors.disabled.background = prevButton.colors.default.background
prevButton.colors.disabled.text = 0xC3C3C3

local nextButton = window:addChild(GUI.adaptiveRoundedButton(14, 2, 1, 0, 0xFFFFFF, 0x3C3C3C, 0x3C3C3C, 0xFFFFFF, ">"))
nextButton.onTouch = function()
	prevOrNextWorkpath(true)
end
nextButton.colors.disabled = prevButton.colors.disabled

local sidebarContainer = window:addChild(GUI.container(1, 4, 20, 1))
sidebarContainer.panel = sidebarContainer:addChild(GUI.panel(1, 1, sidebarContainer.width, 1, 0xFFFFFF, MineOSCore.properties.transparencyEnabled and 0.24))
sidebarContainer.itemsContainer = sidebarContainer:addChild(GUI.container(1, 1, sidebarContainer.width, 1))

local searchInput = window:addChild(GUI.input(1, 2, 36, 1, 0xFFFFFF, 0x696969, 0xA5A5A5, 0xFFFFFF, 0x2D2D2D, nil, MineOSCore.localization.search, true))
searchInput.onInputFinished = function()
	iconField.filenameMatcher = searchInput.text
	iconField.fromFile = 1
	iconField.yOffset = iconFieldYOffset

	updateFileListAndDraw()
end

local iconField = window:addChild(
	MineOSInterface.iconField(
		1, 4, 1, 1, 2, 2, 0x3C3C3C, 0x3C3C3C,
		MineOSPaths.desktop
	)
)

local scrollBar = window:addChild(GUI.scrollBar(1, 4, 1, 1, 0xC3C3C3, 0x444444, iconFieldYOffset, 1, 1, 1, 1, true))

local statusBar = window:addChild(GUI.object(1, 1, 1, 1))
statusBar.draw = function(object)
	buffer.square(object.x, object.y, object.width, object.height, 0xFFFFFF, 0x3C3C3C, " ")
	buffer.text(object.x + 1, object.y, 0x3C3C3C, string.limit(("root/" .. iconField.workpath):gsub("/+$", ""):gsub("%/+", " ► "), object.width - 1, "start"))
end
statusBar.eventHandler = function(mainContainer, object, eventData)
	if (eventData[1] == "component_added" or eventData[1] == "component_removed") and eventData[3] == "filesystem" then
		updateSidebar()
		MineOSInterface.OSDraw()
	elseif eventData[1] == "MineOSNetwork" then
		if eventData[2] == "updateProxyList" or eventData[2] == "timeout" then
			updateSidebar()
			MineOSInterface.OSDraw()
		end
	end
end

local sidebarResizer = window:addChild(GUI.resizer(1, 4, 3, 5, 0xFFFFFF, 0x0))

------------------------------------------------------------------------------------------------------

local function saveFavourites()
	table.toFile(favouritesPath, favourites)
end

local function updateFileListAndDraw()
	iconField:updateFileList()
	MineOSInterface.OSDraw()
end

local function workpathHistoryButtonsUpdate()
	prevButton.disabled = workpathHistoryCurrent <= 1
	nextButton.disabled = workpathHistoryCurrent >= #workpathHistory
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

------------------------------------------------------------------------------------------------------

local function newSidebarItem(textColor, text, path)
	local object = sidebarContainer.itemsContainer:addChild(
		GUI.object(
			1,
			#sidebarContainer.itemsContainer.children > 0 and sidebarContainer.itemsContainer.children[#sidebarContainer.itemsContainer.children].localY + 1 or 1,
			1,
			1
		)
	)
	
	if text then
		object.text = text
		object.textColor = textColor
		object.path = path

		object.draw = function(object)
			object.width = sidebarContainer.itemsContainer.width

			if object.path == iconField.workpath then
				buffer.square(object.x, object.y, object.width, 1, 0x3366CC, 0xFFFFFF, " ")
				buffer.text(object.x + 1, object.y, 0xFFFFFF, string.limit(object.text, object.width - 4, "center"))
				if object.favouriteIndex and object.favouriteIndex > 1 then
					buffer.text(object.x + object.width - 2, object.y, 0xCCFFFF, "x")
				end
			else
				buffer.text(object.x + 1, object.y, object.textColor, string.limit(object.text, object.width - 2, "center"))
			end
			
		end

		object.eventHandler = function(mainContainer, object, eventData)
			if eventData[1] == "touch" then
				if object.favouriteIndex and object.favouriteIndex > 1 and eventData[3] == object.x + object.width - 2 then
					table.remove(favourites, object.favouriteIndex)
					saveFavourites()

					computer.pushSignal("Finder", "updateFavourites")
				elseif fs.isDirectory(object.path) then
					addWorkpath(object.path)
					MineOSInterface.OSDraw()
					
					updateFileListAndDraw()
				end
			end
		end
	end

	return object
end

local function updateSidebar()
	sidebarContainer.itemsContainer:deleteChildren()
	
	sidebarContainer.itemsContainer:addChild(newSidebarItem(0x3C3C3C, MineOSCore.localization.favourite))
	for i = 1, #favourites do
		local object = sidebarContainer.itemsContainer:addChild(newSidebarItem(0x555555, " " .. fs.name(favourites[i].text), favourites[i].path))
		object.favouriteIndex = i
	end

	if MineOSCore.properties.network.enabled and MineOSNetwork.getProxyCount() > 0 then
		sidebarContainer.itemsContainer:addChild(newSidebarItem(0x3C3C3C))
		sidebarContainer.itemsContainer:addChild(newSidebarItem(0x3C3C3C, MineOSCore.localization.network))

		for proxy, path in fs.mounts() do
			if proxy.network then
				sidebarContainer.itemsContainer:addChild(newSidebarItem(0x555555, " " .. MineOSNetwork.getProxyName(proxy), path .. "/"))
			end
		end
	end

	sidebarContainer.itemsContainer:addChild(newSidebarItem(0x3C3C3C))

	sidebarContainer.itemsContainer:addChild(newSidebarItem(0x3C3C3C, MineOSCore.localization.mounts))
	for proxy, path in fs.mounts() do
		if path ~= "/" and not proxy.network then
			sidebarContainer.itemsContainer:addChild(newSidebarItem(0x555555, " " .. (proxy.getLabel() or fs.name(path)), path .. "/"))
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

iconField.eventHandler = function(mainContainer, object, eventData)
	if eventData[1] == "scroll" then
		iconField.yOffset = iconField.yOffset + eventData[5] * 2

		updateScrollBar()

		local delta = iconField.yOffset - iconField.iconsContainer.children[1].localY
		for i = 1, #iconField.iconsContainer.children do
			iconField.iconsContainer.children[i].localY = iconField.iconsContainer.children[i].localY + delta
		end

		MineOSInterface.OSDraw()

		if scrollTimerID then
			event.cancel(scrollTimerID)
			scrollTimerID = nil
		end

		scrollTimerID = event.timer(0.3, function()
			computer.pushSignal("Finder", "updateFileList")
		end, 1)
	elseif eventData[1] == "MineOSCore" or eventData[1] == "Finder" then
		if eventData[2] == "updateFileList" then
			if eventData[1] == "MineOSCore" then
				iconField.yOffset = iconFieldYOffset
			end
			updateFileListAndDraw()
		elseif eventData[2] == "updateFavourites" then
			if eventData[3] then
				table.insert(favourites, eventData[3])
			end
			saveFavourites()
			updateSidebar()

			MineOSInterface.OSDraw()
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
	overrideUpdateFileList(...)
	updateScrollBar()
end

local function calculateSizes(width, height)
	sidebarContainer.height = height - 3
	
	sidebarContainer.panel.width = sidebarContainer.width
	sidebarContainer.panel.height = sidebarContainer.height
	
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
	MineOSInterface.OSDraw()
	updateFileListAndDraw()
end

sidebarResizer.onResize = function(mainContainer, object, eventData, dragWidth, dragHeight)
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

