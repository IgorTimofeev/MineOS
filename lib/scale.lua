
-- CopyPizding from eu_tomat *meowderful* guide

local component = require("component")
local screenScale = {}

------------------------------------------------------------------------------------------------------

function screenScale.getResolution(scale, debug)
	if not scale or scale > 1 then
		scale = 1
	elseif scale < 0.1 then
		scale = 0.1
	end

	local gpu = component.gpu
	local sw, sh = component.proxy(gpu.getScreen()).getAspectRatio()
	local sa = (sw * 2 - 0.5) / (sh - 0.25)

	local gw, gh = gpu.maxResolution()
	if sa > gw / gh then
		gh = gw / sa
	else
		gw = gh * sa
	end

	return math.floor(gw * scale), math.floor(gh * scale) 
end

function screenScale.set(scale)
	component.gpu.setResolution(screenScale.getResolution(scale))
end

------------------------------------------------------------------------------------------------------

-- screenScale.set(0.8)

------------------------------------------------------------------------------------------------------

return screenScale
