
local internet = require("component").internet
local url = "https://oauth.vk.com/token?grant_type=password&client_id=3697615&client_secret=AlVXZFMUqyrnABp8ncuU&username=Igor_Timofeev@me.com&password=3222288222238901371&v=5.50"


local response, errorMessage = internet.request(url)

if response then
	local data = ""
	local readedData

	for key, val in pairs(response) do
		print(key, val)
	end

	while true do
		local readedData, readedReason = response.read()
		if not readedData then
			if readedReason then
				ecs.error("Ашибачка при чтении: " .. readedReason)
				break
			else
				break
			end
		else
			data = data .. readedData
		end
	end

	ecs.error("Ответ сервера: " .. tostring(data))
else
	ecs.error("Ашибачка: " .. tostring(errorMessage))
end













