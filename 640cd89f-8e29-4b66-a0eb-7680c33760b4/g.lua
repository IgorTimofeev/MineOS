local buffer = require("doubleBuffering")
local color = require("color")
local image = require("image")
local web = require('web')
local MineOSCore = require("MineOSCore")

local picture, reason = MineOSCore.loadImageFromString(web.request("https://github.com/IgorTimofeev/OpenComputers/raw/master/Icons/Security.pic"))
if picture then
	buffer.clear(0x0)
	buffer.image(2, 2, picture)
	buffer.draw(true)
else
	print(reason)
end

