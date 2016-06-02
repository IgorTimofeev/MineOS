local libraries = {
	buffer = "doubleBuffering",
	rayEngine = "rayEngine",
	GUI = "GUI",
	event = "event",
}

for library in pairs(libraries) do if not _G[library] then _G[library] = require(libraries[library]) end end; libraries = nil
local scenesPath = "MineOS/Applications/RayWalk.app/Resources/"

----------------------------------------------------------------------------------------------------------------------------------

local function update()
	rayEngine.drawScene()
	rayEngine.drawMap(2, 2, 25, 13, 50)
	buffer.draw()
end

local function menu()
	local buttonWidth = 50
	local buttons = {"Day.scene", "Night.scene", "Выход"}
	local x, y = math.floor(buffer.screen.width / 2 - buttonWidth / 2), math.floor(buffer.screen.height / 2 - (#buttons * 4) / 2)
	local buttonData = {}; for i = 1, #buttons do table.insert(buttonData, {GUI.buttonTypes.default, buttonWidth, 3, 0xDDDDDD, 0x555555, 0xBBBBBB, 0x262626, buttons[i]}) end
		
	rayEngine.drawScene()
	buffer.clear(0x000000, 50)
	buttons = GUI.buttons(x, y, GUI.directions.vertical, 1, table.unpack(buttonData))
	buffer.draw()

	while true do
		local e = {event.pull("touch")}
		for _, button in pairs(buttons) do
			if button:isClicked(e[3], e[4]) then
				button:press()
				if button.text == "Выход" then
					os.exit()
				else
					rayEngine.loadSceneFromFile(scenesPath .. button.text)
					return
				end
				break
			end
		end
	end
end

buffer.start()
rayEngine.loadSceneFromFile(scenesPath .. "Day.scene")
rayEngine.intro()
menu()
update()

while (true) do
	local e = { event.pull("key_down") }

	if ( e[4] == 30 ) then --a
		rayEngine.rotate(-4)
	elseif ( e[4] == 32 ) then --d
		rayEngine.rotate(4)
	elseif ( e[4] == 17 ) then --w
		rayEngine.move(16)
	elseif ( e[4] == 31 ) then --s
		rayEngine.move(-16)
	elseif ( e[4] == 14 or e[4] == 28 ) then --r
		menu()
	end

	update()
end