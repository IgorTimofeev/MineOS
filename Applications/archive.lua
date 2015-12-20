local archive = require("lib/archive")

------------------------------------------------------------------------------------------------------------------------------------

local args = {...}

archive.debugMode = true

if args[1] == "pack" then
	if not args[2] or not args[3] then
		print(" ")
		print("Использование: archive pack <имя архива> <архивируемая папка>")
		print(" ")
		return
	end 
	archive.pack(args[2], args[3])
elseif args[1] == "unpack" then
	if not args[2] or not args[3] then
		print(" ")
		print("Использование: archive unpack <путь к архиву> <папка для сохранения файлов>")
		print(" ")
		return
	end
	archive.unpack(args[2], args[3])
else
	print(" ")
	print("Использование: archive <pack/unpack> <имя архива/путь к архиву> <архивируемая папка/папка для сохранения файлов>")
	print(" ")
	return
end

archive.debugMode = false

------------------------------------------------------------------------------------------------------------------------------------
