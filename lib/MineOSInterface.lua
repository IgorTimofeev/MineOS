
local component = require("component")
local computer = require("computer")
local keyboard = require("keyboard")
local event = require("event")
local term = require("term")
local MineOSCore = require("MineOSCore")
local MineOSPaths = require("MineOSPaths")
local image = require("image")
local GUI = require("GUI")
local fs = require("filesystem")
local unicode = require("unicode")
local buffer = require("doubleBuffering")
local MineOSInterface = {}

-----------------------------------------------------------------------------------------------------------------------------------

MineOSInterface.iconsCache = {}
MineOSInterface.iconClickDelay = 0.2
MineOSInterface.iconConfigFileName = ".icons"
MineOSInterface.iconImageWidth = 8
MineOSInterface.iconImageHeight = 4

-----------------------------------------------------------------------------------------------------------------------------------

local function calculateIconSizes()
	MineOSInterface.iconHalfWidth = math.floor(MineOSCore.properties.iconWidth / 2)
	MineOSInterface.iconTextHeight = MineOSCore.properties.iconHeight - MineOSInterface.iconImageHeight - 1
	MineOSInterface.iconImageHorizontalOffset = math.floor(MineOSInterface.iconHalfWidth - MineOSInterface.iconImageWidth / 2)
end

function MineOSInterface.setIconProperties(width, height, horizontalSpaceBetween, verticalSpaceBetween)
	MineOSCore.properties.iconWidth, MineOSCore.properties.iconHeight, MineOSCore.properties.iconHorizontalSpaceBetween, MineOSCore.properties.iconVerticalSpaceBetween = width, height, horizontalSpaceBetween, verticalSpaceBetween
	MineOSCore.saveProperties()
	calculateIconSizes()

	MineOSInterface.application.iconField:deleteIconConfig()
	MineOSInterface.application.dockContainer.sort()
	
	computer.pushSignal("MineOSCore", "updateFileList")
end

calculateIconSizes()

-----------------------------------------------------------------------------------------------------------------------------------

function MineOSInterface.clearTerminal()
	local gpu = component.gpu
	gpu.setBackground(0x1D1D1D)
	gpu.setForeground(0xFFFFFF)
	local width, height = gpu.getResolution()
	gpu.fill(1, 1, width, height, " ")
	term.setCursor(1, 1)
end

function MineOSInterface.waitForPressingAnyKey()
	print(" ")
	print(MineOSCore.localization.pressAnyKeyToContinue)
	while true do
		local eventType = event.pull()
		if eventType == "key_down" or eventType == "touch" then
			break
		end
	end
end

function MineOSInterface.launchScript(path)
	MineOSInterface.clearTerminal()
	if MineOSInterface.safeLaunch(path) then
		MineOSInterface.waitForPressingAnyKey()
	end
end

-----------------------------------------------------------------------------------------------------------------------------------

function MineOSInterface.cacheIconSource(name, path)
	if not MineOSInterface.iconsCache[name] then
		MineOSInterface.iconsCache[name] = image.load(path)
	end
	
	return MineOSInterface.iconsCache[name]
end

local function iconDraw(icon)
	local selectionTransparency = MineOSCore.properties.transparencyEnabled and 0.5
	local text = MineOSCore.properties.showExtension and icon.name or icon.nameWithoutExtension
	local xCenter, yText = icon.x + MineOSInterface.iconHalfWidth, icon.y + MineOSInterface.iconImageHeight + 1

	local function iconDrawNameLine(y, line)
		local lineLength = unicode.len(line)
		local x = math.floor(xCenter - lineLength / 2)
		
		if icon.selected then
			buffer.drawRectangle(x, y, lineLength, 1, icon.colors.selection, 0x0, " ", selectionTransparency)
		end
		buffer.drawText(x, y, icon.colors.text, line)
	end

	local charIndex = 1
	for lineIndex = 1, MineOSInterface.iconTextHeight do
		if lineIndex < MineOSInterface.iconTextHeight then
			iconDrawNameLine(yText, unicode.sub(text, charIndex, charIndex + icon.width - 1))
			charIndex, yText = charIndex + icon.width, yText + 1
		else
			iconDrawNameLine(yText, string.limit(unicode.sub(text, charIndex, -1), icon.width, "center"))
		end
	end

	local xImage = icon.x + MineOSInterface.iconImageHorizontalOffset
	if icon.selected then
		local xSelection = xImage - 1
		buffer.drawText(xSelection, icon.y - 1, icon.colors.selection, string.rep("▄", MineOSInterface.iconImageWidth + 2), selectionTransparency)
		buffer.drawText(xSelection, icon.y + MineOSInterface.iconImageHeight, icon.colors.selection, string.rep("▀", MineOSInterface.iconImageWidth + 2), selectionTransparency)
		buffer.drawRectangle(xSelection, icon.y, MineOSInterface.iconImageWidth + 2, MineOSInterface.iconImageHeight, icon.colors.selection, 0x0, " ", selectionTransparency)
	end

	if icon.image then
		if icon.cut then
			if not icon.semiTransparentImage then
				icon.semiTransparentImage = image.copy(icon.image)
				for i = 1, #icon.semiTransparentImage[3] do
					icon.semiTransparentImage[5][i] = icon.semiTransparentImage[5][i] + 0.6
					if icon.semiTransparentImage[5][i] > 1 then
						icon.semiTransparentImage[5][i] = 1
					end
				end
			end
			
			buffer.drawImage(xImage, icon.y, icon.semiTransparentImage, true)
		else
			buffer.drawImage(xImage, icon.y, icon.image)
		end
	elseif icon.liveImage then
		icon.liveImage(xImage, icon.y)
	end

	local xShortcut = xImage + MineOSInterface.iconImageWidth
	if icon.isShortcut then
		buffer.set(xShortcut - 1, icon.y + MineOSInterface.iconImageHeight - 1, 0xFFFFFF, 0x0, "<")
	end

	if icon.windows then
		buffer.drawText(xCenter - 1, icon.y + MineOSInterface.iconImageHeight, 0x66DBFF, "╺╸")
		
		local windowCount = table.size(icon.windows)
		if windowCount > 1 then

			windowCount = tostring(windowCount)
			local windowCountLength = #windowCount
			local xTip, yTip = xShortcut - windowCountLength, icon.y

			buffer.drawRectangle(xTip, yTip, windowCountLength, 1, 0xFF4940, 0xFFFFFF, " ")
			buffer.drawText(xTip, yTip, 0xFFFFFF, windowCount)
			buffer.drawText(xTip - 1, yTip, 0xFF4940, "⢸")
			buffer.drawText(xTip + windowCountLength, yTip, 0xFF4940, "⡇")
			buffer.drawText(xTip, yTip - 1, 0xFF4940, string.rep("⣀", windowCountLength))
			buffer.drawText(xTip, yTip + 1, 0xFF4940, string.rep("⠉", windowCountLength))
		end
	end
end

local function iconEventHandler(application, object, e1, e2, e3, e4, e5, ...)
	if e1 == "touch" and object:isPointInside(e3, e4) then
		object.lastTouchPosition = object.lastTouchPosition or {}
		object.lastTouchPosition.x, object.lastTouchPosition.y = e3, e4
		object:moveToFront()

		if e5 == 0 then
			object.parent.parent.onLeftClick(object, e1, e2, e3, e4, e5, ...)
		else
			object.parent.parent.onRightClick(object, e1, e2, e3, e4, e5, ...)
		end
	elseif e1 == "double_touch" and object:isPointInside(e3, e4) and e5 == 0 then
		object.parent.parent.onDoubleClick(object, e1, e2, e3, e4, e5, ...)
	elseif e1 == "drag" and object.parent.parent.iconConfigEnabled and object.lastTouchPosition then
		-- Ебучие авторы мода, ну на кой хуй было делать drop-ивент без наличия drag? ПИДОРЫ
		object.dragStarted = true
		object.localX = object.localX + e3 - object.lastTouchPosition.x
		object.localY = object.localY + e4 - object.lastTouchPosition.y
		object.lastTouchPosition.x, object.lastTouchPosition.y = e3, e4

		application:draw()
	elseif e1 == "drop" and object.parent.parent.iconConfigEnabled and object.dragStarted then
		object.dragStarted = nil
		object.parent.parent.iconConfig[object.name .. (object.isDirectory and "/" or "")] = {
			x = object.localX,
			y = object.localY
		}
		object.parent.parent:saveIconConfig()
		object.lastTouchPosition = nil
	end
end

local function iconAnalyseExtension(icon)
	if icon.isDirectory then
		if icon.extension == ".app" then
			if MineOSCore.properties.showApplicationIcons then
				if fs.exists(icon.path .. "Icon.pic") then
					icon.image = image.load(icon.path .. "Icon.pic")
				elseif fs.exists(icon.path .. "Resources/Icon.pic") then
					icon.image = image.load(icon.path .. "Resources/Icon.pic")
				elseif fs.exists(icon.path .. "Icon.lua") then
					local result, reason = loadfile(icon.path .. "Icon.lua")
					if result then
						result, reason = pcall(result)
						if result then
							icon.liveImage = reason
						else
							error("Failed to load live icon image: " .. tostring(reason))
						end
					else
						error("Failed to load live icon image: " .. tostring(reason))
					end
				else
					icon.image = MineOSInterface.iconsCache.fileNotExists
				end
			else
				icon.image = MineOSInterface.iconsCache.application
			end

			icon.launch = icon.launchers.application
		else
			icon.image = MineOSInterface.iconsCache.folder
			icon.launch = icon.launchers.directory
		end
	else
		if icon.extension == ".lnk" then
			icon.shortcutPath = MineOSCore.readShortcut(icon.path)
			icon.shortcutExtension = fs.extension(icon.shortcutPath)
			icon.shortcutIsDirectory = fs.isDirectory(icon.shortcutPath)
			icon.isShortcut = true

			local shortcutIcon = iconAnalyseExtension({
				path = icon.shortcutPath,
				extension = icon.shortcutExtension,
				name = icon.name,
				nameWithoutExtension = icon.nameWithoutExtension,
				isDirectory = icon.shortcutIsDirectory,
				iconImage = icon.iconImage,
				launchers = icon.launchers
			})

			icon.image = shortcutIcon.image
			icon.shortcutLaunch = shortcutIcon.launch
			icon.launch = icon.launchers.shortcut

			shortcutIcon = nil
		elseif not fs.exists(icon.path) then
			icon.image = MineOSInterface.iconsCache.fileNotExists
			icon.launch = icon.launchers.corrupted
		else
			if MineOSCore.properties.extensionAssociations[icon.extension] then
				icon.launch = icon.launchers.extension
				icon.image = MineOSInterface.cacheIconSource(icon.extension, MineOSCore.properties.extensionAssociations[icon.extension].icon)
			else
				icon.launch = icon.launchers.script
				icon.image = MineOSInterface.iconsCache.script
			end
		end
	end

	return icon
end

local function iconIsPointInside(icon, x, y)
	return
		x >= icon.x + MineOSInterface.iconImageHorizontalOffset and
		y >= icon.y and
		x <= icon.x + MineOSInterface.iconImageHorizontalOffset + MineOSInterface.iconImageWidth - 1 and
		y <= icon.y + MineOSInterface.iconImageHeight - 1
		or
		x >= icon.x and 
		y >= icon.y + MineOSInterface.iconImageHeight + 1 and
		x <= icon.x + MineOSCore.properties.iconWidth - 1 and
		y <= icon.y + MineOSCore.properties.iconHeight - 1
end

function MineOSInterface.icon(x, y, path, textColor, selectionColor)
	local icon = GUI.object(x, y, MineOSCore.properties.iconWidth, MineOSCore.properties.iconHeight)
	
	icon.colors = {
		text = textColor,
		selection = selectionColor
	}

	icon.path = path
	icon.extension = fs.extension(icon.path) or "script"
	icon.name = fs.name(path)
	icon.nameWithoutExtension = fs.hideExtension(icon.name)
	icon.isDirectory = fs.isDirectory(icon.path)
	icon.isShortcut = false
	icon.selected = false

	icon.isPointInside = iconIsPointInside
	icon.draw = iconDraw
	icon.launchers = table.copy(MineOSInterface.iconLaunchers)
	icon.analyseExtension = iconAnalyseExtension

	return icon
end

local function iconFieldUpdate(iconField)
	iconField.backgroundObject.width, iconField.backgroundObject.height = iconField.width, iconField.height
	iconField.iconsContainer.width, iconField.iconsContainer.height = iconField.width, iconField.height

	iconField.iconCount.horizontal = math.floor((iconField.width - iconField.xOffset) / (MineOSCore.properties.iconWidth + MineOSCore.properties.iconHorizontalSpaceBetween))
	iconField.iconCount.vertical = math.floor((iconField.height - iconField.yOffset) / (MineOSCore.properties.iconHeight + MineOSCore.properties.iconVerticalSpaceBetween))
	iconField.iconCount.total = iconField.iconCount.horizontal * iconField.iconCount.vertical

	return iconField
end

local function iconFieldLoadIconConfig(iconField)
	if fs.exists(iconField.workpath .. MineOSInterface.iconConfigFileName) then
		iconField.iconConfig = table.fromFile(iconField.workpath .. MineOSInterface.iconConfigFileName)
	else
		iconField.iconConfig = {}
	end
end

local function iconFieldSaveIconConfig(iconField)
	table.toFile(iconField.workpath .. MineOSInterface.iconConfigFileName, iconField.iconConfig)
end

local function iconFieldDeleteIconConfig(iconField)
	iconField.iconConfig = {}
	fs.remove(iconField.workpath .. MineOSInterface.iconConfigFileName, iconField.iconConfig)
end

-----------------------------------------------------------------------------------------------------------------------------------

MineOSInterface.iconLaunchers = {}

function MineOSInterface.iconLaunchers.application(icon)
	MineOSInterface.safeLaunch(icon.path .. "Main.lua")
end

function MineOSInterface.iconLaunchers.directory(icon)
	icon.parent.parent:setWorkpath(icon.path)
end

function MineOSInterface.iconLaunchers.shortcut(icon)
	local oldPath = icon.path
	icon.path = icon.shortcutPath
	icon:shortcutLaunch()
	icon.path = oldPath
end

function MineOSInterface.iconLaunchers.corrupted(icon)
	GUI.alert("Application is corrupted")
end

function MineOSInterface.iconLaunchers.extension(icon)
	if icon.isShortcut then
		MineOSInterface.safeLaunch(MineOSCore.properties.extensionAssociations[icon.shortcutExtension].launcher, icon.shortcutPath, "-o")
	else
		MineOSInterface.safeLaunch(MineOSCore.properties.extensionAssociations[icon.extension].launcher, icon.path, "-o")
	end
end

function MineOSInterface.iconLaunchers.script(icon)
	MineOSInterface.launchScript(icon.path)
end

function MineOSInterface.iconLaunchers.showPackageContent(icon)
	icon.parent.parent:setWorkpath(icon.path)
	icon.parent.parent:updateFileList()
	icon.firstParent:draw()
end

function MineOSInterface.iconLaunchers.showContainingFolder(icon)
	icon.parent.parent:setWorkpath(fs.path(icon.shortcutPath))
	icon.parent.parent:updateFileList()
	icon.firstParent:draw()
end

-----------------------------------------------------------------------------------------------------------------------------------

local function getCykaIconPosition(iconField)
	local y = iconField.yOffset
	for i = 1, #iconField.iconsContainer.children do
		y = math.max(y, iconField.iconsContainer.children[i].localY)
	end

	local x = iconField.xOffset
	for i = 1, #iconField.iconsContainer.children do
		if iconField.iconsContainer.children[i].localY == y then
			x = math.max(x, iconField.iconsContainer.children[i].localX)
		end
	end

	x = x + MineOSCore.properties.iconWidth + MineOSCore.properties.iconHorizontalSpaceBetween
	if x + MineOSCore.properties.iconWidth + MineOSCore.properties.iconHorizontalSpaceBetween > iconField.iconsContainer.width then
		x, y = iconField.xOffset, y + MineOSCore.properties.iconHeight + MineOSCore.properties.iconVerticalSpaceBetween
	end

	return x, y
end

local function iconFieldUpdateFileList(iconField)
	iconField.fileList = fs.sortedList(iconField.workpath, MineOSCore.properties.sortingMethod or "type", MineOSCore.properties.showHiddenFiles, iconField.filenameMatcher, false)
	iconField:update()

	if iconField.iconConfigEnabled then
		iconField:loadIconConfig()
	end
	
	local configList, notConfigList = {}, {}
	for i = iconField.fromFile, iconField.fromFile + iconField.iconCount.total - 1 do
		if iconField.fileList[i] then
			if iconField.iconConfigEnabled and iconField.iconConfig[iconField.fileList[i]] then
				table.insert(configList, iconField.fileList[i])
			else
				table.insert(notConfigList, iconField.fileList[i])
			end
		else
			break
		end
	end

	local function checkClipboard(icon)
		if MineOSCore.clipboard and MineOSCore.clipboard.cut then
			for i = 1, #MineOSCore.clipboard do
				if MineOSCore.clipboard[i] == icon.path then
					icon.cut = true
				end
			end
		end
	end

	-- Заполнение дочернего контейнера
	iconField.iconsContainer:removeChildren()
	for i = 1, #configList do
		local icon = iconField.iconsContainer:addChild(MineOSInterface.icon(
			iconField.iconConfig[configList[i]].x,
			iconField.iconConfig[configList[i]].y,
			iconField.workpath .. configList[i],
			iconField.colors.text,
			iconField.colors.selection
		))

		checkClipboard(icon)
		icon.eventHandler = iconEventHandler
		icon.launchers = iconField.launchers
		icon:analyseExtension()
	end

	local x, y
	if #configList > 0 then
		x, y = getCykaIconPosition(iconField, configList)
	else
		x, y = iconField.xOffset, iconField.yOffset
	end

	for i = 1, #notConfigList do
		local icon = iconField.iconsContainer:addChild(MineOSInterface.icon(x, y, iconField.workpath .. notConfigList[i], iconField.colors.text, iconField.colors.selection))
		iconField.iconConfig[notConfigList[i]] = {x = x, y = y}

		checkClipboard(icon)
		icon.eventHandler = iconEventHandler
		icon.launchers = iconField.launchers
		icon:analyseExtension()

		x = x + MineOSCore.properties.iconWidth + MineOSCore.properties.iconHorizontalSpaceBetween
		if x + MineOSCore.properties.iconWidth + MineOSCore.properties.iconHorizontalSpaceBetween - 1 > iconField.iconsContainer.width then
			x, y = iconField.xOffset, y + MineOSCore.properties.iconHeight + MineOSCore.properties.iconVerticalSpaceBetween
		end
	end

	if iconField.iconConfigEnabled then
		iconField:saveIconConfig()
	end

	return iconField
end

local function iconFieldBackgroundObjectEventHandler(application, object, e1, e2, e3, e4, e5, ...)
	if e1 == "touch" then
		if e5 == 0 then
			object.parent:deselectAll()
			object.parent.selection = {
				x1 = e3,
				y1 = e4
			}

			application:draw()
		else
			local menu = GUI.addContextMenu(MineOSInterface.application, e3, e4)

			local subMenu = menu:addSubMenu(MineOSCore.localization.create)

			subMenu:addItem(MineOSCore.localization.newFile).onTouch = function()
				MineOSInterface.newFile(MineOSInterface.application, object.parent, e3, e4, object.parent.workpath)
			end
			
			subMenu:addItem(MineOSCore.localization.newFolder).onTouch = function()
				MineOSInterface.newFolder(MineOSInterface.application, object.parent, e3, e4, object.parent.workpath)
			end

			subMenu:addItem(MineOSCore.localization.newFileFromURL, not component.isAvailable("internet")).onTouch = function()
				MineOSInterface.newFileFromURL(MineOSInterface.application, object.parent, e3, e4, object.parent.workpath)
			end

			subMenu:addSeparator()

			subMenu:addItem(MineOSCore.localization.newApplication).onTouch = function()
				MineOSInterface.newApplication(MineOSInterface.application, object.parent, e3, e4, object.parent.workpath)
			end

			menu:addSeparator()
						
			local subMenu = menu:addSubMenu(MineOSCore.localization.sortBy)
			
			subMenu:addItem(MineOSCore.localization.sortByName).onTouch = function()
				object.parent:deleteIconConfig()

				MineOSCore.properties.sortingMethod = "name"
				MineOSCore.saveProperties()
				computer.pushSignal("MineOSCore", "updateFileList")
			end

			subMenu:addItem(MineOSCore.localization.sortByDate).onTouch = function()
				object.parent:deleteIconConfig()

				MineOSCore.properties.sortingMethod = "date"
				MineOSCore.saveProperties()
				computer.pushSignal("MineOSCore", "updateFileList")
			end

			subMenu:addItem(MineOSCore.localization.sortByType).onTouch = function()
				object.parent:deleteIconConfig()

				MineOSCore.properties.sortingMethod = "type"
				MineOSCore.saveProperties()
				computer.pushSignal("MineOSCore", "updateFileList")
			end

			menu:addItem(MineOSCore.localization.sortAutomatically).onTouch = function()
				object.parent:deleteIconConfig()
				computer.pushSignal("MineOSCore", "updateFileList")
			end

			menu:addItem(MineOSCore.localization.update).onTouch = function()
				computer.pushSignal("MineOSCore", "updateFileList")
			end

			menu:addSeparator()

			menu:addItem(MineOSCore.localization.paste, not MineOSCore.clipboard).onTouch = function()
				local i = 1
				while i <= #MineOSCore.clipboard do
					if fs.exists(MineOSCore.clipboard[i]) then
						i = i + 1
					else
						table.remove(MineOSCore.clipboard, i)
					end
				end

				MineOSInterface.copy(MineOSCore.clipboard, object.parent.workpath)

				if MineOSCore.clipboard.cut then
					for i = 1, #MineOSCore.clipboard do
						fs.remove(MineOSCore.clipboard[i])
					end
					MineOSCore.clipboard = nil
				end

				computer.pushSignal("MineOSCore", "updateFileList")
			end

			MineOSInterface.application:draw()
		end
	elseif e1 == "drag" then
		if object.parent.selection then
			object.parent.selection.x2, object.parent.selection.y2 = e3, e4
			object:moveToFront()

			application:draw()
		end
	elseif e1 == "drop" then
		object.parent.selection = nil
		object:moveToBack()

		application:draw()
	end
end

local function iconFieldBackgroundObjectDraw(object)
	if object.parent.selection and object.parent.selection.x2 then
		local x1, y1, x2, y2 = object.parent.selection.x1, object.parent.selection.y1, object.parent.selection.x2, object.parent.selection.y2

		if x2 < x1 then
			x1, x2 = x2, x1
		end

		if y2 < y1 then
			y1, y2 = y2, y1
		end
		
		if MineOSCore.properties.transparencyEnabled then	
			buffer.drawRectangle(x1, y1, x2 - x1 + 1, y2 - y1 + 1, object.parent.colors.selection, 0x0, " ", 0.5)
		else
			buffer.drawFrame(x1, y1, x2 - x1 + 1, y2 - y1 + 1, object.parent.colors.selection)
		end

		for i = 1, #object.parent.iconsContainer.children do
			local xCenter, yCenter = object.parent.iconsContainer.children[i].x + MineOSCore.properties.iconWidth / 2, object.parent.iconsContainer.children[i].y + MineOSCore.properties.iconHeight / 2
			object.parent.iconsContainer.children[i].selected = 
				xCenter >= x1 and
				xCenter <= x2 and
				yCenter >= y1 and
				yCenter <= y2
		end
	end
end

local function iconFieldDeselectAll(iconField)
	for i = 1, #iconField.iconsContainer.children do
		iconField.iconsContainer.children[i].selected = false
	end
end

local function iconFieldGetSelectedIcons(iconField)
	local selectedIcons = {}
	
	for i = 1, #iconField.iconsContainer.children do
		if iconField.iconsContainer.children[i].selected then
			table.insert(selectedIcons, iconField.iconsContainer.children[i])
		end
	end

	return selectedIcons
end

local function iconFieldSetWorkpath(iconField, path)
	iconField.workpath = path
	iconField.filenameMatcher = nil
	iconField.fromFile = 1

	return iconField
end

function MineOSInterface.iconField(x, y, width, height, xOffset, yOffset, textColor, selectionColor, workpath)
	local iconField = GUI.container(x, y, width, height)

	iconField.colors = {
		text = textColor,
		selection = selectionColor
	}

	iconField.iconConfig = {}
	iconField.iconCount = {}
	iconField.fileList = {}
	iconField.fromFile = 1
	iconField.iconConfigEnabled = false
	iconField.xOffset = xOffset
	iconField.yOffset = yOffset
	iconField.workpath = workpath
	iconField.filenameMatcher = nil

	iconField.backgroundObject = iconField:addChild(GUI.object(1, 1, width, height))
	iconField.backgroundObject.eventHandler = iconFieldBackgroundObjectEventHandler
	iconField.backgroundObject.draw = iconFieldBackgroundObjectDraw

	iconField.iconsContainer = iconField:addChild(GUI.container(1, 1, width, height))	

	iconField.updateFileList = iconFieldUpdateFileList
	iconField.update = iconFieldUpdate
	iconField.deselectAll = iconFieldDeselectAll
	iconField.loadIconConfig = iconFieldLoadIconConfig
	iconField.saveIconConfig = iconFieldSaveIconConfig
	iconField.deleteIconConfig = iconFieldDeleteIconConfig
	iconField.getSelectedIcons = iconFieldGetSelectedIcons
	iconField.setWorkpath = iconFieldSetWorkpath

	iconField.onLeftClick = MineOSInterface.iconLeftClick
	iconField.onRightClick = MineOSInterface.iconRightClick
	iconField.onDoubleClick = MineOSInterface.iconDoubleClick

	iconField.launchers = table.copy(MineOSInterface.iconLaunchers)

	return iconField
end

----------------------------------------------------------------------------------------------------------------

function MineOSInterface.iconLeftClick(icon)
	if not keyboard.isKeyDown(29) and not keyboard.isKeyDown(219) then
		icon.parent.parent:deselectAll()
	end
	icon.selected = true

	MineOSInterface.application:draw()
end

function MineOSInterface.iconDoubleClick(icon)
	icon:launch()
	icon.selected = false
	MineOSInterface.application:draw()
end

function MineOSInterface.iconRightClick(icon, e1, e2, e3, e4)
	icon.selected = true
	MineOSInterface.application:draw()

	local selectedIcons = icon.parent.parent:getSelectedIcons()

	local menu = GUI.addContextMenu(MineOSInterface.application, e3, e4)
	
	menu.onMenuClosed = function()
		icon.parent.parent:deselectAll()
		MineOSInterface.application:draw()
	end

	if #selectedIcons == 1 then
		if icon.isDirectory then
			if icon.extension == ".app" then
				menu:addItem(MineOSCore.localization.showPackageContent).onTouch = function()
					icon.parent.parent.launchers.showPackageContent(icon)
				end		

				menu:addItem(MineOSCore.localization.launchWithArguments).onTouch = function()
					MineOSInterface.launchWithArguments(MineOSInterface.application, icon.path .. "Main.lua")
				end

				menu:addItem(MineOSCore.localization.edit .. " Main.lua").onTouch = function()
					MineOSInterface.safeLaunch(MineOSPaths.editor, icon.path .. "Main.lua")
				end

				menu:addSeparator()
			end

			if icon.extension ~= ".app" then
				menu:addItem(MineOSCore.localization.addToFavourites).onTouch = function()
					local container = MineOSInterface.addBackgroundContainer(MineOSInterface.application, MineOSCore.localization.addToFavourites)

					local input = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0x878787, 0xE1E1E1, 0x2D2D2D, icon.name, MineOSCore.localization.name))
					container.panel.eventHandler = function(application, object, e1)
						if e1 == "touch" then
							container:remove()

							if e1 == "touch" and #input.text > 0 then
								computer.pushSignal("Finder", "updateFavourites", {name = input.text, path = icon.path})
							else
								MineOSInterface.application:draw()
							end
						end
					end					
			 	end
			end
			
		else
			if icon.isShortcut then
				menu:addItem(MineOSCore.localization.editShortcut).onTouch = function()
					MineOSInterface.editShortcut(MineOSInterface.application, icon.path)
					computer.pushSignal("MineOSCore", "updateFileList")
				end

				menu:addItem(MineOSCore.localization.showContainingFolder).onTouch = function()
					icon.parent.parent.launchers.showContainingFolder(icon)
				end

				menu:addSeparator()
			else
				if MineOSCore.properties.extensionAssociations[icon.extension] and MineOSCore.properties.extensionAssociations[icon.extension].contextMenu then
					pcall(loadfile(MineOSCore.properties.extensionAssociations[icon.extension].contextMenu), icon, menu)
					menu:addSeparator()
				end

				-- local subMenu = menu:addSubMenu(MineOSCore.localization.openWith)
				-- local fileList = fs.sortedList(MineOSPaths.applications, "name")
				-- subMenu:addItem(MineOSCore.localization.select)
				-- subMenu:addSeparator()
				-- for i = 1, #fileList do
				-- 	subMenu:addItem(fileList[i].nameWithoutExtension)
				-- end
			end
		end
	end

	if #selectedIcons > 1 then
		menu:addItem(MineOSCore.localization.newFolderFromChosen .. " (" .. #selectedIcons .. ")").onTouch = function()
			MineOSInterface.newFolderFromChosen(MineOSInterface.application, icon.parent.parent, e3, e4, selectedIcons)
		end
		menu:addSeparator()
	end

	menu:addItem(MineOSCore.localization.archive .. (#selectedIcons > 1 and " (" .. #selectedIcons .. ")" or "")).onTouch = function()
		local itemsToArchive = {}
		for i = 1, #selectedIcons do
			table.insert(itemsToArchive, selectedIcons[i].path)
		end

		local success, reason = require("archive").pack(fs.path(icon.path) .. "/Archive.arc", itemsToArchive)
		if not success then
			GUI.alert(reason)
		end

		computer.pushSignal("MineOSCore", "updateFileList")
	end

	local function cutOrCopy(cut)
		for i = 1, #icon.parent.children do
			icon.parent.children[i].cut = nil
		end

		MineOSCore.clipboard = {cut = cut}
		for i = 1, #selectedIcons do
			selectedIcons[i].cut = cut
			table.insert(MineOSCore.clipboard, selectedIcons[i].path)
		end
	end

	menu:addItem(MineOSCore.localization.cut).onTouch = function()
		cutOrCopy(true)
	end

	menu:addItem(MineOSCore.localization.copy).onTouch = function()
		cutOrCopy()
	end

	if not icon.isShortcut or #selectedIcons > 1 then
		local subMenu = menu:addSubMenu(MineOSCore.localization.createShortcut)
		
		subMenu:addItem(MineOSCore.localization.inCurrentDirectory).onTouch = function()
			for i = 1, #selectedIcons do
				if not selectedIcons[i].isShortcut then
					MineOSCore.createShortcut(
						fs.path(selectedIcons[i].path) .. "/" .. selectedIcons[i].nameWithoutExtension .. ".lnk",
						selectedIcons[i].path
					)
				end
			end
			
			computer.pushSignal("MineOSCore", "updateFileList")
		end

		subMenu:addItem(MineOSCore.localization.onDesktop).onTouch = function()
			for i = 1, #selectedIcons do
				if not selectedIcons[i].isShortcut then
					MineOSCore.createShortcut(
						MineOSPaths.desktop .. "/" .. selectedIcons[i].nameWithoutExtension .. ".lnk",
						selectedIcons[i].path
					)
				end
			end
			
			computer.pushSignal("MineOSCore", "updateFileList")
		end
	end

	if #selectedIcons == 1 then
		menu:addItem(MineOSCore.localization.rename).onTouch = function()
			MineOSInterface.rename(MineOSInterface.application, icon.path)
		end
	end

	menu:addItem(MineOSCore.localization.delete).onTouch = function()
		for i = 1, #selectedIcons do
			if fs.path(selectedIcons[i].path) == MineOSPaths.trash then
				fs.remove(selectedIcons[i].path)
			else
				local newName = MineOSPaths.trash .. selectedIcons[i].name
				local clearName = selectedIcons[i].nameWithoutExtension
				local repeats = 1
				while fs.exists(newName) do
					newName, repeats = MineOSPaths.trash .. clearName .. string.rep("-copy", repeats) .. selectedIcons[i].extension, repeats + 1
				end
				fs.rename(selectedIcons[i].path, newName)
			end
		end

		computer.pushSignal("MineOSCore", "updateFileList")
	end

	menu:addSeparator()

	if #selectedIcons == 1 then
		menu:addItem(MineOSCore.localization.addToDock).onTouch = function()
			MineOSInterface.application.dockContainer.addIcon(icon.path).keepInDock = true
			MineOSInterface.application.dockContainer.saveToOSSettings()
		end
	end

	menu:addItem(MineOSCore.localization.properties).onTouch = function()
		for i = 1, #selectedIcons do
			MineOSInterface.propertiesWindow(e3, e4, 40, selectedIcons[i])
		end
	end

	MineOSInterface.application:draw()
end

-----------------------------------------------------------------------------------------------------------------------------------

function MineOSInterface.addBackgroundContainer(parentContainer, title)
	local container = GUI.addBackgroundContainer(parentContainer, true, true, title)
	container.panel.colors.background = MineOSCore.properties.transparencyEnabled and 0x0 or MineOSCore.properties.backgroundColor
	container.panel.colors.transparency = MineOSCore.properties.transparencyEnabled and GUI.BACKGROUND_CONTAINER_PANEL_TRANSPARENCY
	
	return container
end

local function addUniversalContainerWithInputTextBox(parentWindow, text, title, placeholder)
	local container = MineOSInterface.addBackgroundContainer(parentWindow, title)
	
	container.inputField = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0x878787, 0xE1E1E1, 0x2D2D2D, text, placeholder, false))
	container.label = container.layout:addChild(GUI.label(1, 1, 36, 1, 0xFF4940, MineOSCore.localization.file .. " " .. MineOSCore.localization.alreadyExists)):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
	container.label.hidden = true

	return container
end

local function checkFileToExists(container, path)
	if fs.exists(path) then
		container.label.hidden = false
		container.parent:draw()
	else
		container:remove()
		return true
	end
end

local function checkIconConfigCanSavePosition(iconField, x, y, filename)
	if iconField.iconConfigEnabled then
		iconField.iconConfig[filename] = { x = x, y = y }
		iconField:saveIconConfig()
	end
end

function MineOSInterface.newFile(parentWindow, iconField, x, y, path)
	local container = addUniversalContainerWithInputTextBox(parentWindow, nil, MineOSCore.localization.newFile, MineOSCore.localization.fileName)

	container.inputField.onInputFinished = function()
		if checkFileToExists(container, path .. container.inputField.text) then
			local file = io.open(path .. container.inputField.text, "w")
			file:close()
			checkIconConfigCanSavePosition(iconField, x, y, container.inputField.text)
			MineOSInterface.safeLaunch(MineOSPaths.editor, path .. container.inputField.text)
			computer.pushSignal("MineOSCore", "updateFileList")
		end
	end

	parentWindow:draw()
end

function MineOSInterface.newFolder(parentWindow, iconField, x, y, path)
	local container = addUniversalContainerWithInputTextBox(parentWindow, nil, MineOSCore.localization.newFolder, MineOSCore.localization.folderName)

	container.inputField.onInputFinished = function()
		if checkFileToExists(container, path .. container.inputField.text) then
			fs.makeDirectory(path .. container.inputField.text)
			checkIconConfigCanSavePosition(iconField, x, y, container.inputField.text .. "/")
			computer.pushSignal("MineOSCore", "updateFileList")
		end
	end

	parentWindow:draw()

	return container
end

function MineOSInterface.newFileFromURL(parentWindow, iconField, x, y, path)
	local container = addUniversalContainerWithInputTextBox(parentWindow, nil, "Загрузить файл по URL", MineOSCore.localization.fileName)

	container.inputFieldURL = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0x878787, 0xE1E1E1, 0x2D2D2D, nil, "URL", false))
	container.panel.eventHandler = function(application, object, e1)
		if e1 == "touch" then
			if #container.inputField.text > 0 and #container.inputFieldURL.text > 0 then
				if fs.exists(path .. container.inputField.text) then
					container.label.hidden = false
					application:draw()
				else
					container.layout:removeChildren(2)
					container.layout:addChild(GUI.label(1, 1, container.width, 1, 0x787878, MineOSCore.localization.downloading .. "...")):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
					application:draw()

					local success, reason = require("web").download(container.inputFieldURL.text, path .. container.inputField.text)
					container:remove()

					if success then
						checkIconConfigCanSavePosition(iconField, x, y, container.inputField.text)
						computer.pushSignal("MineOSCore", "updateFileList")
					else
						GUI.alert(reason)
						application:draw()
					end
				end
			else
				container:remove()
				application:draw()
			end
		end
	end

	parentWindow:draw()
end

function MineOSInterface.newApplication(parentWindow, iconField, x, y, path)
	local container = addUniversalContainerWithInputTextBox(parentWindow, nil, MineOSCore.localization.newApplication, MineOSCore.localization.applicationName)

	local filesystemChooser = container.layout:addChild(GUI.filesystemChooser(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0x444444, 0x969696, nil, MineOSCore.localization.open, MineOSCore.localization.cancel, MineOSCore.localization.iconPath, "/"))
	filesystemChooser:addExtensionFilter(".pic")
	filesystemChooser:moveBackward()
	
	container.panel.eventHandler = function(application, object, e1)
		if e1 == "touch" then	
			if #container.inputField.text > 0 then
				local finalPath = path .. container.inputField.text .. ".app/"
				if checkFileToExists(container, finalPath) then
					fs.makeDirectory(finalPath)
					fs.copy(filesystemChooser.path or MineOSPaths.icons .. "SampleIcon.pic", finalPath .. "Icon.pic")
					
					local file = io.open(finalPath .. "Main.lua", "w")
					file:write("require(\"GUI\").alert(\"Hello world\")")
					file:close()

					container:remove()
					checkIconConfigCanSavePosition(iconField, x, y, container.inputField.text .. ".app/")
					computer.pushSignal("MineOSCore", "updateFileList")
				end
			else
				container:remove()
				parentWindow:draw()
			end
		end
	end

	parentWindow:draw()
end

function MineOSInterface.newFolderFromChosen(parentWindow, iconField, x, y, selectedIcons)
	local container = addUniversalContainerWithInputTextBox(parentWindow, nil, MineOSCore.localization.newFolderFromChosen .. " (" .. #selectedIcons .. ")", MineOSCore.localization.folderName)

	container.inputField.onInputFinished = function()
		local path = fs.path(selectedIcons[1].path) .. container.inputField.text
		if checkFileToExists(container, path) then
			fs.makeDirectory(path)
			for i = 1, #selectedIcons do
				fs.rename(selectedIcons[i].path, path .. "/" .. selectedIcons[i].name)
			end

			checkIconConfigCanSavePosition(iconField, x, y, container.inputField.text)
			computer.pushSignal("MineOSCore", "updateFileList")
		end
	end

	parentWindow:draw()

	return container
end

function MineOSInterface.rename(parentWindow, path)
	local container = addUniversalContainerWithInputTextBox(parentWindow, fs.name(path), MineOSCore.localization.rename, MineOSCore.localization.newName)

	container.inputField.onInputFinished = function()
		if checkFileToExists(container, fs.path(path) .. container.inputField.text) then
			fs.rename(path, fs.path(path) .. container.inputField.text)
			computer.pushSignal("MineOSCore", "updateFileList")
		end
	end

	parentWindow:draw()
end

function MineOSInterface.editShortcut(parentWindow, path)
	local text = MineOSCore.readShortcut(path)
	local container = addUniversalContainerWithInputTextBox(parentWindow, text, MineOSCore.localization.editShortcut, MineOSCore.localization.rename)

	container.inputField.onInputFinished = function()
		if fs.exists(container.inputField.text) then
			MineOSCore.createShortcut(path, container.inputField.text)
			container:remove()
			computer.pushSignal("MineOSCore", "updateFileList")
		else
			container.label.text = MineOSCore.localization.shortcutIsCorrupted
			container.label.hidden = false
			MineOSInterface.application:draw()
		end
	end

	parentWindow:draw()
end

function MineOSInterface.launchWithArguments(parentWindow, path, withTerminal)
	local container = addUniversalContainerWithInputTextBox(parentWindow, nil, MineOSCore.localization.launchWithArguments)

	container.panel.eventHandler = function(application, object, e1)
		if e1 == "touch" then
			local args = {}
			if container.inputField.text then
				for arg in container.inputField.text:gmatch("[^%s]+") do
					table.insert(args, arg)
				end
			end

			container:remove()

			if withTerminal then
				MineOSInterface.clearTerminal()
				if MineOSInterface.safeLaunch(path, table.unpack(args)) then
					MineOSInterface.waitForPressingAnyKey()
				end
			else
				MineOSInterface.safeLaunch(path, table.unpack(args))
			end

			parentWindow:draw(true)
		end
	end
end

----------------------------------------- Windows patterns -----------------------------------------

function MineOSInterface.updateMenu()
	local focusedWindow = MineOSInterface.application.windowsContainer.children[#MineOSInterface.application.windowsContainer.children]
	MineOSInterface.application.menu.children = focusedWindow and focusedWindow.menu.children or MineOSInterface.menuInitialChildren
end

function MineOSInterface.addWindow(window, preserveCoordinates)
	-- Чекаем коорды
	if not preserveCoordinates then
		window.x, window.y = math.floor(MineOSInterface.application.windowsContainer.width / 2 - window.width / 2), math.floor(MineOSInterface.application.windowsContainer.height / 2 - window.height / 2)
	end
	
	-- Ебурим окно к окнам
	MineOSInterface.application.windowsContainer:addChild(window)
	
	-- Получаем путь залупы
	local dockPath, info, dockIcon
	for i = 0, math.huge do
		info = debug.getinfo(i)
		if info then
			if info.source then
				dockPath = info.source:match("=(.+%.app/)Main%.lua$")
				if dockPath then
					break
				end
			end
		else
			break
		end
	end

	dockPath = (dockPath or "/bin/OS.lua"):gsub("/+", "/")

	-- GUI.alert(dockPath)
	
	-- Чекаем наличие иконки в доке с таким же путем, и еси ее нет, то хуячим новую
	for i = 1, #MineOSInterface.application.dockContainer.children do
		if MineOSInterface.application.dockContainer.children[i].path == dockPath then
			dockIcon = MineOSInterface.application.dockContainer.children[i]
			break
		end
	end
	if not dockIcon then
		dockIcon = MineOSInterface.application.dockContainer.addIcon(dockPath, window)
	end
	
	-- Ебурим ссылку на окна в иконку
	dockIcon.windows = dockIcon.windows or {}
	dockIcon.windows[window] = true

	-- Взалупливаем иконке индивидуальную менюху. По дефолту тут всякая хуйня и прочее
	window.menu = GUI.menu(1, 1, 1)
	window.menu.colors = MineOSInterface.application.menu.colors
	local name = fs.hideExtension(fs.name(dockPath))
	local contextMenu = window.menu:addContextMenu(name, 0x0)
	contextMenu:addItem(MineOSCore.localization.closeWindow .. " " .. name, false, "^W").onTouch = function()
		window:close()
	end

	-- Смещаем окно правее и ниже, если уже есть открытые окна этой софтины
	local lastIndex
	for i = #MineOSInterface.application.windowsContainer.children, 1, -1 do
		if MineOSInterface.application.windowsContainer.children[i] ~= window and dockIcon.windows[MineOSInterface.application.windowsContainer.children[i]] then
			lastIndex = i
			break
		end
	end
	if lastIndex then
		window.localX, window.localY = MineOSInterface.application.windowsContainer.children[lastIndex].localX + 4, MineOSInterface.application.windowsContainer.children[lastIndex].localY + 2
	end

	-- Когда окно фокусицца, то главная ОСевая менюха заполницца ДЕТИШЕЧКАМИ оконной менюхи
	window.onFocus = MineOSInterface.updateMenu
	
	-- Биндим функции по ресайзу/закрытию и прочему говнищу
	window.close = function(window)
		local sameIconExists = false
		for i = 1, #MineOSInterface.application.dockContainer.children do
			if 
				MineOSInterface.application.dockContainer.children[i].path == dockPath and
				MineOSInterface.application.dockContainer.children[i].windows and
				table.size(MineOSInterface.application.dockContainer.children[i].windows) > 1
			then
				MineOSInterface.application.dockContainer.children[i].windows[window] = nil
				sameIconExists = true
				break
			end
		end

		if not sameIconExists then
			dockIcon.windows = nil
			if not dockIcon.keepInDock then
				dockIcon:remove()
				MineOSInterface.application.dockContainer.sort()
			end
		end
		
		window:remove()
		MineOSInterface.updateMenu()
	end

	-- Кнопочкам тоже эту хуйню пихаем
	if window.actionButtons then
		window.actionButtons.close.onTouch = function()
			window.close(window)
		end
		window.actionButtons.maximize.onTouch = function()
			window.maximize(window)
		end
		window.actionButtons.minimize.onTouch = function()
			window.minimize(window)
		end
	end

	MineOSInterface.updateMenu()

	return MineOSInterface.application, window, window.menu
end

-----------------------------------------------------------------------------------------------------------------------------------

local function addKeyAndValue(window, x, y, key, value)
	x = x + window:addChild(GUI.label(x, y, unicode.len(key) + 1, 1, 0x333333, key .. ":")).width + 1
	return window:addChild(GUI.label(x, y, unicode.len(value), 1, 0x555555, value))
end

function MineOSInterface.propertiesWindow(x, y, width, icon)
	local application, window = MineOSInterface.addWindow(GUI.titledWindow(x, y, width, 1, package.loaded.MineOSCore.localization.properties))

	window.backgroundPanel.colors.transparency = 0.2
	window:addChild(GUI.image(2, 3, icon.image))

	local x, y = 11, 3
	addKeyAndValue(window, x, y, package.loaded.MineOSCore.localization.type, icon.extension and icon.extension or (icon.isDirectory and package.loaded.MineOSCore.localization.folder or package.loaded.MineOSCore.localization.unknown)); y = y + 1
	local fileSizeLabel = addKeyAndValue(window, x, y, package.loaded.MineOSCore.localization.size, icon.isDirectory and package.loaded.MineOSCore.localization.calculatingSize or string.format("%.2f", fs.size(icon.path) / 1024) .. " KB"); y = y + 1
	addKeyAndValue(window, x, y, package.loaded.MineOSCore.localization.date, os.date("%d.%m.%y, %H:%M", math.floor(fs.lastModified(icon.path) / 1000))); y = y + 1
	addKeyAndValue(window, x, y, package.loaded.MineOSCore.localization.path, " ")

	local textBox = window:addChild(GUI.textBox(17, y, window.width - 18, 1, nil, 0x555555, {icon.path}, 1, 0, 0, true, true))
	textBox.eventHandler = nil

	window.actionButtons.minimize:remove()
	window.actionButtons.maximize:remove()

	window.height = textBox.y + textBox.height
	window.backgroundPanel.width = window.width
	window.backgroundPanel.height = textBox.y + textBox.height

	application:draw()

	if icon.isDirectory then
		fileSizeLabel.text = string.format("%.2f", fs.directorySize(icon.path) / 1024) .. " KB"
		application:draw()
	end
end

-----------------------------------------------------------------------------------------------------------------------------------

local function GUICopy(application, fileList, toPath)
	local applyYes, breakRecursion

	local container = MineOSInterface.addBackgroundContainer(application, MineOSCore.localization.copying)
	local textBox = container.layout:addChild(GUI.textBox(1, 1, container.width, 1, nil, 0x787878, {}, 1, 0, 0, true, true):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP))
	local switchAndLabel = container.layout:addChild(GUI.switchAndLabel(1, 1, 37, 8, 0x66DB80, 0x1E1E1E, 0xE1E1E1, 0x787878, MineOSCore.localization.applyToAll .. ":", false))
	container.panel.eventHandler = nil

	local buttonsLayout = container.layout:addChild(GUI.layout(1, 1, 1, 1, 1, 1))
	buttonsLayout:setDirection(1, 1, GUI.DIRECTION_HORIZONTAL)
	buttonsLayout:setSpacing(1, 1, 2)

	buttonsLayout:addChild(GUI.button(1, 1, 11, 1, 0xE1E1E1, 0x2D2D2D, 0xA5A5A5, 0x2D2D2D, MineOSCore.localization.yes)).onTouch = function()
		applyYes = true
		application:stop()
	end
	buttonsLayout:addChild(GUI.button(1, 1, 11, 1, 0xE1E1E1, 0x2D2D2D, 0xA5A5A5, 0x2D2D2D, MineOSCore.localization.no)).onTouch = function()
		application:stop()
	end
	buttonsLayout:addChild(GUI.button(1, 1, 11, 1, 0xE1E1E1, 0x2D2D2D, 0xA5A5A5, 0x2D2D2D, MineOSCore.localization.cancel)).onTouch = function()
		breakRecursion = true
		application:stop()
	end

	buttonsLayout:fitToChildrenSize(1, 1)

	local function copyOrMove(path, finalPath)
		switchAndLabel.hidden = true
		buttonsLayout.hidden = true

		textBox.lines = {
			MineOSCore.localization.copying .. " " .. MineOSCore.localization.faylaBlyad .. " " .. fs.name(path) .. " " .. MineOSCore.localization.toDirectory .. " " .. string.canonicalPath(toPath),
		}
		textBox:update()

		application:draw()

		fs.remove(finalPath)
		fs.copy(path, finalPath)
	end

	local function recursiveCopy(path, toPath)
		local finalPath = toPath .. "/" .. fs.name(path)

		if fs.isDirectory(path) then
			fs.makeDirectory(finalPath)

			for file in fs.list(path) do
				if breakRecursion then
					return
				end
				recursiveCopy(path .. "/" .. file, finalPath)
			end
		else
			if fs.exists(finalPath) then
				if not switchAndLabel.switch.state then
					switchAndLabel.hidden = false
					buttonsLayout.hidden = false
					applyYes = false

					textBox.lines = {
						MineOSCore.localization.file .. " " .. fs.name(path) .. " " .. MineOSCore.localization.alreadyExists .. " " ..  MineOSCore.localization.inDirectory .. " " .. string.canonicalPath(toPath),
						MineOSCore.localization.needReplace,
					}
					textBox:update()

					application:draw()
					application:start()
					application:draw()
				end

				if applyYes then
					copyOrMove(path, finalPath)
				end
			else
				copyOrMove(path, finalPath)
			end
		end
	end

	for i = 1, #fileList do
		recursiveCopy(fileList[i], toPath)
	end

	container:remove()
	application:draw()
end

function MineOSInterface.copy(what, toPath)
	if type(what) == "string" then
		what = {what}
	end

	GUICopy(MineOSInterface.application, what, toPath)
end

local function menuWidgetEventHandler(application, object, e1, ...)
	if e1 == "touch" and object.onTouch then
		object.selected = true
		MineOSInterface.application:draw()

		object.onTouch(application, object, e1, ...)

		object.selected = false
		MineOSInterface.application:draw()
	end
end

local function menuWidgetDraw(object)
	if object.selected then
		object.textColor = 0xFFFFFF
		buffer.drawRectangle(object.x - 1, object.y, object.width + 2, 1, 0x3366CC, object.textColor, " ")
	else
		object.textColor = 0x0
	end

	object.drawContent(object)
end

function MineOSInterface.menuWidget(width)
	local object = GUI.object(1, 1, width, 1)
	
	object.selected = false
	object.eventHandler = menuWidgetEventHandler
	object.draw = menuWidgetDraw

	return object
end

function MineOSInterface.addMenuWidget(object)
	MineOSInterface.application.menuLayout:addChild(object)
	object:moveToBack()

	return object
end

-----------------------------------------------------------------------------------------------------------------------------------

function MineOSInterface.showErrorWindow(path, line, traceback)
	local application = GUI.application(1, 1, buffer.getWidth(), math.floor(buffer.getHeight() * 0.5))
	application.y = math.floor(buffer.getHeight() / 2 - application.height / 2)
	
	application:addChild(GUI.panel(1, 1, application.width, 3, 0x383838))
	application:addChild(GUI.label(1, 2, application.width, 1, 0xFFFFFF, MineOSCore.localization.errorWhileRunningProgram .. "\"" .. fs.name(path) .. "\"")):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
	local actionButtons = application:addChild(GUI.actionButtons(2, 2, false))
	local sendToDeveloperButton = application:addChild(GUI.adaptiveButton(9, 1, 2, 1, 0x444444, 0xFFFFFF, 0x343434, 0xFFFFFF, MineOSCore.localization.sendFeedback))

	local codeView = application:addChild(GUI.codeView(1, 4, math.floor(application.width * 0.62), application.height - 3, 1, 1, 100, {}, {[line] = 0xFF4444}, GUI.LUA_SYNTAX_PATTERNS, GUI.LUA_SYNTAX_COLOR_SCHEME, true, {}))
	
	codeView.fromLine = line - math.floor((application.height - 3) / 2) + 1
	if codeView.fromLine <= 0 then
		codeView.fromLine = 1
	end
	local toLine, lineCounter = codeView.fromLine + codeView.height - 1, 1
	
	for line in io.lines(path) do
		if lineCounter >= codeView.fromLine and lineCounter <= toLine then
			codeView.lines[lineCounter] = string.gsub(line, "	", "  ")
		elseif lineCounter < codeView.fromLine then
			codeView.lines[lineCounter] = " "
		elseif lineCounter > toLine then
			break
		end
		lineCounter = lineCounter + 1
		if lineCounter % 200 == 0 then
			computer.pullSignal(0)
		end
	end

	application:addChild(GUI.textBox(codeView.width + 1, 4, application.width - codeView.width, codeView.height, 0xFFFFFF, 0x0, string.wrap(MineOSCore.parseErrorMessage(traceback, 4), application.width - codeView.width - 2), 1, 1, 0))
	
	actionButtons.close.onTouch = function()
		application:stop()
	end

	application.eventHandler = function(application, object, e1, e2, e3, e4)
		if e1 == "key_down" and e4 == 28 then
			actionButtons.close.onTouch()
		end
	end

	sendToDeveloperButton.onTouch = function()
		if component.isAvailable("internet") then
			local url = "https://api.mcmodder.ru/ECS/report.php?path=" .. path .. "&errorMessage=" .. string.optimizeForURLRequests(traceback)
			local success, reason = component.internet.request(url)
			if success then
				success:close()
			end

			sendToDeveloperButton.text = MineOSCore.localization.sendedFeedback
			application:draw()
			os.sleep(1)
		end

		actionButtons.close.onTouch()
	end

	buffer.clear(0x0, 0.5)
	application:draw()

	for i = 1, 3 do
		component.computer.beep(1500, 0.08)
	end

	application:start()
end

function MineOSInterface.safeLaunch(...)
	local success, path, line, traceback = MineOSCore.safeLaunch(...)
	if not success then
		MineOSInterface.showErrorWindow(path, line, traceback)
	end

	return success, path, line, traceback
end

-----------------------------------------------------------------------------------------------------------------------------------

local overrideGUIDropDownMenu = GUI.dropDownMenu
function MineOSInterface.updateColorScheme()
	GUI.dropDownMenu = function(...)
		local menu = overrideGUIDropDownMenu(...)
		
		menu.colors.transparency.background = MineOSCore.properties.transparencyEnabled and GUI.CONTEXT_MENU_BACKGROUND_TRANSPARENCY
		menu.colors.transparency.shadow = MineOSCore.properties.transparencyEnabled and GUI.CONTEXT_MENU_SHADOW_TRANSPARENCY

		return menu
	end
end

MineOSInterface.updateColorScheme()

MineOSInterface.cacheIconSource("folder", MineOSPaths.icons .. "Folder.pic")
MineOSInterface.cacheIconSource("fileNotExists", MineOSPaths.icons .. "FileNotExists.pic")
MineOSInterface.cacheIconSource("application", MineOSPaths.icons .. "Application.pic")
MineOSInterface.cacheIconSource("trash", MineOSPaths.icons .. "Trash.pic")
MineOSInterface.cacheIconSource("script", MineOSPaths.icons .. "Script.pic")

-----------------------------------------------------------------------------------------------------------------------------------

return MineOSInterface
	