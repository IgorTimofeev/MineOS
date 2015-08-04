local component = require("component")
local event = require("event")
local term = require("term")
local unicode = require("unicode")
local ecs = require("ECSAPI")
local colorlib = require("colorlib")
local gpu = component.gpu

local context = {}

local separatorColor = 0xcccccc
local shortcutAutism = 3

----------------------------------------------------------------------------------------------------------------

--ОБЪЕКТЫ
local obj = {}
local function newObj(class,name,x1,y1,x2,y2,id)
	obj[class] = obj[class] or {}
	obj[class][name] = obj[class][name] or {}
	obj[class][name]["x1"] = x1
	obj[class][name]["y1"] = y1
	obj[class][name]["x2"] = x2
	obj[class][name]["y2"] = y2
	obj[class][name]["id"] = id
end

function context.menu(...)

	local arg = {...}

	local x = arg[1]
	local y = arg[2]

	local xSize,ySize = gpu.getResolution()
	local sArg = #arg
	local yWindowSize = sArg - 2

	local lengthOfBiggestElement = 1
	for i=3,sArg do
		if arg[i] ~= "-" then
			local length = unicode.len(arg[i][1])
			if arg[i][3] then length = length + shortcutAutism + unicode.len(arg[i][3]) end
			if length > lengthOfBiggestElement then lengthOfBiggestElement = length end
		end
	end
	local xWindowSize = lengthOfBiggestElement + 4

	--КОРРЕКЦИЯ КООРДИНАТЫ МЕНЮ, ЧТОБ ЗА КРАЯ ЭКРАНА НЕ ЗАЛЕЗАЛО
	if y+yWindowSize - 1  >= ySize then y = y - (y + yWindowSize - ySize) end
	if x+xWindowSize - 1  >= xSize then x = x - (x + xWindowSize - xSize) end

	local xWindowEnd = x + xWindowSize - 1
	local yWindowEnd = y + yWindowSize - 1

	--ЗАПОМИНАНИЕ СТАРЫХ ПИКСЕЛЕЙ
	local oldPixels = ecs.rememberOldPixels(x,y,xWindowEnd+2,yWindowEnd+1)

	--НАЧАЛО ОТРИСОВКИ МЕНЮ
	ecs.square(x,y,xWindowSize,yWindowSize,0xffffff)
	ecs.windowShadow(x,y,xWindowSize,yWindowSize)

	gpu.setBackground(0xffffff)
	local posY = y
	local posX = x + 2
	for i=3,sArg do
		local contextColor = 0x000000
		if arg[i] ~= "-" then
			--ЕСЛИ АРГУМЕНТ_2 (СКРЫТЫЙ/НЕ СКРЫТЫЙ) И АРУМЕНТ_3 (ЦВЕТ ТЕКСТА ЭЛЕМЕНТА) ДЛЯ РАССМАТРИВАЕМОГО ЭЛЕМЕНТА НЕ УКАЗАНЫ, ТО
			if arg[i][2] == nil and arg[i][4] == nil then
				contextColor = 0x000000
			--ЕСЛИ АРГУМЕНТ 2 = FALSE И АРГУМЕНТ 4 НЕ УКАЗАН, ТО
			elseif arg[i][2] == false and arg[i][4] == nil then
				contextColor = 0x000000
			--ЕСЛИ АРГУМЕНТ 2 = FALSE И АРГУМЕНТ 4 УКАЗАН, ТО
			elseif arg[i][2] == false and arg[i][4] ~= nil then
				contextColor = arg[i][4]
			--ЕСЛИ АРГУМЕНТ 2 = TRUE, ТО ЭЛЕМЕНТ СКРЫТ
			elseif arg[i][2] == true then
				contextColor = separatorColor
			end

			ecs.colorText(posX,posY,contextColor,arg[i][1])

			if arg[i][3] then
				local xPos = xWindowEnd - unicode.len(arg[i][3]) - 1
				ecs.colorText(xPos,posY,contextColor,arg[i][3])
			end

			if not arg[i][2] then newObj("elements",i,x,posY,xWindowEnd,posY,arg[i][1]) end
		else
			gpu.setForeground(separatorColor)
			gpu.fill(x,posY,xWindowSize,1,"─")
		end

		posY = posY + 1
	end

	local atArea = nil
	while true do
		local e = {event.pull()}
		if e[1] == "touch" then
			for key,val in pairs(obj["elements"]) do
				if ecs.clickedAtArea(e[3],e[4],obj["elements"][key]["x1"],obj["elements"][key]["y1"],obj["elements"][key]["x2"],obj["elements"][key]["y2"]) then
					ecs.square(obj["elements"][key]["x1"],obj["elements"][key]["y1"],xWindowSize,1,ecs.colors.blue)
					ecs.colorText(obj["elements"][key]["x1"]+2,obj["elements"][key]["y1"],0xffffff,obj["elements"][key]["id"])
					
					if arg[key] then
						if arg[key][3] then
							local xPos = xWindowEnd - unicode.len(arg[key][3]) - 1
							ecs.colorText(xPos,obj["elements"][key]["y1"],0xffffff,arg[key][3])
						end
					end

					os.sleep(0.2)
					atArea = obj["elements"][key]["id"]

					break
				end
			end
			--ОТРИСОВАТЬ СТАРЫЕ ПИКСЕЛИ
			ecs.drawOldPixels(oldPixels)
			if atArea then return atArea else return nil end
		end
	end


end

----------------------------------------------------------------------------------------------------------------

--[[local action = "CYka"
while true do
	ecs.clearScreen(0x777777)
	gpu.set(1,2,"Action = "..tostring(action))
	action = context.menu(5,5,{"Hello world!"},{"Cyka?"},"-",{"Ahahaha"},{"Da nu nahui",true},{"afafaf11"},{"Sexy",false,0xff0000},{"Cafaf",true,0x444444},{"daun",false,0x00ff00})
end]]


return context
