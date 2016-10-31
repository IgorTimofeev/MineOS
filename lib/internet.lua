
----------------------------------------- Libraries -----------------------------------------

local fs = require("filesystem")
local internetComponent = require("component").internet
local internet = {}

----------------------------------------- Main methods -----------------------------------------

--Адекватный запрос к веб-серверу вместо стандартного Internet API, бросающего stderr, когда ему вздумается
function internet.request(url, readResponse)
	local success, response = pcall(internetComponent, url)
	
	if readResponse then
		if success then
			local responseData = ""
			while true do
				local data, responseChunk = response.read()	
				if data then
					responseData = responseData .. data
				else
					if responseChunk then
						return false, responseChunk
					else
						return true, responseData
					end
				end
			end
		else
			return false, reason
		end
	end
end

--Загрузка файла с инета
function internet.downloadFile(url, path)
	local success, response = internet.request(url, true)
	if success then
		fs.makeDirectory(fs.path(path) or "")
		local file = io.open(path, "w")
		file:write(response)
		file:close()
	else
		error("Could not connect to to URL address \"" .. url .. "\", the reason is \"" .. response .. "\"")
		return
	end
end


-------------------------------------------------------------------------------------------

return internet





