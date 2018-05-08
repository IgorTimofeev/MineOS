
require("advancedLua")
local buffer = require("doubleBuffering")
local unicode = require("unicode")
local unicodeLen, unicodeSub, unicodeFind = unicode.len, unicode.sub, string.unicodeFind

local syntax = {}

----------------------------------------------------------------------------------------------------------------------------------------

local indentationSymbol = "│"

local colorScheme = {

}

local patterns = {
	
}

----------------------------------------------------------------------------------------------------------------

-- buffer.flush()
-- buffer.clear(0x1b1b1b)

-- buffer.square(5, 5, 30, 3, colorScheme.background, 0x0, " ")

-- local counter = 2
-- for line in io.lines("/g.lua") do
-- 	pcall(syntax.highlightString, 2, counter, 1, 160, 2, line)
	
-- 	counter = counter + 1
-- 	if counter > 50 then
-- 		break
-- 	end
-- end

-- buffer.draw(true)

----------------------------------------------------------------------------------------------------------------

return syntax




