
local keyboard = {}
local pressedCodes = {}

-------------------------------------------------------------------------------

function keyboard.isKeyDown(code)
	checkArg(1, code, "number")
	
	return pressedCodes[code]
end

function keyboard.isControl(code)
	return type(code) == "number" and (code < 32 or (code >= 127 and code <= 159))
end

function keyboard.isAltDown()
	return pressedCodes[56] or pressedCodes[184]
end

function keyboard.isControlDown()
	return pressedCodes[29] or pressedCodes[157]
end

function keyboard.isShiftDown()
	return pressedCodes[42] or pressedCodes[54]
end

function keyboard.isCommandDown()
	return pressedCodes[219]
end

-------------------------------------------------------------------------------

require("Event").addHandler(function(e1, _, _, e4)
	if e1 == "key_down" then
		pressedCodes[e4] = true
	elseif e1 == "key_up" then
		pressedCodes[e4] = nil
	end
end)

-------------------------------------------------------------------------------

return keyboard
