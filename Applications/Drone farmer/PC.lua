
local component = require("component")
local event = require("event")
local modem = component.modem
local port = 512
modem.open(port)

while true do
	local e = {event.pull()}
	if e[1] == "key_down" then
		if e[4] == 28 then
			local file = io.open("/DroneCode.lua", "r")
			local data = file:read("*a")
			file:close()
			modem.broadcast(port, "executeCode", true, data)
		elseif e[4] == 14 then
			local file = io.open("/DroneBIOS.lua", "r")
			local data = file:read("*a")
			file:close()
			modem.broadcast(port, "flashEEPROM", data)
		end
	elseif e[1] == "modem_message" then
		if e[6] == "executionResult" then
			print("Резултат выполнения кода: " .. tostring(e[7]) .. ", " .. tostring(e[8]))
		end
	end
end


