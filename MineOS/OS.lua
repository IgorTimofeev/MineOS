
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
local unicode = require("unicode")
--local ecs = require("ECSAPI")
--local fs = require("filesystem")
--local shell = require("shell")
local context = require("context")
local computer = require("computer")
local keyboard = require("keyboard")
--local image = require("image")
--local config = require("config")
local zip = require("zip")
local gpu = component.gpu
local internet = require("internet")

--Загружаем языковой пакетик чайный
local lang = config.readAll("System/OS/Languages/".._G._OSLANGUAGE..".lang")

------------------------------------------------------------------------------------------------------------------------

-- Ну, тут ваще изи все
local xSize, ySize = gpu.getResolution()

-- Это все для раб стола
local icons = {}
local workPath = ""
local workPathHistory = {}
local clipboard
local currentFileList
local currentDesktop = 1
local countOfDesktops

--ЗАГРУЗКА ИКОНОК
icons["folder"] = image.load("System/OS/Icons/Folder.png")
icons["script"] = image.load("System/OS/Icons/Script.png")
icons["text"] = image.load("System/OS/Icons/Text.png")
icons["config"] = image.load("System/OS/Icons/Config.png")
icons["lua"] = image.load("System/OS/Icons/Lua.png")
icons["image"] = image.load("System/OS/Icons/Image.png")
icons["imageJPG"] = image.load("System/OS/Icons/ImageJPG.png")
icons["pastebin"] = image.load("System/OS/Icons/Pastebin.png")

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
local xPosOfIcons = math.floor(xSize / 2 - (xCountOfIcons * (widthOfIcon + xSpaceBetweenIcons) - xSpaceBetweenIcons*4) / 2)

local dockCountOfIcons = xCountOfIcons - 1

--ПЕРЕМЕННЫЕ ДЛЯ ТОП БАРА
local topBarColor = 0xdddddd
local showHiddenFiles = false
local showSystemFiles = false
local showFileFormat = false

------------------------------------------------------------------------------------------------------------------------

--СОЗДАНИЕ ОБЪЕКТОВ
local obj = {}
local function newObj(class, name, ...)
	obj[class] = obj[class] or {}
	obj[class][name] = {...}
end


-- Не забудь потом сделат общее апи для гитхаба - а то что за копипаста?
-- Непорядок!
-- ЗАГРУЗОЧКА С ГИТХАБА
local function getFromGitHub(url, path)
	local sContent = ""
	local result, response = pcall(internet.request, url)
	if not result then
		return nil
	end

	fs.remove(path)
	fs.makeDirectory(fs.path(path))
	local file = io.open(path, "w")

	for chunk in response do
		file:write(chunk)
		sContent = sContent .. chunk
	end

	file:close()

	return sContent
end

--БЕЗОПАСНАЯ ЗАГРУЗОЧКА
local function getFromGitHubSafely(url, path)
	local success, sRepos = pcall(getFromGitHub, url, path)
	if not success then
		--ecs.error("Could not connect to the Internet. Please ensure you have an Internet connection.")
		return false, sRepos
	end
	return sRepos
end

--Создать ярлык для конкретной проги
local function createShortCut(path, pathToProgram)
	fs.remove(path)
	fs.makeDirectory(fs.path(path))
	local file = io.open(path, "w")
	file:write("return ", "\"", pathToProgram, "\"")
	file:close()
end

--Создать ярлык для конкретной пасты
local function createPastebinShortcut(path, pastebinLink)
	fs.remove(path)
	fs.makeDirectory(fs.path(path))
	local file = io.open(path .. "/"..pastebinLink .. ".paste", "w")
	file:write("return ", "\"", pastebinLink, "\"")
	file:close()
end

--ПОЛУЧИТЬ ДАННЫЕ О ФАЙЛЕ ИЗ ЯРЛЫКА
local function readShortcut(path)
	local success, filename = pcall(loadfile(path))
	if success then
		return filename
	else
		error("Ошибка чтения файла ярлыка. Вероятно, он создан криво, либо не существует в папке " .. path)
	end
end

--ОТРИСОВКА ТЕКСТА ПОД ИКОНКОЙ
local function drawIconText(xIcons, yIcons, path)

	local text = fs.name(path)

	if not showFileFormat then
		local fileFormat = ecs.getFileFormat(text)
		if fileFormat then
			text = unicode.sub(text, 1, -(unicode.len(fileFormat) + 1))
		end
	end

	text = ecs.stringLimit("end", text, widthOfIcon)
	local textPos = xIcons + math.floor(widthOfIcon / 2 - unicode.len(text) / 2) - 2

	ecs.adaptiveText(textPos, yIcons + heightOfIcon - 1, text, 0xffffff)
end

--ОТРИСОВКА КОНКРЕТНОЙ ОДНОЙ ИКОНКИ
local function drawIcon(xIcons, yIcons, path)
	--НАЗНАЧЕНИЕ ВЕРНОЙ ИКОНКИ
	local icon

	local fileFormat = ecs.getFileFormat(path)

	if fs.isDirectory(path) then
		if fileFormat == ".app" then
			icon = path .. "/Resources/Icon.png" 
			icons[icon] = image.load(icon)
		else
			icon = "folder"
		end
	else
		if fileFormat == ".lnk" then
			local shortcutLink = readShortcut(path)
			drawIcon(xIcons, yIcons, shortcutLink)
			ecs.colorTextWithBack(xIcons + widthOfIcon - 6, yIcons + heightOfIcon - 3, 0x000000, 0xffffff, "⤶")
			drawIconText(xIcons, yIcons, path)
			return 0
		elseif fileFormat == ".cfg" or fileFormat == ".config" then
			icon = "config"
		elseif fileFormat == ".txt" or fileFormat == ".rtf" then
			icon = "text"
		elseif fileFormat == ".lua" then
		 	icon = "lua"
		elseif fileFormat == ".png" then
		 	icon = "image"
		elseif fileFormat == ".jpg" then
		 	icon = "imageJPG"
		elseif fileFormat == ".paste" then
			icon = "pastebin"
		else
			icon = "script"
		end
	end

	--ОТРИСОВКА ИКОНКИ
	image.draw(xIcons, yIcons, icons[icon] or icons["script"])

	--ОТРИСОВКА ТЕКСТА
	drawIconText(xIcons, yIcons, path)

end

-- НАРИСОВАТЬ ВЫДЕЛЕНИЕ ИКОНКИ
local function drawIconSelection(x, y, nomer)
	if obj["DesktopIcons"][nomer][6] == true then
		ecs.square(x - 2, y, widthOfIcon, heightOfIcon, iconsSelectionColor)
	elseif obj["DesktopIcons"][nomer][6] == false then
		ecs.square(x - 2, y, widthOfIcon, heightOfIcon, background)
	end
end

-- Развидеть все
local function deselectAll(mode)
	for key, val in pairs(obj["DesktopIcons"]) do
		if not mode then
			if obj["DesktopIcons"][key][6] == true then
				obj["DesktopIcons"][key][6] = false
			end
		else
			if obj["DesktopIcons"][key][6] == false then
				obj["DesktopIcons"][key][6] = nil
			end
		end
	end
end

------------------------------------------------------------------------------------------------

--То, что не нужно отрисовывать
local systemFiles = {
	"bin/",
	"lib/",
	"OS.lua",
	"autorun.lua",
	"init.lua",
	"tmp/",
	"usr/",
	"mnt/",
	"etc/",
	"boot/",
	--"System/",
}

-- Потная штучка, надо будет перекодить - а то странно выглядит, да и условия идиотские
local function reorganizeFilesAndFolders(massivSudaPihay, showHiddenFiles, showSystemFiles)

	local massiv = {}

	for i = 1, #massivSudaPihay do
		if ecs.isFileHidden(massivSudaPihay[i]) and showHiddenFiles then
			table.insert(massiv, massivSudaPihay[i])
		end
	end

	for i = 1, #massivSudaPihay do
		local cyka = massivSudaPihay[i]
		if fs.isDirectory(cyka) and not ecs.isFileHidden(cyka) and ecs.getFileFormat(cyka) ~= ".app" then
			table.insert(massiv, cyka)
		end
		cyka = nil
	end

	for i = 1, #massivSudaPihay do
		local cyka = massivSudaPihay[i]
		if (not fs.isDirectory(cyka) and not ecs.isFileHidden(cyka)) or (fs.isDirectory(cyka) and not ecs.isFileHidden(cyka) and ecs.getFileFormat(cyka) == ".app") then
			table.insert(massiv, cyka)
		end
		cyka = nil
	end


	if not showSystemFiles then
		if workPath == "" or workPath == "/" then
			--ecs.error("Сработало!")
			local i = 1
			while i <= #massiv do
				for j = 1, #systemFiles do
					--ecs.error("massiv[i] = " .. massiv[i] .. ", systemFiles[j] = "..systemFiles[j])
					if massiv[i] == systemFiles[j] then
						--ecs.error("Удалено! massiv[i] = " .. massiv[i] .. ", systemFiles[j] = "..systemFiles[j])
						table.remove(massiv, i)
						i = i - 1
						break
					end

				end

				i = i + 1
			end
		end
	end

	return massiv
end

------------------------------------------------------------------------------------------------

--ОТРИСОВКА ИКОНОК НА РАБОЧЕМ СТОЛЕ ПО ТЕКУЩЕЙ ПАПКЕ
local function drawDesktop(x, y)

	currentFileList = ecs.getFileList(workPath)
	currentFileList = reorganizeFilesAndFolders(currentFileList, showHiddenFiles, showSystemFiles)

	--ОЧИСТКА СТОЛА
	ecs.square(1, y, xSize, yCountOfIcons * (heightOfIcon + ySpaceBetweenIcons) - ySpaceBetweenIcons, background)

	--ОЧИСТКА ОБЪЕКТОВ ИКОНОК
	obj["DesktopIcons"] = {}

	--ОТРИСОВКА КНОПОЧЕК ПЕРЕМЕЩЕНИЯ
	countOfDesktops = math.ceil(#currentFileList / totalCountOfIcons)
	local xButtons, yButtons = math.floor(xSize / 2 - ((countOfDesktops + 1) * 3 - 3) / 2), ySize - heightOfDock - 3
	
	--Очистка серым фоном всех кнопочек
	ecs.square(1, yButtons, xSize, 1, background)
	
	--Отрисовка кнопки "Назад"
	if #workPathHistory > 0 then
		ecs.colorTextWithBack(xButtons, yButtons, 0x262626, 0xffffff, " <")
		newObj("DesktopButtons", 0, xButtons, yButtons, xButtons + 1, yButtons)
		xButtons = xButtons + 3
	end

	--Отрисовка остальных кнопочек
	for i = 1, countOfDesktops do
		local color = 0xffffff

		if i == currentDesktop then
			color = ecs.colors.green
		else
			color = 0xffffff
		end

		ecs.colorTextWithBack(xButtons, yButtons, 0x000000, color, "  ")
		newObj("DesktopButtons", i, xButtons, yButtons, xButtons + 1, yButtons)

		xButtons = xButtons + 3
	end

	--ОТРИСОВКА ИКОНОК ПО ФАЙЛ ЛИСТУ
	local counter = currentDesktop * totalCountOfIcons - totalCountOfIcons + 1
	local xIcons, yIcons = x, y
	for i = 1, yCountOfIcons do
		for j = 1, xCountOfIcons do
			if not currentFileList[counter] then break end

			--ОТРИСОВКА КОНКРЕТНОЙ ИКОНКИ
			local path = workPath .. currentFileList[counter]
			--drawIconSelection(xIcons, yIcons, counter)
			drawIcon(xIcons, yIcons, path)

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
			drawIcon(xIcons, yIcons, pathOfDockShortcuts..dockShortcuts[i])
			newObj("DockIcons", dockShortcuts[i], xIcons - 2, yIcons, xIcons + widthOfIcon - 1, yIcons + heightOfIcon - 1)
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
	local topBarElements = { "MineOS", lang.viewTab }

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

--ПЕРЕРИСОВАТЬ ВЫДЕЛЕННЫЕ ИКОНКИ
local function redrawSelectedIcons()

	for key, value in pairs(obj["DesktopIcons"]) do

		if obj["DesktopIcons"][key][6] ~= nil then

			local path = currentFileList[key]
			local x = obj["DesktopIcons"][key][1]
			local y = obj["DesktopIcons"][key][2]

			drawIconSelection(x, y, key)
			drawIcon(x, y, obj["DesktopIcons"][key][5])

		end
	end
end

--ВЫБРАТЬ ИКОНКУ И ВЫДЕЛИТЬ ЕЕ
local function selectIcon(nomer)
	if keyboard.isControlDown() and not obj["DesktopIcons"][nomer][6] then
		obj["DesktopIcons"][nomer][6] = true
		redrawSelectedIcons()
	elseif keyboard.isControlDown() and obj["DesktopIcons"][nomer][6] then
		obj["DesktopIcons"][nomer][6] = false
		redrawSelectedIcons()
	elseif not keyboard.isControlDown() then
		deselectAll()
		obj["DesktopIcons"][nomer][6] = true
		redrawSelectedIcons()
		deselectAll(true)
	end
end

--ЗАПУСТИТЬ ПРОГУ
local function launchIcon(path, arguments)

	--Запоминаем, какое разрешение было
	local oldWidth, oldHeight = gpu.getResolution()

	--Создаем нормальные аргументы для Шелла
	if arguments then arguments = " " .. arguments else arguments = "" end

	--Получаем файл формат заранее
	local fileFormat = ecs.getFileFormat(path)

	--Если это приложение
	if fileFormat == ".app" then
		ecs.prepareToExit()
		local cyka = path .. "/" .. ecs.hideFileFormat(fs.name(path)) .. ".lua"
		local success, reason = shell.execute(cyka)
		ecs.prepareToExit()
		if not success then ecs.displayCompileMessage(1, reason, true) end
		
	--Если это обычный луа файл - т.е. скрипт
	elseif fileFormat == ".lua" or fileFormat == nil then
		ecs.prepareToExit()
		local success, reason = shell.execute(path .. arguments)
		ecs.prepareToExit()
		if success then
			print(lang.programSuccessfullyExecuted)
		else
			ecs.displayCompileMessage(1, reason, true)
		end

	--Если это фоточка
	elseif fileFormat == ".png" then
		shell.execute("Photoshop.app/Photoshop.lua open "..path)
	
	--Если это текст или конфиг или языковой
	elseif fileFormat == ".txt" or fileFormat == ".cfg" or fileFormat == ".lang" then
		ecs.prepareToExit()
		shell.execute("edit "..path)

	--Если это ярлык
	elseif fileFormat == ".lnk" then
		local shortcutLink = readShortcut(path)
		if fs.exists(shortcutLink) then
			launchIcon(shortcutLink)
		else
			ecs.error(lang.badShortcut)
		end

	--Если это ссылка на пастебин
	elseif fileFormat == ".paste" then
		local shortcutLink = readShortcut(path)
		ecs.prepareToExit()
		local success, reason = shell.execute("pastebin run " .. shortcutLink)
		if success then
			print(lang.programSuccessfullyExecuted)
			ecs.waitForTouchOrClick()
		else
			ecs.displayCompileMessage(1, reason, false)
		end
	end

	--Ставим старое разрешение
	gpu.setResolution(oldWidth, oldHeight)
end

--Перейти в какую-то папку
local function changePath(path)
	table.insert(workPathHistory, workPath)	
	workPath = path
	currentDesktop = 1
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

--Удалить все, что выделено
local function deleteSelectedIcons()
	for key, value in pairs(obj["DesktopIcons"]) do
		if obj["DesktopIcons"][key][6] ~= nil then
			fs.remove(obj["DesktopIcons"][key][5])
		end
	end

	drawDesktop(xPosOfIcons, yPosOfIcons)
end

-- Копирование папки через рекурсию, т.к. fs.copy() не поддерживает папки
-- Ну долбоеб автор мода - хули я тут сделаю? Придется так вот
-- swg2you, привет маме ;)
local function copyFolder(path, toPath)
	local function doCopy(path)
		local fileList = ecs.getFileList(path)
		for i = 1, #fileList do
			if fs.isDirectory(path..fileList[i]) then
				doCopy(path..fileList[i])
			else
				fs.makeDirectory(toPath..path)
				fs.copy(path..fileList[i], toPath ..path.. fileList[i])
			end
		end
	end

	toPath = fs.path(toPath)
	doCopy(path.."/")
end

--Копирование файлов для операционки
local function copy(from, to)
	local name = fs.name(from)
	local toName = to.."/"..name
	local action = ecs.askForReplaceFile(toName)
	if action == nil or action == "replace" then
		fs.remove(toName)
		if fs.isDirectory(from) then
			copyFolder(from, toName)
		else
			fs.copy(from, toName)
		end
	elseif action == "keepBoth" then
		if fs.isDirectory(from) then
			copyFolder(from, to .. "/(copy)" .. name)
		else
			fs.copy(from, to .. "/(copy)" .. name)
		end	
	end
end

-- Скопировать иконки выделенные
local function copySelectedIcons()
	clipboard = {}
	for key, value in pairs(obj["DesktopIcons"]) do
		if obj["DesktopIcons"][key][6] ~= nil then
			table.insert(clipboard, obj["DesktopIcons"][key][5])
		end
	end
end

-- Вставить иконки выделенные
local function pasteSelectedIcons()
	for i = 1, #clipboard do
		if fs.exists(clipboard[i]) then
			copy(clipboard[i], workPath)
		else
			local action = ECSAPI.select("auto", "auto", " ", {{"Файл \"".. fs.name(clipboard[i]) .. "\" не найден, игнорирую его."}}, {{"Прервать копирование", 0xffffff, 0x000000}, {"Ок"}})
			if action == "Прервать копирование" then break end
		end
	end

	drawDesktop(xPosOfIcons, yPosOfIcons)
	drawDock()
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

--Проверка наличия новых версий
local function checkForUpdates()
	
	--Путь к Ватс-нев
	local pathToWhatsNew = "System/OS/Whats-new.txt"

	--Получить версию текущего Ватс-нев, епта
	local function getVersion()
		local lines = config.readFile(pathToWhatsNew)
		if unicode.sub(lines[1], 1, 7) == "Version" then
			local version = tonumber(unicode.sub(lines[1], 8, -1))
			return version
		end
	end

	--Получаем версию старого Ватс-нев
	local oldVersion
	if fs.exists(pathToWhatsNew) then oldVersion = getVersion() end

	--Качаем новую версию с заменой
	local success, reason = getFromGitHubSafely("https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/MineOS/Whats-new/" .. _OSLANGUAGE .. ".lang", pathToWhatsNew)
	
	--Если скачалось все нормально, то
	if success then
		-- И если есть старая версия, то
		if oldVersion then
			-- Получаем новую версию заместо старой
			local newVersion = getVersion()

			--Выводим нотификацию вон в таком случае
			if oldVersion < newVersion then
				return notification(lang.updatesAvailable)
			end
		end
	end
end

local function displayInfoAboutUpdate()

end


--А вот и системка стартует
------------------------------------------------------------------------------------------------------------------------

if not launchConfigurator() then enterSystem() end

local notificationOldPixels = checkForUpdates()

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

				--ЕСЛИ ЛЕВАЯ КНОПА МЫШИ
				if (eventData[5] == 0 and not keyboard.isControlDown()) or (eventData[5] == 1 and keyboard.isControlDown()) then
					
					--ЕСЛИ НЕ ВЫБРАНА, ТО ВЫБРАТЬ СНАЧАЛА
					if not obj["DesktopIcons"][key][6] then
						selectIcon(key)
					
					--А ЕСЛИ ВЫБРАНА УЖЕ, ТО ЗАПУСТИТЬ ПРОЖКУ ИЛИ ОТКРЫТЬ ПАПКУ
					else
						if fs.isDirectory(obj["DesktopIcons"][key][5]) and ecs.getFileFormat(obj["DesktopIcons"][key][5]) ~= ".app" then
							changePath(obj["DesktopIcons"][key][5])
						else
							deselectAll(true)
							launchIcon(obj["DesktopIcons"][key][5])
							drawAll()
						end
					end

				--ЕСЛИ ПРАВАЯ КНОПА МЫШИ
				elseif eventData[5] == 1 and not keyboard.isControlDown() then
					--selectIcon(key)
					obj["DesktopIcons"][key][6] = true
					redrawSelectedIcons()

					local action
					local fileFormat = ecs.getFileFormat(obj["DesktopIcons"][key][5])

					local function getSelectedIcons()
						local selectedIcons = {}
						for key, val in pairs(obj["DesktopIcons"]) do
							if obj["DesktopIcons"][key][6] then
								table.insert(selectedIcons, { ["id"] = key })
							end
						end
						return selectedIcons
					end


					--РАЗНЫЕ КОНТЕКСТНЫЕ МЕНЮ
					if #getSelectedIcons() > 1 then
						action = context.menu(eventData[3], eventData[4], {lang.contextCut, false, "^X"}, {lang.contextCopy, false, "^C"}, {lang.contextPaste, not clipboard, "^V"}, "-", {lang.contextArchive, true}, "-", {lang.contextDelete, false, "⌫"})
					elseif fileFormat == ".app" and fs.isDirectory(obj["DesktopIcons"][key][5]) then
						action = context.menu(eventData[3], eventData[4], {lang.contextShowContent}, "-", {lang.contextCut, false, "^X"}, {lang.contextCopy, false, "^C"}, {lang.contextPaste, not clipboard, "^V"}, "-", {lang.contextRename}, {lang.contextCreateShortcut}, "-", {lang.contextArchive, true}, {lang.contextUploadToPastebin, true}, "-", {lang.contextAddToDock, not (currentCountOfIconsInDock < dockCountOfIcons and workPath ~= "System/OS/Dock/")}, {lang.contextDelete, false, "⌫"})
					elseif fileFormat ~= ".app" and fs.isDirectory(obj["DesktopIcons"][key][5]) then
						action = context.menu(eventData[3], eventData[4], {lang.contextCut, false, "^X"}, {lang.contextCopy, false, "^C"}, {lang.contextPaste, not clipboard, "^V"}, "-", {lang.contextRename}, {lang.contextCreateShortcut}, "-", {lang.contextArchive, true}, {lang.contextUploadToPastebin, true}, "-", {lang.contextDelete, false, "⌫"})
					else
						action = context.menu(eventData[3], eventData[4], {lang.contextEdit}, "-", {lang.contextCut, false, "^X"}, {lang.contextCopy, false, "^C"}, {lang.contextPaste, not clipboard, "^V"}, "-", {lang.contextRename}, {lang.contextCreateShortcut}, "-", {lang.contextArchive, true}, {lang.contextUploadToPastebin, true}, "-", {lang.contextAddToDock, not (currentCountOfIconsInDock < dockCountOfIcons and workPath ~= "System/OS/Dock/")}, {lang.contextDelete, false, "⌫"})
					end

					--ecs.error(#getSelectedIcons())
					deselectAll()
					--ecs.error(#getSelectedIcons())

					--ecs.error("workPath = "..workPath..", obj = "..obj["DesktopIcons"][key][5])

					if action == lang.contextShowContent then
						changePath(obj["DesktopIcons"][key][5])
					elseif action == lang.contextEdit then
						ecs.prepareToExit()
						shell.execute("edit "..obj["DesktopIcons"][key][5])
						drawAll()
					elseif action == lang.contextDelete then
						deleteSelectedIcons()
					elseif action == lang.contextCopy then
						copySelectedIcons()
					elseif action == lang.contextPaste then
						pasteSelectedIcons()
					elseif action == lang.contextRename then
						local success = ecs.rename(obj["DesktopIcons"][key][5])
						success = true
						if success then drawDesktop(xPosOfIcons, yPosOfIcons) end
						drawDesktop(xPosOfIcons, yPosOfIcons)
					elseif action == lang.contextCreateShortcut then
						createShortCut(workPath .. ecs.hideFileFormat(obj["DesktopIcons"][key][5]) .. ".lnk", obj["DesktopIcons"][key][5])
						drawDesktop(xPosOfIcons, yPosOfIcons)
					elseif action == lang.contextAddToDock then
						createShortCut("System/OS/Dock/" .. ecs.hideFileFormat(obj["DesktopIcons"][key][5]) .. ".lnk", obj["DesktopIcons"][key][5])
						drawDock()
					else
						redrawSelectedIcons()
						deselectAll(true)
					end
					
				end

				break
			end	
		end

		--ПРОСЧЕТ КЛИКА НА КНОПОЧКИ ПЕРЕКЛЮЧЕНИЯ РАБОЧИХ СТОЛОВ
		for key, value in pairs(obj["DesktopButtons"]) do
			if ecs.clickedAtArea(eventData[3], eventData[4], obj["DesktopButtons"][key][1], obj["DesktopButtons"][key][2], obj["DesktopButtons"][key][3], obj["DesktopButtons"][key][4]) then
			
				--Кликнули на элемент, а не в очко какое-то
				clickedOnEmptySpace = false

				if key == 0 then 
					if #workPathHistory > 0 then
						ecs.colorTextWithBack(obj["DesktopButtons"][key][1], obj["DesktopButtons"][key][2], 0xffffff, ecs.colors.green, " <")
						os.sleep(0.2)
						workPath = workPathHistory[#workPathHistory]
						workPathHistory[#workPathHistory] = nil
						currentDesktop = 1

						drawDesktop(xPosOfIcons, yPosOfIcons)
					end
				else
					currentDesktop = key
					drawDesktop(xPosOfIcons, yPosOfIcons)
				end

				break
			end
		end

		--Клик на Доковские иконки
		for key, value in pairs(obj["DockIcons"]) do
			if ecs.clickedAtArea(eventData[3], eventData[4], obj["DockIcons"][key][1], obj["DockIcons"][key][2], obj["DockIcons"][key][3], obj["DockIcons"][key][4]) then
			
				--Кликнули на элемент, а не в очко какое-то
				clickedOnEmptySpace = false

				ecs.square(obj["DockIcons"][key][1], obj["DockIcons"][key][2], widthOfIcon, heightOfIcon, iconsSelectionColor)
				drawIcon(obj["DockIcons"][key][1] + 2, obj["DockIcons"][key][2], pathOfDockShortcuts..key)
				
				if eventData[5] == 0 then 
					os.sleep(0.2)
					launchIcon(pathOfDockShortcuts..key)
					drawAll()
				else
					local content = readShortcut(pathOfDockShortcuts..key)
					
					action = context.menu(eventData[3], eventData[4], {lang.contextOpenDockFolder}, {lang.contextOpenDockElementFolder, (fs.path(workPath) == fs.path(content))}, "-", {lang.contextRemoveFromDock, not (currentCountOfIconsInDock > 1)})

					if action == lang.contextOpenDockElementFolder then
						drawDock()	
						if content then
							changePath(fs.path(content))
						end
					elseif action == lang.contextRemoveFromDock then
						fs.remove(pathOfDockShortcuts..key)
						drawDock()
					elseif action == lang.contextOpenDockFolder then
						drawDock()
						changePath(pathOfDockShortcuts)
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

				if key == lang.viewTab then

					local action = context.menu(obj["TopBarButtons"][key][1], obj["TopBarButtons"][key][2] + 1, {(function() if showHiddenFiles then return lang.hideHiddenFiles else return lang.showHiddenFiles end end)()}, {(function() if showSystemFiles then return lang.hideSystemFiles else return lang.showSystemFiles end end)()}, "-", {(function() if showFileFormat then return lang.hideFileFormat else return lang.showFileFormat end end)()})
					
					if action == lang.hideHiddenFiles then
						showHiddenFiles = false
					elseif action == lang.showHiddenFiles then
						showHiddenFiles = true
					elseif action == lang.showSystemFiles then
						showSystemFiles = true
					elseif action == lang.hideSystemFiles then
						showSystemFiles = false
					elseif action == lang.showFileFormat then
						showFileFormat = true
					elseif action == lang.hideFileFormat then
						showFileFormat = false
					end

					drawTopBar()
					drawDesktop(xPosOfIcons, yPosOfIcons)

				elseif key == "MineOS" then
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
				local action = context.menu(eventData[3], eventData[4], {lang.contextNewFile}, {lang.contextNewFolder}, "-", {lang.contextPaste, not clipboard, "^V"}, {lang.contextRunFromPastebin}, {lang.contextCreatePastebinShortcut})

				--Создать новый файл
				if action == lang.contextNewFile then
					local name = ecs.beautifulInput("auto", "auto", 30, lang.contextNewFile, "Ок", ecs.windowColors.background, ecs.windowColors.usualText, 0xcccccc, true, {lang.name})[1]
					if isNameCorrect(name) then
						ecs.prepareToExit()
						shell.execute("edit " .. workPath .. name)
						drawAll()
					end

				--Создать новую папку
				elseif action == lang.contextNewFolder then
					local name = ecs.beautifulInput("auto", "auto", 30, lang.contextNewFolder, "Ок", ecs.windowColors.background, ecs.windowColors.usualText, 0xcccccc, true, {lang.name})[1]
					if isNameCorrect(name) then
						fs.makeDirectory(workPath .. name)
						drawDesktop(xPosOfIcons, yPosOfIcons)
					end

				--Запустить файл из пастебина
				elseif action == lang.contextRunFromPastebin then
					local name = ecs.beautifulInput("auto", "auto", 30, lang.contextRunFromPastebin, "Ок", ecs.windowColors.background, ecs.windowColors.usualText, 0xcccccc, true, {lang.name})[1]
					if isNameCorrect(name) then
						ecs.prepareToExit()
						shell.execute("pastebin run "..name)
						print(" "); print(" ")
						print(lang.pressAnyKeyToContinue)
						ecs.waitForTouchOrClick()
						drawAll()
					end

				--Создать ссылку на файл из пастебина
				elseif action == lang.contextCreatePastebinShortcut then
					local name = ecs.beautifulInput("auto", "auto", 30, lang.contextCreatePastebinShortcut, "Ок", ecs.windowColors.background, ecs.windowColors.usualText, 0xcccccc, true, {lang.name})[1]
					if isNameCorrect(name) then
						createPastebinShortcut(workPath, name)
						drawDesktop(xPosOfIcons, yPosOfIcons)
					end

				--Вставить файл
				elseif action == lang.contextPaste then
					pasteSelectedIcons()
				end
			end
		end


	--ПРОКРУТКА РАБОЧИХ СТОЛОВ
	elseif eventData[1] == "scroll" then
		if eventData[5] == -1 then
			if currentDesktop > 1 then currentDesktop = currentDesktop - 1; drawDesktop(xPosOfIcons, yPosOfIcons) end
		else
			if currentDesktop < countOfDesktops then currentDesktop = currentDesktop + 1; drawDesktop(xPosOfIcons, yPosOfIcons) end
		end

	--Сочетания клавищ, пока не реализовано
	elseif eventData[1] == "key_down" then

	end
end















