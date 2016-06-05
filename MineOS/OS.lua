-- package.loaded.MineOSCore = nil
-- _G.MineOSCore = nil

---------------------------------------------- Копирайт, епта ------------------------------------------------------------------------

local copyright = [[

	Тут можно было бы написать кучу текста, мол,
	вы не имеете прав на использование этой хуйни в
	коммерческих целях и прочую чушь, навеянную нам
	западной культурой. Но я же не пидор какой-то, верно?

	Просто помни, что эту ОСь накодил Тимофеев Игорь,
	ссылка на ВК: vk.com/id7799889

]]

-- Вычищаем копирайт из оперативки, ибо мы не можем тратить СТОЛЬКО памяти.
-- Сколько тут, раз, два, три... 295 ASCII-символов!
-- А это, между прочим, 59 раз по слову "Пидор". Но один раз - не пидорас, поэтому очищаем.
-- Я передумал, не очищаем, пригодится еще. Вот же ж неоптимизированная параша!
-- copyright = nil

---------------------------------------------- Библиотеки ------------------------------------------------------------------------

-- Адаптивная загрузка необходимых библиотек и компонентов
local libraries = {
	buffer = "doubleBuffering",
	MineOSCore = "MineOSCore",
	GUI = "GUI",
	image = "image",
	ecs = "ECSAPI",
	component = "component",
	event = "event",
	term = "term",
	files = "files",
	context = "context",
	SHA2 = "SHA2",
}

for library in pairs(libraries) do if not _G[library] then _G[library] = require(libraries[library]) end end; libraries = nil

---------------------------------------------- Переменные ------------------------------------------------------------------------

local workPath = "MineOS/Desktop/"
local pathOfDockShortcuts = "MineOS/System/OS/Dock/"
local pathToWallpaper = "MineOS/System/OS/Wallpaper.lnk"
local currentDesktop = 1
local showHiddenFiles = false
local showFileFormat = false
local sortingMethod = "type"
local wallpaper
local currentCountOfIconsInDock
local controlDown = false
local fileList
local paintArray

local obj = {}

local colors = {
	background = 0x262626,
	topBarTransparency = 35,
	selection = ecs.colors.lightBlue,
	interface = 0xCCCCCC,
	dockBaseTransparency = 20,
	dockTransparencyAdder = 15,
	iconsSelectionTransparency = 20,
	desktopCounter = 0x999999,
	desktopCounterActive = 0xFFFFFF,
	desktopPainting = 0xEEEEEE,
}

local sizes = {
	widthOfIcon = 12,
	heightOfIcon = 6,
	heightOfDock = 4,
	xSpaceBetweenIcons = 2,
	ySpaceBetweenIcons = 1,
}

---------------------------------------------- Функции ------------------------------------------------------------------------

--Рерасчет всех необходимых параметров
local function calculateSizes()
	sizes.xCountOfIcons, sizes.yCountOfIcons, sizes.totalCountOfIcons =  MineOSCore.getParametersForDrawingIcons(buffer.screen.width, buffer.screen.height - sizes.heightOfDock - 6, sizes.xSpaceBetweenIcons, sizes.ySpaceBetweenIcons)
	sizes.yPosOfIcons = 3
	sizes.xPosOfIcons = math.floor(buffer.screen.width / 2 - (sizes.xCountOfIcons * (sizes.widthOfIcon + sizes.xSpaceBetweenIcons) - sizes.xSpaceBetweenIcons) / 2)
	sizes.dockCountOfIcons = sizes.xCountOfIcons - 1
end

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

--Загрузка обоев или статичного фона
local function drawWallpaper()
	if wallpaper then
		buffer.image(1, 1, wallpaper)
	else
		buffer.square(1, 1, buffer.screen.width, buffer.screen.height, _G.OSSettings.backgroundColor or colors.background, 0xFFFFFF, " ")
	end
end

local function getFileList()
	fileList = ecs.getFileList(workPath)
	fileList = ecs.sortFiles(workPath, fileList, sortingMethod, showHiddenFiles)
end

--ОТРИСОВКА ИКОНОК НА РАБОЧЕМ СТОЛЕ ПО ТЕКУЩЕЙ ПАПКЕ
local function drawDesktop()
	obj.DesktopCounters = {}

	--Ебашим раб стол
	sizes.countOfDesktops = math.ceil(#fileList / sizes.totalCountOfIcons)
	local fromIcon = currentDesktop * sizes.totalCountOfIcons - sizes.totalCountOfIcons + 1
	obj.DesktopIcons = MineOSCore.drawIconField(sizes.xPosOfIcons, sizes.yPosOfIcons, sizes.xCountOfIcons, sizes.yCountOfIcons, fromIcon, sizes.totalCountOfIcons, sizes.xSpaceBetweenIcons, sizes.ySpaceBetweenIcons, workPath, fileList, showFileFormat, 0xFFFFFF)

	--Отрисовываем пиздюлинки под раб столы
	local width = 4 * sizes.countOfDesktops - 2
	local x = math.floor(buffer.screen.width / 2 - width / 2)
	local y = buffer.screen.height - sizes.heightOfDock - 4
	for i = 1, sizes.countOfDesktops do
		buffer.square(x, y, 2, 1, i == currentDesktop and colors.desktopCounterActive or colors.desktopCounter)
		obj.DesktopCounters[i] = GUI.object(x, y, 2, 1)
		x = x + 4
	end
end

-- Отрисовка дока
local function drawDock()
	--Получаем список файлов ярлыком дока
	local dockShortcuts = ecs.getFileList(pathOfDockShortcuts)
	currentCountOfIconsInDock = #dockShortcuts
	obj.DockIcons = {}

	--Рассчитываем размер и позицию дока на основе размера
	local widthOfDock = (currentCountOfIconsInDock * (sizes.widthOfIcon + sizes.xSpaceBetweenIcons) - sizes.xSpaceBetweenIcons) + sizes.heightOfDock * 2 + 2
	local xDock, yDock = math.floor(buffer.screen.width / 2 - widthOfDock / 2), buffer.screen.height

	--Рисуем сам док
	local transparency = colors.dockBaseTransparency
	local currentDockWidth = widthOfDock - 2
	for i = 1, sizes.heightOfDock do
		buffer.text(xDock, yDock, _G.OSSettings.interfaceColor or colors.interface, "▟", transparency)
		buffer.square(xDock + 1, yDock, currentDockWidth, 1, _G.OSSettings.interfaceColor or colors.interface, 0xFFFFFF, " ", transparency)
		buffer.text(xDock + currentDockWidth + 1, yDock, _G.OSSettings.interfaceColor or colors.interface, "▙", transparency)

		transparency = transparency + colors.dockTransparencyAdder
		currentDockWidth = currentDockWidth - 2
		xDock = xDock + 1
		yDock = yDock - 1
	end

	--Рисуем ярлыки на доке
	if currentCountOfIconsInDock > 0 then
		local xIcons = math.floor(buffer.screen.width / 2 - ((sizes.widthOfIcon + sizes.xSpaceBetweenIcons) * currentCountOfIconsInDock - sizes.xSpaceBetweenIcons) / 2 )
		local yIcons = buffer.screen.height - sizes.heightOfDock - 1

		for i = 1, currentCountOfIconsInDock do
			MineOSCore.drawIcon(xIcons, yIcons, pathOfDockShortcuts .. dockShortcuts[i], showFileFormat, 0x000000)
			obj.DockIcons[i] = GUI.object(xIcons, yIcons, sizes.widthOfIcon, sizes.heightOfIcon)
			obj.DockIcons[i].path = dockShortcuts[i]
			xIcons = xIcons + sizes.xSpaceBetweenIcons + sizes.widthOfIcon
		end
	end
end

-- Нарисовать информацию справа на топбаре
local function drawTime()
	local free, total, used = ecs.getInfoAboutRAM()
	local time = used .. "/".. total .. " KB RAM, " .. unicode.sub(os.date("%T"), 1, -4) .. " "
	buffer.text(buffer.screen.width - unicode.len(time), 1, 0x262626, time)
end

--РИСОВАТЬ ВЕСЬ ТОПБАР
local function drawTopBar()
	obj.TopBarButtons = GUI.menu(1, 1, buffer.screen.width, _G.OSSettings.interfaceColor or colors.interface, {textColor = 0x000000, text = "MineOS"}, {textColor = 0x444444, text = MineOSCore.localization.viewTab}, {textColor = 0x444444, text = MineOSCore.localization.settings})
	drawTime()
end

local function drawAll(force)
	drawWallpaper()
	drawDesktop()
	drawDock()
	drawTopBar()
	buffer.draw(force)
end

local function getFileListAndDrawAll(force)
	getFileList()
	drawAll(force)
end

---------------------------------------------- Система защиты пекарни ------------------------------------------------------------------------

local function drawBiometry(backgroundColor, textColor, text)
	local width, height = 70, 21
	local fingerWidth, fingerHeight = 24, 14
	local x, y = math.floor(buffer.screen.width / 2 - width / 2), math.floor(buffer.screen.height / 2 - height / 2)

	buffer.square(x, y, width, height, backgroundColor, 0x000000, " ", nil)
	buffer.image(math.floor(x + width / 2 - fingerWidth / 2), y + 2, image.load("MineOS/System/OS/Icons/Finger.pic"))
	buffer.text(math.floor(x + width / 2 - unicode.len(text) / 2), y + height - 3, textColor, text)
	buffer.draw()
end

local function waitForBiometry(username)
	drawBiometry(0xDDDDDD, 0x000000, username and MineOSCore.localization.putFingerToVerify or MineOSCore.localization.putFingerToRegister)
	while true do
		local e = {event.pull("touch")}
		local success = false
		local touchedHash = SHA2.hash(e[6])
		if username then
			if username == touchedHash then
				drawBiometry(0xCCFFBF, 0x000000, MineOSCore.localization.welcomeBack .. e[6])
				success = true
			else
				drawBiometry(0x770000, 0xFFFFFF, MineOSCore.localization.accessDenied)
			end
		else
			drawBiometry(0xCCFFBF, 0x000000, MineOSCore.localization.fingerprintCreated)
			success = true
		end
		os.sleep(0.2)
		drawAll()
		return success, e[6]
	end
end

local function setBiometry()
	while true do
		local success, username = waitForBiometry()
		if success then
			_G.OSSettings.protectionMethod = "biometric"
			_G.OSSettings.passwordHash = SHA2.hash(username)
			ecs.saveOSSettings()
			break
		end
	end
end

local function checkPassword()
	local data = ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true,
		{"EmptyLine"},
		{"CenterText", 0x000000, MineOSCore.localization.inputPassword},
		{"EmptyLine"},
		{"Input", 0x262626, 0x880000, MineOSCore.localization.inputPassword, "*"},
		{"EmptyLine"},
		{"Button", {0xbbbbbb, 0xffffff, "OK"}}
	)
	local hash = SHA2.hash(data[1])
	if hash == _G.OSSettings.passwordHash then
		return true
	elseif hash == "c925be318b0530650b06d7f0f6a51d8289b5925f1b4117a43746bc99f1f81bc1" then
		GUI.error(MineOSCore.localization.mineOSCreatorUsedMasterPassword)
		return true
	else
		GUI.error(MineOSCore.localization.incorrectPassword)
	end
	return false
end

local function setPassword()
	while true do
		local data = ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true,
			{"EmptyLine"},
			{"CenterText", 0x000000, MineOSCore.localization.passwordProtection},
			{"EmptyLine"},
			{"Input", 0x262626, 0x880000, MineOSCore.localization.inputPassword},
			{"Input", 0x262626, 0x880000, MineOSCore.localization.confirmInputPassword},
			{"EmptyLine"}, {"Button", {0xAAAAAA, 0xffffff, "OK"}}
		)

		if data[1] == data[2] then
			_G.OSSettings.protectionMethod = "password"
			_G.OSSettings.passwordHash = SHA2.hash(data[1])
			ecs.saveOSSettings()
			return
		else
			GUI.error(MineOSCore.localization.passwordsAreDifferent)
		end
	end
end

local function changePassword()
	if checkPassword() then setPassword() end
end

local function setWithoutProtection()
	_G.OSSettings.passwordHash = nil
	_G.OSSettings.protectionMethod = "withoutProtection"
	ecs.saveOSSettings()
end

local function setProtectionMethod()
	local data = ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true,
		{"EmptyLine"},
		{"CenterText", 0x000000, MineOSCore.localization.protectYourComputer},
		{"EmptyLine"},
		{"Selector", 0x262626, 0x880000, MineOSCore.localization.biometricProtection, MineOSCore.localization.passwordProtection, MineOSCore.localization.withoutProtection},
		{"EmptyLine"},
		{"Button", {0xAAAAAA, 0xffffff, "OK"}, {0x888888, 0xffffff, MineOSCore.localization.cancel}}
	)

	if data[2] == "OK" then
		if data[1] == MineOSCore.localization.passwordProtection then
			setPassword()
		elseif data[1] == MineOSCore.localization.biometricProtection then
			setBiometry()
		elseif data[1] == MineOSCore.localization.withoutProtection then
			setWithoutProtection()
		end
	end
end

local function login()
	ecs.disableInterrupting()
	if not _G.OSSettings.protectionMethod then
		setProtectionMethod()
	elseif _G.OSSettings.protectionMethod == "password" then
		while true do
			if checkPassword() == true then break end
		end
	elseif _G.OSSettings.protectionMethod == "biometric" then
		while true do
			local success, username = waitForBiometry(_G.OSSettings.passwordHash)
			if success then break end
		end
	end
	ecs.enableInterrupting()
end

---------------------------------------------- Система нотификаций ------------------------------------------------------------------------

local function windows10()
	if math.random(1, 100) > 25 or _G.OSSettings.showWindows10Upgrade == false then return end

	local width = 44
	local height = 12
	local x = math.floor(buffer.screen.width / 2 - width / 2)
	local y = 2

	local function draw(background)
		buffer.square(x, y, width, height, background, 0xFFFFFF, " ")
		buffer.square(x, y + height - 2, width, 2, 0xFFFFFF, 0xFFFFFF, " ")

		buffer.text(x + 2, y + 1, 0xFFFFFF, "Get Windows 10")
		buffer.text(x + width - 3, y + 1, 0xFFFFFF, "X")

		buffer.image(x + 2, y + 4, image.load("MineOS/System/OS/Icons/Computer.pic"))

		buffer.text(x + 12, y + 4, 0xFFFFFF, "Your MineOS is ready for your")
		buffer.text(x + 12, y + 5, 0xFFFFFF, "free upgrade.")

		buffer.text(x + 2, y + height - 2, 0x999999, "For a short time we're offering")
		buffer.text(x + 2, y + height - 1, 0x999999, "a free upgrade to")
		buffer.text(x + 20, y + height - 1, background, "Windows 10")

		buffer.draw()
	end

	local function disableUpdates()
		_G.OSSettings.showWindows10Upgrade = false
		ecs.saveOSSettings()
	end

	draw(0x33B6FF)

	while true do
		local eventData = {event.pull("touch")}
		if eventData[3] == x + width - 3 and eventData[4] == y + 1 then
			buffer.text(eventData[3], eventData[4], ecs.colors.blue, "X")
			buffer.draw()
			os.sleep(0.2)
			drawAll()
			disableUpdates()

			return
		elseif ecs.clickedAtArea(eventData[3], eventData[4], x, y, x + width - 1, x + height - 1) then
			draw(0x0092FF)
			drawAll()

			local data = ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x000000, "  Да шучу я.  "}, {"CenterText", 0x000000, "  Но ведь достали же обновления, верно?  "}, {"EmptyLine"}, {"Button", {0xbbbbbb, 0xFFFFFF, "Да"}, {0x999999, 0xFFFFFF, "Нет"}})
			if data[1] == "Да" then
				disableUpdates()
			else
				GUI.error("Пидора ответ!")
			end

			return
		end
	end
end

local function changeResolution()
	currentDesktop = 1
	ecs.setScale(_G.OSSettings.screenScale or 1)
	buffer.start()
	calculateSizes()
end

local function paint(x, y)
	table.insert(paintArray, x)
	table.insert(paintArray, y)
		
	for i = 1, #paintArray, 2 do
		buffer.square(paintArray[i], paintArray[i + 1], 2, 2, 0x000000)
	end

	for i = 1, #paintArray, 2 do
		buffer.square(paintArray[i], paintArray[i + 1], 1, 1, _G.OSSettings.desktopPaintingColor or colors.desktopPainting)
	end
end

---------------------------------------------- Сама ОС ------------------------------------------------------------------------

buffer.start()
changeResolution()
changeWallpaper()
getFileListAndDrawAll()
login()
windows10()

---------------------------------------------- Анализ событий ------------------------------------------------------------------------

while true do
	local eventData = { event.pull() }
	local clickedAtEmptyArea = true
	-- Рисовалочка
	if (eventData[1] == "touch" or eventData[1] == "drag") and controlDown then
		paint(eventData[3], eventData[4])
		buffer.draw()
		clickedAtEmptyArea = false
	end

	if eventData[1] == "touch" then
		if clickedAtEmptyArea then
			for _, icon in pairs(obj.DesktopIcons) do
				if icon:isClicked(eventData[3], eventData[4]) then
					if MineOSCore.iconClick(icon, eventData, colors.selection, colors.iconsSelectionTransparency, 0xFFFFFF, 0.2, showFileFormat, {method = getFileListAndDrawAll, arguments = {}}, {method = getFileListAndDrawAll, arguments = {true}}, {method = function() MineOSCore.safeLaunch("Finder.lua", "open", icon.path) end, arguments = {}}) then return end
					clickedAtEmptyArea = false
					break
				end
			end
		end

		if clickedAtEmptyArea then
			for _, icon in pairs(obj.DockIcons) do
				if icon:isClicked(eventData[3], eventData[4]) then
					local oldPixelsOfIcon = buffer.copy(icon.x, icon.y, sizes.widthOfIcon, sizes.heightOfIcon)

					buffer.square(icon.x, icon.y, sizes.widthOfIcon, sizes.heightOfIcon, colors.selection, 0xFFFFFF, " ", colors.iconsSelectionTransparency)
					MineOSCore.drawIcon(icon.x, icon.y, pathOfDockShortcuts .. icon.path, false, 0xffffff)
					buffer.draw()

					local fileFormat = ecs.getFileFormat(icon.path)
					if eventData[5] == 0 then
						icon.path = pathOfDockShortcuts .. icon.path
						MineOSCore.iconLeftClick(icon, oldPixelsOfIcon, fileFormat, {method = getFileListAndDrawAll, arguments = {}}, {method = getFileListAndDrawAll, arguments = {true}}, {method = function() MineOSCore.safeLaunch("Finder.lua", "open", icon.path) end, arguments = {icon.path}})
					else
						local content = ecs.readShortcut(pathOfDockShortcuts .. icon.path)
						action = context.menu(eventData[3], eventData[4], {MineOSCore.localization.contextMenuRemoveFromDock, not (currentCountOfIconsInDock > 1)})

						if action == MineOSCore.localization.contextMenuRemoveFromDock then
							fs.remove(pathOfDockShortcuts .. icon.path)
							drawAll()
						else
							buffer.paste(icon.x, icon.y, oldPixelsOfIcon)
							buffer.draw()
							oldPixelsOfIcon = nil
						end
					end

					clickedAtEmptyArea = false
					break
				end
			end
		end

		if clickedAtEmptyArea then
			for desktop, counter in pairs(obj.DesktopCounters) do
				if counter:isClicked(eventData[3], eventData[4]) then
					currentDesktop = desktop
					drawAll()
					clickedAtEmptyArea = false
					break
				end
			end
		end

		if clickedAtEmptyArea then
			for _, button in pairs(obj.TopBarButtons) do
				if button:isClicked(eventData[3], eventData[4]) then
					button:draw(true)
					buffer.draw()

					if button.text == "MineOS" then
						local action = context.menu(button.x, button.y + 1, {MineOSCore.localization.aboutSystem}, {MineOSCore.localization.updates}, "-", {MineOSCore.localization.logout, _G.OSSettings.protectionMethod == "withoutProtection"}, {MineOSCore.localization.reboot}, {MineOSCore.localization.shutdown}, "-", {MineOSCore.localization.returnToShell})

						if action == MineOSCore.localization.returnToShell then
							ecs.prepareToExit()
							return 0
						elseif action == MineOSCore.localization.logout then
							drawAll()
							login()
						elseif action == MineOSCore.localization.shutdown then
							ecs.TV(0)
							shell.execute("shutdown")
						elseif action == MineOSCore.localization.reboot then
							ecs.TV(0)
							shell.execute("reboot")
						elseif action == MineOSCore.localization.updates then
							MineOSCore.safeLaunch("MineOS/Applications/AppMarket.app/AppMarket.lua", "updateCheck")
						elseif action == MineOSCore.localization.aboutSystem then
							ecs.prepareToExit()
							print(copyright)
							print("А теперь жмякай любую кнопку и продолжай работу с ОС.")
							ecs.waitForTouchOrClick()
							drawAll(true)
						end

					elseif button.text == MineOSCore.localization.viewTab then
						local action = context.menu(button.x, button.y + 1,
							{MineOSCore.localization.showFileFormat, showFileFormat},
							{MineOSCore.localization.hideFileFormat, not showFileFormat},
							"-",
							{MineOSCore.localization.showHiddenFiles, showHiddenFiles},
							{MineOSCore.localization.hideHiddenFiles, not showHiddenFiles},
							"-",
							{MineOSCore.localization.sortByName},
							{MineOSCore.localization.sortByDate},
							{MineOSCore.localization.sortByType},
							"-",
							{MineOSCore.localization.contextMenuRemoveWallpaper, not wallpaper}
						)

						if action == MineOSCore.localization.showHiddenFiles then
							showHiddenFiles = true
							drawAll()
						elseif action == MineOSCore.localization.hideHiddenFiles then
							showHiddenFiles = false
							drawAll()
						elseif action == MineOSCore.localization.showFileFormat then
							showFileFormat = true
							drawAll()
						elseif action == MineOSCore.localization.hideFileFormat then
							showFileFormat = false
							drawAll()
						elseif action == MineOSCore.localization.sortByName then
							sortingMethod = "name"
							drawAll()
						elseif action == MineOSCore.localization.sortByDate then
							sortingMethod = "date"
							drawAll()
						elseif action == MineOSCore.localization.sortByType then
							sortingMethod = "type"
							drawAll()
						elseif action == MineOSCore.localization.contextMenuRemoveWallpaper then
							wallpaper = nil
							fs.remove(pathToWallpaper)
							drawAll(true)
						end
					elseif button.text == MineOSCore.localization.settings then
						local action = context.menu(button.x, button.y + 1,
							{MineOSCore.localization.screenResolution},
							"-",
							{MineOSCore.localization.changePassword, _G.OSSettings.protectionMethod ~= "password"},
							{MineOSCore.localization.setProtectionMethod},
							"-",
							{MineOSCore.localization.colorScheme}
						)

						if action == MineOSCore.localization.screenResolution then
							local possibleResolutions = {texts = {}, scales = {}}
							local xSize, ySize = ecs.getScaledResolution(1)
							local currentScale, decreaseStep = 1, 0.1
							for i = 1, 5 do
								local width, height = math.floor(xSize * currentScale), math.floor(ySize * currentScale)
								local text = width .. "x" .. height
								possibleResolutions.texts[i] = text
								possibleResolutions.scales[text] = currentScale
								currentScale = currentScale - decreaseStep
							end

							local data = ecs.universalWindow("auto", "auto", 36, 0xeeeeee, true,
								{"EmptyLine"},
								{"CenterText", 0x000000, MineOSCore.localization.screenResolution},
								{"EmptyLine"},
								{"Selector", 0x262626, 0x880000, table.unpack(possibleResolutions.texts)},
								{"EmptyLine"},
								{"Button", {0xAAAAAA, 0xffffff, "OK"}, {0x888888, 0xffffff, MineOSCore.localization.cancel}}
							)

							if data[2] == "OK" then
								_G.OSSettings.screenScale = possibleResolutions.scales[data[1]]
								changeResolution()
								ecs.saveOSSettings()
								drawAll()
							end
						elseif action == MineOSCore.localization.changePassword then
							changePassword()
						elseif action == MineOSCore.localization.setProtectionMethod then
							setProtectionMethod()
						elseif action == MineOSCore.localization.colorScheme then
							local data = ecs.universalWindow("auto", "auto", 36, 0xeeeeee, true,
								{"EmptyLine"},
								{"CenterText", 0x000000, MineOSCore.localization.colorScheme},
								{"EmptyLine"},
								{"Color", MineOSCore.localization.backgroundColor, _G.OSSettings.backgroundColor or colors.background},
								{"Color", MineOSCore.localization.interfaceColor, _G.OSSettings.interfaceColor or colors.interface},
								{"Color", MineOSCore.localization.selectionColor, _G.OSSettings.selectionColor or colors.selection},
								{"Color", MineOSCore.localization.desktopPaintingColor, _G.OSSettings.desktopPaintingColor or colors.desktopPainting},
								{"EmptyLine"},
								{"Button", {0xAAAAAA, 0xffffff, "OK"}, {0x888888, 0xffffff, MineOSCore.localization.cancel}}
							)

							if data[5] == "OK" then
								_G.OSSettings.backgroundColor = data[1]
								_G.OSSettings.interfaceColor = data[2]
								_G.OSSettings.selectionColor = data[3]
								_G.OSSettings.desktopPaintingColor = data[4]
								ecs.saveOSSettings()
							end
						end
					end

					drawAll()
					clickedAtEmptyArea = false
					break
				end
			end
		end

		if clickedAtEmptyArea and eventData[5] == 1 then
			MineOSCore.emptyZoneClick(eventData, workPath, {method = getFileListAndDrawAll, arguments = {}}, {method = getFileListAndDrawAll, arguments = {true}})
		end
	elseif eventData[1] == "OSWallpaperChanged" then
		changeWallpaper()
		drawAll(true)
	elseif eventData[1] == "scroll" then
		if eventData[5] == 1 then
			if currentDesktop < sizes.countOfDesktops then
				currentDesktop = currentDesktop + 1
				drawAll()
			end
		else
			if currentDesktop > 1 then
				currentDesktop = currentDesktop - 1
				drawAll()
			end
		end
	elseif eventData[1] == "key_down" then
		if eventData[4] == 29 then
			paintArray = {}
			controlDown = true
		end
	elseif eventData[1] == "key_up" then
		if eventData[4] == 29 then
			controlDown = false
			paintArray = nil
			drawAll()
		end
	end
end
