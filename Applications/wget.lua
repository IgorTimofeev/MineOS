

local component = require("component")
local shell = require("shell")
if not component.isAvailable("internet") then print("Insert internet card, fucking idiot"); return end
local internet = require("internet")
local args, options = shell.parse(...)

local function info(text)
	if not options.q and not options.Q then
		print(text)
	end
end

if args[1] and args[2] then
	info("Downloading file \"" .. tostring(args[2]) .. "\" from url \"" .. tostring(args[1]) .. "\"")
	local success, reason = pcall(internet.downloadFile, args[1], args[2])
	if success then
		info("Done")
	else
		info("Failed to download file")
	end
else
	info("Usage: wget <url> <path to save file>")
end
