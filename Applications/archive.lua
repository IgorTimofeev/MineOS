local archive = require("lib/archive")
local shell = require("shell")
local fs = require("filesystem")

------------------------------------------------------------------------------------------------------------------------------------

local args, options = shell.parse(...)

if not options.q then
	archive.debugMode = true
end

local function debug(text)
	if not options.q then print(text) end
end

if args[1] == "pack" then
	if not args[2] or not args[3] then
		debug(" ")
		debug("Использование: archive pack <имя архива> <архивируемая папка>")
		debug(" ")
		return
	end 
	debug(" ")
	debug("Упаковка пакета начата")
	debug(" ")
	archive.pack(args[2], args[3])
	debug(" ")
	debug("Упаковка пакета завершена, файл сохранен как \"" .. args[2] .. "\", его размер составил " .. math.ceil(fs.size(args[2]) / 1024) .. "КБ")
	debug(" ")
elseif args[1] == "unpack" then
	if not args[2] or not args[3] then
		debug(" ")
		debug("Использование: archive unpack <путь к архиву> <папка для сохранения файлов>")
		debug(" ")
		return
	end
	debug(" ")
	debug("Распаковка пакета начата")
	debug(" ")
	archive.unpack(args[2], args[3])
	debug(" ")
	debug("Распаковка пакета \"" .. args[2] .. "\" завершена")
	debug(" ")
elseif args[1] == "download" or args[1] == "get" then
	if not args[2] or not args[3] then
		debug(" ")
		debug("Использование: archive download <URL-ссылка на архив> <папка для сохранения файлов>")
		debug(" ")
		return
	end
	debug(" ")
	debug("Загрузка файла по ссылке \"" .. args[2] .. "\"")
	shell.execute("wget " .. args[2] .. " TempFile.pkg -fq")
	debug(" ")
	debug("Распаковка загруженного пакета")
	archive.unpack("TempFile.pkg", args[3])
	shell.execute("rm TempFile.pkg")
	debug(" ")
	debug("Пакет \"" .. args[2] .. "\" был успешно загружен и распакован")
	debug(" ")
else
	debug(" ")
	debug("Использование: archive <pack/unpack/download> ...")
	debug(" ")
	return
end

archive.debugMode = false

------------------------------------------------------------------------------------------------------------------------------------
