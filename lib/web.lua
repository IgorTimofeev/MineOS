
----------------------------------------- Libraries -----------------------------------------

local fs = require("filesystem")
local component = require("component")
local web = {}

----------------------------------------- Main methods -----------------------------------------

function web.request(url)
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
						return responseData
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

function web.downloadFile(url, path)
	local result, reason = web.request(url)
	if result then
		fs.makeDirectory(fs.path(path) or "")
		local file = io.open(path, "w")
		file:write(result)
		file:close()

		return result
	else
		return false, "Could not connect to to URL-address \"" .. tostring(url) .. "\", the reason is \"" .. tostring(reason) .. "\""
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

		if application.createShortcut == "desktop" then
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

----------------------------------------------------------------------------------------

-- web.downloadMineOSApplication({
-- 	path="/MineOS/Applications/3DTest",
-- 	url="https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/Applications/3DTest/3DTest.lua",
-- 	about="https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/Applications/3DTest/About/",
-- 	type="Application",
-- 	icon="https://raw.githubusercontent.com/IgorTimofeev/OpenComputers/master/Applications/3DTest/Icon.pic",
-- 	createShortcut="desktop",
-- 	forceDownload=true,
-- 	version=1.16,
-- })

----------------------------------------- Cyka -----------------------------------------

return web





