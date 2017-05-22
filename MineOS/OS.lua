
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
-- Сколько тут, раз, два, три... 286 UTF-8 символов!
-- А это, между прочим, 57 раз по слову "Пидор". Но один раз - не пидорас, поэтому очищаем.
copyright = nil

---------------------------------------------- Либсы-хуибсы ------------------------------------------------------------------------

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

---------------------------------------------- Всякая константная залупа ------------------------------------------------------------------------

local colors = {
	background = 0x1B1B1B,
	topBarTransparency = 20,
	selection = ecs.colors.lightBlue,
	interface = 0xCCCCCC,
	dockBaseTransparency = 60,
	dockTransparencyAdder = 8,
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
local currentDesktop, countOfDesktops = 1

---------------------------------------------- Система защиты пекарни ------------------------------------------------------------------------

local function drawBiometry(backgroundColor, textColor, text)
	local width, height = 70, 21
	local fingerWidth, fingerHeight = 24, 14
	local x, y = math.floor(buffer.width / 2 - width / 2), math.floor(buffer.height / 2 - height / 2)

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
		MineOSCore.OSMainContainer:draw()
		buffer.draw()
		return success, e[6]
	end
end

local function setBiometry()
	while true do
		local success, username = waitForBiometry()
		if success then
			MineOSCore.OSSettings.protectionMethod = "biometric"
			MineOSCore.OSSettings.passwordHash = require("SHA2").hash(username)
			MineOSCore.saveOSSettings()
			break
		end
	end
end

local function checkPassword()
	local container = MineOSCore.addUniversalContainer(MineOSCore.OSMainContainer, MineOSCore.localization.inputPassword)
	local inputTextBox = container.layout:addChild(GUI.inputTextBox(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0xEEEEEE, 0x262626, nil, "Password", true, "*"))
	local label = container.layou:addChild(GUI.label(1, 1, 36, 1, 0xFF4940, " ")):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)

	container.panel.eventHandler = function(mainContainer, object, eventData)
		if eventData[1] == "touch" then
			local hash = require("SHA2").hash(inputTextBox.text or "")
			if hash == MineOSCore.OSSettings.passwordHash then
				container:delete()
				MineOSCore.OSMainContainer:draw()
				buffer.draw()
			elseif hash == "c925be318b0530650b06d7f0f6a51d8289b5925f1b4117a43746bc99f1f81bc1" then
				GUI.error(MineOSCore.localization.mineOSCreatorUsedMasterPassword)
				container:delete()
				MineOSCore.OSMainContainer:draw()
				buffer.draw()
			else
				label.text = MineOSCore.localization.incorrectPassword
				MineOSCore.OSMainContainer:draw()
				buffer.draw()
			end
		end
	end
end

local function setPassword()
	local container = MineOSCore.addUniversalContainer(MineOSCore.OSMainContainer, MineOSCore.localization.passwordProtection)
	local inputTextBox1 = container.layout:addChild(GUI.inputTextBox(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0xEEEEEE, 0x262626, nil, MineOSCore.localization.inputPassword, true, "*"))
	local inputTextBox2 = container.layout:addChild(GUI.inputTextBox(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0xEEEEEE, 0x262626, nil, MineOSCore.localization.confirmInputPassword, true, "*"))
	local label = container.layou:addChild(GUI.label(1, 1, 36, 1, 0xFF4940, " ")):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)

	MineOSCore.OSMainContainer:draw()
	buffer.draw()

	container.panel.eventHandler = function(mainContainer, object, eventData)
		if eventData[1] == "touch" then
			if inputTextBox1.text == inputTextBox2.text then
				container:delete()
				
				MineOSCore.OSSettings.protectionMethod = "password"
				MineOSCore.OSSettings.passwordHash = require("SHA2").hash(inputTextBox1.text or "")
				MineOSCore.saveOSSettings()
			else
				label.text = MineOSCore.localization.passwordsAreDifferent
			end

			MineOSCore.OSMainContainer:draw()
			buffer.draw()
		end
	end
end

local function setWithoutProtection()
	MineOSCore.OSSettings.passwordHash = nil
	MineOSCore.OSSettings.protectionMethod = "withoutProtection"
	MineOSCore.saveOSSettings()
end

local function setProtectionMethod()
	local container = MineOSCore.addUniversalContainer(MineOSCore.OSMainContainer, MineOSCore.localization.protectYourComputer)
	
	local comboBox = container.layout:addChild(GUI.comboBox(1, 1, 36, 3, 0xEEEEEE, 0x262626, 0x666666, 0xEEEEEE))
	comboBox:addItem(MineOSCore.localization.biometricProtection)
	comboBox:addItem(MineOSCore.localization.passwordProtection)
	comboBox:addItem(MineOSCore.localization.withoutProtection)

	container.panel.eventHandler = function(mainContainer, object, eventData)
		if eventData[1] == "touch" then
			container:delete()
			MineOSCore.OSMainContainer:draw()
			buffer.draw()

			if comboBox.selectedItem == 1 then
				setBiometry()
			elseif comboBox.selectedItem == 2 then
				setPassword()
			elseif comboBox.selectedItem == 3 then
				setWithoutProtection()
			end
		end
	end
end

local function login()
	event.interuptingEnabled = false
	if not MineOSCore.OSSettings.protectionMethod then
		setProtectionMethod()
	elseif MineOSCore.OSSettings.protectionMethod == "password" then
		checkPassword()
	elseif MineOSCore.OSSettings.protectionMethod == "biometric" then
		while true do
			local success, username = waitForBiometry(MineOSCore.OSSettings.passwordHash)
			if success then break end
		end
	end
	event.interuptingEnabled = true

	MineOSCore.OSMainContainer:draw()
	buffer.draw()
end

---------------------------------------------- Винда-хуенда ------------------------------------------------------------------------

local function windows10()
	if math.random(1, 100) > 25 or MineOSCore.OSSettings.showWindows10Upgrade == false then
		return
	end

	local width = 44
	local height = 12
	local x = math.floor(buffer.width / 2 - width / 2)
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
		MineOSCore.OSSettings.showWindows10Upgrade = false
		MineOSCore.saveOSSettings()
	end

	draw(0x33B6FF)

	while true do
		local eventData = {event.pull("touch")}
		if ecs.clickedAtArea(eventData[3], eventData[4], x, y, x + width - 1, x + height - 1) then
			draw(0x0092FF)
			os.sleep(0.2)
			MineOSCore.OSMainContainer:draw()
			buffer.draw()
			disableUpdates()
			return
		end
	end
end

---------------------------------------------- Основные функции ------------------------------------------------------------------------

local function changeWallpaper()
	if MineOSCore.OSSettings.wallpaper and fs.exists(MineOSCore.OSSettings.wallpaper) then
		MineOSCore.OSMainContainer.background.wallpaper = image.transform(image.load(MineOSCore.OSSettings.wallpaper), MineOSCore.OSMainContainer.width, MineOSCore.OSMainContainer.height)
	else
		MineOSCore.OSMainContainer.background.wallpaper = nil
	end
end

local function changeWorkpath(newWorkpathHistoryIndex)
	currentDesktop = 1
	currentWorkpathHistoryIndex = newWorkpathHistoryIndex
	MineOSCore.OSMainContainer.iconField.workpath = workpathHistory[currentWorkpathHistoryIndex]
end

local function updateDesktopCounters()
	countOfDesktops = math.ceil(#MineOSCore.OSMainContainer.iconField.fileList / MineOSCore.OSMainContainer.iconField.iconCount.total)
	MineOSCore.OSMainContainer.desktopCounters.children = {}
	local x = 1
	if #workpathHistory > 1 then
		MineOSCore.OSMainContainer.desktopCounters:addChild(GUI.button(x, 1, 1, 1, nil, 0xEEEEEE, nil, 0x888888, "<")).onTouch = function()
			table.remove(workpathHistory, #workpathHistory)
			changeWorkpath(#workpathHistory)
			MineOSCore.OSMainContainer.updateAndDraw()
		end; x = x + 3
	end
	if workpathHistory[currentWorkpathHistoryIndex] ~= "/" then
		MineOSCore.OSMainContainer.desktopCounters:addChild(GUI.button(x, 1, 4, 1, nil, 0xEEEEEE, nil, 0x888888, "Root")).onTouch = function()
			table.insert(workpathHistory, "/")
			changeWorkpath(#workpathHistory)
			MineOSCore.OSMainContainer.updateAndDraw()
		end; x = x + 6
	end
	if workpathHistory[currentWorkpathHistoryIndex] ~= MineOSCore.paths.desktop then
		MineOSCore.OSMainContainer.desktopCounters:addChild(GUI.button(x, 1, 7, 1, nil, 0xEEEEEE, nil, 0x888888, "Desktop")).onTouch = function()
			table.insert(workpathHistory, MineOSCore.paths.desktop)
			changeWorkpath(#workpathHistory)
			MineOSCore.OSMainContainer.updateAndDraw()
		end; x = x + 9
	end
	if countOfDesktops > 1 then
		for i = 1, countOfDesktops do
			MineOSCore.OSMainContainer.desktopCounters:addChild(GUI.button(x, 1, 1, 1, nil, i == currentDesktop and 0xEEEEEE or 0xBBBBBB, nil, 0x888888, "●")).onTouch = function()
				if currentDesktop ~= i then
					currentDesktop = i
					MineOSCore.OSMainContainer.updateAndDraw()
				end
			end; x = x + 3
		end
	end

	MineOSCore.OSMainContainer.desktopCounters.width = x - 3
	MineOSCore.OSMainContainer.desktopCounters.localPosition.x = math.floor(MineOSCore.OSMainContainer.width / 2 - MineOSCore.OSMainContainer.desktopCounters.width / 2)
	MineOSCore.OSMainContainer.desktopCounters.localPosition.y = MineOSCore.OSMainContainer.height - sizes.heightOfDock - 2
end

local function updateDock()
	local function moveDockShortcut(iconIndex, direction)
		MineOSCore.OSSettings.dockShortcuts[iconIndex], MineOSCore.OSSettings.dockShortcuts[iconIndex + direction] = swap(MineOSCore.OSSettings.dockShortcuts[iconIndex], MineOSCore.OSSettings.dockShortcuts[iconIndex + direction])
		MineOSCore.saveOSSettings()
		updateDock()
		MineOSCore.OSMainContainer:draw()
		buffer.draw()
	end

	MineOSCore.OSMainContainer.dockContainer.width = (#MineOSCore.OSSettings.dockShortcuts + 1) * (MineOSCore.iconWidth + sizes.xSpaceBetweenIcons) - sizes.xSpaceBetweenIcons
	MineOSCore.OSMainContainer.dockContainer.localPosition.x = math.floor(MineOSCore.OSMainContainer.width / 2 - MineOSCore.OSMainContainer.dockContainer.width / 2)
	MineOSCore.OSMainContainer.dockContainer.localPosition.y = MineOSCore.OSMainContainer.height - sizes.heightOfDock + 1
	MineOSCore.OSMainContainer.dockContainer:deleteChildren()

	local xPos = 1
	for iconIndex = 1, #MineOSCore.OSSettings.dockShortcuts do
		local icon = MineOSCore.createIcon(xPos, 1, MineOSCore.OSSettings.dockShortcuts[iconIndex].path, 0x262626, MineOSCore.OSSettings.showExtension, 0xFFFFFF)
			
		icon.onRightClick = function(icon, eventData)
			local menu = GUI.contextMenu(eventData[3], eventData[4])
			menu:addItem(MineOSCore.localization.contextMenuShowContainingFolder).onTouch = function()
				table.insert(workpathHistory, fs.path(icon.path))
				changeWorkpath(#workpathHistory)
				MineOSCore.OSMainContainer.updateAndDraw()
			end
			menu:addSeparator()
			menu:addItem(MineOSCore.localization.contextMenuMoveRight, iconIndex >= #MineOSCore.OSSettings.dockShortcuts).onTouch = function()
				moveDockShortcut(iconIndex, 1)
			end
			menu:addItem(MineOSCore.localization.contextMenuMoveLeft, iconIndex <= 1).onTouch = function()
				moveDockShortcut(iconIndex, -1)
			end
			menu:addSeparator()
			menu:addItem(MineOSCore.localization.contextMenuRemoveFromDock, MineOSCore.OSSettings.dockShortcuts[iconIndex].canNotBeDeleted or #MineOSCore.OSSettings.dockShortcuts < 2).onTouch = function()
				table.remove(MineOSCore.OSSettings.dockShortcuts, iconIndex)
				MineOSCore.saveOSSettings()
				updateDock()
				MineOSCore.OSMainContainer:draw()
				buffer.draw()
			end
			menu:show()
		end

		MineOSCore.OSMainContainer.dockContainer:addChild(icon)
		xPos = xPos + MineOSCore.iconWidth + sizes.xSpaceBetweenIcons
	end

	local icon = MineOSCore.createIcon(xPos, 1, MineOSCore.paths.trash, 0x262626, MineOSCore.OSSettings.showExtension, 0xFFFFFF)
	icon.iconImage.image = MineOSCore.icons.trash
	icon.onRightClick = function(icon, eventData)
		local menu = GUI.contextMenu(eventData[3], eventData[4])
		menu:addItem(MineOSCore.localization.emptyTrash).onTouch = function()
			local container = MineOSCore.addUniversalContainer(MineOSCore.OSMainContainer, MineOSCore.localization.areYouSure)
			
			container.layout:addChild(GUI.button(1, 1, 30, 3, 0xEEEEEE, 0x262626, 0xA, 0x262626, "OK")).onTouch = function()
				for file in fs.list(MineOSCore.paths.trash) do
					fs.remove(MineOSCore.paths.trash .. file)
				end
				container:delete()
				MineOSCore.OSMainContainer.updateAndDraw()
			end

			container.panel.onTouch = function()	
				container:delete()
				MineOSCore.OSMainContainer:draw()
				buffer.draw()
			end

			MineOSCore.OSMainContainer:draw()
			buffer.draw()
		end
		menu:show()
	end

	MineOSCore.OSMainContainer.dockContainer:addChild(icon)
end

-- Отрисовка дока
local function createDock()
	MineOSCore.OSMainContainer.dockContainer = MineOSCore.OSMainContainer:addChild(GUI.container(1, 1, MineOSCore.OSMainContainer.width, sizes.heightOfDock))

	-- Отрисовка дока
	local oldDraw = MineOSCore.OSMainContainer.dockContainer.draw
	MineOSCore.OSMainContainer.dockContainer.draw = function(dockContainer)
		local currentDockTransparency, currentDockWidth, xPos, yPos = colors.dockBaseTransparency, dockContainer.width, dockContainer.x, dockContainer.y + 2
		local color = MineOSCore.OSSettings.interfaceColor or colors.interface
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
	buffer.setResolution(table.unpack(MineOSCore.OSSettings.resolution or {160, 50}))

	MineOSCore.OSMainContainer.width, MineOSCore.OSMainContainer.height = buffer.width, buffer.height

	MineOSCore.OSMainContainer.iconField.width, MineOSCore.OSMainContainer.iconField.height = MineOSCore.OSMainContainer.width, MineOSCore.OSMainContainer.height - sizes.heightOfDock - 5
	MineOSCore.OSMainContainer.iconField.iconCount.width, MineOSCore.OSMainContainer.iconField.iconCount.height, MineOSCore.OSMainContainer.iconField.iconCount.total =  MineOSCore.getParametersForDrawingIcons(MineOSCore.OSMainContainer.iconField.width, MineOSCore.OSMainContainer.iconField.height, sizes.xSpaceBetweenIcons, sizes.ySpaceBetweenIcons)
	MineOSCore.OSMainContainer.iconField.localPosition.x = math.floor(MineOSCore.OSMainContainer.width / 2 - (MineOSCore.OSMainContainer.iconField.iconCount.width * (MineOSCore.iconWidth + sizes.xSpaceBetweenIcons) - sizes.xSpaceBetweenIcons) / 2)
	MineOSCore.OSMainContainer.iconField.localPosition.y = 3

	MineOSCore.OSMainContainer.menu.width = MineOSCore.OSMainContainer.width
	MineOSCore.OSMainContainer.background.width, MineOSCore.OSMainContainer.background.height = MineOSCore.OSMainContainer.width, MineOSCore.OSMainContainer.height

	MineOSCore.OSMainContainer.windowsContainer.width, MineOSCore.OSMainContainer.windowsContainer.height = MineOSCore.OSMainContainer.width, MineOSCore.OSMainContainer.height - 1
end

local function createOSWindow()
	MineOSCore.OSMainContainer = GUI.fullScreenContainer()

	MineOSCore.OSMainContainer.background = GUI.object(1, 1, 1, 1)
	MineOSCore.OSMainContainer.background.draw = function(object)
		if object.wallpaper then
			buffer.image(object.x, object.y, object.wallpaper)
		else
			buffer.square(object.x, object.y, object.width, object.height, MineOSCore.OSSettings.backgroundColor or colors.background, 0x0, " ")
		end
	end
	MineOSCore.OSMainContainer.background.eventHandler = function(mainContainer, object, eventData)
		if eventData[1] == "touch" then
			if eventData[5] == 1 then
				MineOSCore.emptyZoneClick(eventData, MineOSCore.OSMainContainer, MineOSCore.OSMainContainer.iconField.workpath)
			end
		end
	end
	MineOSCore.OSMainContainer:addChild(MineOSCore.OSMainContainer.background)
	
	MineOSCore.OSMainContainer.desktopCounters = MineOSCore.OSMainContainer:addChild(GUI.container(1, 1, 1, 1))

	MineOSCore.OSMainContainer.iconField = MineOSCore.OSMainContainer:addChild(
		MineOSCore.createIconField(
			1, 1, 1, 1, 1, 1, 1,
			sizes.xSpaceBetweenIcons,
			sizes.ySpaceBetweenIcons,
			0xFFFFFF,
			MineOSCore.OSSettings.showExtension or true,
			MineOSCore.OSSettings.showHiddenFiles or true,
			MineOSCore.OSSettings.sortingMethod or "type",
			"/",
			0xFFFFFF
		)
	)

	createDock()
	MineOSCore.OSMainContainer.windowsContainer = MineOSCore.OSMainContainer:addChild(GUI.container(1, 2, 1, 1))

	MineOSCore.OSMainContainer.menu = MineOSCore.OSMainContainer:addChild(GUI.menu(1, 1, MineOSCore.OSMainContainer.width, MineOSCore.OSSettings.interfaceColor or colors.interface, 0x444444, 0x3366CC, 0xFFFFFF, colors.topBarTransparency))
	local item1 = MineOSCore.OSMainContainer.menu:addItem("MineOS", 0x000000)
	item1.onTouch = function()
		local menu = GUI.contextMenu(item1.x, item1.y + 1)
		menu:addItem(MineOSCore.localization.updates).onTouch = function()
			MineOSCore.safeLaunch("/MineOS/Applications/AppMarket.app/Main.lua", "updates")
		end
		menu:addSeparator()
		menu:addItem(MineOSCore.localization.logout, MineOSCore.OSSettings.protectionMethod == "withoutProtection").onTouch = function()
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
			MineOSCore.OSMainContainer:stopEventHandling()
			ecs.prepareToExit()
			os.exit()
		end	
		menu:show()
	end

	local item2 = MineOSCore.OSMainContainer.menu:addItem(MineOSCore.localization.viewTab)
	item2.onTouch = function()
		local menu = GUI.contextMenu(item2.x, item2.y + 1)
		menu:addItem(MineOSCore.OSMainContainer.iconField.showExtension and MineOSCore.localization.hideExtension or MineOSCore.localization.showExtension).onTouch = function()
			MineOSCore.OSMainContainer.iconField.showExtension = not MineOSCore.OSMainContainer.iconField.showExtension
			MineOSCore.OSSettings.showExtension = MineOSCore.OSMainContainer.iconField.showExtension
			MineOSCore.saveOSSettings()
			MineOSCore.OSMainContainer.updateAndDraw()
		end
		menu:addItem(MineOSCore.OSMainContainer.iconField.showHiddenFiles and MineOSCore.localization.hideHiddenFiles or MineOSCore.localization.showHiddenFiles).onTouch = function()
			MineOSCore.OSMainContainer.iconField.showHiddenFiles = not MineOSCore.OSMainContainer.iconField.showHiddenFiles
			MineOSCore.OSSettings.showHiddenFiles = MineOSCore.OSMainContainer.iconField.showHiddenFiles
			MineOSCore.saveOSSettings()
			MineOSCore.OSMainContainer.updateAndDraw()
		end
		menu:addItem(MineOSCore.showApplicationIcons and MineOSCore.localization.hideApplicationIcons or  MineOSCore.localization.showApplicationIcons).onTouch = function()
			MineOSCore.showApplicationIcons = not MineOSCore.showApplicationIcons
			MineOSCore.OSMainContainer.updateAndDraw()
		end
		menu:addSeparator()
		menu:addItem(MineOSCore.localization.sortByName).onTouch = function()
			MineOSCore.OSSettings.sortingMethod = "name"
			MineOSCore.saveOSSettings()
			MineOSCore.OSMainContainer.iconField.sortingMethod = MineOSCore.OSSettings.sortingMethod
			MineOSCore.OSMainContainer.updateAndDraw()
		end
		menu:addItem(MineOSCore.localization.sortByDate).onTouch = function()
			MineOSCore.OSSettings.sortingMethod = "date"
			MineOSCore.saveOSSettings()
			MineOSCore.OSMainContainer.iconField.sortingMethod = MineOSCore.OSSettings.sortingMethod
			MineOSCore.OSMainContainer.updateAndDraw()
		end
		menu:addItem(MineOSCore.localization.sortByType).onTouch = function()
			MineOSCore.OSSettings.sortingMethod = "type"
			MineOSCore.saveOSSettings()
			MineOSCore.OSMainContainer.iconField.sortingMethod = MineOSCore.OSSettings.sortingMethod
			MineOSCore.OSMainContainer.updateAndDraw()
		end
		menu:addSeparator()
		menu:addItem(MineOSCore.localization.screensaver).onTouch = function()
			local container = MineOSCore.addUniversalContainer(MineOSCore.OSMainContainer, MineOSCore.localization.screensaver)
			
			local comboBox = container.layout:addChild(GUI.comboBox(1, 1, 36, 3, 0xEEEEEE, 0x262626, 0x666666, 0xEEEEEE))
			comboBox:addItem(MineOSCore.localization.screensaverDisabled)
			for file in fs.list(screensaversPath) do
				comboBox:addItem(fs.hideExtension(file))
			end
			local slider = container.layout:addChild(GUI.slider(1, 1, 36, 0xFFDB40, 0xEEEEEE, 0xFFDB80, 0xBBBBBB, 1, 100, MineOSCore.OSSettings.screensaverDelay or 20, false, MineOSCore.localization.screensaverDelay .. ": ", ""))

			MineOSCore.OSMainContainer:draw()
			buffer.draw()

			container.panel.eventHandler = function(mainContainer, object, eventData)
				if eventData[1] == "touch" then
					container:delete()
					if comboBox.selectedItem == 1 then
						MineOSCore.OSSettings.screensaver = nil
					else
						MineOSCore.OSSettings.screensaver, MineOSCore.OSSettings.screensaverDelay = comboBox.items[comboBox.selectedItem].text, slider.value
					end
					MineOSCore.saveOSSettings()

					MineOSCore.OSMainContainer:draw()
					buffer.draw()
				end
			end
		end
		menu:addItem(MineOSCore.localization.colorScheme).onTouch = function()
			local container = MineOSCore.addUniversalContainer(MineOSCore.OSMainContainer, MineOSCore.localization.colorScheme)
			
			local backgroundColorSelector = container.layout:addChild(GUI.colorSelector(1, 1, 36, 3, MineOSCore.OSSettings.backgroundColor or colors.background, MineOSCore.localization.backgroundColor))
			local interfaceColorSelector = container.layout:addChild(GUI.colorSelector(1, 1, 36, 3, MineOSCore.OSSettings.interfaceColor or colors.interface, MineOSCore.localization.interfaceColor))
			
			backgroundColorSelector.onTouch = function()
				MineOSCore.OSSettings.backgroundColor, MineOSCore.OSSettings.interfaceColor = backgroundColorSelector.color, interfaceColorSelector.color
				MineOSCore.OSMainContainer.menu.colors.default.background = MineOSCore.OSSettings.interfaceColor
				MineOSCore.saveOSSettings()
				
				MineOSCore.OSMainContainer:draw()
				buffer.draw()
			end
			interfaceColorSelector.onTouch = backgroundColorSelector.onTouch

			MineOSCore.OSMainContainer:draw()
			buffer.draw()

			container.panel.eventHandler = function(mainContainer, object, eventData)
				if eventData[1] == "touch" then
					container:delete()
					MineOSCore.OSMainContainer:draw()
					buffer.draw()
				end
			end
		end
		menu:addItem(MineOSCore.localization.contextMenuRemoveWallpaper, not MineOSCore.OSMainContainer.background.wallpaper).onTouch = function()
			MineOSCore.OSSettings.wallpaper = nil
			MineOSCore.saveOSSettings()
			changeWallpaper()
		end
		menu:show()
	end

	local item3 = MineOSCore.OSMainContainer.menu:addItem(MineOSCore.localization.settings)
	item3.onTouch = function()
		local menu = GUI.contextMenu(item3.x, item3.y + 1)
		menu:addItem(MineOSCore.localization.screenResolution).onTouch = function()
			local container = MineOSCore.addUniversalContainer(MineOSCore.OSMainContainer, MineOSCore.localization.screenResolution)
			
			local widthTextBox = container.layout:addChild(GUI.inputTextBox(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0xEEEEEE, 0x262626, tostring(MineOSCore.OSSettings.resolution and MineOSCore.OSSettings.resolution[1] or 160), "Width", true))
			widthTextBox.validator = function(text)
				local number = tonumber(text)
				if number then return number >= 1 and number <= 160 end
			end

			local heightTextBox = container.layout:addChild(GUI.inputTextBox(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0xEEEEEE, 0x262626, tostring(MineOSCore.OSSettings.resolution and MineOSCore.OSSettings.resolution[2] or 50), "Height", true))
			heightTextBox.validator = function(text)
				local number = tonumber(text)
				if number then return number >= 1 and number <= 50 end
			end

			container.panel.eventHandler = function(mainContainer, object, eventData)
				if eventData[1] == "touch" then
					container:delete()
					MineOSCore.OSSettings.resolution = {tonumber(widthTextBox.text), tonumber(heightTextBox.text)}
					MineOSCore.saveOSSettings()
					changeResolution()
					changeWallpaper()
					MineOSCore.OSMainContainer.updateAndDraw()
				end
			end
		end
		menu:addSeparator()
		menu:addItem(MineOSCore.localization.setProtectionMethod).onTouch = function()
			setProtectionMethod()
		end
		menu:show()
	end

	MineOSCore.OSMainContainer.update = function()
		MineOSCore.OSMainContainer.iconField.fromFile = (currentDesktop - 1) * MineOSCore.OSMainContainer.iconField.iconCount.total + 1
		MineOSCore.OSMainContainer.iconField:updateFileList()
		updateDock()
		updateDesktopCounters()
	end

	MineOSCore.OSMainContainer.updateAndDraw = function(forceRedraw)
		MineOSCore.OSMainContainer.update()
		MineOSCore.OSMainContainer:draw()
		buffer.draw(forceRedraw)
	end

	MineOSCore.OSMainContainer.eventHandler = function(mainContainer, object, eventData)
		if eventData[1] == "scroll" then
			if eventData[5] == 1 then
				if currentDesktop < countOfDesktops then
					currentDesktop = currentDesktop + 1
					MineOSCore.OSMainContainer.updateAndDraw()
				end
			else
				if currentDesktop > 1 then
					currentDesktop = currentDesktop - 1
					MineOSCore.OSMainContainer.updateAndDraw()
				end
			end
		elseif eventData[1] == "MineOSCore" then
			if eventData[2] == "updateFileList" then
				MineOSCore.OSMainContainer.updateAndDraw()
			elseif eventData[2] == "updateFileListAndBufferTrueRedraw" then
				MineOSCore.OSMainContainer.updateAndDraw(true)
			elseif eventData[2] == "changeWorkpath" then
				table.insert(workpathHistory, eventData[3])
				changeWorkpath(#workpathHistory)
			elseif eventData[2] == "updateWallpaper" then
				changeWallpaper()
				MineOSCore.OSMainContainer:draw()
				buffer.draw()
			elseif eventData[2] == "newApplication" then
				MineOSCore.newApplication(MineOSCore.OSMainContainer, MineOSCore.OSMainContainer.iconField.workpath)
			elseif eventData[2] == "newFile" then
				MineOSCore.newFile(MineOSCore.OSMainContainer, MineOSCore.OSMainContainer.iconField.workpath)
			elseif eventData[2] == "newFolder" then
				MineOSCore.newFolder(MineOSCore.OSMainContainer, MineOSCore.OSMainContainer.iconField.workpath)
			elseif eventData[2] == "rename" then
				MineOSCore.rename(MineOSCore.OSMainContainer, eventData[3])
			elseif eventData[2] == "applicationHelp" then
				MineOSCore.applicationHelp(MineOSCore.OSMainContainer, eventData[3])
			end
		elseif not eventData[1] then
			screensaverTimer = screensaverTimer + 0.5
			if MineOSCore.OSSettings.screensaver and screensaverTimer > MineOSCore.OSSettings.screensaverDelay and fs.exists(screensaversPath .. MineOSCore.OSSettings.screensaver .. ".lua") then
				MineOSCore.safeLaunch(screensaversPath .. MineOSCore.OSSettings.screensaver .. ".lua")
				screensaverTimer = 0
				MineOSCore.OSMainContainer:draw()
				buffer.draw(true)
			end
		else
			screensaverTimer = 0
		end
	end
end

---------------------------------------------- Сама ОС ------------------------------------------------------------------------

createOSWindow()
changeResolution()
changeWorkpath(1)
changeWallpaper()
MineOSCore.OSMainContainer.update()
login()
windows10()

while true do
	local success, path, line, traceback = MineOSCore.call(MineOSCore.OSMainContainer.startEventHandling, MineOSCore.OSMainContainer, 1)
	if success then
		break
	else
		changeResolution()
		MineOSCore.OSMainContainer.windowsContainer:deleteChildren()
		-- MineOSCore.OSMainContainer:draw()
		-- buffer.draw()

		-- MineOSCore.showErrorWindow(path, line, traceback)

		MineOSCore.OSMainContainer:draw()
		buffer.draw()
	end
end






