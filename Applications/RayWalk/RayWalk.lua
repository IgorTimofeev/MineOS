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
local minimapEnabled, compassEnabled, isCrouch, isJump = true, false, false, false
local jumpHeight, crouchHeight = 10, 10

----------------------------------------------------------------------------------------------------------------------------------

local function update()
	rayEngine.drawWorld()
	if minimapEnabled then rayEngine.drawMap(2, 2, 25, 13, 50) end
	if compassEnabled then rayEngine.compass(2, buffer.screen.height - 26) end
	--rayEngine.drawWeapon()
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

----------------------------------------------------------------------------------------------------------------------------------

local function jumpTimerDone()
	rayEngine.horizontHeight = rayEngine.horizontHeight - jumpHeight
	rayEngine.modifer = rayEngine.modifer - jumpHeight
	jumpTimer = nil
end

local function inJump()
	if not jumpTimer then
		jumpTimer = event.timer(1, jumpTimerDone)
		rayEngine.modifer = rayEngine.modifer + jumpHeight
		rayEngine.horizontHeight = rayEngine.horizontHeight + jumpHeight
	end
end

local function crouch()
	isCrouch = not isCrouch
	local heightAdder = isCrouch and -crouchHeight or crouchHeight
	rayEngine.modifer = rayEngine.modifer + heightAdder
	rayEngine.horizontHeight = rayEngine.horizontHeight + heightAdder
end

-- default control --
local function turnLeft()
	rayEngine.rotate(-4)
end

local function turnRight()
	rayEngine.rotate(4)
end

local function moveForward()
	rayEngine.move(16, 0)
end

local function moveBackward()
	rayEngine.move(-16, 0)
end

local function moveLeft()
	rayEngine.move(0, -16)
end

local function moveRight()
	rayEngine.move(0, 16)
end

local function minimapSwitch()
	minimapEnabled = not minimapEnabled
end

local function compassSwitch()
	compassEnabled = not compassEnabled
end

local controls = {
	["key_down"] =  {
		[57] = inJump, --space
		[29] = crouch, --ctrl
		[16] = turnLeft, --q
		[18] = turnRight, --e
		[30] = moveLeft, --a
		[32] = moveRight, --d
		[17] = moveForward, --w
		[31] = moveBackward, --s
		[50] = minimapSwitch, --m
		[14] = menu, --backspace
		[28] = menu, --enter
		[37] = compassSwitch,
	},
	["key_up"] = {
		[57] = outJump, --space
		[29] = outCrouch, --ctrl
	},
}

--------------------------------------------------------------------------------------------------------------

buffer.start()
-- rayEngine.intro()
rayEngine.loadWorld(worldsPath .. "ExampleWorld")
menu()
update()

while (true) do
	local e = { event.pull(1) }

	if ( e[1] ) then
		if e[1] == "touch" then
			if e[5] == 1 then rayEngine.place(3) else rayEngine.destroy(3) end
		else
			if controls[e[1]] and controls[e[1]][e[4]] then controls[e[1]][e[4]]() end
		end
	end

	update()
end