
local computer = require("computer")
local component = require("component")
local GUI = require("GUI")
local unicode = require("unicode")
local fs = require("filesystem")
local buffer = require("doubleBuffering")
local xmlParser = require("xmlParser")
local scale = require("scale")

--------------------------------------------------------------------------------

local config = {
	scale = 0.63,
	leftBarWidth = 20,
	scrollBarWidth = 4,
	pagesPath = "/InfoPanel/Pages/",
	colors = {
		background = 0x1E1E1E,
		text = 0xFFFFFF,
		leftBarRegularBackground = 0xE1E1E1,
		leftBarRegularText = 0x2D2D2D,
		leftBarAlternativeBackground = 0xD2D2D2,
		leftBarAlternativeText = 0x2D2D2D,
		leftBarSelectionBackground = 0x3366CC,
		leftBarSelectionText = 0xFFFFFF,
		scrollBarBackground = 0xE1E1E1,
		scrollBarPipe = 0x3366CC,
	},
}

local lines = {}
local linesY = 2

--------------------------------------------------------------------------------

scale.set(config.scale)
buffer.flush()

local mainContainer = GUI.fullScreenContainer()
local list = mainContainer:addChild(GUI.list(1, 1, config.leftBarWidth, mainContainer.height, 3, 0, config.colors.leftBarRegularBackground, config.colors.leftBarRegularText, config.colors.leftBarAlternativeBackground, config.colors.leftBarAlternativeText, config.colors.leftBarSelectionBackground, config.colors.leftBarSelectionText))
local data = mainContainer:addChild(GUI.object(list.width + 1, 1, mainContainer.width - list.width, mainContainer.height))

data.draw = function()
	buffer.drawRectangle(data.x, data.y, data.width, data.height, config.colors.background, config.colors.text, " ")
	
	local textColor, y, x = config.colors.text, linesY
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

local scrollBar = mainContainer:addChild(GUI.scrollBar(mainContainer.width - config.scrollBarWidth + 1, 1, config.scrollBarWidth, mainContainer.height, config.colors.scrollBarBackground, config.colors.scrollBarPipe, 1, 100, 1, mainContainer.height, 1))
scrollBar.onTouch = function()
	linesY = -math.floor(scrollBar.value) + 3
	mainContainer:drawOnScreen()
end

local files = {}
for file in fs.list(config.pagesPath) do
	if not fs.isDirectory(config.pagesPath .. file) then
		table.insert(files, file)
	end
end
table.sort(files, function(a, b) return a < b end)

for i = 1, #files do
	list:addItem(files[i]:gsub("^%d+_", "")).onTouch = function()
		lines = {}
		for line in io.lines(config.pagesPath .. files[i]) do
			table.insert(lines, xmlParser.collect(line))
		end

		linesY = 2
		scrollBar.hidden = #lines <= mainContainer.height
		scrollBar.maximumValue = #lines
		scrollBar.value = 1

		mainContainer:drawOnScreen()
	end
end

list:getItem(1).onTouch()
buffer.drawChanges(true)
mainContainer:startEventHandling()