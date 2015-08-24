local component = require("component")
local computer = require("computer")
local term = require("term")
local unicode = require("unicode")
local event = require("event")
local fs = require("filesystem")
local internet = require("internet")
local seri = require("serialization")
local gpu = component.gpu

------------------------------------------------------------------------------

local lang = {
	
}

local applications

local padColor = 0x262626
local installerScale = 1

local timing = 0.2

-----------------------------СТАДИЯ ПОДГОТОВКИ-------------------------------------------

--ЗАГРУЗОЧКА С ГИТХАБА
local function getFromGitHub(url, path)
	local sContent = ""
	local result, response = pcall(internet.request, url)
	if not result then
		return nil
	end

	if fs.exists(path) then fs.remove(path) end
	fs.makeDirectory(fs.path(path))
	local file = io.open(path, "w")

	for chunk in response do
		file:write(chunk)
		sContent = sContent .. chunk
	end

	file:close()

	return sContent
end

--БЕЗОПАСНАЯ ЗАГРУЗОЧКА
local function getFromGitHubSafely(url, path)
	local success, sRepos = pcall(getFromGitHub, url, path)
	if not success then
		io.stderr:write("Could not connect to the Internet. Please ensure you have an Internet connection.")
		return -1
	end
	return sRepos
end

--ЗАГРУЗОЧКА С ПАСТЕБИНА
local function getFromPastebin(paste, filename)
	local cyka = ""
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
			cyka = cyka .. chunk
		end
		f:close()
		--io.write("Saved data to " .. filename .. "\n")
	else
		f:close()
		fs.remove(filename)
		io.stderr:write("HTTP request failed: " .. response .. "\n")
	end

	return cyka
end

local GitHubUserUrl = "https://raw.githubusercontent.com/"

getFromGitHubSafely(GitHubUserUrl .. "IgorTimofeev/OpenComputers/master/lib/ecs.lua", "lib/ecs.lua")

local ecs = require("ECSAPI")

ecs.setScale(installerScale)

local xSize, ySize = gpu.getResolution()
local windowWidth = 80
local windowHeight = 2 + 16 + 2 + 3 + 2
local xWindow, yWindow = math.floor(xSize / 2 - windowWidth / 2), math.ceil(ySize / 2 - windowHeight / 2)
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

--------------------------СТАДИЯ ЗАГРУЗКИ НУЖНЫХ ПАКЕТОВ-----------------------
	
if not fs.exists("System/OS/Installer/OK.png") then

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

	--local response = getSafe(GitHubUserUrl .. "IgorTimofeev/OpenComputers/master/Applications.txt", "System/OS/Applications.txt")
	
	local preLoadApi = {
		{ paste = "IgorTimofeev/OpenComputers/master/lib/image.lua", path = "lib/image.lua" },
		--{ paste = "IgorTimofeev/OpenComputers/master/Installer/Languages.png", path = "System/OS/Installer/Languages.png" },
		{ paste = "IgorTimofeev/OpenComputers/master/Installer/OK.png", path = "System/OS/Installer/OK.png" },
		{ paste = "IgorTimofeev/OpenComputers/master/Installer/Downloading.png", path = "System/OS/Installer/Downloading.png" },
		{ paste = "IgorTimofeev/OpenComputers/master/Installer/OS_Logo.png", path = "System/OS/Installer/OS_Logo.png" },
		{ paste = "IgorTimofeev/OpenComputers/master/MineOS/License.txt", path = "System/OS/License.txt" },
	}

	local countOfAll = #preLoadApi

	for i = 1, countOfAll do

		local percent = i / countOfAll * 100
		ecs.progressBar(xBar, yBar, barWidth, 1, 0xcccccc, ecs.colors.blue, percent)

		if fs.exists(preLoadApi[i]["path"]) then fs.remove(preLoadApi[i]["path"]) end
		fs.makeDirectory(fs.path(preLoadApi[i]["path"]))
		getFromGitHubSafely(GitHubUserUrl .. preLoadApi[i]["paste"], preLoadApi[i]["path"])

	end

end

applications = seri.unserialize(getFromPastebin("3j2x4dDn", "System/OS/Applications.txt"))

local image = require("image")

local imageOS = image.load("System/OS/Installer/OS_Logo.png")
--local imageLanguages = image.load("System/OS/Installer/Languages.png")
local imageDownloading = image.load("System/OS/Installer/Downloading.png")
local imageOK = image.load("System/OS/Installer/OK.png")

------------------------------СТАВИТЬ ЛИ ОСЬ------------------------------------

do
	ecs.clearScreen(padColor)
	clear()

	image.draw(math.ceil(xSize / 2 - 15), yWindow + 2, imageOS)

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
	
	--Откуда рисовать условия согл
	local from = 1
	local xText, yText, TextWidth, TextHeight = xWindow + 4, yWindow + 2, windowWidth - 8, windowHeight - 10

	--Читаем файл с лиц соглл
	local lines = {}
	local file = io.open("System/OS/License.txt", "r")
	for line in file:lines() do
		table.insert(lines, line)
	end
	file:close()

	--image.draw(math.ceil(xSize / 2 - 30), yWindow + 2, imageLanguages)
	--ecs.selector(math.floor(xSize / 2 - 10), yWindowEnd - 5, 20, "Russian", {"English", "Russian"}, 0xffffff, 0x000000, true)

	--Штуку рисуем
	ecs.textField(xText, yText, TextWidth, TextHeight, lines, from)

	--Инфо рисуем
	ecs.centerText("x", yWindowEnd - 5 ,"Принимаете ли вы условия лицензионного соглашения?")

	--кнопа
	drawButton("Принимаю",false)

	while true do
		local e = { event.pull() }
		if e[1] == "touch" then
			if ecs.clickedAtArea(e[3], e[4], obj["buttons"]["Принимаю"][1], obj["buttons"]["Принимаю"][2], obj["buttons"]["Принимаю"][3], obj["buttons"]["Принимаю"][4]) then
				drawButton("Принимаю", true)
				os.sleep(timing)
				break
			end
		elseif e[1] == "scroll" then
			if e[5] == -1 then
				if from < #lines then from = from + 1; ecs.textField(xText, yText, TextWidth, TextHeight, lines, from) end
			else
				if from > 1 then from = from - 1; ecs.textField(xText, yText, TextWidth, TextHeight, lines, from) end
			end
		end
	end
end

--------------------------СТАДИЯ ЗАГРУЗКИ-----------------------------------

do

	local barWidth = math.floor(windowWidth * 2 / 3)
	local xBar = math.floor(xSize/2-barWidth/2)
	local yBar = yWindowEnd - 3

	local function drawInfo(x, y, info)
		ecs.square(x, y, barWidth, 1, ecs.windowColors.background)
		ecs.colorText(x, y, ecs.colors.gray, info)
	end

	ecs.blankWindow(xWindow,yWindow,windowWidth,windowHeight)

	image.draw(math.floor(xSize/2 - 33), yWindow + 2, imageDownloading)

	ecs.colorTextWithBack(xBar, yBar - 1, ecs.colors.gray, ecs.windowColors.background, "Установка OS")
	ecs.progressBar(xBar, yBar, barWidth, 1, 0xcccccc, ecs.colors.blue, 0)
	os.sleep(timing)

	for app = 1, #applications do
		--ВСЕ ДЛЯ ГРАФОНА
		drawInfo(xBar, yBar + 1, "Загрузка "..applications[app]["name"])
		local percent = app / #applications * 100
		ecs.progressBar(xBar, yBar, barWidth, 1, 0xcccccc, ecs.colors.blue, percent)

		--ВСЕ ДЛЯ ЗАГРУЗКИ
		local path = applications[app]["name"]
		if fs.exists(path) then fs.remove(path) end

		--Если тип = приложение
		if applications[app]["type"] == "Application" then
			fs.makeDirectory(path..".app/Resources")
			getFromGitHubSafely(GitHubUserUrl .. applications[app]["url"], path..".app/"..fs.name(applications[app]["name"]..".lua"))
			getFromGitHubSafely(GitHubUserUrl .. applications[app]["icon"], path..".app/Resources/Icon.png")
			if applications[app]["resources"] then
				for i = 1, #applications[app]["resources"] do
					getFromGitHubSafely(GitHubUserUrl .. applications[app]["resources"][i]["url"], path..".app/Resources/"..applications[app]["resources"][i]["name"])
				end
			end

		--Если тип = другой, чужой, а мб и свой пастебин
		elseif applications[app]["type"] == "Pastebin" then
			fs.remove(applications[app]["name"])
			fs.makeDirectory(fs.path(applications[app]["name"]))
			getFromPastebin(applications[app]["url"], applications[app]["name"])

		--А если че-то другое
		else
			getFromGitHubSafely(GitHubUserUrl .. applications[app]["url"], path)
		end
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
