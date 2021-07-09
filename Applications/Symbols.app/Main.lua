
local GUI = require("GUI")
local filesystem = require("Filesystem")
local paths = require("Paths")
local system = require("System")

--------------------------------------------------------------------

local fromChar = 0
local selectedChar = 0
local buttonWidth = 5
local buttonHeight = 3
local horizontalSpacing = 2
local verticalSpacing = 1

local recentCharsPath = paths.user.applicationData .. "Symbols/Recent3.cfg"
local recent = {
	169, 170, 171, 172, 173
}

--------------------------------------------------------------------

local workspace, window = system.addWindow(GUI.filledWindow(1, 1, 90, 23, 0xE1E1E1))

local sidePanel = window:addChild(GUI.panel(1, 1, 17, 1, 0x2D2D2D))
local buttonsContainer = window:addChild(GUI.container(3, 2, 1, 1))
local horizontalResizer = window:addChild(GUI.resizer(1, 1, 10, 3, 0x969696, 0x0))
local verticalResizer = window:addChild(GUI.resizer(1, 1, 3, 5, 0x969696, 0x0))

local sideLayout = window:addChild(GUI.layout(1, 4, sidePanel.width, 1, 1, 1))
sideLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
sideLayout:setFitting(1, 1, true, false, 2, 0)

local texts = {}
for i = 1, 5 do
	texts[i] = sideLayout:addChild(GUI.keyAndValue(1, 1, 0xE1E1E1, 0xA5A5A5, "", ""))
end

local gotoInput = sideLayout:addChild(GUI.input(1, 1, 36, 1, 0x1E1E1E, 0xA5A5A5, 0x4B4B4B, 0x1E1E1E, 0xE1E1E1, "", "Goto code"))

local prevButton = window:addChild(GUI.button(1, 1, sidePanel.width, 3, 0x3C3C3C, 0xE1E1E1, 0x1E1E1E, 0xB4B4B4, "Prev"))
prevButton.colors.disabled.background, prevButton.colors.disabled.text = 0x3C3C3C, 0x787878
prevButton.disabled = true
local nextButton = window:addChild(GUI.button(1, 1, sidePanel.width, 3, 0x4B4B4B, 0xE1E1E1, 0x1E1E1E, 0xB4B4B4, "Next"))

local function updateTexts()
	texts[1].key, texts[1].value = "Char: ", "\"" .. unicode.char(selectedChar) .. "\""
	texts[2].key, texts[2].value = "Dec: ", tostring(selectedChar)
	texts[3].key, texts[3].value = "Hex: ", string.format("0x%X", selectedChar)
	texts[4].key, texts[4].value = "From: ", string.format("0x%X", fromChar)
	texts[5].key, texts[5].value = "To: ", string.format("0x%X", fromChar + #buttonsContainer.children - 1)
end

local function updateChars()
	for i = 1, #buttonsContainer.children do
		buttonsContainer.children[i].pressed = fromChar + i - 1 == selectedChar
		buttonsContainer.children[i].text = unicode.char(fromChar + i - 1)
	end
end

local recentLayout = sideLayout:addChild(GUI.layout(1, 1, 1, 1, 1, 1))
recentLayout:setDirection(1, 1, GUI.DIRECTION_HORIZONTAL)
recentLayout:setSpacing(1, 1, 0)
recentLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)

local function onRecentButtonTouch(workspace, object)
	fromChar = object.code
	selectedChar = object.code
	updateChars()
	updateTexts()

	workspace:draw()
end

local function updateRecent()
	for i = 1, #recentLayout.children do
		recentLayout.children[i].code = recent[i] or math.random(255)
		recentLayout.children[i].text = unicode.char(recentLayout.children[i].code)
	end
end

local step = true
for i = 1, #recent do
	recentLayout:addChild(GUI.button(1, 1, 3, 1, step and 0x3C3C3C or 0x4B4B4B, 0xA5A5A5, 0x1E1E1E, 0xA5A5A5, unicode.char(recent[i]))).onTouch = onRecentButtonTouch
	step = not step
end

local function charButtonOnTouch(workspace, button)
	selectedChar = fromChar + button:indexOf() - 1
	table.insert(recent, 1, selectedChar)
	table.remove(recent, #recent)

	updateChars()
	updateTexts()
	updateRecent()

	workspace:draw()
	filesystem.writeTable(recentCharsPath, recent)
end

window.onResize = function(width, height)
	window.backgroundPanel.localX, window.backgroundPanel.width, window.backgroundPanel.height = sidePanel.width + 1, width - sidePanel.width, height
	buttonsContainer.localX, buttonsContainer.localY, buttonsContainer.width, buttonsContainer.height = window.backgroundPanel.localX + 2, 2, window.backgroundPanel.width - 4, window.backgroundPanel.height - 2
	sidePanel.height = height
	sideLayout.height = sidePanel.height - 3
	horizontalResizer.localX, horizontalResizer.localY = math.floor(window.backgroundPanel.localX + window.backgroundPanel.width / 2 - horizontalResizer.width / 2), window.backgroundPanel.height - 2
	verticalResizer.localX, verticalResizer.localY = window.backgroundPanel.localX + window.backgroundPanel.width - 3, math.floor(window.backgroundPanel.height / 2 - verticalResizer.height / 2)
	
	nextButton.localY = height - 2
	prevButton.localY = height - 5

	buttonsContainer:removeChildren()

	local horizontalCount = math.floor((buttonsContainer.width + horizontalSpacing) / (buttonWidth + horizontalSpacing))
	local verticalCount = math.floor((buttonsContainer.height + verticalSpacing) / (buttonHeight + verticalSpacing))
	local x, y = 1, 1
	
	for j = 1, verticalCount do
		for i = 1, horizontalCount do
			local button = buttonsContainer:addChild(GUI.button(x, y, buttonWidth, buttonHeight, 0xF0F0F0, 0x4B4B4B, 0x880000, 0xE1E1E1, " "))
			button.onTouch = charButtonOnTouch
			button.switchMode = true
			button.animated = false

			x = x + buttonWidth + horizontalSpacing
		end

		x, y = 1, y + buttonHeight + verticalSpacing
	end

	updateChars()
	updateTexts()
	workspace:draw()
end

local function onAny()
	if fromChar < 0 then
		fromChar = 0
	end
	prevButton.disabled = fromChar <= 0
end

nextButton.onTouch = function()
	fromChar = fromChar + #buttonsContainer.children
	onAny()

	updateChars()
	updateTexts()
	workspace:draw()
end

prevButton.onTouch = function()
	fromChar = fromChar - #buttonsContainer.children
	onAny()

	updateChars()
	updateTexts()
	workspace:draw()
end

local overrideWindowEventHandler = window.eventHandler
window.eventHandler = function(...)
	if select(3, ...) == "scroll" then
		if select(7, ...) > 0 then
			prevButton.onTouch()
		else
			nextButton.onTouch()
		end
	end

	overrideWindowEventHandler(...)
end

gotoInput.onInputFinished = function()
	local number = tonumber(gotoInput.text)
	if number then
		gotoInput.text = ""
		fromChar = number
		updateChars()
		updateTexts()

		workspace:draw()
	end
end

horizontalResizer.onResize = function(dragX, dragY)
	window:resize(window.width, window.height + dragY)
end

verticalResizer.onResize = function(dragX, dragY)
	window:resize(window.width + dragX, window.height)
end

--------------------------------------------------------------------

if filesystem.exists(recentCharsPath) then
	recent = filesystem.readTable(recentCharsPath)
end
updateRecent()

window.actionButtons:moveToFront()
window:resize(window.width, window.height)