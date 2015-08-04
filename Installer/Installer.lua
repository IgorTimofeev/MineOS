local component = require("component")
local computer = require("computer")
local term = require("term")
local unicode = require("unicode")
local event = require("event")
local fs = require("filesystem")
local internet = require("internet")
local gpu = component.gpu

------------------------------------------------------------------------------

local data = {
	{ paste = "9dxXHREX", path = "autorun.lua", type = "API", information = "Sasi hui" },
	--{ paste = "87QETLA4", path = "lib/ECSAPI.lua", type = "API", information = "Sasi hui"},
	{ paste = "3MvVCqyS", path = "lib/colorlib.lua", type = "API", information = "Sasi hui"},
	{ paste = "JDPHPKHq", path = "lib/palette.lua", type = "API", information = "Sasi hui" },
	{ paste = "6UR8xkHX", path = "lib/thread.lua", type = "API", information = "Sasi hui" },
	{ paste = "tUgyRS9f", path = "lib/context.lua", type = "API", information = "Sasi hui" },
	{ paste = "8PUQ0teG", path = "lib/zip.lua", type = "API", information = "Sasi hui" },
	{ paste = "Weqcf4SR", path = "lib/config.lua", type = "API", information = "Sasi hui" },

	{ paste = "zmnDb2Zs", path = "PS.lua", type = "Proga", information = "Sasi hui" },
	{ paste = "XLsiyXAw", path = "OS.lua", type = "Proga", information = "Sasi hui" },
	{ paste = "7xGNZNQs", path = "System/OS/Icons/Folder.png", type = "Proga", information = "Sasi hui" },
	{ paste = "7xGNZNQs", path = "System/OS/Icons/Script.png", type = "Proga", information = "Sasi hui" },
	{ paste = "aNWCcdtD", path = "init.lua", type = "Proga", information = "Sasi hui" },
	{ paste = "1Hxri8iv", path = "Crossword.lua", type = "Proga", information = "Sasi hui" },
	{ paste = "SSyX4p8X", path = "CrosswordFile.txt", type = "Proga", information = "Sasi hui" },
	{ paste = "3XfLNdm0", path = "Home.lua", type = "Proga", information = "Sasi hui" },
	{ paste = "TJHGfhEj", path = "Geoscan.lua", type = "Proga", information = "Sasi hui" },

	{ paste = "YiT3nNVr", path = "bin/event.lua", type = "Proga", information = "Sasi hui" },
	{ paste = "pQRSyrV6", path = "bin/memory.lua", type = "Proga", information = "Sasi hui" },
	{ paste = "WFsvgaEm", path = "bin/scale.lua", type = "Proga", information = "Sasi hui" },
	{ paste = "YbbAVJ4V", path = "bin/ls.lua", type = "Proga", information = "Sasi hui" },
	{ paste = "7yHp6Fjw", path = "etc/motd", type = "Proga", information = "Sasi hui" },
	{ paste = "diDyYvzV", path = "usr/misc/greetings/English.txt", type = "Proga", information = "Sasi hui" },
	{ paste = "dgm5eC6v", path = "usr/misc/greetings/Russian.txt", type = "Proga", information = "Sasi hui" },

	{
		type = "Application",
		path = "MineCode.app",
		paste = "DBGEWnLc",
		icon = "nrSeV3mS",
		resources = {
			{ name = "English.lang", paste = "G9yP8mTd" },
			{ name = "Russian.lang", paste = "gevPpGDr" },
		}
	},
}

local lang = {
	
}

local padColor = 0x262626
local installerScale = 1

local sData = #data
local timing = 0.2

-----------------------------СТАДИЯ ПОДГОТОВКИ-------------------------------------------

--ЗАГРУЗОЧКА С ПАСТЕБИНА
local function get(paste, filename)
	local f, reason = io.open(filename, "w")
	if not f then
		io.stderr:write("Failed opening file for writing: " .. reason)
		return
	end
	--io.write("Downloading from pastebin.com... ")
	local url = "http://pastebin.com/raw.php?i=" .. paste
	local result, response = pcall(internet.request, url)
	if result then
		--io.write("success.\n")
		for chunk in response do
			--if not options.k then
				--string.gsub(chunk, "\r\n", "\n")
			--end
			f:write(chunk)
		end
		f:close()
		--io.write("Saved data to " .. filename .. "\n")
	else
		f:close()
		fs.remove(filename)
		io.stderr:write("HTTP request failed: " .. response .. "\n")
	end
end

get("87QETLA4", "lib/ECSAPI.lua")
local ecs = require("ECSAPI")

--ecs.setScale(installerScale)

local xSize, ySize = gpu.getResolution()
local windowWidth = xSize - 20
local windowHeight = ySize - 6
local xWindow, yWindow = math.floor(xSize / 2 - windowWidth / 2), math.floor(ySize / 2 - windowHeight / 2)
local xWindowEnd, yWindowEnd = xWindow + windowWidth - 1, yWindow + windowHeight - 1


-------------------------------------------------------------------------------------------

local function clear()
	ecs.blankWindow(xWindow, yWindow, windowWidth, windowHeight)
end

--ОБЪЕКТЫ
local obj = {}
local function newObj(class, name, ...)
	obj[class] = obj[class] or {}
	obj[class][name] = {...}
end

if not component.isAvailable("internet") then
	io.stderr:write("This program requires an internet card to run.")
	return
end

local function drawButton(name, isPressed)
	local buttonColor = 0x888888
	if isPressed then buttonColor = ecs.colors.blue end
	local d = {ecs.drawAdaptiveButton("auto", yWindowEnd - 3, 2, 1, name, buttonColor, 0xffffff)}
	newObj("buttons", name, d[1], d[2], d[3], d[4])
end

local function waitForClickOnButton(buttonName)
	while true do
		local e = { event.pull() }
		if e[1] == "touch" then
			if ecs.clickedAtArea(e[3], e[4], obj["buttons"][buttonName][1], obj["buttons"][buttonName][2], obj["buttons"][buttonName][3], obj["buttons"][buttonName][4]) then
				drawButton(buttonName, true)
				os.sleep(timing)
				break
			end
		end
	end
end


local function download(i)
	--ЕСЛИ ЭТО ПРИЛОЖЕНИЕ
	if data[i]["type"] == "Application" then
		local path = data[i]["path"]
		--ЕСЛИ ЭТА ХУЙНЯ СУЩЕСТВУЕТ, ТО УДАЛИТЬ ЕЕ
		if fs.exists(path) then fs.remove(path) end
		--СОЗДАТЬ ПУТЬ, А ТО МАЛО ЛИ ЕГО НЕТ
		fs.makeDirectory(path .. "/" .. "Resources")
		--СКАЧАТЬ ПРОГУ
		get(data[i]["paste"], path .. "/" .. ecs.hideFileFormat(fs.name(path)))
		--СКАЧАТЬ ИКОНКУ
		get(data[i]["icon"], path .. "/Resources/Icon.png")
		--СКАЧАТЬ РЕСУРСЫ
		if data[i]["resources"] then
			for j = 1, #data[i]["resources"] do
				get(data[i]["resources"][j]["paste"], path .. "/Resources/" .. data[i]["resources"][j]["name"])
			end
		end
	--ЕСЛИ НЕ ПРИЛОЖЕНИЕ
	else
		--ЕСЛИ ЭТА ХУЙНЯ СУЩЕСТВУЕТ, ТО УДАЛИТЬ ЕЕ
		if fs.exists(data[i]["path"]) then fs.remove(data[i]["path"]) end
		--СОЗДАТЬ ПУТЬ, А ТО МАЛО ЛИ ЕГО НЕТ
		fs.makeDirectory(fs.path(data[i]["path"]))
		--СКАЧАТЬ
		get(data[i]["paste"], data[i]["path"])
	end
end

--------------------------СТАДИЯ ЗАГРУЗКИ НУЖНЫХ ПАКЕТОВ-----------------------
	
do

	local barWidth = math.floor(windowWidth / 2)
	local xBar = math.floor(xSize/2-barWidth/2)
	local yBar = math.floor(ySize/2) + 1

	--создание первичного экрана чистенького
	ecs.clearScreen(padColor)

	clear()

	gpu.setBackground(ecs.windowColors.background)
	gpu.setForeground(ecs.colors.gray)
	ecs.centerText("x", yBar - 2, "Loading installer data")

	ecs.progressBar(xBar, yBar, barWidth, 1, 0xcccccc, ecs.colors.blue, 0)
	os.sleep(timing)

	local preLoadApi = {
		{ paste = "n09xYPTr", path = "lib/image.lua" },
		{ paste = "Dx5mjgWP", path = "System/OS/Installer/Languages.png" },
		{ paste = "KWkyHKnx", path = "System/OS/Installer/OK.png" },
		{ paste = "f2ZgseWs", path = "System/OS/Installer/Downloading.png" },
		{ paste = "PUBh4vdh", path = "System/OS/Installer/OS_Logo.png" },
	}

	for i = 1, #preLoadApi do

		local percent = i / #preLoadApi * 100
		ecs.progressBar(xBar, yBar, barWidth, 1, 0xcccccc, ecs.colors.blue, percent)

		if fs.exists(preLoadApi[i]["path"]) then fs.remove(preLoadApi[i]["path"]) end
		fs.makeDirectory(fs.path(preLoadApi[i]["path"]))
		get(preLoadApi[i]["paste"], preLoadApi[i]["path"])

		os.sleep(timing)
	end

	os.sleep(timing)
end

local image = require("image")

local imageOS = image.load("System/OS/Installer/OS_Logo.png")
local imageLanguages = image.load("System/OS/Installer/Languages.png")
local imageDownloading = image.load("System/OS/Installer/Downloading.png")
local imageOK = image.load("System/OS/Installer/OK.png")

------------------------------СТАВИТЬ ЛИ ОСЬ------------------------------------

do

	clear()

	image.draw(math.ceil(xSize / 2 - 15), math.ceil(ySize / 2 - 11), imageOS)

	--Текстик по центру
	gpu.setBackground(ecs.windowColors.background)
	gpu.setForeground(ecs.colors.gray)
	ecs.centerText("x", yWindowEnd - 5 ,"Чтобы начать установку OS, нажмите Далее")

	--кнопа
	drawButton("->",false)

	waitForClickOnButton("->")

	--УСТАНАВЛИВАЕМ НУЖНЫЙ ЯЗЫК
	local path = "System/OS/Language.lua"
	if fs.exists(path) then fs.remove(path) end
	fs.makeDirectory(fs.path(path))
	local file = io.open(path, "w")
	file:write("return \"Russian\"")
	file:close()

end

------------------------------СТАДИЯ ВЫБОРА ЯЗЫКА------------------------------------------

do

	clear()
	
	image.draw(math.ceil(xSize / 2 - 30), math.ceil(ySize / 2 - 10), imageLanguages)

	ecs.selector(math.floor(xSize / 2 - 10), yWindowEnd - 5, 20, "Russian", {"English", "Russian"}, 0xffffff, 0x000000, true)

	--кнопа
	drawButton("->",false)

	waitForClickOnButton("->")
end

--------------------------СТАДИЯ ЗАГРУЗКИ-----------------------------------

do

	local barWidth = math.floor(windowWidth / 2)
	local xBar = math.floor(xSize/2-barWidth/2)
	local yBar = yWindowEnd - 3

	local function drawInfo(x, y, info)
		ecs.square(x, y, barWidth, 1, ecs.windowColors.background)
		ecs.colorText(x, y, ecs.colors.gray, info)
	end

	ecs.blankWindow(xWindow,yWindow,windowWidth,windowHeight)

	image.draw(math.floor(xSize/2 - 33), math.floor(ySize/2-10), imageDownloading)

	ecs.colorTextWithBack(xBar, yBar - 1, ecs.colors.gray, ecs.windowColors.background, "Установка OS")
	ecs.progressBar(xBar, yBar, barWidth, 1, 0xcccccc, ecs.colors.blue, 0)
	os.sleep(timing)

	for i = 1, sData do

		drawInfo(xBar, yBar + 1, "Загрузка "..data[i]["path"])

		download(i)

		local percent = i / sData * 100
		ecs.progressBar(xBar, yBar, barWidth, 1, 0xcccccc, ecs.colors.blue, percent)

	end

	os.sleep(timing)
end

--------------------------СТАДИЯ ПЕРЕЗАГРУЗКИ КОМПА-----------------------------------

ecs.blankWindow(xWindow,yWindow,windowWidth,windowHeight)

image.draw(math.floor(xSize/2 - 16), math.floor(ySize/2 - 11), imageOK)

--Текстик по центру
gpu.setBackground(ecs.windowColors.background)
gpu.setForeground(ecs.colors.gray)
ecs.centerText("x",yWindowEnd - 5, "Система установлена, необходима перезагрузка")

--Кнопа
drawButton("Перезагрузить",false)

waitForClickOnButton("Перезагрузить")

computer.shutdown(true)
