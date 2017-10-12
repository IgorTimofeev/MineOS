
local fs = require("filesystem")
local component = require("component")
local web = {}

----------------------------------------------------------------------------------------------------

local function serializeTableToURL(existentData, table)
	local result = ""

	for key, value in pairs(table) do
		local keyType, valueType = type(key), type(value)

		if keyType == "number" then
			key = key - 1
		-- elseif keyType == "string" then
		-- 	key = "\"" .. key .. "\""
		end

		if valueType == "table" then
			result = result .. serializeTableToURL(existentData .. "[" .. key .. "]", value)
		else
			result = result .. existentData .. "[" .. key .. "]=" .. value .. "&"
		end
	end

	return result
end

local function rawRequest(url, postData, headers, chunkHandler)
	local stringPostData
	if postData then
		if type(postData) == "table" then
			stringPostData = ""

			for key, value in pairs(postData) do	
				if type(value) == "table" then
					stringPostData = stringPostData .. serializeTableToURL(key, value)
				else
					stringPostData = stringPostData .. key .. "=" .. value .. "&"
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

-- print(web.request("http://test.php", {
-- 	abc = "siski",
-- 	pizda = "test",
-- 	def = {
-- 		{name = "Test1.png", data = "F0"},
-- 		{name = "Test2.png", data = "FF"},
-- 		{hello = "world", meow = "meow-meow"}
-- 	},
-- }))

-- web.downloadFile("https://github.com/IgorTimofeev/OpenComputers/raw/master/Wallpapers/CloudyEvening.pic", "Clouds.pic")

----------------------------------------------------------------------------------------------------

return web





