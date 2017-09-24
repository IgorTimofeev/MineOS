
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
local MineOSCore = require("MineOSCore")
local MineOSNetwork = require("MineOSNetwork")

---------------------------------------------- Всякая константная залупа ------------------------------------------------------------------------

local menuTransparency = 0.2
local dockTransparency = 0.5

local computerUptimeOnBoot = computer.uptime()
local computerDateUptime = computerUptimeOnBoot
local realTimestamp
local timezoneCorrection
local screensaversPath = MineOSCore.paths.system .. "Screensavers/"
local screensaverUptime = computerUptimeOnBoot

---------------------------------------------- Система защиты пекарни ------------------------------------------------------------------------

local function biometry(creatingNew)
	local container = MineOSCore.addUniversalContainer(MineOSCore.OSMainContainer)

	local fingerImage = container.layout:addChild(GUI.image(1, 1, image.fromString([[180E0000FF 0000FF 0000FF 0000FF 0000FF 00FFFF▄00FFFF▄00FFFF▄00FFFF▄FFFFFF▀FFFFFF▀FFFFFF▀FFFFFF▀FFFFFF▀FFFFFF▀00FFFF▄00FFFF▄00FFFF▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 00FFFF▄FFFF00▄FFFFFF▀0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF FFFFFF▀FFFFFF▀FFFF00▄00FFFF▄0000FF 0000FF 0000FF 0000FF 0000FF FFFF00▄FFFFFF▀0000FF 0000FF 0000FF 00FFFF▄00FFFF▄FFFF00▄FFFFFF▀FFFFFF▀FFFFFF▀FFFFFF▀FFFFFF▀FFFFFF▀FFFF00▄00FFFF▄0000FF 0000FF FFFFFF▀FFFF00▄00FFFF▄0000FF 0000FF FFFF00▄FFFFFF▀0000FF 0000FF 00FFFF▄FFFF00▄FFFFFF▀0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF FFFF00▄00FFFF▄0000FF 0000FF FFFF00▄0000FF 00FFFF▄FFFF00▄0000FF 0000FF 00FFFF▄FFFF00▄0000FF 0000FF 0000FF 00FFFF▄00FFFF▄FFFFFF▀FFFFFF▀FFFFFF▀FFFFFF▀FFFFFF▀FFFFFF▀00FFFF▄0000FF FFFF00▄00FFFF▄0000FF FFFFFF▀FFFF00▄FFFF00▄0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF 0000FF 00FFFF▄00FFFF▄00FFFF▄0000FF 0000FF FFFF00▄0000FF 0000FF FFFF00▄0000FF 0000FF FFFF00▄FFFF00▄0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF 00FFFF▄FFFFFF▀0000FF 0000FF 0000FF 0000FF 00FFFF▄FFFF00▄0000FF 0000FF FFFF00▄0000FF 0000FF FFFF00▄0000FF 0000FF FFFF00▄FFFF00▄0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF FFFF00▄0000FF 0000FF 0000FF 0000FF 00FFFF▄FFFF00▄0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF FFFF00▄0000FF 00FFFF▄FFFF00▄FFFF00▄00FFFF▄0000FF 0000FF FFFF00▄00FFFF▄0000FF FFFFFF▀FFFF00▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF FFFF00▄FFFFFF▀0000FF FFFF00▄0000FF 0000FF FFFF00▄0000FF 0000FF 0000FF FFFF00▄00FFFF▄0000FF FFFFFF▀FFFF00▄0000FF 0000FF 0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF 00FFFF▄FFFF00▄0000FF 00FFFF▄FFFFFF▀0000FF 0000FF FFFF00▄00FFFF▄0000FF 0000FF 0000FF FFFF00▄00FFFF▄0000FF FFFF00▄00FFFF▄0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF 00FFFF▄FFFFFF▀0000FF 0000FF FFFF00▄0000FF 0000FF 0000FF 0000FF FFFF00▄00FFFF▄0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF FFFF00▄FFFFFF▀0000FF 0000FF FFFF00▄FFFFFF▀0000FF 0000FF 0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF 0000FF FFFFFF▀FFFF00▄00FFFF▄0000FF 0000FF 0000FF 0000FF 00FFFF▄FFFFFF▀0000FF 0000FF 0000FF 00FFFF▄FFFF00▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF FFFF00▄00FFFF▄0000FF 0000FF 0000FF FFFFFF▀0000FF 0000FF 0000FF 0000FF FFFFFF▀0000FF 0000FF 00FFFF▄FFFF00▄FFFFFF▀0000FF 0000FF 0000FF 0000FF ]])))
	local text = creatingNew and MineOSCore.localization.putFingerToRegister or MineOSCore.localization.putFingerToVerify
	local label = container.layout:addChild(GUI.label(1, 1, container.width, 1, 0xEEEEEE, text):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top))

	local scanLine = container:addChild(GUI.label(1, 1, container.width, 1, 0xFFFFFF, string.rep("─", image.getWidth(fingerImage.image) + 6)):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top))
	local fingerImageHeight = image.getHeight(fingerImage.image) + 1
	local delay = 0.5
	scanLine.hidden = true

	fingerImage.eventHandler = function(mainContainer, object, eventData)
		if eventData[1] == "touch" then
			scanLine.hidden = false
			scanLine:addAnimation(
				function(mainContainer, object, animation)
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

						MineOSCore.OSDraw()

						MineOSCore.OSSettings.protectionMethod = "biometric"
						MineOSCore.OSSettings.biometryHash = touchedHash
						MineOSCore.saveOSSettings()

						container:delete()
						os.sleep(delay)
					else
						if touchedHash == MineOSCore.OSSettings.biometryHash then
							label.text = MineOSCore.localization.welcomeBack .. eventData[6]

							MineOSCore.OSDraw()

							container:delete()
							os.sleep(delay)
						else
							label.text = MineOSCore.localization.accessDenied
							local oldBackground = container.panel.colors.background
							container.panel.colors.background = 0x550000

							MineOSCore.OSDraw()

							os.sleep(delay)

							label.text = text
							container.panel.colors.background = oldBackground
						end
					end

					MineOSCore.OSDraw()
				end
			):start(3)
		end
	end
	label.eventHandler, container.panel.eventHandler = fingerImage.eventHandler, fingerImage.eventHandler

	MineOSCore.OSDraw()
end

local function checkPassword()
	local container = MineOSCore.addUniversalContainer(MineOSCore.OSMainContainer, MineOSCore.localization.inputPassword)
	local inputField = container.layout:addChild(GUI.inputField(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0x666666, 0xEEEEEE, 0x262626, nil, nil, true, "*"))
	local label = container.layout:addChild(GUI.label(1, 1, 36, 1, 0xFF4940, MineOSCore.localization.incorrectPassword)):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	label.hidden = true

	inputField.onInputFinished = function()
		local hash = require("SHA2").hash(inputField.text or "")
		if hash == MineOSCore.OSSettings.passwordHash then
			container:delete()
		elseif hash == "c925be318b0530650b06d7f0f6a51d8289b5925f1b4117a43746bc99f1f81bc1" then
			GUI.error(MineOSCore.localization.mineOSCreatorUsedMasterPassword)
			container:delete()
		else
			label.hidden = false
		end

		MineOSCore.OSDraw()
	end

	MineOSCore.OSDraw()
	inputField:startInput()
end

local function setPassword()
	local container = MineOSCore.addUniversalContainer(MineOSCore.OSMainContainer, MineOSCore.localization.passwordProtection)
	local inputField1 = container.layout:addChild(GUI.inputField(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0x666666, 0xEEEEEE, 0x262626, nil, MineOSCore.localization.inputPassword, true, "*"))
	local inputField2 = container.layout:addChild(GUI.inputField(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0x666666, 0xEEEEEE, 0x262626, nil, MineOSCore.localization.confirmInputPassword, true, "*"))
	local label = container.layout:addChild(GUI.label(1, 1, 36, 1, 0x6340FF, MineOSCore.localization.passwordsAreDifferent)):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	label.hidden = true

	MineOSCore.OSDraw()

	container.panel.eventHandler = function(mainContainer, object, eventData)
		if eventData[1] == "touch" then
			if inputField1.text == inputField2.text then
				container:delete()

				MineOSCore.OSSettings.protectionMethod = "password"
				MineOSCore.OSSettings.passwordHash = require("SHA2").hash(inputField1.text or "")
				MineOSCore.saveOSSettings()
			else
				label.hidden = false
			end

			MineOSCore.OSDraw()
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

	local comboBox = container.layout:addChild(GUI.comboBox(1, 1, 36, 3, 0xEEEEEE, 0x262626, 0x444444, 0x999999))
	comboBox:addItem(MineOSCore.localization.biometricProtection)
	comboBox:addItem(MineOSCore.localization.passwordProtection)
	comboBox:addItem(MineOSCore.localization.withoutProtection)

	container.panel.eventHandler = function(mainContainer, object, eventData)
		if eventData[1] == "touch" then
			container:delete()
			MineOSCore.OSDraw()

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

	if not MineOSCore.OSSettings.protectionMethod then
		setProtectionMethod()
	elseif MineOSCore.OSSettings.protectionMethod == "password" then
		checkPassword()
	elseif MineOSCore.OSSettings.protectionMethod == "biometric" then
		biometry()
	end

	event.interruptingEnabled = true
	MineOSCore.OSDraw()
end

---------------------------------------------- Основные функции ------------------------------------------------------------------------

local function changeWallpaper()
	MineOSCore.OSMainContainer.background.wallpaper = nil

	if MineOSCore.OSSettings.wallpaperEnabled and MineOSCore.OSSettings.wallpaper and fs.exists(MineOSCore.OSSettings.wallpaper) then
		if MineOSCore.OSSettings.wallpaperMode == 1 then
			MineOSCore.OSMainContainer.background.wallpaper = image.transform(image.load(MineOSCore.OSSettings.wallpaper), MineOSCore.OSMainContainer.width, MineOSCore.OSMainContainer.height)
			MineOSCore.OSMainContainer.background.wallpaperPosition.x, MineOSCore.OSMainContainer.background.wallpaperPosition.y = 1, 1
		else
			MineOSCore.OSMainContainer.background.wallpaper = image.load(MineOSCore.OSSettings.wallpaper)
			MineOSCore.OSMainContainer.background.wallpaperPosition.x = math.floor(1 + MineOSCore.OSMainContainer.width / 2 - image.getWidth(MineOSCore.OSMainContainer.background.wallpaper) / 2)
			MineOSCore.OSMainContainer.background.wallpaperPosition.y = math.floor(1 + MineOSCore.OSMainContainer.height / 2 - image.getHeight(MineOSCore.OSMainContainer.background.wallpaper) / 2)
		end
	end
end

---------------------------------------------- Всякая параша для ОС-контейнера ------------------------------------------------------------------------

local function changeResolution()
	buffer.setResolution(table.unpack(MineOSCore.OSSettings.resolution or {160, 50}))

	MineOSCore.OSMainContainer.width, MineOSCore.OSMainContainer.height = buffer.width, buffer.height

	MineOSCore.OSMainContainer.iconField.width = MineOSCore.OSMainContainer.width
	MineOSCore.OSMainContainer.iconField.height = MineOSCore.OSMainContainer.height
	MineOSCore.OSMainContainer.iconField:updateFileList()

	MineOSCore.OSMainContainer.dockContainer.sort()
	MineOSCore.OSMainContainer.dockContainer.localPosition.y = MineOSCore.OSMainContainer.height - MineOSCore.OSMainContainer.dockContainer.height + 1

	MineOSCore.OSMainContainer.menu.width = MineOSCore.OSMainContainer.width
	MineOSCore.OSMainContainer.menuLayout.width = MineOSCore.OSMainContainer.width
	MineOSCore.OSMainContainer.background.width, MineOSCore.OSMainContainer.background.height = MineOSCore.OSMainContainer.width, MineOSCore.OSMainContainer.height

	MineOSCore.OSMainContainer.windowsContainer.width, MineOSCore.OSMainContainer.windowsContainer.height = MineOSCore.OSMainContainer.width, MineOSCore.OSMainContainer.height - 1
end

local function moveDockIcon(index, direction)
	MineOSCore.OSMainContainer.dockContainer.children[index], MineOSCore.OSMainContainer.dockContainer.children[index + direction] = MineOSCore.OSMainContainer.dockContainer.children[index + direction], MineOSCore.OSMainContainer.dockContainer.children[index]
	MineOSCore.OSMainContainer.dockContainer.sort()
	MineOSCore.OSMainContainer.dockContainer.saveToOSSettings()
	MineOSCore.OSDraw()
end

local function createOSWindow()
	MineOSCore.OSMainContainer = GUI.fullScreenContainer()

	MineOSCore.OSMainContainer.background = MineOSCore.OSMainContainer:addChild(GUI.object(1, 1, 1, 1))
	MineOSCore.OSMainContainer.background.wallpaperPosition = {x = 1, y = 1}
	MineOSCore.OSMainContainer.background.draw = function(object)
		buffer.square(object.x, object.y, object.width, object.height, MineOSCore.OSSettings.backgroundColor or 0x0F0F0F, 0x0, " ")
		if object.wallpaper then
			buffer.image(object.wallpaperPosition.x, object.wallpaperPosition.y, object.wallpaper)
		end
	end

	MineOSCore.OSMainContainer.iconField = MineOSCore.OSMainContainer:addChild(
		MineOSCore.iconField(
			1, 2, 1, 1, 2, 1, 3, 2,
			0xFFFFFF,
			0xFFFFFF,
			MineOSCore.paths.desktop
		)
	)
	MineOSCore.OSMainContainer.iconField.iconConfigEnabled = true
	MineOSCore.OSMainContainer.iconField.launchers.directory = function(icon)
		MineOSCore.safeLaunch(MineOSCore.paths.explorer, "-o", icon.path)
	end
	MineOSCore.OSMainContainer.iconField.launchers.showContainingFolder = function(icon)
		MineOSCore.safeLaunch(MineOSCore.paths.explorer, "-o", fs.path(icon.path))
	end
	MineOSCore.OSMainContainer.iconField.launchers.showPackageContent = function(icon)
		MineOSCore.safeLaunch(MineOSCore.paths.explorer, "-o", icon.path)
	end

	-- Dock
	MineOSCore.OSMainContainer.dockContainer = MineOSCore.OSMainContainer:addChild(GUI.container(1, 1, MineOSCore.OSMainContainer.width, 6))
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
			x = x + MineOSCore.iconWidth + MineOSCore.OSMainContainer.iconField.spaceBetweenIcons.horizontal
		end

		MineOSCore.OSMainContainer.dockContainer.width = (#MineOSCore.OSMainContainer.dockContainer.children) * (MineOSCore.iconWidth + MineOSCore.OSMainContainer.iconField.spaceBetweenIcons.horizontal) - MineOSCore.OSMainContainer.iconField.spaceBetweenIcons.horizontal
		MineOSCore.OSMainContainer.dockContainer.localPosition.x = math.floor(MineOSCore.OSMainContainer.width / 2 - MineOSCore.OSMainContainer.dockContainer.width / 2)
	end

	local function dockIconEventHandler(mainContainer, icon, eventData)
		if eventData[1] == "touch" then
			icon.selected = true
			MineOSCore.OSDraw()

			if eventData[5] == 1 then
				icon.onRightClick(icon, eventData)
			else
				icon.onLeftClick(icon, eventData)
			end

			icon.selected = false
			MineOSCore.OSDraw()
		end
	end

	MineOSCore.OSMainContainer.dockContainer.addIcon = function(path, window)
		local icon = MineOSCore.OSMainContainer.dockContainer:addChild(MineOSCore.icon(1, 1, path, 0x262626, 0xFFFFFF))
		icon:analyseExtension()
		icon:moveBackward()

		icon.eventHandler = dockIconEventHandler

		icon.onLeftClick = function(icon, eventData)
			if icon.windows then
				for window in pairs(icon.windows) do
					window.hidden = false
					window:moveToFront()
				end
				MineOSCore.OSDraw()
			else
				-- os.sleep(MineOSCore.iconClickDelay)
				MineOSCore.iconDoubleClick(icon, eventData)
			end
		end

		icon.onRightClick = function(icon, eventData)
			local indexOf = icon:indexOf()

			local menu = MineOSCore.contextMenu(eventData[3], eventData[4])
			menu:addItem(MineOSCore.localization.showContainingFolder).onTouch = function()

			end
			menu:addSeparator()
			menu:addItem(MineOSCore.localization.moveRight, indexOf >= #MineOSCore.OSMainContainer.dockContainer.children - 1).onTouch = function()
				moveDockIcon(indexOf, 1)
			end
			menu:addItem(MineOSCore.localization.moveLeft, indexOf <= 1).onTouch = function()
				moveDockIcon(indexOf, -1)
			end
			menu:addSeparator()
			if icon.keepInDock then
				if #MineOSCore.OSMainContainer.dockContainer.children > 1 then
					menu:addItem(MineOSCore.localization.removeFromDock).onTouch = function()
						if icon.windows then
							icon.keepInDock = nil
						else
							icon:delete()
							MineOSCore.OSMainContainer.dockContainer.sort()
						end
						MineOSCore.OSMainContainer.dockContainer.saveToOSSettings()
						MineOSCore.OSDraw()
					end
				end
			else
				if icon.windows then
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
	icon.launchers.directory = function(icon)
		MineOSCore.safeLaunch(MineOSCore.paths.explorer, "-o", icon.path)
	end
	icon:analyseExtension()
	icon.image = MineOSCore.icons.trash

	icon.eventHandler = dockIconEventHandler

	icon.onLeftClick = function(icon, eventData)
		MineOSCore.iconDoubleClick(icon, eventData)
	end

	icon.onRightClick = function(icon, eventData)
		local menu = MineOSCore.contextMenu(eventData[3], eventData[4])
		menu:addItem(MineOSCore.localization.emptyTrash).onTouch = function()
			local container = MineOSCore.addUniversalContainer(MineOSCore.OSMainContainer, MineOSCore.localization.areYouSure)

			container.layout:addChild(GUI.button(1, 1, 30, 1, 0xEEEEEE, 0x262626, 0xA, 0x262626, "OK")).onTouch = function()
				for file in fs.list(MineOSCore.paths.trash) do
					fs.remove(MineOSCore.paths.trash .. file)
				end
				container:delete()
				computer.pushSignal("MineOSCore", "updateFileList")
			end

			container.panel.onTouch = function()
				container:delete()
				MineOSCore.OSDraw()
			end

			MineOSCore.OSDraw()
		end

		menu:show()
	end

	for i = 1, #MineOSCore.OSSettings.dockShortcuts do
		MineOSCore.OSMainContainer.dockContainer.addIcon(MineOSCore.OSSettings.dockShortcuts[i]).keepInDock = true
	end

	MineOSCore.OSMainContainer.dockContainer.draw = function(dockContainer)
		local color, currentDockTransparency, currentDockWidth, xPos, yPos = MineOSCore.OSSettings.dockColor or 0xFFFFFF, dockTransparency, dockContainer.width + 6, dockContainer.x - 3, dockContainer.y + dockContainer.height - 1

		for i = 1, dockContainer.height - 2 do
			buffer.text(xPos, yPos, color, "◢", MineOSCore.OSSettings.transparencyEnabled and currentDockTransparency)
			buffer.square(xPos + 1, yPos, currentDockWidth - 2, 1, color, 0xFFFFFF, " ", MineOSCore.OSSettings.transparencyEnabled and currentDockTransparency)
			buffer.text(xPos + currentDockWidth - 1, yPos, color, "◣", MineOSCore.OSSettings.transparencyEnabled and currentDockTransparency)

			currentDockTransparency, currentDockWidth, xPos, yPos = currentDockTransparency + 0.08, currentDockWidth - 2, xPos + 1, yPos - 1
			if currentDockTransparency > 1 then
				currentDockTransparency = 1
			end
		end

		GUI.drawContainerContent(dockContainer)
	end

	-- Custom windows support
	MineOSCore.OSMainContainer.windowsContainer = MineOSCore.OSMainContainer:addChild(GUI.container(1, 2, 1, 1))

	-- Main menu
	MineOSCore.OSMainContainer.menu = MineOSCore.OSMainContainer:addChild(GUI.menu(1, 1, MineOSCore.OSMainContainer.width, MineOSCore.OSSettings.menuColor or 0xFFFFFF, 0x555555, 0x3366CC, 0xFFFFFF, MineOSCore.OSSettings.transparencyEnabled and menuTransparency))
	local item1 = MineOSCore.OSMainContainer.menu:addItem("MineOS", 0x000000)
	item1.onTouch = function()
		local menu = MineOSCore.contextMenu(item1.x, item1.y + 1)

		menu:addItem(MineOSCore.localization.aboutSystem).onTouch = function()
			local container = MineOSCore.addUniversalContainer(MineOSCore.OSMainContainer, MineOSCore.localization.aboutSystem)
			container.layout:addChild(GUI.textBox(1, 1, 53, #copyright, nil, 0xBBBBBB, copyright, 1, 0, 0))
		end

		menu:addItem(MineOSCore.localization.updates).onTouch = function()
			MineOSCore.safeLaunch("/MineOS/Applications/AppMarket.app/Main.lua", "updates")
		end

		menu:addSeparator()

		menu:addItem(MineOSCore.localization.logout, MineOSCore.OSSettings.protectionMethod == "withoutProtection").onTouch = function()
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
			MineOSCore.OSMainContainer:stopEventHandling()
			MineOSCore.clearTerminal()
			os.exit()
		end

		menu:show()
	end

	local item2 = MineOSCore.OSMainContainer.menu:addItem(MineOSCore.localization.network)
	item2.onTouch = function()
		local menu = MineOSCore.contextMenu(item2.x, item2.y + 1)

		if component.isAvailable("modem") then
			menu:addItem(MineOSCore.OSSettings.network.enabled and MineOSCore.localization.networkDisable or MineOSCore.localization.networkEnable).onTouch = function()
				MineOSCore.OSSettings.network.enabled = not MineOSCore.OSSettings.network.enabled
				MineOSCore.saveOSSettings()
				if MineOSCore.OSSettings.network.enabled then
					MineOSNetwork.enable()
				else
					MineOSNetwork.disable()
				end
				MineOSNetwork.broadcastComputerState(MineOSCore.OSSettings.network.enabled)
			end

			menu:addItem(MineOSCore.localization.networkName).onTouch = function()
				local container = MineOSCore.addUniversalContainer(MineOSCore.OSMainContainer, MineOSCore.localization.networkName)

				local textBox = container.layout:addChild(GUI.inputField(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0x666666, 0xEEEEEE, 0x262626, MineOSCore.OSSettings.network.name, nil))
				textBox.onInputFinished = function()
					if textBox.text then
						MineOSNetwork.broadcastComputerState(false)
						MineOSCore.OSSettings.network.name = textBox.text
						MineOSCore.saveOSSettings()
						MineOSNetwork.broadcastComputerState(MineOSCore.OSSettings.network.enabled)
						
						container:delete()
						MineOSCore.OSDraw()
					end
				end
			end

			if MineOSNetwork.modemProxy.isWireless() then
				local subMenu = menu:addSubMenu(MineOSCore.localization.networkSearchRadius)
				local i = 2
				while i <= 512 do
					subMenu:addItem(tostring(i)).onTouch = function()
						MineOSCore.OSSettings.network.signalStrength = i
						MineOSCore.saveOSSettings()
						MineOSNetwork.setSignalStrength(i)
					end
					i = i * 2
				end
			end

			if MineOSCore.OSSettings.network.enabled then
				menu:addSeparator()
				
				if MineOSNetwork.getProxyCount() > 0 then
					for proxy, path in fs.mounts() do
						if proxy.network then
							local subMenu = menu:addSubMenu(string.limit(MineOSNetwork.getProxyName(proxy), 25, "end"))

							subMenu:addItem(MineOSCore.OSSettings.network.users[proxy.address].allowReadAndWrite and MineOSCore.localization.networkDenyReadAndWrite or MineOSCore.localization.networkAllowReadAndWrite).onTouch = function()
								MineOSCore.OSSettings.network.users[proxy.address].allowReadAndWrite = not MineOSCore.OSSettings.network.users[proxy.address].allowReadAndWrite
								MineOSCore.saveOSSettings()
							end

							subMenu:addItem(MineOSCore.OSSettings.network.users[proxy.address].allowMessages and MineOSCore.localization.networkDenyMessages or MineOSCore.localization.networkAllowMessages).onTouch = function()
								MineOSCore.OSSettings.network.users[proxy.address].allowMessages = not MineOSCore.OSSettings.network.users[proxy.address].allowMessages
								MineOSCore.saveOSSettings()
							end

							subMenu:addSeparator()

							subMenu:addItem(MineOSCore.localization.networkSendMessage).onTouch = function()
								local container = MineOSCore.addUniversalContainer(MineOSCore.OSMainContainer, MineOSCore.localization.networkSendMessage)

								local textBox = container.layout:addChild(GUI.inputField(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0x666666, 0xEEEEEE, 0x262626, nil, nil, true))
								textBox.onInputFinished = function()
									if textBox.text then
										MineOSNetwork.sendMessage(proxy.address, "MineOSNetwork", "message", textBox.text)
										
										container:delete()
										MineOSCore.OSDraw()
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

	local item3 = MineOSCore.OSMainContainer.menu:addItem(MineOSCore.localization.settings)
	item3.onTouch = function()
		local menu = MineOSCore.contextMenu(item3.x, item3.y + 1)

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
					MineOSCore.OSMainContainer.updateFileListAndDraw()
				end
			end
		end

		menu:addSeparator()

		menu:addItem(MineOSCore.localization.wallpaper).onTouch = function()
			local container = MineOSCore.addUniversalContainer(MineOSCore.OSMainContainer, MineOSCore.localization.wallpaper)

			local filesystemChooser = container.layout:addChild(GUI.filesystemChooser(1, 1, 36, 3, 0xEEEEEE, 0x262626, 0x444444, 0x999999, MineOSCore.OSSettings.wallpaper, MineOSCore.localization.open, MineOSCore.localization.cancel, MineOSCore.localization.wallpaperPath, "/"))
			filesystemChooser:addExtensionFilter(".pic")
			filesystemChooser.onSubmit = function(path)
				MineOSCore.OSSettings.wallpaper = path
				MineOSCore.saveOSSettings()
				changeWallpaper()

				MineOSCore.OSDraw()
			end

			local comboBox = container.layout:addChild(GUI.comboBox(1, 1, 36, 3, 0xEEEEEE, 0x262626, 0x444444, 0x999999))
			comboBox.selectedItem = MineOSCore.OSSettings.wallpaperMode or 1
			comboBox:addItem(MineOSCore.localization.wallpaperModeStretch)
			comboBox:addItem(MineOSCore.localization.wallpaperModeCenter)

			local switch = container.layout:addChild(GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0x2D2D2D, 0xEEEEEE, 0xBBBBBB, MineOSCore.localization.wallpaperEnabled .. ":", MineOSCore.OSSettings.wallpaperEnabled)).switch
			container.layout:addChild(GUI.textBox(1, 1, 36, 1, nil, 0x555555, {MineOSCore.localization.wallpaperSwitchInfo}, 1, 0, 0, true, true))

			switch.onStateChanged = function()
				MineOSCore.OSSettings.wallpaperEnabled = switch.state
				MineOSCore.saveOSSettings()
				changeWallpaper()

				MineOSCore.OSDraw()
			end
			comboBox.onItemSelected = function()
				MineOSCore.OSSettings.wallpaperMode = comboBox.selectedItem
				MineOSCore.saveOSSettings()
				changeWallpaper()

				MineOSCore.OSDraw()
			end
		end
		menu:addItem(MineOSCore.localization.screensaver).onTouch = function()
			local container = MineOSCore.addUniversalContainer(MineOSCore.OSMainContainer, MineOSCore.localization.screensaver)

			local comboBox = container.layout:addChild(GUI.comboBox(1, 1, 36, 3, 0xEEEEEE, 0x262626, 0x444444, 0x999999))
			local fileList = fs.sortedList(screensaversPath, "name", false)
			for i = 1, #fileList do
				comboBox:addItem(fs.hideExtension(fileList[i]))
				if MineOSCore.OSSettings.screensaver == fileList[i] then
					comboBox.selectedItem = i
				end
			end
			local switch = container.layout:addChild(GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0x2D2D2D, 0xEEEEEE, 0xBBBBBB, MineOSCore.localization.screensaverEnabled .. ":", MineOSCore.OSSettings.screensaverEnabled)).switch
			local slider = container.layout:addChild(GUI.slider(1, 1, 36, 0x66DB80, 0x2D2D2D, 0xEEEEEE, 0xBBBBBB, 1, 100, MineOSCore.OSSettings.screensaverDelay or 20, false, MineOSCore.localization.screensaverDelay .. ": ", ""))

			container.panel.eventHandler = function(mainContainer, object, eventData)
				if eventData[1] == "touch" then
					container:delete()
					MineOSCore.OSDraw()

					MineOSCore.OSSettings.screensaverEnabled = switch.state
					MineOSCore.OSSettings.screensaver = fileList[comboBox.selectedItem]
					MineOSCore.OSSettings.screensaverDelay = slider.value

					MineOSCore.saveOSSettings()
				end
			end

			MineOSCore.OSDraw()
		end

		menu:addItem(MineOSCore.localization.colorScheme).onTouch = function()
			local container = MineOSCore.addUniversalContainer(MineOSCore.OSMainContainer, MineOSCore.localization.colorScheme)

			local backgroundColorSelector = container.layout:addChild(GUI.colorSelector(1, 1, 36, 3, MineOSCore.OSSettings.backgroundColor or 0x0F0F0F, MineOSCore.localization.backgroundColor))
			local menuColorSelector = container.layout:addChild(GUI.colorSelector(1, 1, 36, 3, MineOSCore.OSSettings.menuColor or 0xFFFFFF, MineOSCore.localization.menuColor))
			local dockColorSelector = container.layout:addChild(GUI.colorSelector(1, 1, 36, 3, MineOSCore.OSSettings.dockColor or 0xFFFFFF, MineOSCore.localization.dockColor))

			local switch = container.layout:addChild(GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0x2D2D2D, 0xEEEEEE, 0xEEEEEE, MineOSCore.localization.transparencyEnabled .. ":", MineOSCore.OSSettings.transparencyEnabled)).switch
			switch.onStateChanged = function()
				MineOSCore.OSSettings.transparencyEnabled = switch.state
				MineOSCore.saveOSSettings()
				MineOSCore.OSMainContainer.menu.colors.transparency = MineOSCore.OSSettings.transparencyEnabled and menuTransparency
				container.panel.colors.background = switch.state and 0x0 or (MineOSCore.OSSettings.backgroundColor or 0x0F0F0F)
				container.panel.colors.transparency = switch.state and 0.2

				MineOSCore.OSDraw()
			end
			container.layout:addChild(GUI.textBox(1, 1, 36, 1, nil, 0x555555, {MineOSCore.localization.transparencySwitchInfo}, 1, 0, 0, true, true))

			-- Шоб рисовалось в реальном времени
			backgroundColorSelector.onTouch = function()
				MineOSCore.OSSettings.backgroundColor = backgroundColorSelector.color
				MineOSCore.OSSettings.menuColor = menuColorSelector.color
				MineOSCore.OSSettings.dockColor = dockColorSelector.color
				MineOSCore.OSMainContainer.menu.colors.default.background = MineOSCore.OSSettings.menuColor

				MineOSCore.OSDraw()
			end
			menuColorSelector.onTouch = backgroundColorSelector.onTouch
			dockColorSelector.onTouch = backgroundColorSelector.onTouch

			container.panel.eventHandler = function(mainContainer, object, eventData)
				if eventData[1] == "touch" then
					container:delete()
					MineOSCore.OSDraw()

					MineOSCore.saveOSSettings()
				end
			end
		end

		menu:addSeparator()

		menu:addItem(MineOSCore.localization.setProtectionMethod).onTouch = function()
			setProtectionMethod()
		end

		menu:show()
	end

	MineOSCore.OSMainContainer.menuLayout = MineOSCore.OSMainContainer:addChild(GUI.layout(1, 1, 1, 1, 1, 1))
	MineOSCore.OSMainContainer.menuLayout:setCellSpacing(1, 1, 0)
	MineOSCore.OSMainContainer.menuLayout:setCellDirection(1, 1, GUI.directions.horizontal)
	MineOSCore.OSMainContainer.menuLayout:setCellAlignment(1, 1, GUI.alignment.horizontal.right, GUI.alignment.vertical.top)

	local dateButton = MineOSCore.addMenuWidget(GUI.button(1, 1, 1, 1, nil, 0x0, 0x3366CC, 0xFFFFFF, " "))
	dateButton.switchMode = true

	dateButton.onTouch = function()
		local menu = MineOSCore.contextMenu(dateButton.x, dateButton.y + 1)
		for i = -12, 12 do
			menu:addItem("GMT" .. (i >= 0 and "+" or "") .. i).onTouch = function()
				MineOSCore.OSSettings.timezone = i
				MineOSCore.saveOSSettings()

				MineOSCore.OSUpdateTimezone()
				MineOSCore.OSUpdateDate()
				MineOSCore.OSDraw()
			end
		end
		menu:show()
		dateButton.pressed = false
		MineOSCore.OSDraw()
	end

	MineOSCore.OSUpdateTimezone = function()
		local timezone = MineOSCore.OSSettings.timezone or 0
		timezoneCorrection = timezone * 3600
	end

	MineOSCore.OSUpdateDate = function()
		if not realTimestamp then
			local name = MineOSCore.paths.system .. "/Timestamp.tmp"
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

	MineOSCore.OSDraw = function(force)
		MineOSCore.OSMainContainer:draw()
		buffer.draw(force)
	end

	MineOSCore.OSMainContainer.updateFileListAndDraw = function(forceRedraw)
		MineOSCore.OSMainContainer.iconField:updateFileList()
		MineOSCore.OSDraw(forceRedraw)
	end

	MineOSCore.OSMainContainer.eventHandler = function(mainContainer, object, eventData)
		if eventData[1] == "MineOSCore" then
			if eventData[2] == "updateFileList" then
				MineOSCore.OSMainContainer.updateFileListAndDraw()
			elseif eventData[2] == "updateFileListAndBufferTrueRedraw" then
				MineOSCore.OSMainContainer.updateFileListAndDraw(true)
			elseif eventData[2] == "updateWallpaper" then
				changeWallpaper()
				MineOSCore.OSDraw()
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
			MineOSCore.OSDraw()
			computerDateUptime = computerUptime
		end

		if MineOSCore.OSSettings.screensaverEnabled then
			if eventData[1] then
				screensaverUptime = computer.uptime()
			end

			if computerUptime - screensaverUptime >= MineOSCore.OSSettings.screensaverDelay then
				if fs.exists(screensaversPath .. MineOSCore.OSSettings.screensaver) then
					MineOSCore.safeLaunch(screensaversPath .. MineOSCore.OSSettings.screensaver)
					MineOSCore.OSDraw(true)
				end

				screensaverUptime = computer.uptime()
			end
		end
	end
end

---------------------------------------------- Сама ОС ------------------------------------------------------------------------

createOSWindow()
changeResolution()
changeWallpaper()
MineOSCore.OSUpdateTimezone()
MineOSCore.OSUpdateDate()
login()

if MineOSCore.OSSettings.network.enabled then
	MineOSNetwork.setSignalStrength(MineOSCore.OSSettings.network.signalStrength)
	MineOSNetwork.enable()
	MineOSNetwork.broadcastComputerState(true)
end

while true do
	local success, path, line, traceback = MineOSCore.call(
		MineOSCore.OSMainContainer.startEventHandling,
		MineOSCore.OSMainContainer,
		1
	)
	if success then
		break
	else
		createOSWindow()
		changeResolution()
		changeWallpaper()
		MineOSCore.OSMainContainer.updateFileListAndDraw()

		MineOSCore.showErrorWindow(path, line, traceback)

		MineOSCore.OSDraw()
	end
end
