
require("advancedLua")
local component = require("component")
local computer = require("computer")
local image = require("image")
local buffer = require("doubleBuffering")
local GUI = require("GUI")
local fs = require("filesystem")
local unicode = require("unicode")
local web = require("web")
local MineOSPaths = require("MineOSPaths")
local MineOSCore = require("MineOSCore")
local MineOSInterface = require("MineOSInterface")

----------------------------------------------------------------------------------------------------------------

local applicationListURL = "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/Applications.cfg"
local applicationList
local localization = MineOSCore.getCurrentApplicationLocalization()
local resources = MineOSCore.getCurrentApplicationResourcesDirectory()
local updateImage = image.load(resources .. "Update.pic")
local temproraryIconPath = resources .. "TempIcon.pic"
local appsPerPage = 6

local mainContainer, window = MineOSInterface.addWindow(GUI.tabbedWindow(nil, nil, 80, 32))

----------------------------------------------------------------------------------------------------------------

local function newApp(x, y, width, applicationListElement, hideDownloadButton)
	local app = GUI.container(x, y, width, 4)
	
	app.icon = app:addChild(GUI.image(1, 1, MineOSInterface.iconsCache.script))
	if applicationListElement.icon then
		web.downloadFile(applicationListElement.icon, temproraryIconPath)
		app.icon.image = image.load(temproraryIconPath)
	end

	app.downloadButton = app:addChild(GUI.button(1, 1, 13, 1, 0x66DB80, 0xFFFFFF, 0x339240, 0xFFFFFF, localization.download))
	app.downloadButton.localPosition.x = app.width - app.downloadButton.width + 1
	app.downloadButton.onTouch = function()
		app.downloadButton.disabled = true
		app.downloadButton.colors.disabled.background, app.downloadButton.colors.disabled.text = 0xBBBBBB, 0xFFFFFF
		app.downloadButton.text = localization.downloading
		mainContainer:draw()
		buffer.draw()

		web.downloadMineOSApplication(applicationListElement, MineOSCore.properties.language)

		app.downloadButton.text = localization.downloaded
		computer.pushSignal("MineOSCore", "updateFileList")
	end
	app.downloadButton.hidden = hideDownloadButton

	app.pathLabel = app:addChild(GUI.label(app.icon.width + 2, 1, width - app.icon.width - app.downloadButton.width - 3, 1, 0x0, fs.name(applicationListElement.path)))
	app.versionLabel = app:addChild(GUI.label(app.icon.width + 2, 2, app.pathLabel.width, 1, 0x555555, localization.version .. applicationListElement.version))
	if applicationListElement.about then
		local lines = string.wrap({web.request(applicationListElement.about .. MineOSCore.properties.language .. ".txt")}, app.pathLabel.width)
		app.aboutTextBox = app:addChild(GUI.textBox(app.icon.width + 2, 3, app.pathLabel.width, #lines, nil, 0x999999, lines, 1, 0, 0))
		app.aboutTextBox.eventHandler = nil
		if #lines > 2 then
			app.height = #lines + 2
		end
	end

	return app
end

local function addUpdateImage()
	window.contentContainer:deleteChildren()
	local cyka = window.contentContainer:addChild(GUI.image(math.floor(window.contentContainer.width / 2 - image.getWidth(updateImage) / 2), math.floor(window.contentContainer.height / 2 - image.getHeight(updateImage) / 2) - 1, updateImage))
	return cyka.localPosition.y + cyka.height + 2
end

local function updateApplicationList()
	local y = addUpdateImage()
	window.contentContainer:addChild(GUI.label(1, y, window.contentContainer.width, 1, 0x888888, localization.checkingForUpdates)):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	mainContainer:draw()
	buffer.draw()

	applicationList = table.fromString(web.request(applicationListURL))
end


local function displayApps(fromPage, typeFilter, nameFilter, updateCheck)
	window.contentContainer:deleteChildren()
	
	local y = 2
	local finalApplicationList = {}

	if updateCheck then
		local oldApplicationList = table.fromFile(MineOSPaths.applicationList)

		for j = 1, #applicationList do
			local pathFound = false
			
			for i = 1, #oldApplicationList do	
				if oldApplicationList[i].path == applicationList[j].path then
					if oldApplicationList[i].version < applicationList[j].version then
						table.insert(finalApplicationList, applicationList[j])
					end

					pathFound = true
					break
				end
			end

			if not pathFound then
				table.insert(finalApplicationList, applicationList[j])
			end
		end

		if #finalApplicationList == 0 then
			window.contentContainer:addChild(GUI.label(1, 1, window.contentContainer.width, window.contentContainer.height, 0x888888, localization.youHaveNewestApps)):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.center)
			mainContainer:draw()
			buffer.draw()
			return
		else
			window.contentContainer:addChild(GUI.button(math.floor(window.contentContainer.width / 2 - 10), y, 20, 1, 0xBBBBBB, 0xFFFFFF, 0x999999, 0xFFFFFF, localization.updateAll)).onTouch = function()
				y = addUpdateImage()

				local progressBarWidth = math.floor(window.contentContainer.width * 0.65)
				local progressBar = window.contentContainer:addChild(GUI.progressBar(math.floor(window.contentContainer.width / 2 - progressBarWidth / 2), y, progressBarWidth, 0x33B6FF, 0xDDDDDD, 0x0, 0, true, false))
				local label = window.contentContainer:addChild(GUI.label(1, y + 1, window.contentContainer.width, 1, 0x888888, "")):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)

				for i = 1, #finalApplicationList do
					progressBar.value = math.floor(i / #finalApplicationList * 100)
					label.text = localization.updating .. fs.name(finalApplicationList[i].path)
					
					mainContainer:draw()
					buffer.draw()

					web.downloadMineOSApplication(finalApplicationList[i], MineOSCore.properties.language)
				end

				mainContainer:draw()
				buffer.draw()

				table.toFile(MineOSPaths.applicationList, applicationList)

				computer.shutdown(true)
			end
		end
	else
		window.contentContainer.searchInputTextBox = window.contentContainer:addChild(GUI.input(math.floor(window.contentContainer.width / 2 - 10), y, 20, 1, 0xFFFFFF, 0x444444, 0xAAAAAA, 0xFFFFFF, 0x2D2D2D, "", localization.search, true))
		window.contentContainer.searchInputTextBox.onInputFinished = function()
			if window.contentContainer.searchInputTextBox.text then
				displayApps(1, typeFilter, window.contentContainer.searchInputTextBox.text)
			end
		end

		for i = 1, #applicationList do
			if (not typeFilter or typeFilter == applicationList[i].type) and (not nameFilter or string.unicodeFind(unicode.lower(fs.name(applicationList[i].path)), unicode.lower(nameFilter))) then
				table.insert(finalApplicationList, applicationList[i])
			end
		end
	end

	y = y + 2

	mainContainer:draw()
	buffer.draw()
	
	local appOnPageCounter, fromAppCounter, fromApp = 1, 1, (fromPage - 1) * appsPerPage + 1
	for i = 1, #finalApplicationList do
		if fromAppCounter >= fromApp then
			y, appOnPageCounter = y + window.contentContainer:addChild(newApp(1, y, window.contentContainer.width, finalApplicationList[i])).height + 1, appOnPageCounter + 1
			
			mainContainer:draw()
			buffer.draw()

			if appOnPageCounter > appsPerPage then
				break
			end
		end

		fromAppCounter = fromAppCounter + 1
	end

	-- Pages buttons CYKA
	local buttonWidth, text = 7, localization.page .. fromPage
	local textLength = unicode.len(text)
	local x = math.floor(window.contentContainer.width / 2 - (buttonWidth * 2 + textLength + 4) / 2)
	window.contentContainer:addChild(GUI.button(x, y, buttonWidth, 1, 0xBBBBBB, 0xFFFFFF, 0x999999, 0xFFFFFF, "<")).onTouch = function()
		if fromPage > 1 then
			displayApps(fromPage - 1, typeFilter, nameFilter)
		end
	end
	x = x + buttonWidth + 2

	window.contentContainer:addChild(GUI.label(x, y, textLength, 1, 0x3C3C3C, text))
	x = x + textLength + 2

	window.contentContainer:addChild(GUI.button(x, y, buttonWidth, 1, 0xBBBBBB, 0xFFFFFF, 0x999999, 0xFFFFFF, ">")).onTouch = function()
		displayApps(fromPage + 1, typeFilter, nameFilter)
	end

	mainContainer:draw()
	buffer.draw()
end

window.contentContainer = window:addChild(GUI.container(3, 4, window.width - 4, window.height - 3))
window.contentContainer.eventHandler = function(mainContainer, object, eventData)
	if eventData[1] == "scroll" and (eventData[5] == -1 or window.contentContainer.children[1].localPosition.y <= 1) then
		for i = 1, #window.contentContainer.children do
			window.contentContainer.children[i].localPosition.y = window.contentContainer.children[i].localPosition.y + eventData[5]
		end
		mainContainer:draw()
		buffer.draw()
	end
end

local tabs = {
	window.tabBar:addItem(localization.applications),
	window.tabBar:addItem(localization.libraries),
	window.tabBar:addItem(localization.wallpapers),
	window.tabBar:addItem(localization.other),
	window.tabBar:addItem(localization.updates)
}

window.onResize = function(width, height)
	window.contentContainer.width, window.contentContainer.height = width - 4, height - 3
	window.tabBar.width = width
	window.backgroundPanel.width = width
	window.backgroundPanel.height = height - window.tabBar.height
	tabs[window.tabBar.selectedItem].onTouch()
end

tabs[1].onTouch = function() displayApps(1, "Application") end
tabs[2].onTouch = function() displayApps(1, "Library") end
tabs[3].onTouch = function() displayApps(1, "Wallpaper") end
tabs[4].onTouch = function() displayApps(1, "Script") end
tabs[5].onTouch = function() displayApps(1, nil, nil, true) end

----------------------------------------------------------------------------------------------------------------

updateApplicationList()

if select(1, ...) == "updates" then
	window.tabBar.selectedItem = 5
end

tabs[window.tabBar.selectedItem].onTouch()







