local shell = require("shell")
local github = {}

-----------------------------------------------------------------------------------------------

function github.get(url, path)
  shell.execute("github fast " .. url .. " " .. path)
end

-----------------------------------------------------------------------------------------------

return github
