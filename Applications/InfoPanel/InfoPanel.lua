
local computer = require("computer")
local component = require("component")
local GUI = require("GUI")
local unicode = require("unicode")
local fs = require("filesystem")
local buffer = require("doubleBuffering")
local xmlParser = require("xmlParser")

--------------------------------------------------------------------------------

local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x1E1E1E))

local mainLayout = mainContainer:addChild(GUI.layout(1, 1, mainContainer.width, mainContainer.height, 1, 1))

local function addHorizontalLayout()
	local layout = mainLayout:addChild(GUI.layout(1, 1, mainContainer.width, 3, 1, 1))
	layout:setDirection(1, 1, GUI.DIRECTION_HORIZONTAL)
	layout:setSpacing(1, 1, 2)

	return layout
end

mainLayout:addChild(GUI.text(1, 1, 0xE1E1E1, "Screen resolution"))

local resolutionLayout = addHorizontalLayout()
local widthInput = resolutionLayout:addChild(GUI.input(1, 1, 24, 3, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, "160", "Screen width"))
local heightInput = resolutionLayout:addChild(GUI.input(1, 1, widthInput.width, 3, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, "50", "Screen height"))

mainLayout:addChild(GUI.text(1, 1, 0xE1E1E1, "Color scheme"))

local colorsLayout1 = addHorizontalLayout()
local backgroundColorSelector = colorsLayout1:addChild(GUI.colorSelector(1, 1, widthInput.width, 3, 0x1E1E1E, "Background"))
local textColorSelector = colorsLayout1:addChild(GUI.colorSelector(1, 1, widthInput.width, 3, 0xFFFFFF, "Text"))

local colorsLayout2 = addHorizontalLayout()
local leftBarBackgroundColorSelector = colorsLayout2:addChild(GUI.colorSelector(1, 1, widthInput.width, 3, 0xE1E1E1, "Toolbar background"))
local leftBarTextColorSelector = colorsLayout2:addChild(GUI.colorSelector(1, 1, widthInput.width, 3, 0x2D2D2D, "Toolbar text"))

local colorsLayout3 = addHorizontalLayout()
local leftBarAlternativeBackgroundColorSelector = colorsLayout3:addChild(GUI.colorSelector(1, 1, widthInput.width, 3, 0xD2D2D2, "Toolbar alt background"))
local leftBarAlternativeTextColorSelector = colorsLayout3:addChild(GUI.colorSelector(1, 1, widthInput.width, 3, 0x2D2D2D, "Toolbar alt text"))

local colorsLayout4 = addHorizontalLayout()
local leftBarSelectedBackgroundColorSelector = colorsLayout4:addChild(GUI.colorSelector(1, 1, widthInput.width, 3, 0x3366CC, "Toolbar sel background"))
local leftBarSelectedTextColorSelector = colorsLayout4:addChild(GUI.colorSelector(1, 1, widthInput.width, 3, 0xFFFFFF, "Toolbar sel text"))

local colorsLayout5 = addHorizontalLayout()
local scrollBarBackgroundColorSelector = colorsLayout5:addChild(GUI.colorSelector(1, 1, widthInput.width, 3, 0xE1E1E1, "Scrollbar background"))
local scrollBarPipeColorSelector = colorsLayout5:addChild(GUI.colorSelector(1, 1, widthInput.width, 3, 0x3366CC, "Scrollbar pipe"))

mainLayout:addChild(GUI.text(1, 1, 0xE1E1E1, "Text files directory"))

local filesystemChooser = mainLayout:addChild(GUI.filesystemChooser(1, 1, widthInput.width * 2 + 2, 3, 0xE1E1E1, 0x888888, 0x3C3C3C, 0x888888, "/InfoPanel/Pages/", "Open", "Cancel", "Choose directory", "/"))
filesystemChooser:setMode(GUI.IO_MODE_OPEN, GUI.IO_MODE_DIRECTORY)
mainLayout:addChild(GUI.button(1, 1, filesystemChooser.width, 3, 0x3C3C3C, 0xE1E1E1, 0xE1E1E1, 0x3C3C3C, "OK")).onTouch = function()
	mainContainer:removeChildren()

	buffer.setResolution(tonumber(widthInput.text), tonumber(heightInput.text))
	mainContainer.width, mainContainer.height = buffer.getResolution()

	local list = mainContainer:addChild(GUI.list(1, 1, 24, mainContainer.height, 3, 0, leftBarBackgroundColorSelector.color, leftBarTextColorSelector.color, leftBarAlternativeBackgroundColorSelector.color, leftBarAlternativeTextColorSelector.color, leftBarSelectedBackgroundColorSelector.color, leftBarSelectedTextColorSelector.color))
	
	local data = mainContainer:addChild(GUI.object(list.width + 1, 1, mainContainer.width - list.width, mainContainer.height))
	local lines = {}
	local linesY = 2

	data.draw = function()
		buffer.drawRectangle(data.x, data.y, data.width, data.height, backgroundColorSelector.color, textColorSelector.color, " ")
		
		local textColor, y, x = textColorSelector.color, linesY
		for i = 1, #lines do
			x = list.width + 3

			for j = 1, #lines[i] do
				if type(lines[i][j]) == "table" then
					if lines[i][j].label == "color" then
						textColor = tonumber(lines[i][j][1])
					end
				else
					buffer.drawText(x, y, textColor, lines[i][j])
					x = x + unicode.len(lines[i][j])
				end
			end

			y = y + 1
		end
	end

	local scrollBar = mainContainer:addChild(GUI.scrollBar(mainContainer.width - 3, 1, 4, mainContainer.height, scrollBarBackgroundColorSelector.color, scrollBarPipeColorSelector.color, 1, 100, 1, mainContainer.height, 1))
	scrollBar.onTouch = function()
		linesY = -math.floor(scrollBar.value) + 3
		mainContainer:drawOnScreen()
	end

	local files = {}
	for file in fs.list(filesystemChooser.path) do
		if not fs.isDirectory(filesystemChooser.path .. file) then
			table.insert(files, file)
		end
	end
	table.sort(files, function(a, b) return a < b end)

	for i = 1, #files do
		list:addItem(files[i]:gsub("^%d+_", "")).onTouch = function()
			lines = {}
			for line in io.lines(filesystemChooser.path .. files[i]) do
				table.insert(lines, xmlParser.collect(line))
			end

			linesY = 2
			scrollBar.hidden = #lines <= mainContainer.height
			scrollBar.maximumValue = #lines
			scrollBar.value = 1

			mainContainer:drawOnScreen()
		end
	end

	if list:count() > 0 then
		list:getItem(1).onTouch()
	end
end

mainContainer:drawOnScreen(true)
mainContainer:startEventHandling()