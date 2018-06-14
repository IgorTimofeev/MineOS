
local AR = require("advancedRobot")
local event = require("event")
local sides = require("sides")
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
			local w, h, l

			AR.positionX = 0
			AR.positionY = 0
			AR.positionZ = 0
			AR.rotation = 0

			print("Scanning with paramerers: " .. e[8])

			local function moveChunk(side)
				for i = 1, settings.radius * 2 + 1 do
					AR.swingAndMove(side)
				end
			end

			local function doChunk()
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
			end

			local function doLength()
				l = 1
				while l <= settings.length do
					doChunk()
					if l < settings.length then
						moveChunk(sides.front)
					end
					l = l + 1
				end
			end

			h = 1
			while h <= settings.height do
				w = 1
				while w <= settings.width do
					doLength()

					AR.turnRight()
					moveChunk(sides.front)
					AR.turnRight()

					doLength()

					if w < settings.width then
						AR.turnLeft()
						moveChunk(sides.front)
						AR.turnLeft()
					else
						AR.turnRight()
						for i = 1, settings.width * 2 - 1 do
							moveChunk(sides.front)
						end
						AR.turnRight()

						if h < settings.height then
							moveChunk(sides.up)
						else
							for i = 1, settings.height - 1 do
								moveChunk(sides.down)
							end
						end
					end

					w = w + 1
				end

				h = h + 1
			end
			
			print("Task finished")
		end
	end
end
