
local args = {...}
local mainContainer, window, localization = args[1], args[2], args[3]

require("advancedLua")
local component = require("component")
local computer = require("computer")
local GUI = require("GUI")
local buffer = require("doubleBuffering")
local image = require("image")
local MineOSPaths = require("MineOSPaths")
local MineOSInterface = require("MineOSInterface")

----------------------------------------------------------------------------------------------------------------

local module = {}
module.name = localization.moduleEvent

----------------------------------------------------------------------------------------------------------------

module.onTouch = function()
	window.contentContainer:deleteChildren()

	local container = window.contentContainer:addChild(GUI.container(1, 1, window.contentContainer.width, window.contentContainer.height))

	local layout = container:addChild(GUI.layout(1, 1, container.width, window.contentContainer.height, 1, 1))
	layout:setCellAlignment(1, 1, GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	layout:setCellMargin(1, 1, 0, 1)

	local textBox = layout:addChild(GUI.textBox(1, 1, container.width - 4, container.height - 4, nil, 0x888888, {localization.waitingEvents .. "..."}, 1, 0, 0))
	local switch = layout:addChild(GUI.switchAndLabel(1, 1, 27, 6, 0x66DB80, 0x1E1E1E, 0xFFFFFF, 0x2D2D2D, localization.processingEnabled .. ": ", true)).switch
	
	container.eventHandler = function(mainContainer, object, eventData)
		if switch.state and eventData[1] then
			local lines = table.concat(eventData, " ")
			lines = string.wrap(lines, textBox.width)
			for i = 1, #lines do
				table.insert(textBox.lines, lines[i])
			end
			textBox:scrollToEnd()

			mainContainer:draw()
			buffer.draw()
		end
	end
end

----------------------------------------------------------------------------------------------------------------

return module