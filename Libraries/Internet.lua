
local filesystem = require("Filesystem")

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

local function rawRequest(url, postData, headers, chunkHandler, chunkSize, method)
	local pcallSuccess, requestHandle, requestReason = pcall(component.get("internet").request, url, postData, headers, method)
	
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
			return false, requestReason or "Invalid URL-address"
		end
	else
		return false, "Invalid arguments to internet.request"
	end
end

local function request(url, postData, headers, method)
	local data = ""
	local success, reason = rawRequest(
		url,
		postData,
		headers,
			function(chunk)
			data = data .. chunk
		end,
		method
	)

	if success then
		return data
	else
		return false, reason
	end
end

local function download(url, path)
	filesystem.makeDirectory(filesystem.path(path) or "")
	
	local handle, reason = filesystem.open(path, "w")
	if handle then
		local success, reason = rawRequest(url, nil, nil, function(chunk)
			handle:write(chunk)
		end)

		handle:close()
		if success then
			return true
		else
			filesystem.remove(path)
			return false, reason
		end
	else
		return false, "Failed to open file for writing: " .. tostring(reason)
	end	
end

local function run(url, ...)
	local result, reason = request(url)
	if result then
		result, reason = load(result, "=script")
		if result then
			result = {xpcall(result, debug.traceback, ...)}
			if result[1] then
				return table.unpack(result, 2)
			else
				return false, tostring(result[2])
			end
		else
			return false, tostring(reason)
		end
	else
		return false, reason
	end
end

----------------------------------------------------------------------------------------------------

return {
	encode = encode,
	serialize = serialize,
	rawRequest = rawRequest,
	request = request,
	download = download,
	run = run,
}