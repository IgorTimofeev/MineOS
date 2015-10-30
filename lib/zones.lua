
-----------------------------------------------------------------------------------------------------------------------------------------

if not _G.event then _G.event = require("event") end
if not _G.computer then _G.computer = require("computer") end
local zones = {}
zones.objects = {}

-----------------------------------------------------------------------------------------------------------------------------------------

local function listener(...)
	local eventData = { ... }
	local exit
	local zoneInfo
	if eventData[1] == "touch" then
		for program in pairs(zones.objects) do
			if exit then break end
			for class in pairs(zones.objects[program]) do
				if exit then break end
				for name in pairs(zones.objects[program][class]) do
					if exit then break end
					if
						eventData[3] >= zones.objects[program][class][name][1] and
						eventData[4] >= zones.objects[program][class][name][2] and
						eventData[3] <= zones.objects[program][class][name][3] and
						eventData[4] <= zones.objects[program][class][name][4]
					then
						zoneInfo = {}
						for i = 1, #zones.objects[program][class][name] do
							if zones.objects[program][class][name][i] then
								table.insert(zoneInfo, zones.objects[program][class][name][i])
							end
						end
						computer.pushSignal("zone", program, class, name, eventData[3], eventData[4], eventData[5], table.unpack(zoneInfo))
						exit = true
					end
				end
			end
		end
	end
end

function zones.start()
	event.listen("touch", listener)
	event.listen("drag", listener)
end

function zones.stop()
	event.ignore("touch", listener)
	event.ignore("drag", listener)
end

function zones.add(program, class, name, x, y, width, height, ...)
	zones.objects[program] = zones.objects[program] or {}
	zones.objects[program][class] = zones.objects[program][class] or {}
	zones.objects[program][class][name] = { x, y, x + width - 1, y + height - 1, ... }
end

function zones.remove(program, class, name)
	if program and class and name then
		if zones.objects[program] and zones.objects[program][class] then zones.objects[program][class][name] = nil end
	elseif program and class then
		if zones.objects[program] then zones.objects[program][class] = nil end
	elseif program then
		zones.objects[program] = nil
	end
end

-----------------------------------------------------------------------------------------------------------------------------------------

zones.stop()
zones.start()

-----------------------------------------------------------------------------------------------------------------------------------------

return zones



