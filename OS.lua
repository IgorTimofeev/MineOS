
---------------------------------------------- Копирайт, епта ------------------------------------------------------------------------

local copyright = {

	"Тут можно было бы написать кучу текста, мол,",
	"вы не имеете прав на использование этой хуйни в",
	"коммерческих целях и прочую чушь, навеянную нам",
	"западной культурой. Но я же не пидор какой-то, верно?",
	"",
	"Просто помни, что эту ОСь накодил Тимофеев Игорь,",
	"ссылка на ВК: vk.com/id7799889"

}

-- Вычищаем копирайт из оперативки, ибо мы не можем тратить СТОЛЬКО памяти.
-- Сколько тут, раз, два, три... 270 UTF-8 символов!
-- А это, между прочим, 54 раза по слову "Пидор". Но один раз - не пидорас, поэтому вычищаем.
-- ...
-- Бля, передумал, не вычищаем, еще пригодится ниже. Вот же костыльная параша!

-- copyright = nil

---------------------------------------------- Либсы-хуибсы ------------------------------------------------------------------------

-- package.loaded.MineOSCore = nil

local computer = require("computer")
local component = require("component")
local unicode = require("unicode")
local fs = require("filesystem")
local event = require("event")
local image = require("image")
local buffer = require("doubleBuffering")
local GUI = require("GUI")
local MineOSPaths = require("MineOSPaths")
local MineOSCore = require("MineOSCore")
local MineOSNetwork = require("MineOSNetwork")
local MineOSInterface = require("MineOSInterface")

---------------------------------------------- Всякая константная залупа ------------------------------------------------------------------------

local menuTransparency = 0.2
local dockTransparency = 0.5

local computerUptimeOnBoot = computer.uptime()
local computerDateUptime = computerUptimeOnBoot
local realTimestamp
local timezoneCorrection
local screensaversPath = MineOSPaths.system .. "Screensavers/"
local screensaverUptime = computerUptimeOnBoot

---------------------------------------------- Система защиты пекарни ------------------------------------------------------------------------

local function biometry(creatingNew)
	local container = MineOSInterface.addUniversalContainer(MineOSInterface.mainContainer)

	local fingerImage = container.layout:addChild(GUI.image(1, 1, image.fromString([[180E0000FF 0000FF 0000FF 0000FF 0000FF 00FFFF▄00FFFF▄00FFFF▄00FFFF▄FFFFFF▀FFFFFF▀FFFFFF▀FFFFFF▀FFFFFF▀FFFFFF▀00FFFF▄00FFFF▄00FFFF▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 00FFFF▄FFFF00▄FFFFFF▀0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF FFFFFF▀FFFFFF▀FFFF00▄00FFFF▄0000FF 0000FF 0000FF 0000FF 0000FF FFFF00▄FFFFFF▀0000FF 0000FF 0000FF 00FFFF▄00FFFF▄FFFF00▄FFFFFF▀FFFFFF▀FFFFFF▀FFFFFF▀FFFFFF▀FFFFFF▀FFFF00▄00FFFF▄0000FF 0000FF FFFFFF▀FFFF00▄00FFFF▄0000FF 0000FF FFFF00▄FFFFFF▀0000FF 0000FF 00FFFF▄FFFF00▄FFFFFF▀0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF FFFF00▄00FFFF▄0000FF 0000FF FFFF00▄0000FF 00FFFF▄FFFF00▄0000FF 0000FF 00FFFF▄FFFF00▄0000FF 0000FF 0000FF 00FFFF▄00FFFF▄FFFFFF▀FFFFFF▀FFFFFF▀FFFFFF▀FFFFFF▀FFFFFF▀00FFFF▄0000FF FFFF00▄00FFFF▄0000FF FFFFFF▀FFFF00▄FFFF00▄0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF 0000FF 00FFFF▄00FFFF▄00FFFF▄0000FF 0000FF FFFF00▄0000FF 0000FF FFFF00▄0000FF 0000FF FFFF00▄FFFF00▄0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF 00FFFF▄FFFFFF▀0000FF 0000FF 0000FF 0000FF 00FFFF▄FFFF00▄0000FF 0000FF FFFF00▄0000FF 0000FF FFFF00▄0000FF 0000FF FFFF00▄FFFF00▄0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF FFFF00▄0000FF 0000FF 0000FF 0000FF 00FFFF▄FFFF00▄0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF FFFF00▄0000FF 00FFFF▄FFFF00▄FFFF00▄00FFFF▄0000FF 0000FF FFFF00▄00FFFF▄0000FF FFFFFF▀FFFF00▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF FFFF00▄FFFFFF▀0000FF FFFF00▄0000FF 0000FF FFFF00▄0000FF 0000FF 0000FF FFFF00▄00FFFF▄0000FF FFFFFF▀FFFF00▄0000FF 0000FF 0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF 00FFFF▄FFFF00▄0000FF 00FFFF▄FFFFFF▀0000FF 0000FF FFFF00▄00FFFF▄0000FF 0000FF 0000FF FFFF00▄00FFFF▄0000FF FFFF00▄00FFFF▄0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF 00FFFF▄FFFFFF▀0000FF 0000FF FFFF00▄0000FF 0000FF 0000FF 0000FF FFFF00▄00FFFF▄0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF FFFF00▄FFFFFF▀0000FF 0000FF FFFF00▄FFFFFF▀0000FF 0000FF 0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF 0000FF FFFFFF▀FFFF00▄00FFFF▄0000FF 0000FF 0000FF 0000FF 00FFFF▄FFFFFF▀0000FF 0000FF 0000FF 00FFFF▄FFFF00▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF FFFF00▄00FFFF▄0000FF 0000FF 0000FF FFFFFF▀0000FF 0000FF 0000FF 0000FF FFFFFF▀0000FF 0000FF 00FFFF▄FFFF00▄FFFFFF▀0000FF 0000FF 0000FF 0000FF ]])))
	local text = creatingNew and MineOSCore.localization.putFingerToRegister or MineOSCore.localization.putFingerToVerify
	local label = container.layout:addChild(GUI.label(1, 1, container.width, 1, 0xEEEEEE, text):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top))

	local scanLine = container:addChild(GUI.label(1, 1, container.width, 1, 0xFFFFFF, string.rep("─", image.getWidth(fingerImage.image) + 6)):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top))
	local fingerImageHeight = image.getHeight(fingerImage.image) + 1
	local delay = 0.5
	scanLine.hidden = true

	fingerImage.eventHandler = function(mainContainer, object, eventData)
		if eventData[1] == "touch" then
			scanLine:addAnimation(
				function(mainContainer, object, animation)
					scanLine.hidden = false
					if animation.position <= 0.5 then
						scanLine.localPosition.y = math.floor(fingerImage.localPosition.y + fingerImageHeight - fingerImageHeight * animation.position * 2 - 1)
					else
						scanLine.localPosition.y = math.floor(fingerImage.localPosition.y + fingerImageHeight * (animation.position - 0.5) * 2 - 1)
					end
				end,
				function(mainContainer, switch, animation)
					scanLine.hidden = true
					animation:delete()

					local touchedHash = require("SHA2").hash(eventData[6])

					if creatingNew then
						label.text = MineOSCore.localization.fingerprintCreated

						MineOSInterface.OSDraw()

						MineOSCore.properties.protectionMethod = "biometric"
						MineOSCore.properties.biometryHash = touchedHash
						MineOSCore.saveProperties()

						container:delete()
						os.sleep(delay)
					else
						if touchedHash == MineOSCore.properties.biometryHash then
							label.text = MineOSCore.localization.welcomeBack .. eventData[6]

							MineOSInterface.OSDraw()

							container:delete()
							os.sleep(delay)
						else
							label.text = MineOSCore.localization.accessDenied
							local oldBackground = container.panel.colors.background
							container.panel.colors.background = 0x550000

							MineOSInterface.OSDraw()

							os.sleep(delay)

							label.text = text
							container.panel.colors.background = oldBackground
						end
					end

					MineOSInterface.OSDraw()
				end
			):start(3)
		end
	end
	label.eventHandler, container.panel.eventHandler = fingerImage.eventHandler, fingerImage.eventHandler

	MineOSInterface.OSDraw()
end

local function checkPassword()
	local container = MineOSInterface.addUniversalContainer(MineOSInterface.mainContainer, MineOSCore.localization.inputPassword)
	local inputField = container.layout:addChild(GUI.inputField(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0x666666, 0xEEEEEE, 0x262626, nil, nil, true, "*"))
	local label = container.layout:addChild(GUI.label(1, 1, 36, 1, 0xFF4940, MineOSCore.localization.incorrectPassword)):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	label.hidden = true

	inputField.onInputFinished = function()
		local hash = require("SHA2").hash(inputField.text or "")
		if hash == MineOSCore.properties.passwordHash then
			container:delete()
		elseif hash == "c925be318b0530650b06d7f0f6a51d8289b5925f1b4117a43746bc99f1f81bc1" then
			GUI.error(MineOSCore.localization.mineOSCreatorUsedMasterPassword)
			container:delete()
		else
			label.hidden = false
		end

		MineOSInterface.OSDraw()
	end

	MineOSInterface.OSDraw()
	inputField:startInput()
end

local function setPassword()
	local container = MineOSInterface.addUniversalContainer(MineOSInterface.mainContainer, MineOSCore.localization.passwordProtection)
	local inputField1 = container.layout:addChild(GUI.inputField(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0x666666, 0xEEEEEE, 0x262626, nil, MineOSCore.localization.inputPassword, true, "*"))
	local inputField2 = container.layout:addChild(GUI.inputField(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0x666666, 0xEEEEEE, 0x262626, nil, MineOSCore.localization.confirmInputPassword, true, "*"))
	local label = container.layout:addChild(GUI.label(1, 1, 36, 1, 0x6340FF, MineOSCore.localization.passwordsAreDifferent)):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	label.hidden = true

	MineOSInterface.OSDraw()

	container.panel.eventHandler = function(mainContainer, object, eventData)
		if eventData[1] == "touch" then
			if inputField1.text == inputField2.text then
				container:delete()

				MineOSCore.properties.protectionMethod = "password"
				MineOSCore.properties.passwordHash = require("SHA2").hash(inputField1.text or "")
				MineOSCore.saveProperties()
			else
				label.hidden = false
			end

			MineOSInterface.OSDraw()
		end
	end
end

local function setWithoutProtection()
	MineOSCore.properties.passwordHash = nil
	MineOSCore.properties.protectionMethod = "withoutProtection"
	MineOSCore.saveProperties()
end

local function setProtectionMethod()
	local container = MineOSInterface.addUniversalContainer(MineOSInterface.mainContainer, MineOSCore.localization.protectYourComputer)

	local comboBox = container.layout:addChild(GUI.comboBox(1, 1, 36, 3, 0xEEEEEE, 0x262626, 0x444444, 0x999999))
	comboBox:addItem(MineOSCore.localization.biometricProtection)
	comboBox:addItem(MineOSCore.localization.passwordProtection)
	comboBox:addItem(MineOSCore.localization.withoutProtection)

	container.panel.eventHandler = function(mainContainer, object, eventData)
		if eventData[1] == "touch" then
			container:delete()
			MineOSInterface.OSDraw()

			if comboBox.selectedItem == 1 then
				biometry(true)
			elseif comboBox.selectedItem == 2 then
				setPassword()
			elseif comboBox.selectedItem == 3 then
				setWithoutProtection()
			end
		end
	end
end

local function login()
	event.interruptingEnabled = false

	if not MineOSCore.properties.protectionMethod then
		setProtectionMethod()
	elseif MineOSCore.properties.protectionMethod == "password" then
		checkPassword()
	elseif MineOSCore.properties.protectionMethod == "biometric" then
		biometry()
	end

	event.interruptingEnabled = true
	MineOSInterface.OSDraw()
end

---------------------------------------------- Основные функции ------------------------------------------------------------------------

local function changeWallpaper()
	MineOSInterface.mainContainer.background.wallpaper = nil

	if MineOSCore.properties.wallpaperEnabled and MineOSCore.properties.wallpaper and fs.exists(MineOSCore.properties.wallpaper) then
		if MineOSCore.properties.wallpaperMode == 1 then
			MineOSInterface.mainContainer.background.wallpaper = image.transform(image.load(MineOSCore.properties.wallpaper), MineOSInterface.mainContainer.width, MineOSInterface.mainContainer.height)
			MineOSInterface.mainContainer.background.wallpaperPosition.x, MineOSInterface.mainContainer.background.wallpaperPosition.y = 1, 1
		else
			MineOSInterface.mainContainer.background.wallpaper = image.load(MineOSCore.properties.wallpaper)
			MineOSInterface.mainContainer.background.wallpaperPosition.x = math.floor(1 + MineOSInterface.mainContainer.width / 2 - image.getWidth(MineOSInterface.mainContainer.background.wallpaper) / 2)
			MineOSInterface.mainContainer.background.wallpaperPosition.y = math.floor(1 + MineOSInterface.mainContainer.height / 2 - image.getHeight(MineOSInterface.mainContainer.background.wallpaper) / 2)
		end
	end
end

---------------------------------------------- Всякая параша для ОС-контейнера ------------------------------------------------------------------------

local function changeResolution()
	buffer.setResolution(table.unpack(MineOSCore.properties.resolution or {160, 50}))

	MineOSInterface.mainContainer.width, MineOSInterface.mainContainer.height = buffer.width, buffer.height

	MineOSInterface.mainContainer.iconField.width = MineOSInterface.mainContainer.width
	MineOSInterface.mainContainer.iconField.height = MineOSInterface.mainContainer.height
	MineOSInterface.mainContainer.iconField:updateFileList()

	MineOSInterface.mainContainer.dockContainer.sort()
	MineOSInterface.mainContainer.dockContainer.localPosition.y = MineOSInterface.mainContainer.height - MineOSInterface.mainContainer.dockContainer.height + 1

	MineOSInterface.mainContainer.menu.width = MineOSInterface.mainContainer.width
	MineOSInterface.mainContainer.menuLayout.width = MineOSInterface.mainContainer.width
	MineOSInterface.mainContainer.background.width, MineOSInterface.mainContainer.background.height = MineOSInterface.mainContainer.width, MineOSInterface.mainContainer.height

	MineOSInterface.mainContainer.windowsContainer.width, MineOSInterface.mainContainer.windowsContainer.height = MineOSInterface.mainContainer.width, MineOSInterface.mainContainer.height - 1
end

local function moveDockIcon(index, direction)
	MineOSInterface.mainContainer.dockContainer.children[index], MineOSInterface.mainContainer.dockContainer.children[index + direction] = MineOSInterface.mainContainer.dockContainer.children[index + direction], MineOSInterface.mainContainer.dockContainer.children[index]
	MineOSInterface.mainContainer.dockContainer.sort()
	MineOSInterface.mainContainer.dockContainer.saveToOSSettings()
	MineOSInterface.OSDraw()
end

local function createOSWindow()
	MineOSInterface.mainContainer = GUI.fullScreenContainer()

	MineOSInterface.mainContainer.background = MineOSInterface.mainContainer:addChild(GUI.object(1, 1, 1, 1))
	MineOSInterface.mainContainer.background.wallpaperPosition = {x = 1, y = 1}
	MineOSInterface.mainContainer.background.draw = function(object)
		buffer.square(object.x, object.y, object.width, object.height, MineOSCore.properties.backgroundColor or 0x0F0F0F, 0x0, " ")
		if object.wallpaper then
			buffer.image(object.wallpaperPosition.x, object.wallpaperPosition.y, object.wallpaper)
		end
	end

	MineOSInterface.mainContainer.iconField = MineOSInterface.mainContainer:addChild(
		MineOSInterface.iconField(
			1, 2, 1, 1, 2, 1, 3, 2,
			0xFFFFFF,
			0xFFFFFF,
			MineOSPaths.desktop
		)
	)
	MineOSInterface.mainContainer.iconField.iconConfigEnabled = true
	MineOSInterface.mainContainer.iconField.launchers.directory = function(icon)
		MineOSInterface.safeLaunch(MineOSPaths.explorer, "-o", icon.path)
	end
	MineOSInterface.mainContainer.iconField.launchers.showContainingFolder = function(icon)
		MineOSInterface.safeLaunch(MineOSPaths.explorer, "-o", fs.path(icon.path))
	end
	MineOSInterface.mainContainer.iconField.launchers.showPackageContent = function(icon)
		MineOSInterface.safeLaunch(MineOSPaths.explorer, "-o", icon.path)
	end

	-- Dock
	MineOSInterface.mainContainer.dockContainer = MineOSInterface.mainContainer:addChild(GUI.container(1, 1, MineOSInterface.mainContainer.width, 6))
	MineOSInterface.mainContainer.dockContainer.saveToOSSettings = function()
		MineOSCore.properties.dockShortcuts = {}
		for i = 1, #MineOSInterface.mainContainer.dockContainer.children do
			if MineOSInterface.mainContainer.dockContainer.children[i].keepInDock then
				table.insert(MineOSCore.properties.dockShortcuts, MineOSInterface.mainContainer.dockContainer.children[i].path)
			end
		end
		MineOSCore.saveProperties()
	end
	MineOSInterface.mainContainer.dockContainer.sort = function()
		local x = 1
		for i = 1, #MineOSInterface.mainContainer.dockContainer.children do
			MineOSInterface.mainContainer.dockContainer.children[i].localPosition.x = x
			x = x + MineOSInterface.iconWidth + MineOSInterface.mainContainer.iconField.spaceBetweenIcons.horizontal
		end

		MineOSInterface.mainContainer.dockContainer.width = (#MineOSInterface.mainContainer.dockContainer.children) * (MineOSInterface.iconWidth + MineOSInterface.mainContainer.iconField.spaceBetweenIcons.horizontal) - MineOSInterface.mainContainer.iconField.spaceBetweenIcons.horizontal
		MineOSInterface.mainContainer.dockContainer.localPosition.x = math.floor(MineOSInterface.mainContainer.width / 2 - MineOSInterface.mainContainer.dockContainer.width / 2)
	end

	local function dockIconEventHandler(mainContainer, icon, eventData)
		if eventData[1] == "touch" then
			icon.selected = true
			MineOSInterface.OSDraw()

			if eventData[5] == 1 then
				icon.onRightClick(icon, eventData)
			else
				icon.onLeftClick(icon, eventData)
			end

			icon.selected = false
			MineOSInterface.OSDraw()
		end
	end

	MineOSInterface.mainContainer.dockContainer.addIcon = function(path, window)
		local icon = MineOSInterface.mainContainer.dockContainer:addChild(MineOSInterface.icon(1, 1, path, 0x262626, 0xFFFFFF))
		icon:analyseExtension()
		icon:moveBackward()

		icon.eventHandler = dockIconEventHandler

		icon.onLeftClick = function(icon, eventData)
			if icon.windows then
				for window in pairs(icon.windows) do
					window.hidden = false
					window:moveToFront()
				end
				MineOSInterface.OSDraw()
			else
				-- os.sleep(MineOSCore.iconClickDelay)
				MineOSInterface.iconDoubleClick(icon, eventData)
			end
		end

		icon.onRightClick = function(icon, eventData)
			local indexOf = icon:indexOf()

			local menu = MineOSInterface.contextMenu(eventData[3], eventData[4])
			menu:addItem(MineOSCore.localization.showContainingFolder).onTouch = function()

			end
			menu:addSeparator()
			menu:addItem(MineOSCore.localization.moveRight, indexOf >= #MineOSInterface.mainContainer.dockContainer.children - 1).onTouch = function()
				moveDockIcon(indexOf, 1)
			end
			menu:addItem(MineOSCore.localization.moveLeft, indexOf <= 1).onTouch = function()
				moveDockIcon(indexOf, -1)
			end
			menu:addSeparator()
			if icon.keepInDock then
				if #MineOSInterface.mainContainer.dockContainer.children > 1 then
					menu:addItem(MineOSCore.localization.removeFromDock).onTouch = function()
						if icon.windows then
							icon.keepInDock = nil
						else
							icon:delete()
							MineOSInterface.mainContainer.dockContainer.sort()
						end
						MineOSInterface.mainContainer.dockContainer.saveToOSSettings()
						MineOSInterface.OSDraw()
					end
				end
			else
				if icon.windows then
					menu:addItem(MineOSCore.localization.keepInDock).onTouch = function()
						icon.keepInDock = true
						MineOSInterface.mainContainer.dockContainer.saveToOSSettings()
					end
				end
			end

			menu:show()
		end

		MineOSInterface.mainContainer.dockContainer.sort()

		return icon
	end

	-- Trash
	local icon = MineOSInterface.mainContainer.dockContainer.addIcon(MineOSPaths.trash)
	icon.launchers.directory = function(icon)
		MineOSInterface.safeLaunch(MineOSPaths.explorer, "-o", icon.path)
	end
	icon:analyseExtension()
	icon.image = MineOSInterface.iconsCache.trash

	icon.eventHandler = dockIconEventHandler

	icon.onLeftClick = function(icon, eventData)
		MineOSInterface.iconDoubleClick(icon, eventData)
	end

	icon.onRightClick = function(icon, eventData)
		local menu = MineOSInterface.contextMenu(eventData[3], eventData[4])
		menu:addItem(MineOSCore.localization.emptyTrash).onTouch = function()
			local container = MineOSInterface.addUniversalContainer(MineOSInterface.mainContainer, MineOSCore.localization.areYouSure)

			container.layout:addChild(GUI.button(1, 1, 30, 1, 0xEEEEEE, 0x262626, 0xA, 0x262626, "OK")).onTouch = function()
				for file in fs.list(MineOSPaths.trash) do
					fs.remove(MineOSPaths.trash .. file)
				end
				container:delete()
				computer.pushSignal("MineOSCore", "updateFileList")
			end

			container.panel.onTouch = function()
				container:delete()
				MineOSInterface.OSDraw()
			end

			MineOSInterface.OSDraw()
		end

		menu:show()
	end

	for i = 1, #MineOSCore.properties.dockShortcuts do
		MineOSInterface.mainContainer.dockContainer.addIcon(MineOSCore.properties.dockShortcuts[i]).keepInDock = true
	end

	MineOSInterface.mainContainer.dockContainer.draw = function(dockContainer)
		local color, currentDockTransparency, currentDockWidth, xPos, yPos = MineOSCore.properties.dockColor or 0xFFFFFF, dockTransparency, dockContainer.width + 6, dockContainer.x - 3, dockContainer.y + dockContainer.height - 1

		for i = 1, dockContainer.height - 2 do
			buffer.text(xPos, yPos, color, "◢", MineOSCore.properties.transparencyEnabled and currentDockTransparency)
			buffer.square(xPos + 1, yPos, currentDockWidth - 2, 1, color, 0xFFFFFF, " ", MineOSCore.properties.transparencyEnabled and currentDockTransparency)
			buffer.text(xPos + currentDockWidth - 1, yPos, color, "◣", MineOSCore.properties.transparencyEnabled and currentDockTransparency)

			currentDockTransparency, currentDockWidth, xPos, yPos = currentDockTransparency + 0.08, currentDockWidth - 2, xPos + 1, yPos - 1
			if currentDockTransparency > 1 then
				currentDockTransparency = 1
			end
		end

		GUI.drawContainerContent(dockContainer)
	end

	-- Custom windows support
	MineOSInterface.mainContainer.windowsContainer = MineOSInterface.mainContainer:addChild(GUI.container(1, 2, 1, 1))

	-- Main menu
	MineOSInterface.mainContainer.menu = MineOSInterface.mainContainer:addChild(GUI.menu(1, 1, MineOSInterface.mainContainer.width, MineOSCore.properties.menuColor or 0xFFFFFF, 0x555555, 0x3366CC, 0xFFFFFF, MineOSCore.properties.transparencyEnabled and menuTransparency))
	local item1 = MineOSInterface.mainContainer.menu:addItem("MineOS", 0x000000)
	item1.onTouch = function()
		local menu = MineOSInterface.contextMenu(item1.x, item1.y + 1)

		menu:addItem(MineOSCore.localization.aboutSystem).onTouch = function()
			local container = MineOSInterface.addUniversalContainer(MineOSInterface.mainContainer, MineOSCore.localization.aboutSystem)
			container.layout:addChild(GUI.textBox(1, 1, 53, #copyright, nil, 0xBBBBBB, copyright, 1, 0, 0))
		end

		menu:addItem(MineOSCore.localization.updates).onTouch = function()
			MineOSInterface.safeLaunch("/MineOS/Applications/AppMarket.app/Main.lua", "updates")
		end

		menu:addSeparator()

		menu:addItem(MineOSCore.localization.logout, MineOSCore.properties.protectionMethod == "withoutProtection").onTouch = function()
			login()
		end

		menu:addItem(MineOSCore.localization.reboot).onTouch = function()
			MineOSNetwork.broadcastComputerState(false)
			require("computer").shutdown(true)
		end

		menu:addItem(MineOSCore.localization.shutdown).onTouch = function()
			MineOSNetwork.broadcastComputerState(false)
			require("computer").shutdown()
		end

		menu:addSeparator()

		menu:addItem(MineOSCore.localization.returnToShell).onTouch = function()
			MineOSNetwork.broadcastComputerState(false)
			MineOSInterface.mainContainer:stopEventHandling()
			MineOSInterface.clearTerminal()
			os.exit()
		end

		menu:show()
	end

	local item2 = MineOSInterface.mainContainer.menu:addItem(MineOSCore.localization.network)
	item2.onTouch = function()
		local menu = MineOSInterface.contextMenu(item2.x, item2.y + 1)

		if component.isAvailable("modem") then
			menu:addItem(MineOSCore.properties.network.enabled and MineOSCore.localization.networkDisable or MineOSCore.localization.networkEnable).onTouch = function()
				MineOSCore.properties.network.enabled = not MineOSCore.properties.network.enabled
				MineOSCore.saveProperties()
				if MineOSCore.properties.network.enabled then
					MineOSNetwork.enable()
				else
					MineOSNetwork.disable()
				end
				MineOSNetwork.broadcastComputerState(MineOSCore.properties.network.enabled)
			end

			menu:addItem(MineOSCore.localization.networkName).onTouch = function()
				local container = MineOSInterface.addUniversalContainer(MineOSInterface.mainContainer, MineOSCore.localization.networkName)

				local textBox = container.layout:addChild(GUI.inputField(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0x666666, 0xEEEEEE, 0x262626, MineOSCore.properties.network.name, nil))
				textBox.onInputFinished = function()
					if textBox.text then
						MineOSNetwork.broadcastComputerState(false)
						MineOSCore.properties.network.name = textBox.text
						MineOSCore.saveProperties()
						MineOSNetwork.broadcastComputerState(MineOSCore.properties.network.enabled)
						
						container:delete()
						MineOSInterface.OSDraw()
					end
				end
			end

			if MineOSNetwork.modemProxy.isWireless() then
				local subMenu = menu:addSubMenu(MineOSCore.localization.networkSearchRadius)
				local i = 2
				while i <= 512 do
					subMenu:addItem(tostring(i)).onTouch = function()
						MineOSCore.properties.network.signalStrength = i
						MineOSCore.saveProperties()
						MineOSNetwork.setSignalStrength(i)
					end
					i = i * 2
				end
			end

			if MineOSCore.properties.network.enabled then
				menu:addSeparator()
				
				if MineOSNetwork.getProxyCount() > 0 then
					for proxy, path in fs.mounts() do
						if proxy.network then
							local subMenu = menu:addSubMenu(string.limit(MineOSNetwork.getProxyName(proxy), 25, "end"))

							subMenu:addItem(MineOSCore.properties.network.users[proxy.address].allowReadAndWrite and MineOSCore.localization.networkDenyReadAndWrite or MineOSCore.localization.networkAllowReadAndWrite).onTouch = function()
								MineOSCore.properties.network.users[proxy.address].allowReadAndWrite = not MineOSCore.properties.network.users[proxy.address].allowReadAndWrite
								MineOSCore.saveProperties()
							end

							subMenu:addItem(MineOSCore.properties.network.users[proxy.address].allowMessages and MineOSCore.localization.networkDenyMessages or MineOSCore.localization.networkAllowMessages).onTouch = function()
								MineOSCore.properties.network.users[proxy.address].allowMessages = not MineOSCore.properties.network.users[proxy.address].allowMessages
								MineOSCore.saveProperties()
							end

							subMenu:addSeparator()

							subMenu:addItem(MineOSCore.localization.networkSendMessage).onTouch = function()
								local container = MineOSInterface.addUniversalContainer(MineOSInterface.mainContainer, MineOSCore.localization.networkSendMessage)

								local textBox = container.layout:addChild(GUI.inputField(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0x666666, 0xEEEEEE, 0x262626, nil, nil, true))
								textBox.onInputFinished = function()
									if textBox.text then
										MineOSNetwork.sendMessage(proxy.address, "MineOSNetwork", "message", textBox.text)
										
										container:delete()
										MineOSInterface.OSDraw()
									end
								end
							end
						end
					end
				else
					menu:addItem(MineOSCore.localization.networkComputersNotFound, true)
				end
			end
		else
			menu:addItem(MineOSCore.localization.networkModemNotAvailable, true)
		end

		menu:show()
	end

	local item3 = MineOSInterface.mainContainer.menu:addItem(MineOSCore.localization.settings)
	item3.onTouch = function()
		local menu = MineOSInterface.contextMenu(item3.x, item3.y + 1)

		menu:addItem(MineOSCore.localization.screenResolution).onTouch = function()
			local container = MineOSInterface.addUniversalContainer(MineOSInterface.mainContainer, MineOSCore.localization.screenResolution)

			local widthTextBox = container.layout:addChild(GUI.inputField(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0x666666, 0xEEEEEE, 0x262626, tostring(MineOSCore.properties.resolution and MineOSCore.properties.resolution[1] or 160), "Width", true))
			widthTextBox.validator = function(text)
				local number = tonumber(text)
				if number then return number >= 1 and number <= 160 end
			end

			local heightTextBox = container.layout:addChild(GUI.inputField(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0x666666, 0xEEEEEE, 0x262626, tostring(MineOSCore.properties.resolution and MineOSCore.properties.resolution[2] or 50), "Height", true))
			heightTextBox.validator = function(text)
				local number = tonumber(text)
				if number then return number >= 1 and number <= 50 end
			end

			container.panel.eventHandler = function(mainContainer, object, eventData)
				if eventData[1] == "touch" then
					container:delete()
					MineOSCore.properties.resolution = {tonumber(widthTextBox.text), tonumber(heightTextBox.text)}
					MineOSCore.saveProperties()
					changeResolution()
					changeWallpaper()
					MineOSInterface.mainContainer.updateFileListAndDraw()
				end
			end
		end

		menu:addSeparator()

		menu:addItem(MineOSCore.localization.wallpaper).onTouch = function()
			local container = MineOSInterface.addUniversalContainer(MineOSInterface.mainContainer, MineOSCore.localization.wallpaper)

			local filesystemChooser = container.layout:addChild(GUI.filesystemChooser(1, 1, 36, 3, 0xEEEEEE, 0x262626, 0x444444, 0x999999, MineOSCore.properties.wallpaper, MineOSCore.localization.open, MineOSCore.localization.cancel, MineOSCore.localization.wallpaperPath, "/"))
			filesystemChooser:addExtensionFilter(".pic")
			filesystemChooser.onSubmit = function(path)
				MineOSCore.properties.wallpaper = path
				MineOSCore.saveProperties()
				changeWallpaper()

				MineOSInterface.OSDraw()
			end

			local comboBox = container.layout:addChild(GUI.comboBox(1, 1, 36, 3, 0xEEEEEE, 0x262626, 0x444444, 0x999999))
			comboBox.selectedItem = MineOSCore.properties.wallpaperMode or 1
			comboBox:addItem(MineOSCore.localization.wallpaperModeStretch)
			comboBox:addItem(MineOSCore.localization.wallpaperModeCenter)

			local switch = container.layout:addChild(GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0x2D2D2D, 0xEEEEEE, 0xBBBBBB, MineOSCore.localization.wallpaperEnabled .. ":", MineOSCore.properties.wallpaperEnabled)).switch
			container.layout:addChild(GUI.textBox(1, 1, 36, 1, nil, 0x555555, {MineOSCore.localization.wallpaperSwitchInfo}, 1, 0, 0, true, true))

			switch.onStateChanged = function()
				MineOSCore.properties.wallpaperEnabled = switch.state
				MineOSCore.saveProperties()
				changeWallpaper()

				MineOSInterface.OSDraw()
			end
			comboBox.onItemSelected = function()
				MineOSCore.properties.wallpaperMode = comboBox.selectedItem
				MineOSCore.saveProperties()
				changeWallpaper()

				MineOSInterface.OSDraw()
			end
		end
		menu:addItem(MineOSCore.localization.screensaver).onTouch = function()
			local container = MineOSInterface.addUniversalContainer(MineOSInterface.mainContainer, MineOSCore.localization.screensaver)

			local comboBox = container.layout:addChild(GUI.comboBox(1, 1, 36, 3, 0xEEEEEE, 0x262626, 0x444444, 0x999999))
			local fileList = fs.sortedList(screensaversPath, "name", false)
			for i = 1, #fileList do
				comboBox:addItem(fs.hideExtension(fileList[i]))
				if MineOSCore.properties.screensaver == fileList[i] then
					comboBox.selectedItem = i
				end
			end
			local switch = container.layout:addChild(GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0x2D2D2D, 0xEEEEEE, 0xBBBBBB, MineOSCore.localization.screensaverEnabled .. ":", MineOSCore.properties.screensaverEnabled)).switch
			local slider = container.layout:addChild(GUI.slider(1, 1, 36, 0x66DB80, 0x2D2D2D, 0xEEEEEE, 0xBBBBBB, 1, 100, MineOSCore.properties.screensaverDelay or 20, false, MineOSCore.localization.screensaverDelay .. ": ", ""))

			container.panel.eventHandler = function(mainContainer, object, eventData)
				if eventData[1] == "touch" then
					container:delete()
					MineOSInterface.OSDraw()

					MineOSCore.properties.screensaverEnabled = switch.state
					MineOSCore.properties.screensaver = fileList[comboBox.selectedItem]
					MineOSCore.properties.screensaverDelay = slider.value

					MineOSCore.saveProperties()
				end
			end

			MineOSInterface.OSDraw()
		end

		menu:addItem(MineOSCore.localization.colorScheme).onTouch = function()
			local container = MineOSInterface.addUniversalContainer(MineOSInterface.mainContainer, MineOSCore.localization.colorScheme)

			local backgroundColorSelector = container.layout:addChild(GUI.colorSelector(1, 1, 36, 3, MineOSCore.properties.backgroundColor or 0x0F0F0F, MineOSCore.localization.backgroundColor))
			local menuColorSelector = container.layout:addChild(GUI.colorSelector(1, 1, 36, 3, MineOSCore.properties.menuColor or 0xFFFFFF, MineOSCore.localization.menuColor))
			local dockColorSelector = container.layout:addChild(GUI.colorSelector(1, 1, 36, 3, MineOSCore.properties.dockColor or 0xFFFFFF, MineOSCore.localization.dockColor))

			local switch = container.layout:addChild(GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0x2D2D2D, 0xEEEEEE, 0xEEEEEE, MineOSCore.localization.transparencyEnabled .. ":", MineOSCore.properties.transparencyEnabled)).switch
			switch.onStateChanged = function()
				MineOSCore.properties.transparencyEnabled = switch.state
				MineOSCore.saveProperties()
				MineOSInterface.mainContainer.menu.colors.transparency = MineOSCore.properties.transparencyEnabled and menuTransparency
				container.panel.colors.background = switch.state and 0x0 or (MineOSCore.properties.backgroundColor or 0x0F0F0F)
				container.panel.colors.transparency = switch.state and 0.2

				MineOSInterface.OSDraw()
			end
			container.layout:addChild(GUI.textBox(1, 1, 36, 1, nil, 0x555555, {MineOSCore.localization.transparencySwitchInfo}, 1, 0, 0, true, true))

			-- Шоб рисовалось в реальном времени
			backgroundColorSelector.onTouch = function()
				MineOSCore.properties.backgroundColor = backgroundColorSelector.color
				MineOSCore.properties.menuColor = menuColorSelector.color
				MineOSCore.properties.dockColor = dockColorSelector.color
				MineOSInterface.mainContainer.menu.colors.default.background = MineOSCore.properties.menuColor

				MineOSInterface.OSDraw()
			end
			menuColorSelector.onTouch = backgroundColorSelector.onTouch
			dockColorSelector.onTouch = backgroundColorSelector.onTouch

			container.panel.eventHandler = function(mainContainer, object, eventData)
				if eventData[1] == "touch" then
					container:delete()
					MineOSInterface.OSDraw()

					MineOSCore.saveProperties()
				end
			end
		end

		menu:addSeparator()

		menu:addItem(MineOSCore.localization.setProtectionMethod).onTouch = function()
			setProtectionMethod()
		end

		menu:show()
	end

	MineOSInterface.mainContainer.menuLayout = MineOSInterface.mainContainer:addChild(GUI.layout(1, 1, 1, 1, 1, 1))
	MineOSInterface.mainContainer.menuLayout:setCellSpacing(1, 1, 0)
	MineOSInterface.mainContainer.menuLayout:setCellDirection(1, 1, GUI.directions.horizontal)
	MineOSInterface.mainContainer.menuLayout:setCellAlignment(1, 1, GUI.alignment.horizontal.right, GUI.alignment.vertical.top)

	local dateButton = MineOSInterface.addMenuWidget(GUI.button(1, 1, 1, 1, nil, 0x0, 0x3366CC, 0xFFFFFF, " "))
	dateButton.switchMode = true

	dateButton.onTouch = function()
		local menu = MineOSInterface.contextMenu(dateButton.x, dateButton.y + 1)
		for i = -12, 12 do
			menu:addItem("GMT" .. (i >= 0 and "+" or "") .. i).onTouch = function()
				MineOSCore.properties.timezone = i
				MineOSCore.saveProperties()

				MineOSCore.OSUpdateTimezone()
				MineOSCore.OSUpdateDate()
				MineOSInterface.OSDraw()
			end
		end
		menu:show()
		dateButton.pressed = false
		MineOSInterface.OSDraw()
	end

	MineOSCore.OSUpdateTimezone = function()
		local timezone = MineOSCore.properties.timezone or 0
		timezoneCorrection = timezone * 3600
	end

	MineOSCore.OSUpdateDate = function()
		if not realTimestamp then
			local name = MineOSPaths.system .. "/Timestamp.tmp"
			local file = io.open(name, "w")
			file:close()
			realTimestamp = math.floor(fs.lastModified(name) / 1000)
			fs.remove(name)
		end

		local firstPart, month, secondPart = os.date(
			"%d %b %Y  %T",
			realTimestamp + computerDateUptime - computerUptimeOnBoot + timezoneCorrection
		):match("(%d+%s)(%a+)(.+)")

		dateButton.text = firstPart .. (MineOSCore.localization.months[month] or "monthNotAvailable:" .. month) .. secondPart
		dateButton.width = unicode.len(dateButton.text) + 2
	end

	MineOSInterface.OSDraw = function(force)
		MineOSInterface.mainContainer:draw()
		buffer.draw(force)
	end

	MineOSInterface.mainContainer.updateFileListAndDraw = function(forceRedraw)
		MineOSInterface.mainContainer.iconField:updateFileList()
		MineOSInterface.OSDraw(forceRedraw)
	end

	MineOSInterface.mainContainer.eventHandler = function(mainContainer, object, eventData)
		if eventData[1] == "MineOSCore" then
			if eventData[2] == "updateFileList" then
				MineOSInterface.mainContainer.updateFileListAndDraw()
			elseif eventData[2] == "updateFileListAndBufferTrueRedraw" then
				MineOSInterface.mainContainer.updateFileListAndDraw(true)
			elseif eventData[2] == "updateWallpaper" then
				changeWallpaper()
				MineOSInterface.OSDraw()
			end
		elseif eventData[1] == "MineOSNetwork" then
			if eventData[2] == "accessDenied" then
				GUI.error(MineOSCore.localization.networkAccessDenied)
			elseif eventData[2] == "message" then
				GUI.error(MineOSCore.localization.networkMessage .. eventData[3] .. ": " .. eventData[4])
			elseif eventData[2] == "timeout" then
				GUI.error(MineOSCore.localization.networkTimeout)
			end
		end

		local computerUptime = computer.uptime()

		if computerUptime - computerDateUptime >= 1 then
			MineOSCore.OSUpdateDate()
			MineOSInterface.OSDraw()
			computerDateUptime = computerUptime
		end

		if MineOSCore.properties.screensaverEnabled then
			if eventData[1] then
				screensaverUptime = computer.uptime()
			end

			if computerUptime - screensaverUptime >= MineOSCore.properties.screensaverDelay then
				if fs.exists(screensaversPath .. MineOSCore.properties.screensaver) then
					MineOSInterface.safeLaunch(screensaversPath .. MineOSCore.properties.screensaver)
					MineOSInterface.OSDraw(true)
				end

				screensaverUptime = computer.uptime()
			end
		end
	end
end

---------------------------------------------- Сама ОС ------------------------------------------------------------------------

MineOSCore.localization = table.fromFile(MineOSPaths.localizationFiles .. MineOSCore.properties.language .. ".lang")

createOSWindow()
changeResolution()
changeWallpaper()
MineOSCore.OSUpdateTimezone()
MineOSCore.OSUpdateDate()
login()

if MineOSCore.properties.network.enabled then
	MineOSNetwork.setSignalStrength(MineOSCore.properties.network.signalStrength)
	MineOSNetwork.enable()
	MineOSNetwork.broadcastComputerState(true)
end

while true do
	local success, path, line, traceback = MineOSCore.call(
		MineOSInterface.mainContainer.startEventHandling,
		MineOSInterface.mainContainer,
		1
	)
	if success then
		break
	else
		createOSWindow()
		changeResolution()
		changeWallpaper()
		MineOSInterface.mainContainer.updateFileListAndDraw()

		MineOSInterface.showErrorWindow(path, line, traceback)

		MineOSInterface.OSDraw()
	end
end
