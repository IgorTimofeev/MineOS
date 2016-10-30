
package.loaded.rayEngine, package.loaded.GUI, package.loaded.windows, _G.rayEngine, _G.GUI, _G.windows = nil, nil, nil, nil, nil, nil, nil, nil

local libraries = {
	component = "component",
	buffer = "doubleBuffering",
	GUI = "GUI",
	windows = "windows",
	rayEngine = "rayEngine",
	MineOSCore = "MineOSCore",
	unicode = "unicode",
	event = "event",
}

for library in pairs(libraries) do if not _G[library] then _G[library] = require(libraries[library]) end end; libraries = nil

----------------------------------------------------------------------------------------------------------------------------------

local applicationResourcesDirectory = MineOSCore.getCurrentApplicationResourcesDirectory()
local localization = MineOSCore.getLocalization(applicationResourcesDirectory .. "Localization/")
local worldsPath = applicationResourcesDirectory .. "Worlds/"
local rayWalkVersion = "RayWalk Tech Demo v3.4"

----------------------------------------------------------------------------------------------------------------------------------

local function menuBackground()
	rayEngine.drawWorld()
	buffer.clear(0x000000, 50)
end

local function settings()
	local window = windows.empty(1, 1, buffer.screen.width, buffer.screen.height, buffer.screen.width, buffer.screen.height)
	window.onDrawStarted = menuBackground

	local sliderWidth, textBoxWidth = 43, 19
	local x, y = math.floor(window.width / 2 - sliderWidth / 2), math.floor(window.height / 2 - 19)

	window:addLabel("settingsLabel", 1, y, window.width, 1, 0xFFFFFF, localization.rayEngineProperties):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top); y = y + 3

	local resolutionTextBoxWidth = window:addInputTextBox("resolutionTextBoxWidth", x, y, textBoxWidth, 3, 0x262626, 0xBBBBBB, 0x262626, 0xFFFFFF, buffer.screen.width, nil, nil, true)
	window:addLabel("resolutionCrossLabel", x + textBoxWidth + 2, y + 1, 1, 1, 0xFFFFFF, "X")
	local resolutionTextBoxHeight = window:addInputTextBox("resolutionTextBoxHeight",  x + textBoxWidth + 5, y, textBoxWidth, 3, 0x262626, 0xBBBBBB, 0x262626, 0xFFFFFF, buffer.screen.height, nil, nil, true); y = y + 4
	window:addLabel("resolutionLabel", 1, y, window.width, 1, 0xDDDDDD, localization.screenResolution):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top); y = y + 3
	resolutionTextBoxWidth.validator = function(text) local num = tonumber(text); if num and num >= 40 and num <= 160 then return true end end
	resolutionTextBoxHeight.validator = function(text) local num = tonumber(text); if num and num >= 12 and num <= 50 then return true end end
	local function onAnyResolutionTextBoxInputFinished() window:close(); rayEngine.changeResolution(tonumber(resolutionTextBoxWidth.text), tonumber(resolutionTextBoxHeight.text)); settings() end
	resolutionTextBoxWidth.onInputFinished = onAnyResolutionTextBoxInputFinished
	resolutionTextBoxHeight.onInputFinished = onAnyResolutionTextBoxInputFinished

	local drawDistanceSlider = window:addHorizontalSlider("drawDistanceSlider", x, y, sliderWidth, 0xFFDB80, 0x000000, 0xFFDB40, 0xDDDDDD, 100, 5000, rayEngine.properties.drawDistance, true, localization.drawDistance)
	drawDistanceSlider.onValueChanged = function()
		rayEngine.properties.drawDistance = drawDistanceSlider.value
		window:draw()
		buffer:draw()
	end; y = y + 4
	
	local shadingDistanceSlider = window:addHorizontalSlider("shadingDistanceSlider", x, y, sliderWidth, 0xFFDB80, 0x000000, 0xFFDB40, 0xDDDDDD, 100, 3000, rayEngine.properties.shadingDistance, true, localization.shadingDistance)
	shadingDistanceSlider.onValueChanged = function()
		rayEngine.properties.shadingDistance = shadingDistanceSlider.value
		window:draw()
		buffer:draw()
	end; y = y + 4
	
	local shadingCascadesSlider = window:addHorizontalSlider("shadingCascadesSlider", x, y, sliderWidth, 0xFFDB80, 0x000000, 0xFFDB40, 0xDDDDDD, 2, 48, rayEngine.properties.shadingCascades, true, localization.shadingCascades)
	shadingCascadesSlider.onValueChanged = function()
		rayEngine.properties.shadingCascades = shadingCascadesSlider.value
		window:draw()
		buffer:draw()
	end; y = y + 4

	local raycastQualitySlider = window:addHorizontalSlider("raycastQualitySlider", x, y, sliderWidth, 0xFFDB80, 0x000000, 0xFFDB40, 0xDDDDDD, 0.5, 32, rayEngine.properties.raycastQuality, true, localization.raycastQuality)
	raycastQualitySlider.onValueChanged = function()
		rayEngine.properties.raycastQuality = raycastQualitySlider.value
		window:draw()
		buffer:draw()
	end; y = y + 4

	local currentTimeSlider = window:addHorizontalSlider("currentTimeSlider", x, y, sliderWidth, rayEngine.world.colors.sky.current, 0x000000, rayEngine.world.colors.sky.current, 0xDDDDDD, 0, rayEngine.world.dayNightCycle.length, rayEngine.world.dayNightCycle.currentTime, true, localization.dayNightCycle, localization.seconds)
	currentTimeSlider.onValueChanged = function()
		rayEngine.world.dayNightCycle.currentTime = currentTimeSlider.value
		rayEngine.refreshTimeDependentColors()
		currentTimeSlider.colors.active = rayEngine.world.colors.sky.current
		currentTimeSlider.colors.pipe = rayEngine.world.colors.sky.current
		window:draw()
		buffer:draw()
	end; y = y + 4

	window:addLabel("graphonLabel", x, y, sliderWidth, 1, 0xDDDDDD, localization.enableSemipixelRenderer)
	
	local graphonSwitch = window:addSwitch("graphonSwitch", x + sliderWidth - 8, y, 8, 0xFFDB40, 0xAAAAAA, 0xFFFFFF, not rayEngine.properties.useSimpleRenderer)
	graphonSwitch.onStateChanged = function()
		rayEngine.properties.useSimpleRenderer = not graphonSwith.state
		window:draw()
		buffer:draw()
	end; y = y + 3

	window:addLabel("lockTimeLabel", x, y, sliderWidth, 1, 0xDDDDDD, localization.enableDayNightCycle)
	
	local lockTimeSwitch = window:addSwitch("lockTimeSwitch", x + sliderWidth - 8, y, 8, 0xFFDB40, 0xAAAAAA, 0xFFFFFF, rayEngine.world.dayNightCycle.enabled)
	lockTimeSwitch.onStateChanged = function()
		rayEngine.world.dayNightCycle.enabled = lockTimeSwitch.state
		window:draw()
		buffer:draw()
	end; y = y + 3

	window:addButton("resumeButton", x, y, sliderWidth, 3, 0xEEEEEE, 0x262626, 0xBBBBBB, 0x262626, localization.continue).onTouch = function() window:close(); table.toFile(applicationResourcesDirectory .. "RayEngine.cfg", rayEngine.properties, true) end

	window:draw(); buffer.draw(); window:handleEvents()
end

local function menu()
	local window = windows.empty(1, 1, buffer.screen.width, buffer.screen.height, buffer.screen.width, buffer.screen.height)
	window.onDrawStarted = menuBackground

	local buttonWidth, buttonHeight = 50, 3
	local worlds = {}
	for file in fs.list(worldsPath) do table.insert(worlds, unicode.sub(file, 1, -2)) end
	local x, y = math.floor(window.width / 2 - buttonWidth / 2), math.floor(window.height / 2 - #worlds * (buttonHeight + 1) / 2 - 11)
	
	window:addLabel("versionLabel", 1, y, window.width, 1, 0xFFFFFF, rayWalkVersion):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top); y = y + 3
	window:addButton("resumeButton", x, y, buttonWidth, buttonHeight, 0xEEEEEE, 0x262626, 0xBBBBBB, 0x262626, localization.continue).onTouch = function() window:close()	end; y = y + buttonHeight + 1
	window:addButton("settingsButton", x, y, buttonWidth, buttonHeight, 0xEEEEEE, 0x262626, 0xBBBBBB, 0x262626, localization.settings).onTouch = function() window:close(); settings() end; y = y + buttonHeight + 1
	window:addButton("exitButton", x, y, buttonWidth, buttonHeight, 0xEEEEEE, 0x262626, 0x999999, 0x262626, localization.exit).onTouch = function() buffer.clear(0x000000); buffer.draw(); os.exit()	end; y = y + buttonHeight + 1
	window:addLabel("loadWorldLabel", 1, y, window.width, 1, 0xFFFFFF, localization.loadWorld):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top); y = y + 2

	for i = 1, #worlds do
		window:addButton("worldButton" .. i, x, y, buttonWidth, buttonHeight, 0xEEEEEE, 0x262626, 0xBBBBBB, 0x262626, worlds[i]).onTouch = function() rayEngine.loadWorld(worldsPath .. worlds[i]); window:close() end
		y = y + buttonHeight + 1
	end

	local lines = localization.controlsHelp
	table.insert(lines, 1, " ")
	table.insert(lines, 1, {text = localization.controls, color = 0xFFFFFF})
	window:addTextBox("informationTextBox", 1, y, window.width, #lines, nil, 0xDDDDDD, lines, 1):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top); y = y + #lines + 1

	window:draw(); buffer.draw(); window:handleEvents()
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
rayEngine.intro()
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