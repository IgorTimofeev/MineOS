
---------------------------------------- Либсы-хуибсы ----------------------------------------

local computer = require("computer")
local component = require("component")
local unicode = require("unicode")
local fs = require("filesystem")
local keyboard = require("keyboard")
local event = require("event")
local image = require("image")
local color = require("color")
local buffer = require("doubleBuffering")
local GUI = require("GUI")
local MineOSPaths = require("MineOSPaths")
local MineOSCore = require("MineOSCore")
local MineOSNetwork = require("MineOSNetwork")
local MineOSInterface = require("MineOSInterface")

---------------------------------------- Всякая константная залупа ----------------------------------------

local dockTransparency = 0.4

local realTimestamp
local bootUptime = computer.uptime()
local dateUptime = bootUptime
local screensaverUptime = bootUptime
local timezoneCorrection
local screensaversPath = MineOSPaths.system .. "Screensavers/"
local overrideGUIDropDownMenu = GUI.dropDownMenu

---------------------------------------- Система защиты пекарни ----------------------------------------

local function biometry(creatingNew)
	if not creatingNew then
		event.interruptingEnabled = false
	end

	local container = MineOSInterface.addBackgroundContainer(MineOSInterface.mainContainer)
	
	local fingerImage = container.layout:addChild(GUI.image(1, 1, image.fromString([[180E0000FF 0000FF 0000FF 0000FF 0000FF 00FFFF▄00FFFF▄00FFFF▄00FFFF▄FFFFFF▀FFFFFF▀FFFFFF▀FFFFFF▀FFFFFF▀FFFFFF▀00FFFF▄00FFFF▄00FFFF▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 00FFFF▄FFFF00▄FFFFFF▀0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF FFFFFF▀FFFFFF▀FFFF00▄00FFFF▄0000FF 0000FF 0000FF 0000FF 0000FF FFFF00▄FFFFFF▀0000FF 0000FF 0000FF 00FFFF▄00FFFF▄FFFF00▄FFFFFF▀FFFFFF▀FFFFFF▀FFFFFF▀FFFFFF▀FFFFFF▀FFFF00▄00FFFF▄0000FF 0000FF FFFFFF▀FFFF00▄00FFFF▄0000FF 0000FF FFFF00▄FFFFFF▀0000FF 0000FF 00FFFF▄FFFF00▄FFFFFF▀0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF FFFF00▄00FFFF▄0000FF 0000FF FFFF00▄0000FF 00FFFF▄FFFF00▄0000FF 0000FF 00FFFF▄FFFF00▄0000FF 0000FF 0000FF 00FFFF▄00FFFF▄FFFFFF▀FFFFFF▀FFFFFF▀FFFFFF▀FFFFFF▀FFFFFF▀00FFFF▄0000FF FFFF00▄00FFFF▄0000FF FFFFFF▀FFFF00▄FFFF00▄0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF 0000FF 00FFFF▄00FFFF▄00FFFF▄0000FF 0000FF FFFF00▄0000FF 0000FF FFFF00▄0000FF 0000FF FFFF00▄FFFF00▄0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF 00FFFF▄FFFFFF▀0000FF 0000FF 0000FF 0000FF 00FFFF▄FFFF00▄0000FF 0000FF FFFF00▄0000FF 0000FF FFFF00▄0000FF 0000FF FFFF00▄FFFF00▄0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF FFFF00▄0000FF 0000FF 0000FF 0000FF 00FFFF▄FFFF00▄0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF FFFF00▄0000FF 00FFFF▄FFFF00▄FFFF00▄00FFFF▄0000FF 0000FF FFFF00▄00FFFF▄0000FF FFFFFF▀FFFF00▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF FFFF00▄FFFFFF▀0000FF FFFF00▄0000FF 0000FF FFFF00▄0000FF 0000FF 0000FF FFFF00▄00FFFF▄0000FF FFFFFF▀FFFF00▄0000FF 0000FF 0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF 00FFFF▄FFFF00▄0000FF 00FFFF▄FFFFFF▀0000FF 0000FF FFFF00▄00FFFF▄0000FF 0000FF 0000FF FFFF00▄00FFFF▄0000FF FFFF00▄00FFFF▄0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF 00FFFF▄FFFFFF▀0000FF 0000FF FFFF00▄0000FF 0000FF 0000FF 0000FF FFFF00▄00FFFF▄0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF FFFF00▄FFFFFF▀0000FF 0000FF FFFF00▄FFFFFF▀0000FF 0000FF 0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF 0000FF FFFFFF▀FFFF00▄00FFFF▄0000FF 0000FF 0000FF 0000FF 00FFFF▄FFFFFF▀0000FF 0000FF 0000FF 00FFFF▄FFFF00▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF FFFF00▄00FFFF▄0000FF 0000FF 0000FF FFFFFF▀0000FF 0000FF 0000FF 0000FF FFFFFF▀0000FF 0000FF 00FFFF▄FFFF00▄FFFFFF▀0000FF 0000FF 0000FF 0000FF ]])))
	local text = creatingNew and MineOSCore.localization.putFingerToRegister or MineOSCore.localization.putFingerToVerify
	local label = container.layout:addChild(GUI.label(1, 1, container.width, 1, 0xE1E1E1, text):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP))

	local scanLine = container:addChild(GUI.label(1, 1, container.width, 1, 0xFFFFFF, string.rep("─", image.getWidth(fingerImage.image) + 6)):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP))
	local fingerImageHeight = image.getHeight(fingerImage.image) + 1
	local delay = 0.5
	scanLine.hidden = true

	fingerImage.eventHandler = function(mainContainer, object, e1, e2, e3, e4, e5, e6, ...)
		if e1 == "touch" then
			scanLine:addAnimation(
				function(mainContainer, animation)
					scanLine.hidden = false
					if animation.position <= 0.5 then
						scanLine.localY = math.floor(fingerImage.localY + fingerImageHeight - fingerImageHeight * animation.position * 2 - 1)
					else
						scanLine.localY = math.floor(fingerImage.localY + fingerImageHeight * (animation.position - 0.5) * 2 - 1)
					end
				end,
				function(mainContainer, animation)
					scanLine.hidden = true
					animation:remove()

					local touchedHash = require("SHA2").hash(e6)

					if creatingNew then
						label.text = MineOSCore.localization.fingerprintCreated

						MineOSInterface.mainContainer:drawOnScreen()

						MineOSCore.properties.protectionMethod = "biometric"
						MineOSCore.properties.biometryHash = touchedHash
						MineOSCore.saveProperties()

						container:remove()
						os.sleep(delay)
					else
						if touchedHash == MineOSCore.properties.biometryHash then
							label.text = MineOSCore.localization.welcomeBack .. e6

							MineOSInterface.mainContainer:drawOnScreen()

							container:remove()
							os.sleep(delay)

							event.interruptingEnabled = true
						else
							label.text = MineOSCore.localization.accessDenied
							local oldBackground = container.panel.colors.background
							container.panel.colors.background = 0x550000

							MineOSInterface.mainContainer:drawOnScreen()

							os.sleep(delay)

							label.text = text
							container.panel.colors.background = oldBackground
						end
					end

					MineOSInterface.mainContainer:drawOnScreen()
				end
			):start(3)
		end
	end
	label.eventHandler, container.panel.eventHandler = fingerImage.eventHandler, fingerImage.eventHandler

	MineOSInterface.mainContainer:drawOnScreen()
end

local function checkPassword()
	event.interruptingEnabled = false

	local container = MineOSInterface.addBackgroundContainer(MineOSInterface.mainContainer, MineOSCore.localization.inputPassword)
	local inputField = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0x878787, 0xE1E1E1, 0x2D2D2D, nil, nil, true, "*"))
	local label = container.layout:addChild(GUI.label(1, 1, 36, 1, 0xFF4940, MineOSCore.localization.incorrectPassword)):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
	label.hidden = true

	container.panel.eventHandler = nil

	inputField.onInputFinished = function()
		local hash = require("SHA2").hash(inputField.text or "")
		if hash == MineOSCore.properties.passwordHash then
			container:remove()
			event.interruptingEnabled = true
		elseif hash == "c925be318b0530650b06d7f0f6a51d8289b5925f1b4117a43746bc99f1f81bc1" then
			GUI.alert(MineOSCore.localization.mineOSCreatorUsedMasterPassword)
			container:remove()
			event.interruptingEnabled = true
		else
			label.hidden = false
		end

		MineOSInterface.mainContainer:drawOnScreen()
	end

	MineOSInterface.mainContainer:drawOnScreen()
	inputField:startInput()
end

local function setPassword()
	local container = MineOSInterface.addBackgroundContainer(MineOSInterface.mainContainer, MineOSCore.localization.passwordProtection)
	local inputField1 = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0x878787, 0xE1E1E1, 0x2D2D2D, nil, MineOSCore.localization.inputPassword, true, "*"))
	local inputField2 = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0x878787, 0xE1E1E1, 0x2D2D2D, nil, MineOSCore.localization.confirmInputPassword, true, "*"))
	local label = container.layout:addChild(GUI.label(1, 1, 36, 1, 0xFF4940, MineOSCore.localization.passwordsAreDifferent)):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
	label.hidden = true

	local function check()
		if inputField1.text ~= "" and inputField1.text == inputField2.text then
			container:remove()

			MineOSCore.properties.protectionMethod = "password"
			MineOSCore.properties.passwordHash = require("SHA2").hash(inputField1.text or "")
			MineOSCore.saveProperties()
		else
			label.hidden = false
		end

		MineOSInterface.mainContainer:drawOnScreen()
	end

	inputField1.onInputFinished = check
	inputField2.onInputFinished = check

	container.panel.eventHandler = function(mainContainer, object, e1)
		if e1 == "touch" then
			check()
		end
	end

	MineOSInterface.mainContainer:drawOnScreen()
end

local function setWithoutProtection()
	MineOSCore.properties.passwordHash = nil
	MineOSCore.properties.protectionMethod = "withoutProtection"
	MineOSCore.saveProperties()
end

local function setProtectionMethod()
	local container = MineOSInterface.addBackgroundContainer(MineOSInterface.mainContainer, MineOSCore.localization.protectYourComputer)

	local comboBox = container.layout:addChild(GUI.comboBox(1, 1, 36, 3, 0xE1E1E1, 0x2D2D2D, 0x4B4B4B, 0x969696))
	comboBox:addItem(MineOSCore.localization.biometricProtection).onTouch = function()
		container:remove()
		biometry(true)
	end
	comboBox:addItem(MineOSCore.localization.passwordProtection).onTouch = function()
		container:remove()
		setPassword()
	end
	comboBox:addItem(MineOSCore.localization.withoutProtection).onTouch = function()
		container:remove()
		setWithoutProtection()
	end

	container.panel.eventHandler = function(mainContainer, object, e1)
		if e1 == "touch" then
			comboBox:getItem(comboBox.selectedItem).onTouch()
		end
	end 
end

local function login()
	if not MineOSCore.properties.protectionMethod then
		setProtectionMethod()
	elseif MineOSCore.properties.protectionMethod == "password" then
		checkPassword()
	elseif MineOSCore.properties.protectionMethod == "biometric" then
		biometry()
	end

	MineOSInterface.mainContainer:drawOnScreen()
end

---------------------------------------- Основные функции ----------------------------------------

function MineOSInterface.changeWallpaper()
	MineOSInterface.mainContainer.background.wallpaper = nil

	if MineOSCore.properties.wallpaperEnabled and MineOSCore.properties.wallpaper then
		local result, reason = image.load(MineOSCore.properties.wallpaper)
		if result then
			MineOSInterface.mainContainer.background.wallpaper, result = result, nil

			if MineOSCore.properties.wallpaperMode == 1 then
				MineOSInterface.mainContainer.background.wallpaper = image.transform(MineOSInterface.mainContainer.background.wallpaper, MineOSInterface.mainContainer.width, MineOSInterface.mainContainer.height)
				MineOSInterface.mainContainer.background.wallpaperPosition.x, MineOSInterface.mainContainer.background.wallpaperPosition.y = 1, 1
			else
				MineOSInterface.mainContainer.background.wallpaperPosition.x = math.floor(1 + MineOSInterface.mainContainer.width / 2 - image.getWidth(MineOSInterface.mainContainer.background.wallpaper) / 2)
				MineOSInterface.mainContainer.background.wallpaperPosition.y = math.floor(1 + MineOSInterface.mainContainer.height / 2 - image.getHeight(MineOSInterface.mainContainer.background.wallpaper) / 2)
			end

			local backgrounds, foregrounds, r, g, b = MineOSInterface.mainContainer.background.wallpaper[3], MineOSInterface.mainContainer.background.wallpaper[4]
			for i = 1, #backgrounds do
				r, g, b = color.integerToRGB(backgrounds[i])
				backgrounds[i] = color.RGBToInteger(
					math.floor(r * MineOSCore.properties.wallpaperBrightness),
					math.floor(g * MineOSCore.properties.wallpaperBrightness),
					math.floor(b * MineOSCore.properties.wallpaperBrightness)
				)

				r, g, b = color.integerToRGB(foregrounds[i])
				foregrounds[i] = color.RGBToInteger(
					math.floor(r * MineOSCore.properties.wallpaperBrightness),
					math.floor(g * MineOSCore.properties.wallpaperBrightness),
					math.floor(b * MineOSCore.properties.wallpaperBrightness)
				)
			end
		else
			GUI.alert("Failed to load wallpaper: " .. (reason or "image file is corrupted"))
		end
	end
end

---------------------------------------- Всякая параша для ОС-контейнера ----------------------------------------

function MineOSInterface.changeResolution()
	buffer.setResolution(table.unpack(MineOSCore.properties.resolution or {buffer.getGPUProxy().maxResolution()}))

	MineOSInterface.mainContainer.width, MineOSInterface.mainContainer.height = buffer.getResolution()

	MineOSInterface.mainContainer.iconField.width = MineOSInterface.mainContainer.width
	MineOSInterface.mainContainer.iconField.height = MineOSInterface.mainContainer.height
	MineOSInterface.mainContainer.iconField:updateFileList()

	MineOSInterface.mainContainer.dockContainer.sort()
	MineOSInterface.mainContainer.dockContainer.localY = MineOSInterface.mainContainer.height - MineOSInterface.mainContainer.dockContainer.height + 1

	MineOSInterface.mainContainer.menu.width = MineOSInterface.mainContainer.width
	MineOSInterface.mainContainer.menuLayout.width = MineOSInterface.mainContainer.width
	MineOSInterface.mainContainer.background.width, MineOSInterface.mainContainer.background.height = MineOSInterface.mainContainer.width, MineOSInterface.mainContainer.height

	MineOSInterface.mainContainer.windowsContainer.width, MineOSInterface.mainContainer.windowsContainer.height = MineOSInterface.mainContainer.width, MineOSInterface.mainContainer.height - 1
end

local function moveDockIcon(index, direction)
	MineOSInterface.mainContainer.dockContainer.children[index], MineOSInterface.mainContainer.dockContainer.children[index + direction] = MineOSInterface.mainContainer.dockContainer.children[index + direction], MineOSInterface.mainContainer.dockContainer.children[index]
	MineOSInterface.mainContainer.dockContainer.sort()
	MineOSInterface.mainContainer.dockContainer.saveToOSSettings()
	MineOSInterface.mainContainer:drawOnScreen()
end

local function getPercentageColor(pecent)
	if pecent >= 0.75 then
		return 0x00B640
	elseif pecent >= 0.6 then
		return 0x99DB40
	elseif pecent >= 0.3 then
		return 0xFFB640
	elseif pecent >= 0.2 then
		return 0xFF9240
	else
		return 0xFF4940
	end
end

function MineOSInterface.applyTransparency()
	GUI.dropDownMenu = function(...)
		local menu = overrideGUIDropDownMenu(...)
		menu.colors.transparency.background = MineOSCore.properties.transparencyEnabled and GUI.CONTEXT_MENU_BACKGROUND_TRANSPARENCY
		menu.colors.transparency.shadow = MineOSCore.properties.transparencyEnabled and GUI.CONTEXT_MENU_SHADOW_TRANSPARENCY

		return menu
	end
end

function MineOSInterface.createWidgets()
	MineOSInterface.mainContainer:removeChildren()
	MineOSInterface.mainContainer.background = MineOSInterface.mainContainer:addChild(GUI.object(1, 1, 1, 1))
	MineOSInterface.mainContainer.background.wallpaperPosition = {x = 1, y = 1}
	MineOSInterface.mainContainer.background.draw = function(object)
		buffer.drawRectangle(object.x, object.y, object.width, object.height, MineOSCore.properties.backgroundColor, 0, " ")
		if object.wallpaper then
			buffer.drawImage(object.wallpaperPosition.x, object.wallpaperPosition.y, object.wallpaper)
		end
	end

	MineOSInterface.mainContainer.iconField = MineOSInterface.mainContainer:addChild(
		MineOSInterface.iconField(
			1, 2, 1, 1, 3, 2,
			0xFFFFFF,
			0xD2D2D2,
			MineOSPaths.desktop
		)
	)
	MineOSInterface.mainContainer.iconField.iconConfigEnabled = true
	MineOSInterface.mainContainer.iconField.launchers.directory = function(icon)
		MineOSInterface.safeLaunch(MineOSPaths.explorer, "-o", icon.path)
	end
	MineOSInterface.mainContainer.iconField.launchers.showContainingFolder = function(icon)
		MineOSInterface.safeLaunch(MineOSPaths.explorer, "-o", fs.path(icon.shortcutPath or icon.path))
	end
	MineOSInterface.mainContainer.iconField.launchers.showPackageContent = function(icon)
		MineOSInterface.safeLaunch(MineOSPaths.explorer, "-o", icon.path)
	end

	MineOSInterface.mainContainer.dockContainer = MineOSInterface.mainContainer:addChild(GUI.container(1, 1, MineOSInterface.mainContainer.width, 7))
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
		local x = 4
		for i = 1, #MineOSInterface.mainContainer.dockContainer.children do
			MineOSInterface.mainContainer.dockContainer.children[i].localX = x
			x = x + MineOSCore.properties.iconWidth + MineOSCore.properties.iconHorizontalSpaceBetween
		end

		MineOSInterface.mainContainer.dockContainer.width = #MineOSInterface.mainContainer.dockContainer.children * (MineOSCore.properties.iconWidth + MineOSCore.properties.iconHorizontalSpaceBetween) - MineOSCore.properties.iconHorizontalSpaceBetween + 6
		MineOSInterface.mainContainer.dockContainer.localX = math.floor(MineOSInterface.mainContainer.width / 2 - MineOSInterface.mainContainer.dockContainer.width / 2)
	end

	local function dockIconEventHandler(mainContainer, icon, e1, e2, e3, e4, e5, e6, ...)
		if e1 == "touch" then
			icon.selected = true
			MineOSInterface.mainContainer:drawOnScreen()

			if e5 == 1 then
				icon.onRightClick(icon, e1, e2, e3, e4, e5, e6, ...)
			else
				icon.onLeftClick(icon, e1, e2, e3, e4, e5, e6, ...)
			end
		end
	end

	MineOSInterface.mainContainer.dockContainer.addIcon = function(path, window)
		local icon = MineOSInterface.mainContainer.dockContainer:addChild(MineOSInterface.icon(1, 2, path, 0x2D2D2D, 0xFFFFFF))
		icon:analyseExtension()
		icon:moveBackward()

		icon.eventHandler = dockIconEventHandler

		icon.onLeftClick = function(icon, ...)
			if icon.windows then
				for window in pairs(icon.windows) do
					window.hidden = false
					window:moveToFront()
				end

				icon.selected = false
				MineOSInterface.updateMenu()
				MineOSInterface.mainContainer:drawOnScreen()
			else
				MineOSInterface.iconDoubleClick(icon, ...)
			end
		end

		icon.onRightClick = function(icon, e1, e2, e3, e4, ...)
			local indexOf = icon:indexOf()
			local menu = GUI.addContextMenu(MineOSInterface.mainContainer, e3, e4)
			
			menu.onMenuClosed = function()
				icon.selected = false
				MineOSInterface.mainContainer:drawOnScreen()
			end

			if icon.windows then
				local eventData = {...}
				menu:addItem(MineOSCore.localization.newWindow).onTouch = function()
					MineOSInterface.iconDoubleClick(icon, e1, e2, e3, e4, table.unpack(eventData))
				end
				menu:addItem(MineOSCore.localization.closeAllWindows).onTouch = function()
					for window in pairs(icon.windows) do
						window:close()
					end
					MineOSInterface.mainContainer:drawOnScreen()
				end
			end
			
			menu:addItem(MineOSCore.localization.showContainingFolder).onTouch = function()
				MineOSInterface.safeLaunch(MineOSPaths.explorer, "-o", fs.path(icon.shortcutPath or icon.path))			
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
							icon:remove()
							MineOSInterface.mainContainer.dockContainer.sort()
						end
						MineOSInterface.mainContainer.dockContainer.saveToOSSettings()
						MineOSInterface.mainContainer:drawOnScreen()
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

			MineOSInterface.mainContainer:drawOnScreen()
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

	icon.onLeftClick = function(icon, ...)
		MineOSInterface.iconDoubleClick(icon, ...)
	end

	icon.onRightClick = function(icon, e1, e2, e3, e4)
		local menu = GUI.addContextMenu(MineOSInterface.mainContainer, e3, e4)
		
		menu.onMenuClosed = function()
			icon.selected = false
			MineOSInterface.mainContainer:drawOnScreen()
		end
		
		menu:addItem(MineOSCore.localization.emptyTrash).onTouch = function()
			local container = MineOSInterface.addBackgroundContainer(MineOSInterface.mainContainer, MineOSCore.localization.areYouSure)

			container.layout:addChild(GUI.button(1, 1, 30, 1, 0xE1E1E1, 0x2D2D2D, 0xA5A5A5, 0x2D2D2D, "OK")).onTouch = function()
				for file in fs.list(MineOSPaths.trash) do
					fs.remove(MineOSPaths.trash .. file)
				end
				container:remove()
				computer.pushSignal("MineOSCore", "updateFileList")
			end

			container.panel.onTouch = function()
				container:remove()
				MineOSInterface.mainContainer:drawOnScreen()
			end

			MineOSInterface.mainContainer:drawOnScreen()
		end

		MineOSInterface.mainContainer:drawOnScreen()
	end

	for i = 1, #MineOSCore.properties.dockShortcuts do
		MineOSInterface.mainContainer.dockContainer.addIcon(MineOSCore.properties.dockShortcuts[i]).keepInDock = true
	end

	-- Draw dock drawDock dockDraw cyka заебался искать, блядь
	local overrideDockContainerDraw = MineOSInterface.mainContainer.dockContainer.draw
	MineOSInterface.mainContainer.dockContainer.draw = function(dockContainer)
		local color, currentDockTransparency, currentDockWidth, xPos = MineOSCore.properties.dockColor, dockTransparency, dockContainer.width - 2, dockContainer.x

		for y = dockContainer.y + dockContainer.height - 1, dockContainer.y + dockContainer.height - 4, -1 do
			buffer.drawText(xPos, y, color, "◢", MineOSCore.properties.transparencyEnabled and currentDockTransparency)
			buffer.drawRectangle(xPos + 1, y, currentDockWidth, 1, color, 0xFFFFFF, " ", MineOSCore.properties.transparencyEnabled and currentDockTransparency)
			buffer.drawText(xPos + currentDockWidth + 1, y, color, "◣", MineOSCore.properties.transparencyEnabled and currentDockTransparency)

			currentDockTransparency, currentDockWidth, xPos = currentDockTransparency + 0.08, currentDockWidth - 2, xPos + 1
			if currentDockTransparency > 1 then
				currentDockTransparency = 1
			end
		end

		overrideDockContainerDraw(dockContainer)
	end

	MineOSInterface.mainContainer.windowsContainer = MineOSInterface.mainContainer:addChild(GUI.container(1, 2, 1, 1))

	MineOSInterface.mainContainer.menu = MineOSInterface.mainContainer:addChild(GUI.menu(1, 1, MineOSInterface.mainContainer.width, MineOSCore.properties.menuColor, 0x696969, 0x3366CC, 0xFFFFFF))
	
	local MineOSContextMenu = MineOSInterface.mainContainer.menu:addContextMenu("MineOS", 0x000000)
	MineOSContextMenu:addItem(MineOSCore.localization.aboutSystem).onTouch = function()
		local container = MineOSInterface.addBackgroundContainer(MineOSInterface.mainContainer, MineOSCore.localization.aboutSystem)
		container.layout:removeChildren()
		
		local lines = {
			"MineOS",
			"Copyright © 2014-" .. os.date("%Y", MineOSCore.time),
			" ",
			"Developers:",
			" ",
			"Igor Timofeev, vk.com/id7799889",
			"Gleb Trifonov, vk.com/id88323331",
			"Yakov Verevkin, vk.com/id60991376",
			"Alexey Smirnov, vk.com/id23897419",
			"Timofey Shestakov, vk.com/id113499693",
			" ",
			"UX-advisers:",
			" ",
			"Nikita Yarichev, vk.com/id65873873",
			"Vyacheslav Sazonov, vk.com/id21321257",
			"Michail Prosin, vk.com/id75667079",
			"Dmitrii Tiunov, vk.com/id151541414",
			"Egor Paliev, vk.com/id83795932",
			"Maxim Pakin, vk.com/id100687922",
			"Andrey Kakoito, vk.com/id201043162",
			"Maxim Omelaenko, vk.com/id54662296",
			"Konstantin Mayakovskiy, vk.com/id10069748",
			"Ruslan Isaev, vk.com/id181265169",
			"Eugene8388608, github.com/Eugene8388608",
			" ",
			"Translators:",
			" ",
			"06Games, github.com/06Games",
			"Xenia Mazneva, vk.com/id5564402",
			"Yana Dmitrieva, vk.com/id155326634",
		}

		local textBox = container.layout:addChild(GUI.textBox(1, 1, container.layout.width, #lines, nil, 0xB4B4B4, lines, 1, 0, 0))
		textBox:setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
		textBox.eventHandler = container.panel.eventHandler

		MineOSInterface.mainContainer:drawOnScreen()
	end

	MineOSContextMenu:addItem(MineOSCore.localization.updates).onTouch = function()
		MineOSInterface.safeLaunch(MineOSPaths.applications .. "App Market.app/Main.lua", "updates")
	end

	MineOSContextMenu:addSeparator()

	MineOSContextMenu:addItem(MineOSCore.localization.logout, MineOSCore.properties.protectionMethod == "withoutProtection").onTouch = function()
		login()
	end

	MineOSContextMenu:addItem(MineOSCore.localization.reboot).onTouch = function()
		MineOSNetwork.broadcastComputerState(false)
		require("computer").shutdown(true)
	end

	MineOSContextMenu:addItem(MineOSCore.localization.shutdown).onTouch = function()
		MineOSNetwork.broadcastComputerState(false)
		require("computer").shutdown()
	end

	MineOSContextMenu:addSeparator()

	MineOSContextMenu:addItem(MineOSCore.localization.returnToShell).onTouch = function()
		MineOSNetwork.broadcastComputerState(false)
		MineOSInterface.mainContainer:stopEventHandling()
		MineOSInterface.clearTerminal()
		os.exit()
	end
		
	MineOSInterface.mainContainer.menuLayout = MineOSInterface.mainContainer:addChild(GUI.layout(1, 1, 1, 1, 1, 1))
	MineOSInterface.mainContainer.menuLayout:setDirection(1, 1, GUI.DIRECTION_HORIZONTAL)
	MineOSInterface.mainContainer.menuLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_RIGHT, GUI.ALIGNMENT_VERTICAL_TOP)
	MineOSInterface.mainContainer.menuLayout:setMargin(1, 1, 1, 0)
	MineOSInterface.mainContainer.menuLayout:setSpacing(1, 1, 2)

	local dateWidget, dateWidgetText = MineOSInterface.addMenuWidget(MineOSInterface.menuWidget(1))
	dateWidget.drawContent = function()
		buffer.drawText(dateWidget.x, 1, dateWidget.textColor, dateWidgetText)
	end

	local batteryWidget, batteryWidgetPercent, batteryWidgetText = MineOSInterface.addMenuWidget(MineOSInterface.menuWidget(1))
	batteryWidget.drawContent = function()
		buffer.drawText(batteryWidget.x, 1, batteryWidget.textColor, batteryWidgetText)

		local pixelPercent = math.round(batteryWidgetPercent * 4)
		if pixelPercent == 0 then
			pixelPercent = 1
		end
		
		local index = buffer.getIndex(batteryWidget.x + #batteryWidgetText, 1)
		for i = 1, 4 do
			buffer.rawSet(index, buffer.rawGet(index), i <= pixelPercent and getPercentageColor(batteryWidgetPercent) or 0xD2D2D2, i < 4 and "⠶" or "╸")
			index = index + 1
		end
	end

	local RAMWidget, RAMPercent = MineOSInterface.addMenuWidget(MineOSInterface.menuWidget(16))
	RAMWidget.drawContent = function()
		local text = "RAM: " .. math.ceil(RAMPercent * 100) .. "% "
		local barWidth = RAMWidget.width - #text
		local activeWidth = math.ceil(RAMPercent * barWidth)

		buffer.drawText(RAMWidget.x, 1, RAMWidget.textColor, text)
		
		local index = buffer.getIndex(RAMWidget.x + #text, 1)
		for i = 1, barWidth do
			buffer.rawSet(index, buffer.rawGet(index), i <= activeWidth and getPercentageColor(1 - RAMPercent) or 0xD2D2D2, "━")
			index = index + 1
		end
	end

	MineOSCore.updateTime = function()
		MineOSCore.time = realTimestamp + computer.uptime() - bootUptime + timezoneCorrection

		dateWidgetText = os.date(MineOSCore.properties.dateFormat, MineOSCore.properties.timeUseRealTimestamp and MineOSCore.time or nil)
		dateWidget.width = unicode.len(dateWidgetText)

		batteryWidgetPercent = computer.energy() / computer.maxEnergy()
		if batteryWidgetPercent == math.huge then
			batteryWidgetPercent = 1
		end
		batteryWidgetText = math.ceil(batteryWidgetPercent * 100) .. "% "
		batteryWidget.width = #batteryWidgetText + 4

		local totalMemory = computer.totalMemory()
		RAMPercent = (totalMemory - computer.freeMemory()) / totalMemory
	end

	MineOSCore.updateTimezone = function()
		timezoneCorrection = MineOSCore.properties.timezone * 3600
		MineOSCore.updateTime()
	end

	MineOSInterface.updateFileListAndDraw = function(...)
		MineOSInterface.mainContainer.iconField:updateFileList()
		MineOSInterface.mainContainer:drawOnScreen(...)
	end

	local lastWindowHandled
	MineOSInterface.mainContainer.eventHandler = function(mainContainer, object, e1, e2, e3, e4)
		if e1 == "key_down" then
			local windowsCount = #MineOSInterface.mainContainer.windowsContainer.children
			-- Ctrl or CMD
			if windowsCount > 0 and not lastWindowHandled and (keyboard.isKeyDown(29) or keyboard.isKeyDown(219)) then
				-- W
				if e4 == 17 then
					MineOSInterface.mainContainer.windowsContainer.children[windowsCount]:close()
					lastWindowHandled = true

					mainContainer:drawOnScreen()
				-- H
				elseif e4 == 35 then
					local lastUnhiddenWindowIndex = 1
					for i = 1, #MineOSInterface.mainContainer.windowsContainer.children do
						if not MineOSInterface.mainContainer.windowsContainer.children[i].hidden then
							lastUnhiddenWindowIndex = i
						end
					end
					MineOSInterface.mainContainer.windowsContainer.children[lastUnhiddenWindowIndex]:minimize()
					lastWindowHandled = true

					mainContainer:drawOnScreen()
				end
			end
		elseif lastWindowHandled and e1 == "key_up" and (e4 == 17 or e4 == 35) then
			lastWindowHandled = false
		elseif e1 == "MineOSCore" then
			if e2 == "updateFileList" then
				MineOSInterface.updateFileListAndDraw()
			elseif e2 == "updateFileListAndBufferTrueRedraw" then
				MineOSInterface.updateFileListAndDraw(true)
			elseif e2 == "updateWallpaper" then
				MineOSInterface.changeWallpaper()
				MineOSInterface.mainContainer:drawOnScreen()
			end
		elseif e1 == "MineOSNetwork" then
			if e2 == "accessDenied" then
				GUI.alert(MineOSCore.localization.networkAccessDenied)
			elseif e2 == "timeout" then
				GUI.alert(MineOSCore.localization.networkTimeout)
			end
		end

		if computer.uptime() - dateUptime >= 1 then
			MineOSCore.updateTime()
			MineOSInterface.mainContainer:drawOnScreen()
			dateUptime = computer.uptime()
		end

		if MineOSCore.properties.screensaverEnabled then
			if e1 then
				screensaverUptime = computer.uptime()
			end

			if dateUptime - screensaverUptime >= MineOSCore.properties.screensaverDelay then
				if fs.exists(MineOSCore.properties.screensaver) then
					MineOSInterface.safeLaunch(MineOSCore.properties.screensaver)
					MineOSInterface.mainContainer:drawOnScreen(true)
				end

				screensaverUptime = computer.uptime()
			end
		end
	end

	MineOSInterface.menuInitialChildren = MineOSInterface.mainContainer.menu.children
end

local function updateCurrentTimestamp()
	local name = MineOSPaths.system .. "/Timestamp.tmp"
	local file = io.open(name, "w")
	file:close()
	realTimestamp = math.floor(fs.lastModified(name) / 1000)
	fs.remove(name)
end

local function createOSWindow()
	MineOSInterface.mainContainer = GUI.fullScreenContainer()

	MineOSInterface.createWidgets()
	MineOSInterface.changeResolution()
	MineOSInterface.changeWallpaper()
	MineOSCore.updateTimezone()
end

local function runTasks(mode)
	for i = 1, #MineOSCore.properties.tasks do
		local task = MineOSCore.properties.tasks[i]
		if task.mode == mode and task.enabled then
			MineOSInterface.safeLaunch(task.path)
		end
	end
end

---------------------------------------- Сама ОС ----------------------------------------

MineOSCore.localization = MineOSCore.getLocalization(MineOSPaths.localizationFiles)

runTasks(2)

MineOSInterface.applyTransparency()
updateCurrentTimestamp()
createOSWindow()
-- login()
MineOSInterface.mainContainer:drawOnScreen()
MineOSNetwork.update()

runTasks(1)

while true do
	local success, path, line, traceback = MineOSCore.call(
		MineOSInterface.mainContainer.startEventHandling,
		MineOSInterface.mainContainer,
		0
	)

	if success then
		break
	else
		createOSWindow()
		MineOSInterface.mainContainer:drawOnScreen()
		MineOSInterface.showErrorWindow(path, line, traceback)
		MineOSInterface.mainContainer:drawOnScreen()
	end
end
