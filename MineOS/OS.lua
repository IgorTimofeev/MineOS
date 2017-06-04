
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
	local inputField = container.layout:addChild(GUI.inputField(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0x666666, 0xEEEEEE, 0x262626, nil, nil, true, "*"))
	local label = container.layout:addChild(GUI.label(1, 1, 36, 1, 0xFF4940, " ")):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)

	inputField.onInputFinished = function()
		local hash = require("SHA2").hash(inputField.text or "")
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

	MineOSCore.OSMainContainer:draw()
	buffer.draw()
	inputField:startInput()
end

local function setPassword()
	local container = MineOSCore.addUniversalContainer(MineOSCore.OSMainContainer, MineOSCore.localization.passwordProtection)
	local inputField1 = container.layout:addChild(GUI.inputField(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0x666666, 0xEEEEEE, 0x262626, nil, MineOSCore.localization.inputPassword, true, "*"))
	local inputField2 = container.layout:addChild(GUI.inputField(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0x666666, 0xEEEEEE, 0x262626, nil, MineOSCore.localization.confirmInputPassword, true, "*"))
	local label = container.layout:addChild(GUI.label(1, 1, 36, 1, 0xFF4940, " ")):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)

	MineOSCore.OSMainContainer:draw()
	buffer.draw()

	container.panel.eventHandler = function(mainContainer, object, eventData)
		if eventData[1] == "touch" then
			if inputField1.text == inputField2.text then
				container:delete()

				MineOSCore.OSSettings.protectionMethod = "password"
				MineOSCore.OSSettings.passwordHash = require("SHA2").hash(inputField1.text or "")
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
		MineOSCore.OSMainContainer.background.wallpaper = image.load(MineOSCore.OSSettings.wallpaper)
		if MineOSCore.OSSettings.wallpaperMode == 1 then
			MineOSCore.OSMainContainer.background.wallpaper = image.transform(MineOSCore.OSMainContainer.background.wallpaper, MineOSCore.OSMainContainer.width, MineOSCore.OSMainContainer.height)
			MineOSCore.OSMainContainer.background.wallpaperPosition.x, MineOSCore.OSMainContainer.background.wallpaperPosition.y = 1, 1
		else
			MineOSCore.OSMainContainer.background.wallpaperPosition.x = math.floor(MineOSCore.OSMainContainer.width / 2 - image.getWidth(MineOSCore.OSMainContainer.background.wallpaper) / 2)
			MineOSCore.OSMainContainer.background.wallpaperPosition.y = math.floor(MineOSCore.OSMainContainer.height / 2 - image.getHeight(MineOSCore.OSMainContainer.background.wallpaper) / 2)
		end
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

---------------------------------------------- Всякая параша для ОС-контейнера ------------------------------------------------------------------------

local function changeResolution()
	currentDesktop = 1
	buffer.setResolution(table.unpack(MineOSCore.OSSettings.resolution or {160, 50}))

	MineOSCore.OSMainContainer.width, MineOSCore.OSMainContainer.height = buffer.width, buffer.height

	MineOSCore.OSMainContainer.iconField.width, MineOSCore.OSMainContainer.iconField.height = MineOSCore.OSMainContainer.width, MineOSCore.OSMainContainer.height - sizes.heightOfDock - 5
	MineOSCore.OSMainContainer.iconField.iconCount.width, MineOSCore.OSMainContainer.iconField.iconCount.height, MineOSCore.OSMainContainer.iconField.iconCount.total =  MineOSCore.getParametersForDrawingIcons(MineOSCore.OSMainContainer.iconField.width, MineOSCore.OSMainContainer.iconField.height, sizes.xSpaceBetweenIcons, sizes.ySpaceBetweenIcons)
	MineOSCore.OSMainContainer.iconField.localPosition.x = math.floor(MineOSCore.OSMainContainer.width / 2 - (MineOSCore.OSMainContainer.iconField.iconCount.width * (MineOSCore.iconWidth + sizes.xSpaceBetweenIcons) - sizes.xSpaceBetweenIcons) / 2)
	MineOSCore.OSMainContainer.iconField.localPosition.y = 3

	MineOSCore.OSMainContainer.dockContainer.localPosition.y = MineOSCore.OSMainContainer.height - sizes.heightOfDock + 1

	MineOSCore.OSMainContainer.menu.width = MineOSCore.OSMainContainer.width
	MineOSCore.OSMainContainer.background.width, MineOSCore.OSMainContainer.background.height = MineOSCore.OSMainContainer.width, MineOSCore.OSMainContainer.height

	MineOSCore.OSMainContainer.windowsContainer.width, MineOSCore.OSMainContainer.windowsContainer.height = MineOSCore.OSMainContainer.width, MineOSCore.OSMainContainer.height - 1
end

local function moveDockIcon(index, direction)
	MineOSCore.OSMainContainer.dockContainer.children[index], MineOSCore.OSMainContainer.dockContainer.children[index + direction] = MineOSCore.OSMainContainer.dockContainer.children[index + direction], MineOSCore.OSMainContainer.dockContainer.children[index]
	MineOSCore.OSMainContainer.dockContainer.sort()
	MineOSCore.OSMainContainer.dockContainer.saveToOSSettings()
	MineOSCore.OSMainContainer:draw()
	buffer.draw()
end

local function createOSWindow()
	MineOSCore.OSMainContainer = GUI.fullScreenContainer()

	MineOSCore.OSMainContainer.background = MineOSCore.OSMainContainer:addChild(GUI.object(1, 1, 1, 1))
	MineOSCore.OSMainContainer.background.wallpaperPosition = {x = 1, y = 1}
	MineOSCore.OSMainContainer.background.draw = function(object)
		buffer.square(object.x, object.y, object.width, object.height, MineOSCore.OSSettings.backgroundColor or colors.background, 0x0, " ")
		if object.wallpaper then
			buffer.image(object.wallpaperPosition.x, object.wallpaperPosition.y, object.wallpaper)
		end
	end
	MineOSCore.OSMainContainer.background.eventHandler = function(mainContainer, object, eventData)
		if eventData[1] == "touch" then
			if eventData[5] == 1 then
				MineOSCore.emptyZoneClick(eventData, MineOSCore.OSMainContainer, MineOSCore.OSMainContainer.iconField.workpath)
			end
		end
	end

	MineOSCore.OSMainContainer.desktopCounters = MineOSCore.OSMainContainer:addChild(GUI.container(1, 1, 1, 1))

	MineOSCore.OSMainContainer.iconField = MineOSCore.OSMainContainer:addChild(
		MineOSCore.createIconField(
			1, 1, 1, 1, 1, 1, 1,
			sizes.xSpaceBetweenIcons,
			sizes.ySpaceBetweenIcons,
			0xFFFFFF,
			MineOSCore.OSSettings.showExtension,
			MineOSCore.OSSettings.showHiddenFiles,
			MineOSCore.OSSettings.sortingMethod or "type",
			"/",
			0xFFFFFF
		)
	)

	-- Dock
	MineOSCore.OSMainContainer.dockContainer = MineOSCore.OSMainContainer:addChild(GUI.container(1, 1, MineOSCore.OSMainContainer.width, sizes.heightOfDock))
	MineOSCore.OSMainContainer.dockContainer.saveToOSSettings = function()
		MineOSCore.OSSettings.dockShortcuts = {}
		for i = 1, #MineOSCore.OSMainContainer.dockContainer.children do
			if MineOSCore.OSMainContainer.dockContainer.children[i].keepInDock then
				table.insert(MineOSCore.OSSettings.dockShortcuts, MineOSCore.OSMainContainer.dockContainer.children[i].path)
			end
		end
		MineOSCore.saveOSSettings()
	end
	MineOSCore.OSMainContainer.dockContainer.sort = function()
		local x = 1
		for i = 1, #MineOSCore.OSMainContainer.dockContainer.children do
			MineOSCore.OSMainContainer.dockContainer.children[i].localPosition.x = x
			x = x + MineOSCore.iconWidth + sizes.xSpaceBetweenIcons
		end

		MineOSCore.OSMainContainer.dockContainer.width = (#MineOSCore.OSMainContainer.dockContainer.children) * (MineOSCore.iconWidth + sizes.xSpaceBetweenIcons) - sizes.xSpaceBetweenIcons
		MineOSCore.OSMainContainer.dockContainer.localPosition.x = math.floor(MineOSCore.OSMainContainer.width / 2 - MineOSCore.OSMainContainer.dockContainer.width / 2)
	end

	MineOSCore.OSMainContainer.dockContainer.addIcon = function(path, window)
		local icon = MineOSCore.OSMainContainer.dockContainer:addChild(MineOSCore.createIcon(1, 1, path, 0x262626, MineOSCore.OSSettings.showExtension, 0xFFFFFF))
		icon:moveBackward()
		icon.window = window

		icon.onLeftClick = function(icon, eventData)
			if icon.window then
				icon.window.hidden = false
				icon.window:moveToFront()
			else
				MineOSCore.iconLeftClick(icon, eventData)
			end
		end

		icon.onRightClick = function(icon, eventData)
			local indexOf = icon:indexOf()

			local menu = GUI.contextMenu(eventData[3], eventData[4])
			menu:addItem(MineOSCore.localization.contextMenuShowContainingFolder).onTouch = function()
				table.insert(workpathHistory, fs.path(icon.path))
				changeWorkpath(#workpathHistory)
				MineOSCore.OSMainContainer.updateAndDraw()
			end
			menu:addSeparator()
			menu:addItem(MineOSCore.localization.contextMenuMoveRight, indexOf >= #MineOSCore.OSMainContainer.dockContainer.children - 1).onTouch = function()
				moveDockIcon(indexOf, 1)
			end
			menu:addItem(MineOSCore.localization.contextMenuMoveLeft, indexOf <= 1).onTouch = function()
				moveDockIcon(indexOf, -1)
			end
			menu:addSeparator()
			if icon.keepInDock then
				if #MineOSCore.OSMainContainer.dockContainer.children > 1 then
					menu:addItem(MineOSCore.localization.contextMenuRemoveFromDock).onTouch = function()
						if icon.window then
							icon.keepInDock = nil
						else
							icon:delete()
							MineOSCore.OSMainContainer.dockContainer.sort()
						end
						MineOSCore.OSMainContainer.dockContainer.saveToOSSettings()
						MineOSCore.OSMainContainer:draw()
						buffer.draw()
					end
				end
			else
				if icon.window then
					menu:addItem(MineOSCore.localization.keepInDock).onTouch = function()
						icon.keepInDock = true
						MineOSCore.OSMainContainer.dockContainer.saveToOSSettings()
					end
				end
			end

			menu:show()
		end

		MineOSCore.OSMainContainer.dockContainer.sort()

		return icon
	end

	-- Trash
	local icon = MineOSCore.OSMainContainer.dockContainer.addIcon(MineOSCore.paths.trash)
	icon.image = MineOSCore.icons.trash
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

	for i = 1, #MineOSCore.OSSettings.dockShortcuts do
		MineOSCore.OSMainContainer.dockContainer.addIcon(MineOSCore.OSSettings.dockShortcuts[i]).keepInDock = true
	end

	MineOSCore.OSMainContainer.dockContainer.draw = function(dockContainer)
		local color, currentDockTransparency, currentDockWidth, xPos, yPos = MineOSCore.OSSettings.interfaceColor or colors.interface, colors.dockBaseTransparency, dockContainer.width, dockContainer.x, dockContainer.y + 2

		for i = 1, dockContainer.height do
			buffer.text(xPos, yPos, color, "▟", currentDockTransparency)
			buffer.square(xPos + 1, yPos, currentDockWidth - 2, 1, color, 0xFFFFFF, " ", currentDockTransparency)
			buffer.text(xPos + currentDockWidth - 1, yPos, color, "▙", currentDockTransparency)

			currentDockTransparency, currentDockWidth, xPos, yPos = currentDockTransparency - colors.dockTransparencyAdder, currentDockWidth + 2, xPos - 1, yPos + 1
		end

		GUI.drawContainerContent(dockContainer)
	end

	-- Windows
	MineOSCore.OSMainContainer.windowsContainer = MineOSCore.OSMainContainer:addChild(GUI.container(1, 2, 1, 1))

	-- Menu
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
		menu:addItem(MineOSCore.localization.appearance).onTouch = function()
			local container = MineOSCore.addUniversalContainer(MineOSCore.OSMainContainer, MineOSCore.localization.wallpaperProperties)

			local inputField = container.layout:addChild(GUI.inputField(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0x999999, 0xEEEEEE, 0x262626, MineOSCore.OSSettings.wallpaper, MineOSCore.localization.wallpaperPath, true))
			local comboBox = container.layout:addChild(GUI.comboBox(1, 1, 36, 3, 0xEEEEEE, 0x262626, 0x666666, 0xEEEEEE))
			comboBox.selectedItem = MineOSCore.OSSettings.wallpaperMode or 1
			comboBox:addItem(MineOSCore.localization.wallpaperModeStretch)
			comboBox:addItem(MineOSCore.localization.wallpaperModeCenter)

			container.layout:addChild(GUI.label(1, 1, 36, 1, 0xEEEEEE, MineOSCore.localization.colorScheme)):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
			local backgroundColorSelector = container.layout:addChild(GUI.colorSelector(1, 1, 36, 3, MineOSCore.OSSettings.backgroundColor or colors.background, MineOSCore.localization.backgroundColor))
			local interfaceColorSelector = container.layout:addChild(GUI.colorSelector(1, 1, 36, 3, MineOSCore.OSSettings.interfaceColor or colors.interface, MineOSCore.localization.interfaceColor))
			
			comboBox.onItemSelected = function()
				MineOSCore.OSSettings.wallpaperMode = comboBox.selectedItem
				MineOSCore.saveOSSettings()
				changeWallpaper()

				MineOSCore.OSMainContainer:draw()
				buffer.draw()
			end

			inputField.onInputFinished = function()
				MineOSCore.OSSettings.wallpaper = inputField.text
				MineOSCore.saveOSSettings()
				changeWallpaper()

				MineOSCore.OSMainContainer:draw()
				buffer.draw()
			end

			backgroundColorSelector.onTouch = function()
				MineOSCore.OSSettings.backgroundColor, MineOSCore.OSSettings.interfaceColor = backgroundColorSelector.color, interfaceColorSelector.color
				MineOSCore.OSMainContainer.menu.colors.default.background = MineOSCore.OSSettings.interfaceColor
				MineOSCore.saveOSSettings()

				MineOSCore.OSMainContainer:draw()
				buffer.draw()
			end
			interfaceColorSelector.onTouch = backgroundColorSelector.onTouch

			container.panel.eventHandler = function(mainContainer, object, eventData)
				if eventData[1] == "touch" then
					container:delete()
					MineOSCore.OSMainContainer:draw()
					buffer.draw()
				end
			end

			MineOSCore.OSMainContainer:draw()
			buffer.draw()
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

			local widthTextBox = container.layout:addChild(GUI.inputField(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0x666666, 0xEEEEEE, 0x262626, tostring(MineOSCore.OSSettings.resolution and MineOSCore.OSSettings.resolution[1] or 160), "Width", true))
			widthTextBox.validator = function(text)
				local number = tonumber(text)
				if number then return number >= 1 and number <= 160 end
			end

			local heightTextBox = container.layout:addChild(GUI.inputField(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0x666666, 0xEEEEEE, 0x262626, tostring(MineOSCore.OSSettings.resolution and MineOSCore.OSSettings.resolution[2] or 50), "Height", true))
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
		createOSWindow()
		changeResolution()
		changeWorkpath(1)
		changeWallpaper()
		MineOSCore.OSMainContainer.updateAndDraw()

		MineOSCore.showErrorWindow(path, line, traceback)

		MineOSCore.OSMainContainer:draw()
		buffer.draw()
	end
end
