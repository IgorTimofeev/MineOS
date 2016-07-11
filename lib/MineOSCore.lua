---------------------------------------------- Библиотеки ------------------------------------------------------------------------

local libraries = {
	computer = "computer",
	ecs = "ECSAPI",
	component = "component",
	files = "files",
	fs = "filesystem",
	context = "context",
	buffer = "doubleBuffering",
	image = "image",
	GUI = "GUI",
	zip = "archive",
	syntax = "syntax",
}

for library in pairs(libraries) do if not _G[library] then _G[library] = require(libraries[library]) end end
libraries = nil

local MineOSCore = {}

-----------------------------------------------------------------------------------------------------------------------------------

MineOSCore.iconWidth = 12
MineOSCore.iconHeight = 6

MineOSCore.paths = {
	localizationFile = "MineOS/System/OS/Languages/" .. _G.OSSettings.language .. ".lang",
	system = "MineOS/System/",
	icons = "MineOS/System/OS/Icons/",
	applications = "MineOS/Applications/",
	pictures = "MineOS/Pictures/",
	applicationList = "MineOS/System/OS/Applications.txt",
}

MineOSCore.sortingMethods = {
	type = 0,
	name = 1,
	date = 2,
}

MineOSCore.colors = {
	background = 0x262626.
}

MineOSCore.localization = {}

-----------------------------------------------------------------------------------------------------------------------------------

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
end

function MineOSCore.init()
	MineOSCore.localization = files.loadTableFromFile(MineOSCore.paths.localizationFile)
	MineOSCore.loadStandartIcons()
end

-----------------------------------------------------------------------------------------------------------------------------------

--Отрисовка одной иконки
function MineOSCore.drawIcon(x, y, path, showFileFormat, nameColor, name)
	local fileFormat, icon = ecs.getFileFormat(path)

	if fs.isDirectory(path) then
		if fileFormat == ".app" then
			icon = "cyka"
			MineOSCore.icons[icon] = image.load(path .. "/Resources/Icon.pic")
			-- icon = path .. "/Resources/Icon.pic"
			-- MineOSCore.loadIcon(icon, icon)
		else
			icon = "folder"
		end
	else
		if fileFormat == ".lnk" then
			MineOSCore.drawIcon(x, y, ecs.readShortcut(path), showFileFormat, nameColor, fs.name(path))
			buffer.set(x + MineOSCore.iconWidth - 3, y + MineOSCore.iconHeight - 3, 0xFFFFFF, 0x000000, "<")
			return 0
		elseif fileFormat == ".cfg" or fileFormat == ".config" then
			icon = "config"
		elseif fileFormat == ".txt" or fileFormat == ".rtf" then
			icon = "text"
		elseif fileFormat == ".lua" then
		 	icon = "lua"
		elseif fileFormat == ".pic" or fileFormat == ".png" then
		 	icon = "image"
		elseif fileFormat == ".paste" then
			icon = "pastebin"
		elseif fileFormat == ".pkg" then
			icon = "archive"
		elseif fileFormat == ".3dm" then
			icon = "model3D"
		elseif not fs.exists(path) then
			icon = "fileNotExists"
		else
			icon = "script"
		end
	end

	--Рисуем иконку
	buffer.image(x + 2, y, MineOSCore.icons[icon])

	--Делаем текст для иконки
	local text = name or fs.name(path)
	if not showFileFormat and fileFormat then text = unicode.sub(text, 1, -(unicode.len(fileFormat) + 1)) end
	text = ecs.stringLimit("end", text, MineOSCore.iconWidth)
	x = x + math.floor(MineOSCore.iconWidth / 2 - unicode.len(text) / 2)
	--Рисуем текст под иконкой
	buffer.text(x, y + MineOSCore.iconHeight - 1, nameColor or 0xffffff, text)
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

--Функция-оптимизатор говносимволов для урлек, пробелсы там в %20 и т.п.
function MineOSCore.optimizeStringForURLSending(code)
	if code then
	code = string.gsub(code, "([^%w ])", function (c)
		return string.format("%%%02X", string.byte(c))
	end)
		code = string.gsub(code, " ", "+")
	end
	return code 
end

local function drawErrorWindow(path, errorLine, reason, showSendToDeveloperButton)
	local topbarColor = 0x383838
	local programName = "Ошибка при выполнении " .. fs.name(path)
	local width, height = buffer.screen.width, math.floor(buffer.screen.height * 0.45)
	local x, y = 1, math.floor(buffer.screen.height / 2 - height / 2)
	local topbarHeight = 3
	local codeHeight = height - topbarHeight - 3
	local codeWidth = math.floor(width * 0.62)
	local stackWidth = width - codeWidth
	local buttons = {}

	--Фончик
	buffer.square(1, 1, buffer.screen.width, buffer.screen.height, 0x000000, 0x000000, " ", 50)

	--Топбарчик
	buffer.square(x, y, width, topbarHeight, topbarColor, 0xFFFFFF, " ")
	buffer.text(math.floor(x + width / 2 - unicode.len(programName) / 2), y + 1, 0xFFFFFF, programName)

	--Кнопачки
	buttons = GUI.windowActionButtons(x + 1, y + 1, false)
	if showSendToDeveloperButton and component.isAvailable("internet") then buttons.sendToDeveloper = GUI.adaptiveButton(x + 8, y, 2, 1, 0x444444, 0xFFFFFF, 0x343434, 0xFFFFFF, "Отправить отчет") end
	y = y + topbarHeight

	--Кодик
	local strings = {}
	local fromString = errorLine - math.floor((codeHeight - 1) / 2)
	if fromString < 0 then fromString = 1 end
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
			y = y,
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

	--Стек
	strings = GUI.stringWrap(MineOSCore.parseErrorMessage(reason, 4), stackWidth - 2)
	x = x + codeWidth
	buffer.square(x, y, stackWidth, codeHeight, 0xFFFFFF)
	x = x + 1
	for i = 1, #strings do buffer.text(x, y, 0x000000, strings[i]); y = y + 1; if i > codeHeight - 1 then break end end

	buffer.draw()
	for i = 1, 2 do component.computer.beep(1500, 0.1) end

	--Ивентовая параша
	while true do
		local e = {event.pull()}
		if e[1] == "touch" then
			for objectName, button in pairs(buttons) do
				if button:isClicked(e[3], e[4]) then
					button:press()
					if objectName == "close" then
						return
					elseif objectName == "sendToDeveloper" then
						local data = ecs.universalWindow("auto", "auto", 36, 0xeeeeee, true,
							{"EmptyLine"},
							{"CenterText", 0x880000, "Отправить отчет"},
							{"EmptyLine"},
							{"Input", 0x262626, 0x880000, "Ваше имя"},
							{"Input", 0x262626, 0x880000, "Сообщение разработчику"},
							{"EmptyLine"},
							{"CenterText", 0x880000, "Стек ошибки"},
							{"EmptyLine"},
							{"TextField", 5, 0xFFFFFF, 0x000000, 0xcccccc, 0x3366CC, reason},
							{"Button", {0x999999, 0xffffff, "OK"}, {0x777777, 0xffffff, "Отмена"}}
						)

						if data[3] == "OK" then
							if component.isAvailable("internet") then
								local phpUrl = "http://igortimofeev.wallst.ru/MineOSErrorReports/Report.php"
								local url = phpUrl .. "?path=" .. path .. "&errorMessage=" .. MineOSCore.optimizeStringForURLSending(reason) .. "&userMessage=" .. MineOSCore.optimizeStringForURLSending(data[2]) .. "&userContacts=" .. MineOSCore.optimizeStringForURLSending(data[1])
								local success, reason = component.internet.request(url)
								if success then
									success:close()
								else
									ecs.error(reason)
								end
							end

							return
						end
					end

					break
				end
			end
		end
	end
end

function MineOSCore.safeLaunch(path, ...)
	local args = {...}
	local oldResolutionWidth, oldResolutionHeight = component.gpu.getResolution()
	local finalSuccess, finalReason = true, true
	local loadSuccess, loadReason = loadfile(path)
	
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

	if not finalSuccess then
		local errorLine = 1
		local starting, ending = string.find(finalReason, "%:%d+%:")
		if starting and ending then
			path = unicode.sub(finalReason, 2, starting - 1)
			errorLine = tonumber(unicode.sub(finalReason, starting + 1, ending - 1))
		end

		local applications = files.loadTableFromFile(MineOSCore.paths.applicationList)
		local applicationExists = false
		for i = 1, #applications do if path == applications[i].name then applicationExists = true; break end end

		drawErrorWindow(path, errorLine, finalReason, applicationExists)
	end

	component.gpu.setResolution(oldResolutionWidth, oldResolutionHeight)
	buffer.start()
end

-----------------------------------------------------------------------------------------------------------------------------------

-- Запуск приложения
function MineOSCore.launchIcon(path, translate)
	--Получаем файл формат заранее
	local fileFormat = ecs.getFileFormat(path)
	local isDirectory = fs.isDirectory(path)
	--Если это приложение
	if fileFormat == ".app" then
		ecs.applicationHelp(path)
		MineOSCore.safeLaunch(path .. "/" .. ecs.hideFileFormat(fs.name(path)) .. ".lua")
	--Если это папка
	elseif (fileFormat == "" or fileFormat == nil) and isDirectory then
		MineOSCore.safeLaunch("MineOS/Applications/Finder.app/Finder.lua", "open", path)
	--Если это обычный луа файл - т.е. скрипт
	elseif fileFormat == ".lua" or fileFormat == nil then
		buffer.clear(MineOSCore.colors.background)
		ecs.prepareToExit()
		MineOSCore.safeLaunch(path)
	
	--Если это фоточка
	elseif fileFormat == ".pic" then
		MineOSCore.safeLaunch("MineOS/Applications/Viewer.app/Viewer.lua", "open", path)
	
	--Если это 3D-модель
	elseif fileFormat == ".3dm" then
		MineOSCore.safeLaunch("MineOS/Applications/3DPrint.app/3DPrint.lua open " .. path)
	
	--Если это текст или конфиг или языковой
	elseif fileFormat == ".txt" or fileFormat == ".cfg" or fileFormat == ".MineOSCore.localization" then
		ecs.prepareToExit()
		MineOSCore.safeLaunch("bin/edit.lua", path)

	--Если это ярлык
	elseif fileFormat == ".lnk" then
		local shortcutLink = ecs.readShortcut(path)
		if fs.exists(shortcutLink) then
			MineOSCore.launchIcon(shortcutLink)
		else
			GUI.error(MineOSCore.localization.shortcutIsCorrupted)
		end
	
	--Если это архив
	elseif fileFormat == ".zip" then
		zip.unarchive(path, (fs.path(path) or ""))
	end
end

-----------------------------------------------------------------------------------------------------------------------------------

function MineOSCore.getParametersForDrawingIcons(fieldWidth, fieldHeight, xSpaceBetweenIcons, ySpaceBetweenIcons)
	local xCountOfIcons, yCountOfIcons = math.floor(fieldWidth / (MineOSCore.iconWidth + xSpaceBetweenIcons)), math.floor(fieldHeight / (MineOSCore.iconHeight + ySpaceBetweenIcons))
	local totalCountOfIcons = xCountOfIcons * yCountOfIcons
	return xCountOfIcons, yCountOfIcons, totalCountOfIcons
end

function MineOSCore.drawIconField(x, y, xCountOfIcons, yCountOfIcons, fromIcon, totalCountOfIcons, xSpaceBetweenIcons, ySpaceBetweenIcons, path, fileList, showFileFormat, iconTextColor)
	local iconObjects = {}

	local xPos, yPos, iconCounter = x, y, 1
	for i = fromIcon, (fromIcon + totalCountOfIcons - 1) do
		if not fileList[i] then break end

		local iconObject = GUI.object(xPos, yPos, MineOSCore.iconWidth, MineOSCore.iconHeight)
		iconObject.path = path .. fileList[i]
		table.insert(iconObjects, iconObject)
		MineOSCore.drawIcon(xPos, yPos, iconObject.path, showFileFormat, iconTextColor)

		xPos = xPos + MineOSCore.iconWidth + xSpaceBetweenIcons
		iconCounter = iconCounter + 1
		if iconCounter > xCountOfIcons then
			xPos = x
			yPos = yPos + MineOSCore.iconHeight + ySpaceBetweenIcons
			iconCounter = 1
		end
	end

	return iconObjects
end

-----------------------------------------------------------------------------------------------------------------------------------

local function executeMethod(methodArray)
	methodArray.method(table.unpack(methodArray.arguments))
end

function MineOSCore.iconSelect(icon, selectionColor, selectionTransparency, iconTextColor)
	local oldPixelsOfIcon = buffer.copy(icon.x, icon.y, MineOSCore.iconWidth, MineOSCore.iconHeight)
	buffer.square(icon.x, icon.y, MineOSCore.iconWidth, MineOSCore.iconHeight, selectionColor, 0xFFFFFF, " ", selectionTransparency)
	MineOSCore.drawIcon(icon.x, icon.y, icon.path, false, iconTextColor)
	buffer.draw()
	return oldPixelsOfIcon
end

function MineOSCore.iconLeftClick(icon, oldPixelsOfIcon, fileFormat, drawAllMethod, fullRefreshMethod, changeCurrentPathMethod)
	if fs.isDirectory(icon.path) then
		if fileFormat == ".app" then
			MineOSCore.launchIcon(icon.path)
			executeMethod(fullRefreshMethod)
		else
			executeMethod(changeCurrentPathMethod)
			executeMethod(drawAllMethod)
		end
	else
		MineOSCore.launchIcon(icon.path)
		buffer.start()
		executeMethod(fullRefreshMethod)
		-- GUI.error("Скрипт выполнен успешно")
	end
end

function MineOSCore.iconRightClick(icon, oldPixelsOfIcon, eventData, fileFormat, somethingCanBeAddedToDock, drawAllMethod, fullRefreshMethod, changeCurrentPathMethod)
	local action
	-- Разные контекстные меню
	if fs.isDirectory(icon.path) then
		if fileFormat == ".app" then
			action = context.menu(eventData[3], eventData[4],
				{MineOSCore.localization.contextMenuShowPackageContent},
				"-",
				{MineOSCore.localization.contextMenuCut},
				{MineOSCore.localization.contextMenuCopy},
				"-",
				{MineOSCore.localization.contextMenuRename},
				{MineOSCore.localization.contextMenuCreateShortcut, fileFormat == ".lnk"},
				-- "-",
				-- {MineOSCore.localization.contextMenuUploadToPastebin, true},
				"-",
				{MineOSCore.localization.contextMenuAddToDock, not somethingCanBeAddedToDock},
				{MineOSCore.localization.contextMenuDelete}
			)
		else
			action = context.menu(eventData[3], eventData[4],
				{MineOSCore.localization.contextMenuCut},
				{MineOSCore.localization.contextMenuCopy},
				{MineOSCore.localization.contextMenuRename},
				{MineOSCore.localization.contextMenuCreateShortcut, fileFormat == ".lnk"},
				"-",
				{MineOSCore.localization.contextMenuArchive},
				"-",
				{MineOSCore.localization.contextMenuDelete}
			)
		end
	else
		if fileFormat == ".pic" then
			action = context.menu(eventData[3], eventData[4],
				-- {MineOSCore.localization.contextMenuEdit},
				{MineOSCore.localization.contextMenuEditInPhotoshop},
				{MineOSCore.localization.contextMenuSetAsWallpaper},
				"-",
				{MineOSCore.localization.contextMenuCut},
				{MineOSCore.localization.contextMenuCopy},
				{MineOSCore.localization.contextMenuRename},
				{MineOSCore.localization.contextMenuCreateShortcut, fileFormat == ".lnk"},
				-- "-",
				-- {MineOSCore.localization.contextMenuUploadToPastebin, true},
				"-",
				{MineOSCore.localization.contextMenuAddToDock, not somethingCanBeAddedToDock},
				{MineOSCore.localization.contextMenuDelete, false}
			)
		else
			action = context.menu(eventData[3], eventData[4],
				{MineOSCore.localization.contextMenuEdit},
				-- {MineOSCore.localization.contextMenuCreateApplication},
				"-",
				{MineOSCore.localization.contextMenuCut},
				{MineOSCore.localization.contextMenuCopy},
				{MineOSCore.localization.contextMenuRename},
				{MineOSCore.localization.contextMenuCreateShortcut, fileFormat == ".lnk"},
				-- "-",
				-- {MineOSCore.localization.contextMenuUploadToPastebin, true},
				"-",
				{MineOSCore.localization.contextMenuAddToDock, not somethingCanBeAddedToDock},
				{MineOSCore.localization.contextMenuDelete}
			)
		end
	end

	if action == MineOSCore.localization.contextMenuEdit then
		ecs.prepareToExit()
		MineOSCore.safeLaunch("bin/edit.lua", icon.path)
		executeMethod(fullRefreshMethod)
	elseif action == MineOSCore.localization.contextMenuEditInPhotoshop then
		MineOSCore.safeLaunch("MineOS/Applications/Photoshop.app/Photoshop.lua", "open", icon.path)
		executeMethod(fullRefreshMethod)
		-- buffer.paste(1, 1, oldPixelsOfFullScreen)
		-- drawAll(true)
	elseif action == MineOSCore.localization.contextMenuAddToFavourites then
		-- addToFavourites(fs.name(path), path)
		computer.pushSignal("finderFavouriteAdded", icon.path)
		executeMethod(drawAllMethod)
	elseif action == MineOSCore.localization.contextMenuShowPackageContent then
		executeMethod(changeCurrentPathMethod)
		executeMethod(drawAllMethod)
		-- changePath(path)
		-- drawAll()
	elseif action == MineOSCore.localization.contextMenuCopy then
		_G.clipboard = icon.path
		executeMethod(drawAllMethod)
	elseif action == MineOSCore.localization.contextMenuCut then
		_G.clipboard = icon.path
		_G.clipboardCut = true
		executeMethod(drawAllMethod)
	elseif action == MineOSCore.localization.contextMenuDelete then
		fs.remove(icon.path)
		executeMethod(drawAllMethod)
		-- getFileList(workPathHistory[currentWorkPathHistoryElement])
		-- drawAll()
	elseif action == MineOSCore.localization.contextMenuRename then
		ecs.rename(icon.path)
		executeMethod(drawAllMethod)
		-- getFileList(workPathHistory[currentWorkPathHistoryElement])
		-- drawAll()
	elseif action == MineOSCore.localization.contextMenuCreateShortcut then
		ecs.createShortCut(fs.path(icon.path) .. "/" .. ecs.hideFileFormat(fs.name(icon.path)) .. ".lnk", icon.path)
		executeMethod(drawAllMethod)
		-- getFileList(workPathHistory[currentWorkPathHistoryElement])
		-- drawAll()
	elseif action == MineOSCore.localization.contextMenuArchive then
		-- ecs.info("auto", "auto", "", "Архивация файлов...")
		archive.pack(ecs.hideFileFormat(fs.name(icon.path))..".pkg", icon.path)
		executeMethod(drawAllMethod)
		-- getFileList(workPathHistory[currentWorkPathHistoryElement])
		-- drawAll()
	elseif action == MineOSCore.localization.contextMenuUploadToPastebin then
		MineOSCore.safeLaunch("MineOS/Applications/Pastebin.app/Pastebin.lua", "upload", icon.path)
		executeMethod(fullRefreshMethod)
		-- shell.execute("MineOS/Applications/Pastebin.app/Pastebin.lua upload " .. path)
		-- getFileList(workPathHistory[currentWorkPathHistoryElement])
		-- drawAll(true)
	elseif action == MineOSCore.localization.contextMenuSetAsWallpaper then
		--ecs.error(path)
		ecs.createShortCut("MineOS/System/OS/Wallpaper.lnk", icon.path)
		computer.pushSignal("OSWallpaperChanged")
		return true
		-- buffer.paste(1, 1, oldPixelsOfFullScreen)
		-- buffer.draw()
	elseif action == MineOSCore.localization.contextMenuCreateApplication then
		ecs.newApplicationFromLuaFile(icon.path, fs.path(icon.path) or "")
		executeMethod(drawAllMethod)
		-- getFileList(workPathHistory[currentWorkPathHistoryElement])
		-- drawAll()
	else
		buffer.paste(icon.x, icon.y, oldPixelsOfIcon)
		buffer.draw()
	end
end

function MineOSCore.iconClick(icon, eventData, selectionColor, selectionTransparency, iconTextColor, clickSleepDelay, somethingCanBeAddedToDock, drawAllMethod, fullRefreshMethod, changeCurrentPathMethod)
	local fileFormat = ecs.getFileFormat(icon.path)
	local oldPixelsOfIcon = MineOSCore.iconSelect(icon, selectionColor, selectionTransparency, iconTextColor)
	local dataToReturn

	if eventData[5] == 0 then
		os.sleep(clickSleepDelay)
		dataToReturn = MineOSCore.iconLeftClick(icon, oldPixelsOfIcon, fileFormat, drawAllMethod, fullRefreshMethod, changeCurrentPathMethod)
	else
		dataToReturn = MineOSCore.iconRightClick(icon, oldPixelsOfIcon, eventData, fileFormat, somethingCanBeAddedToDock, drawAllMethod, fullRefreshMethod, changeCurrentPathMethod)
	end
	return dataToReturn
end

function MineOSCore.emptyZoneClick(eventData, workPath, drawAllMethod, fullRefreshMethod)
	local action = context.menu(eventData[3], eventData[4], {MineOSCore.localization.contextMenuNewFile}, {MineOSCore.localization.contextMenuNewFolder}, {MineOSCore.localization.contextMenuNewApplication}, "-", {MineOSCore.localization.contextMenuPaste, (_G.clipboard == nil)})
	if action == MineOSCore.localization.contextMenuNewFile then
		ecs.newFile(workPath)
		executeMethod(fullRefreshMethod)
	elseif action == MineOSCore.localization.contextMenuNewFolder then
		ecs.newFolder(workPath)
		executeMethod(drawAllMethod)
	elseif action == MineOSCore.localization.contextMenuPaste then
		ecs.copy(_G.clipboard, workPath)
		if _G.clipboardCut then
			fs.remove(_G.clipboard)
			_G.clipboardCut = nil
			_G.clipboard = nil
		end
		executeMethod(drawAllMethod)
	elseif action == MineOSCore.localization.contextMenuNewApplication then
		ecs.newApplication(workPath)
		executeMethod(drawAllMethod)
	end
end

-----------------------------------------------------------------------------------------------------------------------------------

MineOSCore.init()

-----------------------------------------------------------------------------------------------------------------------------------

return MineOSCore





