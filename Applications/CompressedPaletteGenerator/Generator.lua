

local colors = { }
local color = 0x000000
local gray  = 0x000000

local xPos, yPos = 2, 2

local function printColor(color)
	gpu.setForeground(color)
	gpu.set(xPos, yPos, ecs.HEXtoString(color, 6, true))
	yPos = yPos + 1
	if yPos > 48 then yPos = 2; xPos = xPos + 10 end
end

local function addColor(value)
	table.insert(colors, color)
	printColor(color)
	color = color + value
end

local function add4()
	addColor(0x40)
	addColor(0x40)
	addColor(0x3F)
	addColor(0x40)
	addColor(0x40)
	color = bit32.band(color, 0xffff00)
end

local function createNext4(value)
	add4()
	color = color + value
	yPos = yPos + 1
end

local function add8()
	createNext4(0x2300)
	createNext4(0x2400)
	createNext4(0x2300)
	createNext4(0x2400)
	createNext4(0x2300)
	createNext4(0x2400)
	createNext4(0x2300)
	createNext4(0x2400)
end

local function newGray()
	gray = gray + 0x0F0F0F
	printColor(gray)
	table.insert(colors, gray)
end

local function add8WithGray()
	add8()
	for i = 1, 3 do
		newGray()
	end
	color = bit32.band(color, 0xff0000)
	color = color + 0x320000
end

ecs.prepareToExit()
ecs.error("Создаем таблицу")
for i = 1, 6 do
	add8WithGray()
end

for i = 1, 3 do
	table.remove(colors, #colors)
end

ecs.wait()
ecs.prepareToExit()
ecs.error("Размер массива = " .. #colors .. ", рисуем таблицу")
xPos, yPos = 2, 2
local file = io.open("colors.lua", "w")
file:write("return {\n")
for i = 1, #colors do
	printColor(colors[i])
	file:write("  [" .. ecs.HEXtoString(i - 1, 2, true) .. "] = " .. ecs.HEXtoString(colors[i], 6, true) .. ",\n")
end
file:write("}\n")
file:close()


