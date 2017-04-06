local component = require("component")
local computer = require("computer")
local unicode = require("unicode")
local event = require("event")
local fs = require("filesystem")
local serialization = require("serialization")
local shell = require("shell")
local args, options = shell.parse( ... )

------------------------------------- Проверка компа на соответствие сис. требованиям -------------------------------------

shell.execute("cd ..")
shell.setWorkingDirectory("")

print(" ")
print("Analyzing computer for matching system requirements...")

-- Создаем массив говна
local govno = {}
-- Чекаем архитектуру
-- local architecture = computer.getArchitecture()
-- if architecture ~= "Lua 5.2" then table.insert(govno, "You are using " .. architecture ..  " architecture. Take processor into your hands and switch it to \"Lua 5.2\", after that you will be able to install MineOS.") end
-- Проверяем, не планшет ли это
if component.isAvailable("tablet") then table.insert(govno, "Tablet PC detected: you can't install MineOS on tablet because of primitive GPU and Screen.") end
-- Проверяем GPU
if component.gpu.maxResolution() < 150 then table.insert(govno, "Bad GPU or Screen: MineOS requires Tier 3 GPU and Tier 3 Screen to give you full experience.") end
-- Проверяем оперативку
if math.floor(computer.totalMemory() / 1024 ) < 1024 then table.insert(govno, "Not enough RAM: MineOS requires at least 1024 KB RAM.") end
-- Проверяем, не флоппи-диск ли это
if fs.get("/bin/edit.lua") == nil or fs.get("/bin/edit.lua").isReadOnly() then table.insert(govno, "You can't install MineOS on floppy disk. Run \"install\" in command line and install OpenOS from floppy to HDD first. After that you're be able to install MineOS.") end

--Если нашло какое-то несоответствие сис. требованиям, то написать, что именно не так
if #govno > 0 and not options.skipcheck then
  print(" ")
  for i = 1, #govno do print(govno[i]) end
  print(" ")
  return
else
  print("Done, everything's good. Proceed to downloading.")
  print(" ")
end

------------------------------------- Создание базового дерьмища -------------------------------------

local lang
local applications
local padColor = 0x262626
local installerScale = 1
local timing = 0.2
local GitHubUserUrl = "https://raw.githubusercontent.com/"

local function internetRequest(url)
  local success, response = pcall(component.internet.request, url)
  if success then
    local responseData = ""
    while true do
      local data, responseChunk = response.read() 
      if data then
        responseData = responseData .. data
      else
        if responseChunk then
          return false, responseChunk
        else
          return true, responseData
        end
      end
    end
  else
    return false, reason
  end
end

--БЕЗОПАСНАЯ ЗАГРУЗОЧКА
local function getFromGitHubSafely(url, path)
  local success, reason = internetRequest(url)
  if success then
    fs.makeDirectory(fs.path(path) or "")
    fs.remove(path)
    local file = io.open(path, "w")
    file:write(reason)
    file:close()
    return reason
  else
    error("Can't download \"" .. url .. "\"!\n")
  end
end

-- Прошивочка биоса на более пиздатый, нашенский
local function flashEFI()
  local oldBootAddress = component.eeprom.getData()
  local data; local file = io.open("/MineOS/System/OS/EFI.lua", "r"); data = file:read("*a"); file:close()
  component.eeprom.set(data)
  component.eeprom.setLabel("EEPROM (MineOS EFI)")
  component.eeprom.setData(oldBootAddress)
  pcall(component.proxy(oldBootAddress).setLabel, "MineOS")
end

------------------------------------- Стадия стартовой загрузки всего необходимого -------------------------------------

print("Downloading file list")
applications = serialization.unserialize(getFromGitHubSafely(GitHubUserUrl .. "IgorTimofeev/OpenComputers/master/Applications.txt", "/MineOS/System/OS/Applications.txt"))
print(" ")

for i = 1, #applications do
  if applications[i].preLoadFile then
    print("Downloading \"" .. fs.name(applications[i].name) .. "\"")
    getFromGitHubSafely(GitHubUserUrl .. applications[i].url, applications[i].name)
  end
end

print(" ")

------------------------------------- Стадия инициализации загруженных библиотек -------------------------------------

package.loaded.ecs = nil
package.loaded.ECSAPI = nil
_G.ecs = require("ECSAPI")
_G.image = require("image")

local imageOS = image.load("/MineOS/System/OS/Icons/OS_Logo.pic")
local imageLanguages = image.load("/MineOS/System/OS/Icons/Languages.pic")
local imageDownloading = image.load("/MineOS/System/OS/Icons/Downloading.pic")
local imageOK = image.load("/MineOS/System/OS/Icons/OK.pic")

ecs.setScale(installerScale)

local xSize, ySize = component.gpu.getResolution()
local windowWidth, windowHeight = 80, 25
local xWindow, yWindow = math.floor(xSize / 2 - windowWidth / 2), math.ceil(ySize / 2 - windowHeight / 2)
local xWindowEnd, yWindowEnd = xWindow + windowWidth - 1, yWindow + windowHeight - 1

------------------------------------- Базовые функции для работы с будущим окном -------------------------------------

local function clear()
  ecs.blankWindow(xWindow, yWindow, windowWidth, windowHeight)
end

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

------------------------------------- Стадия выбора языка и настройки системы -------------------------------------

ecs.prepareToExit()

local installOption, downloadWallpapers, showHelpTips

do
  clear()
  image.draw(math.ceil(xSize / 2 - 30), yWindow + 2, imageLanguages)

  drawButton("Select language",false)
  waitForClickOnButton("Select language")

  local data = ecs.universalWindow("auto", "auto", 36, 0x262626, true,
    {"EmptyLine"},
    {"CenterText", ecs.colors.orange, "Select language"},
    {"EmptyLine"},
    {"Select", 0xFFFFFF, ecs.colors.green, "Russian", "English"},
    {"EmptyLine"},
    {"CenterText", ecs.colors.orange, "Change some OS properties"},
    {"EmptyLine"},
    {"Selector", 0xFFFFFF, 0xF2B233, "Full installation", "Install only must-have apps", "Install only libraries"},
    {"EmptyLine"},
    {"Switch", 0xF2B233, 0xFFFFFF, 0xFFFFFF, "Download wallpapers", true},
    {"EmptyLine"},
    {"Switch", 0xF2B233, 0xffffff, 0xFFFFFF, "Show help tips in OS", true},
    {"EmptyLine"},
    {"Button", {ecs.colors.orange, 0x262626, "OK"}}
  )
  installOptions, downloadWallpapers, showHelpTips = data[2], data[3], data[4]

  -- Устанавливаем базовую конфигурацию системы
  _G.OSSettings = {
    screensaver = "Matrix",
    screensaverDelay = 20,
    showHelpOnApplicationStart = showHelpTips,
    language = data[1],
    dockShortcuts = {
      {path = "/MineOS/Applications/AppMarket.app"},
      {path = "/MineOS/Applications/MineCode IDE.app"},
      {path = "/MineOS/Applications/Photoshop.app"},
    }
  }

  ecs.saveOSSettings()

  -- Загружаем локализацию инсталлера
  ecs.info("auto", "auto", " ", " Installing language packages...")
  local pathToLang = "/MineOS/System/OS/Installer/Language.lang"
  getFromGitHubSafely(GitHubUserUrl .. "IgorTimofeev/OpenComputers/master/Installer/" .. _G.OSSettings.language .. ".lang", pathToLang)
  getFromGitHubSafely(GitHubUserUrl .. "IgorTimofeev/OpenComputers/master/MineOS/License/" .. _G.OSSettings.language .. ".txt", "/MineOS/System/OS/License.txt")
  
  local file = io.open(pathToLang, "r"); lang = serialization.unserialize(file:read("*a")); file:close()
end


------------------------------------- Проверка, желаем ли мы вообще ставить ось -------------------------------------

do
  clear()

  image.draw(math.ceil(xSize / 2 - 15), yWindow + 2, imageOS)

  --Текстик по центру
  component.gpu.setBackground(ecs.windowColors.background)
  component.gpu.setForeground(ecs.colors.gray)
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
  local file = io.open("/MineOS/System/OS/License.txt", "r")
  for line in file:lines() do
    table.insert(lines, line)
  end
  file:close()

  --Штуку рисуем
  ecs.textField(xText, yText, TextWidth, TextHeight, lines, from, 0xffffff, 0x262626, 0x888888, ecs.colors.blue)
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
local desktopPath = "/MineOS/Desktop/"
local applicationsPath = "/MineOS/Applications/"
local picturesPath = "/MineOS/Pictures/"

fs.remove(desktopPath)

fs.makeDirectory(picturesPath)
fs.makeDirectory(desktopPath)
fs.makeDirectory("/MineOS/Trash/")

------------------------------ Загрузка всего ------------------------------------------

do
  local barWidth = math.floor(windowWidth * 2 / 3)
  local xBar = math.floor(xSize/2-barWidth/2)
  local yBar = yWindowEnd - 3

  local function drawInfo(x, y, info)
    ecs.square(x, y, barWidth, 1, ecs.windowColors.background)
    ecs.colorText(x, y, ecs.colors.gray, ecs.stringLimit("end", info, barWidth))
  end

  ecs.blankWindow(xWindow,yWindow,windowWidth,windowHeight)

  image.draw(math.floor(xSize / 2 - 33), yWindow + 2, imageDownloading)

  ecs.colorTextWithBack(xBar, yBar - 1, ecs.colors.gray, ecs.windowColors.background, lang.osInstallation)
  ecs.progressBar(xBar, yBar, barWidth, 1, 0xcccccc, ecs.colors.blue, 0)
  os.sleep(timing)

  -- Создаем список того, что будем загружать, в зависимости от выбранных ранее опций
  local thingsToDownload = {}
  for i = 1, #applications do
    if
      not applications[i].preLoadFile and
      (
        (applications[i].type == "Library" or applications[i].type == "Icon")
        or
        (
          (installOptions ~= "Install only libraries")
          and
          (
            (applications[i].forceDownload)
            or
            (applications[i].type == "Wallpaper" and downloadWallpapers)
            or
            (applications[i].type == "Application" and installOptions == "Full installation")
          )
        )
      )
    then
      table.insert(thingsToDownload, applications[i])
    end
    --Подчищаем за собой, а то мусора нынче много
    applications[i] = nil
  end

  -- Загружаем все из списка
  for app = 1, #thingsToDownload do
    drawInfo(xBar, yBar + 1, lang.downloading .. " " .. thingsToDownload[app]["name"])
    local percent = app / #thingsToDownload * 100
    ecs.progressBar(xBar, yBar, barWidth, 1, 0xcccccc, ecs.colors.blue, percent)

    ecs.getOSApplication(thingsToDownload[app])
  end

  os.sleep(timing)
  if installOptions == "Install only libraries" then flashEFI(); ecs.prepareToExit(); computer.shutdown(true) end
end

-- Создаем базовые обои рабочего стола
if downloadWallpapers then
  ecs.createShortCut(desktopPath .. "Pictures.lnk", picturesPath)
  ecs.createShortCut("/MineOS/System/OS/Wallpaper.lnk", picturesPath .. "Ciri.pic")
end

-- Создаем файл автозагрузки
local file = io.open("autorun.lua", "w")
file:write("local success, reason = pcall(loadfile(\"OS.lua\")); if not success then print(\"Ошибка: \" .. tostring(reason)) end")
file:close()

-- Биосик
flashEFI()

------------------------------ Стадия перезагрузки ------------------------------------------

ecs.blankWindow(xWindow,yWindow,windowWidth,windowHeight)

image.draw(math.floor(xSize/2 - 16), math.floor(ySize/2 - 11), imageOK)

--Текстик по центру
component.gpu.setBackground(ecs.windowColors.background)
component.gpu.setForeground(ecs.colors.gray)
ecs.centerText("x",yWindowEnd - 5, lang.needToRestart)

--Кнопа
drawButton(lang.restart, false)
waitForClickOnButton(lang.restart)

--Перезагружаем компик
ecs.prepareToExit()
computer.shutdown(true)