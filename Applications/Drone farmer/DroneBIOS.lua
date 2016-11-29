
drone = component.proxy(component.list("drone")())
eeprom = component.proxy(component.list("eeprom")())
modem = component.proxy(component.list("modem")())
port = 512
modem.open(port)

function sleep(timeout)
	local deadline = computer.uptime() + (timeout or 0)
	while computer.uptime() < deadline do
		computer.pullSignal(deadline - computer.uptime())
	end
end

local function executeCode(code)
	local loadSuccess, loadReason = load(code)
	if loadSuccess then
		local xpcallSuccess, xpcallReason = xpcall(loadSuccess, debug.traceback)
		if xpcallSuccess then
			return true
		else
			return false, xpcallReason
		end
	else
		return false, loadReason
	end
end

while true do
	local e = {computer.pullSignal()}
	if e[1] == "modem_message" then
		if e[6] == "executeCode" and e[7] and e[8] then
			local success, reason = executeCode(e[8])
			if e[7] == true then
				modem.send(e[3], port, "executionResult", success, reason)
			end
		elseif e[6] == "flashEEPROM" and e[7] then
			local success = load(e[7])
			if success then
				eeprom.set(e[7])
				computer.beep(1000, 1)
				computer.stop()
				computer.start()
			else
				for i = 1, 3 do computer.beep(800, 0.3) end
			end
		end
	end
end

