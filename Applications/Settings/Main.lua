
local computer = require("computer")
local component = require("component")
local GUI = require("GUI")
local buffer = require("doubleBuffering")
local filesystem = require("filesystem")
local color = require("color")
local image = require("image")
local unicode = require("unicode")
local MineOSInterface = require("MineOSInterface")
local MineOSPaths = require("MineOSPaths")
local MineOSCore = require("MineOSCore")

--------------------------------------------------------------------------------

local modulesPath = MineOSCore.getCurrentScriptDirectory() .. "Modules/"
local localization = MineOSCore.getCurrentScriptLocalization()
local scrollSpeed = 2

--------------------------------------------------------------------------------

local application, window = MineOSInterface.addWindow(GUI.filledWindow(1, 1, 100, 29, 0xF0F0F0))

local leftPanel = window:addChild(GUI.panel(1, 1, 1, 1, 0x2D2D2D))
window.actionButtons.localY = 2
window.actionButtons:moveToFront()

local modulesLayout = window:addChild(GUI.layout(1, 3, 1, 1, 1, 1))
modulesLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_TOP)
modulesLayout:setSpacing(1, 1, 1)

window.contentLayout = window:addChild(GUI.layout(1, 1, 1, 1, 1, 1))

local function moduleDraw(object)
	local textColor = object.pressed and 0x3C3C3C or 0xE1E1E1
	if object.pressed then
		buffer.drawRectangle(object.x, object.y, object.width, object.height, 0xF0F0F0, textColor, " ")
		buffer.drawText(object.x, object.y - 1, 0xF0F0F0, string.rep("▄", object.width))
		buffer.drawText(object.x, object.y + object.height, 0xF0F0F0, string.rep("▀", object.width))
	end

	buffer.drawImage(object.x + 2, object.y, object.icon)
	buffer.drawText(object.x + 12, object.y + 1, textColor, object.module.name)
end

local function runModule(object)
	window.contentLayout:removeChildren()
	window.contentLayout:setMargin(1, 1, 0, object.module.margin)

	window.contentLayout.eventHandler = function(application, _, e1, e2, e3, e4, e5)
		if e1 == "scroll" then
			local cell = window.contentLayout.cells[1][1]
			local to = -math.floor(cell.childrenHeight / 2)

			cell.verticalMargin = cell.verticalMargin + (e5 > 0 and scrollSpeed or -scrollSpeed)
			if cell.verticalMargin > object.module.margin then
				cell.verticalMargin = object.module.margin
			elseif cell.verticalMargin < to then
				cell.verticalMargin = to
			end

			application:draw()
		end
	end

	object.module.onTouch()
	application:draw()
end

local function selectModule(object)
	local child
	for i = 1, #modulesLayout.children do
		child = modulesLayout.children[i]
		child.pressed = object == child
	end

	runModule(object)
end

local function moduleEventHandler(application, object, e1)
	if e1 == "touch" then
		selectModule(object)
	end
end

modulesLayout.eventHandler = function(application, object, e1, e2, e3, e4, e5)
	if e1 == "scroll" then
		local cell = modulesLayout.cells[1][1]
		local to = -(#modulesLayout.children - 1) * 4 + 1
		
		cell.verticalMargin = cell.verticalMargin + (e5 > 0 and scrollSpeed or -scrollSpeed)
		if cell.verticalMargin > 1 then
			cell.verticalMargin = 1
		elseif cell.verticalMargin < to then
			cell.verticalMargin = to
		end

		application:draw()
	end
end

window.onResize = function(width, height)
	modulesLayout:setMargin(1, 1, 0, 1)

	window.backgroundPanel.width, window.backgroundPanel.height = width - leftPanel.width, height
	window.contentLayout.localX, window.contentLayout.width, window.contentLayout.height = window.backgroundPanel.localX, window.backgroundPanel.width, window.backgroundPanel.height
	leftPanel.height = height
	modulesLayout.height = height - 2

	for i = 1, #modulesLayout.children do
		if modulesLayout.children[i].pressed then
			runModule(modulesLayout.children[i])
			break
		end
	end
end

--------------------------------------------------------------------------------

local modules = {}
for file in filesystem.list(modulesPath) do
	table.insert(modules, file)
end
table.sort(modules, function(a, b) return a < b end)

for i = 1, #modules do
	local result, reason = loadfile(modulesPath .. modules[i] .. "Main.lua")
	if result then
		local success, result = pcall(result, application, window, localization)
		if success then
			local object = modulesLayout:addChild(GUI.object(1, 1, 1, 3))

			object.icon = image.load(modulesPath .. modules[i] .. "Icon.pic")
			object.module = result
			object.pressed = false
			object.draw = moduleDraw
			object.eventHandler = moduleEventHandler

			leftPanel.width = math.max(leftPanel.width, unicode.len(result.name) + 14)
		else
			error("Failed to execute module " .. modules[i] .. ": " .. tostring(result))
		end
	else
		error("Failed to load module " .. modules[i] .. ": " .. tostring(reason))
	end
end

modulesLayout.width = leftPanel.width
window.backgroundPanel.localX = leftPanel.width + 1
for i = 1, #modulesLayout.children do
	modulesLayout.children[i].width = leftPanel.width
end

window:resize(window.width, window.height)
selectModule(modulesLayout.children[1])
