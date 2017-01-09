
---------------------------------------------- Libraries ------------------------------------------------------------------------

local component = require("component")
local computer = require("computer")
local event = require("event")
local advancedLua = require("advancedLua")
local image = require("image")
local buffer = require("doubleBuffering")
local GUI = require("GUI")
local windows = require("windows")
local ecs = require("ECSAPI")
local zip = require("archive")
local syntax = require("syntax")
local fs = require("filesystem")
local unicode = require("unicode")

---------------------------------------------- Core constants ------------------------------------------------------------------------

local MineOSCore = {}

MineOSCore.showApplicationIcons = true
MineOSCore.iconWidth = 12
MineOSCore.iconHeight = 6
MineOSCore.iconClickDelay = 0.2

MineOSCore.paths = {}
MineOSCore.paths.OS = "/MineOS/"
MineOSCore.paths.system = MineOSCore.paths.OS .. "System/"
MineOSCore.paths.wallpaper = MineOSCore.paths.system .. "OS/Wallpaper.lnk"
MineOSCore.paths.localizationFile = MineOSCore.paths.system .. "OS/Languages/" .. _G.OSSettings.language .. ".lang"
MineOSCore.paths.icons = MineOSCore.paths.system .. "OS/Icons/"
MineOSCore.paths.applications = MineOSCore.paths.OS .. "Applications/"
MineOSCore.paths.pictures = MineOSCore.paths.OS .. "Pictures/"
MineOSCore.paths.desktop = MineOSCore.paths.OS .. "Desktop/"
MineOSCore.paths.applicationList = MineOSCore.paths.system .. "OS/Applications.txt"
MineOSCore.paths.trash = MineOSCore.paths.OS .. "Trash/"
MineOSCore.paths.OSSettings = MineOSCore.paths.system .. "OS/OSSettings.cfg"

MineOSCore.sortingMethods = enum(
	"type",
	"name",
	"date"
)

MineOSCore.localization = {}

---------------------------------------------- Current sсript processing methods ------------------------------------------------------------------------

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

---------------------------------------------- Filesystem-related methods ------------------------------------------------------------------------

local function getFilenameAndFormat(path)
	local fileName, format = string.match(path, "^(.+)(%..+)$")
	return (fileName or path), (format and string.gsub(format, "%/+$", "") or nil)
end

local function getFilePathAndName(path)
	local filePath, fileName = string.math(path, "^(.+%/)(.+)$")
	return (filePath or "/"), (fileName or path)
end

function MineOSCore.getFileFormat(path)
	local fileName, format = getFilenameAndFormat(path)
	return format
end

function MineOSCore.hideFileFormat(path)
	local fileName, format = getFilenameAndFormat(path)
	return fileName
end

function MineOSCore.isFileHidden(path)
	if string.match(path, "^%..+$") then return true end
	return false
end

function MineOSCore.getFileList(path)
	if not fs.exists(path) then error("Failed to get file list: directory \"" .. tostring(path) .. "\" doesn't exists") end
	if not fs.isDirectory(path) then error("Failed to get file list: path \"" .. tostring(path) .. "\" is not a directory") end

	local fileList = {}
	for file in fs.list(path) do table.insert(fileList, file) end
	return fileList
end

function MineOSCore.sortFileList(path, fileList, sortingMethod, showHiddenFiles)
	local sortedFileList = {}

	if sortingMethod == MineOSCore.sortingMethods.type then
		local typeList = {}
		for i = 1, #fileList do
			local fileFormat = MineOSCore.getFileFormat(fileList[i]) or "Script"
			if fs.isDirectory(path .. fileList[i]) and fileFormat ~= ".app" then fileFormat = "Folder" end
			typeList[fileFormat] = typeList[fileFormat] or {}
			table.insert(typeList[fileFormat], fileList[i])
		end

		if typeList.Folder then
			for i = 1, #typeList.Folder do
				table.insert(sortedFileList, typeList.Folder[i])
			end
			typeList["Folder"] = nil
		end

		for fileFormat in pairs(typeList) do
			for i = 1, #typeList[fileFormat] do
				table.insert(sortedFileList, typeList[fileFormat][i])
			end
		end
	elseif MineOSCore.sortingMethods.name then
		sortedFileList = fileList
	elseif MineOSCore.sortingMethods.date then
		for i = 1, #fileList do
			fileList[i] = {fileList[i], fs.lastModified(path .. fileList[i])}
		end
		table.sort(fileList, function(a,b) return a[2] > b[2] end)
		for i = 1, #fileList do
			table.insert(sortedFileList, fileList[i][1])
		end
	else
		error("Unknown sorting method: " .. tostring(sortingMethod))
	end

	local i = 1
	while i <= #sortedFileList do
		if not showHiddenFiles and MineOSCore.isFileHidden(sortedFileList[i]) then
			table.remove(sortedFileList, i)
		else
			i = i + 1
		end
	end

	return sortedFileList
end

function MineOSCore.limitFileName(text, limit)
	if unicode.len(text) > limit then
		local partSize = math.ceil(limit / 2)
		text = unicode.sub(text, 1, partSize) .. "…" .. unicode.sub(text, -partSize + 1, -1)
	end
	return text
end

---------------------------------------------- MineOS Icons related methods ------------------------------------------------------------------------

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
end

function MineOSCore.init()
	MineOSCore.localization = table.fromFile(MineOSCore.paths.localizationFile)
	MineOSCore.loadStandartIcons()
end

local function waitForPressingAnyKey()
	print(" ")
	print(MineOSCore.localization.pressAnyKeyToContinue)
	while true do
		local eventType = event.pull()
		if eventType == "key_down" or eventType == "touch" then break end
	end
end

function MineOSCore.analyseIconFormat(iconObject)
	if iconObject.isDirectory then
		if iconObject.format == ".app" then
			if MineOSCore.showApplicationIcons then
				iconObject.iconImage.image = image.load(iconObject.path .. "/Resources/Icon.pic")
			else
				iconObject.iconImage.image = MineOSCore.icons.application
			end

			iconObject.launch = function()
				ecs.applicationHelp(iconObject.path)
				MineOSCore.safeLaunch(iconObject.path .. "/" .. MineOSCore.hideFileFormat(fs.name(iconObject.path)) .. ".lua")
			end
		else
			iconObject.iconImage.image = MineOSCore.icons.folder
			iconObject.launch = function()
				computer.pushSignal("MineOSCore", "changeWorkpath", iconObject.path)
			end
		end
	else
		if iconObject.format == ".lnk" then
			iconObject.shortcutPath = ecs.readShortcut(iconObject.path)
			iconObject.shortcutFormat = MineOSCore.getFileFormat(iconObject.shortcutPath)
			iconObject.shortcutIsDirectory = fs.isDirectory(iconObject.shortcutPath)
			iconObject.isShortcut = true

			local shortcutIconObject = MineOSCore.analyseIconFormat({
				path = iconObject.shortcutPath,
				format = iconObject.shortcutFormat,
				isDirectory = iconObject.shortcutIsDirectory,
				iconImage = iconObject.iconImage
			})

			iconObject.iconImage.image = shortcutIconObject.iconImage.image
			iconObject.launch = shortcutIconObject.launch

			shortcutIconObject = nil
		elseif iconObject.format == ".cfg" or iconObject.format == ".config" then
			iconObject.iconImage.image = MineOSCore.icons.config
			iconObject.launch = function()
				ecs.prepareToExit()
				MineOSCore.safeLaunch("/bin/edit.lua", iconObject.path)
			end
		elseif iconObject.format == ".txt" or iconObject.format == ".rtf" then
			iconObject.iconImage.image = MineOSCore.icons.text
			iconObject.launch = function()
				ecs.prepareToExit()
				MineOSCore.safeLaunch("/bin/edit.lua", iconObject.path)
			end
		elseif iconObject.format == ".lua" then
		 	iconObject.iconImage.image = MineOSCore.icons.lua
		 	iconObject.launch = function()
				ecs.prepareToExit()
				if MineOSCore.safeLaunch(iconObject.path) then
					waitForPressingAnyKey()
				end
			end
		elseif iconObject.format == ".pic" or iconObject.format == ".png" then
			iconObject.iconImage.image = MineOSCore.icons.image
			iconObject.launch = function()
				MineOSCore.safeLaunch(MineOSCore.paths.applications .. "Viewer.app/Viewer.lua", "open", iconObject.path)
			end
		elseif iconObject.format == ".pkg" or iconObject.format == ".zip" then
			iconObject.iconImage.image = MineOSCore.icons.archive
			iconObject.launch = function()
				zip.unarchive(iconObject.path, (fs.path(iconObject.path) or ""))
			end
		elseif iconObject.format == ".3dm" then
			iconObject.iconImage.image = MineOSCore.icons.model3D
			iconObject.launch = function()
				MineOSCore.safeLaunch(MineOSCore.paths.applications .. "3DPrint.app/3DPrint.lua", "open", iconObject.path)
			end
		elseif not fs.exists(iconObject.path) then
			iconObject.iconImage.image = MineOSCore.icons.fileNotExists
			iconObject.launch = function()
				GUI.error("Application is corrupted")
			end
		else
			iconObject.iconImage.image = MineOSCore.icons.script
			iconObject.launch = function()
				ecs.prepareToExit()
				if MineOSCore.safeLaunch(iconObject.path) then
					waitForPressingAnyKey()
				end
			end
		end
	end

	return iconObject
end

function MineOSCore.getParametersForDrawingIcons(fieldWidth, fieldHeight, xSpaceBetweenIcons, ySpaceBetweenIcons)
	local xCountOfIcons, yCountOfIcons = math.floor(fieldWidth / (MineOSCore.iconWidth + xSpaceBetweenIcons)), math.floor(fieldHeight / (MineOSCore.iconHeight + ySpaceBetweenIcons))
	local totalCountOfIcons = xCountOfIcons * yCountOfIcons
	return xCountOfIcons, yCountOfIcons, totalCountOfIcons
end

function MineOSCore.createIconObject(x, y, path, textColor, showFileFormat)
	local iconObject = GUI.container(x, y, MineOSCore.iconWidth, MineOSCore.iconHeight)
	
	iconObject.path = path
	iconObject.size = fs.size(iconObject.path)
	iconObject.isDirectory = fs.isDirectory(iconObject.path)
	iconObject.format = MineOSCore.getFileFormat(iconObject.path)
	iconObject.showFormat = showFileFormat
	iconObject.isShortcut = false
	iconObject.isSelected = false

	iconObject.iconImage = iconObject:addImage(3, 1, {width = 8, height = 4})
	iconObject.textLabel = iconObject:addLabel(1, MineOSCore.iconHeight, MineOSCore.iconWidth, 1, textColor, fs.name(iconObject.path)):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	
	local oldDraw = iconObject.draw
	iconObject.draw = function(iconObject)
		if iconObject.isSelected then buffer.square(iconObject.x, iconObject.y, iconObject.width, iconObject.height, 0xFFFFFF, 0x000000, " ", 50) end
		if iconObject.showFormat then
			iconObject.textLabel.text = MineOSCore.limitFileName(fs.name(iconObject.path), iconObject.textLabel.width)
		else
			iconObject.textLabel.text = MineOSCore.limitFileName(MineOSCore.hideFileFormat(fs.name(iconObject.path)), iconObject.textLabel.width)
		end
		oldDraw(iconObject)
		if iconObject.isShortcut then buffer.set(iconObject.iconImage.x + iconObject.iconImage.width - 1, iconObject.iconImage.y + iconObject.iconImage.height - 1, 0xFFFFFF, 0x000000, "<") end
	end

	-- Поддержка изменяемых извне функций правого и левого кликов
	iconObject.onLeftClick = MineOSCore.iconLeftClick
	iconObject.onRightClick = MineOSCore.iconRightClick

	-- Обработка клика непосредственно на иконку
	iconObject.iconImage.onTouch = function(eventData)
		iconObject.isSelected = true
		local firstParent = iconObject:getFirstParent()
		firstParent:draw()
		buffer.draw()

		if eventData[5] == 0 then
			os.sleep(MineOSCore.iconClickDelay)
			iconObject.onLeftClick(iconObject, eventData)
		else
			iconObject.onRightClick(iconObject, eventData)
		end

		iconObject.isSelected = false
		firstParent:draw()
		buffer.draw()
	end

	-- Онализ формата и прочего говна иконки для последующего получения изображения иконки и функции-лаунчера
	MineOSCore.analyseIconFormat(iconObject)
	
	return iconObject
end

local function updateIconFieldFileList(iconField)
	iconField.fileList = MineOSCore.getFileList(iconField.workpath)
	iconField.fileList = MineOSCore.sortFileList(iconField.workpath, iconField.fileList, iconField.sortingMethod, iconField.showHiddenFiles)
	iconField.children = {}

	local xPos, yPos, counter = 1, 1, 1
	for i = iconField.fromFile, iconField.fromFile + iconField.iconCount.total - 1 do
		if not iconField.fileList[i] then break end

		iconField:addChild(
			MineOSCore.createIconObject(
				xPos, yPos, iconField.workpath .. iconField.fileList[i], iconField.colors.iconText, iconField.showFileFormat
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

function MineOSCore.createIconField(x, y, width, height, xCountOfIcons, yCountOfIcons, totalCountOfIcons, xSpaceBetweenIcons, ySpaceBetweenIcons, iconTextColor, showFileFormat, showHiddenFiles, sortingMethod, workpathworkpath)
	local iconField = GUI.container(x, y, width, height)

	iconField.colors = {iconText = iconTextColor}

	iconField.iconCount = {}
	iconField.spaceBetweenIcons = {x = xSpaceBetweenIcons, y = ySpaceBetweenIcons}
	iconField.iconCount.width, iconField.iconCount.height, iconField.iconCount.total = xCountOfIcons, yCountOfIcons, totalCountOfIcons

	iconField.workpath = workpath
	iconField.showFileFormat = showFileFormat
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
	local drawLimit = buffer.getDrawLimit(); buffer.resetDrawLimit()
	local colors = { topBar = 0x383838, title = 0xFFFFFF }
	local programName = MineOSCore.localization.errorWhileRunningProgram .. "\"" .. fs.name(path) .. "\""
	local width, height = buffer.screen.width, math.floor(buffer.screen.height * 0.45)
	local x, y = 1, math.floor(buffer.screen.height / 2 - height / 2)
	local codeWidth, codeHeight = math.floor(width * 0.62), height - 3
	local stackWidth = width - codeWidth

	-- Затенение оконца
	buffer.clear(0x000000, 50)

	-- Окошечко и всякая шняжка на нем
	local window = windows.empty(x, y, width, height, width, height)
	window:addPanel(1, 1, width, 3, colors.topBar)
	window:addLabel(1, 2, width, 1, colors.title, programName):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	local windowActionButtons = window:addWindowActionButtons(2, 2, false)
	local sendToDeveloperButton = window:addAdaptiveButton(9, 1, 2, 1, 0x444444, 0xFFFFFF, 0x343434, 0xFFFFFF, MineOSCore.localization.sendFeedback)
	local stackTextBox = window:addTextBox(codeWidth + 1, 4, stackWidth, codeHeight, 0xFFFFFF, 0x000000, string.wrap(MineOSCore.parseErrorMessage(reason, 4), stackWidth - 2), 1, 1, 0)
	--Рисуем окошечко, чтобы кодику не было ОБИДНО
	--!!1
	window:draw()

	--Кодик на окошечке
	local strings = {}
	local fromString = errorLine - math.floor((codeHeight - 1) / 2); if fromString < 0 then fromString = 1 end
	local toString = fromString + codeHeight - 1
	local file = io.open(path, "r")
	local lineCounter = 1
	for line in file:lines() do
		if lineCounter >= fromString and lineCounter <= toString then
			line = string.gsub(line, "	", "  ")
			table.insert(strings, line)
		elseif lineCounter > toString then
			break
		end
		lineCounter = lineCounter + 1
	end
	file:close()
	syntax.viewCode(
		{
			x = x,
			y = y + 3,
			width = codeWidth,
			height = codeHeight, 
			strings = strings, 
			maximumStringWidth = 50,
			fromSymbol = 1,
			fromString = 1,
			fromStringOnLineNumbers = fromString,
			highlightLuaSyntax = true,
			highlightedStrings = {[errorLine] = 0xFF4444},
			scrollbars = {
				vertical = true,
				horizontal = false,
			}
		}
	)

	-- Всякие действия пиздатые
	local function exit()
		windowActionButtons.close:pressAndRelease()
		buffer.setDrawLimit(drawLimit)
		window:close()
	end
	
	windowActionButtons.close.onTouch = exit
	
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
				local url = "http://igortimofeev.wallst.ru/MineOSErrorReports/Report.php?path=" .. path .. "&version=" .. string.optimizeForURLRequests(programVersion) .. "&userContacts=" .. string.optimizeForURLRequests(data[1]) .. "&userMessage=" .. string.optimizeForURLRequests(data[2]) .. "&errorMessage=" .. string.optimizeForURLRequests(reason)
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
				local traceback, info, firstMatch = xpcallTraceback .. "\n" .. debug.traceback()
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
			if not runSuccess and not string.find(runReason.traceback, "interrupted", 1, 15) then
				finalSuccess, finalPath, finalLine, finalTraceback = false, runReason.path, runReason.line, runReason.traceback
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

	component.gpu.setResolution(oldResolutionWidth, oldResolutionHeight)
	buffer.start()

	return finalSuccess, finalPath, finalLine, finalTraceback
end

-----------------------------------------------------------------------------------------------------------------------------------

function MineOSCore.iconLeftClick(iconObject, eventData)
	iconObject.launch()
	computer.pushSignal("MineOSCore", "updateFileList")
end

function MineOSCore.iconRightClick(icon, eventData)
	local action
	-- Разные контекстные меню
	if icon.isDirectory then
		if icon.format == ".app" then
			action = GUI.contextMenu(eventData[3], eventData[4],
				{MineOSCore.localization.contextMenuShowPackageContent},
				"-",
				{MineOSCore.localization.contextMenuCut},
				{MineOSCore.localization.contextMenuCopy},
				{MineOSCore.localization.contextMenuRename},
				{MineOSCore.localization.contextMenuCreateShortcut, icon.format == ".lnk"},
				-- "-",
				-- {MineOSCore.localization.contextMenuUploadToPastebin, true},
				"-",
				{MineOSCore.localization.contextMenuAddToDock},
				{MineOSCore.localization.contextMenuProperties},
				{MineOSCore.localization.contextMenuDelete}
			):show()
		else
			action = GUI.contextMenu(eventData[3], eventData[4],
				{MineOSCore.localization.contextMenuCut},
				{MineOSCore.localization.contextMenuCopy},
				{MineOSCore.localization.contextMenuRename},
				{MineOSCore.localization.contextMenuCreateShortcut, icon.format == ".lnk"},
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
		elseif icon.format == ".pic" then
			action = GUI.contextMenu(eventData[3], eventData[4],
				-- {MineOSCore.localization.contextMenuEdit},
				{MineOSCore.localization.contextMenuEditInPhotoshop},
				{MineOSCore.localization.contextMenuSetAsWallpaper},
				"-",
				{MineOSCore.localization.contextMenuCut},
				{MineOSCore.localization.contextMenuCopy},
				{MineOSCore.localization.contextMenuRename},
				{MineOSCore.localization.contextMenuCreateShortcut, icon.format == ".lnk"},
				-- "-",
				-- {MineOSCore.localization.contextMenuUploadToPastebin, true},
				"-",
				{MineOSCore.localization.contextMenuAddToDock},
				{MineOSCore.localization.contextMenuProperties},
				{MineOSCore.localization.contextMenuDelete}
			):show()
		elseif icon.format == ".lua" then
			action = GUI.contextMenu(eventData[3], eventData[4],
				{MineOSCore.localization.contextMenuEdit},
				{MineOSCore.localization.contextMenuFlashEEPROM, (not component.isAvailable("eeprom") or icon.size > 4096)},
				{MineOSCore.localization.contextMenuCreateApplication},
				"-",
				{MineOSCore.localization.contextMenuCut},
				{MineOSCore.localization.contextMenuCopy},
				{MineOSCore.localization.contextMenuRename},
				{MineOSCore.localization.contextMenuCreateShortcut, icon.format == ".lnk"},
				-- "-",
				-- {MineOSCore.localization.contextMenuUploadToPastebin, true},
				"-",
				{MineOSCore.localization.contextMenuAddToDock},
				{MineOSCore.localization.contextMenuProperties},
				{MineOSCore.localization.contextMenuDelete}
			):show()
		else
			action = GUI.contextMenu(eventData[3], eventData[4],
				{MineOSCore.localization.contextMenuEdit},
				-- {MineOSCore.localization.contextMenuCreateApplication},
				"-",
				{MineOSCore.localization.contextMenuCut},
				{MineOSCore.localization.contextMenuCopy},
				{MineOSCore.localization.contextMenuRename},
				{MineOSCore.localization.contextMenuCreateShortcut, icon.format == ".lnk"},
				-- "-",
				-- {MineOSCore.localization.contextMenuUploadToPastebin, true},
				"-",
				{MineOSCore.localization.contextMenuAddToDock},
				{MineOSCore.localization.contextMenuProperties},
				{MineOSCore.localization.contextMenuDelete}
			):show()
		end
	end

	if action == MineOSCore.localization.contextMenuEdit then
		ecs.prepareToExit()
		MineOSCore.safeLaunch("/bin/edit.lua", icon.path)
		computer.pushSignal("MineOSCore", "updateFileList")
	elseif action == "Свойства" then
		MineOSCore.showPropertiesWindow(eventData[3], eventData[4], 36, 11, icon)
	elseif action == MineOSCore.localization.contextMenuShowContainingFolder then
		computer.pushSignal("MineOSCore", "changeWorkpath", fs.path(icon.shortcutPath))
		computer.pushSignal("MineOSCore", "updateFileList")
	elseif action == MineOSCore.localization.contextMenuEditInPhotoshop then
		MineOSCore.safeLaunch("MineOS/Applications/Photoshop.app/Photoshop.lua", "open", icon.path)
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
		fs.remove(icon.path)
		computer.pushSignal("MineOSCore", "updateFileList")
	elseif action == MineOSCore.localization.contextMenuRename then
		ecs.rename(icon.path)
		computer.pushSignal("MineOSCore", "updateFileList")
	elseif action == MineOSCore.localization.contextMenuCreateShortcut then
		ecs.createShortCut(fs.path(icon.path) .. "/" .. ecs.hideFileFormat(fs.name(icon.path)) .. ".lnk", icon.path)
		computer.pushSignal("MineOSCore", "updateFileList")
	elseif action == MineOSCore.localization.contextMenuArchive then
		-- ecs.info("auto", "auto", "", "Архивация файлов...")
		archive.pack(ecs.hideFileFormat(fs.name(icon.path))..".pkg", icon.path)
		computer.pushSignal("MineOSCore", "updateFileList")
	elseif action == MineOSCore.localization.contextMenuSetAsWallpaper then
		fs.remove(MineOSCore.paths.wallpaper)
		ecs.createShortCut(MineOSCore.paths.wallpaper, icon.path)
		computer.pushSignal("MineOSCore", "updateWallpaper")
	elseif action == MineOSCore.localization.contextMenuFlashEEPROM then
		local file = io.open(icon.path, "r")
		component.eeprom.set(file:read("*a"))
		file:close()
		computer.beep(1500, 0.2)
	elseif action == MineOSCore.localization.contextMenuCreateApplication then
		ecs.newApplicationFromLuaFile(icon.path, fs.path(icon.path) or "")
		computer.pushSignal("MineOSCore", "updateFileList")
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
		ecs.newFile(workpath)
		computer.pushSignal("MineOSCore", "updateFileListAndBufferTrueRedraw")
	elseif action == MineOSCore.localization.contextMenuNewFolder then
		ecs.newFolder(workpath)
		computer.pushSignal("MineOSCore", "updateFileList")
	elseif action == MineOSCore.localization.contextMenuPaste then
		ecs.copy(_G.clipboard, workpath)
		if _G.clipboardCut then
			fs.remove(_G.clipboard)
			_G.clipboardCut = nil
			_G.clipboard = nil
		end
		computer.pushSignal("MineOSCore", "updateFileList")
	elseif action == MineOSCore.localization.contextMenuNewApplication then
		ecs.newApplication(workpath)
		computer.pushSignal("MineOSCore", "updateFileList")
	end
end

local function addKeyAndValue(window, x, y, key, value)
	window:addLabel(x, y, window.width , 1, 0x333333, key .. ":"); x = x + unicode.len(key) + 2
	window:addLabel(x, y, window.width, 1, 0x555555, value)
end

function MineOSCore.showPropertiesWindow(x, y, width, height, iconObject)
	local window = windows.empty(x, y, width, height)
	local backgroundPanel = window:addPanel(1, 2, window.width, window.height - 1, 0xFFFFFF, 20)
	window:addPanel(1, 1, window.width, 1, 0xEEEEEE)
	window:addLabel(1, 1, window.width, 1, 0x333333, MineOSCore.localization.contextMenuProperties):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	window:addButton(2, 1, 1, 1, nil, 0xFF4940, nil, 0x992400, "●").onTouch = function() window:close() end

	window:addImage(3, 3, iconObject.iconImage.image)

	local y = 3
	addKeyAndValue(window, 13, y, MineOSCore.localization.type, iconObject.format and unicode.upper(unicode.sub(iconObject.format, 2, 2)) .. unicode.sub(iconObject.format, 3, -1) or (iconObject.isDirectory and MineOSCore.localization.folder or MineOSCore.localization.unknown)); y = y + 1
	if not iconObject.isDirectory then addKeyAndValue(window, 13, y, MineOSCore.localization.size, math.ceil(iconObject.size / 1024) .. "KB"); y = y + 1 end
	addKeyAndValue(window, 13, y, MineOSCore.localization.date, os.date("%d.%m.%y, %H:%M", fs.lastModified(iconObject.path))); y = y + 1
	addKeyAndValue(window, 13, y, MineOSCore.localization.path, " ")

	local lines = string.wrap(iconObject.path, window.width - 19)
	local textBox = window:addTextBox(19, y, window.width - 19, #lines, nil, 0x555555, lines, 1)
	window.height = textBox.y + textBox.height 
	backgroundPanel.height = window.height - 1

	if window.x + window.width > buffer.screen.width then window.x = window.x - (window.x + window.width - buffer.screen.width) end
	if window.y + window.height > buffer.screen.height then window.y = window.y - (window.y + window.height - buffer.screen.height) end

	window:draw()
	GUI.windowShadow(window.x, window.y, window.width, window.height, 50, true)
	buffer.draw()
	window:handleEvents()
end

-----------------------------------------------------------------------------------------------------------------------------------

MineOSCore.init()

-----------------------------------------------------------------------------------------------------------------------------------

return MineOSCore





