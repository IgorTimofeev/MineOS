
-- Адаптивная загрузка необходимых библиотек и компонентов
local libraries = {
	["component"] = "component",
	["computer"] = "computer",
	["event"] = "event",
	["fs"] = "filesystem",
	["context"] = "context",
	["unicode"] = "unicode",
	["buffer"] = "doubleBuffering",
	["archive"] = "archive",
	["serialization"] = "serialization",
}

local components = {
	["gpu"] = "gpu",
}

for library in pairs(libraries) do if not _G[library] then _G[library] = require(libraries[library]) end end
for comp in pairs(components) do if not _G[comp] then _G[comp] = _G.component[components[comp]] end end
libraries, components = nil, nil

------------------------------------------------------------------------------------------------------------------

local colors = {
	topBar = 0xdddddd,
	main = 0xffffff,
	leftBar = 0xeeeeee,
	leftBarSelection = ecs.colors.blue,
	closes = {cross = ecs.colors.red, hide = ecs.colors.orange, full = ecs.colors.green},
	topText = 0x262626,
	topButtons = 0xffffff,
	topButtonsText = 0x262626,
	leftBarHeader = 0x000000,
	leftBarList = 0x444444,
	selection = 0x555555,
}

local leftBar
local pathToConfig = "MineOS/System/Finder/Config.cfg"

local lang = {}

local workPathHistory = {}
local currentWorkPathHistoryElement = 1

local x, y, width, height, yEnd, xEnd, heightOfTopBar, widthOfLeftBar, heightOfLeftBar, yLeftBar, widthOfMain, xMain
local widthOfBottom, widthOfIcon, heightOfIcon, xSpaceBetweenIcons, ySpaceBetweenIcons, xCountOfIcons, yCountOfIcons
local fileList, fromLine, fromLineLeftBar = nil, 1, 1
local showSystemFiles, showHiddenFiles, showFileFormat
local oldPixelsOfMini, oldPixelsOfFullScreen
local isFullScreen
local sortingMethods = {
	{name = "type", symbol = "По типу"},
	{name = "name", symbol = "По имени"},
	{name = "date", symbol = "По дате"},
}
local currentSortingMethod = 1

------------------------------------------------------------------------------------------------------------------

--Сохраняем все настроечки вот тут вот
local function saveConfig()
	fs.makeDirectory(fs.path(pathToConfig))
	local file = io.open(pathToConfig, "w")
	file:write(serialization.serialize( { ["leftBar"] = leftBar, ["showHiddenFiles"] = showHiddenFiles, ["showSystemFiles"] = showSystemFiles, ["showFileFormat"] = showFileFormat, ["currentSortingMethod"] = currentSortingMethod }))
	file:close()
end

--Загрузка конфига
local function loadConfig()
	if fs.exists(pathToConfig) then
		local file = io.open(pathToConfig, "r")
		local readedConfig = file:read("*a")
		file:close()
		readedConfig = serialization.unserialize(readedConfig)
		leftBar = readedConfig.leftBar
		showFileFormat = readedConfig.showFileFormat
		showSystemFiles = readedConfig.showSystemFiles
		showHiddenFiles = readedConfig.showHiddenFiles
		currentSortingMethod = readedConfig.currentSortingMethod
	else
		leftBar = {
			{"Title", "Избранное"},
			{"Element", "Root", ""},
			{"Element", "System", "MineOS/System/"},
			{"Element", "Libraries", "lib/"},
			{"Element", "Scripts", "bin/"},
			{"Element", "Desktop", "MineOS/Desktop/"},
			{"Element", "Applications", "MineOS/Applications/"},
			{"Element", "Pictures", "MineOS/Pictures/"},
			{"Title", "", ""},
			{"Title", "Диски"},
		}
		showFileFormat = false
		showSystemFiles = false
		showHiddenFiles = false
		currentSortingMethod = 1
		saveConfig()
	end
end

--СОЗДАНИЕ ОБЪЕКТОВ
local obj = {}
local function newObj(class, name, ...)
	obj[class] = obj[class] or {}
	obj[class][name] = {...}
end

--Создание дисков для лефтбара
local function createDisks()
	local HDDs = ecs.getHDDs()

	for proxy, path in fs.mounts() do
		for i = 1, #HDDs do
			if proxy.address == HDDs[i].address and path ~= "/" then
				table.insert(leftBar, {"Element", fs.name(path), unicode.sub(path, 2, -1)})
				--ecs.error("path = "..path)
			end
		end
	end
end

--Короч такая хуйня, смари. Сначала оно удаляет все диски
--А затем их создает заново
local function chkdsk()
	local position = #leftBar
	while true do
		if leftBar[position][1] == "Title" then break end
		--Анализ
		table.remove(leftBar, position)
		--Постанализ
		position = position - 1
	end

	fromLineLeftBar = 1
	createDisks()
end

--Получить файловый список
local function getFileList(path)
	fileList = ecs.getFileList(path)
	fileList = ecs.sortFiles(path, fileList, sortingMethods[currentSortingMethod].name, showHiddenFiles)
end

--Перейти в какую-то папку
local function changePath(path)
	--Очищаем все элементы, следующие за текущим
	for i = currentWorkPathHistoryElement, #workPathHistory do
		table.remove(workPathHistory, currentWorkPathHistoryElement + 1)
	end
	--Вставляем новый элементик нового пути
	table.insert(workPathHistory, path)	
	--На всякий
	fromLine = 1
	--Текущий элемент равен последнему
	currentWorkPathHistoryElement = #workPathHistory
	--Получаем список файлов текущей директории
	getFileList(workPathHistory[currentWorkPathHistoryElement])
end

--Считаем размеры всего
local function calculateSizes()
	heightOfTopBar = 3
	widthOfLeftBar = 16
	heightOfLeftBar = height - heightOfTopBar
	heightOfMain = heightOfLeftBar - 1
	yLeftBar = y + heightOfTopBar
	widthOfMain = width - widthOfLeftBar - 1
	widthOfBottom = width - widthOfLeftBar
	xMain = x + widthOfLeftBar
	yEnd = y + height - 1
	xEnd = x + width - 1
	widthOfIcon = 12
	heightOfIcon = 6
	xSpaceBetweenIcons = 1
	ySpaceBetweenIcons = 1
	xCountOfIcons = math.floor(widthOfMain / (widthOfIcon + xSpaceBetweenIcons))
	yCountOfIcons = math.floor(heightOfLeftBar / (heightOfIcon + ySpaceBetweenIcons))
	maxCountOfIcons = xCountOfIcons * yCountOfIcons
end

--Рисем цветные кружочки слева вверху
local function drawCloses()
	local symbol = "⬤"
	buffer.set(x + 1, y, colors.topBar, colors.closes.cross, symbol)
	buffer.set(x + 3, y, colors.topBar, colors.closes.hide, symbol)
	buffer.set(x + 5, y, colors.topBar, colors.closes.full, symbol)
	newObj("Closes", 1, x + 1, y, x + 2, y)
	newObj("Closes", 2, x + 3, y, x + 4, y)
	newObj("Closes", 3, x + 5, y, x + 6, y)
end

--Рисуем строку поиска
local function drawSearch()
	local limit = width * 1 / 4
	ecs.inputText(x + width - limit - 1, y + 1, limit, " Поиск", colors.topButtons, 0x999999, true)
end

local function drawFsControl()
	obj["FSButtons"] = {}
	local xPos, yPos = xMain, y + 1
	local name, fg, bg

	local function getColors(cyka)
		if cyka then return 0x262626, 0xffffff else return 0xffffff, 0x262626 end
	end

	for i = 1, #sortingMethods do
		name = sortingMethods[i].symbol; bg, fg = getColors(currentSortingMethod == i); newObj("FSButtons", i, buffer.button(xPos, yPos, unicode.len(name) + 2, 1, bg, fg, name)); xPos = xPos + unicode.len(name) + 3
	end
	--xPos = xPos + 4
	name = "Формат"; bg, fg = getColors(showFileFormat); newObj("FSButtons",  #sortingMethods + 1, buffer.button(xPos, yPos, unicode.len(name) + 2, 1, bg, fg, name)); xPos = xPos + unicode.len(name) + 3	
	name = "Скрытые"; bg, fg = getColors(showHiddenFiles); newObj("FSButtons",  #sortingMethods + 2, buffer.button(xPos, yPos, unicode.len(name) + 2, 1, bg, fg, name)); xPos = xPos + unicode.len(name) + 3

	-- name = "Формат"; newObj("FSButtons", 1, buffer.adaptiveButton(xPos, yPos, 1, 0, getColors(showFileFormat), name)); xPos = xPos + unicode.len(name) + 3
	-- name = "Скрытые"; newObj("FSButtons", 2, buffer.adaptiveButton(xPos, yPos, 1, 0, getColors(showHiddenFiles), name)); xPos = xPos + unicode.len(name) + 3
	-- name = "Системные"; newObj("FSButtons", 3, buffer.adaptiveButton(xPos, yPos, 1, 0, getColors(showSystemFiles), name)); xPos = xPos + unicode.len(name) + 3
end

--Рисуем верхнюю часть
local function drawTopBar()
	--Рисуем сам бар
	buffer.square(x, y, width, heightOfTopBar, colors.topBar, 0xffffff, " ")
	--Рисуем кнопочки
	drawCloses()
	--Рисуем титл
	-- local text = workPathHistory[currentWorkPathHistoryElement] or "Root"
	-- ecs.colorText(x + math.floor(width / 2 - unicode.len(text) / 2), y, colors.topText, text)
	--Рисуем кнопочки влево-вправо
	local xPos, yPos = x + 1, y + 1
	name = "<"; newObj("TopButtons", name, buffer.button(xPos, yPos, 3, 1, colors.topButtons, colors.topButtonsText, name))
	xPos = xPos + 4
	name = ">"; newObj("TopButtons", name, buffer.button(xPos, yPos, 3, 1, colors.topButtons, colors.topButtonsText, name))
	--Поиск рисуем
	--drawSearch()
	--Кнопочки контроля файловой системы рисуем
	drawFsControl()
end

--Рисуем нижнюю полосочку с путем
local function drawBottomBar()
	--Подложка
	buffer.square(xMain, yEnd, widthOfBottom, 1, colors.leftBar, 0xffffff, " ")
	--Создаем переменную строки истории
	local historyString = workPathHistory[currentWorkPathHistoryElement]
	if historyString == "" or historyString == "/" then
		historyString = "Root"
	else
		historyString = string.gsub(historyString, "/", " ► ")
		if unicode.sub(historyString, -3, -1) == " ► " then
			historyString = "Root ► " .. unicode.sub(historyString, 1, -4)
		end
	end
	--Рисуем ее
	buffer.text(xMain + 1, yEnd, colors.topText, ecs.stringLimit("start", historyString, widthOfMain - 2))
end

--Рисуем зону иконок
local function drawMain(fromLine)
	--С какой линии начинать отрисовку
	fromLine = fromLine or 1
	--Очищаем объекты
	obj["Icons"] = {}
	--Рисуем белую подложку
	buffer.square(xMain, yLeftBar, widthOfMain, heightOfMain, colors.main, 0xffffff, " ")
	--Рисуем скроллбарчик, епты бля!
	local scrollHeight = math.ceil(#fileList / xCountOfIcons); if scrollHeight == 0 then scrollHeight = 1 end
	buffer.scrollBar(xEnd, yLeftBar, 1, heightOfMain, scrollHeight, fromLine, colors.topBar, 0x555555)
	--Позиции отрисовки иконок
	local xPos, yPos = xMain + 1, yLeftBar + 1
	--С какой иконки начинать отрисовку
	local counter = fromLine * xCountOfIcons - xCountOfIcons + 1
	--Перебираем квадрат иконочной зоны
	for j = 1, yCountOfIcons do
		for i = 1, xCountOfIcons do
			--Разрываем цикл, если конец файл листа
			if not fileList[counter] then break end
			--Получаем путь к файлу для иконки
			local path = workPathHistory[currentWorkPathHistoryElement] .. fileList[counter]
			--Рисуем иконку
			ecs.drawOSIcon(xPos, yPos, path, showFileFormat, 0x000000)
			--Создаем объект иконки
			newObj("Icons", counter, xPos, yPos, xPos + widthOfIcon - 1, yPos + heightOfIcon - 1, path)
			--Очищаем оперативку
			path = nil
			--Увеличиваем xPos для след. иконки справа и cчетчик файлов
			xPos = xPos + widthOfIcon + xSpaceBetweenIcons
			counter = counter + 1
		end
		--Сбрасываем xPos на старт и увеличиваем yPos для иконок ниже
		xPos = xMain + 1
		yPos = yPos + heightOfIcon + ySpaceBetweenIcons
	end
end

--Рисуем левую часть
local function drawLeftBar()
	obj["Favorites"] = {}
	--Рисуем подложку лефтбара
	buffer.square(x, yLeftBar, widthOfLeftBar, heightOfLeftBar, 0xffffff, 0xffffff, " ", 30)
	buffer.scrollBar(x + widthOfLeftBar - 1, yLeftBar, 1, heightOfLeftBar, #leftBar, fromLineLeftBar, colors.topBar, 0x555555)
	--Коорды
	local xPos, yPos, limit = x + 1, yLeftBar, widthOfLeftBar - 3

	--Перебираем массив лефтбара
	for i = fromLineLeftBar, (heightOfLeftBar + fromLineLeftBar - 1) do
		--Если в лефтбаре такой вообще существует вещ
		if leftBar[i] then
			--Рисуем заголовок
			if leftBar[i][1] == "Title" then
				buffer.text(xPos, yPos, colors.leftBarHeader, leftBar[i][2])
			else
				--Делаем сразу строку
				local text = ecs.stringLimit("end", leftBar[i][2], limit)
				--Если текущий путь сопадает с путем фаворитса
				if leftBar[i][3] == workPathHistory[currentWorkPathHistoryElement] then
					buffer.square(x, yPos, widthOfLeftBar - 1, 1, colors.leftBarSelection, 0xffffff, " ")
					buffer.text(xPos + 1, yPos, 0xffffff, text)
				else
					buffer.text(xPos + 1, yPos,  colors.leftBarList,text )
				end

				newObj("Favorites", i, x, yPos, x + widthOfLeftBar - 1, yPos, leftBar[i][3])
				
			end

			yPos = yPos + 1
		end
	end
end

local function drawShadows()
	buffer.square(xEnd + 1, y + 1, 2, height, 0x000000, 0xffffff, " ", 60)
	buffer.square(x + 2, yEnd + 1, width - 2, 1, 0x000000, 0xffffff, " ", 60)
end

--Рисуем вообще все
local function drawAll(force)
	if isFullScreen then
		buffer.paste(1, 1, oldPixelsOfFullScreen)
	else
		buffer.paste(x, y, oldPixelsOfMini)
	end
	drawTopBar()
	drawBottomBar()
	drawLeftBar()
	drawMain(fromLine)
	drawShadows()
	buffer.draw(force)
end

--Назад по истории
local function backToPast()
	if currentWorkPathHistoryElement > 1 then
		--Го!
		currentWorkPathHistoryElement = currentWorkPathHistoryElement - 1
		--Получаем список файлов текущей директории
		getFileList(workPathHistory[currentWorkPathHistoryElement])
		--Раб стол перерисовываем, блеа!
		fromLine = 1
	end
	--Кнопы перерисовываем, ды!
	drawAll()
end

--Вперед по истории
local function backToFuture()
	if currentWorkPathHistoryElement < #workPathHistory then
		--Го!
		currentWorkPathHistoryElement = currentWorkPathHistoryElement + 1
		--Получаем список файлов текущей директории
		getFileList(workPathHistory[currentWorkPathHistoryElement])
		--Раб стол перерисовываем, блеа!
		fromLine = 1
	end
	--Кнопы перерисовываем, ды!
	drawAll()
end

--Добавить что-то в избранное
local function addToFavourites(name, path)
	table.insert(leftBar, 2, {"Element", name, path})
end

----------------------------------------------------------------------------------------------------------------------------------

local args = { ... }
-- local cykaImage = image.load("MineOS/Pictures/AhsokaTano.pic")
-- buffer.image(1, 1, cykaImage)

--Загружаем конфигурационный файл
loadConfig()
--Создаем дисковую парашу там вон
chkdsk()
--Задаем стартовые размеры
local startWidth, startHeight = 86, 25
width = startWidth
height = startHeight
--Задаем стартовый путь
changePath(args[1] or "")
--Даем возможность авторасчета координат
local xStart, yStart = ecs.correctStartCoords("auto", "auto", width, height)
x, y = xStart, yStart
--Пересчитываем все размеры
calculateSizes()
--Запоминаем старые пиксели, чтобы потом можно было отрисовать предыдущий интерфейс
oldPixelsOfMini = buffer.copy(x, y, width + 2, height + 1)
oldPixelsOfFullScreen = buffer.copy(1, 1, buffer.screen.width, buffer.screen.height)
isFullScreen = false

--Рисуем вообще все
drawAll()

local clickedOnEmptySpace
while true do
	local e = {event.pull()}
	if e[1] == "touch" then
		--Переменная, становящаяся ложью только в случае клика на какой-либо элемент, не суть какой
		clickedOnEmptySpace = true
		
		--Перебираем иконки
		for key in pairs(obj["Icons"]) do
			if ecs.clickedAtArea(e[3], e[4], obj["Icons"][key][1], obj["Icons"][key][2], obj["Icons"][key][3], obj["Icons"][key][4]) then
				--Рисуем иконку выделенную
				buffer.square(obj["Icons"][key][1], obj["Icons"][key][2], widthOfIcon, heightOfIcon, colors.selection, 0xffffff, " ")
				ecs.drawOSIcon(obj["Icons"][key][1], obj["Icons"][key][2], obj["Icons"][key][5], showFileFormat, 0xffffff)
				buffer.draw()

				--Получаем путь иконки и ее формат
				local path = obj["Icons"][key][5]
				local fileFormat = ecs.getFileFormat(path)
				local action

				--Левая кнопка мыши
				if e[5] == 0 then
					os.sleep(0.2)
					--Думаем, че делать дальше
					if fs.isDirectory(path) and fileFormat ~= ".app" then
						changePath(path)
						drawAll()
					else
						ecs.launchIcon(path)
						drawAll(true)
					end
				--А если правая
				else
					if fs.isDirectory(path) then
						if fileFormat ~= ".app" then
							action = context.menu(e[3], e[4], {"Добавить в избранное"},"-", {"Копировать", false, "^C"},  {"Переименовать"}, {"Создать ярлык"}, "-", {"Добавить в архив"}, "-", {"Удалить", false, "⌫"})
						else
							action = context.menu(e[3], e[4], {"Показать содержимое"}, {"Добавить в избранное"},"-", {"Копировать", false, "^C"}, {"Переименовать"}, {"Создать ярлык"}, "-", {"Добавить в архив"}, "-", {"Удалить", false, "⌫"})
						end
					else
						if fileFormat == ".pic" then
							action = context.menu(e[3], e[4], {"Редактировать"}, {"Установить как обои"}, "-", {"Копировать", false, "^C"}, "-", {"Переименовать"}, {"Создать ярлык"}, "-", {"Загрузить на Pastebin"}, "-", {"Удалить", false, "⌫"})
						elseif fileFormat == ".lua" then
							action = context.menu(e[3], e[4], {"Редактировать"}, {"Создать приложение"}, "-", {"Копировать", false, "^C"}, {"Переименовать"}, {"Создать ярлык"}, "-", {"Загрузить на Pastebin"}, "-", {"Удалить", false, "⌫"})
						else
							action = context.menu(e[3], e[4], {"Редактировать"}, "-", {"Копировать", false, "^C"}, {"Переименовать"}, {"Создать ярлык"}, "-", {"Загрузить на Pastebin"}, "-", {"Удалить", false, "⌫"})
						end
					end

					--АналИз действия
					if action == "Редактировать" then
						ecs.prepareToExit()
						shell.execute("edit "..path)
						buffer.paste(1, 1, oldPixelsOfFullScreen)
						drawAll(true)
					elseif action == "Добавить в избранное" then
						addToFavourites(fs.name(path), path)
						drawAll()
					elseif action == "Показать содержимое" then
						changePath(path)
						drawAll()
					elseif action == "Копировать" then
						_G.clipboard = path
						drawAll()
					elseif action == "Вставить" then
						ecs.copy(_G.clipboard, fs.path(path) or "")
						getFileList(workPathHistory[currentWorkPathHistoryElement])
						drawAll()
					elseif action == "Удалить" then
						fs.remove(path)
						getFileList(workPathHistory[currentWorkPathHistoryElement])
						drawAll()
					elseif action == "Переименовать" then
						ecs.rename(path)
						getFileList(workPathHistory[currentWorkPathHistoryElement])
						drawAll()
					elseif action == "Создать ярлык" then
						ecs.createShortCut(fs.path(path).."/"..ecs.hideFileFormat(fs.name(path))..".lnk", path)
						getFileList(workPathHistory[currentWorkPathHistoryElement])
						drawAll()
					elseif action == "Добавить в архив" then
						ecs.info("auto", "auto", "", "Архивация файлов...")
						archive.pack(ecs.hideFileFormat(fs.name(path))..".pkg", path)
						getFileList(workPathHistory[currentWorkPathHistoryElement])
						drawAll()
					elseif action == "Загрузить на Pastebin" then
						shell.execute("System/Applications/Pastebin.app/Pastebin.lua upload " .. path)
					elseif action == "Установить как обои" then
						--ecs.error(path)
						ecs.createShortCut("MineOS/System/OS/Wallpaper.lnk", path)
						computer.pushSignal("OSWallpaperChanged")
						-- buffer.paste(1, 1, oldPixelsOfFullScreen)
						-- buffer.draw()
						return
					elseif action == "Создать приложение" then
						ecs.newApplicationFromLuaFile(path, workPathHistory[currentWorkPathHistoryElement])
						getFileList(workPathHistory[currentWorkPathHistoryElement])
						drawAll()
					else
						--Рисуем иконку выделенную
						buffer.square(obj["Icons"][key][1], obj["Icons"][key][2], widthOfIcon, heightOfIcon, colors.main, 0xffffff, " ")
						ecs.drawOSIcon(obj["Icons"][key][1], obj["Icons"][key][2], obj["Icons"][key][5], showFileFormat, 0x000000)
						buffer.draw()
					end
				end

				
				--Кликнули не в жопу!
				clickedOnEmptySpace = false
				break
			end
		end

		--ВНИМАНИЕ: ЖОПА!!!!
		--КЛИКНУЛИ В ЖОПУ!!!!!!
		if ecs.clickedAtArea(e[3], e[4], xMain, yLeftBar, xEnd, yEnd - 1) and clickedOnEmptySpace and e[5] == 1 then
			action = context.menu(e[3], e[4], {"Новый файл"}, {"Новая папка"}, {"Новое приложение"}, "-", {"Вставить", (_G.clipboard == nil), "^V"})
			if action == "Новый файл" then
				ecs.newFile(workPathHistory[currentWorkPathHistoryElement])
				getFileList(workPathHistory[currentWorkPathHistoryElement])
				--buffer.paste(1, 1, oldPixelsOfFullScreen)
				drawAll(true)
			elseif action == "Новая папка" then
				ecs.newFolder(workPathHistory[currentWorkPathHistoryElement])
				getFileList(workPathHistory[currentWorkPathHistoryElement])
				drawAll()
			elseif action == "Вставить" then
				ecs.copy(_G.clipboard, workPathHistory[currentWorkPathHistoryElement])
				getFileList(workPathHistory[currentWorkPathHistoryElement])
				drawAll()
			elseif action == "Новое приложение" then
				ecs.newApplication(workPathHistory[currentWorkPathHistoryElement])
				getFileList(workPathHistory[currentWorkPathHistoryElement])
				drawAll()
			end
		end

		--Перебираем всякую шнягу наверху
		for key in pairs(obj["TopButtons"]) do
			if ecs.clickedAtArea(e[3], e[4], obj["TopButtons"][key][1], obj["TopButtons"][key][2], obj["TopButtons"][key][3], obj["TopButtons"][key][4]) then
				buffer.button(obj["TopButtons"][key][1], obj["TopButtons"][key][2], 3, 1, colors.topButtonsText, colors.topButtons, key)
				buffer.draw()
				os.sleep(0.2)
				if key == ">" then
					backToFuture()
				elseif key == "<" then
					backToPast()
				end

				break
			end
		end

		--Фаворитсы слева
		for key in pairs(obj["Favorites"]) do
			if ecs.clickedAtArea(e[3], e[4], obj["Favorites"][key][1], obj["Favorites"][key][2], obj["Favorites"][key][3], obj["Favorites"][key][4]) then
					
				changePath(obj["Favorites"][key][5])
				drawAll()

				--Левая кнопка мыши
				if e[5] == 1 then
					local action = context.menu(e[3], e[4], {"Показать содержащую папку"}, "-",{"Удалить из избранного"})
					if action == "Удалить из избранного" then
						table.remove(leftBar, key)
						drawAll()
					elseif action == "Показать содержащую папку" then
						changePath(fs.path(leftBar[key][3]) or "")
						drawAll()
					end
				end

				break
			end
		end

		--Кнопочки красивые наверху слева круглые кароч вот хыыы
		for key in pairs(obj["Closes"]) do
			if ecs.clickedAtArea(e[3], e[4], obj["Closes"][key][1], obj["Closes"][key][2], obj["Closes"][key][3], obj["Closes"][key][4]) then
				
				--Закрыть прогу
				if key == 1 then
					ecs.colorTextWithBack(obj["Closes"][key][1], obj["Closes"][key][2], ecs.colors.blue, colors.topBar, "⮾")
					
					saveConfig()
					
					-- if isFullScreen then
					-- 	buffer.paste(1, 1, oldPixelsOfFullScreen)
					-- 	buffer.draw()
					-- else
					-- 	buffer.paste(x, y, oldPixelsOfMini)
					-- 	buffer.draw()
					-- end
					return

				--Пока ниче не делать
				elseif key == 2 and isFullScreen then
					ecs.colorTextWithBack(obj["Closes"][key][1], obj["Closes"][key][2], ecs.colors.blue, colors.topBar, "⮾")
					os.sleep(0.2)
					x, y, width, height = xStart, yStart, startWidth, startHeight
					isFullScreen = false
					--Пересчитываем все размеры
					calculateSizes()
					--Рисуем старые пиксельсы из фулл скрина
					buffer.paste(1, 1, oldPixelsOfFullScreen)
					--Рисуем окно заново
					drawAll()
				--Масштаб
				elseif key == 3 and not isFullScreen then
					ecs.colorTextWithBack(obj["Closes"][key][1], obj["Closes"][key][2], ecs.colors.blue, colors.topBar, "⮾")
					os.sleep(0.2)
					--Задаем новые координаты окна
					x = 1
					y = 1
					width, height = gpu.getResolution()
					isFullScreen = true
					--Пересчитываем все размеры
					calculateSizes()
					--Рисуем окно заново
					drawAll()
				end

				break
			end
		end

		for key in pairs(obj["FSButtons"]) do
			if ecs.clickedAtArea(e[3], e[4], obj["FSButtons"][key][1], obj["FSButtons"][key][2], obj["FSButtons"][key][3], obj["FSButtons"][key][4]) then
				if key == 1 then
					currentSortingMethod = 1
				elseif key == 2 then
					currentSortingMethod = 2
				elseif key == 3 then
					currentSortingMethod = 3
				elseif key == 4 then
					showFileFormat = not showFileFormat
				elseif key == 5 then
					showHiddenFiles = not showHiddenFiles
				end
				fromLine = 1
				getFileList(workPathHistory[currentWorkPathHistoryElement])
				drawAll()

				break
			end
		end

	elseif e[1] == "component_added" and e[3] == "filesystem" then
		chkdsk()
		drawAll()
	elseif e[1] == "component_removed" and e[3] == "filesystem" then
		chkdsk()
		changePath("")
		drawAll()

	elseif e[1] == "scroll" then
		--Если скроллим в зоне иконок
		if ecs.clickedAtArea(e[3], e[4], xMain, yLeftBar, xEnd, yEnd - 1) then
			if e[5] == 1 then
				if fromLine > 1 then
					fromLine = fromLine - 1 
					drawMain(fromLine)
					buffer.draw()
				end
			else
				if fromLine < (math.ceil(#fileList / xCountOfIcons)) then
					fromLine = fromLine + 1 
					drawMain(fromLine)
					buffer.draw()
				end
			end

		--А если в зоне лефтбара
		elseif ecs.clickedAtArea(e[3], e[4], x, yLeftBar, x + widthOfLeftBar - 1, yEnd) then
			if e[5] == 1 then
				if fromLineLeftBar > 1 then
					fromLineLeftBar = fromLineLeftBar - 1 
					drawAll()
				end
			else
				if fromLineLeftBar < #leftBar then
					fromLineLeftBar = fromLineLeftBar  + 1 
					drawAll()
				end
			end
		end
	end
end


