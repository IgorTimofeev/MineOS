local component  = require "component"
local computer   = require "computer"
local filesystem = require "filesystem"
local shell      = require "shell"
--local s = require "serialization"

local system_utils

local function getAllHDD()
	local args, options = shell.parse(threedot)

	local candidates = {}
	for address in component.list("filesystem", true) do
	  local dev = component.proxy(address)
	  if not dev.isReadOnly() and dev.address ~= computer.tmpAddress() then
	    table.insert(candidates, dev)
	  end
	end

	return candidates
end

--Check system requirements
local function checkMemory(require_memory)
	local MEMORY_MATCH = true

	local totalMemory = computer.totalMemory()
	if ( totalMemory >= require_memory) then
		return MEMORY_MATCH, totalMemory
	end

	return not MEMORY_MATCH, totalMemory
end

local function checkHDD(require_hdd_size)
	local HDD_SIZE_MATCH = true

	local hdds = getAllHDD()
	local totalHDDSize = 0
	for i = 1, #hdds do
		totalHDDSize = totalHDDSize + hdds[i].spaceTotal()
	end

	if ( totalHDDSize >= require_hdd_size ) then
		return HDD_SIZE_MATCH, totalHDDSize
	end

	return not HDD_SIZE_MATCH, totalHDDSize
end

local function checkGpuTier(address, tier)
	local GPU_TIER_LIST = {
		[1] = 1,
		[4] = 2,
		[8] = 3
	}

	local componentProxy = component.proxy(address)
	if ( GPU_TIER_LIST[componentProxy.maxDepth()] >= tier ) then
		return true
	end

	return false
end

local function checkScreenTier(address, tier)
	local SCREEN_TIER_LIST = {
		--[1] = 1, --Not really!
		[false] = 2,
		[true] = 3
	}

	local componentProxy = component.proxy(address)
	componentProxy.setPrecise(true)

	if ( SCREEN_TIER_LIST[ componentProxy.isPrecise() ] >= tier ) then
		componentProxy.setPrecise(false)
		return true
	end

	componentProxy.setPrecise(false)
	return false
end

local function checkHologramTier(address, tier)
	local HOLOGRAM_TIER_LIST = {
		[1] = 1,
		[2] = 2
	}

	local componentProxy = component.proxy(address)

	if ( HOLOGRAM_TIER_LIST[ componentProxy.maxDepth() ] >= tier ) then
		return true
	end

	return false
end

local LEVELED_COMPONENTS = {
	["gpu"] = checkGpuTier,
	["screen"] = checkScreenTier,
	["hologram"] = checkHologramTier
}

local function checkRequirementComponent(all_components, component_type, count, tier)
	local COMPONENTS_MATCH = true

	local aviableComponentCount = 0
	for address, componentType in pairs(all_components) do
		if ( componentType == component_type ) then
			local checkTierFunction = LEVELED_COMPONENTS[component_type]
			if ( checkTierFunction == nil or checkTierFunction(address, tier) ) then
				aviableComponentCount = aviableComponentCount + 1
			end
		end
	end

	if (aviableComponentCount >= count) then
		return COMPONENTS_MATCH, aviableComponentCount
	end

	return not COMPONENTS_MATCH, aviableComponentCount
end

function system_utils.checkSystemRequirements(system_requirements_list)
	local allAviableComponents = component.list()
	local report = {}
	local result = true
	for componentType, componentRequirements in pairs(system_requirements_list.requirementComponents) do
		report[componentType] = { checkRequirementComponent(allAviableComponents, componentType, componentRequirements.count, componentRequirements.tier) }
		result = result and report[componentType][1]
	end

	report["hdd_size"] = { checkHDD(system_requirements_list.requirementOthers.hdd_size) }
	report["memory_size"] = { checkMemory(system_requirements_list.requirementOthers.memory_size) }

	return result, report
end

return system_utils

--[[ Example
local list = {}
--Component type = { count, tier } 
list.requirementComponents = {
	["gpu"]      = {["count"] = 1, ["tier"] = 3},
	["internet"] = {["count"] = 1, ["tier"] = 0},
	["modem"]    = {["count"] = 1, ["tier"] = 0},
	["screen"]   = {["count"] = 1, ["tier"] = 3},
	["keyboard"] = {["count"] = 1, ["tier"] = 0},
	["hologram"] = {["count"] = 1, ["tier"] = 2}
}

list.requirementOthers = {
	["memory_size"] = 1048576,
	["hdd_size"]    = 2097152
}

local result, rList = checkSystemRequirements(list)
print( result, s.serialize(rList) )
]]
