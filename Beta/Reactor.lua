local ecs = require("ECSAPI")
local components = require("component")


local function getInfoAboutReactors()
	local massiv = {}
	for component, address in pairs(components) do
		if component == "reactor_chamber" then
			table.insert(massiv, components.proxy(address))
		end
	end
end

local reactors = getInfoAboutReactors()

for i = 1, #reactors do
	print(reactors[i])
end