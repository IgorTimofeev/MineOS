local component = require("component")
local event = require("event")
local term = require("term")
local unicode = require("unicode")
local ecs = require("ECSAPI")
local fs = require("filesystem")
local shell = require("shell")
local internet = require("internet")
local context = require("context")
local xml = require("xmlParser")
local config = require("config")
local unixtime = require("unixtime")
local SHA2 = require("SHA2")
-- local computer = require("computer")
-- local keyboard = require("keyboard")
-- local image = require("image")

local gpu = component.gpu

--//replace 1,3,12,11,13,7,16,15,14,582,56,73,166,165,21,167,168,228,229,10,11 0
--
--------------------------------------------------------------------------------------------------------------------------

local xSize, ySize = gpu.getResolution()
local centerX, centerY = math.floor(xSize / 2), math.floor(ySize / 2)

local username = nil
local password = nil

local userkey = nil
local devKey = "e98db6da803203282d172156bc46137c"
local pastebin_url = nil

local isNotLoggedIn = true

local pathToConfig = "System/Pastebin/Login.cfg"

--МАССИВ СО ВСЕМИ ПАСТАМИ С ПАСТЕБИНА
local MyMassivWithPastes = {}
local drawPastesFrom = 1

local tabColor1 = 0x103258
local tabColor2 = 0x034879
local tabTextColor = 0xffffff

--------------------------------------------------------------------------------------------------------------------------

--СОЗДАНИЕ ОБЪЕКТОВ
local obj = {}
local function newObj(class, name, ...)
	obj[class] = obj[class] or {}
	obj[class][name] = {...}
end

--ЗАГРУЗИТЬ ФАЙЛ С ПАСТЕБИНА
local function get(pasteId, filename)
  local f, reason = io.open(filename, "w")
  if not f then
    io.stderr:write("Failed opening file for writing: " .. reason)
    return
  end

  --io.write("Downloading from pastebin.com... ")
  local url = "http://pastebin.com/raw.php?i=" .. pasteId
  local result, response = pcall(internet.request, url)
  if result then
    --io.write("success.\n")
    for chunk in response do
      --if not options.k then
        chunk = string.gsub(chunk, "\r\n", "\n")
        chunk = string.gsub(chunk, "	", "  ")
      --end
      f:write(chunk)
    end

    f:close()
    --io.write("Saved data to " .. filename .. "\n")
  else
    --io.write("failed.\n")
    f:close()
    fs.remove(filename)
    io.stderr:write("HTTP request failed: " .. response .. "\n")
  end
end

-- This makes a string safe for being used in a URL.
local function encode(code)
  if code then
    code = string.gsub(code, "([^%w ])", function (c)
      return string.format("%%%02X", string.byte(c))
    end)
    code = string.gsub(code, " ", "+")
  end
  return code 
end



--Удалить файлецкий
local function delete(paste)
	local result, response = pcall(internet.request,
	    "http://pastebin.com/api/api_post.php", 
	    "api_option=delete&"..
        "api_dev_key="..devKey.."&"..
        "api_user_key="..userKey.."&"..
        "api_paste_key="..paste
	)

	if result then
		return true
	else
		ecs.error("Отсутствует соединение с Pastebin.com")
		return false
	end
end

--ЗАЛОГИНИТЬСЯ В АККАУНТ
local function loginToAccount(username, password)

	--print("Логинюсь в пастебине... ")
	local result, response = pcall(internet.request,
	    "http://pastebin.com/api/api_login.php", 
	    "api_dev_key="..devKey..
	    "&api_user_name="..username..
	    "&api_user_password="..password
	)

	if result then
		--print("Запрос на пастебин пришел!")
		local info = ""
		for chunk in response do
			info = info .. chunk
		end
		if string.match(info, "^Bad API request, ") then
			--io.write(info)
			return false, info
		--ЕСЛИ ВСЕ ЗАЕБОК
		else
			--print("Получен юзеркей!")
			userKey = info
			--print("Вот так оно выглядит: "..info)
			return true
		end
	else
		--print("Хуйня произошла. Либо URL неверный, либо пастебин недоступен.\n")
		--io.stderr:write(response)
		return false, response
	end

end

--ЗАГРУЗКА СПИСКА ФАЙЛОВ
local function getFileListFromPastebin(countOfFilesToShow)
	local result, response = pcall(internet.request,
        "http://pastebin.com/api/api_post.php",
        "api_dev_key="..devKey..
        "&api_user_key="..userKey..
        "&api_results_limit="..countOfFilesToShow..
        "&api_option=list"
    )

	--КИНУТЬ ОШИБКУ, ЕСЛИ ЧЕТ НЕ ТАК
   	if not result then io.stderr:write( response ) end

   	--ПРОЧИТАТЬ ОТВЕТ С СЕРВЕРА ПАСТЕБИНА
   	local info = ""
   	for chunk in response do
   		info = info .. chunk
   	end

   	--РАСПАСИТЬ ХМЛ
	local x = xml.collect(info)

	--ЗАХУЯРИТЬ МАССИВ С ПАСТАМИ
    MyMassivWithPastes = {}
	for pasteID = 1, #x do
		MyMassivWithPastes[pasteID]={}
		MyMassivWithPastes[pasteID]["paste_key"] = x[pasteID][1][1]
		MyMassivWithPastes[pasteID]["paste_date"] = x[pasteID][2][1]
		MyMassivWithPastes[pasteID]["paste_title"] = x[pasteID][3][1]
		MyMassivWithPastes[pasteID]["paste_size"] = x[pasteID][4][1]
		MyMassivWithPastes[pasteID]["paste_expire_date"] = x[pasteID][5][1]
		MyMassivWithPastes[pasteID]["paste_private"] = x[pasteID][6][1]
		MyMassivWithPastes[pasteID]["paste_format_long"] = x[pasteID][7][1]
		MyMassivWithPastes[pasteID]["paste_format_short"] = x[pasteID][8][1]
		MyMassivWithPastes[pasteID]["paste_url"] = x[pasteID][9][1]
		MyMassivWithPastes[pasteID]["paste_hits"] = x[pasteID][10][1]
	end
end

local xPos, yPos
local widthTitle
local widthOthers
local xDate
local xDownloads
local xSyntax
local maxPastesCountToShow = math.floor((ySize - 7) / 2)

local function displayPaste(i, background, foreground)

	ecs.square(1, yPos, xSize - 2, 1, background)

	--Нарисовать цветной кружочек
	local color = ecs.colors.green
	if tonumber(MyMassivWithPastes[i]["paste_private"]) == 1 then
		color = ecs.colors.red
	end
	ecs.colorText(xPos, yPos, color, "●")
	color = nil

	--Нарисовать имя пасты
	ecs.colorText(xPos + 2, yPos, foreground, ecs.stringLimit("end", MyMassivWithPastes[i]["paste_title"], widthTitle - 3))
	
	--Нарисовать дату пасты
	local date = unixtime.convert(tonumber(MyMassivWithPastes[i]["paste_date"]))
	gpu.set(xDate, yPos, date)

	--Нарисовать Хитсы
	gpu.set(xDownloads, yPos, MyMassivWithPastes[i]["paste_hits"])

	--Нарисовать формат
	gpu.set(xSyntax, yPos, MyMassivWithPastes[i]["paste_format_long"])
end

--Нарисовать пасты
local function displayPastes(from)

	obj["Pastes"] = nil

	--Стартовые коорды
	xPos, yPos = 2, 6

	--Размеры таблицы
	widthTitle = math.floor((xSize - 2) / 2) + 5
	widthOthers = math.floor((xSize - 2 - widthTitle) / 3)
	xDate = xPos + widthTitle
	xDownloads = xDate + widthOthers
	xSyntax = xDownloads + widthOthers

	--Цвет фона на нужный сразу
	gpu.setBackground(0xffffff)

	--Стартовая инфотаблица - ну, имя там, размер, дата и прочее
	ecs.colorText(xPos, yPos, 0x990000, "Имя")
	gpu.set(xDate, yPos, "Дата")
	gpu.set(xDownloads, yPos, "Скачиваний")
	gpu.set(xSyntax, yPos, "Синтакс")

	ecs.colorText(1, yPos + 1, 0x990000, string.rep("─", xSize - 2))
	yPos = yPos + 2

	ecs.srollBar(xSize - 1, 6, 2, ySize - 5, #MyMassivWithPastes, from, 0xcccccc, ecs.colors.blue)

	--Все пасты рисуем
	for i = from, (from + maxPastesCountToShow - 1) do

		if MyMassivWithPastes[i] then
			displayPaste(i, 0xffffff, 0x000000)

			newObj("Pastes", i, 1, yPos, xSize - 2, yPos)

			--Нарисовать разделитель
			if i ~= (from + maxPastesCountToShow - 1) then ecs.colorText(1, yPos + 1, 0xcccccc, string.rep("─", xSize - 2)) end
		else
			ecs.square(1, yPos, xSize - 2, 2, 0xffffff)
		end

		yPos = yPos + 2
	end
end

local function getRandomCifri(length)
	local cifri = ""
	for i = 1, length do
		cifri = cifri .. tostring(math.random(0, 1))
	end
	return cifri
end

local function drawTopBar()

	--Полосочки
	ecs.square(1, 1, xSize, 1, tabColor1)

	gpu.setBackground(tabColor2)
	gpu.setForeground( tabColor1 )
	gpu.fill(1, 2, xSize, 3, "░")

	ecs.square(1, 5, xSize, 1, tabColor1)

	--Листочек
	local sheetWidth = 6
	gpu.setForeground(0x000000)
	gpu.setBackground(0xffffff)

	gpu.set(2, 2, getRandomCifri(sheetWidth))
	gpu.set(3, 3, getRandomCifri(sheetWidth))
	gpu.set(4, 4, getRandomCifri(sheetWidth))

	--Надписи всякие
	ecs.colorTextWithBack(2, 1, tabColor2, tabColor1, "#1 paste tool since 2002")
	ecs.colorTextWithBack(11, 3, tabTextColor, tabColor2, "PASTEBIN")
	local name = "⛨Загрузить новый файл"; newObj("TopButtons", name, ecs.drawAdaptiveButton(1, 5, 1, 0, name, tabColor1, tabTextColor))
	
	local xPos = xSize - 23
	if username then
		name = "Разлогиниться"; newObj("TopButtons", name, ecs.drawAdaptiveButton(xPos, 5, 1, 0, name, tabColor1, tabTextColor)); xPos = xPos + unicode.len(name) + 3
		name = "Выход"; newObj("TopButtons", name, ecs.drawAdaptiveButton(xPos, 5, 1, 0, name, tabColor1, tabTextColor)); xPos = xPos + unicode.len(name) + 3

		--Никнейм
		ecs.colorTextWithBack(xSize - 1 - unicode.len(username), 3, tabTextColor, tabColor2, username)
	end
end

local function clear()
	ecs.square(1, 6, xSize, ySize, 0xffffff)
end

local function inputPassword()
	--local massiv = ecs.input("auto", "auto", 20, "Войти в Pastebin", {"input", "Логин", ""},  {"input", "Пароль", ""})

	local data = ecs.universalWindow("auto", "auto", 24, tabColor1, true, {"EmptyLine"}, {"CenterText", 0xffffff, "Авторизация"}, {"EmptyLine"}, {"Input", 0xffffff, 0xccccff, "Логин"}, {"Input", 0xffffff, 0xccccff, "Пароль", "●"}, {"EmptyLine"}, {"Button", {tabColor2, 0xffffff, "Войти в аккаунт"}, {0x006dbf, 0xffffff, "Отмена"}})

	if data[3] == "Отмена" then return false end

	username = data[1] or ""
	password = data[2] or ""
	clear()

	return true
end

local function analyseConfig()
	if fs.exists(pathToConfig) then
		local massiv = config.readAll(pathToConfig)
		username = massiv.username
		password = massiv.password
		massiv = nil
	else
		fs.makeDirectory(fs.path(pathToConfig))
		local success = inputPassword()
		if not success then return false end
		config.write(pathToConfig, "username", username)
		config.write(pathToConfig, "password", password)
	end

	return true
end

local function waitForSuccessLogin()
	while true do

		local success = analyseConfig()
		if not success then return false end
		ecs.info("auto", "auto", " ", "Захожу в аккаунт...")
		local success, reason = loginToAccount(username, password)

		if success then
			break
		else
			if string.match(reason, "^Bad API request, ") then
				reason = string.sub(reason, 18, -1)
			end

			if reason == "invalid login" then fs.remove(pathToConfig); ecs.error("Неверное сочетание логин/пароль!"); clear() end
		end
		
	end

	return true
end

local function drawAll()
	ecs.clearScreen(0xffffff)
	drawTopBar()
end

local function viewPaste(i)
	local id = MyMassivWithPastes[i]["paste_key"]
	local tmp = "System/Pastebin/tempfile.lua"
	ecs.info("auto", "auto", " ", "Загружаю файл...")
	os.sleep(0.3)
	get(id, tmp)

	local file = io.open(tmp, "r")
	local lines = {}
	for line in file:lines() do
		table.insert(lines, line)
	end
	file:close()

	ecs.clearScreen(0xffffff)

	local from = 1

	local back = 0xbbbbbb

	ecs.square(1, 1, xSize, 1, back)
	gpu.setForeground(0xffffff)
	ecs.centerText("x", 1, "Просмотр "..id)
	ecs.colorTextWithBack(xSize, 1, 0x000000, back, "X")

	--ecs.error("#lines = ".. #lines)

	ecs.textField(1, 2, xSize, ySize - 1, lines, from, 0xffffff, 0x262626, 0xdddddd, ecs.colors.blue)

	fs.remove(tmp)

	while true do
		local e = {event.pull()}
		if e[1] == "scroll" then
			if e[5] == 1 then
				if from > 1 then from = from - 1; ecs.textField(1, 2, xSize, ySize - 1, lines, from, 0xffffff, 0x262626, 0xdddddd, ecs.colors.blue) end
			else
				if from < #lines then from = from + 1; ecs.textField(1, 2, xSize, ySize - 1, lines, from, 0xffffff, 0x262626, 0xdddddd, ecs.colors.blue) end
			end
		elseif e[1] == "touch" then
			if e[3] == (xSize) and e[4] == 1 then
				ecs.colorTextWithBack(xSize, 1, 0xffffff, back, "X")
				os.sleep(0.3)
				return
			end
		end
	end
end

local function launch(i)
	local tmp = "System/Pastebin/tempfile.lua"
	ecs.info("auto", "auto", " ", "Загружаю файл...")
	get(MyMassivWithPastes[i]["paste_key"], tmp)

	ecs.prepareToExit()
	local s, r = shell.execute(tmp)
	if not s then
		ecs.displayCompileMessage(1, r, true, false)
	else
		ecs.prepareToExit()
		print("Программа выполнена успешно. Нажмите любую клавишу, чтобы продолжить.")
		ecs.waitForTouchOrClick()
	end



	fs.remove(tmp)
end

--ЗАГРУЗИТЬ ФАЙЛ НА ПАСТЕБИН
local function upload(path, title)
	ecs.info("auto", "auto", " ", "Загружаю \""..fs.name(path).."\"...")
	local file = io.open(path, "r")
    local sText = file:read("*a")
    file:close()
    
    local result, response = pcall(internet.request,
        "http://pastebin.com/api/api_post.php", 
        "api_option=paste&"..
        "api_dev_key="..devKey.."&"..
        "api_user_key="..userKey.."&"..
        "api_paste_private=0&"..
        "api_paste_format=lua&"..
        "api_paste_name="..encode(title).."&"..
        "api_paste_code="..encode(sText)
    )
        
    if result then
    	--ecs.error(response)
    else
    	ecs.error("Отсутствует соединение с Pastebin.com")
        return false
    end
end


--------------------------------------------------------------------------------------------------------------------------

local pasteLoadLimit = 50
local args = {...}

drawAll()
if not waitForSuccessLogin() then ecs.prepareToExit(); return true end
drawTopBar()

if #args > 1 then
	if args[1] == "upload" or args[1] == "load" then
		if fs.exists(args[2]) and not fs.isDirectory(args[2]) then
			upload(args[2], fs.name(args[2]))
			os.sleep(5) -- Ждем, пока 100% прогрузится апи пастебина
		else
			ecs.error("Файл не существует или является директорией.")
			return
		end
	end
end

ecs.info("auto", "auto", " ", "Получаю список файлов...")
getFileListFromPastebin(pasteLoadLimit)

displayPastes(drawPastesFrom)

while true do
	local e = {event.pull()}
	if e[1] == "scroll" then
		if e[5] == 1 then
			if drawPastesFrom > 1 then drawPastesFrom = drawPastesFrom - 1; displayPastes(drawPastesFrom) end
		else
			if drawPastesFrom < pasteLoadLimit then drawPastesFrom = drawPastesFrom + 1; displayPastes(drawPastesFrom) end
		end
	elseif e[1] == "touch" then
		for key, val in pairs(obj["Pastes"]) do
			if ecs.clickedAtArea(e[3], e[4], obj["Pastes"][key][1], obj["Pastes"][key][2], obj["Pastes"][key][3], obj["Pastes"][key][4] ) then
				--ecs.error("key = "..key)
				yPos = obj["Pastes"][key][2]
				displayPaste(key, ecs.colors.blue, 0xffffff)

				if e[5] == 1 then
					local action = context.menu(e[3], e[4], {"Просмотр"}, "-", {"Запустить"}, {"Сохранить как"}, "-",{"Удалить"})

					if action == "Сохранить как" then
						local data = ecs.universalWindow("auto", "auto", 36, tabColor1, true, {"EmptyLine"}, {"CenterText", 0xffffff, "Сохранить как"}, {"EmptyLine"}, {"Input", 0xffffff, 0xccccff, "Имя"}, {"EmptyLine"}, {"Button", {0xffffff, 0xccccff, "OK"}} ) 
						local path = data[1]
						if path ~= nil or path ~= "" or path ~= " " then
							fs.makeDirectory(fs.path(path))
							local action2 = ecs.askForReplaceFile(path)
							ecs.info("auto", "auto", " ", "Загружаю файл...")
							if action2 == nil or action2 == "replace" then
								fs.remove(path)
								get(MyMassivWithPastes[key]["paste_key"], path)
								ecs.select("auto", "auto", " ", {{"Загрузка завершена."}}, {{"Заебись!"}})
							elseif action2 == "keepBoth" then
								get(MyMassivWithPastes[key]["paste_key"], fs.path(path).."(copy)"..fs.name(path))
							end
							drawAll()
							displayPastes(drawPastesFrom)
						else
							ecs.error("Сохранение не удалось: не указан путь.")
						end
					elseif action == "Удалить" then
						ecs.info("auto", "auto", " ", "Удаляю файл...")
						delete(MyMassivWithPastes[key]["paste_key"])
						os.sleep(5)
						ecs.info("auto", "auto", " ", "Перезагружаю список файлов...")
						getFileListFromPastebin(pasteLoadLimit)
						drawAll()
						displayPastes(drawPastesFrom)
					elseif action == "Просмотр" then
						viewPaste(key)
						drawAll()
						displayPastes(drawPastesFrom)
					elseif action == "Запустить" then
						launch(key)
						drawAll()
						displayPastes(drawPastesFrom)
					end

					displayPaste(key, 0xffffff, 0x000000)
				else
					--os.sleep(0.3)
					viewPaste(key)
					drawAll()
					displayPastes(drawPastesFrom)
				end

				break
			end
		end

		for key, val in pairs(obj["TopButtons"]) do
			if ecs.clickedAtArea(e[3], e[4], obj["TopButtons"][key][1], obj["TopButtons"][key][2], obj["TopButtons"][key][3], obj["TopButtons"][key][4] ) then
				ecs.drawAdaptiveButton(obj["TopButtons"][key][1], obj["TopButtons"][key][2], 1, 0, key, tabColor2, tabTextColor)

				os.sleep(0.3)

				if key == "Разлогиниться" then
					fs.remove("System/Pastebin/Login.cfg")
					drawAll()
					if not waitForSuccessLogin() then
						ecs.prepareToExit()
						return true		
					end
					drawTopBar()
					ecs.info("auto", "auto", " ", "Получаю список файлов...")
					getFileListFromPastebin(pasteLoadLimit)
					drawAll()
					displayPastes(drawPastesFrom)
				elseif key == "⛨Загрузить новый файл" then
					local data = ecs.universalWindow("auto", "auto", 36, tabColor1, true, {"EmptyLine"}, {"CenterText", 0xffffff, "Загрузить на Pastebin"}, {"EmptyLine"}, {"Input", 0xffffff, 0xccccff, "Путь к файлу"}, {"Input", 0xffffff, 0xccccff, "Имя на Pastebin"}, {"EmptyLine"}, {"Button", {tabColor2, 0xffffff, "OK"}}) 
					if fs.exists(data[1]) then
						if not fs.isDirectory(data[1]) then
							upload(data[1], data[2] or "Untitled")
							os.sleep(5)
							ecs.info("auto", "auto", " ", "Перезагружаю список файлов...")
							
							getFileListFromPastebin(pasteLoadLimit)
							drawAll()
							drawPastesFrom = 1
							displayPastes(drawPastesFrom)
						else
							ecs.error("Нельзя загружать папки.")
						end
					else
						ecs.error("Файл \""..fs.name(data[1]).."\" не существует.")
					end
				elseif key == "Выход" then
					ecs.prepareToExit()
					return true
				end

				drawTopBar()

				break
			end
		end
	end
end






--------------------------------------------------------------------------------------------------------------------------
