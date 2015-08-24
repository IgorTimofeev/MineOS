
local component = require("component")
local gpu = component.gpu
local ecs = require("ECSAPI")
local image = require("image")
local unicode = require("unicode")
local event = require("event")
local palette = require("palette")

------------------------------------------------------------------------------------------------

local xSize, ySize = gpu.getResolution()

local width, height = 80, 25
local x, y = math.floor(xSize /2 - width / 2), math.floor(ySize / 2 - height / 2)
local xCenter, yCenter = math.floor(xSize / 2), math.floor(ySize / 2)

local oldPixels = ecs.rememberOldPixels(x, y, x + width + 1, y + height)

local OS_Logo = image.load("System/OS/Installer/OS_Logo.png")
local Love = image.load("System/OS/Icons/Love.png")

local offset = 3

local buttonColor = 0x888888
local buttonPressColor = ecs.colors.blue

------------------------------------------------------------------------------------------------

--СОЗДАНИЕ ОБЪЕКТОВ
local obj = {}
local function newObj(class, name, ...)
	obj[class] = obj[class] or {}
	obj[class][name] = {...}
end

local function clear()
	obj = {}
	ecs.blankWindow(x, y, width, height)
end

local function drawTablicu(y, users)
	local width = 40
	local limit = 7

	local x = math.ceil(xCenter - width / 2)

	local yPos = y
	ecs.square(x, yPos, width, 1, ecs.colors.blue)
	ecs.colorText(x + 1, yPos, 0xffffff, "Пользователи ("..#users.." из "..limit..")")

	yPos = yPos + 1
	ecs.square(x, yPos, width, limit * 2 - 1, 0xffffff)

	for i = 1, limit do
		if users[i] then
			ecs.colorText(x + 1, yPos, 0x000000, ecs.stringLimit("end", users[i], width - 2))
		end
		if i < limit then
			ecs.colorText(x, yPos + 1, 0xaaaaaa, string.rep("─", width))
		end

		yPos = yPos + 2
	end
end

------------------------------------------------------------------------------------------------

local function stage1()
	clear()
	image.draw(math.ceil(xSize / 2 - 15), y + 2, OS_Logo)

	local yPos = y + height - 6
	gpu.setForeground(ecs.windowColors.usualText); gpu.setBackground(ecs.windowColors.background); ecs.centerText("x", yPos, "Добро пожаловать в программу настройки MineOS!")
	yPos = yPos + 2

	local name
	name = "Далее"; newObj("Buttons", name, ecs.drawAdaptiveButton("auto", yPos, offset, 1, name, buttonColor, 0xffffff))

	while true do
		local e = {event.pull()}
		if e[1] == "touch" then
			if ecs.clickedAtArea(e[3], e[4], obj["Buttons"][name][1], obj["Buttons"][name][2], obj["Buttons"][name][3], obj["Buttons"][name][4] ) then
				ecs.drawAdaptiveButton(obj["Buttons"][name][1], obj["Buttons"][name][2], offset, 1, name, buttonPressColor, 0xffffff)
				os.sleep(0.3)
				return
			end
		end
	end
end

local function stage2()
	clear()
	local users = {}
	drawTablicu(y + 2, users)

	local yPos = y + height - 7
	gpu.setForeground(ecs.windowColors.usualText); gpu.setBackground(ecs.windowColors.background)
	ecs.centerText("x", yPos, "Это биометрическая защита компьютера."); yPos = yPos + 1
	ecs.centerText("x", yPos, "Прикоснитесь к экрану - и система зарегистрирует вас."); yPos = yPos + 1
	
	local yPos = yPos + 1
	local name = "Далее"; newObj("Buttons", name, ecs.drawAdaptiveButton("auto", yPos, offset, 1, name, buttonColor, 0xffffff))

	while true do
		local e = {event.pull()}
		if e[1] == "touch" then
			if ecs.clickedAtArea(e[3], e[4], obj["Buttons"][name][1], obj["Buttons"][name][2], obj["Buttons"][name][3], obj["Buttons"][name][4] ) then
				ecs.drawAdaptiveButton(obj["Buttons"][name][1], obj["Buttons"][name][2], offset, 1, name, buttonPressColor, 0xffffff)
				if #users == 0 then table.insert(users, e[6]) end
				drawTablicu(y + 2, users)
				os.sleep(0.3)
				return users
			else
				if #users < 7 then
					local exists
					for key, val in pairs(users) do
						if e[6] == val then exists = true; break end
					end
					if not exists then
						table.insert(users, e[6])
						drawTablicu(y + 2, users)
					end
				end
			end
		end
	end
end

local function drawSampleCode(y, background, foreground)
	local shirina = width - 10
	local visota = 14
	local x = math.floor(xCenter - shirina / 2)
	ecs.square(x, y, shirina, visota, background)
	ecs.colorText(x + 1, y + 1, 0xff0000, "/#")
	ecs.colorText(x + 4, y + 1, foreground, "Hello world!")
end

local function stage3()

	local background, foreground = 0x262626, 0xffffff

	clear()

	while true do
		drawSampleCode(y + 2, background, foreground)

		local yPos = y + height - 7
		gpu.setForeground(ecs.windowColors.usualText); gpu.setBackground(ecs.windowColors.background)
		ecs.centerText("x", yPos, "Вы можете выбрать цвет текста и фона консоли."); yPos = yPos + 1
		ecs.centerText("x", yPos, "Пример кода выше."); yPos = yPos + 1
		yPos = yPos + 1

		obj = {}
		local xPos = xCenter - 28
		local name = "Изменить текст"; newObj("Buttons", name, ecs.drawAdaptiveButton(xPos, yPos, offset, 1, name, foreground, 0xffffff - foreground)); xPos = xPos + unicode.len(name) + offset * 3
		name = "Изменить фон"; newObj("Buttons", name, ecs.drawAdaptiveButton(xPos, yPos, offset, 1, name, background, 0xffffff - background)); xPos = xPos + unicode.len(name) + offset * 3
		name = "Далее"; newObj("Buttons", name, ecs.drawAdaptiveButton(xPos, yPos, offset, 1, name, buttonColor, 0xffffff)); xPos = xPos + unicode.len(name) + offset * 3

		local exit
		while true do
			if exit then break end
			local e = {event.pull()}
			if e[1] == "touch" then
				for name, val in pairs(obj["Buttons"]) do
					if ecs.clickedAtArea(e[3], e[4], obj["Buttons"][name][1], obj["Buttons"][name][2], obj["Buttons"][name][3], obj["Buttons"][name][4] ) then
						ecs.drawAdaptiveButton(obj["Buttons"][name][1], obj["Buttons"][name][2], offset, 1, name, buttonPressColor, 0xffffff)
						os.sleep(0.3)
						
						if name == "Изменить текст" then
							local color = palette.draw("auto", "auto", foreground)
							if color then foreground = color end
							exit = true
							break
						elseif name == "Изменить фон" then
							local color = palette.draw("auto", "auto", background)
							if color then background = color end
							exit = true
							break
						else
							return background, foreground
						end
					end
				end
			end
		end
	end
end

local function stage5()
	clear()
	image.draw(xCenter - 17, y + 2, Love)

	local yPos = y + height - 6
	--gpu.setForeground(ecs.windowColors.usualText); gpu.setBackground(ecs.windowColors.background); ecs.centerText("x", yPos, "Все готово!")
	yPos = yPos + 2

	local name
	name = "Начать использование OC"; newObj("Buttons", name, ecs.drawAdaptiveButton("auto", yPos, offset, 1, name, buttonColor, 0xffffff))

	while true do
		local e = {event.pull()}
		if e[1] == "touch" then
			if ecs.clickedAtArea(e[3], e[4], obj["Buttons"][name][1], obj["Buttons"][name][2], obj["Buttons"][name][3], obj["Buttons"][name][4] ) then
				ecs.drawAdaptiveButton(obj["Buttons"][name][1], obj["Buttons"][name][2], offset, 1, name, buttonPressColor, 0xffffff)
				os.sleep(0.3)
				return
			end
		end
	end
end

------------------------------------------------------------------------------------------------

stage1()
local users = stage2()
local background, foreground = stage3()
stage5()

local path = "System/OS/Users.cfg"
fs.remove(path)
fs.makeDirectory(fs.path(path))
local file = io.open(path, "w")
for _,val in pairs(users) do
	file:write(val, "\n")
end
file:close()

ecs.drawOldPixels(oldPixels)


