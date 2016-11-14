
_G.modem = component.proxy(component.list("modem")())
_G.inventory_controller = component.proxy(component.list("modem")())
_G.drone = component.proxy(component.list("drone")())
_G.port = 512

modem.open(port)

while true do
	local e = {computer.pullSignal()}
	if e[1] == "modem_message" then
		if e[6] == "executeScript" then
			modem.send(e[2], port, "executionResult", xpcall(load(e[7]), debug.traceback()))
		end
	end
end
