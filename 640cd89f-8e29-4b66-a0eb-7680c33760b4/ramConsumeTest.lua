

local computer = require("computer")

local old = computer.freeMemory()

-- local t = {width = 160, height = 50}
-- for i = 1, t.width * t.height do
-- 	table.insert(t, 0xFFFFFF)
-- 	table.insert(t, 0xFFFFFF)
-- 	table.insert(t, 0xFF)
-- 	table.insert(t, "Й")
-- end

local t = {160, 50}
for i = 1, t[1] * t[2] do
	table.insert(t, 0xFFFFFF)
	table.insert(t, 0xFFFFFF)
	table.insert(t, 0xFF)
	table.insert(t, "Й")
end

print("Сожрало памяти: " .. (old - computer.freeMemory()) / 1024 .. " KB")


