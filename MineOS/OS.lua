
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
copyright = nil

---------------------------------------------- Адаптивная загрузка библиотек ------------------------------------------------------------------------

-- package.loaded.MineOSCore = nil

local component = require("component")
local unicode = require("unicode")
local fs = require("filesystem")
local event = require("event")
local image = require("image")
local buffer = require("doubleBuffering")
local GUI = require("GUI")
local MineOSCore = require("MineOSCore")
local ecs = require("ECSAPI")

---------------------------------------------- Базовые константы ------------------------------------------------------------------------

local colors = {
	background = 0x1B1B1B,
	topBarTransparency = 20,
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

local screensaversPath, screensaverTimer = MineOSCore.paths.system .. "OS/Screensavers/", 0

local currentWorkpathHistoryIndex, workpathHistory = 1, {MineOSCore.paths.desktop}
local workspace
local currentDesktop, countOfDesktops = 1


---------------------------------------------- Система защиты пекарни ------------------------------------------------------------------------

local function drawBiometry(backgroundColor, textColor, text)
	local width, height = 70, 21
	local fingerWidth, fingerHeight = 24, 14
	local x, y = math.floor(buffer.screen.width / 2 - width / 2), math.floor(buffer.screen.height / 2 - height / 2)

	buffer.square(x, y, width, height, backgroundColor, 0x000000, " ", nil)
	buffer.image(math.floor(x + width / 2 - fingerWidth / 2), y + 2, image.fromString([[180E0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 000000 000000 000000 000000 000000 000000 000000 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 000000 000000 000000 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 000000 000000 000000 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 000000 000000 000000 0000FF 0000FF 0000FF 0000FF 000000 000000 000000 000000 0000FF 0000FF 0000FF 0000FF 0000FF 000000 000000 0000FF 0000FF 0000FF 0000FF 0000FF 000000 000000 0000FF 0000FF 0000FF 000000 000000 000000 000000 0000FF 0000FF 000000 000000 000000 000000 0000FF 0000FF 0000FF 000000 000000 0000FF 0000FF 0000FF 000000 000000 0000FF 0000FF 0000FF 000000 000000 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 000000 000000 0000FF 0000FF 000000 0000FF 0000FF 000000 000000 0000FF 0000FF 0000FF 000000 000000 0000FF 0000FF 0000FF 000000 000000 000000 000000 000000 000000 0000FF 0000FF 000000 0000FF 0000FF 000000 000000 0000FF 000000 0000FF 0000FF 0000FF 000000 0000FF 0000FF 0000FF 0000FF 000000 000000 0000FF 0000FF 0000FF 0000FF 000000 000000 0000FF 000000 000000 0000FF 0000FF 000000 0000FF 000000 0000FF 0000FF 0000FF 000000 000000 0000FF 0000FF 000000 0000FF 0000FF 0000FF 000000 000000 0000FF 0000FF 000000 0000FF 0000FF 000000 0000FF 0000FF 000000 000000 0000FF 000000 0000FF 0000FF 0000FF 000000 0000FF 0000FF 000000 000000 0000FF 0000FF 0000FF 000000 0000FF 0000FF 000000 0000FF 0000FF 000000 0000FF 0000FF 000000 0000FF 0000FF 000000 000000 0000FF 0000FF 000000 0000FF 0000FF 0000FF 000000 0000FF 0000FF 0000FF 0000FF 0000FF 000000 000000 0000FF 000000 0000FF 0000FF 000000 000000 0000FF 0000FF 0000FF 000000 0000FF 0000FF 000000 000000 0000FF 0000FF 0000FF 000000 0000FF 0000FF 0000FF 0000FF 000000 0000FF 000000 0000FF 0000FF 0000FF 000000 0000FF 0000FF 0000FF 0000FF 000000 000000 0000FF 0000FF 000000 000000 0000FF 0000FF 000000 000000 0000FF 0000FF 0000FF 0000FF 000000 000000 0000FF 000000 000000 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 000000 000000 0000FF 0000FF 000000 000000 0000FF 0000FF 0000FF 0000FF 0000FF 000000 000000 000000 0000FF 000000 000000 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 000000 000000 0000FF 0000FF 000000 000000 0000FF 0000FF 0000FF 0000FF 000000 0000FF 0000FF 000000 000000 0000FF 0000FF 0000FF 0000FF 0000FF ]]))
	buffer.text(math.floor(x + width / 2 - unicode.len(text) / 2), y + height - 3, textColor, text)
	buffer.draw()
end

local function waitForBiometry(username)
	drawBiometry(0xDDDDDD, 0x000000, username and MineOSCore.localization.putFingerToVerify or MineOSCore.localization.putFingerToRegister)
	while true do
		local e = {event.pull("touch")}
		local success = false
		local touchedHash = require("SHA2").hash(e[6])
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
		workspace:draw()
		buffer.draw()
		return success, e[6]
	end
end

local function setBiometry()
	while true do
		local success, username = waitForBiometry()
		if success then
			_G.OSSettings.protectionMethod = "biometric"
			_G.OSSettings.passwordHash = require("SHA2").hash(username)
			MineOSCore.saveOSSettings()
			break
		end
	end
end

local function checkPassword()
	local container = GUI.addUniversalContainer(workspace, MineOSCore.localization.inputPassword)
	local inputTextBox = container.layout:addInputTextBox(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0xEEEEEE, 0x262626, nil, "Password", true, "*")
	local label = container.layout:addLabel(1, 1, 36, 1, 0xFF4940, " "):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)

	workspace:draw()
	buffer.draw()

	container.panel.onTouch = function()	
		local hash = require("SHA2").hash(inputTextBox.text or "")
		if hash == _G.OSSettings.passwordHash then
			container:delete()
			workspace:draw()
			buffer.draw()
		elseif hash == "c925be318b0530650b06d7f0f6a51d8289b5925f1b4117a43746bc99f1f81bc1" then
			GUI.error(MineOSCore.localization.mineOSCreatorUsedMasterPassword)
			container:delete()
			workspace:draw()
			buffer.draw()
		else
			label.text = MineOSCore.localization.incorrectPassword
			workspace:draw()
			buffer.draw()
		end
	end
end

local function setPassword()
	local container = GUI.addUniversalContainer(workspace, MineOSCore.localization.passwordProtection)
	local inputTextBox1 = container.layout:addInputTextBox(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0xEEEEEE, 0x262626, nil, MineOSCore.localization.inputPassword, true, "*")
	local inputTextBox2 = container.layout:addInputTextBox(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0xEEEEEE, 0x262626, nil, MineOSCore.localization.confirmInputPassword, true, "*")

	workspace:draw()
	buffer.draw()

	container.panel.onTouch = function()	
		if inputTextBox1.text == inputTextBox2.text then
			container:delete()
			
			_G.OSSettings.protectionMethod = "password"
			_G.OSSettings.passwordHash = require("SHA2").hash(inputTextBox1.text or "")
			MineOSCore.saveOSSettings()

			workspace:draw()
			buffer.draw()
		else
			GUI.error(MineOSCore.localization.passwordsAreDifferent)
		end
	end
end

local function setWithoutProtection()
	_G.OSSettings.passwordHash = nil
	_G.OSSettings.protectionMethod = "withoutProtection"
	MineOSCore.saveOSSettings()
end

local function setProtectionMethod()
	local container = GUI.addUniversalContainer(workspace, MineOSCore.localization.protectYourComputer)
	
	local comboBox = container.layout:addComboBox(1, 1, 36, 3, 0xEEEEEE, 0x262626, 0x666666, 0xEEEEEE)
	comboBox:addItem(MineOSCore.localization.biometricProtection)
	comboBox:addItem(MineOSCore.localization.passwordProtection)
	comboBox:addItem(MineOSCore.localization.withoutProtection)

	workspace:draw()
	buffer.draw()

	container.panel.onTouch = function()
		container:delete()
		workspace:draw()
		buffer.draw()

		if comboBox.currentItem == 1 then
			setBiometry()
		elseif comboBox.currentItem == 2 then
			setPassword()
		elseif comboBox.currentItem == 3 then
			setWithoutProtection()
		end
	end
end

local function login()
	event.interuptingEnabled = false
	if not _G.OSSettings.protectionMethod then
		setProtectionMethod()
	elseif _G.OSSettings.protectionMethod == "password" then
		checkPassword()
	elseif _G.OSSettings.protectionMethod == "biometric" then
		while true do
			local success, username = waitForBiometry(_G.OSSettings.passwordHash)
			if success then break end
		end
	end
	event.interuptingEnabled = true
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
		if ecs.clickedAtArea(eventData[3], eventData[4], x, y, x + width - 1, x + height - 1) then
			draw(0x0092FF)
			os.sleep(0.2)
			workspace:draw()
			buffer.draw()
			disableUpdates()
			return
		end
	end
end

---------------------------------------------- Основные функции ------------------------------------------------------------------------

local function changeWallpaper()
	if _G.OSSettings.wallpaper and fs.exists(_G.OSSettings.wallpaper) then
		workspace.wallpaper.image = image.load(_G.OSSettings.wallpaper)
		workspace.wallpaper.isHidden = false
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
	workspace.desktopCounters.children = {}
	local x = 1
	if #workpathHistory > 1 then
		workspace.desktopCounters:addButton(x, 1, 1, 1, nil, 0xEEEEEE, nil, 0x888888, "<").onTouch = function()
			table.remove(workpathHistory, #workpathHistory)
			changeWorkpath(#workpathHistory)
			workspace.updateAndDraw()
		end; x = x + 3
	end
	if workpathHistory[currentWorkpathHistoryIndex] ~= "/" then
		workspace.desktopCounters:addButton(x, 1, 4, 1, nil, 0xEEEEEE, nil, 0x888888, "Root").onTouch = function()
			table.insert(workpathHistory, "/")
			changeWorkpath(#workpathHistory)
			workspace.updateAndDraw()
		end; x = x + 6
	end
	if workpathHistory[currentWorkpathHistoryIndex] ~= MineOSCore.paths.desktop then
		workspace.desktopCounters:addButton(x, 1, 7, 1, nil, 0xEEEEEE, nil, 0x888888, "Desktop").onTouch = function()
			table.insert(workpathHistory, MineOSCore.paths.desktop)
			changeWorkpath(#workpathHistory)
			workspace.updateAndDraw()
		end; x = x + 9
	end
	if countOfDesktops > 1 then
		for i = 1, countOfDesktops do
			workspace.desktopCounters:addButton(x, 1, 1, 1, nil, i == currentDesktop and 0xEEEEEE or 0xBBBBBB, nil, 0x888888, "●").onTouch = function()
				if currentDesktop ~= i then
					currentDesktop = i
					workspace.updateAndDraw()
				end
			end; x = x + 3
		end
	end

	workspace.desktopCounters.width = x - 3
	workspace.desktopCounters.localPosition.x = math.floor(workspace.width / 2 - workspace.desktopCounters.width / 2)
	workspace.desktopCounters.localPosition.y = workspace.height - sizes.heightOfDock - 2
end

local function updateDock()
	local function moveDockShortcut(iconIndex, direction)
		_G.OSSettings.dockShortcuts[iconIndex], _G.OSSettings.dockShortcuts[iconIndex + direction] = swap(_G.OSSettings.dockShortcuts[iconIndex], _G.OSSettings.dockShortcuts[iconIndex + direction])
		MineOSCore.saveOSSettings()
		updateDock()
		workspace:draw()
		buffer.draw()
	end

	workspace.dockContainer.width = (#_G.OSSettings.dockShortcuts + 1) * (MineOSCore.iconWidth + sizes.xSpaceBetweenIcons) - sizes.xSpaceBetweenIcons
	workspace.dockContainer.localPosition.x = math.floor(workspace.width / 2 - workspace.dockContainer.width / 2)
	workspace.dockContainer.localPosition.y = workspace.height - sizes.heightOfDock + 1
	workspace.dockContainer:deleteChildren()

	local xPos = 1
	for iconIndex = 1, #_G.OSSettings.dockShortcuts do
		local icon = MineOSCore.createIcon(xPos, 1, _G.OSSettings.dockShortcuts[iconIndex].path, 0x262626, _G.OSSettings.showExtension)
			
		icon.onRightClick = function(icon, eventData)
			local menu = GUI.contextMenu(eventData[3], eventData[4])
			menu:addItem(MineOSCore.localization.contextMenuShowContainingFolder).onTouch = function()
				table.insert(workpathHistory, fs.path(icon.path))
				changeWorkpath(#workpathHistory)
				workspace.updateAndDraw()
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
				updateDock()
				workspace:draw()
				buffer.draw()
			end
			menu:show()
		end

		workspace.dockContainer:addChild(icon, GUI.objectTypes.container)
		xPos = xPos + MineOSCore.iconWidth + sizes.xSpaceBetweenIcons
	end

	local icon = MineOSCore.createIcon(xPos, 1, MineOSCore.paths.trash, 0x262626, _G.OSSettings.showExtension)
	icon.iconImage.image = MineOSCore.icons.trash
	icon.onRightClick = function(icon, eventData)
		local menu = GUI.contextMenu(eventData[3], eventData[4])
		menu:addItem(MineOSCore.localization.emptyTrash).onTouch = function()
			local container = GUI.addUniversalContainer(workspace, MineOSCore.localization.areYouSure)
			
			container.layout:addButton(1, 1, 30, 3, 0xEEEEEE, 0x262626, 0xA, 0x262626, "OK").onTouch = function()
				for file in fs.list(MineOSCore.paths.trash) do
					fs.remove(MineOSCore.paths.trash .. file)
				end
				container:delete()
				workspace.updateAndDraw()
			end

			container.panel.onTouch = function()	
				container:delete()
				workspace:draw()
				buffer.draw()
			end

			workspace:draw()
			buffer.draw()
		end
		menu:show()
	end

	workspace.dockContainer:addChild(icon, GUI.objectTypes.container)
end

-- Отрисовка дока
local function createDock()
	workspace.dockContainer = workspace:addContainer(1, 1, workspace.width, sizes.heightOfDock)

	-- Отрисовка дока
	local oldDraw = workspace.dockContainer.draw
	workspace.dockContainer.draw = function(dockContainer)
		local currentDockTransparency, currentDockWidth, xPos, yPos = colors.dockBaseTransparency, dockContainer.width, dockContainer.x, dockContainer.y + 2
		local color = _G.OSSettings.interfaceColor or colors.interface
		for i = 1, dockContainer.height do
			buffer.text(xPos, yPos, color, "▟", currentDockTransparency)
			buffer.square(xPos + 1, yPos, currentDockWidth - 2, 1, color, 0xFFFFFF, " ", currentDockTransparency)
			buffer.text(xPos + currentDockWidth - 1, yPos, color, "▙", currentDockTransparency)

			currentDockTransparency, currentDockWidth, xPos, yPos = currentDockTransparency - colors.dockTransparencyAdder, currentDockWidth + 2, xPos - 1, yPos + 1
		end

		oldDraw(dockContainer)
	end
end

local function changeResolution()
	currentDesktop = 1
	buffer.setResolution(table.unpack(_G.OSSettings.resolution or {160, 50}))

	workspace.width, workspace.height = buffer.screen.width, buffer.screen.height

	workspace.iconField.iconCount.width, workspace.iconField.iconCount.height, workspace.iconField.iconCount.total =  MineOSCore.getParametersForDrawingIcons(workspace.width, workspace.height - sizes.heightOfDock - 5, sizes.xSpaceBetweenIcons, sizes.ySpaceBetweenIcons)
	workspace.iconField.localPosition.x = math.floor(workspace.width / 2 - (workspace.iconField.iconCount.width * (MineOSCore.iconWidth + sizes.xSpaceBetweenIcons) - sizes.xSpaceBetweenIcons) / 2)
	workspace.iconField.localPosition.y = 3

	workspace.menu.width = workspace.width
	workspace.background.width, workspace.background.height = workspace.width, workspace.height
end

local function createWorkspace()
	workspace = GUI.fullScreenWindow()
	workspace.background = workspace:addPanel(1, 1, workspace.width, workspace.height, _G.OSSettings.backgroundColor or colors.background)
	workspace.wallpaper = workspace:addImage(1, 1, {workspace.width, workspace.height})

	workspace.desktopCounters = workspace:addContainer(1, 1, 1, 1)

	workspace.iconField = workspace:addChild(
		MineOSCore.createIconField(
			1, 1, 1, 1, 1, 1, 1,
			sizes.xSpaceBetweenIcons,
			sizes.ySpaceBetweenIcons,
			0xFFFFFF,
			_G.OSSettings.showExtension == nil and true or _G.OSSettings.showExtension,
			_G.OSSettings.showHiddenFiles == nil and true or _G.OSSettings.showHiddenFiles,
			(_G.OSSettings.sortingMethod or "type"),
			"/"
		),
		GUI.objectTypes.container
	)

	createDock()

	workspace.menu = workspace:addMenu(1, 1, workspace.width, _G.OSSettings.interfaceColor or colors.interface, 0x444444, 0x3366CC, 0xFFFFFF, colors.topBarTransparency)
	local item1 = workspace.menu:addItem("MineOS", 0x000000)
	item1.onTouch = function()
		local menu = GUI.contextMenu(item1.x, item1.y + 1)
		-- menu:addItem(MineOSCore.localization.aboutSystem).onTouch = function()
		-- 	ecs.prepareToExit()
		-- 	print(copyright)
		-- 	ecs.waitForTouchOrClick()
		-- 	buffer.draw(true)
		-- end
		menu:addItem(MineOSCore.localization.updates).onTouch = function()
			MineOSCore.safeLaunch("/MineOS/Applications/AppMarket.app/Main.lua", "updateCheck")
		end
		menu:addSeparator()
		menu:addItem(MineOSCore.localization.logout, _G.OSSettings.protectionMethod == "withoutProtection").onTouch = function()
			login()
		end
		menu:addItem(MineOSCore.localization.reboot).onTouch = function()
			-- ecs.TV(0)
			require("computer").shutdown(true)
			dofile("/bin/reboot.lua")
		end
		menu:addItem(MineOSCore.localization.shutdown).onTouch = function()
			-- ecs.TV(0)
			require("computer").shutdown()
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
		menu:addItem(workspace.iconField.showExtension and MineOSCore.localization.hideExtension or MineOSCore.localization.showExtension).onTouch = function()
			workspace.iconField.showExtension = not workspace.iconField.showExtension
			_G.OSSettings.showExtension = workspace.iconField.showExtension
			MineOSCore.saveOSSettings()
			workspace.updateAndDraw()
		end
		menu:addItem(workspace.iconField.showHiddenFiles and MineOSCore.localization.hideHiddenFiles or MineOSCore.localization.showHiddenFiles).onTouch = function()
			workspace.iconField.showHiddenFiles = not workspace.iconField.showHiddenFiles
			_G.OSSettings.showHiddenFiles = workspace.iconField.showHiddenFiles
			MineOSCore.saveOSSettings()
			workspace.updateAndDraw()
		end
		menu:addItem(MineOSCore.showApplicationIcons and MineOSCore.localization.hideApplicationIcons or  MineOSCore.localization.showApplicationIcons).onTouch = function()
			MineOSCore.showApplicationIcons = not MineOSCore.showApplicationIcons
			workspace.updateAndDraw()
		end
		menu:addSeparator()
		menu:addItem(MineOSCore.localization.sortByName).onTouch = function()
			_G.OSSettings.sortingMethod = "name"
			MineOSCore.saveOSSettings()
			workspace.iconField.sortingMethod = _G.OSSettings.sortingMethod
			workspace.updateAndDraw()
		end
		menu:addItem(MineOSCore.localization.sortByDate).onTouch = function()
			_G.OSSettings.sortingMethod = "date"
			MineOSCore.saveOSSettings()
			workspace.iconField.sortingMethod = _G.OSSettings.sortingMethod
			workspace.updateAndDraw()
		end
		menu:addItem(MineOSCore.localization.sortByType).onTouch = function()
			_G.OSSettings.sortingMethod = "type"
			MineOSCore.saveOSSettings()
			workspace.iconField.sortingMethod = _G.OSSettings.sortingMethod
			workspace.updateAndDraw()
		end
		menu:addSeparator()
		menu:addItem(MineOSCore.localization.screensaver).onTouch = function()
			local container = GUI.addUniversalContainer(workspace, MineOSCore.localization.screensaver)
			
			local comboBox = container.layout:addComboBox(1, 1, 36, 3, 0xEEEEEE, 0x262626, 0x666666, 0xEEEEEE)
			comboBox:addItem(MineOSCore.localization.screensaverDisabled)
			for file in fs.list(screensaversPath) do
				comboBox:addItem(fs.hideExtension(file))
			end
			local slider = container.layout:addHorizontalSlider(1, 1, 36, 0xFFDB40, 0xEEEEEE, 0xFFDB80, 0xBBBBBB, 1, 100, _G.OSSettings.screensaverDelay or 20, false, MineOSCore.localization.screensaverDelay .. ": ", "")

			workspace:draw()
			buffer.draw()

			container.panel.onTouch = function()
				container:delete()
				if comboBox.currentItem == 1 then
					_G.OSSettings.screensaver = nil
				else
					_G.OSSettings.screensaver, _G.OSSettings.screensaverDelay = comboBox.items[comboBox.currentItem].text, slider.value
				end
				MineOSCore.saveOSSettings()

				workspace:draw()
				buffer.draw()
			end
		end
		menu:addItem(MineOSCore.localization.colorScheme).onTouch = function()
			local container = GUI.addUniversalContainer(workspace, MineOSCore.localization.colorScheme)
			
			local backgroundColorSelector = container.layout:addColorSelector(1, 1, 36, 3, workspace.background.colors.background, MineOSCore.localization.backgroundColor)
			local interfaceColorSelector = container.layout:addColorSelector(1, 1, 36, 3, workspace.menu.colors.default.background, MineOSCore.localization.interfaceColor)
			
			backgroundColorSelector.onTouch = function()
				_G.OSSettings.backgroundColor, _G.OSSettings.interfaceColor = backgroundColorSelector.color, interfaceColorSelector.color
				workspace.background.colors.background, workspace.menu.colors.default.background = _G.OSSettings.backgroundColor, _G.OSSettings.interfaceColor
				MineOSCore.saveOSSettings()
				
				workspace:draw()
				buffer.draw()
			end
			interfaceColorSelector.onTouch = backgroundColorSelector.onTouch

			workspace:draw()
			buffer.draw()

			container.panel.onTouch = function()
				container:delete()
				workspace:draw()
				buffer.draw()
			end
		end
		menu:addItem(MineOSCore.localization.contextMenuRemoveWallpaper, workspace.wallpaper.isHidden).onTouch = function()
			_G.OSSettings.wallpaper = nil
			MineOSCore.saveOSSettings()
			changeWallpaper()
		end
		menu:show()
	end

	local item3 = workspace.menu:addItem(MineOSCore.localization.settings)
	item3.onTouch = function()
		local menu = GUI.contextMenu(item3.x, item3.y + 1)
		menu:addItem(MineOSCore.localization.screenResolution).onTouch = function()
			local container = GUI.addUniversalContainer(workspace, MineOSCore.localization.screenResolution)
			
			local widthTextBox = container.layout:addInputTextBox(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0xEEEEEE, 0x262626, tostring(_G.OSSettings.resolution and _G.OSSettings.resolution[1] or 160), "Width", true)
			widthTextBox.validator = function(text)
				local number = tonumber(text)
				if number then return number >= 1 and number <= 160 end
			end

			local heightTextBox = container.layout:addInputTextBox(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0xEEEEEE, 0x262626, tostring(_G.OSSettings.resolution and _G.OSSettings.resolution[2] or 50), "Height", true)
			heightTextBox.validator = function(text)
				local number = tonumber(text)
				if number then return number >= 1 and number <= 50 end
			end

			container.panel.onTouch = function()
				container:delete()
				_G.OSSettings.resolution = {tonumber(widthTextBox.text), tonumber(heightTextBox.text)}
				MineOSCore.saveOSSettings()
				changeResolution()
				workspace.updateAndDraw()
			end
		end
		menu:addSeparator()
		menu:addItem(MineOSCore.localization.setProtectionMethod).onTouch = function()
			setProtectionMethod()
		end
		menu:show()
	end

	workspace.update = function()
		workspace.iconField.fromFile = (currentDesktop - 1) * workspace.iconField.iconCount.total + 1
		workspace.iconField:updateFileList()
		updateDock()
		updateDesktopCounters()
	end

	workspace.updateAndDraw = function(forceRedraw)
		workspace.update()
		workspace:draw()
		buffer.draw(forceRedraw)
	end

	workspace.onAnyEvent = function(eventData)
		if eventData[1] == "scroll" then
			if eventData[5] == 1 then
				if currentDesktop < countOfDesktops then
					currentDesktop = currentDesktop + 1
					workspace.updateAndDraw()
				end
			else
				if currentDesktop > 1 then
					currentDesktop = currentDesktop - 1
					workspace.updateAndDraw()
				end
			end
		elseif eventData[1] == "MineOSCore" then
			if eventData[2] == "updateFileList" then
				workspace.updateAndDraw()
			elseif eventData[2] == "updateFileListAndBufferTrueRedraw" then
				workspace.updateAndDraw(true)
			elseif eventData[2] == "changeWorkpath" then
				table.insert(workpathHistory, eventData[3])
				changeWorkpath(#workpathHistory)
			elseif eventData[2] == "updateWallpaper" then
				changeWallpaper()
				workspace:draw()
				buffer.draw()
			elseif eventData[2] == "newApplication" then
				MineOSCore.newApplication(workspace, workspace.iconField.workpath)
			elseif eventData[2] == "newFile" then
				MineOSCore.newFile(workspace, workspace.iconField.workpath)
			elseif eventData[2] == "newFolder" then
				MineOSCore.newFolder(workspace, workspace.iconField.workpath)
			elseif eventData[2] == "rename" then
				MineOSCore.rename(workspace, eventData[3])
			elseif eventData[2] == "applicationHelp" then
				MineOSCore.applicationHelp(workspace, eventData[3])
			end
		elseif not eventData[1] then
			screensaverTimer = screensaverTimer + 0.5
			if _G.OSSettings.screensaver and screensaverTimer > _G.OSSettings.screensaverDelay and fs.exists(screensaversPath .. _G.OSSettings.screensaver .. ".lua") then
				MineOSCore.safeLaunch(screensaversPath .. _G.OSSettings.screensaver .. ".lua")
				screensaverTimer = 0
				workspace:draw()
				buffer.draw(true)
			end
		else
			screensaverTimer = 0
		end
	end
end

---------------------------------------------- Сама ОС ------------------------------------------------------------------------

createWorkspace()
changeResolution()
changeWorkpath(1)
changeWallpaper()
workspace.update()
login()
windows10()
workspace:handleEvents(0.5)






