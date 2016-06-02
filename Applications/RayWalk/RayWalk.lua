local libraries = {
	buffer = "doubleBuffering",
	rayEngine = "rayEngine",
}

for library in pairs(libraries) do if not _G[library] then _G[library] = require(libraries[library]) end end; libraries = nil

----------------------------------------------------------------------------------------------------------------------------------

local function update()
	rayEngine.drawScene()
	rayEngine.drawMap(2, 2, 25, 13, 50)
end

buffer.start()
rayEngine.loadSceneFromFile("MineOS/Applications/RayWalk.app/Resources/Scene1.level")
rayEngine.intro()
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
	elseif ( e[4] == 19 or e[4] == 28 ) then --r
		return
	end

	update()
end