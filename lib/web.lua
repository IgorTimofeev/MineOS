
local component = require("component")
local fs = require("filesystem")
local web = {}

----------------------------------------------------------------------------------------------------

local function serializeTable(table, currentData)
	local result = ""

	for key, value in pairs(table) do
		local keyType, valueType = type(key), type(value)

		if keyType == "number" then
			key = key - 1
		end

		if valueType == "table" then
			result = result .. serializeTable(value, currentData .. "[" .. key .. "]")
		else
			result = result .. currentData .. "[" .. key .. "]=" .. value .. "&"
		end
	end

	return result
end

function web.serialize(data)
	if type(data) == "table" then
		local serializedData = ""
		
		for key, value in pairs(data) do	
			if type(value) == "table" then
				serializedData = serializedData .. serializeTable(value, key)
			else
				serializedData = serializedData .. key .. "=" .. value .. "&"
			end
		end

		return serializedData
	else
		return tostring(data)
	end
end

function web.encode(data)
	if data then
		data = string.gsub(data, "([^%w ])", function(char)
			return string.format("%%%02X", string.byte(char))
		end)
		data = string.gsub(data, " ", "+")
	end

	return data 
end

----------------------------------------------------------------------------------------------------

function web.rawRequest(url, postData, headers, chunkHandler, chunkSize)
	if postData then
		postData = web.serialize(postData)
	end

	local pcallSuccess, requestHandle, requestReason = pcall(component.internet.request, url, postData, headers)
	if pcallSuccess then
		if requestHandle then
			while true do
				local chunk, reason = requestHandle.read(chunkSize or math.huge)	
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
			return false, "Invalid URL-address"
		end
	else
		return false, "Invalid arguments to component.internet.request"
	end
end

function web.request(url, postData, headers)
	local data = ""
	local success, reason = web.rawRequest(url, postData, headers, function(chunk)
		data = data .. chunk
	end)

	if success then
		return data
	else
		return false, reason
	end
end

function web.download(url, path)
	fs.makeDirectory(fs.path(path) or "")
	
	local handle, reason = io.open(path, "w")
	if handle then
		local success, reason = web.rawRequest(url, nil, nil, function(chunk)
			handle:write(chunk)
		end)

		handle:close()
		if success then
			return true
		else
			return false, reason
		end
	else
		return false, "Failed to open file for writing: " .. tostring(reason)
	end	
end

function web.run(url, ...)
	local result, reason = web.request(url)
	if result then
		result, reason = load(result)
		if result then
			result = { pcall(result, ...) }
			if result[1] then
				return table.unpack(result, 2)
			else
				return false, "Failed to run script: " .. tostring(result[2])
			end
		else
			return false, "Failed to run script: " .. tostring(loadReason)
		end
	else
		return false, reason
	end
end

----------------------------------------------------------------------------------------------------

-- print(
-- 	web.serialize({
-- 		string = "Hello world",
-- 		number = 123,
-- 		array = {
-- 			arrayString = "Meow",
-- 			arrayInArray = {
-- 				arrayInArrayNumber = 456
-- 			}
-- 		}
-- 	})
-- )

-- print(
-- 	web.run(
-- 		"https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/Screensavers/Matrix.lua"
-- 	)
-- )

-- print(result)

----------------------------------------------------------------------------------------------------

return web





