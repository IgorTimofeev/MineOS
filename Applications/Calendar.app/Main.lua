local GUI = require("GUI")
local system = require("System")
local bigLetters = require("BigLetters")
local screen = require("Screen")
local image = require("Image")
local paths = require("paths")
local fs = require("Filesystem")

---------------------------------------------------------------------------------------

local currentScriptPath = fs.path(system.getCurrentScript())
local localization = system.getLocalization(currentScriptPath .. "Localizations/") 

local arrowLeftIcon = image.load(currentScriptPath .. "Icons/ArrowLeft.pic")
local arrowRightIcon = image.load(currentScriptPath .. "Icons/ArrowRight.pic")

local configPath = paths.user.applicationData .. "Calendar/Config.cfg"
local config = fs.exists(configPath) and fs.readTable(configPath) or {
	isWeekAlt = false
}

local countOfDays = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
local monthDateMove = {3, 2, 3, 2, 3, 2, 3, 3, 2, 3, 2, 3}
local lastCountedYear = 0
local comMonthMem
local curYearList

---------------------------------------------------------------------------------------

local workspace, window, menu = system.addWindow(GUI.filledWindow(1, 1, 42, 24, 0xFFFFFF))
window.actionButtons.localY = 1

local function isLeap(year)
	if year % 4 == 0 or year % 400 == 0 then return true else return false end
end

local function getNextDay(day)
	return day < 7 and day + 1 or 1
end

local function calculateYear(year, fstDayPos)
	local yearList = {}
	local leap = isLeap(year)

	for month = 1, 12 do
   		yearList[month] = {}

    		if month == 2 then
      			if leap then
				yearList[month].countOfDays = 29
				yearList[month].fstDayPos = fstDayPos
				fstDayPos = getNextDay(fstDayPos)
			else
				yearList[month].countOfDays = 28
				yearList[month].fstDayPos = fstDayPos
      			end
   		 else
			yearList[month].countOfDays = countOfDays[month]
			yearList[month].fstDayPos = fstDayPos
			for i = 1, monthDateMove[month] do
				fstDayPos = getNextDay(fstDayPos)
      			end
		end
	end

	return yearList
end

local function fstJanPos(year)
	local day = 0

	local difference = math.abs(year - 1010)
	local leapCount
  
	if difference % 4 == 0 then
		leapCount = difference / 4
	elseif difference % 4 == 1 or difference % 4 == 2 then
		leapCount = math.floor(difference / 4)
	elseif difference % 4 == 3 then
		leapCount = math.floor(difference / 4) + 1
	end

	local offset = difference + leapCount

	if offset % 7 == 0 then
		day = 1
	else
		day = offset % 7 + 1
	end

	return day
end

local function makeIconButton(x, y, parentObj, right, onTouch)
	local obj = GUI.image(x, y, right and arrowRightIcon or arrowLeftIcon)
	
	parentObj:addChild(obj).eventHandler = function(_, _, event)
		if event == "touch" then
			onTouch()
		end
	end

	return obj
end

local currentStamp = os.date("*t", system.getTime())
local currentYear, currentMonth, currentDay = currentStamp.year, currentStamp.month, currentStamp.day
local selectedYear, selectedMonth = currentYear, currentMonth

local function renderYear(object)
	local text = tostring(selectedYear)
	local width = bigLetters.getTextSize(text)
	bigLetters.drawText(math.floor(object.x + object.width / 2 - width / 2), object.y, 0x000000, text)
end

local year = window:addChild(GUI.object(8, 3, 28, 5))
year.draw = function(object)
	renderYear(object)
end


local function renderMonth(xCoord, yCoord, width, monthPos)
	local text = localization.months[monthPos]
	local weekText = config.isWeekAlt and localization.weekLineAlt or localization.weekLine
	local xStart = math.floor(xCoord + width / 2 - unicode.len(weekText) / 2)
	
	screen.drawText(math.floor(xCoord + width / 2 - unicode.len(text) / 2), yCoord, 0xFF0000, text)
	screen.drawText(xStart, yCoord + 2, 0x888888, weekText)
	
	if not curYearList or selectedYear ~= lastCountedYear then
		curYearList = calculateYear(selectedYear, fstJanPos(selectedYear))
	end
	
	local counter, line = curYearList[monthPos].fstDayPos - 1, 4
	
	if config.isWeekAlt then
		counter = counter + 1 == 7 and 0 or counter + 1
	end
	
	for i=1, curYearList[monthPos].countOfDays do
		local numColor = (config.isWeekAlt and (counter == 0 or counter == 6) and 0xFF0000) or (not config.isWeekAlt and counter > 4 and 0xFF0000) or 0x262626 
		
		if selectedYear == currentYear and monthPos == currentMonth and i == currentDay then
			screen.drawText(xStart + (counter * 4) - 1, yCoord + line - 1, 0xD2D2D2, '⢀▄▄⡀')
			screen.drawRectangle(xStart + (counter * 4) - 1, yCoord + line, 4, 1, 0xD2D2D2, 0x000000, ' ')
			screen.drawText(xStart + (counter * 4) - 1, yCoord + line + 1, 0xD2D2D2, '⠈▀▀⠁')
		end
		
		screen.drawText(xStart + (counter * 4), yCoord + line, numColor, (i < 10 and ' ' or '')..tostring(i))
		counter = counter == 6 and 0 or counter + 1
		if counter == 0 then line = line + 2 end
	end
end

local month = window:addChild(GUI.object(9, 9, 26, 15))
month.draw = function(object)
	renderMonth(object.x, object.y, object.width, selectedMonth)
end


local function prevYear()
	selectedYear = selectedYear == 0 and selectedYear or selectedYear - 1
	workspace:draw()
end

local function nextYear()
	selectedYear = selectedYear == 9999 and selectedYear or selectedYear + 1
	workspace:draw()
end

local arrowLeftBlack = makeIconButton(3, 4, window, false, prevYear)
local arrowRightBlack = makeIconButton(39, 4, window, true, nextYear)

local function prevMonth()
	selectedMonth = selectedMonth - 1

	if selectedMonth < 1 then
		if selectedYear - 1 ~= -1 then
			selectedMonth = 12
			prevYear()
		else
			selectedMonth = 1
		end
	else
		workspace:draw()
	end
end

local function nextMonth()
	selectedMonth = selectedMonth + 1

	if selectedMonth > 12 then
		if selectedYear + 1 ~= 10000 then
			selectedMonth = 1
			nextYear()
		else
			selectedMonth = 12
		end
	else
		workspace:draw()
	end
end

local arrowLeft = makeIconButton(3, 15, window, false, prevMonth)
local arrowRight = makeIconButton(39, 15, window, true, nextMonth)

local weekType = menu:addItem(localization.startWeek..localization.sunday)
weekType.onTouch = function()
	config.isWeekAlt = not config.isWeekAlt
	weekType.text = config.isWeekAlt and localization.startWeek..localization.monday or localization.startWeek..localization.sunday

	fs.writeTable(configPath, config)
end

window.actionButtons.maximize.onTouch = function()
	if not window.maximized then
		year.localX, year.localY = 130, 3
		arrowLeftBlack.localX, arrowLeftBlack.localY = 129, 9
		arrowRightBlack.localX, arrowRightBlack.localY = 157, 9
		month.localX, month.localY = 3, 2
		comMonthMem = selectedMonth
		selectedMonth = 1
		
		local mx, my = 35, 2

		for i=2, 12 do
			local newMonth = window:addChild(GUI.object(mx, my, 26, 15))
			
			newMonth.draw = function(object)
				renderMonth(object.x, object.y, object.width, i)
			end
			
			mx = mx + 32 == 131 and 3 or mx + 32
			
			if mx == 3 then my = my + 16 end
		end
	else
		year.localX, year.localY = 8, 3
		arrowLeftBlack.localX, arrowLeftBlack.localY = 3, 4
		arrowRightBlack.localX, arrowRightBlack.localY = 39, 4
		month.localX, month.localY = 9, 9
		selectedMonth = comMonthMem
		window:removeChildren(9)
	end

	window:maximize()
	
	arrowLeft.hidden = not arrowLeft.hidden
	arrowRight.hidden = not arrowRight.hidden
end


window.onResize = function(newWidth, newHeight)
	window.backgroundPanel.width, window.backgroundPanel.height = newWidth, newHeight
end

workspace:draw()
