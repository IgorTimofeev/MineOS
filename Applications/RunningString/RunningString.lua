local unicode = require("unicode")
local keyboard = require("keyboard")

local str,freq,speed,scale,bg,fg

-- gpu.setResolution(gpu.maxResolution())
-- ecs.prepareToExit()

local data = ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true,
	{"EmptyLine"},
	{"CenterText", 0x880000, "Бегущая строка"},
	{"EmptyLine"},
	{"CenterText", 0x000000, "Для выхода из программы"},
	{"CenterText", 0x000000, "удерживайте Enter"},
	{"EmptyLine"},
	{"Input", 0x262626, 0x880000, "Программист за работой, не мешай, сука!"},
	{"Color", "Цвет фона", 0x000000},
	{"Color", "Цвет текста", 0xFFFFFF},
	{"Slider", 0x262626, 0x880000, 1, 100, 1, "Масштаб: ", "%"},
    {"Slider", 0x262626, 0x880000, 1, 100, 40, "Скорость: ", "/100 FPS"},
	{"EmptyLine"},
	{"Button", {0xbbbbbb, 0xffffff, "OK"}, {0x999999, 0xffffff, "Отмена"}}
)

-- ecs.error(table.unpack(data))
if data[6] == "OK" then
	str = data[1] or "Где текст, сука?"
	bg = tonumber(data[2]) or 0x000000
	fg = tonumber(data[3]) or 0xFFFFFF
	scale = tonumber(data[4])/100 or 0.1
	speed = tonumber(data[5])/100 or 0.4
	freq = 5
else
	return
end

local xOld, yOld = gpu.getResolution()
ecs.setScale(scale)
local xSize, ySize = gpu.getResolution()
gpu.setBackground(bg)
gpu.setForeground(fg)
gpu.fill(1, 1, xSize, ySize, " ")

str = " " .. str .. string.rep(" ", freq)

while true do
	str = unicode.sub(str, 2, -1) .. unicode.sub(str, 1, 1)
	gpu.set(math.ceil(xSize / 2 - unicode.len(str) / 2), math.ceil(ySize / 2), str)
	
	if keyboard.isKeyDown(28) then
		gpu.setResolution(xOld, yOld)
		ecs.prepareToExit()
		return
	end

	os.sleep(speed)
end