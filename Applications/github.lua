local internet = require("internet")
local fs = require("filesystem")
local seri = require("serialization")
local shell = require("shell")
local config = require("config")

local args, options = shell.parse(...)

local function printUsage()
  io.write("\n Использование:\n")
  io.write(" github set <ссылка на репозиторий> - установить указанный репозиторий в качестве постоянного\n")
  io.write(" github get <ссылка> <путь сохранения> - загрузить указанный файл из текущего репозитория\n")
  io.write(" github fast <ссылка на raw файл> <путь сохранения>- скачать файл без ебли мозгов\n\n")
  io.write(" Примеры:\n")
  io.write(" github set IgorTimofeev/OpenComputers\n")
  io.write(" github get Applications/Home.lua Home.lua\n")
  io.write(" github fast IgorTimofeev/OpenComputers/master/Applications/Home.lua Home.lua\n\n")	
end

if #args < 2 or string.lower(tostring(args[1])) == "help" then
  printUsage()
  return
end

local quiet = false
if args[1] == "fast" then quiet = true end

local pathToConfig = "System/GitHub/Repository.cfg"
local currentRepository
local userUrl = "https://raw.githubusercontent.com/"

--pastebin run SthviZvU IgorTimofeev/OpenComputers/master/Applications.txt hehe.txt

------------------------------------------------------------------------------------------

local function info(text)
	if not quiet then print(text) end
end

--ЗАГРУЗОЧКА С ГИТХАБА
local function getFromGitHub(url, path)
	local sContent = ""

	info(" ")
	info("Подключаюсь к GitHub по адресу "..url)

	local result, response = pcall(internet.request, url)
	if not result then
		return nil
	end

	info(" ")

	if result == "" or result == " " or result == "\n" then info("Файл пустой, либо ссылка неверная."); return end

	if fs.exists(path) then
		info("Файл уже существует, удаляю старый.")
		fs.remove(path)
	end
	fs.makeDirectory(fs.path(path))
	local file = io.open(path, "w")

	for chunk in response do
		file:write(chunk)
		sContent = sContent .. chunk
	end

	file:close()
	info("Файл загружен и находится в /"..path)
	info(" ")
	return sContent
end

--БЕЗОПАСНАЯ ЗАГРУЗОЧКА
local function getFromGitHubSafely(url, path)
	local success, sRepos = pcall(getFromGitHub, url, path)
	if not success then
		io.stderr:write("Не удалось подключиться по данной ссылке. Вероятно, она неверная, либо отсутствует подключение к Интернету.")
		return nil
	end
	return sRepos
end

if args[1] == "set" then
	if fs.exists(pathToConfig) then fs.remove(pathToConfig) end
	fs.makeDirectory(fs.path(pathToConfig))
	config.write(pathToConfig, "currentRepository", args[2])
	currentRepository = args[2]
	info(" ")
	info("Текущий репозиторий изменен на "..currentRepository)
	info(" ")
elseif args[1] == "get" then
	if not fs.exists(pathToConfig) then
		io.write("\nТекущий репозиторий не установлен. Используйте \"github set <путь к репозиторию>\".\n\n")
	else
		currentRepository = config.readAll(pathToConfig).currentRepository
		getFromGitHubSafely(userUrl .. currentRepository .. "/master/" .. args[2], args[3])
	end
elseif args[1] == "fast" then
	getFromGitHubSafely(userUrl .. args[2], args[3])
else
	printUsage()
	return
end
