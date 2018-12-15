
local computer = require("computer")
local component = require("component")
local unicode = require("unicode")
local filesystem = require("filesystem")
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

---------------------------------------- Constants ----------------------------------------

local dockTransparency = 0.4
local doubleTouchInterval = 0.3

local mainContainer
local bootUptime = computer.uptime()
local dateUptime = bootUptime
local screensaverUptime = bootUptime
local realTimestamp
local timezoneCorrection
local doubleTouchX
local doubleTouchY
local doubleTouchButton
local doubleTouchUptime
local doubleTouchScreenAddress

---------------------------------------- UI methods ----------------------------------------

function MineOSInterface.changeWallpaper()
	mainContainer.backgroundObject.wallpaper = nil

	if MineOSCore.properties.wallpaperEnabled and MineOSCore.properties.wallpaper then
		local result, reason = image.load(MineOSCore.properties.wallpaper)
		if result then
			mainContainer.backgroundObject.wallpaper, result = result, nil

			-- Fit to screen size mode
			if MineOSCore.properties.wallpaperMode == 1 then
				mainContainer.backgroundObject.wallpaper = image.transform(mainContainer.backgroundObject.wallpaper, mainContainer.width, mainContainer.height)
				mainContainer.backgroundObject.wallpaperPosition.x, mainContainer.backgroundObject.wallpaperPosition.y = 1, 1
			-- Centerized mode
			else
				mainContainer.backgroundObject.wallpaperPosition.x = math.floor(1 + mainContainer.width / 2 - image.getWidth(mainContainer.backgroundObject.wallpaper) / 2)
				mainContainer.backgroundObject.wallpaperPosition.y = math.floor(1 + mainContainer.height / 2 - image.getHeight(mainContainer.backgroundObject.wallpaper) / 2)
			end

			-- Brightness adjustment
			local backgrounds, foregrounds, r, g, b = mainContainer.backgroundObject.wallpaper[3], mainContainer.backgroundObject.wallpaper[4]
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

function MineOSInterface.changeResolution()
	buffer.setResolution(table.unpack(MineOSCore.properties.resolution or {buffer.getGPUProxy().maxResolution()}))

	mainContainer.width, mainContainer.height = buffer.getResolution()

	mainContainer.iconField.width = mainContainer.width
	mainContainer.iconField.height = mainContainer.height
	mainContainer.iconField:updateFileList()

	mainContainer.dockContainer.sort()
	mainContainer.dockContainer.localY = mainContainer.height - mainContainer.dockContainer.height + 1

	mainContainer.menu.width = mainContainer.width
	mainContainer.menuLayout.width = mainContainer.width
	mainContainer.backgroundObject.width, mainContainer.backgroundObject.height = mainContainer.width, mainContainer.height

	mainContainer.windowsContainer.width, mainContainer.windowsContainer.height = mainContainer.width, mainContainer.height - 1
end

local function moveDockIcon(index, direction)
	mainContainer.dockContainer.children[index], mainContainer.dockContainer.children[index + direction] = mainContainer.dockContainer.children[index + direction], mainContainer.dockContainer.children[index]
	mainContainer.dockContainer.sort()
	mainContainer.dockContainer.saveToOSSettings()
	mainContainer:drawOnScreen()
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

local function dockIconEventHandler(mainContainer, icon, e1, e2, e3, e4, e5, e6, ...)
	if e1 == "touch" then
		icon.selected = true
		mainContainer:drawOnScreen()

		if e5 == 1 then
			icon.onRightClick(icon, e1, e2, e3, e4, e5, e6, ...)
		else
			icon.onLeftClick(icon, e1, e2, e3, e4, e5, e6, ...)
		end
	end
end

function MineOSInterface.createWidgets()
	mainContainer:removeChildren()
	
	mainContainer.backgroundObject = mainContainer:addChild(GUI.object(1, 1, 1, 1))
	mainContainer.backgroundObject.wallpaperPosition = {x = 1, y = 1}
	mainContainer.backgroundObject.draw = function(object)
		buffer.drawRectangle(object.x, object.y, object.width, object.height, MineOSCore.properties.backgroundColor, 0, " ")
		if object.wallpaper then
			buffer.drawImage(object.wallpaperPosition.x, object.wallpaperPosition.y, object.wallpaper)
		end
	end

	mainContainer.iconField = mainContainer:addChild(
		MineOSInterface.iconField(
			1, 2, 1, 1, 3, 2,
			0xFFFFFF,
			0xD2D2D2,
			MineOSPaths.desktop
		)
	)
	
	mainContainer.iconField.iconConfigEnabled = true
	
	mainContainer.iconField.launchers.directory = function(icon)
		MineOSInterface.safeLaunch(MineOSPaths.explorer, "-o", icon.path)
	end
	
	mainContainer.iconField.launchers.showContainingFolder = function(icon)
		MineOSInterface.safeLaunch(MineOSPaths.explorer, "-o", filesystem.path(icon.shortcutPath or icon.path))
	end
	
	mainContainer.iconField.launchers.showPackageContent = function(icon)
		MineOSInterface.safeLaunch(MineOSPaths.explorer, "-o", icon.path)
	end

	mainContainer.dockContainer = mainContainer:addChild(GUI.container(1, 1, mainContainer.width, 7))

	mainContainer.dockContainer.saveToOSSettings = function()
		MineOSCore.properties.dockShortcuts = {}
		for i = 1, #mainContainer.dockContainer.children do
			if mainContainer.dockContainer.children[i].keepInDock then
				table.insert(MineOSCore.properties.dockShortcuts, mainContainer.dockContainer.children[i].path)
			end
		end
		MineOSCore.saveProperties()
	end

	mainContainer.dockContainer.sort = function()
		local x = 4
		for i = 1, #mainContainer.dockContainer.children do
			mainContainer.dockContainer.children[i].localX = x
			x = x + MineOSCore.properties.iconWidth + MineOSCore.properties.iconHorizontalSpaceBetween
		end

		mainContainer.dockContainer.width = #mainContainer.dockContainer.children * (MineOSCore.properties.iconWidth + MineOSCore.properties.iconHorizontalSpaceBetween) - MineOSCore.properties.iconHorizontalSpaceBetween + 6
		mainContainer.dockContainer.localX = math.floor(mainContainer.width / 2 - mainContainer.dockContainer.width / 2)
	end

	mainContainer.dockContainer.addIcon = function(path, window)
		local icon = mainContainer.dockContainer:addChild(MineOSInterface.icon(1, 2, path, 0x2D2D2D, 0xFFFFFF))
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
				mainContainer:drawOnScreen()
			else
				MineOSInterface.iconDoubleClick(icon, ...)
			end
		end

		icon.onRightClick = function(icon, e1, e2, e3, e4, ...)
			local indexOf = icon:indexOf()
			local menu = GUI.addContextMenu(mainContainer, e3, e4)
			
			menu.onMenuClosed = function()
				icon.selected = false
				mainContainer:drawOnScreen()
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
					mainContainer:drawOnScreen()
				end
			end
			
			menu:addItem(MineOSCore.localization.showContainingFolder).onTouch = function()
				MineOSInterface.safeLaunch(MineOSPaths.explorer, "-o", filesystem.path(icon.shortcutPath or icon.path))
			end
			
			menu:addSeparator()
			
			menu:addItem(MineOSCore.localization.moveRight, indexOf >= #mainContainer.dockContainer.children - 1).onTouch = function()
				moveDockIcon(indexOf, 1)
			end
			
			menu:addItem(MineOSCore.localization.moveLeft, indexOf <= 1).onTouch = function()
				moveDockIcon(indexOf, -1)
			end
			
			menu:addSeparator()
			
			if icon.keepInDock then
				if #mainContainer.dockContainer.children > 1 then
					menu:addItem(MineOSCore.localization.removeFromDock).onTouch = function()
						if icon.windows then
							icon.keepInDock = nil
						else
							icon:remove()
							mainContainer.dockContainer.sort()
						end
						mainContainer.dockContainer.saveToOSSettings()
						mainContainer:drawOnScreen()
					end
				end
			else
				if icon.windows then
					menu:addItem(MineOSCore.localization.keepInDock).onTouch = function()
						icon.keepInDock = true
						mainContainer.dockContainer.saveToOSSettings()
					end
				end
			end

			mainContainer:drawOnScreen()
		end

		mainContainer.dockContainer.sort()

		return icon
	end

	-- Trash
	local icon = mainContainer.dockContainer.addIcon(MineOSPaths.trash)
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
		local menu = GUI.addContextMenu(mainContainer, e3, e4)
		
		menu.onMenuClosed = function()
			icon.selected = false
			mainContainer:drawOnScreen()
		end
		
		menu:addItem(MineOSCore.localization.emptyTrash).onTouch = function()
			local container = MineOSInterface.addBackgroundContainer(mainContainer, MineOSCore.localization.areYouSure)

			container.layout:addChild(GUI.button(1, 1, 30, 1, 0xE1E1E1, 0x2D2D2D, 0xA5A5A5, 0x2D2D2D, "OK")).onTouch = function()
				for file in filesystem.list(MineOSPaths.trash) do
					filesystem.remove(MineOSPaths.trash .. file)
				end
				container:remove()
				computer.pushSignal("MineOSCore", "updateFileList")
			end

			container.panel.onTouch = function()
				container:remove()
				mainContainer:drawOnScreen()
			end

			mainContainer:drawOnScreen()
		end

		mainContainer:drawOnScreen()
	end

	for i = 1, #MineOSCore.properties.dockShortcuts do
		mainContainer.dockContainer.addIcon(MineOSCore.properties.dockShortcuts[i]).keepInDock = true
	end

	-- Draw dock drawDock dockDraw cyka заебался искать, блядь
	local overrideDockContainerDraw = mainContainer.dockContainer.draw
	mainContainer.dockContainer.draw = function(dockContainer)
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

	mainContainer.windowsContainer = mainContainer:addChild(GUI.container(1, 2, 1, 1))

	mainContainer.menu = mainContainer:addChild(GUI.menu(1, 1, mainContainer.width, MineOSCore.properties.menuColor, 0x696969, 0x3366CC, 0xFFFFFF))
	
	local MineOSContextMenu = mainContainer.menu:addContextMenu("MineOS", 0x000000)
	MineOSContextMenu:addItem(MineOSCore.localization.aboutSystem).onTouch = function()
		local container = MineOSInterface.addBackgroundContainer(mainContainer, MineOSCore.localization.aboutSystem)
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
			"Eugene8388608, vk.com/id287247631",
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

		mainContainer:drawOnScreen()
	end

	MineOSContextMenu:addItem(MineOSCore.localization.updates).onTouch = function()
		MineOSInterface.safeLaunch(MineOSPaths.applications .. "App Market.app/Main.lua", "updates")
	end

	MineOSContextMenu:addSeparator()

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
		mainContainer:stopEventHandling()
		MineOSInterface.clearTerminal()
		os.exit()
	end
		
	mainContainer.menuLayout = mainContainer:addChild(GUI.layout(1, 1, 1, 1, 1, 1))
	mainContainer.menuLayout:setDirection(1, 1, GUI.DIRECTION_HORIZONTAL)
	mainContainer.menuLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_RIGHT, GUI.ALIGNMENT_VERTICAL_TOP)
	mainContainer.menuLayout:setMargin(1, 1, 1, 0)
	mainContainer.menuLayout:setSpacing(1, 1, 2)

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
		mainContainer.iconField:updateFileList()
		mainContainer:drawOnScreen(...)
	end

	local lastWindowHandled
	mainContainer.eventHandler = function(mainContainer, object, e1, e2, e3, e4)
		if e1 == "key_down" then
			local windowsCount = #mainContainer.windowsContainer.children
			-- Ctrl or CMD
			if windowsCount > 0 and not lastWindowHandled and (keyboard.isKeyDown(29) or keyboard.isKeyDown(219)) then
				-- W
				if e4 == 17 then
					mainContainer.windowsContainer.children[windowsCount]:close()
					lastWindowHandled = true

					mainContainer:drawOnScreen()
				-- H
				elseif e4 == 35 then
					local lastUnhiddenWindowIndex = 1
					for i = 1, #mainContainer.windowsContainer.children do
						if not mainContainer.windowsContainer.children[i].hidden then
							lastUnhiddenWindowIndex = i
						end
					end
					mainContainer.windowsContainer.children[lastUnhiddenWindowIndex]:minimize()
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
				mainContainer:drawOnScreen()
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
			mainContainer:drawOnScreen()
			dateUptime = computer.uptime()
		end

		if MineOSCore.properties.screensaverEnabled then
			if e1 then
				screensaverUptime = computer.uptime()
			end

			if dateUptime - screensaverUptime >= MineOSCore.properties.screensaverDelay then
				if filesystem.exists(MineOSCore.properties.screensaver) then
					MineOSInterface.safeLaunch(MineOSCore.properties.screensaver)
					mainContainer:drawOnScreen(true)
				end

				screensaverUptime = computer.uptime()
			end
		end
	end

	MineOSInterface.menuInitialChildren = mainContainer.menu.children
end

---------------------------------------- Main loop ----------------------------------------

-- Runs tasks before/after OS UI initialization
local function runTasks(mode)
	for i = 1, #MineOSCore.properties.tasks do
		local task = MineOSCore.properties.tasks[i]
		if task.mode == mode and task.enabled then
			MineOSInterface.safeLaunch(task.path)
		end
	end
end

-- Creates OS main container and all its widgets
local function createWidgets()
	mainContainer = GUI.fullScreenContainer()
	MineOSInterface.mainContainer = mainContainer

	MineOSInterface.createWidgets()
	MineOSInterface.changeResolution()
	MineOSInterface.changeWallpaper()
	MineOSCore.updateTimezone()
end

-- "double_touch" event handler
if not event.doubleTouchHandler then
	event.doubleTouchHandler = event.listen(
		"touch",
		function(signalType, screenAddress, x, y, button, user)
			local uptime = computer.uptime()
			
			if doubleTouchX == x and doubleTouchY == y and doubleTouchButton == button and doubleTouchScreenAddress == screenAddress and uptime - doubleTouchUptime <= doubleTouchInterval then
				computer.pushSignal("double_touch", screenAddress, x, y, button, user)
			end

			doubleTouchX, doubleTouchY, doubleTouchButton, doubleTouchUptime, doubleTouchScreenAddress = x, y, button, uptime, screenAddress
		end,
		math.huge,
		math.huge
	)
end

-- Optaining temporary file's last modified UNIX timestamp
local temporaryPath = MineOSPaths.system .. "Timestamp.tmp"
local file = io.open(temporaryPath, "w")
file:close()
realTimestamp = math.floor(filesystem.lastModified(temporaryPath) / 1000)
filesystem.remove(temporaryPath)

-- Localization loading
MineOSCore.localization = MineOSCore.getLocalization(MineOSPaths.localizationFiles)

-- Tasks and UI initialization
runTasks(2)
createWidgets()
mainContainer:drawOnScreen()
MineOSNetwork.update()
runTasks(1)

-- Loops with UI regeneration after errors 
while true do
	local success, path, line, traceback = MineOSCore.call(
		mainContainer.startEventHandling,
		mainContainer,
		0
	)

	if success then
		break
	else
		createWidgets()
		mainContainer:drawOnScreen()
		MineOSInterface.showErrorWindow(path, line, traceback)
		mainContainer:drawOnScreen()
	end
end
