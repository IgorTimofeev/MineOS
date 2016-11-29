
----------------------------------------- Libraries -----------------------------------------

local fs = require("filesystem")
local internetComponent = require("component").internet
local internet = {}

----------------------------------------- Main methods -----------------------------------------

--Адекватный запрос к веб-серверу вместо стандартного Internet API, бросающего stderr, когда ему вздумается
function internet.request(url, skipReadingResponse)
	local pcallSuccess, requestHandle, requestReason = pcall(internetComponent.request, url)
	
	-- Если требуется чтение инфы из соединения, то читаем
	if not skipReadingResponse then
		-- Если функция компонента была вызвана верна, то идем дальше
		if pcallSuccess then
			-- Если компонент вернул там хендл соединения, то читаем ответ из него
			-- Хендл может не вернуться в случае хуевой урл-ки, которая не нравится компоненту
			if requestHandle then
				local responseData = ""
				-- Читаем данные из хендла по кусочкам
				while true do
					local data, responseChunk = requestHandle.read()	
					-- Если прочтение удалость, то записываем кусочек в буфер
					if data then
						responseData = responseData .. data
					else
						-- Если чтение не удалось, и существует некий прочитанный кусочек, то в нем стопудова содержится ошибка чтения
						if responseChunk then
							requestHandle:close()
							return false, responseChunk
						-- А если кусочка нет, то это значит, что соединение можно закрывать с чистой совестью и возвращать всю инфу
						else
							requestHandle:close()
							return true, responseData
						end
					end
				end
			else
				return false, requestReason
			end
		else
			return false, reason
		end
	end
end

--Загрузка файла с инета
function internet.downloadFile(url, path)
	local success, response = internet.request(url)
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

-- print(internet.request("http://VK.com", true))

return internet





