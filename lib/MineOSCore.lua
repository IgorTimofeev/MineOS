
---------------------------------------------- Libraries ------------------------------------------------------------------------

local component = require("component")
local computer = require("computer")
local advancedLua = require("advancedLua")
local image = require("image")
local buffer = require("doubleBuffering")
local GUI = require("GUI")
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
MineOSCore.paths.wallpaper = "OS/Wallpaper.lnk"
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
				MineOSCore.safeLaunch("/MineOS/Applications/Finder.app/Finder.lua", "open", iconObject.path)
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
				MineOSCore.safeLaunch(iconObject.path)
			end
		elseif iconObject.format == ".pic" or iconObject.format == ".png" then
			iconObject.iconImage.image = MineOSCore.icons.image
			iconObject.launch = function()
				MineOSCore.safeLaunch("/MineOS/Applications/Viewer.app/Viewer.lua", "open", iconObject.path)
			end
		elseif iconObject.format == ".pkg" or iconObject.format == ".zip" then
			iconObject.iconImage.image = MineOSCore.icons.archive
			iconObject.launch = function()
				zip.unarchive(iconObject.path, (fs.path(iconObject.path) or ""))
			end
		elseif iconObject.format == ".3dm" then
			iconObject.iconImage.image = MineOSCore.icons.model3D
			iconObject.launch = function()
				MineOSCore.safeLaunch("/MineOS/Applications/3DPrint.app/3DPrint.lua", "open", iconObject.path)
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
				MineOSCore.safeLaunch("/bin/edit.lua", iconObject.path)
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

local function drawErrorWindow(path, programVersion, errorLine, reason, showSendToDeveloperButton)
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
	local window = require("windows").empty(x, y, width, height, width, height)
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
	local oldResolutionWidth, oldResolutionHeight = component.gpu.getResolution()
	local finalSuccess, finalReason = true, true
	local loadSuccess, loadReason = loadfile(string.canonicalPath("/" .. path))
	
	if fs.exists(path) then
		if loadSuccess then
			local function launcher()
				loadSuccess(table.unpack(args))
			end

			local runSuccess, runReason = xpcall(launcher, debug.traceback)
			if not runSuccess then
				if type(runReason) == "string" then
					if not string.find(runReason, "interrupted", 1, 15) then
						finalSuccess, finalReason = false, runReason
					end
				end
			end
		else
			finalSuccess, finalReason = false, loadReason
		end
	else
		finalSuccess, finalReason = false, unicode.sub(debug.traceback(), 19, -1)
	end

	if not finalSuccess then
		finalReason = string.canonicalPath("/" .. finalReason)
		local match = string.match(finalReason, "%/[^%:]+%:%d+%:")
		if match then
			local errorLine = tonumber(unicode.sub(string.match(match, "%:%d+%:"), 2, -2))
			local errorPath = unicode.sub(string.match(match, "%/[^%:]+%:"), 1, -2)

			--print(string.match("bad arg in cyka bla bla /lib/cyka.lua:2013:cykatest in path bin/pidor.lua:31:afa", "%/[^%:%/]+%:%d+%:"))

			--Проверяем, стоит ли нам врубать отсылку отчетов на мой сервер, ибо это должно быть онли у моих прожек
			local applications, applicationExists, programVersion = table.fromFile(MineOSCore.paths.applicationList), true, "N/A"
			-- errorPath = string.canonicalPath(errorPath)

			-- for i = 1, #applications do
			-- 	if errorPath == string.canonicalPath("/" .. applications[i].name) then
			-- 		applicationExists = true
			-- 		programVersion = math.doubleToString(applications[i].version, 2) or programVersion
			-- 		break
			-- 	end
			-- end

			drawErrorWindow(errorPath, programVersion, errorLine, finalReason, applicationExists)
		else
			GUI.error("Unknown error in lib/MineOSCore.lua due program execution: possible reason is \"" .. tostring(finalReason) .. "\"")
		end
	end

	component.gpu.setResolution(oldResolutionWidth, oldResolutionHeight)
	buffer.start()
end

-----------------------------------------------------------------------------------------------------------------------------------

function MineOSCore.iconLeftClick(iconObject, eventData)
	if iconObject.isDirectory then
		if iconObject.format == ".app" then
			iconObject.launch()
			computer.pushSignal("MineOSCore", "updateFileList")
		else
			computer.pushSignal("MineOSCore", "changeWorkpath", iconObject.path)
		end
	else
		iconObject.launch()
		computer.pushSignal("MineOSCore", "updateFileListAndBufferTrueRedraw")
	end
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
				"-",
				{MineOSCore.localization.contextMenuRename},
				{MineOSCore.localization.contextMenuCreateShortcut, icon.format == ".lnk"},
				-- "-",
				-- {MineOSCore.localization.contextMenuUploadToPastebin, true},
				"-",
				{MineOSCore.localization.contextMenuAddToDock},
				{MineOSCore.localization.contextMenuDelete}
			):show()
		else
			action = GUI.contextMenu(eventData[3], eventData[4],
				{MineOSCore.localization.contextMenuCut},
				{MineOSCore.localization.contextMenuCopy},
				{MineOSCore.localization.contextMenuRename},
				{MineOSCore.localization.contextMenuCreateShortcut, icon.format == ".lnk"},
				"-",
				{MineOSCore.localization.contextMenuArchive},
				"-",
				{MineOSCore.localization.contextMenuDelete}
			):show()
		end
	else
		if icon.format == ".pic" then
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
				{MineOSCore.localization.contextMenuDelete, false}
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
				{MineOSCore.localization.contextMenuDelete}
			):show()
		end
	end

	if action == MineOSCore.localization.contextMenuEdit then
		ecs.prepareToExit()
		MineOSCore.safeLaunch("/bin/edit.lua", icon.path)
		computer.pushSignal("MineOSCore", "updateFileListAndBufferTrueRedraw")
	elseif action == MineOSCore.localization.contextMenuEditInPhotoshop then
		MineOSCore.safeLaunch("MineOS/Applications/Photoshop.app/Photoshop.lua", "open", icon.path)
		computer.pushSignal("MineOSCore", "updateFileList")
	elseif action == MineOSCore.localization.contextMenuAddToFavourites then
		computer.pushSignal("finderFavouriteAdded", icon.path)
	elseif action == MineOSCore.localization.contextMenuShowPackageContent then
		computer.pushSignal("MineOSCore", "changeWorkpath", icon.path)
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

-----------------------------------------------------------------------------------------------------------------------------------

MineOSCore.init()

-----------------------------------------------------------------------------------------------------------------------------------

return MineOSCore





