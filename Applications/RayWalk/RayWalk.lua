package.loaded.rayEngine = nil
_G.rayEngine = nil

local libraries = {
	buffer = "doubleBuffering",
	rayEngine = "rayEngine",
	GUI = "GUI",
	ecs = "ECSAPI",
	unicode = "unicode",
	event = "event",
}

for library in pairs(libraries) do if not _G[library] then _G[library] = require(libraries[library]) end end; libraries = nil

----------------------------------------------------------------------------------------------------------------------------------

local applicationPath = "MineOS/Applications/RayWalk.app/Resources/"
local worldsPath = applicationPath .. "Worlds/"
local rayWalkVersion = "RayWalk v3.2 closed beta"

----------------------------------------------------------------------------------------------------------------------------------

local function menu()
	local buttonWidth, buttonHeight = 50, 3
	local selectWorldButtons, buttons = {}, {}
	for file in fs.list(worldsPath) do table.insert(selectWorldButtons, unicode.sub(file, 1, -2)) end
	local x, y = math.floor(buffer.screen.width / 2 - buttonWidth / 2), math.floor(buffer.screen.height / 2 - ((#selectWorldButtons + 3) * (buttonHeight + 1)) / 2)
	local buttonData = {}; for i = 1, #selectWorldButtons do table.insert(buttonData, {GUI.buttonTypes.default, buttonWidth, buttonHeight, 0xEEEEEE, 0x262626, 0xBBBBBB, 0x262626, selectWorldButtons[i]}) end

	rayEngine.drawWorld()
	buffer.clear(0x000000, 50)

	GUI.centeredText(GUI.alignment.verticalCenter, y, 0xFFFFFF, rayWalkVersion); y = y + 2
	buttons.resume = GUI.button(x, y, buttonWidth, buttonHeight, 0xEEEEEE, 0x262626, 0xBBBBBB, 0x262626, "Продолжить"); y = y + buttonHeight + 1
	buttons.quit = GUI.button(x, y, buttonWidth, buttonHeight, 0xEEEEEE, 0x262626, 0x999999, 0x262626, "Выход"); y = y + buttonHeight + 1
	GUI.centeredText(GUI.alignment.verticalCenter, y, 0xFFFFFF, "Загрузить мир"); y = y + 2
	selectWorldButtons = GUI.buttons(x, y, GUI.directions.vertical, 1, table.unpack(buttonData))

	buffer.draw()

	while true do
		local e = {event.pull("touch")}
		for _, button in pairs(selectWorldButtons) do
			if button:isClicked(e[3], e[4]) then
				button:press()
				rayEngine.loadWorld(worldsPath .. button.text)
				return
			end
		end

		if buttons.resume:isClicked(e[3], e[4]) then
			buttons.resume:press()
			return
		elseif buttons.quit:isClicked(e[3], e[4]) then
			buttons.quit:press()
			os.exit()
		end
	end
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
	},
	["key_up"] = {
		[29] = rayEngine.crouch, --ctrl
	},
}

--------------------------------------------------------------------------------------------------------------

buffer.start()
-- rayEngine.intro()
rayEngine.loadEngine(applicationPath .. "RayEngine.cfg")
rayEngine.loadWeapons(applicationPath .. "Weapons/")
rayEngine.loadWorld(worldsPath .. "ExampleWorld")
menu()
rayEngine.update()

while (true) do
	local e = { event.pull(1) }

	if ( e[1] ) then
		if e[1] == "touch" then
			if e[5] == 1 then 
				if not rayEngine.currentWeapon then rayEngine.place(3) end
			else
				if rayEngine.currentWeapon then rayEngine.fire() else rayEngine.destroy(3) end
			end
		else
			if e[4] > 1 and e[4] < 10 then
				rayEngine.changeWeapon(e[4] - 2)
			else
				if controls[e[1]] and controls[e[1]][e[4]] then controls[e[1]][e[4]]() end
			end
		end
	end

	rayEngine.update()
end