
-------------------------------------------------------- Libraries --------------------------------------------------------

local buffer = require("doubleBuffering")
local postProcessing = {}

-------------------------------------------------------- Plane object --------------------------------------------------------

function postProcessing.photofilter(color, transparency)
	buffer.clear(color, transparency)
end

function postProcessing.fadePhotifilter(color, fromTransparency, toTransparency, step)
	for i = fromTransparency, toTransparency, fromTransparency < toTransparency and step or -step do
		postProcessing.photofilter(color, i)
	end
end

-------------------------------------------------------- Zalupa --------------------------------------------------------

return postProcessing
