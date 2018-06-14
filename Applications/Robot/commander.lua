local AR = require("advancedRobot")
local args = {...}

if #args == 0 then
	print("Usage:")
	print("  commander <command string>")
	return
end

print("Task stated")

local function execute(symbol)
	if symbol == "f" then
		print("Moving forward:", AR.moveForward())
	elseif symbol == "b" then
		print("Moving backward:", AR.moveBackward())
	elseif symbol == "u" then
		print("Moving up:", AR.moveUp())
	elseif symbol == "d" then
		print("Moving down:", AR.moveDown())
	elseif symbol == "r" then
		print("Turning right:", AR.turnRight())
	elseif symbol == "l" then
		print("Turning left:", AR.turnLeft())
	elseif symbol == "t" then
		print("Turning around:", AR.turnAround())
	elseif symbol == "s" then
		print("Swinging:", AR.swingForward())
	elseif symbol == "e" then
		print("Swinging:", AR.useForward())
	elseif symbol == "." then
		print("Returning to start:", AR.moveToZeroPosition())
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
