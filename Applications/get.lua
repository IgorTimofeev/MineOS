
local component = require("component")
local ecs = require("ECSAPI")
local serialization = require("serialization")
local unicode = require("unicode")

local pathToApplications = "MineOS/System/OS/Applications.txt"
local applications = {}
local arguments = { ... }

--------------------------------------------------------------------------------------------------------------

local function loadApplications()
	local file = io.open(pathToApplications, "r")
	applications = serialization.unserialize(file:read("*a"))
	file:close()
end

local function printUsage()
	print("Использование:")
	print("  get <Имя файла> - программа попытается найти указанный файл по имени и загрузить его")
	print("  get all <Applications/Wallpapers/Scripts/Libraries> - программа загрузит все существующие файлы из указанной категории")
	print("  get everything - программа загрузит все файлы из списка")
	print("  get ApplicationList - программа перезагрузит список файлов из GitHub")
	-- print("Доступные категории:")
	-- print("  Applications - приложения MineOS")
	-- print("  Wallpapers - обои для MineOS")
	-- print("  Scripts - различные программы с расширением .lua")
	-- print("  Libraries - библиотеки")
	-- print(" ")
end

local function searchFile(searchName)
	searchName = unicode.lower(searchName)
	if ecs.getFileFormat(searchName) == ".app" then searchName = ecs.hideFileFormat(searchName) end
	for i = 1, #applications do
		if unicode.lower(fs.name(applications[i].name)) == searchName then
			return i
		end
	end
end

local function getCategory(category)
	local counter = 0
	for i = 1, #applications do
		if applications[i].type == category then
			print("Загружаю файл \"" .. applications[i].name .. "\" по адресу \"" .. applications[i].url .. "\"")
			ecs.getOSApplication(applications[i])
			counter = counter + 1
		end
	end
	if counter > 0 then print(" ") end
	print("Количество загруженных файлов: " .. counter)
end

local function getEverything()
	local counter = 0
	for i = 1, #applications do
		print("Загружаю файл \"" .. applications[i].name .. "\" по адресу \"" .. applications[i].url .. "\"")
		ecs.getOSApplication(applications[i])
		counter = counter + 1
	end
	print("Количество загруженных файлов: " .. counter)
end

local function parseArguments()
	if not arguments[1] then
		printUsage()
	elseif unicode.lower(arguments[1]) == "all" then
		if not arguments[2] then
			printUsage()
		elseif unicode.lower(arguments[2]) == "libraries" then
			getCategory("Library")
		elseif unicode.lower(arguments[2]) == "wallpapers" then
			getCategory("Wallpaper")
		elseif unicode.lower(arguments[2]) == "scripts" then
			getCategory("Script")
		elseif unicode.lower(arguments[2]) == "applications" then
			getCategory("Application")
		else
			print("Указана неизвестная категория \"" .. arguments[2] .. "\", поддерживаются только Applications, Wallpapers, Libraries или Scripts.")
		end
	elseif unicode.lower(arguments[1]) == "everything" then
		getEverything()
	elseif unicode.lower(arguments[1]) == "applicationlist" then
		local url = "IgorTimofeev/OpenComputers/master/Applications.txt"
		print("Загружаю список приложений по адресу \"" .. url .. "\"")
		ecs.getFromGitHub(url, "MineOS/System/OS/Applications.txt")
	else
		local foundedID = searchFile(arguments[1])
		if foundedID then
			print("Файл \"" .. applications[foundedID].name .. "\" найден, загружаю по адресу \"" .. applications[foundedID].url .. "\"")
			ecs.getOSApplication(applications[foundedID])
		else
			print("Указанный файл не найден")
		end
	end
end

--------------------------------------------------------------------------------------------------------------

if not component.isAvailable("internet") then 
	print("Этой программе требуется интернет-карта для работы")
	return
end

loadApplications()
print(" ")
parseArguments()
print(" ")












