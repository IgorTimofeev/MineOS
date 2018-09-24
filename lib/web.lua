
local component = require("component")
local fs = require("filesystem")

----------------------------------------------------------------------------------------------------

local function encode(data)
	data = data:gsub("([^%w%-%_%.%~])", function(char)
		return string.format("%%%02X", string.byte(char))
	end)
	
	return data
end

local function serialize(data)
	if type(data) == "table" then		
		local result = ""

		local function doSerialize(table, keyStack)
			for key, value in pairs(table) do
				if type(key) == "number" then
					key = key - 1
				end

				if type(value) == "table" then
					doSerialize(value, keyStack .. "[" .. encode(tostring(key)) .. "]")
				else
					result = result .. keyStack .. "[" .. encode(tostring(key)) .. "]=" .. encode(tostring(value)) .. "&"
				end
			end
		end
		
		for key, value in pairs(data) do	
			if type(value) == "table" then
				doSerialize(value, encode(tostring(key)))
			else
				result = result .. key .. "=" .. encode(tostring(value)) .. "&"
			end
		end

		return result:sub(1, -2)
	else
		return tostring(data)
	end
end

----------------------------------------------------------------------------------------------------

local function rawRequest(url, postData, headers, chunkHandler, chunkSize)
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

local function request(url, postData, headers)
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

local function download(url, path)
	fs.makeDirectory(fs.path(path) or "")
	
	local handle, reason = io.open(path, "w")
	if handle then
		local success, reason = rawRequest(url, nil, nil, function(chunk)
			handle:write(chunk)
		end)

		handle:close()
		if success then
			return true
		else
			fs.remove(path)
			return false, reason
		end
	else
		return false, "Failed to open file for writing: " .. tostring(reason)
	end	
end

local function run(url, ...)
	local result, reason = request(url)
	if result then
		result, reason = load(result)
		if result then
			result = {pcall(result, ...)}
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

-- print(serialize({
-- 	array = {
-- 		pidor = "English Test 123-_.~",
-- 		tyan = 512,
-- 		second = {
-- 			zalupa = 421,
-- 			penis = "Член"
-- 		}
-- 	},
-- }, true))

----------------------------------------------------------------------------------------------------

return {
	encode = encode,
	serialize = serialize,
	rawRequest = rawRequest,
	request = request,
	download = download,
	run = run,
}





