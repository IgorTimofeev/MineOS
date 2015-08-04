
local internet = require("internet")
local fs = require("filesystem")
local seri = require("serialization")
local shell = require("shell")

local args, options = shell.parse(...)

if #args < 3 then
  io.write("\nИспользование: github get <ссылка> <путь сохранения>\n")
  io.write("  -q: Тихий режим, текстовая информация об успехе не выводится.\n\n")
  io.write("  Пример: github  get  IgorTimofeev/OpenComputers/master/Applications.txt  Applications.txt\n")
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


