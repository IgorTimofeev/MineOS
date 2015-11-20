
------------------------------------------ Библиотеки ---------------------------------------------------------------

local ecs = require("ECSAPI")
local fs = require("filesystem")
local gpu = require("component").gpu
local unicode = require("unicode")
local event = require("event")
local serialization = require("serialization")

------------------------------------------ Переменные ---------------------------------------------------------------

local width, height = 70, 30
local x, y = ecs.correctStartCoords("auto", "auto", width, height)
local oldPixels = ecs.rememberOldPixels(x, y, x + width - 1, y + height - 1)
local dataWidth, dataHeight = width - 6, height - 14
local drawListFrom = 1
local selectedObject = 3
local pathToList = "MineOS/System/AutorunManager/Filelist.txt"
local autorunObjects = {
	-- { path = "OS.lua", enabled = true, size = 30 },
	-- { path = "Cyka/Home.lua", enabled = true, size = 30 },
	-- { path = "Pidar/Lalra/Cyka.lua", enabled = true, size = 30 },
	-- { path = "322File.lua", enabled = false, size = 30 },
	-- { path = "SasiHyu.lua", enabled = true, size = 30 },
	-- { path = "Blabla.cfg", enabled = false, size = 30 },
}

------------------------------------------ Функции ---------------------------------------------------------------

--Объекты для тача
local obj = {}
local function newObj(class, name, ...)
	obj[class] = obj[class] or {}
	obj[class][name] = {...}
end

local function saveAutorun()
	local file = io.open("autorun.lua", "w")
	file:write("local success, reason\n")
	for i = 1, #autorunObjects do
		if autorunObjects[i].enabled then
			file:write("success, reason = pcall(loadfile(\"" .. autorunObjects[i].path .. "\")); if not success then print(\"Ошибка: \" .. tostring(reason)) end\n")
		end
	end
	file:close()
end

local function saveList()
	local file = io.open(pathToList, "w")
	file:write(serialization.serialize(autorunObjects))
	file:close()
end

local function loadList()
	if fs.exists(pathToList) then
		local file = io.open(pathToList, "r")
		local text = file:read("*a")
		autorunObjects = serialization.unserialize(text)
		file:close()
	else
		fs.makeDirectory(fs.path(pathToList))
		saveList()
	end
end

local function drawFiles(x, y)

	local limit, from = dataHeight, drawListFrom

	obj["List"] = {}

	local yPos = y + 1

	ecs.square(x, y, dataWidth, dataHeight, 0xFFFFFF)
	ecs.square(x, y, dataWidth, 1, ecs.colors.blue)
	gpu.setForeground(0xFFFFFF)
	gpu.set(x + 1, y, "Запуск")
	gpu.set(x + 9, y, "Файл")
	gpu.set(x + 48, y, "Размер")

	ecs.srollBar(x + dataWidth - 1, yPos, 1, dataHeight - 1, #autorunObjects == 0 and from or #autorunObjects, from, 0xCCCCCC, ecs.colors.lightBlue)


	local color, color2
	for i = from, (from + #autorunObjects - 1) do
		if i > limit then break end
		if i % 2 == 0 then color = 0xFFFFFF; color2 = 0x262626 else color = 0xEEEEEE; color2 = 0x262626 end
		if i == selectedObject then color = ecs.colors.green; color2 = 0xFFFFFF end

		if autorunObjects[i] then

			ecs.square(x, yPos, dataWidth - 1, 1, color)

			if autorunObjects[i].enabled then
				ecs.colorTextWithBack(x + 3, yPos, ecs.colors.blue, color, "✔")
			else
				ecs.colorTextWithBack(x + 3, yPos, ecs.colors.red, color, "❌")
			end

			gpu.setBackground(color)
			gpu.setForeground(color2)
			gpu.set(x + 9, yPos, ecs.stringLimit("start", autorunObjects[i].path, 37))

			gpu.set(x + 48, yPos, autorunObjects[i].size .. " КБ")

			newObj("List", i, x, yPos, x + dataWidth - 1, yPos)

			yPos = yPos + 1
		end
	end
end

local function drawWindow()
	local xPos, yPos

	ecs.square(x, y, width, height, 0xDDDDDD)

	xPos = x + 3
	yPos = y + 4

	ecs.colorText(xPos, yPos, 0x262626, "Эти объекты будут запускаться автоматически при загрузке:")
	yPos = yPos + 2

	ecs.square(x, y, width, 3, 0xCCCCCC)

	ecs.centerText("x", y + 1, "Менеджер автозагрузки")

	drawFiles(x + 3, y + 6)

	yPos = y + height - 7
	ecs.colorTextWithBack(xPos, yPos, 0x262626, 0xDDDDDD, "Чтобы отключить загрузку файла, снимите галочку рядом с именем")
	yPos = yPos + 1
	gpu.set(xPos, yPos, "программы. Приоритет загузки снижается сверху вниз.")
	yPos = yPos + 2

	local name
	name = "+"; newObj("Buttons", name, ecs.drawAdaptiveButton(xPos, yPos, 2, 1, name, 0xFFFFFF, 0x262626)); xPos = obj["Buttons"][name][3] + 2
	name = "-"; newObj("Buttons", name, ecs.drawAdaptiveButton(xPos, yPos, 2, 1, name, 0xFFFFFF, 0x262626)); xPos = obj["Buttons"][name][3] + 2

	name = "Выше"; newObj("Buttons", name, ecs.drawAdaptiveButton(xPos, yPos, 2, 1, name, 0xFFFFFF, 0x262626)); xPos = obj["Buttons"][name][3] + 2
	name = "Ниже"; newObj("Buttons", name, ecs.drawAdaptiveButton(xPos, yPos, 2, 1, name, 0xFFFFFF, 0x262626)); xPos = obj["Buttons"][name][3] + 2
	-- if fs.isAutorunEnabled() then
	-- 	name = "Выключить автозапуск"
	-- else
	-- 	name = "Включить автозапуск "
	-- end
	-- newObj("Buttons", name, ecs.drawAdaptiveButton(xPos, yPos, 2, 1, name, 0xAAAAAA, 0xFFFFFF)); xPos = obj["Buttons"][name][3] + 2

	xPos = x + width - 12
	name = "Выход"; newObj("Buttons", name, ecs.drawAdaptiveButton(xPos, yPos, 2, 1, name, 0x888888, 0xFFFFFF))
end

------------------------------------------ Программа ---------------------------------------------------------------

loadList()
drawWindow()

while true do
	local e = {event.pull()}
	if e[1] == "touch" then
		--if obj["List"] and #obj["List"] > 0 then
			for key in pairs(obj["List"]) do
				if ecs.clickedAtArea(e[3], e[4], obj["List"][key][1], obj["List"][key][2], obj["List"][key][3], obj["List"][key][4]) then
					if selectedObject ~= key then
						selectedObject = key
						drawFiles(x + 3, y + 6)
					else
						if e[3] >= obj["List"][key][1] + 2 and e[3] <= obj["List"][key][1] + 4 then
							autorunObjects[key].enabled = not autorunObjects[key].enabled 
							drawFiles(x + 3, y + 6)
							saveList()
							saveAutorun()
						end
					end
					break
				end	
			end
		--end

		for key in pairs(obj["Buttons"]) do
			if ecs.clickedAtArea(e[3], e[4], obj["Buttons"][key][1], obj["Buttons"][key][2], obj["Buttons"][key][3], obj["Buttons"][key][4]) then
				ecs.drawAdaptiveButton(obj["Buttons"][key][1], obj["Buttons"][key][2], 2, 1, key, ecs.colors.blue, 0xFFFFFF)
				os.sleep(0.2)
				ecs.drawAdaptiveButton(obj["Buttons"][key][1], obj["Buttons"][key][2], 2, 1, key, 0xFFFFFF, 0x262626)
				
				if key == "-" then
					table.remove(autorunObjects, selectedObject)
					if drawListFrom == selectedObject then drawListFrom = 1 end
					drawFiles(x + 3, y + 6)
					saveList()
					saveAutorun()
				elseif key == "+" then
					local data = ecs.universalWindow("auto", "auto", 36, 0xeeeeee, true, {"EmptyLine"}, {"CenterText", 0x880000, "Добавить новый файл"}, {"EmptyLine"}, {"Input", 0x262626, 0x880000, "Путь к файлу"}, {"EmptyLine"}, {"Button", {0x888888, 0xffffff, "Добавить"}, {0xAAAAAA, 0xffffff, "Отмена"}})
					if data[2] == "Добавить" then
						if fs.exists(data[1]) then
							local cyka = false
							for i = 1, #autorunObjects do
								if autorunObjects[i].path == data[1] then cyka = true end
							end
							if not cyka then
								table.insert(autorunObjects, { path = data[1], enabled = true, size = math.ceil(fs.size(data[1]) / 1024) })
								drawFiles(x + 3, y + 6)
								saveList()
								saveAutorun()
							else
								ecs.error("Файл \"" .. data[1] .. "\" уже есть в этом списке!")
							end
						else
							ecs.error("Файл \"" .. data[1] .. "\" не существует!")
						end
					end
				elseif key == "Выше" then
					if selectedObject > 1 then
						local cyka = autorunObjects[selectedObject]
						table.remove(autorunObjects, selectedObject)
						table.insert(autorunObjects, selectedObject - 1, cyka)
						selectedObject = selectedObject - 1
						drawFiles(x + 3, y + 6)
						saveList()
						saveAutorun()
					end
				elseif key == "Ниже" then
					if selectedObject < #autorunObjects then
						local cyka = autorunObjects[selectedObject]
						table.remove(autorunObjects, selectedObject)
						table.insert(autorunObjects, selectedObject + 1, cyka)
						selectedObject = selectedObject + 1
						drawFiles(x + 3, y + 6)
						saveList()
						saveAutorun()
					end
				elseif key == "Выход" then
					ecs.drawOldPixels(oldPixels)
					return
				-- elseif key == "Включить автозапуск " then
				-- 	fs.setAutorunEnabled(true)
				-- 	drawWindow()
				-- elseif key == "Выключить автозапуск" then
				-- 	fs.setAutorunEnabled(false)
				-- 	drawWindow()
				end

				break
			end
		end

	elseif e[1] == "scroll" then
		if e[5] == 1 then
			if drawListFrom > 1 then drawListFrom = drawListFrom - 1; drawFiles(x + 3, y + 6) end
		else
			if drawListFrom < #autorunObjects then drawListFrom = drawListFrom + 1; drawFiles(x + 3, y + 6) end
		end
	end
end













