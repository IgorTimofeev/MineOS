local component = require("component")
local unicode = require("unicode")
local fs = require("filesystem")
local gpu = component.gpu

---------------------------------------------------------------------------------------------------------------------------------

local applications = {
	{ url = "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/lib/advancedLua.lua", path = "/lib/advancedLua.lua" },
	{ url = "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/lib/colorlib.lua", path = "/lib/colorlib.lua" },
	{ url = "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/lib/image.lua", path = "/lib/image.lua" },
	{ url = "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/lib/doubleBuffering.lua", path = "/lib/doubleBuffering.lua" },
	{ url = "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/lib/syntax.lua", path = "/lib/syntax.lua" },
	{ url = "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/lib/GUI.lua", path = "/lib/GUI.lua" },
	{ url = "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/lib/windows.lua", path = "/lib/windows.lua" },
	{ url = "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/lib/MineOSCore.lua", path = "/lib/MineOSCore.lua" },
	{ url = "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/lib/palette.lua", path = "/lib/palette.lua" },
	{ url = "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/lib/ECSAPI.lua", path = "/lib/ECSAPI.lua" },

	{ url = "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/MineOS/Icons/Folder.pic", path = "/MineOS/System/OS/Icons/Folder.pic" },
	{ url = "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/MineOS/Icons/Script.pic", path = "/MineOS/System/OS/Icons/Script.pic" },
	{ url = "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/MineOS/Icons/Text.pic", path = "/MineOS/System/OS/Icons/Text.pic" },
	{ url = "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/MineOS/Icons/Config.pic", path = "/MineOS/System/OS/Icons/Config.pic" },
	{ url = "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/MineOS/Icons/Lua.pic", path = "/MineOS/System/OS/Icons/Lua.pic" },
	{ url = "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/MineOS/Icons/Image.pic", path = "/MineOS/System/OS/Icons/Image.pic" },
	{ url = "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/MineOS/Icons/Pastebin.pic", path = "/MineOS/System/OS/Icons/Pastebin.pic" },
	{ url = "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/MineOS/Icons/FileNotExists.pic", path = "/MineOS/System/OS/Icons/FileNotExists.pic" },
	{ url = "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/MineOS/Icons/Archive.pic", path = "/MineOS/System/OS/Icons/Archive.pic" },
	{ url = "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/MineOS/Icons/3DModel.pic", path = "/MineOS/System/OS/Icons/3DModel.pic" },
	{ url = "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/MineOS/Icons/Application.pic", path = "/MineOS/System/OS/Icons/Application.pic" },
	{ url = "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/MineOS/Icons/Trash.pic", path = "/MineOS/System/OS/Icons/Trash.pic" },

	{ url = "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/MineOS/Languages/Russian.lang", path = "/MineOS/System/OS/Languages/Russian.lang" },
	{ url = "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/MineOS/OSSettings.cfg", path = "/MineOS/System/OS/OSSettings.cfg" },

	{ url = "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/Applications/MineCodeIDE/Localization/Russian.lang", path = "/MineCode/Resources/Localization/Russian.lang" },
	{ url = "https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/Applications/MineCodeIDE/MineCodeIDE.lua", path = "/MineCode/MineCode.lua" },
}

---------------------------------------------------------------------------------------------------------------------------------

local resolutionWidth, resolutionHeight = gpu.getResolution()

function getFile(url, path)
	local file, fileReason = io.open(path, "w")
	if file then
		local pcallSuccess, requestHandle, requestReason = pcall(component.internet.request, url)
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

local function rememberOldPixels(x, y, width, height)
	local oldPixels = {}
	for j = y, y + height - 1 do
		for i = x, x + width - 1 do
			local symbol, foreground, background = gpu.get(i, j)
			symbol, foreground, background = symbol or " ", foreground or 0x0, background or 0x0
			oldPixels[background] = oldPixels[background] or {}
			oldPixels[background][foreground] = oldPixels[background][foreground] or {}
			table.insert(oldPixels[background][foreground], { i, j, symbol })
		end
	end
	return oldPixels
end

local function drawOldPixels(oldPixels)
	for background in pairs(oldPixels) do
		gpu.setBackground(background)
		for foreground in pairs(oldPixels[background]) do
			gpu.setForeground(foreground)
			for i = 1, #oldPixels[background][foreground] do
				gpu.set(oldPixels[background][foreground][i][1], oldPixels[background][foreground][i][2], oldPixels[background][foreground][i][3])
			end
		end
	end
end

local function progressBar(x, y, width, height, passiveColor, activeColor, percent)
	gpu.setForeground(passiveColor)
	gpu.set(x, y, string.rep("━", width))
	gpu.setForeground(activeColor)
	gpu.set(x, y, string.rep("━", math.ceil(width * percent)))
end

local function downloadWindow()
	local windowWidth, windowHeight = math.ceil(resolutionWidth * 0.35), 5
	local x, y = math.floor(resolutionWidth / 2 - windowWidth / 2), math.floor(resolutionHeight / 2 - windowHeight / 2)
	local progressBarWidth = windowWidth - 4

	local oldPixels = rememberOldPixels(x, y, windowWidth + 2, windowHeight + 1)

	gpu.setBackground(0x555555)
	gpu.fill(x + 2, y + windowHeight, windowWidth, 1, " ")
	gpu.fill(x + windowWidth, y + 1, 2, windowHeight - 1, " ")

	gpu.setBackground(0xCCCCCC)
	gpu.fill(x, y, windowWidth, 1, " ")
	
	local titleText = "Installer"
	gpu.setForeground(0x262626)
	gpu.set(math.floor(x + windowWidth / 2 - unicode.len(titleText) / 2), y, titleText)
	
	gpu.setBackground(0xEEEEEE)
	gpu.fill(x, y + 1, windowWidth, windowHeight - 1, " ")

	local percent = 0
	for i = 1, #applications do
		progressBar(x + 2, y + 2, progressBarWidth, 1, 0xCCCCCC, 0x3366CC, i / #applications)
		gpu.setForeground(0x444444)
		gpu.set(x + 2, y + 3, string.rep(" ", progressBarWidth))
		gpu.set(x + 2, y + 3, unicode.sub("Downloading " .. applications[i].path, 1, progressBarWidth))
		fs.makeDirectory(fs.path(applications[i].path))
		getFile(applications[i].url, applications[i].path)
	end

	os.sleep(0.3)
	drawOldPixels(oldPixels)
end

---------------------------------------------------------------------------------------------------------------------------------

downloadWindow()