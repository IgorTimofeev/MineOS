--local component = require("component")
local event = require("event")
local term = require("term")
local unicode = require("unicode")
--local ecs = require("ECSAPI")
--local fs = require("filesystem")
local context = require("context")
--local colorlib = require("colorlib")
--local palette = require("palette")
local computer = require("computer")
local seri = require("serialization")
local keyboard = require("keyboard")
local shell = require("shell")
local config = require("config")
local lang = config.readAll("MineCode.app/Resources/".._OSLANGUAGE..".lang")

local gpu = component.gpu

-------------------------------------ПЕРЕМЕННЫЕ------------------------------------------------------


local args = {...}

local xSize, ySize = gpu.getResolution()

local projectPath = "/test.lua"
local leftToolbarPath = projectPath

local strings = {}

--local topButtons = {"Файл", "Правка", "Поиск", "Вид", "Переход"}
local topButtons = {lang.topMenuFile, lang.topMenuEdit, lang.topMenuFind, lang.topMenuView, lang.topMenuGoto}

local toolbarsToShow = {top = true, left = true, bottom = true}

local stringToDisplayFrom = 1
local symbolToDisplayFrom = 1
--
local yStartOfTopBar = 2
local heightOfTopBar = 3
--
local yStartOfText = yStartOfTopBar + heightOfTopBar
local xStartOfText = 0
local textWidth = 0
local textHeight = ySize - 1 - heightOfTopBar - 1
--
local lineNumbersHeight = ySize - yStartOfText 
local lineNumbersWidth = 0
local xStartOfLineNumbers = 1
--
local infoPanelWidth = math.floor(xSize / 3)
local xInfoPanel = math.floor(xSize / 2 - infoPanelWidth / 2)
--
local leftBarWidth = 17
local leftBarLimit = ySize - yStartOfText - 3
local leftBarHeight = leftBarLimit + 2
--
local indentationWidth = 2
--
local scaleMultiplier = math.ceil(xSize / gpu.maxResolution() * 100)
local oldScale = scaleMultiplier / 100
--
local leftToolbarFileList = {}
local drawFilesOnLeftToolBarFrom = 1
local drawFilesOnLeftToolBarTo = 0
local leftToolbarHeight = ySize - heightOfTopBar - 1
--
local xCursorPos, yCursorPos = 1, 1
local canCursorBeBlinked = true
--
local useAnimations = true
--
local bottomToolbarHeight = 3
local yStartOfBottomToolbar = ySize - bottomToolbarHeight + 1
local xStartOfBottomToolbar = xStartOfLineNumbers 
local bottomToolbarWidth = 0


-------------------------------------------------------------

local topBarColor = 0xcccccc
local topBarButtonColor = 0xbbbbbb
local topBarButtonPressedColor = 0x3d3d3d
local topBarButtonTextColor = 0x3d3d3d
local topBarButtonPressedTextColor = 0xffffff
local topMenuColor = 0xeeeeee
local topMenuTextColor = 0x444444
local lineNumbersColor = 0x3d3d3d
local lineNumbersTextColor = 0xcccccc
local textAreaColor = 0x262626
local textAreaTextColor = 0xffffff
local scrollBarColor = 0x222222
local scrollBarActiveColor = ecs.colors.lightBlue
local shadowColor = 0x1d1d1d
local infoPanelColor = 0xe8e8e8
local infoPanelTextColor = 0x444444
local usualTextColor = 0xffffff
local backSelectionColor = 0xaaaaff
local textSelectionColor = 0xffffff
local backHighlightColor = 0xff9200
local textHighlightColor = 0xffffff
local textCommentColor = 0x339933
local indentationColor = 0x3d3d3d
local leftToolbarColor = 0xdddddd
local leftToolbarFileColor = 0x3d3d3d
local leftToolbarFolderColor = 0x00aa00
local leftToolbarFieldColor = 0x000000------------------
local errorColor = 0xcc0000
local errorTextColor = 0xffffff
local successColor = 0x55ff55
local successTextColor = 0xffffff
local bottomToolbarColor = 0x555555
local bottomToolbarButtonColor = 0x383838
local bottomToolbarTextColor = 0xffffff

--------------------------------------ФУНКЦИИ------------------------------------------------------

local obj = {}
local function newObj(class, name, ...)
	obj[class] = obj[class] or {}
	obj[class][name] = {...}
end

local function convertCoordsToCursorPoses(x, y, reverse)
	if reverse then
		--FALSE
		return (x + xStartOfText - 1), (y + yStartOfText - 1)
	else
		--TRUE
		return (x - xStartOfText + 1), (y - yStartOfText + 1)
	end
end

local function setCursor(blink)
	term.setCursorBlink(false)
	local x, y = convertCoordsToCursorPoses(xCursorPos, yCursorPos, true)
	local pixel = {gpu.get(x, y)}
	gpu.setBackground(pixel[3])
	gpu.setForeground(textAreaTextColor)
	term.setCursor(x, y)
	term.setCursorBlink(canCursorBeBlinked or blink or false)
end

local function calculateLineNumbersWidth()
	lineNumbersWidth = #tostring(#strings) + 2
	--ЭТО ШОБ ТЕКСТ НЕ ВЫЛЕЗАЛ В ПИЗДУ КАРОЧ, ВОООТ
	textWidth = xSize - (xStartOfLineNumbers + lineNumbersWidth) - 3
	--А ЭТО КАРОЧ ТОЧКА, ОТКУДОВА ТЕКСТ БУДЕТ РИСОВАТЬСЯ, ВООООТ
	xStartOfText = xStartOfLineNumbers + lineNumbersWidth + 1
end

local function recalculateTo4toNuzhno()

	textHeight = ySize - 2
	bottomToolbarWidth = xSize

	if toolbarsToShow.top then
		yStartOfText = yStartOfTopBar + heightOfTopBar
		textHeight = textHeight - heightOfTopBar
		leftToolbarHeight = ySize - heightOfTopBar - 1
	else
		yStartOfText = 2
		leftToolbarHeight = ySize - 1
	end

	if toolbarsToShow.left then
		xStartOfLineNumbers = leftBarWidth + 1
		bottomToolbarWidth = bottomToolbarWidth - leftBarWidth
	else xStartOfLineNumbers = 1
		xStartOfLineNumbers = 1
	end

	if toolbarsToShow.bottom then
		bottomToolbarHeight = 3
		yStartOfBottomToolbar = ySize - bottomToolbarHeight + 1
		xStartOfBottomToolbar = xStartOfLineNumbers
		textHeight = textHeight - bottomToolbarHeight
	else
		bottomToolbarHeight = 0
	end

	textWidth = xSize - (xStartOfLineNumbers + lineNumbersWidth) - 3
	lineNumbersHeight = ySize - yStartOfText
	infoPanelWidth = math.floor(xSize / 3)
	xInfoPanel = math.floor(xSize / 2 - infoPanelWidth / 2)

	leftBarLimit = ySize - yStartOfText - 1
	leftBarHeight = leftBarLimit + 2

	calculateLineNumbersWidth()

	setCursor(true)

	--ecs.error("xStartOfText="..xStartOfText..", xCursorPos="..xCursorPos)

	newObj("zones", "textArea", xStartOfText, yStartOfText, xStartOfText + textWidth - 1, yStartOfText + textHeight - 1)
	newObj("zones", "leftBar", 1, yStartOfText, leftBarWidth, yStartOfText + leftBarHeight - 1)
	newObj("zones", "topBar", 1, yStartOfTopBar, xSize, yStartOfTopBar + heightOfTopBar - 1)
	newObj("zones", "bottomBar", xStartOfBottomToolbar, yStartOfBottomToolbar, bottomToolbarWidth, bottomToolbarHeight)
end


local function drawTopButtons()
	ecs.square(1,1,xSize,1,topMenuColor)

	local posX = 3
	local spaceBetween = 2
	gpu.setForeground(topMenuTextColor)
	for i=1,#topButtons do
		gpu.set(posX,1,topButtons[i])
		local length = unicode.len(topButtons[i])
		
		posX = posX + length + spaceBetween
	end
end

local function getInfoAboutRAM()
	local free = computer.freeMemory()
	local total = computer.totalMemory()
	local used = total - free
	return math.ceil(used / 1024), math.floor(total / 1024)
end

local function drawInfoPanel(massivSudaPihay, zad, pered)

	local used, total = getInfoAboutRAM()

	local text = massivSudaPihay or {
		[1] = fs.name(projectPath) or lang.infoPanelNewProject,
		[2] = lang.infoPanelString .." "..stringToDisplayFrom .. " "..lang.infoPanelStringOf.." " .. #strings,
		[3] = tostring(used) .. "/" .. tostring(total) .. " KB RAM"
	}
	local backColor = zad or infoPanelColor
	local frontColor = pered or infoPanelTextColor

	----------------------------------------------------------------------

	--КАРОЧ ФОН ВОТ ЭТОЙ БЕЛОЙ ШНЯГИ
	ecs.square(xInfoPanel, yStartOfTopBar, infoPanelWidth, heightOfTopBar, backColor)

	--ОБРЕЗАНИЕ И РИСОВАНИЕ ТЕКСТА
	gpu.setForeground(frontColor)
	for i = 1, #text do
		text[i] = ecs.stringLimit("start", text[i], infoPanelWidth)

		local xPos = xInfoPanel + infoPanelWidth / 2 - unicode.len(text[i]) / 2
		gpu.set(xPos, yStartOfTopBar + i - 1, text[i])
	end
end

local function drawTopToolbar()
	ecs.square(1, yStartOfTopBar, xSize, heightOfTopBar, topBarColor)

	--ЭТО КРОПОЧКИ
	local xPos = 3
	local spaceBetween = 2
	xPos = {ecs.drawAdaptiveButton(xPos, yStartOfTopBar, 2, 1, "►", topBarButtonColor, topBarButtonTextColor)}
		newObj("topButtons", "►", xPos[1], xPos[2], xPos[3], xPos[4])
	xPos = xPos[3] + spaceBetween + 1
	ecs.drawAdaptiveButton(xPos, yStartOfTopBar, 2, 1, "☼", topBarButtonColor, topBarButtonTextColor)



	--А ЭТО Я ВООБЩЕ РОТ ЕТОГО ЕБАЛ 
	--ГОВНОКОД, НО РАБОТАЕТ
	local hernya = {
		{
			"╓───┐",
			"║   │",
			"╙───┘"
		},
		{
			"╒═══╕",
			"│   │",
			"└───┘"
		},
		{
			"┌───╖",
			"│   ║",
			"└───╜"
		},
	}

	xPos = xInfoPanel + infoPanelWidth + 2
	gpu.setBackground(topBarColor)
	for i = 1, 3 do
		local color = topBarButtonTextColor
		if i == 1 and not toolbarsToShow.left then color = topBarButtonColor end
		if i == 2 and not toolbarsToShow.top then color = topBarButtonColor end
		if i == 3 and not toolbarsToShow.bottom then color = topBarButtonColor end

		gpu.setForeground(color)
		for j = 1, 3 do
			gpu.set(xPos, yStartOfTopBar + j - 1, hernya[i][j])
		end

		xPos = xPos + 6


		color = nil
	end

	--ecs.drawAdaptiveButton(xPos, yStartOfTopBar, 2, 1, "☼", topBarColor, topBarButtonTextColor)


	xPos, spaceBetween = nil, nil

	if toolbarsToShow.top then drawInfoPanel() end
end

local function drawBottomScrollBar()
	local yPos = yStartOfText + textHeight

	local width = 0
	if toolbarsToShow.left then width = xSize - leftBarWidth - 2 else width = xSize - 2 end
	ecs.square(xStartOfText - 1, yPos, width, 1, scrollBarColor)
	ecs.square(xStartOfText - 1, yPos, 8, 1, scrollBarActiveColor)

	width, yPos = nil, nil
end

local function drawRightSrollBar()
	local rightScrollBarHeight = textHeight
	local countOfAllElements = #strings
	local sizeOfScrollBar = math.ceil(1 / countOfAllElements * rightScrollBarHeight)
	local displayBarFrom = math.floor(yStartOfText + rightScrollBarHeight * ((stringToDisplayFrom - 1) / countOfAllElements))

	ecs.square(xSize - 1, yStartOfText, 2, rightScrollBarHeight, scrollBarColor)
	ecs.square(xSize - 1, displayBarFrom, 2, sizeOfScrollBar, scrollBarActiveColor)

	sizeOfScrollBar, displayBarFrom, rightScrollBarHeight, countOfAllElements = nil, nil, nil, nil
end

local function isStringCommented(stro4ka)
	local starting, ending = string.find(stro4ka, "^%-%-")
	if not starting then
		starting, ending = string.find(stro4ka, "^%s*%-%-")
	end
	if not starting then return false end

	return starting, ending
end

local function analyseStrings(from, to)
	for i = from, to do

		--УБИРАЕМ ТАБСЫ НА ХЕР, ЗАМЕНЯЕМ ИХ ПРОБЕЛАМИ
		strings[i][1] = string.gsub(strings[i][1], "	", string.rep(" ", indentationWidth))

		--ВСЯКИЕ ТАМ КОММЕНТАРИИ И ПРОЧЕЕ
		local isCommentet = false
		local starting = isStringCommented(strings[i][1])
		if starting then isCommentet = true end

		strings[i][2] = isCommentet
		strings[i][3] = false
		strings[i][4] = false

		isCommentet = nil
	end

	calculateLineNumbersWidth()
end

local function drawString(i)

	local yPos = yStartOfText + i - stringToDisplayFrom
	--ecs.error("yPos="..yPos..", yStartOfText="..yStartOfText..", stringToDisplayFrom="..stringToDisplayFrom..", i="..i)
	local xPos = xStartOfText

	--ВСЯКАЯ ПОЕБИСТИКА С ЦВЕТАМИ
	local textColor = textAreaTextColor
	local backColor = textAreaColor

	if strings[i][4] then
		backColor = backSelectionColor
		textColor = textSelectionColor
		if strings[i][3] then backColor = backSelectionColor + backHighlightColor end
	elseif strings[i][3] then
		backColor = backHighlightColor
		textColor = textHighlightColor
	end

	if strings[i][2] then
		textColor = textCommentColor
	end

	--if strings[i][3] or strings[i][4] then ecs.square(xPos + 1, yPos, textWidth - 1, 1, backColor) end

	--САМА ПЕЧАТЬ ТЕКСТА

	gpu.setBackground(backColor)

	local symbolToDisplayFromEnd = symbolToDisplayFrom + textWidth - 1
	local widthOfCoverSpaces = textWidth - unicode.len(unicode.sub(strings[i][1], symbolToDisplayFrom, symbolToDisplayFromEnd))
	local text = unicode.sub(strings[i][1], symbolToDisplayFrom, symbolToDisplayFromEnd)

	ecs.colorText(xStartOfText, yPos, textColor, text .. string.rep(" ", widthOfCoverSpaces))

	-- ОТСТУПЫ, ТАБУЛЯЦИЯ
	-- local starting, ending = string.find(text, "^%s*[^%s]")
	-- if starting then
	-- 	local count = math.floor(ending / indentationWidth)
	-- 	ecs.colorText(xStartOfText - math.ceil((ending - 1) % indentationWidth), yPos, indentationColor, string.rep("│" .. string.rep(" ", indentationWidth - 1), count))
	-- end

	--А ЭТО КАРОЧ ВАЩЕ АХУЕННАЯ ИДЕЙКА, ЩА ПОТЕСТИМ, БУДЕТ ЛИ РАБОТАТЬ
	--В ОБЩЕМ, ЭТО ОТРИСОВОЧКА ЛИНЕНУМБЕРСОВ ВАШЕ ВСЕХ!!! ПРЯМ ВСЕХ
	--ВАЩЕЕЕЕ, СУКА, ВСЕХ!
	gpu.setBackground(lineNumbersColor)
	gpu.setForeground(lineNumbersTextColor)
	local text = string.rep(" ", lineNumbersWidth - 1 - #tostring(i)) .. i .. " "
	gpu.set(xStartOfLineNumbers, yPos, text)
	text = nil
	
	symbolToDisplayFromEnd, text, widthOfCoverSpaces, textColor, count, starting, ending = nil, nil, nil, nil, nil, nil, nil

	return yPos, xPos
end

local function drawText()
	local yPos = 0
	for i = stringToDisplayFrom, (stringToDisplayFrom + textHeight - 1) do
		if strings[i] then
			--ТУТ МЫ КАРОЧ ПОЛУЧАЕМ СТРОЧКУ - НОМЕР ЕЕ, НУ И РИСУЕМ ЗАОДНО
			yPos = drawString(i)
			--А ЭТО КАРОЧ ОЧИСТКА ВСЕГО ЛИШНЕГО ГОВНА, КОТОРОЕ ПРИ СКРОЛЛИНГЕ ОСТАЕТСЯ 
			if i >= #strings then
				if yPos < (yStartOfText + textHeight -1) then
					gpu.setBackground(textAreaColor)
					gpu.set(xStartOfText, yPos + 1, string.rep(" ", textWidth))
					--ЭТО СЕРАЯ ХУЙНЯ ДОНИЗУ
					ecs.square(xStartOfLineNumbers, yPos + 1, lineNumbersWidth, ySize - yPos - bottomToolbarHeight , lineNumbersColor)
				end
			end
		else
			break
		end
	end

	yPos = nil

	-- ОЧИСТКА ВЕРТИКАЛЬНОЙ ХУЕТЫ ОКОЛО ЛИНЕНУМБЕРСА
	ecs.square(xStartOfLineNumbers + lineNumbersWidth, yStartOfText, 1, textHeight, textAreaColor)
end

local function moveText(direction)
	if direction == "up" then
		if stringToDisplayFrom > 1 then
			stringToDisplayFrom = stringToDisplayFrom - 1
			drawText()
			drawRightSrollBar()
		end
	elseif direction == "down" then
		if stringToDisplayFrom < #strings then
			stringToDisplayFrom = stringToDisplayFrom + 1
			drawText()
			drawRightSrollBar()
		end
	elseif direction == "left" then
		if symbolToDisplayFrom > 1 then
			symbolToDisplayFrom = symbolToDisplayFrom - 1
			drawText()
		end
	elseif direction == "right" then
		if symbolToDisplayFrom < 100 then
			symbolToDisplayFrom = symbolToDisplayFrom + 1
			drawText()
		end
	end
	if toolbarsToShow.top then drawInfoPanel() end
end

local function convertCoordToString(coord)
	return stringToDisplayFrom + (coord - yStartOfText)
end

local function convertStringToCoord(string)
	
end

local selectedStrings = {}
local function selectString(coord)
	local number = convertCoordToString(coord)
	if strings[number] and number >= stringToDisplayFrom and number <= (stringToDisplayFrom + textHeight) then
		
		if not strings[number][4] then
			strings[number][4] = true
			drawString(number)

			table.insert(selectedStrings, number)
		end
	end
	number = nil
end

local function deselectStrings()
	for i = 1, #selectedStrings do
		strings[selectedStrings[i]][4] = false
	end

	selectedStrings = {}
end

local function selectAll()
	selectedStrings = {}
	for i = 1, #strings do
		strings[i][4] = true
		selectedStrings[i] = i
	end
end

local function deselectAll()
	selectedStrings = {}
	for i = 1, #strings do
		strings[i][4] = false
	end
end

local function indent()
	for i = 1, #selectedStrings do
		local number = selectedStrings[i]
		strings[number][1] = string.rep(" ", indentationWidth) .. strings[number][1]
	end
end

local function unIndent()
	for i = 1, #selectedStrings do
		local number = selectedStrings[i]
		local starting, ending = string.find(strings[number][1], "^"..string.rep("%s", indentationWidth))
		if starting then 
			strings[number][1] = unicode.sub(strings[number][1], ending + 1, -1)
		end
	end	
end

local function toggleComment()
	local countOfCommentedStrings = 0

	for i = 1, #selectedStrings do
		local number = selectedStrings[i]

		local starting, ending = isStringCommented(strings[number][1])

		if starting then countOfCommentedStrings = countOfCommentedStrings + 1 end

		number, starting, ending = nil, nil, nil
	end

	if countOfCommentedStrings >= #selectedStrings then
		for i = 1, #selectedStrings do
			local number = selectedStrings[i]
			local starting, ending = isStringCommented(strings[number][1])
			if starting then
				strings[number][2] = false
				strings[number][1] = unicode.sub(strings[number][1], 1, starting - 1) .. unicode.sub(strings[number][1], ending + 1, -1)
			end
		end
	else
		for i = 1, #selectedStrings do
			local number = selectedStrings[i]
			strings[number][2] = true
			strings[number][1] = "--"..strings[number][1]
		end
	end
end

local clipBoard = {}
local function copy()
	clipBoard = {}

	--КОПИРУЕМ В БУФЕР ОБМЕНА ВОТ ТАКИМ ВОТ ХИТРОЗАДЫМ МЕТОДОМ
	for i = 1, #selectedStrings do
		local position = #clipBoard + 1
		clipBoard[position] = {}

		for j = 1, 4 do
			clipBoard[position][j] = strings[selectedStrings[i]][j]
		end

		clipBoard[position][3], clipBoard[position][4] = false, false
	end

	--ecs.error("#selectedStrings = "..#selectedStrings..", #clipBoard = "..#clipBoard..", #strings = "..#strings)
end

local function paste(yPos)
	deselectStrings()
	local massiv
	local counter = 1
	for i = 1, #clipBoard do
		massiv = {}
		for j = 1, 4 do
			massiv[j] = clipBoard[i][j]
		end
		table.insert(strings, yPos + counter, massiv)
		counter = counter + 1
	end

end

local function highlightString(number)
	strings[number][3] = true
end

--ОТРИСОВКА ПОЛОСЫ ПРОКРУТКИ
local function newScrollBar(x,y,height,countOfAllElements,displayingFrom,displayingTo,backColor,frontColor)
	local diapason = displayingTo - displayingFrom + 1
	local percent = diapason / countOfAllElements
	local sizeOfScrollBar = math.ceil(percent * height)
	local displayBarFrom = math.floor(y + height*(displayingFrom-1)/countOfAllElements)

	ecs.square(x,y,1,height,backColor)
	ecs.square(x, displayBarFrom, 1, sizeOfScrollBar, frontColor)
end

local function calculateEndFile()
	local size = #leftToolbarFileList
	if size < leftBarLimit then drawFilesOnLeftToolBarTo = drawFilesOnLeftToolBarFrom + size - 1 else drawFilesOnLeftToolBarTo = drawFilesOnLeftToolBarFrom + leftBarLimit - 1 end
end

local function drawFileListOnLeftToolbar(path)
	calculateEndFile()
	local from, to = drawFilesOnLeftToolBarFrom, drawFilesOnLeftToolBarTo
	local yPos = yStartOfText + 1
	local xPos = 2
	local textLimit = leftBarWidth - 3

	--СКРОЛЛБАР
	newScrollBar(leftBarWidth, yStartOfText + 1, leftBarLimit, #leftToolbarFileList, from, to, scrollBarColor, scrollBarActiveColor)

	--САМ ТЕКСТ
	gpu.setBackground(leftToolbarColor)

	for i = from, to do
		if leftToolbarFileList[i] then
			local color = leftToolbarFileColor
			local cyka = path..leftToolbarFileList[i]
			if fs.isDirectory(cyka) then
				color = leftToolbarFolderColor
			end
			if ecs.isFileHidden(cyka) then
				color = leftToolbarFileColor - 0x999999
			end
			--ecs.error(cyka.." "..projectPath)
			if cyka == projectPath then
				color = 0xffffff
				ecs.square(1, yPos, leftBarWidth - 1, 1, ecs.colors.blue)
			end
			local text = ecs.stringLimit("start", leftToolbarFileList[i], textLimit)
			ecs.colorText(2, yPos, color, text)
			gpu.setBackground(leftToolbarColor)


			newObj("leftBarFiles", cyka, 1, yPos, leftBarWidth - 1, yPos, text)
			--ecs.error("path = ".. cyka)

			yPos = yPos + 1
			color, cyka, text = nil, nil, nil
		else
			break
		end
	end

	countOfAllElements, sizeOfScrollBar, displayBarFrom, xPos, yPos = nil, nil, nil, nil, nil
end

local leftToolbarHistory = {}
local function drawLeftToolBar()
	local path = leftToolbarPath

	--ЭТО КАРОЧ ВЕРХНЯЯ ПОЛОСОЧКА И ЗАЛИВКА ВООБЩЕ ВСЯ
	ecs.square(1, yStartOfText, leftBarWidth, 1, 0xffffff)
	ecs.colorText(1, yStartOfText, 0x000000, ecs.stringLimit("start", path, leftBarWidth))
	ecs.square(1, yStartOfText + 1, leftBarWidth - 1, leftToolbarHeight, leftToolbarColor)
	ecs.square(1, ySize, leftBarWidth, 1, leftToolbarFieldColor)
	
	--ОТРИСОВКА КНОПОЧЕК СНИЗУ КАРОЧ
	local buttons = {"◄", "Home", "Root"}
	local xPos = 2
	for i = 1, #buttons do
		newObj("leftBarButtons", buttons[i], ecs.drawAdaptiveButton(xPos, ySize, 0, 0, buttons[i], leftToolbarFieldColor, topBarButtonTextColor))
		xPos = xPos + unicode.len(buttons[i]) + 2
	end
	--ecs.colorText(2, yStartOfText + textHeight, topBarButtonTextColor, "◄  Home  Root")

	obj["leftBarFiles"] = {}
	local fileList = ecs.getFileList(path)
	if #fileList > 0 then
		leftToolbarFileList = ecs.reorganizeFilesAndFolders(fileList, true)
		drawFileListOnLeftToolbar(path)
	end



end

local function drawBottomToolbar()
	--СЕРАЯ ПОДЛОЖКА
	ecs.square(xStartOfBottomToolbar, yStartOfBottomToolbar, bottomToolbarWidth, bottomToolbarHeight, bottomToolbarColor )
	--КНОПЫ
	local xPos = xStartOfBottomToolbar + 2
	local yPos = yStartOfBottomToolbar + 1
	local buttonCase = {ecs.drawAdaptiveButton(xPos, yPos, 1, 0, "Aa", bottomToolbarButtonColor, bottomToolbarTextColor)}; xPos = xPos + 5
	local buttonInSelection = {ecs.drawAdaptiveButton(xPos, yPos, 1, 0, "¬", bottomToolbarButtonColor, bottomToolbarTextColor)}; xPos = xPos + 4

	--БЕЛАЯ СТРОКА ПОИСКА
	local inputWidth = bottomToolbarWidth - 36
	ecs.inputText(xPos, yPos, inputWidth, "local function", 0xffffff, 0x000000, true)

	--ОПЯТЬ КНОПЫ
	xPos = xStartOfBottomToolbar + bottomToolbarWidth - 24
	local buttonFind = {ecs.drawAdaptiveButton(xPos, yPos, 2, 0, "Find", bottomToolbarButtonColor, bottomToolbarTextColor)}; xPos = xPos + 9
	local buttonFindNext = {ecs.drawAdaptiveButton(xPos, yPos, 2, 0, "Find Prev", bottomToolbarButtonColor, bottomToolbarTextColor)}

	--ОБЖЕКТЫ
	newObj("bottomElements", "Aa")
end

local function drawAll()
	ecs.square(xStartOfLineNumbers, yStartOfText, xStartOfLineNumbers + lineNumbersWidth + textWidth, textHeight, textAreaColor)
	drawTopButtons()
	--ВОТ ТУТ РИСУЕМ ТУ МЕЛКУЮ ХУЙНЮ ПОД НОМЕРАМИ СТРОК
	ecs.square(xStartOfLineNumbers, yStartOfText + textHeight, lineNumbersWidth, 1, lineNumbersColor)
	drawText()
	drawBottomScrollBar()
	drawRightSrollBar()
	if toolbarsToShow.top then drawTopToolbar() end
	if toolbarsToShow.left then drawLeftToolBar() end
	if toolbarsToShow.bottom then drawBottomToolbar() end

	setCursor(true)
end

local function changeScale(plus)
	if plus then
		scaleMultiplier = scaleMultiplier + 10
	else
		scaleMultiplier = scaleMultiplier - 10
	end

	local width, height = gpu.maxResolution()
	local proportion = width / height
	local newWidth = math.ceil(width * (scaleMultiplier / 100))
	local newHeight = math.ceil(newWidth / proportion)
	gpu.setResolution(newWidth,newHeight)
	xSize, ySize = newWidth, newHeight

	width, height, proportion, newHeight, newWidth = nil, nil, nil, nil, nil

	recalculateTo4toNuzhno()
	drawAll()
end

local function open(path)
	local f = io.open(path,"r")
	local lines = {}
	while true do
		local line = f:read("*l")
		if not line then break else table.insert(lines, line) end
		line = nil
	end
	f:close()

	strings = {}
	for i = 1, #lines do
		table.insert(strings, {lines[i]})
	end

	stringToDisplayFrom = 1
	selectedStrings = {}
end


local function compile()
	local success, reason = shell.execute(projectPath)
	drawAll()
	if not success then
		--ecs.error("reason = "..reason)
		if toolbarsToShow.top then drawInfoPanel({" ", "Ошибка!", " "}, errorColor, errorTextColor) end
		--drawErrorMessage(yStartOfText, reason, xSize - 20)
		--ecs.error(reason)
		ecs.displayCompileMessage(yStartOfText, reason, true)
	else
		if toolbarsToShow.top then drawInfoPanel({" ", "Программа выполнена!", " "}, successColor, successTextColor) end
	end
end

---------------------------------------ПРОГА------------------------------------------------------

if args[1] == "-o" or args[1] == "open" then
	projectPath = "/"..args[2]
	leftToolbarPath = fs.path(projectPath)
	open(projectPath)
else
	projectPath = "/"
	leftToolbarPath = projectPath
	strings = {{"Hello world!"}, {"This is insane lags"}, {"while true do"}, {"forever end ahahahha for i = 1, 10 do"}, {"end"}}
end

leftToolbarHistory = {""}

recalculateTo4toNuzhno()
analyseStrings(1, #strings)
drawAll()

ecs.error("MineCode вообще в стадии разработки. Так что не думай, что тут что-то можно делать. Можно только файлики открывать.")


while true do
	local e = {event.pull()}
	if e[1] == "drag" then
		if ecs.clickedAtArea(e[3], e[4], obj["zones"]["textArea"][1], obj["zones"]["textArea"][2], obj["zones"]["textArea"][3], obj["zones"]["textArea"][4]) then
	
			selectString(e[4])

		end

	elseif e[1] == "touch" then

		--КЛИК В ТЕКСТОВУЮ ЗОНУ
		if ecs.clickedAtArea(e[3], e[4], obj["zones"]["textArea"][1], obj["zones"]["textArea"][2], obj["zones"]["textArea"][3], obj["zones"]["textArea"][4]) then
			
			if e[5] == 0 then
				if #selectedStrings > 0 and not keyboard.isControlDown() then
					deselectStrings()
					drawText()
				end

				xCursorPos, yCursorPos = convertCoordsToCursorPoses(e[3], e[4])

				setCursor(true)
			else
				local action = context.menu(e[3], e[4], {"Вырезать", false, "^X"}, {"Копировать", false, "^C"}, {"Вставить", not (#clipBoard > 0), "^V"}, "-", {"Подсветить",false,"^L"}, {"Закомментировать",false,"^⌂C"}, "-", {"Выбрать все",false,"^A"})
				if action == "Вставить" and #clipBoard > 0 then
					paste(yCursorPos)
					calculateLineNumbersWidth()
					drawText()
				elseif action == "Копировать" and #selectedStrings > 0 then
					copy()
					deselectStrings()
					drawText()
				elseif action == "Закомментировать" and #selectedStrings > 0 then
					toggleComment()
					drawText()
				elseif action == "Выбрать все" then
					selectAll()
					drawText()
				elseif action == "Подсветить" and #selectedStrings > 0 then
					for i = 1, #selectedStrings do
						highlightString(selectedStrings[i])
					end
					drawText()
				end
			end

		--ЕСЛИ КЛИКНУЛИ НА ТОП ТУЛБАР
		elseif toolbarsToShow.top and ecs.clickedAtArea(e[3], e[4], obj["zones"]["topBar"][1], obj["zones"]["topBar"][2], obj["zones"]["topBar"][3], obj["zones"]["topBar"][4]) then

			for key, val in pairs(obj["topButtons"]) do
				if ecs.clickedAtArea(e[3], e[4], obj["topButtons"][key][1], obj["topButtons"][key][2], obj["topButtons"][key][3], obj["topButtons"][key][4]) then
					ecs.drawAdaptiveButton(obj["topButtons"][key][1], obj["topButtons"][key][2], 2, 1, key, topBarButtonTextColor, 0xffffff - topBarButtonTextColor)
					os.sleep(0.2)
					compile()

					break
				end
			end

		--КЛИК НА ЛЕВЫЙ ТУЛБАР
		elseif toolbarsToShow.left and ecs.clickedAtArea(e[3], e[4], obj["zones"]["leftBar"][1], obj["zones"]["leftBar"][2], obj["zones"]["leftBar"][3], obj["zones"]["leftBar"][4]) then
			for key, val in pairs(obj["leftBarFiles"]) do
				if ecs.clickedAtArea(e[3], e[4], obj["leftBarFiles"][key][1], obj["leftBarFiles"][key][2], obj["leftBarFiles"][key][3], obj["leftBarFiles"][key][4]) then
					


					if fs.isDirectory(key) then

						ecs.square(1, obj["leftBarFiles"][key][2], obj["leftBarFiles"][key][3], 1, ecs.colors.blue)
						ecs.colorText(2, obj["leftBarFiles"][key][2], 0xffffff, obj["leftBarFiles"][key][5])
						os.sleep(0.2)
						table.insert(leftToolbarHistory, key)
						leftToolbarPath = key
						drawLeftToolBar()
					else
						projectPath = key
						open(projectPath)
						analyseStrings(1, #strings)
						recalculateTo4toNuzhno()
						drawAll()
					end
					break

				end
			end

			--КЛИК НА КНПОЧКИ ЛЕВОГО ТУЛБАРА
			for key, val in pairs(obj["leftBarButtons"]) do
				if ecs.clickedAtArea(e[3], e[4], obj["leftBarButtons"][key][1], obj["leftBarButtons"][key][2], obj["leftBarButtons"][key][3], obj["leftBarButtons"][key][4]) then
				
					ecs.drawAdaptiveButton(obj["leftBarButtons"][key][1] - 1, obj["leftBarButtons"][key][2], 1, 0, key, topBarButtonTextColor, topBarColor)
					os.sleep(0.3)

					if key == "◄" and #leftToolbarHistory > 1 then 
						leftToolbarHistory[#leftToolbarHistory] = nil
						leftToolbarPath = leftToolbarHistory[#leftToolbarHistory]
					elseif key == "Home" then
						leftToolbarHistory = {"/"}
						leftToolbarPath = fs.path(projectPath)
					elseif key == "Root" then
						leftToolbarHistory = {"/"}
						leftToolbarPath = "/"
					end

					drawLeftToolBar()

					break
				end
			end
		end

	elseif e[1] == "key_down" then
		if e[4] == 200 then
			moveText("up")
		elseif e[4] == 208 then
			moveText("down")
		elseif e[4] == 203 then
			moveText("left")
		elseif e[4] == 205 then
			moveText("right")
		-- CTRL + C
		elseif e[4] == 46 then
			if keyboard.isControlDown() and not keyboard.isShiftDown() and #selectedStrings > 0 then
				copy()
				ecs.error("Скопировалось")
				deselectStrings()
				drawText()
			elseif keyboard.isControlDown() and keyboard.isShiftDown() and #selectedStrings > 0 then
				--ecs.error("Закомментировалось")
				toggleComment()
				drawText()
			end
		-- CTRL + V
		--КЛАВИШИ - И +
		elseif e[4] == 12 then
			if keyboard.isControlDown() and scaleMultiplier < 100 then changeScale(true) end
		elseif e[4] == 13 then
			if keyboard.isControlDown() and scaleMultiplier > 50 then changeScale(false) end
		--КЛАВИША Q
		elseif e[4] == 16 then
			if keyboard.isControlDown() then
				ecs.setScale(oldScale)
				ecs.prepareToExit(0x262626)
				return 0
			end
		--КЛАВИША 0
		elseif e[4] == 11 then
			if toolbarsToShow.top then toolbarsToShow.top = false else toolbarsToShow.top = true end
			recalculateTo4toNuzhno()
			drawAll()
		--КЛАВИША 9
		elseif e[4] == 10 then
			if toolbarsToShow.left then toolbarsToShow.left = false else toolbarsToShow.left = true end
			recalculateTo4toNuzhno()
			drawAll()
		--КЛАВИША 8
		elseif e[4] == 9 then
			toolbarsToShow.bottom = not toolbarsToShow.bottom
			recalculateTo4toNuzhno()
			drawAll()	
		-- ENTER
		elseif e[4] == 28 then
			if keyboard.isControlDown() then compile() end
		elseif e[4] == 47 then
			if keyboard.isControlDown() and #clipBoard > 0 then

				paste(yCursorPos)
				--ecs.error("Вставилось")
				calculateLineNumbersWidth()

				drawText()
			end
		-- CTRL + A
		elseif e[4] == 30 then
			if keyboard.isControlDown() then

				selectAll()

				drawText()
			end
		-- CTRL + D
		elseif e[4] == 32 then
			if keyboard.isControlDown() then
				deselectAll()
				drawText()
			end
		-- TAB
		elseif e[4] == 15 and #selectedStrings > 0 then
			if keyboard.isShiftDown() then
				unIndent()
			else
				indent()
			end
			drawText()
		end
	end
end

