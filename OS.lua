
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

local application
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
	application.backgroundObject.wallpaper = nil

	if MineOSCore.properties.wallpaperEnabled and MineOSCore.properties.wallpaper then
		local result, reason = image.load(MineOSCore.properties.wallpaper)
		if result then
			application.backgroundObject.wallpaper, result = result, nil

			-- Fit to screen size mode
			if MineOSCore.properties.wallpaperMode == 1 then
				application.backgroundObject.wallpaper = image.transform(application.backgroundObject.wallpaper, application.width, application.height)
				application.backgroundObject.wallpaperPosition.x, application.backgroundObject.wallpaperPosition.y = 1, 1
			-- Centerized mode
			else
				application.backgroundObject.wallpaperPosition.x = math.floor(1 + application.width / 2 - image.getWidth(application.backgroundObject.wallpaper) / 2)
				application.backgroundObject.wallpaperPosition.y = math.floor(1 + application.height / 2 - image.getHeight(application.backgroundObject.wallpaper) / 2)
			end

			-- Brightness adjustment
			local backgrounds, foregrounds, r, g, b = application.backgroundObject.wallpaper[3], application.backgroundObject.wallpaper[4]
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

	application.width, application.height = buffer.getResolution()

	application.iconField.width = application.width
	application.iconField.height = application.height
	application.iconField:updateFileList()

	application.dockContainer.sort()
	application.dockContainer.localY = application.height - application.dockContainer.height + 1

	application.menu.width = application.width
	application.menuLayout.width = application.width
	application.backgroundObject.width, application.backgroundObject.height = application.width, application.height

	application.windowsContainer.width, application.windowsContainer.height = application.width, application.height - 1
end

local function moveDockIcon(index, direction)
	application.dockContainer.children[index], application.dockContainer.children[index + direction] = application.dockContainer.children[index + direction], application.dockContainer.children[index]
	application.dockContainer.sort()
	application.dockContainer.saveToOSSettings()
	application:draw()
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

local function dockIconEventHandler(application, icon, e1, e2, e3, e4, e5, e6, ...)
	if e1 == "touch" then
		icon.selected = true
		application:draw()

		if e5 == 1 then
			icon.onRightClick(icon, e1, e2, e3, e4, e5, e6, ...)
		else
			icon.onLeftClick(icon, e1, e2, e3, e4, e5, e6, ...)
		end
	end
end

function MineOSInterface.createWidgets()
	application:removeChildren()
	
	application.backgroundObject = application:addChild(GUI.object(1, 1, 1, 1))
	application.backgroundObject.wallpaperPosition = {x = 1, y = 1}
	application.backgroundObject.draw = function(object)
		buffer.drawRectangle(object.x, object.y, object.width, object.height, MineOSCore.properties.backgroundColor, 0, " ")
		if object.wallpaper then
			buffer.drawImage(object.wallpaperPosition.x, object.wallpaperPosition.y, object.wallpaper)
		end
	end

	application.iconField = application:addChild(
		MineOSInterface.iconField(
			1, 2, 1, 1, 3, 2,
			0xFFFFFF,
			0xD2D2D2,
			MineOSPaths.desktop
		)
	)
	
	application.iconField.iconConfigEnabled = true
	
	application.iconField.launchers.directory = function(icon)
		MineOSInterface.safeLaunch(MineOSPaths.explorer, "-o", icon.path)
	end
	
	application.iconField.launchers.showContainingFolder = function(icon)
		MineOSInterface.safeLaunch(MineOSPaths.explorer, "-o", filesystem.path(icon.shortcutPath or icon.path))
	end
	
	application.iconField.launchers.showPackageContent = function(icon)
		MineOSInterface.safeLaunch(MineOSPaths.explorer, "-o", icon.path)
	end

	application.dockContainer = application:addChild(GUI.container(1, 1, application.width, 7))

	application.dockContainer.saveToOSSettings = function()
		MineOSCore.properties.dockShortcuts = {}
		for i = 1, #application.dockContainer.children do
			if application.dockContainer.children[i].keepInDock then
				table.insert(MineOSCore.properties.dockShortcuts, application.dockContainer.children[i].path)
			end
		end
		MineOSCore.saveProperties()
	end

	application.dockContainer.sort = function()
		local x = 4
		for i = 1, #application.dockContainer.children do
			application.dockContainer.children[i].localX = x
			x = x + MineOSCore.properties.iconWidth + MineOSCore.properties.iconHorizontalSpaceBetween
		end

		application.dockContainer.width = #application.dockContainer.children * (MineOSCore.properties.iconWidth + MineOSCore.properties.iconHorizontalSpaceBetween) - MineOSCore.properties.iconHorizontalSpaceBetween + 6
		application.dockContainer.localX = math.floor(application.width / 2 - application.dockContainer.width / 2)
	end

	application.dockContainer.addIcon = function(path, window)
		local icon = application.dockContainer:addChild(MineOSInterface.icon(1, 2, path, 0x2D2D2D, 0xFFFFFF))
		icon:analyseExtension()
		icon:moveBackward()

		icon.eventHandler = dockIconEventHandler

		icon.onLeftClick = function(icon, ...)
			if icon.windows then
				for window in pairs(icon.windows) do
					window.hidden = false
					window:moveToFront()
				end

				os.sleep(0.2)

				icon.selected = false
				MineOSInterface.updateMenu()
				application:draw()
			else
				MineOSInterface.iconDoubleClick(icon, ...)
			end
		end

		icon.onRightClick = function(icon, e1, e2, e3, e4, ...)
			local indexOf = icon:indexOf()
			local menu = GUI.addContextMenu(application, e3, e4)
			
			menu.onMenuClosed = function()
				icon.selected = false
				application:draw()
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
					application:draw()
				end
			end
			
			menu:addItem(MineOSCore.localization.showContainingFolder).onTouch = function()
				MineOSInterface.safeLaunch(MineOSPaths.explorer, "-o", filesystem.path(icon.shortcutPath or icon.path))
			end
			
			menu:addSeparator()
			
			menu:addItem(MineOSCore.localization.moveRight, indexOf >= #application.dockContainer.children - 1).onTouch = function()
				moveDockIcon(indexOf, 1)
			end
			
			menu:addItem(MineOSCore.localization.moveLeft, indexOf <= 1).onTouch = function()
				moveDockIcon(indexOf, -1)
			end
			
			menu:addSeparator()
			
			if icon.keepInDock then
				if #application.dockContainer.children > 1 then
					menu:addItem(MineOSCore.localization.removeFromDock).onTouch = function()
						if icon.windows then
							icon.keepInDock = nil
						else
							icon:remove()
							application.dockContainer.sort()
						end
						application.dockContainer.saveToOSSettings()
						application:draw()
					end
				end
			else
				if icon.windows then
					menu:addItem(MineOSCore.localization.keepInDock).onTouch = function()
						icon.keepInDock = true
						application.dockContainer.saveToOSSettings()
					end
				end
			end

			application:draw()
		end

		application.dockContainer.sort()

		return icon
	end

	-- Trash
	local icon = application.dockContainer.addIcon(MineOSPaths.trash)
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
		local menu = GUI.addContextMenu(application, e3, e4)
		
		menu.onMenuClosed = function()
			icon.selected = false
			application:draw()
		end
		
		menu:addItem(MineOSCore.localization.emptyTrash).onTouch = function()
			local container = MineOSInterface.addBackgroundContainer(application, MineOSCore.localization.areYouSure)

			container.layout:addChild(GUI.button(1, 1, 30, 1, 0xE1E1E1, 0x2D2D2D, 0xA5A5A5, 0x2D2D2D, "OK")).onTouch = function()
				for file in filesystem.list(MineOSPaths.trash) do
					filesystem.remove(MineOSPaths.trash .. file)
				end
				container:remove()
				computer.pushSignal("MineOSCore", "updateFileList")
			end

			container.panel.onTouch = function()
				container:remove()
				application:draw()
			end

			application:draw()
		end

		application:draw()
	end

	for i = 1, #MineOSCore.properties.dockShortcuts do
		application.dockContainer.addIcon(MineOSCore.properties.dockShortcuts[i]).keepInDock = true
	end

	-- Draw dock drawDock dockDraw cyka заебался искать, блядь
	local overrideDockContainerDraw = application.dockContainer.draw
	application.dockContainer.draw = function(dockContainer)
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

	application.windowsContainer = application:addChild(GUI.container(1, 2, 1, 1))

	application.menu = application:addChild(GUI.menu(1, 1, application.width, MineOSCore.properties.menuColor, 0x696969, 0x3366CC, 0xFFFFFF))
	
	local MineOSContextMenu = application.menu:addContextMenu("MineOS", 0x000000)
	MineOSContextMenu:addItem(MineOSCore.localization.aboutSystem).onTouch = function()
		local container = MineOSInterface.addBackgroundContainer(application, MineOSCore.localization.aboutSystem)
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

		application:draw()
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
		application:stop()
		MineOSInterface.clearTerminal()
		os.exit()
	end
		
	application.menuLayout = application:addChild(GUI.layout(1, 1, 1, 1, 1, 1))
	application.menuLayout:setDirection(1, 1, GUI.DIRECTION_HORIZONTAL)
	application.menuLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_RIGHT, GUI.ALIGNMENT_VERTICAL_TOP)
	application.menuLayout:setMargin(1, 1, 1, 0)
	application.menuLayout:setSpacing(1, 1, 2)

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
		application.iconField:updateFileList()
		application:draw(...)
	end

	local lastWindowHandled
	application.eventHandler = function(application, object, e1, e2, e3, e4)
		if e1 == "key_down" then
			local windowsCount = #application.windowsContainer.children
			-- Ctrl or CMD
			if windowsCount > 0 and not lastWindowHandled and (keyboard.isKeyDown(29) or keyboard.isKeyDown(219)) then
				-- W
				if e4 == 17 then
					application.windowsContainer.children[windowsCount]:close()
					lastWindowHandled = true

					application:draw()
				-- H
				elseif e4 == 35 then
					local lastUnhiddenWindowIndex = 1
					for i = 1, #application.windowsContainer.children do
						if not application.windowsContainer.children[i].hidden then
							lastUnhiddenWindowIndex = i
						end
					end
					application.windowsContainer.children[lastUnhiddenWindowIndex]:minimize()
					lastWindowHandled = true

					application:draw()
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
				application:draw()
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
			application:draw()
			dateUptime = computer.uptime()
		end

		if MineOSCore.properties.screensaverEnabled then
			if e1 then
				screensaverUptime = computer.uptime()
			end

			if dateUptime - screensaverUptime >= MineOSCore.properties.screensaverDelay then
				if filesystem.exists(MineOSCore.properties.screensaver) then
					MineOSInterface.safeLaunch(MineOSCore.properties.screensaver)
					application:draw(true)
				end

				screensaverUptime = computer.uptime()
			end
		end
	end

	MineOSInterface.menuInitialChildren = application.menu.children
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
	application = GUI.application()
	MineOSInterface.application = application

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
application:draw()
MineOSNetwork.update()
runTasks(1)

-- Loops with UI regeneration after errors 
while true do
	local success, path, line, traceback = MineOSCore.call(
		application.start,
		application,
		0
	)

	if success then
		break
	else
		createWidgets()
		application:draw()
		MineOSInterface.showErrorWindow(path, line, traceback)
		application:draw()
	end
end