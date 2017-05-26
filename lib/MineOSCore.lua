
---------------------------------------------- Libraries ------------------------------------------------------------------------

local component = require("component")
local computer = require("computer")
local event = require("event")
local advancedLua = require("advancedLua")
local image = require("image")
local buffer = require("doubleBuffering")
local GUI = require("GUI")
local ecs = require("ECSAPI")
local fs = require("filesystem")
local unicode = require("unicode")
local keyboard = require("keyboard")

local gpu = component.gpu

----------------------------------------------------------------------------------------------------------------

local MineOSCore = {}

MineOSCore.showApplicationIcons = true
MineOSCore.iconWidth = 12
MineOSCore.iconHeight = 6
MineOSCore.iconClickDelay = 0.2

MineOSCore.paths = {}
MineOSCore.paths.OS = "/MineOS/"
MineOSCore.paths.system = MineOSCore.paths.OS .. "System/"
MineOSCore.paths.localizationFiles = MineOSCore.paths.system .. "OS/Localization/"
MineOSCore.paths.icons = MineOSCore.paths.system .. "OS/Icons/"
MineOSCore.paths.applications = MineOSCore.paths.OS .. "Applications/"
MineOSCore.paths.pictures = MineOSCore.paths.OS .. "Pictures/"
MineOSCore.paths.desktop = MineOSCore.paths.OS .. "Desktop/"
MineOSCore.paths.applicationList = MineOSCore.paths.system .. "OS/Applications.cfg"
MineOSCore.paths.trash = MineOSCore.paths.OS .. "Trash/"
MineOSCore.paths.OSSettings = MineOSCore.paths.system .. "OS/OSSettings.cfg"

MineOSCore.localization = {}


---------------------------------------------- Tasks ------------------------------------------------------------------------

--[[
MineOSCore.tasks = {}

function MineOSCore.showTaskManager()
	MineOSCore.tasks.current = 1
	buffer.clear(0x2D2D2D)
	for i = 1, #MineOSCore.tasks do
		buffer.text(1, i, 0xFFFFFF, i .. ": " .. table.toString(MineOSCore.tasks[i]))
	end
	buffer.draw()
	MineOSCore.rawPullSignal()
end

local function replacePullSignal()
	MineOSCore.rawPullSignal = computer.pullSignal
	computer.pullSignal = function(timeout)
		local signalData = {MineOSCore.rawPullSignal(timeout)}

		local i = 1
		while i <= #MineOSCore.tasks do
			if coroutine.status(MineOSCore.tasks[i].coroutine) == "dead" then
				if i > 1 then
					MineOSCore.tasks.current = 1
					MineOSCore.tasks[i].coroutine = nil
					table.remove(MineOSCore.tasks, i)
				else
					error("MineOSCore fatal error cyka bitch")
				end
			else
				i = i + 1
			end
		end

		if MineOSCore.taskManagerOpen then
			MineOSCore.showTaskManager()
		else
			if keyboard.isKeyDown(0) and keyboard.isKeyDown(28) then
				MineOSCore.taskManagerOpen = true
				MineOSCore.tasks[MineOSCore.tasks.current].isPaused = true
				computer.pushSignal("")
				coroutine.yield()
			else
				return table.unpack(signalData)
			end
		end
	end
end

function MineOSCore.newTask(func, name)
	local task = {
		coroutine = coroutine.create(func),
		name = name,
		isPaused = false
	}
	table.insert(MineOSCore.tasks, task)
	return task
end

function MineOSCore.newTaskFromFile(path)
	local loadSuccess, loadReason = loadfile(path)
	MineOSCore.newTask(loadSuccess)
end

]]

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

----------------------------------------------------------------------------------------------------------------

function MineOSCore.getMethodExecutionTime(method)
	local oldOSClock = os.clock()
	method()
	return os.clock() - oldOSClock
end

function MineOSCore.getAverageMethodExecutionTime(method, countOfTries)
	local averageTime = 0
	for i = 1, countOfTries do
		averageTime = (averageTime + MineOSCore.getMethodExecutionTime(method)) / 2
		os.sleep(0.1)
	end
	return averageTime
end

-----------------------------------------------------------------------------------------------------------------------------------

function MineOSCore.createShortcut(where, forWhat)
	fs.makeDirectory(fs.path(where))
	local file = io.open(where, "w")
	file:write("return \"" .. forWhat .. "\"")
	file:close()
end

function MineOSCore.readShortcut(path)
	local success, filename = pcall(loadfile(path))
	if success then
		return filename
	else
		error("Failed to read shortcut from path \"" .. fs.path(path) .. "\": file is corrupted")
	end
end

function MineOSCore.saveOSSettings()
	table.toFile(MineOSCore.paths.OSSettings, MineOSCore.OSSettings, true)
end

function MineOSCore.loadOSSettings()
	MineOSCore.OSSettings = table.fromFile(MineOSCore.paths.OSSettings)
end

function MineOSCore.loadIcon(name, path)
	if not MineOSCore.icons[name] then MineOSCore.icons[name] = image.load(path) end
	return MineOSCore.icons[name]
end

--Вся необходимая информация для иконок
function MineOSCore.loadStandartIcons()
	MineOSCore.icons = {}
	MineOSCore.loadIcon("folder", MineOSCore.paths.icons .. "Folder.pic")
	MineOSCore.loadIcon("script", MineOSCore.paths.icons .. "Script.pic")
	MineOSCore.loadIcon("text", MineOSCore.paths.icons .. "Text.pic")
	MineOSCore.loadIcon("config", MineOSCore.paths.icons .. "Config.pic")
	MineOSCore.loadIcon("lua", MineOSCore.paths.icons .. "Lua.pic")
	MineOSCore.loadIcon("image", MineOSCore.paths.icons .. "Image.pic")
	MineOSCore.loadIcon("pastebin", MineOSCore.paths.icons .. "Pastebin.pic")
	MineOSCore.loadIcon("fileNotExists", MineOSCore.paths.icons .. "FileNotExists.pic")
	MineOSCore.loadIcon("archive", MineOSCore.paths.icons .. "Archive.pic")
	MineOSCore.loadIcon("model3D", MineOSCore.paths.icons .. "3DModel.pic")
	MineOSCore.loadIcon("application", MineOSCore.paths.icons .. "Application.pic")
	MineOSCore.loadIcon("trash", MineOSCore.paths.icons .. "Trash.pic")
end

-----------------------------------------------------------------------------------------------------------------------------------

function MineOSCore.init()
	fs.makeDirectory(MineOSCore.paths.trash)
	MineOSCore.loadOSSettings()
	MineOSCore.localization = table.fromFile(MineOSCore.paths.localizationFiles .. MineOSCore.OSSettings.language .. ".lang")
	MineOSCore.loadStandartIcons()
end

function MineOSCore.clearTerminal()
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

-----------------------------------------------------------------------------------------------------------------------------------

local function launchApp(icon)
	computer.pushSignal("MineOSCore", "applicationHelp", icon.path)
end

local function launchDirectory(icon)
	computer.pushSignal("MineOSCore", "changeWorkpath", icon.path)
end

local function launchEditor(icon)
	MineOSCore.safeLaunch(MineOSCore.paths.applications .. "/MineCode IDE.app/Main.lua", "open", icon.path)
end

local function launchLua(icon)
	MineOSCore.clearTerminal()
	if MineOSCore.safeLaunch(icon.path) then
		MineOSCore.waitForPressingAnyKey()
	end
end

local function launchImage(icon)
	MineOSCore.safeLaunch(MineOSCore.paths.applications .. "Photoshop.app/Main.lua", "open", icon.path)
end

local function launchPackage(icon)
	require("compressor").unpack(icon.path, fs.path(icon.path))
end

local function launch3DPrint(icon)
	MineOSCore.safeLaunch(MineOSCore.paths.applications .. "3DPrint.app/Main.lua", "open", icon.path)
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

function MineOSCore.analyzeIconExtension(icon)
	if icon.isDirectory then
		if icon.extension == ".app" then
			if MineOSCore.showApplicationIcons then
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
		elseif icon.extension == ".cfg" or icon.extension == ".config" then
			icon.image = MineOSCore.icons.config
			icon.launch = launchEditor
		elseif icon.extension == ".txt" or icon.extension == ".rtf" then
			icon.image = MineOSCore.icons.text
			icon.launch = launchEditor
		elseif icon.extension == ".lua" then
		 	icon.image = MineOSCore.icons.lua
		 	icon.launch = launchLua
		elseif icon.extension == ".pic" or icon.extension == ".png" then
			icon.image = MineOSCore.icons.image
			icon.launch = launchImage
		elseif icon.extension == ".pkg" then
			icon.image = MineOSCore.icons.archive
			icon.launch = launchPackage
		elseif icon.extension == ".3dm" then
			icon.image = MineOSCore.icons.model3D
			icon.launch = launch3DPrint
		elseif not fs.exists(icon.path) then
			icon.image = MineOSCore.icons.fileNotExists
			icon.launch = launchCorrupted
		else
			icon.image = MineOSCore.icons.script
			icon.launch = launchLua
		end
	end

	return icon
end

function MineOSCore.getParametersForDrawingIcons(fieldWidth, fieldHeight, xSpaceBetweenIcons, ySpaceBetweenIcons)
	local xCountOfIcons, yCountOfIcons = math.floor(fieldWidth / (MineOSCore.iconWidth + xSpaceBetweenIcons)), math.floor(fieldHeight / (MineOSCore.iconHeight + ySpaceBetweenIcons))
	local totalCountOfIcons = xCountOfIcons * yCountOfIcons
	return xCountOfIcons, yCountOfIcons, totalCountOfIcons
end

local function iconDraw(icon)
	if icon.isSelected then
		buffer.square(icon.x, icon.y, icon.width, icon.height,  icon.colors.selection, 0x000000, " ", 50)
	end

	buffer.image(icon.x + 2, icon.y, icon.image)

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

function MineOSCore.createIcon(x, y, path, textColor, showExtension, selectionColor)
	local icon = GUI.object(x, y, MineOSCore.iconWidth, MineOSCore.iconHeight)
	
	icon.colors = {
		text = textColor,
		selection = selectionColor,
	}
	icon.path = path
	icon.size = fs.size(icon.path)
	icon.isDirectory = fs.isDirectory(icon.path)
	icon.extension = fs.extension(icon.path)
	icon.showExtension = showExtension
	icon.isShortcut = false
	icon.isSelected = false

	icon.draw = iconDraw

	-- Поддержка изменяемых извне функций правого и левого кликов
	icon.onLeftClick = MineOSCore.iconLeftClick
	icon.onRightClick = MineOSCore.iconRightClick

	-- Обработка клика непосредственно на иконку
	icon.eventHandler = function(mainContainer, object, eventData)
		if eventData[1] == "touch" then
			icon.isSelected = true
			MineOSCore.OSDraw()

			if eventData[5] == 0 then
				os.sleep(MineOSCore.iconClickDelay)
				icon.onLeftClick(icon, eventData)
			else
				icon.onRightClick(icon, eventData)
			end

			icon.isSelected = false
			MineOSCore.OSDraw()
		end
	end

	-- Онализ формата и прочего говна иконки для последующего получения изображения иконки и функции-лаунчера
	MineOSCore.analyzeIconExtension(icon)
	
	return icon
end

local function updateIconFieldFileList(iconField)
	iconField.fileList = fs.sortedList(iconField.workpath, iconField.sortingMethod, iconField.showHiddenFiles)
	iconField.children = {}

	local xPos, yPos, counter = 1, 1, 1
	for i = iconField.fromFile, iconField.fromFile + iconField.iconCount.total - 1 do
		if not iconField.fileList[i] then break end

		iconField:addChild(
			MineOSCore.createIcon(
				xPos,
				yPos,
				iconField.workpath .. iconField.fileList[i],
				iconField.colors.iconText,
				iconField.showExtension,
				iconField.selectionColor
			)
		)

		xPos, counter = xPos + MineOSCore.iconWidth + iconField.spaceBetweenIcons.x, counter + 1
		if counter > iconField.iconCount.width then
			xPos, counter = 1, 1
			yPos = yPos + MineOSCore.iconHeight + iconField.spaceBetweenIcons.y
		end
	end

	return iconField
end

function MineOSCore.createIconField(x, y, width, height, xCountOfIcons, yCountOfIcons, totalCountOfIcons, xSpaceBetweenIcons, ySpaceBetweenIcons, iconTextColor, showExtension, showHiddenFiles, sortingMethod, workpath, selectionColor)
	local iconField = GUI.container(x, y, width, height)

	iconField.colors = {iconText = iconTextColor}

	iconField.iconCount = {}
	iconField.spaceBetweenIcons = {x = xSpaceBetweenIcons, y = ySpaceBetweenIcons}
	iconField.iconCount.width, iconField.iconCount.height, iconField.iconCount.total = xCountOfIcons, yCountOfIcons, totalCountOfIcons

	iconField.workpath = workpath
	iconField.showExtension = showExtension
	iconField.showHiddenFiles = showHiddenFiles
	iconField.sortingMethod = sortingMethod
	iconField.fileList = {}
	iconField.fromFile = 1
	iconField.selectionColor = selectionColor

	iconField.updateFileList = updateIconFieldFileList

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
		GUI.error("Failed to safely launch file that doesn't exists: \"" .. path .. "\"", {title = {color = 0xFFDB40, text = "Warning"}})
	end

	component.screen.setPrecise(false)
	buffer.setResolution(oldResolutionWidth, oldResolutionHeight)

	if not finalSuccess then
		MineOSCore.showErrorWindow(finalPath, finalLine, finalTraceback)
	end

	return finalSuccess, finalPath, finalLine, finalTraceback
end

-----------------------------------------------------------------------------------------------------------------------------------

function MineOSCore.iconLeftClick(icon, eventData)
	 MineOSCore.lastLaunchPath = icon.path
	icon:launch()
	computer.pushSignal("MineOSCore", "updateFileList")
end

function MineOSCore.iconRightClick(icon, eventData)
	local action
	-- Разные контекстные меню
	if icon.isDirectory then
		if icon.extension == ".app" then
			action = GUI.contextMenu(eventData[3], eventData[4],
				{MineOSCore.localization.contextMenuShowPackageContent},
				"-",
				{MineOSCore.localization.contextMenuCut},
				{MineOSCore.localization.contextMenuCopy},
				{MineOSCore.localization.contextMenuRename},
				{MineOSCore.localization.contextMenuDelete},
				{MineOSCore.localization.contextMenuCreateShortcut, icon.extension == ".lnk"},
				{MineOSCore.localization.contextMenuArchive},
				"-",
				{MineOSCore.localization.contextMenuAddToDock},
				{MineOSCore.localization.contextMenuProperties}
			):show()
		else
			action = GUI.contextMenu(eventData[3], eventData[4],
				{MineOSCore.localization.contextMenuCut},
				{MineOSCore.localization.contextMenuCopy},
				{MineOSCore.localization.contextMenuRename},
				{MineOSCore.localization.contextMenuDelete},
				{MineOSCore.localization.contextMenuCreateShortcut, icon.extension == ".lnk"},
				{MineOSCore.localization.contextMenuArchive},
				"-",
				{MineOSCore.localization.contextMenuAddToDock},
				{MineOSCore.localization.contextMenuProperties}
			):show()
		end
	else
		if icon.isShortcut then
			action = GUI.contextMenu(eventData[3], eventData[4],
				{MineOSCore.localization.contextMenuEdit},
				{MineOSCore.localization.contextMenuShowContainingFolder},
				"-",
				{MineOSCore.localization.contextMenuCut},
				{MineOSCore.localization.contextMenuCopy},
				{MineOSCore.localization.contextMenuRename},
				{MineOSCore.localization.contextMenuDelete},
				"-",
				{MineOSCore.localization.contextMenuAddToDock},
				{MineOSCore.localization.contextMenuProperties}
			):show()
		elseif icon.extension == ".pic" then
			action = GUI.contextMenu(eventData[3], eventData[4],
				{MineOSCore.localization.contextMenuSetAsWallpaper},
				"-",
				{MineOSCore.localization.contextMenuCut},
				{MineOSCore.localization.contextMenuCopy},
				{MineOSCore.localization.contextMenuRename},
				{MineOSCore.localization.contextMenuDelete},
				{MineOSCore.localization.contextMenuCreateShortcut, icon.extension == ".lnk"},
				"-",
				{MineOSCore.localization.contextMenuAddToDock},
				{MineOSCore.localization.contextMenuProperties}
			):show()
		elseif icon.extension == ".lua" then
			action = GUI.contextMenu(eventData[3], eventData[4],
				{MineOSCore.localization.contextMenuEdit},
				{MineOSCore.localization.launchWithArguments},
				{MineOSCore.localization.contextMenuFlashEEPROM, (not component.isAvailable("eeprom") or icon.size > 4096)},
				"-",
				{MineOSCore.localization.contextMenuCut},
				{MineOSCore.localization.contextMenuCopy},
				{MineOSCore.localization.contextMenuRename},
				{MineOSCore.localization.contextMenuDelete},
				{MineOSCore.localization.contextMenuCreateShortcut, icon.extension == ".lnk"},
				"-",
				{MineOSCore.localization.contextMenuAddToDock},
				{MineOSCore.localization.contextMenuProperties}
			):show()
		else
			action = GUI.contextMenu(eventData[3], eventData[4],
				{MineOSCore.localization.contextMenuEdit},
				"-",
				{MineOSCore.localization.contextMenuCut},
				{MineOSCore.localization.contextMenuCopy},
				{MineOSCore.localization.contextMenuRename},
				{MineOSCore.localization.contextMenuDelete},
				{MineOSCore.localization.contextMenuCreateShortcut, icon.extension == ".lnk"},
				"-",
				{MineOSCore.localization.contextMenuAddToDock},
				{MineOSCore.localization.contextMenuProperties}
			):show()
		end
	end

	if action == MineOSCore.localization.contextMenuEdit then
		MineOSCore.safeLaunch(MineOSCore.paths.applications .. "/MineCode IDE.app/Main.lua", "open", icon.path)
		computer.pushSignal("MineOSCore", "updateFileList")
	elseif action == "Свойства" then
		MineOSCore.propertiesWindow(eventData[3], eventData[4], 40, icon)
	elseif action == MineOSCore.localization.contextMenuShowContainingFolder then
		computer.pushSignal("MineOSCore", "changeWorkpath", fs.path(icon.shortcutPath))
		computer.pushSignal("MineOSCore", "updateFileList")
	elseif action == MineOSCore.localization.contextMenuAddToFavourites then
		computer.pushSignal("finderFavouriteAdded", icon.path)
	elseif action == MineOSCore.localization.contextMenuShowPackageContent then
		computer.pushSignal("MineOSCore", "changeWorkpath", icon.path)
		computer.pushSignal("MineOSCore", "updateFileList")
	elseif action == MineOSCore.localization.contextMenuCopy then
		_G.clipboard = icon.path
	elseif action == MineOSCore.localization.contextMenuCut then
		_G.clipboard = icon.path
		_G.clipboardCut = true
		computer.pushSignal("MineOSCore", "updateFileList")
	elseif action == MineOSCore.localization.contextMenuDelete then
		if fs.path(icon.path) == MineOSCore.paths.trash then
			fs.remove(icon.path)
		else
			local newName = MineOSCore.paths.trash .. fs.name(icon.path)
			local clearName = fs.hideExtension(fs.name(icon.path))
			local repeats = 1
			while fs.exists(newName) do
				newName, repeats = MineOSCore.paths.trash .. clearName .. string.rep("-copy", repeats) .. icon.extension, repeats + 1
			end
			fs.rename(icon.path, newName)
		end
		computer.pushSignal("MineOSCore", "updateFileList")
	elseif action == MineOSCore.localization.contextMenuRename then
		computer.pushSignal("MineOSCore", "rename", icon.path)
	elseif action == MineOSCore.localization.contextMenuCreateShortcut then
		MineOSCore.createShortcut(fs.path(icon.path) .. "/" .. fs.hideExtension(fs.name(icon.path)) .. ".lnk", icon.path)
		computer.pushSignal("MineOSCore", "updateFileList")
	elseif action == MineOSCore.localization.contextMenuArchive then
		require("compressor").pack(fs.path(icon.path) .. fs.hideExtension(fs.name(icon.path)) .. ".pkg", icon.path)
		computer.pushSignal("MineOSCore", "updateFileList")
	elseif action == MineOSCore.localization.contextMenuSetAsWallpaper then
		MineOSCore.OSSettings.wallpaper = icon.path
		MineOSCore.saveOSSettings()
		computer.pushSignal("MineOSCore", "updateWallpaper")
	elseif action == MineOSCore.localization.contextMenuFlashEEPROM then
		local file = io.open(icon.path, "r")
		component.eeprom.set(file:read("*a"))
		file:close()
		computer.beep(1500, 0.2)
	elseif action == MineOSCore.localization.contextMenuAddToDock then
		MineOSCore.OSMainContainer.dockContainer.addIcon(icon.path).keepInDock = true
		MineOSCore.OSMainContainer.dockContainer.saveToOSSettings()
	elseif action == MineOSCore.localization.launchWithArguments then
		MineOSCore.launchWithArguments(MineOSCore.OSMainContainer, icon.path)
	end
end

function MineOSCore.emptyZoneClick(eventData, mainContainer, workpath)
	local action = GUI.contextMenu(eventData[3], eventData[4],
		{MineOSCore.localization.contextMenuNewFile},
		{MineOSCore.localization.contextMenuNewFolder},
		{MineOSCore.localization.contextMenuNewApplication},
		"-",
		{MineOSCore.localization.contextMenuPaste, (_G.clipboard == nil)}
	):show()

	if action == MineOSCore.localization.contextMenuNewFile then
		computer.pushSignal("MineOSCore", "newFile")
	elseif action == MineOSCore.localization.contextMenuNewFolder then
		computer.pushSignal("MineOSCore", "newFolder")
	elseif action == MineOSCore.localization.contextMenuPaste then
		ecs.copy(_G.clipboard, workpath)
		if _G.clipboardCut then
			fs.remove(_G.clipboard)
			_G.clipboardCut = nil
			_G.clipboard = nil
		end
		computer.pushSignal("MineOSCore", "updateFileList")
	elseif action == MineOSCore.localization.contextMenuNewApplication then
		computer.pushSignal("MineOSCore", "newApplication")
	end
end

-----------------------------------------------------------------------------------------------------------------------------------

function MineOSCore.addUniversalContainer(parentContainer, title)
	local container = parentContainer:addChild(GUI.container(1, 1, parentContainer.width, parentContainer.height))
	container.panel = container:addChild(GUI.panel(1, 1, container.width, container.height, 0x0, 30))
	container.layout = container:addChild(GUI.layout(1, 1, container.width, container.height, 1, 1))
	container.layout:addChild(GUI.label(1, 1, unicode.len(title), 1, 0xEEEEEE, title)):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	
	return container
end

-----------------------------------------------------------------------------------------------------------------------------------

local function addUniversalContainerWithInputTextBoxes(parentWindow, path, text, title, placeholder)
	local container = MineOSCore.addUniversalContainer(parentWindow, title)
	
	container.inputTextBox = container.layout:addChild(GUI.inputTextBox(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0xEEEEEE, 0x262626, text, placeholder, false))
	container.label = container.layout:addChild(GUI.label(1, 1, 36, 3, 0xFF4940, " ")):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	container.panel.eventHandler = function(mainContainer, object, eventData)
		if eventData[1] == "touch" then
			container:delete()
			mainContainer:draw()
			buffer.draw()
		end
	end

	parentWindow:draw()
	buffer.draw()

	return container
end

local function checkFileToExists(container, path)
	if fs.exists(path) then
		container.label.text = MineOSCore.localization.fileAlreadyExists
		container.parent:draw()
		buffer.draw()
	else
		container:delete()
		fs.makeDirectory(fs.path(path))
		return true
	end
end

function MineOSCore.newApplication(parentWindow, path)
	local container = addUniversalContainerWithInputTextBoxes(parentWindow, path, nil, MineOSCore.localization.contextMenuNewApplication, MineOSCore.localization.applicationName)

	container.inputTextBox.onInputFinished = function()
		local finalPath = path .. container.inputTextBox.text .. ".app/"
		if checkFileToExists(container, finalPath) then
			fs.makeDirectory(finalPath .. "/Resources/")
			fs.copy(MineOSCore.paths.icons .. "SampleIcon.pic", finalPath .. "/Resources/Icon.pic")
			local file = io.open(finalPath .. "Main.lua", "w")
			file:write("require('GUI').error('Hello world')")
			file:close()

			computer.pushSignal("MineOSCore", "updateFileList")
		end
	end
end

function MineOSCore.newFile(parentWindow, path)
	local container = addUniversalContainerWithInputTextBoxes(parentWindow, path, nil, MineOSCore.localization.contextMenuNewFile, MineOSCore.localization.fileName)

	container.inputTextBox.onInputFinished = function()
		if checkFileToExists(container, path .. container.inputTextBox.text) then
			local file = io.open(path .. container.inputTextBox.text, "w")
			file:close()
			MineOSCore.safeLaunch(MineOSCore.paths.applications .. "/MineCode IDE.app/Main.lua", "open", path .. container.inputTextBox.text)	
			computer.pushSignal("MineOSCore", "updateFileList")
		end
	end
end

function MineOSCore.newFolder(parentWindow, path)
	local container = addUniversalContainerWithInputTextBoxes(parentWindow, path, nil, MineOSCore.localization.contextMenuNewFolder, MineOSCore.localization.folderName)

	container.inputTextBox.onInputFinished = function()
		if checkFileToExists(container, path .. container.inputTextBox.text) then
			fs.makeDirectory(path .. container.inputTextBox.text)
			computer.pushSignal("MineOSCore", "updateFileList")
		end
	end
end

function MineOSCore.rename(parentWindow, path)
	local container = addUniversalContainerWithInputTextBoxes(parentWindow, path, fs.name(path), MineOSCore.localization.contextMenuRename, MineOSCore.localization.newName)

	container.inputTextBox.onInputFinished = function()
		if checkFileToExists(container, fs.path(path) .. container.inputTextBox.text) then
			fs.rename(path, fs.path(path) .. container.inputTextBox.text)
			computer.pushSignal("MineOSCore", "updateFileList")
		end
	end
end

function MineOSCore.launchWithArguments(parentWindow, path)
	local container = addUniversalContainerWithInputTextBoxes(parentWindow, path, nil, MineOSCore.localization.launchWithArguments)

	container.inputTextBox.onInputFinished = function()
		local args = {}
		if container.inputTextBox.text then
			for arg in container.inputTextBox.text:gmatch("[^%s]+") do
				table.insert(args, arg)
			end
		end
		container:delete()

		MineOSCore.clearTerminal()
		if MineOSCore.safeLaunch(path, table.unpack(args)) then
			MineOSCore.waitForPressingAnyKey()
		end

		MineOSCore.OSDraw(true)
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
		lines = string.wrap(lines, 50)
		
		container.layout:addChild(GUI.textBox(1, 1, 50, #lines, nil, 0xcccccc, lines, 1, 0, 0))
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
	local mainContainer, window = MineOSCore.addWindow(GUI.titledWindow(x, y, width, 1, package.loaded.MineOSCore.localization.contextMenuProperties))

	window.backgroundPanel.colors.transparency = 25
	window:addChild(GUI.image(2, 3, icon.image))

	local x, y = 11, 3
	addKeyAndValue(window, x, y, package.loaded.MineOSCore.localization.type, icon.extension and icon.extension or (icon.isDirectory and package.loaded.MineOSCore.localization.folder or package.loaded.MineOSCore.localization.unknown)); y = y + 1
	local fileSizeLabel = addKeyAndValue(window, x, y, package.loaded.MineOSCore.localization.size, icon.isDirectory and package.loaded.MineOSCore.localization.calculatingSize or string.format("%.2f", icon.size / 1024) .. " KB"); y = y + 1
	addKeyAndValue(window, x, y, package.loaded.MineOSCore.localization.date, os.date("%d.%m.%y, %H:%M", fs.lastModified(icon.path))); y = y + 1
	addKeyAndValue(window, x, y, package.loaded.MineOSCore.localization.path, " ")

	local lines = string.wrap(icon.path, window.width - 18)
	local textBox = window:addChild(GUI.textBox(17, y, window.width - 18, #lines, nil, 0x555555, lines, 1))
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

function MineOSCore.OSDraw(force)
	MineOSCore.OSMainContainer:draw()
	buffer.draw(force)
end

-----------------------------------------------------------------------------------------------------------------------------------

MineOSCore.init()

-----------------------------------------------------------------------------------------------------------------------------------

return MineOSCore





