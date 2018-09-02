
local component = require("component")
local sides = require("sides")
local robot = require("robot")
local event = require("event")
local serialization = require("serialization")

local inventory_controller = component.inventory_controller

local QUAD_FUEL = "IC2:reactorMOXQuad"
local DIAM_VENT = "IC2:reactorVentDiamond"
local IRON_VENT = "IC2:reactorVentSpread"
local STON_VENT = "IC2:reactorVent"
local GOLD_VENT = "IC2:reactorHeatSwitchSpread"
local RCTR_PLAT = "IC2:reactorPlating"

local allowed = {
	[QUAD_FUEL] = true,
	[DIAM_VENT] = true,
	[IRON_VENT] = true,
	[STON_VENT] = true,
	[GOLD_VENT] = true,
	[RCTR_PLAT] = true,
}

local map = {
	DIAM_VENT, GOLD_VENT, DIAM_VENT, IRON_VENT, RCTR_PLAT, IRON_VENT, DIAM_VENT, GOLD_VENT, DIAM_VENT,
	IRON_VENT, DIAM_VENT, QUAD_FUEL, DIAM_VENT, IRON_VENT, DIAM_VENT, QUAD_FUEL, DIAM_VENT, IRON_VENT,
	STON_VENT, IRON_VENT, DIAM_VENT, IRON_VENT, DIAM_VENT, IRON_VENT, DIAM_VENT, IRON_VENT, STON_VENT,
	GOLD_VENT, DIAM_VENT, IRON_VENT, DIAM_VENT, QUAD_FUEL, DIAM_VENT, IRON_VENT, DIAM_VENT, GOLD_VENT,
	DIAM_VENT, QUAD_FUEL, DIAM_VENT, IRON_VENT, DIAM_VENT, IRON_VENT, DIAM_VENT, QUAD_FUEL, DIAM_VENT,
	IRON_VENT, DIAM_VENT, GOLD_VENT, STON_VENT, IRON_VENT, STON_VENT, GOLD_VENT, DIAM_VENT, IRON_VENT,
}

local args = {...}

if args[1] == "fill" then
	print("Filling...")

	local filledMap = {}
	for robotSlot = 1, robot.inventorySize() do
		local stack = inventory_controller.getStackInInternalSlot(robotSlot)
		if stack and allowed[stack.name] then
			for mapSlot = 1, #map do
				if map[mapSlot] == stack.name and not filledMap[mapSlot] then
					robot.select(robotSlot)
					print("Drop status", inventory_controller.dropIntoSlot(sides.front, mapSlot, 1))
					filledMap[mapSlot] = true
					break
				end
			end
		end
	end
elseif args[1] == "count" then
	print("Checking...")

	local need, have = {}, {}
	for i = 1, #map do
		need[map[i]] = (need[map[i]] or 0) + 1
	end

	for i = 1, robot.inventorySize() do
		local stack = inventory_controller.getStackInInternalSlot(i)
		if stack and allowed[stack.name] then
			have[stack.name] = (have[stack.name] or 0) + stack.size
		end
	end

	for key, value in pairs(need) do
		local name = key:sub(12, -1)

		if have[key] then
			if have[key] < value then
				print(name .. ": put " .. (value - (have[key] or 0)))
			else
				print(name .. ": OK, over " .. (have[key] - value))
			end
		else
			print(name .. ": put " .. value)
		end
	end
end





