
---------------------------------------------- Libraries ------------------------------------------------------------------------

local component = require("component")
local computer = require("computer")
local event = require("event")
local advancedLua = require("advancedLua")
local image = require("image")
local buffer = require("doubleBuffering")
local GUI = require("GUI")
local fs = require("filesystem")
local unicode = require("unicode")
local keyboard = require("keyboard")

----------------------------------------------------------------------------------------------------------------

local MineOSCore = {}
MineOSCore.iconWidth = 12
MineOSCore.iconHeight = 6
MineOSCore.selectionIconPart = 0.4
MineOSCore.iconClickDelay = 0.2
MineOSCore.iconConfigFileName = "/.icons"

MineOSCore.paths = {}
MineOSCore.paths.OS = "/MineOS/"
MineOSCore.paths.system = MineOSCore.paths.OS .. "System/"
MineOSCore.paths.extensionAssociations = MineOSCore.paths.system .. "ExtensionAssociations/"
MineOSCore.paths.localizationFiles = MineOSCore.paths.system .. "Localization/"
MineOSCore.paths.icons = MineOSCore.paths.system .. "Icons/"
MineOSCore.paths.applications = MineOSCore.paths.OS .. "Applications/"
MineOSCore.paths.pictures = MineOSCore.paths.OS .. "Pictures/"
MineOSCore.paths.desktop = MineOSCore.paths.OS .. "Desktop/"
MineOSCore.paths.applicationList = MineOSCore.paths.system .. "Applications.cfg"
MineOSCore.paths.trash = MineOSCore.paths.OS .. "Trash/"
MineOSCore.paths.OSSettings = MineOSCore.paths.system .. "Settings.cfg"
MineOSCore.paths.editor = MineOSCore.paths.applications .. "/MineCode IDE.app/Main.lua"

MineOSCore.localization = {}

----------------------------------------------------------------------------------------------------------------

function MineOSCore.getCurrentScriptDirectory()
	return fs.path(getCurrentScript())
end

function MineOSCore.getCurrentApplicationResourcesDirectory() 
	return MineOSCore.getCurrentScriptDirectory() .. "/Resources/"
end

function MineOSCore.getLocalization(pathToLocalizationFolder)
	local localizationFileName = pathToLocalizationFolder .. MineOSCore.OSSettings.language .. ".lang"
	if fs.exists(localizationFileName) then
		return table.fromFile(localizationFileName)
	else
		error("Localization file \"" .. localizationFileName .. "\" doesn't exists")
	end
end

function MineOSCore.getCurrentApplicationLocalization()
	return MineOSCore.getLocalization(MineOSCore.getCurrentApplicationResourcesDirectory() .. "Localization/")	
end

-----------------------------------------------------------------------------------------------------------------------------------

function MineOSCore.createShortcut(where, forWhat)
	fs.makeDirectory(fs.path(where))
	local file = io.open(where, "w")
	file:write(forWhat)
	file:close()
end

function MineOSCore.readShortcut(path)
	local file = io.open(path, "r")
	local data = file:read("*a")
	file:close()
	
	return data
end

-----------------------------------------------------------------------------------------------------------------------------------

function MineOSCore.saveOSSettings()
	table.toFile(MineOSCore.paths.OSSettings, MineOSCore.OSSettings, true)
end

function MineOSCore.loadOSSettings()
	MineOSCore.OSSettings = table.fromFile(MineOSCore.paths.OSSettings)
end

-----------------------------------------------------------------------------------------------------------------------------------

function MineOSCore.associateExtensionLauncher(extension, pathToLauncher)
	MineOSCore.OSSettings.extensionAssociations[extension] = MineOSCore.OSSettings.extensionAssociations[extension] or {}
	MineOSCore.OSSettings.extensionAssociations[extension].launcher = pathToLauncher
end

function MineOSCore.associateExtensionIcon(extension, pathToIcon)
	MineOSCore.OSSettings.extensionAssociations[extension] = MineOSCore.OSSettings.extensionAssociations[extension] or {}
	MineOSCore.OSSettings.extensionAssociations[extension].icon = pathToIcon
end

function MineOSCore.associateExtensionContextMenu(extension, pathToContextMenu)
	MineOSCore.OSSettings.extensionAssociations[extension] = MineOSCore.OSSettings.extensionAssociations[extension] or {}
	MineOSCore.OSSettings.extensionAssociations[extension].contextMenu = pathToContextMenu
end

function MineOSCore.associateExtension(extension, pathToLauncher, pathToIcon, pathToContextMenu)
	MineOSCore.associateExtensionLauncher(extension, pathToLauncher)
	MineOSCore.associateExtensionIcon(extension, pathToIcon)
	MineOSCore.associateExtensionContextMenu(extension, pathToContextMenu)
end

function MineOSCore.associationsExtensionAutomatically()
	local path, extension = MineOSCore.paths.extensionAssociations
	for file in fs.list(path) do
		if fs.isDirectory(path .. file) then
			extension = "." .. unicode.sub(file, 1, -2)

			if fs.exists(path .. file .. "Context menu.lua") then
				MineOSCore.associateExtensionContextMenu(extension, path .. file .. "Context menu.lua")
			end

			if fs.exists(path .. file .. "Launcher.lua") then
				MineOSCore.associateExtensionLauncher(extension, path .. file .. "Launcher.lua")
			end
		end
	end
end

-----------------------------------------------------------------------------------------------------------------------------------

function MineOSCore.loadIcon(name, path)
	if not MineOSCore.icons[name] then MineOSCore.icons[name] = image.load(path) end
	return MineOSCore.icons[name]
end

-----------------------------------------------------------------------------------------------------------------------------------

function MineOSCore.clearTerminal()
	local gpu = component.gpu
	gpu.setBackground(0x1D1D1D)
	gpu.setForeground(0xFFFFFF)
	local width, height = gpu.getResolution()
	gpu.fill(1, 1, width, height, " ")
	require("term").setCursor(1, 1)
end

function MineOSCore.waitForPressingAnyKey()
	print(" ")
	print(MineOSCore.localization.pressAnyKeyToContinue)
	while true do
		local eventType = event.pull()
		if eventType == "key_down" or eventType == "touch" then
			break
		end
	end
end

function MineOSCore.launchScript(path)
	MineOSCore.clearTerminal()
	if MineOSCore.safeLaunch(path) then
		MineOSCore.waitForPressingAnyKey()
	end
end

-----------------------------------------------------------------------------------------------------------------------------------

local function launchApp(icon)
	computer.pushSignal("MineOSCore", "applicationHelp", icon.path)
end

local function launchDirectory(icon)
	computer.pushSignal("MineOSCore", "changeWorkpath", icon.path)
end

local function launchLnk(icon)
	local oldPath = icon.path
	icon.path = icon.shortcutPath
	icon:shortcutLaunch()
	icon.path = oldPath
end

local function launchCorrupted(icon)
	GUI.error("Application is corrupted")
end

local function launchExtension(icon)
	MineOSCore.safeLaunch(MineOSCore.OSSettings.extensionAssociations[icon.extension].launcher, icon.path, "-o")
end

local function launchScript(icon)
	MineOSCore.launchScript(icon.path)
end

function MineOSCore.analyzeIconExtension(icon)
	if icon.isDirectory then
		if icon.extension == ".app" then
			if MineOSCore.OSSettings.showApplicationIcons then
				icon.image = image.load(icon.path .. "/Resources/Icon.pic")
			else
				icon.image = MineOSCore.icons.application
			end

			icon.launch = launchApp
		else
			icon.image = MineOSCore.icons.folder
			icon.launch = launchDirectory
		end
	else
		if icon.extension == ".lnk" then
			icon.shortcutPath = MineOSCore.readShortcut(icon.path)
			icon.shortcutExtension = fs.extension(icon.shortcutPath)
			icon.shortcutIsDirectory = fs.isDirectory(icon.shortcutPath)
			icon.isShortcut = true

			local shortcutIcon = MineOSCore.analyzeIconExtension({
				path = icon.shortcutPath,
				extension = icon.shortcutExtension,
				isDirectory = icon.shortcutIsDirectory,
				iconImage = icon.iconImage
			})

			icon.image = shortcutIcon.image
			icon.shortcutLaunch = shortcutIcon.launch
			icon.launch = launchLnk

			shortcutIcon = nil
		elseif not fs.exists(icon.path) then
			icon.image = MineOSCore.icons.fileNotExists
			icon.launch = launchCorrupted
		else
			if MineOSCore.OSSettings.extensionAssociations[icon.extension] then
				icon.launch = launchExtension
				icon.image = MineOSCore.loadIcon(icon.extension, MineOSCore.OSSettings.extensionAssociations[icon.extension].icon)
			else
				icon.launch = launchScript
				icon.image = MineOSCore.icons.script
			end
		end
	end

	return icon
end

local function iconDraw(icon)
	if icon.selected then
		buffer.square(icon.x, icon.y, icon.width, icon.height, icon.colors.selection, 0x000000, " ", 60)
	end

	if icon.cut then
		if not icon.semiTransparentImage then
			icon.semiTransparentImage = image.copy(icon.image)
			for i = 3, #icon.semiTransparentImage, 4 do
				icon.semiTransparentImage[i + 2] = icon.semiTransparentImage[i + 2] + 0.6
				if icon.semiTransparentImage[i + 2] > 1 then
					icon.semiTransparentImage[i + 2] = 1
				end
			end
		end
		
		buffer.image(icon.x + 2, icon.y, icon.semiTransparentImage, true)
	else
		buffer.image(icon.x + 2, icon.y, icon.image)
	end

	local text
	if icon.showExtension then
		text = string.limit(fs.name(icon.path), icon.width, "center")
	else
		text = string.limit(fs.hideExtension(fs.name(icon.path)), icon.width, "center")
	end
	
	buffer.text(math.floor(icon.x + icon.width / 2 - unicode.len(text) / 2), icon.y + icon.height - 1, icon.colors.text, text)

	if icon.isShortcut then
		buffer.set(icon.x + 9, icon.y + 3, 0xFFFFFF, 0x000000, "<")
	end

	if icon.window then
		buffer.text(icon.x + 5, icon.y + 4, 0x66DBFF, "╺╸")
	end
end

local function iconEventHandler(mainContainer, object, eventData)
	if eventData[1] == "touch" then
		object.lastTouchPosition = object.lastTouchPosition or {}
		object.lastTouchPosition.x, object.lastTouchPosition.y = eventData[3], eventData[4]
		object:moveToFront()

		object.selected = true
		MineOSCore.OSDraw()

		if eventData[5] == 0 then
			object.onLeftClick(object, eventData)
		else
			object.onRightClick(object, eventData)
			object.selected = false
			MineOSCore.OSDraw()
		end
	elseif eventData[1] == "double_touch" and object:isClicked(eventData[3], eventData[4]) and eventData[5] == 0 then
		object.onDoubleClick(object, eventData)
	elseif eventData[1] == "drag" and object.lastTouchPosition then
		object.localPosition.x = object.localPosition.x + eventData[3] - object.lastTouchPosition.x
		object.localPosition.y = object.localPosition.y + eventData[4] - object.lastTouchPosition.y
		object.lastTouchPosition.x, object.lastTouchPosition.y = eventData[3], eventData[4]

		MineOSCore.OSDraw()
	elseif eventData[1] == "drop" then
		-- Сейвим позицию иконки на дисочек. Юзаем ручной поиск вместо :indexOf(), ибо
		-- иконки из-за перемещения вперед могут иметь отличный от файллиста индекс
		for i = 1, #object.parent.parent.fileList do
			if object.parent.parent.workpath .. object.parent.parent.fileList[i] == object.path then
				object.parent.parent.iconConfig[object.parent.parent.fileList[i]] = {
					x = object.localPosition.x,
					y = object.localPosition.y
				}
				object.parent.parent:saveIconConfig()
				break
			end
		end
	end
end

function MineOSCore.icon(x, y, path, textColor, selectionColor, showExtension)
	local icon = GUI.object(x, y, MineOSCore.iconWidth, MineOSCore.iconHeight)
	
	icon.colors = {
		text = textColor,
		selection = selectionColor,
	}
	icon.path = path
	icon.isDirectory = fs.isDirectory(icon.path)
	icon.extension = fs.extension(icon.path) or "script"
	icon.showExtension = showExtension
	icon.isShortcut = false
	icon.selected = false

	icon.draw = iconDraw

	-- Поддержка изменяемых извне функций правого и левого кликов
	icon.onLeftClick = MineOSCore.iconLeftClick
	icon.onRightClick = MineOSCore.iconRightClick
	icon.onDoubleClick = MineOSCore.iconDoubleClick
	icon.eventHandler = iconEventHandler

	-- Онализ формата и прочего говна иконки для последующего получения изображения иконки и функции-лаунчера
	MineOSCore.analyzeIconExtension(icon)
	
	return icon
end

local function iconFieldUpdate(iconField)
	iconField.backgroundObject.width, iconField.backgroundObject.height = iconField.width, iconField.height
	iconField.foregroundObject.width, iconField.foregroundObject.height = iconField.width, iconField.height
	iconField.iconsContainer.width, iconField.iconsContainer.height = iconField.width, iconField.height

	iconField.iconCount.horizontal = math.floor(iconField.width / (MineOSCore.iconWidth + iconField.spaceBetweenIcons.horizontal))
	iconField.iconCount.vertical = math.floor(iconField.height / (MineOSCore.iconHeight + iconField.spaceBetweenIcons.vertical))
	iconField.iconCount.total = iconField.iconCount.horizontal * iconField.iconCount.vertical

	return iconField
end

local function iconFieldLoadIconConfig(iconField)
	if fs.exists(iconField.workpath .. MineOSCore.iconConfigFileName) then
		iconField.iconConfig = table.fromFile(iconField.workpath .. MineOSCore.iconConfigFileName)

		-- Чистим конфиг от файлов, которых более нет в иконфилде
		local iconConfigItemExistsInFileList
		for key in pairs(iconField.iconConfig) do
			local iconConfigItemExistsInFileList = false
			for i = 1, #iconField.fileList do
				if key == iconField.fileList[i] then
					iconConfigItemExistsInFileList = true
					break
				end
			end

			if not iconConfigItemExistsInFileList then
				iconField.iconConfig[key] = nil
			end
		end

		iconField:saveIconConfig()
	else
		iconField.iconConfig = {}
	end
end

local function iconFieldSaveIconConfig(iconField)
	table.toFile(iconField.workpath .. MineOSCore.iconConfigFileName, iconField.iconConfig)
end

local function iconFieldUpdateFileList(iconField)
	-- Обновление файлового списка
	iconField.fileList = fs.sortedList(iconField.workpath, iconField.sortingMethod, iconField.showHiddenFiles)
	-- Грузим инфу об иконочках
	iconField:loadIconConfig()
	-- Подсчет числа влезаемых иконочек
	iconField:update()
	-- Заполнение дочернего контейнера
	iconField.iconsContainer:deleteChildren()
	local xPos, yPos, horizontalIconCounter = 1, 1, 1
	for i = iconField.fromFile, iconField.fromFile + iconField.iconCount.total - 1 do
		if iconField.fileList[i] then
			local xIcon, yIcon = xPos, yPos
			if iconField.iconConfig[iconField.fileList[i]] then
				xIcon, yIcon = iconField.iconConfig[iconField.fileList[i]].x, iconField.iconConfig[iconField.fileList[i]].y
			else
				xPos, horizontalIconCounter = xPos + MineOSCore.iconWidth + iconField.spaceBetweenIcons.horizontal, horizontalIconCounter + 1
				if horizontalIconCounter > iconField.iconCount.horizontal then
					xPos, horizontalIconCounter = 1, 1
					yPos = yPos + MineOSCore.iconHeight + iconField.spaceBetweenIcons.vertical
				end
			end

			iconField.iconsContainer:addChild(
				MineOSCore.icon(
					xIcon, yIcon,
					iconField.workpath .. iconField.fileList[i],
					iconField.colors.text,
					iconField.colors.selection,
					iconField.showExtension
				)
			)
		else
			break
		end
	end

	return iconField
end

local function iconFieldBackgroundObjectEventHandler(mainContainer, object, eventData)
	if eventData[1] == "touch" then
		if eventData[5] == 0 then
			object.parent:deselectAll()
			object.parent.selection.firstReady, object.parent.selection.x1, object.parent.selection.y1 = true, eventData[3], eventData[4]
			MineOSCore.OSDraw()
		else
			local menu = MineOSCore.contextMenu(eventData[3], eventData[4])

			menu:addItem(MineOSCore.localization.newFile).onTouch = function()
				computer.pushSignal("MineOSCore", "newFile")
			end
			
			menu:addItem(MineOSCore.localization.newFolder).onTouch = function()
				computer.pushSignal("MineOSCore", "newFolder")
			end

			menu:addItem(MineOSCore.localization.newFileFromURL, not component.isAvailable("internet")).onTouch = function()
				computer.pushSignal("MineOSCore", "newFileFromURL")
			end

			menu:addItem(MineOSCore.localization.newApplication).onTouch = function()
				computer.pushSignal("MineOSCore", "newApplication")
			end

			menu:addSeparator()

			local subMenu = menu:addSubMenu(MineOSCore.localization.view)

			subMenu:addItem(MineOSCore.OSMainContainer.iconField.showExtension and MineOSCore.localization.hideExtension or MineOSCore.localization.showExtension).onTouch = function()
				MineOSCore.OSMainContainer.iconField.showExtension = not MineOSCore.OSMainContainer.iconField.showExtension
				MineOSCore.OSSettings.showExtension = MineOSCore.OSMainContainer.iconField.showExtension
				MineOSCore.saveOSSettings()
				computer.pushSignal("MineOSCore", "updateFileList")
			end

			subMenu:addItem(MineOSCore.OSMainContainer.iconField.showHiddenFiles and MineOSCore.localization.hideHiddenFiles or MineOSCore.localization.showHiddenFiles).onTouch = function()
				MineOSCore.OSMainContainer.iconField.showHiddenFiles = not MineOSCore.OSMainContainer.iconField.showHiddenFiles
				MineOSCore.OSSettings.showHiddenFiles = MineOSCore.OSMainContainer.iconField.showHiddenFiles
				MineOSCore.saveOSSettings()
				computer.pushSignal("MineOSCore", "updateFileList")
			end

			subMenu:addItem(MineOSCore.OSSettings.showApplicationIcons and MineOSCore.localization.hideApplicationIcons or MineOSCore.localization.showApplicationIcons).onTouch = function()
				MineOSCore.OSSettings.showApplicationIcons = not MineOSCore.OSSettings.showApplicationIcons
				MineOSCore.saveOSSettings()
				computer.pushSignal("MineOSCore", "updateFileList")
			end
			
			local subMenu = menu:addSubMenu(MineOSCore.localization.sortBy)
			subMenu:addItem(MineOSCore.localization.sortByName).onTouch = function()
				MineOSCore.OSSettings.sortingMethod = "name"
				MineOSCore.saveOSSettings()
				MineOSCore.OSMainContainer.iconField.sortingMethod = MineOSCore.OSSettings.sortingMethod
				computer.pushSignal("MineOSCore", "updateFileList")
			end

			menu:addItem(MineOSCore.localization.sortAutomatically).onTouch = function()
				object.parent.iconConfig = {}
				object.parent:saveIconConfig()
				computer.pushSignal("MineOSCore", "updateFileList")
			end

			subMenu:addItem(MineOSCore.localization.sortByDate).onTouch = function()
				MineOSCore.OSSettings.sortingMethod = "date"
				MineOSCore.saveOSSettings()
				MineOSCore.OSMainContainer.iconField.sortingMethod = MineOSCore.OSSettings.sortingMethod
				computer.pushSignal("MineOSCore", "updateFileList")
			end

			subMenu:addItem(MineOSCore.localization.sortByType).onTouch = function()
				MineOSCore.OSSettings.sortingMethod = "type"
				MineOSCore.saveOSSettings()
				MineOSCore.OSMainContainer.iconField.sortingMethod = MineOSCore.OSSettings.sortingMethod
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

				MineOSCore.copy(MineOSCore.clipboard, object.parent.workpath)

				if MineOSCore.clipboard.cut then
					for i = 1, #MineOSCore.clipboard do
						fs.remove(MineOSCore.clipboard[i])
					end
					MineOSCore.clipboard = nil
				end

				computer.pushSignal("MineOSCore", "updateFileList")
			end

			menu:show()
		end
	elseif eventData[1] == "drag" then
		object.parent.foregroundObject.hidden = false
		computer.pushSignal(table.unpack(eventData))
	end
end

local function iconFieldForegroundObjectEventHandler(mainContainer, object, eventData)
	if eventData[1] == "drag" then
		object.parent.selection.secondReady, object.parent.selection.x2, object.parent.selection.y2 = true, eventData[3], eventData[4]
		MineOSCore.OSDraw()
	elseif eventData[1] == "touch" or eventData[1] == "drop" then
		object.parent.selection.firstReady, object.parent.selection.secondReady = false, false
		object.parent.foregroundObject.hidden = true
		MineOSCore.OSDraw()
	end
end

local function iconFieldForegroundObjectDraw(object)
	if object.parent.selection.firstReady and object.parent.selection.secondReady then
		local x1, y1, x2, y2 = object.parent.selection.x1, object.parent.selection.y1, object.parent.selection.x2, object.parent.selection.y2

		if x2 < x1 then
			x1, x2 = x2, x1
		end

		if y2 < y1 then
			y1, y2 = y2, y1
		end

		local width, height = x2 - x1 + 1, y2 - y1 + 1
		buffer.square(x1, y1, width, height, 0xFFFFFF, 0x0, " ", 70)
		buffer.frame(x1, y1, width, height, 0xFFFFFF)

		local partialWidth, partialHeight = MineOSCore.iconWidth * MineOSCore.selectionIconPart, MineOSCore.iconHeight * MineOSCore.selectionIconPart
		for i = 1, #object.parent.iconsContainer.children do
			object.parent.iconsContainer.children[i].selected = 
				object.parent.iconsContainer.children[i].x + partialWidth >= x1 and
				object.parent.iconsContainer.children[i].x + object.parent.iconsContainer.children[i].width - 1 - partialWidth <= x2 and
				object.parent.iconsContainer.children[i].y + partialHeight >= y1 and
				object.parent.iconsContainer.children[i].y + object.parent.iconsContainer.children[i].height - 1 - partialHeight <= y2
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

function MineOSCore.iconField(x, y, width, height, xSpaceBetweenIcons, ySpaceBetweenIcons, textColor, selectionColor, showExtension, showHiddenFiles, sortingMethod, workpath)
	local iconField = GUI.container(x, y, width, height)

	iconField.colors = {
		text = textColor,
		selection = selectionColor
	}

	iconField.spaceBetweenIcons = {
		horizontal = xSpaceBetweenIcons,
		vertical = ySpaceBetweenIcons
	}

	iconField.iconConfig = {}
	iconField.selection = {}
	iconField.iconCount = {}
	iconField.fileList = {}
	iconField.fromFile = 1

	iconField.backgroundObject = iconField:addChild(GUI.object(1, 1, width, height))
	iconField.backgroundObject.eventHandler = iconFieldBackgroundObjectEventHandler

	iconField.iconsContainer = iconField:addChild(GUI.container(1, 1, width, height))

	iconField.foregroundObject = iconField:addChild(GUI.object(1, 1, width, height))
	iconField.foregroundObject.eventHandler = iconFieldForegroundObjectEventHandler
	iconField.foregroundObject.hidden = true
	iconField.foregroundObject.draw = iconFieldForegroundObjectDraw

	iconField.workpath = workpath
	iconField.showExtension = showExtension
	iconField.showHiddenFiles = showHiddenFiles
	iconField.sortingMethod = sortingMethod
	iconField.updateFileList = iconFieldUpdateFileList
	iconField.update = iconFieldUpdate
	iconField.eventHandler = iconFieldEventHandler
	iconField.deselectAll = iconFieldDeselectAll
	iconField.loadIconConfig = iconFieldLoadIconConfig
	iconField.saveIconConfig = iconFieldSaveIconConfig
	iconField.getSelectedIcons = iconFieldGetSelectedIcons

	return iconField
end

-----------------------------------------------------------------------------------------------------------------------------------

--Функция парсинга Lua-сообщения об ошибке. Конвертирует из строки в массив.
function MineOSCore.parseErrorMessage(error, indentationWidth)
	local parsedError = {}

	--Замена /r/n и табсов
	error = string.gsub(error, "\r\n", "\n")
	error = string.gsub(error, "	", string.rep(" ", indentationWidth or 4))

	--Удаление энтеров
	local searchFrom, starting, ending = 1
	for i = 1, unicode.len(error) do
		starting, ending = string.find(error, "\n", searchFrom)
		if starting then
			table.insert(parsedError, unicode.sub(error, searchFrom, starting - 1))
			searchFrom = ending + 1
		else
			break
		end
	end

	--На всякий случай, если сообщение об ошибке без энтеров вообще, т.е. однострочное
	if #parsedError == 0 then table.insert(parsedError, error) end

	return parsedError
end

function MineOSCore.showErrorWindow(path, errorLine, reason)
	buffer.clear(0x0, 50)

	local mainContainer = GUI.container(1, 1, buffer.width, math.floor(buffer.height * 0.45))
	mainContainer.y = math.floor(buffer.height / 2 - mainContainer.height / 2)
	
	mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, 3, 0x383838))
	mainContainer:addChild(GUI.label(1, 2, mainContainer.width, 1, 0xFFFFFF, MineOSCore.localization.errorWhileRunningProgram .. "\"" .. fs.name(path) .. "\"")):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	local actionButtons = mainContainer:addChild(GUI.actionButtons(2, 2, false))
	local sendToDeveloperButton = mainContainer:addChild(GUI.adaptiveButton(9, 1, 2, 1, 0x444444, 0xFFFFFF, 0x343434, 0xFFFFFF, MineOSCore.localization.sendFeedback))

	local codeView = mainContainer:addChild(GUI.codeView(1, 4, math.floor(mainContainer.width * 0.62), mainContainer.height - 3, {}, 1, 1, 100, {}, {[errorLine] = 0xFF4444}, true, 2))
	codeView.scrollBars.horizontal.hidden = true

	codeView.fromLine = errorLine - math.floor((mainContainer.height - 3) / 2) + 1
	if codeView.fromLine <= 0 then codeView.fromLine = 1 end
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
	end

	mainContainer:addChild(GUI.textBox(codeView.width + 1, 4, mainContainer.width - codeView.width, codeView.height, 0xFFFFFF, 0x000000, string.wrap(MineOSCore.parseErrorMessage(reason, 4), mainContainer.width - codeView.width - 2), 1, 1, 0))
	
	actionButtons.close.onTouch = function()
		mainContainer:stopEventHandling()
	end

	mainContainer.eventHandler = function(mainContainer, object, eventData)
		if eventData[1] == "key_down" and eventData[4] == 28 then
			actionButtons.close.onTouch()
		end
	end

	sendToDeveloperButton.onTouch = function()
		if component.isAvailable("internet") then
			local url = "https://api.mcmodder.ru/ECS/report.php?path=" .. path .. "&errorMessage=" .. string.optimizeForURLRequests(reason)
			local success, reason = component.internet.request(url)
			if success then
				success:close()
			end

			sendToDeveloperButton.text = MineOSCore.localization.sendedFeedback
			mainContainer:draw()
			buffer.draw()
			os.sleep(1)
		end
		actionButtons.close.onTouch()
	end

	mainContainer:draw()
	buffer.draw()
	for i = 1, 3 do
		component.computer.beep(1500, 0.08)
	end
	mainContainer:startEventHandling()
end

function MineOSCore.call(method, ...)
	local args = {...}
	local function launchMethod()
		method(table.unpack(args))
	end

	local function tracebackMethod(xpcallTraceback)
		local traceback, info, firstMatch = tostring(xpcallTraceback) .. "\n" .. debug.traceback()
		for runLevel = 0, math.huge do
			info = debug.getinfo(runLevel)
			if info then
				if (info.what == "main" or info.what == "Lua") and info.source ~= "=machine" then
					if firstMatch then
						return {
							path = info.source:sub(2, -1),
							line = info.currentline,
							traceback = traceback
						}
					else
						firstMatch = true
					end
				end
			else
				error("Failed to get debug info for runlevel " .. runLevel)
			end
		end
	end
	
	local xpcallSuccess, xpcallReason = xpcall(launchMethod, tracebackMethod)
	if type(xpcallReason) == "string" or type(xpcallReason) == "nil" then xpcallReason = {path = "/lib/MineOSCore.lua", line = 1, traceback = "MineOSCore fatal error: " .. tostring(xpcallReason)} end
	if not xpcallSuccess and not xpcallReason.traceback:match("^table") and not xpcallReason.traceback:match("interrupted") then
		return false, xpcallReason.path, xpcallReason.line, xpcallReason.traceback
	end

	return true
end

function MineOSCore.safeLaunch(path, ...)
	local oldResolutionWidth, oldResolutionHeight = buffer.width, buffer.height
	local finalSuccess, finalPath, finalLine, finalTraceback = true
	
	if fs.exists(path) then
		local loadSuccess, loadReason = loadfile("/" .. path)
		if loadSuccess then
			local success, path, line, traceback = MineOSCore.call(loadSuccess, ...)
			if not success then
				finalSuccess, finalPath, finalLine, finalTraceback = false, path, line, traceback
			end
		else
			local match = string.match(loadReason, ":(%d+)%:")
			finalSuccess, finalPath, finalLine, finalTraceback = false, path, tonumber(match) or 1, loadReason
		end
	else
		GUI.error("Failed to safely launch file that doesn't exists: \"" .. path .. "\"")
	end

	component.screen.setPrecise(false)
	buffer.setResolution(oldResolutionWidth, oldResolutionHeight)

	if not finalSuccess then
		MineOSCore.showErrorWindow(finalPath, finalLine, finalTraceback)
	end

	return finalSuccess, finalPath, finalLine, finalTraceback
end

-----------------------------------------------------------------------------------------------------------------------------------

function MineOSCore.contextMenu(...)
	local menu = GUI.contextMenu(...)
	
	menu.colors.transparency.background = MineOSCore.OSSettings.transparencyEnabled and GUI.colors.contextMenu.transparency.background
	menu.colors.transparency.shadow = MineOSCore.OSSettings.transparencyEnabled and GUI.colors.contextMenu.transparency.shadow

	return menu
end

function MineOSCore.iconLeftClick(icon, eventData)
	if not keyboard.isKeyDown(29) and not keyboard.isKeyDown(219) then
		icon.parent.parent:deselectAll()
	end
	icon.selected = true

	MineOSCore.OSDraw()
end

function MineOSCore.iconDoubleClick(icon, eventData)
	MineOSCore.lastLaunchPath = icon.path
	icon:launch()
	computer.pushSignal("MineOSCore", "updateFileList")
end

function MineOSCore.iconRightClick(icon, eventData)
	icon.selected = true
	MineOSCore.OSDraw()

	local selectedIcons = icon.parent.parent:getSelectedIcons()

	local menu = MineOSCore.contextMenu(eventData[3], eventData[4])
	if #selectedIcons == 1 then
		if icon.isDirectory then
			if icon.extension == ".app" then
				menu:addItem(MineOSCore.localization.showPackageContent).onTouch = function()
					computer.pushSignal("MineOSCore", "changeWorkpath", icon.path)
					computer.pushSignal("MineOSCore", "updateFileList")
				end		
				menu:addItem(MineOSCore.localization.launchWithArguments).onTouch = function()
					MineOSCore.launchWithArguments(MineOSCore.OSMainContainer, icon.path)
				end
			end

			menu:addItem(MineOSCore.localization.archive).onTouch = function()
				require("compressor").pack(fs.path(icon.path) .. fs.hideExtension(fs.name(icon.path)) .. ".pkg", icon.path)
				computer.pushSignal("MineOSCore", "updateFileList")
			end
			
			menu:addSeparator()
		else
			if icon.isShortcut then
				menu:addItem(MineOSCore.localization.editShortcut).onTouch = function()
					MineOSCore.editShortcut(MineOSCore.OSMainContainer, icon.path)
					computer.pushSignal("MineOSCore", "updateFileList")
				end

				menu:addItem(MineOSCore.localization.showContainingFolder).onTouch = function()
					computer.pushSignal("MineOSCore", "changeWorkpath", fs.path(icon.shortcutPath))
					computer.pushSignal("MineOSCore", "updateFileList")
				end

				menu:addSeparator()
			else
				if MineOSCore.OSSettings.extensionAssociations[icon.extension] and MineOSCore.OSSettings.extensionAssociations[icon.extension].contextMenu then
					pcall(loadfile(MineOSCore.OSSettings.extensionAssociations[icon.extension].contextMenu), icon, menu)
					menu:addSeparator()
				end

				-- local subMenu = menu:addSubMenu(MineOSCore.localization.openWith)
				-- local fileList = fs.sortedList(MineOSCore.paths.applications, "name")
				-- subMenu:addItem(MineOSCore.localization.select)
				-- subMenu:addSeparator()
				-- for i = 1, #fileList do
				-- 	subMenu:addItem(fs.hideExtension(fileList[i]))
				-- end
			end
		end
	end

	if #selectedIcons > 1 then
		menu:addItem(MineOSCore.localization.newFolderFromChosen .. " (" .. #selectedIcons .. ")").onTouch = function()
			MineOSCore.newFolderFromChosen(MineOSCore.OSMainContainer, selectedIcons)
		end
		menu:addSeparator()
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
						fs.path(selectedIcons[i].path) .. "/" .. fs.hideExtension(fs.name(selectedIcons[i].path)) .. ".lnk",
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
						fs.path(MineOSCore.paths.desktop) .. "/" .. fs.hideExtension(fs.name(selectedIcons[i].path)) .. ".lnk",
						selectedIcons[i].path
					)
				end
			end
			
			computer.pushSignal("MineOSCore", "updateFileList")
		end
	end

	if #selectedIcons == 1 then
		menu:addItem(MineOSCore.localization.rename).onTouch = function()
			computer.pushSignal("MineOSCore", "rename", icon.path)
		end
	end

	menu:addItem(MineOSCore.localization.delete).onTouch = function()
		for i = 1, #selectedIcons do
			if fs.path(selectedIcons[i].path) == MineOSCore.paths.trash then
				fs.remove(selectedIcons[i].path)
			else
				local newName = MineOSCore.paths.trash .. fs.name(selectedIcons[i].path)
				local clearName = fs.hideExtension(fs.name(selectedIcons[i].path))
				local repeats = 1
				while fs.exists(newName) do
					newName, repeats = MineOSCore.paths.trash .. clearName .. string.rep("-copy", repeats) .. selectedIcons[i].extension, repeats + 1
				end
				fs.rename(selectedIcons[i].path, newName)
			end
		end

		computer.pushSignal("MineOSCore", "updateFileList")
	end

	menu:addSeparator()

	if #selectedIcons == 1 then
		menu:addItem(MineOSCore.localization.addToDock).onTouch = function()
			MineOSCore.OSMainContainer.dockContainer.addIcon(icon.path).keepInDock = true
			MineOSCore.OSMainContainer.dockContainer.saveToOSSettings()
		end
	end

	menu:addItem(MineOSCore.localization.properties).onTouch = function()
		for i = 1, #selectedIcons do
			MineOSCore.propertiesWindow(eventData[3], eventData[4], 40, selectedIcons[i])
		end
	end

	menu:show()

	icon.parent.parent:deselectAll()
	MineOSCore.OSDraw()
end

-----------------------------------------------------------------------------------------------------------------------------------

function MineOSCore.addUniversalContainer(parentContainer, title)
	local container = parentContainer:addChild(GUI.container(1, 1, parentContainer.width, parentContainer.height))
	
	container.panel = container:addChild(GUI.panel(1, 1, container.width, container.height, MineOSCore.OSSettings.transparencyEnabled and 0x0 or (MineOSCore.OSSettings.backgroundColor or 0x0F0F0F), MineOSCore.OSSettings.transparencyEnabled and 20))
	container.layout = container:addChild(GUI.layout(1, 1, container.width, container.height, 1, 1))
	
	if title then
		container.layout:addChild(GUI.label(1, 1, unicode.len(title), 1, 0xEEEEEE, title)):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	end

	container.panel.eventHandler = function(mainContainer, object, eventData)
		if eventData[1] == "touch" then
			container:delete()
			mainContainer:draw()
			buffer.draw()
		end
	end

	return container
end

-----------------------------------------------------------------------------------------------------------------------------------

local function addUniversalContainerWithInputTextBox(parentWindow, text, title, placeholder)
	local container = MineOSCore.addUniversalContainer(parentWindow, title)
	
	container.inputField = container.layout:addChild(GUI.inputField(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0x666666, 0xEEEEEE, 0x262626, text, placeholder, false))
	container.label = container.layout:addChild(GUI.label(1, 1, 36, 1, 0xFF4940, MineOSCore.localization.file .. " " .. MineOSCore.localization.alreadyExists)):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	container.label.hidden = true

	return container
end

local function checkFileToExists(container, path)
	if fs.exists(path) then
		container.label.hidden = false
		container.parent:draw()
		buffer.draw()
	else
		container:delete()
		fs.makeDirectory(fs.path(path))
		return true
	end
end

function MineOSCore.newApplication(parentWindow, path)
	local container = addUniversalContainerWithInputTextBox(parentWindow, nil, MineOSCore.localization.newApplication, MineOSCore.localization.applicationName)

	container.inputField.onInputFinished = function()
		local finalPath = path .. container.inputField.text .. ".app/"
		if checkFileToExists(container, finalPath) then
			fs.makeDirectory(finalPath .. "/Resources/")
			fs.copy(MineOSCore.paths.icons .. "SampleIcon.pic", finalPath .. "/Resources/Icon.pic")
			local file = io.open(finalPath .. "Main.lua", "w")
			file:write("require('GUI').error('Hello world')")
			file:close()

			computer.pushSignal("MineOSCore", "updateFileList")
		end
	end

	parentWindow:draw()
	buffer.draw()
end

function MineOSCore.newFile(parentWindow, path)
	local container = addUniversalContainerWithInputTextBox(parentWindow, nil, MineOSCore.localization.newFile, MineOSCore.localization.fileName)

	container.inputField.onInputFinished = function()
		if checkFileToExists(container, path .. container.inputField.text) then
			local file = io.open(path .. container.inputField.text, "w")
			file:close()
			MineOSCore.safeLaunch(MineOSCore.paths.editor, path .. container.inputField.text)	
			computer.pushSignal("MineOSCore", "updateFileList")
		end
	end

	parentWindow:draw()
	buffer.draw()
end

function MineOSCore.newFolder(parentWindow, path)
	local container = addUniversalContainerWithInputTextBox(parentWindow, nil, MineOSCore.localization.newFolder, MineOSCore.localization.folderName)

	container.inputField.onInputFinished = function()
		if checkFileToExists(container, path .. container.inputField.text) then
			fs.makeDirectory(path .. container.inputField.text)
			computer.pushSignal("MineOSCore", "updateFileList")
		end
	end

	parentWindow:draw()
	buffer.draw()

	return container
end

function MineOSCore.newFolderFromChosen(parentWindow, selectedIcons)
	local container = addUniversalContainerWithInputTextBox(parentWindow, nil, MineOSCore.localization.newFolderFromChosen .. " (" .. #selectedIcons .. ")", MineOSCore.localization.folderName)

	container.inputField.onInputFinished = function()
		local path = fs.path(selectedIcons[1].path) .. container.inputField.text
		if checkFileToExists(container, path) then
			fs.makeDirectory(path)
			for i = 1, #selectedIcons do
				fs.rename(selectedIcons[i].path, path .. "/" .. fs.name(selectedIcons[i].path))
			end

			computer.pushSignal("MineOSCore", "updateFileList")
		end
	end

	parentWindow:draw()
	buffer.draw()

	return container
end

function MineOSCore.rename(parentWindow, path)
	local container = addUniversalContainerWithInputTextBox(parentWindow, fs.name(path), MineOSCore.localization.rename, MineOSCore.localization.newName)

	container.inputField.onInputFinished = function()
		if checkFileToExists(container, fs.path(path) .. container.inputField.text) then
			fs.rename(path, fs.path(path) .. container.inputField.text)
			computer.pushSignal("MineOSCore", "updateFileList")
		end
	end

	parentWindow:draw()
	buffer.draw()
	container.inputField:startInput()
end

function MineOSCore.editShortcut(parentWindow, path)
	local text = MineOSCore.readShortcut(path)
	local container = addUniversalContainerWithInputTextBox(parentWindow, text, MineOSCore.localization.editShortcut, MineOSCore.localization.rename)

	container.panel.eventHandler = nil
	container.inputField.onInputFinished = function()
		if fs.exists(container.inputField.text) then
			MineOSCore.createShortcut(path, container.inputField.text)
			container:delete()
			computer.pushSignal("MineOSCore", "updateFileList")
		else
			container.label.text = MineOSCore.localization.shortcutIsCorrupted
			container.label.hidden = false
			MineOSCore.OSDraw()
		end
	end

	parentWindow:draw()
	buffer.draw()
	container.inputField:startInput()
end

function MineOSCore.launchWithArguments(parentWindow, path)
	local container = addUniversalContainerWithInputTextBox(parentWindow, nil, MineOSCore.localization.launchWithArguments)

	container.inputField.onInputFinished = function()
		local args = {}
		if container.inputField.text then
			for arg in container.inputField.text:gmatch("[^%s]+") do
				table.insert(args, arg)
			end
		end
		container:delete()

		MineOSCore.clearTerminal()
		if MineOSCore.safeLaunch(path, table.unpack(args)) then
			MineOSCore.waitForPressingAnyKey()
		end

		parentWindow:draw()
		buffer.draw(true)
	end
end

function MineOSCore.applicationHelp(parentWindow, path)
	local pathToAboutFile = path .. "/resources/About/" .. MineOSCore.OSSettings.language .. ".txt"
	if MineOSCore.OSSettings.showHelpOnApplicationStart and fs.exists(pathToAboutFile) then
		local container = MineOSCore.addUniversalContainer(parentWindow, MineOSCore.localization.applicationHelp .. "\"" .. fs.name(path) .. "\"")
		
		local lines = {}
		for line in io.lines(pathToAboutFile) do
			table.insert(lines, line)
		end
		
		container.layout:addChild(GUI.textBox(1, 1, 50, 1, nil, 0xcccccc, lines, 1, 0, 0, true, true))
		local button = container.layout:addChild(GUI.button(1, 1, 30, 1, 0xEEEEEE, 0x262626, 0xAAAAAA, 0x262626, MineOSCore.localization.dontShowAnymore))	
		
		container.panel.eventHandler = function(mainContainer, object, eventData)
			if eventData[1] == "touch" then
				container:delete()
				MineOSCore.safeLaunch(path .. "/Main.lua")
			end
		end

		button.onTouch = function()
			MineOSCore.OSSettings.showHelpOnApplicationStart = false
			MineOSCore.saveOSSettings()
			container:delete()
			MineOSCore.safeLaunch(path .. "/Main.lua")
		end
	else
		MineOSCore.safeLaunch(path .. "/Main.lua")
	end

	parentWindow:draw()
	buffer.draw()
end

function MineOSCore.newFileFromURL(parentWindow, path)
	local container = addUniversalContainerWithInputTextBox(parentWindow, nil, "Загрузить файл по URL", MineOSCore.localization.fileName)

	container.inputFieldURL = container.layout:addChild(GUI.inputField(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0x666666, 0xEEEEEE, 0x262626, nil, "URL", false))
	container.inputField.onInputFinished = function()
		if fs.exists(path .. container.inputField.text) then
			container.label.hidden = false
			parentWindow:draw()
			buffer.draw()
		else
			if container.inputFieldURL.text then
				local success, reason = require("web").downloadFile(container.inputFieldURL.text, path .. container.inputField.text)
				if not success then
					GUI.error(reason)
				end

				container:delete()
				computer.pushSignal("MineOSCore", "updateFileList")
			end
		end
	end
	container.inputFieldURL.onInputFinished = container.inputField.onInputFinished

	parentWindow:draw()
	buffer.draw()
end

----------------------------------------- Windows patterns -----------------------------------------

local function onWindowResize(window, width, height)
	if window.titleLabel then
		window.titleLabel.width = width
	end

	if window.titlePanel then
		window.titlePanel.width = height
	end

	if window.tabBar then
		window.tabBar.width = width
	end

	window.backgroundPanel.width, window.backgroundPanel.height = width, height - (window.titlePanel and 1 or 0)
end

local function windowResize(window, width, height)
	window.width, window.height = width, height
	window:onResize(width, height)

	return window
end

function MineOSCore.addWindow(window)
	window.x = window.x or math.floor(MineOSCore.OSMainContainer.windowsContainer.width / 2 - window.width / 2)
	window.y = window.y or math.floor(MineOSCore.OSMainContainer.windowsContainer.height / 2 - window.height / 2)
	
	MineOSCore.OSMainContainer.windowsContainer:addChild(window)

	-- Dock
	local dockPath = MineOSCore.lastLaunchPath or "/lib/MineOSCore.lua"
	MineOSCore.lastLaunchPath = nil

	local dockIcon
	for i = 1, #MineOSCore.OSMainContainer.dockContainer.children do
		if MineOSCore.OSMainContainer.dockContainer.children[i].path == dockPath then
			dockIcon = MineOSCore.OSMainContainer.dockContainer.children[i]
			break
		end
	end
	dockIcon = dockIcon or MineOSCore.OSMainContainer.dockContainer.addIcon(dockPath, window)
	dockIcon.window = dockIcon.window or window

	window.resize = windowResize
	window.onResize = onWindowResize
	window.close = function(window)
		local sameIconExists = false
		for i = 1, #MineOSCore.OSMainContainer.dockContainer.children do
			if MineOSCore.OSMainContainer.dockContainer.children[i].path == dockPath and MineOSCore.OSMainContainer.dockContainer.children[i].window and MineOSCore.OSMainContainer.dockContainer.children[i].window ~= window then
				sameIconExists = true
				break
			end
		end

		if not sameIconExists then
			dockIcon.window = nil
			if not dockIcon.keepInDock then
				dockIcon:delete()
				MineOSCore.OSMainContainer.dockContainer.sort()
			end
		end
		
		window:delete()
		MineOSCore.OSDraw()
	end
	
	window.maximize = function(window)
		window.localPosition.x, window.localPosition.y = 1, 1
		window:resize(window.parent.width, window.parent.height)
		MineOSCore.OSDraw()
	end

	window.minimize = function(window)
		window.hidden = true
		MineOSCore.OSDraw()
	end

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

	return MineOSCore.OSMainContainer, window
end

-----------------------------------------------------------------------------------------------------------------------------------

local function addKeyAndValue(window, x, y, key, value)
	x = x + window:addChild(GUI.label(x, y, unicode.len(key) + 1, 1, 0x333333, key .. ":")).width + 1
	return window:addChild(GUI.label(x, y, unicode.len(value), 1, 0x555555, value))
end

function MineOSCore.propertiesWindow(x, y, width, icon)
	local mainContainer, window = MineOSCore.addWindow(GUI.titledWindow(x, y, width, 1, package.loaded.MineOSCore.localization.properties))

	-- window.backgroundPanel.colors.transparency = 25
	window:addChild(GUI.image(2, 3, icon.image))

	local x, y = 11, 3
	addKeyAndValue(window, x, y, package.loaded.MineOSCore.localization.type, icon.extension and icon.extension or (icon.isDirectory and package.loaded.MineOSCore.localization.folder or package.loaded.MineOSCore.localization.unknown)); y = y + 1
	local fileSizeLabel = addKeyAndValue(window, x, y, package.loaded.MineOSCore.localization.size, icon.isDirectory and package.loaded.MineOSCore.localization.calculatingSize or string.format("%.2f", fs.size(icon.path) / 1024) .. " KB"); y = y + 1
	addKeyAndValue(window, x, y, package.loaded.MineOSCore.localization.date, os.date("%d.%m.%y, %H:%M", math.floor(fs.lastModified(icon.path) / 1000))); y = y + 1
	addKeyAndValue(window, x, y, package.loaded.MineOSCore.localization.path, " ")

	local textBox = window:addChild(GUI.textBox(17, y, window.width - 18, 1, nil, 0x555555, {icon.path}, 1, 0, 0, true, true))
	window:resize(window.width, textBox.y + textBox.height)
	textBox.eventHandler = nil

	mainContainer:draw()
	buffer.draw()

	if icon.isDirectory then
		fileSizeLabel.text = string.format("%.2f", fs.directorySize(icon.path) / 1024) .. " KB"
		mainContainer:draw()
		buffer.draw()
	end
end

-----------------------------------------------------------------------------------------------------------------------------------

local function GUICopy(parentContainer, fileList, toPath)
	local applyYes, breakRecursion

	local container = MineOSCore.addUniversalContainer(parentContainer, MineOSCore.localization.copying)
	local textBox = container.layout:addChild(GUI.textBox(1, 1, container.width, 1, nil, 0x777777, {}, 1, 0, 0, true, true):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top))
	local switchAndLabel = container.layout:addChild(GUI.switchAndLabel(1, 1, 37, 8, 0x66DB80, 0x2D2D2D, 0xEEEEEE, 0x777777, MineOSCore.localization.applyToAll .. ":", false))
	container.panel.eventHandler = nil

	local buttonsLayout = container.layout:addChild(GUI.layout(1, 1, 1, 1, 1, 1))
	buttonsLayout:addChild(GUI.button(1, 1, 11, 1, 0xEEEEEE, 0x262626, 0xAAAAAA, 0x262626, MineOSCore.localization.yes)).onTouch = function()
		applyYes = true
		parentContainer:stopEventHandling()
	end
	buttonsLayout:addChild(GUI.button(1, 1, 11, 1, 0xEEEEEE, 0x262626, 0xAAAAAA, 0x262626, MineOSCore.localization.no)).onTouch = function()
		parentContainer:stopEventHandling()
	end
	buttonsLayout:addChild(GUI.button(1, 1, 11, 1, 0xEEEEEE, 0x262626, 0xAAAAAA, 0x262626, MineOSCore.localization.cancel)).onTouch = function()
		breakRecursion = true
		parentContainer:stopEventHandling()
	end
	buttonsLayout:setCellDirection(1, 1, GUI.directions.horizontal)
	buttonsLayout:setCellSpacing(1, 1, 2)
	buttonsLayout:fitToChildrenSize(1, 1)

	local function copyOrMove(path, finalPath)
		switchAndLabel.hidden = true
		buttonsLayout.hidden = true

		textBox.lines = {
			MineOSCore.localization.copying .. " " .. MineOSCore.localization.faylaBlyad .. " " .. fs.name(path) .. " " .. MineOSCore.localization.toDirectory .. " " .. string.canonicalPath(toPath),
		}
		textBox.height = #textBox.lines

		parentContainer:draw()
		buffer.draw()

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
					textBox.height = #textBox.lines

					parentContainer:draw()
					buffer.draw()
					
					parentContainer:startEventHandling()

					parentContainer:draw()
					buffer.draw()
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

	container:delete()
	parentContainer:draw()
	buffer.draw()
end

function MineOSCore.copy(what, toPath)
	if type(what) == "string" then
		what = {what}
	end

	GUICopy(MineOSCore.OSMainContainer, what, toPath)
end

-----------------------------------------------------------------------------------------------------------------------------------

function MineOSCore.init()
	MineOSCore.icons = {}
	MineOSCore.loadOSSettings()
	MineOSCore.localization = table.fromFile(MineOSCore.paths.localizationFiles .. MineOSCore.OSSettings.language .. ".lang")
	fs.makeDirectory(MineOSCore.paths.trash)

	MineOSCore.OSSettings.extensionAssociations = MineOSCore.OSSettings.extensionAssociations or {}
	MineOSCore.loadIcon("folder", MineOSCore.paths.icons .. "Folder.pic")
	MineOSCore.loadIcon("fileNotExists", MineOSCore.paths.icons .. "FileNotExists.pic")
	MineOSCore.loadIcon("application", MineOSCore.paths.icons .. "Application.pic")
	MineOSCore.loadIcon("trash", MineOSCore.paths.icons .. "Trash.pic")
	MineOSCore.loadIcon("script", MineOSCore.paths.icons .. "Script.pic")

	MineOSCore.associateExtension(".pic", MineOSCore.paths.applications .. "/Photoshop.app/Main.lua", MineOSCore.paths.icons .. "/Image.pic", MineOSCore.paths.extensionAssociations .. "Pic/ContextMenu.lua")
	MineOSCore.associateExtension(".txt", MineOSCore.paths.editor, MineOSCore.paths.icons .. "/Text.pic")
	MineOSCore.associateExtension(".cfg", MineOSCore.paths.editor, MineOSCore.paths.icons .. "/Config.pic")
	MineOSCore.associateExtension(".3dm", MineOSCore.paths.applications .. "/3DPrint.app/Main.lua", MineOSCore.paths.icons .. "/3DModel.pic")

	MineOSCore.associateExtension("script", MineOSCore.paths.extensionAssociations .. "Lua/Launcher.lua", MineOSCore.paths.icons .. "/Script.pic", MineOSCore.paths.extensionAssociations .. "Lua/ContextMenu.lua")
	MineOSCore.associateExtension(".lua", MineOSCore.paths.extensionAssociations .. "Lua/Launcher.lua", MineOSCore.paths.icons .. "/Lua.pic", MineOSCore.paths.extensionAssociations .. "Lua/ContextMenu.lua")
	MineOSCore.associateExtension(".pkg", MineOSCore.paths.extensionAssociations .. "Pkg/Launcher.lua", MineOSCore.paths.icons .. "/Archive.pic")

	MineOSCore.saveOSSettings()
end

-----------------------------------------------------------------------------------------------------------------------------------

MineOSCore.init()

-- buffer.clear(0x0)
-- buffer.draw(true)

-- local cykaContainer = GUI.fullScreenContainer()
-- cykaContainer:addChild(GUI.panel(1, 1, cykaContainer.width, cykaContainer.height, 0xFF0000))

-- GUICopy(cykaContainer, "/MineOS/papka/", "/MineOS/mamka/", true)

-----------------------------------------------------------------------------------------------------------------------------------

return MineOSCore





