local component = require("component")
local computer = require("computer")
local term = require("term")
local unicode = require("unicode")
local event = require("event")
local fs = require("filesystem")
local internet = require("internet")
local seri = require("serialization")
local gpu = component.gpu

-----------------Проверка компа на соответствие сис. требованиям--------------------------

--Создаем массив говна
local govno = {}

print(" ")
print("Analyzing computer for matching system requirements...")

--Проверяем GPU
if gpu.maxResolution() < 150 then table.insert(govno, "Bad GPU - this OS requires Tier 3 GPU.") end

--Проверяем экран
if gpu.getDepth() < 8 and gpu.maxResolution() < 150 then table.insert(govno, "Bad Screen - this OS requires Tier 3 screen.") end

--Проверяем оперативку
if math.floor(computer.totalMemory() / 1024 ) < 2048 then table.insert(govno, "Not enough RAM - this OS requires at least 2048 KB RAM.") end

if fs.get("bin/edit.lua") == nil or fs.get("bin/edit.lua").isReadOnly() then table.insert(govno, "You can't install MineOS on floppy disk. Run \"install\" in command line and install OpenOS from floppy to HDD first. After that you're be able to install MineOS from Pastebin.") end

--Если нашло какое-то несоответствие сис. требованиям, то написать, что именно не так
if #govno > 0 then
  print(" ")
  for i = 1, #govno do
    print(govno[i])
  end
  print(" ")
  return
else
  print("Done, everything's good. Proceed to downloading.")
  print(" ")
end

------------------------------------------------------------------------------------------

local lang

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
    io.stderr:write("Can't download \"" .. url .. "\"!\n")
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


--------------------------------- Стадия стартовой загрузки всего необходимого ---------------------------------


local preLoadApi = {
  { paste = "IgorTimofeev/OpenComputers/master/lib/ECSAPI.lua", path = "lib/ECSAPI.lua" },
  { paste = "IgorTimofeev/OpenComputers/master/lib/colorlib.lua", path = "lib/colorlib.lua" },
  { paste = "IgorTimofeev/OpenComputers/master/lib/image.lua", path = "lib/image.lua" },
  { paste = "IgorTimofeev/OpenComputers/master/lib/config.lua", path = "lib/config.lua" },
  { paste = "IgorTimofeev/OpenComputers/master/MineOS/Icons/Languages.pic", path = "MineOS/System/OS/Icons/Languages.pic" },
  { paste = "IgorTimofeev/OpenComputers/master/MineOS/Icons/OK.pic", path = "MineOS/System/OS/Icons/OK.pic" },
  { paste = "IgorTimofeev/OpenComputers/master/MineOS/Icons/Downloading.pic", path = "MineOS/System/OS/Icons/Downloading.pic" },
  { paste = "IgorTimofeev/OpenComputers/master/MineOS/Icons/OS_Logo.pic", path = "MineOS/System/OS/Icons/OS_Logo.pic" },
}

print("Downloading file list")
applications = seri.unserialize(getFromGitHubSafely(GitHubUserUrl .. "IgorTimofeev/OpenComputers/master/Applications.txt", "MineOS/System/OS/Applications.txt"))
print(" ")

for i = 1, #preLoadApi do
  print("Downloading must-have files (" .. fs.name(preLoadApi[i].path) .. ")")
  getFromGitHubSafely(GitHubUserUrl .. preLoadApi[i].paste, preLoadApi[i].path)
end

print(" ")

_G.ecs = require("ECSAPI")
_G.image = require("image")
_G.config = require("config")

local imageOS = image.load("MineOS/System/OS/Icons/OS_Logo.pic")
local imageLanguages = image.load("MineOS/System/OS/Icons/Languages.pic")
local imageDownloading = image.load("MineOS/System/OS/Icons/Downloading.pic")
local imageOK = image.load("MineOS/System/OS/Icons/OK.pic")

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

local function drawButton(name, isPressed)
  local buttonColor = 0x888888
  if isPressed then buttonColor = ecs.colors.blue end
  local d = { ecs.drawAdaptiveButton("auto", yWindowEnd - 3, 2, 1, name, buttonColor, 0xffffff) }
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


------------------------------ВЫБОР ЯЗЫКА------------------------------------

ecs.prepareToExit()

local downloadWallpapers, showHelpTips = false, false

do

  clear()

  image.draw(math.ceil(xSize / 2 - 30), yWindow + 2, imageLanguages)

  --кнопа
  drawButton("Select language",false)

  waitForClickOnButton("Select language")

  local data = ecs.universalWindow("auto", "auto", 36, 0x262626, true, {"EmptyLine"}, {"CenterText", ecs.colors.orange, "Select language"}, {"EmptyLine"}, {"Select", 0xFFFFFF, ecs.colors.green, "Russian", "English"}, {"EmptyLine"}, {"CenterText", ecs.colors.orange, "Change some OS properties"}, {"EmptyLine"}, {"Switch", 0xF2B233, 0xffffff, 0xFFFFFF, "Download wallpapers", true}, {"EmptyLine"}, {"Switch", 0xF2B233, 0xffffff, 0xFFFFFF, "Show help tips in OS", true}, {"EmptyLine"}, {"Button", {ecs.colors.green, 0xffffff, "OK"}})
  downloadWallpapers, showHelpTips = data[2], data[3]

  --УСТАНАВЛИВАЕМ НУЖНЫЙ ЯЗЫК
  _G.OSSettings = { showHelpOnApplicationStart = showHelpTips, language = data[1] }
  ecs.saveOSSettings()

  --Качаем язык
  ecs.info("auto", "auto", " ", " Installing language packages...")
  local pathToLang = "MineOS/System/OS/Installer/Language.lang"
  getFromGitHubSafely(GitHubUserUrl .. "IgorTimofeev/OpenComputers/master/Installer/" .. _G.OSSettings.language .. ".lang", pathToLang)
  getFromGitHubSafely(GitHubUserUrl .. "IgorTimofeev/OpenComputers/master/MineOS/License/" .. _G.OSSettings.language .. ".txt", "MineOS/System/OS/License.txt")
  
  --Ставим язык
  lang = config.readAll(pathToLang)

end


------------------------------СТАВИТЬ ЛИ ОСЬ------------------------------------

do
  clear()

  image.draw(math.ceil(xSize / 2 - 15), yWindow + 2, imageOS)

  --Текстик по центру
  gpu.setBackground(ecs.windowColors.background)
  gpu.setForeground(ecs.colors.gray)
  ecs.centerText("x", yWindowEnd - 5 , lang.beginOsInstall)

  --кнопа
  drawButton("->",false)

  waitForClickOnButton("->")

end

------------------------------ЛИЦ СОГЛАЩЕНЬКА------------------------------------------

do
  clear()
  
  --Откуда рисовать условия согл
  local from = 1
  local xText, yText, TextWidth, TextHeight = xWindow + 4, yWindow + 2, windowWidth - 8, windowHeight - 7

  --Читаем файл с лиц соглл
  local lines = {}
  local file = io.open("MineOS/System/OS/License.txt", "r")
  for line in file:lines() do
    table.insert(lines, line)
  end
  file:close()

  --Штуку рисуем
  ecs.textField(xText, yText, TextWidth, TextHeight, lines, from, 0xffffff, 0x262626, 0x888888, ecs.colors.blue)

  --Инфо рисуем
  --ecs.centerText("x", yWindowEnd - 5 ,"Принимаете ли вы условия лицензионного соглашения?")

  --кнопа
  drawButton(lang.acceptLicense, false)

  while true do
    local e = { event.pull() }
    if e[1] == "touch" then
      if ecs.clickedAtArea(e[3], e[4], obj["buttons"][lang.acceptLicense][1], obj["buttons"][lang.acceptLicense][2], obj["buttons"][lang.acceptLicense][3], obj["buttons"][lang.acceptLicense][4]) then
        drawButton(lang.acceptLicense, true)
        os.sleep(timing)
        break
      end
    elseif e[1] == "scroll" then
      if e[5] == -1 then
        if from < #lines then from = from + 1; ecs.textField(xText, yText, TextWidth, TextHeight, lines, from, 0xffffff, 0x262626, 0x888888, ecs.colors.blue) end
      else
        if from > 1 then from = from - 1; ecs.textField(xText, yText, TextWidth, TextHeight, lines, from, 0xffffff, 0x262626, 0x888888, ecs.colors.blue) end
      end
    end
  end
end

-------------------------- Подготавливаем файловую систему ----------------------------------

--Создаем стартовые пути и прочие мелочи чисто для эстетики
local desktopPath = "MineOS/Desktop/"
local dockPath = "MineOS/System/OS/Dock/"
local applicationsPath = "MineOS/Applications/"
local picturesPath = "MineOS/Pictures/"

fs.remove(desktopPath)
fs.remove(dockPath)

fs.makeDirectory(desktopPath .. "My files")
fs.makeDirectory(picturesPath)
fs.makeDirectory(dockPath)

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

  ecs.colorTextWithBack(xBar, yBar - 1, ecs.colors.gray, ecs.windowColors.background, lang.osInstallation)
  ecs.progressBar(xBar, yBar, barWidth, 1, 0xcccccc, ecs.colors.blue, 0)
  os.sleep(timing)

  for app = 1, #applications do
    --ВСЕ ДЛЯ ГРАФОНА
    drawInfo(xBar, yBar + 1, lang.downloading .. " " .. applications[app]["name"])
    local percent = app / #applications * 100
    ecs.progressBar(xBar, yBar, barWidth, 1, 0xcccccc, ecs.colors.blue, percent)

    --ВСЕ ДЛЯ ЗАГРУЗКИ
    local path = applications[app]["name"]
    fs.remove(path .. ".app")

    --Если тип = приложение
    if applications[app]["type"] == "Application" then
      fs.makeDirectory(path..".app/Resources")
      getFromGitHubSafely(GitHubUserUrl .. applications[app]["url"], path .. ".app/" .. fs.name(applications[app]["name"] .. ".lua"))
      getFromGitHubSafely(GitHubUserUrl .. applications[app]["icon"], path .. ".app/Resources/Icon.pic")
      
      --Если есть ресурсы, то загружаем ресурсы
      if applications[app]["resources"] then
        for i = 1, #applications[app]["resources"] do
          getFromGitHubSafely(GitHubUserUrl .. applications[app]["resources"][i]["url"], path..".app/Resources/"..applications[app]["resources"][i]["name"])
        end
      end

      --Если есть файл "о программе", то грузим и его
      if applications[app].about then
        getFromGitHubSafely(GitHubUserUrl .. applications[app].about, path .. ".app/Resources/About.txt")
      end 

      --Если имеется режим создания ярлыка, то создаем его
      if applications[app].createShortcut then
        if applications[app].createShortcut == "dock" then
          ecs.createShortCut(dockPath .. fs.name(applications[app].name) .. ".lnk", applications[app].name .. ".app")
        else
          ecs.createShortCut(desktopPath .. fs.name(applications[app].name) .. ".lnk", applications[app].name .. ".app")
        end
      end

    --Если тип = другой, чужой, а мб и свой пастебин
    elseif applications[app]["type"] == "Pastebin" then
      fs.remove(applications[app]["name"])
      fs.makeDirectory(fs.path(applications[app]["name"]))
      getFromPastebin(applications[app]["url"], applications[app]["name"])

    --Если обои
    elseif applications[app]["type"] == "Wallpaper" then
      if downloadWallpapers then
        getFromGitHubSafely(GitHubUserUrl .. applications[app]["url"], path)
      end
    --А если че-то другое
    else
      getFromGitHubSafely(GitHubUserUrl .. applications[app]["url"], path)
    end
  end

  os.sleep(timing)
end

--Создаем базовые обои рабочего стола
ecs.createShortCut(desktopPath .. "Pictures.lnk", picturesPath)
if downloadWallpapers then ecs.createShortCut("MineOS/System/OS/Wallpaper.lnk", picturesPath .. "ChristmasTree.pic") end

--Автозагрузка
local file = io.open("autorun.lua", "w")
file:write("local success, reason = pcall(loadfile(\"OS.lua\")); if not success then print(\"Ошибка: \" .. tostring(reason)) end")
file:close()

--------------------------СТАДИЯ ПЕРЕЗАГРУЗКИ КОМПА-----------------------------------

ecs.blankWindow(xWindow,yWindow,windowWidth,windowHeight)

image.draw(math.floor(xSize/2 - 16), math.floor(ySize/2 - 11), imageOK)

--Текстик по центру
gpu.setBackground(ecs.windowColors.background)
gpu.setForeground(ecs.colors.gray)
ecs.centerText("x",yWindowEnd - 5, lang.needToRestart)

--Кнопа
drawButton(lang.restart, false)
waitForClickOnButton(lang.restart)
ecs.prepareToExit()

computer.shutdown(true)