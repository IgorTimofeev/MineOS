
-- Адаптивная загрузка необходимых библиотек и компонентов
local libraries = {
	["component"] = "component",
	["event"] = "event",
	["fs"] = "filesystem",
	["context"] = "context",
	["unicode"] = "unicode",
	["buffer"] = "doubleBuffering",
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
	closes = {cross = 0xCC4C4C, hide = 0xDEDE6C, full = 0x57A64E},
	topText = 0x262626,
	topButtons = 0xffffff,
	topButtonsText = 0x262626,
	leftBarHeader = 0x262626,
	leftBarList = 0x666666,
	selection = 0x555555,
}

local leftBar
local pathToConfig = "System/Finder/Config.cfg"

local lang = {}

local workPathHistory = {}
local currentWorkPathHistoryElement = 1

local x, y, width, height, yEnd, xEnd, heightOfTopBar, widthOfLeftBar, heightOfLeftBar, yLeftBar, widthOfMain, xMain
local widthOfBottom, widthOfIcon, heightOfIcon, xSpaceBetweenIcons, ySpaceBetweenIcons, xCountOfIcons, yCountOfIcons
local fileList, fromLine, fromLineLeftBar = nil, 1, 1
local showSystemFiles, showHiddenFiles, showFileFormat

------------------------------------------------------------------------------------------------------------------

--Сохраняем все настроечки вот тут вот
local function saveConfig()
	fs.makeDirectory(fs.path(pathToConfig))
	local file = io.open(pathToConfig, "w")
	file:write(serialization.serialize( { ["leftBar"] = leftBar, ["showHiddenFiles"] = showHiddenFiles, ["showSystemFiles"] = showSystemFiles, ["showFileFormat"] = showFileFormat }))
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
	else
		leftBar = {
			{"Title", "Избранное"},
			{"Element", "Root", ""},
			{"Element", "Desktop", "System/OS/Desktop/"},
			{"Element", "Libraries", "lib/"},
			{"Element", "Applications", "bin/"},
			{"Element", "System", "System/"},
			{"Title", "", ""},
			{"Title", "Диски"},
		}
		showFileFormat = false
		showSystemFiles = false
		showHiddenFiles = false
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
	fileList = ecs.reorganizeFilesAndFolders(fileList, showHiddenFiles, showSystemFiles)
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
	local symbol = "⮾"
	gpu.setBackground(colors.topBar)
	local yPos = y
	ecs.colorText(x + 1, yPos , colors.closes.cross, symbol)
	ecs.colorText(x + 3, yPos , colors.closes.hide, symbol)
	ecs.colorText(x + 5, yPos , colors.closes.full, symbol)
	newObj("Closes", 1, x + 1, yPos, x + 1, yPos)
	newObj("Closes", 2, x + 3, yPos, x + 3, yPos)
	newObj("Closes", 3, x + 5, yPos, x + 5, yPos)
end

--Рисуем строку поиска
local function drawSearch()
	local limit = width * 1 / 4
	ecs.inputText(x + width - limit - 1, y + 1, limit, " Поиск", colors.topButtons, 0x999999, true)
end

local function drawFsControl()
	obj["FSButtons"] = {}
	local xPos, yPos = xMain, y + 1
	local name

	local function getColors(cyka)
		if cyka then return 0x262626, 0xffffff else return 0xffffff, 0x262626 end
	end

	name = "Формат"; newObj("FSButtons", 1, ecs.drawAdaptiveButton(xPos, yPos, 1, 0, name, getColors(showFileFormat))); xPos = xPos + unicode.len(name) + 3
	name = "Скрытые"; newObj("FSButtons", 2, ecs.drawAdaptiveButton(xPos, yPos, 1, 0, name, getColors(showHiddenFiles))); xPos = xPos + unicode.len(name) + 3
	name = "Системные"; newObj("FSButtons", 3, ecs.drawAdaptiveButton(xPos, yPos, 1, 0, name, getColors(showSystemFiles))); xPos = xPos + unicode.len(name) + 3
end

--Рисуем верхнюю часть
local function drawTopBar()
	--Рисуем сам бар
	ecs.square(x, y, width, heightOfTopBar, colors.topBar)
	--Рисуем кнопочки
	drawCloses()
	--Рисуем титл
	-- local text = workPathHistory[currentWorkPathHistoryElement] or "Root"
	-- ecs.colorText(x + math.floor(width / 2 - unicode.len(text) / 2), y, colors.topText, text)
	--Рисуем кнопочки влево-вправо
	local xPos, yPos = x + 1, y + 1
	name = "<"; newObj("TopButtons", name, ecs.drawButton(xPos, yPos, 3, 1, name, colors.topButtons, colors.topButtonsText))
	xPos = xPos + 4
	name = ">"; newObj("TopButtons", name, ecs.drawButton(xPos, yPos, 3, 1, name, colors.topButtons, colors.topButtonsText))
	--Поиск рисуем
	--drawSearch()
	--Кнопочки контроля файловой системы рисуем
	drawFsControl()
end

--Рисуем нижнюю полосочку с путем
local function drawBottomBar()
	--Подложка
	ecs.square(xMain, yEnd, widthOfBottom, 1, colors.leftBar)
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
	ecs.colorText(xMain + 1, yEnd, colors.topText, ecs.stringLimit("start", historyString, widthOfMain - 2))
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
	ecs.srollBar(xEnd, yLeftBar, 1, heightOfMain, scrollHeight, fromLine, colors.topBar, ecs.colors.blue)
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
	buffer.draw()
end

--Рисуем левую часть
local function drawLeftBar()
	obj["Favorites"] = {}
	--Рисуем подложку лефтбара
	ecs.srollBar(x + widthOfLeftBar - 1, yLeftBar, 1, heightOfLeftBar, #leftBar, fromLineLeftBar, colors.topBar, ecs.colors.blue)
	ecs.square(x, yLeftBar, widthOfLeftBar - 1, heightOfLeftBar, colors.leftBar)
	--Коорды
	local xPos, yPos, limit = x + 1, yLeftBar, widthOfLeftBar - 3

	--Перебираем массив лефтбара
	for i = fromLineLeftBar, (heightOfLeftBar + fromLineLeftBar - 1) do
		--Если в лефтбаре такой вообще существует вещ
		if leftBar[i] then
			--Рисуем заголовок
			if leftBar[i][1] == "Title" then
				ecs.colorText(xPos, yPos, colors.leftBarHeader, leftBar[i][2])
			else
				--Делаем сразу строку
				local text = ecs.stringLimit("end", leftBar[i][2], limit)
				--Если текущий путь сопадает с путем фаворитса
				if leftBar[i][3] == workPathHistory[currentWorkPathHistoryElement] then
					ecs.square(x, yPos, widthOfLeftBar - 1, 1, colors.leftBarSelection)
					ecs.colorText(xPos + 1, yPos, 0xffffff, text )
					gpu.setBackground(colors.leftBar)
				else
					ecs.colorText(xPos + 1, yPos,  colors.leftBarList,text )
				end

				newObj("Favorites", i, x, yPos, x + widthOfLeftBar - 1, yPos, leftBar[i][3])
				
			end

			yPos = yPos + 1
		end
	end
end

--Рисуем вообще все
local function drawAll()
	drawTopBar()
	drawBottomBar()
	drawLeftBar()
	drawMain(fromLine)
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
		drawMain(fromLine)
		drawBottomBar()
		drawLeftBar()
	end
	--Кнопы перерисовываем, ды!
	drawTopBar()
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
		drawMain(fromLine)
		drawBottomBar()
		drawLeftBar()
	end
	--Кнопы перерисовываем, ды!
	drawTopBar()
end

--Добавить что-то в избранное
local function addToFavourites(name, path)
	table.insert(leftBar, 2, {"Element", name, path})
end

--Главная функция
local function drawManager(xStart, yStart, widthOfManager, heightOfManager, startPath)
	--Загружаем конфигурационный файл
	loadConfig()
	--Создаем дисковую парашу там вон
	chkdsk()
	--Задаем стартовые размеры
	width = widthOfManager
	height = heightOfManager
	--Задаем стартовый путь
	changePath(startPath)
	--Даем возможность авторасчета координат
	xStart, yStart = ecs.correctStartCoords(xStart, yStart, width, height)
	x, y = xStart, yStart
	--Пересчитываем все размеры
	calculateSizes()
	--Запоминаем старые пиксели, чтобы потом можно было отрисовать предыдущий интерфейс
	local oldPixelsOfMini = ecs.rememberOldPixels(x, y, x + width - 1, y + height - 1)
	local oldPixelsOfFullScreen = ecs.rememberOldPixels(1, 1, gpu.getResolution())
	local isFullScreen = false
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
						else
							ecs.launchIcon(path)
							if not isFullScreen then ecs.drawOldPixels(oldPixelsOfFullScreen) end
						end
						drawAll()
					--А если правая
					else
						if fs.isDirectory(path) then
							if fileFormat ~= ".app" then
								action = context.menu(e[3], e[4], {"Добавить в избранное"},"-", {"Копировать", false, "^C"}, {"Вставить", (_G.clipboard == nil), "^V"}, "-", {"Переименовать"}, {"Создать ярлык"}, "-", {"Добавить в архив"}, "-", {"Удалить", false, "⌫"})
							else
								action = context.menu(e[3], e[4], {"Показать содержимое"}, {"Добавить в избранное"},"-", {"Копировать", false, "^C"}, {"Вставить", (_G.clipboard == nil), "^V"}, "-", {"Переименовать"}, {"Создать ярлык"}, "-", {"Добавить в архив"}, "-", {"Удалить", false, "⌫"})
							end
						else
							action = context.menu(e[3], e[4], {"Редактировать"}, "-", {"Копировать", false, "^C"}, {"Вставить", (not _G.clipboard), "^V"}, "-", {"Переименовать"}, {"Создать ярлык"}, "-", {"Добавить в архив"}, {"Загрузить на Pastebin"}, "-", {"Удалить", false, "⌫"})
						end

						--АналИз действия
						if action == "Редактировать" then
							ecs.prepareToExit()
							shell.execute("edit "..path)
							ecs.drawOldPixels(oldPixelsOfFullScreen)
							drawAll()
						elseif action == "Добавить в избранное" then
							addToFavourites(fs.name(path), path)
							drawLeftBar()
							drawMain(fromLine)
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
							zip.archive(path, ecs.hideFileFormat(fs.name(path))..".zip")
							getFileList(workPathHistory[currentWorkPathHistoryElement])
							drawAll()
						elseif action == "Загрузить на Pastebin" then
							shell.execute("Pastebin.app/Pastebin.lua upload " .. path)
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
					ecs.drawOldPixels(oldPixelsOfFullScreen)
					drawAll()
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
					ecs.drawButton(obj["TopButtons"][key][1], obj["TopButtons"][key][2], 3, 1, key, colors.topButtonsText, colors.topButtons)
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
					--Левая кнопка мыши
					if e[5] == 0 then
						changePath(obj["Favorites"][key][5])
						drawAll()
					else
						local action = context.menu(e[3], e[4], {"Показать содержащую папку"}, "-",{"Удалить из избранного"})
						if action == "Удалить из избранного" then
							table.remove(leftBar, key)
							drawLeftBar()
						else
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
						os.sleep(0.2)
						saveConfig()
						if isFullScreen then
							ecs.drawOldPixels(oldPixelsOfFullScreen)
						else
							ecs.drawOldPixels(oldPixelsOfMini)
						end
						return

					--Пока ниче не делать
					elseif key == 2 and isFullScreen then
						ecs.colorTextWithBack(obj["Closes"][key][1], obj["Closes"][key][2], ecs.colors.blue, colors.topBar, "⮾")
						os.sleep(0.2)
						x, y, width, height = xStart, yStart, widthOfManager, heightOfManager
						--Пересчитываем все размеры
						calculateSizes()
						--Рисуем старые пиксельсы из фулл скрина
						ecs.drawOldPixels(oldPixelsOfFullScreen)
						--Рисуем окно заново
						drawAll()
						isFullScreen = false
					--Масштаб
					elseif key == 3 and not isFullScreen then
						ecs.colorTextWithBack(obj["Closes"][key][1], obj["Closes"][key][2], ecs.colors.blue, colors.topBar, "⮾")
						os.sleep(0.2)
						--Задаем новые координаты окна
						x = 1
						y = 1
						width, height = gpu.getResolution()
						--Пересчитываем все размеры
						calculateSizes()
						--Рисуем окно заново
						drawAll()
						isFullScreen = true
					end

					break
				end
			end

			for key in pairs(obj["FSButtons"]) do
				if ecs.clickedAtArea(e[3], e[4], obj["FSButtons"][key][1], obj["FSButtons"][key][2], obj["FSButtons"][key][3], obj["FSButtons"][key][4]) then
					if key == 1 then
						showFileFormat = not showFileFormat
					elseif key == 2 then
						showHiddenFiles = not showHiddenFiles
					else
						showSystemFiles = not showSystemFiles
					end
					fromLine = 1
					getFileList(workPathHistory[currentWorkPathHistoryElement])
					drawAll()

					break
				end
			end

		elseif e[1] == "component_added" and e[3] == "filesystem" then
			chkdsk()
			drawLeftBar()
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
					end
				else
					if fromLine < (math.ceil(#fileList / xCountOfIcons)) then
						fromLine = fromLine + 1 
						drawMain(fromLine)
					end
				end

			--А если в зоне лефтбара
			elseif ecs.clickedAtArea(e[3], e[4], x, yLeftBar, x + widthOfLeftBar - 1, yEnd) then
				if e[5] == 1 then
					if fromLineLeftBar > 1 then
						fromLineLeftBar = fromLineLeftBar - 1 
						drawLeftBar()
					end
				else
					if fromLineLeftBar < #leftBar then
						fromLineLeftBar = fromLineLeftBar  + 1 
						drawLeftBar()
					end
				end
			end
		end
	end
end

------------------------------------------------------------------------------------------------------------------

local args = {...}
drawManager("auto", "auto", 84, 28, args[1] or "")





