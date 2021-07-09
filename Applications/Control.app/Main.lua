
local image = require("Image")
local screen = require("Screen")
local GUI = require("GUI")
local filesystem = require("Filesystem")
local paths = require("Paths")
local system = require("System")

----------------------------------------------------------------------------------------------------------------

local currentScriptDirectory = filesystem.path(system.getCurrentScript())
local modulesPath = currentScriptDirectory .. "Modules/"
local localization = system.getLocalization(currentScriptDirectory .. "Localizations/")

local workspace, window = system.addWindow(GUI.tabbedWindow(1, 1, 80, 25))

----------------------------------------------------------------------------------------------------------------

window.contentContainer = window:addChild(GUI.container(1, 4, window.width, window.height - 3))

local function loadModules()
	local fileList = filesystem.list(modulesPath)
	for i = 1, #fileList do
		if filesystem.extension(fileList[i]) == ".lua" then
			local loadedFile, reason = loadfile(modulesPath .. fileList[i])
			if loadedFile then
				local pcallSuccess, reason = pcall(loadedFile, workspace, window, localization)
				if pcallSuccess then
					window.tabBar:addItem(reason.name).onTouch = function()
						reason.onTouch()
						workspace:draw()
					end
				else
					error("Failed to call loaded module \"" .. tostring(fileList[i]) .. "\": " .. tostring(reason))
				end
			else
				error("Failed to load module \"" .. tostring(fileList[i]) .. "\": " .. tostring(reason))
			end
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


