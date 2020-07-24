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
load(data)()