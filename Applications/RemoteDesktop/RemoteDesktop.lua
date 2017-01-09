

local unicode = require("unicode")
local component = require("component")
local modem = component.modem
local gpu = component.gpu
local event = require("event")

local port = 512
modem.open(port)

local function sendString(data)
	local stringSize = string.len(data)
	local maxPacketSize = modem.maxPacketSize()
	local myPacketSize = maxPacketSize - 32

	modem.broadcast(port, "TVS")
	local i = 1
	while i <= stringSize do
		local str = data:sub(i, i + myPacketSize - 1)
		modem.broadcast(port, "TVC", str)
		i = i + myPacketSize
	end
	modem.broadcast(port, "TVE")
end

local function getScreenString()
	local resolutionX, resolutionY = gpu.getResolution()
	local str = string.format("%02X", resolutionX) .. string.format("%02X", resolutionY)
	for y = 1, resolutionY do
		for x = 1, resolutionX do
			local symbol, foreground, background = gpu.get(x, y)
			str = str .. string.format("%06X", background) .. string.format("%06X", foreground) .. symbol
		end
	end
	return str
end

local function decodeScreenString(str)
	local resolutionX, resolutionY = tonumber("0x" .. unicode.sub(str, 1, 2)), tonumber("0x" .. unicode.sub(str, 3, 4))
	-- print("RES: ", resolutionX, resolutionY)
	local x, y, i = 1, 1, 5
	while i <= unicode.len(str) do
		local background, foreground, symbol = unicode.sub(str, i, i + 5), unicode.sub(str, i + 6, i + 11), unicode.sub(str, i + 12, i + 12)
		-- print(x, y, background, foreground, symbol)
		gpu.setBackground(tonumber("0x" .. background))
		gpu.setForeground(tonumber("0x" .. foreground))
		gpu.set(x, y, symbol)
		-- event.pull("touch")
		x = x + 1
		if x > resolutionX then
			os.sleep(0)
			x, y = 1, y + 1
		end
		i = i + 13
	end
end

local function receive()
	local str
	while true do
		local e = {event.pull()}
		if e[1] == "modem_message" then
			if e[6] == "TVS" then
				str = ""
			elseif e[6] == "TVC" then
				str = str .. e[7]
			elseif e[6] == "TVE" then
				return str
			end
		end
	end
end


-- sendString(getScreenString())
decodeScreenString(receive())










