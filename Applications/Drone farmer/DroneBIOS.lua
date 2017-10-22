
drone = component.proxy(component.list("drone")())
eeprom = component.proxy(component.list("eeprom")())
modem = component.proxy(component.list("modem")())
port = 512
modem.open(port)

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
	local eventData = {computer.pullSignal()}
	if eventData[1] == "modem_message" then
		if eventData[6] == "executeCode" and eventData[7] then
			local success, reason = executeCode(table.unpack(eventData, 8))
			if eventData[7] == true then
				modem.send(eventData[3], port, "executionResult", success, reason)
			end
		elseif eventData[6] == "flashEEPROM" and eventData[7] then
			local success = load(eventData[7])
			if success then
				eeprom.set(eventData[7])
				computer.beep(1000, 1)
				computer.stop()
				computer.start()
			else
				for i = 1, 3 do computer.beep(800, 0.3) end
			end
		end
	end
end

