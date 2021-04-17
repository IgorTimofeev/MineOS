local handle, data, chunk = component.proxy(component.list("internet")()).request("https://raw.githubusercontent.com/IgorTimofeev/MineOS/master/Installer/Main.lua"), ""
   
while true do
	chunk = handle.read(math.huge)
	
	if chunk then
		data = data .. chunk
	else
		break
	end
end

handle.close()

local result, reason = load(data, "=installer")
if result then
	result, reason = xpcall(result, debug.traceback)
	if not result then
		error(reason)
	end
else
	error(reason)	
end
