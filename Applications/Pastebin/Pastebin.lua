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
-- local computer = require("computer")
-- local keyboard = require("keyboard")
-- local image = require("image")

local gpu = component.gpu

--//replace 1,3,12,11,13,7,16,15,14,582,56,73,166,165,21,167,168,228,229,10,11 0

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

--------------------------------------------------------------------------------------------------------------------------

-- --ЗАГРУЗИТЬ ФАЙЛ С ПАСТЕБИНА
-- local function get(pasteId, filename)
--   local f, reason = io.open(filename, "w")
--   if not f then
--     io.stderr:write("Failed opening file for writing: " .. reason)
--     return
--   end

--   --io.write("Downloading from pastebin.com... ")
--   local url = "http://pastebin.com/raw.php?i=" .. pasteId
--   local result, response = pcall(internet.request, url)
--   if result then
--     --io.write("success.\n")
--     for chunk in response do
--       --if not options.k then
--         string.gsub(chunk, "\r\n", "\n")
--       --end
--       f:write(chunk)
--     end

--     f:close()
--     --io.write("Saved data to " .. filename .. "\n")
--   else
--     --io.write("failed.\n")
--     f:close()
--     fs.remove(filename)
--     io.stderr:write("HTTP request failed: " .. response .. "\n")
--   end
-- end

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

-- --ЗАПУСТИТЬ ПРОЖКУ
-- local function run(pasteId, ...)
--   local tmpFile = os.tmpname()
--   get(pasteId, tmpFile)

--   ecs.prepareToExit()

--   local success, reason = shell.execute(tmpFile, nil, ...)
--   ecs.prepareToExit()
--   if not success then
--   	print("Ошибка при выполнении программы. Причина:")
--   	print(" ")
--     print(reason)
--   else
--   	print("Программа выполена успешно! Нажмите любую клавишу, чтобы продолжить.")
--   end
--   fs.remove(tmpFile)

--   event.pull("key_down")

-- end

-- --ЗАГРУЗИТЬ ФАЙЛ НА ПАСТЕБИН
-- local function put()
-- 	local file = fs.open(filename,"r")
--     local sName = fs.getName( filename )
--     local sText = file.readAll()
--     file.close()
    
--     local devKey = "0ec2eb25b6166c0c27a394ae118ad829"
--     local response = http.post(
--         "http://pastebin.com/api/api_post.php", 
--         "api_option=paste&"..
--         "api_dev_key="..devKey.."&"..
--         "api_user_key="..userkey.."&"..
--         "api_paste_private=0&"..
--         "api_paste_format=lua&"..
--         "api_paste_name="..textutils.urlEncode(sName).."&"..
--         "api_paste_code="..textutils.urlEncode(sText)
--     )
        
--     if response then
--         local sResponse = response.readAll()
--         response.close()                  
--         local sCode = string.match( sResponse, "[^/]+$" )
--         return sCode
--     else
--         return false
--     end
-- end

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

local function convertUnixTime(time)
    local govno = time + 62167144220
    local year = math.floor(govno/31556926)
    local ostatok = govno % 31556926
    local month = math.ceil(ostatok/2629743)
    ostatok = ostatok % 2629743
    local day = math.ceil(ostatok/86400)+2
    return day,month,year
end

local xPos, yPos
local widthTitle
local widthOthers
local xDate
local xDownloads
local xSyntax

local function displayPaste(i, background)
	--Нарисовать цветной кружочек
	local color = ecs.colors.green
	if tonumber(MyMassivWithPastes[i]["paste_private"]) == 1 then
		color = ecs.colors.red
	end
	ecs.colorText(xPos, yPos, color, "●")
	color = nil

	--Нарисовать имя пасты
	ecs.colorText(xPos + 2, yPos, 0x000000, ecs.stringLimit("end", MyMassivWithPastes[i]["paste_title"], widthTitle - 3))
	
	--Нарисовать дату пасты
	local day, month, year = convertUnixTime(tonumber(MyMassivWithPastes[i]["paste_date"]))
	gpu.set(xDate, yPos, day.."."..month.."."..year)

	--Нарисовать Хитсы
	gpu.set(xDownloads, yPos, MyMassivWithPastes[i]["paste_hits"])

	--Нарисовать формат
	gpu.set(xSyntax, yPos, MyMassivWithPastes[i]["paste_format_long"])
end

--Нарисовать пасты
local function displayPastes(from, to)

	--Стартовые коорды
	xPos, yPos = 2, 6

	--Размеры таблицы
	widthTitle = math.floor((xSize - 2) / 2)
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

	--Все пасты рисуем
	for i = from, to do

		displayPaste(i, 0xffffff)

		--Нарисовать разделитель
		ecs.colorText(1, yPos + 1, 0x999999, string.rep("─", xSize - 2))

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
	local tabColor1 = 0x103258
	local tabColor2 = 0x034879
	local tabTextColor = 0xffffff

	--Полосочки
	ecs.square(1, 1, xSize, 1, tabColor1)

	gpu.setBackground(tabColor2)
	gpu.setForeground( 0x023a61 )
	gpu.fill(1, 2, xSize, 3, "⁕")

	ecs.square(1, 5, xSize, 1, tabColor1)

	--Листочек
	local sheetWidth = 6
	gpu.setForeground(0x000000)
	gpu.setBackground(0xffffff)

	gpu.set(2, 2, getRandomCifri(sheetWidth))
	gpu.set(3, 3, getRandomCifri(sheetWidth))
	gpu.set(4, 4, getRandomCifri(sheetWidth))

	--Надписи всякие
	ecs.colorTextWithBack(2, 1, tabTextColor - 0x333333, tabColor1, "#1 paste tool since 2002")
	ecs.colorTextWithBack(11, 3, tabTextColor, tabColor2, "PASTEBIN")

end

local function inputPassword()
	local massiv = ecs.input("auto", "auto", 20, "Войти в Pastebin", {"input", "Логин", ""},  {"input", "Пароль", ""})
	username = massiv[1]
	password = massiv[2]
end

local function analyseConfig()
	if fs.exists(pathToConfig) then
		local massiv = config.readAll(pathToConfig)
		username = massiv.username
		password = massiv.password
		massiv = nil
	else
		fs.makeDirectory(fs.path(pathToConfig))
		inputPassword()
		config.write(pathToConfig, "username", username)
		config.write(pathToConfig, "password", password)
	end
end

local function waitForSuccessLogin()
	while true do

		analyseConfig()
		local success, reason = loginToAccount(username, password)

		if success then
			break
		else
			if string.match(reason, "^Bad API request, ") then
				reason = string.sub(reason, 18, -1)
			end

			if reason == "invalid login" then fs.remove(pathToConfig); ecs.error("Неверное сочетание логин/пароль!") end
		end
		
	end
end

local function drawAll()
	ecs.clearScreen(0xffffff)
	drawTopBar()
end


--------------------------------------------------------------------------------------------------------------------------

drawAll()
waitForSuccessLogin()

getFileListFromPastebin(10)

displayPastes(1, 10)

event.pull("key_down")

--------------------------------------------------------------------------------------------------------------------------
