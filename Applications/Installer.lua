local component = require("component")
local unicode = require("unicode")
local fs = require("filesystem")
local gpu = component.gpu
local internet = component.internet

---------------------------------------------------------------------------------------------------------------------------------

-- Таблица с информацией о файлах, которые необходимо загрузить. Первый элемент - ссылка на файл, второй - путь для сохранения файла.
local applications = {
  {
    url = "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/lib/advancedLua.lua",
    path = "/lib/advancedLua.lua"
  },
  {
    url = "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/lib/color.lua",
    path = "/lib/color.lua"
  },
  {
    url = "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/lib/FormatModules/OCIF.lua",
    path = "/lib/FormatModules/OCIF.lua"
  },
  {
    url = "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/lib/image.lua",
    path = "/lib/image.lua"
  },
  {
    url = "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/lib/doubleBuffering.lua",
    path = "/lib/doubleBuffering.lua"
  }
}

---------------------------------------------------------------------------------------------------------------------------------

local resolutionWidth, resolutionHeight = gpu.getResolution()

function getFile(url, path)
  local file, fileReason = io.open(path, "w")
  if file then
    local pcallSuccess, requestHandle = pcall(internet.request, url)
    if pcallSuccess then
      if requestHandle then
        while true do
          local data, reason = requestHandle.read(math.huge)  
          if data then
            file:write(data)
          else
            requestHandle:close()
            if reason then
              error(reason)
            else
              file:close()
              return
            end
          end
        end
      else
        error("Invalid URL-address: " .. tostring(url))
      end 
    else
      error("Usage: component.internet.request(string url)")
    end

    file:close()
  else
    error("Failed to open file for writing: " .. tostring(fileReason))
  end
end

local function progressBar(x, y, width, height, passiveColor, activeColor, percent)
  gpu.setForeground(passiveColor)
  gpu.set(x, y, string.rep("━", width))
  gpu.setForeground(activeColor)
  gpu.set(x, y, string.rep("━", math.ceil(width * percent)))
end

local function shadowPixel(x, y, symbol)
  local _, _, background = gpu.get(x, y)
  gpu.setBackground(background)
  gpu.set(x, y, symbol)
end

local function downloadWindow()
  local windowWidth, windowHeight = math.ceil(resolutionWidth * 0.35), 5
  local progressBarWidth = windowWidth - 4
  local x, y = math.floor(resolutionWidth / 2 - windowWidth / 2), math.floor(resolutionHeight / 2 - windowHeight / 2)

  gpu.setBackground(0x444444)
  gpu.fill(x + windowWidth, y + 1, 1, windowHeight - 2, " ")
  gpu.setForeground(0x444444)
  for i = x + 1, x + windowWidth do
    shadowPixel(i, y + windowHeight - 1, "▀")
  end
  shadowPixel(x + windowWidth, y, "▄")
  
  gpu.setBackground(0xEEEEEE)
  gpu.fill(x, y, windowWidth, windowHeight - 1, " ")

  local percent = 0
  for i = 1, #applications do
    progressBar(x + 2, y + 1, progressBarWidth, 1, 0xCCCCCC, 0x3366CC, i / #applications)
    gpu.setForeground(0x888888)
    gpu.set(x + 2, y + 2, string.rep(" ", progressBarWidth))
    gpu.set(x + 2, y + 2, unicode.sub("Downloading " .. applications[i].path, 1, progressBarWidth))
    fs.makeDirectory(fs.path(applications[i].path))
    getFile(applications[i].url, applications[i].path)
  end

  os.sleep(0.3)
  
  gpu.setBackground(0x0)
  gpu.fill(x, y, windowWidth + 1, windowHeight + 1, " ")
end

---------------------------------------------------------------------------------------------------------------------------------

downloadWindow()