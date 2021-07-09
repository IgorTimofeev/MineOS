
local screen = require("Screen")
local event = require("Event")

-------------------------------------------------------------------------------------

local lineCount = 10
local backgroundColor = 0x0
local lineColor = 0xFFFFFF
local bufferWidth, bufferHeight = screen.getResolution()

-------------------------------------------------------------------------------------

local t = {}

function rnd()
	if math.random(0,1) == 0 then
		return -1
	else
		return 1
	end
end
 
for i = 1, lineCount do
	t[i] = {
		x = math.random(1, bufferWidth),
		y = math.random(1, bufferHeight * 2),
		dx = rnd(),
		dy = rnd()
	}
end

-------------------------------------------------------------------------------------

screen.clear(backgroundColor)
screen.update()

while true do
	local eventType = event.pull(0.0001)
	if eventType == "touch" or eventType == "key_down" then
		break
	end

	for i = 1, lineCount do
		t[i].x = t[i].x + t[i].dx
		t[i].y = t[i].y + t[i].dy

		if t[i].x > bufferWidth then t[i].dx = -1 end
		if t[i].y > bufferHeight * 2 then t[i].dy = -1 end
		if t[i].x < 1 then t[i].dx = 1 end
		if t[i].y < 1 then t[i].dy = 1 end
	end

	screen.clear(backgroundColor)

	for i = 1, lineCount - 1 do
		screen.drawSemiPixelLine(t[i].x, t[i].y, t[i + 1].x, t[i + 1].y, lineColor)
	end

	screen.drawSemiPixelLine(t[1].x, t[1].y, t[lineCount].x, t[lineCount].y, lineColor)
	screen.update()
end