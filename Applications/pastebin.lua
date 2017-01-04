
local component = require("component")
local shell = require("shell")
if not component.isAvailable("internet") then print("Insert internet card, fucking idiot"); return end
local internet = require("internet")
local args, options = shell.parse(...)

local rawURL = "http://pastebin.com/raw/"

local function info(text)
	if not options.q and not options.Q then
		print(text)
	end
end

local function printUsage()
	info("Usage:")
	info("  pastebin run <paste>")
	info("  pastebin get <paste> <path to save file>")
end

if args[1] == "run" then
	if args[2] then
		info("Running script from url \"" .. args[2] .. "\"")
		local success, response = internet.request(rawURL .. args[2])
		if success then
			load(response)()
		else
			info("Failed to connect")
		end
	else
		printUsage()
	end
elseif args[1] == "get" then
	if args[2] and args[3] then
		info("Downloading file \"" .. args[3] .. "\" from url \"" .. args[2] .. "\"")
		local success, reason = pcall(internet.downloadFile, rawURL .. args[2], args[3])
		if success then
			info("Done")
		else
			info("Failed to download file")
		end
	else
		printUsage()
	end
else
	printUsage()
end
