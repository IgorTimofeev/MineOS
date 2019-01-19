
local filesystem = require("Filesystem")
local screen = require("Screen")
local GUI = require("GUI")
local system = require("System")
local event = require("Event")

----------------------------------------------------------------------------------------------------------------------------------

local applicationResourcesDirectory = filesystem.path(system.getCurrentScript())
local localization = system.getLocalization(applicationResourcesDirectory .. "Localizations/")
local worldsPath = applicationResourcesDirectory .. "Worlds/"
local rayWalkVersion = "RayWalk Tech Demo v3.5"

local rayEngine = dofile(applicationResourcesDirectory .. "RayEngine.lua")

----------------------------------------------------------------------------------------------------------------------------------

local function menuBackground()
	rayEngine.drawWorld()
	screen.clear(0x000000, 0.5)
end

local function settings()
	local window = GUI.workspace()
	local oldDraw = window.draw
	window.draw = function()
		menuBackground()
		oldDraw(window)
	end

	local sliderWidth, textBoxWidth = 43, 19
	local x, y = math.floor(window.width / 2 - sliderWidth / 2), math.floor(window.height / 2 - 19)

	window:addChild(GUI.label(1, y, window.width, 1, 0xFFFFFF, localization.rayEngineProperties)):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP); y = y + 3

	local resolutionTextBoxWidth = window:addChild(GUI.input(x, y, textBoxWidth, 3, 0x262626, 0xBBBBBB, 0xBBBBBB, 0x262626, 0xFFFFFF, tostring(screen.getWidth()), nil, true))
	window:addChild(GUI.label(x + textBoxWidth + 2, y + 1, 1, 1, 0xFFFFFF, "X"))
	local resolutionTextBoxHeight = window:addChild(GUI.input(x + textBoxWidth + 5, y, textBoxWidth, 3, 0x262626, 0xBBBBBB, 0xBBBBBB, 0x262626, 0xFFFFFF, tostring(screen.getHeight()), nil, true)); y = y + 4
	window:addChild(GUI.label(1, y, window.width, 1, 0xDDDDDD, localization.screenResolution)):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP); y = y + 3
	resolutionTextBoxWidth.validator = function(text) local num = tonumber(text); if num and num >= 40 and num <= 160 then return true end end
	resolutionTextBoxHeight.validator = function(text) local num = tonumber(text); if num and num >= 12 and num <= 50 then return true end end
	local function onAnyResolutionTextBoxInputFinished()
		window:stop()
		rayEngine.changeResolution(tonumber(resolutionTextBoxWidth.text), tonumber(resolutionTextBoxHeight.text))
		settings()
	end
	resolutionTextBoxWidth.onInputFinished = onAnyResolutionTextBoxInputFinished
	resolutionTextBoxHeight.onInputFinished = onAnyResolutionTextBoxInputFinished

	local drawDistanceSlider = window:addChild(GUI.slider(x, y, sliderWidth, 0xFFDB80, 0x000000, 0xFFDB40, 0xDDDDDD, 100, 5000, rayEngine.properties.drawDistance, true, localization.drawDistance))
	drawDistanceSlider.onValueChanged = function()
		rayEngine.properties.drawDistance = drawDistanceSlider.value
		window:draw()
	end; y = y + 4
	
	local shadingDistanceSlider = window:addChild(GUI.slider(x, y, sliderWidth, 0xFFDB80, 0x000000, 0xFFDB40, 0xDDDDDD, 100, 3000, rayEngine.properties.shadingDistance, true, localization.shadingDistance))
	shadingDistanceSlider.onValueChanged = function()
		rayEngine.properties.shadingDistance = shadingDistanceSlider.value
		window:draw()
	end; y = y + 4
	
	local shadingCascadesSlider = window:addChild(GUI.slider(x, y, sliderWidth, 0xFFDB80, 0x000000, 0xFFDB40, 0xDDDDDD, 2, 48, rayEngine.properties.shadingCascades, true, localization.shadingCascades))
	shadingCascadesSlider.onValueChanged = function()
		rayEngine.properties.shadingCascades = shadingCascadesSlider.value
		window:draw()
	end; y = y + 4

	local raycastQualitySlider = window:addChild(GUI.slider(x, y, sliderWidth, 0xFFDB80, 0x000000, 0xFFDB40, 0xDDDDDD, 0.5, 32, rayEngine.properties.raycastQuality, true, localization.raycastQuality))
	raycastQualitySlider.onValueChanged = function()
		rayEngine.properties.raycastQuality = raycastQualitySlider.value
		window:draw()
	end; y = y + 4

	local currentTimeSlider = window:addChild(GUI.slider(x, y, sliderWidth, rayEngine.world.colors.sky.current, 0x000000, rayEngine.world.colors.sky.current, 0xDDDDDD, 0, rayEngine.world.dayNightCycle.length, rayEngine.world.dayNightCycle.currentTime, true, localization.dayNightCycle, localization.seconds))
	currentTimeSlider.onValueChanged = function()
		rayEngine.world.dayNightCycle.currentTime = currentTimeSlider.value
		rayEngine.refreshTimeDependentColors()
		currentTimeSlider.colors.active = rayEngine.world.colors.sky.current
		currentTimeSlider.colors.pipe = rayEngine.world.colors.sky.current
		window:draw()
	end; y = y + 4

	window:addChild(GUI.label(x, y, sliderWidth, 1, 0xDDDDDD, localization.enableSemipixelRenderer))
	
	local graphonSwitch = window:addChild(GUI.switch(x + sliderWidth - 8, y, 8, 0xFFDB40, 0xAAAAAA, 0xFFFFFF, not rayEngine.properties.useSimpleRenderer))
	graphonSwitch.onStateChanged = function()
		rayEngine.properties.useSimpleRenderer = not graphonSwitch.state
		window:draw()
	end; y = y + 3

	window:addChild(GUI.label(x, y, sliderWidth, 1, 0xDDDDDD, localization.enableDayNightCycle))
	
	local lockTimeSwitch = window:addChild(GUI.switch(x + sliderWidth - 8, y, 8, 0xFFDB40, 0xAAAAAA, 0xFFFFFF, rayEngine.world.dayNightCycle.enabled))
	lockTimeSwitch.onStateChanged = function()
		rayEngine.world.dayNightCycle.enabled = lockTimeSwitch.state
		window:draw()
	end; y = y + 3

	window:addChild(GUI.button(x, y, sliderWidth, 3, 0xEEEEEE, 0x262626, 0xBBBBBB, 0x262626, localization.continue)).onTouch = function() window:stop(); filesystem.writeTable(applicationResourcesDirectory .. "RayEngine.cfg", rayEngine.properties, true) end

	window:draw()
	window:start()
end

local function menu()
	local window = GUI.workspace()
	local oldDraw = window.draw
	window.draw = function()
		menuBackground()
		oldDraw(window)
	end

	local buttonWidth, buttonHeight = 50, 3
	local worlds = filesystem.list(worldsPath)
	for i = 1, #worlds do
		worlds[i] = unicode.sub(worlds[i], 1, -2)
	end

	local x, y = math.floor(window.width / 2 - buttonWidth / 2), math.floor(window.height / 2 - #worlds * (buttonHeight + 1) / 2 - 11)
	
	window:addChild(GUI.label(1, y, window.width, 1, 0xFFFFFF, rayWalkVersion)):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP); y = y + 3
	window:addChild(GUI.button(x, y, buttonWidth, buttonHeight, 0xEEEEEE, 0x262626, 0xBBBBBB, 0x262626, localization.continue)).onTouch = function() window:stop()	end; y = y + buttonHeight + 1
	window:addChild(GUI.button(x, y, buttonWidth, buttonHeight, 0xEEEEEE, 0x262626, 0xBBBBBB, 0x262626, localization.settings)).onTouch = function() window:stop(); settings() end; y = y + buttonHeight + 1
	window:addChild(GUI.button(x, y, buttonWidth, buttonHeight, 0xEEEEEE, 0x262626, 0x999999, 0x262626, localization.exit)).onTouch = function() screen.clear(0x000000); error("interrupted", 0) end; y = y + buttonHeight + 1
	window:addChild(GUI.label(1, y, window.width, 1, 0xFFFFFF, localization.loadWorld)):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP); y = y + 2

	for i = 1, #worlds do
		window:addChild(GUI.button(x, y, buttonWidth, buttonHeight, 0xEEEEEE, 0x262626, 0xBBBBBB, 0x262626, worlds[i])).onTouch = function() rayEngine.loadWorld(worldsPath .. worlds[i]); window:stop() end
		y = y + buttonHeight + 1
	end

	local lines = {}; for i = 1, #localization.controlsHelp do table.insert(lines, localization.controlsHelp[i]) end
	table.insert(lines, 1, " ")
	table.insert(lines, 1, {text = localization.controls, color = 0xFFFFFF})
	window:addChild(GUI.textBox(1, y, window.width, #lines, nil, 0xCCCCCC, lines, 1):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)); y = y + #lines + 1

	window:draw()
	window:start()
end


----------------------------------------------------------------------------------------------------------------------------------

local controls = {
	["key_down"] =  {
		[16] = rayEngine.turnLeft, --q
		[18] = rayEngine.turnRight, --e
		[30] = rayEngine.moveLeft, --a
		[32] = rayEngine.moveRight, --d
		[17] = rayEngine.moveForward, --w
		[31] = rayEngine.moveBackward, --s
		[50] = rayEngine.toggleMinimap, --m
		[37] = rayEngine.toggleCompass, --k
		[25] = rayEngine.toggleWatch, --p
		[14] = menu, --backspace
		[28] = rayEngine.commandLine, --enter
		[57] = rayEngine.jump, --space
		[29] = rayEngine.crouch, --ctrl
		[59] = rayEngine.toggleDebugInformation, -- F1
	},
	["key_up"] = {
		[29] = rayEngine.crouch, --ctrl
	},
}

--------------------------------------------------------------------------------------------------------------

rayEngine.loadEngineProperties(applicationResourcesDirectory .. "RayEngine.cfg")
rayEngine.loadWeapons(applicationResourcesDirectory .. "Weapons/")
rayEngine.loadWorld(worldsPath .. "ExampleWorld")
rayEngine.changeResolution(rayEngine.properties.screenResolution.width, rayEngine.properties.screenResolution.height)
-- rayEngine.intro()
menu()
rayEngine.update()

while true do
	local e = { event.pull(1) }
	if e[1] == "touch" then
		if e[5] == 1 then 
			if not rayEngine.currentWeapon then rayEngine.place(3, 0x3) end
		else
			if rayEngine.currentWeapon then rayEngine.fire() else rayEngine.destroy(3) end
		end
	elseif e[1] == "key_down" then
		if e[4] > 1 and e[4] < 10 then
			rayEngine.changeWeapon(e[4] - 2)
		else
			if controls[e[1]] and controls[e[1]][e[4]] then controls[e[1]][e[4]]() end
		end
	elseif e[1] == "key_up" then
		if controls[e[1]] and controls[e[1]][e[4]] then controls[e[1]][e[4]]() end
	end
	rayEngine.update()
end