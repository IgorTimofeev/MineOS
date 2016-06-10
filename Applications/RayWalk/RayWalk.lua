package.loaded.rayEngine = nil
_G.rayEngine = nil

local libraries = {
	buffer = "doubleBuffering",
	rayEngine = "rayEngine",
	GUI = "GUI",
	unicode = "unicode",
	event = "event",
}

for library in pairs(libraries) do if not _G[library] then _G[library] = require(libraries[library]) end end; libraries = nil
local worldsPath = "MineOS/Applications/RayWalk.app/Resources/Worlds/"
local minimapEnabled = true

----------------------------------------------------------------------------------------------------------------------------------

local function update()
	rayEngine.drawWorld()
	if minimapEnabled then rayEngine.drawMap(2, 2, 25, 13, 50) end
	buffer.draw()
end

local function menu()
	local buttonWidth = 50
	local buttons = {}
	for file in fs.list(worldsPath) do table.insert(buttons, unicode.sub(file, 1, -2)) end
	local x, y = math.floor(buffer.screen.width / 2 - buttonWidth / 2), math.floor(buffer.screen.height / 2 - ((#buttons + 1) * 4) / 2)
	local buttonData = {}; for i = 1, #buttons do table.insert(buttonData, {GUI.buttonTypes.default, buttonWidth, 3, 0xDDDDDD, 0x555555, 0xBBBBBB, 0x262626, buttons[i]}) end
	table.insert(buttonData, {GUI.buttonTypes.default, buttonWidth, 3, 0xBBBBBB, 0x262626, 0x999999, 0x262626, "Выход"})

	rayEngine.drawWorld()
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
					rayEngine.loadWorld(worldsPath .. button.text)
					return
				end
				break
			end
		end
	end
end

buffer.start()
-- rayEngine.intro()
rayEngine.loadWorld(worldsPath .. "ExampleWorld")
menu()
update()

local xDrag = 0
while (true) do
	local e = { event.pull(1) }
	if e[1] == "touch" then
		if e[5] == 1 then rayEngine.place(3) else rayEngine.destroy(3) end
	elseif e[1] == "key_down" then
		if ( e[4] == 30 ) then --a
			rayEngine.rotate(-4)
		elseif ( e[4] == 32 ) then --d
			rayEngine.rotate(4)
		elseif ( e[4] == 17 ) then --w
			rayEngine.move(16, 0)
		elseif ( e[4] == 31 ) then --s
			rayEngine.move(-16, 0)
		elseif ( e[4] == 14 or e[4] == 28 ) then --backspace, enter
			menu()
		elseif ( e[4] == 50 ) then
			minimapEnabled = not minimapEnabled
		end
	end

	update()
end