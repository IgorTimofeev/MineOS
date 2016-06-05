local args = {...}

local libraries = {
	buffer = "doubleBuffering",
	image = "image",
	fs = "filesystem",
	GUI = "GUI",
}

for library in pairs(libraries) do if not _G[library] then _G[library] = require(libraries[library]) end end; libraries = nil

------------------------------------------------------------------------------------------------------------------
buffer.start()

if fs.exists(args[1]) then
	local cyka = image.load(args[1])
	buffer.clear(0x000000)
	buffer.image(1, 1, cyka)
	buffer.draw()

	if args[2] then
		fs.makeDirectory(fs.path(args[2]) or "")
		image.save(args[2], cyka, 4)
	end
else
	GUI.error("Файл \"" .. args[1] .. "\" не существует")
end
