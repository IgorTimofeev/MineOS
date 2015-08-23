local component = require("component")
local event = require("event")
local term = require("term")
local unicode = require("unicode")
local ecs = require("ECSAPI")
local fs = require("filesystem")
local shell = require("shell")
local context = require("context")
local computer = require("computer")
local keyboard = require("keyboard")
local image = require("image")

local gpu = component.gpu

------------------------------------------------------------------------------------------------------------------------

local xSize, ySize = gpu.getResolution()

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

--ПЕРЕМЕННЫЕ ДЛЯ ДОКА
local dockColor = 0xcccccc
local heightOfDock = 4
local background = 0x262626

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


--ПЕРЕМЕННЫЕ ДЛЯ ТОП БАРА
local topBarColor = 0xdddddd
local showHiddenFiles = false
local showSystemFiles = true
local showFileFormat = false

------------------------------------------------------------------------------------------------------------------------

--СОЗДАНИЕ ОБЪЕКТОВ
local obj = {}
local function newObj(class, name, ...)
	obj[class] = obj[class] or {}
	obj[class][name] = {...}
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
		else
			icon = "script"
		end
	end

	--ОТРИСОВКА ИКОНКИ
	image.draw(xIcons, yIcons, icons[icon] or icons["script"])

	--ОТРИСОВКА ТЕКСТА
	drawIconText(xIcons, yIcons, path)

end

--НАРИСОВАТЬ ВЫДЕЛЕНИЕ ИКОНКИ
local function drawIconSelection(x, y, nomer)
	if obj["DesktopIcons"][nomer][6] == true then
		ecs.square(x - 2, y, widthOfIcon, heightOfIcon, iconsSelectionColor)
	elseif obj["DesktopIcons"][nomer][6] == false then
		ecs.square(x - 2, y, widthOfIcon, heightOfIcon, background)
	end
end

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
	ecs.square(1, yButtons, xSize, 1, background)
	for i = 1, countOfDesktops do
		local color = 0xffffff
		if i == 1 then
			if #workPathHistory == 0 then color = color - 0x444444 end
			ecs.colorTextWithBack(xButtons, yButtons, 0x262626, color, " <")
			newObj("DesktopButtons", 0, xButtons, yButtons, xButtons + 1, yButtons)
			xButtons = xButtons + 3
		end

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

	--ПУСТЬ К ЯРЛЫКАМ НА ДОКЕ
	local pathOfDockShortcuts = "System/OS/Dock"

	--ПОЛУЧИТЬ СПИСОК ЯРЛЫКОВ НА ДОКЕ
	local dockShortcuts = ecs.getFileList(pathOfDockShortcuts)
	local sDockShortcuts = #dockShortcuts

	--ПОДСЧИТАТЬ РАЗМЕР ДОКА И ПРОЧЕЕ
	local widthOfDock = (sDockShortcuts * (widthOfIcon + xSpaceBetweenIcons) - xSpaceBetweenIcons) + heightOfDock * 2 + 2
	local xDock, yDock = math.floor(xSize / 2 - widthOfDock / 2) + 1, ySize - heightOfDock

	--НАРИСОВАТЬ ПОДЛОЖКУ
	local color = dockColor
	for i = 1, heightOfDock do
		ecs.square(xDock + i, ySize - i + 1, widthOfDock - i * 2, 1, color)
		color = color - 0x181818
	end

	--НАРИСОВАТЬ ЯРЛЫКИ НА ДОКЕ
	if sDockShortcuts > 0 then
		local xIcons = math.floor(xSize / 2 - ((widthOfIcon + xSpaceBetweenIcons) * sDockShortcuts - xSpaceBetweenIcons * 4) / 2 )
		local yIcons = ySize - heightOfDock - 1

		for i = 1, sDockShortcuts do
			drawIcon(xIcons, yIcons, pathOfDockShortcuts.."/"..dockShortcuts[i])
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
	local topBarElements = { "MineOS", "Вид" }

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
			print("Программа выполнена успешно! Нажмите любую клавишу, чтобы продолжить.")
		else
			ecs.displayCompileMessage(1, reason, true)
		end

	elseif fileFormat == ".png" then
		shell.execute("Photoshop.app/Photoshop.lua open "..path)
	elseif fileFormat == ".txt" or fileFormat == ".cfg" or fileFormat == ".lang" then
		shell.execute("edit "..path)
	elseif fileFormat == ".lnk" then
		local shortcutLink = readShortcut(path)
		if fs.exists(shortcutLink) then
			launchIcon(shortcutLink)
		else
			ecs.error("Ярлык ссылается на несуществующий файл.")
		end
	end
end


------------------------------------------------------------------------------------------------------------------------

drawAll()

------------------------------------------------------------------------------------------------------------------------

while true do
	local eventData = { event.pull() }
	if eventData[1] == "touch" then

		--ПРОСЧЕТ КЛИКА НА ИКОНОЧКИ РАБОЧЕГО СТОЛА
		for key, value in pairs(obj["DesktopIcons"]) do
			if ecs.clickedAtArea(eventData[3], eventData[4], obj["DesktopIcons"][key][1], obj["DesktopIcons"][key][2], obj["DesktopIcons"][key][3], obj["DesktopIcons"][key][4]) then
				
				--ЕСЛИ ЛЕВАЯ КНОПА МЫШИ
				if (eventData[5] == 0 and not keyboard.isControlDown()) or (eventData[5] == 1 and keyboard.isControlDown()) then
					
					--ЕСЛИ НЕ ВЫБРАНА, ТО ВЫБРАТЬ СНАЧАЛА
					if not obj["DesktopIcons"][key][6] then
						selectIcon(key)
					
					--А ЕСЛИ ВЫБРАНА УЖЕ, ТО ЗАПУСТИТЬ ПРОЖКУ ИЛИ ОТКРЫТЬ ПАПКУ
					else
						if fs.isDirectory(obj["DesktopIcons"][key][5]) and ecs.getFileFormat(obj["DesktopIcons"][key][5]) ~= ".app" then
							table.insert(workPathHistory, workPath)							
							workPath = obj["DesktopIcons"][key][5]
							drawDesktop(xPosOfIcons, yPosOfIcons)
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
						action = context.menu(eventData[3], eventData[4], {"Вырезать", false, "^X"}, {"Копировать", false, "^C"}, {"Вставить", not clipboard, "^V"}, "-", {"Добавить в архив"}, "-", {"Удалить", false, "⌫"})
					elseif fileFormat == ".app" and fs.isDirectory(obj["DesktopIcons"][key][5]) then
						action = context.menu(eventData[3], eventData[4], {"Показать содержимое"}, "-", {"Вырезать", false, "^X"}, {"Копировать", false, "^C"}, {"Вставить", not clipboard, "^V"}, "-", {"Переименовать"}, {"Создать ярлык"}, {"Добавить в архив"}, "-", {"Удалить", false, "⌫"})
					elseif fileFormat ~= ".app" and fs.isDirectory(obj["DesktopIcons"][key][5]) then
						action = context.menu(eventData[3], eventData[4], {"Вырезать", false, "^X"}, {"Копировать", false, "^C"}, {"Вставить", not clipboard, "^V"}, "-", {"Переименовать"}, {"Создать ярлык"}, {"Добавить в архив"}, "-", {"Удалить", false, "⌫"})
					else
						action = context.menu(eventData[3], eventData[4], {"Редактировать"}, "-", {"Вырезать", false, "^X"}, {"Копировать", false, "^C"}, {"Вставить", not clipboard, "^V"}, "-", {"Переименовать"}, {"Создать ярлык"}, {"Добавить в архив"}, "-", {"Удалить", false, "⌫"})
					end

					--ecs.error(#getSelectedIcons())
					deselectAll()
					--ecs.error(#getSelectedIcons())

					if action == "Показать содержимое" then
						table.insert(workPathHistory, workPath)	
						workPath = obj["DesktopIcons"][key][5]
						drawDesktop(xPosOfIcons, yPosOfIcons)
					elseif action == "Редактировать" then
						ecs.prepareToExit()
						shell.execute("edit "..obj["DesktopIcons"][key][5])
						drawAll()
					elseif action == "Удалить" then
						fs.remove(workPath .. "/" .. obj["DesktopIcons"][key][5])
						drawDesktop(xPosOfIcons, yPosOfIcons)
					elseif action == "Копировать" then
						clipboard = workPath .. "/" .. obj["DesktopIcons"][key][5]
					elseif action == "Вставить" then
						ecs.copy(clipboard, workPath)
						drawDesktop(xPosOfIcons, yPosOfIcons)
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
			end
		end

		for key, val in pairs(obj["TopBarButtons"]) do
			if ecs.clickedAtArea(eventData[3], eventData[4], obj["TopBarButtons"][key][1], obj["TopBarButtons"][key][2], obj["TopBarButtons"][key][3], obj["TopBarButtons"][key][4]) then
				ecs.colorTextWithBack(obj["TopBarButtons"][key][1], obj["TopBarButtons"][key][2], 0xffffff, ecs.colors.blue, " "..key.." ")

				if key == "Вид" then

					local action = context.menu(obj["TopBarButtons"][key][1], obj["TopBarButtons"][key][2] + 1, {(function() if showHiddenFiles then return "Скрывать скрытые файлы" else return "Показывать скрытые файлы" end end)()}, {(function() if showSystemFiles then return "Скрывать системные файлы" else return "Показывать системные файлы" end end)()}, "-", {(function() if showFileFormat then return "Скрывать формат файлов" else return "Показывать формат файлов" end end)()})
					
					if action == "Скрывать скрытые файлы" then
						showHiddenFiles = false
					elseif action == "Показывать скрытые файлы" then
						showHiddenFiles = true
					elseif action == "Показывать системные файлы" then
						showSystemFiles = true
					elseif action == "Скрывать системные файлы" then
						showSystemFiles = false
					elseif action == "Показывать формат файлов" then
						showFileFormat = true
					elseif action == "Скрывать формат файлов" then
						showFileFormat = false
					end

					drawTopBar()
					drawDesktop(xPosOfIcons, yPosOfIcons)

				elseif key == "MineOS" then
					local action = context.menu(obj["TopBarButtons"][key][1], obj["TopBarButtons"][key][2] + 1, {"Обновления"}, "-", {"Перезагрузить"}, {"Выключить"}, "-", {"Вернуться в Shell"})
				
					if action == "Вернуться в Shell" then
						ecs.prepareToExit()
						return 0
					elseif action == "Выключить" then
						shell.execute("shutdown")
					elseif action == "Перезагрузить" then
						shell.execute("reboot")
					elseif
						action == "Обновления" then
						shell.execute("pastebin run 0nm5b1ju")
						ecs.prepareToExit()
						return 0
					end
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

	elseif eventData[1] == "key_down" then

	end
end















