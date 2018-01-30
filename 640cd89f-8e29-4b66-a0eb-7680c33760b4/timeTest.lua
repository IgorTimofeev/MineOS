

local bit32 = require("bit32")

local function toRGB1(IntegerColor)
	return bit32.rshift(IntegerColor, 16), bit32.band(bit32.rshift(IntegerColor, 8), 0xFF), bit32.band(IntegerColor, 0xFF)
end

local function toRGB2(IntegerColor)
	return bit32.rshift(IntegerColor, 16), bit32.band(bit32.rshift(IntegerColor, 8), 0xFF), bit32.band(IntegerColor, 0xFF)
end


local oldClock = os.clock()

print("TIME: ", os.clock() - oldClock)