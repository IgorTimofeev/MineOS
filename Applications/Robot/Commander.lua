local robotAPI = require("robotAPI")
local args = {...}

if #args < 0 then
	print("No arguments")
	return
end

print("Task stated")

local function execute(symbol)
	if symbol == "f" then
		print("Moving forward:", robotAPI.moveForward())
	elseif symbol == "b" then
		print("Moving backward:", robotAPI.moveBackward())
	elseif symbol == "u" then
		print("Moving up:", robotAPI.moveUp())
	elseif symbol == "d" then
		print("Moving down:", robotAPI.moveDown())
	elseif symbol == "r" then
		print("Turning right:", robotAPI.turnRight())
	elseif symbol == "l" then
		print("Turning left:", robotAPI.turnLeft())
	elseif symbol == "t" then
		print("Turning around:", robotAPI.turnAround())
	elseif symbol == "s" then
		print("Swinging:", robotAPI.swing())
	elseif symbol == "e" then
		print("Swinging:", robotAPI.use())
	end
end

local i, commands, symbol, starting, ending, count = 1, args[1]
while i <= #commands do
	starting, ending = commands:find("%d+", i)
	
	if starting == i then
		symbol, count = commands:sub(ending + 1, ending + 1), tonumber(commands:sub(starting, ending))
		
		print("Executing \"" .. symbol .. "\" command for " .. count .. " times")
		for j = 1, count do
			execute(symbol)
		end 

		i = ending + 2
	else
		execute(commands:sub(i, i))
		i = i + 1
	end
end

print("Task finished")