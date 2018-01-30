
computer.beep(2000, 0.1)

local eeprom = component.proxy(component.list("eeprom")())
local modem = component.proxy(component.list("modem")())
local port = 512
modem.open(port)

------------------------------------------------------------------------

local masterControllerAddress
local thisComputerAddress = computer.address()

------------------------------------------------------------------------

local function turnOnNearbyComputers()
	for address in component.list("computer") do
		if address ~= thisComputerAddress then
			component.proxy(address).start()
		end
	end
end

------------------------------------------------------------------------

turnOnNearbyComputers()
modem.broadcast(port, "tunnelUpdate", thisComputerAddress)

while true do
	local eventData = {computer.pullSignal()}
	if eventData[1] == "modem_message" then
		if eventData[6] == "flash" then
			if load(eventData[7]) then
				for i = 1, 3 do
					computer.beep(1000, 0.5)
				end
				eeprom.set(eventData[7])
				computer.shutdown(true)
			else
				computer.beep(400, 0.2)
			end
		elseif eventData[6] == "tunnelState" then
			if eventData[7] == "stop" and thisComputerAddress ~= masterControllerAddress then
				computer.shutdown()
			elseif eventData[7] == "start" then
				turnOnNearbyComputers()
			end
		elseif eventData[6] == "tunnelMasterControllerUpdate" then
			masterControllerAddress = eventData[7]
		end
	end
end
