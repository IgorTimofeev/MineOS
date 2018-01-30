

local computer = require("computer")


local f = function(abc) for i = 1, 10 do print("aefaef") end end
local t = {a = {b = {c = {}}}}
for i = 1, 1000 do
	table.insert(t.a.b.c, 123)
end
local zalupa = {}
local m = computer.freeMemory()
for i = 1, 2 do
	zalupa[i] = f
end
local cyka = m - computer.freeMemory()
print("RASHOD", cyka)
print(l)