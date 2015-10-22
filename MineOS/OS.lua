
local copyright = [[
	
	Тут можно было бы написать кучу текста, мол,
	вы не имеете прав на использование этой хуйни в
	коммерческих целях и прочую чушь, навеянную нам
	западной культурой. Но я же не пидор какой-то, верно?
	 
	Просто помни, сука, что эту ОСь накодил Тимофеев Игорь,
	ссылка на ВК: vk.com/id7799889

]]

local component = require("component")
local event = require("event")
local term = require("term")
local gpu = component.gpu
local internet = require("internet")

--Загружаем языковой пакетик чайный
local lang = config.readAll("System/OS/Languages/".._G._OSLANGUAGE..".lang")

------------------------------------------------------------------------------------------------------------------------

-- Ну, тут ваще изи все
local xSize, ySize = gpu.getResolution()

-- Это все для раб стола
local icons = {}
local workPath = "System/OS/Desktop/"
local currentFileList

--ПЕРЕМЕННЫЕ ДЛЯ ДОКА
local dockColor = 0xcccccc
local heightOfDock = 4
local background = 0x262626
local currentCountOfIconsInDock = 4
local pathOfDockShortcuts = "System/OS/Dock/"

--ПЕРЕМЕННЫЕ, КАСАЮЩИЕСЯ ИКОНОК
local widthOfIcon = 12
local heightOfIcon = 6
local xSpaceBetweenIcons = 2
local ySpaceBetweenIcons = 1
local xCountOfIcons = math.floor(xSize / (widthOfIcon + xSpaceBetweenIcons))
local yCountOfIcons = math.floor((ySize - (heightOfDock + 6)) / (heightOfIcon + ySpaceBetweenIcons))
local totalCountOfIcons = xCountOfIcons * yCountOfIcons
local iconsSelectionColor = ecs.colors.lightBlue
--local yPosOfIcons = math.floor((ySize - heightOfDock - 2) / 2 - (yCountOfIcons * (heightOfIcon + ySpaceBetweenIcons) - ySpaceBetweenIcons * 2) / 2)
local yPosOfIcons = 3
local xPosOfIcons = math.floor(xSize / 2 - (xCountOfIcons * (widthOfIcon + xSpaceBetweenIcons) - xSpaceBetweenIcons) / 2)

local dockCountOfIcons = xCountOfIcons - 1

--ПЕРЕМЕННЫЕ ДЛЯ ТОП БАРА
local topBarColor = 0xdddddd

------------------------------------------------------------------------------------------------------------------------

--СОЗДАНИЕ ОБЪЕКТОВ
local obj = {}
local function newObj(class, name, ...)
	obj[class] = obj[class] or {}
	obj[class][name] = {...}
end


--ОТРИСОВКА ИКОНОК НА РАБОЧЕМ СТОЛЕ ПО ТЕКУЩЕЙ ПАПКЕ
local function drawDesktop(x, y)

	currentFileList = ecs.getFileList(workPath)
	currentFileList = ecs.reorganizeFilesAndFolders(currentFileList, false, false)

	--ОЧИСТКА СТОЛА
	ecs.square(1, y, xSize, yCountOfIcons * (heightOfIcon + ySpaceBetweenIcons) - ySpaceBetweenIcons, background)

	--ОЧИСТКА ОБЪЕКТОВ ИКОНОК
	obj["DesktopIcons"] = {}

	--ОТРИСОВКА ИКОНОК ПО ФАЙЛ ЛИСТУ
	local counter = 1
	local xIcons, yIcons = x, y
	for i = 1, yCountOfIcons do
		for j = 1, xCountOfIcons do
			if not currentFileList[counter] then break end

			--ОТРИСОВКА КОНКРЕТНОЙ ИКОНКИ
			local path = workPath .. currentFileList[counter]
			--drawIconSelection(xIcons, yIcons, counter)
			ecs.drawOSIcon(xIcons, yIcons, path, true, 0xffffff)

			--СОЗДАНИЕ ОБЪЕКТА ИКОНКИ
			newObj("DesktopIcons", counter, xIcons, yIcons, xIcons + widthOfIcon - 1, yIcons + heightOfIcon - 1, path, nil)

			xIcons = xIcons + widthOfIcon + xSpaceBetweenIcons
			counter = counter + 1
		end

		xIcons = x
		yIcons = yIcons + heightOfIcon + ySpaceBetweenIcons
	end
end

--ОТРИСОВКА ДОКА
local function drawDock()

	--Очистка объектов дока
	obj["DockIcons"] = {}

	--ПОЛУЧИТЬ СПИСОК ЯРЛЫКОВ НА ДОКЕ
	local dockShortcuts = ecs.getFileList(pathOfDockShortcuts)
	currentCountOfIconsInDock = #dockShortcuts

	--ПОДСЧИТАТЬ РАЗМЕР ДОКА И ПРОЧЕЕ
	local widthOfDock = (currentCountOfIconsInDock * (widthOfIcon + xSpaceBetweenIcons) - xSpaceBetweenIcons) + heightOfDock * 2 + 2
	local xDock, yDock = math.floor(xSize / 2 - widthOfDock / 2) + 1, ySize - heightOfDock

	--Закрасить все фоном
	ecs.square(1, yDock - 1, xSize, heightOfDock + 2, background)

	--НАРИСОВАТЬ ПОДЛОЖКУ
	local color = dockColor
	for i = 1, heightOfDock do
		ecs.square(xDock + i, ySize - i + 1, widthOfDock - i * 2, 1, color)
		color = color - 0x181818
	end

	--НАРИСОВАТЬ ЯРЛЫКИ НА ДОКЕ
	if currentCountOfIconsInDock > 0 then
		local xIcons = math.floor(xSize / 2 - ((widthOfIcon + xSpaceBetweenIcons) * currentCountOfIconsInDock - xSpaceBetweenIcons * 4) / 2 )
		local yIcons = ySize - heightOfDock - 1

		for i = 1, currentCountOfIconsInDock do
			ecs.drawOSIcon(xIcons, yIcons, pathOfDockShortcuts..dockShortcuts[i], false, 0x000000)
			newObj("DockIcons", dockShortcuts[i], xIcons, yIcons, xIcons + widthOfIcon - 1, yIcons + heightOfIcon - 1)
			xIcons = xIcons + xSpaceBetweenIcons + widthOfIcon
		end
	end
end

--РИСОВАТЬ ВРЕМЯ СПРАВА
local function drawTime()
	local time = " " .. unicode.sub(os.date("%T"), 1, -4) .. " "
	local sTime = unicode.len(time)
	ecs.colorTextWithBack(xSize - sTime, 1, 0x000000, topBarColor, time)
end

--РИСОВАТЬ ВЕСЬ ТОПБАР
local function drawTopBar()

	--Элементы топбара
	local topBarElements = { "MineOS" }

	--Белая горизонтальная линия
	ecs.square(1, 1, xSize, 1, topBarColor)

	--Рисуем элементы и создаем объекты
	local xPos = 2
	gpu.setForeground(0x000000)
	for i = 1, #topBarElements do

		if i > 1 then gpu.setForeground(0x666666) end

		local length = unicode.len(topBarElements[i])
		gpu.set(xPos + 1, 1, topBarElements[i])

		newObj("TopBarButtons", topBarElements[i], xPos, 1, xPos + length + 1, 1)

		xPos = xPos + length + 2
	end

	--Рисуем время
	drawTime()
end

--РИСОВАТЬ ВАЩЕ ВСЕ СРАЗУ
local function drawAll()
	ecs.clearScreen(background)
	drawTopBar()
	drawDock()
	drawDesktop(xPosOfIcons, yPosOfIcons)
end


--Биометрический сканер
local function biometry()
	local users
	local path = "System/OS/Users.cfg"

	if fs.exists(path) then
		users = config.readFile(path)

		local width = 80
		local height = 25

		local x, y = math.floor(xSize / 2 - width / 2), math.floor(ySize / 2 - height / 2)

		local Finger = image.load("System/OS/Icons/Finger.png")
		local OK = image.load("System/OS/Installer/OK.png")
		local OC

		local function okno(color, textColor, text, images)
			ecs.square(x, y, width, height, color)
			ecs.windowShadow(x, y, width, height)

			image.draw(math.floor(xSize / 2 - 15), y + 2, images)

			gpu.setBackground(color)
			gpu.setForeground(textColor)
			ecs.centerText("x", y + height - 5, text)
		end

		okno(ecs.windowColors.background, ecs.windowColors.usualText, lang.fingerToLogin, Finger)

		local exit
		while true do
			if exit then break end

			local e = {event.pull()}
			if e[1] == "touch" then
				for _, val in pairs(users) do
					if e[6] == val or e[6] == "IT" then
						okno(ecs.windowColors.background, ecs.windowColors.usualText, lang.welcomeBack..e[6], OK)
						os.sleep(1.5)
						exit = true
						break
					end
				end

				if not exit then
					okno(0xaa0000, 0xffffff, lang.accessDenied, Finger)
					os.sleep(1.5)
					okno(ecs.windowColors.background, ecs.windowColors.usualText, lang.fingerToLogin, Finger)
				end
			end
		end

		Finger = nil
		users = nil
	end
end

--Запустить конфигуратор ОС, если еще не запускался
local function launchConfigurator()
	if not fs.exists("System/OS/Users.cfg") and not fs.exists("System/OS/Password.cfg") and not fs.exists("System/OS/WithoutProtection.cfg") then
		drawAll()
		--ecs.prepareToExit()
		shell.execute("System/OS/Configurator/Configurator.lua")
		drawAll()
		--ecs.prepareToExit()
		return true
	end
end

--Аккуратно запускаем биометрию - а то мало ли ctrl alt c
local function safeBiometry()
	ecs.prepareToExit()
	while true do
		local s, r = pcall(biometry)
		if s then break end
	end
end

--Простое окошко ввода пароля и его анализ по конфигу
local function login()
	local readedPassword = config.readFile("System/OS/Password.cfg")[1]
	while true do
		local password = ecs.beautifulInput("auto", "auto", 30, lang.enterSystem, "Ок", ecs.windowColors.background, ecs.windowColors.usualText, 0xcccccc, true, {lang.password, true})[1]
		if password == readedPassword then
			return
		else
			ecs.error(lang.accessDenied)
		end
	end
end

--Безопасный ввод пароля, чтоб всякие дауны не крашнули прогу
local function safeLogin()
	drawAll()
	while true do
		local s, r = pcall(login)
		if s then return true end
	end
end

--Финальный вход в систему
local function enterSystem()
	if fs.exists("System/OS/Password.cfg") then
		safeLogin()
	elseif fs.exists("System/OS/Users.cfg") then
		safeBiometry()
		drawAll()
	elseif fs.exists("System/OS/WithoutProtection.cfg") then
		drawAll()
	end
end

--Проверка имени файла для всяких полей ввода, а то заебался писать это везде
local function isNameCorrect(name)
	if name ~= "" and name ~= " " and name ~= nil then
		return true
	else
		ecs.error(lang.invalidName)
		return false
	end
end

--Рисуем маленькую полоску оповещений
local function notification(text)
	local maxWidth = math.floor(xSize * 2 / 3)
	local height = 3
	local width = unicode.len(text) + 5
	width = math.min(maxWidth, width)
	local x = math.floor(xSize / 2 - width / 2)
	local y = 1

	--Запоминаем, что было нарисовано
	local oldPixels = ecs.rememberOldPixels(x, y, x + width - 1, y + height - 1)

	--Рисуем саму полосочку
	ecs.square(x, y, width, height, 0xffffff)
	ecs.colorText(x + 4, y + 1, ecs.windowColors.usualText, ecs.stringLimit("end", text, width - 5))
	ecs.colorTextWithBack(x + 1, y + 1, 0xffffff, ecs.colors.blue, "❕")
	--Крестик
	ecs.colorTextWithBack(x + width - 1, y, 0x000000, 0xffffff, "x")

	newObj("Notification", "Exit", x + width - 1, y, x + width - 1, y)
	newObj("Notification", "Show", x, y, x + width - 2, y + height - 1)

	return oldPixels
end

local function createDesktopShortCuts()
	local apps = {
		"Calc.app",
		"Calendar.app",
		"Control.app",
		"Crossword.app",
		"Finder.app",
		"Geoscan.app",
		"Highlight.app",
		"HoloClock.app",
		"HoloEdit.app",
		"MineCode.app",
		"Pastebin.app",
		"Photoshop.app",
		"Piano.app",
		"RCON.app",
		"Robot.app",
		"Shooting.app",
		"Shop.app",
		"CodeDoor.app",
		"Snake.app",
		"Keyboard.app",
		"Nano.app",
	}

	local dockApps = {
		"Finder.app",
		"Calendar.app",
		"Control.app",
		"Photoshop.app",
	}

	local desktopPath = "System/OS/Desktop/"
	local dockPath = "System/OS/Dock/"

	fs.makeDirectory(desktopPath .. "My files")
	for i = 1, #apps do
		local pathToShortcut = desktopPath .. ecs.hideFileFormat(apps[i]) .. ".lnk"
		if not fs.exists(pathToShortcut) then
			ecs.createShortCut(pathToShortcut, apps[i])
		end
	end

	fs.makeDirectory(dockPath)

	for i = 1, #dockApps do
		local pathToShortcut = dockPath .. ecs.hideFileFormat(dockApps[i]) .. ".lnk"
		if not fs.exists(pathToShortcut) then
			ecs.createShortCut(pathToShortcut, dockApps[i])
		end
	end
end


--А вот и системка стартует
------------------------------------------------------------------------------------------------------------------------

createDesktopShortCuts()
if not launchConfigurator() then enterSystem() end

------------------------------------------------------------------------------------------------------------------------

-- Понеслась моча по трубам
while true do

	local eventData = { event.pull() }
	if eventData[1] == "touch" then

		--Удаляем нотификацию, если имеется
		if notificationOldPixels then ecs.drawOldPixels(notificationOldPixels); notificationOldPixels = false end

		--Переменная, становящаяся ложью только в случае клика на какой-либо элемент, не суть какой
		local clickedOnEmptySpace = true

		--Клик на иконочки раб стола
		for key, value in pairs(obj["DesktopIcons"]) do
			if ecs.clickedAtArea(eventData[3], eventData[4], obj["DesktopIcons"][key][1], obj["DesktopIcons"][key][2], obj["DesktopIcons"][key][3], obj["DesktopIcons"][key][4]) then

				--Кликнули на элемент, а не в очко какое-то
				clickedOnEmptySpace = false

				ecs.square(obj["DesktopIcons"][key][1], obj["DesktopIcons"][key][2], widthOfIcon, heightOfIcon, iconsSelectionColor)
				ecs.drawOSIcon(obj["DesktopIcons"][key][1], obj["DesktopIcons"][key][2], obj["DesktopIcons"][key][5], true, 0xffffff)

				local fileFormat = ecs.getFileFormat(obj["DesktopIcons"][key][5])

				--ЕСЛИ ЛЕВАЯ КНОПА МЫШИ
				if eventData[5] == 0 then
					
					os.sleep(0.2)
					
					if fs.isDirectory(obj["DesktopIcons"][key][5])	then
						if fileFormat == ".app" then
							ecs.launchIcon(obj["DesktopIcons"][key][5])
							drawAll()
						else
							shell.execute("Finder.app/Finder.lua "..obj["DesktopIcons"][key][5])
						end
					else
						ecs.launchIcon(obj["DesktopIcons"][key][5])
						drawAll()
					end
					

				--ЕСЛИ ПРАВАЯ КНОПА МЫШИ
				elseif eventData[5] == 1 and not keyboard.isControlDown() then

					local action
					local fileFormat = ecs.getFileFormat(obj["DesktopIcons"][key][5])

					--РАЗНЫЕ КОНТЕКСТНЫЕ МЕНЮ
					if fileFormat == ".app" and fs.isDirectory(obj["DesktopIcons"][key][5]) then
						action = context.menu(eventData[3], eventData[4], {lang.contextShowContent}, "-", {lang.contextCopy, false, "^C"}, {lang.contextPaste, not _G.clipboard, "^V"}, "-", {lang.contextRename}, {lang.contextCreateShortcut}, "-",  {lang.contextUploadToPastebin, true}, "-", {lang.contextAddToDock, not (currentCountOfIconsInDock < dockCountOfIcons and workPath ~= "System/OS/Dock/")}, {lang.contextDelete, false, "⌫"})
					elseif fileFormat ~= ".app" and fs.isDirectory(obj["DesktopIcons"][key][5]) then
						action = context.menu(eventData[3], eventData[4], {lang.contextCopy, false, "^C"}, {lang.contextPaste, not _G.clipboard, "^V"}, "-", {lang.contextRename}, {lang.contextCreateShortcut}, "-", {lang.contextUploadToPastebin, true}, "-", {lang.contextDelete, false, "⌫"})
					else
						action = context.menu(eventData[3], eventData[4], {lang.contextEdit}, "-", {lang.contextCopy, false, "^C"}, {lang.contextPaste, not _G.clipboard, "^V"}, "-", {lang.contextRename}, {lang.contextCreateShortcut}, "-", {lang.contextUploadToPastebin, true}, "-", {lang.contextAddToDock, not (currentCountOfIconsInDock < dockCountOfIcons and workPath ~= "System/OS/Dock/")}, {lang.contextDelete, false, "⌫"})
					end

					--Анализ действия контекстного меню
					if action == lang.contextShowContent then
						shell.execute("Finder.app/Finder.lua "..obj["DesktopIcons"][key][5])
					elseif action == lang.contextEdit then
						ecs.editFile(obj["DesktopIcons"][key][5])
						drawAll()
					elseif action == lang.contextDelete then
						fs.remove(obj["DesktopIcons"][key][5])
						drawDesktop(xPosOfIcons, yPosOfIcons)
					elseif action == lang.contextCopy then
						_G.clipboard = obj["DesktopIcons"][key][5]
					elseif action == lang.contextPaste then
						ecs.copy(_G.clipboard, workPath)
						drawDesktop(xPosOfIcons, yPosOfIcons)
					elseif action == lang.contextRename then
						ecs.rename(obj["DesktopIcons"][key][5])
						drawDesktop(xPosOfIcons, yPosOfIcons)
					elseif action == lang.contextCreateShortcut then
						ecs.createShortCut(workPath .. ecs.hideFileFormat(obj["DesktopIcons"][key][5]) .. ".lnk", obj["DesktopIcons"][key][5])
						drawDesktop(xPosOfIcons, yPosOfIcons)
					elseif action == lang.contextAddToDock then
						ecs.createShortCut("System/OS/Dock/" .. ecs.hideFileFormat(obj["DesktopIcons"][key][5]) .. ".lnk", obj["DesktopIcons"][key][5])
						drawDesktop(xPosOfIcons, yPosOfIcons)
						drawDock()
					end

				end

				ecs.square(obj["DesktopIcons"][key][1], obj["DesktopIcons"][key][2], widthOfIcon, heightOfIcon, background)
				ecs.drawOSIcon(obj["DesktopIcons"][key][1], obj["DesktopIcons"][key][2], obj["DesktopIcons"][key][5], true, 0xffffff)

				break
			end	
		end


		--Клик на Доковские иконки
		for key, value in pairs(obj["DockIcons"]) do
			if ecs.clickedAtArea(eventData[3], eventData[4], obj["DockIcons"][key][1], obj["DockIcons"][key][2], obj["DockIcons"][key][3], obj["DockIcons"][key][4]) then
			
				--Кликнули на элемент, а не в очко какое-то
				clickedOnEmptySpace = false

				ecs.square(obj["DockIcons"][key][1], obj["DockIcons"][key][2], widthOfIcon, heightOfIcon, iconsSelectionColor)
				ecs.drawOSIcon(obj["DockIcons"][key][1], obj["DockIcons"][key][2], pathOfDockShortcuts..key, showFileFormat)
				
				if eventData[5] == 0 then 
					os.sleep(0.2)
					ecs.launchIcon(pathOfDockShortcuts..key)
					drawAll()
				else
					local content = ecs.readShortcut(pathOfDockShortcuts..key)
					
					action = context.menu(eventData[3], eventData[4], {lang.contextRemoveFromDock, not (currentCountOfIconsInDock > 1)})

					if action == lang.contextRemoveFromDock then
						fs.remove(pathOfDockShortcuts..key)
						drawDock()
					else
						drawDock()
					end

					break

				end
			end
		end

		--Обработка верхних кнопок - ну, вид там, и проч
		for key, val in pairs(obj["TopBarButtons"]) do
			if ecs.clickedAtArea(eventData[3], eventData[4], obj["TopBarButtons"][key][1], obj["TopBarButtons"][key][2], obj["TopBarButtons"][key][3], obj["TopBarButtons"][key][4]) then
		
				--Кликнули на элемент, а не в очко какое-то
				clickedOnEmptySpace = false

				ecs.colorTextWithBack(obj["TopBarButtons"][key][1], obj["TopBarButtons"][key][2], 0xffffff, ecs.colors.blue, " "..key.." ")

				if key == "MineOS" then
					local action = context.menu(obj["TopBarButtons"][key][1], obj["TopBarButtons"][key][2] + 1, {lang.aboutSystem}, {lang.updateSystem}, "-", {lang.restart}, {lang.shutdown}, "-", {lang.backToShell})
				
					if action == lang.backToShell then
						ecs.prepareToExit()
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
						drawAll()
					end
				end

				drawTopBar()

				break

			end
		end

		--А если все-таки кликнулось в очко какое-то, то вот че делать
		if clickedOnEmptySpace then
			if eventData[5] == 1 then
				local action = context.menu(eventData[3], eventData[4], {lang.contextNewFile}, {lang.contextNewFolder}, "-", {lang.contextPaste, not _G.clipboard, "^V"})

				--Создать новый файл
				if action == lang.contextNewFile then
					ecs.newFile(workPath)
					drawAll()
				--Создать новую папку
				elseif action == lang.contextNewFolder then
					ecs.newFolder(workPath)
					drawDesktop(xPosOfIcons, yPosOfIcons)
				--Вставить файл
				elseif action == lang.contextPaste then

				end
				
			end
		end

	--Если скрин делаем
	elseif eventData[1] == "screenshot" then
		drawDesktop(xPosOfIcons, yPosOfIcons)

	--Сочетания клавищ, пока не реализовано
	elseif eventData[1] == "key_down" then

	end
end















