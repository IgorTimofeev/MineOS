
local AR = require("advancedRobot")
local event = require("event")
local serialization = require("serialization")

local port = 512
AR.proxies.modem.open(port)

--------------------------------------------------------------------------------

local function broadcast(...)
	modem.broadcast(port, "VRScan", ...)
end

local function move(x, y, z)
	print("Moving to next chunk with offset " .. x .. "x" .. y .. "x" .. z)
	AR.moveToPosition(AR.robotPositionX + x, AR.robotPositionY + y, AR.robotPositionZ + z)
end

while true do
	local e = {event.pull()}
	if e[1] == "modem_message" and e[6] == "VRScan" then
		if e[7] == "scan" then
			print("Scanning started")

			local width, height, length, radius, minDensity, maxDensity = e[8], e[9], e[10], e[11], e[12], e[13]
			
			for h = 1, height do
				for w = 1, width do
					for l = 1, length do
						print("Scanning chunk " .. w .. " x " .. h .. " x " .. l)
						
						local result, column = {}
						for z = -radius, radius do
							for x = -radius, radius do
								column = AR.proxies.geolyzer.scan(x, z)
								for i = 1, #column do
									if column[i] >= minDensity and column[i] <= maxDensity then
										table.insert(result, AR.robotPositionX)
										table.insert(result, AR.robotPositionY)
										table.insert(result, AR.robotPositionZ)
										table.insert(result, column[i])
									end
								end 
							end
						end

						print("Scanning finished. Sending result with size: " .. #result)
						broadcast("result", AR.robotPositionX, AR.robotPositionY, AR.robotPositionZ, serialization.serialize(result))

						move(0, 0, radius + 1)
					end

					move(radius + 1, 0, 0)
				end

				move(0, radius + 1, 0)
			end
		end
	end
end
