
package.loaded.MineOSCore, _G.MineOSCore = nil, nil
package.loaded.GUI, _G.GUI = nil, nil
package.loaded.windows, _G.windows = nil, nil

---------------------------------------------- Копирайт, епта ------------------------------------------------------------------------

local copyright = [[

	Тут можно было бы написать кучу текста, мол,
	вы не имеете прав на использование этой хуйни в
	коммерческих целях и прочую чушь, навеянную нам
	западной культурой. Но я же не пидор какой-то, верно?

	Просто помни, что эту ОСь накодил Тимофеев Игорь,
	ссылка на ВК: vk.com/id7799889

]]

-- Вычищаем копирайт из оперативки, ибо мы не можем тратить СТОЛЬКО памяти.
-- Сколько тут, раз, два, три... 282 UTF-8 символа!
-- А это, между прочим, 56 раз по слову "Пидор". Но один раз - не пидорас, поэтому очищаем.

-- Я передумал, не очищаем, пригодится еще кое-где. Вот же ж костыльная параша!
-- copyright = nil

---------------------------------------------- Адаптивная загрузка библиотек ------------------------------------------------------------------------

local component = require("component")
local fs = require("filesystem")
local event = require("event")
local image = require("image")
local buffer = require("doubleBuffering")
local GUI = require("GUI")
local windows = require("windows")
local MineOSCore = require("MineOSCore")
local ecs = require("ECSAPI")
local SHA2 = require("SHA2")

---------------------------------------------- Базовые константы ------------------------------------------------------------------------

local colors = {
	background = 0x262626,
	topBarTransparency = 35,
	selection = ecs.colors.lightBlue,
	interface = 0xCCCCCC,
	dockBaseTransparency = 70,
	dockTransparencyAdder = 10,
	iconsSelectionTransparency = 20,
	desktopCounter = 0x999999,
	desktopCounterActive = 0xFFFFFF,
	desktopPainting = 0xEEEEEE,
}

local sizes = {
	heightOfDock = 6,
	xSpaceBetweenIcons = 2,
	ySpaceBetweenIcons = 1,
}

local currentWorkpathHistoryIndex, workpathHistory = 1, {"/"}
local workspace
local currentDesktop, countOfDesktops = 1

---------------------------------------------- Основные функции ------------------------------------------------------------------------

local function changeWallpaper()
	if fs.exists(MineOSCore.paths.wallpaper) then
		local path = ecs.readShortcut(MineOSCore.paths.wallpaper)
		if fs.exists(path) then
			workspace.wallpaper.image = image.load(path)
			workspace.wallpaper.isHidden = false
		end
	else
		workspace.wallpaper.image = nil
		workspace.wallpaper.isHidden = true
	end
end

local function changeWorkpath(newWorkpathHistoryIndex)
	currentDesktop = 1
	currentWorkpathHistoryIndex = newWorkpathHistoryIndex
	workspace.iconField.workpath = workpathHistory[currentWorkpathHistoryIndex]
	workspace.background.onTouch = function(eventData)
		if eventData[5] == 1 then
			MineOSCore.emptyZoneClick(eventData, workspace, workspace.iconField.workpath)
		end
	end
	workspace.wallpaper.onTouch = workspace.background.onTouch
end

local function updateDesktopCounters()
	countOfDesktops = math.ceil(#workspace.iconField.fileList / workspace.iconField.iconCount.total)
	workspace.desktopCounters.width = (countOfDesktops) * 3
	workspace.desktopCounters.localPosition.x = math.floor(workspace.width / 2 - workspace.desktopCounters.width / 2)
	workspace.desktopCounters.localPosition.y = workspace.height - sizes.heightOfDock - 2
	workspace.desktopCounters.children = {}
	local x = 1
	if #workpathHistory > 1 then
		workspace.desktopCounters:addButton(x, 1, 1, 1, nil, 0xEEEEEE, nil, 0x888888, "<").onTouch = function()
			table.remove(workpathHistory, #workpathHistory)
			changeWorkpath(#workpathHistory)
			workspace.updateFileList()
		end
		x = x + 3
	end
	for i = 1, countOfDesktops do
		workspace.desktopCounters:addButton(x, 1, 1, 1, nil, i == currentDesktop and 0xEEEEEE or 0xBBBBBB, nil, 0x888888, "●").onTouch = function()
			if currentDesktop ~= i then
				currentDesktop = i
				workspace.updateFileList()
			end
		end
		x = x + 3
	end
end

local function changeResolution()
	currentDesktop = 1
	ecs.setScale(_G.OSSettings.screenScale or 1)
	buffer.start()

	workspace.width, workspace.height = buffer.screen.width, buffer.screen.height

	workspace.iconField.iconCount.width, workspace.iconField.iconCount.height, workspace.iconField.iconCount.total =  MineOSCore.getParametersForDrawingIcons(workspace.width, workspace.height - sizes.heightOfDock - 5, sizes.xSpaceBetweenIcons, sizes.ySpaceBetweenIcons)
	workspace.iconField.localPosition.x = math.floor(workspace.width / 2 - (workspace.iconField.iconCount.width * (MineOSCore.iconWidth + sizes.xSpaceBetweenIcons) - sizes.xSpaceBetweenIcons) / 2)
	workspace.iconField.localPosition.y = 3

	workspace.dockContainer.width = (#_G.OSSettings.dockShortcuts * (MineOSCore.iconWidth + sizes.xSpaceBetweenIcons) - sizes.xSpaceBetweenIcons) + 2
	workspace.dockContainer.localPosition.x = math.floor(buffer.screen.width / 2 - workspace.dockContainer.width / 2)
	workspace.dockContainer.localPosition.y = workspace.height - sizes.heightOfDock + 1

	workspace.updateFileList(true)
end

-- Отрисовка дока
local function createDock()
	workspace.dockContainer = workspace:addContainer(1, 1, workspace.width, sizes.heightOfDock)
	workspace.dockContainer.updateFileList = function(dockContainer)
		local function moveDockShortcut(iconIndex, direction)
			_G.OSSettings.dockShortcuts[iconIndex], _G.OSSettings.dockShortcuts[iconIndex + direction] = swap(_G.OSSettings.dockShortcuts[iconIndex], _G.OSSettings.dockShortcuts[iconIndex + direction])
			MineOSCore.saveOSSettings()
			dockContainer:updateFileList()
			workspace:draw()
			buffer.draw()
		end

		-- Создание иконок дока
		dockContainer:deleteChildren()
		local xPos, yPos = 2, 1
		for iconIndex = 1, #_G.OSSettings.dockShortcuts do
			local iconObject = MineOSCore.createIconObject(xPos, yPos, _G.OSSettings.dockShortcuts[iconIndex].path, 0x000000, showFileFormat)
				
			iconObject.onRightClick = function(iconObject, eventData)
				local menu = GUI.contextMenu(eventData[3], eventData[4])
				menu:addItem(MineOSCore.localization.contextMenuShowContainingFolder, true).onTouch = function()
					MineOSCore.safeLaunch(MineOSCore.paths.applications .. "Finder.app/Finder.lua", "open", fs.path(_G.OSSettings.dockShortcuts[iconIndex].path))
					dockContainer:updateFileList()
					workspace:draw()
					buffer.draw()
				end
				menu:addSeparator()
				menu:addItem(MineOSCore.localization.contextMenuMoveRight, iconIndex >= #_G.OSSettings.dockShortcuts).onTouch = function()
					moveDockShortcut(iconIndex, 1)
				end
				menu:addItem(MineOSCore.localization.contextMenuMoveLeft, iconIndex <= 1).onTouch = function()
					moveDockShortcut(iconIndex, -1)
				end
				menu:addSeparator()
				menu:addItem(MineOSCore.localization.contextMenuRemoveFromDock, _G.OSSettings.dockShortcuts[iconIndex].canNotBeDeleted or #_G.OSSettings.dockShortcuts < 2).onTouch = function()
					table.remove(_G.OSSettings.dockShortcuts, iconIndex)
					MineOSCore.saveOSSettings()
					dockContainer:updateFileList()
					workspace:draw()
					buffer.draw()
				end
				menu:show()
			end

			dockContainer:addChild(iconObject, GUI.objectTypes.container)
			xPos = xPos + MineOSCore.iconWidth + sizes.xSpaceBetweenIcons
		end
	end

	-- Отрисовка дока
	local oldDraw = workspace.dockContainer.draw
	workspace.dockContainer.draw = function(dockContainer)
		if #_G.OSSettings.dockShortcuts > 0 then
			local currentDockTransparency, currentDockWidth, xPos, yPos = colors.dockBaseTransparency, dockContainer.width - 2, dockContainer.x, dockContainer.y + 2
			
			for i = 1, sizes.heightOfDock do
				buffer.text(xPos, yPos, _G.OSSettings.interfaceColor or colors.interface, "▟", currentDockTransparency)
				buffer.square(xPos + 1, yPos, currentDockWidth, 1, _G.OSSettings.interfaceColor or colors.interface, 0xFFFFFF, " ", currentDockTransparency)
				buffer.text(xPos + currentDockWidth + 1, yPos, _G.OSSettings.interfaceColor or colors.interface, "▙", currentDockTransparency)

				currentDockTransparency, currentDockWidth, xPos, yPos = currentDockTransparency - colors.dockTransparencyAdder, currentDockWidth + 2, xPos - 1, yPos + 1
			end
		end

		oldDraw(dockContainer)
	end

	return dockContainer
end

local function createWorkspace()
	workspace = windows.fullScreen()
	workspace.background = workspace:addPanel(1, 1, workspace.width, workspace.height, _G.OSSettings.backgroundColor or colors.background)
	workspace.wallpaper = workspace:addImage(1, 1, {width = workspace.width, height = workspace.height})

	workspace.desktopCounters = workspace:addContainer(1, 1, 1, 1)

	workspace.iconField = workspace:addChild(
		MineOSCore.createIconField(
			1, 1, 1, 1, 1, 1, 1,
			sizes.xSpaceBetweenIcons,
			sizes.ySpaceBetweenIcons,
			0xFFFFFF,
			_G.OSSettings.showFileFormat == nil and true or _G.OSSettings.showFileFormat,
			_G.OSSettings.showHiddenFiles == nil and true or _G.OSSettings.showHiddenFiles,
			MineOSCore.sortingMethods[_G.OSSettings.sortingMethod or "type"],
			"/"
		),
		GUI.objectTypes.container
	)

	createDock()

	workspace.menu = workspace:addMenu(1, 1, workspace.width, _G.OSSettings.interfaceColor or colors.interface, 0x444444, 0x3366CC, 0xFFFFFF, 10)
	local item1 = workspace.menu:addItem("MineOS", 0x000000)
	item1.onTouch = function()
		local menu = GUI.contextMenu(item1.x, item1.y + 1)
		menu:addItem(MineOSCore.localization.aboutSystem).onTouch = function()
			ecs.prepareToExit()
			print(copyright)
			ecs.waitForTouchOrClick()
			buffer.draw(true)
		end
		menu:addItem(MineOSCore.localization.updates).onTouch = function()
			MineOSCore.safeLaunch("/MineOS/Applications/AppMarket.app/AppMarket.lua", "updateCheck")
		end
		menu:addSeparator()
		menu:addItem(MineOSCore.localization.logout, _G.OSSettings.protectionMethod == "withoutProtection").onTouch = function()
			login()
		end
		menu:addItem(MineOSCore.localization.reboot).onTouch = function()
			ecs.TV(0)
			shell.execute("reboot")
		end
		menu:addItem(MineOSCore.localization.shutdown).onTouch = function()
			ecs.TV(0)
			shell.execute("shutdown")
		end		
		menu:addSeparator()
		menu:addItem(MineOSCore.localization.returnToShell).onTouch = function()
			workspace:close()
			ecs.prepareToExit()
			os.exit()
		end	
		menu:show()
	end

	local item2 = workspace.menu:addItem(MineOSCore.localization.viewTab)
	item2.onTouch = function()
		local menu = GUI.contextMenu(item2.x, item2.y + 1)
		menu:addItem(workspace.iconField.showFileFormat and MineOSCore.localization.hideFileFormat or MineOSCore.localization.showFileFormat).onTouch = function()
			workspace.iconField.showFileFormat = not workspace.iconField.showFileFormat
			_G.OSSettings.showFileFormat = workspace.iconField.showFileFormat
			MineOSCore.saveOSSettings()
			workspace:updateFileList()
		end
		menu:addItem(workspace.iconField.showHiddenFiles and MineOSCore.localization.hideHiddenFiles or MineOSCore.localization.showHiddenFiles).onTouch = function()
			workspace.iconField.showHiddenFiles = not workspace.iconField.showHiddenFiles
			_G.OSSettings.showHiddenFiles = workspace.iconField.showHiddenFiles
			MineOSCore.saveOSSettings()
			workspace:updateFileList()
		end
		menu:addItem(MineOSCore.showApplicationIcons and MineOSCore.localization.hideApplicationIcons or  MineOSCore.localization.showApplicationIcons).onTouch = function()
			MineOSCore.showApplicationIcons = not MineOSCore.showApplicationIcons
		end
		menu:addSeparator()
		menu:addItem(MineOSCore.localization.sortByName).onTouch = function()
			_G.OSSettings.sortingMethod = "name"
			MineOSCore.saveOSSettings()
			workspace.iconField.sortingMethod = MineOSCore.sortingMethods.name
			workspace:updateFileList()
		end
		menu:addItem(MineOSCore.localization.sortByDate).onTouch = function()
			_G.OSSettings.sortingMethod = "date"
			MineOSCore.saveOSSettings()
			workspace.iconField.sortingMethod = MineOSCore.sortingMethods.date
			workspace:updateFileList()
		end
		menu:addItem(MineOSCore.localization.sortByType).onTouch = function()
			_G.OSSettings.sortingMethod = "type"
			MineOSCore.saveOSSettings()
			workspace.iconField.sortingMethod = MineOSCore.sortingMethods.type
			workspace:updateFileList()
		end
		menu:addSeparator()
		menu:addItem(MineOSCore.localization.contextMenuRemoveWallpaper, workspace.wallpaper.isHidden).onTouch = function()
			fs.remove(MineOSCore.paths.wallpaper)
			changeWallpaper()
		end
		menu:show()
	end

	local item3 = workspace.menu:addItem(MineOSCore.localization.settings)
	item3.onTouch = function()
		local menu = GUI.contextMenu(item3.x, item3.y + 1)
		menu:addItem(MineOSCore.localization.screenResolution).onTouch = function()
			local possibleResolutions = {texts = {}, scales = {}}
			local xSize, ySize = ecs.getScaledResolution(1)
			local currentScale, decreaseStep = 1, 0.1
			for i = 1, 5 do
				local width, height = math.floor(xSize * currentScale), math.floor(ySize * currentScale)
				local text = width .. "x" .. height
				possibleResolutions.texts[i] = text
				possibleResolutions.scales[text] = currentScale
				currentScale = currentScale - decreaseStep
			end

			local data = ecs.universalWindow("auto", "auto", 36, 0xeeeeee, true,
				{"EmptyLine"},
				{"CenterText", 0x000000, MineOSCore.localization.screenResolution},
				{"EmptyLine"},
				{"Selector", 0x262626, 0x880000, table.unpack(possibleResolutions.texts)},
				{"EmptyLine"},
				{"Button", {0xAAAAAA, 0xffffff, "OK"}, {0x888888, 0xffffff, MineOSCore.localization.cancel}}
			)

			if data[2] == "OK" then
				_G.OSSettings.screenScale = possibleResolutions.scales[data[1]]
				MineOSCore.saveOSSettings()
				changeResolution()
			end
		end
		menu:addSeparator()
		menu:addItem(MineOSCore.localization.changePassword, _G.OSSettings.protectionMethod ~= "password").onTouch = function()
			changePassword()
		end
		menu:addItem(MineOSCore.localization.setProtectionMethod).onTouch = function()
			setProtectionMethod()
		end
		menu:addSeparator()
		menu:addItem(MineOSCore.localization.colorScheme).onTouch = function()
			local data = ecs.universalWindow("auto", "auto", 36, 0xeeeeee, true,
				{"EmptyLine"},
				{"CenterText", 0x000000, MineOSCore.localization.colorScheme},
				{"EmptyLine"},
				{"Color", MineOSCore.localization.backgroundColor, _G.OSSettings.backgroundColor or colors.background},
				{"Color", MineOSCore.localization.interfaceColor, _G.OSSettings.interfaceColor or colors.interface},
				{"Color", MineOSCore.localization.selectionColor, _G.OSSettings.selectionColor or colors.selection},
				{"Color", MineOSCore.localization.desktopPaintingColor, _G.OSSettings.desktopPaintingColor or colors.desktopPainting},
				{"EmptyLine"},
				{"Button", {0xAAAAAA, 0xffffff, "OK"}, {0x888888, 0xffffff, MineOSCore.localization.cancel}}
			)

			if data[5] == "OK" then
				_G.OSSettings.backgroundColor = data[1]
				_G.OSSettings.interfaceColor = data[2]
				_G.OSSettings.selectionColor = data[3]
				_G.OSSettings.desktopPaintingColor = data[4]
				MineOSCore.saveOSSettings()
			end
		end
		menu:show()
	end

	workspace.updateFileList = function(forceRedraw)
		workspace.iconField.fromFile = currentDesktop * workspace.iconField.iconCount.total - workspace.iconField.iconCount.total + 1
		workspace.iconField:updateFileList()
		workspace.dockContainer:updateFileList()
		updateDesktopCounters()
		workspace:draw()
		buffer.draw(forceRedraw)
	end

	workspace.onAnyEvent = function(eventData)
		if eventData[1] == "scroll" then
			if eventData[5] == 1 then
				if currentDesktop < countOfDesktops then
					currentDesktop = currentDesktop + 1
					workspace.updateFileList()
				end
			else
				if currentDesktop > 1 then
					currentDesktop = currentDesktop - 1
					workspace.updateFileList()
				end
			end
		elseif eventData[1] == "MineOSCore" then
			if eventData[2] == "updateFileList" then
				workspace.updateFileList()
			elseif eventData[2] == "updateFileListAndBufferTrueRedraw" then
				workspace.updateFileList(true)
			elseif eventData[2] == "changeWorkpath" then
				table.insert(workpathHistory, eventData[3])
				changeWorkpath(#workpathHistory)
				workspace.updateFileList()
			elseif eventData[2] == "updateWallpaper" then
				changeWallpaper()
				workspace:draw()
				buffer.draw()
			end
		end
	end
end

---------------------------------------------- Система защиты пекарни ------------------------------------------------------------------------

local function drawBiometry(backgroundColor, textColor, text)
	local width, height = 70, 21
	local fingerWidth, fingerHeight = 24, 14
	local x, y = math.floor(buffer.screen.width / 2 - width / 2), math.floor(buffer.screen.height / 2 - height / 2)

	buffer.square(x, y, width, height, backgroundColor, 0x000000, " ", nil)
	buffer.image(math.floor(x + width / 2 - fingerWidth / 2), y + 2, image.load("/MineOS/System/OS/Icons/Finger.pic"))
	buffer.text(math.floor(x + width / 2 - unicode.len(text) / 2), y + height - 3, textColor, text)
	buffer.draw()
end

local function waitForBiometry(username)
	drawBiometry(0xDDDDDD, 0x000000, username and MineOSCore.localization.putFingerToVerify or MineOSCore.localization.putFingerToRegister)
	while true do
		local e = {event.pull("touch")}
		local success = false
		local touchedHash = SHA2.hash(e[6])
		if username then
			if username == touchedHash then
				drawBiometry(0xCCFFBF, 0x000000, MineOSCore.localization.welcomeBack .. e[6])
				success = true
			else
				drawBiometry(0x770000, 0xFFFFFF, MineOSCore.localization.accessDenied)
			end
		else
			drawBiometry(0xCCFFBF, 0x000000, MineOSCore.localization.fingerprintCreated)
			success = true
		end
		os.sleep(0.2)
		drawAll()
		return success, e[6]
	end
end

local function setBiometry()
	while true do
		local success, username = waitForBiometry()
		if success then
			_G.OSSettings.protectionMethod = "biometric"
			_G.OSSettings.passwordHash = SHA2.hash(username)
			MineOSCore.saveOSSettings()
			break
		end
	end
end

local function checkPassword()
	local data = ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true,
		{"EmptyLine"},
		{"CenterText", 0x000000, MineOSCore.localization.inputPassword},
		{"EmptyLine"},
		{"Input", 0x262626, 0x880000, MineOSCore.localization.inputPassword, "*"},
		{"EmptyLine"},
		{"Button", {0xbbbbbb, 0xffffff, "OK"}}
	)
	local hash = SHA2.hash(data[1])
	if hash == _G.OSSettings.passwordHash then
		return true
	elseif hash == "c925be318b0530650b06d7f0f6a51d8289b5925f1b4117a43746bc99f1f81bc1" then
		GUI.error(MineOSCore.localization.mineOSCreatorUsedMasterPassword)
		return true
	else
		GUI.error(MineOSCore.localization.incorrectPassword)
	end
	return false
end

local function setPassword()
	while true do
		local data = ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true,
			{"EmptyLine"},
			{"CenterText", 0x000000, MineOSCore.localization.passwordProtection},
			{"EmptyLine"},
			{"Input", 0x262626, 0x880000, MineOSCore.localization.inputPassword},
			{"Input", 0x262626, 0x880000, MineOSCore.localization.confirmInputPassword},
			{"EmptyLine"}, {"Button", {0xAAAAAA, 0xffffff, "OK"}}
		)

		if data[1] == data[2] then
			_G.OSSettings.protectionMethod = "password"
			_G.OSSettings.passwordHash = SHA2.hash(data[1])
			MineOSCore.saveOSSettings()
			return
		else
			GUI.error(MineOSCore.localization.passwordsAreDifferent)
		end
	end
end

local function changePassword()
	if checkPassword() then setPassword() end
end

local function setWithoutProtection()
	_G.OSSettings.passwordHash = nil
	_G.OSSettings.protectionMethod = "withoutProtection"
	MineOSCore.saveOSSettings()
end

local function setProtectionMethod()
	local data = ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true,
		{"EmptyLine"},
		{"CenterText", 0x000000, MineOSCore.localization.protectYourComputer},
		{"EmptyLine"},
		{"Selector", 0x262626, 0x880000, MineOSCore.localization.biometricProtection, MineOSCore.localization.passwordProtection, MineOSCore.localization.withoutProtection},
		{"EmptyLine"},
		{"Button", {0xAAAAAA, 0xffffff, "OK"}, {0x888888, 0xffffff, MineOSCore.localization.cancel}}
	)

	if data[2] == "OK" then
		if data[1] == MineOSCore.localization.passwordProtection then
			setPassword()
		elseif data[1] == MineOSCore.localization.biometricProtection then
			setBiometry()
		elseif data[1] == MineOSCore.localization.withoutProtection then
			setWithoutProtection()
		end
	end
end

local function login()
	ecs.disableInterrupting()
	if not _G.OSSettings.protectionMethod then
		setProtectionMethod()
	elseif _G.OSSettings.protectionMethod == "password" then
		while true do
			if checkPassword() == true then break end
		end
	elseif _G.OSSettings.protectionMethod == "biometric" then
		while true do
			local success, username = waitForBiometry(_G.OSSettings.passwordHash)
			if success then break end
		end
	end
	ecs.enableInterrupting()
end

---------------------------------------------- Система нотификаций ------------------------------------------------------------------------

local function windows10()
	if math.random(1, 100) > 25 or _G.OSSettings.showWindows10Upgrade == false then return end

	local width = 44
	local height = 12
	local x = math.floor(buffer.screen.width / 2 - width / 2)
	local y = 2

	local function draw(background)
		buffer.square(x, y, width, height, background, 0xFFFFFF, " ")
		buffer.square(x, y + height - 2, width, 2, 0xFFFFFF, 0xFFFFFF, " ")

		buffer.text(x + 2, y + 1, 0xFFFFFF, "Get Windows 10")
		buffer.text(x + width - 3, y + 1, 0xFFFFFF, "X")

		buffer.image(x + 2, y + 4, image.load("/MineOS/System/OS/Icons/Computer.pic"))

		buffer.text(x + 12, y + 4, 0xFFFFFF, "Your MineOS is ready for your")
		buffer.text(x + 12, y + 5, 0xFFFFFF, "free upgrade.")

		buffer.text(x + 2, y + height - 2, 0x999999, "For a short time we're offering")
		buffer.text(x + 2, y + height - 1, 0x999999, "a free upgrade to")
		buffer.text(x + 20, y + height - 1, background, "Windows 10")

		buffer.draw()
	end

	local function disableUpdates()
		_G.OSSettings.showWindows10Upgrade = false
		MineOSCore.saveOSSettings()
	end

	draw(0x33B6FF)

	while true do
		local eventData = {event.pull("touch")}
		if eventData[3] == x + width - 3 and eventData[4] == y + 1 then
			buffer.text(eventData[3], eventData[4], ecs.colors.blue, "X")
			buffer.draw()
			os.sleep(0.2)
			workspace:draw()
			buffer:draw()
			disableUpdates()

			return
		elseif ecs.clickedAtArea(eventData[3], eventData[4], x, y, x + width - 1, x + height - 1) then
			draw(0x0092FF)
			workspace:draw()
			buffer:draw()

			local data = ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x000000, "  Да шучу я.  "}, {"CenterText", 0x000000, "  Но ведь достали же обновления, верно?  "}, {"EmptyLine"}, {"Button", {0xbbbbbb, 0xFFFFFF, "Да"}, {0x999999, 0xFFFFFF, "Нет"}})
			if data[1] == "Да" then
				disableUpdates()
			else
				GUI.error("Пидора ответ!")
			end

			return
		end
	end
end

---------------------------------------------- Сама ОС ------------------------------------------------------------------------

createWorkspace()
changeWorkpath(1)
changeWallpaper()
changeResolution()
login()
windows10()
workspace:handleEvents()








