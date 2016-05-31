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

-- Загрузка языкового пакета
-- local lang = files.loadTableFromFile("MineOS/System/OS/Languages/" .. _G.OSSettings.language .. ".lang")
local lang = {}
local MineOSCore = {}

-----------------------------------------------------------------------------------------------------------------------------------

MineOSCore.iconsPath = "MineOS/System/OS/Icons/"
MineOSCore.iconWidth = 12
MineOSCore.iconHeight = 6
MineOSCore.sortingMethods = {
	type = 0,
	name = 1,
	date = 2,
}
MineOSCore.colors = {
	background = 0x262626.
}

-----------------------------------------------------------------------------------------------------------------------------------

--Присвоение языкового пакета
function MineOSCore.setLocalization(langArray)
	lang = langArray
end

--Вся необходимая информация для иконок
function MineOSCore.loadIcons()
	if MineOSCore.icons then return end
	MineOSCore.icons = {}
	MineOSCore.icons.folder = image.load(MineOSCore.iconsPath .. "Folder.pic")
	MineOSCore.icons.script = image.load(MineOSCore.iconsPath .. "Script.pic")
	MineOSCore.icons.text = image.load(MineOSCore.iconsPath .. "Text.pic")
	MineOSCore.icons.config = image.load(MineOSCore.iconsPath .. "Config.pic")
	MineOSCore.icons.lua = image.load(MineOSCore.iconsPath .. "Lua.pic")
	MineOSCore.icons.image = image.load(MineOSCore.iconsPath .. "Image.pic")
	MineOSCore.icons.pastebin = image.load(MineOSCore.iconsPath .. "Pastebin.pic")
	MineOSCore.icons.fileNotExists = image.load(MineOSCore.iconsPath .. "FileNotExists.pic")
	MineOSCore.icons.archive = image.load(MineOSCore.iconsPath .. "Archive.pic")
	MineOSCore.icons.model3D = image.load(MineOSCore.iconsPath .. "3DModel.pic")
end

--Отрисовка одной иконки
function MineOSCore.drawIcon(x, y, path, showFileFormat, nameColor)
	local fileFormat, icon = ecs.getFileFormat(path)

	if fs.isDirectory(path) then
		if fileFormat == ".app" then
			-- icon = "cyka"
			-- MineOSCore.icons[icon] = image.load(path .. "/Resources/Icon.pic")
			icon = path .. "/Resources/Icon.pic"
			if not MineOSCore.icons[icon] then
				 MineOSCore.icons[icon] = image.load(icon)
			end
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
	local success, reason = pcall(loadfile(command), ...)
	--Ебал я автора мода в задницу, кусок ебанутого говна
	--Какого хуя я должен вставлять кучу костылей в свой прекрасный код только потому, что эта ублюдочная
	--скотина захотела выдавать table из pcall? Что, блядь? Где это видано, сука?
	--Почему тогда во всех случаях выдается string, а при os.exit выдается {reason = "terminated"}?
	--Что за ебливая сучья логика? 
	if not success and type(reason) ~= "table" then
		reason = ecs.parseErrorMessage(reason, false)
		GUI.error(reason, {title = {color = 0xFFDB40, text = "Ошибка при выполнении программы"}})
	end
end

-- Запуск приложения
function MineOSCore.launchIcon(path, translate)
	--Запоминаем, какое разрешение было
	local oldWidth, oldHeight = component.gpu.getResolution()
	--Получаем файл формат заранее
	local fileFormat = ecs.getFileFormat(path)
	local isDirectory = fs.isDirectory(path)
	--Если это приложение
	if fileFormat == ".app" then
		ecs.applicationHelp(path)
		MineOSCore.safeLaunch(path .. "/" .. ecs.hideFileFormat(fs.name(path)) .. ".lua")
	--Если это папка
	elseif (fileFormat == "" or fileFormat == nil) and isDirectory then
		MineOSCore.safeLaunch("MineOS/Applications/Finder.app/Finder.lua " .. path)
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
	elseif fileFormat == ".txt" or fileFormat == ".cfg" or fileFormat == ".lang" then
		ecs.prepareToExit()
		MineOSCore.safeLaunch("bin/edit.lua", path)

	--Если это ярлык
	elseif fileFormat == ".lnk" then
		local shortcutLink = ecs.readShortcut(path)
		if fs.exists(shortcutLink) then
			MineOSCore.launchIcon(shortcutLink)
		else
			GUI.error(lang.shortcutIsCorrupted)
		end
	
	--Если это архив
	elseif fileFormat == ".zip" then
		zip.unarchive(path, (fs.path(path) or ""))
	end
	--Ставим старое разрешение
	component.gpu.setResolution(oldWidth, oldHeight)
	buffer.start()
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
				{lang.contextMenuShowPackageContent},
				"-",
				{lang.contextMenuCopy},
				{lang.contextMenuPaste, not _G.clipboard},
				"-",
				{lang.contextMenuRename},
				{lang.contextMenuCreateShortcut},
				"-",
				{lang.contextMenuUploadToPastebin, true},
				"-",
				{lang.contextMenuAddToDock, not somethingCanBeAddedToDock},
				{lang.contextMenuDelete}
			)
		else
			action = context.menu(eventData[3], eventData[4],
				{lang.contextMenuCopy},
				{lang.contextMenuRename},
				{lang.contextMenuCreateShortcut},
				"-",
				{lang.contextMenuArchive},
				"-",
				{lang.contextMenuDelete}
			)
		end
	else
		if fileFormat == ".pic" then
			action = context.menu(eventData[3], eventData[4],
				{lang.contextMenuEdit},
				{lang.contextMenuEditInPhotoshop},
				{lang.contextMenuSetAsWallpaper},
				"-",
				{lang.contextMenuCopy, false},
				{lang.contextMenuRename},
				{lang.contextMenuCreateShortcut},
				"-",
				{lang.contextMenuUploadToPastebin, true},
				"-",
				{lang.contextMenuAddToDock, not somethingCanBeAddedToDock},
				{lang.contextMenuDelete, false}
			)
		else
			action = context.menu(eventData[3], eventData[4],
				{lang.contextMenuEdit},
				-- {lang.contextMenuCreateApplication},
				"-",
				{lang.contextMenuCopy},
				{lang.contextMenuRename},
				{lang.contextMenuCreateShortcut},
				"-",
				{lang.contextMenuUploadToPastebin, true},
				"-",
				{lang.contextMenuAddToDock, not somethingCanBeAddedToDock},
				{lang.contextMenuDelete}
			)
		end
	end

	if action == lang.contextMenuEdit then
		ecs.prepareToExit()
		MineOSCore.safeLaunch("bin/edit.lua", icon.path)
		executeMethod(fullRefreshMethod)
	elseif action == lang.contextMenuEditInPhotoshop then
		MineOSCore.safeLaunch("MineOS/Applications/Photoshop.app/Photoshop.lua", "open", icon.path)
		executeMethod(fullRefreshMethod)
		-- buffer.paste(1, 1, oldPixelsOfFullScreen)
		-- drawAll(true)
	elseif action == lang.contextMenuAddToFavourites then
		-- addToFavourites(fs.name(path), path)
		computer.pushSignal("finderFavouriteAdded", icon.path)
		executeMethod(drawAllMethod)
	elseif action == lang.contextMenuShowPackageContent then
		executeMethod(changeCurrentPathMethod)
		executeMethod(drawAllMethod)
		-- changePath(path)
		-- drawAll()
	elseif action == lang.contextMenuCopy then
		_G.clipboard = icon.path
		executeMethod(drawAllMethod)
	elseif action == lang.contextMenuPaste then
		ecs.copy(_G.clipboard, fs.path(icon.path) or "")
		executeMethod(drawAllMethod)
		-- getFileList(workPathHistory[currentWorkPathHistoryElement])
		-- drawAll()
	elseif action == lang.contextMenuDelete then
		fs.remove(icon.path)
		executeMethod(drawAllMethod)
		-- getFileList(workPathHistory[currentWorkPathHistoryElement])
		-- drawAll()
	elseif action == lang.contextMenuRename then
		ecs.rename(icon.path)
		executeMethod(drawAllMethod)
		-- getFileList(workPathHistory[currentWorkPathHistoryElement])
		-- drawAll()
	elseif action == lang.contextMenuCreateShortcut then
		ecs.createShortCut(fs.path(icon.path).."/"..ecs.hideFileFormat(fs.name(icon.path))..".lnk", icon.path)
		executeMethod(drawAllMethod)
		-- getFileList(workPathHistory[currentWorkPathHistoryElement])
		-- drawAll()
	elseif action == lang.contextMenuArchive then
		-- ecs.info("auto", "auto", "", "Архивация файлов...")
		archive.pack(ecs.hideFileFormat(fs.name(icon.path))..".pkg", icon.path)
		executeMethod(drawAllMethod)
		-- getFileList(workPathHistory[currentWorkPathHistoryElement])
		-- drawAll()
	elseif action == lang.contextMenuUploadToPastebin then
		MineOSCore.safeLaunch("MineOS/Applications/Pastebin.app/Pastebin.lua", "upload", icon.path)
		executeMethod(fullRefreshMethod)
		-- shell.execute("MineOS/Applications/Pastebin.app/Pastebin.lua upload " .. path)
		-- getFileList(workPathHistory[currentWorkPathHistoryElement])
		-- drawAll(true)
	elseif action == lang.contextMenuSetAsWallpaper then
		--ecs.error(path)
		ecs.createShortCut("MineOS/System/OS/Wallpaper.lnk", icon.path)
		computer.pushSignal("OSWallpaperChanged")
		return true
		-- buffer.paste(1, 1, oldPixelsOfFullScreen)
		-- buffer.draw()
	elseif action == lang.contextMenuCreateApplication then
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

function MineOSCore.emptyZoneClick(eventData, workPath, drawAllMethod)
	local action = context.menu(eventData[3], eventData[4], {lang.contextMenuNewFile}, {lang.contextMenuNewFolder}, {lang.contextMenuNewApplication}, "-", {lang.contextMenuPaste, (_G.clipboard == nil), "^V"})
	if action == lang.contextMenuNewFile then
		ecs.newFile(workPath)
		executeMethod(drawAllMethod)
	elseif action == lang.contextMenuNewFolder then
		ecs.newFolder(workPath)
		executeMethod(drawAllMethod)
	elseif action == lang.contextMenuPaste then
		ecs.copy(_G.clipboard, workPath)
		executeMethod(drawAllMethod)
	elseif action == lang.contextMenuNewApplication then
		ecs.newApplication(workPath)
		executeMethod(drawAllMethod)
	end
end


-----------------------------------------------------------------------------------------------------------------------------------

-- MineOSCore.loadIcons()
-- buffer.start()

-- buffer.clear(0x262626)
-- MineOSCore.drawIconField(2, 2, 5, 5, 1, 25, 2, 1, "lib/", "type", true, 0xFFFFFF)
-- buffer.draw(true)

-----------------------------------------------------------------------------------------------------------------------------------

return MineOSCore





