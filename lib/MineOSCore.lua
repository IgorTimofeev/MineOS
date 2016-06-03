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
	zip = "archive"
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
function MineOSCore.drawIcon(x, y, path, showFileFormat, nameColor)
	local fileFormat, icon = ecs.getFileFormat(path)

	if fs.isDirectory(path) then
		if fileFormat == ".app" then
			-- icon = "cyka"
			-- MineOSCore.icons[icon] = image.load(path .. "/Resources/Icon.pic")
			icon = path .. "/Resources/Icon.pic"
			MineOSCore.loadIcon(icon, icon)
		else
			icon = "folder"
		end
	else
		if fileFormat == ".lnk" then
			MineOSCore.drawIcon(x, y, ecs.readShortcut(path), showFileFormat, nameColor)
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
	local text = fs.name(path)
	if not showFileFormat and fileFormat then text = unicode.sub(text, 1, -(unicode.len(fileFormat) + 1)) end
	text = ecs.stringLimit("end", text, MineOSCore.iconWidth)
	x = x + math.floor(MineOSCore.iconWidth / 2 - unicode.len(text) / 2)
	--Рисуем текст под иконкой
	buffer.text(x, y + MineOSCore.iconHeight - 1, nameColor or 0xffffff, text)
end

function MineOSCore.safeLaunch(command, ...)
	local oldResolutionWidth, oldResolutionHeight = component.gpu.getResolution()
	local loadSuccess, loadReason = loadfile(command)
	if loadSuccess then
		local success, reason = pcall(loadSuccess, ...)
		--Ебал я автора мода в задницу, кусок ебанутого говна
		--Какого хуя я должен вставлять кучу костылей в свой прекрасный код только потому, что эта ублюдочная
		--скотина захотела выдавать table из pcall? Что, блядь? Где это видано, сука?
		--Почему тогда во всех случаях выдается string, а при os.exit выдается {reason = "terminated"}?
		--Что за ебливая сучья логика? 
		if not success and type(reason) ~= "table" then
			reason = ecs.parseErrorMessage(reason, false)
			GUI.error(reason, {title = {color = 0xFFDB40, text = MineOSCore.localization.errorWhileRunningProgram}})
		end
	else
		component.gpu.setResolution(oldResolutionWidth, oldResolutionHeight)
		GUI.error(loadReason, {title = {color = 0xFFDB40, text = MineOSCore.localization.errorWhileRunningProgram}})
	end
	buffer.start()
end

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
				{MineOSCore.localization.contextMenuCopy},
				{MineOSCore.localization.contextMenuPaste, not _G.clipboard},
				"-",
				{MineOSCore.localization.contextMenuRename},
				{MineOSCore.localization.contextMenuCreateShortcut},
				"-",
				{MineOSCore.localization.contextMenuUploadToPastebin, true},
				"-",
				{MineOSCore.localization.contextMenuAddToDock, not somethingCanBeAddedToDock},
				{MineOSCore.localization.contextMenuDelete}
			)
		else
			action = context.menu(eventData[3], eventData[4],
				{MineOSCore.localization.contextMenuCopy},
				{MineOSCore.localization.contextMenuRename},
				{MineOSCore.localization.contextMenuCreateShortcut},
				"-",
				{MineOSCore.localization.contextMenuArchive},
				"-",
				{MineOSCore.localization.contextMenuDelete}
			)
		end
	else
		if fileFormat == ".pic" then
			action = context.menu(eventData[3], eventData[4],
				{MineOSCore.localization.contextMenuEdit},
				{MineOSCore.localization.contextMenuEditInPhotoshop},
				{MineOSCore.localization.contextMenuSetAsWallpaper},
				"-",
				{MineOSCore.localization.contextMenuCopy, false},
				{MineOSCore.localization.contextMenuRename},
				{MineOSCore.localization.contextMenuCreateShortcut},
				"-",
				{MineOSCore.localization.contextMenuUploadToPastebin, true},
				"-",
				{MineOSCore.localization.contextMenuAddToDock, not somethingCanBeAddedToDock},
				{MineOSCore.localization.contextMenuDelete, false}
			)
		else
			action = context.menu(eventData[3], eventData[4],
				{MineOSCore.localization.contextMenuEdit},
				-- {MineOSCore.localization.contextMenuCreateApplication},
				"-",
				{MineOSCore.localization.contextMenuCopy},
				{MineOSCore.localization.contextMenuRename},
				{MineOSCore.localization.contextMenuCreateShortcut},
				"-",
				{MineOSCore.localization.contextMenuUploadToPastebin, true},
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
	elseif action == MineOSCore.localization.contextMenuPaste then
		ecs.copy(_G.clipboard, fs.path(icon.path) or "")
		executeMethod(drawAllMethod)
		-- getFileList(workPathHistory[currentWorkPathHistoryElement])
		-- drawAll()
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
		ecs.createShortCut(fs.path(icon.path).."/"..ecs.hideFileFormat(fs.name(icon.path))..".lnk", icon.path)
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
	local action = context.menu(eventData[3], eventData[4], {MineOSCore.localization.contextMenuNewFile}, {MineOSCore.localization.contextMenuNewFolder}, {MineOSCore.localization.contextMenuNewApplication}, "-", {MineOSCore.localization.contextMenuPaste, (_G.clipboard == nil), "^V"})
	if action == MineOSCore.localization.contextMenuNewFile then
		ecs.newFile(workPath)
		executeMethod(fullRefreshMethod)
	elseif action == MineOSCore.localization.contextMenuNewFolder then
		ecs.newFolder(workPath)
		executeMethod(drawAllMethod)
	elseif action == MineOSCore.localization.contextMenuPaste then
		ecs.copy(_G.clipboard, workPath)
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





