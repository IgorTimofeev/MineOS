
local internet = require("internet")
local fs = require("filesystem")
local seri = require("serialization")
local shell = require("shell")

local args, options = shell.parse(...)

if #args < 3 or string.lower(tostring(args[1])) == "help" then
  io.write("\nИспользование:")
  io.write("github set <ссылка на репозиторий> - установить текущий репозиторий\n")
  io.write("github get <ссылка> <путь сохранения> - загрузить указанный файл из текущего репозитория\n")
  io.write("github fast <ссылка на raw файл> <путь сохранения>- скачать файл без ебли мозгов\n\n")
  io.write(" Примеры:")
  io.write(" github set <IgorTimofeev/OpenComputers> <путь сохранения> - загрузить указанный файл из текущего репозитория\n")
  io.write(" github get Applications/Home.lua Home.lua\n")
  io.write(" github fast Applications/Home.lua Home.lua\n")
  return
end

local quiet = false
local ssilka, put = args[2], args[3]
if args[1] == "quiet" then quiet = true end

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
	info("Успех!")
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

getFromGitHub(userUrl..ssilka, put)


