
require("advancedLua")
local component = require("component")
local computer = require("computer")
local image = require("image")
local buffer = require("doubleBuffering")
local GUI = require("GUI")
local fs = require("filesystem")
local unicode = require("unicode")
local MineOSPaths = require("MineOSPaths")
local MineOSCore = require("MineOSCore")
local MineOSInterface = require("MineOSInterface")

----------------------------------------------------------------------------------------------------------------

local resourcesPath = MineOSCore.getCurrentScriptDirectory()
local modulesPath = resourcesPath .. "Modules/"
local localization = MineOSCore.getLocalization(resourcesPath .. "Localizations/")

local application, window = MineOSInterface.addWindow(GUI.tabbedWindow(1, 1, 80, 25))

----------------------------------------------------------------------------------------------------------------

window.contentContainer = window:addChild(GUI.container(1, 4, window.width, window.height - 3))

local function loadModules()
	local fileList = fs.sortedList(modulesPath, "name", false)
	for i = 1, #fileList do
		local loadedFile, reason = loadfile(modulesPath .. fileList[i])
		if loadedFile then
			local pcallSuccess, reason = pcall(loadedFile, application, window, localization)
			if pcallSuccess then
				window.tabBar:addItem(reason.name).onTouch = function()
					reason.onTouch()
					MineOSInterface.application:draw()
				end
			else
				error("Failed to call loaded module \"" .. tostring(fileList[i]) .. "\": " .. tostring(reason))
			end
		else
			error("Failed to load module \"" .. tostring(fileList[i]) .. "\": " .. tostring(reason))
		end
	end
end

window.onResize = function(width, height)
	window.tabBar.width = width
	window.backgroundPanel.width = width
	window.backgroundPanel.height = height - 3
	window.contentContainer.width = width
	window.contentContainer.height = window.backgroundPanel.height

	window.tabBar:getItem(window.tabBar.selectedItem).onTouch()
end

----------------------------------------------------------------------------------------------------------------

loadModules()
window.onResize(80, 25)


