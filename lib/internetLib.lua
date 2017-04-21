
----------------------------------------- Libraries -----------------------------------------

local fs = require("filesystem")
local component = require("component")
local internet = {}

----------------------------------------- Main methods -----------------------------------------

function internet.request(url)
	local pcallSuccess, requestHandle, requestReason = pcall(component.internet.request, url)
	
	-- Если функция компонента была вызвана верно, то идем дальше
	if pcallSuccess then
		-- Если компонент вернул там хендл соединения, то читаем ответ из него
		-- Хендл может не вернуться в случае хуевой урл-ки, которая не нравится компоненту
		if requestHandle then
			local responseData = ""
			-- Читаем данные из хендла по кусочкам
			while true do
				local data, reason = requestHandle.read(math.huge)	
				-- Если прочтение удалость, то записываем кусочек в буфер
				if data then
					responseData = responseData .. data
				else
					-- Если чтение не удалось, и существует некий прочитанный кусочек, то в нем стопудова содержится ошибка чтения
					requestHandle:close()
					if reason then
						return false, reason
					-- А если кусочка нет, то это значит, что соединение можно закрывать с чистой совестью и возвращать всю инфу
					else
						return true, responseData
					end
				end
			end
		else
			return false, "Invalid URL-addess"
		end
	else
		return false, "Usage: internet.request(string url)"
	end
end

function internet.downloadFile(url, path)
	local success, result = internet.request(url)
	if success then
		fs.makeDirectory(fs.path(path) or "")
		local file = io.open(path, "w")
		file:write(result)
		file:close()
		return true
	else
		return false, "Could not connect to to URL-address \"" .. tostring(url) .. "\", the reason is \"" .. tostring(result) .. "\""
	end
end

function internet.runScript(url)
	local success, result = internet.request(url)
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
		return false, "Could not connect to to URL-address \"" .. tostring(url) .. "\", the reason is \"" .. tostring(result) .. "\""
	end
end

----------------------------------------- Cyka -----------------------------------------

return internet





