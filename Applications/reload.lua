local seri = require("serialization")
local fs = require("filesystem")
local github = require("github")

local args = {...}

---------------------------------------------------------------------------------------

local function printUsage()
  print(" ")
  print(" Использование:")
  print(" reload <путь к файлу> - перезагружает файл с GitHub автора")
  print(" ")
end

local function readFile()
  local readedFile = ""
  local file = io.open("System/OS/Applications.txt", "r")
  readedFile = file:read("*a")
  readedFile = seri.unserialize(readedFile)
  file:close()
  return readedFile
end

local function getGitHubUrl(name)
  local massiv = readFile()
  for i = 1, #massiv do
    --print(massiv[i]["name"])
    if massiv[i]["name"] == name then
      return massiv[i]["url"]
    end
  end
end

local function reloadFromGitHub(url, name)
  github.get("https://raw.githubusercontent.com/" .. url, name)
  print(" ")
  print("Файл " .. name .. " перезагружен из https://raw.githubusercontent.com/" .. url)
  print(" ")
end

---------------------------------------------------------------------------------------

if #args < 1 then printUsage(); return end
local url = getGitHubUrl(args[1])
if not url then print(" "); io.stderr:write("На GitHub автора отсутствует указанный файл."); print(" ") end

reloadFromGitHub(url, args[1])
