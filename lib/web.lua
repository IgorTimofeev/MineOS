
local fs = require("filesystem")
local component = require("component")
local web = {}

----------------------------------------------------------------------------------------------------

local function rawRequest(url, postData, headers, chunkHandler)
	local stringPostData
	if postData then
		if type(postData) == "table" then
			stringPostData = ""
			for key, value in pairs(postData) do
				if type(value) == "table" then
					for i = 1, #value do
						stringPostData = stringPostData .. "&" .. key .. "[" .. (i - 1) .. "]=" .. value[i]
					end
				else
					stringPostData = stringPostData .. "&" .. key .. "=" .. value
				end
			end
		elseif type(postData) == "string" then
			stringPostData = postData
		end
	end

	local pcallSuccess, requestHandle, requestReason = pcall(component.internet.request, url, stringPostData, headers)
	if pcallSuccess then
		if requestHandle then
			while true do
				local chunk, reason = requestHandle.read(math.huge)	
				if chunk then
					chunkHandler(chunk)
				else
					requestHandle:close()
					if reason then
						return false, reason
					else
						return true
					end
				end
			end
		else
			return false, "Invalid URL-addess"
		end
	else
		return false, "Usage: web.request(string url)"
	end
end

----------------------------------------------------------------------------------------------------

function web.request(url, postData, headers)
	local data = ""
	local success, reason = rawRequest(url, postData, headers, function(chunk)
		data = data .. chunk
	end)

	if success then
		return data
	else
		return false, reason
	end
end

function web.downloadFile(url, path)
	fs.makeDirectory(fs.path(path) or "")
	local file, reason = io.open(path, "w")
	if file then
		local success, reason = rawRequest(url, nil, nil, function(chunk)
			file:write(chunk)
		end)

		file:close()
		if success then
			return true
		else
			return false, "Could not connect to to URL-address \"" .. tostring(url) .. "\", the reason is \"" .. tostring(reason) .. "\""
		end
	else
		return false, "Failed to open file for writing: " .. tostring(reason)
	end	
end

function web.runScript(url)
	local result, reason = web.request(url)
	if success then
		local loadSucces, loadReason = load(result)
		if loadSucces then
			local xpcallSuccess, xpcallSuccessReason = xpcall(loadSucces, debug.traceback)
			if xpcallSuccess then
				return true
			else
				return false, "Failed to run script: " .. tostring(xpcallSuccessReason)
			end
		else
			return false, "Failed to run script: " .. tostring(loadReason)
		end
	else
		return false, "Could not connect to to URL-address \"" .. tostring(url) .. "\", the reason is \"" .. tostring(reason) .. "\""
	end
end

function web.downloadMineOSApplication(application, language)
    if application.type == "Application" then
		fs.remove(application.path .. ".app")

		web.downloadFile(application.url, application.path .. ".app/Main.lua")
		web.downloadFile(application.icon, application.path .. ".app/Resources/Icon.pic")

		if application.resources then
			for i = 1, #application.resources do
				web.downloadFile(application.resources[i].url, application.path .. ".app/Resources/" .. application.resources[i].path)
			end
		end

		if application.about then
			web.downloadFile(application.about .. language .. ".txt", application.path .. ".app/Resources/About/" .. language .. ".txt")
		end 

		if application.createShortcut then
			local path = "/MineOS/Desktop/" .. fs.name(application.path) .. ".lnk"
			fs.makeDirectory(fs.path(path))

			local file, reason = io.open(path, "w")
			if file then
				file:write(application.path .. ".app/")
				file:close()
			else
				print(reason)
			end
		end
	else
		web.downloadFile(application.url, application.path)
	end
end

----------------------------------------------------------------------------------------------------

-- print(web.request("http://94.242.34.251:8888/MineOS/AppMarket/test.php", {
-- 	abc = "siski",
-- 	def = {"meow", "sex", "pizda"},
-- 	ghi = 123
-- }))

-- web.downloadFile("https://github.com/IgorTimofeev/OpenComputers/raw/master/Wallpapers/CloudyEvening.pic", "Clouds.pic")

----------------------------------------------------------------------------------------------------

return web





