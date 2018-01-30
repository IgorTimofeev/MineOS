

local MineOSCore = require("MineOSCore")

local t = {cyka = {}}

t.size = 160 * 50
for i = 1, t.size do
	t.cyka[i] = 0xFFFFFF 
end

local abc = 0
local method = function()
	for i = 1, 30000 do
		abc = #t.cyka + 5
	end
end

print("Время выполнения среднее: ", MineOSCore.getAverageMethodExecutionTime(method, 15))

