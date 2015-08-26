local component = require("component")
local computer = require("computer")
local term = require("term")
local unicode = require("unicode")
local event = require("event")
local fs = require("filesystem")
local internet = require("internet")
local seri = require("serialization")
local os = require("os")
local gpu = component.gpu

--Variables and etc

local lang = {
    ["en"] = {
        lang_name_short = "en",
        lang_name_long = "English",
        err_get_github = "Could not connect to the 'github.com' or file write failed. Check internet connection and use RW filesystem. Error: ",
        err_file_write = "Write to file failed: ",
        err_no_inetcard = "This program requires an internet card to run.",
        err_http_req = "HTTP request failed: ",
        info_load_inst_data = "Loading installer data",
        info_install_next = "Press Next to continue OS installation",
        info_license_question = "Do you accept following license?",
        info_installing_os = "Installing OS",
        info_downloading_app = "Downloading: ",
        info_reboot = "OS installation complete, reboot required",
        button_reboot = "Reboot",
        button_accept = "Accept",
        file_language_lua = "return \"English\"",
        file_license = "System/OS/License/English.txt",
    },
    ["ru"] = {
        lang_name_short = "ru",
        lang_name_long = "Russian",
        err_no_inetcar = "Для запуска этой программы необходима интернет карта",
        info_load_inst_data = "Загрузка данных установщика",
        info_install_next = "Чтобы начать установку ОС, нажмите Далее",
        info_license_question = "Принимаете ли вы условия лицензионного соглашения?",
        info_installing_os = "Установка OS",
        info_downloading_app = "Загрузка: ",
        info_reboot = "Система установлена, необходима перезагрузка",
        button_reboot = "Перезагрузить",
        button_accept = "Принимаю",
        file_license = "System/OS/License/Russian.txt",
        file_language_lua = "return \"Russian\"",
    }
}

local github_raw_url = "https://raw.githubusercontent.com/"
local github_repo = "IgorTimofeev/OpenComputers"

local applications

local padColor = 0x262626
local installerScale = 1

local timing = 0.2

--Init--

local function localize(str_name, llang)
    str_name = tostring(str_name) --You never can be too safe
    return (lang[os.getenv("LANG") or (llang and lang[tostring(llang)]) or "en"])[str_name] or "!"..str_name.."!"
end
local L = localize

local function writeToLog(...)
    if not (os.getenv("DEBUG")=="DEBUG") then return end
    local str = table.concat({...}," ")
    local lfile = io.open("/tmp/log","a")
    lfile:write(str.."\n")
    lfile:close()
end

--Github downloading--
local function getFromGitHub(url, path)
    local sContent = ""
    local result, response = pcall(internet.request, url)
    writeToLog("gfGH1: ",tostring(result),tostring(response))
    if not result then
        return nil, response
    end
    path = os.getenv("PWD")..path
    writeToLog("gfGH2: ", path)
    fs.makeDirectory(fs.path(path))
    if fs.exists(path) then fs.remove(path) end
    local file = io.open(path, "w")
    for chunk in response do
        file:write(chunk)
        sContent = sContent .. chunk
    end

    file:close()

    return result,sContent
end

--pcall wrapper
local function getFromGitHubSafely(url, path)
    local success, sRepos = pcall(getFromGitHub, url, path)
    if not success then
        writeToLog(tostring(url),";",tostring(sRepos))
        io.stderr:write(L("err_get_github")..sRepos)
        os.sleep(1)
        return -1
    end
    return sRepos
end

--pastebin downloading
local function getFromPastebin(paste, filename)
    local content = ""
    local f, reason = io.open(filename, "w")
    if not f then
        io.stderr:write((L"err_file_write") .. reason)
        return
    end
    --io.write("Downloading from pastebin.com... ")
    local url = "http://pastebin.com/raw.php?i=" .. paste
    local result, response = pcall(internet.request, url)
    if result then
        --io.write("Success.\n")
        for chunk in response do
            --if not options.k then
            --string.gsub(chunk, "\r\n", "\n")
            --end
            f:write(chunk)
            content = content .. chunk
        end
        f:close()
        --io.write("Saved data to " .. filename .. "\n")
    else
        f:close()
        fs.remove(filename)
        io.stderr:write(L"err_http_req" .. response .. "\n")
    end

    return content
end

if not component.isAvailable("internet") then
    io.stderr:write(L"err_no_inetcard")
    return
end

getFromGitHubSafely(github_raw_url..github_repo.."/master/lib/ECSAPI.lua", "lib/ECSAPI.lua")

local ecs = require("lib/ECSAPI")

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

--Base package downloading--

if not fs.exists("System/OS/Installer/OK.png") then

    local barWidth = math.floor(windowWidth / 2)
    local xBar = math.floor(xSize/2-barWidth/2)
    local yBar = math.floor(ySize/2) + 1

    --Screen clear
    ecs.clearScreen(padColor)

    clear()

    gpu.setBackground(ecs.windowColors.background)
    gpu.setForeground(ecs.colors.gray)
    ecs.centerText("x", yBar - 2, L"info_load_inst_data")

    ecs.progressBar(xBar, yBar, barWidth, 1, 0xcccccc, ecs.colors.blue, 0)
    os.sleep(timing)

    --local response = getSafe(github_raw_url .. github_repo .. "/master/Applications.txt", "System/OS/Applications.txt")

    local preLoadApi = {
        { paste = github_repo .. "/master/lib/image.lua", path = "lib/image.lua" },
      --{ paste = github_repo .. "/master/Installer/Languages.png", path = "System/OS/Installer/Languages.png" },
        { paste = github_repo .. "/master/Installer/OK.png", path = "System/OS/Installer/OK.png" },
        { paste = github_repo .. "/master/Installer/Downloading.png", path = "System/OS/Installer/Downloading.png" },
        { paste = github_repo .. "/master/Installer/OS_Logo.png", path = "System/OS/Installer/OS_Logo.png" },
        { paste = github_repo .. "/master/MineOS/License/"..L("lang_name_long")..".txt", path = "System/OS/License/"..L("lang_name_long")..".txt" },
    }

    for i = 1, #preLoadApi do

        local percent = i / #preLoadApi * 100
        ecs.progressBar(xBar, yBar, barWidth, 1, 0xcccccc, ecs.colors.blue, percent)

        if fs.exists(preLoadApi[i]["path"]) then fs.remove(preLoadApi[i]["path"]) end
        fs.makeDirectory(fs.path(preLoadApi[i]["path"]))
        getFromGitHubSafely(github_raw_url .. preLoadApi[i]["paste"], preLoadApi[i]["path"])

    end

end

applications = seri.unserialize(getFromPastebin("3j2x4dDn", "System/OS/Applications.txt")) --loading something from pastebin that is on GH? Whatever.

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

    --Centered text
    gpu.setBackground(ecs.windowColors.background)
    gpu.setForeground(ecs.colors.gray)
    ecs.centerText("x", yWindowEnd - 5 ,L"info_install_next")

    --Button
    drawButton("->",false)

    waitForClickOnButton("->")

    --Language setup (TODO: do something with that)
    local path = "System/OS/Language.lua"
    if fs.exists(path) then fs.remove(path) end
    fs.makeDirectory(fs.path(path))
    local file = io.open(path, "w")
    file:write(L"file_language_lua")
    file:close()

end

------------------------------СТАДИЯ ВЫБОРА ЯЗЫКА------------------------------------------

do

    clear()

    --TOS?
    local from = 1
    local xText, yText, TextWidth, TextHeight = xWindow + 4, yWindow + 2, windowWidth - 8, windowHeight - 10

    --Read TOS file
    local lines = {}
    local file, reason = io.open(fs.canonical(L"file_license"), "r")
    for line in file:lines() do
        table.insert(lines, line)
    end
    file:close()

    --image.draw(math.ceil(xSize / 2 - 30), yWindow + 2, imageLanguages)
    --ecs.selector(math.floor(xSize / 2 - 10), yWindowEnd - 5, 20, "Russian", {"English", "Russian"}, 0xffffff, 0x000000, true)

    --Штуку рисуем
    ecs.textField(xText, yText, TextWidth, TextHeight, lines, from)

    --Инфо рисуем
    ecs.centerText("x", yWindowEnd - 5 ,"info_license_question")

    --кнопа
    drawButton(L"button_accept",false)

    while true do
        local e = { event.pull() }
        if e[1] == "touch" then
            if ecs.clickedAtArea(e[3], e[4], obj["buttons"][L"button_accept"][1], obj["buttons"][L"button_accept"][2], obj["buttons"][L"button_accept"][3], obj["buttons"][L"button_accept"][4]) then
                drawButton(L"button_accept", true)
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

    --Downloading things--

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

        ecs.colorTextWithBack(xBar, yBar - 1, ecs.colors.gray, ecs.windowColors.background, L"info_installing_os")
        ecs.progressBar(xBar, yBar, barWidth, 1, 0xcccccc, ecs.colors.blue, 0)
        os.sleep(timing)

        for app = 1, #applications do
            --Drawing init
            drawInfo(xBar, yBar + 1, L"info_downloading_app"..applications[app]["name"])
            local percent = app / #applications * 100
            ecs.progressBar(xBar, yBar, barWidth, 1, 0xcccccc, ecs.colors.blue, percent)

            --Downloading init
            local path = applications[app]["name"]
            if fs.exists(path) then fs.remove(path) end

            --If it is an app
            if applications[app]["type"] == "Application" then
                fs.makeDirectory(path..".app/Resources")
                getFromGitHubSafely(github_raw_url .. applications[app]["url"], path..".app/"..fs.name(applications[app]["name"]..".lua"))
                getFromGitHubSafely(github_raw_url .. applications[app]["icon"], path..".app/Resources/Icon.png")
                if applications[app]["resources"] then
                    for i = 1, #applications[app]["resources"] do
                        getFromGitHubSafely(github_raw_url .. applications[app]["resources"][i]["url"], path..".app/Resources/"..applications[app]["resources"][i]["name"])
                    end
                end
            --If it's on pastebin
            elseif applications[app]["type"] == "Pastebin" then
                    fs.remove(applications[app]["name"])
                    fs.makeDirectory(fs.path(applications[app]["name"]))
                    getFromPastebin(applications[app]["url"], applications[app]["name"])

            --Everything else
            else
                    getFromGitHubSafely(github_raw_url .. applications[app]["url"], path)
                end
            end

            os.sleep(timing)
        end

        --Reboot--

        ecs.blankWindow(xWindow,yWindow,windowWidth,windowHeight)

        image.draw(math.floor(xSize/2 - 16), math.floor(ySize/2 - 11), imageOK)

        --Текстик по центру
        gpu.setBackground(ecs.windowColors.background)
        gpu.setForeground(ecs.colors.gray)
        ecs.centerText("x",yWindowEnd - 5, L"info_reboot")

        --Кнопа
        drawButton(L"button_reboot",false)

        waitForClickOnButton(L"button_reboot")

        computer.shutdown(true)
