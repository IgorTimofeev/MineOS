
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

copyright = nil

---------------------------------------------- Либсы-хуибсы ------------------------------------------------------------------------

-- package.loaded.MineOSInterface = nil
-- package.loaded.MineOSCore = nil

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

---------------------------------------------- Всякая константная залупа ------------------------------------------------------------------------

local dockTransparency = 0.4

local computerUptimeOnBoot = computer.uptime()
local computerDateUptime = computerUptimeOnBoot
local realTimestamp
local timezoneCorrection
local screensaversPath = MineOSPaths.system .. "Screensavers/"
local screensaverUptime = computerUptimeOnBoot

---------------------------------------------- Система защиты пекарни ------------------------------------------------------------------------

local function biometry(creatingNew)
	if not creatingNew then
		event.interruptingEnabled = false
	end

	local container = MineOSInterface.addUniversalContainer(MineOSInterface.mainContainer)
	container.layout:setCellFitting(2, 1, false, false)

	local fingerImage = container.layout:addChild(GUI.image(1, 1, image.fromString([[180E0000FF 0000FF 0000FF 0000FF 0000FF 00FFFF▄00FFFF▄00FFFF▄00FFFF▄FFFFFF▀FFFFFF▀FFFFFF▀FFFFFF▀FFFFFF▀FFFFFF▀00FFFF▄00FFFF▄00FFFF▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 00FFFF▄FFFF00▄FFFFFF▀0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF FFFFFF▀FFFFFF▀FFFF00▄00FFFF▄0000FF 0000FF 0000FF 0000FF 0000FF FFFF00▄FFFFFF▀0000FF 0000FF 0000FF 00FFFF▄00FFFF▄FFFF00▄FFFFFF▀FFFFFF▀FFFFFF▀FFFFFF▀FFFFFF▀FFFFFF▀FFFF00▄00FFFF▄0000FF 0000FF FFFFFF▀FFFF00▄00FFFF▄0000FF 0000FF FFFF00▄FFFFFF▀0000FF 0000FF 00FFFF▄FFFF00▄FFFFFF▀0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF FFFF00▄00FFFF▄0000FF 0000FF FFFF00▄0000FF 00FFFF▄FFFF00▄0000FF 0000FF 00FFFF▄FFFF00▄0000FF 0000FF 0000FF 00FFFF▄00FFFF▄FFFFFF▀FFFFFF▀FFFFFF▀FFFFFF▀FFFFFF▀FFFFFF▀00FFFF▄0000FF FFFF00▄00FFFF▄0000FF FFFFFF▀FFFF00▄FFFF00▄0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF 0000FF 00FFFF▄00FFFF▄00FFFF▄0000FF 0000FF FFFF00▄0000FF 0000FF FFFF00▄0000FF 0000FF FFFF00▄FFFF00▄0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF 00FFFF▄FFFFFF▀0000FF 0000FF 0000FF 0000FF 00FFFF▄FFFF00▄0000FF 0000FF FFFF00▄0000FF 0000FF FFFF00▄0000FF 0000FF FFFF00▄FFFF00▄0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF FFFF00▄0000FF 0000FF 0000FF 0000FF 00FFFF▄FFFF00▄0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF FFFF00▄0000FF 00FFFF▄FFFF00▄FFFF00▄00FFFF▄0000FF 0000FF FFFF00▄00FFFF▄0000FF FFFFFF▀FFFF00▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF FFFF00▄FFFFFF▀0000FF FFFF00▄0000FF 0000FF FFFF00▄0000FF 0000FF 0000FF FFFF00▄00FFFF▄0000FF FFFFFF▀FFFF00▄0000FF 0000FF 0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF 00FFFF▄FFFF00▄0000FF 00FFFF▄FFFFFF▀0000FF 0000FF FFFF00▄00FFFF▄0000FF 0000FF 0000FF FFFF00▄00FFFF▄0000FF FFFF00▄00FFFF▄0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF 00FFFF▄FFFFFF▀0000FF 0000FF FFFF00▄0000FF 0000FF 0000FF 0000FF FFFF00▄00FFFF▄0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF FFFF00▄FFFFFF▀0000FF 0000FF FFFF00▄FFFFFF▀0000FF 0000FF 0000FF 0000FF 0000FF FFFF00▄0000FF 0000FF 0000FF FFFFFF▀FFFF00▄00FFFF▄0000FF 0000FF 0000FF 0000FF 00FFFF▄FFFFFF▀0000FF 0000FF 0000FF 00FFFF▄FFFF00▄0000FF 0000FF 0000FF 0000FF 0000FF 0000FF 0000FF FFFF00▄00FFFF▄0000FF 0000FF 0000FF FFFFFF▀0000FF 0000FF 0000FF 0000FF FFFFFF▀0000FF 0000FF 00FFFF▄FFFF00▄FFFFFF▀0000FF 0000FF 0000FF 0000FF ]])))
	local text = creatingNew and MineOSCore.localization.putFingerToRegister or MineOSCore.localization.putFingerToVerify
	local label = container.layout:addChild(GUI.label(1, 1, container.width, 1, 0xE1E1E1, text):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top))

	local scanLine = container:addChild(GUI.label(1, 1, container.width, 1, 0xFFFFFF, string.rep("─", image.getWidth(fingerImage.image) + 6)):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top))
	local fingerImageHeight = image.getHeight(fingerImage.image) + 1
	local delay = 0.5
	scanLine.hidden = true

	fingerImage.eventHandler = function(mainContainer, object, eventData)
		if eventData[1] == "touch" then
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

							event.interruptingEnabled = true
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
	event.interruptingEnabled = false

	local container = MineOSInterface.addUniversalContainer(MineOSInterface.mainContainer, MineOSCore.localization.inputPassword)
	local inputField = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0x696969, 0xE1E1E1, 0x2D2D2D, nil, nil, true, "*"))
	local label = container.layout:addChild(GUI.label(1, 1, 36, 1, 0xFF4940, MineOSCore.localization.incorrectPassword)):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	label.hidden = true

	container.panel.eventHandler = nil

	inputField.onInputFinished = function()
		local hash = require("SHA2").hash(inputField.text or "")
		if hash == MineOSCore.properties.passwordHash then
			container:delete()
			event.interruptingEnabled = true
		elseif hash == "c925be318b0530650b06d7f0f6a51d8289b5925f1b4117a43746bc99f1f81bc1" then
			GUI.error(MineOSCore.localization.mineOSCreatorUsedMasterPassword)
			container:delete()
			event.interruptingEnabled = true
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
	local inputField1 = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0x696969, 0xE1E1E1, 0x2D2D2D, nil, MineOSCore.localization.inputPassword, true, "*"))
	local inputField2 = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0x696969, 0xE1E1E1, 0x2D2D2D, nil, MineOSCore.localization.confirmInputPassword, true, "*"))
	local label = container.layout:addChild(GUI.label(1, 1, 36, 1, 0xFF4940, MineOSCore.localization.passwordsAreDifferent)):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	label.hidden = true

	local function check()
		if inputField1.text ~= "" and inputField1.text == inputField2.text then
			container:delete()

			MineOSCore.properties.protectionMethod = "password"
			MineOSCore.properties.passwordHash = require("SHA2").hash(inputField1.text or "")
			MineOSCore.saveProperties()
		else
			label.hidden = false
		end

		MineOSInterface.OSDraw()
	end

	inputField1.onInputFinished = check
	inputField2.onInputFinished = check

	container.panel.eventHandler = function(mainContainer, object, eventData)
		if eventData[1] == "touch" then
			check()
		end
	end

	MineOSInterface.OSDraw()
end

local function setWithoutProtection()
	MineOSCore.properties.passwordHash = nil
	MineOSCore.properties.protectionMethod = "withoutProtection"
	MineOSCore.saveProperties()
end

local function setProtectionMethod()
	local container = MineOSInterface.addUniversalContainer(MineOSInterface.mainContainer, MineOSCore.localization.protectYourComputer)

	local comboBox = container.layout:addChild(GUI.comboBox(1, 1, 36, 3, 0xE1E1E1, 0x2D2D2D, 0x4B4B4B, 0x969696))
	comboBox:addItem(MineOSCore.localization.biometricProtection).onTouch = function()
		container:delete()
		biometry(true)
	end
	comboBox:addItem(MineOSCore.localization.passwordProtection).onTouch = function()
		container:delete()
		setPassword()
	end
	comboBox:addItem(MineOSCore.localization.withoutProtection).onTouch = function()
		container:delete()
		setWithoutProtection()
	end

	container.panel.eventHandler = function(mainContainer, object, eventData)
		if eventData[1] == "touch" then
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

		local r, g, b
		for i = 3, #MineOSInterface.mainContainer.background.wallpaper, 4 do
			r, g, b = color.IntegerToRGB(MineOSInterface.mainContainer.background.wallpaper[i])
			MineOSInterface.mainContainer.background.wallpaper[i] = color.RGBToInteger(math.floor(r * MineOSCore.properties.wallpaperBrightness), math.floor(g * MineOSCore.properties.wallpaperBrightness), math.floor(b * MineOSCore.properties.wallpaperBrightness))
			
			r, g, b = color.IntegerToRGB(MineOSInterface.mainContainer.background.wallpaper[i + 1])
			MineOSInterface.mainContainer.background.wallpaper[i + 1] = color.RGBToInteger(math.floor(r * MineOSCore.properties.wallpaperBrightness), math.floor(g * MineOSCore.properties.wallpaperBrightness), math.floor(b * MineOSCore.properties.wallpaperBrightness))
		end
	end
end

---------------------------------------------- Всякая параша для ОС-контейнера ------------------------------------------------------------------------

local function changeResolution()
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
	MineOSInterface.OSDraw()
end

local function createOSWindow()
	MineOSInterface.mainContainer = GUI.fullScreenContainer()
	-- MineOSInterface.mainContainer.passScreenEvents = true
	
	-- MineOSInterface.mainContainer.draw = function()
	-- 	GUI.drawContainerContent(MineOSInterface.mainContainer)
		
	-- 	local limit = 70
	-- 	local lines = string.wrap(debug.traceback(), limit)
	-- 	buffer.square(1, 1, limit, #lines, 0x0, 0xFFFFFF, " ", 0.2)
	-- 	for i = 1, #lines do
	-- 		buffer.text(1, i, 0xFFFFFF, lines[i])
	-- 	end
	-- end
	
	MineOSInterface.mainContainer.background = MineOSInterface.mainContainer:addChild(GUI.object(1, 1, 1, 1))
	MineOSInterface.mainContainer.background.wallpaperPosition = {x = 1, y = 1}
	MineOSInterface.mainContainer.background.draw = function(object)
		buffer.square(object.x, object.y, object.width, object.height, MineOSCore.properties.backgroundColor, 0x0, " ")
		if object.wallpaper then
			buffer.image(object.wallpaperPosition.x, object.wallpaperPosition.y, object.wallpaper)
		end
	end

	MineOSInterface.mainContainer.iconField = MineOSInterface.mainContainer:addChild(
		MineOSInterface.iconField(
			1, 2, 1, 1, 3, 2,
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
		MineOSInterface.safeLaunch(MineOSPaths.explorer, "-o", fs.path(icon.shortcutPath or icon.path))
	end
	MineOSInterface.mainContainer.iconField.launchers.showPackageContent = function(icon)
		MineOSInterface.safeLaunch(MineOSPaths.explorer, "-o", icon.path)
	end

	-- Dock
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
		local icon = MineOSInterface.mainContainer.dockContainer:addChild(MineOSInterface.icon(1, 2, path, 0x2D2D2D, 0xFFFFFF))
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
				MineOSInterface.iconDoubleClick(icon, eventData)
			end
		end

		icon.onRightClick = function(icon, eventData)
			local indexOf = icon:indexOf()

			local menu = MineOSInterface.contextMenu(eventData[3], eventData[4])
			if icon.windows then
				menu:addItem(MineOSCore.localization.newWindow).onTouch = function()
					MineOSInterface.iconDoubleClick(icon, eventData)
				end
				menu:addItem(MineOSCore.localization.closeAllWindows).onTouch = function()
					for window in pairs(icon.windows) do
						window:close()
					end
					MineOSInterface.OSDraw()
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

			container.layout:addChild(GUI.button(1, 1, 30, 1, 0xE1E1E1, 0x2D2D2D, 0xA5A5A5, 0x2D2D2D, "OK")).onTouch = function()
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

	-- Draw dock drawDock dockDraw cyka заебался искать, блядь
	MineOSInterface.mainContainer.dockContainer.draw = function(dockContainer)
		local color, currentDockTransparency, currentDockWidth, xPos = MineOSCore.properties.dockColor, dockTransparency, dockContainer.width - 2, dockContainer.x

		for y = dockContainer.y + dockContainer.height - 1, dockContainer.y + dockContainer.height - 4, -1 do
			buffer.text(xPos, y, color, "◢", MineOSCore.properties.transparencyEnabled and currentDockTransparency)
			buffer.square(xPos + 1, y, currentDockWidth, 1, color, 0xFFFFFF, " ", MineOSCore.properties.transparencyEnabled and currentDockTransparency)
			buffer.text(xPos + currentDockWidth + 1, y, color, "◣", MineOSCore.properties.transparencyEnabled and currentDockTransparency)

			currentDockTransparency, currentDockWidth, xPos = currentDockTransparency + 0.08, currentDockWidth - 2, xPos + 1
			if currentDockTransparency > 1 then
				currentDockTransparency = 1
			end
		end

		GUI.drawContainerContent(dockContainer)
	end

	-- Custom windows support
	MineOSInterface.mainContainer.windowsContainer = MineOSInterface.mainContainer:addChild(GUI.container(1, 2, 1, 1))

	-- Main menu
	MineOSInterface.mainContainer.menu = MineOSInterface.mainContainer:addChild(GUI.menu(1, 1, MineOSInterface.mainContainer.width, MineOSCore.properties.menuColor, 0x555555, 0x3366CC, 0xFFFFFF))
	local item1 = MineOSInterface.mainContainer.menu:addItem("MineOS", 0x000000)
	item1.onTouch = function()
		local menu = MineOSInterface.contextMenu(item1.x, item1.y + 1)

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
		local container = MineOSInterface.addUniversalContainer(MineOSInterface.mainContainer, MineOSCore.localization.network)
		local insertModemTextBox = container.layout:addChild(GUI.textBox(1, 1, 36, 1, nil, 0x555555, {MineOSCore.localization.networkModemNotAvailable}, 1, 0, 0, true, true))
		
		local stateSwitchAndLabel = container.layout:addChild(GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0x2D2D2D, 0xE1E1E1, 0x878787, MineOSCore.localization.networkState .. ":", MineOSCore.properties.network.enabled))
		local signalStrengthSlider = container.layout:addChild(GUI.slider(1, 1, 36, 0x66DB80, 0x2D2D2D, 0xE1E1E1, 0x878787, 0, 512, MineOSCore.properties.network.signalStrength, false, MineOSCore.localization.networkSearchRadius ..": ", ""))
		signalStrengthSlider.roundValues = true
		signalStrengthSlider.height = 2

		container.layout:addChild(GUI.object(1, 1, 1, 1))

		container.layout:addChild(GUI.label(1, 1, container.width, 1, 0xE1E1E1, MineOSCore.localization.networkName):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top))
		local networkNameInput = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0x696969, 0xE1E1E1, 0x2D2D2D, MineOSCore.properties.network.name or ""))

		container.layout:addChild(GUI.label(1, 1, container.width, 1, 0xE1E1E1, MineOSCore.localization.networkComputers):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top))
		local comboBox = container.layout:addChild(GUI.comboBox(1, 1, 36, 3, 0xE1E1E1, 0x2D2D2D, 0x4B4B4B, 0x969696))
		local allowReadAndWriteSwitchAndLabel = container.layout:addChild(GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0x2D2D2D, 0xE1E1E1, 0x878787, MineOSCore.localization.networkAllowReadAndWrite .. ":", false))
		local noPCDetectedLabel = container.layout:addChild(GUI.label(1, 1, container.width, 1, 0x878787, MineOSCore.localization.networkComputersNotFound):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top))

		local function check()
			local modemAvailable = component.isAvailable("modem")
			for i = 3, #container.layout.children do
				container.layout.children[i].hidden = not modemAvailable
			end
			insertModemTextBox.hidden = modemAvailable

			if modemAvailable then
				local stateSwitchAndLabelIndexOf = stateSwitchAndLabel:indexOf()
				for i = 3, #container.layout.children do
					if i ~= stateSwitchAndLabelIndexOf then
						container.layout.children[i].hidden = not stateSwitchAndLabel.switch.state
					end
				end

				if stateSwitchAndLabel.switch.state then
					signalStrengthSlider.hidden = not MineOSNetwork.modemProxy.isWireless()

					comboBox:clear()
					for proxy, path in fs.mounts() do
						if proxy.network then
							local item = comboBox:addItem(MineOSNetwork.getProxyName(proxy))
							item.proxyAddress = proxy.address
							item.onTouch = function()
								allowReadAndWriteSwitchAndLabel.switch:setState(MineOSCore.properties.network.users[item.proxyAddress].allowReadAndWrite)
							end
						end
					end
					
					noPCDetectedLabel.hidden = comboBox:count() > 0
					allowReadAndWriteSwitchAndLabel.hidden = not noPCDetectedLabel.hidden
					comboBox.hidden = not noPCDetectedLabel.hidden

					if noPCDetectedLabel.hidden then
						comboBox:getItem(comboBox.selectedItem).onTouch()
					end
				end
			end

			MineOSInterface.OSDraw()
		end

		networkNameInput.onInputFinished = function()
			if #networkNameInput.text > 0 then
				MineOSCore.properties.network.name = networkNameInput.text
				MineOSCore.saveProperties()

				MineOSNetwork.broadcastComputerState(MineOSCore.properties.network.enabled)
			end
		end

		signalStrengthSlider.onValueChanged = function()
			MineOSCore.properties.network.signalStrength = math.floor(signalStrengthSlider.value)
			MineOSCore.saveProperties()
		end

		stateSwitchAndLabel.switch.onStateChanged = function()
			if stateSwitchAndLabel.switch.state then
				MineOSNetwork.enable()
			else
				MineOSNetwork.disable()
			end

			check()
		end

		allowReadAndWriteSwitchAndLabel.switch.onStateChanged = function()
			MineOSCore.properties.network.users[comboBox:getItem(comboBox.selectedItem).proxyAddress].allowReadAndWrite = allowReadAndWriteSwitchAndLabel.switch.state
			MineOSCore.saveProperties()
		end

		container.panel.eventHandler = function(mainContainer, object, eventData)
			if eventData[1] == "touch" then
				container:delete()
				MineOSInterface.OSDraw()
			elseif (eventData[1] == "component_added" or eventData[1] == "component_removed") and eventData[3] == "modem" then
				check()
			elseif eventData[1] == "MineOSNetwork" and eventData[2] == "updateProxyList" then
				check()
			end
		end

		check()
	end

	local item3 = MineOSInterface.mainContainer.menu:addItem(MineOSCore.localization.settings)
	item3.onTouch = function()
		local menu = MineOSInterface.contextMenu(item3.x, item3.y + 1)

		menu:addItem(MineOSCore.localization.screenResolution).onTouch = function()
			local container = MineOSInterface.addUniversalContainer(MineOSInterface.mainContainer, MineOSCore.localization.screenResolution)

			local widthTextBox = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0x696969, 0xE1E1E1, 0x2D2D2D, tostring(MineOSCore.properties.resolution and MineOSCore.properties.resolution[1] or 160), "Width", true))
			widthTextBox.validator = function(text)
				local number = tonumber(text)
				if number then return number >= 1 and number <= 160 end
			end

			local heightTextBox = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0x696969, 0xE1E1E1, 0x2D2D2D, tostring(MineOSCore.properties.resolution and MineOSCore.properties.resolution[2] or 50), "Height", true))
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

			local filesystemChooser = container.layout:addChild(GUI.filesystemChooser(1, 1, 36, 3, 0xE1E1E1, 0x2D2D2D, 0x4B4B4B, 0x969696, MineOSCore.properties.wallpaper, MineOSCore.localization.open, MineOSCore.localization.cancel, MineOSCore.localization.wallpaperPath, "/"))
			filesystemChooser:addExtensionFilter(".pic")
			filesystemChooser.onSubmit = function(path)
				MineOSCore.properties.wallpaper = path
				MineOSCore.saveProperties()
				changeWallpaper()

				MineOSInterface.OSDraw()
			end

			local comboBox = container.layout:addChild(GUI.comboBox(1, 1, 36, 3, 0xE1E1E1, 0x2D2D2D, 0x4B4B4B, 0x969696))
			comboBox.selectedItem = MineOSCore.properties.wallpaperMode or 1
			comboBox:addItem(MineOSCore.localization.wallpaperModeStretch)
			comboBox:addItem(MineOSCore.localization.wallpaperModeCenter)

			local switch = container.layout:addChild(GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0x2D2D2D, 0xE1E1E1, 0xE1E1E1, MineOSCore.localization.wallpaperEnabled .. ":", MineOSCore.properties.wallpaperEnabled)).switch
			switch.onStateChanged = function()
				MineOSCore.properties.wallpaperEnabled = switch.state
				MineOSCore.saveProperties()
				changeWallpaper()

				MineOSInterface.OSDraw()
			end

			container.layout:addChild(GUI.textBox(1, 1, 36, 1, nil, 0x555555, {MineOSCore.localization.wallpaperSwitchInfo}, 1, 0, 0, true, true))

			local slider = container.layout:addChild(GUI.slider(1, 1, 36, 0x66DB80, 0x2D2D2D, 0xE1E1E1, 0x878787, 0, 100, MineOSCore.properties.wallpaperBrightness * 100, false, MineOSCore.localization.wallpaperBrightness .. ": ", "%"))
			slider.roundValues = true
			slider.onValueChanged = function()
				MineOSCore.properties.wallpaperBrightness = slider.value / 100
				MineOSCore.saveProperties()
				changeWallpaper()

				MineOSInterface.OSDraw()
			end
			container.layout:addChild(GUI.object(1, 1, 1, 1))
			
			comboBox.onItemSelected = function()
				MineOSCore.properties.wallpaperMode = comboBox.selectedItem
				MineOSCore.saveProperties()
				changeWallpaper()

				MineOSInterface.OSDraw()
			end
		end
		menu:addItem(MineOSCore.localization.screensaver).onTouch = function()
			local container = MineOSInterface.addUniversalContainer(MineOSInterface.mainContainer, MineOSCore.localization.screensaver)

			local comboBox = container.layout:addChild(GUI.comboBox(1, 1, 36, 3, 0xE1E1E1, 0x2D2D2D, 0x4B4B4B, 0x969696))
			local fileList = fs.sortedList(screensaversPath, "name", false)
			for i = 1, #fileList do
				comboBox:addItem(fs.hideExtension(fileList[i]))
				if MineOSCore.properties.screensaver == fileList[i] then
					comboBox.selectedItem = i
				end
			end
			local switch = container.layout:addChild(GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0x2D2D2D, 0xE1E1E1, 0xE1E1E1, MineOSCore.localization.screensaverEnabled .. ":", MineOSCore.properties.screensaverEnabled)).switch
			local slider = container.layout:addChild(GUI.slider(1, 1, 36, 0x66DB80, 0x2D2D2D, 0xE1E1E1, 0x878787, 1, 80, MineOSCore.properties.screensaverDelay, false, MineOSCore.localization.screensaverDelay .. ": ", ""))

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

			local backgroundColorSelector = container.layout:addChild(GUI.colorSelector(1, 1, 36, 3, MineOSCore.properties.backgroundColor, MineOSCore.localization.backgroundColor))
			local menuColorSelector = container.layout:addChild(GUI.colorSelector(1, 1, 36, 3, MineOSCore.properties.menuColor, MineOSCore.localization.menuColor))
			local dockColorSelector = container.layout:addChild(GUI.colorSelector(1, 1, 36, 3, MineOSCore.properties.dockColor, MineOSCore.localization.dockColor))

			local switch = container.layout:addChild(GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0x2D2D2D, 0xE1E1E1, 0xE1E1E1, MineOSCore.localization.transparencyEnabled .. ":", MineOSCore.properties.transparencyEnabled)).switch
			switch.onStateChanged = function()
				MineOSCore.properties.transparencyEnabled = switch.state
				MineOSCore.saveProperties()
				MineOSInterface.mainContainer.menu.colors.transparency = MineOSCore.properties.transparencyEnabled and menuTransparency
				container.panel.colors.background = switch.state and 0x0 or (MineOSCore.properties.backgroundColor)
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

		menu:addItem(MineOSCore.localization.iconProperties).onTouch = function()
			local container = MineOSInterface.addUniversalContainer(MineOSInterface.mainContainer, MineOSCore.localization.iconProperties)

			local showExtensionSwitch = container.layout:addChild(GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0x2D2D2D, 0xE1E1E1, 0x878787, MineOSCore.localization.showExtension .. ":", MineOSCore.properties.showExtension)).switch
			local showHiddenFilesSwitch = container.layout:addChild(GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0x2D2D2D, 0xE1E1E1, 0x878787, MineOSCore.localization.showHiddenFiles .. ":", MineOSCore.properties.showHiddenFiles)).switch
			local showApplicationIconsSwitch = container.layout:addChild(GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0x2D2D2D, 0xE1E1E1, 0x878787, MineOSCore.localization.showApplicationIcons .. ":", MineOSCore.properties.showApplicationIcons)).switch

			container.layout:addChild(GUI.label(1, 1, container.width, 1, 0xE1E1E1, MineOSCore.localization.sizeOfIcons):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top))

			local iconWidthSlider = container.layout:addChild(GUI.slider(1, 1, 36, 0x66DB80, 0x2D2D2D, 0xE1E1E1, 0x878787, 8, 16, MineOSCore.properties.iconWidth, false, MineOSCore.localization.byHorizontal .. ": ", ""))
			local iconHeightSlider = container.layout:addChild(GUI.slider(1, 1, 36, 0x66DB80, 0x2D2D2D, 0xE1E1E1, 0x878787, 6, 16, MineOSCore.properties.iconHeight, false, MineOSCore.localization.byVertical .. ": ", ""))

			container.layout:addChild(GUI.object(1, 1, 1, 0))
			container.layout:addChild(GUI.label(1, 1, container.width, 1, 0xE1E1E1, MineOSCore.localization.spaceBetweenIcons):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top))

			local iconHorizontalSpaceBetweenSlider = container.layout:addChild(GUI.slider(1, 1, 36, 0x66DB80, 0x2D2D2D, 0xE1E1E1, 0x878787, 0, 5, MineOSCore.properties.iconHorizontalSpaceBetween, false, MineOSCore.localization.byHorizontal .. ": ", ""))
			local iconVerticalSpaceBetweenSlider = container.layout:addChild(GUI.slider(1, 1, 36, 0x66DB80, 0x2D2D2D, 0xE1E1E1, 0x878787, 0, 5, MineOSCore.properties.iconVerticalSpaceBetween, false, MineOSCore.localization.byVertical .. ": ", ""))
			
			iconHorizontalSpaceBetweenSlider.roundValues, iconVerticalSpaceBetweenSlider.roundValues = true, true
			iconWidthSlider.roundValues, iconHeightSlider.roundValues = true, true

			iconWidthSlider.onValueChanged = function()
				MineOSInterface.setIconProperties(math.floor(iconWidthSlider.value), math.floor(iconHeightSlider.value), MineOSCore.properties.iconHorizontalSpaceBetween, MineOSCore.properties.iconVerticalSpaceBetween)
			end
			iconHeightSlider.onValueChanged = iconWidthSlider.onValueChanged

			iconHorizontalSpaceBetweenSlider.onValueChanged = function()
				MineOSInterface.setIconProperties(MineOSCore.properties.iconWidth, MineOSCore.properties.iconHeight, math.floor(iconHorizontalSpaceBetweenSlider.value), math.floor(iconVerticalSpaceBetweenSlider.value))
			end
			iconVerticalSpaceBetweenSlider.onValueChanged = iconHorizontalSpaceBetweenSlider.onValueChanged

			showExtensionSwitch.onStateChanged = function()
				MineOSCore.properties.showExtension = showExtensionSwitch.state
				MineOSCore.properties.showHiddenFiles = showHiddenFilesSwitch.state
				MineOSCore.properties.showApplicationIcons = showApplicationIconsSwitch.state
				MineOSCore.saveProperties()

				computer.pushSignal("MineOSCore", "updateFileList")
			end
			showHiddenFilesSwitch.onStateChanged, showApplicationIconsSwitch.onStateChanged = showExtensionSwitch.onStateChanged, showExtensionSwitch.onStateChanged
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
		if eventData[1] == "key_down" then
			local windowsCount = #MineOSInterface.mainContainer.windowsContainer.children
			-- Ctrl or CMD
			if windowsCount > 0 and not eventData.lastWindowHandled and (keyboard.isKeyDown(29) or keyboard.isKeyDown(219)) then
				-- W
				if eventData[4] == 17 then
					eventData.lastWindowHandled = true
					MineOSInterface.mainContainer.windowsContainer.children[windowsCount]:close()

					mainContainer:draw()
					buffer.draw()
				-- H
				elseif eventData[4] == 35 then
					eventData.lastWindowHandled = true
					
					local lastUnhiddenWindowIndex = 1
					for i = 1, #MineOSInterface.mainContainer.windowsContainer.children do
						if not MineOSInterface.mainContainer.windowsContainer.children[i].hidden then
							lastUnhiddenWindowIndex = i
						end
					end
					MineOSInterface.mainContainer.windowsContainer.children[lastUnhiddenWindowIndex]:minimize()

					mainContainer:draw()
					buffer.draw()
				end
			end
		elseif eventData[1] == "MineOSCore" then
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

MineOSNetwork.update()

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
		changeResolution()
		changeWallpaper()
		MineOSCore.OSUpdateDate()
		MineOSInterface.mainContainer.updateFileListAndDraw()

		MineOSInterface.showErrorWindow(path, line, traceback)

		MineOSInterface.OSDraw()
	end
end
