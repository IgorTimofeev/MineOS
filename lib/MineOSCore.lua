
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
	local localizationFileName = pathToLocalizationFolder .. _G.OSSettings.language .. ".lang"
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
	table.toFile(MineOSCore.paths.OSSettings, _G.OSSettings, true)
end

function MineOSCore.loadOSSettings()
	_G.OSSettings = table.fromFile(MineOSCore.paths.OSSettings)
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
	MineOSCore.localization = table.fromFile(MineOSCore.paths.localizationFiles .. _G.OSSettings.language .. ".lang")
	MineOSCore.loadStandartIcons()
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
	ecs.prepareToExit()
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

local function launchCorrupted(icon)
	GUI.error("Application is corrupted")
end

function MineOSCore.analyzeIconExtension(icon)
	if icon.isDirectory then
		if icon.extension == ".app" then
			if MineOSCore.showApplicationIcons then
				icon.iconImage.image = image.load(icon.path .. "/Resources/Icon.pic")
			else
				icon.iconImage.image = MineOSCore.icons.application
			end

			icon.launch = launchApp
		else
			icon.iconImage.image = MineOSCore.icons.folder
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

			icon.path = shortcutIcon.path
			icon.iconImage.image = shortcutIcon.iconImage.image
			icon.launch = shortcutIcon.launch

			shortcutIcon = nil
		elseif icon.extension == ".cfg" or icon.extension == ".config" then
			icon.iconImage.image = MineOSCore.icons.config
			icon.launch = launchEditor
		elseif icon.extension == ".txt" or icon.extension == ".rtf" then
			icon.iconImage.image = MineOSCore.icons.text
			icon.launch = launchEditor
		elseif icon.extension == ".lua" then
		 	icon.iconImage.image = MineOSCore.icons.lua
		 	icon.launch = launchLua
		elseif icon.extension == ".pic" or icon.extension == ".png" then
			icon.iconImage.image = MineOSCore.icons.image
			icon.launch = launchImage
		elseif icon.extension == ".pkg" then
			icon.iconImage.image = MineOSCore.icons.archive
			icon.launch = launchPackage
		elseif icon.extension == ".3dm" then
			icon.iconImage.image = MineOSCore.icons.model3D
			icon.launch = launch3DPrint
		elseif not fs.exists(icon.path) then
			icon.iconImage.image = MineOSCore.icons.fileNotExists
			icon.launch = launchCorrupted
		else
			icon.iconImage.image = MineOSCore.icons.script
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

function MineOSCore.createIcon(x, y, path, textColor, showExtension)
	local icon = GUI.container(x, y, MineOSCore.iconWidth, MineOSCore.iconHeight)
	
	icon.path = path
	icon.size = fs.size(icon.path)
	icon.isDirectory = fs.isDirectory(icon.path)
	icon.extension = fs.extension(icon.path)
	icon.showExtension = showExtension
	icon.isShortcut = false
	icon.isSelected = false

	icon.iconImage = icon:addImage(3, 1, {8, 4})
	icon.textLabel = icon:addLabel(1, MineOSCore.iconHeight, MineOSCore.iconWidth, 1, textColor, fs.name(icon.path)):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	
	local oldDraw = icon.draw
	icon.draw = function(icon)
		if icon.isSelected then buffer.square(icon.x, icon.y, icon.width, icon.height, 0xFFFFFF, 0x000000, " ", 50) end
		if icon.showExtension then
			icon.textLabel.text = string.limit(fs.name(icon.path), icon.textLabel.width, "center")
		else
			icon.textLabel.text = string.limit(fs.hideExtension(fs.name(icon.path)), icon.textLabel.width, "center")
		end
		oldDraw(icon)
		if icon.isShortcut then buffer.set(icon.iconImage.x + icon.iconImage.width - 1, icon.iconImage.y + icon.iconImage.height - 1, 0xFFFFFF, 0x000000, "<") end
	end

	-- Поддержка изменяемых извне функций правого и левого кликов
	icon.onLeftClick = MineOSCore.iconLeftClick
	icon.onRightClick = MineOSCore.iconRightClick

	-- Обработка клика непосредственно на иконку
	icon.iconImage.onTouch = function(eventData)
		icon.isSelected = true
		local firstParent = icon:getFirstParent()
		firstParent:draw()
		buffer.draw()

		if eventData[5] == 0 then
			os.sleep(MineOSCore.iconClickDelay)
			icon.onLeftClick(icon, eventData)
		else
			icon.onRightClick(icon, eventData)
		end

		icon.isSelected = false
		firstParent:draw()
		buffer.draw()
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
				xPos, yPos, iconField.workpath .. iconField.fileList[i], iconField.colors.iconText, iconField.showExtension
			),
			GUI.objectTypes.container
		)

		xPos, counter = xPos + MineOSCore.iconWidth + iconField.spaceBetweenIcons.x, counter + 1
		if counter > iconField.iconCount.width then
			xPos, counter = 1, 1
			yPos = yPos + MineOSCore.iconHeight + iconField.spaceBetweenIcons.y
		end
	end

	return iconField
end

function MineOSCore.createIconField(x, y, width, height, xCountOfIcons, yCountOfIcons, totalCountOfIcons, xSpaceBetweenIcons, ySpaceBetweenIcons, iconTextColor, showExtension, showHiddenFiles, sortingMethod, workpathworkpath)
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
	iconField.fromFile = fromFile

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

local function drawErrorWindow(path, programVersion, errorLine, reason)
	local oldDrawLimit = buffer.getDrawLimit(); buffer.resetDrawLimit()
	local width, height = buffer.screen.width, math.floor(buffer.screen.height * 0.45)
	local y = math.floor(buffer.screen.height / 2 - height / 2)

	-- Окошечко и всякая шняжка на нем
	local window = GUI.window(1, y, width, height, width, height)
	window:addPanel(1, 1, width, 3, 0x383838)
	window:addLabel(1, 2, width, 1, 0xFFFFFF, MineOSCore.localization.errorWhileRunningProgram .. "\"" .. fs.name(path) .. "\""):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	local windowActionButtons = window:addWindowActionButtons(2, 2, false)
	local sendToDeveloperButton = window:addAdaptiveButton(9, 1, 2, 1, 0x444444, 0xFFFFFF, 0x343434, 0xFFFFFF, MineOSCore.localization.sendFeedback)

	--Кодик на окошечке
	local lines = {}
	local fromLine = errorLine - math.floor((height - 3) / 2) + 1; if fromLine <= 0 then fromLine = 1 end
	local toLine = fromLine + window.height - 3 - 1
	local file = io.open(path, "r")
	local lineCounter = 1
	for line in file:lines() do
		if lineCounter >= fromLine and lineCounter <= toLine then
			lines[lineCounter] = string.gsub(line, "	", "  ")
		elseif lineCounter < fromLine then
			lines[lineCounter] = " "
		elseif lineCounter > toLine then
			break
		end
		lineCounter = lineCounter + 1
	end
	file:close()

	local codeView = window:addCodeView(1, 4, math.floor(width * 0.62), height - 3, lines, 1, fromLine, 100, {}, {[errorLine] = 0xFF4444}, true, 2)
	codeView.scrollBars.horizontal.isHidden = true

	-- Текстбоксик
	local stackTextBox = window:addTextBox(codeView.width + 1, 4, window.width - codeView.width, codeView.height, 0xFFFFFF, 0x000000, string.wrap(MineOSCore.parseErrorMessage(reason, 4), window.width - codeView.width - 2), 1, 1, 0)

	-- Всякие действия пиздатые
	local function exit()
		windowActionButtons.close:pressAndRelease()
		buffer.setDrawLimit(oldDrawLimit)
		window:close()
	end
	
	windowActionButtons.close.onTouch = exit
	
	window.onDrawStarted = function()
		buffer.clear(0x000000, 50)
	end

	window.onKeyDown = function(eventData)
		if eventData[4] == 28 then exit() end
	end

	sendToDeveloperButton.onTouch = function()
		local data = ecs.universalWindow("auto", "auto", 36, 0xeeeeee, true,
			{"EmptyLine"},
			{"CenterText", 0x880000, MineOSCore.localization.sendFeedback},
			{"EmptyLine"},
			{"Input", 0x262626, 0x880000, MineOSCore.localization.yourContacts},
			{"Input", 0x262626, 0x880000, MineOSCore.localization.additionalInfo},
			{"EmptyLine"},
			{"CenterText", 0x880000, MineOSCore.localization.stackTraceback .. ":"},
			{"EmptyLine"},
			{"TextField", 5, 0xFFFFFF, 0x000000, 0xcccccc, 0x3366CC, reason},
			{"Button", {0x999999, 0xffffff, "OK"}, {0x777777, 0xffffff, MineOSCore.localization.cancel}}
		)

		if data[3] == "OK" then
			if component.isAvailable("internet") then
				local url = "https://api.mcmodder.ru/ECS/report.php?path=" .. path .. "&version=" .. string.optimizeForURLRequests(programVersion) .. "&userContacts=" .. string.optimizeForURLRequests(data[1]) .. "&userMessage=" .. string.optimizeForURLRequests(data[2]) .. "&errorMessage=" .. string.optimizeForURLRequests(reason)
				local success, reason = component.internet.request(url)
				if success then
					success:close()
				else
					ecs.error(reason)
				end
			end
			exit()
		end
	end

	-- Начинаем гомоеблю!
	window:draw()
	buffer.draw()
	for i = 1, 3 do component.computer.beep(1500, 0.08) end
	window:handleEvents()
end

function MineOSCore.safeLaunch(path, ...)
	local args = {...}
	local oldResolutionWidth, oldResolutionHeight = buffer.screen.width, buffer.screen.height
	local finalSuccess, finalPath, finalLine, finalTraceback = true
	
	if fs.exists(path) then
		local loadSuccess, loadReason = loadfile(string.canonicalPath("/" .. path))

		if loadSuccess then
			local function launchMethod()
				loadSuccess(table.unpack(args))
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
			
			local runSuccess, runReason = xpcall(launchMethod, tracebackMethod)
			if type(runReason) == "string" then
				GUI.error(runReason, {title = {color = 0xFFDB40, text = "Warning"}})
			else
				if not runSuccess and not string.match(runReason.traceback, "^table") and not string.find(runReason.traceback, "interrupted", 1, 15) then
					finalSuccess, finalPath, finalLine, finalTraceback = false, runReason.path, runReason.line, runReason.traceback
				end
			end
		else
			finalSuccess, finalPath, finalTraceback = false, path, loadReason
			local match = string.match(loadReason, ":(%d+)%:")
			finalLine = tonumber(match)
			if not match or not finalLine then error("Дебажь говно! " .. tostring(loadReason)) end
		end
	else
		GUI.error("Failed to safely launch file that doesn't exists: \"" .. path .. "\"", {title = {color = 0xFFDB40, text = "Warning"}})
	end

	if not finalSuccess then
		drawErrorWindow(finalPath, "1.0", finalLine, finalTraceback)
	end

	component.screen.setPrecise(false)
	gpu.setResolution(oldResolutionWidth, oldResolutionHeight)
	buffer.start()

	return finalSuccess, finalPath, finalLine, finalTraceback
end

-----------------------------------------------------------------------------------------------------------------------------------

function MineOSCore.iconLeftClick(icon, eventData)
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
				{MineOSCore.localization.contextMenuCreateShortcut, icon.extension == ".lnk"},
				"-",
				{MineOSCore.localization.contextMenuArchive},
				{MineOSCore.localization.contextMenuAddToDock},
				"-",
				{MineOSCore.localization.contextMenuProperties},
				{MineOSCore.localization.contextMenuDelete}
			):show()
		else
			action = GUI.contextMenu(eventData[3], eventData[4],
				{MineOSCore.localization.contextMenuCut},
				{MineOSCore.localization.contextMenuCopy},
				{MineOSCore.localization.contextMenuRename},
				{MineOSCore.localization.contextMenuCreateShortcut, icon.extension == ".lnk"},
				"-",
				{MineOSCore.localization.contextMenuArchive},
				{MineOSCore.localization.contextMenuAddToDock},
				"-",
				{MineOSCore.localization.contextMenuProperties},
				{MineOSCore.localization.contextMenuDelete}
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
				"-",
				{MineOSCore.localization.contextMenuAddToDock},
				{MineOSCore.localization.contextMenuProperties},
				{MineOSCore.localization.contextMenuDelete}
			):show()
		elseif icon.extension == ".pic" then
			action = GUI.contextMenu(eventData[3], eventData[4],
				{MineOSCore.localization.contextMenuSetAsWallpaper},
				"-",
				{MineOSCore.localization.contextMenuCut},
				{MineOSCore.localization.contextMenuCopy},
				{MineOSCore.localization.contextMenuRename},
				{MineOSCore.localization.contextMenuCreateShortcut, icon.extension == ".lnk"},
				"-",
				-- {MineOSCore.localization.contextMenuArchive},
				{MineOSCore.localization.contextMenuAddToDock},
				"-",
				{MineOSCore.localization.contextMenuProperties},
				{MineOSCore.localization.contextMenuDelete}
			):show()
		elseif icon.extension == ".lua" then
			action = GUI.contextMenu(eventData[3], eventData[4],
				{MineOSCore.localization.contextMenuEdit},
				{MineOSCore.localization.contextMenuFlashEEPROM, (not component.isAvailable("eeprom") or icon.size > 4096)},
				"-",
				{MineOSCore.localization.contextMenuCut},
				{MineOSCore.localization.contextMenuCopy},
				{MineOSCore.localization.contextMenuRename},
				{MineOSCore.localization.contextMenuCreateShortcut, icon.extension == ".lnk"},
				-- "-",
				-- {MineOSCore.localization.contextMenuUploadToPastebin, true},
				"-",
				-- {MineOSCore.localization.contextMenuArchive},
				{MineOSCore.localization.contextMenuAddToDock},
				"-",
				{MineOSCore.localization.contextMenuProperties},
				{MineOSCore.localization.contextMenuDelete}
			):show()
		else
			action = GUI.contextMenu(eventData[3], eventData[4],
				{MineOSCore.localization.contextMenuEdit},
				"-",
				{MineOSCore.localization.contextMenuCut},
				{MineOSCore.localization.contextMenuCopy},
				{MineOSCore.localization.contextMenuRename},
				{MineOSCore.localization.contextMenuCreateShortcut, icon.extension == ".lnk"},
				"-",
				-- {MineOSCore.localization.contextMenuArchive},
				{MineOSCore.localization.contextMenuAddToDock},
				"-",
				{MineOSCore.localization.contextMenuProperties},
				{MineOSCore.localization.contextMenuDelete}
			):show()
		end
	end

	if action == MineOSCore.localization.contextMenuEdit then
		MineOSCore.safeLaunch(MineOSCore.paths.applications .. "/MineCode IDE.app/Main.lua", "open", icon.path)
		computer.pushSignal("MineOSCore", "updateFileList")
	elseif action == "Свойства" then
		MineOSCore.showPropertiesWindow(eventData[3], eventData[4], 40, icon)
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
		_G.OSSettings.wallpaper = icon.path
		MineOSCore.saveOSSettings()
		computer.pushSignal("MineOSCore", "updateWallpaper")
	elseif action == MineOSCore.localization.contextMenuFlashEEPROM then
		local file = io.open(icon.path, "r")
		component.eeprom.set(file:read("*a"))
		file:close()
		computer.beep(1500, 0.2)
	elseif action == MineOSCore.localization.contextMenuAddToDock then
		table.insert(_G.OSSettings.dockShortcuts, {path = icon.path})
		MineOSCore.saveOSSettings()
		computer.pushSignal("MineOSCore", "updateFileList")
	end
end

function MineOSCore.emptyZoneClick(eventData, workspace, workpath)
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

local function addKeyAndValue(window, x, y, key, value)
	window:addLabel(x, y, window.width , 1, 0x333333, key .. ":"); x = x + unicode.len(key) + 2
	return window:addLabel(x, y, window.width, 1, 0x555555, value)
end

function MineOSCore.showPropertiesWindow(x, y, width, icon)
	local window = GUI.window(x, y, width, 1)
	local backgroundPanel = window:addPanel(1, 2, window.width, 1, 0xDDDDDD)
	window:addPanel(1, 1, window.width, 1, 0xEEEEEE)
	window:addLabel(1, 1, window.width, 1, 0x333333, MineOSCore.localization.contextMenuProperties):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	window:addButton(2, 1, 1, 1, nil, 0xFF4940, nil, 0x992400, "●").onTouch = function() window:close() end

	window:addImage(3, 3, icon.iconImage.image)

	local y = 3
	addKeyAndValue(window, 13, y, MineOSCore.localization.type, icon.extension and icon.extension or (icon.isDirectory and MineOSCore.localization.folder or MineOSCore.localization.unknown)); y = y + 1
	local fileSizeLabel = addKeyAndValue(window, 13, y, MineOSCore.localization.size, icon.isDirectory and MineOSCore.localization.calculatingSize or string.format("%.2f", icon.size / 1024) .. " KB"); y = y + 1
	addKeyAndValue(window, 13, y, MineOSCore.localization.date, os.date("%d.%m.%y, %H:%M", fs.lastModified(icon.path))); y = y + 1
	addKeyAndValue(window, 13, y, MineOSCore.localization.path, " ")

	local lines = string.wrap(icon.path, window.width - 19)
	local textBox = window:addTextBox(19, y, window.width - 19, #lines, nil, 0x555555, lines, 1)
	window.height = textBox.y + textBox.height 
	backgroundPanel.height = window.height - 1

	if window.x + window.width > buffer.screen.width then window.x = window.x - (window.x + window.width - buffer.screen.width) end
	if window.y + window.height > buffer.screen.height then window.y = window.y - (window.y + window.height - buffer.screen.height) end

	window:draw()
	buffer.draw()

	if icon.isDirectory then
		fileSizeLabel.text = string.format("%.2f", fs.directorySize(icon.path) / 1024) .. " KB"
		window:draw()
		buffer.draw()
	end

	window:handleEvents()
end

-----------------------------------------------------------------------------------------------------------------------------------

local function createUniversalContainer(parentWindow, path, text, title, placeholder)
	local container = GUI.addUniversalContainer(parentWindow, title)
	
	container.inputTextBox = container.layout:addInputTextBox(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0xEEEEEE, 0x262626, text, placeholder, false)
	container.label = container.layout:addLabel(1, 1, 36, 3, 0xFF4940, " "):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	
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
	local container = createUniversalContainer(parentWindow, path, nil, MineOSCore.localization.contextMenuNewApplication, MineOSCore.localization.applicationName)

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
	local container = createUniversalContainer(parentWindow, path, nil, MineOSCore.localization.contextMenuNewFile, MineOSCore.localization.fileName)

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
	local container = createUniversalContainer(parentWindow, path, nil, MineOSCore.localization.contextMenuNewFolder, MineOSCore.localization.folderName)

	container.inputTextBox.onInputFinished = function()
		if checkFileToExists(container, path .. container.inputTextBox.text) then
			fs.makeDirectory(path .. container.inputTextBox.text)
			computer.pushSignal("MineOSCore", "updateFileList")
		end
	end
end

function MineOSCore.rename(parentWindow, path)
	local container = createUniversalContainer(parentWindow, path, fs.name(path), MineOSCore.localization.contextMenuRename, MineOSCore.localization.newName)

	container.inputTextBox.onInputFinished = function()
		if checkFileToExists(container, fs.path(path) .. container.inputTextBox.text) then
			fs.rename(path, fs.path(path) .. container.inputTextBox.text)
			computer.pushSignal("MineOSCore", "updateFileList")
		end
	end
end

function MineOSCore.applicationHelp(parentWindow, path)
	local pathToAboutFile = path .. "/resources/About/" .. _G.OSSettings.language .. ".txt"
	if _G.OSSettings.showHelpOnApplicationStart and fs.exists(pathToAboutFile) then
		local container = GUI.addUniversalContainer(parentWindow, MineOSCore.localization.applicationHelp .. "\"" .. fs.name(path) .. "\"")
		
		local lines = {}
		for line in io.lines(pathToAboutFile) do
			table.insert(lines, line)
		end
		lines = string.wrap(lines, 50)
		
		container.layout:addTextBox(1, 1, 50, #lines, nil, 0xcccccc, lines, 1, 0, 0)
		local button = container.layout:addButton(1, 1, 30, 1, 0xEEEEEE, 0x262626, 0xAAAAAA, 0x262626, MineOSCore.localization.dontShowAnymore)

		parentWindow:draw()
		buffer.draw()

		container.panel.onTouch = function()
			container:delete()
			MineOSCore.safeLaunch(path .. "/Main.lua")
			parentWindow:draw()
			buffer.draw()
		end

		button.onTouch = function()
			_G.OSSettings.showHelpOnApplicationStart = false
			MineOSCore.saveOSSettings()
			
			container.panel.onTouch()
		end
	else
		MineOSCore.safeLaunch(path .. "/Main.lua")
		parentWindow:draw()
		buffer.draw()
	end
end

-----------------------------------------------------------------------------------------------------------------------------------

MineOSCore.init()

-----------------------------------------------------------------------------------------------------------------------------------

return MineOSCore





