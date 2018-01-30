
local web = require("web")

local function fileList(user, repo, path)
	local result, reason = web.request("https://github.com/" .. user .. "/" .. repo .. "/" .. path)
	if result then
		for path in result:gmatch("octicon%-file%-.+<a href=") do
			print(path)
		end
	else
		error(reason)
	end
end

fileList("IgorTimofeev", "OpenComputers", "")