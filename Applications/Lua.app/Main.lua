
local GUI = require("GUI")
local system = require("System")

---------------------------------------------------------------------------------

local workspace, window, menu = system.addWindow(GUI.titledWindow(1, 1, 90, 25, "Terminal", true))

local localization = system.getCurrentScriptLocalization()

local lines = {
	{
		text = (computer.getArchitecture and computer.getArchitecture() or "Lua 5.2") .. " Copyright (C) 1994-2019 Lua.org, PUC-Rio",
		color = 0x969696,
	}
}

local textBox = window:addChild(GUI.textBox(2, 2, 1, 1, nil, 0x3C3C3C, lines, 1, 0, 0))
textBox.passScreenEvents = true

local input = window:addChild(GUI.input(1, 1, 1, 3, 0xE1E1E1, 0x2D2D2D, 0x969696, 0xE1E1E1, 0x2D2D2D, "", "Type statement here"))
input.historyEnabled = true
input.onInputFinished = function()
	

	input.text = ""
end

window.onResize = function(width, height)
	window.backgroundPanel.width, window.backgroundPanel.height = width, height
	textBox.width, textBox.height = width - 2, height - 4
	input.localY, input.width = height - input.height + 1, width
end


---------------------------------------------------------------------------------

window.actionButtons:moveToFront()
window:resize(window.width, window.height)
workspace:draw()
