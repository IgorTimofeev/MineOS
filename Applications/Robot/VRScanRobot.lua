
local AR = require("advancedRobot")
local event = require("event")
local serialization = require("serialization")

local port = 512
AR.proxies.modem.open(port)

--------------------------------------------------------------------------------

local function broadcast(...)
	AR.proxies.modem.broadcast(port, "VRScan", ...)
end

local function round(num, decimalPlaces)
	local mult = 10 ^ (decimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end

local function move(x, y, z)
	print("Moving to next chunk with offset " .. x .. "x" .. y .. "x" .. z)
	AR.moveToPosition(AR.positionX + x, AR.positionY + y, AR.positionZ + z)
end

print("Waiting for modem commands...")

while true do
	local e = {event.pull()}
	if e[1] == "modem_message" and e[6] == "VRScan" then
		if e[7] == "scan" then
			local settings = serialization.unserialize(e[8])
			
			print("Scanning with paramerers: " .. e[8])

			local h, w, l, startX, startY, startZ = 0, 0, 0, AR.positionX, AR.positionY, AR.positionZ

			local function move()
				local distance = settings.radius * 2 + 1
				local moveX, moveZ = AR.getRotatedPosition(w * distance, l * distance)
				
				AR.moveToPosition(
					startX + moveX,
					startY + h * distance,
					startZ + moveZ
				)
			end

			while h < settings.height do
				while w < settings.width do
					while l < settings.length do
						print("Scanning chunk " .. w .. " x " .. h .. " x " .. l)
						
						local result, column = {
							x = AR.positionX,
							y = AR.positionY,
							z = AR.positionZ,
							blocks = {}
						}

						local blockCount = 0
						for z = -settings.radius, settings.radius do
							for x = -settings.radius, settings.radius do
								column = AR.proxies.geolyzer.scan(x, z)
								
								for i = 32 - settings.radius, 32 + settings.radius do
									if column[i] >= settings.minDensity and column[i] <= settings.maxDensity then
										local y = i - 33
										result.blocks[x] = result.blocks[x] or {}
										result.blocks[x][y] = result.blocks[x][y] or {}
										result.blocks[x][y][z] = result.blocks[x][y][z] or {}
										table.insert(result.blocks[x][y][z], round(column[i], 2))

										blockCount = blockCount + 1
									end
								end 
							end
						end

						print("Scanning finished. Sending result with blocks size: " .. blockCount)
						broadcast("result", serialization.serialize(result))

						l = l + 1
						move()
					end

					w = w + 1
					move()
				end

				h = h + 1
				move()
			end
		end
	end
end
