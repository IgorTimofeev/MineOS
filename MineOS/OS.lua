
---------------------------------------------- Библиотеки ------------------------------------------------------------------------

local copyright = [[
	
	Тут можно было бы написать кучу текста, мол,
	вы не имеете прав на использование этой хуйни в
	коммерческих целях и прочую чушь, навеянную нам
	западной культурой. Но я же не пидор какой-то, верно?
	 
	Просто помни, сука, что эту ОСь накодил Тимофеев Игорь,
	ссылка на ВК: vk.com/id7799889

]]

-- Адаптивная загрузка необходимых библиотек и компонентов
local libraries = {
	["ecs"] = "ECSAPI",
	["component"] = "component",
	["event"] = "event",
	["term"] = "term",
	["config"] = "config",
	["context"] = "context",
	["internet"] = "internet",
	["buffer"] = "doubleBuffering",
	["image"] = "image",
	["zones"] = "zones",
}

local components = {
	["gpu"] = "gpu",
}

for library in pairs(libraries) do if not _G[library] then _G[library] = require(libraries[library]) end end
for comp in pairs(components) do if not _G[comp] then _G[comp] = _G.component[components[comp]] end end
libraries, components = nil, nil

-- Загрузка языкового пакета
local lang = config.readAll("MineOS/System/OS/Languages/" .. _G.OSSettings.language .. ".lang")

---------------------------------------------- Переменные ------------------------------------------------------------------------

local workPath = "MineOS/Desktop/"
local pathOfDockShortcuts = "MineOS/System/OS/Dock/"
local pathToWallpaper = "MineOS/System/OS/Wallpaper.lnk"
local currentFileList
local wallpaper
local currentCountOfIconsInDock

local colors = {
	background = 0x262626,
	topBarColor = 0xFFFFFF,
	topBarTransparency = 35,
	dockColor = 0xDDDDDD,
	dockBaseTransparency = 25,
	dockTransparencyAdder = 15,
	iconsSelectionColor = ecs.colors.lightBlue,
	iconsSelectionTransparency = 20,
}

local sizes = {}
sizes.xSize, sizes.ySize = gpu.getResolution()

sizes.widthOfIcon = 12
sizes.heightOfIcon = 6
sizes.heightOfDock = 4
sizes.xSpaceBetweenIcons = 2
sizes.ySpaceBetweenIcons = 1
sizes.xCountOfIcons = math.floor(sizes.xSize / (sizes.widthOfIcon + sizes.xSpaceBetweenIcons))
sizes.yCountOfIcons = math.floor((sizes.ySize - (sizes.heightOfDock + 6)) / (sizes.heightOfIcon + sizes.ySpaceBetweenIcons))
sizes.totalCountOfIcons = sizes.xCountOfIcons * sizes.yCountOfIcons
sizes.yPosOfIcons = 3
sizes.xPosOfIcons = math.floor(sizes.xSize / 2 - (sizes.xCountOfIcons * (sizes.widthOfIcon + sizes.xSpaceBetweenIcons) - sizes.xSpaceBetweenIcons) / 2)
sizes.dockCountOfIcons = sizes.xCountOfIcons - 1


---------------------------------------------- Функции ------------------------------------------------------------------------

--Изменение обоев из файла обоев
local function changeWallpaper()
	wallpaper = nil
	if fs.exists(pathToWallpaper) then
		local path = ecs.readShortcut(pathToWallpaper)
		if fs.exists(path) then
			wallpaper = image.load(path)
		end
	end
end
changeWallpaper()

--Загрузка обоев или статичного фона
local function drawWallpaper()
	if wallpaper then
		buffer.image(1, 1, wallpaper)
	else
		buffer.square(1, 1, sizes.xSize, sizes.ySize, colors.background, 0xFFFFFF, " ")
	end
end

--ОТРИСОВКА ИКОНОК НА РАБОЧЕМ СТОЛЕ ПО ТЕКУЩЕЙ ПАПКЕ
local function drawDesktop()
	currentFileList = ecs.getFileList(workPath)
	currentFileList = ecs.sortFiles(workPath, currentFileList, "type", false)

	drawWallpaper()

	--Отрисовка иконок по файл-листу
	local counter = 1
	local xPos, yPos = sizes.xPosOfIcons, sizes.yPosOfIcons
	for i = 1, sizes.yCountOfIcons do
		for j = 1, sizes.xCountOfIcons do
			if not currentFileList[counter] then break end

			--Отрисовка конкретной иконки
			local path = workPath .. currentFileList[counter]
			ecs.drawOSIcon(xPos, yPos, path, false, 0xffffff)

			--Создание объекта иконки
			zones.add("OS", "DesktopIcons", counter, xPos, yPos, sizes.widthOfIcon, sizes.heightOfIcon, path)

			xPos = xPos + sizes.widthOfIcon + sizes.xSpaceBetweenIcons
			counter = counter + 1
		end

		xPos = sizes.xPosOfIcons
		yPos = yPos + sizes.heightOfIcon + sizes.ySpaceBetweenIcons
	end
end

--ОТРИСОВКА ДОКА
local function drawDock()

	--Получаем список файлов ярлыком дока
	local dockShortcuts = ecs.getFileList(pathOfDockShortcuts)
	currentCountOfIconsInDock = #dockShortcuts

	--Рассчитываем размер и позицию дока на основе размера
	local widthOfDock = (currentCountOfIconsInDock * (sizes.widthOfIcon + sizes.xSpaceBetweenIcons) - sizes.xSpaceBetweenIcons) + sizes.heightOfDock * 2 + 2
	local xDock, yDock = math.floor(sizes.xSize / 2 - widthOfDock / 2) + 1, sizes.ySize - sizes.heightOfDock

	--Рисуем сам док
	local transparency = colors.dockBaseTransparency
	for i = 1, sizes.heightOfDock do
		buffer.square(xDock + i, sizes.ySize - i + 1, widthOfDock - i * 2, 1, 0xFFFFFF, 0xFFFFFF, " ", transparency)
		transparency = transparency + colors.dockTransparencyAdder
	end

	--Рисуем ярлыки на доке
	if currentCountOfIconsInDock > 0 then
		local xIcons = math.floor(sizes.xSize / 2 - ((sizes.widthOfIcon + sizes.xSpaceBetweenIcons) * currentCountOfIconsInDock - sizes.xSpaceBetweenIcons) / 2 ) + 1
		local yIcons = sizes.ySize - sizes.heightOfDock - 1

		for i = 1, currentCountOfIconsInDock do
			ecs.drawOSIcon(xIcons, yIcons, pathOfDockShortcuts .. dockShortcuts[i], false, 0x000000)
			zones.add("OS", "DockIcons", dockShortcuts[i], xIcons, yIcons, sizes.widthOfIcon, sizes.heightOfIcon)
			xIcons = xIcons + sizes.xSpaceBetweenIcons + sizes.widthOfIcon
		end
	end
end

-- Нарисовать информацию справа на топбаре
local function drawTime()
	local free, total, used = ecs.getInfoAboutRAM()
	local time = used .. "/".. total .. " KB RAM, " .. unicode.sub(os.date("%T"), 1, -4) .. " "
	local sTime = unicode.len(time)
	buffer.text(sizes.xSize - sTime, 1, 0x000000, time)
end

--РИСОВАТЬ ВЕСЬ ТОПБАР
local function drawTopBar()
	--Элементы топбара
	local topBarElements = { "MineOS", "Вид" }
	--Белая горизонтальная линия
	buffer.square(1, 1, sizes.xSize, 1, colors.topBarColor, 0xFFFFFF, " ", colors.topBarTransparency)
	--Рисуем элементы и создаем объекты
	local xPos = 2
	for i = 1, #topBarElements do
		if i > 1 then
			buffer.text(xPos + 1, 1, 0x666666, topBarElements[i])
		else
			buffer.text(xPos + 1, 1, 0x000000, topBarElements[i])
		end
		local length = unicode.len(topBarElements[i])
		zones.add("OS", "TopBarButtons", topBarElements[i], xPos, 1, length + 2, 1)
		xPos = xPos + length + 2
	end
	--Рисуем время
	drawTime()
end

local function drawAll(force)
	drawDesktop()
	drawDock()
	drawTopBar()
	buffer.draw(force)
end

---------------------------------------------- Сама ОС ------------------------------------------------------------------------

zones.stop()
zones.start()
zones.remove("OS")
buffer.start()

--zones.add("OS", "Global", "Global", 1, 1, sizes.xSize, sizes.ySize)
--createDesktopShortCuts()
drawAll(true)

--------------------------------------------------------------------------------------------------------------------------------

while true do
	local eventData = { event.pull() }

	if eventData[1] == "zone" then

		local x, y, mouseKey, xZone, yZone, path = eventData[5], eventData[6], eventData[7], eventData[8], eventData[9], eventData[12]

		if eventData[2] == "OS" then
			if eventData[3] == "DesktopIcons" then
				local fileFormat = ecs.getFileFormat(path)

				local oldPixelsOfIcon = buffer.copy(xZone, yZone, sizes.widthOfIcon, sizes.heightOfIcon)

				buffer.square(xZone, yZone, sizes.widthOfIcon, sizes.heightOfIcon, colors.iconsSelectionColor, 0xFFFFFF, " ", colors.iconsSelectionTransparency)
				ecs.drawOSIcon(xZone, yZone, path, false, 0xffffff)
				buffer.draw()

				-- Левый клик
				if mouseKey == 0 then
					os.sleep(0.2)
					if fs.isDirectory(path)	then
						if fileFormat == ".app" then
							ecs.launchIcon(path)
							buffer.start()
							drawAll()
						else
							shell.execute("MineOS/Applications/Finder.app/Finder.lua "..path)
						end
					else
						ecs.launchIcon(path)
						buffer.start()
						drawAll()
					end

				-- Правый клик
				elseif mouseKey == 1 then

					local action
					local fileFormat = ecs.getFileFormat(path)

					-- Разные контекстные меню
					if fileFormat == ".app" and fs.isDirectory(path) then
						action = context.menu(x, y, {lang.contextShowContent}, "-", {lang.contextCopy, false, "^C"}, {lang.contextPaste, not _G.clipboard, "^V"}, "-", {lang.contextRename}, {lang.contextCreateShortcut}, "-",  {lang.contextUploadToPastebin, true}, "-", {lang.contextAddToDock, not (currentCountOfIconsInDock < sizes.dockCountOfIcons and workPath ~= "MineOS/System/OS/Dock/")}, {lang.contextDelete, false, "⌫"})
					elseif fileFormat ~= ".app" and fs.isDirectory(path) then
						action = context.menu(x, y, {lang.contextCopy, false, "^C"}, {lang.contextPaste, not _G.clipboard, "^V"}, "-", {lang.contextRename}, {lang.contextCreateShortcut}, "-", {lang.contextUploadToPastebin, true}, "-", {lang.contextDelete, false, "⌫"})
					else
						if fileFormat == ".pic" then
							action = context.menu(x, y, {lang.contextEdit}, {"Установить как обои"},"-", {lang.contextCopy, false, "^C"}, {lang.contextPaste, not _G.clipboard, "^V"}, "-", {lang.contextRename}, {lang.contextCreateShortcut}, "-", {lang.contextUploadToPastebin, true}, "-", {lang.contextAddToDock, not (currentCountOfIconsInDock < sizes.dockCountOfIcons and workPath ~= "MineOS/System/OS/Dock/")}, {lang.contextDelete, false, "⌫"})
						else
							action = context.menu(x, y, {lang.contextEdit}, "-", {lang.contextCopy, false, "^C"}, {lang.contextPaste, not _G.clipboard, "^V"}, "-", {lang.contextRename}, {lang.contextCreateShortcut}, "-", {lang.contextUploadToPastebin, true}, "-", {lang.contextAddToDock, not (currentCountOfIconsInDock < sizes.dockCountOfIcons and workPath ~= "MineOS/System/OS/Dock/")}, {lang.contextDelete, false, "⌫"})
						end
					end

					--Анализ действия контекстного меню
					if action == lang.contextShowContent then
						shell.execute("MineOS/Applications/Finder.app/Finder.lua "..path)
					elseif action == lang.contextEdit then
						ecs.editFile(path)
						drawAll(true)
					elseif action == lang.contextDelete then
						fs.remove(path)
						drawAll()
					elseif action == lang.contextCopy then
						_G.clipboard = path
					elseif action == lang.contextPaste then
						ecs.copy(_G.clipboard, workPath)
						drawAll()
					elseif action == lang.contextRename then
						ecs.rename(path)
						drawAll()
					elseif action == lang.contextCreateShortcut then
						ecs.createShortCut(workPath .. ecs.hideFileFormat(path) .. ".lnk", path)
						drawAll()
					elseif action == lang.contextAddToDock then
						ecs.createShortCut("MineOS/System/OS/Dock/" .. ecs.hideFileFormat(path) .. ".lnk", path)
						drawAll()
					elseif action == "Установить как обои" then
						ecs.createShortCut(pathToWallpaper, path)
						changeWallpaper()
						drawAll(true)
					else
						buffer.paste(xZone, yZone, oldPixelsOfIcon)
						buffer.draw()
					end
				end

			elseif eventData[3] == "DockIcons" then

				local oldPixelsOfIcon = buffer.copy(xZone, yZone, sizes.widthOfIcon, sizes.heightOfIcon)

				buffer.square(xZone, yZone, sizes.widthOfIcon, sizes.heightOfIcon, colors.iconsSelectionColor, 0xFFFFFF, " ", colors.iconsSelectionTransparency)
				ecs.drawOSIcon(xZone, yZone, pathOfDockShortcuts .. eventData[4], false, 0xffffff)
				buffer.draw()

				if mouseKey == 0 then 
					os.sleep(0.2)
					ecs.launchIcon(pathOfDockShortcuts..eventData[4])
					drawAll(true)
				else
					local content = ecs.readShortcut(pathOfDockShortcuts .. eventData[4])
					
					action = context.menu(x, y, {lang.contextRemoveFromDock, not (currentCountOfIconsInDock > 1)})

					if action == lang.contextRemoveFromDock then
						fs.remove(pathOfDockShortcuts..eventData[4])
						drawAll()
					else
						buffer.paste(xZone, yZone, oldPixelsOfIcon)
						buffer.draw()
						oldPixelsOfIcon = nil
					end
				end

			elseif eventData[3] == "TopBarButtons" then

				buffer.square(xZone, yZone, unicode.len(eventData[4]) + 2, 1, ecs.colors.blue, 0xFFFFFF, " ")
				buffer.text(xZone + 1, yZone, 0xffffff, eventData[4])
				buffer.draw()

				if eventData[4] == "MineOS" then
					local action = context.menu(xZone, yZone + 1, {lang.aboutSystem}, {lang.updateSystem}, "-", {lang.restart}, {lang.shutdown}, "-", {lang.backToShell})
				
					if action == lang.backToShell then
						ecs.prepareToExit()
						zones.remove("OS")
						return 0
					elseif action == lang.shutdown then
						shell.execute("shutdown")
					elseif action == lang.restart then
						shell.execute("reboot")
					elseif action == lang.updateSystem then
						shell.execute("pastebin run 0nm5b1ju")
						ecs.prepareToExit()
						return 0
					elseif action == lang.aboutSystem then
						ecs.prepareToExit()
						print(copyright)
						print("	А теперь жмякай любую кнопку и продолжай работу с ОС.")
						ecs.waitForTouchOrClick()
						drawAll(true)
					end
				
				elseif eventData[4] == lang.viewTab then
					local action = context.menu(xZone, yZone + 1, {"Скрыть обои", not wallpaper}, {"Показать обои", wallpaper or not fs.exists(pathToWallpaper)})
					if action == "Скрыть обои" then
						wallpaper = nil
						fs.remove(pathToWallpaper)
						drawAll(true)
					elseif action == "Показать обои" then
						changeWallpaper()
						drawAll(true)
					end
				end

				drawAll()

			end
		end

	elseif eventData[1] == "OSWallpaperChanged" then
		changeWallpaper()
		drawAll(true)
	end
	--Если пустая глобал зона
	-- if eventData[1] == "touch" then
	-- 	if eventData[5] == 1 then
	-- 		local action = context.menu(eventData[3], eventData[4], {"Убрать обои", not wallpaper},"-", {lang.contextNewFile}, {lang.contextNewFolder}, "-", {lang.contextPaste, not _G.clipboard, "^V"})

	-- 		--Создать новый файл
	-- 		if action == lang.contextNewFile then
	-- 			ecs.newFile(workPath)
	-- 			drawAll(true)
	-- 		--Создать новую папку
	-- 		elseif action == lang.contextNewFolder then
	-- 			ecs.newFolder(workPath)
	-- 			drawAll()
	-- 		--Вставить файл
	-- 		elseif action == lang.contextPaste then

	-- 		elseif action == "Убрать обои" then
	-- 			wallpaper = nil
	-- 			fs.remove(pathToWallpaper)
	-- 			drawAll()
	-- 		end
	-- 	end
	-- end
end
 










