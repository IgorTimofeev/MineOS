local component = require("component")
local event = require("event")

local rad180 = math.rad(180)
local playerHitpointYOffset = 1.2
local shaftSingleExtensionValue = 0.5
local defaultShaftLength = 2

local turrets = {
	["4b1229f4-640c-4288-8055-3fc1d9761b4c"] = {
		x = -221.5,
		y = 75.5,
		z = 324.5
	},
	["c7646649-292c-49e5-8c4a-4549511cce87"] = {
		x = -220.5,
		y = 75.5,
		z = 324.5
	},
	["86a3b628-8f8b-42e5-b890-2ec6c2065d36"] = {
		x = -218.5,
		y = 75.5,
		z = 324.5
	},
	["bdb164ab-af71-4eb0-8fe0-cdd0fc40364e"] = {
		x = -216.5,
		y = 75.5,
		z = 324.5
	},
	["a03228e7-0041-4909-acb0-8f78d7ddfc24"] = {
		x = -215.5,
		y = 75.5,
		z = 324.5
	},
}
for address in pairs(turrets) do
	turrets[address].proxy = component.proxy(address)
	turrets[address].proxy.extendShaft(defaultShaftLength)
end

local scanners = {}
for address in component.list("os_entdetector") do
	table.insert(scanners, component.proxy(address))
end

while true do
	local entities = {}
	for i = 1, #scanners do
		local localEntities = scanners[i].scanPlayers(512)
		for j = 1, #localEntities do
			entities[localEntities[j].name] = localEntities[j]
		end
	end

	for name, data in pairs(entities) do
		for _, turret in pairs(turrets) do
			local dx = data.x - turret.x
			local dy = (data.y + playerHitpointYOffset) - (turret.y + turret.proxy.getShaftLength() * shaftSingleExtensionValue)
			local dz = data.z - turret.z

			turret.proxy.moveToRadians(
				dz > 0 and rad180 - math.atan(dx / dz) or -math.atan(dx / dz),
				dz > 0 and math.atan(dy / dz) or -math.atan(dy / dz)
			)		

			if turret.proxy.isReady() and turret.proxy.isOnTarget() then
				turret.proxy.fire()
			end
		end

		break
	end

	os.sleep(0.05)
end