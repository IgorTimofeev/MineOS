
local fs = require("filesystem")
local advancedLua = require("advancedLua")
local buffer = require("doubleBuffering")
local GUI = require("GUI")
local windows = require("windows")
local MineOSCore = require("MineOSCore")
local event = require("event")
local unicode = require("unicode")

-----------------------------------------------------------------------------------------------------------------------------

local window = {}

-----------------------------------------------------------------------------------------------------------------------------

local function loadModule(moduleID)
	if fs.exists(window.modules[moduleID].path) then
		local success, reason = dofile(window.modules[moduleID].path)
		if success then
			window.modules[moduleID].module = success
			window.modules[moduleID].module.execute(window)
		else
			error("Error due module execution: " .. reason)
		end
	else
		error("Mudule file \"" .. window.modules[moduleID].path "\" doesn't exists")
	end
end

local function createWindow()
	window = windows.empty("auto", "auto", math.floor(buffer.screen.width * 0.8), math.floor(buffer.screen.height * 0.7), 78, 24)
	window:addPanel(1, 1, window.width, window.height, 0xEEEEEE).disabled = true
	window.tabBar = window:addTabBar(1, 1, window.width, 3, 1, 0xDDDDDD, 0x262626, 0xCCCCCC, 0x262626, "Интерпретатор Lua", "События", "Память", "Диски", "BIOS")
	window.tabBar.onTabSwitched = function(object, eventData)
		
	end
	window:addWindowActionButtons(2, 1, false).close.onTouch = function()
		window:close()
	end
	window.drawingArea = window:addContainer(1, 4, window.width, window.height - 3, 0xEEEEEE)
	
	window.resourcesPath = MineOSCore.getCurrentApplicationResourcesDirectory()
	window.modules = {}
	for file in fs.list(window.resourcesPath .. "Modules/") do
		table.insert(window.modules, {
			path = window.resourcesPath .. "Modules/" .. file
		})
	end
end

-----------------------------------------------------------------------------------------------------------------------------

createWindow()
loadModule(1)
window.drawShadow = true
window:draw()
buffer.draw()
window.drawShadow = false
window:handleEvents()


